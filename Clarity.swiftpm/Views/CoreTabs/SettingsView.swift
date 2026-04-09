
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false

    @State private var showDeleteAllAlert = false
    @State private var showResetOnboardingConfirm = false
    @State private var showLoadDemoConfirm = false
    @State private var showDoneToast = false
    @State private var toastMessage = ""
    @State private var showStory = false

    // Computed
    private var currentAppearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceMode) ?? .system
    }

    var body: some View {
        NavigationStack {
            List {

                // MARK: — App Header
                Section {
                    appHeaderRow
                }

                // MARK: — Appearance
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label {
                            Text("Appearance")
                        } icon: {
                            SettingsIcon(icon: "paintbrush.fill", color: .purple)
                        }

                        // Visual segmented control — like Display & Brightness
                        HStack(spacing: 0) {
                            ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        appearanceMode = mode.rawValue
                                    }
                                    HapticManager.shared.selection()
                                } label: {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(appearanceModePreviewBackground(mode))
                                                .frame(width: 62, height: 44)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        .stroke(
                                                            currentAppearance == mode
                                                                ? ClarityTheme.accentCyan
                                                                : Color.primary.opacity(0.12),
                                                            lineWidth: currentAppearance == mode ? 2.5 : 1
                                                        )
                                                )

                                            Image(systemName: mode.icon)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(
                                                    currentAppearance == mode
                                                        ? ClarityTheme.accentCyan
                                                        : .secondary
                                                )
                                        }

                                        Text(mode.label)
                                            .font(.caption2.weight(currentAppearance == mode ? .bold : .medium))
                                            .foregroundColor(
                                                currentAppearance == mode ? .primary : .secondary
                                            )
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Display")
                }

                // MARK: — Preferences
                Section {
                    Toggle(isOn: $hapticsEnabled) {
                        Label {
                            Text("Haptic Feedback")
                        } icon: {
                            SettingsIcon(icon: "hand.tap.fill", color: .orange)
                        }
                    }
                    .tint(ClarityTheme.accentCyan)

                    Toggle(isOn: $notificationsEnabled) {
                        Label {
                            Text("Study Reminders")
                        } icon: {
                            SettingsIcon(icon: "bell.badge.fill", color: ClarityTheme.accentGreen)
                        }
                    }
                    .tint(ClarityTheme.accentCyan)
                } header: {
                    Text("Preferences")
                } footer: {
                    if notificationsEnabled {
                        Text("Coming soon — daily study reminders to keep your calibration streak alive.")
                    }
                }

                // MARK: — Data Management
                Section {
                    Button {
                        showLoadDemoConfirm = true
                        HapticManager.shared.impact(style: .medium)
                    } label: {
                        Label {
                            Text("Load Demo Data")
                                .foregroundStyle(.primary)
                        } icon: {
                            SettingsIcon(icon: "arrow.down.doc.fill", color: ClarityTheme.accentCyan)
                        }
                    }

                    Button {
                        showResetOnboardingConfirm = true
                        HapticManager.shared.impact(style: .medium)
                    } label: {
                        Label {
                            Text("Reset Onboarding")
                                .foregroundStyle(.primary)
                        } icon: {
                            SettingsIcon(icon: "arrow.counterclockwise", color: .gray)
                        }
                    }
                } header: {
                    Text("Data")
                }

                // MARK: — Danger Zone
                Section {
                    Button(role: .destructive) {
                        showDeleteAllAlert = true
                        HapticManager.shared.impact(style: .medium)
                    } label: {
                        Label {
                            Text("Delete All Data")
                        } icon: {
                            SettingsIcon(icon: "trash.fill", color: .red)
                        }
                    }
                } footer: {
                    Text("This permanently removes all concepts, topics, and attempt history.")
                }

                // MARK: — About
                Section {
                    LabeledContent {
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    } label: {
                        Label {
                            Text("Version")
                        } icon: {
                            SettingsIcon(icon: "info.circle.fill", color: .blue)
                        }
                    }

                    LabeledContent {
                        Text("SwiftUI · SwiftData")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } label: {
                        Label {
                            Text("Frameworks")
                        } icon: {
                            SettingsIcon(icon: "hammer.fill", color: .indigo)
                        }
                    }
                    
                    // Privacy & Support (placeholders for App Store)
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        Label {
                            HStack {
                                Text("Privacy Policy")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        } icon: {
                            SettingsIcon(icon: "hand.raised.fill", color: .blue)
                        }
                    }

                    // Why I Built This
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showStory.toggle()
                        }
                    } label: {
                        HStack {
                            Label {
                                Text("Why I Built This")
                            } icon: {
                                SettingsIcon(icon: "heart.fill", color: .pink)
                            }
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                                .rotationEffect(.degrees(showStory ? 180 : 0))
                        }
                    }
                    .tint(.primary)

                    if showStory {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Before one major exam, I felt completely prepared after rereading my notes. My confidence was high, but my score didn't reflect that. The problem wasn't effort — it was **miscalibrated confidence**.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineSpacing(4)

                            Text("Clarity exists to fix this. By making you predict your score before seeing it, then comparing against AI analysis, you learn to **see your own blind spots**.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineSpacing(4)
                        }
                        .padding(.vertical, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                } header: {
                    Text("About")
                } footer: {
                    VStack(spacing: 8) {
                        Text("Made with ❤️ by Abhinav")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("© 2026 Clarity")
                            .font(.caption2)
                            .foregroundStyle(.quaternary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .overlay {
                // Toast overlay
                if showDoneToast {
                    VStack {
                        Spacer()
                        toastView
                            .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
                }
            }
            .alert("Delete All Data?", isPresented: $showDeleteAllAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This will permanently delete all concepts, topics, and attempts. This cannot be undone.")
            }
            .alert("Reset Onboarding?", isPresented: $showResetOnboardingConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    hasSeenOnboarding = false
                    showToast("Onboarding will show on next launch")
                }
            } message: {
                Text("Next time you open the app, the onboarding flow will appear.")
            }
            .alert("Load Demo Data?", isPresented: $showLoadDemoConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Load", role: .none) {
                    MockData.insertSampleData(modelContext: modelContext)
                    showToast("Demo data loaded ✓")
                }
            } message: {
                Text("This will add sample concepts and topics for you to explore.")
            }
        }
    }

    // MARK: - Appearance Mode Preview

    private func appearanceModePreviewBackground(_ mode: AppearanceMode) -> some ShapeStyle {
        switch mode {
        case .system:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray5)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
        case .light:
            return AnyShapeStyle(Color.white)
        case .dark:
            return AnyShapeStyle(Color(white: 0.12))
        }
    }

    // MARK: - App Header

    private var appHeaderRow: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ClarityTheme.cyanGradient)
                    .frame(width: 60, height: 60)
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Clarity")
                    .font(.title2.weight(.bold))
                Text("Metacognition & Active Recall")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    // MARK: - Toast

    private var toastView: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(ClarityTheme.accentGreen)
            Text(toastMessage)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
    }

    private func showToast(_ message: String) {
        toastMessage = message
        withAnimation(.spring(response: 0.4)) { showDoneToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.4)) { showDoneToast = false }
        }
    }

    // MARK: - Actions

    private func deleteAllData() {
        do {
            try modelContext.delete(model: Attempt.self)
            try modelContext.delete(model: Topic.self)
            try modelContext.delete(model: Concept.self)
            UserDefaults.standard.set(false, forKey: "hasInsertedSampleData")
            HapticManager.shared.impact(style: .rigid)
            showToast("All data deleted")
        } catch {
            print("Failed to delete data: \(error)")
        }
    }
}
