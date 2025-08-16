//
//  MealFilterTests.swift
//  Fit Pantry
//
//  Created by Heather Amistani on 4/19/25.
//

import XCTest

enum Goal {
    case loseWeight
    case gainWeight
    case maintainWeight
}

struct MockMeal: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var dietaryTags: [String]
    var calories: Int
    var protein: Int
    var fat: Int
}

struct MealFilter {
    static func filterMeals(
        meals: [MockMeal],
        goal: Goal,
        dietaryPreferences: [String]
    ) -> [MockMeal] {
        return meals.filter { meal in
            let matchesPreferences = dietaryPreferences.allSatisfy {
                meal.dietaryTags.contains($0)
            }

            let matchesGoal: Bool
            switch goal {
            case .loseWeight:
                matchesGoal = meal.calories <= 500 && meal.fat <= 20
            case .gainWeight:
                matchesGoal = meal.calories >= 600 && meal.protein >= 20
            case .maintainWeight:
                matchesGoal = (450...650).contains(meal.calories)
            }

            return matchesPreferences && matchesGoal
        }
    }
}

final class MealFilterTests: XCTestCase {

    func testLoseWeightFiltering() {
        let meals = [
            MockMeal(name: "Burger", dietaryTags: ["glutenFree"], calories: 800, protein: 25, fat: 35),
            MockMeal(name: "Salad", dietaryTags: ["vegetarian"], calories: 350, protein: 10, fat: 12)
        ]

        let filtered = MealFilter.filterMeals(
            meals: meals,
            goal: .loseWeight,
            dietaryPreferences: ["vegetarian"]
        )

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Salad")
    }

    func testGainWeightFilteringFailsLowProtein() {
        let meals = [
            MockMeal(name: "Smoothie", dietaryTags: ["vegetarian"], calories: 700, protein: 5, fat: 20)
        ]

        let filtered = MealFilter.filterMeals(
            meals: meals,
            goal: .gainWeight,
            dietaryPreferences: ["vegetarian"]
        )

        XCTAssertTrue(filtered.isEmpty)
    }
}
