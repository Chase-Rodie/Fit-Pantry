import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PantryView: View {
    @State private var pantryItems: [PantryItem] = []
    @State private var errorMessage: String? = nil
    @State private var isLoading = true
    @State private var showEditSheet: Bool = false
    @State private var selectedItem: PantryItem?
    @State private var newQuantity: String = ""
    @State private var newQuantityDbl: Double = 0.0
    @State private var selectedUnits: [String: String] = [:]


    // Function to fetch pantry items
    private func fetchPantryItems() {
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        let db = Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("pantry")
        
        db.getDocuments { snapshot, error in
            isLoading = false
            
            if let error = error {
                self.errorMessage = "Failed to fetch pantry items: \(error.localizedDescription)"
                return
            }
            
            guard let snapshot = snapshot else {
                self.errorMessage = "No pantry data found"
                return
            }
            
            self.pantryItems = snapshot.documents.compactMap { doc in
                let data = doc.data()
                let id = doc.documentID
                let food_id = data["id"] as? Int ?? 0
                let name = data["name"] as? String ?? "Unknown Item"
                let quantity = data["quantity"] as? Double ?? 0.0
                let unit = data["unit"] as? String ?? "g"
                
                return PantryItem(id: id, food_id: food_id, name: name, quantity: quantity, unit: unit)
                //return PantryItem(id: id, food_id: food_id, name: name, quantity: quantity)
            }
            
            self.errorMessage = nil
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView()
                    Text("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                }
                
                if pantryItems.isEmpty {
                    Text("Your pantry is empty")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(pantryItems, id: \.id) { item in
                            Button(action: { editQuantity(item) }) {
                                HStack {
                                    Text(item.name)
                                    Spacer()
                                    Text("\(item.quantity, specifier: "%.1f") \(item.unit)")
                                        .foregroundColor(Color("BackgroundColor"))
                                }
                            }
                        }
                        .onDelete(perform: deletePantryItem)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
                
                NavigationLink(destination: AddFoodView()) {
                    Text("Add Food")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("BackgroundColor"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("My Pantry")
            .onAppear {
                fetchPantryItems()
            }
            .sheet(isPresented: $showEditSheet) {
                VStack {
                    Text("Amount on hand?")
                        .font(.headline)
                        .padding()
                    
//                    TextField("Quantity", text: $newQuantity)
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .keyboardType(.decimalPad)
//                        .padding()
                    
                    HStack {
                        TextField("Quantity", text: $newQuantity)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)

                        Picker("Unit", selection: Binding(
                            get: { selectedUnits[selectedItem?.id ?? ""] ?? "g" },
                            set: { selectedUnits[selectedItem?.id ?? ""] = $0 }
                        )) {
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
                    
                    HStack {
                        Button("Submit") {
                            submitAmount()
                        }
                        .padding()
                        .foregroundColor(Color("Navy"))
                        
                        Spacer()
                        
                        Button("Cancel") {
                            showEditSheet = false
                        }
                        .padding()
                    }
                    .padding()
                }
                .padding()
            }
        }
    }

    private func deletePantryItem(at offsets: IndexSet) {
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }
        
        for index in offsets {
            let itemToDelete = pantryItems[index]
            let db = Firestore.firestore()
                .collection("users")
                .document(userID)
                .collection("pantry")
                .document(itemToDelete.id)
            
            db.delete { error in
                if let error = error {
                    self.errorMessage = "Failed to delete item: \(error.localizedDescription)"
                } else {
                    self.pantryItems.remove(at: index)
                    self.errorMessage = nil
                }
            }
        }
    }

    private func editQuantity(_ item: PantryItem) {
        selectedItem = item
        newQuantity = ""
        showEditSheet = true
    }

    private func submitAmount() {
//        guard let selectedItem = selectedItem, let value = Double(newQuantity) else {
//            errorMessage = "Please enter a valid number"
//            return
//        }
//        
//        updatePantryItem(item: selectedItem, value: value)
        guard let selectedItem = selectedItem,
              let rawValue = Double(newQuantity) else {
            errorMessage = "Please enter a valid number"
            return
        }

        let selectedUnit = selectedUnits[selectedItem.id] ?? "g"

        guard let factor = Units[selectedUnit] else {
            errorMessage = "Invalid unit"
            return
        }
        
        updatePantryItem(item: selectedItem, value: rawValue)
        fetchPantryItems()
        showEditSheet = false
    }

    private func updatePantryItem(item: PantryItem, value: Double) {
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }
        
        let db = Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("pantry")
            .document(item.id)
        
//        let data: [String: Any] = [
//            "id": item.food_id,
//            "name": item.name,
//            "quantity": value
//        ]
        let data: [String: Any] = [
            "id": item.food_id,
            "name": item.name,
            "quantity": value,
            "unit": selectedUnits[item.id] ?? "g"  // Store selected unit (like "oz", "cup", etc.)
        ]
        
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
    PantryView()
}
