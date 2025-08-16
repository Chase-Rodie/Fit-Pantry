////
////  TempRingsView.swift
////  Fit Pantry
////
////  Created by Lexie Reddon on 12/1/24.
////
//
//import SwiftUI
//
//struct ProgressRingView: View {
//    
//    var progress: Double // Progress value between 0.0 and 1.0
//    var ringColor: Color = Color("LighterColor")
//    var ringWidth: CGFloat = 10.0
//    
//    var body: some View {
//        ZStack {
//                    // Background Circle (empty ring)
//                    Circle()
//                        .stroke(Color.gray.opacity(0.3), lineWidth: ringWidth)
//                    
//                    // Foreground Circle (progress)
//                    Circle()
//                        .trim(from: 0.0, to: progress)
//                        .stroke(ringColor, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
//                        .rotationEffect(.degrees(-90)) // Start from the top
//                        .animation(.easeInOut, value: progress)
//                    
//                    // Text (shows progress as percentage)
//                    Text("\(Int(progress * 100))%")
//                        .font(.headline)
//                        .bold()
//                }
//                .frame(width: 100, height: 100) // Adjust the size as needed
//        
//    }
//}
//
//
//
