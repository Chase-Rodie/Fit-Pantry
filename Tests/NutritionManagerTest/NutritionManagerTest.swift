////
////  NutritionManagerTest.swift
////  NutritionManagerTest
////
////  Created by Heather Amistani on 12/1/24.
////
//
//import XCTest
//@testable import Fit_Pantry
//
//final class NutritionManagerTest: XCTestCase {
//
//    var nutritionManager: NutritionManager!
//
//    override func setUpWithError() throws {
//        nutritionManager = NutritionManager()
//    }
//
//    override func tearDownWithError() throws {
//        nutritionManager = nil
//    }
//
//    func testCalculateTotalCalories() throws {
//        //Input meals
//        let meals = ["Breakfast", "Lunch", "Dinner"]
//
//        //Expected total calories
//        let expectedCalories = 150 + 400 + 500
//
//        //Calculate total calories
//        let totalCalories = nutritionManager.calculateTotalCalories(for: meals)
//
//        //Assert the total calories match expected value
//        XCTAssertEqual(totalCalories, expectedCalories, "Total calories calculation is incorrect.")
//    }
//
//    func testGetNutritionalInfoForBreakfast() throws {
//        //Input meal
//        let meal = "Breakfast"
//
//        //Expected nutritional information
//        let expectedNutritionalInfo: [String: Any] = [
//            "Calories": 96,
//            "Protein": 2.01,
//            "Carbohydrates": 20.97,
//            "Fat": 0.19
//        ]
//
//        //Get nutritional info
//        let nutritionalInfo = nutritionManager.getNutritionalInfo(for: meal)
//
//        //Assert nutritional information matches expected values
//        XCTAssertEqual(nutritionalInfo["Calories"] as? Int, expectedNutritionalInfo["Calories"] as? Int, "Calories for Breakfast are incorrect.")
//        XCTAssertEqual(nutritionalInfo["Protein"] as? Double, expectedNutritionalInfo["Protein"] as? Double, "Protein for Breakfast is incorrect.")
//        XCTAssertEqual(nutritionalInfo["Carbohydrates"] as? Double, expectedNutritionalInfo["Carbohydrates"] as? Double, "Carbohydrates for Breakfast are incorrect.")
//        XCTAssertEqual(nutritionalInfo["Fat"] as? Double, expectedNutritionalInfo["Fat"] as? Double, "Fat for Breakfast is incorrect.")
//    }
//
//    func testGetNutritionalInfoForUnknownMeal() throws {
//        //Input unknown meal
//        let meal = "Snack"
//
//        //Get nutritional info
//        let nutritionalInfo = nutritionManager.getNutritionalInfo(for: meal)
//
//        //Assert the nutritional info is empty for unknown meal
//        XCTAssertTrue(nutritionalInfo.isEmpty, "Nutritional info for unknown meal should be empty.")
//    }
//}
