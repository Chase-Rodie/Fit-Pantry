//
//  Meal.swift
//  Fit Pantry
//
//  Created by Heather Amistani on 3/3/25.
//

import Foundation

//struct Meal: Identifiable, Hashable {
//    let id = UUID()
//    let name: String
//    let foodID: String
//    //    let imageURL: String?
//}

struct SavedRecipe: Identifiable {
    var id: String
    var title: String
    var recipeText: String
    var timestamp: Date
}
