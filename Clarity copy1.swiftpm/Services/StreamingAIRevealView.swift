
 
import SwiftUI
import FoundationModels

struct StreamingAIRevealView: View {

    let streamingState: StreamingState
    let partial: AIAnalysisResult.PartiallyGenerated?
    let finalResult: AIAnalysisResult?
    let profile: EvaluationProfile?
    let predictedScore: Int
    let confidence: Int
    var showPredicted: Bool = true

    @State private var pulseGlow = false
    @State private var showProfile = false

    private var displayScore: Int {
        finalResult?.accuracyScore ?? partial?.accuracyScore ?? 0
    }

    private var scoreColor: Color {
        switch displayScore {
        case 80...100: return .green
        case 60...79:  return .cyan
        case 40...59:  return .orange
        default:       return .red
        }
    }

    private var gapValue: Int { (showPredicted ? predictedScore : confidence) - displayScore }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerRow

            switch streamingState {
            case .idle:
                EmptyView()

            case .preparing:
                statusView(icon: "hourglass", label: "Initializing ClarityAI session...", color: .purple)

            case .toolCalling:
                toolCallingView

            case .streaming:
                VStack(alignment: .leading, spacing: 20) {
                    scoreSection
                    if let p = partial { streamingFieldsSection(partial: p) }
                }

            case .complete:
                VStack(alignment: .leading, spacing: 20) {
                    scoreSection
                
                    if let result = finalResult {
                        finalFieldsSection(result: result)
                    }
                    calibrationGapSection
                }

            case .failed(let message):
                failureView(message: message)
            }
        }
        .liquidCard()
        .onAppear { pulseGlow = true }
    }

    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("THE REALITY CHECK")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white.opacity(0.5))
                Text("AI Evaluation")
                    .font(.title2.weight(.heavy))
                    .foregroundColor(.white)
            }
            Spacer()
            if streamingState == .streaming {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 8, height: 8)
                        .scaleEffect(pulseGlow ? 1.3 : 0.8)
                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: pulseGlow)
                    Text("LIVE")
                        .font(.caption2.weight(.black))
                        .foregroundColor(.cyan)
                }
            }
        }
    }

    private func statusView(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(color)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    private var toolCallingView: some View {
        VStack(alignment: .leading, spacing: 12) {
            toolCallRow(icon: "doc.text.magnifyingglass", label: "Extracting concept rubric from model answer...", color: .cyan)
            toolCallRow(icon: "waveform.path.ecg",        label: "Profiling your answer quality...", color: .purple)
            toolCallRow(icon: "brain",                    label: "Building evaluation context...", color: .orange)
        }
        .padding(.vertical, 8)
    }

    private func toolCallRow(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            ProgressView().scaleEffect(0.8).tint(color)
        }
    }

    private var scoreSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("AI ACCURACY SCORE")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white.opacity(0.5))

                Text("\(displayScore)%")
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundColor(scoreColor)
                    .shadow(color: scoreColor.opacity(0.4), radius: 20)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: displayScore)
            }
            Spacer()
      
            let signal = finalResult?.recallSignal ?? partial?.recallSignal
            if let signal = signal {
                Text(signal)
                    .font(.caption.weight(.black)) // HIG
                    .foregroundColor(scoreColor)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(scoreColor.opacity(0.15))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(scoreColor.opacity(0.3), lineWidth: 1))
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }


    private func streamingFieldsSection(partial: AIAnalysisResult.PartiallyGenerated) -> some View {
        VStack(alignment: .leading, spacing: 16) {

           
            if let concepts = partial.missingConcepts, !concepts.isEmpty {
                fieldCard(icon: "exclamationmark.triangle.fill", label: "MISSING CONCEPTS", color: .orange) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(concepts, id: \.self) { concept in
                            HStack(spacing: 8) {
                                Circle().fill(Color.orange).frame(width: 6, height: 6)
                                Text(concept)
                                    .font(.subheadline.weight(.medium)) // HIG
                                    .foregroundColor(.white)
                            }
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                    }
                }
            } else {
                shimmerPlaceholder(label: "MISSING CONCEPTS", color: .orange)
            }

        
            if let claims = partial.incorrectClaims, !claims.isEmpty {
                fieldCard(icon: "xmark.circle.fill", label: "INCORRECT CLAIMS", color: .red) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(claims, id: \.self) { claim in
                            HStack(spacing: 8) {
                                Circle().fill(Color.red).frame(width: 6, height: 6)
                                Text(claim)
                                    .font(.subheadline.weight(.medium)) // HIG
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }

            if let feedback = partial.constructiveFeedback, !feedback.isEmpty {
                fieldCard(icon: "lightbulb.fill", label: "FEEDBACK", color: .cyan) {
                    Text(feedback)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(4)
                        .animation(.easeIn(duration: 0.2), value: feedback)
                }
            } else {
                shimmerPlaceholder(label: "FEEDBACK", color: .cyan)
            }
        }
    }


    private func finalFieldsSection(result: AIAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {

            if !result.missingConcepts.isEmpty {
                fieldCard(icon: "exclamationmark.triangle.fill", label: "MISSING CONCEPTS", color: .orange) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(result.missingConcepts, id: \.self) { concept in
                            HStack(spacing: 8) {
                                Circle().fill(Color.orange).frame(width: 6, height: 6)
                                Text(concept)
                                    .font(.subheadline.weight(.medium)) // HIG
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }

            if !result.incorrectClaims.isEmpty {
                fieldCard(icon: "xmark.circle.fill", label: "INCORRECT CLAIMS", color: .red) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(result.incorrectClaims, id: \.self) { claim in
                            HStack(spacing: 8) {
                                Circle().fill(Color.red).frame(width: 6, height: 6)
                                Text(claim)
                                    .font(.subheadline.weight(.medium)) // HIG
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }

            fieldCard(icon: "lightbulb.fill", label: "FEEDBACK", color: .cyan) {
                Text(result.constructiveFeedback)
                    .font(.subheadline.weight(.medium)) // HIG
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(4)
            }
        }
    }


    @ViewBuilder
    private func fieldCard<Content: View>(
        icon: String,
        label: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.footnote.weight(.bold))
                    .foregroundColor(color)
                Text(label)
                    .font(.caption2.weight(.black))
                    .foregroundColor(color.opacity(0.8))
                    .kerning(0.5)
            }
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(color.opacity(0.2), lineWidth: 1))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func shimmerPlaceholder(label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption2.weight(.black))
                .foregroundColor(color.opacity(0.3))
                .kerning(0.5)
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(0.08))
                .frame(height: 12)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var calibrationGapSection: some View {
        VStack(spacing: 14) {
            Divider().overlay(Color.white.opacity(0.1))

            HStack(spacing: 0) {
                if showPredicted {
                    scoreColumn(label: "YOU PREDICTED", value: predictedScore, color: .yellow)
                    Divider().frame(height: 50).overlay(Color.white.opacity(0.1))
                }
                scoreColumn(label: "CONFIDENCE", value: confidence, color: .cyan)
                Divider().frame(height: 50).overlay(Color.white.opacity(0.1))
                scoreColumn(label: "AI SCORE", value: displayScore, color: scoreColor)
            }

            let gap = abs(gapValue)
            let gapColor: Color = gap <= 10 ? .green : (gap <= 25 ? .orange : .red)
            let zoneLabel: String = {
                if gapValue > 25  { return "Overconfident Zone" }
                if gapValue < -25 { return "Underconfident Zone" }
                if gapValue > 10  { return "Slightly Overconfident" }
                if gapValue < -10 { return "Slightly Underestimating" }
                return "Well Calibrated ✓"
            }()

            VStack(spacing: 6) {
                Text("CLARITY GAP")
                    .font(.caption2.weight(.black))
                    .foregroundColor(.white.opacity(0.4))
                    .kerning(0.5)

                Text("\(gapValue > 0 ? "+" : "")\(gapValue) pts")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundColor(gapColor)
                    .shadow(color: gapColor.opacity(0.4), radius: 12)
                    .contentTransition(.numericText())

                Text(zoneLabel)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(gapColor)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(gapColor.opacity(0.12))
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(gapColor.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: streamingState == .complete)
    }

    private func scoreColumn(label: String, value: Int, color: Color) -> some View {
            VStack(spacing: 4) {
                Text(label)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white.opacity(0.4))
                    .kerning(0.3)
                    .multilineTextAlignment(.center)
                Text("\(value)%")
                    .font(.title2.weight(.heavy))
                    .fontDesign(.rounded)
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
        }

    private func profilerBadge(profile: EvaluationProfile) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring()) { showProfile.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "cpu.fill")
                        .font(.caption2)
                        .foregroundColor(.purple.opacity(0.7))
                    Text("ClarityAI Profile")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    Text("\(String(format: "%.0f", profile.latencyMilliseconds))ms")
                        .font(.caption2.weight(.bold).monospaced())
                        .foregroundColor(.purple.opacity(0.7))
                    Image(systemName: showProfile ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(10)
                .background(Color.purple.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.purple.opacity(0.15), lineWidth: 1))
            }
            .buttonStyle(.plain)

            if showProfile {
                Text(profile.summary)
                    .font(.caption2.monospaced()) // HIG
                    .foregroundColor(.white.opacity(0.5))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.purple.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func failureView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("Analysis Incomplete")
                .font(.headline.weight(.bold))
                .foregroundColor(.white)
            Text(message)
                .font(.caption) 
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}
