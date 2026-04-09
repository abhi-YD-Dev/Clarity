
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var showDeleteAllAlert = false
    @State private var showResetOnboardingConfirm = false
    @State private var showLoadDemoConfirm = false
    @State private var showDoneToast = false
    @State private var toastMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // MARK: - About Clarity
                        aboutSection

                        // MARK: - Data Management
                        dataSection

                        // MARK: - The Story
                        storySection

                        // MARK: - App Info
                        appInfoSection

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                }

                // Toast overlay
                if showDoneToast {
                    VStack {
                        Spacer()
                        toastView
                            .padding(.bottom, 120)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
                }
            }
            .navigationTitle("Settings")
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
                    hasCompletedOnboarding = false
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

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "ABOUT CLARITY", icon: "brain.head.profile.fill", color: .cyan)

            Text("Clarity helps you bridge the gap between how well you **think** you know something and how well you **actually** know it.")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.75))
                .lineSpacing(4)

            HStack(spacing: 12) {
                infoPill(label: "Self-Assessment", icon: "person.fill.questionmark", color: .cyan)
                infoPill(label: "AI Grading", icon: "sparkles", color: .purple)
                infoPill(label: "Calibration", icon: "chart.line.uptrend.xyaxis", color: .green)
            }
        }
        .settingsCard()
    }

    // MARK: - Data Section

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "DATA MANAGEMENT", icon: "externaldrive.fill", color: .orange)

            actionButton(
                title: "Load Demo Data",
                subtitle: "Add sample concepts for exploring the app",
                icon: "arrow.down.doc.fill",
                color: .cyan
            ) {
                showLoadDemoConfirm = true
            }

            actionButton(
                title: "Reset Onboarding",
                subtitle: "Show the welcome flow again on next launch",
                icon: "arrow.counterclockwise",
                color: .yellow
            ) {
                showResetOnboardingConfirm = true
            }

            actionButton(
                title: "Delete All Data",
                subtitle: "Remove all concepts, topics, and attempts",
                icon: "trash.fill",
                color: .red
            ) {
                showDeleteAllAlert = true
            }
        }
        .settingsCard()
    }

    // MARK: - Story Section

    private var storySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "WHY I BUILT THIS", icon: "heart.fill", color: .pink)

            Text("Before one major exam, I felt completely prepared after rereading my notes. My confidence was high, but my score didn't reflect that. The problem wasn't effort — it was **miscalibrated confidence**.")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)

            Text("Clarity exists to fix this. By making you predict your score before seeing it, then comparing against AI analysis, you learn to **see your own blind spots**.")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
        }
        .settingsCard()
    }

    // MARK: - App Info

    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "APP INFO", icon: "info.circle.fill", color: .white.opacity(0.5))

            HStack {
                Text("Version")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("1.0.0")
                    .font(.subheadline.weight(.bold).monospaced())
                    .foregroundColor(.white.opacity(0.3))
            }

            HStack {
                Text("Built with")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "swift")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.orange)
                    Text("Swift Playgrounds")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

            HStack {
                Text("Frameworks")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("SwiftUI · SwiftData · FoundationModels")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .settingsCard()
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.footnote.weight(.bold))
                .foregroundColor(color)
            Text(title)
                .font(.caption2.weight(.black))
                .foregroundColor(color.opacity(0.8))
                .kerning(0.5)
        }
    }

    private func infoPill(label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.2), lineWidth: 1))
    }

    private func actionButton(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            HapticManager.shared.impact(style: .medium)
        }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(color.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var toastView: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.subheadline.weight(.bold))
                .foregroundColor(.green)
            Text(toastMessage)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.green.opacity(0.3), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }

    private func showToast(_ message: String) {
        toastMessage = message
        withAnimation(.spring(response: 0.4)) { showDoneToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.4)) { showDoneToast = false }
        }
    }

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

// MARK: - Settings Card Modifier

private struct SettingsCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    Color(red: 0.07, green: 0.07, blue: 0.12)
                    Color.white.opacity(0.03)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

extension View {
    fileprivate func settingsCard() -> some View {
        modifier(SettingsCardModifier())
    }
}
