//
//  StepCountBar.swift
//  Fit Pantry
//
//  Created by Heather Amistani on 4/20/25.
//

import SwiftUI

// A horizontal progress bar that visually displays the user's current step count relative to their goal
struct StepCountBar: View {
    var steps: Int
    var goal: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Steps", systemImage: "figure.walk")
                    .font(.headline)
                    .foregroundColor(Color("Navy"))
                Spacer()
                Text("\(steps) / \(goal)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 20)
                    .frame(height: 10)
                    .foregroundColor(Color.gray.opacity(0.3))

                RoundedRectangle(cornerRadius: 20)
                    .frame(width: progressWidth, height: 10)
                    .foregroundColor(Color("BackgroundColor"))
                    .animation(.easeInOut(duration: 0.3), value: steps)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 3)
        .padding(.horizontal)
    }

    // Calculates the width of the progress bar relative to the screen and step goal
    private var progressWidth: CGFloat {
        let ratio = min(Double(steps) / Double(goal), 1.0)
        return CGFloat(ratio * UIScreen.main.bounds.width * 0.8)
    }
}
