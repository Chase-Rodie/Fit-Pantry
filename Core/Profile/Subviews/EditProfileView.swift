//
//  EditProfileView.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 2/11/25.
//

import FirebaseFirestore
import FirebaseAuth
import SwiftUI

struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var showProfilePopup: Bool
    @State private var editedUser: DBUser?
    @State private var showSavedMessage = false

    
    // New States for Height
    @State private var feet = 5
    @State private var inches = 8
    
    // New State for Weight
    @State private var weightInput = ""
    
    var body: some View {
        Form {
            if let _ = editedUser {
                Section(header: Text("Personal Information")) {
                    
                    TextField("Name", text: Binding(
                        get: { editedUser?.profile.name ?? "" },
                        set: { editedUser?.profile.name = $0 }
                    ))
                    
                    TextField("Age", text: Binding(
                        get: { editedUser?.profile.age.map { "\($0)" } ?? "" },
                        set: { editedUser?.profile.age = Int($0) }
                    ))
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    /*
                    TextField("Gender", text: Binding(
                        get: { editedUser?.profile.gender?.rawValue ?? "" },
                        set: { editedUser?.profile.gender = Gender(rawValue: $0) }
                    ))
                    */
                    
                    Picker("Gender", selection: Binding(
                        get: { editedUser?.profile.gender?.rawValue ?? "" },
                        set: { editedUser?.profile.gender = Gender(rawValue: $0) }
                    )) {
                        Text("Female").tag("Female")
                        Text("Male").tag("Male")
                        Text("Non-binary").tag("Non-binary")
                        Text("Other").tag("Other")
                        Text("Prefer not to say").tag("Prefer not to say")
                    }
                    
                    Picker("Fitness Level", selection: Binding(
                        get: { editedUser?.profile.fitnessLevel?.rawValue ?? "" },
                        set: { editedUser?.profile.fitnessLevel = FitnessLevel(rawValue: $0) }
                    )) {
                        Text("Beginner").tag("Beginner")
                        Text("Intermediate").tag("Intermediate")
                        Text("Advanced").tag("Advanced")
                    }
                    
                    Picker("Fitness Goal", selection: Binding(
                        get: { editedUser?.profile.goal?.rawValue ?? "" },
                        set: { editedUser?.profile.goal = Goal(rawValue: $0) }
                    )) {
                        Text("Lose Weight").tag("LoseWeight")
                        Text("Gain Weight").tag("GainWeight")
                        Text("Maintain Weight").tag("MaintainWeight")
                    }

                    //VStack(alignment: .leading, spacing: 10) {
                    //    Text("Height")

                        HStack {
                            Text("Height")
                            Picker("", selection: $feet) {
                                ForEach(1...8, id: \.self) { foot in
                                    Text("\(foot) ft").tag(foot)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())

                            Picker("", selection: $inches) {
                                ForEach(0...11, id: \.self) { inch in
                                    Text("\(inch) in").tag(inch)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    //}

                    //VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Weight (lbs)")
                        
                        TextField("Weight", text: $weightInput)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: weightInput) { newValue in
                                validateWeightInput(newValue)
                            }
                    }
                }

                Button(action: {
                    Task {
                        await saveProfile()
                        setProfileCompleted()
                        showProfilePopup = false
                        showSavedMessage = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showSavedMessage = false
                        }
                    }
                }) {
                    Text("Save Changes")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("BackgroundColor"))
                        .cornerRadius(10)
                }
                .frame(maxWidth: .infinity)
                
                if showSavedMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Profile saved!")
                            .foregroundColor(.green)
                            .font(.headline)
                    }
                    .padding(.top, 8)
                    .transition(.opacity)
                }


            } else {
                Text("Loading profile...").foregroundColor(.gray)
            }
        }

        .navigationTitle("Edit Profile")
        .onAppear {
            Task {
                await loadUser()
            }
        }
        .onChange(of: viewModel.user) { _ in
            self.editedUser = viewModel.user
        }
    }
    
    private func loadUser() async {
        do {
            try await viewModel.loadCurrentUser()
            DispatchQueue.main.async {
                if let user = viewModel.user {
                    self.editedUser = user
                    print("EditProfileView received user data: \(user)")
                    
                    if let heightString = user.profile.height {
                        let components = heightString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                        if components.count == 2,
                           let f = Int(components[0]),
                           let i = Int(components[1]) {
                            self.feet = f
                            self.inches = i
                        }
                    }
                    
                    self.weightInput = user.profile.weight ?? ""
                    
                } else {
                    print("EditProfileView: No user data received.")
                }
            }
        } catch {
            print("Error loading user: \(error)")
        }
    }
    
    private func saveProfile() async {
        guard var updatedUser = editedUser else {
            print("No user data to save")
            return
        }
        
        // Save height and weight correctly
        updatedUser.profile.height = "\(feet), \(inches)"
        updatedUser.profile.weight = weightInput
        
        do {
            try await viewModel.updateUserProfile(user: updatedUser)
            print("Successfully updated profile: \(updatedUser)")
            await loadUser()
            DispatchQueue.main.async {
                viewModel.user = updatedUser
            }
        } catch {
            print("Error updating profile: \(error)")
        }
    }

    private func validateWeightInput(_ input: String) {
        let filtered = input.filter { "0123456789.".contains($0) }
        let decimalParts = filtered.split(separator: ".")
        
        if decimalParts.count > 2 {
            weightInput = String(decimalParts[0]) + "." + String(decimalParts[1])
        } else {
            weightInput = filtered
        }
    }
    
    func setProfileCompleted() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "profileCompleted": true
        ]) { error in
            if let error = error {
                print("Error updating profileCompleted: \(error)")
            } else {
                print("Profile marked as completed after edit!")
            }
        }
    }



}
