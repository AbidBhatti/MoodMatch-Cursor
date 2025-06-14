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
    
    /// Reset game state to initial values
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
    
    /// Start a new game
    func startGame() {
        reset()
        isGameActive = true
    }
    
    /// End the current game
    func endGame() {
        isGameActive = false
        isGameOver = true
    }
    
    /// Process a correct match
    func correctMatch() {
        score += 1
        lastResult = true
        showResultOverlay = true
    }
    
    /// Process an incorrect match
    func incorrectMatch() {
        lives -= 1
        lastResult = false
        showResultOverlay = true
        
        if lives <= 0 {
            endGame()
        }
    }
    
    /// Use a skip
    func useSkip() {
        if skipsRemaining > 0 {
            skipsRemaining -= 1
        }
    }
    
    /// Reset timer for new round
    func resetTimer() {
        timeRemaining = Self.maxTime
    }
} 