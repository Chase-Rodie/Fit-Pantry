//
//  SignUpEmailViewModel.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 3/1/25.
//

import Foundation
import FirebaseAuth

@MainActor
final class SignUpEmailViewModel: ObservableObject {
    
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""

    // In SignUpEmailViewModel
    func signUp() async throws -> AuthDataResultModel {
        return try await AuthenticationManager.shared.createUser(email: email, password: password)
    }
}


