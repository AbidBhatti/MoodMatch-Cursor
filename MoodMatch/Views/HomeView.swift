//
//  HomeView.swift
//  MoodMatch
//
//  Created by Abid Bhatti on 14/06/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = GameViewModel(moodValidator: OpenAIMoodValidator())
    @State private var showingGame = false
    @State private var animateTitle = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Background gradient
                    LinearGradient(
                        colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    VStack(spacing: 40) {
                        Spacer()
                        
                        // App Title
                        VStack(spacing: 10) {
                            Text("MoodMatch")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .scaleEffect(animateTitle ? 1.0 : 0.8)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateTitle)
                            
                            Text("📸 Match Your Mood")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.9))
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        // Game Instructions
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(alignment: .center, spacing: 15) {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.yellow)
                                    .font(.title2)
                                    .frame(width: 24, alignment: .center)
                                
                                Text("Take photos that match the mood")
                                    .foregroundColor(.white)
                                    .font(.body)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                            
                            HStack(alignment: .center, spacing: 15) {
                                Image(systemName: "timer")
                                    .foregroundColor(.orange)
                                    .font(.title2)
                                    .frame(width: 24, alignment: .center)
                                
                                Text("30 seconds per round")
                                    .foregroundColor(.white)
                                    .font(.body)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                            
                            HStack(alignment: .center, spacing: 15) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                    .font(.title2)
                                    .frame(width: 24, alignment: .center)
                                
                                Text("3 lives to beat your best score")
                                    .foregroundColor(.white)
                                    .font(.body)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 30)
                        
                        Spacer()
                        
                        // Start Game Button
                        Button(action: {
                            startGame()
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.title2)
                                Text("Start Game")
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
                        .padding(.horizontal, 40)
                        .scaleEffect(showingGame ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: showingGame)
                        
                        Spacer()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $showingGame) {
            GameView(viewModel: viewModel)
        }
        .onAppear {
            animateTitle = true
        }
    }
    
    /// Starts a new game and presents the game screen.
    private func startGame() {
        viewModel.startNewGame()
        showingGame = true
    }
}

#Preview {
    HomeView()
} 