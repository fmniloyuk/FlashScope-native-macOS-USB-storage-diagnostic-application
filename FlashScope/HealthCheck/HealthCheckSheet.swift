import FlashScopeCore
import SwiftUI

struct HealthCheckSheet: View {
    private enum CheckMode: String, CaseIterable, Identifiable {
        case quick = "Quick"
        case standard = "Standard"
        case deep = "Deep"
        case capacity = "Capacity Integrity"

        var id: String { rawValue }
        var preset: BenchmarkPreset {
            switch self {
            case .quick: .quick
            case .standard: .standard
            case .deep: .extended
            case .capacity: .custom
            }
        }
        var icon: String {
            switch self {
            case .quick: "bolt.fill"
            case .standard: "checkmark.shield.fill"
            case .deep: "waveform.path.ecg"
            case .capacity: "externaldrive.badge.checkmark"
            }
        }
        var summary: String {
            switch self {
            case .quick: "Fast connection + integrity sample for first-pass troubleshooting."
            case .standard: "Balanced read/write, SHA-256 verification, and optional small-file testing."
            case .deep: "Longer sustained workload designed to expose instability and cache slowdowns."
            case .capacity: "Largest currently safe free-space sample without touching existing files."
            }
        }
        var tint: Color {
            switch self {
            case .quick: FlashScopeTheme.accent
            case .standard: FlashScopeTheme.accentBlue
            case .deep: FlashScopeTheme.accentViolet
            case .capacity: FlashScopeTheme.warning
            }
        }
    }

    let model: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var mode: CheckMode
    @State private var includeSmallFiles: Bool

    init(model: AppViewModel) {
        self.model = model
        let suggested = model.suggestedBenchmarkConfiguration()
        let initialMode: CheckMode
        switch suggested?.preset {
        case .quick: initialMode = .quick
        case .extended: initialMode = .deep
        default: initialMode = .standard
        }
        _mode = State(initialValue: initialMode)
        _includeSmallFiles = State(initialValue: model.preferences.includeSmallFileTest)
    }

