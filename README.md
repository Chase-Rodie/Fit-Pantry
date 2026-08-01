# Fit Pantry

Fit Pantry is an iOS nutrition and fitness application built with SwiftUI that helps users manage their pantry, plan meals, track nutrition, generate workout plans, and monitor daily fitness progress.

Developed as a senior capstone project at the University of Nevada, Reno.

---

## Features

### Pantry Management
- Store food inventory in Firebase Firestore
- Add, edit, and remove pantry items
- Track quantities using multiple measurement units
- Automatically update pantry inventory as meals are consumed

### Meal Planning
- Generate meal plans from available pantry ingredients
- Organize meals by breakfast, lunch, and dinner
- View nutritional information for individual meals
- Generate recipe suggestions from selected ingredients

### Food Journal
- Log meals throughout the day
- Track calories and macronutrients
- Visualize daily nutrition progress
- Maintain historical meal records

### Workout Planning
- Generate personalized workout plans
- Support multiple training frequencies and durations
- Track workout completion progress
- Display weekly workout progress

### Health Integration
- Apple HealthKit step tracking
- Daily activity dashboard
- Workout progress visualization

### Authentication
- Firebase Authentication
- Google Sign-In
- Sign in with Apple
- Secure user-specific cloud data

---

## Technologies

- Swift
- SwiftUI
- Firebase Authentication
- Cloud Firestore
- Google Sign-In
- Apple HealthKit
- Xcode
- XCTest

---

## Architecture

The application follows a SwiftUI architecture using:

- EnvironmentObjects for shared application state
- ViewModels to separate UI from business logic
- Firebase for authentication and cloud storage
- HealthKit for fitness integration
- Firestore collections for user pantry, meals, workouts, and profile data

---

## Testing

The project includes unit and UI tests covering multiple application components including:

- Workout generation
- Meal planning
- Nutrition calculations
- Shopping list functionality
- User preferences
- Firestore interactions
- UI testing

---

## Repository Structure

```
App/
Authentication/
Core/
FoodJournal/
HomePage/
Meal Planning/
Pantry/
WorkoutPlanner/
Utilities/
Firestore/
Models/
Tests/
```

---

## My Contributions

This project was developed collaboratively as a university capstone.

My primary contributions included:

- Firebase integration
- Workout planning functionality
- Exercise database integration
- Firestore data management
- Authentication features
- Testing and debugging
- Application integration and feature development across multiple modules

---

## Setup

1. Clone the repository.
2. Open the Xcode project.
3. Add your own `GoogleService-Info.plist`.
4. Configure a Firebase project.
5. Build and run on iOS.

---

## Notes

The Firebase configuration file has been removed from this public repository. To run the application, create your own Firebase project and add your own configuration.

---

## Future Improvements

- Cloud synchronization improvements
- Better meal recommendation algorithms
- Expanded workout customization
- Offline support
- Apple Watch integration
- AI-assisted nutrition recommendations
