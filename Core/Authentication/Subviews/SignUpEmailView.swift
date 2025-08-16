//
//  SignUpEmailView.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 3/1/25.
//

import SwiftUI

struct SignUpEmailView: View {
    
    @StateObject private var viewModel = SignUpEmailViewModel()
    @Binding var showSignInView: Bool
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var emailErrorMessage: String? = nil
    @State private var passwordErrorMessage: String? = nil
    @State private var confirmPasswordErrorMessage: String? = nil
    @State private var showEmailVerificationView = false

    var body: some View {
        VStack {
            // Email Input
            TextField("Email...", text: $viewModel.email)
                .padding()
                .background(Color.gray.opacity(0.4))
                .cornerRadius(10)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .onChange(of: viewModel.email) { _ in
                    emailErrorMessage = nil
                }
            
            // Email Error Message
            if let emailErrorMessage = emailErrorMessage {
                Text(emailErrorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            // Password Input
            HStack {
                if showPassword {
                    TextField("Password...", text: $viewModel.password)
                } else {
                    SecureField("Password...", text: $viewModel.password)
                        .textContentType(.oneTimeCode)
                }
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.4))
            .cornerRadius(10)
            
            // Confirm Password Input
            HStack {
                if showConfirmPassword {
                    TextField("Confirm Password...", text: $viewModel.confirmPassword)
                } else {
                    SecureField("Confirm Password...", text: $viewModel.confirmPassword)
                        .textContentType(.oneTimeCode)
                }
                Button(action: { showConfirmPassword.toggle() }) {
                    Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.4))
            .cornerRadius(10)

            // Password Error Message
            if let passwordErrorMessage = passwordErrorMessage {
                Text(passwordErrorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            // Confirm Password Error Message
            if let confirmPasswordErrorMessage = confirmPasswordErrorMessage {
                Text(confirmPasswordErrorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            // Sign Up Button
            Button {
                passwordErrorMessage = nil  // Reset previous error
                confirmPasswordErrorMessage = nil  // Reset previous confirm password error
                
                // Check if password is too simple
                if isPasswordTooSimple(viewModel.password) {
                    passwordErrorMessage = "Password must be at least 6 characters long and include at least one number and one special character."
                }
                // Check if password and confirm password match
                else if viewModel.password.isEmpty || viewModel.confirmPassword.isEmpty {
                    confirmPasswordErrorMessage = "Please fill out both password fields."
                }
                else if viewModel.password != viewModel.confirmPassword {
                    confirmPasswordErrorMessage = "Passwords do not match."
                } else {
                    Task {
                        do {
                            let user = try await viewModel.signUp()
                            
                            if !user.isEmailVerified {  // Now this will work
                                showEmailVerificationView = true  // Redirect to verification screen
                            } else {
                                showSignInView = false  // If email is already verified, go to sign-in
                            }
                        } catch let error as NSError {
                            passwordErrorMessage = error.localizedDescription  // Display Firebase error
                        }
                    }

                }
            } label: {
                Text("Sign Up")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Sign Up With Email")
        .navigationDestination(isPresented: $showEmailVerificationView) {
            EmailVerificationView(showSignInView: $showSignInView)
        }
    }
    
    private func isPasswordTooSimple(_ password: String) -> Bool {
        let regex = "^(?=.*[0-9])(?=.*[A-Za-z])(?=.*[!@#$%^&*(),.?\":{}|<>]).{6,}$"
        return password.range(of: regex, options: .regularExpression) == nil
    }
}

struct SignUpEmailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SignUpEmailView(showSignInView: .constant(false))
        }
    }
}
