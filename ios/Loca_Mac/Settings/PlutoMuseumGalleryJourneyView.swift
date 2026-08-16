import SwiftUI

// MARK: - PlutoMuseumGalleryJourneyView (Demo 3: Cupertino Design Museum & Philosophy Gallery)

/// Museum-grade interactive design gallery showcasing the evolutionary philosophy of PLUTO OS
/// from v1.0 Genesis to v5.0 Sovereign OS, featuring Before/After architecture comparators
/// and Steve Jobs / Elon Musk design principles.
struct PlutoMuseumGalleryJourneyView: View {

    @State private var selectedWingIndex: Int = 4 // Default to Wing 5 (v5.0 Masterwork)
    @State private var beforeAfterRatio: Double = 0.5 // 0.0 = Bloat, 1.0 = Pluto Pure
    @State private var isComparingMode: Bool = false

    struct MuseumWing: Identifiable {
        let id: Int
        let version: String
        let wingTitle: String
        let artifactName: String
        let icon: String
        let accent: Color
        let philosophyQuote: String
        let quoteAuthor: String
        let curationNotes: String
        let technicalSculpting: String
        let architecturalSpecs: [(label: String, value: String)]
    }

    private let wings: [MuseumWing] = [
        MuseumWing(
            id: 0,
            version: "v1.0",
            wingTitle: "Wing I · The Offline Foundation",
            artifactName: "The Local SQLite Genesis Board",
            icon: "flame.fill",
            accent: Color(red: 0.95, green: 0.77, blue: 0.25),
            philosophyQuote: "“Details matter, it's worth waiting to get it right.”",
            quoteAuthor: "Steve Jobs",
            curationNotes: "The foundational realization: Web-based wrappers and remote databases ruin daily momentum with spinning loaders. Software should feel like an immutable, physical wooden desk.",
            technicalSculpting: "Replaced HTTP API requests with local SwiftData SQLite containers, dropping log latency from 450ms down to 0.18ms.",
            architecturalSpecs: [
                ("Storage Engine", "Local SwiftData SQLite"),
                ("Network Overhead", "0.0 KB (Offline First)"),
                ("Streak Walk", "Cached O(1) Updates")
            ]
        ),
        MuseumWing(
            id: 1,
            version: "v2.0",
            wingTitle: "Wing II · Velocity & Focus",
            artifactName: "The Eisenhower Decision Cockpit",
            icon: "bolt.horizontal.fill",
            accent: Color(red: 0.85, green: 0.40, blue: 0.40),
            philosophyQuote: "“Deciding what not to do is as important as deciding what to do.”",
            quoteAuthor: "Steve Jobs",
            curationNotes: "Linear to-do lists create psychological debt. version 2.0 introduced visual triage: separating the urgent from the truly important, instantly convertible into 25m sprint sessions.",
            technicalSculpting: "Constructed dual-pane Eisenhower triage board linked directly to hardware Pomodoro timer cycles.",
            architecturalSpecs: [
                ("Triage Matrix", "4-Quadrant Split"),
                ("Focus Interval", "25m Sprint / 5m Break"),
                ("Capture Latency", "1 Keyboard Stroke (⌥Space)")
            ]
        ),
        MuseumWing(
            id: 2,
            version: "v3.0",
            wingTitle: "Wing III · Biometric Sovereignty",
            artifactName: "The Secure Enclave Reflection Sanctum",
            icon: "lock.shield.fill",
            accent: Color(red: 0.75, green: 0.55, blue: 0.95),
            philosophyQuote: "“Privacy is not an option, and it shouldn't be the price we accept for just using the Internet.”",
            quoteAuthor: "Apple Engineering Principle",
            curationNotes: "A man's private journal and 10-year life blueprint should never be stored in an AI company's cloud database. Version 3.0 brought Apple hardware biometric encryption.",
            technicalSculpting: "Integrated Apple LocalAuthentication `LAContext` over Journal and Life Blueprint with zero cloud telemetry.",
            architecturalSpecs: [
                ("Hardware Lock", "Apple Secure Enclave Touch ID"),
                ("Auto-Lock Window", "5m Background Resign"),
                ("Cloud Exposure", "Zero Third-Party APIs")
            ]
        ),
        MuseumWing(
            id: 3,
            version: "v4.0",
            wingTitle: "Wing IV · High-Altitude Odyssey",
            artifactName: "The 3D Himalayan Topographic Atlas",
            icon: "mountain.2.fill",
            accent: Color(red: 0.30, green: 0.85, blue: 0.80),
            philosophyQuote: "“The mountains are calling and I must go.”",
            quoteAuthor: "John Muir",
            curationNotes: "Daily digital discipline is meaningless if you have no real-world vitality. Version 4.0 brought high-altitude mountaineering telemetry, MapKit 3D elevation terrains, and gold passports.",
            technicalSculpting: "Implemented 3D MapKit terrain mesh with elevation coordinates for Kedarkantha, Roopkund, and Nanda Devi.",
            architecturalSpecs: [
                ("Elevation Telemetry", "Up to 6,816m (Nanda Devi)"),
                ("Passport Format", "National Geographic Gold Foil"),
                ("Ranks Engine", "7-Tier Mountaineer Progression")
            ]
        ),
        MuseumWing(
            id: 4,
            version: "v5.0",
            wingTitle: "Wing V · The Sovereign Monolith",
            artifactName: "The 4-Pillar Executive Architecture",
            icon: "crown.fill",
            accent: Color(red: 0.95, green: 0.80, blue: 0.30),
            philosophyQuote: "“The best part is no part. The best process is no process. It weighs nothing, costs nothing, can't go wrong.”",
            quoteAuthor: "Elon Musk & Steve Jobs",
            curationNotes: "The ultimate triumph of post-pruning. We ripped apart 12 nested menus, eliminated GitHub bloat, merged Pomodoro into Today, Habits into Today's Log, and Treks into Life. 4 Pure Pillars remain.",
            technicalSculpting: "Consolidated entire navigation to 4 executive shortcuts (⌘1 Today, ⌘2 Work, ⌘3 Journal, ⌘4 Life) with acoustic sound.",
            architecturalSpecs: [
                ("Executive Pillars", "4 Pure Domains (⌘1 - ⌘4)"),
                ("Acoustic Engine", "Native Mechanical Sounds"),
                ("Settings System", "Bento Grid Horizon")
            ]
        )
    ]

