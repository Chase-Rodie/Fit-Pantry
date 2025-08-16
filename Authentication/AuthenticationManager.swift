//
//  AuthenticationManager.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 11/23/24.
//

//A lot of code was grabbed from Firebase's documentation on how to support Authentication
//https://firebase.google.com/docs/auth/ios/password-auth

import Foundation
import FirebaseAuth
import FirebaseFirestore

// Maps Firebase `User` object into a simpler model for use throughout the app
struct AuthDataResultModel {
    let uid: String
    let email: String?
    let photoUrl: String?
    let isAnonymous: Bool
    let isEmailVerified: Bool
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email
        self.photoUrl = user.photoURL?.absoluteString
        self.isAnonymous = user.isAnonymous
        self.isEmailVerified = user.isEmailVerified
    }
}

// Unlinks a specified provider (e.g. Google, Apple) from the current authenticated user
func unlinkProvider(_ provider: AuthProviderOption) async throws {
    guard let user = Auth.auth().currentUser else {
        throw CustomAuthenticationErrors.userNotFound
    }
    do {
        try await user.unlink(fromProvider: provider.rawValue)
    } catch {
        throw CustomAuthenticationErrors.unknownError(error.localizedDescription)
    }
}

// Updates the current user's display name and/or photo URL
func updateUserProfile(displayName: String?, photoUrl: URL?) async throws {
    guard let user = Auth.auth().currentUser else {
        throw CustomAuthenticationErrors.userNotFound
    }
    let changeRequest = user.createProfileChangeRequest()
    changeRequest.displayName = displayName
    changeRequest.photoURL = photoUrl
    do {
        try await changeRequest.commitChanges()
    } catch {
        throw CustomAuthenticationErrors.unknownError(error.localizedDescription)
    }
}

// Retrieves the current user's Firebase ID token, useful for custom backend auth
func getUserToken() async throws -> String {
    guard let user = Auth.auth().currentUser else {
        throw CustomAuthenticationErrors.userNotFound
    }
    do {
        let token = try await user.getIDToken()
        return token
    } catch {
        throw CustomAuthenticationErrors.unknownError(error.localizedDescription)
    }
}

// Custom errors for various authentication-related issues
enum CustomAuthenticationErrors: LocalizedError {
    case userNotFound
    case emailVerificationFailed
    case invalidCredentials
    case signOutFailed
    case providerOptionNotFound(String)
    case unknownError(String)
    case requiresReauthentication
    case deleteUserDefaultFailed(String)

    var errorDescription: String? {
            switch self {
            case .userNotFound:
                return "No authenticated user was found."
            case .emailVerificationFailed:
                return "Failed to send email verification."
            case .invalidCredentials:
                return "The provided credentials are invalid."
            case .signOutFailed:
                return "Sign out operation failed."
            case .providerOptionNotFound(let providerID):
                return "Provider option not recognized: \(providerID)"
            case .requiresReauthentication:
                        return "Reauthentication is required before deleting your account."
            case .unknownError(let message):
                return "An unknown error occurred: \(message)"
            case .deleteUserDefaultFailed(let message):
                return "Failed to delete user defaults: \(message)"
            }
        }
    }

// Enum for supported authentication providers
enum AuthProviderOption: String {
    case email = "password"
    case google = "google.com"
    case apple = "apple.com"
}

final class AuthenticationManager {
    
    static let shared = AuthenticationManager()
    private init() {}
    
    // Retrieves the currently authenticated user and maps them to a custom model
    func getAuthenticatedUser() throws -> AuthDataResultModel {
        guard let user = Auth.auth().currentUser else {
            throw CustomAuthenticationErrors.userNotFound
        }
        
        return AuthDataResultModel(user: user)
    }
    
