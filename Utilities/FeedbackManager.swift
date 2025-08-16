//
//  FeedbackManager.swift
//  Fit Pantry
//
//  Created by Chase Rodie on 4/18/25.
//

import AVFoundation
import AudioToolbox

class FeedbackManager {
    static let shared = FeedbackManager()

    func playSuccessSoundIfEnabled() {
        if UserDefaults.standard.bool(forKey: "soundEnabled") {
            AudioServicesPlaySystemSound(1057) 
        }
    }

    func vibrateIfEnabled() {
        if UserDefaults.standard.bool(forKey: "vibrationEnabled") {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
}
