import SwiftUI

// MARK: - PlutoKeynoteJourneyModal (The Apple Keynote Holographic Stage v1.0 -> v5.0)

/// Visually stunning Apple Keynote 3D Stage showcasing the evolutionary journey of PLUTO OS
/// from v1.0 Genesis to v5.0 Sovereign OS.
struct PlutoKeynoteJourneyModal: View {

    @Environment(\.dismiss) private var dismiss
    @State private var activeIndex: Int = 4 // Start at v5.0 Sovereign OS
    @State private var isHoveringNext = false
    @State private var isHoveringPrev = false

    // MARK: - Era Blueprint Data
    struct EraBlueprint: Identifiable {
        let id: Int
        let version: String
        let codename: String
        let tagline: String
        let icon: String
        let accentColor: Color
        let story: String
        let breakthrough: String
        let metricTitle: String
        let metricValue: String
        let pillars: [String]
        let graphicType: GraphicType
    }

    enum GraphicType {
        case habitGrid
        case eisenhowerMatrix
        case biometricVault
        case mountainAtlas
        case sovereignFourPillars
    }

    private let eras: [EraBlueprint] = [
        EraBlueprint(
            id: 0,
            version: "v1.0",
            codename: "Genesis",
            tagline: "The Offline Spark & Immutable Heatmap",
            icon: "flame.fill",
            accentColor: Color(red: 0.95, green: 0.77, blue: 0.25),
            story: "Born from a refusal to accept cloud subscriptions, tracking telemetry, and sluggish web wrappers. Built as an ultra-fast, local-first SwiftData SQLite habit grid with instant tactile check-ins.",
            breakthrough: "Local SQLite engine with sub-millisecond writes and zero server dependence.",
            metricTitle: "Write Latency",
            metricValue: "< 0.2ms",
            pillars: ["Habits", "Heatmaps", "Local DB"],
            graphicType: .habitGrid
        ),
        EraBlueprint(
            id: 1,
            version: "v2.0",
            codename: "Tactical Matrix",
            tagline: "High-Velocity Eisenhower Cockpit",
            icon: "bolt.horizontal.fill",
            accentColor: Color(red: 0.85, green: 0.40, blue: 0.40),
            story: "To-do lists were passive graveyards. Version 2.0 introduced the 4-Quadrant Eisenhower Decision Matrix, instant global quick-capture, and integrated 25-minute Pomodoro focus sprints.",
            breakthrough: "1-Click Direct Teleportation between priority triage and active focus sprints.",
            metricTitle: "Focus Velocity",
            metricValue: "25m Sprints",
            pillars: ["Eisenhower", "Focus Timers", "Global Capture"],
            graphicType: .eisenhowerMatrix
        ),
        EraBlueprint(
            id: 2,
            version: "v3.0",
            codename: "Sovereign Sanctum",
            tagline: "Hardware Biometric Vault & Reflection Ledger",
            icon: "lock.shield.fill",
            accentColor: Color(red: 0.75, green: 0.55, blue: 0.95),
            story: "Your innermost strategic thoughts, life principles, and evening reflections demanded physical hardware encryption. Integrated Apple Secure Enclave Touch ID / Face ID biometric lock.",
            breakthrough: "Biometric hardware auto-lock when away, ensuring total privacy.",
            metricTitle: "Encryption",
            metricValue: "Secure Enclave",
            pillars: ["Touch ID Vault", "Evening Logs", "Life Blueprint"],
            graphicType: .biometricVault
        ),
        EraBlueprint(
            id: 3,
            version: "v4.0",
            codename: "Alpine Odyssey",
            tagline: "3D Himalayan Elevation & Digital Passports",
            icon: "mountain.2.fill",
            accentColor: Color(red: 0.30, green: 0.85, blue: 0.80),
            story: "Discipline extends beyond screens into high-altitude physical summits. Integrated interactive 3D MapKit elevation terrain, GPS altitude telemetry, and gold-embossed expedition passports for Sacred Indian peaks.",
            breakthrough: "Interactive 3D topographic mountain exploration with Apple Watch elevation sync.",
            metricTitle: "Peak Elevation",
            metricValue: "6,816m Nanda Devi",
            pillars: ["3D Trek Atlas", "Passports", "Trophy Cabinet"],
            graphicType: .mountainAtlas
        ),
        EraBlueprint(
            id: 4,
            version: "v5.0",
            codename: "Sovereign OS",
            tagline: "The 4-Pillar Master Monolith & Acoustic Soul",
            icon: "crown.fill",
            accentColor: Color(red: 0.95, green: 0.80, blue: 0.30),
            story: "The culmination of post-pruning architecture. Ruthlessly eliminating bloat into 4 uncompromised Executive Pillars: Today, Work, Journal, and Life. Completed with native acoustic mechanical audio feedback.",
            breakthrough: "4-Pillar master architecture with native mechanical audio and Bento Grid controls.",
            metricTitle: "Executive Pillars",
            metricValue: "⌘1 to ⌘4",
            pillars: ["☀️ Today", "💼 Work", "📖 Journal", "🏔️ Life"],
            graphicType: .sovereignFourPillars
        )
    ]

