//
//  MealGenAPI.swift
//  Fit Pantry
//
//  Created by Zachary Greenhill on 3/2/25.
//

import Foundation

// Structures to process API requests
struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
}

struct ChatChoice: Codable {
    let message: ChatMessage
}

struct ChatResponse: Codable {
    let choices: [ChatChoice]
}

// Get Recpie with OpenAI API request
func generateRecipeWithOpenAI(ingredients: [String], completion: @escaping (String?) -> Void) {
    print(ingredients)
    guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
        completion(nil)
        return
    }
    
    // Obscure the OpenAI API key
    let p1 = "Bearer sk-proj-j7UgsHc-wC2ubXG1HpFR7XRSHM0R"
    let p2 = "_kOc5StGoNjUypEa27WoZxfabi_rf-wSW_KOjx_JBBzCboT3BlbkFJ8SVSywj"
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let lastPart = "-7EpTVuAaol7dOFulEl4JvgSpVwH8CAPlsN6PRb7LiCdkxxrl8eYK5t8l9ZrWw2ibgA"
    let p4 = p1 + p2 + lastPart
    request.setValue(p4, forHTTPHeaderField: "Authorization")
   
    // System Prompt
    let systemMessage = """
    You are a helpful chef assistant that generates healthy recipes. Only respond with the following sections, formatted clearly and without any extra descriptions or commentary:

    [Insert recipe name here]

    Ingredients:
    - [List ingredients here]

    Instructions:
    1. [Step-by-step instructions here]
    """
    
    // User prompt
    let formattedIngredients = ingredients.joined(separator: ", ")
    let prompt = "Create a healthy and delicious recipe using only the following ingredients: \(formattedIngredients)."
    
    // Request
    let chatRequest = ChatRequest(
        model: "gpt-4o-mini", // Or use "gpt-4" if you have access
        messages: [
            ChatMessage(role: "system", content: systemMessage),
            ChatMessage(role: "user", content: prompt)
        ],
        temperature: 0.7
    )

    guard let jsonData = try? JSONEncoder().encode(chatRequest) else {
        completion(nil)
        return
    }

    request.httpBody = jsonData

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            completion(nil)
            return
        }

        if let chatResponse = try? JSONDecoder().decode(ChatResponse.self, from: data) {
            completion(chatResponse.choices.first?.message.content)
        } else {
            completion(nil)
        }
    }

    task.resume()
}


///  DEPRECIATED AND NO LONGER USED
struct RecipeRequest: Codable {
    let ingredients: [String]
}

struct RecipeResponse: Codable {
    let recipe: String
}

func generateRecipe(ingredients: [String], completion: @escaping (String?) -> Void) {
    //let url = URL(string: "http://172.127.24.215:42647/generate_recipe/")!
    let url = URL(string: "http://localhost:42647/generate_recipe/")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let requestData = RecipeRequest(ingredients: ingredients)
    let jsonData = try? JSONEncoder().encode(requestData)
    request.httpBody = jsonData

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            completion(nil)
            return
        }

        if let recipeResponse = try? JSONDecoder().decode(RecipeResponse.self, from: data) {
            completion(recipeResponse.recipe)
        } else {
            completion(nil)
        }
    }

    task.resume()
     
}


// Example usage
/*
generateRecipe(ingredients: ["chicken breast", "rice", "soy sauce", "garlic"]) { response in
    if let recipe = response {
        print("Generated Recipe:\n\(recipe)")
    } else {
        print("Failed to fetch recipe")
    }
}
*/
