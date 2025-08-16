//
//  NutritionManager.swift
//  Fit Pantry
//
//  Created by Heather Amistani on 12/1/24.
//

import Foundation

class NutritionManager {
    func calculateTotalCalories(for meals: [String]) -> Int{
        var totalCalories = 0
        for meal in meals{
            switch meal{
                case "Breakfast":
                    totalCalories += 150
                case "Lunch":
                    totalCalories += 400
                case "Dinner":
                    totalCalories += 500
                default: break
            }
        }
        
        return totalCalories
    }
    
    func getNutritionalInfo(for meal: String) -> [String: Any]{
        var nutritionalInfo: [String: Any] = [:]
        
        switch meal{
        case "Breakfast":
            nutritionalInfo["Calories"] = 96
            nutritionalInfo["Protein"] = 2.01
            nutritionalInfo["Carbohydrates"] = 20.97
            nutritionalInfo["Fat"] = 0.19
        default:
            break
        }
        
        return nutritionalInfo
    }
}
