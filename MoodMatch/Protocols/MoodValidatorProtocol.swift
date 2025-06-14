//
//  MoodValidatorProtocol.swift
//  MoodMatch
//
//  Created by Abid Bhatti on 14/06/25.
//

import UIKit

/// Protocol for mood validation services
protocol MoodValidatorProtocol {
    /// Validate an image against a mood prompt
    /// - Parameters:
    ///   - image: The captured image
    ///   - mood: The mood prompt to validate against
    /// - Returns: Boolean indicating if the image matches the mood
    func validate(image: UIImage, forMood mood: String) async -> Bool
    
    /// Validate with error handling
    /// - Parameters:
    ///   - image: The captured image
    ///   - mood: The mood prompt to validate against
    /// - Returns: Result enum with success/failure
    func validateWithErrorHandling(image: UIImage, forMood mood: String) async -> Result<Bool, ValidationError>
}

/// Errors that can occur during validation
enum ValidationError: Error, LocalizedError {
    case networkError
    case networkTimeout
    case invalidImage
    case apiError(String)
    case authenticationError
    case rateLimitExceeded
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection failed"
        case .networkTimeout:
            return "Request timed out. Please check your internet connection."
        case .invalidImage:
            return "Invalid image provided"
        case .apiError(let message):
            return "API Error: \(message)"
        case .authenticationError:
            return "Authentication failed. Please check your API key."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .invalidResponse:
            return "Invalid response from API"
        }
    }
} 