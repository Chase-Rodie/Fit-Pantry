//
//  File.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 3/7/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct FavoriteMealView: View {
    @State private var savedRecipes: [SavedRecipe] = []
    @State private var selectedRecipe: SavedRecipe?
    @State private var isDetailPresented: Bool = false

    var body: some View {
        NavigationView {
            List {
                ForEach(savedRecipes) { recipe in
                    Button(action: {
                        selectedRecipe = recipe
                        isDetailPresented = true
                    }) {
                        VStack(alignment: .leading) {
                            Text(recipe.title)
                                .font(.headline)
                            Text(recipe.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteRecipe)
            }
            .navigationTitle("Favorite Recipes")
            .onAppear {
                fetchSavedRecipes()
            }
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe)
            }
        }
    }

    func fetchSavedRecipes() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }

        let db = Firestore.firestore()
        db.collection("users")
            .document(userID)
            .collection("SavedRecipes")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching recipes: \(error.localizedDescription)")
                    return
                }

                if let documents = snapshot?.documents {
                    self.savedRecipes = documents.compactMap { doc in
                        let data = doc.data()
                        guard
                            let title = data["title"] as? String,
                            let recipeText = data["recipeText"] as? String,
                            let timestamp = data["timestamp"] as? Timestamp
                        else {
                            return nil
                        }

                        return SavedRecipe(id: doc.documentID, title: title, recipeText: recipeText, timestamp: timestamp.dateValue())
                    }
                }
            }
    }
    
    func deleteRecipe(at offsets: IndexSet) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }

        offsets.forEach { index in
            let recipe = savedRecipes[index]
            let db = Firestore.firestore()

            db.collection("users")
                .document(userID)
                .collection("SavedRecipes")
                .document(recipe.id)
                .delete { error in
                    if let error = error {
                        print("Error deleting recipe: \(error.localizedDescription)")
                    } else {
                        print("Deleted recipe: \(recipe.title)")
                    }
                }
        }

        savedRecipes.remove(atOffsets: offsets)
    }

}

struct RecipeDetailView: View {
    var recipe: SavedRecipe
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(recipe.title)
                        .font(.largeTitle)
                        .bold()
                    Text("Date Created: " + recipe.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Divider()
                    Text(recipe.recipeText)
                        .font(.body)
                }
                .padding()
            }
            //.navigationTitle("Recipe Details")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
        }
    }
}



#Preview {
    FavoriteMealView()
}
