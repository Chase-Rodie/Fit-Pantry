//
//  HomePageView.swift
//  Fit Pantry
//
//  Created by Lexie Reddon on 11/29/24.
//  Edited by Heather Amistani on 03/29/2025
//

//Views:
//HomePageView
//ProgressView
//LogProgressView?

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct HomePageView: View {
    @EnvironmentObject var mealManager: TodayMealManager
    @ObservedObject var viewModel: ProfileViewModel
    @ObservedObject var retrieveworkoutdata = RetrieveWorkoutData()
    @State private var progressValues: [Double] = Array(repeating: 1, count: 5)
    @State private var selectedDate: Date = Date()
    @State private var stepCount: Int = 0
    @State private var stepGoal: Int = 10000
    @Binding var showSignInView: Bool
    let dayIndex: Int = 1

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("Fit Pantry")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                
                NavigationLink(destination: ProfileView(showSignInView: $showSignInView)) {
                    Image(systemName: "person.circle")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
                
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    VStack(alignment: .leading, spacing: 10) {
                        StepCountBar(steps: stepCount, goal: stepGoal)
                            .padding(.top, 20)
//                        DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
//                            .datePickerStyle(.compact)
//                            .padding(.horizontal)
//                            .padding(.top, 20)
                        
                        Text("Workout Progress")
                            .font(.largeTitle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                        
                        ScrollView(.horizontal) {
                            HStack {
//                                ForEach(1..<7, id: \ .self) { dayIndex in
//                                    VStack(spacing: 20) {
//                                        NavigationLink(destination: ProgressView()) {
//                                            ProgressRingView(progress: progressValues[dayIndex], ringWidth: 15)
//                                                .padding()
//                                                .background(Color("BackgroundColor"))
//                                                .foregroundColor(.white)
//                                                .cornerRadius(10)
//                                        }
//                                        Text("Day \(dayIndex)")
//                                    }
//                                }
                                ForEach(0..<5, id: \.self) { index in
                                    VStack(spacing: 20) {
                                        NavigationLink(destination: CompletedWorkoutsView(
                                            dayIndex: index,
                                            workoutPlanModel: retrieveworkoutdata
                                        )) {
                                            ProgressRingView(progress: progressValues.indices.contains(index) ? progressValues[index] : 0.0, ringWidth: 15)
                                                .padding()
                                                .background(Color("BackgroundColor"))
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                        }
                                        Text("Day \(index + 1)")
                                    }
                                }
                            }.padding(.leading, 20)
                        }
                        
                        // Today's meals section title
                        Text("Today's Meals")
                            .font(.largeTitle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                        
                        // Horizontal scroll view of meal types (breakfast, lunch, dinner)
                        ScrollView(.horizontal) {
                            HStack(spacing: 20) {
                                ForEach(MealType.allCases, id: \.self) { type in
                                    NavigationLink(destination: TodayMealView(
                                        selectedDate: selectedDate,
                                        mealType: type,
                                        meals: Binding(
                                            get: { mealManager.getMeals(for: selectedDate, type: type) },
                                            set: { mealManager.setMeals(for: selectedDate, type: type, meals: $0) }
                                        ),
                                        onRemove: { removedMeal in
                                            let restoredAmountInPantryUnits = removedMeal.actualConsumedPantryAmount ?? 0.0

                                            print("Restoring \(restoredAmountInPantryUnits) \(removedMeal.unit ?? "g") for \(removedMeal.name) (saved consumed pantry amount)")
                                            
                                            // Restore pantry quantity for removed meal
                                            if !removedMeal.pantryDocID.isEmpty {
                                                updatePantryQuantity(docID: removedMeal.pantryDocID, amount: restoredAmountInPantryUnits)
                                            } else {
                                                print("⚠️ pantryDocID is empty for meal: \(removedMeal.name)")
                                            }
                                            
                                            // Remove the meal from Firestore log
                                            removeMealFromFirestore(removedMeal, for: selectedDate, type: type) {
                                                Task {
                                                    await mealManager.restoreMeals(for: selectedDate) {
                                                        print("Meals refreshed after deletion")
                                                    }
                                                }
                                            }
                                        }
                                    )
                                        .environmentObject(mealManager)
                                    ) {
                                        VStack {
                                            Image(type.rawValue)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 150, height: 150)
                                            Text(type.rawValue)
                                                .foregroundColor(.black)                                        }
                                    }
                                }
                            }.padding(.horizontal)
                        }
                        
                    }
                    .navigationBarBackButtonHidden(true)

                    // On appear: fetch workout progress and HealthKit step count
                    .onAppear {
                        fetchAllDaysProgress()

                        HealthKitManager.shared.requestAuthorization { success in
                            if success {
                                print("HealthKit authorized")
                                // Request HealthKit permissions and fetch today's step count
                                HealthKitManager.shared.fetchStepCount(for: Date()) { steps in
                                    if let steps = steps {
                                        DispatchQueue.main.async {
                                            self.stepCount = Int(steps)
                                            print("Step count fetched: \(steps)")
                                        }
                                    } else {
                                        print("Failed to fetch step count")
                                    }
                                }
                            } else {
                                print("Failed to authorize HealthKit")
                            }
                        }
                        // Load or reset workout plan
                        retrieveworkoutdata.workoutPlanExists { exists in
                            DispatchQueue.main.async {
                                if exists {
                                    retrieveworkoutdata.fetchWorkoutPlan()
                                } else {
                                    retrieveworkoutdata.workoutPlan = []
                                    resetProgressValues()
                                }
                            }
                        }
                    }

                }
            }
            .accentColor(.background)
        }
    }

    // Firestore helper to update pantry quantities
    private func updatePantryQuantity(docID: String, amount: Double) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No auth user found.")
            return
        }
        let docRef = Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("pantry")
            .document(docID)

        docRef.updateData(["quantity": FieldValue.increment(amount)])
    }
    
    // Reset all progress ring values to 0.0
    private func resetProgressValues() {
        progressValues = Array(repeating: 0.0, count: 5)
    }
    
    // Fetch workout progress for each of 5 days
    private func fetchAllDaysProgress() {
        for dayIndex in 0..<5 {
            retrieveworkoutdata.countCompletedAndTotalExercises(dayIndex: dayIndex + 1) { completed, total in
                let progress = total > 0 ? Double(completed) / Double(total) : 0.0
                
                DispatchQueue.main.async {
                    progressValues[dayIndex] = progress
                }
            }
        }
    }
    
    // Remove a meal from Firestore's mealLogs for the given day and type
    private func removeMealFromFirestore(_ meal: MealPlanner, for date: Date, type: MealType, completion: @escaping () -> Void){
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        let logRef = Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("mealLogs")
            .document(dateString)

        logRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  var array = data[type.rawValue.lowercased()] as? [[String: Any]] else {
                print("Could not get array to update or data is missing")
                return
            }

            array.removeAll {
                ($0["foodID"] as? String == meal.foodID) &&
                ($0["name"] as? String == meal.name)
            }

            logRef.updateData([
                type.rawValue.lowercased(): array
            ]) { error in
                if let error = error {
                    print("Error updating Firestore: \(error.localizedDescription)")
                } else {
                    print("Removed from Firestore successfully")
                }
                completion()
            }
        }
    }
}

