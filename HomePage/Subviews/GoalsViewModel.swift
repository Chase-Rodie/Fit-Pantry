//
//  GoalsViewModel.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 4/11/25.
//

import Foundation

class GoalsViewModel: ObservableObject {
    @Published var dailyTargets: DailyTargets?
    
    func updateDailyTargets(for user: UserMeal) {
        let simplifiedGoal = normalizeGoal(user.goal)
        let calories = calculateDailyCalories(
            age: user.age,
            weightInLbs: user.weightInLbs,
            heightInFeet: user.heightInFeet,
            heightInInches: user.heightInInches,
            gender: user.gender.lowercased(),
            goal: simplifiedGoal,
            activityLevel: user.activityLevel
        )
        
        let macros = calculateMacros(calories: calories, weightInLbs: user.weightInLbs)
        dailyTargets = DailyTargets(
            calories: macros.calories,
            protein: macros.protein,
            fats: macros.fats,
            carbs: macros.carbs
        )
    }
    
    func normalizeGoal(_ goal: String) -> String {
        switch goal.lowercased() {
        case "gain weight": return "gain"
        case "lose weight": return "lose"
        case "maintain weight": return "maintain"
        default: return "maintain"
        }
    }

    func calculateMacros(calories: Int, weightInLbs: Double) -> (calories: Int, protein: Int, fats: Int, carbs: Int) {
        let protein = Int(weightInLbs * 1.0) 
        let fat = Int(Double(calories) * 0.25 / 9)
        let remainingCalories = calories - (protein * 4 + fat * 9)
        let carbs = Int(Double(remainingCalories) / 4)
        
        return (calories, protein, fat, carbs)
    }
}
