import Charts
import FlashScopeCore
import SwiftUI

struct PerformanceCard: View {
    let benchmark: BenchmarkResult?
    let progress: BenchmarkProgress?
    let isBenchmarking: Bool
    let expectedRange: ClosedRange<Double>?
    let unit: ThroughputUnit
    let workload: StorageWorkload
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        DiagnosticCard("Performance", systemImage: "speedometer", subtitle: "Measured speed translated into stability, expected range, workload fit, and sustained behavior") {
            VStack(alignment: .leading, spacing: 16) {
                if isBenchmarking, let progress {
                    liveProgress(progress)
                }

                if let benchmark {
                    headlineMetrics(benchmark)
                    measuredVsExpected(benchmark)
                    throughputChart(benchmark)
                    derivedInsights(benchmark)
                    DisclosureGroup("Benchmark details") {
                        VStack(alignment: .leading, spacing: 14) {
                            detailedStatistics(benchmark)
                            limitations(benchmark)
                        }
                        .padding(.top, 10)
                    }
                    .font(.callout.weight(.medium))
                } else if !isBenchmarking {
                    noBenchmarkState
                }
            }
        }
        .accessibilityIdentifier("performance-card")
    }

    private var noBenchmarkState: some View {
        HStack(spacing: 16) {
            Image(systemName: "waveform.path.ecg.rectangle")
                .font(.system(size: 31, weight: .medium))
                .foregroundStyle(FlashScopeTheme.accentViolet)
                .frame(width: 64, height: 64)
                .background(FlashScopeTheme.accentViolet.opacity(0.08), in: RoundedRectangle(cornerRadius: 17))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text("No performance baseline yet")
                    .font(.headline)
                Text("Run a Standard check to measure bounded sequential performance, stability, cache behavior, and SHA-256 integrity.")
                    .font(FlashScopeTheme.supporting)
                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
            }
            Spacer()
        }
        .padding(16)
        .flashScopeInsetSurface(accent: FlashScopeTheme.accentViolet)
    }

    private func headlineMetrics(_ benchmark: BenchmarkResult) -> some View {
        let stability = DiagnosticInsightAnalyzer.stability(for: benchmark)
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 185), spacing: 12)], spacing: 12) {
            MetricTile(
                title: "Sustained write",
                value: String(format: "%.1f %@", converted(benchmark.writeMegabytesPerSecond), unit.rawValue),
                detail: "Durably synchronized",
                systemImage: "arrow.down.to.line",
                tint: FlashScopeTheme.accentViolet
            )
            MetricTile(
                title: "Sequential read",
                value: String(format: "%.1f %@", converted(benchmark.readMegabytesPerSecond), unit.rawValue),
                detail: "File-level read",
                systemImage: "arrow.up.from.line",
                tint: FlashScopeTheme.accent
            )
            MetricTile(
                title: "Transfer stability",
                value: "\(stability.score) / 100",
                detail: "\(stability.label) · \(stability.variationPercent)% variation · \(stability.stallCount) stall\(stability.stallCount == 1 ? "" : "s")",
                systemImage: "waveform.path",
                tint: stability.score >= 80 ? FlashScopeTheme.positive : FlashScopeTheme.warning
            )
            MetricTile(
                title: "Data integrity",
                value: benchmark.integrity.status == .passed ? "Passed" : "Mismatch",
                detail: "SHA-256 complete read-back",
                systemImage: benchmark.integrity.status == .passed ? "checkmark.shield.fill" : "exclamationmark.shield.fill",
                tint: benchmark.integrity.status == .passed ? FlashScopeTheme.positive : FlashScopeTheme.critical
            )
        }
    }

    private func measuredVsExpected(_ benchmark: BenchmarkResult) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text("Measured vs expected")
                    .font(.callout.weight(.semibold))
                Spacer()
                Text("Connection-relative guidance")
                    .font(.caption2)
                    .foregroundStyle(FlashScopeTheme.foregroundTertiary)
            }

            if let expectedRange {
                comparisonRow(title: "Read", measured: benchmark.readMegabytesPerSecond, expected: expectedRange, tint: FlashScopeTheme.accent)
                let writeGuidance = max(5, expectedRange.lowerBound * 0.35)...max(15, expectedRange.upperBound * 0.70)
                comparisonRow(title: "Write", measured: benchmark.writeMegabytesPerSecond, expected: writeGuidance, tint: FlashScopeTheme.accentViolet)
                Text("Guidance is based on the current connection class, not a manufacturer promise. Flash media can legitimately be slower than the bus ceiling.")
                    .font(.caption2)
                    .foregroundStyle(FlashScopeTheme.foregroundTertiary)
            } else {
                Text("Negotiated USB speed is unavailable, so FlashScope cannot anchor these measurements to a connection class. The measurements remain useful, but bottleneck confidence is lower.")
                    .font(FlashScopeTheme.supporting)
                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
            }
        }
        .flashScopeInsetSurface(accent: FlashScopeTheme.accentBlue)
    }

    private func comparisonRow(title: String, measured: Double, expected: ClosedRange<Double>, tint: Color) -> some View {
        let normalized = min(1, measured / max(expected.upperBound, measured))
        let below = measured < expected.lowerBound * 0.70
        let status = below ? "Below guidance" : (measured <= expected.upperBound * 1.25 ? "Plausible for this connection" : "Above generic guidance")
        let statusColor = below ? FlashScopeTheme.warning : FlashScopeTheme.positive

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.caption.weight(.semibold))
                Spacer()
                Text(String(format: "%.1f %@", converted(measured), unit.rawValue))
                    .font(.caption.monospacedDigit().weight(.semibold))
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.055))
                    Capsule()
                        .fill(LinearGradient(colors: [tint, tint.opacity(0.55)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: proxy.size.width * CGFloat(normalized))
                }
            }
            .frame(height: 5)
            HStack {
                Label(status, systemImage: below ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(statusColor)
                Spacer()
                Text(String(format: "Guidance %.0f–%.0f MB/s", expected.lowerBound, expected.upperBound))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(FlashScopeTheme.foregroundTertiary)
            }
        }
    }

    private func throughputChart(_ benchmark: BenchmarkResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Throughput over time")
                    .font(.callout.weight(.semibold))
                Spacer()
                HStack(spacing: 12) {
                    legendDot("Write", color: FlashScopeTheme.accentViolet)
                    legendDot("Read", color: FlashScopeTheme.accent)
                }
            }

            Chart {
                ForEach(benchmark.writeSamples) { sample in
                    AreaMark(
                        x: .value("Time", sample.elapsedSeconds),
                        y: .value("Write", converted(sample.megabytesPerSecond))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FlashScopeTheme.accentViolet.opacity(0.16), FlashScopeTheme.accentViolet.opacity(0.01)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Time", sample.elapsedSeconds),
                        y: .value("Write", converted(sample.megabytesPerSecond))
                    )
                    .foregroundStyle(FlashScopeTheme.accentViolet)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                }

                ForEach(benchmark.readSamples) { sample in
                    LineMark(
                        x: .value("Time", sample.elapsedSeconds),
                        y: .value("Read", converted(sample.megabytesPerSecond))
                    )
                    .foregroundStyle(FlashScopeTheme.accent)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                }

                if let expectedRange {
                    RuleMark(y: .value("Expected minimum", converted(expectedRange.lowerBound)))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 5]))
                        .foregroundStyle(FlashScopeTheme.foregroundTertiary.opacity(0.55))
                }
            }
            .frame(height: 210)
            .chartLegend(.hidden)
            .chartYAxisLabel(unit.rawValue)
            .chartXAxisLabel("Elapsed seconds")
            .chartPlotStyle { plot in
                plot.background(Color.white.opacity(0.015))
            }
            .accessibilityLabel("Sequential throughput over time")
        }
        .padding(13)
        .background(Color.white.opacity(0.022), in: RoundedRectangle(cornerRadius: FlashScopeTheme.Radius.tile))
        .overlay { RoundedRectangle(cornerRadius: FlashScopeTheme.Radius.tile).stroke(Color.white.opacity(0.055), lineWidth: 1) }
    }

    private func legendDot(_ label: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.caption2).foregroundStyle(FlashScopeTheme.foregroundSecondary)
        }
    }

    @ViewBuilder
    private func derivedInsights(_ benchmark: BenchmarkResult) -> some View {
        let suitability = DiagnosticInsightAnalyzer.workloadSuitability(workload, benchmark: benchmark)
        InsetNotice(
            kind: suitability.rating == .poor ? .warning : .info,
            title: "\(workload.rawValue): \(suitability.rating.rawValue)",
            message: suitability.summary
        )

        if let cliff = DiagnosticInsightAnalyzer.cacheCliff(for: benchmark), cliff.detected {
            let location = cliff.estimatedCliffBytes.map { " after approximately \(StorageFormatting.bytes($0))" } ?? " during the sustained write"
            InsetNotice(
                kind: .warning,
                title: "Write-cache cliff detected",
                message: String(format: "Write throughput started around %.1f MB/s and settled near %.1f MB/s, a %d%% drop%@. This pattern is more consistent with burst/cache exhaustion or sustained-media limits than with the USB bus alone.", cliff.burstMegabytesPerSecond, cliff.sustainedMegabytesPerSecond, cliff.dropPercent, location)
            )
        }

        transferTimePanel(benchmark)

        if benchmark.configuration.preset == .custom {
            InsetNotice(
                kind: benchmark.integrity.status == .passed ? .info : .critical,
                title: "Capacity integrity sample",
                message: benchmark.integrity.status == .passed
                    ? "FlashScope successfully wrote and verified \(StorageFormatting.bytes(benchmark.configuration.sizeBytes)) of app-owned temporary data. This strengthens confidence in the tested free-space sample but does not prove occupied or otherwise untested capacity."
                    : "The capacity sample did not read back identically. Treat this as critical integrity evidence and back up important data immediately."
            )
        }
    }

    private func transferTimePanel(_ benchmark: BenchmarkResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Estimated copy time")
                .font(.callout.weight(.semibold))
            HStack(spacing: 10) {
                transferEstimate("1 GB", bytes: 1_000_000_000, benchmark: benchmark)
                transferEstimate("10 GB", bytes: 10_000_000_000, benchmark: benchmark)
                transferEstimate("100 GB", bytes: 100_000_000_000, benchmark: benchmark)
            }
            Text("Based on measured sustained write speed; real copies vary with file sizes, source media, filesystem overhead, caching, and other system activity.")
                .font(.caption2)
                .foregroundStyle(FlashScopeTheme.foregroundTertiary)
        }
        .flashScopeInsetSurface(accent: FlashScopeTheme.accentViolet)
    }

    private func transferEstimate(_ label: String, bytes: UInt64, benchmark: BenchmarkResult) -> some View {
        let seconds = DiagnosticInsightAnalyzer.estimatedTransferSeconds(bytes: bytes, megabytesPerSecond: benchmark.writeMegabytesPerSecond)
        return VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption2).foregroundStyle(FlashScopeTheme.foregroundSecondary)
            Text(seconds.map(StorageFormatting.duration) ?? "—")
                .font(.callout.weight(.semibold))
                .monospacedDigit()
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 10))
    }

    private func detailedStatistics(_ benchmark: BenchmarkResult) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 290), spacing: 14)], spacing: 12) {
            statistics("Write statistics", benchmark.writeStatistics, tint: FlashScopeTheme.accentViolet)
            statistics("Read statistics", benchmark.readStatistics, tint: FlashScopeTheme.accent)
        }
    }

    @ViewBuilder
    private func limitations(_ benchmark: BenchmarkResult) -> some View {
        if let small = benchmark.smallFileResult {
            InsetNotice(kind: .info, title: "Small-file workload", message: String(format: "%.1f %@, %.0f files/s, %.0f ops/s across %d files. Small-file work is intentionally reported separately from large sequential throughput.", converted(small.megabytesPerSecond), unit.rawValue, small.filesPerSecond, small.operationsPerSecond, small.fileCount))
        }
        InsetNotice(kind: .info, title: "Read-cache limitation", message: "The standard read is file-level and may be influenced by macOS filesystem/RAM caching. It is never labeled as raw-media performance. Write timing includes a durable flush.")
    }

    private func liveProgress(_ progress: BenchmarkProgress) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().stroke(Color.white.opacity(0.08), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: max(0.02, progress.fraction))
                        .stroke(FlashScopeTheme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 38, height: 38)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(progress.phase.rawValue.capitalized)
                        .font(.callout.weight(.semibold))
                    Text(progress.message)
                        .font(.caption)
                        .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(Int(progress.fraction * 100))%")
                        .font(.headline.monospacedDigit())
                    if let rate = progress.currentMegabytesPerSecond {
                        Text(String(format: "%.1f %@", converted(rate), unit.rawValue))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                    }
                }
            }
            ProgressView(value: progress.fraction)
                .tint(FlashScopeTheme.accent)
        }
        .padding(14)
        .background(FlashScopeTheme.accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 15))
        .overlay { RoundedRectangle(cornerRadius: 15).stroke(FlashScopeTheme.accent.opacity(0.14), lineWidth: 1) }
        .contentTransition(.numericText())
        .animation(reduceMotion ? nil : .easeOut(duration: 0.24), value: progress.fraction)
        .accessibilityIdentifier("benchmark-progress")
    }

    private func statistics(_ title: String, _ stats: BenchmarkStatistics, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Circle().fill(tint).frame(width: 7, height: 7)
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(FlashScopeTheme.foregroundSecondary)
            }
            Text("Min \(format(stats.minimum))  •  Avg \(format(stats.average))  •  Median \(format(stats.median))")
            Text("p95 \(format(stats.p95))  •  Max \(format(stats.maximum))  •  Variation \(Int(stats.coefficientOfVariation * 100))%")
        }
        .font(.caption.monospacedDigit())
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 11))
    }

    private func converted(_ decimalMBps: Double) -> Double { StorageFormatting.throughput(decimalMBps, unit: unit) }
    private func format(_ value: Double) -> String { String(format: "%.1f", converted(value)) }
}
