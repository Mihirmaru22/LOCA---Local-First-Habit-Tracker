import SwiftUI
import Foundation

// MARK: - ExplorerRank

/// Progressive mountaineering ranks unlocked based on conquered peaks and cumulative vertical gain.
enum ExplorerRank: Int, CaseIterable, Identifiable, Sendable {
    case basecampScout      = 1
    case valleyWanderer     = 2
    case ridgeRunner        = 3
    case skylinePioneer     = 4
    case verticalTitan      = 5
    case sevenSummitsLegend = 6

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .basecampScout:      return "Basecamp Scout"
        case .valleyWanderer:     return "Valley Wanderer"
        case .ridgeRunner:        return "Ridge Runner"
        case .skylinePioneer:     return "Skyline Pioneer"
        case .verticalTitan:      return "Vertical Titan"
        case .sevenSummitsLegend: return "Seven Summits Legend"
        }
    }

    var subtitle: String {
        switch self {
        case .basecampScout:      return "Taking first steps into high-altitude wilderness"
        case .valleyWanderer:     return "Building trail endurance across alpine passes"
        case .ridgeRunner:        return "Traversing steep ridgelines and summit corridors"
        case .skylinePioneer:     return "Mastering technical alpine and high-altitude climbs"
        case .verticalTitan:      return "Elite climber with massive cumulative vertical gain"
        case .sevenSummitsLegend: return "Grand mountaineer conquering the highest pinnacles on Earth"
        }
    }

    var icon: String {
        switch self {
        case .basecampScout:      return "tent.fill"
        case .valleyWanderer:     return "figure.hiking"
        case .ridgeRunner:        return "mountain.2.fill"
        case .skylinePioneer:     return "sun.horizon.fill"
        case .verticalTitan:      return "bolt.shield.fill"
        case .sevenSummitsLegend: return "crown.fill"
        }
    }

    var minSummits: Int {
        switch self {
        case .basecampScout:      return 0
        case .valleyWanderer:     return 2
        case .ridgeRunner:        return 5
        case .skylinePioneer:     return 10
        case .verticalTitan:      return 20
        case .sevenSummitsLegend: return 30
        }
    }

    var accentColor: Color {
        switch self {
        case .basecampScout:      return Color(red: 0.80, green: 0.50, blue: 0.20) // Bronze
        case .valleyWanderer:     return Color.green
        case .ridgeRunner:        return Color.cyan
        case .skylinePioneer:     return Color(red: 0.95, green: 0.75, blue: 0.15) // Gold
        case .verticalTitan:      return Color.purple
        case .sevenSummitsLegend: return Color(red: 0.90, green: 0.92, blue: 1.00) // Platinum
        }
    }
}

// MARK: - MountaineerBadge

struct MountaineerBadge: Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let category: String
    let isUnlocked: Bool
    let progress: Double
    let currentCount: Int
    let targetCount: Int
    let unlockedDate: Date?
    let tierColor: Color
    let contributingTreks: [String]

    var formattedProgress: String {
        "\(currentCount)/\(targetCount)"
    }
}

// MARK: - MountaineerRankEngine

enum MountaineerRankEngine {

    /// Calculates current user rank based on conquered treks.
    static func currentRank(conqueredTreks: [TrekRecord]) -> ExplorerRank {
        let count = conqueredTreks.count
        let totalGain = conqueredTreks.compactMap(\.elevationGainMeters).reduce(0, +)

        if count >= 30 || totalGain >= 40_000 {
            return .sevenSummitsLegend
        } else if count >= 20 || totalGain >= 25_000 {
            return .verticalTitan
        } else if count >= 10 || totalGain >= 12_000 {
            return .skylinePioneer
        } else if count >= 5 || totalGain >= 5_000 {
            return .ridgeRunner
        } else if count >= 2 {
            return .valleyWanderer
        } else {
            return .basecampScout
        }
    }

    /// Computes progress toward the next rank tier.
    static func nextRankProgress(conqueredTreks: [TrekRecord]) -> (nextRank: ExplorerRank?, progress: Double, remainingSummits: Int) {
        let current = currentRank(conqueredTreks: conqueredTreks)
        let count = conqueredTreks.count

        guard let nextIndex = ExplorerRank.allCases.firstIndex(of: current),
              nextIndex + 1 < ExplorerRank.allCases.count else {
            return (nil, 1.0, 0)
        }

        let nextRank = ExplorerRank.allCases[nextIndex + 1]
        let currentFloor = current.minSummits
        let nextTarget = nextRank.minSummits
        let range = max(1, nextTarget - currentFloor)
        let progress = min(1.0, max(0.0, Double(count - currentFloor) / Double(range)))
        let remaining = max(0, nextTarget - count)

        return (nextRank, progress, remaining)
    }

