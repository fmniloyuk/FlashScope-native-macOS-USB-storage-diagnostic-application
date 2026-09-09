import SwiftUI

// MARK: - FlashScope design system

enum FlashScopeTheme {
    static let accent = Color(red: 0.28, green: 0.86, blue: 0.89)
    static let accentBlue = Color(red: 0.34, green: 0.57, blue: 1.0)
    static let accentViolet = Color(red: 0.58, green: 0.43, blue: 0.98)
    static let positive = Color(red: 0.30, green: 0.88, blue: 0.68)
    static let warning = Color(red: 1.0, green: 0.70, blue: 0.30)
    static let critical = Color(red: 1.0, green: 0.39, blue: 0.43)
    static let neutral = Color(red: 0.58, green: 0.63, blue: 0.72)

    static let foregroundPrimary = Color(nsColor: .labelColor)
    static let foregroundSecondary = Color(nsColor: .secondaryLabelColor)
    static let foregroundTertiary = Color(nsColor: .tertiaryLabelColor)

    enum Radius {
        static let large: CGFloat = 22
        static let card: CGFloat = 19
        static let tile: CGFloat = 14
        static let control: CGFloat = 11
    }

    enum Spacing {
        static let xSmall: CGFloat = 6
        static let small: CGFloat = 10
        static let medium: CGFloat = 14
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 28
    }

    enum Motion {
        static let quick = 0.16
        static let standard = 0.24
    }

    static let pageTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let heroMetric = Font.system(size: 34, weight: .semibold, design: .rounded)
    static let sectionTitle = Font.system(size: 19, weight: .semibold, design: .default)
    static let cardTitle = Font.system(size: 15, weight: .semibold, design: .default)
    static let body = Font.system(size: 14, weight: .regular, design: .default)
    static let supporting = Font.system(size: 12.5, weight: .regular, design: .default)
    static let micro = Font.system(size: 11, weight: .medium, design: .default)
}

struct FlashScopeBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        Color(red: 0.035, green: 0.045, blue: 0.095),
                        Color(red: 0.055, green: 0.050, blue: 0.125),
                        Color(red: 0.026, green: 0.060, blue: 0.105)
                    ]
                    : [
                        Color(red: 0.94, green: 0.96, blue: 0.99),
                        Color(red: 0.95, green: 0.94, blue: 0.99),
                        Color(red: 0.92, green: 0.97, blue: 0.98)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [FlashScopeTheme.accentViolet.opacity(colorScheme == .dark ? 0.18 : 0.10), .clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 560
            )

            RadialGradient(
                colors: [FlashScopeTheme.accent.opacity(colorScheme == .dark ? 0.13 : 0.09), .clear],
                center: .bottomTrailing,
                startRadius: 30,
                endRadius: 620
            )

            RadialGradient(
                colors: [FlashScopeTheme.accentBlue.opacity(colorScheme == .dark ? 0.08 : 0.05), .clear],
                center: .center,
                startRadius: 60,
                endRadius: 760
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

private struct PremiumSurfaceModifier: ViewModifier {
    let emphasized: Bool
    @State private var hovering = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: FlashScopeTheme.Radius.card, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? (emphasized ? 0.095 : 0.065) : 0.28),
                                FlashScopeTheme.accentBlue.opacity(emphasized ? 0.045 : 0.018),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: FlashScopeTheme.Radius.card, style: .continuous))
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: FlashScopeTheme.Radius.card, style: .continuous)
                    .stroke(
                        hovering
                            ? FlashScopeTheme.accent.opacity(0.26)
                            : Color.white.opacity(colorScheme == .dark ? (emphasized ? 0.16 : 0.095) : 0.34),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.09), radius: hovering ? 18 : 13, y: hovering ? 8 : 5)
            .onHover { inside in
                if reduceMotion {
                    hovering = inside
                } else {
                    withAnimation(.easeOut(duration: FlashScopeTheme.Motion.quick)) {
                        hovering = inside
                    }
                }
            }
    }
}

