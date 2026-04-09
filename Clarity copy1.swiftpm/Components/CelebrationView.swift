
import SwiftUI

struct CelebrationView: View {
    let zone: String       // "Well Calibrated", "Overconfident", "Underconfident"
    let gapValue: Int
    let score: Int
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showParticles = false
    @State private var ringScale: CGFloat = 0.3
    @State private var ringOpacity: Double = 0

    private var zoneColor: Color {
        let gap = abs(gapValue)
        if gap <= 10 { return .green }
        if gap <= 25 { return .orange }
        return .red
    }

    private var zoneIcon: String {
        let gap = abs(gapValue)
        if gap <= 10 { return "checkmark.seal.fill" }
        if gapValue > 0 { return "arrow.up.circle.fill" }
        return "arrow.down.circle.fill"
    }

    private var zoneMessage: String {
        let gap = abs(gapValue)
        if gap <= 10 { return "Your confidence matches your knowledge!" }
        if gapValue > 25 { return "Let's work on calibrating your confidence." }
        if gapValue > 10 { return "Slightly overconfident — keep testing to improve." }
        if gapValue < -25 { return "You know more than you think. Trust yourself!" }
        return "Slightly underestimating — you're doing better than you think."
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture { dismissFlow() }

            // Expanding ring
            Circle()
                .stroke(zoneColor.opacity(0.3), lineWidth: 2)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            // Particle dots
            if showParticles {
                ForEach(0..<12, id: \.self) { i in
                    Circle()
                        .fill(zoneColor.opacity(Double.random(in: 0.3...0.8)))
                        .frame(width: CGFloat.random(in: 4...8))
                        .offset(particleOffset(index: i))
                        .transition(.scale.combined(with: .opacity))
                }
            }

            // Main content
            VStack(spacing: 28) {
                Spacer()

                // Zone icon
                ZStack {
                    Circle()
                        .fill(zoneColor.opacity(0.15))
                        .frame(width: 100, height: 100)
                        .scaleEffect(showContent ? 1 : 0.3)
                        .opacity(showContent ? 1 : 0)

                    Image(systemName: zoneIcon)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(zoneColor)
                        .shadow(color: zoneColor.opacity(0.6), radius: 20)
                        .scaleEffect(showContent ? 1 : 0.1)
                        .opacity(showContent ? 1 : 0)
                }

                // Score
                VStack(spacing: 6) {
                    Text("AI SCORE")
                        .font(.caption2.weight(.black))
                        .foregroundColor(.white.opacity(0.4))
                        .kerning(0.8)

                    Text("\(score)%")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundColor(zoneColor)
                        .shadow(color: zoneColor.opacity(0.5), radius: 16)
                        .contentTransition(.numericText())
                }
                .scaleEffect(showContent ? 1 : 0.5)
                .opacity(showContent ? 1 : 0)

                // Zone label
                VStack(spacing: 8) {
                    Text(zone)
                        .font(.title3.weight(.heavy))
                        .foregroundColor(.white)

                    Text(zoneMessage)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .offset(y: showContent ? 0 : 20)
                .opacity(showContent ? 1 : 0)

                Spacer()

                // Dismiss button
                Button {
                    dismissFlow()
                } label: {
                    Text("Done")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [zoneColor, zoneColor.opacity(0.6)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: zoneColor.opacity(0.4), radius: 16, y: 6)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 30)
                .offset(y: showContent ? 0 : 30)
                .opacity(showContent ? 1 : 0)
                .accessibilityLabel("Done — dismiss celebration")

                Spacer().frame(height: 40)
            }
        }
        .onAppear {
            HapticManager.shared.impact(style: .heavy)

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }

            withAnimation(.easeOut(duration: 1.2)) {
                ringScale = 3.0
                ringOpacity = 0
            }
            ringOpacity = 0.8

            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                showParticles = true
            }

            // Second haptic for the "well calibrated" case
            if abs(gapValue) <= 10 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    let gen = UINotificationFeedbackGenerator()
                    gen.notificationOccurred(.success)
                }
            }
        }
    }

    private func dismissFlow() {
        withAnimation(.easeIn(duration: 0.25)) { showContent = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onDismiss() }
    }

    private func particleOffset(index: Int) -> CGSize {
        let angle = Double(index) * (360.0 / 12.0) * .pi / 180.0
        let radius: CGFloat = showContent ? CGFloat.random(in: 80...140) : 0
        return CGSize(
            width: cos(angle) * radius,
            height: sin(angle) * radius
        )
    }
}
