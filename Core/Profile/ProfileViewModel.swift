//
//  ProfileViewModel.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 2/5/25.

import Foundation
import SwiftUI
import PhotosUI

@MainActor
final class ProfileViewModel: ObservableObject {
    
    @Published var user: DBUser?
    @Published var dietaryPreferences: [String] = []
    @Published var allergies: [String] = []
    @Published var hasLoaded = false
           
    //checks to see if a current user can be found
    func loadCurrentUser() async throws {
        guard !hasLoaded else { return }
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        let fetchedUser = try await UserManager.shared.getUserProfile(userId: authDataResult.uid)
        let prefs = try await UserManager.shared.getUserPreferences(userId: authDataResult.uid)
        
        await MainActor.run{
            self.user = fetchedUser
            self.dietaryPreferences = prefs.dietaryPreferences
            self.allergies = prefs.allergies
            self.hasLoaded = true
        }
    }

    //updates users profile
    func updateUserProfile(user: DBUser) async throws {
        try? await UserManager.shared.updateUserProfile(user: user)
        DispatchQueue.main.async {
            self.user = user
        }
    }
    
    //not used
    func saveProfileImage(item: PhotosPickerItem) {
        guard let user else { return }

        Task {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }
            let (path, name) = try await StorageManager.shared.saveImage(data: data, userId: user.metadata.userId)
            let url = try await StorageManager.shared.getUrlForImage(path: path)
            try await UserManager.shared.updateUserProfileImagePath(userId: user.metadata.userId, path: path, url: url.absoluteString)
        }
    }
    
    //not used
    func deleteProfileImage() {
        guard let user, let path = user.profile.profileImagePath else { return }

        Task {
            try await StorageManager.shared.deleteImage(path: path)
            try await UserManager.shared.updateUserProfileImagePath(userId: user.metadata.userId, path: nil, url: nil)
        }
    }
    
    //updates dietary preferences
    func updatePreferences(dietary: [String], allergies: [String]) async throws {
        guard let userId = user?.metadata.userId else { return }
        try await UserManager.shared.updateUserPreferences(userId: userId, dietaryPreferences: dietary, allergies: allergies)

        self.dietaryPreferences = dietary
        self.allergies = allergies
    }
}
