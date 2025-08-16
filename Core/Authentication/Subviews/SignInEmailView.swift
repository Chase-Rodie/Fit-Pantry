//
//  SignInEmailView.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 11/23/24.
//

import SwiftUI

struct SignInEmailView: View {
    
    @StateObject private var viewModel = SignInEmailViewModel()
    @Binding var showSignInView: Bool
    @State private var resetEmail: String = ""
    @State private var showResetAlert = false
    @State private var resetMessage: String = ""
    @State private var errorMessage: String?
    @State private var showPassword: Bool = false  
    
    var body: some View {
        VStack {
            // Email Input Field
            TextField("Email...", text: $viewModel.email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding()
                .background(Color.gray.opacity(0.4))
                .cornerRadius(10)
            
            // Password Input Field with Eye Icon
            HStack {
                if showPassword {
                    TextField("Password...", text: $viewModel.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding()
                } else {
                    SecureField("Password...", text: $viewModel.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding()
                }
                
                // Eye icon for toggling password visibility
                Button(action: {
                    showPassword.toggle()
                }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                        .padding(.trailing, 10)
                }
            }
            .background(Color.gray.opacity(0.4))
            .cornerRadius(10)
            
            // Error Message Display
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Sign In Button
            Button {
                Task {
                    do {
                        try await viewModel.signIn()
                        showSignInView = false
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            } label: {
                Text("Sign In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 55)
                    .frame(width: 360)
                    .background(Color.green)
                    .cornerRadius(10)
            }
            
            // Forgot Password Button
            Button(action: {
                resetEmail = viewModel.email
                showResetAlert = true
            }) {
                Text("Forgot Password?")
                    .font(.body)
                    .foregroundColor(.blue)
                    .underline()
                    .padding(.top, 5)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Sign In With Email")
        .alert("Reset Password", isPresented: $showResetAlert) {
            Button("Send Reset Link") {
                Task {
                    do {
                        try await viewModel.resetPassword(email: resetEmail)
                        resetMessage = "A reset link has been sent to your email."
                    } catch {
                        resetMessage = "Failed to send reset link. Please check your email."
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(resetMessage)
        }
    }
}

struct SignInEmailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SignInEmailView(showSignInView: .constant(false))
        }
    }
}
