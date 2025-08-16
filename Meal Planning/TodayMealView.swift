//
//  TodayMealView.swift
//  Fit Pantry
//
//  Created by Heather Amistani on 3/28/25.
//

import SwiftUI

// Displays and manages meals for a selected date and type, with nutrition summaries and goal feedback
struct TodayMealView: View {
    @EnvironmentObject var todayMealManager: TodayMealManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var goalsVM = GoalsViewModel()

    let selectedDate: Date
    let mealType: MealType
    @Binding var meals: [MealPlanner]
    var onRemove: (MealPlanner) -> Void
    var dailyGoal: DailyTargets?

    var body: some View {
        VStack {
            Text("\(mealType.rawValue) Meals")
                .font(.largeTitle)
                .bold()
                .padding()
            
            Text("Date: \(selectedDate.formatted(date: .abbreviated, time: .omitted))")

            if meals.isEmpty {
                Text("No meals added yet.")
                    .foregroundColor(.gray)
            } else {
                List {
                    ForEach(meals) { meal in
                        HStack {
                            Text("\(meal.name) (\(meal.consumedAmount ?? 0, specifier: "%.1f") \(meal.consumedUnit ?? "g"))")
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    if let index = meals.firstIndex(where: { $0.id == meal.id }) {
                                        let removedMeal = meals[index]
                                        onRemove(removedMeal)

                                        meals.remove(at: index)
                                        todayMealManager.setMeals(for: selectedDate, type: mealType, meals: meals)
                                    }
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                if !meals.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(Color("BackgroundColor"))
                            Text("Meal Totals")
                                .font(.headline)
                                .foregroundColor(Color("Navy"))
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 6) {
                            Label("Calories: \(mealTotals.calories)", systemImage: "flame.fill")
                            Label("Protein: \(String(format: "%.1f", mealTotals.protein))g", systemImage: "bolt.fill")
                            Label("Carbs: \(String(format: "%.1f", mealTotals.carbs))g", systemImage: "leaf.fill")
                            Label("Fat: \(String(format: "%.1f", mealTotals.fat))g", systemImage: "drop.fill")
                        }
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        if let targets = goalsVM.dailyTargets {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your Goals:")
                                    .font(.caption)
                                    .bold()
                                Text("• Calories: \(targets.calories) kcal")
                                Text("• Protein: \(targets.protein)g  • Carbs: \(targets.carbs)g  • Fat: \(targets.fats)g")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        }

                        if !goalProgressMessage.isEmpty {
                            Text(goalProgressMessage)
                                .font(.footnote)
                                .foregroundColor(.orange)
                                .padding()
                                .background(Color.yellow.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal, -10)
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white, Color.white.opacity(0.95)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.gray.opacity(0.2), radius: 5, x: 0, y: 3)
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(Color("BackgroundColor"))
                }
            }
        }
    }
    
// Calculates total nutritional values for the current meal list
    var mealTotals: (calories: Int, protein: Double, carbs: Double, fat: Double) {
        let filteredMeals = meals
        var totalCalories = 0
        var totalProtein = 0.0
        var totalCarbs = 0.0
        var totalFat = 0.0

        for meal in filteredMeals {
            let ratio = getConversionRatio(unit: meal.consumedUnit ?? "g")
            let amount = meal.consumedAmount ?? 0

            totalCalories += Int(Double(meal.calories) * ratio * amount / 100)
            totalProtein += Double(meal.protein) * ratio * amount / 100
            totalCarbs += Double(meal.carbs) * ratio * amount / 100
            totalFat += Double(meal.fat) * ratio * amount / 100
        }

        return (totalCalories, totalProtein, totalCarbs, totalFat)
    }
    
// Generates a message comparing current meal totals to user goals
    var goalProgressMessage: String {
        guard let targets = goalsVM.dailyTargets else { return "" }
        var message = ""

        if mealTotals.calories < targets.calories {
            message += "You're \(targets.calories - mealTotals.calories) kcal under your goal.\n"
        } else {
            message += "You've exceeded your calorie goal by \(mealTotals.calories - targets.calories) kcal.\n"
        }

        if mealTotals.protein < Double(targets.protein) {
            message += "Try adding more protein.\n"
        }
        if mealTotals.carbs < Double(targets.carbs) {
            message += "Consider adding more carbs.\n"
        }
        if mealTotals.fat < Double(targets.fats) {
            message += "You're still under your fat goal."
        }

        return message.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
// Converts units (e.g., oz, tbsp) into grams for nutritional scaling
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
}
