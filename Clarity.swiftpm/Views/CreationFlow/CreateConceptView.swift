//
//  CreateConceptView 2.swift
//  Clarity
//
//  Created by Abhinav Yadav on 22/02/26.
//

import SwiftUI
import SwiftData
import PhotosUI


struct CreateConceptView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var title     = ""
    @State private var appeared  = false

    var body: some View {
        ZStack {
            
            Color(red: 0.04, green: 0.04, blue: 0.07).ignoresSafeArea()

            
            Ellipse()
                .fill(Color(red: 1.0, green: 0.65, blue: 0.1).opacity(0.12))
                .frame(width: 320, height: 220)
                .blur(radius: 60)
                .offset(x: -80, y: -120)
                .ignoresSafeArea()

           
            Ellipse()
                .fill(Color.cyan.opacity(0.07))
                .frame(width: 260, height: 180)
                .blur(radius: 50)
                .offset(x: 120, y: 280)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

              
                HStack(spacing: 6) {
                    Capsule()
                        .fill(Color(red: 1.0, green: 0.7, blue: 0.2))
                        .frame(width: 28, height: 4)
                    Text("1 / 1")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.top, 20)
                .padding(.horizontal, 32)
                .offset(y: appeared ? 0 : -10)
                .opacity(appeared ? 1 : 0)

                Spacer()

              
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.2))
                            Text("NEW CONCEPT")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.2))
                                .kerning(1.2)
                        }

                        Text("What are you\nstudying?")
                            .font(.system(size: 42, weight: .black))
                            .foregroundColor(.white)
                            .lineSpacing(2)
                    }
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)

                    
                    VStack(alignment: .leading, spacing: 0) {
                        TextField("", text: $title, prompt:
                            Text("e.g. Neuroscience…")
                                .foregroundColor(.white.opacity(0.18))
                        )
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                        .tint(Color(red: 1.0, green: 0.7, blue: 0.2))
                        .autocorrectionDisabled()

                     
                        Rectangle()
                            .fill(
                                title.isEmpty
                                    ? Color.white.opacity(0.12)
                                    : Color(red: 1.0, green: 0.7, blue: 0.2)
                            )
                            .frame(height: title.isEmpty ? 1 : 2)
                            .animation(.spring(response: 0.35), value: title.isEmpty)
                            .padding(.top, 12)
                    }
                    .offset(y: appeared ? 0 : 30)
                    .opacity(appeared ? 1 : 0)

              
                    if !title.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "return")
                                .font(.system(size: 11, weight: .bold))
                            Text("Tap Create to continue")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.3))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 32)
                .animation(.spring(response: 0.4), value: !title.isEmpty)

                Spacer()
                Spacer()

                Button {
                    guard !title.isEmpty else { return }
                    HapticManager.shared.impact(style: .rigid)
                    let newConcept = Concept(title: title, isCustom: true)
                    modelContext.insert(newConcept)
                    dismiss()
                } label: {
                    HStack {
                        Text("Create Concept")
                            .font(.system(.headline, weight: .bold))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(title.isEmpty ? .white.opacity(0.2) : Color(red: 0.06, green: 0.06, blue: 0.1))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                title.isEmpty
                                    ? Color.white.opacity(0.05)
                                    : Color(red: 1.0, green: 0.75, blue: 0.2)
                            )
                    )
                    .shadow(
                        color: title.isEmpty ? .clear : Color(red: 1.0, green: 0.6, blue: 0.1).opacity(0.55),
                        radius: 20, x: 0, y: 8
                    )
                    .animation(.spring(response: 0.4), value: title.isEmpty)
                }
                .disabled(title.isEmpty)
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
                .offset(y: appeared ? 0 : 20)
                .opacity(appeared ? 1 : 0)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }
}


