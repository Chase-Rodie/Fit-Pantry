//
//  HelperFunctions.swift
//  Fit Pantry
//
//  Created by Heather Amistani on 11/11/24.
//

import Foundation

//Error Handling
enum InputError: Error {
    case emptyField
    case invalidInput
}

//Helper Functions
func calculateDailyCalories(
    age: Int,
    weightInLbs: Double,
    heightInFeet: Int,
    heightInInches: Int,
    gender: String,
    goal: String,
    activityLevel: String = "Active",
    mealPreferences: [String] = []
) -> Int {
    //Conversion: 1lb = 0.453592kg, 1ft = 30.48cm, 1in = 2.54cm
    let weightInKg = weightInLbs * 0.45359237
    let heightInCm = Double(heightInFeet) * 30.48 + Double(heightInInches) * 2.54
    
    //BMR calculation using the Mifflin-St Jeor Equation
    let bmr: Double
    if gender == "male" {
        bmr = (10 * weightInKg) + (6.25 * heightInCm) - (5 * Double(age)) + 5
    } else {
        bmr = (10 * weightInKg) + (6.25 * heightInCm) - (5 * Double(age)) - 161
    }
    
    //Adjust BMR based on activity level
    let activityMultiplier: Double
    switch activityLevel {
    case "Sedentary":
        activityMultiplier = 1.2
    case "Lightly Active":
        activityMultiplier = 1.375
    case "Active":
        activityMultiplier = 1.55
    case "Very Active":
        activityMultiplier = 1.725
    default:
        activityMultiplier = 1.2 // Default to Sedentary
    }
    
    let adjustedBmr = bmr * activityMultiplier
    
    //Adjust based on goal
    if goal == "lose" {
        return Int(adjustedBmr * 0.8)
    } else if goal == "gain" {
        return Int(adjustedBmr * 1.2)
    } else {
        return Int(adjustedBmr) // Maintain weight
    }
}

func calculateBMI(weightInLbs: Double, heightInFeet: Int, heightInInches: Int) -> Double {
    let weightInKg = weightInLbs * 0.453592
    let heightInMeters = (Double(heightInFeet) * 30.48 + Double(heightInInches) * 2.54) / 100
    return weightInKg / (heightInMeters * heightInMeters)
}

func healthTip(for bmi: Double) -> String {
    if bmi < 18.5 {
        return "According to your BMI you are underweight."
    } else if bmi < 24.9 {
        return "According to your BMI you are at a normal weight."
    } else if bmi < 29.9 {
        return "According to your BMI you are overweight."
    } else {
        return "According to your BMI you are obese."
    }
}

func suggestFoods(for user: UserMeal) -> [Food] {
    let allFoods = [
        Food(id: "1", name: "Apples", foodGroup: "Fruit", food_id: 171688, calories: 52, fat: 0.17, carbohydrates: 13.81, protein: 0.26, suitableFor: ["vegan", "vegetarian", "nut-free"]),
        Food(id: "2", name: "Bread White Wheat", foodGroup: "Baked Foods", food_id: 167532, calories: 238, fat: 2.15, carbohydrates: 43.91, protein: 10.66, suitableFor: ["vegetarian", "nut-free"]),
        Food(id: "3", name: "Rice White Cooked Glutinous", foodGroup: "Grains and Pasta", food_id: 785525, calories: 96, fat: 0.19, carbohydrates: 20.97, protein: 2.01, suitableFor: ["nut-free", "vegetarian"]),
        Food(id: "4", name: "Buttermilk Low Fat (1%)", foodGroup: "Dairy and Egg Products", food_id: 781099, calories: 40, fat: 0.88, carbohydrates: 4.79, protein: 3.31, suitableFor: ["vegetarian", "nut-free"])
    ]
    
    //Filter foods based on dietary restrictions
    return allFoods.filter { food in
        return !user.dietaryRestrictions.contains { restriction in
            !food.suitableFor.contains(restriction)
        }
    }
}

func formatUserData(user: UserMeal) -> String {
    return """
    Age: \(user.age)
    Weight: \(user.weightInLbs) lbs
    Height: \(user.heightInFeet) ft \(user.heightInInches) in
    Gender: \(user.gender)
    Goal: \(user.goal)
    Activity Level: \(user.activityLevel)
    """
}

func mealSuggestions(for timeOfDay: String) -> [String] {
    switch timeOfDay {
    case "Breakfast":
        return ["Oatmeal with berries", "Greek yogurt with honey", "Avocado toast"]
    case "Lunch":
        return ["Grilled chicken salad", "Quinoa bowl with veggies", "Tuna sandwich"]
    case "Dinner":
        return ["Baked salmon with asparagus", "Stir-fry tofu with rice", "Pasta with tomato sauce"]
    default:
        return ["Healthy snack options"]
    }
}
