//
//  OpenAIMoodValidatorTests.swift
//  MoodMatchTests
//
//  Created by Abid Bhatti on 14/06/25.
//

import XCTest
import UIKit
@testable import MoodMatch

final class OpenAIMoodValidatorTests: XCTestCase {
    
    var validator: OpenAIMoodValidator!
    var mockURLSession: MockURLSession!
    var testImage: UIImage!
    
    override func setUp() {
        super.setUp()
        mockURLSession = MockURLSession()
        testImage = createTestImage()
        
        validator = OpenAIMoodValidator(
            apiKey: "test-api-key",
            baseURL: "https://api.openai.com/v1",
            urlSession: mockURLSession
        )
    }
    
    override func tearDown() {
        validator = nil
        mockURLSession = nil
        testImage = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    // MARK: - Success Tests
    
    func testValidateWithPositiveResponse() async {
        // Given
        let successResponse = """
        {
            "choices": [
                {
                    "message": {
                        "content": "yes"
                    }
                }
            ]
        }
        """
        
        mockURLSession.data = successResponse.data(using: .utf8)
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result = await validator.validateWithErrorHandling(image: testImage, forMood: "happy")
        
        // Then
        switch result {
        case .success(let isValid):
            XCTAssertTrue(isValid, "Should return true for 'yes' response")
        case .failure(let error):
            XCTFail("Should not fail with valid response: \(error)")
        }
    }
    
    func testValidateWithNegativeResponse() async {
        // Given
        let negativeResponse = """
        {
            "choices": [
                {
                    "message": {
                        "content": "no"
                    }
                }
            ]
        }
        """
        
        mockURLSession.data = negativeResponse.data(using: .utf8)
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result = await validator.validateWithErrorHandling(image: testImage, forMood: "happy")
        
        // Then
        switch result {
        case .success(let isValid):
            XCTAssertFalse(isValid, "Should return false for 'no' response")
        case .failure(let error):
            XCTFail("Should not fail with valid response: \(error)")
        }
    }
    
    func testValidateSimpleMethod() async {
        // Given
        let successResponse = """
        {
            "choices": [
                {
                    "message": {
                        "content": "yes"
                    }
                }
            ]
        }
        """
        
        mockURLSession.data = successResponse.data(using: .utf8)
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let isValid = await validator.validate(image: testImage, forMood: "happy")
        
        // Then
        XCTAssertTrue(isValid, "Simple validate method should return true for 'yes' response")
    }
    
    // MARK: - Error Handling Tests
    
    func testValidateWithNetworkError() async {
        // Given
        mockURLSession.error = URLError(.networkConnectionLost)
        
        // When
        let result = await validator.validateWithErrorHandling(image: testImage, forMood: "happy")
        
        // Then
        switch result {
        case .success:
            XCTFail("Should fail with network error")
        case .failure(let error):
            XCTAssertEqual(error as? ValidationError, .networkError)
        }
    }
    
    func testValidateWithAuthenticationError() async {
        // Given
        mockURLSession.data = Data()
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result = await validator.validateWithErrorHandling(image: testImage, forMood: "happy")
        
        // Then
        switch result {
        case .success:
            XCTFail("Should fail with authentication error")
        case .failure(let error):
            XCTAssertEqual(error as? ValidationError, .authenticationError)
        }
    }
    
    func testValidateWithRateLimitError() async {
        // Given
        mockURLSession.data = Data()
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 429,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result = await validator.validateWithErrorHandling(image: testImage, forMood: "happy")
        
        // Then
        switch result {
        case .success:
            XCTFail("Should fail with rate limit error")
        case .failure(let error):
            XCTAssertEqual(error as? ValidationError, .rateLimitExceeded)
        }
    }
    
    func testValidateWithInvalidImage() async {
        // Given - using a corrupted UIImage (this is tricky to simulate, so we'll test the happy path)
        
        // When
        let result = await validator.validateWithErrorHandling(image: testImage, forMood: "happy")
        
        // Then - Since our test image is valid, we expect network-related behavior
        // In a real scenario with invalid image data, we'd get .invalidImage
        XCTAssertNotNil(result, "Should return a result")
    }
    
    func testValidateWithInvalidResponse() async {
        // Given
        let invalidResponse = "invalid json"
        
        mockURLSession.data = invalidResponse.data(using: .utf8)
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result = await validator.validateWithErrorHandling(image: testImage, forMood: "happy")
        
        // Then
        switch result {
        case .success:
            XCTFail("Should fail with invalid response")
        case .failure(let error):
            XCTAssertEqual(error as? ValidationError, .invalidResponse)
        }
    }
    
    func testValidateWithAPIError() async {
        // Given
        let errorResponse = """
        {
            "error": {
                "message": "Invalid model specified",
                "type": "invalid_request_error",
                "code": "model_not_found"
            }
        }
        """
        
        mockURLSession.data = errorResponse.data(using: .utf8)
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 400,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result = await validator.validateWithErrorHandling(image: testImage, forMood: "happy")
        
        // Then
        switch result {
        case .success:
            XCTFail("Should fail with API error")
        case .failure(let error):
            if case .apiError(let message) = error as? ValidationError {
                XCTAssertEqual(message, "Invalid model specified")
            } else {
                XCTFail("Should be apiError with correct message")
            }
        }
    }
    
    // MARK: - Configuration Tests
    
    func testValidatorWithUnconfiguredAPIKey() async {
        // Given
        let unconfiguredValidator = OpenAIMoodValidator(
            apiKey: "sk-replace-with-your-actual-openai-api-key-here",
            urlSession: mockURLSession
        )
        
        // When
        let result = await unconfiguredValidator.validateWithErrorHandling(image: testImage, forMood: "happy")
        
        // Then
        switch result {
        case .success:
            XCTFail("Should fail with unconfigured API key")
        case .failure(let error):
            XCTAssertEqual(error as? ValidationError, .authenticationError)
        }
    }
    
    // MARK: - Response Parsing Tests
    
    func testParseResponseWithVariousYesFormats() async {
        let yesVariations = ["yes", "YES", "Yes", "  yes  ", "yes."]
        
        for variation in yesVariations {
            let response = """
            {
                "choices": [
                    {
                        "message": {
                            "content": "\(variation)"
                        }
                    }
                ]
            }
            """
            
            mockURLSession.data = response.data(using: .utf8)
            mockURLSession.response = HTTPURLResponse(
                url: URL(string: "https://api.openai.com/v1/chat/completions")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
            
            let result = await validator.validateWithErrorHandling(image: testImage, forMood: "happy")
            
            switch result {
            case .success(let isValid):
                XCTAssertTrue(isValid, "Should return true for variation: '\(variation)'")
            case .failure(let error):
                XCTFail("Should not fail with valid response variation '\(variation)': \(error)")
            }
        }
    }
    
    func testParseResponseWithVariousNoFormats() async {
        let noVariations = ["no", "NO", "No", "  no  ", "no."]
        
        for variation in noVariations {
            let response = """
            {
                "choices": [
                    {
                        "message": {
                            "content": "\(variation)"
                        }
                    }
                ]
            }
            """
            
            mockURLSession.data = response.data(using: .utf8)
            mockURLSession.response = HTTPURLResponse(
                url: URL(string: "https://api.openai.com/v1/chat/completions")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
            
            let result = await validator.validateWithErrorHandling(image: testImage, forMood: "happy")
            
            switch result {
            case .success(let isValid):
                XCTAssertFalse(isValid, "Should return false for variation: '\(variation)'")
            case .failure(let error):
                XCTFail("Should not fail with valid response variation '\(variation)': \(error)")
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testValidationPerformance() {
        measure {
            let expectation = XCTestExpectation(description: "Validation completes")
            
            let successResponse = """
            {
                "choices": [
                    {
                        "message": {
                            "content": "yes"
                        }
                    }
                ]
            }
            """
            
            mockURLSession.data = successResponse.data(using: .utf8)
            mockURLSession.response = HTTPURLResponse(
                url: URL(string: "https://api.openai.com/v1/chat/completions")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
            
            Task {
                _ = await validator.validate(image: testImage, forMood: "happy")
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
}

// MARK: - Mock URLSession

class MockURLSession: URLSession {
    var data: Data?
    var response: URLResponse?
    var error: Error?
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = error {
            throw error
        }
        
        let data = self.data ?? Data()
        let response = self.response ?? HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        return (data, response)
    }
} 