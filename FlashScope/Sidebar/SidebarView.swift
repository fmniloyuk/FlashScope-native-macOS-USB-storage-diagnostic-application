import FlashScopeCore
import SwiftUI

struct SidebarView: View {
    let model: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            brandHeader

            List(selection: selection) {
                Section {
                    ForEach(model.drives) { drive in
                        DriveSidebarRow(drive: drive, selected: model.selectedDriveID == drive.id)
                            .tag(drive.id)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .accessibilityIdentifier("sidebar-drive-\(drive.id)")
                    }
                } header: {
                    Text("REMOVABLE STORAGE")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.7)
                        .foregroundStyle(FlashScopeTheme.foregroundTertiary)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.sidebar)

            if model.simulationMode {
                simulationBadge
            }
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.white.opacity(0.055))
                .frame(width: 1)
                .accessibilityHidden(true)
        }
    }

    private var brandHeader: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [FlashScopeTheme.accentBlue.opacity(0.30), FlashScopeTheme.accentViolet.opacity(0.24)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "waveform.path.ecg.rectangle.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(FlashScopeTheme.accent)
            }
            .frame(width: 42, height: 42)
            .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.10), lineWidth: 1) }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text("FlashScope")
                    .font(.system(size: 20, weight: .bold))
                Text("USB diagnostics")
                    .font(FlashScopeTheme.micro)
                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private var simulationBadge: some View {
        Label("Simulation Mode", systemImage: "testtube.2")
            .font(.caption.weight(.semibold))
            .foregroundStyle(FlashScopeTheme.warning)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FlashScopeTheme.warning.opacity(0.07), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(FlashScopeTheme.warning.opacity(0.16), lineWidth: 1)
            }
            .padding(12)
            .accessibilityIdentifier("simulation-mode-banner")
    }

    private var selection: Binding<String?> {
        Binding(
            get: { model.selectedDriveID },
            set: { id in
                guard let id, let drive = model.drives.first(where: { $0.id == id }) else { return }
                Task { await model.selectDrive(drive) }
            }
        )
    }
}

private struct DriveSidebarRow: View {
    let drive: PhysicalDrive
    let selected: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill((selected ? FlashScopeTheme.accent : FlashScopeTheme.accentBlue).opacity(selected ? 0.16 : 0.08))
                Image(systemName: "externaldrive.fill")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(selected ? FlashScopeTheme.accent : FlashScopeTheme.foregroundSecondary)
            }
            .frame(width: 36, height: 36)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(drive.displayName)
                    .font(.callout.weight(selected ? .semibold : .medium))
                    .lineLimit(1)
                HStack(spacing: 5) {
                    Text(StorageFormatting.bytes(drive.capacityBytes))
                    Text("•")
                    Text(drive.isRemovable ? "Removable" : "Restricted")
                }
                .font(.caption2)
                .foregroundStyle(FlashScopeTheme.foregroundSecondary)
            }

            Spacer(minLength: 4)

            Circle()
                .fill(drive.isRemovable ? FlashScopeTheme.positive : FlashScopeTheme.warning)
                .frame(width: 7, height: 7)
                .overlay { Circle().stroke(Color.white.opacity(0.20), lineWidth: 1) }
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(
            selected
                ? FlashScopeTheme.accent.opacity(0.095)
                : (hovering ? Color.white.opacity(0.035) : Color.clear),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay {
            if selected {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(FlashScopeTheme.accent.opacity(0.22), lineWidth: 1)
            }
        }
        .contentShape(Rectangle())
        .onHover { inside in
            if reduceMotion {
                hovering = inside
            } else {
                withAnimation(.easeOut(duration: FlashScopeTheme.Motion.quick)) { hovering = inside }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(drive.displayName), \(StorageFormatting.bytes(drive.capacityBytes)), \(drive.isRemovable ? "removable USB drive" : "write benchmark restricted")")
    }
}
