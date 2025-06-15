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
    
    /// Loads the list of moods from a JSON file in the app bundle, or uses a default set if loading fails.
    /// 
    /// Resets the used moods list after loading.
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
    
    /// Returns a random mood prompt, ensuring moods are not repeated until all have been used.
    ///
    /// If all moods have been used, the pool is reset. Returns "Happy" if no moods are available.
    ///
    /// - Returns: A random mood string. If no moods are available, returns "Happy".
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
    
    /// Reloads the list of moods from the data source and resets the mood pools to their initial state.
    func reset() {
        loadMoods()
    }
} 