struct CreateTopicView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    let concept: Concept

   
    @State private var title      = ""
    @State private var question   = ""
    @State private var quickHint  = ""
    @State private var difficulty: Difficulty = .medium
    @State private var solutions: [SolutionMedia] = []

    @State private var currentStep = 0
    @State private var slideDirection: Edge = .trailing
    @State private var stepAppeared = false

    @State private var showingTextAdd          = false
    @State private var pendingTextSolution     = ""
    @State private var showingImageActionSheet = false
    @State private var showingCamera           = false
    @State private var showingGallery          = false
    @State private var cameraImageData: Data?  = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @StateObject private var voiceRecorder = VoiceRecorder()

    private let totalSteps = 5

    private var stepConfig: (question: String, sub: String, icon: String, color: Color, tag: String) {
        switch currentStep {
        case 0: return ("What's the\ntopic called?",    "Give it a sharp, clear name.",                  "textformat.abc",       .cyan,                              "TITLE")
        case 1: return ("What will you\nask yourself?", "Write the question you'll answer from memory.",  "questionmark.bubble",  Color(red: 0.5, green: 0.3, blue: 1.0), "QUESTION")
        case 2: return ("Any quick\nhints?",            "A nudge — not the answer.",                     "lightbulb",            Color(red: 0.9, green: 0.65, blue: 0.1), "HINT")
        case 3: return ("How hard\nis it?",             "Difficulty shapes your calibration scoring.",   "dial.medium",          Color(red: 0.2, green: 0.8, blue: 0.5), "DIFFICULTY")
        case 4: return ("Add model\nsolutions.",        "What's the correct answer? Use text, image or voice.", "checkmark.seal", .purple,                            "SOLUTIONS")
        default: return ("", "", "", .white, "")
        }
    }

    private var canAdvance: Bool {
        switch currentStep {
        case 0: return !title.isEmpty
        case 1: return !question.isEmpty
        case 2: return !quickHint.isEmpty
        case 3: return true
        case 4: return !solutions.isEmpty
        default: return false
        }
    }

    var body: some View {
        ZStack {
            
            Color(red: 0.04, green: 0.04, blue: 0.07).ignoresSafeArea()

            
            Ellipse()
                .fill(stepConfig.color.opacity(0.1))
                .frame(width: 340, height: 240)
                .blur(radius: 70)
                .offset(x: -60, y: -140)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: currentStep)

            VStack(spacing: 0) {

                
                topBar

                ZStack {
                    stepContent
                        .id(currentStep)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: slideDirection).combined(with: .opacity),
                                removal: .move(edge: slideDirection == .trailing ? .leading : .trailing).combined(with: .opacity)
                            )
                        )
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: currentStep)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                
                bottomNav
            }
        }
        .navigationBarHidden(true)
        .alert("Add Text Solution", isPresented: $showingTextAdd) {
            TextField("Enter the correct answer...", text: $pendingTextSolution)
            Button("Cancel", role: .cancel) { pendingTextSolution = "" }
            Button("Add") {
                if !pendingTextSolution.isEmpty {
                    withAnimation(.spring()) {
                        solutions.append(SolutionMedia(type: .text, textContent: pendingTextSolution))
                    }
                    pendingTextSolution = ""
                }
            }
        }
        .alert("Add Image Solution", isPresented: $showingImageActionSheet) {
            Button("Take Photo")          { showingCamera  = true }
            Button("Choose from Gallery") { showingGallery = true }
            Button("Cancel", role: .cancel) { }
        } message: { Text("Where would you like to get the image from?") }
        .photosPicker(isPresented: $showingGallery, selection: $selectedPhotoItem, matching: .images)
        .sheet(isPresented: $showingCamera) {
            CameraPicker(selectedImageData: $cameraImageData).ignoresSafeArea()
        }

        .onChange(of: cameraImageData) { _, newData in
            if let data = newData { solutions.append(SolutionMedia(type: .image, imageData: data)); cameraImageData = nil }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    solutions.append(SolutionMedia(type: .image, imageData: data))
                }
                selectedPhotoItem = nil
            }
        }
    }

  

    private var topBar: some View {
            VStack(spacing: 12) {
                
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                HStack {
                    Spacer()
                    Text("\(currentStep + 1) of \(totalSteps)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                    Spacer()
                }

             
                HStack(spacing: 5) {
                    ForEach(0..<totalSteps, id: \.self) { i in
                        Capsule()
                            .fill(i <= currentStep ? stepConfig.color : Color.white.opacity(0.1))
                            .frame(height: 3)
                            .animation(.spring(response: 0.4), value: currentStep)
                    }
                }
                .padding(.horizontal, 24)
            }
        }

  

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0: textInputStep(binding: $title,    multiline: false)
        case 1: textInputStep(binding: $question, multiline: true)
        case 2: textInputStep(binding: $quickHint, multiline: false)
        case 3: difficultyStep
        case 4: solutionsStep
        default: EmptyView()
        }
    }

    

    private func textInputStep(binding: Binding<String>, multiline: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 28) {

               
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Image(systemName: stepConfig.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(stepConfig.color)
                        Text(stepConfig.tag)
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(stepConfig.color)
                            .kerning(1.2)
                    }

                    Text(stepConfig.question)
                        .font(.system(size: 38, weight: .black))
                        .foregroundColor(.white)
                        .lineSpacing(1)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(stepConfig.sub)
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundColor(.white.opacity(0.35))
                }

              
                VStack(alignment: .leading, spacing: 0) {
                    if multiline {
                        TextEditor(text: binding)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .tint(stepConfig.color)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 90, maxHeight: 140)
                            .autocorrectionDisabled()
                    } else {
                        TextField("", text: binding, prompt:
                            Text("Type here…")
                                .foregroundColor(.white.opacity(0.15))
                        )
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)
                        .tint(stepConfig.color)
                        .autocorrectionDisabled()
                    }

                    
                    Rectangle()
                        .fill(
                            binding.wrappedValue.isEmpty
                                ? Color.white.opacity(0.1)
                                : stepConfig.color
                        )
                        .frame(height: binding.wrappedValue.isEmpty ? 1 : 2)
                        .animation(.spring(response: 0.3), value: binding.wrappedValue.isEmpty)
                        .padding(.top, 10)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }


    private var difficultyStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 36) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Image(systemName: stepConfig.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(stepConfig.color)
                        Text(stepConfig.tag)
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(stepConfig.color)
                            .kerning(1.2)
                    }

                    Text(stepConfig.question)
                        .font(.system(size: 38, weight: .black))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(stepConfig.sub)
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundColor(.white.opacity(0.35))
                }

                VStack(spacing: 14) {
                    ForEach(Difficulty.allCases, id: \.self) { diff in
                        Button {
                            withAnimation(.spring(response: 0.35)) { difficulty = diff }
                            HapticManager.shared.impact(style: .light)
                        } label: {
                            HStack(spacing: 18) {
                                ZStack {
                                    Circle()
                                        .fill(diff.color.opacity(difficulty == diff ? 0.25 : 0.08))
                                        .frame(width: 46, height: 46)
                                    Circle()
                                        .fill(diff.color)
                                        .frame(width: difficulty == diff ? 14 : 8)
                                        .animation(.spring(response: 0.3), value: difficulty == diff)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(diff.rawValue.capitalized)
                                        .font(.system(.headline, weight: .bold))
                                        .foregroundColor(difficulty == diff ? .white : .white.opacity(0.55))

                                    Text(difficultySubtitle(diff))
                                        .font(.system(.caption, weight: .medium))
                                        .foregroundColor(.white.opacity(0.3))
                                }

                                Spacer()

                                if difficulty == diff {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(diff.color)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(
                                        difficulty == diff
                                            ? diff.color.opacity(0.1)
                                            : Color.white.opacity(0.04)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(
                                        difficulty == diff ? diff.color.opacity(0.4) : Color.white.opacity(0.07),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.35), value: difficulty)
                    }
                }
            }
            .padding(.horizontal, 28)

            Spacer()
            Spacer()
        }
    }

    private func difficultySubtitle(_ diff: Difficulty) -> String {
        switch diff {
        case .easy:   return "Foundational recall — builds confidence"
        case .medium: return "Solid understanding required"
        case .hard:   return "Deep mastery — tests real comprehension"
        }
    }


    private var solutionsStep: some View {
        VStack(alignment: .leading, spacing: 0) {

            VStack(alignment: .leading, spacing: 20) {

                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Image(systemName: stepConfig.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(stepConfig.color)
                        Text(stepConfig.tag)
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(stepConfig.color)
                            .kerning(1.2)
                    }

                    Text(stepConfig.question)
                        .font(.system(size: 34, weight: .black))
                        .foregroundColor(.white)

                    Text(stepConfig.sub)
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundColor(.white.opacity(0.35))
                }
                .padding(.top, 20)

                if !solutions.isEmpty {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(solutions) { solution in
                                solutionChip(solution)
                            }
                        }
                    }
                    .frame(maxHeight: 180)
                } else {
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "tray")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.12))
                            Text("No solutions yet")
                                .font(.system(.caption, weight: .medium))
                                .foregroundColor(.white.opacity(0.2))
                        }
                        Spacer()
                    }
                    .padding(.vertical, 30)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {

                    mediaGridButton(icon: "text.cursor",    label: "Text",  color: .cyan)   { showingTextAdd = true }
                    mediaGridButton(icon: "camera.viewfinder", label: "Image", color: .purple) {
                        showingImageActionSheet = true
                        HapticManager.shared.selection()
                    }

                    Button {
                        if voiceRecorder.isRecording {
                            if let data = voiceRecorder.stopRecording() {
                                withAnimation(.spring()) {
                                    solutions.append(SolutionMedia(type: .voice, audioData: data))
                                }
                            }
                            HapticManager.shared.impact(style: .rigid)
                        } else {
                            voiceRecorder.startRecording()
                            HapticManager.shared.impact(style: .medium)
                        }
                    } label: {
                        VStack(spacing: 7) {
                            Image(systemName: voiceRecorder.isRecording ? "stop.circle.fill" : "mic.fill")
                                .font(.system(size: 22, weight: .semibold))
                            Text(voiceRecorder.isRecording ? "Stop" : "Voice")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(voiceRecorder.isRecording ? .white : .orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(voiceRecorder.isRecording ? Color.red : Color.orange.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(voiceRecorder.isRecording ? Color.red.opacity(0.6) : Color.orange.opacity(0.2), lineWidth: 1)
                        )
                        .scaleEffect(voiceRecorder.isRecording ? 1.04 : 1.0)
                        .animation(voiceRecorder.isRecording ? .easeInOut(duration: 0.7).repeatForever() : .default, value: voiceRecorder.isRecording)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 28)

            Spacer()
        }
    }


    private func solutionChip(_ solution: SolutionMedia) -> some View {
        HStack(spacing: 12) {
            Image(systemName: solution.type == .text ? "text.alignleft"
                           : solution.type == .image ? "photo"
                           : "waveform")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(solution.type == .text ? .cyan : .purple)
                .frame(width: 32, height: 32)
                .background((solution.type == .text ? Color.cyan : Color.purple).opacity(0.12))
                .clipShape(Circle())

            Group {
                if solution.type == .text {
                    Text(solution.textContent ?? "")
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                } else if solution.type == .image, let data = solution.imageData, let img = UIImage(data: data) {
                    HStack(spacing: 8) {
                        Image(uiImage: img)
                            .resizable().scaledToFill()
                            .frame(width: 36, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("Image answer")
                            .font(.system(.subheadline, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else if solution.type == .voice, let data = solution.audioData {
                    AudioPlaybackRow(audioData: data)
                }
            }

            Spacer()

            Button {
                withAnimation(.spring()) { solutions.removeAll { $0.id == solution.id } }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
                    .frame(width: 24, height: 24)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .transition(.move(edge: .leading).combined(with: .opacity))
    }

    private func mediaGridButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                Text(label)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(color.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var bottomNav: some View {
            HStack {
                // Back Button
                Button {
                    if currentStep > 0 {
                        goBack()
                    } else {
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                        Text("Back")
                            .font(.system(.headline, weight: .bold))
                    }
                    .foregroundColor(currentStep > 0 ? Color(red: 0.05, green: 0.05, blue: 0.08) : .white.opacity(0.2))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(currentStep > 0 ? Color.white.opacity(0.8) : Color.white.opacity(0.06))
                    )
                }
                .disabled(currentStep == 0) 
                .buttonStyle(.plain)

                Spacer()

               
                Button {
                    if currentStep < totalSteps - 1 {
                        goNext()
                    } else {
                        saveTopic()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(currentStep == totalSteps - 1 ? "Save Topic" : "Next")
                            .font(.system(.headline, weight: .bold))
                        Image(systemName: currentStep == totalSteps - 1 ? "checkmark" : "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(canAdvance ? Color(red: 0.05, green: 0.05, blue: 0.08) : .white.opacity(0.2))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(canAdvance ? stepConfig.color : Color.white.opacity(0.06))
                    )
                    .shadow(
                        color: canAdvance ? stepConfig.color.opacity(0.45) : .clear,
                        radius: 14, x: 0, y: 5
                    )
                    .animation(.spring(response: 0.35), value: canAdvance)
                }
                .disabled(!canAdvance)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 44)
            .padding(.top, 16)
        }

    private func goNext() {
        guard canAdvance else { return }
        HapticManager.shared.impact(style: .light)
        slideDirection = .trailing
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            currentStep += 1
        }
    }

    private func goBack() {
        slideDirection = .leading
        HapticManager.shared.impact(style: .light)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            currentStep -= 1
        }
    }

    private func saveTopic() {
        guard canAdvance else { return }
        HapticManager.shared.impact(style: .rigid)
        let newTopic = Topic(
            title: title,
            question: question,
            quickHint: quickHint,
            difficulty: difficulty,
            solution: solutions
        )
        concept.topics.append(newTopic)
        dismiss()
    }
}
