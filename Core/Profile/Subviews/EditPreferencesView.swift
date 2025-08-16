//
//  EditPreferencesView.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 4/19/25.
//

import SwiftUI

struct EditPreferencesView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss

    @State private var dietaryPreferences: [String] = []
    @State private var allergies: [String] = []
    @State private var dietaryInput = ""
    @State private var allergyInput = ""

    var body: some View {
        Form {
            Section(header: Text("Dietary Preferences")) {
                ForEach(dietaryPreferences, id: \.self) { item in
                    Text(item)
                }
                HStack {
                    TextField("Add preference", text: $dietaryInput)
                    Button("Add") {
                        guard !dietaryInput.isEmpty else { return }
                        dietaryPreferences.append(dietaryInput)
                        dietaryInput = ""
                    }
                    .foregroundColor(Color("BackgroundColor")) // Change text color to BackgroundColor
                }
            }

            Section(header: Text("Allergies")) {
                ForEach(allergies, id: \.self) { item in
                    Text(item)
                }
                HStack {
                    TextField("Add allergy", text: $allergyInput)
                    Button("Add") {
                        guard !allergyInput.isEmpty else { return }
                        allergies.append(allergyInput)
                        allergyInput = ""
                    }
                    .foregroundColor(Color("BackgroundColor")) // Change text color to BackgroundColor
                }
            }

            Button("Save Preferences") {
                Task {
                    await savePreferences()
                }
            }
            .foregroundColor(Color("BackgroundColor")) // Change text color to BackgroundColor
        }
        .navigationTitle("Edit Preferences")
        .onAppear {
            Task {
                await loadPreferences()
            }
        }
    }

    private func loadPreferences() async {
        guard let userId = viewModel.user?.metadata.userId else { return }
        do {
            let prefs = try await UserManager.shared.getUserPreferences(userId: userId)
            dietaryPreferences = prefs.dietaryPreferences
            allergies = prefs.allergies
        } catch {
            print("Error loading preferences: \(error)")
        }
    }

    private func savePreferences() async {
        guard let userId = viewModel.user?.metadata.userId else { return }
        do {
            try await UserManager.shared.updateUserPreferences(userId: userId, dietaryPreferences: dietaryPreferences, allergies: allergies)
            dismiss()
        } catch {
            print("Error saving preferences: \(error)")
        }
    }
}
