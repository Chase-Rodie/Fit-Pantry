//
//  Foods.swift
//  Fit Pantry
//
//  Created by Zach Greenhill on 11/29/24.
//

import Foundation

// Model for Foods
struct Food: Identifiable, Decodable, Encodable {
    var id: String
    var name: String
    var foodGroup: String
    var food_id: Int32
    var calories: Double  
    var fat: Double
    var carbohydrates: Double
    var protein: Double
    var suitableFor: [String]
}

// Model for Pantry Item
struct PantryItem: Identifiable, Decodable {
    let id: String
    let food_id: Int
    let name: String
    let quantity: Double
    let unit: String
}


struct FoodJournalItem: Identifiable, Decodable, Encodable {
    var id: String
    var name: String
    var foodGroup: String
    var food_id: String
    var calories: Int32
    var fat: Double //Float32
    var carbohydrates: Double //Float32
    var protein: Double //Float32
    var suitableFor: [String]
    var quantity: Double
    var unit: String
}

struct DailyTargets {
    let calories: Int
    let protein: Int
    let fats: Int
    let carbs: Int
}
