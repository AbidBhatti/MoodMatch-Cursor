//
//  MoodProvider.swift
//  MoodMatch
//
//  Created by Abid Bhatti on 14/06/25.
//

import Foundation

/// Service for providing random mood prompts
class MoodProvider: ObservableObject {
    private var availableMoods: [String] = []
    private var usedMoods: [String] = []
    
    init() {
        loadMoods()
    }
    
    /// Load moods from the JSON file
    private func loadMoods() {
        guard let url = Bundle.main.url(forResource: "moods", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let container = try? JSONDecoder().decode(MoodContainer.self, from: data) else {
            // Fallback moods if JSON file fails to load
            availableMoods = [
                "Happy", "Sad", "Excited", "Calm", "Lonely", "Curious", "Angry", 
                "Hopeful", "Nostalgic", "Anxious", "Proud", "Confused", "Shy", 
                "Grateful", "Tired", "Surprised", "Peaceful", "Energetic", "Focused", "Dreamy"
            ]
            return
        }
        
        availableMoods = container.moods
        usedMoods = []
    }
    
    /// Get a random mood that hasn't been used recently
    func getRandomMood() -> String {
        // If we've used all moods, reset the pool
        if availableMoods.isEmpty {
            availableMoods = usedMoods
            usedMoods = []
        }
        
        guard !availableMoods.isEmpty else {
            return "Happy" // Fallback
        }
        
        let randomIndex = Int.random(in: 0..<availableMoods.count)
        let selectedMood = availableMoods.remove(at: randomIndex)
        usedMoods.append(selectedMood)
        
        return selectedMood
    }
    
    /// Reset the mood pool
    func reset() {
        loadMoods()
    }
} 