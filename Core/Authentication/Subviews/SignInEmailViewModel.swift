//
//  SignInEmailViewModel.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 1/21/25.
//

import Foundation

@MainActor
final class SignInEmailViewModel: ObservableObject {
    
    @Published var email = ""
    @Published var password = ""
    
    //Uses email and password to sign in user
    func signIn() async throws {
        guard !email.isEmpty, !password.isEmpty else {
            throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Email and password cannot be empty."])
        }
        
        try await AuthenticationManager.shared.signInUser(email: email, password: password)
    }
    
    //allows user to reset their password
    func resetPassword(email: String) async throws {
        guard !email.isEmpty else {
            throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Please enter your email."])
        }
        
        try await AuthenticationManager.shared.resetPassword(email: email)
    }
}
