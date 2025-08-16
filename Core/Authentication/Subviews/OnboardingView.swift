//
//  OnboardingView.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 3/27/25.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct OnboardingView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var currentStep: Int = 0
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var gender: String = ""
    @State private var fitnessLevel: String = ""
    @State private var goal: String = ""
    @State private var height: String = ""
    @State private var weight: String = ""
    @Binding var showSignInView: Bool
    @State private var onboardingComplete = false

    var body: some View {
        VStack {
            // Render step-specific view
            if currentStep == 0 {
                WelcomeStep()
            } else if currentStep == 1 {
                NameStep(name: $name)
            } else if currentStep == 2 {
                AgeStep(age: $age)
            } else if currentStep == 3 {
                GenderStep(gender: $gender)
            } else if currentStep == 4 {
                FitnessLevelStep(fitnessLevel: $fitnessLevel)
            } else if currentStep == 5 {
                GoalStep(goal: $goal)
            } else if currentStep == 6 {
                HeightStep(height: $height)
            } else if currentStep == 7 {
                WeightStep(weight: $weight)
            } else {
                CompletionStep()
            }

            // Navigation button
            Button(action: nextStep) {
                Text(currentStep < 8 ? "Next" : "Finish")
                    .padding()
                    .background(Color.background)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .onAppear {
            loadUserData()
        }
    }

    //advances to next step or finishes
    private func nextStep() {
        if currentStep < 7 {
            currentStep += 1
        } else if currentStep == 7 {
            currentStep += 1
        } else if currentStep == 8 {
            guard !onboardingComplete else { return }
            onboardingComplete = true

            Task {
                await saveUserData()
            }
        }
    }

    //preloads existing data
    private func loadUserData() {
        if let user = userManager.currentUser {
            name = user.profile.name ?? ""
            age = user.profile.age.map { String($0) } ?? ""
            gender = user.profile.gender?.rawValue ?? ""
            fitnessLevel = user.profile.fitnessLevel?.rawValue ?? ""
            goal = user.profile.goal?.rawValue ?? ""
            height = user.profile.height ?? ""
            weight = user.profile.weight ?? ""
        }
    }
    
    //saves users info to firebase
    @MainActor
    func saveUserData() async {
        guard let authUser = Auth.auth().currentUser else {
            print("No Firebase user found")
            return
        }

        guard let parsedAge = Int(age) else {
            print("Invalid age entered")
            return
        }

        let parsedGender = Gender(rawValue: gender)
        let parsedFitnessLevel = FitnessLevel(rawValue: fitnessLevel)
        let parsedGoal = Goal(rawValue: goal)

        let metadata = UserMetadata(
            userId: authUser.uid,
            email: authUser.email,
            isAnonymous: authUser.isAnonymous,
            photoUrl: authUser.photoURL?.absoluteString,
            dateCreated: Date()
        )

        let profile = UserProfile(
            name: name,
            age: parsedAge,
            gender: parsedGender,
            fitnessLevel: parsedFitnessLevel,
            goal: parsedGoal,
            height: height,
            weight: weight,
            profileImagePath: nil,
            profileImagePathUrl: nil
        )

        let newUser = DBUser(metadata: metadata, profile: profile)

        do {
            try await userManager.createNewUser(user: newUser)
            await userManager.fetchCurrentUser()
        } catch {
            print("Error creating new user: \(error)")
        }

        await MainActor.run {
            showSignInView = false
            onboardingComplete = true
        }
    }
}

struct WelcomeStep: View {
    var body: some View {
        Text("Welcome to Fit Pantry! Let’s set up your profile.")
            .font(.title)
            .multilineTextAlignment(.center)
    }
}

struct NameStep: View {
    @Binding var name: String
    var body: some View {
        VStack {
            Text("Enter your name")
            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
    }
}

struct AgeStep: View {
    @Binding var age: String
    var body: some View {
        VStack {
            Text("Enter your age")
            TextField("Age", text: $age)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
        }
        .padding()
    }
}

struct GenderStep: View {
    @Binding var gender: String
    var body: some View {
        VStack {
            Text("Enter your gender")
            Picker("Gender", selection: $gender) {
                Text("Female").tag("Female")
                Text("Male").tag("Male")
                Text("Non-binary").tag("Non-binary")
                Text("Other").tag("Other")
                Text("Prefer not to say").tag("Prefer not to say")
            }
            .pickerStyle(.menu)
        }
        .padding()
    }
}

struct FitnessLevelStep: View {
    @Binding var fitnessLevel: String
    var body: some View {
        VStack {
            Text("Select your fitness level")
            Picker("Fitness Level", selection: $fitnessLevel) {
                Text("Beginner").tag("Beginner")
                Text("Intermediate").tag("Intermediate")
                Text("Advanced").tag("Advanced")
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
    }
}

struct GoalStep: View {
    @Binding var goal: String
    var body: some View {
        VStack {
            Text("Enter your fitness goal")
            Picker("Fitness Goal", selection: $goal) {
                Text("Lose Weight").tag("LoseWeight")
                Text("Gain Weight").tag("GainWeight")
                Text("Maintain Weight").tag("MaintainWeight")
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
    }
}

struct HeightStep: View {
    @Binding var height: String
    @State private var selectedFeet = 5
    @State private var selectedInches = 6

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter your height")
                .font(.headline)

            HStack {
                Picker("Feet", selection: $selectedFeet) {
                    ForEach(3...8, id: \.self) { feet in
                        Text("\(feet) ft").tag(feet)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 100)

                Picker("Inches", selection: $selectedInches) {
                    ForEach(0...11, id: \.self) { inch in
                        Text("\(inch) in").tag(inch)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 100)
            }
            .onChange(of: selectedFeet) { _ in updateHeight() }
            .onChange(of: selectedInches) { _ in updateHeight() }
        }
        .onAppear {
            updateHeight()
        }
        .padding()
    }
    
    //updates height string
    private func updateHeight() {
        height = "\(selectedFeet), \(selectedInches)"
    }
}

struct WeightStep: View {
    @Binding var weight: String
    @State private var internalWeight = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter your weight (in pounds)")
                .font(.headline)

            TextField("Weight (lbs)", text: $internalWeight)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: internalWeight) { newValue in
                    validateWeightInput(newValue)
                }
        }
        .padding()
        .onAppear {
            internalWeight = weight
        }
    }
    
    //filters and updates weight input
    private func validateWeightInput(_ input: String) {
        let filtered = input.filter { "0123456789.".contains($0) }
        let decimalParts = filtered.split(separator: ".")

        if decimalParts.count > 2 {
            internalWeight = String(decimalParts[0]) + "." + String(decimalParts[1])
        } else {
            internalWeight = filtered
        }

        weight = internalWeight
    }
}

struct CompletionStep: View {
    var body: some View {
        Text("You're all set! Enjoy Fit Pantry.")
            .font(.title)
            .multilineTextAlignment(.center)
    }
}
