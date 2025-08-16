//
//  Units.swift
//  Fit Pantry
//
//  Created by Heather Amistani on 4/20/25.
//

import Foundation

// Conversion factors to a base reference unit
let Units: [String: Double] = [
    "g": 1.0,
    "mg": 0.001,
    "oz": 1.0,
    "lbs": 16.0, 
    "kg": 35.274,
    "cup": 8.0,
    "tbsp": 0.5,
    "tsp": 0.1667,
    "slice": 1.0,
    "can": 12.0,
    "loaf": 16.0,
    "ml": 0.0338,
    "L": 33.814,
    "gal": 128.0
]

// Provides unit-to-unit conversions using the Units map above
struct UnitConverter {
    static func convert(amount: Double, from fromUnit: String, to toUnit: String) -> Double? {
        guard let fromFactor = Units[fromUnit], let toFactor = Units[toUnit] else {
            return nil
        }

        let amountInGrams = amount * fromFactor
        let convertedAmount = amountInGrams / toFactor
        
        return convertedAmount
    }
}

