//
//  AIValidationService.swift
//  MoodMatch
//
//  Created by Abid Bhatti on 14/06/25.
//

import UIKit

/// Service for validating photos against mood prompts using AI (Mock Implementation)
class AIValidationService: MoodValidatorProtocol {
    static let shared = AIValidationService()
    
    private init() {}
    
    /// Validate an image against a mood prompt
    /// - Parameters:
    ///   - image: The captured image
    ///   - mood: The mood prompt to validate against
    /// Asynchronously simulates validating an image against a mood prompt using AI logic.
    ///
    /// Adds an artificial delay to mimic an API call and returns a randomly generated Boolean result with a slight bias toward success. Intended for mock or testing purposes.
    ///
    /// - Parameters:
    ///   - image: The image to validate.
    ///   - mood: The mood prompt to validate against.
    ///
    /// - Returns: `true` if the image is considered to match the mood, otherwise `false`.
    func validate(image: UIImage, forMood mood: String) async -> Bool {
        // Simulate API call delay – unit tests can override `responseDelayNanoseconds` to speed things up
        if Self.responseDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: Self.responseDelayNanoseconds)
        }
        
        // Mock validation logic - randomly return true/false
        // In production, this would send the image to Claude API
        let isValid = Bool.random()
        
        // Add slight bias toward success for better gameplay
        let biasedResult = isValid || (Int.random(in: 1...10) <= 3)
        
        return biasedResult
    }
    
    /// Validate with error handling
    /// - Parameters:
    ///   - image: The captured image
    ///   - mood: The mood prompt to validate against
    /// Validates whether an image matches a given mood prompt, returning the result wrapped in a `Result`.
    ///
    /// This method asynchronously checks if the provided image corresponds to the specified mood and always returns a `.success` result containing the validation outcome. Error handling is included for interface compatibility, but no errors are currently generated.
    ///
    /// - Parameters:
    ///   - image: The image to validate.
    ///   - mood: The mood prompt to validate against.
    ///
    /// - Returns: A `Result` containing a Boolean indicating if the image matches the mood, or a `ValidationError` (never returned in this implementation).
    func validateWithErrorHandling(image: UIImage, forMood mood: String) async -> Result<Bool, ValidationError> {
        let result = await validate(image: image, forMood: mood)
        return .success(result)
    }
    
    // MARK: - Testing helpers
    
    /// The artificial delay added to the mock validation response. Defaults to 2 seconds but can be
    /// overridden in unit tests to speed them up.
    static var responseDelayNanoseconds: UInt64 = 2_000_000_000
}

// ValidationError is now defined in MoodValidatorProtocol.swift 
