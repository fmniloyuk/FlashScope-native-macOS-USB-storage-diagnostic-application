import FlashScopeCore
import SwiftUI

struct HealthStatusBadge: View {
    let classification: HealthClassification

    var body: some View {
        Label(classification.rawValue, systemImage: icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: [color.opacity(0.18), color.opacity(0.07)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Capsule()
            )
            .overlay { Capsule().stroke(color.opacity(0.25), lineWidth: 1) }
            .foregroundStyle(color)
            .accessibilityLabel("Health status: \(classification.rawValue)")
    }

    private var icon: String {
        switch classification {
        case .healthy: "checkmark.seal.fill"
        case .limitedByConnection: "cable.connector.horizontal"
        case .attentionRecommended: "exclamationmark.triangle.fill"
        case .critical: "exclamationmark.octagon.fill"
        case .inconclusive: "questionmark.diamond.fill"
        }
    }

    private var color: Color {
        switch classification {
        case .healthy: FlashScopeTheme.positive
        case .limitedByConnection: FlashScopeTheme.accent
        case .attentionRecommended: FlashScopeTheme.warning
        case .critical: FlashScopeTheme.critical
        case .inconclusive: FlashScopeTheme.neutral
        }
    }
}

struct SeverityLabel: View {
    let severity: FindingSeverity

    var body: some View {
        Label(name, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(color.opacity(0.10), in: Capsule())
            .overlay { Capsule().stroke(color.opacity(0.18), lineWidth: 1) }
            .foregroundStyle(color)
            .accessibilityLabel("Severity: \(name)")
    }

    private var name: String {
        switch severity {
        case .info: "Info"
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        case .critical: "Critical"
        }
    }

    private var icon: String {
        switch severity {
        case .info: "info.circle"
        case .low: "circle"
        case .medium: "exclamationmark.triangle"
        case .high: "exclamationmark.triangle.fill"
        case .critical: "exclamationmark.octagon.fill"
        }
    }

    private var color: Color {
        switch severity {
        case .info: FlashScopeTheme.accentBlue
        case .low: FlashScopeTheme.accent
        case .medium: FlashScopeTheme.warning
        case .high, .critical: FlashScopeTheme.critical
        }
    }
}
