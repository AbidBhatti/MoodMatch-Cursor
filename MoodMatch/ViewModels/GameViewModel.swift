//
//  GameViewModel.swift
//  MoodMatch
//
//  Created by Abid Bhatti on 14/06/25.
//

import SwiftUI
import Combine
import AVFoundation

/// ViewModel for managing game logic and state
class GameViewModel: ObservableObject {
    @Published var gameState = GameState()
    @Published var showCamera = false
    @Published var capturedImage: UIImage?
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    
    private let moodProvider = MoodProvider()
    private let moodValidator: MoodValidatorProtocol
    private var gameTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    /// Initialize with dependency injection for the mood validator
    /// - Parameter moodValidator: The mood validation service to use
    init(moodValidator: MoodValidatorProtocol = OpenAIMoodValidator()) {
        self.moodValidator = moodValidator
        setupBindings()
        
        // Forward GameState changes to notify SwiftUI of nested updates
        gameState.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func setupBindings() {
        // Auto-hide result overlay after 3 seconds and continue to next round
        gameState.$showResultOverlay
            .filter { $0 }
            .delay(for: .seconds(3), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.hideResultOverlayAndContinue()
            }
            .store(in: &cancellables)
    }
    
    /// Start a new game
    func startNewGame() {
        gameState.startGame()
        moodProvider.reset()
        startNewRound()
    }
    
    /// Start a new round with a fresh mood
    func startNewRound() {
        gameState.currentMood = moodProvider.getRandomMood()
        gameState.resetTimer()
        startTimer()
    }
    
    /// Start the countdown timer
    private func startTimer() {
        stopTimer()
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    /// Stop the current timer
    private func stopTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    /// Update timer countdown
    private func updateTimer() {
        if gameState.timeRemaining > 0 {
            gameState.timeRemaining -= 1
        } else {
            // Time's up - treat as incorrect match
            stopTimer()
            
            // If validation is in progress, cancel it
            if gameState.isValidating {
                gameState.isValidating = false
            }
            
            gameState.incorrectMatch()
            
            // Result overlay will be handled by setupBindings() after 3 seconds
        }
    }
    
    /// Handle photo capture
    func capturePhoto(_ image: UIImage) {
        capturedImage = image
        validatePhoto(image)
    }
    
    /// Validate captured photo against current mood
    private func validatePhoto(_ image: UIImage) {
        guard !gameState.currentMood.isEmpty else { return }
        
        gameState.isValidating = true
        stopTimer()
        
        Task {
            let result = await moodValidator.validateWithErrorHandling(image: image, forMood: gameState.currentMood)
            
            await MainActor.run {
                gameState.isValidating = false
                
                switch result {
                case .success(let isValid):
                    // Process the result and show overlay
                    if isValid {
                        gameState.correctMatch()
                        // Add haptic feedback for success
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    } else {
                        gameState.incorrectMatch()
                        // Add haptic feedback for failure
                        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                        impactFeedback.impactOccurred()
                    }
                    
                    // Force show result overlay immediately
                    gameState.showResultOverlay = true
                    
                case .failure(let error):
                    // Handle validation errors - don't penalize the user
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                    
                    // Restart the timer so the user can try again
                    self.startTimer()
                    
                    // Add haptic feedback for error
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
            }
        }
    }
    
    /// Skip the current mood
    func skipCurrentMood() {
        guard gameState.skipsRemaining > 0 && !gameState.isValidating && !gameState.showResultOverlay else { 
            return 
        }
        
        // Stop timer and clear any validation state
        stopTimer()
        gameState.isValidating = false
        
        // Use skip and clear captured image
        gameState.useSkip()
        capturedImage = nil
        
        // Start new round
        startNewRound()
        
        // Add haptic feedback for skip
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// Hide result overlay and reset
    private func hideResultOverlay() {
        gameState.showResultOverlay = false
        capturedImage = nil
    }
    
    /// Hide result overlay and continue to next round
    func hideResultOverlayAndContinue() {
        hideResultOverlay()
        
        if !gameState.isGameOver {
            startNewRound()
        }
    }
    
    /// Check camera permission
    func checkCameraPermission() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return status == .authorized
    }
    
    /// Request camera permission
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    /// Clean up when view disappears
    func cleanup() {
        stopTimer()
        cancellables.removeAll()
    }
    
    deinit {
        cleanup()
    }
} 