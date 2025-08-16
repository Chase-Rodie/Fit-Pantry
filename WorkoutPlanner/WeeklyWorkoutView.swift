//
//  ReworkedWorkoutView.swift
//  Fit Pantry
//
//  Created by Lexie Reddon on 3/8/25.
//  WeeklyWorkoutView provides the UI for the weekly summary of workouts. A custom progress ring is used to display the workout progress for each day.

import SwiftUI

struct WeeklyWorkoutView: View {
    
    @StateObject var workoutPlanModel = RetrieveWorkoutData()
    @State private var isLoading: Bool = false
    @State private var progressValues: [Double] = Array(repeating: 0.0, count: 7)
    @State var isShowingDialog = false

    var body: some View {
        ZStack{
            ScrollView{
                Spacer()
                    Text("Weekly Summary")
                        .foregroundColor(.green)
                        .font(.system(size: 36, weight: .bold))
                        .fontWeight(.bold)
                Spacer()
                VStack(alignment: .leading){
                    let numWorkingDays = workoutPlanModel.workoutMetadata["numberOfDays"] as? Int ?? 0
                    let totalDays = 7
                    let numRestDays = totalDays - numWorkingDays
                    HStack{
                        VStack{
                            Text("\(numWorkingDays) Working Days")
                            Text("\(numRestDays) Rest Days")
                        }
                        
                    }
                    
                }
                Divider()
                    .background(Color.black)
                    .frame(width: 350)
               
                
                VStack(alignment: .leading){
                    ForEach(0..<workoutPlanModel.workoutPlan.count, id: \.self){
                        typeIndex in
                        let dayWorkoutPlan = workoutPlanModel.workoutPlan[typeIndex]
                        HStack{
                            ProgressRingView(progress: progressValues[typeIndex+1], ringWidth: 15)
                                .padding(.trailing, 16)
                            VStack(alignment: .leading){
                                HStack{
                                    NavigationLink(destination: DailyWorkoutView(dayIndex: typeIndex, dayWorkoutPlan: dayWorkoutPlan, workoutPlanModel: workoutPlanModel)){
                                        Text("Day \(typeIndex + 1)")
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding()
                                            .frame(width: 100, height: 25)
                                            .background(Color.green)
                                            .cornerRadius(10)
                                    }
                                }
                                let muscleGroupKey = "muscleGroupDay\(typeIndex + 1)"
                                Text("Muscle Groups: \(workoutPlanModel.workoutMetadata[muscleGroupKey] as? String ?? "")")
                                
                            }
                            
                            
                        }.padding(.bottom, 40)
                        
                    }
                    VStack{
                
                    Button(action: {
                        
                        isShowingDialog = true
                        
                    }) {
                        HStack {
                            Text("New workout Plan")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 200, height: 50)
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                    }.confirmationDialog(
                        "Delete?",
                        isPresented: $isShowingDialog
                    ){
                        Button("Delete current workout plan", role: .destructive){
//                            workoutPlanModel.clearAllExerciseCompletionData()
                            workoutPlanModel.deleteWorkoutPlan()
                            print("Workout plan successfully removed.")
                            workoutPlanModel.isWorkoutPlanAvailable = false
                            print("Workout plan has been deleted.")
                        }
                    } message: {
                        Text("You cannot undo this action. All current progress in this workout plan will be lost.")
                    }
                    .padding(.vertical)
                    Text("Don't like this plan? You can generate a new one! This plan will be permanently deleted and all progress for it will be lost.")
                                .font(.footnote)
                }
                } .padding()
            
            }
            .onAppear {
                fetchAllDaysProgress()
            }
            
        }.accentColor(.green)
        
    }
    
    //Fetch the progress of completed workouts for all days. This utilizes a method from retrieveWorkout to do this.
    private func fetchAllDaysProgress() {
        for dayIndex in 0..<7 {
            workoutPlanModel.countCompletedAndTotalExercises(dayIndex: dayIndex) { completed, total in
                let progress = total > 0 ? Double(completed) / Double(total) : 0.0
                
                DispatchQueue.main.async {
                    
                    progressValues[dayIndex] = progress
                }
            }
        }
    }
    
}


struct ProgressRingView: View {
    var progress: Double
    //Progress value between 0.0 and 1.0
    var ringColor: Color = Color("LighterColor")
    var ringWidth: CGFloat = 10.0

    var body: some View {
        ZStack {
                    // Background Circle (empty ring)
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: ringWidth)

                    // Foreground Circle (progress)
                    Circle()
                        .trim(from: 0.0, to: progress)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: progress)

                    
                    Text("\(Int(progress * 100))%")
                        .font(.headline)
                        .bold()
                }
                .frame(width: 100, height: 100)

    }

}







#Preview {
    WeeklyWorkoutView()
}
