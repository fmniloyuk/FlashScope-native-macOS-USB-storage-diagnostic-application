import FlashScopeCore
import SwiftUI

struct DashboardView: View {
    private enum DashboardMode: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case diagnose = "Diagnose"
        case technical = "Technical"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .overview: "square.grid.2x2"
            case .diagnose: "stethoscope"
            case .technical: "slider.horizontal.3"
            }
        }
    }

    let model: AppViewModel
    let verifyFilesystem: () -> Void
    let retestAction: () -> Void
    @State private var mode: DashboardMode = .overview

    var body: some View {
        if let drive = model.selectedDrive, let volume = model.selectedVolume {
            ScrollView {
                LazyVStack(spacing: 18) {
                    pageHeader(drive: drive, volume: volume)

                    OverviewCard(
                        drive: drive,
                        volume: volume,
                        diagnosis: model.diagnosis,
                        connection: model.connection,
                        benchmark: model.benchmarkResult,
                        filesystemCheck: model.filesystemCheck,
                        healthSignals: model.healthSignals,
                        history: model.history,
                        runCheckAction: retestAction
                    )

                    dashboardModePicker

                    switch mode {
                    case .overview:
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 430), spacing: 18)], spacing: 18) {
                            ConnectionCard(
                                drive: drive,
                                connection: model.connection,
                                diagnosis: model.diagnosis,
                                refreshAction: { Task { await model.refresh() } }
                            )
                            FilesystemCard(
                                volume: volume,
                                result: model.filesystemCheck,
                                isVerifying: model.isVerifyingFilesystem,
                                verifyAction: verifyFilesystem,
                                refreshAction: { Task { await model.refresh() } }
                            )
                        }
                        FindingsCard(diagnosis: model.diagnosis, retestAction: retestAction)
                        PerformanceCard(
                            benchmark: model.benchmarkResult,
                            progress: model.benchmarkProgress,
                            isBenchmarking: model.isBenchmarking,
                            expectedRange: model.diagnosis?.expectedPracticalRangeMBps,
                            unit: model.preferences.throughputUnit,
                            workload: model.preferences.workload
                        )
                        HistoryCard(
                            sessions: model.history,
                            unit: model.preferences.throughputUnit,
                            delete: { session in Task { await model.deleteHistory(session) } },
                            deleteAll: { Task { await model.deleteAllHistory() } }
                        )

                    case .diagnose:
                        FindingsCard(diagnosis: model.diagnosis, retestAction: retestAction)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 430), spacing: 18)], spacing: 18) {
                            ConnectionCard(
                                drive: drive,
                                connection: model.connection,
                                diagnosis: model.diagnosis,
                                refreshAction: { Task { await model.refresh() } }
                            )
                            FilesystemCard(
                                volume: volume,
                                result: model.filesystemCheck,
                                isVerifying: model.isVerifyingFilesystem,
                                verifyAction: verifyFilesystem,
                                refreshAction: { Task { await model.refresh() } }
                            )
                        }
                        PerformanceCard(
                            benchmark: model.benchmarkResult,
                            progress: model.benchmarkProgress,
                            isBenchmarking: model.isBenchmarking,
                            expectedRange: model.diagnosis?.expectedPracticalRangeMBps,
                            unit: model.preferences.throughputUnit,
                            workload: model.preferences.workload
                        )

                    case .technical:
                        technicalEvidence(drive: drive, volume: volume)
                        ConnectionCard(
                            drive: drive,
                            connection: model.connection,
                            diagnosis: model.diagnosis,
                            refreshAction: { Task { await model.refresh() } }
                        )
                        FilesystemCard(
                            volume: volume,
                            result: model.filesystemCheck,
                            isVerifying: model.isVerifyingFilesystem,
                            verifyAction: verifyFilesystem,
                            refreshAction: { Task { await model.refresh() } }
                        )
                        PerformanceCard(
                            benchmark: model.benchmarkResult,
                            progress: model.benchmarkProgress,
                            isBenchmarking: model.isBenchmarking,
                            expectedRange: model.diagnosis?.expectedPracticalRangeMBps,
                            unit: model.preferences.throughputUnit,
                            workload: model.preferences.workload
                        )
                        FindingsCard(diagnosis: model.diagnosis, retestAction: retestAction)
                        HistoryCard(
                            sessions: model.history,
                            unit: model.preferences.throughputUnit,
                            delete: { session in Task { await model.deleteHistory(session) } },
                            deleteAll: { Task { await model.deleteAllHistory() } }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 34)
                .frame(maxWidth: 1460)
                .frame(maxWidth: .infinity)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("")
            .background(Color.clear)
        } else {
            VStack(spacing: 12) {
                ProgressView()
                Text("Inspecting drive…")
                    .font(.headline)
                Text("FlashScope is collecting safe read-only information about the selected removable drive.")
                    .font(FlashScopeTheme.supporting)
                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
            }
            .padding(30)
            .flashScopeSurface()
            .padding(30)
        }
    }

    private func pageHeader(drive: PhysicalDrive, volume: Volume) -> some View {
        HStack(alignment: .bottom, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("FLASHSCOPE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(FlashScopeTheme.accent)
                Text(volume.name)
                    .font(FlashScopeTheme.pageTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text("\(drive.displayName)  •  \(StorageFormatting.bytes(volume.capacityBytes))  •  \(volume.filesystem.value?.rawValue ?? "Filesystem not exposed")")
                    .font(FlashScopeTheme.supporting)
                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                    .lineLimit(1)
            }
            Spacer()
            if model.simulationMode {
                Label("SIMULATION", systemImage: "testtube.2")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(FlashScopeTheme.warning)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(FlashScopeTheme.warning.opacity(0.08), in: Capsule())
                    .overlay { Capsule().stroke(FlashScopeTheme.warning.opacity(0.18), lineWidth: 1) }
            }
        }
    }

    private var dashboardModePicker: some View {
        HStack(spacing: 6) {
            ForEach(DashboardMode.allCases) { item in
                Button {
                    mode = item
                } label: {
                    Label(item.rawValue, systemImage: item.icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(mode == item ? FlashScopeTheme.foregroundPrimary : FlashScopeTheme.foregroundSecondary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 7)
                        .background(mode == item ? FlashScopeTheme.accent.opacity(0.10) : Color.clear, in: Capsule())
                        .overlay {
                            if mode == item {
                                Capsule().stroke(FlashScopeTheme.accent.opacity(0.18), lineWidth: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(mode == item ? .isSelected : [])
            }
            Spacer()
        }
        .padding(5)
        .background(Color.white.opacity(0.025), in: Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("dashboard-mode-picker")
    }

    private func technicalEvidence(drive: PhysicalDrive, volume: Volume) -> some View {
        DiagnosticCard("Technical Evidence", systemImage: "terminal", subtitle: model.preferences.technicianMode ? "Technician mode — raw evidence plus conservative lab triage" : "Enable Technician mode in Settings for lab-oriented context") {
            VStack(alignment: .leading, spacing: 14) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: 14)], spacing: 10) {
                    MetricTile(title: "BSD device", value: drive.bsdName, detail: volume.bsdName, systemImage: "externaldrive")
                    MetricTile(title: "Filesystem", value: volume.filesystem.value?.rawValue ?? "Not exposed", detail: volume.partitionScheme.value?.rawValue, systemImage: "internaldrive")
                    MetricTile(title: "Negotiated link", value: model.connection.negotiatedSpeed.value?.label ?? "Not exposed", detail: model.connection.portPath.value, systemImage: "cable.connector")
                    MetricTile(title: "Lab triage", value: labTriage, detail: "\(model.history.count) local history record\(model.history.count == 1 ? "" : "s")", systemImage: "checklist")
                }

                DisclosureGroup("Raw identifiers and mount information") {
                    VStack(alignment: .leading, spacing: 7) {
                        MetricRow(label: "Mount path", value: volume.mountPath)
                        MetricRow(label: "VID", value: model.connection.vendorID.value.map { String(format: "0x%04X", $0) } ?? "Not exposed")
                        MetricRow(label: "PID", value: model.connection.productID.value.map { String(format: "0x%04X", $0) } ?? "Not exposed")
                    }
                    .padding(.top, 8)
                }

                let coverage = DiagnosticInsightAnalyzer.evidenceCoverage(
                    drive: drive,
                    volume: volume,
                    connection: model.connection,
                    benchmark: model.benchmarkResult,
                    filesystemCheck: model.filesystemCheck,
                    healthSignals: model.healthSignals
                )
                InsetNotice(
                    kind: labTriage == "FAIL" ? .critical : .info,
                    title: "Evidence coverage \(coverage.availableSignals)/\(coverage.totalSignals)",
                    message: "Available: \(coverage.available.joined(separator: ", ")). Missing: \(coverage.missing.isEmpty ? "none" : coverage.missing.joined(separator: ", ")). Lab triage is conservative and is not a certification of future reliability."
                )
            }
        }
        .accessibilityIdentifier("technical-evidence-card")
    }

    private var labTriage: String {
        guard model.preferences.technicianMode else { return "Technician mode off" }
        guard let diagnosis = model.diagnosis else { return "REVIEW" }
        if diagnosis.findings.contains(where: { $0.severity == .critical }) { return "FAIL" }
        if model.benchmarkResult?.integrity.status == .mismatch { return "FAIL" }
        if diagnosis.findings.contains(where: { $0.severity >= .high }) { return "REVIEW" }
        if model.benchmarkResult == nil { return "REVIEW" }
        return "PASS"
    }
}
