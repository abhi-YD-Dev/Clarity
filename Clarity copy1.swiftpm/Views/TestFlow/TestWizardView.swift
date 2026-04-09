
import SwiftUI
import SwiftData
import PhotosUI
import FoundationModels


struct TestWizardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    let topic: Topic

    enum TestStep: Int, CaseIterable {
        case question = 0, confidence, answer, evaluationChoice,
             compareAnswers, predictScore, aiReveal, reflection

        var description: String {
            switch self {
            case .question: return "Question"
            case .confidence: return "Confidence"
            case .answer: return "Your Answer"
            case .evaluationChoice: return "Evaluate"
            case .compareAnswers: return "Compare"
            case .predictScore: return "Self Grade"
            case .aiReveal: return "AI Result"
            case .reflection: return "Reflect"
            }
        }
    }

    enum EvaluationMode { case none, selfReflect, aiOnly, ultimateCalibration }

    @State private var step: TestStep = .question
    @State private var evalMode: EvaluationMode = .none
    @State private var slideForward = true

    @State private var showHint      = false
    @State private var confidence    = 50.0
    @State private var userAnswers:  [SolutionMedia] = []
    @State private var predictedScore = 50.0
    @State private var aiScore:      Int? = nil
    @State private var reflectionText = ""
    @State private var isAnalyzing   = false

    @State private var streamingState:    StreamingState = .idle
    @State private var partialResult:     AIAnalysisResult.PartiallyGenerated? = nil
    @State private var finalResult:       AIAnalysisResult? = nil
    @State private var evaluationProfile: EvaluationProfile? = nil
    
    @State private var showingTextAdd          = false
    @State private var pendingTextAnswer       = ""
    @State private var showingImageActionSheet = false
    @State private var showingCamera           = false
    @State private var showingGallery          = false
    @State private var cameraImageData: Data?  = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @StateObject private var voiceRecorder     = VoiceRecorder()
    @State private var showCelebration         = false


    private var stepAccent: Color {
        switch step {
        case .question:          return .white
        case .confidence:        return .cyan
        case .answer:            return Color(red: 0.4, green: 0.7, blue: 1.0)
        case .evaluationChoice:  return .indigo
        case .compareAnswers:    return .teal
        case .predictScore:      return Color(red: 1.0, green: 0.8, blue: 0.2)
        case .aiReveal:          return .purple
        case .reflection:        return Color(red: 0.3, green: 0.9, blue: 0.6)
        }
    }

    private var stepLabel: String {
        switch step {
        case .question:         return "Question"
        case .confidence:       return "Confidence"
        case .answer:           return "Your Answer"
        case .evaluationChoice: return "Evaluate"
        case .compareAnswers:   return "Compare"
        case .predictScore:     return "Self Grade"
        case .aiReveal:         return "AI Result"
        case .reflection:       return "Reflect"
        }
    }

    private var stepNumber: Int { step.rawValue + 1 }
    private var totalSteps: Int { TestStep.allCases.count }

    var isButtonDisabled: Bool {
        if step == .evaluationChoice && evalMode == .none { return true }
        if step == .answer && userAnswers.isEmpty { return true }
        if step == .aiReveal {
            switch streamingState {
            case .preparing, .toolCalling, .streaming: return true
            default: return false
            }
        }
        return false
    }

    private var primaryLabel: String {
        switch step {
        case .question:         return "I'm Ready"
        case .confidence:       return "Begin Recall"
        case .answer:           return "Lock In Answer"
        case .evaluationChoice: return "Continue"
        case .compareAnswers:   return "Grade Myself"
        case .predictScore:     return evalMode == .selfReflect ? "Confirm Grade" : "Reveal AI Reality"
        case .aiReveal:         return isAnalyzing ? "Analyzing…" : "Continue to Reflection"
        case .reflection:       return "Save Attempt"
        }
    }

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.08).ignoresSafeArea()

            Text("\(stepNumber)")
                .font(.system(size: 240, weight: .black, design: .rounded))
                .foregroundColor(stepAccent.opacity(0.04))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .offset(x: 30, y: 40)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: step)

            VStack(spacing: 0) {

                navBar

                stepHeader
                    .padding(.horizontal, 28)
                    .padding(.top, 8)
                    .padding(.bottom, 24)

                ScrollView(showsIndicators: false) {
                    ZStack {
                        currentStepView
                            .id(step)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: slideForward ? .trailing : .leading).combined(with: .opacity),
                                    removal:   .move(edge: slideForward ? .leading  : .trailing).combined(with: .opacity)
                                )
                            )
                    }
                    .animation(.spring(response: 0.42, dampingFraction: 0.85), value: step)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 140)
                }

                Spacer(minLength: 0)
            }
            VStack {
                Spacer()
                primaryButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
                    .background(
                        LinearGradient(
                            colors: [.clear, Color(red: 0.05, green: 0.05, blue: 0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 130)
                        .ignoresSafeArea()
                    )
            }

            // Celebration overlay
            if showCelebration {
                CelebrationView(
                    zone: celebrationZone,
                    gapValue: celebrationGap,
                    score: celebrationScore,
                    onDismiss: { dismiss() }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .alert("Add Text Answer", isPresented: $showingTextAdd) {
            TextField("Type your answer…", text: $pendingTextAnswer)
            Button("Cancel", role: .cancel) { pendingTextAnswer = "" }
            Button("Add") {
                if !pendingTextAnswer.isEmpty {
                    userAnswers.append(SolutionMedia(type: .text, textContent: pendingTextAnswer))
                    pendingTextAnswer = ""
                }
            }
        }
        .alert("Add an Image Answer", isPresented: $showingImageActionSheet) {
            Button("Take Photo")          { showingCamera  = true }
            Button("Choose from Gallery") { showingGallery = true }
            Button("Cancel", role: .cancel) { }
        } message: { Text("Capture your handwritten notes.") }
        .photosPicker(isPresented: $showingGallery, selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared())
        .sheet(isPresented: $showingCamera) {
            CameraPicker(selectedImageData: $cameraImageData).ignoresSafeArea()
        }
        .onChange(of: cameraImageData) { _, newData in
            if let data = newData { userAnswers.append(SolutionMedia(type: .image, imageData: data)); cameraImageData = nil }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    userAnswers.append(SolutionMedia(type: .image, imageData: data))
                }
                selectedPhotoItem = nil
            }
        }
    }
    private var navBar: some View {
        HStack {
            Button {
                if step.rawValue > 0 {
                    slideForward = false
                    withAnimation { step = TestStep(rawValue: step.rawValue - 1)! }
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: step == .question ? "xmark" : "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.07))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(step == .question ? "Close" : "Go back")
            .accessibilityHint(step == .question ? "Dismiss the test" : "Return to \(stepNumber > 1 ? TestStep(rawValue: step.rawValue - 1)!.description : "previous step")")

            Spacer()
            HStack(spacing: 5) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i <= step.rawValue ? stepAccent : Color.white.opacity(0.12))
                        .frame(width: i == step.rawValue ? 18 : 5, height: 5)
                        .animation(.spring(response: 0.35), value: step)
                }
            }

            Spacer()
            Text(topic.difficultyRaw.uppercased())
                .font(.caption2.weight(.bold)) // HIG
                .kerning(0.5)
                .foregroundColor(topic.difficulty.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(topic.difficulty.color.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    private var stepHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(stepNumber) of \(totalSteps)")
                    .font(.caption2.weight(.bold).monospaced())
                    .foregroundColor(stepAccent.opacity(0.6))
                    .kerning(0.5)

                Text(stepLabel)
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.white)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch step {
        case .question:         questionStep
        case .confidence:       confidenceStep
        case .answer:           answerStep
        case .evaluationChoice: evaluationChoiceStep
        case .compareAnswers:   compareAnswersStep
        case .predictScore:     predictScoreStep
        case .aiReveal:         aiRevealStep
        case .reflection:       reflectionStep
        }
    }

    private var questionStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            Label(topic.title, systemImage: "doc.text")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)
            Text(topic.question)
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.35)) { showHint.toggle() }
                    HapticManager.shared.selection()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: showHint ? "lightbulb.fill" : "lightbulb")
                            .font(.subheadline.weight(.semibold))
                        Text(showHint ? "Hide Hint" : "Show Hint")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.2))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)

                if showHint {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.2))
                            .padding(.top, 2)
                        Text(topic.quickHint)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .background(Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.2), lineWidth: 1))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .stepCard(accent: stepAccent)
    }

    private var confidenceStep: some View {
        VStack(alignment: .leading, spacing: 36) {

            VStack(alignment: .leading, spacing: 8) {
                Text("Before writing a single word —")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.5))
                Text("How confident are you that you know this?")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)
                    .lineSpacing(4)
            }

            VStack(spacing: 4) {
                Text("\(Int(confidence))")
                    .font(.system(size: 88, weight: .black, design: .rounded))
                    .foregroundColor(stepAccent)
                    .shadow(color: stepAccent.opacity(0.4), radius: 20)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.25), value: Int(confidence))

                Text("percent confident")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 10) {
                Slider(value: $confidence, in: 0...100, step: 5)
                    .tint(stepAccent)
                    .onChange(of: confidence) { HapticManager.shared.selection() }
                    .accessibilityLabel("Confidence level")
                    .accessibilityValue("\(Int(confidence)) percent")
                    .accessibilityHint("Adjust how confident you feel about this topic")

                HStack {
                    Text("Not sure at all")
                    Spacer()
                    Text("Completely certain")
                }
                .font(.caption2.weight(.medium))
                .foregroundColor(.white.opacity(0.25))
            }

            confidenceBandLabel
        }
        .stepCard(accent: stepAccent)
    }

    private var confidenceBandLabel: some View {
        let conf = Int(confidence)
        let (label, color): (String, Color) = {
            switch conf {
            case 0..<30:   return ("Low confidence — be honest with yourself.", .orange)
            case 30..<60:  return ("Moderate confidence — interesting territory.", .yellow)
            case 60..<85:  return ("High confidence — let's see if it holds up.", .cyan)
            default:       return ("Very high confidence — bold claim!", .green)
            }
        }()

        return HStack(spacing: 8) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(color.opacity(0.9))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(color.opacity(0.08))
        .clipShape(Capsule())
        .animation(.easeInOut(duration: 0.2), value: Int(confidence / 30))
    }

    private var answerStep: some View {
        VStack(alignment: .leading, spacing: 24) {

            VStack(alignment: .leading, spacing: 8) {
                Text("No hints. No peeking.")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.4))
                Text("Write everything you know from memory.")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)
                    .lineSpacing(4)
            }

     
            if !userAnswers.isEmpty {
                VStack(spacing: 10) {
                    ForEach(userAnswers) { answer in
                        answerChip(answer)
                    }
                }
            } else {
        
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.12))
                    Text("Use one of the input modes below")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.25))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            HStack(spacing: 10) {
                MediaInputButton(icon: "text.cursor",     label: "Text",  color: stepAccent) { showingTextAdd = true }
                MediaInputButton(icon: "camera.viewfinder", label: "Image", color: .purple)  { showingImageActionSheet = true }

                Button {
                    if voiceRecorder.isRecording {
                        if let data = voiceRecorder.stopRecording() {
                            userAnswers.append(SolutionMedia(type: .voice, audioData: data))
                        }
                        HapticManager.shared.impact(style: .rigid)
                    } else {
                        voiceRecorder.startRecording()
                        HapticManager.shared.impact(style: .medium)
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: voiceRecorder.isRecording ? "stop.circle.fill" : "mic.fill")
                            .font(.title3.weight(.semibold))
                        Text(voiceRecorder.isRecording ? "Stop" : "Voice")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundColor(voiceRecorder.isRecording ? .white : .orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(voiceRecorder.isRecording ? Color.red : Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(voiceRecorder.isRecording ? Color.red.opacity(0.5) : Color.orange.opacity(0.2), lineWidth: 1))
                    .scaleEffect(voiceRecorder.isRecording ? 1.04 : 1.0)
                    .animation(voiceRecorder.isRecording ? .easeInOut(duration: 0.8).repeatForever() : .default, value: voiceRecorder.isRecording)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(voiceRecorder.isRecording ? "Stop recording" : "Record voice answer")
                .accessibilityHint(voiceRecorder.isRecording ? "Double tap to stop and save your voice recording" : "Double tap to start recording a voice answer")
            }
        }
        .stepCard(accent: stepAccent)
    }

    private func answerChip(_ answer: SolutionMedia) -> some View {
        HStack(spacing: 12) {
            Image(systemName: answer.type == .text ? "text.alignleft" : answer.type == .image ? "photo" : "waveform")
                .font(.footnote.weight(.semibold)) // HIG
                .foregroundColor(stepAccent)
                .frame(width: 32, height: 32)
                .background(stepAccent.opacity(0.1))
                .clipShape(Circle())

            Group {
                if answer.type == .text {
                    Text(answer.textContent ?? "")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                } else if answer.type == .image, let data = answer.imageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 34)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else if answer.type == .voice {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Voice Recording")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                        Text("Audio attached")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }

            Spacer()

            Button {
                withAnimation(.spring()) { userAnswers.removeAll { $0.id == answer.id } }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white.opacity(0.3))
                    .frame(width: 24, height: 24)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(answer.type == .text ? "text" : answer.type == .image ? "image" : "voice") answer")
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .transition(.move(edge: .top).combined(with: .opacity))
    }



    private var evaluationChoiceStep: some View {
        VStack(alignment: .leading, spacing: 20) {

            VStack(alignment: .leading, spacing: 8) {
                Text("Answer locked. Now —")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.4))
                Text("How do you want to evaluate?")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 12) {
                evalOption(
                    title:    "Self Analysis",
                    subtitle: "Compare to model answer. Grade yourself.",
                    icon:     "person.fill.viewfinder",
                    color:    .cyan,
                    selected: evalMode == .selfReflect
                ) {
                    evalMode = .selfReflect
                    HapticManager.shared.selection()
                }

                evalOption(
                    title:    "AI Analysis",
                    subtitle: "Instant objective grading by Apple Intelligence.",
                    icon:     "sparkles",
                    color:    .indigo,
                    selected: evalMode == .aiOnly
                ) {
                    evalMode = .aiOnly
                    HapticManager.shared.selection()
                }

                evalOption(
                    title:    "Ultimate Calibration",
                    subtitle: "Predict your score first, then face the AI reality.",
                    icon:     "cpu",
                    color:    .purple,
                    selected: evalMode == .ultimateCalibration
                ) {
                    evalMode = .ultimateCalibration
                    HapticManager.shared.selection()
                }
            }
        }
        .stepCard(accent: stepAccent)
    }

    private func evalOption(
        title: String, subtitle: String, icon: String,
        color: Color, selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(selected ? 0.25 : 0.08))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(2)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(selected ? color : Color.white.opacity(0.15), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if selected {
                        Circle()
                            .fill(color)
                            .frame(width: 12, height: 12)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3), value: selected)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selected ? color.opacity(0.08) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(selected ? color.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
            )
            .animation(.spring(response: 0.3), value: selected)
        }
        .buttonStyle(.plain)
    }

    private var compareAnswersStep: some View {
        VStack(alignment: .leading, spacing: 20) {

            VStack(alignment: .leading, spacing: 8) {
                Text("No more guessing —")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.4))
                Text("See the model answer.")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)
            }
            comparePanel(
                title: "Model Answer",
                icon: "checkmark.seal.fill",
                color: .teal,
                items: topic.solutions,
                emptyMessage: "No model solution provided."
            )
            comparePanel(
                title: "Your Answer",
                icon: "person.fill",
                color: stepAccent,
                items: userAnswers,
                emptyMessage: "No answer recorded."
            )
        }
        .stepCard(accent: stepAccent)
    }

    private func comparePanel(title: String, icon: String, color: Color, items: [SolutionMedia], emptyMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(color)
            }

            if items.isEmpty {
                Text(emptyMessage)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(items) { item in renderMediaItem(item) }
                }
            }
        }
        .padding(16)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(color.opacity(0.2), lineWidth: 1))
    }

    @ViewBuilder
    private func renderMediaItem(_ media: SolutionMedia) -> some View {
        if media.type == .text {
            Text(media.textContent ?? "")
                .font(.subheadline.weight(.regular))
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(4)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else if media.type == .image, let data = media.imageData, let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable().scaledToFit()
                .frame(maxHeight: 180)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else if media.type == .voice, let data = media.audioData {
            AudioPlaybackRow(audioData: data)
        }
    }


    private var predictScoreStep: some View {
        VStack(alignment: .leading, spacing: 36) {

            VStack(alignment: .leading, spacing: 8) {
                Text(evalMode == .ultimateCalibration ? "Commit to a number —" : "Be honest with yourself —")
                    .font(.subheadline.weight(.medium)) // HIG
                    .foregroundColor(.white.opacity(0.4))
                Text(evalMode == .ultimateCalibration
                     ? "What score do you think you earned?"
                     : "What is your honest self-grade?")
                    .font(.title3.weight(.bold)) // HIG
                    .foregroundColor(.white)
                    .lineSpacing(4)
            }

            VStack(spacing: 4) {
                Text("\(Int(predictedScore))")
                    .font(.system(size: 88, weight: .black, design: .rounded))
                    .foregroundColor(stepAccent)
                    .shadow(color: stepAccent.opacity(0.35), radius: 20)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.25), value: Int(predictedScore))

                Text("out of 100")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 10) {
                Slider(value: $predictedScore, in: 0...100, step: 5)
                    .tint(stepAccent)
                    .onChange(of: predictedScore) { HapticManager.shared.selection() }
                    .accessibilityLabel(evalMode == .selfReflect ? "Self grade" : "Predicted score")
                    .accessibilityValue("\(Int(predictedScore)) percent")
                    .accessibilityHint("Adjust your predicted accuracy score")
                HStack {
                    Text("0%")
                    Spacer()
                    Text("100%")
                }
                .font(.caption2.weight(.medium))
                .foregroundColor(.white.opacity(0.2))
            }

            if evalMode == .ultimateCalibration {
                let gap = Int(confidence) - Int(predictedScore)
                HStack(spacing: 10) {
                    Image(systemName: "arrow.up.left.and.down.right.magnifyingglass")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.4))
                    Text("Confidence: \(Int(confidence))%  →  Prediction: \(Int(predictedScore))%  =  \(gap > 0 ? "+" : "")\(gap) gap")
                        .font(.caption.weight(.medium).monospaced())
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .stepCard(accent: stepAccent)
    }

  

    var aiRevealStep: some View {
        StreamingAIRevealView(
            streamingState: streamingState,
            partial: partialResult,
            finalResult: finalResult,
            profile: evaluationProfile,
            predictedScore: Int(predictedScore),
            confidence: Int(confidence),
            showPredicted: evalMode != .aiOnly
        )
    }

    private var reflectionStep: some View {
        VStack(alignment: .leading, spacing: 24) {

            VStack(alignment: .leading, spacing: 8) {
                Text("The session is over —")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.4))
                Text("What did this reveal about you?")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)
                    .lineSpacing(4)
            }

            HStack(spacing: 0) {
                scoreColumn(
                    label: "Confidence",
                    value: "\(Int(confidence))%",
                    color: .cyan,
                    icon: "brain"
                )
                VStack(spacing: 6) {
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.bold)) // HIG
                        .foregroundColor(.white.opacity(0.2))

                    let gap = Int(confidence) - (evalMode == .selfReflect ? Int(predictedScore) : (aiScore ?? 0))
                    Text("\(gap > 0 ? "": "")\(gap)")
                        .font(.caption2.weight(.heavy).monospaced()) // HIG
                        .foregroundColor(gap == 0 ? .green : (abs(gap) > 20 ? .red : .orange))
                }
                .frame(maxWidth: .infinity)

                scoreColumn(
                    label: evalMode == .selfReflect ? "Self Grade" : "AI Grade",
                    value: "\(evalMode == .selfReflect ? Int(predictedScore) : (aiScore ?? 0))%",
                    color: evalMode == .selfReflect ? Color(red: 1.0, green: 0.8, blue: 0.2) : .purple,
                    icon: evalMode == .selfReflect ? "person.fill" : "sparkles"
                )
            }
            .padding(18)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))

            Text("Why did this gap happen? What do you think?")
                .font(.subheadline.weight(.semibold)) // HIG
                .foregroundColor(.white.opacity(0.7))

            
            ZStack(alignment: .topLeading) {
                if reflectionText.isEmpty {
                    Text("Write your reflection here…")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.2))
                        .padding(14)
                }
                TextEditor(text: $reflectionText)
                    .font(.body)
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .tint(stepAccent)
                    .frame(height: 130)
                    .padding(8)
            }
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(stepAccent.opacity(reflectionText.isEmpty ? 0.1 : 0.3), lineWidth: 1))
            .animation(.easeInOut(duration: 0.2), value: reflectionText.isEmpty)
        }
        .stepCard(accent: stepAccent)
    }

    private func scoreColumn(label: String, value: String, color: Color, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(color.opacity(0.8))
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Primary Button

    private var primaryButton: some View {
        Button {
            handlePrimaryAction()
            HapticManager.shared.impact(style: .rigid)
        } label: {
            HStack(spacing: 10) {
                if step == .aiReveal && isAnalyzing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.85)
                }
                Text(primaryLabel)
                    .font(.headline.weight(.bold))
                if !isButtonDisabled && step != .reflection {
                    Image(systemName: step == .reflection ? "checkmark" : "arrow.right")
                        .font(.footnote.weight(.bold))
                }
            }
            .foregroundColor(isButtonDisabled ? .white.opacity(0.25) : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Group {
                    if isButtonDisabled {
                        AnyView(Color.white.opacity(0.07))
                    } else if step == .reflection {
                        AnyView(LinearGradient(
                            colors: [stepAccent, stepAccent.opacity(0.7)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                    } else {
                        AnyView(LinearGradient(
                            colors: [stepAccent, stepAccent.opacity(0.65)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(
                color: isButtonDisabled ? .clear : stepAccent.opacity(0.45),
                radius: 16, x: 0, y: 6
            )
            .animation(.spring(response: 0.35), value: isButtonDisabled)
        }
        .disabled(isButtonDisabled)
        .buttonStyle(.plain)
    }

    func handlePrimaryAction() {
        if step == .aiReveal && isAnalyzing { return }
        slideForward = true
        withAnimation {
            switch step {
            case .question, .confidence, .answer:
                advanceStep()
            case .evaluationChoice:
                if evalMode == .selfReflect {
                    step = .compareAnswers
                } else if evalMode == .aiOnly {
                    step = .aiReveal
                    triggerAIEvaluation()
                } else {
                    
                    step = .compareAnswers
                }
            case .compareAnswers:
                step = .predictScore
            case .predictScore:
                if evalMode == .ultimateCalibration {
                    step = .aiReveal
                    triggerAIEvaluation()
                } else {
                    step = .reflection
                }
            case .aiReveal:
                advanceStep()
            case .reflection:
                saveAttempt()
            }
        }
    }

    func advanceStep() {
        if let next = TestStep(rawValue: step.rawValue + 1) { step = next }
    }

    func triggerAIEvaluation() {
            switch streamingState {
            case .preparing, .toolCalling, .streaming: return
            default: break
            }
            partialResult = nil; finalResult = nil; evaluationProfile = nil
            isAnalyzing = true; streamingState = .idle

            // MINIMAL FIX: Extract thread-safe properties BEFORE entering the Task
            let payload = AIEvaluationPayload(
                title: topic.title,
                question: topic.question,
                quickHint: topic.quickHint,
                difficulty: topic.difficultyRaw,
                solutions: topic.solutions,
                userAnswers: userAnswers
            )

            if #available(iOS 26.0, *) {
                Task {
                    
                    await AIEvaluationEngine.shared.streamEvaluation(
                        payload: payload,
                        onStateChange: { s in
                            await MainActor.run { withAnimation(.spring(response: 0.4)) { self.streamingState = s } }
                        },
                        onProfileUpdate: { p in
                            await MainActor.run { self.evaluationProfile = p }
                        },
                        onPartialUpdate: { partial in
                            await MainActor.run {
                                withAnimation(.easeIn(duration: 0.15)) {
                                    self.partialResult = partial
                                    if let score = partial.accuracyScore { self.aiScore = score }
                                }
                            }
                        },
                        onComplete: { result in
                            await MainActor.run {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    self.finalResult = result
                                    self.aiScore = result.accuracyScore
                                    self.isAnalyzing = false
                                    HapticManager.shared.impact(style: .heavy)
                                }
                            }
                        },
                        onError: { error in
                            await MainActor.run {
                                withAnimation { self.streamingState = .failed(error.localizedDescription); self.isAnalyzing = false }
                            }
                            // Pass 'payload' to fallback
                            let fallback = await AIEvaluationEngine.shared.fallbackEvaluation(payload: payload)
                            await MainActor.run {
                                withAnimation { self.finalResult = fallback; self.aiScore = fallback.accuracyScore; self.streamingState = .complete; self.isAnalyzing = false }
                            }
                        }
                    )
                }
            } else {
                Task {
                    await MainActor.run { self.streamingState = .toolCalling }
                    
                    let fallback = await AIEvaluationEngine.shared.fallbackEvaluation(payload: payload)
                    await MainActor.run {
                        withAnimation(.spring()) {
                            self.finalResult = fallback; self.aiScore = fallback.accuracyScore
                            self.streamingState = .complete; self.isAnalyzing = false
                            HapticManager.shared.impact(style: .heavy)
                        }
                    }
                }
            }
        }
    private var celebrationGap: Int {
        let actual = evalMode == .ultimateCalibration ? (aiScore ?? Int(predictedScore)) : Int(predictedScore)
        return Int(confidence) - actual
    }

    private var celebrationScore: Int {
        evalMode == .ultimateCalibration ? (aiScore ?? Int(predictedScore)) : Int(predictedScore)
    }

    private var celebrationZone: String {
        let gap = abs(celebrationGap)
        if gap <= 10 { return "Well Calibrated ✓" }
        if celebrationGap > 0 { return "Overconfident" }
        return "Underconfident"
    }

    func saveAttempt() {
        let textStrings = userAnswers.filter { $0.type == .text }.compactMap { $0.textContent }
        let attempt = Attempt(
            topicID: topic.id,
            confidenceLevel: Int(confidence),
            predictedScore: Int(predictedScore),
            aiScore: evalMode == .ultimateCalibration ? aiScore : nil,
            reflectionText: reflectionText,
            textAnswers: textStrings
        )
        modelContext.insert(attempt)
        withAnimation(.spring(response: 0.5)) {
            showCelebration = true
        }
    }
}


private struct StepCardModifier: ViewModifier {
    let accent: Color

    func body(content: Content) -> some View {
        content
            .padding(24)
            .background(
                ZStack {
                    Color(red: 0.08, green: 0.08, blue: 0.13)
                    RadialGradient(
                        colors: [accent.opacity(0.07), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 200
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(accent.opacity(0.15), lineWidth: 1)
            )
    }
}

extension View {
    fileprivate func stepCard(accent: Color) -> some View {
        modifier(StepCardModifier(accent: accent))
    }
}
struct AIEvaluationPayload: Sendable {
    let title: String
    let question: String
    let quickHint: String
    let difficulty: String
    let solutions: [SolutionMedia]
    let userAnswers: [SolutionMedia]
}