    // Returns the list of email-based providers associated with the user (e.g., email, google, apple)
    func getcurrentEmailProvider() throws -> [AuthProviderOption] {
        guard let providerData = Auth.auth().currentUser?.providerData else{
            throw CustomAuthenticationErrors.userNotFound
        }
        
        var providers: [AuthProviderOption] = []
        for provider in providerData {
            if let option = AuthProviderOption(rawValue: provider.providerID) {
                providers.append(option)
            } else {
                throw CustomAuthenticationErrors.providerOptionNotFound(provider.providerID)
            }
        }
        print(providers)
        return providers
    }
    
    // Signs out the user, clears session data, and resets user defaults
    func signOut() async throws {
        try Auth.auth().signOut()
        UserDefaults.standard.removeObject(forKey: "userSession")
        UserDefaults.standard.synchronize()
        try await resetUserDefaults()
        print("User signed out successfully")
    }
    
    // Deletes the user's authentication credentials and associated Firestore data
    func deleteUser() async throws {
        guard let user = Auth.auth().currentUser else {
            throw CustomAuthenticationErrors.userNotFound
        }

        let userID = user.uid
        let db = Firestore.firestore()
        let batch = db.batch()

        do {
            //Steps to batch delete collections/subcollecitons
            // Delete profile doc
            let profileRef = db.collection("users").document(userID).collection("UserInformation").document("profile")
            batch.deleteDocument(profileRef)

            // Delete root user doc
            let userRef = db.collection("users").document(userID)
            batch.deleteDocument(userRef)

            // Delete workout plan collection (delete each document inside the collection)
            let workoutPlanRef = db.collection("users").document(userID).collection("workoutplan")
            
            // Fetch all workout plan documents
            let workoutDocs = try await workoutPlanRef.getDocuments()

            // Add delete operations for each workout plan document
            for document in workoutDocs.documents {
                let workoutPlanDocumentRef = document.reference
                batch.deleteDocument(workoutPlanDocumentRef)

                // Delete sub-collections (Day1, Day2, etc.)
                for dayIndex in 1...7 {
                    let dayCollectionRef = workoutPlanDocumentRef.collection("Day\(dayIndex)")
                    let exercises = try await dayCollectionRef.getDocuments()

                    // Delete each exercise in the day collection
                    for exerciseDoc in exercises.documents {
                        batch.deleteDocument(exerciseDoc.reference)
                    }
                }
            }

            // Commit the batch of delete operations
            try await batch.commit()
            print("User document, profile, and workoutplan deleted from Firestore")

            // Delete Firebase Auth user
            try await user.delete()
            print("User deleted from Firebase Authentication")

            // Reset UserDefaults
            try await resetUserDefaults()
            print("User defaults reset")

            // Clear currentUser on main thread
            await MainActor.run {
                UserManager.shared.currentUser = nil
            }
            print("UserManager currentUser cleared")

        } catch {
            if let errorCode = (error as NSError?)?.code,
               errorCode == AuthErrorCode.requiresRecentLogin.rawValue {
                throw CustomAuthenticationErrors.requiresReauthentication
            } else {
                throw CustomAuthenticationErrors.unknownError(error.localizedDescription)
            }
        }
    }
    
    // Sends an email verification message to the current user's email
    func sendEmailVerification() throws {
        guard let user = Auth.auth().currentUser else {
            throw CustomAuthenticationErrors.userNotFound
        }
        
        user.sendEmailVerification { error in
            if let error = error {
                print("Failed to send email verification: \(error.localizedDescription)")
            } else {
                print("Email verification sent successfully.")
            }
        }
    }
    
    // Removes specific user default keys, verifying that deletion was successful
    func resetUserDefaults()async throws{
        let keysToRemove = ["workoutPlan", "workoutMetadata"]
        let defaults = UserDefaults.standard

        for key in keysToRemove {
            defaults.removeObject(forKey: key)
            if defaults.object(forKey: key) != nil {
                throw CustomAuthenticationErrors.deleteUserDefaultFailed("Failed to remove key: \(key)")
            } else {
                print("Removed key: \(key)")
            }
        }

        defaults.synchronize() //Optional according to StackOverflow. Does not seem to impact functionality, leaving here just in case.
    }


    
}

//SignIn Email Functions

extension AuthenticationManager {
    
