import FlashScopeCore
import SwiftUI

struct FindingsCard: View {
    let diagnosis: DiagnosisReport?
    let retestAction: () -> Void

    var body: some View {
        DiagnosticCard("Key Findings", systemImage: "sparkles.rectangle.stack", subtitle: "Plain-English causes first; technical evidence stays one click away") {
            if let diagnosis {
                VStack(alignment: .leading, spacing: 12) {
                    if diagnosis.findings.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(FlashScopeTheme.positive)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("No specific problem identified")
                                    .font(.headline)
                                Text("The currently available evidence does not point to a concrete fault. Keep a backup and retest if behavior changes.")
                                    .font(FlashScopeTheme.supporting)
                                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                            }
                        }
                        .padding(14)
                        .background(FlashScopeTheme.positive.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                    }

                    ForEach(Array(diagnosis.findings.enumerated()), id: \.element.id) { index, finding in
                        findingCard(finding, rank: index + 1)
                    }

                    if !diagnosis.limitations.isEmpty {
                        DisclosureGroup("Evidence limitations · \(diagnosis.limitations.count)") {
                            VStack(alignment: .leading, spacing: 7) {
                                ForEach(diagnosis.limitations, id: \.self) { limitation in
                                    Label(limitation, systemImage: "questionmark.circle")
                                        .font(.caption)
                                        .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                                }
                                Text("Missing evidence lowers confidence. It is not automatically a failed health signal.")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                            }
                            .padding(.top, 8)
                        }
                        .font(.callout.weight(.medium))
                    }
                }
            } else {
                Text("Select and inspect a drive to generate findings.")
                    .font(FlashScopeTheme.body)
                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
            }
        }
        .accessibilityIdentifier("findings-card")
    }

    private func findingCard(_ finding: DiagnosticFinding, rank: Int) -> some View {
        let tint = color(for: finding.severity)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tint.opacity(0.10))
                    Image(systemName: icon(for: finding.severity))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tint)
                }
                .frame(width: 38, height: 38)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Finding \(rank)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(FlashScopeTheme.foregroundTertiary)
                        SeverityLabel(severity: finding.severity)
                    }
                    Text(finding.title)
                        .font(.headline)
                    Text(finding.explanation)
                        .font(FlashScopeTheme.body)
                        .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(finding.confidence * 100))%")
                        .font(.title3.monospacedDigit().weight(.semibold))
                    Text("confidence")
                        .font(.caption2)
                        .foregroundStyle(FlashScopeTheme.foregroundTertiary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Finding confidence \(Int(finding.confidence * 100)) percent")
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 12)], spacing: 12) {
                explanationBlock(title: "Impact", icon: "bolt.trianglebadge.exclamationmark", text: finding.expectedImpact, tint: tint)
                explanationBlock(title: "Recommended action", icon: "wrench.and.screwdriver", text: finding.recommendedAction, tint: FlashScopeTheme.accent)
            }

            if let experiment = diagnosticExperiment(for: finding) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Fix → retest experiment", systemImage: "testtube.2")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FlashScopeTheme.accent)
                    Text(experiment)
                        .font(.caption)
                        .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                    Button {
                        retestAction()
                    } label: {
                        Label("Retest After the Change", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .flashScopeInsetSurface(accent: FlashScopeTheme.accent)
            }

            DisclosureGroup("Technical evidence") {
                VStack(alignment: .leading, spacing: 7) {
                    if let caveat = finding.caveat {
                        Text("Caveat: \(caveat)")
                            .font(.caption)
                            .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                    }
                    ForEach(finding.evidence) { evidence in
                        MetricRow(label: evidence.label, value: evidence.value)
                    }
                }
                .padding(.top, 8)
            }
            .font(.caption.weight(.medium))
        }
        .padding(15)
        .background(
            LinearGradient(colors: [tint.opacity(0.07), Color.white.opacity(0.018)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay { RoundedRectangle(cornerRadius: 16).stroke(tint.opacity(finding.severity >= .high ? 0.26 : 0.10), lineWidth: 1) }
        .accessibilityElement(children: .contain)
    }

    private func explanationBlock(title: String, icon: String, text: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
            Text(text)
                .font(.caption)
                .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(11)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .topLeading)
        .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 12))
    }

    private func diagnosticExperiment(for finding: DiagnosticFinding) -> String? {
        switch finding.category {
        case .connectionBottleneck, .hubAdapter:
            return "Change one thing only: remove intermediate hubs/adapters or move to another known high-speed port. Then rerun the same profile. If link speed and throughput rise together, the original connection path was the probable cause."
        case .slowSequentialWrite, .unstableThroughput:
            return "Let the drive idle/cool, keep the same port, ensure at least 15% free space where practical, and rerun the same profile. Repeated results under similar conditions are stronger evidence than one run."
        case .nearlyFull:
            return "Move or delete unneeded files yourself, empty Trash if appropriate, refresh FlashScope, then rerun the same profile and compare sustained write speed."
        case .insufficientPower:
            return "Connect directly to the Mac or a properly powered hub, then rerun the same profile. Improved stability or fewer disconnects supports a power-path explanation."
        case .smallFileOverhead:
            return "Repeat with the small-file workload enabled. If sequential performance remains healthy while files/s stays low, metadata and file-count overhead are the likely cause."
        case .filesystemVerification:
            return "After backing up important data and addressing the filesystem with an appropriate macOS tool, rerun read-only verification before another write benchmark."
        default:
            return nil
        }
    }

    private func icon(for severity: FindingSeverity) -> String {
        switch severity {
        case .critical: "exclamationmark.octagon.fill"
        case .high: "exclamationmark.triangle.fill"
        case .medium: "exclamationmark.circle.fill"
        case .low: "info.circle.fill"
        case .info: "lightbulb.fill"
        }
    }

    private func color(for severity: FindingSeverity) -> Color {
        switch severity {
        case .critical, .high: FlashScopeTheme.critical
        case .medium: FlashScopeTheme.warning
        case .low: FlashScopeTheme.accent
        case .info: FlashScopeTheme.accentBlue
        }
    }
}
