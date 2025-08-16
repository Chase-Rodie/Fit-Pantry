//
//  RootView.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 11/23/24.
//

import SwiftUI
import FirebaseAuth

struct RootView: View {

    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var mealManager: TodayMealManager
    @State private var showSignInView: Bool = false
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        ZStack {
            // Show the main content only if the user is signed in
            if !showSignInView {
                TempContentView(showSignInView: $showSignInView, viewModel: viewModel)
            }
        }
        .onAppear {
            // Check if there's an authenticated user when the view appears
            let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
            self.showSignInView = authUser == nil

            // Request HealthKit access when the app loads
            HealthKitManager.shared.requestAuthorization { success in
                print(success ? "HealthKit Authorized!" : "HealthKit Not authorized")
            }
        }
        .fullScreenCover(isPresented: $showSignInView) {
            // Show the authentication screen in full-screen mode if needed
            NavigationStack {
                AuthenticationView(showSignInView: $showSignInView)
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}

