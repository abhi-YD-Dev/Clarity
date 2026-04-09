
import SwiftUI

struct CelebrationView: View {
    let zone: String       // "Well Calibrated ✓", "Overconfident", "Underconfident"
    let gapValue: Int
    let score: Int
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showParticles = false
    @State private var ringScale: CGFloat = 0.3
    @State private var ringOpacity: Double = 0

    private var zoneColor: Color {
        let gap = abs(gapValue)
        if gap <= 10 { return ClarityTheme.accentGreen }
        if gap <= 25 { return ClarityTheme.accentOrange }
        return ClarityTheme.accentRed
    }

    private var zoneIcon: String {
        let gap = abs(gapValue)
        if gap <= 10 { return "checkmark.seal.fill" }
        if gapValue > 0 { return "arrow.up.circle.fill" }
        return "arrow.down.circle.fill"
    }

    private var zoneMessage: String {
        let gap = abs(gapValue)
        if gap <= 10 { return "Your confidence perfectly matches your knowledge!" }
        if gapValue > 25 { return "Let's work on calibrating your confidence." }
        if gapValue > 10 { return "Slightly overconfident — keep testing to improve." }
        if gapValue < -25 { return "You know more than you think. Trust yourself!" }
        return "Slightly underestimating — you're doing better than you think."
    }

    var body: some View {
        ZStack {
            // Glass material background
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea()
                .onTapGesture { dismissFlow() }

            // Color overlay for tinting
            zoneColor.opacity(0.06)
                .ignoresSafeArea()

            // Expanding ring
            Circle()
                .stroke(zoneColor.opacity(0.25), lineWidth: 2)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            // Particle dots
            if showParticles {
                ForEach(0..<16, id: \.self) { i in
                    particleDot(index: i)
                }
            }

            // Main content
            VStack(spacing: 32) {
                Spacer()

                // Zone icon
                ZStack {
                    Circle()
                        .fill(zoneColor.opacity(0.12))
                        .frame(width: 110, height: 110)
                        .scaleEffect(showContent ? 1 : 0.3)
                        .opacity(showContent ? 1 : 0)

                    Image(systemName: zoneIcon)
                        .font(.system(size: 52, weight: .bold))
                        .foregroundColor(zoneColor)
                        .shadow(color: zoneColor.opacity(0.4), radius: 20)
                        .scaleEffect(showContent ? 1 : 0.1)
                        .opacity(showContent ? 1 : 0)
                }

                // Score
                VStack(spacing: 8) {
                    Text("SCORE")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .kerning(1.2)

                    Text("\(score)%")
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundColor(zoneColor)
                        .shadow(color: zoneColor.opacity(0.35), radius: 16)
                        .contentTransition(.numericText())
                }
                .scaleEffect(showContent ? 1 : 0.5)
                .opacity(showContent ? 1 : 0)

                // Zone label
                VStack(spacing: 10) {
                    Text(zone)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)

                    Text(zoneMessage)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                }
                .offset(y: showContent ? 0 : 20)
                .opacity(showContent ? 1 : 0)

                Spacer()

                // Dismiss button — gradient CTA
                Button {
                    dismissFlow()
                } label: {
                    Text("Done")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [zoneColor, zoneColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: zoneColor.opacity(0.3), radius: 12, y: 6)
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

            // Success haptic for well-calibrated
            if abs(gapValue) <= 10 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    HapticManager.shared.notification(.success)
                }
            }
        }
    }

    // MARK: - Helpers

    private func dismissFlow() {
        withAnimation(.easeIn(duration: 0.25)) { showContent = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onDismiss() }
    }

    @ViewBuilder
    private func particleDot(index: Int) -> some View {
        let shapes = ["circle.fill", "star.fill", "diamond.fill", "triangle.fill"]
        let shape = shapes[index % shapes.count]
        let size = CGFloat.random(in: 4...10)

        Image(systemName: shape)
            .font(.system(size: size))
            .foregroundColor(zoneColor.opacity(Double.random(in: 0.3...0.7)))
            .offset(particleOffset(index: index))
            .transition(.scale.combined(with: .opacity))
    }

    private func particleOffset(index: Int) -> CGSize {
        let angle = Double(index) * (360.0 / 16.0) * .pi / 180.0
        let radius: CGFloat = showContent ? CGFloat.random(in: 80...160) : 0
        return CGSize(
            width: cos(angle) * radius,
            height: sin(angle) * radius
        )
    }
}
