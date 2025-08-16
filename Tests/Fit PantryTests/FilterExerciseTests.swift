////
////  FilterExerciseTests.swift
////  Fit PantryTests
////
////  Created by Chase Rodie on 4/20/25.
////
//
//import XCTest
//@testable import Fit_Pantry
//
//class FilterExercisesTests: XCTestCase {
//
//    func testAgeFilteringWithCategories() {
//        let workoutData = RetrieveWorkoutData()
//
//        let exercises = [
//            Exercise.mock(name: "Jump Squats", category: "strength"),
//            Exercise.mock(name: "Barbell Squat", category: "strength"),
//            Exercise.mock(name: "Kettlebell Swing", category: "strength"),
//            Exercise.mock(name: "Leg Press", category: "strength"),
//            Exercise.mock(name: "Yoga", category: "stretching"),
//            Exercise.mock(name: "Swimming", category: "cardio"),
//            Exercise.mock(name: "Tai Chi", category: "stretching"),
//        ]
//
//        let youngUserAge = 16
//        let adultUserAge = 30
//        let olderUserAge = 60
//
//        let youngUserExercises = workoutData.filterExercisesForAge(exercises: exercises, userAge: youngUserAge)
//        let adultUserExercises = workoutData.filterExercisesForAge(exercises: exercises, userAge: adultUserAge)
//        let olderUserExercises = workoutData.filterExercisesForAge(exercises: exercises, userAge: olderUserAge)
//
//        // Tests for young users
//        XCTAssertTrue(youngUserExercises.contains { $0.name == "Jump Squats" })
//        
//        // Tests for adult users
//        XCTAssertTrue(adultUserExercises.contains { $0.name == "Kettlebell Swing" })
//        
//        // Tests for older users
//        XCTAssertTrue(olderUserExercises.contains { $0.name == "Yoga" })
//        XCTAssertTrue(olderUserExercises.contains { $0.name == "Tai Chi" })
//        
//        // Tests for exclusion of exercises for older users
//        XCTAssertFalse(olderUserExercises.contains { $0.name == "Jump Squats" })
//        XCTAssertFalse(olderUserExercises.contains { $0.name == "Barbell Squat" })
//    }
//}
