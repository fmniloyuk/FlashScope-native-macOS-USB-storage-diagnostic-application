import Charts
import FlashScopeCore
import SwiftUI

struct HistoryCard: View {
    let sessions: [TestSession]
    let unit: ThroughputUnit
    let delete: (TestSession) -> Void
    let deleteAll: () -> Void

    var body: some View {
        DiagnosticCard("Device Timeline", systemImage: "clock.arrow.circlepath", subtitle: "Local history makes deterioration, recovery, and fix/retest outcomes visible over time") {
            if sessions.isEmpty {
                emptyHistory
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    if let comparison = latestComparison {
                        comparisonPanel(comparison)
                    }

                    let benchmarked = sessions.filter { $0.benchmark != nil }.sorted { $0.timestamp < $1.timestamp }
                    if !benchmarked.isEmpty {
                        trendChart(benchmarked)
                    }

                    HStack {
                        Text("Recent checks")
                            .font(.callout.weight(.semibold))
                        Spacer()
                        Text("\(sessions.count) local record\(sessions.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundStyle(FlashScopeTheme.foregroundTertiary)
                    }

                    VStack(spacing: 0) {
                        ForEach(sessions.prefix(8)) { session in
                            timelineRow(session)
                            if session.id != sessions.prefix(8).last?.id {
                                Divider().opacity(0.18).padding(.leading, 42)
                            }
                        }
                    }
                    .background(Color.white.opacity(0.018), in: RoundedRectangle(cornerRadius: 14))

                    HStack {
                        Label("Stored only on this Mac", systemImage: "lock.shield")
                            .font(.caption2)
                            .foregroundStyle(FlashScopeTheme.foregroundTertiary)
                        Spacer()
                        Button("Delete All History", role: .destructive, action: deleteAll)
                            .controlSize(.small)
                    }
                }
            }
        }
        .accessibilityIdentifier("history-card")
    }

