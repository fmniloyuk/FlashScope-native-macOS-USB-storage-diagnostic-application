import AppKit
import FlashScopeCore
import SwiftUI

struct ConnectionCard: View {
    let drive: PhysicalDrive
    let connection: USBConnection
    let diagnosis: DiagnosisReport?
    let refreshAction: () -> Void

    var body: some View {
        DiagnosticCard("Connection", systemImage: "cable.connector", subtitle: "See the Mac-to-drive path and where performance may be constrained") {
            VStack(alignment: .leading, spacing: 15) {
                connectionPathVisualizer

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 175), spacing: 11)], spacing: 11) {
                    if let specification {
                        MetricTile(title: "USB capability", value: specification.rawValue, detail: "Device-declared", systemImage: "externaldrive", tint: FlashScopeTheme.accent)
                    }
                    if let speed = connection.negotiatedSpeed.value {
                        MetricTile(title: "Negotiated link", value: speed.label, detail: speed.classLabel, systemImage: "cable.connector", tint: isReducedUSB3Link ? FlashScopeTheme.warning : FlashScopeTheme.positive)
                        MetricTile(title: "Bus ceiling", value: String(format: "%.1f MB/s", speed.theoreticalMegabytesPerSecond), detail: "Theoretical, not expected flash speed", systemImage: "gauge.with.dots.needle.67percent", tint: FlashScopeTheme.accentBlue)
                    }
                    if let range = diagnosis?.expectedPracticalRangeMBps {
                        MetricTile(title: "Practical read guide", value: String(format: "%.0f–%.0f MB/s", range.lowerBound, range.upperBound), detail: "Connection-relative guidance", systemImage: "chart.line.uptrend.xyaxis", tint: FlashScopeTheme.accentViolet)
                    }
                    if let power {
                        MetricTile(title: "USB power", value: power, systemImage: "bolt.fill", tint: FlashScopeTheme.warning)
                    }
                }

                if isReducedUSB3Link {
                    InsetNotice(
                        kind: .warning,
                        title: "Connection bottleneck detected",
                        message: "This USB 3-capable device is currently operating at USB 2-class speed. The connection path is the strongest explanation for reduced large-file throughput before assuming the flash media is unhealthy."
                    )
                    recoveryActions(includeSystemInformation: true)
                } else if hasLimitedConnectionEvidence {
                    InsetNotice(
                        kind: .info,
                        title: "Some USB evidence is hidden",
                        message: connectionLimitationMessage
                    )
                    recoveryActions(includeSystemInformation: true)
                } else if let speed = connection.negotiatedSpeed.value {
                    InsetNotice(
                        kind: .info,
                        title: "Connection classified",
                        message: "macOS reports a \(speed.label) negotiated link. FlashScope interprets benchmark results against this current path instead of a marketing maximum."
                    )
                }

                DisclosureGroup("USB details") {
                    VStack(alignment: .leading, spacing: 10) {
                        if let port = connection.portPath.value {
                            MetricRow(label: "USB location", value: port)
                        }
                        if let identifiers {
                            MetricRow(label: "Vendor / Product ID", value: identifiers)
                        }
                        if !connection.topology.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Raw topology").font(.caption.weight(.semibold))
                                ForEach(connection.topology) { node in
                                    Label(node.name, systemImage: node.kind.localizedCaseInsensitiveContains("hub") ? "point.3.connected.trianglepath.dotted" : "circle.dotted")
                                        .font(.caption)
                                        .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                                }
                            }
                        }
                        if !missingEvidenceReasons.isEmpty {
                            Divider().opacity(0.25)
                            Text("Why some values are unavailable")
                                .font(.caption.weight(.semibold))
                            ForEach(missingEvidenceReasons, id: \.self) { reason in
                                Label(reason, systemImage: "info.circle")
                                    .font(.caption)
                                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                            }
                            Text("Missing telemetry lowers confidence. It is not itself a hardware failure.")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                        }
                    }
                    .padding(.top, 9)
                }
                .font(.callout.weight(.medium))
            }
        }
        .accessibilityIdentifier("connection-card")
    }

    private var connectionPathVisualizer: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text("Connection path")
                    .font(.callout.weight(.semibold))
                Spacer()
                if isReducedUSB3Link {
                    Label("Bottleneck", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FlashScopeTheme.warning)
                }
            }

            HStack(spacing: 7) {
                pathNode(title: "Mac", detail: "USB host", icon: "laptopcomputer", warning: false)
                pathArrow

                if connection.hubOrAdapterDetected.value == true {
                    pathNode(title: "Hub / adapter", detail: "Intermediate device", icon: "point.3.connected.trianglepath.dotted", warning: isReducedUSB3Link)
                    pathArrow
                }

                pathNode(
                    title: connection.negotiatedSpeed.value?.label ?? "Link unknown",
                    detail: connection.negotiatedSpeed.value?.classLabel ?? "Speed not exposed",
                    icon: "cable.connector",
                    warning: isReducedUSB3Link || connection.negotiatedSpeed.value == nil
                )
                pathArrow
                pathNode(
                    title: drive.displayName,
                    detail: specification?.rawValue ?? "Capability not exposed",
                    icon: "externaldrive.fill",
                    warning: false
                )
            }
            .accessibilityElement(children: .contain)

            if isReducedUSB3Link {
                Label(
                    connection.hubOrAdapterDetected.value == true
                        ? "Remove the intermediate device and retest the same profile to isolate the path."
                        : "Try another known high-speed port and retest the same profile.",
                    systemImage: "arrow.triangle.2.circlepath"
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(FlashScopeTheme.warning)
            }
        }
        .padding(14)
        .background(
            LinearGradient(colors: [FlashScopeTheme.accentBlue.opacity(0.07), Color.white.opacity(0.018)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay { RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 1) }
    }

    private func pathNode(title: String, detail: String, icon: String, warning: Bool) -> some View {
        let tint = warning ? FlashScopeTheme.warning : FlashScopeTheme.accent
        return VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                .lineLimit(2)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
        .background(tint.opacity(warning ? 0.09 : 0.045), in: RoundedRectangle(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).stroke(tint.opacity(warning ? 0.30 : 0.08), lineWidth: 1) }
    }

    private var pathArrow: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(FlashScopeTheme.foregroundTertiary)
            .accessibilityHidden(true)
    }

    private var specification: USBSpecification? {
        connection.declaredSpecification.value ?? drive.capabilities.declaredUSBSpecification.value
    }

    private var identifiers: String? {
        guard connection.vendorID.value != nil || connection.productID.value != nil else { return nil }
        let vendor = connection.vendorID.value.map { String(format: "0x%04X", $0) } ?? "—"
        let product = connection.productID.value.map { String(format: "0x%04X", $0) } ?? "—"
        return "\(vendor) / \(product)"
    }

    private var power: String? {
        let allocated = connection.allocatedMilliAmps.value.map { "\($0) mA requested" }
        let available = connection.availableMilliAmps.value.map { "\($0) mA available" }
        let values = [allocated, available].compactMap { $0 }
        return values.isEmpty ? nil : values.joined(separator: " · ")
    }

    private var hasLimitedConnectionEvidence: Bool {
        specification == nil || connection.negotiatedSpeed.value == nil
    }

    private var connectionLimitationMessage: String {
        if specification == nil && connection.negotiatedSpeed.value == nil {
            return "FlashScope found the removable disk, but macOS or its USB bridge did not expose enough descriptor/link information to classify the path. Refresh, reconnect directly to the Mac, remove intermediate devices where practical, or compare System Information."
        }
        if connection.negotiatedSpeed.value == nil {
            return "The device was identified, but macOS did not expose a negotiated link speed FlashScope can safely classify. Refresh after reconnecting directly, or compare System Information."
        }
        return "The current link speed is available, but the device's declared USB specification is not exposed. FlashScope does not infer capabilities from marketing names."
    }

    private var missingEvidenceReasons: [String] {
        var reasons: [String] = []
        if specification == nil {
            reasons.append(connection.declaredSpecification.explanation ?? drive.capabilities.declaredUSBSpecification.explanation ?? "USB specification was not exposed")
        }
        if connection.negotiatedSpeed.value == nil, let reason = connection.negotiatedSpeed.explanation { reasons.append(reason) }
        if connection.vendorID.value == nil, let reason = connection.vendorID.explanation { reasons.append(reason) }
        if connection.productID.value == nil, let reason = connection.productID.explanation { reasons.append(reason) }
        if connection.portPath.value == nil, let reason = connection.portPath.explanation { reasons.append(reason) }
        if connection.allocatedMilliAmps.value == nil, let reason = connection.allocatedMilliAmps.explanation { reasons.append(reason) }
        if connection.availableMilliAmps.value == nil, let reason = connection.availableMilliAmps.explanation { reasons.append(reason) }
        return Array(Set(reasons)).sorted()
    }

    private var isReducedUSB3Link: Bool {
        guard specification == .usb3 || specification == .usb4,
              let speed = connection.negotiatedSpeed.value else { return false }
        return speed.megabitsPerSecond <= 500
    }

    @ViewBuilder
    private func recoveryActions(includeSystemInformation: Bool) -> some View {
        HStack(spacing: 10) {
            Button { refreshAction() } label: { Label("Refresh", systemImage: "arrow.clockwise") }
            if includeSystemInformation {
                Button { openSystemInformation() } label: { Label("System Information", systemImage: "info.circle") }
            }
            Spacer(minLength: 0)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private func openSystemInformation() {
        let candidates = [
            "/System/Applications/Utilities/System Information.app",
            "/Applications/Utilities/System Information.app"
        ]
        guard let path = candidates.first(where: { FileManager.default.fileExists(atPath: $0) }) else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }
}
