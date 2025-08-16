////
////  ShoppingListTest.swift
////  ShoppingListTest
////
////  Created by Heather Amistani on 12/1/24.
////
//
//import XCTest
//@testable import Fit_Pantry
//
//final class ShoppingListTest: XCTestCase {
//
//    var shoppingList: ShoppingList!
//
//    override func setUpWithError() throws {
//        //Initialize ShoppingList before each test
//        shoppingList = ShoppingList()
//    }
//
//    override func tearDownWithError() throws {
//        //Deallocate ShoppingList after each test
//        shoppingList = nil
//    }
//
//    func testAddItemsForMealPlan() throws {
//        //Input meal plan
//        let mealPlan = ["Breakfast", "Lunch", "Dinner"]
//
//        //Call addItems method
//        shoppingList.addItems(for: mealPlan)
//
//        //Expected items
//        let expectedItems = ["eggs", "milk", "Grilled Cheese", "Apples", "Chicken and Salad"]
//
//        //Assert items match expected
//        XCTAssertEqual(shoppingList.items.count, expectedItems.count, "Shopping list should contain \(expectedItems.count) items.")
//        XCTAssertEqual(shoppingList.items, expectedItems, "Shopping list items are incorrect.")
//    }
//
//    func testAddItemsForEmptyMealPlan() throws {
//        //Input empty meal plan
//        let mealPlan: [String] = []
//
//        //Call addItems method
//        shoppingList.addItems(for: mealPlan)
//
//        //Assert items list is empty
//        XCTAssertTrue(shoppingList.items.isEmpty, "Shopping list should be empty for an empty meal plan.")
//    }
//
//    func testAddItemsForUnknownMeal() throws {
//        //Input meal plan with unknown meal
//        let mealPlan = ["Snack"]
//
//        //Call addItems method
//        shoppingList.addItems(for: mealPlan)
//
//        //Assert items list is empty (no matching case in switch)
//        XCTAssertTrue(shoppingList.items.isEmpty, "Shopping list should be empty for an unknown meal.")
//    }
//
//    func testPrintShoppingList() throws {
//        //Input meal plan
//        let mealPlan = ["Breakfast"]
//
//        //Call addItems and capture the output of printShoppingList
//        shoppingList.addItems(for: mealPlan)
//        shoppingList.printShoppingList()
//
//        //Expected printed output
//        let expectedItems = ["eggs", "milk"]
//        XCTAssertEqual(shoppingList.items, expectedItems, "Shopping list should contain items for 'Breakfast'.")
//    }
//}
