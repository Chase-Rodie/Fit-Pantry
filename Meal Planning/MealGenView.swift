//
//  MealGenView.swift
//  Fit Pantry
//
//  Created by Zachary Greenhill on 3/2/25.
//
// NOTE:
// This is for demostration purposes and can be removed later
// NOTE:
// Can be removed now

import SwiftUI

struct RecipeGeneratorView: View {
    @State private var ingredients: String = ""
    @State private var recipe: String = "Your recipe will appear here..."
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("AI Recipe Generator")
                .font(.largeTitle)
                .bold()
            
            TextField("Enter ingredients (comma-separated)", text: $ingredients)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: fetchRecipe) {
                Text(isLoading ? "Generating..." : "Generate Recipe")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoading ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isLoading)
            .padding()
            
            ScrollView {
                Text(recipe)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .border(Color.gray, width: 1)
            .padding()
        }
        .padding()
    }
    
    func fetchRecipe() {
        let ingredientList = ingredients.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard !ingredientList.isEmpty else {
            recipe = "Please enter at least one ingredient."
            return
        }
        
        //print(ingredientList)

        isLoading = true
        generateRecipe(ingredients: ingredientList) { result in
            DispatchQueue.main.async {
                if let result = result {
                    recipe = result
                } else {
                    recipe = "Failed to generate recipe. Please try again."
                }
                isLoading = false
            }
        }
    }
}


struct RecipeGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeGeneratorView()
    }
}

