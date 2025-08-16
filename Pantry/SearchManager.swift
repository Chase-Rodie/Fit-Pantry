//
//  SearchManager.swift
//  Fit Pantry
//
//  Created by Zach Greenhill on 11/29/24.
//
   
import Foundation
import FirebaseFirestore
import Combine

class SearchManager: ObservableObject {
    
    private var db = Firestore.firestore()
    let dbName = "Food" // Change later for production
    
    @Published var items: [Food] = []
    
    // Reserved keywords
    let CAL_KEY = "CALORIES"
    let FAT_KEY = "FAT"
    let CARB_KEY = "CARBS"
    let PROT_KEY = "PROTEIN"
    
    // Function to fetch items based on a search query
    func fetchItems(searchQuery: String) {
        
        // Check to see if there is an equal operator
        let query = processSearchTerm(searchQuery)
        
        // If there is an '=' & there is something before or after it
        if (query.before != nil && query.after != nil) {
            
            var keywordFlag = false
            var keyword = ""
            if (query.before?.uppercased() == CAL_KEY){
                keyword = "Calories"
                keywordFlag = true
            }
            else if (query.before?.uppercased() == FAT_KEY){
                keyword = "Fat (g)"
                keywordFlag = true
            }
            else if (query.before?.uppercased() == CARB_KEY){
                keyword = "Carbohydrate (g)"
                keywordFlag = true
            }
            else if (query.before?.uppercased() == PROT_KEY){
                keyword = "Protein (g)"
                keywordFlag = true
            }
            
            var operandFlag = false
            let operandCheck = parseFirstCharacter(from: query.after ?? "")
            if operandCheck.firstCharacter == "<" || operandCheck.firstCharacter == ">" {
                operandFlag = true
            }
            
            var valueFlag = false
            var value = 0.0
            if operandFlag == true {
                value = Double(operandCheck.remainingString) ?? -1
                if value >= 0 {
                    valueFlag = true
                }
            }
            else {
                value = Double(query.after ?? "") ?? -1
                if value >= 0 {
                    valueFlag = true
                }
            }
            
            if (keywordFlag == true && valueFlag == true) {
                
                // Perform search for items greater than criteria
                if operandCheck.firstCharacter == ">" {
                    getItemGreater(field: keyword, searchQuery: value) { result in
                        switch result {
                        case .success(let fetchedItems):
                            DispatchQueue.main.async {
                                self.items = fetchedItems
                            }
                        case .failure(let error):
                            print("Error fetching items: \(error.localizedDescription)")
                        }
                    }
                }
                
                // Perform search for items less than criteria
                else if operandCheck.firstCharacter == "<" {
                    getItemLess(field: keyword, searchQuery: value) { result in
                        switch result {
                        case .success(let fetchedItems):
                            DispatchQueue.main.async {
                                self.items = fetchedItems
                            }
                        case .failure(let error):
                            print("Error fetching items: \(error.localizedDescription)")
                        }
                    }
                }
                else {
                    getItemByValue(field: keyword, searchQuery: value) { result in
                        switch result {
                        case .success(let fetchedItems):
                            DispatchQueue.main.async {
                                self.items = fetchedItems
                            }
                        case .failure(let error):
                            print("Error fetching items: \(error.localizedDescription)")
                        }
                    }
                }
            }
            else {
                getItemByName(searchQuery: searchQuery) { result in
                    switch result {
                    case .success(let fetchedItems):
                        DispatchQueue.main.async {
                            // Filter the items locally after fetching all of them
                            self.items = self.filterItems(fetchedItems, withQuery: searchQuery)
                        }
                    case .failure(let error):
                        print("Error fetching items: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        // Search by name (if there's no '=' in query)
        else {
            getItemByName(searchQuery: searchQuery) { result in
                switch result {
                case .success(let fetchedItems):
                    DispatchQueue.main.async {
                        // Filter the items locally after fetching all of them
                        self.items = self.filterItems(fetchedItems, withQuery: searchQuery)
                    }
                case .failure(let error):
                    print("Error fetching items: \(error.localizedDescription)")
                }
            }
        }
    }

    
    // Function to filter items based on the search query (case-insensitive partial matching)
    func filterItems(_ items: [Food], withQuery query: String) -> [Food] {
        // Make the query case-insensitive
        let lowercasedQuery = query.lowercased()
        return items.filter { food in
            food.name.lowercased().contains(lowercasedQuery) ||
            food.foodGroup.lowercased().contains(lowercasedQuery) ||
            String(food.calories).contains(lowercasedQuery) ||
            String(food.fat).contains(lowercasedQuery) ||
            String(food.carbohydrates).contains(lowercasedQuery) ||
            String(food.protein).contains(lowercasedQuery)
        }
    }

    func getItemByName(searchQuery: String, completion: @escaping (Result<[Food], Error>) -> Void) {
        db.collection(dbName)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let snapshot = snapshot else {
                    completion(.success([]))
                    return
                }

                // Log the document data to ensure correct data
                snapshot.documents.forEach { document in
                    print("Fetched document data: \(document.data())")
                }

                // Map Firestore data to Food model with rounding
                let fetchedItems: [Food] = snapshot.documents.compactMap { d in
                    let calories = (d["Calories"] as? Double ?? 0.0)
                    let fat = (d["Fat (g)"] as? Double ?? 0.0)
                    let carbohydrates = (d["Carbohydrate (g)"] as? Double ?? 0.0)
                    let protein = (d["Protein (g)"] as? Double ?? 0.0)
                    
                    let food = Food(
                        id: d.documentID,
                        name: d["name"] as? String ?? "",
                        foodGroup: d["Food Group"] as? String ?? "",
                        food_id: d["ID"] as? Int32 ?? 0,
                        calories: calories,
                        fat: fat,
                        carbohydrates: carbohydrates,
                        protein: protein,
                        suitableFor: d["suitableFor"] as? [String] ?? []
                    )
                    return food
                }

                // Return the successfully fetched items
                completion(.success(fetchedItems))
            }
    }
    
    func getItemGreater(field: String, searchQuery: Double, completion: @escaping (Result<[Food], Error>) -> Void) {
        db.collection(dbName)
            .whereField(field, isGreaterThan: searchQuery)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let snapshot = snapshot else {
                    completion(.success([]))
                    return
                }

                let fetchedItems: [Food] = snapshot.documents.compactMap { d in
                    return Food(
                        id: d.documentID,
                        name: d["name"] as? String ?? "",
                        foodGroup: d["Food Group"] as? String ?? "",
                        food_id: d["ID"] as? Int32 ?? 0,
                        calories: d["Calories"] as? Double ?? 0.0,
                        fat: d["Fat (g)"] as? Double ?? 0.0,
                        carbohydrates: d["Carbohydrate (g)"] as? Double ?? 0.0,
                        protein: d["Protein (g)"] as? Double ?? 0.0,
                        suitableFor: d["suitableFor"] as? [String] ?? []
                    )
                }
                
                completion(.success(fetchedItems))
            }
    }
    
    func getItemLess(field: String, searchQuery: Double, completion: @escaping (Result<[Food], Error>) -> Void) {
        db.collection(dbName)
            .whereField(field, isLessThan: searchQuery)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let snapshot = snapshot else {
                    completion(.success([]))
                    return
                }

                let fetchedItems: [Food] = snapshot.documents.compactMap { d in
                    return Food(
                        id: d.documentID,
                        name: d["name"] as? String ?? "",
                        foodGroup: d["Food Group"] as? String ?? "",
                        food_id: d["ID"] as? Int32 ?? 0,
                        calories: d["Calories"] as? Double ?? 0.0,
                        fat: d["Fat (g)"] as? Double ?? 0.0,
                        carbohydrates: d["Carbohydrate (g)"] as? Double ?? 0.0,
                        protein: d["Protein (g)"] as? Double ?? 0.0,
                        suitableFor: d["suitableFor"] as? [String] ?? []
                    )
                }
                
                completion(.success(fetchedItems))
            }
    }

    func getItemByValue(field: String, searchQuery: Double, completion: @escaping (Result<[Food], Error>) -> Void) {
        db.collection(dbName)
            .whereField(field, isEqualTo: searchQuery)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let snapshot = snapshot else {
                    completion(.success([]))
                    return
                }

                let fetchedItems: [Food] = snapshot.documents.compactMap { d in
                    return Food(
                        id: d.documentID,
                        name: d["name"] as? String ?? "",
                        foodGroup: d["Food Group"] as? String ?? "",
                        food_id: d["ID"] as? Int32 ?? 0,
                        calories: d["Calories"] as? Double ?? 0.0,
                        fat: d["Fat (g)"] as? Double ?? 0.0,
                        carbohydrates: d["Carbohydrate (g)"] as? Double ?? 0.0,
                        protein: d["Protein (g)"] as? Double ?? 0.0,
                        suitableFor: d["suitableFor"] as? [String] ?? []
                    )
                }
                
                completion(.success(fetchedItems))
            }
    }
    
    // Helper function to process search term (split by '=')
    func processSearchTerm(_ searchTerm: String) -> (before: String?, after: String?) {
        let components = searchTerm.split(separator: "=").map { String($0).trimmingCharacters(in: .whitespaces) }
        if components.count == 2 {
            return (before: components[0], after: components[1])
        }
        return (before: nil, after: nil)
    }
    
    // Helper function to parse first character (for operands like < or >)
    func parseFirstCharacter(from string: String) -> (firstCharacter: String, remainingString: String) {
        let firstCharacter = String(string.prefix(1))
        let remainingString = String(string.dropFirst())
        return (firstCharacter, remainingString)
    }
}
