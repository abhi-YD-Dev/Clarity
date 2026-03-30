//
//  WelcomeView.swift
//  Clarity
//
//  Created by Abhinav Yadav on 20/02/26.
//


import SwiftUI

struct WelcomeView: View {
    
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            
            Color.black.ignoresSafeArea()
            
            RadialGradient(
                colors: [glowColor.opacity(0.3), .clear],
                center: .top,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.8), value: currentPage)
            
            VStack {
               
                TabView(selection: $currentPage) {
                    
                    OnboardingPage(
                        icon: "brain.head.profile",
                        iconColor: .orange,
                        title: "The Illusion of\nCompetence",
                        subtitle: "Recognizing an answer is not the same as recalling it. Stop re-reading your notes and start testing your actual memory.",
                        isActive: currentPage == 0
                    )
                    .tag(0)
                    
                    
                    OnboardingPage(
                        icon: "cpu",
                        iconColor: .purple,
                        title: "Ultimate\nCalibration",
                        subtitle: "Predict your score before the AI grades you. Discover if you are dangerously overconfident or suffering from imposter syndrome.",
                        isActive: currentPage == 1
                    )
                    .tag(1)
                    
                    OnboardingPage(
                        icon: "chart.xyaxis.line",
                        iconColor: .green,
                        title: "The Zone of\nClarity",
                        subtitle: "Track your metacognition over time. Flatten the curve, align your confidence with reality, and master your subjects.",
                        isActive: currentPage == 2
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                
                VStack(spacing: 24) {
                    
                    
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Capsule()
                                .fill(currentPage == index ? .white : .white.opacity(0.2))
                                .frame(width: currentPage == index ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    
                    Button {
                        if currentPage < 2 {
                            withAnimation {
                                currentPage += 1
                                HapticManager.shared.selection()
                            }
                        } else {
                            
                            HapticManager.shared.impact(style: .heavy)
                            withAnimation(.easeOut(duration: 0.3)) {
                                hasSeenOnboarding = true
                            }
                        }
                    } label: {
                        Text(currentPage == 2 ? "Ready" : "Continue")
                            .font(.system(.title3, weight: .bold))
                            .foregroundColor(currentPage == 2 ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                currentPage == 2 ? Color.green : Color.white.opacity(0.1)
                            )
                            .clipShape(Capsule())
                            .shadow(color: currentPage == 2 ? .green.opacity(0.4) : .clear, radius: 15, x: 0, y: 5)
                            .animation(.easeInOut, value: currentPage)
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    private var glowColor: Color {
        switch currentPage {
        case 0: return .orange
        case 1: return .purple
        case 2: return .green
        default: return .cyan
        }
    }
}

struct OnboardingPage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isActive: Bool
    
    @State private var triggerAnimation = 0
    
    var body: some View {
        VStack(spacing: 40) {
            
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 120, weight: .thin))
                .foregroundStyle(iconColor.gradient)
                .symbolEffect(.bounce.up.byLayer, value: triggerAnimation)
                .frame(height: 150)
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Text(subtitle)
                    .font(.system(.title3, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(6)
            }
            
            Spacer()
            Spacer()
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                triggerAnimation += 1
            }
        }
        .onAppear {
            if isActive {
                triggerAnimation += 1
            }
        }
    }
}
