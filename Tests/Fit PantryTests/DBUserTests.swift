//
//  DBUserTests.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 2/27/25.
//

import XCTest
import FirebaseAuth
@testable import Fit_Pantry

class AuthenticationManagerTests: XCTestCase {
    var authManager: AuthenticationManager!
    
    override func setUp() {
        super.setUp()
        authManager = AuthenticationManager.shared
    }
    
    override func tearDown() {
        authManager = nil
        super.tearDown()
    }
    
    func testCreateUser_Success() async throws {
        let email = "testuser\(UUID().uuidString)@example.com"
        let password = "Secure@123"
        
        do {
            let user = try await authManager.createUser(email: email, password: password)
            XCTAssertNotNil(user.uid, "User ID should not be nil after successful registration.")
        } catch {
            XCTFail("Expected successful registration but got error: \(error)")
        }
    }
    
    func testCreateUser_PasswordTooWeak() async {
        let email = "weakpassworduser\(UUID().uuidString)@example.com"
        let weakPassword = "12345" // Less than 6 characters
        
        do {
            _ = try await authManager.createUser(email: email, password: weakPassword)
            XCTFail("Expected failure due to weak password, but succeeded.")
        } catch let error as NSError {
            print("Error Code: \(error.code) - \(error.localizedDescription)")
            XCTAssertTrue(error.code == AuthErrorCode.weakPassword.rawValue || error.code == 17999, "Unexpected error code: \(error.code)")
        }
    }
    
    func testCreateUser_EmailAlreadyInUse() async {
        let email = "existinguser@example.com"
        let password = "Secure@123"
        
        do {
            _ = try await authManager.createUser(email: email, password: password)
        } catch {  }

        do {
            _ = try await authManager.createUser(email: email, password: password)
            XCTFail("Expected failure due to duplicate email, but succeeded.")
        } catch let error as NSError {
            XCTAssertEqual(error.code, AuthErrorCode.emailAlreadyInUse.rawValue, "Expected email already in use error.")
        }
    }
    
    func testSendEmailVerification_Success() {
        do {
            try authManager.sendEmailVerification()
        } catch {
            XCTFail("Expected email verification to be sent successfully, but got error: \(error)")
        }
    }
}

