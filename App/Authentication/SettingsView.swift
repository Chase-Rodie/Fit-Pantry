//
//  SettingsView.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 11/23/24.
//

import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    
    @Published var authProviders: [AuthProviderOption] = []
    @Published var authUser: AuthDataResultModel? = nil
    
    func loadAuthProviders() {
        if let providers = try? AuthenticationManager.shared.getcurrentEmailProvider() {
            authProviders = providers
        }
    }
    
    func loadAuthUser() {
        self.authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
    }
    
    func signOut() throws {
        try AuthenticationManager.shared.signOut()
    }
    
    func resetPassword() async throws {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        
        guard let email = authUser.email else {
            throw URLError(.fileDoesNotExist)
        }
        
        try await AuthenticationManager.shared.resetPassword(email: email)
    }
    
    func updateEmail() async throws {
        let email = "helloemail@gmail.com"
        try await AuthenticationManager.shared.updateEmail(email: email)
    }
    
    func updatePassword() async throws {
        let password = "hello456"
        try await AuthenticationManager.shared.updatePassword(password: password)
    }
    
    func linkGoogleAccount() async throws {
        let helper = SignInGoogleHelper()
        let tokens = try await helper.signIn()
        let authDataResult = try await AuthenticationManager.shared.linkGoogle(tokens: tokens)
        self.authUser = authDataResult
    }
    
    func linkAppleAccount() async throws {
        let helper = SignInAppleHelper()
        let tokens = try await helper.startSignInWithAppleFlow()
        let authDataResult = try await AuthenticationManager.shared.linkApple(tokens: tokens)
        self.authUser = authDataResult
    }
    
    //Create UI for email, text fields with whole other screen
    func linkEmailAccount() async throws {
        let email = "hello234@gmail.com"
        let password = "Hello234@"
        let authDataResult = try await AuthenticationManager.shared.linkEmail(email: email, password: password)
        self.authUser = authDataResult
    }
    
    //Give user a warning to warn user action is permanent / reauthenticate (login)
    func deleteAccount() async throws {
        try await AuthenticationManager.shared.deleteUser()
    }
}

import SwiftUI

struct SettingsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    @Binding var showSignInView: Bool
    
    var body: some View {
        List {
            // Conditionally show Log Out and Delete Account buttons
            if !(viewModel.authUser?.isAnonymous ?? true) {
                Button("Log out") {
                    Task {
                        do {
                            try viewModel.signOut()
                            showSignInView = true
                        } catch {
                            print("Error during logout: \(error)")
                        }
                    }
                }
                
                Button(role: .destructive) {
                    Task {
                        do {
                            try await viewModel.deleteAccount()
                            print("Account Deleted")
                        } catch {
                            print("Error during account deletion: \(error)")
                        }
                    }
                } label: {
                    Text("Delete Account")
                }
            } else {
                // Show linking options for anonymous users
                anonymousSection
            }
            
            // Show email-related options if email is a provider
            if viewModel.authProviders.contains(.email) {
                emailSection
            }
        }
        .onAppear {
            viewModel.loadAuthProviders()
            viewModel.loadAuthUser()
        }
        .navigationBarTitle("Settings")
    }
}

extension SettingsView {
    
    private var emailSection: some View {
        Section {
            Button("Reset Password") {
                Task {
                    do {
                        try await viewModel.resetPassword()
                        print("Password Reset")
                    } catch {
                        print("Error resetting password: \(error)")
                    }
                }
            }
        
            Button("Update password") {
                Task {
                    do {
                        try await viewModel.updatePassword()
                        print("Updated Password")
                    } catch {
                        print("Error updating password: \(error)")
                    }
                }
            }
            
            Button("Update email") {
                Task {
                    do {
                        try await viewModel.updateEmail()
                        print("Updated Email")
                    } catch {
                        print("Error updating email: \(error)")
                    }
                }
            }
        } header: {
            Text("Email Functions")
        }
    }
    
    private var anonymousSection: some View {
        Section {
            Button("Link Email Account") {
                Task {
                    do {
                        try await viewModel.linkEmailAccount()
                        print("Linked Email Account")
                    } catch {
                        print("Error linking email account: \(error)")
                    }
                }
            }
            
            Button("Link Google Account") {
                Task {
                    do {
                        try await viewModel.linkGoogleAccount()
                        print("Linked Google Account")
                    } catch {
                        print("Error linking Google account: \(error)")
                    }
                }
            }
            
            Button("Link Apple Account") {
                Task {
                    do {
                        try await viewModel.linkAppleAccount()
                        print("Linked Apple Account")
                    } catch {
                        print("Error linking Apple account: \(error)")
                    }
                }
            }
        } header: {
            Text("Create Account")
        }
    }
}
    
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView(showSignInView: .constant(false))
        }
    }
}

//Instead of link buttons use actual UI sign in buttons that are on sign in screen (future implementation)
/*extension SettingsView {
    
    private var emailSection: some View{
        Section {
            Button("Reset Password") {
                Task {
                    do {
                        try await viewModel.resetPassword()
                        print("PASSWORD RESET")
                    } catch {
                        print(error)
                    }
                }
            }
        
            Button("Update password") {
                Task {
                    do {
                        try await viewModel.updatePassword()
                        print("Updated Password")
                    }catch {
                        print(error)
                    }
                }
            }
            Button("Update email") {
                Task {
                    do {
                        try await viewModel.updateEmail()
                        print("Updated Email")
                    }catch {
                        print(error)
                    }
                }
            }
            } header: {
                Text("Email functions")
        }
    }
    
    private var anonymousSection: some View{
        Section {
            Button("Link Email Account") {
                Task {
                    do {
                        try await viewModel.linkEmailAccount()
                        print("Linked Email Account")
                    } catch {
                        print(error)
                    }
                }
            }
        
            Button("Link Google Account") {
                Task {
                    do {
                        try await viewModel.linkGoogleAccount()
                        print("Linked Google Account")
                    }catch {
                        print(error)
                    }
                }
            }
            
            Button("Link Apple Account") {
                Task {
                    do {
                        try await viewModel.linkAppleAccount()
                        print("Linked Apple Account")
                    }catch {
                        print(error)
                    }
                }
            }
            } header: {
                Text("Create account")
        }
    }
}*/


//Have some sort of intermediate screen so that user can update password/email in app rather than signing in/out to reauthetnicate

//Also create custom errors rather than doing print(error)
