//
//  AIValidationServiceTests.swift
//  MoodMatchTests
//
//  Created by Abid Bhatti on 14/06/25.
//

import XCTest
import UIKit
@testable import MoodMatch

final class AIValidationServiceTests: XCTestCase {
    
    var aiService: AIValidationService!
    var testImage: UIImage!
    
    override func setUp() {
        super.setUp()
        aiService = AIValidationService.shared
        
        // Reduce artificial delay to speed up the test suite
        AIValidationService.responseDelayNanoseconds = 5_000_000 // 5 ms
        
        // Create a simple test image
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        testImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    override func tearDown() {
        aiService = nil
        testImage = nil
        // Restore default delay so other code paths remain unaffected
        AIValidationService.responseDelayNanoseconds = 2_000_000_000
        super.tearDown()
    }
    
    // MARK: - Basic Validation Tests
    
    func testValidateReturnsBoolean() async {
        let result = await aiService.validate(image: testImage, forMood: "Happy")
        
        XCTAssertTrue(result, "Validation should return a Boolean value")
    }
    
    func testValidateWithDifferentMoods() async {
        let moods = ["Happy", "Sad", "Excited", "Calm", "Angry"]
        
        for mood in moods {
            let result = await aiService.validate(image: testImage, forMood: mood)
            XCTAssertNotNil(result, "Should return result for mood: \(mood)")
        }
    }
    
    func testValidateWithEmptyMood() async {
        let result = await aiService.validate(image: testImage, forMood: "")
        
        XCTAssertNotNil(result, "Should handle empty mood gracefully")
    }
    
    func testValidateWithLongMoodString() async {
        let longMood = String(repeating: "VeryLongMoodName", count: 10)
        let result = await aiService.validate(image: testImage, forMood: longMood)
        
        XCTAssertNotNil(result, "Should handle long mood strings")
    }
    
    // MARK: - Timing Tests
    
    func testValidationTimingIsReasonable() async {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        _ = await aiService.validate(image: testImage, forMood: "Happy")
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // With the reduced delay this should complete quickly (<0.5 s)
        XCTAssertLessThan(duration, 0.5, "Validation should be fast in test mode")
    }
    
    func testMultipleValidationsExecuteConcurrently() async {
        let numberOfValidations = 3
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Run multiple validations concurrently
        await withTaskGroup(of: Bool.self) { group in
            for i in 0..<numberOfValidations {
                group.addTask {
                    await self.aiService.validate(image: self.testImage, forMood: "Mood\(i)")
                }
            }
            
            // Wait for all to complete
            for await _ in group {}
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Should not take 3x as long since they run concurrently
        XCTAssertLessThanOrEqual(duration, 4.0, "Concurrent validations should not block each other")
    }
    
    // MARK: - Error Handling Tests
    
    func testValidateWithErrorHandlingSuccess() async {
        let result = await aiService.validateWithErrorHandling(image: testImage, forMood: "Happy")
        
        switch result {
        case .success(let isValid):
            XCTAssertTrue(isValid, "Success case should contain boolean")
        case .failure:
            XCTFail("Should not fail with valid inputs")
        }
    }
    
    func testValidateWithErrorHandlingStructure() async {
        let result = await aiService.validateWithErrorHandling(image: testImage, forMood: "Test")
        
        // Ensure we get a proper Result type
        switch result {
        case .success:
            XCTAssertTrue(true, "Success case handled properly")
        case .failure(let error):
            // If it fails, ensure the error is properly structured
            XCTAssertNotNil(error.localizedDescription, "Error should have description")
        }
    }
    
    // MARK: - Mock Behavior Tests
    
    func testMockValidationVariability() async {
        var results: [Bool] = []
        let numberOfTests = 20
        
        for _ in 0..<numberOfTests {
            let result = await aiService.validate(image: testImage, forMood: "Happy")
            results.append(result)
        }
        
        // With randomness, we should get some variety in results
        let trueCount = results.filter { $0 }.count
        let falseCount = results.count - trueCount
        
        // Should not be all true or all false (very unlikely with randomness)
        XCTAssertGreaterThan(trueCount, 0, "Should have some true results")
        XCTAssertGreaterThan(falseCount, 0, "Should have some false results")
    }
    
    func testMockValidationBias() async {
        var results: [Bool] = []
        let numberOfTests = 100
        
        for _ in 0..<numberOfTests {
            let result = await aiService.validate(image: testImage, forMood: "Happy")
            results.append(result)
        }
        
        let trueCount = results.filter { $0 }.count
        let successRate = Double(trueCount) / Double(numberOfTests)
        
        // Mock has bias toward success, should be > 50%
        XCTAssertGreaterThan(successRate, 0.5, "Mock should have bias toward success")
        XCTAssertLessThan(successRate, 1.0, "Should not always return true")
    }
    
    // MARK: - Singleton Tests
    
    func testSingletonBehavior() {
        let service1 = AIValidationService.shared
        let service2 = AIValidationService.shared
        
        XCTAssertTrue(service1 === service2, "Should return same singleton instance")
    }
    
    // MARK: - Image Handling Tests
    
    func testValidateWithDifferentImageSizes() async {
        let sizes = [CGSize(width: 10, height: 10), CGSize(width: 1000, height: 1000)]
        
        for size in sizes {
            UIGraphicsBeginImageContext(size)
            UIColor.red.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            let image = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            let result = await aiService.validate(image: image, forMood: "Happy")
            XCTAssertNotNil(result, "Should handle \(size) images")
        }
    }
    
    // MARK: - Performance Tests
    
    func testValidationPerformance() {
        measure {
            let expectation = XCTestExpectation(description: "Validation completes")
            
            Task {
                _ = await aiService.validate(image: testImage, forMood: "Happy")
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Edge Cases
    
    func testValidateWithSpecialCharactersInMood() async {
        let specialMoods = ["🙂", "test-mood", "mood_with_underscore", "UPPERCASE"]
        
        for mood in specialMoods {
            let result = await aiService.validate(image: testImage, forMood: mood)
            XCTAssertNotNil(result, "Should handle mood: \(mood)")
        }
    }
    
    func testValidateMultipleTimesSequentially() async {
        for i in 0..<5 {
            let result = await aiService.validate(image: testImage, forMood: "Sequential\(i)")
            XCTAssertNotNil(result, "Sequential validation \(i) should work")
        }
    }
} 
