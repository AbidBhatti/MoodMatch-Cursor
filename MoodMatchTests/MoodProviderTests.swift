//
//  MoodProviderTests.swift
//  MoodMatchTests
//
//  Created by Abid Bhatti on 14/06/25.
//

import XCTest
@testable import MoodMatch

final class MoodProviderTests: XCTestCase {
    
    var moodProvider: MoodProvider!
    
    override func setUp() {
        super.setUp()
        moodProvider = MoodProvider()
    }
    
    override func tearDown() {
        moodProvider = nil
        super.tearDown()
    }
    
    // MARK: - Mood Loading Tests
    
    func testInitialMoodProviderLoadsSuccessfully() {
        XCTAssertNotNil(moodProvider, "MoodProvider should initialize successfully")
    }
    
    func testGetRandomMoodReturnsNonEmptyString() {
        let mood = moodProvider.getRandomMood()
        
        XCTAssertFalse(mood.isEmpty, "Random mood should not be empty")
        XCTAssertGreaterThan(mood.count, 0, "Random mood should have characters")
    }
    
    func testGetRandomMoodReturnsValidMood() {
        let mood = moodProvider.getRandomMood()
        
        // Test that the mood is a reasonable string (no special characters, reasonable length)
        XCTAssertTrue(mood.allSatisfy { $0.isLetter }, "Mood should contain only letters")
        XCTAssertLessThanOrEqual(mood.count, 20, "Mood should be reasonably short")
        XCTAssertGreaterThanOrEqual(mood.count, 3, "Mood should be at least 3 characters")
    }
    
    // MARK: - Mood Randomization Tests
    
    func testConsecutiveMoodsAreDifferent() {
        let firstMood = moodProvider.getRandomMood()
        let secondMood = moodProvider.getRandomMood()
        
        // While not guaranteed due to randomness, it's very likely they'll be different
        // If this test fails occasionally, it's not necessarily a bug
        XCTAssertNotEqual(firstMood, secondMood, "Consecutive moods should typically be different")
    }
    
    func testMultipleMoodsAreGenerated() {
        var moods: Set<String> = []
        let numberOfMoods = 10
        
        for _ in 0..<numberOfMoods {
            let mood = moodProvider.getRandomMood()
            moods.insert(mood)
        }
        
        // Should get at least a few different moods
        XCTAssertGreaterThanOrEqual(moods.count, 3, "Should generate multiple different moods")
    }
    
    func testMoodPoolExhaustionAndReset() {
        var allMoods: Set<String> = []
        
        // Get enough moods to potentially exhaust the pool
        // The app has fallback moods, so we should get at least 10 unique moods
        for _ in 0..<50 {
            let mood = moodProvider.getRandomMood()
            allMoods.insert(mood)
        }
        
        // Should have gotten a variety of moods
        XCTAssertGreaterThanOrEqual(allMoods.count, 10, "Should have at least 10 different moods available")
    }
    
    // MARK: - Reset Functionality Tests
    
    func testResetRestoresMoodPool() {
        // Get some moods to use up the available pool
        let moodsBefore: Set<String> = {
            var moods: Set<String> = []
            for _ in 0..<20 {
                moods.insert(moodProvider.getRandomMood())
            }
            return moods
        }()
        
        // Reset the provider
        moodProvider.reset()
        
        // Get moods after reset
        let moodsAfter: Set<String> = {
            var moods: Set<String> = []
            for _ in 0..<20 {
                moods.insert(moodProvider.getRandomMood())
            }
            return moods
        }()
        
        // Should still be able to get a variety of moods
        XCTAssertGreaterThanOrEqual(moodsAfter.count, 5, "Should still get variety after reset")
    }
    
    func testMoodProviderConsistency() {
        // Test that the provider consistently returns valid moods
        for _ in 0..<100 {
            let mood = moodProvider.getRandomMood()
            XCTAssertFalse(mood.isEmpty, "Every mood should be non-empty")
            XCTAssertTrue(mood.first?.isUppercase ?? false, "Mood should start with uppercase letter")
        }
    }
    
    // MARK: - Fallback Mood Tests
    
    func testFallbackMoodBehavior() {
        // Create multiple providers to test fallback behavior
        let providers = (0..<5).map { _ in MoodProvider() }
        
        for provider in providers {
            let mood = provider.getRandomMood()
            XCTAssertFalse(mood.isEmpty, "Should always return a mood even with fallback")
        }
    }
    
    func testMoodPoolDoesNotReturnEmpty() {
        // Stress test to ensure we never get empty moods
        for _ in 0..<200 {
            let mood = moodProvider.getRandomMood()
            XCTAssertFalse(mood.isEmpty, "Should never return empty mood")
            XCTAssertNotEqual(mood, "", "Should never return empty string")
        }
    }
    
    // MARK: - Expected Moods Tests
    
    func testContainsExpectedMoods() {
        var foundMoods: Set<String> = []
        
        // Collect a large sample of moods
        for _ in 0..<100 {
            foundMoods.insert(moodProvider.getRandomMood())
        }
        
        // Check for some expected moods from our JSON
        let expectedMoods = ["Happy", "Sad", "Excited", "Calm", "Angry"]
        var foundExpected = 0
        
        for expected in expectedMoods {
            if foundMoods.contains(expected) {
                foundExpected += 1
            }
        }
        
        XCTAssertGreaterThanOrEqual(foundExpected, 3, "Should find at least 3 expected moods")
    }
    
    func testMoodFormatting() {
        let mood = moodProvider.getRandomMood()
        
        // Test proper formatting
        XCTAssertTrue(mood.first?.isUppercase ?? false, "First letter should be uppercase")
        XCTAssertFalse(mood.contains(" "), "Mood should be a single word")
        XCTAssertFalse(mood.hasPrefix(" "), "Should not start with whitespace")
        XCTAssertFalse(mood.hasSuffix(" "), "Should not end with whitespace")
    }
} 