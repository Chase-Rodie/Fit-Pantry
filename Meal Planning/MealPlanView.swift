//
//  MealPlanView.swift
//  Fit Pantry
//
//  Created by Heather Amistani on 02/28/2025
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Foundation

// Displays the user's meal plan, allows selection of foods, meal logging, and recipe generation
struct MealPlanView: View {
    @EnvironmentObject var mealManager: TodayMealManager
    @State private var selectedDate = Date()
    @State private var mealPlan: [MealPlanner] = []
    @State private var isLoading = true
    @State private var selectedCategory: MealCategory = .prepared
    @State private var selectedMeals: Set<MealPlanner> = []
    @State private var showQuantityInput = false
    @State private var selectedMealType: MealType = .breakfast
    @State private var inputQuantities: [UUID: String] = [:]
    @State private var quantityErrors: [UUID: String] = [:]
    @EnvironmentObject var userManager: UserManager
    @State private var selectedUnits: [UUID: String] = [:]

    
    @State private var showMealGen = false

    @State private var generatedRecipe: String = ""
    @State private var isRecipeLoading = false


    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Meal Plan")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.leading)
                
                // Header and date picker
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding(.horizontal)

                // Allows switching between 'prepared' and 'ingredient' meals
                Picker("Meal Category", selection: $selectedCategory) {
                    ForEach(MealCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .onChange(of: selectedCategory) { newValue in
                    selectedMeals.removeAll()
                }

                HStack {
                    ForEach(MealType.allCases) { type in
                        NavigationLink(destination: TodayMealView(
                            selectedDate: selectedDate,
                            mealType: type,
                            meals: Binding(
                                get: { mealManager.getMeals(for: selectedDate, type: type) },
                                set: { mealManager.setMeals(for: selectedDate, type: type, meals: $0) }
                            ),
                            onRemove: { removedMeal in
                                let restoredAmountInPantryUnits = removedMeal.actualConsumedPantryAmount ?? 0.0

                                print("Restoring \(restoredAmountInPantryUnits) \(removedMeal.unit ?? "g") for \(removedMeal.name) (saved consumed pantry amount)")

                                if !removedMeal.pantryDocID.isEmpty {
                                    updatePantryQuantity(docID: removedMeal.pantryDocID, amount: restoredAmountInPantryUnits)
                                } else {
                                    print("⚠️ pantryDocID is empty for meal: \(removedMeal.name)")
                                }

                                removeMealFromFirestore(removedMeal, for: selectedDate, type: selectedMealType)

                                Task {
                                    await fetchMealsAsync()
                                }
                            }
                        )
                            .environmentObject(mealManager)
                        ){
                            VStack {
                                Image(systemName: "fork.knife")
                                    .foregroundColor(Color("Navy"))
                                Text(type.rawValue)
                                    .foregroundColor(Color("Navy"))
                            }
                            .padding()
                            .background(Color("BackgroundColor").opacity(0.5))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()

                if isLoading {
                    VStack {
                        ProgressView()
                        Text("Loading meals...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    let filteredMeals = mealPlan.filter { $0.category == selectedCategory && $0.quantity > 0 }
                    if filteredMeals.isEmpty {
                        Text("No \(selectedCategory.rawValue.lowercased()) meals available. Add food to your pantry to use your meal plan!")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        List {
                            ForEach(filteredMeals) { meal in
                                HStack {
                                    NavigationLink(destination: MealDetailView(meal: meal.name, foodID: meal.foodID)) {
                                        VStack(alignment: .leading) {
                                            Text("\(meal.name) (\(meal.quantity, specifier: "%.1f") \(meal.unit ?? "g"))")
                                                .font(.title3)
                                            
                                            Text("Tap to view details")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }

                                    Spacer()

                                    Button(action: {
                                        if selectedMeals.contains(meal) {
                                            selectedMeals.remove(meal)
                                        } else {
                                            selectedMeals.insert(meal)
                                        }
                                    }) {
                                        Image(systemName: selectedMeals.contains(meal) ? "checkmark.circle.fill" : "plus.circle")
                                            .font(.title2)
                                            .foregroundColor(
                                                selectedMeals.contains(meal) ? Color("Orange") : Color("BackgroundColor")
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contentShape(Rectangle())
                                }
                                .padding(.vertical, 5)
                            }
                        }
                        .listStyle(PlainListStyle())
                        .padding(.horizontal)
                    }
                }
                
                if !selectedMeals.isEmpty {
                    VStack{
                        if selectedCategory == .ingredient {
                            HStack {
                                Button("Generate Recipe") {
                                    showMealGen = true
                                }
                                .padding(6)
                                .background(Color("BackgroundColor"))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                        
                        HStack {
                            Text("Add selected to:")
                            ForEach(MealType.allCases) { type in
                                Button(type.rawValue) {
                                    selectedMealType = type
                                    showQuantityInput = true
                                }
                                .padding(6)
                                .background(Color("Navy"))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                }
                
                
                Spacer()
            }
            .onAppear {
                mealManager.restoreMeals(for: selectedDate) {
                    print("Meals restored!")
                    Task {
                        await fetchMealsAsync()
                    }
                }
            }
            .sheet(isPresented: $showQuantityInput) {
                VStack {
                    Text("How much of each selected item was eaten?")
                        .font(.headline)
                        .padding()
                    if let goal = userManager.currentUser?.profile.goal {
                                let flaggedMessages = selectedMeals.compactMap { MealFilter.flaggedReason(for: $0, goal: goal) }

                                if !flaggedMessages.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("⚠️ Nutrition Considerations:")
                                            .font(.headline)
                                            .foregroundColor(.orange)

                                        ForEach(flaggedMessages, id: \.self) { message in
                                            Text("• \(message)")
                                                .font(.footnote)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding()
                                    .background(Color.yellow.opacity(0.1))
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                }
                            }
                    ScrollView {
                        ForEach(Array(selectedMeals), id: \.self) { meal in
                            QuantityInputRow(
                                meal: meal,
                                amount: Binding(
                                    get: { inputQuantities[meal.id] ?? "" },
                                    set: { inputQuantities[meal.id] = $0 }
                                ),
                                selectedUnit: Binding(
                                    get: { selectedUnits[meal.id] ?? "g" },
                                    set: { selectedUnits[meal.id] = $0 }
                                ),
                                error: quantityErrors[meal.id]
                            )
                        }
                    }
                    Button(action: {
                        quantityErrors = [:]
                        var isValid = true

                        // Validate input amounts and check against available pantry quantity
                        for meal in selectedMeals {
                            guard let input = inputQuantities[meal.id], let eaten = Double(input) else {
                                quantityErrors[meal.id] = "Enter a valid number"
                                isValid = false
                                continue
                            }

                            let selectedUnit = selectedUnits[meal.id] ?? "g"
                            let pantryUnit = meal.unit ?? "g"
                            guard let eatenFactor = Units[selectedUnit], let pantryFactor = Units[pantryUnit] else {
                                quantityErrors[meal.id] = "Invalid unit selected"
                                isValid = false
                                continue
                            }

                            let eatenInGrams = eaten * eatenFactor
                            let pantryQuantityInGrams = meal.quantity * pantryFactor

                            if eatenInGrams > pantryQuantityInGrams + 0.01 {
                                let formatted = String(format: "%.1f", meal.quantity)
                                quantityErrors[meal.id] = "You only have \(formatted) \(pantryUnit)"
                                isValid = false
                            }
                        }

                        guard isValid else { return }
                        
                        // Log valid meals, update pantry quantities, and save meal info to Firestore
                        for meal in selectedMeals {
                            if let input = inputQuantities[meal.id], let eaten = parseFraction(from: input) {
                                let selectedUnit = selectedUnits[meal.id] ?? "g"
                                let pantryUnit = meal.unit ?? "g"
                                let eatenFactor = Units[selectedUnit] ?? 1.0
                                let pantryFactor = Units[pantryUnit] ?? 1.0

                                let eatenInGrams = eaten * eatenFactor
                                let amountToSubtract = eatenInGrams / pantryFactor

                                updatePantryQuantity(docID: meal.pantryDocID, amount: -amountToSubtract)
                                //logMeal(for: meal, amount: eaten, type: selectedMealType)

                                var updatedMeal = meal
                                updatedMeal.consumedAmount = eaten
                                updatedMeal.consumedUnit = selectedUnit
                                updatedMeal.actualConsumedPantryAmount = amountToSubtract
                                updatedMeal.quantity -= amountToSubtract
                                mealManager.appendMeal(for: selectedDate, type: selectedMealType, meal: updatedMeal)
                                
                                logMeal(for: updatedMeal, amount: eaten, type: selectedMealType)

                                if let index = mealPlan.firstIndex(where: { $0.id == meal.id }) {
                                    mealPlan[index].quantity -= amountToSubtract
                                }
                            }
                        }

                        selectedMeals.removeAll()
                        inputQuantities.removeAll()
                        showQuantityInput = false
                    }) {
                        Text("Submit")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("Navy"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    .padding()
                }
            }
            .sheet(isPresented: $showMealGen) {
                MealGenerationView(selectedMeals: selectedMeals)
            }

        }
    }
    
// Updates the pantry quantity in Firestore based on user input
    func updatePantryQuantity(docID: String, amount: Double) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }

        let db = Firestore.firestore()
        let pantryDoc = db.collection("users")
            .document(userID)
            .collection("pantry")
            .document(docID)

        pantryDoc.getDocument { documentSnapshot, error in
            if let error = error {
                print("Error fetching pantry document: \(error.localizedDescription)")
                return
            }

            guard let data = documentSnapshot?.data(),
                  let currentQuantity = data["quantity"] as? Double else {
                print("Pantry document missing or missing quantity field")
                return
            }

            let newQuantity = currentQuantity + amount

            pantryDoc.updateData(["quantity": newQuantity]) { error in
                if let error = error {
                    print("Error updating quantity: \(error.localizedDescription)")
                } else {
                    print("✅ Pantry \(docID) quantity updated: \(currentQuantity) + \(amount) = \(newQuantity)")
                }
            }
        }
    }
    
// Logs a meal to Firestore under the selected date and meal type
    func logMeal(for meal: MealPlanner, amount: Double, type: MealType) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: selectedDate)

        let logRef = Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("mealLogs")
            .document(today)

        let mealData: [String: Any] = [
            "name": meal.name,
            "foodID": meal.foodID,
            "amount": amount,
            "consumed_unit": meal.consumedUnit ?? "g",
            "calories": meal.calories,
            "protein": meal.protein,
            "carbs": meal.carbs,
            "fat": meal.fat,
            "pantryDocID": meal.pantryDocID,
            "actual_consumed_pantry_amount": meal.actualConsumedPantryAmount ?? 0.0
        ]

        logRef.setData([type.rawValue.lowercased(): FieldValue.arrayUnion([mealData])], merge: true)
    }
    
// Fetches pantry items from Firestore and filters them based on user preferences
    func fetchMealsAsync() async {
        await withCheckedContinuation { continuation in
            guard let userID = Auth.auth().currentUser?.uid else {
                print("User not authenticated")
                isLoading = false
                continuation.resume()
                return
            }
            let db = Firestore.firestore()
                .collection("users")
                .document(userID)
                .collection("pantry")

            db.getDocuments { snapshot, error in
                if let error = error {
                    print("Failed to fetch pantry items: \(error.localizedDescription)")
                    isLoading = false
                    continuation.resume()
                    return
                }

                guard let snapshot = snapshot else {
                    print("No pantry data found")
                    isLoading = false
                    continuation.resume()
                    return
                }

                let group = DispatchGroup()
                var fetchedMeals: [MealPlanner] = []

                for doc in snapshot.documents {
                    let data = doc.data()
                    guard let foodID = data["id"] as? Int,
                          let name = data["name"] as? String,
                          let quantity = data["quantity"] as? Double,
                          quantity > 0 else {
                        continue
                    }
                    
                    let unit = data["unit"] as? String ?? "g"

                    group.enter()
                    Firestore.firestore().collection("Food").document(String(foodID)).getDocument { foodSnapshot, error in
                        defer { group.leave() }

                        var mealCategory: MealCategory = .prepared  // Default to .prepared

                        if let foodData = foodSnapshot?.data(),
                           let categoryString = foodData["category"] as? String,
                           let parsedCategory = MealCategory(rawValue: categoryString) {
                            mealCategory = parsedCategory
                        } else {
                            print("Could not find category for foodID \(foodID), defaulting to .prepared")
                        }
                        
                        let calories = foodSnapshot?.data()?["calories"] as? Int ?? 0
                        let protein = foodSnapshot?.data()?["protein"] as? Double ?? 0.0
                        let carbs = foodSnapshot?.data()?["carbohydrates"] as? Double ?? 0
                        let fat = foodSnapshot?.data()?["fat"] as? Double ?? 0.0
                        let dietaryTags = foodSnapshot?.data()?["tags"] as? [String] ?? []

                        let meal = MealPlanner(
                            pantryDocID: doc.documentID,
                            name: name,
                            foodID: String(foodID),
                            imageURL: nil,
                            category: mealCategory,
                            quantity: quantity,
                            dietaryTags: dietaryTags,
                            calories: calories,
                            protein: protein,
                            carbs: carbs,
                            fat: fat,
                            unit: unit
                        )
                        fetchedMeals.append(meal)
                    }
                }
                group.notify(queue: .main) {
                    guard let goal = userManager.currentUser?.profile.goal,
                          let preferences = userManager.currentUser?.profile.dietaryPreferences else {
                        print("Missing user goal or preferences")
                        self.mealPlan = fetchedMeals // fallback
                        isLoading = false
                        continuation.resume()
                        return
                    }
                    self.mealPlan = fetchedMeals
                    isLoading = false
                    continuation.resume()
                }
            }
        }
    }
    
// Removes a meal from Firestore log for a specific date and type
    func removeMealFromFirestore(_ meal: MealPlanner, for date: Date, type: MealType) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        let logRef = Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("mealLogs")
            .document(dateString)
        logRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  var array = data[type.rawValue.lowercased()] as? [[String: Any]] else {
                print("Could not get array to update or data is missing")
                return
            }

            array.removeAll {
                ($0["foodID"] as? String == meal.foodID) &&
                ($0["name"] as? String == meal.name)
            }

            logRef.updateData([
                type.rawValue.lowercased(): array
            ]) { error in
                if let error = error {
                    print("Error updating Firestore: \(error.localizedDescription)")
                } else {
                    print("Removed from Firestore successfully")
                }
            }
        }
    }

}

// View for showing AI-generated recipe based on selected ingredients
struct MealGenerationView: View {
    var selectedMeals: Set<MealPlanner>
    @Environment(\.dismiss) var dismiss
    @State private var foodAliases: [FoodAlias] = []
    @State private var recipe: String = "Generating your recipe..."
    
    @State private var showSaveConfirmation = false

    var body: some View {
        NavigationView {
                ZStack {
                    // Background scrollable content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            
                            // Recipe currently displayed as plain text from AI
                            Text(recipe)
 
                            Text("⚠️ Disclaimer ⚠️")
                                .font(.headline)
                                .padding(.top)
                            Text("These recipes are generated using AI and are for informational purposes only. Please use your best judgment when preparing and consuming meals. Always ensure ingredients are safe to eat, properly cooked, and that any allergies or dietary restrictions are considered. FitPantry is not responsible for any adverse effects resulting from the use of AI-generated content.")
                            // Makes space above the fixed button
                            Spacer(minLength: 80)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }

                    // Fixed bottom buttons with solid background
                    VStack(spacing: 0) {
                        Spacer()

                        ZStack {
                            // Background layer (solid white)
                            Rectangle()
                                .fill(Color.white)
                                .frame(height: 80)
                                .shadow(radius: 5)

                            // Button row
                            HStack(spacing: 16) {
                                Button(action: {
                                    saveRecipe()
                                }) {
                                    Text("Save Recipe")
                                        .font(.headline)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.navy)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                .alert(isPresented: $showSaveConfirmation) {
                                    Alert(
                                        title: Text("Recipe Saved!"),
                                        dismissButton: .default(Text("OK"))
                                    )
                                }


                                Button(action: {
                                    generate()
                                }) {
                                    Text("Regenerate")
                                        .font(.headline)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color("BackgroundColor"))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                }
            
            .navigationTitle("Generated Recipe")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                fetchAliasesAndGenerate()
            }
        }
    }
    
    // Used with Legacy AI and is no longer implemented
    func fetchAliasesAndGenerate() {
        let db = Firestore.firestore()
        let foodIDs = selectedMeals.map { $0.foodID }
        var fetchedAliases: [FoodAlias] = []
        let group = DispatchGroup()

        for id in foodIDs {
            group.enter()
            db.collection("Food").document(id).getDocument { docSnapshot, error in
                defer { group.leave() }

                if let doc = docSnapshot, let data = doc.data() {
                    let alias = data["alias"] as? String ?? "Unknown Alias"
                    let name = data["name"] as? String ?? "Unknown Name"
                    let food = FoodAlias(id: id, alias: alias, name: name)
                    if !(alias == "prepared_na") {
                        fetchedAliases.append(food)
                    }
                } else {
                    let food = FoodAlias(id: id, alias: "Unknown Alias", name: "Unknown Name")
                    fetchedAliases.append(food)
                }
            }
        }

        group.notify(queue: .main) {
            self.foodAliases = fetchedAliases
            generate()
        }
    }
    
    // Makes API call to generate recipe
    func generate() {
        recipe = "Generating your recipe..."
        //let ingredients = foodAliases.map { $0.alias }
        let ingredients = foodAliases.map { $0.name }

        Fit_Pantry.generateRecipeWithOpenAI(ingredients: ingredients) { result in
            DispatchQueue.main.async {
                if let result = result {
                    recipe = result
                    print(recipe)
                } else {
                    recipe = "Failed to generate recipe. Please try again."
                }
            }
        }
    }
    
    // Save's recipe to users saved recipes in Firestore
    func saveRecipe() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }
        
        let db = Firestore.firestore()
        let docRef = db.collection("users")
            .document(userID)
            .collection("SavedRecipes")
            .document()
        
        // Get title from recipe
        let title = recipe.components(separatedBy: .newlines).first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Untitled Recipe"
        
        // Remove the title line and trim whitespace/newlines
        let lines = recipe.components(separatedBy: .newlines)
        let cleanedRecipeText = lines
            .dropFirst() // drops the first line regardless
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let recipeData: [String: Any] = [
            "title": title,
            "recipeText": cleanedRecipeText,
            "ingredients": foodAliases.map { $0.name },
            "timestamp": Timestamp(date: Date())
        ]

        docRef.setData(recipeData) { error in
            if let error = error {
                print("Error saving recipe: \(error.localizedDescription)")
            } else {
                print("Recipe saved successfully!")
                showSaveConfirmation = true
            }
        }
    }
}

struct QuantityInputRow: View {
    let meal: MealPlanner
    @Binding var amount: String
    @Binding var selectedUnit: String
    let error: String?

    let units = ["g", "oz", "cup", "tbsp", "tsp", "slice", "can", "loaf", "lbs", "kg", "ml", "L", "gal"]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(meal.name)
                .font(.subheadline)

            HStack {
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Picker("Unit", selection: $selectedUnit) {
                    ForEach(units, id: \.self) { unit in
                        Text(unit).tag(unit)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 80)
            }

            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 5)
    }
}

// Parses string input like "0.5" into a Double value
func parseFraction(from string: String) -> Double? {
    let trimmed = string.trimmingCharacters(in: .whitespaces)
    
    if let value = Double(trimmed) {
        return value
    }
    
    if trimmed.contains("/") {
        let parts = trimmed.split(separator: "/")
        if parts.count == 2,
           let numerator = Double(parts[0]),
           let denominator = Double(parts[1]),
           denominator != 0 {
            return numerator / denominator
        }
    }
    
    return nil
}



struct MealPlanView_Previews: PreviewProvider {
    static var previews: some View {
        MealPlanView().environmentObject(TodayMealManager())
    }
}
