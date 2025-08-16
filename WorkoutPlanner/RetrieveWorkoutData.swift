//
//  RetrieveWorkoutData.swift
//  Fit Pantry
//
//  Created by Lexie Reddon on 11/26/24.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class RetrieveWorkoutData : ObservableObject {
    
    @Published var isWorkoutPlanAvailable:Bool = false
    //2D array for workoutplan
    @Published var workoutPlan : [[Exercise]] = []
    @Published var completedExercisesCounts: [Int] = []
    var workoutDays: [(String, [String])] = []
    @Published var workoutMetadata: [String: Any] = [:]
    @Published var manualWorkoutsToday: [ManualWorkout] = []
    
    
    
    let now = Date()
    
    //Saves workoutplan locally to userdefaults.
    func saveWorkoutPlanLocally(){
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(workoutPlan){
            UserDefaults.standard.set(encodedData, forKey: "workoutPlan")
        } else{
            print("Failed to encode exercises.")
        }
        
        UserDefaults.standard.set(workoutMetadata, forKey: "workoutMetadata")
    }
    
    //Fetches existing workoutplan from FireBase. Stores workoutplan to UserDefaults w/ the saveWorkoutPlanLocally function.
    func fetchWorkoutPlan() {
        
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }
        //get current date in correct format for document naming purposes
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-yyyy-'W'W"
        let formattedDate = dateFormatter.string(from: now)
        
        let db = Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("workoutplan")
            .document(formattedDate)
        
        var tempWorkoutPlan: [[Exercise]] = []
        
        db.getDocument{ document, error in
            if let error = error{
                print("Error fetching workout metadata:\(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists,
                  let workoutData = document.data() else{
                print("Workout metadata does not exist")
                return
            }
            self.workoutMetadata = workoutData

        }
        for i in 1...5 {
            db.collection("Day\(i)").getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching documents: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found for Day \(i)")
                    // group.leave()
                    return
                }
                
                var exercisesForDay: [Exercise] = []
                for document in documents {
                    let data = document.data()
                    
                    let exercise = Exercise(
                        category: data["category"] as? String ?? "",
                        equipment: data["equipment"] as? String ?? "",
                        force: data["force"] as? String ?? "",
                        id: document.documentID,
                        imageURLs: data["imageURLs"] as? [String] ?? [],
                        instructions: data["instructions"] as? [String] ?? [],
                        level: data["level"] as? String ?? "",
                        mechanic: data["mechanic"] as? String ?? "",
                        name: data["name"] as? String ?? "",
                        primaryMuscles: data["primaryMuscles"] as? [String] ?? [],
                        secondaryMuscles: data["secondaryMuscles"] as? [String] ?? [],
                        isComplete: data["isComplete"] as? Bool ?? false,
                        sets: data["sets"] as? Int ?? 3,
                        reps: data["reps"] as? Int ?? 10
                    )
                    self.saveExerciseCompletionStatus(exercise: exercise)

                    
                    exercisesForDay.append(exercise)
                    
                }
                if !exercisesForDay.isEmpty {
                    
                    DispatchQueue.main.async {
                        while tempWorkoutPlan.count < i {
                            tempWorkoutPlan.append([])
                        }
                        tempWorkoutPlan[i - 1] = exercisesForDay
                        print("Fetched \(exercisesForDay.count) exercises for Day \(i)")
                        self.workoutPlan = tempWorkoutPlan
                        self.saveWorkoutPlanLocally()  // Save locally after fetching
                    }
                }
            }
        }
        
    }
    
    //Marks a single exercise as complete. Then saves changes to UserDefaults and Firebase.
    func markComplete(for exercise: Exercise){
        for dayIndex in workoutPlan.indices{
            if let exerciseIndex = workoutPlan[dayIndex].firstIndex(where: { $0.id == exercise.id }){
                workoutPlan[dayIndex][exerciseIndex].isComplete.toggle()
                saveExerciseCompletionStatus(exercise: workoutPlan[dayIndex][exerciseIndex])
                updateExerciseCompletionInDB(exercise: workoutPlan[dayIndex][exerciseIndex], dayIndex: dayIndex)
                break
            }
        }
        
    }
    
    //Makes Query to firestore to build user's requested workout plan. Saves to Firebase and UserDefaults with separate function calls.
    func queryExercises(days: [(String, [String])], maxExercises: Int = 4, level: String, goal: String, completion: @escaping () -> Void)  {
        let db = Firestore.firestore()
        self.workoutDays = days
        
        var tempExercises: [[Exercise]] = Array(repeating: [], count: days.count)
        let (customSets, customReps) = self.getSetsAndReps(for: goal)
        
        let group = DispatchGroup()
        
        for(index,(type, primaryMuscle)) in days.enumerated(){
            group.enter()
            db.collection("exercises").whereField("force", isEqualTo: type).whereField("level", isEqualTo: level ).whereField("primaryMuscles", arrayContainsAny: primaryMuscle).limit(to: maxExercises*2).getDocuments{ snapshot, error in
                
                if error == nil{
                    print("No errors")
                    if let snapshot = snapshot{
                        let allExercises = snapshot.documents.compactMap{document -> Exercise? in
                            return Exercise(
                                category: document["category"] as? String ?? "",
                                equipment: document["equipment"] as? String ?? "",
                                force: document["force"] as? String ?? "",
                                id: document.documentID,
                                imageURLs: (document["imageURLs"] as? [String]) ?? [],
                                instructions: (document["instructions"] as? [String]) ?? [],
                                level: document["level"] as? String ?? "",
                                mechanic: document["mechanic"] as? String ?? "",
                                name: document["name"] as? String ?? "",
                                primaryMuscles: (document["primaryMuscles"] as? [String]) ?? [],
                                secondaryMuscles: (document["secondaryMuscles"] as? [String]) ?? [],
                                isComplete: document["isComplete"] as? Bool ?? false,
                                sets: customSets,
                                reps: customReps

                            )
                        }
                        
                        let randomizedExercises = allExercises.shuffled().prefix(maxExercises)
                        tempExercises[index] = Array(randomizedExercises)
                    }
                }
                group.leave()
            }
        }
        group.notify(queue: .main){
            DispatchQueue.main.async{
                self.workoutPlan = tempExercises
                
                self.saveWorkoutPlanDB()
                
                self.saveWorkoutPlanLocally()
                self.isWorkoutPlanAvailable = true
                completion()
                
            }
        }
    }
    
    //Saves the workoutplan to Firebase.
    func saveWorkoutPlanDB(){
        
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-yyyy-'W'W"
        let formattedDate = dateFormatter.string(from: now)
        let docID = "\(formattedDate)"
        
        let db = Firestore.firestore()
        
        let workoutPlanDoc = db
            .collection("users")
            .document(userID)
            .collection("workoutplan")
            .document(docID)
        
        
        var workoutData: [String: Any] = [
            "numberOfDays" : workoutDays.count
        ]
        
        for (index, day) in workoutDays.enumerated() {
            let key = "muscleGroupDay\(index + 1)"
            let muscleGroups = day.1.joined(separator: ", ")
            workoutData[key] = muscleGroups
        }
        
        
        workoutPlanDoc.setData(workoutData, merge: true) { error in
            if let error = error {
                print("Error saving workout metadata: \(error.localizedDescription)")
            } else {
                print("Workout metadata saved successfully.")
            }
        }
        
        
        self.workoutMetadata = workoutData
        
        //iterate through every exercise in the weekly plan
        for(dayIndex, exercises) in workoutPlan.enumerated(){
            let dayCollection = db
                .collection("users")
                .document(userID)
                .collection("workoutplan")
                .document(formattedDate)
                .collection("Day\(dayIndex + 1)")
            
            for exercise in exercises{
                let exerciseDocument = dayCollection.document(exercise.name)
                
                let data: [String: Any] = [
                    "category": exercise.category,
                    "equipment": exercise.equipment,
                    "force": exercise.force,
                    "id": exercise.id,
                    "imageURLs": exercise.imageURLs,
                    "instructions": exercise.instructions,
                    "level": exercise.level,
                    "mechanic": exercise.mechanic,
                    "name": exercise.name,
                    "primaryMuscles": exercise.primaryMuscles,
                    "secondaryMuscles": exercise.secondaryMuscles,
                    "isComplete": exercise.isComplete,
                    "sets": exercise.sets,
                    "reps": exercise.reps
                ]
                exerciseDocument.setData(data, merge: true) { error in
                    if error != nil{
                        print("Error updating Workout Document \(exercise.name).")
                    } else{
                        print("Updated Workout Document\(exercise.name).")
                    }
                }
            }
            
        }
    }
    
    
    //Loads workoutplan from UserDefaults
    func loadWorkoutPlan() -> Bool {
        let decoder = JSONDecoder()
        if let savedData = UserDefaults.standard.data(forKey: "workoutPlan"),
           let decodedData = try? decoder.decode([[Exercise]].self, from: savedData) {
            DispatchQueue.main.async{
                self.workoutPlan = decodedData
            }
            
            if let savedMetadata = UserDefaults.standard.dictionary(forKey: "workoutMetadata") {
                DispatchQueue.main.async {
                    self.workoutMetadata = savedMetadata
                }
                return true
            } else {
                print("No workout metadata found.")
            }
            return true
        }else{
            print("No saved exercises found.")
            return false
        }
    }
    
    
    //Updates user's recorded reps and weight for the exercise.
    func updateRecordedSets(for exercise: Exercise, reps: Int, weight: Double, day: Int, setIndex: Int) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-yyyy-'W'W"
        let formattedDate = dateFormatter.string(from: now)
        
        let day = "Day\(day+1)"
        let db = Firestore.firestore()
        let exerciseRef = db.collection("users")
            .document(userID)
            .collection("workoutplan")
            .document(formattedDate)
            .collection(day)
            .document(exercise.name)
        
        exerciseRef.getDocument { documentSnapshot, error in
                if let document = documentSnapshot, document.exists {
                    var sets = document.data()?["recordedSets"] as? [[String: Any]] ?? []

                    let newSet: [String: Any] = ["reps": reps, "weight": weight]

                    if sets.count > setIndex {
                        sets[setIndex] = newSet
                    } else {
                        while sets.count < setIndex {
                            sets.append(["reps": 0, "weight": 0])
                        }
                        //add newSet
                        sets.append(newSet)
                    }

                    exerciseRef.updateData(["recordedSets": sets]) { error in
                        if let error = error {
                            print("Error updating set: \(error.localizedDescription)")
                        } else {
                            print("Set \(setIndex + 1) updated successfully!")
                        }
                    }
                } else {
                    print("Exercise document does not exist or failed to fetch")
                }
            }
        }
    
    
    func fetchRecordedSets(for exercise: Exercise, day: Int, completion: @escaping ([[String: Any]]) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-yyyy-'W'W"
        let formattedDate = dateFormatter.string(from: now)

        let dayKey = "Day\(day + 1)"
        let db = Firestore.firestore()
        let exerciseRef = db.collection("users")
            .document(userID)
            .collection("workoutplan")
            .document(formattedDate)
            .collection(dayKey)
            .document(exercise.name)

        exerciseRef.getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                let recordedSets = data?["recordedSets"] as? [[String: Any]] ?? []
                completion(recordedSets)
            } else {
                print("No recorded sets found: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
            }
        }
    }

    
    //Function to check if workoutplan exists in UserDefaults
    func workoutPlanExists(completion: @escaping (Bool) -> Void) {
        // First Check UserDefaults
        if loadWorkoutPlan() {
            print("Workout plan found in UserDefaults.")
            completion(true)
            return
        }
        
        // Second Check Database
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user logged in.")
            completion(false)
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-yyyy-'W'W"
        let formattedDate = dateFormatter.string(from: now)
        
        let db = Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("workoutplan")
            .document(formattedDate)
        
        db.getDocument { (document, error) in
            if let error = error {
                print("Error checking Firestore: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let document = document, document.exists {
                print("Workout plan found in Firestore.")
                completion(true)
            } else {
                print("No workout plan found.")
                completion(false)
            }
        }
    }
    
    //Retrieves the weight that the user entered for the exercise.
    func getSavedWeight(for exercise: Exercise, completion: @escaping (Double?) -> Void) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-yyyy-'W'W"
        let formattedDate = dateFormatter.string(from: now)
        
        
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No user ID found")
            completion(nil)
            return
        }
        
        let weightRef = Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("workoutplan")
            .document(formattedDate)
            .collection("Day1")
            .document(exercise.name)
        
        weightRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching weight: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                if let weight = data?["weightUsed"] as? Double {
                    completion(weight)
                } else {
                    completion(nil)
                }
            } else {
                print("Document does not exist")
                completion(nil)
            }
        }
    }
    
    //Saves to userdefaults that exercise was marked complete.
    func saveExerciseCompletionStatus(exercise: Exercise) {
        let defaults = UserDefaults.standard
        let key = "exerciseCompleted_\(exercise.id)"
        defaults.set(exercise.isComplete, forKey: key)
        print("Exercise \(exercise.name) completion status saved: \(exercise.isComplete)")
    }
    
    //Checks to see if exercise was completed.
    func isExerciseCompleted(exercise: Exercise) -> Bool {
        let defaults = UserDefaults.standard
        let key = "exerciseCompleted_\(exercise.id)"
        return defaults.bool(forKey: key)
    }
    
    //Checks all exercises in day to see if completed.
    func loadCompletionStatuses() {
        for dayIndex in workoutPlan.indices {
            for exerciseIndex in workoutPlan[dayIndex].indices {
                let exercise = workoutPlan[dayIndex][exerciseIndex]
                workoutPlan[dayIndex][exerciseIndex].isComplete = isExerciseCompleted(exercise: exercise)
            }
        }
    }
    
    //Saves to Firebase that exercise was marked complete.
    func updateExerciseCompletionInDB(exercise: Exercise, dayIndex: Int) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No user logged in.")
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-yyyy-'W'W"
        let formattedDate = dateFormatter.string(from: now)
        
        let db = Firestore.firestore()
        let exerciseRef = db.collection("users")
            .document(userID)
            .collection("workoutplan")
            .document(formattedDate)
            .collection("Day\(dayIndex + 1)")
            .document(exercise.name)
        
        exerciseRef.updateData(["isComplete": exercise.isComplete]) { error in
            if let error = error {
                print("Error updating exercise completion status: \(error.localizedDescription)")
            } else {
                print("Exercise \(exercise.name) completion status updated successfully in Firestore.")
            }
        }
    }
    
    //Counts total amount of completed exercises in a day.
    func countCompletedAndTotalExercises(dayIndex: Int, completion: @escaping (Int, Int) -> Void) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-yyyy-'W'W"
        let formattedDate = dateFormatter.string(from: now)
        
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No user logged in.")
            completion(0, 0)
            return
        }
        
        let db = Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("workoutplan")
            .document(formattedDate)
            .collection("Day\(dayIndex)")
        
        db.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching exercises: \(error.localizedDescription)")
                completion(0, 0)
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No exercises found for Day \(dayIndex)")
                completion(0, 0)
                return
            }
            
            let totalExercises = documents.count
            let completedCount = documents.filter { ($0.data()["isComplete"] as? Bool) == true }.count
            
            print("Day \(dayIndex+1): Completed \(completedCount) / \(totalExercises)")
            completion(completedCount, totalExercises)
        }
    }
    
    //Clears completion data from UserDefaults.
    func clearAllExerciseCompletionData() {
        let defaults = UserDefaults.standard
        
        // Iterate over all the keys in UserDefaults and remove those that start with "exerciseCompleted_"
        for (key, _) in defaults.dictionaryRepresentation() {
            if key.hasPrefix("exerciseCompleted_") {
                defaults.removeObject(forKey: key)
            }
        }
        
        print("Cleared all exercise completion data.")
    }
    
    //Marks exercise as a favorite.
    func toggleFavoriteStatus(for exercise: Exercise) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No user logged in.")
            return
        }
        
        let db = Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("workoutplan")
            .document("favorites")
            .collection("exercises")
        
        let docRef = db.document(exercise.id)
        
        docRef.getDocument { (document, error) in
            if let error = error {
                print("Error checking if exercise is favorited: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                docRef.delete { error in
                    if let error = error {
                        print("Error removing exercise from favorites: \(error.localizedDescription)")
                    } else {
                        print("Exercise removed from favorites")
                    }
                }
            } else {
                docRef.setData([
                    "name": exercise.name,
                    "id": exercise.id
                ]) { error in
                    if let error = error {
                        print("Error adding exercise to favorites: \(error.localizedDescription)")
                    } else {
                        print("Exercise added to favorites")
                    }
                }
            }
        }
    }
    
    //Checks if exercise is favorited.
    func isExerciseFavorited(exercise: Exercise, completion: @escaping (Bool) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No user logged in.")
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("workoutplan")
            .document("favorites")
            .collection("exercises")
            .document(exercise.id)
        
        db.getDocument { (document, error) in
            if let document = document, document.exists {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    //Deleted workoutplan from firebase
    func deleteWorkoutPlan() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user logged in.")
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-yyyy-'W'W"
        let formattedDate = dateFormatter.string(from: now)
        
        let db = Firestore.firestore()
        let workoutPlanDocRef = db
            .collection("users")
            .document(userID)
            .collection("workoutplan")
            .document(formattedDate)
        
        let group = DispatchGroup()
        for i in 1...5 {
            group.enter()
            workoutPlanDocRef.collection("Day\(i)").getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching Day\(i) for deletion: \(error.localizedDescription)")
                    group.leave()
                    return
                }
                
                let batch = db.batch()
                snapshot?.documents.forEach { batch.deleteDocument($0.reference) }
                
                batch.commit { error in
                    if let error = error {
                        print("Error deleting exercises in Day\(i): \(error.localizedDescription)")
                    } else {
                        print("Successfully deleted Day\(i)")
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            workoutPlanDocRef.delete { error in
                if let error = error {
                    print("Error deleting workout plan document: \(error.localizedDescription)")
                } else {
                    print("Workout plan document deleted successfully.")
                    
                    self.clearAllExerciseCompletionData()
                    
                    UserDefaults.standard.removeObject(forKey: "workoutPlan")
                    UserDefaults.standard.removeObject(forKey: "workoutMetadata")
                    
                    DispatchQueue.main.async {
                        self.workoutPlan = []
                        self.workoutMetadata = [:]
                        self.isWorkoutPlanAvailable = false
                    }
                    
                }
            }
        }
    }
    
    
    //Saves manually entered workout to Firebase
    func saveManuallyEnteredWorkout(
                name: String,
                type: String,
                exercises: [[String: Any]] = [],
                day: Int,
                duration: Int,
                distance: Int
            ) {
                guard let userID = Auth.auth().currentUser?.uid else {
                    print("No user ID")
                    return
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM-yyyy-'W'W"
                let formattedDate = dateFormatter.string(from: now)
                
                let dayID = ("Day\(day)")
                let db = Firestore.firestore()
                
                let workoutRef = db
                    .collection("users")
                    .document(userID)
                    .collection("manualWorkouts")
                    .document("\(formattedDate)-manual")
                    .collection(dayID)

                var workoutData: [String: Any] = [
                    "name": name,
                    "type": type
                ]
                
                if type == "Strength" {
                        workoutData["exercises"] = exercises
                    } else {
                        workoutData["duration"] = duration
                        workoutData["distance"] = distance
                    }
                    
                
                workoutRef.addDocument(data:workoutData) { error in
                    if let error = error {
                        print("Error saving manual workout: \(error.localizedDescription)")
                    } else {
                        print("Manual workout saved successfully.")
                    }
                }
            }
    

    //Fetches the manually entered workouts from Firebase.
    func fetchManuallyEnteredWorkoutsForDay(day: Int) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user ID")
            return
        }
        
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-yyyy-'W'W"
        let formattedDate = dateFormatter.string(from: now)
        
        let dayID = "Day\(day)"
        let db = Firestore.firestore()
        
        let workoutRef = db
            .collection("users")
            .document(userID)
            .collection("manualWorkouts")
            .document("\(formattedDate)-manual")
            .collection(dayID)
        
            workoutRef.getDocuments { snapshot, error in
                if let error = error {
                print("Error fetching workouts for day: \(error.localizedDescription)")
                self.manualWorkoutsToday = []
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No workouts found for day.")
                self.manualWorkoutsToday = []
                return
            }
            
            self.manualWorkoutsToday = documents.map { doc in
                let data = doc.data()
                
                print("Workout data: \(data)")

                
                let name = data["name"] as? String ?? "Unnamed Workout"
                let type = data["type"] as? String ?? "Unknown"
                let duration = data["duration"] as? Int ?? 0
                let distance = data["distance"] as? Int ?? 0
                let exercises = data["exercises"] as? [[String: Any]] ?? []
                
                return ManualWorkout(
                    id: doc.documentID,
                    name: name,
                    type: type,
                    duration: duration,
                    distance: distance,
                    exercises: exercises
                )
            }
        }
    }

    //Fetches the saved sets and reps.
    private func getSetsAndReps(for goal: String) -> (Int, Int) {
        switch goal.lowercased() {
        case "lose":
            return (3, 15) // higher reps, moderate sets
        case "gain":
            return (4, 8) // lower reps, higher sets for hypertrophy
        case "maintain":
            return (3, 10) // balanced
        default:
            return (3, 10)
        }
    }

    //Delete the manual workout that was logged.
    func deleteManualWorkout(day: Int, workout: ManualWorkout) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user ID")
            return
        }
        
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-yyyy-'W'W"
        let formattedDate = dateFormatter.string(from: now)
        
        let db = Firestore.firestore()
        let dayID = "Day\(day)"
        
        let dayCollectionRef = db
            .collection("users")
            .document(userID)
            .collection("manualWorkouts")
            .document("\(formattedDate)-manual")
            .collection(dayID)
        
        dayCollectionRef.document(workout.id).delete { error in
            if let error = error {
                print("Error deleting workout: \(error.localizedDescription)")
            } else {
                print("Workout successfully deleted!")
                self.fetchManuallyEnteredWorkoutsForDay(day: day)
            }
        }
    }
    
}



