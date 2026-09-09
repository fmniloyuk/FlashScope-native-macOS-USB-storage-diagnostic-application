import FlashScopeCore
import SwiftUI

struct SettingsView: View {
    @Bindable var preferences: AppPreferences

    var body: some View {
        ZStack {
            FlashScopeBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    settingsHeader
                    diagnostics
                    privacy
                    technician
                    advanced
                    appearance
                }
                .padding(22)
            }
        }
        .frame(width: 640, height: 700)
        .navigationTitle("FlashScope Settings")
    }

    private var settingsHeader: some View {
        HStack(spacing: 13) {
            Image(systemName: "gearshape.2.fill")
                .font(.system(size: 25))
                .foregroundStyle(FlashScopeTheme.accent)
                .frame(width: 52, height: 52)
                .background(FlashScopeTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 15))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("Settings")
                    .font(.title2.weight(.bold))
                Text("Tune diagnostics and privacy without changing FlashScope's non-destructive safety boundary.")
                    .font(FlashScopeTheme.supporting)
                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
            }
        }
    }

    private var diagnostics: some View {
        DiagnosticCard("Diagnostics", systemImage: "stethoscope", subtitle: "Defaults for new health checks") {
            VStack(spacing: 12) {
                Picker("Default check", selection: $preferences.defaultPreset) {
                    Text("Quick — 256 MiB").tag(BenchmarkPreset.quick)
                    Text("Standard — 1 GiB").tag(BenchmarkPreset.standard)
                    Text("Deep — 4 GiB").tag(BenchmarkPreset.extended)
                }
                Picker("Typical workload", selection: $preferences.workload) {
                    ForEach(StorageWorkload.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                Toggle("Enable small-file workload by default", isOn: $preferences.includeSmallFileTest)
                HStack {
                    Text("Sample interval")
                    Slider(value: $preferences.sampleInterval, in: 0.1...2.0, step: 0.1)
                    Text(String(format: "%.1f s", preferences.sampleInterval))
                        .monospacedDigit()
                        .frame(width: 46)
                }
                Picker("Throughput units", selection: $preferences.throughputUnit) {
                    ForEach(ThroughputUnit.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
            }
        }
    }

    private var privacy: some View {
        DiagnosticCard("Privacy & History", systemImage: "lock.shield.fill", subtitle: "Local retention, redaction, and explicit opt-in intelligence controls") {
            VStack(alignment: .leading, spacing: 11) {
                Picker("History retention", selection: $preferences.historyRetention) {
                    ForEach(AppPreferences.HistoryRetention.allCases) { Text($0.title).tag($0) }
                }
                Toggle("Redact device identifiers in exports", isOn: $preferences.redactIdentifiers)
                Toggle("Check safely identifiable orphaned benchmark data on launch", isOn: $preferences.automaticCleanupChecks)
                Toggle("Prepare anonymous community-baseline contributions", isOn: $preferences.anonymousIntelligenceOptIn)
                Text("Opt-in only. This build never uploads automatically. When enabled, Export can prepare a privacy-minimized JSON contribution without filenames, directory listings, clear serial numbers, or user paths.")
                    .font(.caption)
                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
            }
        }
    }

    private var technician: some View {
        DiagnosticCard("Technician / Lab", systemImage: "wrench.and.screwdriver", subtitle: "Additional evidence context without enabling destructive actions") {
            VStack(alignment: .leading, spacing: 7) {
                Toggle("Technician mode", isOn: $preferences.technicianMode)
                Text("Adds evidence coverage, conservative lab triage, raw identifiers exposed by macOS, repeatability context, and support-certificate shortcuts.")
                    .font(.caption)
                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
            }
        }
    }

    private var advanced: some View {
        DiagnosticCard("Advanced", systemImage: "slider.horizontal.3", subtitle: "Unavailable capabilities remain disabled instead of silently escalating privileges") {
            VStack(alignment: .leading, spacing: 7) {
                Toggle("Enable raw-device read test", isOn: $preferences.advancedRawReadEnabled)
                    .disabled(!preferences.rawReadHelperAvailable)
                Text("Unavailable in this build. No privileged helper is installed and FlashScope never falls back to sudo, arbitrary commands, or raw writes. Standard file-level diagnostics remain fully usable.")
                    .font(.caption)
                    .foregroundStyle(FlashScopeTheme.foregroundSecondary)
            }
        }
    }

    private var appearance: some View {
        DiagnosticCard("Appearance", systemImage: "circle.lefthalf.filled", subtitle: "The atmospheric interface adapts semantically in both light and dark appearances") {
            Picker("Appearance", selection: $preferences.appearance) {
                ForEach(AppPreferences.Appearance.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }
}
