//
//  HamburgerMenuView.swift
//  Fit Pantry
//
//  Created by Lexie Reddon on 11/30/24.
//

//import SwiftUI
//
//struct HamburgerMenuView: View {
//    var body: some View {
//        VStack(alignment: .leading){
//            HStack{
//                Image(systemName: "star")
//                    .foregroundColor(.black)
//                    .imageScale(.large)
//                Text("Favorite Recipes")
//                    .foregroundColor(.black)
//                    .font(.headline)
//            }
//            .padding(.top, 100)
//            HStack{
//                Image(systemName: "person")
//                    .foregroundColor(.black)
//                    .imageScale(.large)
//                Text("Profile")
//                    .foregroundColor(.black)
//                    .font(.headline)
//            }
//            .padding(.top, 30)
//            HStack{
//                Image(systemName: "gear")
//                    .foregroundColor(.black)
//                    .imageScale(.large)
//                Text("Settings")
//                    .foregroundColor(.black)
//                    .font(.headline)
//            }
//            .padding(.top, 30)
//            Spacer()
//        }
//        .padding()
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .background(Color("LighterColor"))
//
//    }
//}
//
//struct HamburgerMenuView_Previews: PreviewProvider {
//    static var previews: some View {
//      HamburgerMenuView()
//    }
//}

import SwiftUI

struct HamburgerMenuView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "star")
                    .foregroundColor(.black)
                    .imageScale(.large)
                Text("Favorite Recipes")
                    .foregroundColor(.black)
                    .font(.headline)
            }
            .padding(.top, 100)
            
            //NavigationLink(destination: ProfileView(showSignInView: .constant(false))) {
                //HStack {
                    //Image(systemName: "person")
                        //.foregroundColor(.black)
                        //.imageScale(.large)
                   // Text("Profile")
                        //.foregroundColor(.black)
                        //.font(.headline)
                //}
            //}
            //.padding(.top, 30)
            
            //NavigationLink(destination: SettingsView(showSignInView: .constant(false))) {
                //HStack {
                    //Image(systemName: "gear")
                        //.foregroundColor(.black)
                        //.imageScale(.large)
                    //Text("Settings")
                       // .foregroundColor(.black)
                        //.font(.headline)
                //}
            //}
            //.padding(.top, 30)
            
            //Divider()
               // .padding(.vertical, 20)

            NavigationLink(destination: ShoppingListView()) {
                HStack {
                    Image(systemName: "cart")
                        .foregroundColor(.black)
                        .imageScale(.large)
                    Text("Shopping List")
                        .foregroundColor(.black)
                        .font(.headline)
                }
            }
            .padding(.top, 10)

            NavigationLink(destination: MealPlanView()) {
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.black)
                        .imageScale(.large)
                    Text("Meal Plan")
                        .foregroundColor(.black)
                        .font(.headline)
                }
            }
            .padding(.top, 10)

            Spacer()

            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
//                HStack {
//                    Image(systemName: "xmark.circle.fill")
//                        .foregroundColor(.red)
//                        .imageScale(.large)
//                    Text("Close Menu")
//                        .foregroundColor(.red)
//                        .font(.headline)
//                }
//                .padding(.bottom, 30)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("LighterColor"))
    }
}

struct HamburgerMenuView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HamburgerMenuView()
        }
    }
}
