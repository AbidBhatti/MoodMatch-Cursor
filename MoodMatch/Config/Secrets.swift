//
//  Secrets.swift
//  MoodMatch
//
//  Created by Abid Bhatti on 14/06/25.
//

import Foundation

/// Configuration for API keys and secrets
enum Secrets {
    /// OpenAI API Key for GPT-4o Vision API
    /// Replace with your actual API key
    static let openAIAPIKey = "API_KEY"
    
    /// OpenAI API Base URL
    static let openAIBaseURL = "https://api.openai.com/v1"
    
    /// Validate that API key is configured
    static var isConfigured: Bool {
        return !openAIAPIKey.isEmpty && !openAIAPIKey.contains("replace-with")
    }
} 
