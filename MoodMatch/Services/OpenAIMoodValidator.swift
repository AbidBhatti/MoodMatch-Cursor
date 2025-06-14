//
//  OpenAIMoodValidator.swift
//  MoodMatch
//
//  Created by Abid Bhatti on 14/06/25.
//

import UIKit
import Foundation

/// Timeout error for network requests
struct TimeoutError: Error {}

/// OpenAI GPT-4o Vision-based mood validator
class OpenAIMoodValidator: MoodValidatorProtocol {
    
    // MARK: - Properties
    
    private let urlSession: URLSession
    private let apiKey: String
    private let baseURL: String
    
    // MARK: - Initialization
    
    init(apiKey: String = Secrets.openAIAPIKey, 
         baseURL: String = Secrets.openAIBaseURL,
         urlSession: URLSession = URLSession.shared) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.urlSession = urlSession
    }
    
    // MARK: - MoodValidatorProtocol
    
    func validate(image: UIImage, forMood mood: String) async -> Bool {
        let result = await validateWithErrorHandling(image: image, forMood: mood)
        switch result {
        case .success(let isValid):
            return isValid
        case .failure:
            // On error, return false but don't penalize the user
            return false
        }
    }
    
    func validateWithErrorHandling(image: UIImage, forMood mood: String) async -> Result<Bool, ValidationError> {
        // Validate API key is configured
        guard Secrets.isConfigured else {
            return .failure(.authenticationError)
        }
        
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return .failure(.invalidImage)
        }
        
        let base64Image = imageData.base64EncodedString()
        
        do {
            let request = try createOpenAIRequest(base64Image: base64Image, mood: mood)
            
            // Add timeout for the request
            let (data, response) = try await withTimeout(seconds: 30) { [self] in
                try await self.urlSession.data(for: request)
            }
            
            // Check HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.networkError)
            }
            
            switch httpResponse.statusCode {
            case 200:
                return try parseOpenAIResponse(data)
            case 401:
                return .failure(.authenticationError)
            case 429:
                return .failure(.rateLimitExceeded)
            default:
                let errorMessage = extractErrorMessage(from: data) ?? "HTTP \(httpResponse.statusCode)"
                return .failure(.apiError(errorMessage))
            }
            
        } catch is TimeoutError {
            return .failure(.networkTimeout)
        } catch {
            if error is ValidationError {
                return .failure(error as! ValidationError)
            }
            return .failure(.networkError)
        }
    }
    
    // MARK: - Private Methods
    
    private func createOpenAIRequest(base64Image: String, mood: String) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw ValidationError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let payload = OpenAIRequest(
            model: "gpt-4o",
            messages: [
                OpenAIMessage(
                    role: "system",
                    content: [.text("You're an assistant that verifies if a photo matches a given mood. Only answer 'yes' or 'no'.")]
                ),
                OpenAIMessage(
                    role: "user",
                    content: [
                        .text("Does this photo match the mood '\(mood)'?"),
                        .imageURL("data:image/jpeg;base64,\(base64Image)")
                    ]
                )
            ],
            maxTokens: 10,
            temperature: 0.0
        )
        
        request.httpBody = try JSONEncoder().encode(payload)
        return request
    }
    
    private func parseOpenAIResponse(_ data: Data) throws -> Result<Bool, ValidationError> {
        do {
            let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            
            guard let firstChoice = response.choices.first,
                  let content = firstChoice.message.content else {
                throw ValidationError.invalidResponse
            }
            
            let normalizedContent = content.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let isMatch = normalizedContent.contains("yes")
            
            return .success(isMatch)
            
        } catch {
            throw ValidationError.invalidResponse
        }
    }
    
    private func extractErrorMessage(from data: Data) -> String? {
        do {
            let errorResponse = try JSONDecoder().decode(OpenAIErrorResponse.self, from: data)
            return errorResponse.error.message
        } catch {
            return nil
        }
    }
}

// MARK: - Data Models

private struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let maxTokens: Int
    let temperature: Double
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

private struct OpenAIMessage: Codable {
    let role: String
    let content: [OpenAIContent]
}

private enum OpenAIContent: Codable {
    case text(String)
    case imageURL(String)
    
    enum CodingKeys: String, CodingKey {
        case type, text
        case imageURL = "image_url"
    }
    
    private struct ImageURL: Codable {
        let url: String
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case .imageURL(let url):
            try container.encode("image_url", forKey: .type)
            try container.encode(ImageURL(url: url), forKey: .imageURL)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "text":
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)
        case "image_url":
            let imageURL = try container.decode(ImageURL.self, forKey: .imageURL)
            self = .imageURL(imageURL.url)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown content type")
        }
    }
}

private struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

private struct OpenAIChoice: Codable {
    let message: OpenAIResponseMessage
}

private struct OpenAIResponseMessage: Codable {
    let content: String?
}

private struct OpenAIErrorResponse: Codable {
    let error: OpenAIError
}

private struct OpenAIError: Codable {
    let message: String
    let type: String?
    let code: String?
}

// MARK: - Timeout Helper

/// Add timeout to async operations
func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }
        
        guard let result = try await group.next() else {
            throw TimeoutError()
        }
        
        group.cancelAll()
        return result
    }
} 