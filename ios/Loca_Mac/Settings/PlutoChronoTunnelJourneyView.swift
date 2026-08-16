import SwiftUI

// MARK: - PlutoChronoTunnelJourneyView (Demo 2: The Cosmic Chrono-Tunnel Vertical Timeline)

/// Visually stunning vertical cosmic timeline showcasing the journey of PLUTO OS
/// from v1.0 Genesis to v5.0 Sovereign OS.
struct PlutoChronoTunnelJourneyView: View {

    @State private var hoveredNodeIndex: Int? = nil

    struct ChronoMilestone: Identifiable {
        let id: Int
        let version: String
        let codename: String
        let title: String
        let icon: String
        let accent: Color
        let problemSolved: String
        let breakthrough: String
        let telemetryBadges: [String]
        let architectureDossier: String
    }

    private let milestones: [ChronoMilestone] = [
        ChronoMilestone(
            id: 0,
            version: "v1.0",
            codename: "Genesis Era",
            title: "The Immutable Local-First Habit Grid",
            icon: "flame.fill",
            accent: Color(red: 0.95, green: 0.77, blue: 0.25),
            problemSolved: "SaaS habit trackers relied on remote servers, causing 300ms network latency and monthly subscription paywalls for basic habit heatmaps.",
            breakthrough: "Sub-millisecond local SQLite writes via SwiftData with zero cloud tracking and tactile Force Touch completions.",
            telemetryBadges: ["< 0.2ms Latency", "100% Offline", "Zero Telemetry"],
            architectureDossier: "Engineered single-table SwiftData schema with cached streak properties, avoiding O(n) history walks on every render."
        ),
        ChronoMilestone(
            id: 1,
            version: "v2.0",
            codename: "Tactical Matrix Era",
            title: "Eisenhower Quadrants & Focus Sprints",
            icon: "bolt.horizontal.fill",
            accent: Color(red: 0.85, green: 0.40, blue: 0.40),
            problemSolved: "Traditional to-do apps were passive infinite lists where tasks went to die without urgent vs important prioritization.",
            breakthrough: "Integrated 4-Quadrant Eisenhower Decision Cockpit and 1-click teleportation to 25-minute Pomodoro focus timers.",
            telemetryBadges: ["1-Click Triage", "25m Sprint Engine", "⌥+Space Capture"],
            architectureDossier: "Created unified `TodoItem` state pipeline with instant keyboard completion triggers and HUD quick-capture buffer."
        ),
        ChronoMilestone(
            id: 2,
            version: "v3.0",
            codename: "Sovereign Sanctum Era",
            title: "Apple Secure Enclave Biometric Encryption",
            icon: "lock.shield.fill",
            accent: Color(red: 0.75, green: 0.55, blue: 0.95),
            problemSolved: "Private thoughts and daily reflections in modern apps are stored in unencrypted third-party clouds vulnerable to breaches.",
            breakthrough: "Hardware-level Touch ID / Face ID auto-lock that encrypts private reflections and Life Blueprints locally.",
            telemetryBadges: ["Secure Enclave AES-256", "Auto-Lock on Sleep", "Local Vault"],
            architectureDossier: "Integrated `LAContext` biometric evaluation with zero external network calls; thoughts never leave device memory."
        ),
        ChronoMilestone(
            id: 3,
            version: "v4.0",
            codename: "Alpine Odyssey Era",
            title: "3D Himalayan Topography & Digital Passports",
            icon: "mountain.2.fill",
            accent: Color(red: 0.30, green: 0.85, blue: 0.80),
            problemSolved: "Productivity apps divorced digital goals from physical real-world endurance, outdoor mountaineering, and grit.",
            breakthrough: "3D interactive MapKit elevation terrain, GPS altitude telemetry, and gold-embossed digital expedition passports for Sacred Indian peaks.",
            telemetryBadges: ["3D MapKit Elevation", "6,816m Nanda Devi", "Apple Watch Sync"],
            architectureDossier: "Rendered realistic altitude topography for Kedarkantha, Roopkund, and Nanda Devi with 7-tier Mountaineer ranks."
        ),
        ChronoMilestone(
            id: 4,
            version: "v5.0",
            codename: "Sovereign OS Monolith",
            title: "The 4-Pillar Master Architecture & Acoustic Soul",
            icon: "crown.fill",
            accent: Color(red: 0.95, green: 0.80, blue: 0.30),
            problemSolved: "Complex applications force users through dozens of nested menus. Elon Musk's principle: The lowest clicks to get highest value.",
            breakthrough: "Sculpted and pruned the entire OS into 4 pure Executive Pillars (Today, Work, Journal, Life) powered by native acoustic mechanical sound.",
            telemetryBadges: ["4 Executive Pillars (⌘1-⌘4)", "Native Acoustic Audio", "Bento Grid Studio"],
            architectureDossier: "Ruthlessly pruned GitHub & redundant sidebars. Unified Pomodoro into Today, Habits into Today's Log, and Treks into Life."
        )
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // Cosmic Header
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(red: 0.95, green: 0.77, blue: 0.25))
                            .frame(width: 8, height: 8)
                        Text("CHRONO-TUNNEL TIMELINE")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Color(red: 0.95, green: 0.77, blue: 0.25))
                    }

                    Text("The Evolution of Pluto OS")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)

                    Text("From a minimal local SQLite habit grid to an uncompromised 4-Pillar Executive Operating System.")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 580)
                }
                .padding(.top, 24)
                .padding(.bottom, 32)

                // Vertical Timeline Flow
                ZStack(alignment: .top) {

                    // Luminous Central Vertical Fiber-Optic Line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.77, blue: 0.25),
                                    Color(red: 0.85, green: 0.40, blue: 0.40),
                                    Color(red: 0.75, green: 0.55, blue: 0.95),
                                    Color(red: 0.30, green: 0.85, blue: 0.80),
                                    Color(red: 0.95, green: 0.80, blue: 0.30)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 3)
                        .padding(.vertical, 30)

                    // Milestone Nodes Stack
                    VStack(spacing: 40) {
                        ForEach(milestones) { milestone in
                            chronoMilestoneRow(milestone: milestone)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
            .frame(maxWidth: 860)
        }
    }

    // MARK: - Milestone Row (Alternating Left / Right)
    private func chronoMilestoneRow(milestone: ChronoMilestone) -> some View {
        let isEven = milestone.id % 2 == 0
        let isHovered = hoveredNodeIndex == milestone.id

        return HStack(alignment: .top, spacing: 20) {

            // Left side
            if isEven {
                milestoneCard(milestone: milestone, isHovered: isHovered)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Spacer()
                    .frame(maxWidth: .infinity)
            }

            // Center Node Badge
            VStack(spacing: 4) {
                Button {
                    PlutoSoundEngine.shared.play(.checkmark)
                    Haptics.impact(.medium)
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.10, green: 0.10, blue: 0.14))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(milestone.accent, lineWidth: isHovered ? 3 : 2)
                            )
                            .shadow(color: milestone.accent.opacity(isHovered ? 0.6 : 0.25), radius: isHovered ? 12 : 6)

                        Image(systemName: milestone.icon)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(milestone.accent)
                    }
                }
                .buttonStyle(.plain)
                .onHover { h in
                    hoveredNodeIndex = h ? milestone.id : nil
                }

                Text(milestone.version)
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(milestone.accent)
            }
            .frame(width: 60)

            // Right side
            if !isEven {
                milestoneCard(milestone: milestone, isHovered: isHovered)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer()
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Milestone Dossier Card
    private func milestoneCard(milestone: ChronoMilestone, isHovered: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            // Header
            HStack(spacing: 8) {
                Text(milestone.codename.uppercased())
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(milestone.accent.opacity(0.18))
                    .foregroundStyle(milestone.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Spacer()
            }

            Text(milestone.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(DS.Color.textPrimary)

            // The Problem vs Breakthrough
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 6) {
                    Text("❌")
                        .font(.system(size: 11))
                    Text(milestone.problemSolved)
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Color.textSecondary)
                }

                HStack(alignment: .top, spacing: 6) {
                    Text("✨")
                        .font(.system(size: 11))
                    Text(milestone.breakthrough)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                }
            }
            .padding(10)
            .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))

            // Architecture Dossier
            Text(milestone.architectureDossier)
                .font(.system(size: 11))
                .foregroundStyle(DS.Color.textTertiary)
                .lineSpacing(3)

            // Telemetry Badges
            HStack(spacing: 6) {
                ForEach(milestone.telemetryBadges, id: \.self) { badge in
                    Text(badge)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(DS.Color.surface)
                        .foregroundStyle(milestone.accent)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.10, green: 0.10, blue: 0.13).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(milestone.accent.opacity(isHovered ? 0.6 : 0.2), lineWidth: isHovered ? 1.5 : 1)
                )
                .shadow(color: milestone.accent.opacity(isHovered ? 0.2 : 0.05), radius: 12)
        )
    }
}