    private var currentEra: EraBlueprint {
        eras[activeIndex]
    }

    var body: some View {
        ZStack {
            // Cinematic Stage Void Background
            Color(red: 0.05, green: 0.05, blue: 0.07)
                .ignoresSafeArea()

            // Dynamic Ambient Spotlight Glow
            RadialGradient(
                colors: [currentEra.accentColor.opacity(0.18), Color.clear],
                center: .center,
                startRadius: 50,
                endRadius: 550
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: activeIndex)

            VStack(spacing: 0) {

                // Top Header Bar
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(currentEra.accentColor)

                        Text("PLUTO EVOLUTIONARY ODYSSEY")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundStyle(DS.Color.textSecondary)
                    }

                    Spacer()

                    // Close Button
                    Button {
                        PlutoSoundEngine.shared.play(.tabSwitch)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                .padding(.bottom, 12)

                Spacer(minLength: 10)

                // Central Keynote Holographic Card
                HStack(spacing: 24) {

                    // Prev Arrow
                    Button {
                        navigate(direction: -1)
                    } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(activeIndex > 0 ? DS.Color.textSecondary : DS.Color.textTertiary.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .disabled(activeIndex == 0)

                    // Active 3D Holographic Stage Card
                    keynoteStageCard
                        .frame(maxWidth: 780, maxHeight: 460)

                    // Next Arrow
                    Button {
                        navigate(direction: 1)
                    } label: {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(activeIndex < eras.count - 1 ? DS.Color.textSecondary : DS.Color.textTertiary.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .disabled(activeIndex == eras.count - 1)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 10)

                // Bottom Timeline Scrubber & Version Badges
                bottomTimelineControls
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
            }
        }
        .frame(minWidth: 920, minHeight: 620)
    }

    // MARK: - Keynote Stage Card
    private var keynoteStageCard: some View {
        HStack(spacing: 0) {

            // Left Narrative Column
            VStack(alignment: .leading, spacing: 14) {

                // Era Version Pill + Codename
                HStack(spacing: 10) {
                    Text(currentEra.version)
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(currentEra.accentColor)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text(currentEra.codename.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(currentEra.accentColor)

                    Spacer()
                }

                // Title Tagline
                Text(currentEra.tagline)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(2)

                // Narrative Story
                Text(currentEra.story)
                    .font(.system(size: 13))
                    .foregroundStyle(DS.Color.textSecondary)
                    .lineSpacing(4)

                Divider()

                // Breakthrough Callout
                VStack(alignment: .leading, spacing: 4) {
                    Text("ARCHITECTURAL BREAKTHROUGH")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(DS.Color.textTertiary)

                    Text(currentEra.breakthrough)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DS.Color.textPrimary)
                }

                Spacer()

                // Pillars and Telemetry
                HStack(spacing: 16) {
                    // Metric Pill
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentEra.metricTitle.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(DS.Color.textTertiary)
                        Text(currentEra.metricValue)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(currentEra.accentColor)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))

                    // Pillars List
                    HStack(spacing: 6) {
                        ForEach(currentEra.pillars, id: \.self) { pill in
                            Text(pill)
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(currentEra.accentColor.opacity(0.12))
                                .foregroundStyle(currentEra.accentColor)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 440)

            Divider()

            // Right Graphic Showcase Canvas
            ZStack {
                Color.black.opacity(0.3)

                graphicShowcase(for: currentEra.graphicType, accent: currentEra.accentColor)
                    .padding(24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.10, green: 0.10, blue: 0.13).opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(currentEra.accentColor.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: currentEra.accentColor.opacity(0.15), radius: 24, x: 0, y: 12)
        )
    }

    // MARK: - Graphic Showcases
    @ViewBuilder
    private func graphicShowcase(for type: GraphicType, accent: Color) -> some View {
        switch type {
        case .habitGrid:
            // v1.0 Graphic: Minimalist Habit Heatmap
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(accent)
                    Text("Daily Momentum Heatmap")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                }

                // Grid of active cells
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                    ForEach(0..<28, id: \.self) { idx in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(idx % 3 != 0 ? accent.opacity(Double(idx % 4 + 1) * 0.22) : DS.Color.surface)
                            .frame(height: 24)
                    }
                }

                HStack {
                    Text("Current Streak: 24 Days")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(accent)
                    Spacer()
                    Text("Local SQLite ✓")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(DS.Color.textTertiary)
                }
            }
            .padding(16)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 10))

        case .eisenhowerMatrix:
            // v2.0 Graphic: 4-Quadrant Eisenhower Matrix
            VStack(spacing: 8) {
                Text("Eisenhower Priority Quadrants")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DS.Color.textPrimary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    quadrantPill(title: "1. DO NOW (Urgent)", icon: "exclamationmark.3", color: accent)
                    quadrantPill(title: "2. SCHEDULE (Strategic)", icon: "calendar.badge.clock", color: .blue)
                    quadrantPill(title: "3. DELEGATE (Quick)", icon: "person.2", color: .orange)
                    quadrantPill(title: "4. ELIMINATE (Prune)", icon: "trash", color: .gray)
                }

                HStack {
                    Image(systemName: "timer")
                        .foregroundStyle(accent)
                    Text("Instant 25m Focus Sprint Mode Active")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.Color.textSecondary)
                }
                .padding(.top, 4)
            }

