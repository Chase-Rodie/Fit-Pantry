////
////  MealPlannerTest.swift
////  Fit PantryTests
////
////  Created by Heather Amistani on 11/11/24.
////
//
//import XCTest
//@testable import Fit_Pantry
//
//class MealPlannerTest: XCTestCase {
//
//    //MARK: - Test Calculate Daily Calories
//    func testCalculateDailyCalories() {
//        // Input values
//        let age = 25
//        let weightInLbs = 150.0
//        let heightInFeet = 5
//        let heightInInches = 10
//        let gender = "male"
//        let goal = "lose"
//        let activityLevel = "Active"
//        
//        //Expected calories for these inputs
//        let expectedCalories = 2072
//        
//        //Test function
//        let calculatedCalories = calculateDailyCalories(
//            age: age,
//            weightInLbs: weightInLbs,
//            heightInFeet: heightInFeet,
//            heightInInches: heightInInches,
//            gender: gender,
//            goal: goal,
//            activityLevel: activityLevel
//        )
//        
//        //Assert
//        XCTAssertEqual(calculatedCalories, expectedCalories, "Calories calculation is incorrect.")
//    }
//    
//    //MARK: - Test BMI Calculation
//    func testCalculateBMI() {
//        // Input values
//        let weightInLbs = 150.0
//        let heightInFeet = 5
//        let heightInInches = 10
//        
//        // Expected BMI
//        let expectedBMI = 21.5
//        
//        // Test function
//        let calculatedBMI = calculateBMI(
//            weightInLbs: weightInLbs,
//            heightInFeet: heightInFeet,
//            heightInInches: heightInInches
//        )
//        
//        //Assert
//        XCTAssertEqual(calculatedBMI, expectedBMI, accuracy: 0.1, "BMI calculation is incorrect.")
//    }
//    
//    //MARK: - Test Health Tip
//    func testHealthTip() {
//        //Input BMI
//        let bmi = 30.0
//        
//        //Expected health tip
//        let expectedTip = "According to your BMI you are obese."
//        
//        //Test function
//        let healthTipResult = healthTip(for: bmi)
//        
//        //Assert
//        XCTAssertEqual(healthTipResult, expectedTip, "Health tip generation is incorrect.")
//    }
//    
//    //MARK: - Test Food Suggestions
//    func testSuggestFoods() {
//        //Create a test user
//        let testUser = UserMeal(
//            age: 30,
//            weightInLbs: 160.0,
//            heightInFeet: 5,
//            heightInInches: 9,
//            gender: "female",
//            dietaryRestrictions: ["nut-free"],
//            goal: "maintain",
//            onMedications: nil,
//            hormoneTherapy: nil,
//            activityLevel: "Lightly Active",
//            mealPreferences: ["High Protein"],
//            allergies: nil
//        )
//        
//        //Test function
//        let suggestedFoods = suggestFoods(for: testUser)
//        
//        //Check that restricted foods are not included
//        XCTAssertFalse(
//            suggestedFoods.contains { food in food.name == "Chicken Breast" || food.name == "Eggs"},
//            "Suggested foods should not contain restricted items."
//        )
//    }
//    
//    //MARK: - Test Format User Data
//    func testFormatUserData() {
//        //Create a test user
//        let testUser = UserMeal(
//            age: 25,
//            weightInLbs: 150.0,
//            heightInFeet: 5,
//            heightInInches: 10,
//            gender: "male",
//            dietaryRestrictions: ["vegetarian"],
//            goal: "gain",
//            onMedications: ["Vitamin D"],
//            hormoneTherapy: nil,
//            activityLevel: "Lightly Active",
//            mealPreferences: ["Fruit"],
//            allergies: ["Gluten"]
//        )
//        
//        //Test function
//        let formattedData = formatUserData(user: testUser)
//        
//        //Expected output
//        let expectedOutput = """
//        Age: 25
//        Weight: 150.0 lbs
//        Height: 5 ft 10 in
//        Gender: male
//        Goal: gain
//        Activity Level: Lightly Active
//        """
//        
//        //Assert
//        XCTAssertEqual(formattedData, expectedOutput, "User data formatting is incorrect.")
//    }
//}
