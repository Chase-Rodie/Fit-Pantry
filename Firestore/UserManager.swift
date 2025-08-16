//
//  UserManager.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 2/3/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

//Users gender options
enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case nonBinary = "Non-binary"
    case other = "Other"
    case preferNotToSay = "Prefer not to say"
}

//Users fitness level
enum FitnessLevel: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}

//Users fitness goals
enum Goal: String, Codable, CaseIterable {
    case loseWeight = "LoseWeight"
    case gainWeight = "GainWeight"
    case maintainWeight = "MaintainWeight"
}

//Stores user profile details
struct UserProfile: Codable, Equatable {
    var name: String?
    var age: Int?
    var gender: Gender?
    var fitnessLevel: FitnessLevel?
    var goal: Goal?
    var height: String?
    var weight: String?
    var profileImagePath: String?
    var profileImagePathUrl: String?
    var dietaryPreferences: [String]?
    var allergies: [String]?
}

//Firebase metadata
struct UserMetadata: Codable, Equatable {
    var userId: String
    var email: String?
    var isAnonymous: Bool?
    var photoUrl: String?
    var dateCreated: Date?
}

//Main user object stored in Firebase
struct DBUser: Decodable, Equatable {
    var metadata: UserMetadata
    var profile: UserProfile
    
    var profileImagePathUrl: String? {
        return profile.profileImagePathUrl
    }

    enum CodingKeys: String, CodingKey {
        case metadata
        case profile
        case profileImagePath
        case profileImagePathUrl
    }
    
    enum MetadataKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case isAnonymous = "is_anonymous"
        case photoUrl = "photo_url"
        case dateCreated = "date_created"
    }

    enum ProfileKeys: String, CodingKey {
        case name
        case age
        case gender
        case fitnessLevel = "fitnessLevel"
        case goal
        case height
        case weight
        case profileImagePath
        case profileImagePathUrl
        case dietaryPreferences
        case allergies
    }
    
    //Initialize DBUser
    init(auth: AuthDataResultModel) {
        self.metadata = UserMetadata(
            userId: auth.uid,
            email: auth.email,
            isAnonymous: auth.isAnonymous,
            photoUrl: auth.photoUrl,
            dateCreated: Date()
        )
        self.profile = UserProfile(
            name: nil,
            age: nil,
            gender: nil,
            fitnessLevel: nil,
            goal: nil,
            height: nil,
            weight: nil,
            profileImagePath: nil,
            profileImagePathUrl: nil,
            dietaryPreferences: nil,
            allergies: nil
        )
    }

    init(metadata: UserMetadata, profile: UserProfile) {
        self.metadata = metadata
        self.profile = profile
    }
    
    //Decode DBUser using containers
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let metadataContainer = try container.nestedContainer(keyedBy: MetadataKeys.self, forKey: .metadata)
        let userId = try metadataContainer.decode(String.self, forKey: .userId)
        let email = try metadataContainer.decode(String?.self, forKey: .email)
        let isAnonymous = try metadataContainer.decode(Bool?.self, forKey: .isAnonymous)
        let photoUrl = try metadataContainer.decode(String?.self, forKey: .photoUrl)
        let dateCreated = try metadataContainer.decodeIfPresent(Timestamp.self, forKey: .dateCreated)?.dateValue()
        
        self.metadata = UserMetadata(
            userId: userId,
            email: email,
            isAnonymous: isAnonymous,
            photoUrl: photoUrl,
            dateCreated: dateCreated
        )

        let profileContainer = try container.nestedContainer(keyedBy: ProfileKeys.self, forKey: .profile)
        let name = try profileContainer.decode(String?.self, forKey: .name)
        let age = try profileContainer.decode(Int?.self, forKey: .age)
        let genderRawValue = try profileContainer.decode(String?.self, forKey: .gender)
        let gender = genderRawValue.flatMap { Gender(rawValue: $0) }
        let fitnessLevelRawValue = try profileContainer.decode(String?.self, forKey: .fitnessLevel)
        let fitnessLevel = fitnessLevelRawValue.flatMap { FitnessLevel(rawValue: $0) }
        let goalRawValue = try profileContainer.decode(String?.self, forKey: .goal)
        let goal = goalRawValue.flatMap { Goal(rawValue: $0) }
        let height = try profileContainer.decode(String?.self, forKey: .height)
        let weight = try profileContainer.decode(String?.self, forKey: .weight)
        let profileImagePath = try profileContainer.decode(String?.self, forKey: .profileImagePath)
        let profileImagePathUrl = try profileContainer.decode(String?.self, forKey: .profileImagePathUrl)
        let dietaryPreferences = try profileContainer.decodeIfPresent([String].self, forKey: .dietaryPreferences)
        let allergies = try profileContainer.decodeIfPresent([String].self, forKey: .allergies)

        self.profile = UserProfile(
            name: name,
            age: age,
            gender: gender,
            fitnessLevel: fitnessLevel,
            goal: goal,
            height: height,
            weight: weight,
            profileImagePath: profileImagePath,
            profileImagePathUrl: profileImagePathUrl,
            dietaryPreferences: dietaryPreferences,
            allergies: allergies
        )
    }
}



