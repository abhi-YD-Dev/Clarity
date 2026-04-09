
import SwiftUI

// MARK: - Appearance Mode

/// User-selectable appearance override.
enum AppearanceMode: Int, CaseIterable {
    case system = 0
    case light  = 1
    case dark   = 2

    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

// MARK: - Adaptive Color Tokens

/// Centralized design system following Apple HIG.
/// All colors adapt automatically for light and dark mode via UIColor dynamic provider.
enum ClarityTheme {

    // MARK: Backgrounds (System Semantic)
    static let screenBackground   = Color(.systemGroupedBackground)
    static let cardBackground     = Color(.secondarySystemGroupedBackground)
    static let elevatedBackground = Color(.tertiarySystemGroupedBackground)

    // MARK: Text (System Semantic)
    static let primaryText   = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText  = Color(.tertiaryLabel)

    // MARK: Separators
    static let separator = Color(.separator)

    // MARK: Brand Accent Palette — Refined & Adaptive
    // Curated colors inspired by Apple Health, Fitness, Weather.
    // Light mode: muted, sophisticated. Dark mode: vibrant, luminous.

    /// Primary brand color — teal-blue (inspired by Apple Health)
    static let accentCyan = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.38, green: 0.82, blue: 0.92, alpha: 1)   // luminous teal
                : UIColor(red: 0.06, green: 0.52, blue: 0.65, alpha: 1)   // deep teal
        }
    )

    /// Secondary accent — indigo-violet
    static let accentPurple = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.58, green: 0.45, blue: 0.98, alpha: 1)   // soft violet
                : UIColor(red: 0.38, green: 0.22, blue: 0.78, alpha: 1)   // deep indigo
        }
    )

    /// Success / well-calibrated — Apple Fitness ring green
    static let accentGreen = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.42, green: 0.88, blue: 0.56, alpha: 1)   // fresh mint
                : UIColor(red: 0.20, green: 0.62, blue: 0.36, alpha: 1)   // nature green
        }
    )

    /// Warning / overconfident — warm amber
    static let accentOrange = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 1.00, green: 0.68, blue: 0.32, alpha: 1)   // warm amber
                : UIColor(red: 0.85, green: 0.48, blue: 0.10, alpha: 1)   // deep amber
        }
    )

    /// Bookmarks / highlights
    static let accentYellow = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 1.00, green: 0.86, blue: 0.36, alpha: 1)   // golden
                : UIColor(red: 0.78, green: 0.62, blue: 0.04, alpha: 1)   // deep gold
        }
    )

    /// Danger / destructive
    static let accentRed = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.96, green: 0.42, blue: 0.42, alpha: 1)   // coral red
                : UIColor(red: 0.80, green: 0.20, blue: 0.20, alpha: 1)   // deep red
        }
    )

    // MARK: Gradient Presets (used sparingly — CTA buttons and hero cards only)

    static let cyanGradient = LinearGradient(
        colors: [accentCyan, accentCyan.opacity(0.72)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let purpleGradient = LinearGradient(
        colors: [accentPurple, accentPurple.opacity(0.72)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let greenGradient = LinearGradient(
        colors: [accentGreen, accentGreen.opacity(0.72)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // MARK: Subtle accent tint for card backgrounds
    /// A very light wash of the accent used behind cards — adaptive
    static func accentTint(_ color: Color, opacity: Double = 0.08) -> Color {
        color.opacity(opacity)
    }
}

// MARK: - Typography Helpers (SF Pro via .system())

/// Pre-configured text styles following Apple HIG hierarchy.
/// SF Pro is the system default — no custom font loading needed.
enum ClarityFont {
    static let largeTitle = Font.system(.largeTitle, design: .default, weight: .bold)
    static let title      = Font.system(size: 28, weight: .bold, design: .default)
    static let title2     = Font.system(.title2, design: .default, weight: .bold)
    static let title3     = Font.system(.title3, design: .default, weight: .semibold)
    static let headline   = Font.system(.headline, design: .default, weight: .semibold)
    static let body       = Font.system(.body, design: .default, weight: .regular)
    static let callout    = Font.system(.callout, design: .default, weight: .medium)
    static let subheadline = Font.system(.subheadline, design: .default, weight: .regular)
    static let footnote   = Font.system(.footnote, design: .default, weight: .medium)
    static let caption    = Font.system(.caption, design: .default, weight: .medium)
    static let caption2   = Font.system(.caption2, design: .default, weight: .medium)

    // Monospaced numeric display (for scores, percentages)
    static func scoreDisplay(size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }
}

// MARK: - Card Modifiers

/// Standard card — uses adaptive system grouped background with subtle shadow.
struct ClarityCard: ViewModifier {
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(ClarityTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

/// Glass card — uses `.ultraThinMaterial` for frosted-glass effect.
/// Use sparingly: navigation overlays, floating controls, celebration modals.
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

/// Step card for TestWizardView — adaptive background with subtle accent glow.
/// NO hardcoded dark colors — works in both light and dark mode.
struct StepCard: ViewModifier {
    var accent: Color = ClarityTheme.accentCyan

    func body(content: Content) -> some View {
        content
            .padding(24)
            .background(
                ZStack {
                    ClarityTheme.cardBackground
                    RadialGradient(
                        colors: [accent.opacity(0.06), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 220
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(accent.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: accent.opacity(0.05), radius: 12, x: 0, y: 4)
    }
}

/// Floating bottom bar with glass background — for CTA buttons.
struct FloatingBarBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 0)
            )
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.primary.opacity(0.06))
                    .frame(height: 0.5)
            }
    }
}

extension View {
    func clarityCard(cornerRadius: CGFloat = 16) -> some View {
        self.modifier(ClarityCard(cornerRadius: cornerRadius))
    }

    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        self.modifier(GlassCard(cornerRadius: cornerRadius))
    }

    func stepCard(accent: Color = ClarityTheme.accentCyan) -> some View {
        self.modifier(StepCard(accent: accent))
    }

    func liquidCard() -> some View {
        self.modifier(ClarityCard(cornerRadius: 24))
    }

    func floatingBar() -> some View {
        self.modifier(FloatingBarBackground())
    }
}

// MARK: - Settings Row Icon Helper

/// Renders a small colored-circle icon like Apple's native Settings rows.
struct SettingsIcon: View {
    let icon: String
    let color: Color
    var size: CGFloat = 29

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.48, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(color)
            )
    }
}

// MARK: - Haptic Manager

@MainActor
class HapticManager {
    static let shared = HapticManager()

    private init() {}

    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard UserDefaults.standard.object(forKey: "hapticsEnabled") == nil
           || UserDefaults.standard.bool(forKey: "hapticsEnabled") else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    func selection() {
        guard UserDefaults.standard.object(forKey: "hapticsEnabled") == nil
           || UserDefaults.standard.bool(forKey: "hapticsEnabled") else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard UserDefaults.standard.object(forKey: "hapticsEnabled") == nil
           || UserDefaults.standard.bool(forKey: "hapticsEnabled") else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}
