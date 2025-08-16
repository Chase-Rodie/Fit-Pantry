//
//  UserPreferences.swift
//  Fit Pantry
//
//  Created by Heather Amistani on 12/1/24.
//

import Foundation

// Stores and manages a user's food-related preferences
class UserPreferences{
    var dietaryRestrictions: [String]
    var activityLevel: String
    var mealPreferences:[String]
    
    // Initializes a new set of user preferences
    init(dietaryRestrictions: [String], activityLevel: String, mealPreferences: [String]){
        self.dietaryRestrictions = dietaryRestrictions
        self.activityLevel = activityLevel
        self.mealPreferences = mealPreferences
    }
    
    // Updates all user preferences at once
    func updatePreferences(dietaryRestrictions: [String], activityLevel: String, mealPreferences: [String]){
        self.dietaryRestrictions = dietaryRestrictions
        self.activityLevel = activityLevel
        self.mealPreferences = mealPreferences
    }
    
    // Prints the current user preferences to the console (for debugging or logging)
    func printPreferences(){
        print("Dietary Restrictions: \(dietaryRestrictions)")
        print("Activity Level: \(activityLevel)")
        print("Meal Preferences: \(mealPreferences)")
    }
}