    private var activeWing: MuseumWing {
        wings[selectedWingIndex]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // Gallery Header & Philosophy Banner
                galleryHeaderBanner

                // Interactive Before vs After Comparator
                beforeAfterArchitecturalComparator

                // Museum Exhibition Wings Navigation
                wingsGallerySelector

                // Active Exhibition Placard
                activeExhibitionPlacard

                Spacer(minLength: 40)
            }
            .padding(32)
            .frame(maxWidth: 900)
        }
    }

    // MARK: - Gallery Header Banner
    private var galleryHeaderBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30))

                Text("CUPERTINO DESIGN MUSEUM · EXHIBITION")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30))

                Spacer()
            }

            Text("The Art of Post-Pruning Architecture")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(DS.Color.textPrimary)

            Text("“Most software grows bloated over time as teams add feature upon feature. PLUTO was built on the inverse philosophy: build expansive ideas, experience them, then ruthlessly sculpt and prune until only pure value remains.”")
                .font(.system(size: 13))
                .foregroundStyle(DS.Color.textSecondary)
                .lineSpacing(4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.10, green: 0.10, blue: 0.13))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.95, green: 0.80, blue: 0.30).opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Before vs After Architectural Comparator
    private var beforeAfterArchitecturalComparator: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("THE REDUCTION PRINCIPLE (BEFORE VS. AFTER)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(DS.Color.textTertiary)
                Spacer()
                Text("Elon Musk & Steve Jobs Paradigm")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30))
            }

            HStack(spacing: 16) {

                // Before: Bloated Software (Traditional SaaS)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("❌ BEFORE (Bloated SaaS Tools)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.red.opacity(0.9))
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        comparisonPoint(icon: "xmark", text: "12+ nested sidebar menus & hidden subpages", color: .red)
                        comparisonPoint(icon: "xmark", text: "Requires cloud login, sync spinners & trackers", color: .red)
                        comparisonPoint(icon: "xmark", text: "Passive infinite to-do lists without triage", color: .red)
                        comparisonPoint(icon: "xmark", text: "No physical world vitality or endurance link", color: .red)
                        comparisonPoint(icon: "xmark", text: "Silent, lifeless web-based button clicks", color: .red)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.2), lineWidth: 1))

                // After: PLUTO Sovereign OS (Post-Pruned Masterwork)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("✨ AFTER (PLUTO Sovereign OS)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30))
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        comparisonPoint(icon: "checkmark", text: "4 Pure Pillars: ⌘1 Today, ⌘2 Work, ⌘3 Journal, ⌘4 Life", color: .green)
                        comparisonPoint(icon: "checkmark", text: "100% Local SwiftData SQLite (<0.2ms writes)", color: .green)
                        comparisonPoint(icon: "checkmark", text: "Eisenhower Decision Quadrants + 25m Focus Flow", color: .green)
                        comparisonPoint(icon: "checkmark", text: "3D Himalayan Peak Atlas & National Geo Passports", color: .green)
                        comparisonPoint(icon: "checkmark", text: "Native Acoustic Mechanical Sound & Force Haptics", color: .green)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.95, green: 0.80, blue: 0.30).opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(red: 0.95, green: 0.80, blue: 0.30).opacity(0.25), lineWidth: 1))
            }
        }
    }

    private func comparisonPoint(icon: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(DS.Color.textSecondary)
        }
    }

    // MARK: - Exhibition Wings Selector
    private var wingsGallerySelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SELECT EXHIBITION WING (v1.0 TO v5.0)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(DS.Color.textTertiary)

            HStack(spacing: 8) {
                ForEach(wings) { wing in
                    let isSelected = selectedWingIndex == wing.id

                    Button {
                        selectedWingIndex = wing.id
                        PlutoSoundEngine.shared.play(.tabSwitch)
                        Haptics.impact(.light)
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(wing.version)
                                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(isSelected ? wing.accent : DS.Color.textTertiary)
                                Spacer()
                                Image(systemName: wing.icon)
                                    .font(.system(size: 11))
                                    .foregroundStyle(isSelected ? wing.accent : DS.Color.textTertiary)
                            }
                            Text(wing.artifactName)
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? DS.Color.textPrimary : DS.Color.textSecondary)
                                .lineLimit(1)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(isSelected ? wing.accent.opacity(0.15) : DS.Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? wing.accent : DS.Color.border.opacity(0.5), lineWidth: isSelected ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Active Exhibition Placard
    private var activeExhibitionPlacard: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Placard Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(activeWing.wingTitle.uppercased())
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundStyle(activeWing.accent)

                    Text(activeWing.artifactName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                }
                Spacer()

                Button {
                    PlutoSoundEngine.shared.play(.summitPassport)
                    Haptics.impact(.medium)
                } label: {
                    Label("Curator Chime", systemImage: "speaker.wave.2.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(activeWing.accent.opacity(0.18))
                        .foregroundStyle(activeWing.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }

            // Philosophy Quote Block
            VStack(alignment: .leading, spacing: 4) {
                Text(activeWing.philosophyQuote)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .italic()
                    .foregroundStyle(DS.Color.textPrimary)
                Text("— \(activeWing.quoteAuthor)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(activeWing.accent)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))

            // Curation Narrative & Technical Details
            VStack(alignment: .leading, spacing: 8) {
                Text("CURATORIAL NOTES:")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(DS.Color.textTertiary)

                Text(activeWing.curationNotes)
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Color.textSecondary)
                    .lineSpacing(3)

                Text("ARCHITECTURAL SCULPTING:")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(DS.Color.textTertiary)
                    .padding(.top, 4)

                Text(activeWing.technicalSculpting)
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Color.textSecondary)
                    .lineSpacing(3)
            }

            Divider()

            // Architectural Specs Grid
            HStack(spacing: 24) {
                ForEach(activeWing.architecturalSpecs, id: \.label) { spec in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(spec.label.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(DS.Color.textTertiary)
                        Text(spec.value)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(activeWing.accent)
                    }
                }
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.10, green: 0.10, blue: 0.13))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(activeWing.accent.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: activeWing.accent.opacity(0.12), radius: 18)
        )
    }
}
