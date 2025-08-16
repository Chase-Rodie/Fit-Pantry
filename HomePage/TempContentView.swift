//
//  TempContentView.swift
//  Fit Pantry
//
//  Created by Lexie Reddon on 11/30/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct TempContentView: View {
    @State private var selectedTab = 0
    @State var showMenu = false
    @Binding var showSignInView: Bool
    @State private var dragOffset: CGFloat = 0
    @State private var navigateToEditProfile = false
    @State private var showProfilePopup = false
    @ObservedObject var viewModel: ProfileViewModel
    @State private var profileCompleted = false


    var body: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                NavigationStack { FoodJournalView() }
                    .tabItem { Label("Food Journal", systemImage: "book.fill") }
                    .tag(2)

                    NavigationStack { MainWorkoutView() }
                        .tabItem { Label("Workout", systemImage: "figure.run") }
                        .tag(1)

                    NavigationStack { HomePageView(viewModel: viewModel, showSignInView: $showSignInView) }
                        .tabItem { Label("Home", systemImage: "house.fill") }
                        .tag(0)

                    NavigationStack { MealPlanView() }
                        .tabItem { Label("Meal", systemImage: "fork.knife.circle.fill") }
                        .tag(3)

                    NavigationStack {
                        ProfileView(showSignInView: $showSignInView)
                    }
                    .tabItem { Label("Profile", systemImage: "person.fill") }
                    .tag(4)

                    NavigationStack {
                        SettingsView(showSignInView: $showSignInView)
                    }
                    .tabItem { Label("Settings", systemImage: "gear") }
                    .tag(5)

                    NavigationStack {
                        GoalsView(user: UserMeal(
                            age: 24,
                            weightInLbs: 160,
                            heightInFeet: 5,
                            heightInInches: 10,
                            gender: "Male",
                            dietaryRestrictions: [],
                            goal: "Gain Weight",
                            activityLevel: "Active",
                            mealPreferences: []
                        ))
                    }
                    .tabItem { Label("Goals", systemImage: "target") }
                    .tag(6)

                    NavigationStack {
                        ShoppingListView()
                    }
                    .tabItem { Label("Shopping List", systemImage: "list.bullet") }
                    .tag(7)

                    NavigationStack {
                        PantryView()
                    }
                    .tabItem { Label("Pantry", systemImage: "cart") }
                    .tag(8)

                    NavigationStack {
                        FavoriteMealView()
                    }
                    .tabItem { Label("Favorite Meals", systemImage: "star") }
                        .tag(9)
                }
                .accentColor(Color("BackgroundColor"))
                .ignoresSafeArea(edges: .bottom)

                
                // Profile completion popup
                if showProfilePopup {
                    VStack {
                        Text("Would you like to complete your profile?")
                            .font(.headline)
                            .padding()

                        HStack {
                            Button("Yes") {
                                navigateToEditProfile = true
                                showProfilePopup = false
                                setProfileCompleted()
                            }
                            .padding()

                            Button("No") {
                                showProfilePopup = false
                                setProfileCompleted()
                            }
                            .padding()
                        }
                    }
                    .frame(width: 300, height: 200)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .padding(40)
                }
            }
            .onAppear {
                print("TempContentView appeared")

                // Manually clear the flag if the account was recreated
                if Auth.auth().currentUser?.uid != nil {
                    clearUserDefaultsOnAccountDeletion()
                }

                // Check for profile popup state only if the popup hasn't been dismissed
                if !UserDefaults.standard.bool(forKey: "profilePopupDismissed") {
                    print("Popup not dismissed before, checking profile completion")
                    checkProfileCompletion()
                } else {
                    print("Popup already dismissed previously.")
                }
            }

            // Navigation link to edit profile view
            NavigationLink(
                "",
                destination: EditProfileView(viewModel: viewModel, showProfilePopup: $showProfilePopup),
                isActive: $navigateToEditProfile
            )
            .hidden()
        }

    func checkProfileCompletion() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No Firebase user ID found")
            return
        }

        print("Checking profile completion for user: \(userId)")

        // Check if the user signed up with Google or Apple
        if let user = Auth.auth().currentUser {
            // Check provider data to see if the user signed in with Google or Apple
            if let provider = user.providerData.first(where: { $0.providerID == "google.com" }) {
                // User signed up with Google
                UserDefaults.standard.set("google", forKey: "loginMethod")
                print("User signed up with Google")
            } else if let provider = user.providerData.first(where: { $0.providerID == "apple.com" }) {
                // User signed up with Apple
                UserDefaults.standard.set("apple", forKey: "loginMethod")
                print("User signed up with Apple")
            } else {
                // User signed up with email/password
                UserDefaults.standard.set("email", forKey: "loginMethod")
                print("User signed up with email/password")
            }
        }

        // Only show the profile completion popup for Google or Apple users
        if let loginMethod = UserDefaults.standard.string(forKey: "loginMethod") {
            if loginMethod == "google" || loginMethod == "apple" {
                let db = Firestore.firestore()
                db.collection("users").document(userId).getDocument { document, error in
                    if let document = document, document.exists {
                        let data = document.data()
                        let profileCompleted = data?["profileCompleted"] as? Bool ?? false
                        print("Profile completion status: \(profileCompleted)")

                        // Only show the popup if profile is incomplete and user hasn't dismissed it before
                        if !profileCompleted && !UserDefaults.standard.bool(forKey: "profilePopupDismissed") {
                            self.showProfilePopup = true
                        } else {
                            print("Profile is already complete or popup has been dismissed.")
                        }
                    } else {
                        // If the document doesn't exist, initialize it and show the popup
                        print("No document found for user, initializing user data")
                        self.initializeUserData(userId: userId)
                    }
                }
            } else {
                print("Not a Google or Apple user, skipping popup.")
            }
        }
    }


    func setProfileCompleted() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "profileCompleted": true
        ]) { error in
            if let error = error {
                print("Error updating profileCompleted: \(error)")
            } else {
                print("Profile marked as completed.")
            }
        }

        // Save to UserDefaults that the user has dismissed the popup
        UserDefaults.standard.set(true, forKey: "profilePopupDismissed")
    }

    func initializeUserData(userId: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).setData([
            "profileCompleted": false
        ]) { error in
            if let error = error {
                print("Error initializing user data: \(error)")
            } else {
                print("User data initialized for new account.")
                // Show the popup if profile is incomplete and not dismissed before
                self.showProfilePopup = true
            }
        }
    }

    // Function to clear UserDefaults when account is deleted
    func clearUserDefaultsOnAccountDeletion() {
        UserDefaults.standard.removeObject(forKey: "profilePopupDismissed")
        UserDefaults.standard.removeObject(forKey: "loginMethod")
    }
}

struct TempContentView_Previews: PreviewProvider {
    static var previews: some View {
        TempContentView(showSignInView: .constant(false), viewModel: ProfileViewModel())
    }
}
