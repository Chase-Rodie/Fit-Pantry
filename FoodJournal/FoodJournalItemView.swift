//
//  FoodJournalitemView.swift
//  Fit Pantry
//
//  Created by Lexie Reddon on 2/16/25.
//

import SwiftUI

struct FoodJournalItemView: View {
    let item: FoodJournalItem
    let mealName: String
    
    @ObservedObject var viewModel: FoodJournalViewModel
    
    var body: some View {
        ZStack(alignment: .topLeading){
            
            LinearGradient(colors:[.background, .lighter], startPoint:  .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            HStack{
                VStack(alignment: .leading, spacing: 10){
                    Text(item.name)
                        .bold()
                        .font(.system(size: 30))
                    Text("Quantity: "+item.quantity.description + " " + item.unit.description)
                    Text("Calories: "+item.calories.description)
                    Text("Fats: \(String(format: "%.1f", item.fat)) g")
                    Text("Carbohydrates: \(String(format: "%.1f", item.carbohydrates)) g")
                    Text("Protein: \(String(format: "%.1f", item.protein)) g")
                    //Text("Show More")
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }
}

/*
#Preview {
    FoodJournalItemView(item: FoodJournalItem(id: "1", name: "Banana", foodGroup: "Fruits", food_id: "101", calories: 100, fat: 0.3, carbohydrates: 27, protein: 1.3, suitableFor: ["Vegan", "Gluten-Free"], quantity: 2.4), mealName: "breakfast", viewModel: FoodJournalViewModel())
}
*/
