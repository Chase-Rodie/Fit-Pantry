//
//  MainWorkoutView.swift
//  Fit Pantry
//
//  Created by Lexie Reddon on 3/16/25.
//  This is the entry view for the workout tab. If user has a workout plan already, then it displays the workout plan. If the user does not have a workout plan yet, it prompts them to create one.

import SwiftUI

struct MainWorkoutView: View {
    @StateObject private var viewModel = RetrieveWorkoutData()
    @State private var hasAppeared = false

    
    var body: some View {
        Group{
            if viewModel.isWorkoutPlanAvailable{
                WeeklyWorkoutView(workoutPlanModel: viewModel)
            } else {
                GetWorkoutPlanView(workoutPlanModel: viewModel)
            }
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true

            viewModel.workoutPlanExists { exists in
                DispatchQueue.main.async {
                    viewModel.isWorkoutPlanAvailable = exists
                    if exists {
                        viewModel.fetchWorkoutPlan()
             
                    }
                }
            }
        }
    }
}


struct GetWorkoutPlanView: View {
    @ObservedObject var workoutPlanModel: RetrieveWorkoutData
    //@Binding  var isLoading: Bool
    @State var days = 0
    let numDays = ["3", "4", "5"]
    @State var dur = 0
    let duration = ["30", "60"]
    @State var diff = 0
    let difficulty = ["Beginner", "Intermediate", "Expert"]
    
    var body: some View {
        ZStack{
            
            LinearGradient(colors:[.background, .lighter], startPoint:  .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack{
                Text("You do not currently have a workout plan.")
                    .fontWeight(.semibold)
                Text("Please fill out the form below to get one!")
                    .fontWeight(.semibold)
             
                VStack{
                        Text("Workout Duration in Minutes")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Picker("Minutes", selection: $dur){
                            ForEach(duration.indices, id:\.self){i in                        Text(self.duration[i])
                            }
                        }.pickerStyle(.segmented)
                        
                        Text("Number of Days")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Picker("Days", selection: $days){
                                ForEach(numDays.indices, id:\.self){i in                        Text(self.numDays[i])
                                }
                        }.pickerStyle(.segmented)
                    
                        Text("Diffculty Level")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Picker("Difficulty", selection: $diff){
                            ForEach(difficulty.indices, id:\.self){i in                        Text(self.difficulty[i])
                            }
                        }.pickerStyle(.segmented)
                
                    ZStack{
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white).frame(width: 200, height: 25)
                        
                        Button("Get Workout Plan"){
                            print("Generating Workout Plan")
                            
                            var passMax: Int = 0
                            
                            if dur == 0{
                                passMax = 3
                            }else{
                                passMax = 5
                            }
                            
                            
                            if days == 0 {
                                print("3 days")
                                workoutPlanModel.queryExercises(days: [
                                    ("push", ["chest", "shoulders", "triceps"]),
                                    ("pull", ["back", "biceps", "abdominals"]),
                                    ("pull", ["glutes", "quadriceps", "calves", "hamstrings"])
                                ], maxExercises: passMax, level: "beginner", goal: "lose"){
                                    
                                    DispatchQueue.main.async {
                                        
                                        
                                    }
                                    print("Generated Workout Plan: \(workoutPlanModel.workoutPlan)")
                                }
                            }else if days == 1 {
                                print("4 days")
                                
                                workoutPlanModel.queryExercises(days: [
                                    ("push", ["chest", "triceps"]),
                                    ("pull", ["back", "biceps"]),
                                    ("pull", ["glutes", "quadriceps", "calves", "hamstrings"]),
                                    ("pull", ["shoulders", "abdominals"])
                                ], maxExercises: passMax, level: "beginner",goal: "lose"){
                                    
                                    DispatchQueue.main.async {
                                        
                                    }
                                    print("Generated Workout Plan: \(workoutPlanModel.workoutPlan)")
                                }
                            }else if days == 2 {
                                print("5 days")
                                
                                workoutPlanModel.queryExercises(days: [
                                    ("push", ["chest", "shoulders", "triceps"]),
                                    ("pull", ["glutes", "quadriceps", "calves", "hamstrings"]),
                                    ("pull", ["back", "biceps", "abdominals"]),
                                    ("pull", ["calves", "hamstrings"]),
                                    //full body
                                    ("pull", ["quadriceps","shoulders", "hamstrings"])
                                ], maxExercises: passMax, level: "beginner", goal: "lose"){
                                    
                                    DispatchQueue.main.async {
                                        
                                        workoutPlanModel.isWorkoutPlanAvailable = true
                                    }
                                    print("Generated Workout Plan: \(workoutPlanModel.workoutPlan)")
                                }
                            }
                        }
                        .foregroundColor(.black)
                    }
                    .padding(.top, 30)
                    
                } .padding()
                
            }
            
        }
    }
}


#Preview {
    MainWorkoutView()
}