// View that displays all completed workouts for a specific day
struct CompletedWorkoutsView: View {
    var dayIndex: Int
    @ObservedObject var workoutPlanModel: RetrieveWorkoutData
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Completed Workouts for Day \(dayIndex + 1)")
                .font(.largeTitle)
                .foregroundColor(Color("BackgroundColor"))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top)
                .padding(.horizontal)
            Divider()
                .padding(.horizontal)
            
            // Extract only completed exercises for the selected day
            let completedExercises = workoutPlanModel.workoutPlan.indices.contains(dayIndex) ?
            workoutPlanModel.workoutPlan[dayIndex].filter { workoutPlanModel.isExerciseCompleted(exercise: $0) } : []
            
            if completedExercises.isEmpty {
                VStack {
                    Text("No completed exercises yet!")
                        .foregroundColor(.gray)
                        .font(.title3)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // If there are completed exercises, display them in a scrollable list
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 15) {
                        ForEach(completedExercises) { exercise in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(exercise.name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("\(exercise.sets) Sets · \(exercise.reps) Reps")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                            .padding()
                            .background(Color("Navy"))
                            .cornerRadius(12)
                            .shadow(radius: 2)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            workoutPlanModel.loadCompletionStatuses()
        }
    }
}

struct HomePageView_Previews: PreviewProvider {
    static var previews: some View {
        HomePageView(
            viewModel: ProfileViewModel(),
            showSignInView: .constant(false)
        )
        .environmentObject(TodayMealManager())
    }
}
