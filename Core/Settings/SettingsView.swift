//
//  SettingsView.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 11/23/24.
//
//  UI View for the user's settings page

import SwiftUI

struct SettingsView: View {

    @StateObject private var viewModel = SettingsViewModel()
    @Binding var showSignInView: Bool

    // Alerts for logout, account deletion, and reauthentication prompts
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false
    @State private var showReauthAlert = false

    // Temporary storage for reauthentication
    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        List {
            // Log out button, with special handling for anonymous users
            Button("Log out") {
                if viewModel.authUser?.isAnonymous == true {
                    showLogoutAlert = true
                } else {
                    Task {
                        do {
                            try await viewModel.signOut()
                            showSignInView = true
                        } catch {
                            print("Error signing out: \(error)")
                        }
                    }
                }
            }

            // Account deletion button
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Text("Delete Account")
            }

            // Email-related account management
            if viewModel.authProviders.contains(.email) {
                emailSection
            }

            // Options for anonymous users to link their account
            if viewModel.authUser?.isAnonymous == true {
                anonymousSection
            }

            // Preferences section (sound, vibration, notifications)
            preferencesSection
        }
        .onAppear {
            // Load authentication-related info when view appears
            viewModel.loadAuthProviders()
            viewModel.loadAuthUser()
        }
        .navigationBarTitle("Settings")

        // Alert: Warn guest user that logging out will delete data
        .alert("Warning", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteAccount()
                        showSignInView = true
                    } catch {
                        print("Error signing out: \(error)")
                    }
                }
            }
        } message: {
            Text("Logging out will permanently delete your data since you are signed in as a guest.")
        }

        // Alert: Confirm account deletion
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteAccount()
                        showSignInView = true
                    } catch {
                        print("Error deleting account: \(error)")
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }

        // Alert: Reauthentication prompt before critical actions
        .alert("Authentication Required", isPresented: $showReauthAlert) {
            TextField("Email", text: $email)
            SecureField("Password", text: $password)

            Button("Cancel", role: .cancel) { }
            Button("Reauthenticate") {
                Task {
                    do {
                        try await viewModel.reauthenticateUser(email: email, password: password)
                        try await viewModel.deleteAccount()
                        showSignInView = true
                    } catch {
                        print("Reauthentication failed: \(error)")
                    }
                }
            }
        } message: {
            Text("Please sign in again to confirm your identity before deleting your account.")
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


extension SettingsView {
    
    //sections for email/password functions
    private var emailSection: some View {
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
                    } catch {
                        print(error)
                    }
                }
            }

            Button("Update email") {
                Task {
                    do {
                        try await viewModel.updateEmail()
                        print("Updated Email")
                    } catch {
                        print(error)
                    }
                }
            }
        } header: {
            Text("Email functions")
        }
    }

    //section for anonymous users
    private var anonymousSection: some View {
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
                    } catch {
                        print(error)
                    }
                }
            }

            Button("Link Apple Account") {
                Task {
                    do {
                        try await viewModel.linkAppleAccount()
                        print("Linked Apple Account")
                    } catch {
                        print(error)
                    }
                }
            }
        } header: {
            Text("Create account")
        }
    }
    
    //sections for notifications, sound, and vibration
    private var preferencesSection: some View {
        Section(header: Text("Preferences")) {
            VStack {
                Toggle("Enable Sound", isOn: $viewModel.soundEnabled)
                Toggle("Enable Vibration", isOn: $viewModel.vibrationEnabled)
                Toggle("Enable Notifications", isOn: $viewModel.notificationsEnabled)
                    .onChange(of: viewModel.notificationsEnabled) { enabled in
                        viewModel.requestNotificationPermission()
                    }
                }
        }
    }
}
    
