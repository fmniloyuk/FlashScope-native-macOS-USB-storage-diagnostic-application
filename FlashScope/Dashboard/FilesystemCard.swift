import AppKit
import FlashScopeCore
import SwiftUI

struct FilesystemCard: View {
    let volume: Volume
    let result: FilesystemCheckResult
    let isVerifying: Bool
    let verifyAction: () -> Void
    let refreshAction: () -> Void

    var body: some View {
        DiagnosticCard("Filesystem", systemImage: "internaldrive", subtitle: "Compatibility, free space, write state, and read-only verification — never automatic repair") {
            VStack(alignment: .leading, spacing: 14) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 175), spacing: 11)], spacing: 11) {
                    MetricTile(title: "Format", value: volume.filesystem.value?.rawValue ?? "Not exposed", detail: "Detected filesystem", systemImage: "externaldrive", tint: FlashScopeTheme.accentBlue)
                    MetricTile(title: "Available", value: StorageFormatting.bytes(volume.availableBytes), detail: "\(Int(volume.freeFraction * 100))% free", systemImage: "chart.pie", tint: volume.freeFraction < 0.10 ? FlashScopeTheme.warning : FlashScopeTheme.positive)
                    MetricTile(title: "Write state", value: volume.isReadOnly ? "Read-only" : "Writable", detail: volume.isMounted ? "Mounted" : "Not mounted", systemImage: volume.isReadOnly ? "lock.fill" : "pencil.and.outline", tint: volume.isReadOnly ? FlashScopeTheme.warning : FlashScopeTheme.accent)
                    MetricTile(title: "Verification", value: verificationLabel, detail: result.exitStatus.map { "Exit status \($0)" }, systemImage: verificationIcon, tint: verificationColor)
                }

                if volume.filesystem.value == .fat32 {
                    InsetNotice(kind: .info, title: "FAT32 compatibility note", message: "FAT32 cannot store a single file of 4 GiB or larger, so FlashScope disables incompatible extended benchmarks. This is a filesystem limitation, not evidence of failing flash.")
                }

                if volume.freeFraction < 0.10 {
                    InsetNotice(
                        kind: .warning,
                        title: volume.availableBytes == 0 ? "Drive is full" : "Very little free space",
                        message: volume.availableBytes == 0
                            ? "No free space is available. FlashScope cannot safely run a write benchmark until space is freed. Open the drive in Finder, move or remove files yourself, then refresh."
                            : "A nearly full flash drive can sustain slower writes and leaves little room for a safe benchmark. Move or remove unneeded files yourself, then refresh and retest."
                    )
                    safeActions(showFinder: true, showDiskUtility: false)
                }

                if volume.isReadOnly {
                    InsetNotice(kind: .warning, title: "Volume is read-only", message: "FlashScope cannot run a write benchmark while macOS reports this volume as read-only. Check hardware write protection if present, reconnect the drive, or inspect it in Disk Utility. FlashScope will not remount it read-write or reformat it automatically.")
                    safeActions(showFinder: false, showDiskUtility: true)
                }

                switch result.status {
                case .issuesDetected:
                    InsetNotice(kind: .critical, title: "Filesystem verification reported problems", message: "Back up important data before attempting repair. FlashScope performed verification only and did not change the filesystem.")
                    HStack(spacing: 9) {
                        Button("Verify Again…") { verifyAction() }
                            .disabled(isVerifying || !volume.isMounted)
                        Button("Open Disk Utility") { openDiskUtility() }
                        Spacer()
                    }
                    .controlSize(.small)
                case .unableToRun, .permissionDenied, .toolUnavailable:
                    InsetNotice(kind: .info, title: "Verification did not complete", message: result.summary)
                    HStack(spacing: 9) {
                        Button("Try Again…") { verifyAction() }
                            .disabled(isVerifying || !volume.isMounted)
                        Button("Open Disk Utility") { openDiskUtility() }
                        Spacer()
                    }
                    .controlSize(.small)
                default:
                    EmptyView()
                }

                DisclosureGroup("Filesystem compatibility guidance") {
                    VStack(alignment: .leading, spacing: 8) {
                        guidance("FAT32", "Very broad compatibility; 4 GiB single-file limit and older design.")
                        guidance("exFAT", "Broad macOS/Windows compatibility for large files; common on removable media.")
                        guidance("APFS", "Modern Apple filesystem; best suited to Apple platforms and not broadly writable elsewhere.")
                        guidance("HFS+", "Legacy Apple filesystem; useful for older macOS workflows but less portable.")
                        Text("Changing filesystems normally requires destructive reformatting. Back up first. FlashScope provides guidance only and never performs that action automatically.")
                            .font(.caption)
                            .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                        Button("Open Disk Utility") { openDiskUtility() }
                            .controlSize(.small)
                    }
                    .padding(.top, 8)
                }
                .font(.callout.weight(.medium))

                HStack {
                    Button {
                        verifyAction()
                    } label: {
                        if isVerifying {
                            HStack(spacing: 7) {
                                ProgressView().controlSize(.small)
                                Text("Verifying…")
                            }
                        } else {
                            Label(result.status == .passed ? "Verify Again…" : "Verify Filesystem…", systemImage: "checkmark.shield")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isVerifying || !volume.isMounted)
                    .accessibilityHint("Requests confirmation before a normal, non-forced unmount. No repair command is run.")
                    .accessibilityIdentifier("verify-filesystem-button")
                    Spacer()
                    Label("Read-only check · may require normal unmount", systemImage: "lock.shield")
                        .font(.caption2)
                        .foregroundStyle(FlashScopeTheme.foregroundTertiary)
                }
            }
        }
        .accessibilityIdentifier("filesystem-card")
    }

    private var verificationLabel: String {
        switch result.status {
        case .passed: "Passed"
        case .issuesDetected: "Issues detected"
        case .unableToRun: "Could not run"
        case .permissionDenied: "Permission denied"
        case .toolUnavailable: "Tool unavailable"
        case .cancelled: "Cancelled"
        case .notRun: "Not run"
        }
    }

    private var verificationIcon: String {
        switch result.status {
        case .passed: "checkmark.shield.fill"
        case .issuesDetected: "exclamationmark.shield.fill"
        default: "shield.lefthalf.filled"
        }
    }

    private var verificationColor: Color {
        switch result.status {
        case .passed: FlashScopeTheme.positive
        case .issuesDetected: FlashScopeTheme.critical
        default: FlashScopeTheme.accentBlue
        }
    }

    @ViewBuilder
    private func safeActions(showFinder: Bool, showDiskUtility: Bool) -> some View {
        HStack(spacing: 9) {
            if showFinder {
                Button { openVolumeInFinder() } label: { Label("Open Drive", systemImage: "folder") }
                    .disabled(!volume.isMounted)
            }
            if showDiskUtility {
                Button("Open Disk Utility") { openDiskUtility() }
            }
            Button { refreshAction() } label: { Label("Refresh", systemImage: "arrow.clockwise") }
            Spacer()
        }
        .controlSize(.small)
    }

    private func guidance(_ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(FlashScopeTheme.accent)
                .frame(width: 48, alignment: .leading)
            Text(text)
                .font(.caption)
                .foregroundStyle(FlashScopeTheme.foregroundSecondary)
        }
    }

    private func openVolumeInFinder() {
        guard volume.isMounted else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: volume.mountPath, isDirectory: true))
    }

    private func openDiskUtility() {
        let candidates = [
            "/System/Applications/Utilities/Disk Utility.app",
            "/Applications/Utilities/Disk Utility.app"
        ]
        guard let path = candidates.first(where: { FileManager.default.fileExists(atPath: $0) }) else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }
}
