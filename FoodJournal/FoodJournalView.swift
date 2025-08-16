//
//  FoodJournalView.swift
//  Fit Pantry
//
//  Created by Lexie Reddon on 2/13/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

struct FoodJournalView: View {
    @StateObject private var viewModel = FoodJournalViewModel()
    @State private var selectedMeal: Meal?
    @State private var now = Date()
    @State private var macroTotals = macroNutrients()
    @State private var showMacros = false // Macro menu

    var calorieGoal: Double {
        macroTotals.cals ?? 0
    }

    var fatGoal: Double {
        macroTotals.fat ?? 0
    }

    var carbGoal: Double {
        macroTotals.carbs ?? 0
    }

    var protGoal: Double {
        macroTotals.protein ?? 0
    }
   
    var body: some View{
        
        ZStack{
          
            LinearGradient(colors:[.background, .lighter], startPoint:  .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ScrollView{
                VStack{
                    VStack(spacing: 8) {
        
                        Text("Food Journal For")
                            .font(.title)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)

                        DatePicker("", selection: $now, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    Spacer(minLength: 30)
                        
                    VStack {
                        // Always-visible calories section
                        let totalCalories = viewModel.totalCaloriesForDay()
                        let calProgress = min(Double(totalCalories) / Double(calorieGoal), 1.0)

                        VStack(spacing: 5) {
                            Text("Calories: \(totalCalories) / \(calorieGoal.formatted(.number.precision(.fractionLength(0))))")
                            ProgressView(value: calProgress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle())
                                .frame(width: 300, height: 30)
                                .tint(.navy)
                        }
                        .padding(.horizontal, 16)

                        // Toggle button
                        Button(action: {
                            withAnimation {
                                showMacros.toggle()
                            }
                        }) {
                            Text(showMacros ? "Hide Macros" : "Show Macros")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.top, 8)
                        }

                        // Collapsible macro section
                        if showMacros {
                            VStack(spacing: 8) {
                                // Fat
                                let totalFat = viewModel.totalFatForDay()
                                let fatProgress = min(Double(totalFat) / Double(fatGoal), 1.0)

                                HStack {
                                    Text("Fat: \(String(format: "%.1f", totalFat))g / \(String(format: "%.1f", fatGoal))g")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    ProgressView(value: fatProgress, total: 1.0)
                                        .progressViewStyle(LinearProgressViewStyle())
                                        .frame(width: 150, height: 20)
                                        .tint(.navy)
                                }

                                // Carbs
                                let totalCarbs = viewModel.totalCarbsForDay()
                                let carbProgress = min(Double(totalCarbs) / Double(carbGoal), 1.0)

                                HStack {
                                    Text("Carbs: \(String(format: "%.1f", totalCarbs))g / \(String(format: "%.1f", carbGoal))g")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    ProgressView(value: carbProgress, total: 1.0)
                                        .progressViewStyle(LinearProgressViewStyle())
                                        .frame(width: 150, height: 20)
                                        .tint(.navy)
                                }

                                // Protein
                                let totalProtein = viewModel.totalProteinForDay()
                                let proteinProgress = min(Double(totalProtein) / Double(protGoal), 1.0)

                                HStack {
                                    Text("Protein: \(String(format: "%.1f", totalProtein))g / \(String(format: "%.1f", protGoal))g")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    ProgressView(value: proteinProgress, total: 1.0)
                                        .progressViewStyle(LinearProgressViewStyle())
                                        .frame(width: 150, height: 20)
                                        .tint(.navy)
                                }
                            }
                            .padding(.horizontal, 16)
                            .transition(.opacity.combined(with: .slide))
                        }
                    

                    
                        HStack{
                            VStack(alignment: .leading){
                                HStack{
                                    Text("Breakfast:")
                                        .font(.system(size: 20, weight: .bold))
                                    Spacer()
                                    Button {
                                        selectedMeal = Meal(name: "breakfast")
                                    } label: {
                                        Image(systemName: "plus")
                                            .font(.system(size: 20))
                                    }.sheet(item: $selectedMeal) { meal in
                                        FoodJournalAddItemView(
                                            mealName: meal.name,
                                            selectedDate: viewModel.now,
                                            viewModel: viewModel
                                        )
                                    }
                                }
                                Divider()
                                    .background(Color.black)
                               
                                ForEach(viewModel.breakfastFoodEntries){ food in
                                    NavigationLink(destination:FoodJournalItemView(item: food, mealName: "breakfast", viewModel: viewModel)){
                                        HStack{
                                            VStack(alignment: .leading){
                                                Text(food.name)
                                                    .font(.system(size: 18, weight: .semibold))
                                                
                                                Text("Quantity: \(food.quantity.description) \(food.unit.description)   •    Calories: \(food.calories.description)")
                                            }
                                        }
                                        Spacer()
                                        Button{
                                            viewModel.deleteFoodEntry(mealName: "breakfast", food: food)
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .padding(.vertical, 15)
                                    }
                                }

                            }
                        }
                        .padding()
                        HStack{
                            VStack(alignment: .trailing){
                                HStack{
                                    Text("Lunch:")
                                        .font(.system(size: 20, weight: .bold))
                                    Spacer()
                                    Button {
                                        selectedMeal = Meal(name: "lunch")
                                    } label: {
                                        Image(systemName: "plus")
                                            .font(.system(size: 20))
                                    }.sheet(item: $selectedMeal) { meal in
                                        FoodJournalAddItemView(
                                            mealName: meal.name,
                                            selectedDate: viewModel.now,
                                            viewModel: viewModel
                                        )
                                    }

                                }
                                Divider()
                                    .background(Color.black)
                                ForEach(viewModel.lunchFoodEntries){ food in
                                    NavigationLink(destination:FoodJournalItemView(item: food, mealName: "lunch", viewModel: viewModel)){
                                        HStack{
                                            VStack(alignment: .leading){
                                                Text(food.name)
                                                    .font(.system(size: 18, weight: .semibold))
                                                
                                                Text("Quantity: \(food.quantity.description) \(food.unit.description)   •    Calories: \(food.calories.description)")
                                            }
                                        }
                                        Spacer()
                                        Button{
                                            viewModel.deleteFoodEntry(mealName: "lunch", food: food)
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .padding(.vertical, 15)
                                    }
                                }
                            }
                        }
                        .padding()
                        HStack{
                            VStack(alignment: .trailing){
                                HStack{
                                    Text("Dinner:")
                                        .font(.system(size: 20, weight: .bold))
                                    Spacer()
                                    Button {
                                        selectedMeal = Meal(name: "dinner")
                                    } label: {
                                        Image(systemName: "plus")
                                            .font(.system(size: 20))
                                    }.sheet(item: $selectedMeal) { meal in
                                        FoodJournalAddItemView(
                                            mealName: meal.name,
                                            selectedDate: viewModel.now,
                                            viewModel: viewModel
                                        )
                                    }

                                }
                                Divider()
                                    .background(Color.black)
                                ForEach(viewModel.dinnerFoodEntries){ food in
                                    NavigationLink(destination:FoodJournalItemView(item: food, mealName: "dinner", viewModel: viewModel)){
                                    HStack{
                                        VStack(alignment: .leading){
                                            Text(food.name)
                                                .font(.system(size: 18, weight: .semibold))
                                            
                                            Text("Quantity: \(food.quantity.description) \(food.unit.description)   •    Calories: \(food.calories.description)")
                                        }
                                        }
                                        Spacer()
                                        Button{
                                            viewModel.deleteFoodEntry(mealName: "dinner", food: food)
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .padding(.vertical, 15)
                                    }
                                }

                            }
                        }
                        .padding()
                        
                    }
                    
                }
            }
        }.foregroundColor(.white)
            .onChange(of: now) { newDate in
                viewModel.clearFoodEntries()
                viewModel.fetchFoodEntries(mealName: "breakfast", for: newDate)
                viewModel.fetchFoodEntries(mealName: "lunch", for: newDate)
                viewModel.fetchFoodEntries(mealName: "dinner", for: newDate)
            }
            .onAppear {
                viewModel.fetchFoodEntries(mealName: "breakfast", for: now)
                viewModel.fetchFoodEntries(mealName: "lunch", for: now)
                viewModel.fetchFoodEntries(mealName: "dinner", for: now)
                
                //Get macro nutrients for user
                macroCalculator.getMacros { macros in
                    DispatchQueue.main.async {
                        macroTotals = macros
                    }
                }
            }
    }
}


struct Meal: Identifiable {
    let id = UUID()  // Conforming to Identifiable
    let name: String
}


#Preview {
    FoodJournalView()
}
