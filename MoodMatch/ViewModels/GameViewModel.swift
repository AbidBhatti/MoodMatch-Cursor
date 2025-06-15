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
    
    /// Sets up a binding to automatically hide the result overlay and proceed to the next round 3 seconds after the overlay is shown.
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
    
    /// Resets the game state and mood provider, then starts a new game round.
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
    
    /// Starts a repeating timer that triggers the countdown update every second.
    private func startTimer() {
        stopTimer()
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    /// Stops and invalidates the active game timer.
    private func stopTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    /// Decrements the round timer and handles timeout by marking the match as incorrect if time runs out.
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
    /// If validation succeeds, updates the game state as correct or incorrect and displays the result overlay with appropriate haptic feedback.  
    /// If validation fails due to an error, shows an error alert, restarts the timer, and provides error haptic feedback.  
    /// Does nothing if there is no current mood.
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
    
    /// Skips the current mood if skips remain and no validation or result overlay is active.
    ///
    /// Stops the timer, clears validation state and the captured image, uses a skip, starts a new round, and provides medium haptic feedback.
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
    
    /// Requests camera access permission from the user.
    ///
    /// Calls the completion handler with `true` if access is granted, or `false` otherwise. The completion handler is always invoked on the main thread.
    ///
    /// - Parameter completion: Closure called with the result of the permission request.
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