//
//  GoalsView.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 3/7/25.
//

import SwiftUI

struct GoalsView: View {
    @StateObject private var viewModel = GoalsViewModel()
    @State private var macroTotals = macroNutrients()
    var user: UserMeal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Daily Goals")
                .font(.title)
                .bold()
            
            goalRow(title: "Calories", value: "\(Int(macroTotals.cals ?? 0)) kcal")
            goalRow(title: "Protein", value: "\(Int(macroTotals.protein ?? 0)) g")
            goalRow(title: "Fats", value: "\(Int(macroTotals.fat ?? 0)) g")
            goalRow(title: "Carbs", value: "\(Int(macroTotals.carbs ?? 0)) g")
            Spacer()
        }
        .padding()
        .onAppear {
            macroCalculator.getMacros { macros in
                DispatchQueue.main.async {
                    macroTotals = macros
                }
            }
    }
}
    
    func goalRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .fontWeight(.semibold)
            Spacer()
            Text(value)
        }
        .padding(.vertical, 4)
    }
}


#Preview {
    GoalsView(user: UserMeal(
        age: 24,
        weightInLbs: 160,
        heightInFeet: 5,
        heightInInches: 10,
        gender: "Male",
        dietaryRestrictions: [],
        goal: "Gain Weight",
        activityLevel: "Active",
        mealPreferences: []
    ))
}
