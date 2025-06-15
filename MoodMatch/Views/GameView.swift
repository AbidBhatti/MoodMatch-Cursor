//
//  GameView.swift
//  MoodMatch
//
//  Created by Abid Bhatti on 14/06/25.
//

import SwiftUI
import AVFoundation

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingCamera = false
    @State private var showingPermissionAlert = false
    @State private var showingGameOver = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            if viewModel.gameState.isGameOver {
                // Game Over View
                GameOverView(
                    finalScore: viewModel.gameState.score,
                    onPlayAgain: {
                        // Reset the game over state first
                        showingGameOver = false
                        // Clear any existing state
                        viewModel.capturedImage = nil
                        // Start a completely new game
                        viewModel.startNewGame()
                    },
                    onGoHome: {
                        dismiss()
                    }
                )
            } else {
                // Main Game Interface
                VStack(spacing: 0) {
                    // Top HUD
                    topHUD
                    
                    Spacer()
                    
                    // Current Mood Display
                    moodDisplay
                    
                    Spacer()
                    
                    // Camera Preview Area
                    cameraPreviewArea
                    
                    Spacer()
                    
                    // Bottom Controls
                    bottomControls
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            
            // Loading/Validation Overlay
            if viewModel.gameState.isValidating {
                validationOverlay
            }
            
            // Result Overlay
            if viewModel.gameState.showResultOverlay {
                resultOverlay
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(isPresented: $showingCamera) { image in
                viewModel.capturePhoto(image)
            }
        }
        .alert("Camera Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Please enable camera access in Settings to play MoodMatch.")
        }
        .alert("Validation Error", isPresented: $viewModel.showErrorAlert) {
            Button("Try Again", role: .cancel) {
                // Timer was already restarted in the error handler
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewModel.gameState.isGameOver, { _, isGameOver in
            if isGameOver {
                showingGameOver = true
            }
        })
        .onAppear {
            checkCameraPermission()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
    
    // MARK: - View Components
    
    private var topHUD: some View {
        HStack {
            // Score
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("\(viewModel.gameState.score)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Lives
            HStack(spacing: 5) {
                ForEach(0..<GameState.maxLives, id: \.self) { index in
                    Image(systemName: "heart.fill")
                        .foregroundColor(index < viewModel.gameState.lives ? .red : .gray.opacity(0.3))
                        .font(.title2)
                }
            }
        }
        .padding(.top, 10)
    }
    
    private var moodDisplay: some View {
        VStack(spacing: 15) {
            Text("Show me...")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
            
            Text(viewModel.gameState.currentMood)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue.opacity(0.3))
                        .stroke(Color.blue, lineWidth: 2)
                )
                .scaleEffect(viewModel.gameState.timeRemaining <= 5 ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.5), value: viewModel.gameState.timeRemaining)
        }
    }
    
    private var cameraPreviewArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 300)
                .overlay(
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.6))
                        Text("Tap capture to take photo")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.body)
                    }
                )
            
            // Display captured image if available
            if let image = viewModel.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 300)
                    .clipped()
                    .cornerRadius(20)
            }
        }
    }
    
    private var bottomControls: some View {
        HStack {
            // Timer
            VStack {
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundColor(viewModel.gameState.timeRemaining <= 5 ? .red : .orange)
                
                Text("\(viewModel.gameState.timeRemaining)s")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.gameState.timeRemaining <= 5 ? .red : .white)
            }
            
            Spacer()
            
            // Capture Button
            Button(action: capturePhoto) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(Color.gray, lineWidth: 5)
                            .frame(width: 70, height: 70)
                    )
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.title)
                            .foregroundColor(.black)
                    )
            }
            .disabled(viewModel.gameState.isValidating)
            .scaleEffect(viewModel.gameState.isValidating ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: viewModel.gameState.isValidating)
            
            Spacer()
            
            // Skip Button
            Button(action: {
                viewModel.skipCurrentMood()
            }) {
                VStack {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.gameState.skipsRemaining > 0 ? .blue : .gray)
                    
                    Text("\(viewModel.gameState.skipsRemaining) skips")
                        .font(.caption)
                        .foregroundColor(viewModel.gameState.skipsRemaining > 0 ? .white : .gray)
                }
            }
            .disabled(viewModel.gameState.skipsRemaining <= 0 || viewModel.gameState.isValidating)
        }
        .padding(.bottom, 30)
    }
    
    private var validationOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Checking your mood...")
                    .font(.title2)
                    .foregroundColor(.white)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.8))
            )
        }
    }
    
    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    // Allow manual dismissal by tapping
                    viewModel.hideResultOverlayAndContinue()
                }
            
            VStack(spacing: 20) {
                // Result Icon
                Image(systemName: viewModel.gameState.lastResult ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(viewModel.gameState.lastResult ? .green : .red)
                    .scaleEffect(1.2)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: viewModel.gameState.showResultOverlay)
                
                // Result Text
                Text(viewModel.gameState.lastResult ? "Perfect Match! +1" : "Not quite right...")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Tap to continue hint
                Text("Tap to continue")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 10)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.9))
                    .stroke(viewModel.gameState.lastResult ? Color.green : Color.red, lineWidth: 2)
            )
            .onTapGesture {
                // Allow manual dismissal by tapping the overlay
                viewModel.hideResultOverlayAndContinue()
            }
        }
    }
    
    /// Initiates the photo capture process by checking and requesting camera permission as needed.
    ///
    /// If camera permission is already granted, presents the camera interface. Otherwise, requests permission and shows an alert if access is denied.
    
    private func capturePhoto() {
        if viewModel.checkCameraPermission() {
            showingCamera = true
        } else {
            viewModel.requestCameraPermission { granted in
                if granted {
                    showingCamera = true
                } else {
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    /// Checks and requests camera permission if not already granted, displaying an alert if permission is denied.
    private func checkCameraPermission() {
        if !viewModel.checkCameraPermission() {
            viewModel.requestCameraPermission { granted in
                if !granted {
                    showingPermissionAlert = true
                }
            }
        }
    }
}

#Preview {
    GameView(viewModel: GameViewModel(moodValidator: OpenAIMoodValidator()))
} 
