//
//  AuthenticationView.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 11/23/24.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct AuthenticationView: View {
    
    @StateObject private var viewModel = AuthenticationViewModel()
    @Binding var showSignInView: Bool
    @State private var isReturningUser: Bool = true  
    
    var body: some View {
        VStack {
            // Logo at the top
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .padding(.bottom, 20)
            
            // Toggle between "Returning User" and "New User"
            Picker("Authentication Type", selection: $isReturningUser) {
                Text("Sign In").tag(true)
                Text("Sign Up").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            // Email Authentication (Sign In / Sign Up)
            NavigationLink {
                if isReturningUser {
                    SignInEmailView(showSignInView: $showSignInView)
                } else {
                    SignUpEmailView(showSignInView: $showSignInView)
                }
            } label: {
                Text(isReturningUser ? "Sign In with Email" : "Sign Up with Email")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 375)
                    .background(Color.blue)
                    .cornerRadius(20)
                    .shadow(radius: 10)
            }
            .padding(.bottom, 15)
            
            // Google Sign-In Button
            Button {
                Task {
                    do {
                        try await viewModel.signInGoogle()
                        showSignInView = false
                        UserDefaults.standard.set("google", forKey: "loginMethod")
                    } catch {
                        print(error)
                    }
                }
            } label: {
                HStack {
                    Image("GoogleButton")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                    
                    Text("Sign in with Google")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Spacer()
                }
                .padding()
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.bottom, 15)
            
            // Apple Sign-In Button
            Button(action: {
                Task {
                    do {
                        try await viewModel.signInApple()
                        showSignInView = false
                        UserDefaults.standard.set("apple", forKey: "loginMethod")
                    } catch {
                        print(error)
                    }
                }
            }, label: {
                SignInWithAppleButtonViewRepresentable(type: .default, style: .black)
                    .allowsHitTesting(false)
            })
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.bottom, 15)
            
            HStack {
                Button(action: {
                    Task {
                        do {
                            try await viewModel.signInAnonymous()
                            showSignInView = false
                        } catch {
                            print(error)
                        }
                    }
                }, label: {
                    Text("Continue as Guest")
                        .font(.body)
                        .foregroundColor(.gray)
                        .underline()
                })
                Spacer()
            }
            .padding(.leading)
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AuthenticationView(showSignInView: .constant(false))
        }
    }
}