extension DBUser {
    //Convets DBUser into dictionary
    func encodeToFirestore() -> [String: Any] {
        var data: [String: Any?] = [
            "userId": metadata.userId,
            "email": metadata.email,
            "isAnonymous": metadata.isAnonymous ?? false,
            "photoUrl": metadata.photoUrl,
            "dateCreated": metadata.dateCreated != nil ? Timestamp(date: metadata.dateCreated!) : FieldValue.serverTimestamp(),
            "name": profile.name,
            "age": profile.age,
            "gender": profile.gender?.rawValue,
            "fitnessLevel": profile.fitnessLevel?.rawValue,
            "goal": profile.goal?.rawValue,
            "height": profile.height,
            "weight": profile.weight
        ]

        return data.compactMapValues { $0 }
    }
}

@MainActor
final class UserManager: ObservableObject {
    static let shared = UserManager()

    @Published var currentUser: DBUser?

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private init() {
        Task {
            await fetchCurrentUser()
        }
    }

    private let userCollection: CollectionReference = Firestore.firestore().collection("users")

    //Returns reference to user's profile doc
    private func userDocument(userId: String) -> DocumentReference {
        return userCollection.document(userId).collection("UserInformation").document("profile")
    }
    
    //Returns reference to user's favorite products collection
    private func userPreferencesDocument(userId: String) -> DocumentReference {
        userCollection.document(userId).collection("UserInformation").document("preferences")
    }


    private func userFavoriteProductCollection(userId: String) -> CollectionReference {
        userDocument(userId: userId).collection("favorite_products")
    }

    func loadUserProfile(userId: String) async throws -> DBUser? {
        let user = try await UserManager.shared.getUserProfile(userId: userId)
        return user
    }
    
    //Creates metadata entry for new user
    func createUserMetadata(user: DBUser) async throws {
        let data: [String: Any] = [
            "user_id": user.metadata.userId,
            "email": user.metadata.email ?? "",
            "is_anonymous": user.metadata.isAnonymous ?? false,
            "photo_url": user.metadata.photoUrl ?? "",
            "date_created": user.metadata.dateCreated != nil ? Timestamp(date: user.metadata.dateCreated!) : FieldValue.serverTimestamp()
        ]
        try await Firestore.firestore().collection("users").document(user.metadata.userId).setData(data, merge: true)
    }
    
    //Full user document
    func createNewUser(user: DBUser) async throws {
        try await createUserMetadata(user: user)

        let profileData: [String: Any] = [
            "name": user.profile.name ?? "",
            "age": user.profile.age ?? 0,
            "gender": user.profile.gender?.rawValue ?? "",
            "fitnessLevel": user.profile.fitnessLevel?.rawValue ?? "",
            "goal": user.profile.goal?.rawValue ?? "",
            "height": user.profile.height ?? "",
            "weight": user.profile.weight ?? "",
            "profileImagePath": user.profile.profileImagePath ?? "",
            "profileImagePathUrl": user.profile.profileImagePathUrl ?? ""
        ]

        try await userDocument(userId: user.metadata.userId).setData(profileData)
    }