    /// Evaluates the 12 specialized expedition trophy badges.
    static func evaluateBadges(conqueredTreks: [TrekRecord], allTreks: [TrekRecord]) -> [MountaineerBadge] {
        var badges: [MountaineerBadge] = []

        // 1. 🇮🇳 Himalayan Sovereign (3+ Himalayan peaks > 3,500m)
        let himalayanTreks = conqueredTreks.filter {
            $0.country.localizedCaseInsensitiveContains("India") &&
            $0.elevationMeters >= 3500 &&
            ($0.region.localizedCaseInsensitiveContains("Himalaya") ||
             $0.region.localizedCaseInsensitiveContains("Uttarakhand") ||
             $0.region.localizedCaseInsensitiveContains("Ladakh") ||
             $0.region.localizedCaseInsensitiveContains("Sikkim") ||
             $0.region.localizedCaseInsensitiveContains("Himachal") ||
             $0.region.localizedCaseInsensitiveContains("Garhwal"))
        }
        badges.append(
            MountaineerBadge(
                id: "himalayan_sovereign",
                title: "Himalayan Sovereign",
                subtitle: "Conquer 3+ sacred Himalayan summits above 3,500m",
                icon: "mountain.2.fill",
                category: "Regional 🇮🇳",
                isUnlocked: himalayanTreks.count >= 3,
                progress: min(1.0, Double(himalayanTreks.count) / 3.0),
                currentCount: min(3, himalayanTreks.count),
                targetCount: 3,
                unlockedDate: himalayanTreks.count >= 3 ? himalayanTreks[2].dateConquered : nil,
                tierColor: Color(red: 0.95, green: 0.75, blue: 0.15), // Gold
                contributingTreks: himalayanTreks.map(\.name)
            )
        )

        // 2. ⚔️ Sahyadri Fort Champion (5+ Maratha hill forts in Maharashtra)
        let sahyadriTreks = conqueredTreks.filter {
            $0.country.localizedCaseInsensitiveContains("India") &&
            ($0.region.localizedCaseInsensitiveContains("Maharashtra") ||
             $0.region.localizedCaseInsensitiveContains("Sahyadri") ||
             $0.region.localizedCaseInsensitiveContains("Pune") ||
             $0.region.localizedCaseInsensitiveContains("Nashik") ||
             $0.region.localizedCaseInsensitiveContains("Ahmednagar"))
        }
        badges.append(
            MountaineerBadge(
                id: "sahyadri_champion",
                title: "Sahyadri Fort Champion",
                subtitle: "Conquer 5+ historic Maratha hill fort pinnacles",
                icon: "shield.checkered",
                category: "Regional 🇮🇳",
                isUnlocked: sahyadriTreks.count >= 5,
                progress: min(1.0, Double(sahyadriTreks.count) / 5.0),
                currentCount: min(5, sahyadriTreks.count),
                targetCount: 5,
                unlockedDate: sahyadriTreks.count >= 5 ? sahyadriTreks[4].dateConquered : nil,
                tierColor: Color.orange,
                contributingTreks: sahyadriTreks.map(\.name)
            )
        )

        // 3. 🌿 Western Ghats Vanguard (Summits in Maharashtra, Karnataka & Kerala)
        let hasMh = conqueredTreks.contains { $0.region.localizedCaseInsensitiveContains("Maharashtra") }
        let hasKa = conqueredTreks.contains { $0.region.localizedCaseInsensitiveContains("Karnataka") || $0.region.localizedCaseInsensitiveContains("Coorg") || $0.region.localizedCaseInsensitiveContains("Chikkamagaluru") }
        let hasKl = conqueredTreks.contains { $0.region.localizedCaseInsensitiveContains("Kerala") || $0.region.localizedCaseInsensitiveContains("Wayanad") || $0.region.localizedCaseInsensitiveContains("Munnar") }
        let statesCount = (hasMh ? 1 : 0) + (hasKa ? 1 : 0) + (hasKl ? 1 : 0)

        badges.append(
            MountaineerBadge(
                id: "western_ghats_vanguard",
                title: "Western Ghats Vanguard",
                subtitle: "Summit peaks across Maharashtra, Karnataka, and Kerala",
                icon: "leaf.fill",
                category: "Regional 🇮🇳",
                isUnlocked: statesCount >= 3,
                progress: Double(statesCount) / 3.0,
                currentCount: statesCount,
                targetCount: 3,
                unlockedDate: statesCount >= 3 ? Date() : nil,
                tierColor: Color.green,
                contributingTreks: conqueredTreks.filter {
                    $0.region.localizedCaseInsensitiveContains("Maharashtra") ||
                    $0.region.localizedCaseInsensitiveContains("Karnataka") ||
                    $0.region.localizedCaseInsensitiveContains("Kerala")
                }.map(\.name)
            )
        )

        // 4. 🏔️ 6000er High-Altitude Club (Conquer at least 1 peak > 6,000m)
        let high6000Treks = conqueredTreks.filter { $0.elevationMeters >= 6000 }
        badges.append(
            MountaineerBadge(
                id: "club_6000",
                title: "6000er High-Altitude Club",
                subtitle: "Stand atop an extreme summit above 6,000 meters",
                icon: "snowflake",
                category: "Extreme",
                isUnlocked: !high6000Treks.isEmpty,
                progress: high6000Treks.isEmpty ? 0.0 : 1.0,
                currentCount: min(1, high6000Treks.count),
                targetCount: 1,
                unlockedDate: high6000Treks.first?.dateConquered,
                tierColor: Color.cyan,
                contributingTreks: high6000Treks.map(\.name)
            )
        )

        // 5. ❄️ Ice & Snow Pioneer (Sub-zero winter expedition or frozen river)
        let iceTreks = conqueredTreks.filter {
            $0.name.localizedCaseInsensitiveContains("Chadar") ||
            $0.name.localizedCaseInsensitiveContains("Kedarkantha") ||
            $0.name.localizedCaseInsensitiveContains("Brahmatal") ||
            $0.elevationMeters >= 5000
        }
        badges.append(
            MountaineerBadge(
                id: "ice_pioneer",
                title: "Ice & Snow Pioneer",
                subtitle: "Complete a frozen river, glacial pass, or sub-zero winter climb",
                icon: "wind.snow",
                category: "Expedition",
                isUnlocked: !iceTreks.isEmpty,
                progress: iceTreks.isEmpty ? 0.0 : 1.0,
                currentCount: min(1, iceTreks.count),
                targetCount: 1,
                unlockedDate: iceTreks.first?.dateConquered,
                tierColor: Color(red: 0.70, green: 0.85, blue: 1.00),
                contributingTreks: iceTreks.map(\.name)
            )
        )

        // 6. 🌅 Dawn Patrol / Goraikō (3+ summits with sunrise memoirs)
        let sunriseTreks = conqueredTreks.filter {
            $0.personalNotes.localizedCaseInsensitiveContains("sunrise") ||
            $0.personalNotes.localizedCaseInsensitiveContains("dawn") ||
            $0.personalNotes.localizedCaseInsensitiveContains("goraiko") ||
            $0.name.localizedCaseInsensitiveContains("Fuji") ||
            $0.name.localizedCaseInsensitiveContains("Kalsubai") ||
            $0.name.localizedCaseInsensitiveContains("Sandakphu")
        }
        badges.append(
            MountaineerBadge(
                id: "dawn_patrol",
                title: "Dawn Patrol",
                subtitle: "Witness 3+ golden sunrises above the sea of clouds",
                icon: "sun.max.fill",
                category: "Expedition",
                isUnlocked: sunriseTreks.count >= 3,
                progress: min(1.0, Double(sunriseTreks.count) / 3.0),
                currentCount: min(3, sunriseTreks.count),
                targetCount: 3,
                unlockedDate: sunriseTreks.count >= 3 ? sunriseTreks[2].dateConquered : nil,
                tierColor: Color(red: 1.0, green: 0.65, blue: 0.15),
                contributingTreks: sunriseTreks.map(\.name)
            )
        )

        // 7. 🗺️ Continental High-Point (Conquered at least 1 Seven Summit giant)
        let sevenSummits = ["Everest", "Kilimanjaro", "Mont Blanc", "Denali", "Aconcagua", "Elbrus", "Vinson", "Puncak Jaya", "Kosciuszko"]
        let continentalTreks = conqueredTreks.filter { trek in
            sevenSummits.contains(where: { trek.name.localizedCaseInsensitiveContains($0) })
        }
        badges.append(
            MountaineerBadge(
                id: "continental_peak",
                title: "Continental High-Point",
                subtitle: "Stand upon one of the world's iconic continental high summits",
                icon: "globe.asia.australia.fill",
                category: "Global",
                isUnlocked: !continentalTreks.isEmpty,
                progress: continentalTreks.isEmpty ? 0.0 : 1.0,
                currentCount: min(1, continentalTreks.count),
                targetCount: 1,
                unlockedDate: continentalTreks.first?.dateConquered,
                tierColor: Color(red: 0.95, green: 0.80, blue: 0.20),
                contributingTreks: continentalTreks.map(\.name)
            )
        )

        // 8. ⚡ Vertical Kilometer Club (1,000m+ gain in a single trek)
        let vkTreks = conqueredTreks.filter { ($0.elevationGainMeters ?? 0) >= 1000 }
        badges.append(
            MountaineerBadge(
                id: "vertical_kilometer",
                title: "Vertical Kilometer Club",
                subtitle: "Climb over 1,000 meters of vertical ascent in a single expedition",
                icon: "arrow.up.forward.app.fill",
                category: "Endurance",
                isUnlocked: !vkTreks.isEmpty,
                progress: vkTreks.isEmpty ? 0.0 : 1.0,
                currentCount: min(1, vkTreks.count),
                targetCount: 1,
                unlockedDate: vkTreks.first?.dateConquered,
                tierColor: Color.red,
                contributingTreks: vkTreks.map(\.name)
            )
        )

        // 9. 📈 Alpine Century Club (50,000m+ total cumulative vertical gain)
        let totalGain = conqueredTreks.compactMap(\.elevationGainMeters).reduce(0, +)
        badges.append(
            MountaineerBadge(
                id: "alpine_century",
                title: "Alpine Century Club",
                subtitle: "Accumulate over 50,000 meters of cumulative lifetime vertical gain",
                icon: "chart.line.uptrend.xyaxis",
                category: "Endurance",
                isUnlocked: totalGain >= 50_000,
                progress: min(1.0, totalGain / 50_000.0),
                currentCount: Int(totalGain),
                targetCount: 50_000,
                unlockedDate: totalGain >= 50_000 ? Date() : nil,
                tierColor: Color.purple,
                contributingTreks: ["\(Int(totalGain).formatted()) m total vertical climbed"]
            )
        )

        // 10. 📸 Summit Chronicler (10+ summit photos attached)
        let totalPhotos = conqueredTreks.map(\.photoFileNames.count).reduce(0, +)
        badges.append(
            MountaineerBadge(
                id: "summit_chronicler",
                title: "Summit Chronicler",
                subtitle: "Preserve 10+ summit expedition photographs in the photo vault",
                icon: "camera.fill",
                category: "Memoirs",
                isUnlocked: totalPhotos >= 10,
                progress: min(1.0, Double(totalPhotos) / 10.0),
                currentCount: min(10, totalPhotos),
                targetCount: 10,
                unlockedDate: totalPhotos >= 10 ? Date() : nil,
                tierColor: Color.indigo,
                contributingTreks: ["\(totalPhotos) photos across \(conqueredTreks.count) summits"]
            )
        )

        // 11. 🧭 Master Cartographer (3+ GPX trail routes imported or flown)
        let gpxTreks = conqueredTreks.filter { $0.hasGPXTrack }
        badges.append(
            MountaineerBadge(
                id: "master_cartographer",
                title: "Master Cartographer",
                subtitle: "Import or fly over 3+ high-resolution GPX trail route corridors",
                icon: "map.fill",
                category: "Cartography",
                isUnlocked: gpxTreks.count >= 3,
                progress: min(1.0, Double(gpxTreks.count) / 3.0),
                currentCount: min(3, gpxTreks.count),
                targetCount: 3,
                unlockedDate: gpxTreks.count >= 3 ? gpxTreks[2].dateConquered : nil,
                tierColor: Color.teal,
                contributingTreks: gpxTreks.map(\.name)
            )
        )

        // 12. 🪨 Technical Alpine Master (Conquer an .alpineExpert or .extreme mountain)
        let technicalTreks = conqueredTreks.filter { $0.difficulty == .alpineExpert || $0.difficulty == .extreme }
        badges.append(
            MountaineerBadge(
                id: "technical_master",
                title: "Technical Alpine Master",
                subtitle: "Conquer a high-risk technical peak with grade Alpine Expert or Extreme",
                icon: "figure.climbing",
                category: "Extreme",
                isUnlocked: !technicalTreks.isEmpty,
                progress: technicalTreks.isEmpty ? 0.0 : 1.0,
                currentCount: min(1, technicalTreks.count),
                targetCount: 1,
                unlockedDate: technicalTreks.first?.dateConquered,
                tierColor: Color(red: 0.90, green: 0.30, blue: 0.35),
                contributingTreks: technicalTreks.map(\.name)
            )
        )

        return badges
    }
}
