//
//  FoodJournalAddItemView.swift
//  Fit Pantry
//
//  Modified version of AddFoodView for FoodJournalView

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FoodJournalAddItemView: View {
    let mealName: String
    let selectedDate: Date
    @ObservedObject var viewModel: FoodJournalViewModel
    
    // Search bar text
    @State private var searchText: String = ""
    // Track selected item
    @State private var selectedItem: Food? = nil
    // Temp variable - is later converted to numerical value
    @State private var amountStr: String = ""
    // The amount the of the food the user ate
    @State private var amountDbl: Double = 0
    // Error message for invalid queries
    @State private var errorMessage: String? = nil
    
    // Variables to control popups
    @State private var showSheet = false
    @State private var showError = false
    
    @State private var selectedUnit: String = "g"
    let unitTypes = ["g", "oz", "cup", "tbsp", "tsp", "slice", "can", "loaf", "lbs", "kg", "ml", "L", "gal"]

    
    // Search Mangager Object to handle queries
    @ObservedObject var searchManager = SearchManager()
    
    // let now = Date()
    
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
            .foregroundColor(.black)
            
            // Sheet to prompt user for the amount of food they have
            // when item is selected
            .sheet(isPresented: $showSheet) {
                VStack {
                    Text("Amount eaten?")
                            .font(.headline)
                            .padding(.bottom)

                        HStack {
                            // Quantity Input
                            TextField("Quantity", text: $amountStr)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                                .frame(maxWidth: .infinity)

                            // Unit Picker
                            Picker("Unit", selection: $selectedUnit) {
                                ForEach(unitTypes, id: \.self) { unit in
                                    Text(unit).tag(unit)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 100) // You can adjust this width as needed
                        }
                        .padding(.horizontal)

                    
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
                .foregroundColor(.black)
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
            } 
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
                addFood(item: selectedItem, value: value, mealName: mealName)
                
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
    
    // Add Food to the food Log and have it displayed in the Journal
    private func addFood(item: Food, value: Double, mealName: String) {
        guard let userID = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User not authenticated"
            return
        }

        // Format current date for document ID
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: selectedDate)

        // Reference to the meal document
        let docRef = Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("mealLogs")
            .document(formattedDate)

        // Create the new food entry
        let newEntry: [String: Any] = [
            "foodID": String(item.food_id),
            "amount": value,
            "name": item.name,
            "consumed_unit": selectedUnit
        ]

        docRef.getDocument { snapshot, error in
            var mealArray = [[String: Any]]()

            if let snapshot = snapshot, snapshot.exists {
                // If the document exists, read current meal array if it exists
                if let data = snapshot.data(), let existingArray = data[mealName] as? [[String: Any]] {
                    mealArray = existingArray
                }
            }

            // Append the new entry
            mealArray.append(newEntry)

            // Use setData with merge to create or update the mealName field
            docRef.setData([mealName: mealArray], merge: true) { error in
                if let error = error {
                    print("Error writing document: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        viewModel.fetchFoodEntries(mealName: mealName, for: selectedDate)
                    }
                    print("Food item added successfully!")
                }
            }
        }
    }
}
    


//#Preview {
//    FoodJournalAddItemView(mealName: "breakfast")
//}