    var body: some View {
        ZStack {
            FlashScopeBackground()

            VStack(spacing: 0) {
                header
                Divider().opacity(0.18)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if let drive = model.selectedDrive, let volume = model.selectedVolume {
                            preflight(drive: drive, volume: volume)
                            profileSelector(volume: volume)
                            testPlan
                            safetyNotice(volume: volume)
                        }
                    }
                    .padding(22)
                }

                Divider().opacity(0.18)
                footer
            }
        }
        .frame(minWidth: 720, idealWidth: 800, minHeight: 720)
        .accessibilityIdentifier("health-check-sheet")
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: [FlashScopeTheme.accentBlue.opacity(0.22), FlashScopeTheme.accentViolet.opacity(0.16)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "stethoscope")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(FlashScopeTheme.accent)
            }
            .frame(width: 50, height: 50)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("Run Diagnostic Check")
                    .font(.title2.weight(.bold))
                Text("Choose the evidence depth. FlashScope explains exactly what it will write before you start.")
                    .font(FlashScopeTheme.supporting)
                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
            }
            Spacer()
            Button("Cancel") { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
        .padding(20)
    }

    private var footer: some View {
        HStack(spacing: 14) {
            Label("Existing user files are never overwritten", systemImage: "lock.shield.fill")
                .font(.caption)
                .foregroundStyle(FlashScopeTheme.foregroundSecondary)
            Spacer()
            Button(startButtonTitle) {
                let config = BenchmarkConfiguration(
                    preset: mode.preset,
                    sizeBytes: selectedBytes,
                    sampleIntervalSeconds: model.preferences.sampleInterval,
                    dataPattern: .deterministicPseudoRandom,
                    includeSmallFileWorkload: includeSmallFiles && mode != .capacity
                )
                model.startHealthCheck(configuration: config)
                dismiss()
            }
            .buttonStyle(FlashScopePrimaryButtonStyle())
            .keyboardShortcut(.defaultAction)
            .disabled(!canStart)
            .accessibilityHint("Creates one unique FlashScope-owned temporary benchmark workspace on the selected removable volume, writes the stated amount, flushes, reads it back, verifies SHA-256, then performs exact cleanup.")
            .accessibilityIdentifier("confirm-start-benchmark-button")
        }
        .padding(17)
        .background(.ultraThinMaterial)
    }

    private func preflight(drive: PhysicalDrive, volume: Volume) -> some View {
        DiagnosticCard("Preflight", systemImage: "checklist", subtitle: "Target and free-space checks before any temporary benchmark file is created") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 11)], spacing: 11) {
                MetricTile(title: "Device", value: drive.displayName, detail: drive.bsdName, systemImage: "externaldrive", tint: FlashScopeTheme.accent)
                MetricTile(title: "Available", value: StorageFormatting.bytes(volume.availableBytes), detail: "\(Int(volume.freeFraction * 100))% free", systemImage: "chart.pie", tint: volume.freeFraction < 0.10 ? FlashScopeTheme.warning : FlashScopeTheme.positive)
                MetricTile(title: "Filesystem", value: volume.filesystem.value?.rawValue ?? "Unavailable", detail: volume.name, systemImage: "internaldrive", tint: FlashScopeTheme.accentBlue)
                MetricTile(title: "Target", value: drive.isExternal && drive.isRemovable && !drive.isInternal ? "Eligible" : "Restricted", detail: "External + removable required", systemImage: "lock.shield", tint: drive.isExternal && drive.isRemovable && !drive.isInternal ? FlashScopeTheme.positive : FlashScopeTheme.warning)
            }

            if volume.freeFraction < 0.10 {
                InsetNotice(kind: .warning, title: "Nearly full", message: "Low free space can reduce write performance and limits every safe diagnostic profile.")
            }
            if volume.isReadOnly {
                InsetNotice(kind: .warning, title: "Read-only volume", message: "Write-based checks cannot run while macOS reports this volume as read-only.")
            }
        }
    }

    private func profileSelector(volume: Volume) -> some View {
        DiagnosticCard("Diagnostic profile", systemImage: "slider.horizontal.3", subtitle: "Choose speed, evidence depth, and flash-wear tradeoff") {
            VStack(alignment: .leading, spacing: 13) {
                Picker("Diagnostic profile", selection: $mode) {
                    ForEach(CheckMode.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("diagnostic-profile-picker")

                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 13)
                            .fill(mode.tint.opacity(0.10))
                        Image(systemName: mode.icon)
                            .font(.title2)
                            .foregroundStyle(mode.tint)
                    }
                    .frame(width: 48, height: 48)
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(mode.rawValue).font(.headline)
                        Text(mode.summary)
                            .font(FlashScopeTheme.supporting)
                            .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                        HStack(spacing: 16) {
                            Label("Writes \(StorageFormatting.bytes(selectedBytes))", systemImage: "arrow.down.doc")
                            Label("~\(estimatedDuration)", systemImage: "clock")
                        }
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                    }
                    Spacer()
                }
                .flashScopeInsetSurface(accent: mode.tint)

                if mode == .capacity {
                    InsetNotice(kind: .warning, title: "Capacity verification stays non-destructive", message: capacityExplanation(volume: volume))
                } else {
                    Toggle("Include small-file workload", isOn: $includeSmallFiles)
                    Text("Useful for developer projects, document folders, and workloads containing thousands of small files. Results are reported separately from sequential throughput.")
                        .font(.caption)
                        .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                }
            }
        }
    }

    private var testPlan: some View {
        DiagnosticCard("What FlashScope will measure", systemImage: "list.bullet.rectangle", subtitle: "Real workflow stages only — no fake progress") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 10)], spacing: 10) {
                planRow("Connection context", "USB capability, negotiated link, topology, hub/adapter, and power evidence.", icon: "cable.connector")
                planRow("Sustained write", mode == .quick ? "Short bounded write sample." : "Tracks throughput over time to reveal cache cliffs and stalls.", icon: "arrow.down.to.line")
                planRow("Durable flush", "Synchronizes the temporary benchmark data before readback.", icon: "arrow.triangle.2.circlepath")
                planRow("Sequential read", "File-level read performance with explicit cache caveats.", icon: "arrow.up.from.line")
                planRow("Integrity", "SHA-256 is computed while writing and compared with the complete readback.", icon: "checkmark.shield")
                if includeSmallFiles && mode != .capacity {
                    planRow("Small files", "Bounded mixed-size workload with files/s and ops/s.", icon: "doc.on.doc")
                }
                if mode == .capacity {
                    planRow("Capacity coverage", "Largest safe sample of currently free space; occupied areas remain untouched.", icon: "externaldrive.badge.checkmark")
                }
            }
        }
    }

    private func safetyNotice(volume: Volume) -> some View {
        DiagnosticCard("Safety & wear", systemImage: "lock.shield.fill", subtitle: "FlashScope's non-destructive boundary remains unchanged") {
            VStack(alignment: .leading, spacing: 9) {
                safetyRow("Unique temporary workspace", "Never overwrites an existing path.")
                safetyRow("Verified cleanup", "Removes only exact FlashScope-owned identities after readback.")
                safetyRow("Cancellation safe", "Cancellation and removal use the same guarded cleanup rules.")
                InsetNotice(kind: .info, title: "Write amount", message: "This profile writes approximately \(StorageFormatting.bytes(selectedBytes)) once. Capacity Integrity can write substantially more than Standard or Deep, so use it only when you need stronger free-space evidence.")
                if volume.filesystem.value == .fat32 && mode == .capacity {
                    Text("FAT32 limits one file to under 4 GB, so capacity coverage is partial in this build. FlashScope will never reformat the volume to increase test coverage.")
                        .font(.caption)
                        .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                }
            }
        }
    }

    private func planRow(_ title: String, _ detail: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(FlashScopeTheme.accent)
                .frame(width: 22)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout.weight(.medium))
                Text(detail).font(.caption).foregroundStyle(FlashScopeTheme.foregroundSecondary)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.022), in: RoundedRectangle(cornerRadius: 11))
    }

    private func safetyRow(_ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(FlashScopeTheme.positive)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout.weight(.medium))
                Text(detail).font(.caption).foregroundStyle(FlashScopeTheme.foregroundSecondary)
            }
        }
    }

    private var selectedBytes: UInt64 {
        guard let volume = model.selectedVolume else { return 0 }
        let safe = model.maximumSafeBenchmarkBytes(for: volume)
        let fat32Limit: UInt64 = 3_800_000_000
        switch mode {
        case .quick:
            return min(BenchmarkPreset.quick.defaultBytes, safe)
        case .standard:
            return min(BenchmarkPreset.standard.defaultBytes, safe)
        case .deep:
            let target = min(BenchmarkPreset.extended.defaultBytes, safe)
            return volume.filesystem.value == .fat32 ? min(target, fat32Limit) : target
        case .capacity:
            return volume.filesystem.value == .fat32 ? min(safe, fat32Limit) : safe
        }
    }

    private var estimatedDuration: String {
        let referenceRate = max(10, model.benchmarkResult?.writeMegabytesPerSecond ?? model.history.compactMap(\.benchmark).first?.writeMegabytesPerSecond ?? 30)
        let write = DiagnosticInsightAnalyzer.estimatedTransferSeconds(bytes: selectedBytes, megabytesPerSecond: referenceRate) ?? 0
        let read = DiagnosticInsightAnalyzer.estimatedTransferSeconds(bytes: selectedBytes, megabytesPerSecond: max(referenceRate, 40)) ?? 0
        return StorageFormatting.duration((write + read) * 1.15)
    }

    private var startButtonTitle: String {
        mode == .capacity
            ? "Start Capacity Sample — Write \(StorageFormatting.bytes(selectedBytes))"
            : "Start \(mode.rawValue) Check — Write \(StorageFormatting.bytes(selectedBytes))"
    }

    private func capacityExplanation(volume: Volume) -> String {
        let fraction = volume.availableBytes == 0 ? 0 : Int((Double(selectedBytes) / Double(volume.availableBytes) * 100).rounded())
        return "FlashScope will temporarily write and verify \(StorageFormatting.bytes(selectedBytes)), about \(fraction)% of the currently free space permitted by its safety policy. Existing files and occupied regions remain untouched. Passing this sample proves only the area that was actually tested."
    }

    private var canStart: Bool {
        guard let drive = model.selectedDrive, let volume = model.selectedVolume else { return false }
        return drive.isExternal && drive.isRemovable && !drive.isInternal && volume.isMounted && !volume.isReadOnly && selectedBytes <= model.maximumSafeBenchmarkBytes(for: volume) && selectedBytes >= 32 * 1_024 * 1_024 && !(volume.filesystem.value == .fat32 && selectedBytes >= 4_000_000_000)
    }
}
