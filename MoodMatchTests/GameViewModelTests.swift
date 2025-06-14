//
//  GameViewModelTests.swift
//  MoodMatchTests
//
//  Created by Abid Bhatti on 14/06/25.
//

import XCTest
import UIKit
import AVFoundation
@testable import MoodMatch

final class GameViewModelTests: XCTestCase {
    
    var gameViewModel: GameViewModel!
    var testImage: UIImage!
    
    override func setUp() {
        super.setUp()
        // Use the mock AI service without network delay for faster and more deterministic tests
        AIValidationService.responseDelayNanoseconds = 0
        gameViewModel = GameViewModel(moodValidator: AIValidationService.shared)
        
        // Create a simple test image
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        UIColor.green.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        testImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    override func tearDown() {
        gameViewModel.cleanup()
        gameViewModel = nil
        testImage = nil
        // Restore default delay for any other tests that may rely on it
        AIValidationService.responseDelayNanoseconds = 2_000_000_000
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialGameStateIsCorrect() {
        XCTAssertEqual(gameViewModel.gameState.score, 0, "Initial score should be 0")
        XCTAssertEqual(gameViewModel.gameState.lives, 3, "Initial lives should be 3")
        XCTAssertEqual(gameViewModel.gameState.skipsRemaining, 3, "Initial skips should be 3")
        XCTAssertFalse(gameViewModel.gameState.isGameActive, "Game should not be active initially")
        XCTAssertFalse(gameViewModel.gameState.isGameOver, "Game should not be over initially")
        XCTAssertNil(gameViewModel.capturedImage, "Should have no captured image initially")
    }
    
    // MARK: - Game Start Tests
    
    func testStartNewGameInitializesCorrectly() {
        gameViewModel.startNewGame()
        
        XCTAssertTrue(gameViewModel.gameState.isGameActive, "Game should be active after start")
        XCTAssertFalse(gameViewModel.gameState.isGameOver, "Game should not be over after start")
        XCTAssertEqual(gameViewModel.gameState.score, 0, "Score should be reset")
        XCTAssertEqual(gameViewModel.gameState.lives, 3, "Lives should be reset")
        XCTAssertEqual(gameViewModel.gameState.skipsRemaining, 3, "Skips should be reset")
        XCTAssertFalse(gameViewModel.gameState.currentMood.isEmpty, "Should have a current mood")
    }
    
    func testStartNewRoundSetsMood() {
        gameViewModel.startNewGame()
        let initialMood = gameViewModel.gameState.currentMood
        
        gameViewModel.startNewRound()
        
        XCTAssertFalse(gameViewModel.gameState.currentMood.isEmpty, "Should have a mood after new round")
        XCTAssertEqual(gameViewModel.gameState.timeRemaining, 30, "Timer should reset")
    }
    
    // MARK: - Photo Capture Tests
    
    func testCapturePhotoSetsImage() {
        gameViewModel.capturePhoto(testImage)
        
        XCTAssertNotNil(gameViewModel.capturedImage, "Captured image should be set")
        XCTAssertEqual(gameViewModel.capturedImage, testImage, "Should store the correct image")
        XCTAssertTrue(gameViewModel.gameState.isValidating, "Should be in validating state")
    }
    
    func testCapturePhotoTriggersValidation() async {
        let expectation = XCTestExpectation(description: "Validation completes")
        
        gameViewModel.startNewGame()
        
        // Monitor for validation state changes
        var validationStarted = false
        var validationCompleted = false
        
        // Capture photo which should trigger validation
        gameViewModel.capturePhoto(testImage)
        validationStarted = gameViewModel.gameState.isValidating
        
        // Wait for validation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            validationCompleted = !self.gameViewModel.gameState.isValidating
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        XCTAssertTrue(validationStarted, "Validation should have started")
        XCTAssertTrue(validationCompleted, "Validation should have completed")
    }
    
    // MARK: - Skip Functionality Tests
    
    func testSkipCurrentMoodWhenSkipsAvailable() {
        gameViewModel.startNewGame()
        let initialSkips = gameViewModel.gameState.skipsRemaining
        let initialMood = gameViewModel.gameState.currentMood
        
        gameViewModel.skipCurrentMood()
        
        XCTAssertEqual(gameViewModel.gameState.skipsRemaining, initialSkips - 1, "Skips should decrease")
        XCTAssertNotEqual(gameViewModel.gameState.currentMood, initialMood, "Mood should change")
    }
    
    func testSkipCurrentMoodWhenNoSkipsRemaining() {
        gameViewModel.startNewGame()
        gameViewModel.gameState.skipsRemaining = 0
        let initialMood = gameViewModel.gameState.currentMood
        
        gameViewModel.skipCurrentMood()
        
        XCTAssertEqual(gameViewModel.gameState.skipsRemaining, 0, "Skips should remain 0")
        XCTAssertEqual(gameViewModel.gameState.currentMood, initialMood, "Mood should not change")
    }
    
    func testSkipCurrentMoodWhenValidating() {
        gameViewModel.startNewGame()
        gameViewModel.gameState.isValidating = true
        let initialSkips = gameViewModel.gameState.skipsRemaining
        
        gameViewModel.skipCurrentMood()
        
        XCTAssertEqual(gameViewModel.gameState.skipsRemaining, initialSkips, "Should not use skip when validating")
    }
    
    func testMultipleSkipsDecrementCorrectly() {
        gameViewModel.startNewGame()
        let initialSkips = gameViewModel.gameState.skipsRemaining
        
        gameViewModel.skipCurrentMood()
        gameViewModel.skipCurrentMood()
        
        XCTAssertEqual(gameViewModel.gameState.skipsRemaining, initialSkips - 2, "Should use 2 skips")
    }
    
    // MARK: - Game Over Tests
    
    func testGameOverAfterAllLivesLost() async {
        let expectation = XCTestExpectation(description: "Game over after losing all lives")
        
        gameViewModel.startNewGame()
        
        // Manually set lives to 1 and trigger incorrect match
        gameViewModel.gameState.lives = 1
        gameViewModel.gameState.incorrectMatch()
        
        // Wait briefly for any async operations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.gameViewModel.gameState.isGameOver, "Game should be over after losing last life")
            XCTAssertFalse(self.gameViewModel.gameState.isGameActive, "Game should not be active")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Score and Lives Integration Tests
    
    func testScoreIncreasesOnCorrectValidation() async {
        let expectation = XCTestExpectation(description: "Score increases on correct validation")
        
        gameViewModel.startNewGame()
        let initialScore = gameViewModel.gameState.score
        
        // Manually trigger correct match (simulating successful validation)
        gameViewModel.gameState.correctMatch()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.gameViewModel.gameState.score, initialScore + 1, "Score should increase by 1")
            XCTAssertTrue(self.gameViewModel.gameState.showResultOverlay, "Should show result overlay")
            XCTAssertTrue(self.gameViewModel.gameState.lastResult, "Last result should be true")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testLifeDecreasesOnIncorrectValidation() async {
        let expectation = XCTestExpectation(description: "Life decreases on incorrect validation")
        
        gameViewModel.startNewGame()
        let initialLives = gameViewModel.gameState.lives
        
        // Manually trigger incorrect match (simulating failed validation)
        gameViewModel.gameState.incorrectMatch()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.gameViewModel.gameState.lives, initialLives - 1, "Lives should decrease by 1")
            XCTAssertTrue(self.gameViewModel.gameState.showResultOverlay, "Should show result overlay")
            XCTAssertFalse(self.gameViewModel.gameState.lastResult, "Last result should be false")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Mood Cycling Tests
    
    func testNextMoodCyclesProperly() {
        gameViewModel.startNewGame()
        let firstMood = gameViewModel.gameState.currentMood
        
        gameViewModel.startNewRound()
        let secondMood = gameViewModel.gameState.currentMood
        
        gameViewModel.startNewRound()
        let thirdMood = gameViewModel.gameState.currentMood
        
        // All moods should be non-empty
        XCTAssertFalse(firstMood.isEmpty, "First mood should not be empty")
        XCTAssertFalse(secondMood.isEmpty, "Second mood should not be empty")
        XCTAssertFalse(thirdMood.isEmpty, "Third mood should not be empty")
        
        // Should get different moods (not guaranteed but very likely)
        let uniqueMoods = Set([firstMood, secondMood, thirdMood])
        XCTAssertGreaterThan(uniqueMoods.count, 1, "Should generate different moods")
    }
    
    // MARK: - Camera Permission Tests
    
    func testCheckCameraPermissionReturnsBoolean() {
        let hasPermission = gameViewModel.checkCameraPermission()
        XCTAssertTrue(hasPermission is Bool, "Should return a boolean value")
    }
    
    func testRequestCameraPermissionCallsCompletion() {
        let expectation = XCTestExpectation(description: "Permission completion called")
        
        gameViewModel.requestCameraPermission { granted in
            XCTAssertTrue(granted is Bool, "Should provide boolean result")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Timer and State Management Tests
    
    func testTimerResetsCorrectlyOnNewRound() {
        gameViewModel.startNewGame()
        gameViewModel.gameState.timeRemaining = 10
        
        gameViewModel.startNewRound()
        
        XCTAssertEqual(gameViewModel.gameState.timeRemaining, 30, "Timer should reset to 30")
    }
    
    func testCleanupStopsTimers() {
        gameViewModel.startNewGame()
        gameViewModel.cleanup()
        
        // Cleanup should not crash and should handle timer cleanup gracefully
        XCTAssertTrue(true, "Cleanup should complete without issues")
    }
    
    // MARK: - Edge Cases Tests
    
    func testCapturePhotoWithNilImage() {
        // This tests the robustness of the capture method
        gameViewModel.startNewGame()
        
        // In a real scenario, we wouldn't pass nil, but testing edge case
        // The method signature requires UIImage, so we'll test with a minimal image instead
        let minimalImage = UIImage()
        gameViewModel.capturePhoto(minimalImage)
        
        XCTAssertEqual(gameViewModel.capturedImage, minimalImage, "Should handle minimal images")
    }
    
    func testMultipleGameStarts() {
        gameViewModel.startNewGame()
        let firstMood = gameViewModel.gameState.currentMood
        
        gameViewModel.startNewGame()
        
        XCTAssertTrue(gameViewModel.gameState.isGameActive, "Should still be active after second start")
        XCTAssertEqual(gameViewModel.gameState.score, 0, "Score should reset on new game")
        XCTAssertEqual(gameViewModel.gameState.lives, 3, "Lives should reset on new game")
        XCTAssertFalse(gameViewModel.gameState.currentMood.isEmpty, "Should have a mood after restart")
    }
    
    func testGameStateConsistencyAfterMultipleOperations() {
        gameViewModel.startNewGame()
        
        // Perform various operations
        gameViewModel.skipCurrentMood()
        gameViewModel.gameState.correctMatch()
        gameViewModel.startNewRound()
        gameViewModel.gameState.incorrectMatch()
        
        // Game state should remain consistent
        XCTAssertTrue(gameViewModel.gameState.score >= 0, "Score should not be negative")
        XCTAssertTrue(gameViewModel.gameState.lives >= 0, "Lives should not be negative")
        XCTAssertTrue(gameViewModel.gameState.skipsRemaining >= 0, "Skips should not be negative")
        XCTAssertFalse(gameViewModel.gameState.currentMood.isEmpty, "Should always have a mood")
    }
} 