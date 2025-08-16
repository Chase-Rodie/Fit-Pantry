//
//  EmailVerificationView.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 3/21/25.
//

import SwiftUI
import FirebaseAuth

struct EmailVerificationView: View {
    @State private var isVerified = false
    @State private var errorMessage: String?
    @Binding var showSignInView: Bool
    @State private var showOnboarding = false

    var body: some View {
        NavigationStack {
            VStack {
                // Envelope image icon
                Image(systemName: "envelope.badge")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.background)

                // Header title
                Text("Verify Your Email")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 10)

                // Instructional text
                Text("We have sent a verification email to your inbox. Please verify your email before continuing.")
                    .multilineTextAlignment(.center)
                    .padding()

                // Display error messages, if any
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }

                // Button to check if the email has been verified
                Button("Check Verification Status") {
                    Task {
                        await checkVerificationStatus()
                    }
                }
                .padding()
                .background(Color.background)
                .foregroundColor(.white)
                .cornerRadius(10)

                // Button to resend the verification email
                Button("Resend Verification Email") {
                    resendVerificationEmail()
                }
                .padding(.top, 10)
                .foregroundColor(.background)

                // Hidden NavigationLink to move to onboarding if verification succeeds
                NavigationLink(destination: OnboardingView(showSignInView: $showSignInView), isActive: $showOnboarding) {
                    EmptyView()
                }
            }
            .padding()
        }
    }
    
    //checks to see if the user's email is verified
    func checkVerificationStatus() async {
        do {
            let user = Auth.auth().currentUser
            try await user?.reload()

            if user?.isEmailVerified == true {
                DispatchQueue.main.async {
                    self.showOnboarding = true
                }
                print("Email verified, moving to onboarding")
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Your email is not verified yet. Please check your inbox."
                }
                print("Email is not verified")
            }
        } catch {
            print("Failed to reload user: \(error.localizedDescription)")
        }
    }

    //resends email verification to current user
    func resendVerificationEmail() {
        let user = Auth.auth().currentUser
        user?.sendEmailVerification { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Error resending email: \(error.localizedDescription)"
                } else {
                    self.errorMessage = "Verification email sent again. Check your inbox!"
                }
            }
        }
    }
}
