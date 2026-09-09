import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            FlashScopeBackground()

            VStack(spacing: 0) {
                HStack(spacing: 13) {
                    Image(systemName: "lifepreserver.fill")
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(FlashScopeTheme.accent)
                        .frame(width: 48, height: 48)
                        .background(FlashScopeTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FlashScope Help")
                            .font(.title2.weight(.bold))
                        Text("Understand the verdict, evidence, and safe next steps")
                            .font(FlashScopeTheme.supporting)
                            .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                    }
                    Spacer()
                    Button("Done") { dismiss() }.keyboardShortcut(.cancelAction)
                }
                .padding(20)

                Divider().opacity(0.18)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 14)], spacing: 14) {
                        helpSection("Start with the verdict", icon: "waveform.path.ecg.rectangle", "Overview leads with the likely cause, confidence, media/connection/filesystem/performance dimensions, evidence coverage, and safest next step before technical detail.")
                        helpSection("Diagnostic profiles", icon: "slider.horizontal.3", "Quick is a short first pass. Standard is balanced. Deep writes more data to expose sustained slowdowns. Capacity Integrity verifies the largest safe free-space sample without touching occupied data.")
                        helpSection("Connection-path diagnosis", icon: "cable.connector", "FlashScope separates declared USB capability from the current negotiated link and visualizes Mac → hub/adapter → link → drive before blaming flash media.")
                        helpSection("Fix and retest", icon: "arrow.triangle.2.circlepath", "Change one variable—such as removing a hub, freeing space, or changing ports—then rerun the same profile. Device Timeline makes improvement or regression visible.")
                        helpSection("Cache cliff & stability", icon: "waveform.path", "FlashScope analyzes sustained samples for large burst-to-tail drops, stalls, variation, and I/O errors instead of reporting one misleading peak number.")
                        helpSection("Workload fit", icon: "briefcase", "Choose general storage, photos/documents, large video, backup, small files, or developer projects. Suitability guidance is practical context, not a guarantee for a specific application.")
                        helpSection("Community intelligence privacy", icon: "person.3.sequence.fill", "The optional baseline setting does not upload anything in this build. It only prepares a privacy-minimized payload that excludes filenames, clear serial numbers, directory listings, and user paths.")
                        helpSection("Technician mode", icon: "wrench.and.screwdriver", "Technician mode exposes raw evidence, coverage, local history context, and conservative PASS/REVIEW/FAIL triage. It is not a warranty or future-reliability certification.")
                        helpSection("Data safety", icon: "lock.shield.fill", "Inspection is read-only. Benchmarks start only after confirmation, use an app-owned temporary workspace, verify identity before cleanup, and never format, repartition, repair, force-unmount, or raw-write a disk.")
                        helpSection("Filesystem verification", icon: "checkmark.shield", "Verification is separate from repair. FlashScope asks before a normal unmount, never force-unmounts, runs only allowlisted verification, and reports an inability to run as inconclusive rather than corruption.")
                        helpSection("SMART & USB bridges", icon: "memorychip", "Many flash drives and bridges do not expose SMART. Missing SMART lowers evidence coverage; it is not interpreted as device failure.")
                        helpSection("Benchmarks & caches", icon: "speedometer", "Write throughput includes durable synchronization. Standard reads are file-level and may be influenced by macOS caching, so FlashScope does not label them raw-media performance.")
                        helpSection("Backups", icon: "externaldrive.badge.timemachine", "Diagnostics reduce uncertainty but cannot guarantee future reliability. Keep independent backups, especially after integrity mismatches, repeated I/O errors, or filesystem problems.")
                    }
                    .padding(20)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 640)
    }

    private func helpSection(_ title: String, icon: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(FlashScopeTheme.accent)
                    .frame(width: 24, height: 24)
                    .background(FlashScopeTheme.accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 7))
                    .accessibilityHidden(true)
                Text(title).font(.headline)
            }
            Text(text)
                .font(FlashScopeTheme.supporting)
                .foregroundStyle(FlashScopeTheme.foregroundSecondary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 125, alignment: .topLeading)
        .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 15))
        .overlay { RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.06), lineWidth: 1) }
    }
}
