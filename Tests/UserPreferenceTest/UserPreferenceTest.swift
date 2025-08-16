////
////  UserPreferenceTest.swift
////  UserPreferenceTest
////
////  Created by Heather Amistani on 12/1/24.
////
//
//import XCTest
//@testable import Fit_Pantry
//
//final class UserPreferenceTest: XCTestCase {
//
//    var userPreferences: UserPreferences!
//
//    override func setUpWithError() throws {
//        //Initialize UserPreferences with default values
//        userPreferences = UserPreferences(dietaryRestrictions: ["Gluten-Free"], activityLevel: "Moderate", mealPreferences: ["Low Carb"])
//    }
//
//    override func tearDownWithError() throws {
//        //Deallocate UserPreferences after each test
//        userPreferences = nil
//    }
//
//    func testInitialization() throws {
//        //Verify initial values are set correctly
//        XCTAssertEqual(userPreferences.dietaryRestrictions, ["Gluten-Free"], "Dietary restrictions should be initialized correctly.")
//        XCTAssertEqual(userPreferences.activityLevel, "Moderate", "Activity level should be initialized correctly.")
//        XCTAssertEqual(userPreferences.mealPreferences, ["Low Carb"], "Meal preferences should be initialized correctly.")
//    }
//
//    func testUpdatePreferences() throws {
//        //Update preferences
//        let newDietaryRestrictions = ["Vegan", "Nut-Free"]
//        let newActivityLevel = "Active"
//        let newMealPreferences = ["High Protein", "Low Sugar"]
//        
//        userPreferences.updatePreferences(dietaryRestrictions: newDietaryRestrictions, activityLevel: newActivityLevel, mealPreferences: newMealPreferences)
//        
//        //Verify updated values
//        XCTAssertEqual(userPreferences.dietaryRestrictions, newDietaryRestrictions, "Dietary restrictions should update correctly.")
//        XCTAssertEqual(userPreferences.activityLevel, newActivityLevel, "Activity level should update correctly.")
//        XCTAssertEqual(userPreferences.mealPreferences, newMealPreferences, "Meal preferences should update correctly.")
//    }
//
//    func testPrintPreferences() throws {
//        //Capture the print output of `printPreferences`
//        let dietaryRestrictions = ["Vegetarian"]
//        let activityLevel = "Light"
//        let mealPreferences = ["Low Carb", "High Fiber"]
//        
//        userPreferences.updatePreferences(dietaryRestrictions: dietaryRestrictions, activityLevel: activityLevel, mealPreferences: mealPreferences)
//
//        //Verify by checking the values directly
//        XCTAssertEqual(userPreferences.dietaryRestrictions, dietaryRestrictions, "Dietary restrictions should be correctly set for printing.")
//        XCTAssertEqual(userPreferences.activityLevel, activityLevel, "Activity level should be correctly set for printing.")
//        XCTAssertEqual(userPreferences.mealPreferences, mealPreferences, "Meal preferences should be correctly set for printing.")
//    }
//}