    // Creates a new user with email and password, sends a verification email, and stores user in Firestore
    @discardableResult
    func createUser(email: String, password: String) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let user = authDataResult.user
        
        // This sends email verification
        try await user.sendEmailVerification()
        
        // This creates a Firestore entry
        let authDataModel = AuthDataResultModel(user: user)
        let dbUser = DBUser(auth: authDataModel)
        try await UserManager.shared.createNewUser(user: dbUser)
        
        return authDataModel
    }
    
    // Signs in a user with email and password, ensuring email is verified before proceeding
    @discardableResult
    func signInUser(email: String, password: String) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().signIn(withEmail: email, password: password)
        let user = authDataResult.user
        
        guard user.isEmailVerified else {
            print("User email is not verified: \(user.email ?? "Uknown email")")
            throw CustomAuthenticationErrors.emailVerificationFailed
        }
        return AuthDataResultModel(user: user)
    }
    
    // Sends a password reset email to the given email address
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    // Updates the current user's password
    func updatePassword(password: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        
        try await user.updatePassword(to: password)
    }
    
    // Resends email verification to the current user
    func resendEmailVerification() throws {
        guard let user = Auth.auth().currentUser else {
            throw CustomAuthenticationErrors.userNotFound
        }
        
        user.sendEmailVerification { error in
            if let error = error {
                print("Error resending verification email: \(error.localizedDescription)")
            } else {
                print("Verification email resent successfully.")
            }
        }
    }
    
    // Sends a verification email and then updates the user's email address
    func updateEmail(email: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user.sendEmailVerification(beforeUpdatingEmail: email) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

//SignIn SSO Functions

extension AuthenticationManager {
    
    // Signs in a user with Google credentials
    @discardableResult
    func signInWithGoogle(tokens: GoogleSignInResultModel) async throws -> AuthDataResultModel {
        let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
        return try await signIn(credential: credential)
    }
    
    // Signs in a user with Apple credentials
    @discardableResult
    func signInWithApple(tokens: SignInWithAppleResult) async throws -> AuthDataResultModel {
        let credential = OAuthProvider.credential(withProviderID: AuthProviderOption.apple.rawValue, idToken: tokens.token, rawNonce: tokens.nonce)
        return try await signIn(credential: credential)
    }
    
    // Signs in a user with the provided Firebase AuthCredential
    func signIn(credential: AuthCredential) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().signIn(with: credential)
        return AuthDataResultModel(user: authDataResult.user)
    }
}

extension AuthenticationManager {
    
    // Reauthenticates the user using email and password
    func reauthenticateUser(email:String, password: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw CustomAuthenticationErrors.userNotFound
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        do {
            try await user.reauthenticate(with: credential)
        } catch {
            throw CustomAuthenticationErrors.unknownError(error.localizedDescription)
        }
    }
    
    // Signs in the user anonymously
    @discardableResult
    func signInAnonymous() async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().signInAnonymously()
        return AuthDataResultModel(user: authDataResult.user)
    }
    
    // Links an email/password credential to the current user
    func linkEmail(email: String, password: String) async throws -> AuthDataResultModel {
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        return try await linkCredential(credential: credential)
    }
    
    // Links Apple credentials to the current user
    func linkApple(tokens: SignInWithAppleResult) async throws -> AuthDataResultModel {
        let credential = OAuthProvider.credential(withProviderID: AuthProviderOption.apple.rawValue, idToken: tokens.token, rawNonce: tokens.nonce)
        return try await linkCredential(credential: credential)
    }
    
    // Links Google credentials to the current user
    func linkGoogle(tokens: GoogleSignInResultModel) async throws -> AuthDataResultModel {
        let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
        return try await linkCredential(credential: credential)
    }
    
    // Links a generic credential to the current user
    private func linkCredential(credential: AuthCredential) async throws -> AuthDataResultModel {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badURL)
        }
        
        let authDataResult = try await user.link(with: credential)
        return AuthDataResultModel(user: authDataResult.user)
    }
}
