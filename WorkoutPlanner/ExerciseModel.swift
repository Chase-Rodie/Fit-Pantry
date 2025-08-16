//
//  Exercise.swift
//  Fit Pantry
//
//  Created by Lexie Reddon on 11/26/24.
//

import Foundation

struct Exercise: Decodable,Encodable,Identifiable{
    var category: String
    var equipment: String
    var force: String
    var id: String
    var imageURLs: Array<String>
    var instructions: Array<String>
    var level: String
    var mechanic: String
    var name: String
    var primaryMuscles: Array<String>
    var secondaryMuscles: Array<String>
    var isComplete: Bool = false
    var weightUsed: Double?
    var sets: Int
    var reps: Int
    
    init(
        category: String,
        equipment: String,
        force: String,
        id: String,
        imageURLs: [String],
        instructions: [String],
        level: String,
        mechanic: String,
        name: String,
        primaryMuscles: [String],
        secondaryMuscles: [String],
        isComplete: Bool,
        weightUsed: Double? = nil,
        sets: Int,
        reps: Int
    ) {
        self.category = category
        self.equipment = equipment
        self.force = force
        self.id = id
        self.imageURLs = imageURLs
        self.instructions = instructions
        self.level = level
        self.mechanic = mechanic
        self.name = name
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.isComplete = isComplete
        self.weightUsed = weightUsed
        self.sets = sets
        self.reps = reps
    }
    var recordedSets: [[String: Int]] = []
}



struct ManualWorkout: Identifiable {
    let id: String
    let name: String
    let type: String
    let duration: Int
    let distance: Int
    let exercises: [[String: Any]]
}

// Extension for Mock tests (might get rid of later)

extension Exercise {
    // Trying to test using mock stuff
    static func mock(name: String, category: String) -> Exercise {
        return Exercise(
            category: category,
            equipment: "",
            force: "",
            id: UUID().uuidString,
            imageURLs: [],
            instructions: [],
            level: "",
            mechanic: "",
            name: name,
            primaryMuscles: [],
            secondaryMuscles: [],
            isComplete: false,
            weightUsed: nil,
            sets: 3,  
            reps: 10
        )
    }
}