    //Both metadata and profile data
    func getFullUser(userId: String) async throws -> (meta: [String: Any], profile: DBUser?) {
        let db = Firestore.firestore()

        let metaRef = db.collection("users").document(userId)
        let metaSnapshot = try await metaRef.getDocument()
        let metadata = metaSnapshot.data() ?? [:]

        let profileRef = metaRef.collection("UserInformation").document("profile")
        let profileSnapshot = try await profileRef.getDocument()

        let profile: DBUser?
        if profileSnapshot.exists {
            profile = try? profileSnapshot.data(as: DBUser.self)
        } else {
            profile = nil
        }

        return (meta: metadata, profile: profile)
    }

    //Reference to a single favorite product doc
    private func userFavoriteProductDocument(userId: String, favoriteProductId: String) -> DocumentReference {
        userFavoriteProductCollection(userId: userId).document(favoriteProductId)
    }
    
    private let encoder: Firestore.Encoder = Firestore.Encoder()
    private let decoder: Firestore.Decoder = Firestore.Decoder()
    
    //Full user profile from firbebase
    func getUserProfile(userId: String) async throws -> DBUser {
         let db = Firestore.firestore()

         let metaDoc = try await db.collection("users").document(userId).getDocument()
         let metaData = metaDoc.data() ?? [:]

         var cleanedMetaData = metaData

         let profileDoc = try await db.collection("users").document(userId)
             .collection("UserInformation")
             .document("profile")
             .getDocument()

         let profileData = profileDoc.data() ?? [:]

         let combined: [String: Any] = [
             "metadata": cleanedMetaData,
             "profile": profileData
         ]

         do {
             let decoder = Firestore.Decoder()
             let user = try decoder.decode(DBUser.self, from: combined)
             return user
         } catch {
             print("Decoding error: \(error)")
             throw NSError(domain: "UserManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to decode user profile data"])
         }
     }
    
    //not used
    func updateUserProfileImagePath(userId: String, path: String?, url: String?) async throws {
        let data: [String: Any] = [
            DBUser.CodingKeys.profileImagePath.rawValue: path,
            DBUser.CodingKeys.profileImagePathUrl.rawValue: url
        ]

        try await userDocument(userId: userId).updateData(data)
    }
    
    //Merges profile updates into Firestore
    func updateUserProfile(user: DBUser) async throws {
        let profileData: [String: Any] = [
            "name": user.profile.name ?? "",
            "age": user.profile.age ?? 0,
            "gender": user.profile.gender?.rawValue ?? "",
            "fitnessLevel": user.profile.fitnessLevel?.rawValue ?? "",
            "goal": user.profile.goal?.rawValue ?? "",
            "height": user.profile.height ?? "",
            "weight": user.profile.weight ?? "",
            "profileImagePath": user.profile.profileImagePath ?? "",
            "profileImagePathUrl": user.profile.profileImagePathUrl ?? "",
            "dietaryPreferences": user.profile.dietaryPreferences ?? [],
            "allergies": user.profile.allergies ?? []
        ]

        try await userDocument(userId: user.metadata.userId).setData(profileData, merge: true)
    }

    //not used
    func fetchProfileImageUrl(userId: String) async throws -> String? {
        guard let user = currentUser else {
            throw NSError(domain: "UserManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }

        return user.profileImagePathUrl
    }
    
    //updates user's dietary preferences and allergies
    func getUserPreferences(userId: String) async throws -> (dietaryPreferences: [String], allergies: [String]) {
        let snapshot = try await userPreferencesDocument(userId: userId).getDocument()
        let data = snapshot.data() ?? [:]

        let dietaryPreferences = data["dietaryPreferences"] as? [String] ?? []
        let allergies = data["allergies"] as? [String] ?? []

        return (dietaryPreferences, allergies)
    }

    //loads currently autenticated user's profile into memory
    func updateUserPreferences(userId: String, dietaryPreferences: [String], allergies: [String]) async throws {
        let data: [String: Any] = [
            "dietaryPreferences": dietaryPreferences,
            "allergies": allergies
        ]

        try await userPreferencesDocument(userId: userId).setData(data, merge: true)
    }



    @MainActor
    func fetchCurrentUser() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No Firebase user ID found")
            return
        }

        do {
            let user = try await getUserProfile(userId: userId)
            DispatchQueue.main.async {
                self.currentUser = user
            }
        } catch {
            print("Error fetching user: \(error.localizedDescription)")
        }
    }
}
