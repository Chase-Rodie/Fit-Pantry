//
//  ProfileView.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 12/2/24.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Binding var showSignInView: Bool
    @State private var selectedItem: PhotosPickerItem? = nil

    var body: some View {
        NavigationStack {
            List {
                if let user = viewModel.user {
                    // Profile management section if user is loaded
                    Section {
                        NavigationLink {
                            EditProfileView(viewModel: viewModel, showProfilePopup: .constant(false))
                        } label: {
                            Text("Edit Profile")
                        }

                        NavigationLink {
                            EditPreferencesView(viewModel: viewModel)
                        } label: {
                            Text("Edit Dietary Preferences & Allergies")
                        }
                    }
                } else {
                    // Show loading indicator while fetching user
                    ProgressView("Loading profile...")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .onAppear {
                // Load user data when the view appears
                Task {
                    do {
                        try await viewModel.loadCurrentUser()
                    } catch {
                        print("Error loading user in ProfileView: \(error.localizedDescription)")
                    }
                }
            }
            .onChange(of: selectedItem) { newValue in
                // If a new photo is selected, save it to the profile
                if let newValue {
                    viewModel.saveProfileImage(item: newValue)
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
