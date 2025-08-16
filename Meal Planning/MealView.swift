//
//  MealView.swift
//  Fit Pantry
//
//  Code by Heather Amistani 11/11/24.
//

import UIKit

//ViewController Implementation
class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    //Outlets
    @IBOutlet weak var ageTextField: UITextField!
    @IBOutlet weak var weightTextField: UITextField!
    @IBOutlet weak var heightFeetTextField: UITextField!
    @IBOutlet weak var heightInchesTextField: UITextField!
    
    @IBOutlet weak var genderPickerView: UIPickerView!
    @IBOutlet weak var goalPickerView: UIPickerView!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var dietaryRestrictionsTextField: UITextField!
    
    //PickerView Data
    let genderOptions = ["Male", "Female", "Non-Binary", "Trans Female", "Trans Male", "Prefer not to answer"]
    let goalOptions = ["Lose", "Gain", "Maintain"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        genderPickerView.delegate = self
        genderPickerView.dataSource = self
        
        goalPickerView.delegate = self
        goalPickerView.dataSource = self
    }
    
    //UIPickerView Methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerView == genderPickerView ? genderOptions.count : goalOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerView == genderPickerView ? genderOptions[row] : goalOptions[row]
    }
    
    //Calculate Button Action
    @IBAction func calculateButtonTapped(_ sender: UIButton) {
        do {
            let age = try validateInput(ageTextField.text)
            let weightInLbs = try validateInput(weightTextField.text)
            let heightInFeet = try validateInput(heightFeetTextField.text)
            let heightInInches = try validateInput(heightInchesTextField.text)
            
            let gender = genderOptions[genderPickerView.selectedRow(inComponent: 0)]
            let goal = goalOptions[goalPickerView.selectedRow(inComponent: 0)]
            
            let restrictionsText = dietaryRestrictionsTextField.text
            let restrictions = restrictionsText?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? []
            
            let user = UserMeal(
                age: Int(age),
                weightInLbs: weightInLbs,
                heightInFeet: Int(heightInFeet),
                heightInInches: Int(heightInInches),
                gender: gender,
                dietaryRestrictions: restrictions,
                goal: goal,
                onMedications: nil,
                hormoneTherapy: nil,
                activityLevel: "Active",
                mealPreferences: []
            )
            
            let dailyCalories = calculateDailyCalories(
                age: Int(age),
                weightInLbs: weightInLbs,
                heightInFeet: Int(heightInFeet),
                heightInInches: Int(heightInInches),
                gender: gender,
                goal: goal
            )
            
            let foodSuggestions = suggestFoods(for: user)
            
            resultLabel.text = """
            Daily Calories: \(dailyCalories)
            Suggestions: \(foodSuggestions.map { $0.name }.joined(separator: ", "))
            """
        } catch InputError.emptyField {
            resultLabel.text = "Please fill in all fields."
        } catch {
            resultLabel.text = "Invalid input. Please enter numbers only."
        }
    }
    
    func validateInput(_ input: String?) throws -> Double {
        guard let input = input, !input.isEmpty else {
            throw InputError.emptyField
        }
        guard let value = Double(input) else {
            throw InputError.invalidInput
        }
        return value
    }
}
