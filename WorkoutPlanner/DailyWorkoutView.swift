//
//  DailyWorkoutView.swift
//  Fit Pantry
//
//  Created by Lexie Reddon on 4/1/25.
//  DailyWorkoutView provides the UI for when an individual day is selected on the user's plan.

import SwiftUI

struct DailyWorkoutView: View {
    let dayIndex: Int
    let dayWorkoutPlan: [Exercise]
    @ObservedObject var workoutPlanModel: RetrieveWorkoutData
    @State private var manualWorkoutFormShowing = false

    var body: some View {
        ScrollView{
            VStack{
                Spacer()
                
                Text("Day \(dayIndex + 1) ")
                        .foregroundColor(.green)
                        .font(.system(size: 36, weight: .bold))
                        .fontWeight(.bold)
              
                let muscleGroupKey = "muscleGroupDay\(dayIndex + 1)"
                Text("Muscle Groups: \(workoutPlanModel.workoutMetadata[muscleGroupKey] as? String ?? "")")
                Divider()
                    .background(Color.black)
                    .frame(width: 350)
               
                Button(action: {
                    manualWorkoutFormShowing = true
                }) {
                    HStack {
                        Text("Add My Own Workout")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 180, height: 25)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                } .sheet(isPresented: $manualWorkoutFormShowing){
                    AddWorkoutForm(day: dayIndex+1 , workoutPlanModel: workoutPlanModel, manualWorkoutFormShowing: $manualWorkoutFormShowing)
                }
                VStack(alignment: .leading){
                    VStack {
                        Text("Manually Logged Workouts")
                            .font(.subheadline)
                            .fontWeight(.bold)

                        if !workoutPlanModel.manualWorkoutsToday.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(workoutPlanModel.manualWorkoutsToday) { workout in
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack{
                                                Text(workout.name)
                                                    .font(.headline)
                                                
                                                Button(action: {
                                                    workoutPlanModel.deleteManualWorkout(day: dayIndex+1, workout: workout)
                                                }) {
                                                    Image(systemName: "trash")
                                                        .foregroundColor(.red)
                                                        .padding(8)
                                                        .background(Color.white)
                                                        .clipShape(Circle())
                                                }
                                            }

                                            if workout.type.lowercased() == "cardio" {
                                                                            Text("Duration: \(workout.duration) min")
                                                                                .font(.subheadline)
                                                                            if workout.distance > 0 {
                                                                                Text("Distance: \(workout.distance) miles")
                                                                                    .font(.subheadline)
                                                                            }
                                                                        } else if workout.type.lowercased() == "flexibility" {
                                                                            Text("Duration: \(workout.duration) min")
                                                                                .font(.subheadline)
                                                                        } else if workout.type.lowercased() == "strength" {
                                                                            if !workout.exercises.isEmpty {
                                                                                Text("Exercises:")
                                                                                    .font(.subheadline)
                                                                                    .bold()
                                                                                
                                                                                ForEach(workout.exercises.indices, id: \.self) { index in
                                                                                    let exercise = workout.exercises[index]
                                                                                    Text("- \(exercise["name"] as? String ?? "Unnamed Exercise")")
                                                                                        .font(.caption)
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                        .padding()
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                        .padding(.vertical, 5)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            Text("No manual entered workouts today.")
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                    .padding()

                    
                    ForEach(dayWorkoutPlan){exercise in
                        ExerciseRowView(exercise: exercise, workoutPlanModel: workoutPlanModel, dayIndex: dayIndex)
                    }
                }.padding()
               
            }
            .onAppear {
                workoutPlanModel.fetchManuallyEnteredWorkoutsForDay(day: dayIndex+1)
            }

        }.accentColor(.green)
    }
}



struct ExerciseRowView: View {
    let exercise: Exercise
    let workoutPlanModel: RetrieveWorkoutData
    var dayIndex: Int

    var body: some View {
        
        HStack {
            if let firstImageURL = exercise.imageURLs.first, let url = URL(string: firstImageURL) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipped()
                } placeholder: {
                    ProgressView()
                }
            }
            VStack(alignment: .leading) {
                NavigationLink(exercise.name, destination: DetailedExercise(exercise: exercise, workoutPlanModel: workoutPlanModel, dayIndex: dayIndex))
                Text("Sets: \(exercise.sets)")
                Text("Reps: \(exercise.reps)")
            }
            
            Image(systemName: workoutPlanModel.isExerciseCompleted(exercise: exercise) ? "checkmark.square" : "square")
                                        .foregroundColor(.green)
                                        .font(.system(size: 30))
        }
    }
}


struct DetailedExercise: View {
    var exercise: Exercise
    @ObservedObject var workoutPlanModel: RetrieveWorkoutData
    @State private var isStarFilled = false
    @State private var isFavorited: Bool = false
    var dayIndex: Int


    var body: some View{
        ZStack{
            ScrollView{
                VStack(alignment: .leading, spacing: 16){
                    
                    if let firstImageURL = exercise.imageURLs.first, let url = URL(string: firstImageURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(maxHeight: 250)
                                .clipped()
                                .padding(.horizontal, 12)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                    
                    VStack{
                        HStack{
                            Text(exercise.name)
                                .font(.title)
                                .bold()
                                .padding(.bottom, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button(action: {
                                workoutPlanModel.toggleFavoriteStatus(for: exercise)
                                self.isFavorited.toggle()
                                    }) {
                                        Image(systemName: self.isFavorited ? "star.fill" : "star")
                                            .foregroundColor(.navy)
                                            .font(.system(size: 30))

                                    }
                        }
                        Text("Reccomended \(exercise.sets) sets of \(exercise.reps) reps")
                        
                        ForEach(0..<exercise.sets, id:\.self){ setIndex in
                            weightEntryView(exercise: exercise, workoutPlanModel: workoutPlanModel, setIndex: setIndex, dayIndex: dayIndex)
                            
                        }
                        HStack{
                                Text("Exercise done: ")
                                Image(systemName: workoutPlanModel.isExerciseCompleted(exercise: exercise) ? "checkmark.square" : "square")
                                    .foregroundColor(.green)
                                    .font(.system(size: 30))
                        }
                        
                        Button(action: {
                            workoutPlanModel.markComplete(for: exercise)
                            FeedbackManager.shared.playSuccessSoundIfEnabled()
                            FeedbackManager.shared.vibrateIfEnabled()
                        }) {
                            HStack {
                                Text("Complete Exercise")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(width: 200, height: 50)
                                    .background(Color.green)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.vertical)
                        
                        Text("Instructions:")
                            .font(.headline)
                        ForEach(exercise.instructions, id:\.self){ step in
                            HStack(alignment: .top, spacing: 8){
                                Text("•")
                                    .font(.body)
                                    .frame(width: 20, alignment: .leading)
                                Text(step)
                                    .font(.body)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .onAppear {
            workoutPlanModel.isExerciseFavorited(exercise: exercise) { isFavorited in
                self.isFavorited = isFavorited
            }
        }
        .hideKeyboardOnTap()
    }
}



struct weightEntryView: View{
    @State private var reps: Int?
    @State private var weight: Int?
    
    var exercise: Exercise
    var workoutPlanModel: RetrieveWorkoutData
    var setIndex: Int
    var dayIndex: Int
    
    var body: some View {
        HStack{
            Text("\(setIndex+1)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.green)
                .clipShape(Circle())
                
            
            TextField("Reps", value: $reps, formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .onChange(of: reps) { newReps in
                       // Automatically save when the value changes
                       if let reps = newReps, let weight = weight {
                           workoutPlanModel.updateRecordedSets(for: exercise, reps: reps, weight: Double(weight), day: dayIndex, setIndex: setIndex)
                       }
                   }
            
            TextField("Weight in lbs", value: $weight, formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .onChange(of: weight) { newValue in
                       if let reps = reps, let weight = newValue {
                           workoutPlanModel.updateRecordedSets(for: exercise, reps: reps, weight: Double(weight), day: dayIndex, setIndex: setIndex)
                       }
                   }
          
            Spacer()
        }
                .padding()
                .onAppear{
                    workoutPlanModel.fetchRecordedSets(for: exercise, day: dayIndex){ sets in
                        if setIndex < sets.count {
                            if let fetchedReps = sets[setIndex]["reps"] as? Int {
                                reps = fetchedReps
                            }
                            if let fetchedWeight = sets[setIndex]["weight"] as? Double{
                                weight = Int(fetchedWeight)
                            }
                        }
                        
                    }
                }
            }
}


struct AddWorkoutForm: View{
    
    let day: Int
    @ObservedObject var workoutPlanModel: RetrieveWorkoutData
    @Binding var manualWorkoutFormShowing: Bool
    
    @State var workoutType = 0
    let workoutTypes = ["Strength", "Cardio", "Flexibility"]
    @State var workoutName: String = ""
    
    //For strength type
    @State var exercises = 1
    let numExercises = Array(1...5)
    let numberOptions = Array(1...15)
    @State private var setsList = Array(repeating: 1, count: 5)
    @State private var repsList = Array(repeating: 1, count: 5)
    @State private var exerciseNamesList: [String] = Array(repeating: "", count: 5)

    
    //For cardio & flexibility type
    @State var dur: Int = 5
    @State var dist: Int = 1
    
    let durOptions = Array(5...120)
    let distOptions = Array(1...20)

   
    var body: some View{
        Form{
            Section(header: Text("Workout Type")){
                Picker("Type", selection: $workoutType){
                    ForEach(workoutTypes.indices, id: \.self){i in
                        Text(self.workoutTypes[i])
                    }
                } .pickerStyle(SegmentedPickerStyle())
            }
            Section(header: Text("Workout Name")){
                TextField("Workout Name", text: $workoutName)
            }
            
            if workoutType == 0 {
                Section(header: Text("Number of Exercises:")){
                    Picker("Exercises", selection: $exercises){
                        ForEach(numExercises, id: \.self){number in
                            Text("\(number)").tag(number)
                        }
                    }
                    
                }
                ForEach(1..<exercises+1, id: \.self){ i in
                    Section(header: Text("Exercise")){
                        TextField("Exercise Name", text: $exerciseNamesList[i])
                        Picker("Sets", selection: $setsList[i]) {
                            ForEach(numberOptions, id: \.self) {
                                Text("\($0)").tag($0)
                            }
                        }
                        Picker("Reps", selection: $repsList[i]) {
                            ForEach(numberOptions, id: \.self) {
                                Text("\($0)").tag($0)
                            }
                        }
                    }
                }
            }else if workoutType == 1{
                Section(header: Text("Duration")){
                    Picker("Duration (min)", selection: $dur){
                        ForEach(durOptions, id: \.self){value in
                            Text("\(value) min")
                        }
                    }
                }
                Section(header: Text("Distance")){
                    Picker("Distance (miles)", selection: $dist){
                        ForEach(distOptions, id: \.self){value in
                            Text("\(value) miles")
                        }
                    }
                }
                
                
                
            }else if workoutType == 2{
                Section(header: Text("Duration")){
                    Picker("Duration (min)", selection: $dur){
                        ForEach(durOptions, id: \.self){value in
                            Text("\(value) min")
                        }
                    }
                }
                
            }
            
            Section(header: Text("Submit"))
            {
                Button("Submit"){
                    let selectedType = workoutTypes[workoutType]
                    
                    var manualExercises: [[String: Any]] = []
                    if selectedType == "Strength" {
                        for i in 1...exercises {
                            let exercise: [String: Any] = [
                                "name": exerciseNamesList[i],
                                "sets": setsList[i],
                                "reps": repsList[i]
                            ]
                            manualExercises.append(exercise)
                        }
                    }
                    workoutPlanModel.saveManuallyEnteredWorkout(name: workoutName, type: selectedType, exercises: manualExercises, day: day, duration: dur, distance: dist)
                    workoutPlanModel.fetchManuallyEnteredWorkoutsForDay(day: day)

                    manualWorkoutFormShowing = false
                }
            }
            
        }
    }
    
    
}
extension View {
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        
    }
}
