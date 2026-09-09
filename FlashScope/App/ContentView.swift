import FlashScopeCore
import SwiftUI

struct ContentView: View {
    let model: AppViewModel
    @State private var showHealthCheck = false
    @State private var showHelp = false
    @State private var showVerificationConfirmation = false

    var body: some View {
        ZStack {
            FlashScopeBackground()

            NavigationSplitView {
                SidebarView(model: model)
                    .navigationSplitViewColumnWidth(min: 238, ideal: 270, max: 330)
            } detail: {
                ZStack {
                    FlashScopeBackground()

                    if model.drives.isEmpty && !model.isRefreshing {
                        emptyState
                    } else if model.selectedDrive != nil {
                        DashboardView(
                            model: model,
                            verifyFilesystem: { showVerificationConfirmation = true },
                            retestAction: { showHealthCheck = true }
                        )
                    } else {
                        selectDriveState
                    }
                }
            }
        }
        .toolbar { toolbar }
        .task { await model.start() }
        .sheet(isPresented: $showHealthCheck) { HealthCheckSheet(model: model) }
        .sheet(isPresented: $showHelp) { HelpView() }
        .confirmationDialog(
            "Verify the filesystem?",
            isPresented: $showVerificationConfirmation,
            titleVisibility: .visible
        ) {
            Button("Unmount Normally and Verify") { Task { await model.verifyFilesystemAfterConfirmation() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Close files and Finder windows using this volume. FlashScope will request a normal, non-forced unmount, run read-only verification only, and attempt to remount. It will not repair the filesystem.")
        }
        .alert(item: Binding(get: { model.notice }, set: { model.notice = $0 })) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [FlashScopeTheme.accent.opacity(0.22), FlashScopeTheme.accentBlue.opacity(0.06), .clear],
                            center: .center,
                            startRadius: 8,
                            endRadius: 88
                        )
                    )
                    .frame(width: 176, height: 176)

                RoundedRectangle(cornerRadius: 27, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 116, height: 116)
                    .overlay {
                        RoundedRectangle(cornerRadius: 27, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    }

                Image(systemName: "externaldrive.fill.badge.plus")
                    .font(.system(size: 48, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(FlashScopeTheme.accent)
            }
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Connect a USB drive")
                    .font(FlashScopeTheme.pageTitle)
                    .multilineTextAlignment(.center)
                Text("FlashScope safely analyzes its connection, performance, filesystem, integrity, and available health signals.")
                    .font(FlashScopeTheme.body)
                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 470)
            }

            Button {
                Task { await model.refresh() }
            } label: {
                Label(model.isRefreshing ? "Refreshing…" : "Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(FlashScopePrimaryButtonStyle())
            .disabled(model.isRefreshing)
            .accessibilityIdentifier("empty-refresh-button")

            Label("FlashScope never formats or repairs drives automatically", systemImage: "lock.shield.fill")
                .font(FlashScopeTheme.supporting)
                .foregroundStyle(FlashScopeTheme.foregroundSecondary)
        }
        .padding(44)
        .frame(maxWidth: 680)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("empty-state")
    }

    private var selectDriveState: some View {
        VStack(spacing: 14) {
            Image(systemName: "externaldrive.badge.questionmark")
                .font(.system(size: 42))
                .foregroundStyle(FlashScopeTheme.accent)
                .accessibilityHidden(true)
            Text("Select a USB drive")
                .font(.title2.weight(.semibold))
            Text("Choose a removable storage device from the sidebar to see its diagnostic overview.")
                .font(FlashScopeTheme.body)
                .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .flashScopeSurface(emphasized: true)
        .padding(32)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button { Task { await model.refresh() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                .disabled(model.isRefreshing)
                .help("Refresh removable USB drives")
                .accessibilityIdentifier("refresh-button")

            if model.isBenchmarking {
                Button(role: .cancel) { model.cancelBenchmark() } label: { Label("Cancel Test", systemImage: "stop.circle") }
                    .accessibilityIdentifier("cancel-benchmark-button")
            } else {
                Button { showHealthCheck = true } label: { Label("Run Check", systemImage: "stethoscope") }
                    .disabled(model.suggestedBenchmarkConfiguration() == nil)
                    .help("Choose Quick, Standard, Deep, or Capacity Integrity diagnostics")
                    .accessibilityIdentifier("health-check-button")
            }

            Menu {
                Button("PDF Evidence Report…") { export(.pdf) }
                Button("JSON Diagnostic Report…") { export(.json) }
                Button("Text Evidence Certificate…") { export(.text) }
                Divider()
                Button("Copy Support Certificate") { copySummary() }
                if model.preferences.anonymousIntelligenceOptIn {
                    Button("Copy Anonymous Baseline Contribution") { copyAnonymousContribution() }
                }
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .disabled(model.currentSession() == nil)
            .accessibilityIdentifier("export-menu")

            Button { Task { await model.safeEjectSelectedDrive() } } label: { Label("Eject", systemImage: "eject") }
                .disabled(model.selectedDrive == nil || model.isBenchmarking)
                .help("Safely eject the selected drive")

            SettingsLink { Label("Settings", systemImage: "gearshape") }
            Button { showHelp = true } label: { Label("Help", systemImage: "questionmark.circle") }
        }
    }

    private func export(_ format: ReportExportController.Format) {
        guard let session = model.currentSession() else { return }
        do { try ReportExportController.export(session: session, format: format, reports: model.services.reports, redactIdentifiers: model.preferences.redactIdentifiers) }
        catch { model.notice = .init(title: "Export failed", message: error.localizedDescription) }
    }

    private func copySummary() {
        guard let session = model.currentSession() else { return }
        ReportExportController.copySupportSummary(session: session, reports: model.services.reports, redactIdentifiers: model.preferences.redactIdentifiers)
        model.notice = .init(title: "Support certificate copied", message: "A redacted plain-text diagnostic evidence certificate is on the clipboard.")
    }

    private func copyAnonymousContribution() {
        guard let session = model.currentSession() else { return }
        do {
            try ReportExportController.copyAnonymousContribution(session: session)
            model.notice = .init(title: "Anonymous contribution copied", message: "The privacy-minimized baseline payload is on the clipboard. FlashScope did not upload it anywhere.")
        } catch {
            model.notice = .init(title: "Couldn’t prepare contribution", message: error.localizedDescription)
        }
    }
}
