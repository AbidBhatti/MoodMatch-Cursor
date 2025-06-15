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
    
    /// Sets up a binding to automatically hide the result overlay and proceed to the next round after it is shown for 3 seconds.
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
    
    /// Resets the game state and mood provider, then begins a new game round.
    func startNewGame() {
        gameState.startGame()
        moodProvider.reset()
        startNewRound()
    }
    
    /// Begins a new round by selecting a random mood, resetting the timer, and starting the countdown.
    func startNewRound() {
        gameState.currentMood = moodProvider.getRandomMood()
        gameState.resetTimer()
        startTimer()
    }
    
    /// Starts a repeating timer that updates the countdown every second for the current game round.
    private func startTimer() {
        stopTimer()
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    /// Stops and clears the active game timer.
    private func stopTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    /// Updates the countdown timer for the current round, handling timeouts as incorrect matches.
    ///
    /// Decrements the remaining time by one second. If time runs out, stops the timer, cancels any ongoing validation, and marks the match as incorrect.
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
    
    /// Stores the captured photo and initiates validation against the current mood.
    ///
    /// - Parameter image: The photo captured by the user.
    func capturePhoto(_ image: UIImage) {
        capturedImage = image
        validatePhoto(image)
    }
    
    /// Validates the provided image against the current mood using the mood validator.
    ///
    /// If validation succeeds, updates the game state as a correct or incorrect match and displays the result overlay.  
    /// If validation fails due to an error, shows an error alert and restarts the timer, allowing the user to try again.  
    /// Provides haptic feedback based on the outcome.  
    ///
    /// - Parameter image: The photo to validate against the current mood.
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
    
    /// Skips the current mood if skips are available and no validation or result overlay is active.
    ///
    /// Decrements the remaining skips, clears the captured image, and starts a new round with haptic feedback. Skipping is only allowed when not validating and the result overlay is not shown.
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
    
    /// Hides the result overlay and clears the captured image.
    private func hideResultOverlay() {
        gameState.showResultOverlay = false
        capturedImage = nil
    }
    
    /// Hides the result overlay and starts a new round if the game is not over.
    func hideResultOverlayAndContinue() {
        hideResultOverlay()
        
        if !gameState.isGameOver {
            startNewRound()
        }
    }
    
    /// Checks if the app has authorization to access the device camera.
    ///
    /// - Returns: `true` if camera access is authorized; otherwise, `false`.
    func checkCameraPermission() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return status == .authorized
    }
    
    /// Requests camera access permission from the user and calls the completion handler with the result on the main thread.
    ///
    /// - Parameter completion: Closure called with `true` if access is granted, `false` otherwise.
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    /// Stops the countdown timer and cancels all Combine subscriptions to clean up resources.
    func cleanup() {
        stopTimer()
        cancellables.removeAll()
    }
    
    deinit {
        cleanup()
    }
} 