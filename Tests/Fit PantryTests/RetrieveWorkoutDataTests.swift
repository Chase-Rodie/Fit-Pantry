////
////  FoodJournalViewTests.swift
////  Fit PantryTests
////
////  Created by Lexie Reddon on 2/16/25.
////
//
//import XCTest
//@testable import Fit_Pantry
//
//class RetrieveWorkoutDataTests: XCTestCase {
//    var retrieveWorkoutData: RetrieveWorkoutData!
//
//    override func setUp() {
//        super.setUp()
//        retrieveWorkoutData = RetrieveWorkoutData()
//    }
//    override func tearDown() {
//        retrieveWorkoutData = nil
//        super.tearDown()
//    }
//
//    func testSaveWorkoutPlanLocally() {
//        //mock an exercises
//            let mockExercise = Exercise(category: "Strength", equipment: "Dumbbell", force: "Push", id: "1", imageURLs: [], instructions: [], level: "Beginner", mechanic: "Compound", name: "Bench Press", primaryMuscles: ["Chest"], secondaryMuscles: ["Triceps"], isComplete: false)
//            retrieveWorkoutData.workoutPlan = [[mockExercise]]
//        //force a local save
//            retrieveWorkoutData.saveWorkoutPlanLocally()
//            let savedPlan = retrieveWorkoutData.loadWorkoutPlan()
//        //verify correct message received
//            XCTAssertTrue(savedPlan, "Workout plan should be successfully saved and loaded")
//        }
//
//    func testMarkComplete() {
//        //Arrange
//        let exercise = Exercise(
//                category: "Strength",
//                equipment: "Dumbbell",
//                force: "Push",
//                id: "1",
//                imageURLs: [],
//                instructions: [],
//                level: "Beginner",
//                mechanic: "Compound",
//                name: "Bench Press",
//                primaryMuscles: ["Chest"],
//                secondaryMuscles: ["Triceps"],
//                isComplete: false
//            )
//        
//        //Act
//        retrieveWorkoutData.workoutPlan = [[exercise]]
//        retrieveWorkoutData.markComplete(for: exercise)
//        //Assert
//        XCTAssertTrue(retrieveWorkoutData.workoutPlan[0][0].isComplete, "Exercise should be marked as complete.")
//    }
//}

