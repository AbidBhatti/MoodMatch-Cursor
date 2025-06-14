//
//  GameStateTests.swift
//  MoodMatchTests
//
//  Created by Abid Bhatti on 14/06/25.
//

import XCTest
@testable import MoodMatch

final class GameStateTests: XCTestCase {
    
    var gameState: GameState!
    
    override func setUp() {
        super.setUp()
        gameState = GameState()
    }
    
    override func tearDown() {
        gameState = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialStateIsCorrect() {
        XCTAssertEqual(gameState.score, 0, "Initial score should be 0")
        XCTAssertEqual(gameState.lives, 3, "Initial lives should be 3")
        XCTAssertEqual(gameState.skipsRemaining, 3, "Initial skips should be 3")
        XCTAssertEqual(gameState.timeRemaining, 30, "Initial time should be 30")
        XCTAssertEqual(gameState.currentMood, "", "Initial mood should be empty")
        XCTAssertFalse(gameState.isGameActive, "Game should not be active initially")
        XCTAssertFalse(gameState.isGameOver, "Game should not be over initially")
        XCTAssertFalse(gameState.isValidating, "Should not be validating initially")
        XCTAssertFalse(gameState.showResultOverlay, "Should not show result overlay initially")
        XCTAssertFalse(gameState.lastResult, "Last result should be false initially")
    }
    
    func testMaxValuesAreCorrect() {
        XCTAssertEqual(GameState.maxLives, 3, "Max lives should be 3")
        XCTAssertEqual(GameState.maxSkips, 3, "Max skips should be 3")
        XCTAssertEqual(GameState.maxTime, 30, "Max time should be 30")
    }
    
    // MARK: - Game Flow Tests
    
    func testStartGameSetsCorrectState() {
        gameState.startGame()
        
        XCTAssertEqual(gameState.score, 0, "Score should reset to 0")
        XCTAssertEqual(gameState.lives, 3, "Lives should reset to 3")
        XCTAssertEqual(gameState.skipsRemaining, 3, "Skips should reset to 3")
        XCTAssertEqual(gameState.timeRemaining, 30, "Time should reset to 30")
        XCTAssertTrue(gameState.isGameActive, "Game should be active after start")
        XCTAssertFalse(gameState.isGameOver, "Game should not be over after start")
    }
    
    func testEndGameSetsCorrectState() {
        gameState.startGame()
        gameState.endGame()
        
        XCTAssertFalse(gameState.isGameActive, "Game should not be active after end")
        XCTAssertTrue(gameState.isGameOver, "Game should be over after end")
    }
    
    func testResetResetsAllValues() {
        // Modify state
        gameState.score = 5
        gameState.lives = 1
        gameState.skipsRemaining = 0
        gameState.timeRemaining = 10
        gameState.currentMood = "Happy"
        gameState.isGameActive = true
        gameState.isGameOver = true
        gameState.isValidating = true
        gameState.showResultOverlay = true
        gameState.lastResult = true
        
        // Reset
        gameState.reset()
        
        // Verify all values are reset
        XCTAssertEqual(gameState.score, 0)
        XCTAssertEqual(gameState.lives, 3)
        XCTAssertEqual(gameState.skipsRemaining, 3)
        XCTAssertEqual(gameState.timeRemaining, 30)
        XCTAssertEqual(gameState.currentMood, "")
        XCTAssertFalse(gameState.isGameActive)
        XCTAssertFalse(gameState.isGameOver)
        XCTAssertFalse(gameState.isValidating)
        XCTAssertFalse(gameState.showResultOverlay)
        XCTAssertFalse(gameState.lastResult)
    }
    
    // MARK: - Score and Lives Tests
    
    func testCorrectMatchIncreasesScore() {
        let initialScore = gameState.score
        
        gameState.correctMatch()
        
        XCTAssertEqual(gameState.score, initialScore + 1, "Score should increase by 1")
        XCTAssertTrue(gameState.lastResult, "Last result should be true")
        XCTAssertTrue(gameState.showResultOverlay, "Should show result overlay")
    }
    
    func testIncorrectMatchDecreasesLife() {
        let initialLives = gameState.lives
        
        gameState.incorrectMatch()
        
        XCTAssertEqual(gameState.lives, initialLives - 1, "Lives should decrease by 1")
        XCTAssertFalse(gameState.lastResult, "Last result should be false")
        XCTAssertTrue(gameState.showResultOverlay, "Should show result overlay")
        XCTAssertFalse(gameState.isGameOver, "Game should not be over with lives remaining")
    }
    
    func testIncorrectMatchWithNoLivesEndsGame() {
        gameState.lives = 1 // Set to last life
        
        gameState.incorrectMatch()
        
        XCTAssertEqual(gameState.lives, 0, "Lives should be 0")
        XCTAssertTrue(gameState.isGameOver, "Game should be over when lives reach 0")
    }
    
    func testMultipleCorrectMatchesIncrementScore() {
        let numberOfMatches = 5
        
        for _ in 0..<numberOfMatches {
            gameState.correctMatch()
        }
        
        XCTAssertEqual(gameState.score, numberOfMatches, "Score should equal number of matches")
    }
    
    // MARK: - Skip Tests
    
    func testUseSkipDecreasesSkipsRemaining() {
        let initialSkips = gameState.skipsRemaining
        
        gameState.useSkip()
        
        XCTAssertEqual(gameState.skipsRemaining, initialSkips - 1, "Skips should decrease by 1")
    }
    
    func testUseSkipWhenNoSkipsRemaining() {
        gameState.skipsRemaining = 0
        
        gameState.useSkip()
        
        XCTAssertEqual(gameState.skipsRemaining, 0, "Skips should remain 0 when already at 0")
    }
    
    func testMultipleSkipsDecrementCorrectly() {
        let initialSkips = gameState.skipsRemaining
        let numberOfSkips = 2
        
        for _ in 0..<numberOfSkips {
            gameState.useSkip()
        }
        
        XCTAssertEqual(gameState.skipsRemaining, initialSkips - numberOfSkips, "Skips should decrease correctly")
    }
    
    // MARK: - Timer Tests
    
    func testResetTimerSetsCorrectValue() {
        gameState.timeRemaining = 10
        
        gameState.resetTimer()
        
        XCTAssertEqual(gameState.timeRemaining, GameState.maxTime, "Timer should reset to max time")
    }
} 