    private var emptyHistory: some View {
        HStack(spacing: 15) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 28))
                .foregroundStyle(FlashScopeTheme.accentBlue)
                .frame(width: 58, height: 58)
                .background(FlashScopeTheme.accentBlue.opacity(0.07), in: RoundedRectangle(cornerRadius: 15))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("No history for this drive")
                    .font(.headline)
                Text("Completed checks will build a private timeline so FlashScope can compare future performance against this exact device.")
                    .font(FlashScopeTheme.supporting)
                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
            }
            Spacer()
        }
        .padding(14)
        .flashScopeInsetSurface(accent: FlashScopeTheme.accentBlue)
    }

    private func trendChart(_ benchmarked: [TestSession]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Performance trend")
                    .font(.callout.weight(.semibold))
                Spacer()
                legend("Write", FlashScopeTheme.accentViolet)
                legend("Read", FlashScopeTheme.accent)
            }

            Chart {
                ForEach(benchmarked) { session in
                    if let benchmark = session.benchmark {
                        LineMark(
                            x: .value("Date", session.timestamp),
                            y: .value("Write", converted(benchmark.writeMegabytesPerSecond))
                        )
                        .foregroundStyle(FlashScopeTheme.accentViolet)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", session.timestamp),
                            y: .value("Write", converted(benchmark.writeMegabytesPerSecond))
                        )
                        .foregroundStyle(FlashScopeTheme.accentViolet)

                        LineMark(
                            x: .value("Date", session.timestamp),
                            y: .value("Read", converted(benchmark.readMegabytesPerSecond))
                        )
                        .foregroundStyle(FlashScopeTheme.accent)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", session.timestamp),
                            y: .value("Read", converted(benchmark.readMegabytesPerSecond))
                        )
                        .foregroundStyle(FlashScopeTheme.accent)
                    }
                }
            }
            .frame(height: 170)
            .chartLegend(.hidden)
            .chartYAxisLabel(unit.rawValue)
            .chartPlotStyle { $0.background(Color.white.opacity(0.012)) }
            .accessibilityLabel("Read and write benchmark timeline")
        }
        .padding(13)
        .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.055), lineWidth: 1) }
    }

    private func timelineRow(_ session: TestSession) -> some View {
        HStack(alignment: .top, spacing: 11) {
            ZStack {
                Circle().fill(color(for: session.diagnosis.assessment.classification).opacity(0.10))
                Image(systemName: icon(for: session.diagnosis.assessment.classification))
                    .foregroundStyle(color(for: session.diagnosis.assessment.classification))
            }
            .frame(width: 30, height: 30)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(session.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.callout.weight(.medium))
                    HealthStatusBadge(classification: session.diagnosis.assessment.classification)
                }
                if let benchmark = session.benchmark {
                    Text(String(format: "Write %.1f %@   Read %.1f %@   Integrity %@", converted(benchmark.writeMegabytesPerSecond), unit.rawValue, converted(benchmark.readMegabytesPerSecond), unit.rawValue, benchmark.integrity.status.rawValue))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                    let stability = DiagnosticInsightAnalyzer.stability(for: benchmark)
                    Text("\(benchmark.configuration.preset.rawValue.capitalized) · stability \(stability.score)/100")
                        .font(.caption2)
                        .foregroundStyle(FlashScopeTheme.foregroundTertiary)
                } else {
                    Text(session.diagnosis.assessment.summary)
                        .font(.caption)
                        .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            Button(role: .destructive) { delete(session) } label: { Image(systemName: "trash") }
                .buttonStyle(.borderless)
                .help("Delete this local history record")
                .accessibilityLabel("Delete history from \(session.timestamp.formatted())")
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
    }

    private func comparisonPanel(_ comparison: SessionDelta) -> some View {
        let improved = comparison.writePercent >= 20
        let regressed = comparison.writePercent <= -20
        let tint = improved ? FlashScopeTheme.positive : (regressed ? FlashScopeTheme.warning : FlashScopeTheme.accentBlue)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Fix / retest comparison", systemImage: "arrow.triangle.swap")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(tint)
                Spacer()
                Text(changeLabel(comparison.writePercent))
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .foregroundStyle(tint)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                MetricTile(title: "Previous write", value: String(format: "%.1f %@", converted(comparison.previous.writeMegabytesPerSecond), unit.rawValue), systemImage: "clock", tint: FlashScopeTheme.neutral)
                MetricTile(title: "Latest write", value: String(format: "%.1f %@", converted(comparison.latest.writeMegabytesPerSecond), unit.rawValue), systemImage: "arrow.right.circle", tint: tint)
                MetricTile(title: "Read change", value: changeLabel(comparison.readPercent), systemImage: "arrow.up.arrow.down", tint: FlashScopeTheme.accent)
            }
            Text(comparisonExplanation(comparison))
                .font(FlashScopeTheme.supporting)
                .foregroundStyle(FlashScopeTheme.foregroundSecondary)
        }
        .flashScopeInsetSurface(accent: tint)
    }

    private func legend(_ text: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text).font(.caption2).foregroundStyle(FlashScopeTheme.foregroundSecondary)
        }
    }

    private var latestComparison: SessionDelta? {
        let ordered = sessions.compactMap { session -> (Date, BenchmarkResult)? in
            session.benchmark.map { (session.timestamp, $0) }
        }.sorted { $0.0 > $1.0 }
        guard ordered.count >= 2 else { return nil }
        let latest = ordered[0].1
        let previous = ordered[1].1
        let writePercent = previous.writeMegabytesPerSecond > 0 ? (latest.writeMegabytesPerSecond / previous.writeMegabytesPerSecond - 1) * 100 : 0
        let readPercent = previous.readMegabytesPerSecond > 0 ? (latest.readMegabytesPerSecond / previous.readMegabytesPerSecond - 1) * 100 : 0
        return .init(previous: previous, latest: latest, writePercent: writePercent, readPercent: readPercent)
    }

    private func changeLabel(_ percent: Double) -> String {
        String(format: "%@%.0f%%", percent >= 0 ? "+" : "", percent)
    }

    private func comparisonExplanation(_ comparison: SessionDelta) -> String {
        if comparison.writePercent >= 25 {
            return "The latest write result improved materially. If you intentionally changed one variable—such as removing a hub, changing ports, or freeing space—this supports that change as a likely contributor."
        }
        if comparison.writePercent <= -25 {
            return "The latest write result is materially lower. Repeat under similar conditions before concluding the drive deteriorated; port, temperature, free space, and host activity can affect results."
        }
        return "The two most recent write results are in a similar range. Repeated tests under controlled conditions provide stronger evidence than a single measurement."
    }

    private func icon(for classification: HealthClassification) -> String {
        switch classification {
        case .healthy: "checkmark.circle.fill"
        case .limitedByConnection: "cable.connector"
        case .attentionRecommended: "exclamationmark.triangle.fill"
        case .critical: "xmark.octagon.fill"
        case .inconclusive: "questionmark.circle.fill"
        }
    }

    private func color(for classification: HealthClassification) -> Color {
        switch classification {
        case .healthy: FlashScopeTheme.positive
        case .limitedByConnection: FlashScopeTheme.accent
        case .attentionRecommended: FlashScopeTheme.warning
        case .critical: FlashScopeTheme.critical
        case .inconclusive: FlashScopeTheme.neutral
        }
    }

    private func converted(_ value: Double) -> Double { StorageFormatting.throughput(value, unit: unit) }

    private struct SessionDelta {
        let previous: BenchmarkResult
        let latest: BenchmarkResult
        let writePercent: Double
        let readPercent: Double
    }
}