        case .biometricVault:
            // v3.0 Graphic: Touch ID Hardware Vault
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(accent.opacity(0.3), lineWidth: 3)
                        .frame(width: 80, height: 80)

                    Circle()
                        .fill(accent.opacity(0.12))
                        .frame(width: 70, height: 70)

                    Image(systemName: "touchid")
                        .font(.system(size: 38))
                        .foregroundStyle(accent)
                }

                Text("Secure Enclave AES-256")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(DS.Color.textPrimary)

                Text("Private Journal reflections & Life Principles locked to hardware biometric key.")
                    .font(.system(size: 11))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DS.Color.textSecondary)
            }

        case .mountainAtlas:
            // v4.0 Graphic: 3D Mountain Peak Atlas
            VStack(spacing: 12) {
                ZStack {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accent, Color.teal],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                VStack(spacing: 2) {
                    Text("Kedarkantha & Nanda Devi")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("3D MapKit Topographic Elevation Profiles")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Color.textTertiary)
                }

                HStack(spacing: 8) {
                    Label("GPS Altimeter", systemImage: "location.north.circle.fill")
                    Label("Gold Passport Stamped", systemImage: "rosette")
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(accent)
            }

        case .sovereignFourPillars:
            // v5.0 Graphic: The 4-Pillar Master Architecture
            VStack(spacing: 14) {
                Text("The 4-Pillar Master Architecture")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(DS.Color.textPrimary)

                HStack(spacing: 10) {
                    pillarBox(shortcut: "⌘1", name: "Today", icon: "sun.max.fill", color: Color(red: 0.95, green: 0.77, blue: 0.25))
                    pillarBox(shortcut: "⌘2", name: "Work", icon: "briefcase.fill", color: Color(red: 0.35, green: 0.65, blue: 0.95))
                    pillarBox(shortcut: "⌘3", name: "Journal", icon: "book.closed.fill", color: Color(red: 0.75, green: 0.55, blue: 0.95))
                    pillarBox(shortcut: "⌘4", name: "Life", icon: "mountain.2.fill", color: Color(red: 0.30, green: 0.85, blue: 0.80))
                }

                HStack(spacing: 6) {
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundStyle(accent)
                    Text("Native Acoustic Mechanical Sound Engine Active")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
        }
    }

    private func quadrantPill(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(DS.Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.3), lineWidth: 1))
    }

    private func pillarBox(shortcut: String, name: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(name)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(DS.Color.textPrimary)
            Text(shortcut)
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 4))
                .foregroundStyle(color)
        }
        .frame(width: 64, height: 74)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Bottom Timeline Controls
    private var bottomTimelineControls: some View {
        HStack(spacing: 12) {
            ForEach(0..<eras.count, id: \.self) { idx in
                let era = eras[idx]
                let isSelected = activeIndex == idx

                Button {
                    activeIndex = idx
                    PlutoSoundEngine.shared.play(.checkmark)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: era.icon)
                            .font(.system(size: 10))
                        Text(era.version)
                            .font(.system(size: 11, weight: isSelected ? .heavy : .medium, design: .monospaced))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isSelected ? era.accentColor : DS.Color.surface)
                    .foregroundStyle(isSelected ? .black : DS.Color.textSecondary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(isSelected ? Color.clear : DS.Color.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func navigate(direction: Int) {
        let newIndex = activeIndex + direction
        if newIndex >= 0 && newIndex < eras.count {
            activeIndex = newIndex
            if newIndex == eras.count - 1 {
                PlutoSoundEngine.shared.play(.summitPassport)
            } else {
                PlutoSoundEngine.shared.play(.tabSwitch)
            }
        }
    }
}
