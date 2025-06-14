//
//  GameOverView.swift
//  MoodMatch
//
//  Created by Abid Bhatti on 14/06/25.
//

import SwiftUI

struct GameOverView: View {
    let finalScore: Int
    let onPlayAgain: () -> Void
    let onGoHome: () -> Void
    
    @State private var animateScore = false
    @State private var showButtons = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.red.opacity(0.6), Color.orange.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Game Over Title
                VStack(spacing: 20) {
                    Text("Game Over")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("💔")
                        .font(.system(size: 60))
                        .scaleEffect(animateScore ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: animateScore)
                }
                
                // Score Display
                VStack(spacing: 15) {
                    Text("Final Score")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                        .fontWeight(.medium)
                    
                    Text("\(finalScore)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow)
                        .scaleEffect(animateScore ? 1.1 : 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animateScore)
                    
                    // Score feedback
                    Text(scoreMessage)
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Action Buttons
                if showButtons {
                    VStack(spacing: 20) {
                        // Play Again Button
                        Button(action: onPlayAgain) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title2)
                                Text("Play Again")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color.green.opacity(0.8))
                                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                            )
                        }
                        
                        // Home Button
                        Button(action: onGoHome) {
                            HStack {
                                Image(systemName: "house.fill")
                                    .font(.title2)
                                Text("Home")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color.blue.opacity(0.8))
                                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                            )
                        }
                    }
                    .padding(.horizontal, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
        }
        .onAppear {
            animateScore = true
            
            // Show buttons after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showButtons = true
                }
            }
        }
    }
    
    private var scoreMessage: String {
        switch finalScore {
        case 0:
            return "Better luck next time! 🎯"
        case 1...3:
            return "Not bad for a start! 🌟"
        case 4...7:
            return "Great job! You're getting good at this! 🎉"
        case 8...12:
            return "Impressive! You have a keen eye for moods! 👁️"
        case 13...20:
            return "Amazing! You're a mood matching master! 🏆"
        default:
            return "Incredible! You're a mood matching legend! 🎭"
        }
    }
}

#Preview {
    GameOverView(
        finalScore: 12,
        onPlayAgain: {},
        onGoHome: {}
    )
} 