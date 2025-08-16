//
//  TodayMealManager.swift
//  Fit Pantry
//
//  Created by Heather Amistani on 3/28/25.
//

import SwiftUI
import Firebase
import FirebaseAuth

// Manages and tracks meals by date and type, including storing, retrieving, and calculating nutrition totals
class TodayMealManager: ObservableObject {
    @Published var mealsByDate: [String: [MealType: [MealPlanner]]] = [:]

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

// Returns meals of a given type for a specific date
    func getMeals(for date: Date, type: MealType) -> [MealPlanner] {
        let dateString = dateFormatter.string(from: date)
        return mealsByDate[dateString]?[type] ?? []
    }

// Stores the list of meals for a specific date and meal type.
    func setMeals(for date: Date, type: MealType, meals: [MealPlanner]) {
        let dateString = dateFormatter.string(from: date)
        if mealsByDate[dateString] == nil {
            mealsByDate[dateString] = [:]
        }
        mealsByDate[dateString]?[type] = meals
    }

// Appends a single meal to the specified date and type
    func appendMeal(for date: Date, type: MealType, meal: MealPlanner) {
        let dateString = dateFormatter.string(from: date)
        if mealsByDate[dateString] == nil {
            mealsByDate[dateString] = [:]
        }
        mealsByDate[dateString]?[type, default: []].append(meal)
    }
}

extension TodayMealManager {
// Calculates total calories, protein, carbs, and fat for all meals on a specific date
    func totalNutrition(for date: Date) -> (calories: Int, protein: Double, carbs: Double, fat: Double) {
        let dateString = dateFormatter.string(from: date)
        let dayMeals = mealsByDate[dateString] ?? [:]
        var totalCalories = 0
        var totalProtein = 0.0
        var totalCarbs = 0.0
        var totalFat = 0.0

        for mealList in dayMeals.values {
            for meal in mealList {
                let ratio = getConversionRatio(unit: meal.consumedUnit ?? "g")
                let amount = meal.consumedAmount ?? 0

                totalCalories += Int(Double(meal.calories) * ratio * amount / 100)
                totalProtein += Double(meal.protein) * ratio * amount / 100
                totalCarbs += Double(meal.carbs) * ratio * amount / 100
                totalFat += Double(meal.fat) * ratio * amount / 100
            }
        }

        return (totalCalories, totalProtein, totalCarbs, totalFat)
    }

// Converts a given unit to its equivalent gram-based ratio for nutritional scaling
    private func getConversionRatio(unit: String) -> Double {
        switch unit {
            case "g": return 1.0
            case "oz": return 28.35
            case "cup": return 340.00
            case "tbsp": return 14.175
            case "tsp": return 5.69
            case "slice": return 35.00
            case "can": return 340.2
            case "loaf": return 800.0
            case "lbs": return 453.59
            case "kg": return 1000.0
            case "ml": return 1.0
            case "L": return 1000.0
            case "gal": return 3785.411
            default: return 100.0
        }
    }
    
// Restores meals from Firestore for a given date and updates the local meal log
    func restoreMeals(for date: Date, completion: @escaping () -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            completion()
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        let docRef = Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("mealLogs")
            .document(dateString)

        docRef.getDocument { snapshot, error in
            guard let snapshot = snapshot, let data = snapshot.data() else {
                print("No meal log found")
                completion()
                return
            }

            var mealsByType: [MealType: [MealPlanner]] = [:]

            for type in MealType.allCases {
                let typeKey = type.rawValue.lowercased()
                guard let items = data[typeKey] as? [[String: Any]] else { continue }

                var restoredMeals: [MealPlanner] = []

                for item in items {
                    guard let name = item["name"] as? String,
                          let foodID = item["foodID"] as? String,
                          let amount = item["amount"] as? Double,
                          let unit = item["consumed_unit"] as? String else {
                        continue
                    }

                    let pantryDocID = item["pantryDocID"] as? String ?? ""

                    let restoredMeal = MealPlanner(
                        pantryDocID: pantryDocID,
                        name: name,
                        foodID: foodID,
                        imageURL: nil,
                        category: .prepared,
                        quantity: 0,
                        consumedAmount: amount,
                        dietaryTags: [],
                        calories: item["calories"] as? Int ?? 0,
                        protein: item["protein"] as? Double ?? 0.0,
                        carbs: item["carbs"] as? Double ?? 0.0,
                        fat: item["fat"] as? Double ?? 0.0,
                        unit: unit,
                        consumedUnit: unit,
                        actualConsumedPantryAmount: item["actual_consumed_pantry_amount"] as? Double ?? nil
                    )

                    restoredMeals.append(restoredMeal)
                }

                mealsByType[type] = restoredMeals
            }

            DispatchQueue.main.async {
                self.mealsByDate[dateString] = mealsByType
                completion()
            }
        }
    }

}

