//
//  HealthKitManager.swift
//  Fit Pantry
//
//  Created by Heather Amistani on 4/12/25.
//

import Foundation
import HealthKit

// Manages HealthKit interactions
class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()

    private init() {}

    // Requests HealthKit permission to read and write nutritional and step data
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        // Check if HealthKit is available on this device
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data not available on this device")
            completion(false)
            return
        }
        
        // Define all the data types we want to read/write
        guard
            let energy = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed),
            let protein = HKObjectType.quantityType(forIdentifier: .dietaryProtein),
            let fat = HKObjectType.quantityType(forIdentifier: .dietaryFatTotal),
            let carbs = HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates),
            let steps = HKObjectType.quantityType(forIdentifier: .stepCount)
        else {
            print("One or more HealthKit data types are unavailable.")
            completion(false)
            return
        }

        let typesToShare: Set = [energy, protein, fat, carbs, steps]
        let typesToRead: Set = [energy, protein, fat, carbs, steps]

        // Request authorization for reading and writing the defined types
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if success {
                print("HealthKit authorization successful")
            } else {
                print("Authorization failed: \(error?.localizedDescription ?? "unknown error")")
            }
            completion(success)
        }
    }

    // Logs a meal's nutritional data to HealthKit
    func logMealToHealthKit(calories: Double, protein: Double, carbs: Double, fat: Double) {
        let now = Date()

        func createSample(typeIdentifier: HKQuantityTypeIdentifier, value: Double, unit: HKUnit) -> HKQuantitySample? {
            guard let quantityType = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else {
                print("Could not create sample for: \(typeIdentifier.rawValue)")
                return nil
            }
            let quantity = HKQuantity(unit: unit, doubleValue: value)
            return HKQuantitySample(type: quantityType, quantity: quantity, start: now, end: now)
        }

        let samples = [
            createSample(typeIdentifier: .dietaryEnergyConsumed, value: calories, unit: .kilocalorie()),
            createSample(typeIdentifier: .dietaryProtein, value: protein, unit: .gram()),
            createSample(typeIdentifier: .dietaryCarbohydrates, value: carbs, unit: .gram()),
            createSample(typeIdentifier: .dietaryFatTotal, value: fat, unit: .gram())
        ].compactMap { $0 } 

        guard !samples.isEmpty else {
            print("No valid samples to save to HealthKit.")
            return
        }

        healthStore.save(samples) { success, error in
            if success {
                print("Successfully logged meal to HealthKit")
            } else {
                print("Error saving to HealthKit: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    // Fetches step count for a given day
    func fetchStepCount(for date: Date, completion: @escaping (Double?) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            print("Step count type is unavailable.")
            completion(nil)
            return
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let quantity = result.sumQuantity() else {
                completion(nil)
                return
            }

            let steps = quantity.doubleValue(for: HKUnit.count())
            completion(steps)
        }
        healthStore.execute(query)
    }
}
