//
//  MealFilter.swift
//  Fit Pantry
//
//  Created by Heather Amistani on 4/19/25.
//

import Foundation

// Returns a list of meals that match the user's dietary preferences and fitness goal
struct MealFilter {
    static func filterMeals(
        meals: [MealPlanner],
        goal: Goal,
        dietaryPreferences: [String]
    ) -> [MealPlanner] {
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

extension MealFilter {
// Returns true if the meal does not align with the specified fitness goal
    static func flaggedForGoal(meal: MealPlanner, goal: Goal) -> Bool {
        switch goal {
        case .loseWeight:
            return !(meal.calories <= 500 && meal.fat <= 20)
        case .gainWeight:
            return !(meal.calories >= 600 && meal.protein >= 20)
        case .maintainWeight:
            return !(450...650).contains(meal.calories)
        }
    }
    
// Provides a reason why the meal doesn't meet the user's fitness goal
    static func flaggedReason(for meal: MealPlanner, goal: Goal) -> String? {
        switch goal {
        case .loseWeight:
            if meal.calories > 500 {
                return "High in calories for a weight loss goal. (Note: This depends on how much you eat.)"
            }
            if meal.fat > 20 {
                return "High in fat for a weight loss goal. (Actual impact varies based on portion size.)"
            }

        case .gainWeight:
            if meal.calories < 600 {
                return "May not provide enough calories for weight gain. (Depending on portion consumed.)"
            }
            if meal.protein < 20 {
                return "Protein content may be too low for muscle growth unless consumed in large amounts."
            }

        case .maintainWeight:
            if !(450...650).contains(meal.calories) {
                return "Calorie content is outside the ideal range for maintenance. (Depends on serving size.)"
            }
        }
        return nil
    }
}
