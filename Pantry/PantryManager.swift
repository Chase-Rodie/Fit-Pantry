// PantryManager.swift
// Fit Pantry
//
// Created by Chase Rodie on 3/15/25.
//

import FirebaseFirestore
import FirebaseAuth
import Foundation

// Handles saving pantry items to Firestore for the authenticated user
class PantryManager {
    static let shared = PantryManager()
    // Saves a pantry item to Firestore, merging with existing data if necessary
    func saveFoodToFirestore(pantryItem: PantryItem, foodData: Food) {
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }

        let db = Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("pantry")
            .document(pantryItem.id)

        let carbs = foodData.carbohydrates
        let fat = foodData.fat
        let protein = foodData.protein

        let data: [String: Any] = [
            "ID": pantryItem.food_id,
            "name": pantryItem.name,
            "Food Group": foodData.foodGroup,
            "Calories": foodData.calories,
            "Carbohydrate (g)": carbs,
            "Fat (g)": fat,
            "Protein (g)": protein,
            "quantity": pantryItem.quantity
        ]

        db.setData(data, merge: true) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document updated!")
            }
        }
    }
}


