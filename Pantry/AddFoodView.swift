//
//  AddFoodView.swift
//  Fit Pantry
//
//  Created by Zach Greenhill on 11/29/24.
//

import Foundation
import SwiftUI

// Move these dependencies to another file
import FirebaseAuth
import FirebaseFirestore

struct AddFoodView: View {
    // Search bar text
    @State private var searchText: String = ""
    // Track selected item
    @State private var selectedItem: Food? = nil
    // Temp variable - is later converted to numerical value
    @State private var amountStr: String = ""
    // The amount the of the food the user has on hand
    @State private var amountDbl: Double = 0
    // Error message for invalid queries
    @State private var errorMessage: String? = nil
    
    // Variables to control popups
    @State private var showSheet = false
    @State private var showError = false
    @State private var selectedUnit: String = "g"
    
    // Search Mangager Object to handle queries
    @ObservedObject var searchManager = SearchManager()
    // Search view, contians:
    // - Search bar
    // - Results from search
    // - Popup to prompt user when entering food
    var body: some View {
        VStack{
            HStack {
                // Display search field
                TextField("Search", text: $searchText)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // Update search on each character being entered
                    .onChange(of: searchText) { oldValue, newValue in
                        if newValue.isEmpty {
                            searchManager.items = []
                        } else {
                            searchManager.fetchItems(searchQuery: newValue)
                        }
                    }
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 8)
                }
            }
            // Display search results
            List(searchManager.items, id: \.id) {item in
                //Text(item.name) //  Displays items as a list
                
                // Show search results as buttons
                Button(action: {
                    
                    // Preform the function when item is pressed
                    selectFood(item)
                }) {
                    
                    // Display search results
                    HStack {
                        Text(item.name)
                            .foregroundColor(.black)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue))
                }
            }
        }
        .padding()
        
        // Sheet to prompt user for the amount of food they have
        // when item is selected
        .sheet(isPresented: $showSheet) {
            VStack {
                // Text to display
                Text("Amount on hand?")
                    .font(.headline)
                    .padding()
                
//                TextField("Quantity", text: $amountStr)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    // Displays keypad
//                    .keyboardType(.decimalPad)
//                    .padding()
                
                HStack {
                    TextField("Quantity", text: $amountStr)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)

                    Picker("Unit", selection: $selectedUnit) {
                        ForEach(Array(Units.keys), id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 80)
                }
                .padding()
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Show buttons at bottom
                HStack {
                    // Submit Button
                    Button("Submit") {
                        submitAmount()
                    }
                    .padding()
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    //Cancel Button
                    Button("Cancel") {
                        
                        // Get rid of popup without commiting changes
                        showSheet = false
                    }
                    .padding()
                }
                .padding()
            }
            .padding()
        } // End .sheet popup entry
        
        .sheet(isPresented: $showError) {
            VStack {
                // Text to display
                Text("ERROR")
                    .foregroundColor(.red)
                    .padding()
                
                Text("\(errorMessage ?? "")")
                    .foregroundColor(.black)
                    .padding()
                
                Button("Okay") {
                    showError = false
                }
            }
        } // End Error sheet popup
        /*.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink { SettingsView(showSignInView: $showSignInView)
                } label: {
                    Image(systemName: "gear")
                        .font(.headline)
                }
            }
        }*/
    }
    
    // Function for what happens when a food is selected
    private func selectFood(_ item: Food) {
        // Debug message
        //print("Item tapped: \(item.id)")
        
        // Get Food that was selected
        selectedItem = item
        
        // Reset Values
        amountStr = ""
        amountDbl = 0.0
        errorMessage = nil
        
        // Display popup menu
        showSheet = true
    }
    
    // Get amount and validate for entry into database
    private func submitAmount() {
        
        // Ensure a valid item has been selected
        guard let selectedItem = selectedItem else {
            return
        }
        
        if let value = Double(amountStr) {
            // Set amount to value if numerical
            amountDbl = value
            
            // Debug print
            print("Entered value for \(selectedItem.name): \(amountDbl)")
            
            // Valid value add food to database
            addFood(item: selectedItem, value: value)
            
        } else {
            // Conversion to numerical value failed
            // Display error message
            errorMessage = "Please enter a valid number"
            print("\(errorMessage ?? "")")
            showError = true
        }
        
        // Close any popups and return to search view
        showError = false
        showSheet = false
    }
    
    // Add food to a users pantry
    private func addFood(item: Food, value: Double) {
        // Get the user's ID
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }

        let originalFood = Food(
            id: item.id,
            name: item.name,
            foodGroup: item.foodGroup,
            food_id: item.food_id,
            calories: item.calories,
            fat: item.fat,
            carbohydrates: item.carbohydrates,
            protein: item.protein,
            suitableFor: item.suitableFor
        )
        
        let pantryItem = PantryItem(
            id: originalFood.id,
            food_id: Int(originalFood.food_id),
            name: originalFood.name,
            quantity: value,
            unit: selectedUnit
        )
        
        // Save the pantry item to Firestore
        PantryManager.shared.saveFoodToFirestore(pantryItem: pantryItem, foodData: originalFood)

        // Reference to Firestore database
        let db = Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("pantry")
            .document(item.id)
        
        // Add food and nutritional info without rounding
        let data: [String: Any] = [
            "id": item.food_id,
            "name": item.name,
            "quantity": value,
            "unit": selectedUnit,
            "calories": originalFood.calories,
            "fat": originalFood.fat,
            "carbohydrates": originalFood.carbohydrates,
            "protein": originalFood.protein
        ]
        
        // Update doc
        db.setData(data, merge: true) { error in
            if error != nil {
                print("Error updating document")
            } else {
                print("Document updated!")
            }
        }
    }





}

#Preview {
    AddFoodView()
}

