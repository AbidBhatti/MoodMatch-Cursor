//
//  GameState.swift
//  MoodMatch
//
//  Created by Abid Bhatti on 14/06/25.
//

import Foundation

/// Represents the current state of the game
class GameState: ObservableObject {
    @Published var score: Int = 0
    @Published var lives: Int = 3
    @Published var skipsRemaining: Int = 3
    @Published var timeRemaining: Int = 30
    @Published var currentMood: String = ""
    @Published var isGameActive: Bool = false
    @Published var isGameOver: Bool = false
    @Published var isValidating: Bool = false
    @Published var showResultOverlay: Bool = false
    @Published var lastResult: Bool = false
    
    /// Maximum values for game parameters
    static let maxLives = 3
    static let maxSkips = 3
    static let maxTime = 30
    
    /// Resets all game state properties to their initial default values.
    ///
    /// Restores score, lives, skips, time, mood, and status flags to start a new game session.
    func reset() {
        score = 0
        lives = Self.maxLives
        skipsRemaining = Self.maxSkips
        timeRemaining = Self.maxTime
        currentMood = ""
        isGameActive = false
        isGameOver = false
        isValidating = false
        showResultOverlay = false
        lastResult = false
    }
    
    /// Initializes and starts a new game session by resetting all game state and marking the game as active.
    func startGame() {
        reset()
        isGameActive = true
    }
    
    /// Marks the game as over and sets the game as inactive.
    func endGame() {
        isGameActive = false
        isGameOver = true
    }
    
    /// Updates the game state for a correct match.
    ///
    /// Increments the score, marks the last result as correct, and displays the result overlay.
    func correctMatch() {
        score += 1
        lastResult = true
        showResultOverlay = true
    }
    
    /// Handles an incorrect match by decrementing lives, updating the result state, and ending the game if no lives remain.
    func incorrectMatch() {
        lives -= 1
        lastResult = false
        showResultOverlay = true
        
        if lives <= 0 {
            endGame()
        }
    }
    
    /// Decreases the number of skips remaining by one if any skips are available.
    func useSkip() {
        if skipsRemaining > 0 {
            skipsRemaining -= 1
        }
    }
    
    /// Resets the time remaining to the maximum allowed time for a round.
    func resetTimer() {
        timeRemaining = Self.maxTime
    }
} 