extension View {
    func flashScopeSurface(emphasized: Bool = false) -> some View {
        modifier(PremiumSurfaceModifier(emphasized: emphasized))
    }

    func flashScopeInsetSurface(accent: Color? = nil) -> some View {
        padding(12)
            .background(
                (accent ?? FlashScopeTheme.accentBlue).opacity(0.055),
                in: RoundedRectangle(cornerRadius: FlashScopeTheme.Radius.tile, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: FlashScopeTheme.Radius.tile, style: .continuous)
                    .stroke(Color.white.opacity(0.075), lineWidth: 1)
            }
    }
}

struct FlashScopeSectionLabel: View {
    let title: String
    let subtitle: String?
    let systemImage: String

    init(_ title: String, subtitle: String? = nil, systemImage: String) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(FlashScopeTheme.accent)
                .frame(width: 28, height: 28)
                .background(FlashScopeTheme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(FlashScopeTheme.cardTitle)
                    .foregroundStyle(FlashScopeTheme.foregroundPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(FlashScopeTheme.supporting)
                        .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    var detail: String?
    var systemImage: String?
    var tint: Color = FlashScopeTheme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(tint)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(FlashScopeTheme.micro)
                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
            }
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(FlashScopeTheme.foregroundPrimary)
                .lineLimit(2)
            if let detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(FlashScopeTheme.foregroundTertiary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [tint.opacity(0.075), Color.white.opacity(0.025)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: FlashScopeTheme.Radius.tile, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: FlashScopeTheme.Radius.tile, style: .continuous)
                .stroke(Color.white.opacity(0.075), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(detail.map { "\(title), \(value), \($0)" } ?? "\(title), \(value)")
    }
}

struct FlashScopePrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .foregroundStyle(Color.white.opacity(isEnabled ? 0.98 : 0.55))
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background {
                LinearGradient(
                    colors: isEnabled
                        ? [FlashScopeTheme.accentBlue, FlashScopeTheme.accentViolet.opacity(0.95)]
                        : [Color.secondary.opacity(0.3), Color.secondary.opacity(0.25)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .clipShape(RoundedRectangle(cornerRadius: FlashScopeTheme.Radius.control, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: FlashScopeTheme.Radius.control, style: .continuous)
                    .stroke(Color.white.opacity(isEnabled ? 0.16 : 0.06), lineWidth: 1)
            }
            .shadow(color: isEnabled ? FlashScopeTheme.accentBlue.opacity(0.20) : .clear, radius: 10, y: 4)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Shared diagnostic surfaces

struct DiagnosticCard<Content: View>: View {
    let title: String
    let systemImage: String
    var subtitle: String?
    @ViewBuilder let content: Content

    init(_ title: String, systemImage: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FlashScopeTheme.Spacing.medium) {
            FlashScopeSectionLabel(title, subtitle: subtitle, systemImage: systemImage)
            content
        }
        .padding(FlashScopeTheme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .flashScopeSurface()
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    var detail: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .foregroundStyle(FlashScopeTheme.foregroundSecondary)
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                if let detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(FlashScopeTheme.foregroundTertiary)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .font(FlashScopeTheme.body)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }
}

struct InsetNotice: View {
    enum Kind { case info, warning, critical }
    let kind: Kind
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.11), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(message)
                    .font(FlashScopeTheme.supporting)
                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(color.opacity(0.075), in: RoundedRectangle(cornerRadius: FlashScopeTheme.Radius.tile, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: FlashScopeTheme.Radius.tile, style: .continuous)
                .stroke(color.opacity(0.16), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var icon: String {
        switch kind {
        case .info: "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .critical: "exclamationmark.octagon.fill"
        }
    }

    private var color: Color {
        switch kind {
        case .info: FlashScopeTheme.accentBlue
        case .warning: FlashScopeTheme.warning
        case .critical: FlashScopeTheme.critical
        }
    }
}
