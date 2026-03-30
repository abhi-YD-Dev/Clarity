

import SwiftUI
import SwiftData
import PhotosUI

struct QuickCreateFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    @Query(sort: \Concept.title) private var allConcepts: [Concept]

    enum Phase { case concept, topic }

    @State private var phase: Phase = .concept

   
    @State private var newConceptTitle  = ""
    @State private var selectedConcept: Concept? = nil
    @State private var createNew        = true

    
    @State private var topicTitle      = ""
    @State private var question        = ""
    @State private var quickHint       = ""
    @State private var difficulty: Difficulty = .medium
    @State private var solutions: [SolutionMedia] = []

    @State private var showingTextAdd          = false
    @State private var pendingText             = ""
    @State private var showingImageSheet       = false
    @State private var showingCamera           = false
    @State private var showingGallery          = false
    @State private var cameraImageData: Data?  = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @StateObject private var voiceRecorder     = VoiceRecorder()

    @State private var slideForward = true

    private var conceptPhaseReady: Bool {
        createNew ? !newConceptTitle.isEmpty : selectedConcept != nil
    }

    private var topicPhaseReady: Bool {
        !topicTitle.isEmpty && !question.isEmpty && !quickHint.isEmpty && !solutions.isEmpty
    }

    private var resolvedConcept: Concept? {
        if createNew {
            return nil
        } else {
            return selectedConcept
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.04, blue: 0.07).ignoresSafeArea()

                RadialGradient(
                    colors: [phase == .concept
                             ? Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.1)
                             : Color.purple.opacity(0.08),
                             .clear],
                    center: .top, startRadius: 0, endRadius: 300
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: phase)

                VStack(spacing: 0) {
                   
                    phaseBar
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 24)

                  
                    ScrollView(showsIndicators: false) {
                        ZStack {
                            Group {
                                if phase == .concept {
                                    conceptPhaseView
                                } else {
                                    topicPhaseView
                                }
                            }
                            .id(phase)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: slideForward ? .trailing : .leading).combined(with: .opacity),
                                    removal:   .move(edge: slideForward ? .leading  : .trailing).combined(with: .opacity)
                                )
                            )
                        }
                        .animation(.spring(response: 0.42, dampingFraction: 0.85), value: phase)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 140)
                    }

                    Spacer(minLength: 0)
                }

               
                VStack {
                    Spacer()
                    bottomButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, 36)
                        .background(
                            LinearGradient(
                                colors: [.clear, Color(red: 0.04, green: 0.04, blue: 0.07)],
                                startPoint: .top, endPoint: .bottom
                            )
                            .frame(height: 120)
                            .ignoresSafeArea()
                        )
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if phase == .topic {
                            slideForward = false
                            withAnimation { phase = .concept }
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: phase == .concept ? "xmark" : "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.07))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .alert("Add Text Solution", isPresented: $showingTextAdd) {
            TextField("Enter the correct answer...", text: $pendingText)
            Button("Cancel", role: .cancel) { pendingText = "" }
            Button("Add") {
                if !pendingText.isEmpty {
                    solutions.append(SolutionMedia(type: .text, textContent: pendingText))
                    pendingText = ""
                }
            }
        }
        .alert("Add Image Solution", isPresented: $showingImageSheet) {
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

    private var phaseBar: some View {
        HStack(spacing: 0) {
            phaseStep(
                number: "1",
                label: "Concept",
                active: phase == .concept,
                done: phase == .topic,
                color: Color(red: 1.0, green: 0.75, blue: 0.2)
            )

            Rectangle()
                .fill(phase == .topic ? Color.purple.opacity(0.4) : Color.white.opacity(0.08))
                .frame(height: 1.5)
                .frame(maxWidth: .infinity)
                .animation(.easeInOut(duration: 0.4), value: phase)

            phaseStep(
                number: "2",
                label: "Topic",
                active: phase == .topic,
                done: false,
                color: .purple
            )
        }
    }

    private func phaseStep(number: String, label: String, active: Bool, done: Bool, color: Color) -> some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(done ? color : (active ? color : Color.white.opacity(0.07)))
                    .frame(width: 32, height: 32)
                if done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                } else {
                    Text(number)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(active ? .black : .white.opacity(0.3))
                }
            }
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(active ? color : .white.opacity(0.3))
        }
        .animation(.spring(response: 0.35), value: active)
    }

    private var conceptPhaseView: some View {
        VStack(alignment: .leading, spacing: 28) {

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.2))
                    Text("STEP 1 — CONCEPT")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.2))
                        .kerning(1.0)
                }
                Text("Choose or create\na concept folder.")
                    .font(.system(size: 34, weight: .black))
                    .foregroundColor(.white)
                    .lineSpacing(2)
            }

     
            if !allConcepts.isEmpty {
                HStack(spacing: 8) {
                    toggleChip("Create New", selected: createNew, color: Color(red: 1.0, green: 0.75, blue: 0.2)) {
                        withAnimation(.spring(response: 0.3)) { createNew = true }
                    }
                    toggleChip("Pick Existing", selected: !createNew, color: Color(red: 1.0, green: 0.75, blue: 0.2)) {
                        withAnimation(.spring(response: 0.3)) { createNew = false }
                    }
                }
            }

      
            if createNew {
                
                VStack(alignment: .leading, spacing: 0) {
                    TextField("", text: $newConceptTitle, prompt:
                        Text("e.g. Neuroscience, SwiftData…")
                            .foregroundColor(.white.opacity(0.18))
                    )
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .tint(Color(red: 1.0, green: 0.75, blue: 0.2))
                    .autocorrectionDisabled()

                    Rectangle()
                        .fill(newConceptTitle.isEmpty
                              ? Color.white.opacity(0.1)
                              : Color(red: 1.0, green: 0.75, blue: 0.2))
                        .frame(height: newConceptTitle.isEmpty ? 1 : 2)
                        .animation(.spring(response: 0.3), value: newConceptTitle.isEmpty)
                        .padding(.top, 10)
                }

                if !newConceptTitle.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.2))
                        Text("Great name! Now add a topic in step 2.")
                            .font(.system(.caption, weight: .medium))
                            .foregroundColor(.white.opacity(0.45))
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

            } else {
           
                VStack(spacing: 10) {
                    ForEach(allConcepts) { concept in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedConcept = concept
                            }
                            HapticManager.shared.selection()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill((concept.isCustom ? Color.purple : Color.cyan).opacity(0.15))
                                        .frame(width: 38, height: 38)
                                    Image(systemName: concept.isCustom ? "person.badge.plus" : "book.pages.fill")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(concept.isCustom ? .purple : .cyan)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(concept.title)
                                        .font(.system(.subheadline, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("\(concept.topics.count) topic\(concept.topics.count == 1 ? "" : "s")")
                                        .font(.system(.caption, weight: .medium))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                Spacer()
                                if selectedConcept?.id == concept.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.2))
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(selectedConcept?.id == concept.id
                                          ? Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.08)
                                          : Color.white.opacity(0.04))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(selectedConcept?.id == concept.id
                                            ? Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.4)
                                            : Color.white.opacity(0.07),
                                            lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.3), value: selectedConcept?.id)
                    }
                }
            }
        }
    }



    private var topicPhaseView: some View {
        VStack(alignment: .leading, spacing: 24) {

            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.bubble.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.purple)
                    Text("STEP 2 — TOPIC")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.purple)
                        .kerning(1.0)
                }
                Text("Add a topic to\nyour concept.")
                    .font(.system(size: 34, weight: .black))
                    .foregroundColor(.white)
                    .lineSpacing(2)

               
                let name = createNew ? newConceptTitle : (selectedConcept?.title ?? "")
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 11))
                    Text(name)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.2))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.1))
                .clipShape(Capsule())
            }

            
            VStack(spacing: 18) {
                topicField(label: "Topic Title", placeholder: "e.g. Action Potentials",
                           icon: "textformat", color: .purple, text: $topicTitle)

                
                VStack(alignment: .leading, spacing: 8) {
                    Label("The Question", systemImage: "questionmark.circle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.5, green: 0.3, blue: 1.0).opacity(0.9))
                    TextEditor(text: $question)
                        .font(.system(.body, weight: .medium))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .tint(.purple)
                        .frame(height: 90)
                        .padding(12)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.purple.opacity(0.2), lineWidth: 1))
                }

                topicField(label: "Quick Hint", placeholder: "A nudge, not the answer…",
                           icon: "lightbulb", color: Color(red: 0.9, green: 0.65, blue: 0.1), text: $quickHint)

               
                VStack(alignment: .leading, spacing: 10) {
                    Label("Difficulty", systemImage: "dial.medium")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))

                    HStack(spacing: 10) {
                        ForEach(Difficulty.allCases, id: \.self) { diff in
                            Button {
                                withAnimation(.spring(response: 0.3)) { difficulty = diff }
                                HapticManager.shared.selection()
                            } label: {
                                HStack(spacing: 6) {
                                    Circle().fill(diff.color).frame(width: 7, height: 7)
                                    Text(diff.rawValue.capitalized)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(difficulty == diff ? .black : .white.opacity(0.5))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(difficulty == diff ? diff.color : diff.color.opacity(0.08))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            
            VStack(alignment: .leading, spacing: 14) {
                Label("Model Solution", systemImage: "checkmark.seal")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.purple.opacity(0.8))

                if !solutions.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(solutions) { sol in
                            solutionChip(sol)
                        }
                    }
                }

                HStack(spacing: 10) {
                    mediaBtn(icon: "text.cursor",     label: "Text",  color: .cyan)   { showingTextAdd = true }
                    mediaBtn(icon: "camera.viewfinder", label: "Image", color: .purple) { showingImageSheet = true }
                    voiceButton
                }
            }
        }
    }

    private func topicField(label: String, placeholder: String, icon: String, color: Color, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color.opacity(0.9))
            TextField("", text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.18)))
                .font(.system(.body, weight: .medium))
                .foregroundColor(.white)
                .tint(color)
                .padding(12)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(color.opacity(0.2), lineWidth: 1))
        }
    }

    private func solutionChip(_ sol: SolutionMedia) -> some View {
        HStack(spacing: 10) {
            Image(systemName: sol.type == .text ? "text.alignleft" : sol.type == .image ? "photo" : "waveform")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.purple)
                .frame(width: 28, height: 28)
                .background(Color.purple.opacity(0.1))
                .clipShape(Circle())

            Group {
                if sol.type == .text {
                    Text(sol.textContent ?? "").font(.system(.caption, weight: .medium)).foregroundColor(.white).lineLimit(1)
                } else if sol.type == .image, let d = sol.imageData, let img = UIImage(data: d) {
                    Image(uiImage: img).resizable().scaledToFill().frame(width: 36, height: 28).clipShape(RoundedRectangle(cornerRadius: 5))
                } else if sol.type == .voice, let d = sol.audioData {
                    AudioPlaybackRow(audioData: d)
                }
            }
            Spacer()
            Button {
                withAnimation(.spring()) { solutions.removeAll { $0.id == sol.id } }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
                    .frame(width: 22, height: 22)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func mediaBtn(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 18, weight: .semibold))
                Text(label).font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(color.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var voiceButton: some View {
        Button {
            if voiceRecorder.isRecording {
                if let data = voiceRecorder.stopRecording() {
                    withAnimation(.spring()) { solutions.append(SolutionMedia(type: .voice, audioData: data)) }
                }
                HapticManager.shared.impact(style: .rigid)
            } else {
                voiceRecorder.startRecording()
                HapticManager.shared.impact(style: .medium)
            }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: voiceRecorder.isRecording ? "stop.circle.fill" : "mic.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text(voiceRecorder.isRecording ? "Stop" : "Voice")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(voiceRecorder.isRecording ? .white : .orange)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(voiceRecorder.isRecording ? Color.red : Color.orange.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(voiceRecorder.isRecording ? Color.red.opacity(0.5) : Color.orange.opacity(0.18), lineWidth: 1))
            .scaleEffect(voiceRecorder.isRecording ? 1.04 : 1.0)
            .animation(voiceRecorder.isRecording ? .easeInOut(duration: 0.8).repeatForever() : .default, value: voiceRecorder.isRecording)
        }
        .buttonStyle(.plain)
    }

        private func toggleChip(_ label: String, selected: Bool, color: Color, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                Text(label)
                    .font(.system(size: 13, weight: .bold))
                    
                    .foregroundColor(selected ? .black : .white.opacity(0.6))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                       
                        Capsule().fill(selected ? color : Color.white.opacity(0.02))
                    )
                   
                    .overlay(
                        Capsule().stroke(selected ? color : Color.white.opacity(0.15), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }


    private var bottomButton: some View {
        Button {
            handleAction()
        } label: {
            HStack(spacing: 10) {
                Text(phase == .concept ? "Next: Add Topic" : "Save Everything")
                    .font(.system(.headline, weight: .bold))
                Image(systemName: phase == .concept ? "arrow.right" : "checkmark")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(buttonEnabled ? (phase == .concept ? Color(red: 0.05, green: 0.05, blue: 0.08) : .white) : .white.opacity(0.2))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Group {
                    if !buttonEnabled {
                        AnyView(Color.white.opacity(0.06))
                    } else if phase == .concept {
                        AnyView(Color(red: 1.0, green: 0.75, blue: 0.2))
                    } else {
                        AnyView(LinearGradient(
                            colors: [Color(red: 0.7, green: 0.3, blue: 1.0), Color(red: 0.45, green: 0.1, blue: 0.8)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(
                color: buttonEnabled
                    ? (phase == .concept ? Color(red: 1.0, green: 0.6, blue: 0.1).opacity(0.5) : Color.purple.opacity(0.5))
                    : .clear,
                radius: 16, x: 0, y: 6
            )
            .animation(.spring(response: 0.35), value: buttonEnabled)
        }
        .disabled(!buttonEnabled)
        .buttonStyle(.plain)
    }

    private var buttonEnabled: Bool {
        phase == .concept ? conceptPhaseReady : topicPhaseReady
    }


    private func handleAction() {
        if phase == .concept {
            HapticManager.shared.impact(style: .light)
            slideForward = true
            withAnimation { phase = .topic }
        } else {
            save()
        }
    }

    private func save() {
        HapticManager.shared.impact(style: .rigid)

        let concept: Concept
        if createNew {
            concept = Concept(title: newConceptTitle, isCustom: true)
            modelContext.insert(concept)
        } else if let existing = selectedConcept {
            concept = existing
        } else {
            return
        }

        let topic = Topic(
            title: topicTitle,
            question: question,
            quickHint: quickHint,
            difficulty: difficulty,
            solution: solutions
        )
        concept.topics.append(topic)
        dismiss()
    }
}


