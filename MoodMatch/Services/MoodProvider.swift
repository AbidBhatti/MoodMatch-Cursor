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
    
    /// Loads moods from the "moods.json" file in the app bundle, populating the available moods list.
    /// Falls back to a predefined set of moods if loading or decoding fails. Resets the used moods list.
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
    
    /// Returns a random mood prompt, ensuring no immediate repeats until all moods have been used.
    ///
    /// If all moods have been cycled through, the pool is reset to allow reuse. Returns "Happy" as a fallback if no moods are available.
    ///
    /// - Returns: A randomly selected mood string.
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
    
    /// Reloads the list of moods from the data source, resetting the available and used mood pools.
    func reset() {
        loadMoods()
    }
} 