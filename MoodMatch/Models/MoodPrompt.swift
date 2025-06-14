//
//  MoodPrompt.swift
//  MoodMatch
//
//  Created by Abid Bhatti on 14/06/25.
//

import Foundation

/// Represents a mood prompt for the game
struct MoodPrompt: Codable, Identifiable, Equatable {
    var id = UUID()
    let mood: String
    
    init(mood: String) {
        self.mood = mood
    }
}

/// Container for loading moods from JSON
struct MoodContainer: Codable {
    let moods: [String]
} 
