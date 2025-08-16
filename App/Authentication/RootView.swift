//
//  RootView.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 11/23/24.
//

import SwiftUI

struct RootView: View {
    
    @State private var showSignInView: Bool = false
    @State private var showMenu: Bool = false
    
    var body: some View {
        ZStack {
            if !showSignInView {
                NavigationStack {
                    TempContentView()
                }
            }
        }
        .onAppear {
            // Force logout for testing
            do {
                try AuthenticationManager.shared.signOut()
                self.showSignInView = true
            } catch {
                print("Failed to sign out: \(error.localizedDescription)")
                self.showSignInView = true // Redirect even if there's an issue
            }
        }
        .fullScreenCover(isPresented: $showSignInView) {
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
