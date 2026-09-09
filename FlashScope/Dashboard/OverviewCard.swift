import FlashScopeCore
import SwiftUI

struct OverviewCard: View {
    let drive: PhysicalDrive
    let volume: Volume
    let diagnosis: DiagnosisReport?
    let connection: USBConnection
    let benchmark: BenchmarkResult?
    let filesystemCheck: FilesystemCheckResult
    let healthSignals: [HealthSignal]
    let history: [TestSession]
    let runCheckAction: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            hero
            dimensionGrid
            evidenceAndAction
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .flashScopeSurface(emphasized: true)
        .accessibilityIdentifier("overview-card")
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: 28) {
            HealthGauge(
                score: visualScore,
                classification: diagnosis?.assessment.classification ?? .inconclusive,
                label: scoreUsesConfidence ? "Confidence" : "Health"
            )
            .frame(width: 170, height: 170)

            VStack(alignment: .leading, spacing: 11) {
                HStack(spacing: 9) {
                    Text("DRIVE HEALTH")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(FlashScopeTheme.foregroundTertiary)
                    if let assessment = diagnosis?.assessment {
                        HealthStatusBadge(classification: assessment.classification)
                    }
                }

                Text(drive.displayName)
                    .font(FlashScopeTheme.pageTitle)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(primaryVerdict)
                    .font(FlashScopeTheme.sectionTitle)
                    .foregroundStyle(statusColor)

                Text(primarySummary)
                    .font(FlashScopeTheme.body)
                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 620, alignment: .leading)

                HStack(spacing: 7) {
                    contextPill(connection.negotiatedSpeed.value?.label ?? "Link not exposed", icon: "cable.connector")
                    contextPill(volume.filesystem.value?.rawValue ?? "Filesystem unknown", icon: "internaldrive")
                    contextPill(StorageFormatting.bytes(volume.capacityBytes), icon: "externaldrive")
                }
                .padding(.top, 2)

                if let comparison = localComparison {
                    Label(historyChangeText(comparison), systemImage: comparison.writeChangePercent >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(abs(comparison.writeChangePercent) >= 25 ? FlashScopeTheme.warning : FlashScopeTheme.foregroundSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 10) {
                Text("NEXT STEP")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(FlashScopeTheme.foregroundTertiary)
                Text(primaryAction)
                    .font(.callout.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    runCheckAction()
                } label: {
                    Label(benchmark == nil ? "Run Health Check" : "Run Again", systemImage: "stethoscope")
                }
                .buttonStyle(FlashScopePrimaryButtonStyle())
                .accessibilityIdentifier("overview-run-check-button")

                Text("Safe, bounded temporary data only")
                    .font(.caption2)
                    .foregroundStyle(FlashScopeTheme.foregroundTertiary)
            }
            .padding(15)
            .frame(width: 235, alignment: .leading)
            .background(FlashScopeTheme.accentBlue.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 16).stroke(FlashScopeTheme.accent.opacity(0.12), lineWidth: 1) }
        }
    }

    private var dimensionGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 12)], spacing: 12) {
            dimensionTile(
                title: "Media reliability",
                icon: "memorychip",
                component: diagnosis?.assessment.media,
                fallback: benchmark?.integrity.status == .passed ? "No integrity failure detected" : "Needs integrity evidence",
                tint: FlashScopeTheme.positive
            )
            dimensionTile(
                title: "Connection",
                icon: "cable.connector",
                component: diagnosis?.assessment.connection,
                fallback: connection.negotiatedSpeed.value == nil ? "Link evidence unavailable" : "Connection measured",
                tint: FlashScopeTheme.accent
            )
            dimensionTile(
                title: "Filesystem",
                icon: "internaldrive",
                component: diagnosis?.assessment.filesystem,
                fallback: filesystemCheck.status == .passed ? "Verification passed" : "Verification not complete",
                tint: FlashScopeTheme.accentBlue
            )
            dimensionTile(
                title: "Performance",
                icon: "speedometer",
                component: diagnosis?.assessment.performance,
                fallback: benchmark == nil ? "Not benchmarked yet" : "Measured",
                tint: FlashScopeTheme.accentViolet
            )
        }
    }

    private func dimensionTile(title: String, icon: String, component: AssessmentComponent?, fallback: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                Text(title)
                    .font(FlashScopeTheme.micro)
                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                Spacer(minLength: 4)
                if let score = component?.score {
                    Text("\(score)")
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(tint)
                }
            }
            Text(component?.summary ?? fallback)
                .font(.callout.weight(.medium))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            if let score = component?.score {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.055))
                        Capsule()
                            .fill(LinearGradient(colors: [tint, tint.opacity(0.55)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: proxy.size.width * CGFloat(max(0, min(100, score))) / 100)
                    }
                }
                .frame(height: 4)
                .accessibilityLabel("\(title) evidence-based score")
                .accessibilityValue("\(score) out of 100")
            } else {
                Text("More evidence needed")
                    .font(.caption2)
                    .foregroundStyle(FlashScopeTheme.foregroundTertiary)
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
        .background(
            LinearGradient(colors: [tint.opacity(0.075), Color.white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: FlashScopeTheme.Radius.tile, style: .continuous)
        )
        .overlay { RoundedRectangle(cornerRadius: FlashScopeTheme.Radius.tile).stroke(Color.white.opacity(0.07), lineWidth: 1) }
    }

    private var evidenceAndAction: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Evidence coverage", systemImage: "checklist.checked")
                        .font(.callout.weight(.semibold))
                    Spacer()
                    Text("\(coverage.availableSignals)/\(coverage.totalSignals) · \(coverage.percentage)%")
                        .font(.callout.monospacedDigit().weight(.semibold))
                        .foregroundStyle(FlashScopeTheme.accent)
                }
                ProgressView(value: coverage.fraction)
                    .tint(FlashScopeTheme.accent)
                Text(coverage.missing.isEmpty ? "All tracked evidence categories are available." : "Missing: \(coverage.missing.joined(separator: ", ")). Missing evidence lowers confidence but is not itself a drive failure.")
                    .font(FlashScopeTheme.supporting)
                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let assessment = diagnosis?.assessment {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Diagnostic confidence")
                        .font(FlashScopeTheme.micro)
                        .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                    Text("\(Int(assessment.confidence * 100))%")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    Text("Evidence certainty, not a prediction of future reliability")
                        .font(.caption2)
                        .foregroundStyle(FlashScopeTheme.foregroundTertiary)
                }
                .frame(width: 235, alignment: .leading)
            }
        }
        .flashScopeInsetSurface(accent: FlashScopeTheme.accent)
    }

    private func contextPill(_ value: String, icon: String) -> some View {
        Label(value, systemImage: icon)
            .font(.caption.weight(.medium))
            .foregroundStyle(FlashScopeTheme.foregroundSecondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.045), in: Capsule())
            .overlay { Capsule().stroke(Color.white.opacity(0.07), lineWidth: 1) }
    }

    private var coverage: EvidenceCoverageSummary {
        DiagnosticInsightAnalyzer.evidenceCoverage(
            drive: drive,
            volume: volume,
            connection: connection,
            benchmark: benchmark,
            filesystemCheck: filesystemCheck,
            healthSignals: healthSignals
        )
    }

    private var primaryFinding: DiagnosticFinding? {
        diagnosis?.findings
            .filter { $0.severity > .info }
            .sorted {
                if $0.severity != $1.severity { return $0.severity > $1.severity }
                return $0.confidence > $1.confidence
            }
            .first
    }

    private var primaryVerdict: String {
        if let finding = primaryFinding { return finding.title }
        if benchmark == nil { return "Ready for a diagnostic check" }
        return diagnosis?.assessment.classification.rawValue ?? "Collecting evidence"
    }

    private var primarySummary: String {
        if let finding = primaryFinding { return finding.explanation }
        return diagnosis?.assessment.summary ?? "FlashScope is collecting safe evidence from this removable drive."
    }

    private var primaryAction: String {
        primaryFinding?.recommendedAction ?? (benchmark == nil ? "Run a Standard diagnostic check to establish a baseline." : "No high-priority corrective action is indicated. Keep monitoring and retest if behavior changes.")
    }

    private var localComparison: LocalPerformanceComparison? {
        guard let benchmark else { return nil }
        let prior = history.compactMap(\.benchmark).filter { $0 != benchmark }
        return DiagnosticInsightAnalyzer.localComparison(current: benchmark, history: prior)
    }

    private var scoreUsesConfidence: Bool {
        availableComponentScores.isEmpty
    }

    private var visualScore: Int {
        let scores = availableComponentScores
        if !scores.isEmpty {
            return Int((Double(scores.reduce(0, +)) / Double(scores.count)).rounded())
        }
        return Int((diagnosis?.assessment.confidence ?? 0) * 100)
    }

    private var availableComponentScores: [Int] {
        guard let assessment = diagnosis?.assessment else { return [] }
        return [assessment.media.score, assessment.connection.score, assessment.filesystem.score, assessment.performance.score].compactMap { $0 }
    }

    private var statusColor: Color {
        switch diagnosis?.assessment.classification ?? .inconclusive {
        case .healthy: FlashScopeTheme.positive
        case .limitedByConnection: FlashScopeTheme.accent
        case .attentionRecommended: FlashScopeTheme.warning
        case .critical: FlashScopeTheme.critical
        case .inconclusive: FlashScopeTheme.neutral
        }
    }

    private func historyChangeText(_ comparison: LocalPerformanceComparison) -> String {
        let sign = comparison.writeChangePercent >= 0 ? "+" : ""
        return String(format: "Write performance %@%.0f%% vs local history", sign, comparison.writeChangePercent)
    }
}

private struct HealthGauge: View {
    let score: Int
    let classification: HealthClassification
    let label: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.055), style: StrokeStyle(lineWidth: 13, lineCap: .round))

            Circle()
                .trim(from: 0, to: appeared || reduceMotion ? CGFloat(max(0, min(100, score))) / 100 : 0)
                .stroke(
                    AngularGradient(colors: [color.opacity(0.55), color, color.opacity(0.78)], center: .center),
                    style: StrokeStyle(lineWidth: 13, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.24), radius: 8)

            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 38, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
            }
        }
        .padding(13)
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.easeOut(duration: 0.55)) { appeared = true }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) score, \(score) out of 100, status \(classification.rawValue)")
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
