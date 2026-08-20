//
//  PlutoEvolutionaryUIManager.swift
//  PLUTO
//
//  3-Stage Evolutionary UI Architecture:
//  🌱 Stage 1: "Spark" (Zero Friction Cockpit · Single Input + Live Vitual Dials)
//  ⚔️ Stage 2: "Hero" (Tri-Diurnal Horizontal Timeline · 3 Active Objectives · Energy Meter)
//  👑 Stage 3: "Architect" (Full 3-Column Sovereign Desktop Operating System)
//

import SwiftUI
import Combine

// MARK: - PlutoUserStage

enum PlutoUserStage: String, CaseIterable, Identifiable, Codable {
    case spark     = "Spark"
    case hero      = "Hero"
    case architect = "Architect"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spark:     return "Spark"
        case .hero:      return "Hero"
        case .architect: return "Architect"
        }
    }

    var icon: String {
        switch self {
        case .spark:     return "sparkle"
        case .hero:      return "shield.fill"
        case .architect: return "crown.fill"
        }
    }

    var tagline: String {
        switch self {
        case .spark:     return "Single-Action Cockpit · Zero Friction"
        case .hero:      return "Tri-Diurnal Timeline · 3 Focus Missions · Energy Meter"
        case .architect: return "Full 3-Column Sovereign Operating System"
        }
    }
}

// MARK: - SimplifiedModeManager (Evolutionary UI Manager)

final class SimplifiedModeManager: ObservableObject {

    static let shared = SimplifiedModeManager()

    private let stageKey = "mac_pluto_user_stage_v1"
    private let launchCountKey = "mac_launch_count_v2"
    private let manualSwitchKey = "mac_has_manually_switched_mode"

    @Published var activeStage: PlutoUserStage {
        didSet {
            UserDefaults.standard.set(activeStage.rawValue, forKey: stageKey)
        }
    }

    @Published var showLevelUpCelebration: Bool = false
    @Published var celebrationTargetStage: PlutoUserStage = .hero

    @Published var launchCount: Int {
        didSet {
            UserDefaults.standard.set(launchCount, forKey: launchCountKey)
        }
    }

    @Published var hasManuallySwitched: Bool {
        didSet {
            UserDefaults.standard.set(hasManuallySwitched, forKey: manualSwitchKey)
        }
    }

    /// Backward compatibility for simple boolean checks
    var isSimplifiedModeActive: Bool {
        get { activeStage != .architect }
        set {
            if newValue {
                if activeStage == .architect {
                    activeStage = .spark
                }
            } else {
                activeStage = .architect
            }
        }
    }

    private init() {
        let defaults = UserDefaults.standard
        let savedStageRaw = defaults.string(forKey: stageKey) ?? PlutoUserStage.spark.rawValue
        let stage = PlutoUserStage(rawValue: savedStageRaw) ?? .spark
        let count = defaults.integer(forKey: launchCountKey) + 1
        let switched = defaults.bool(forKey: manualSwitchKey)

        self.activeStage = stage
        self.launchCount = count
        self.hasManuallySwitched = switched

        defaults.set(count, forKey: launchCountKey)
    }

    /// Transition to a specific evolutionary stage with animation and haptics.
    func setStage(_ newStage: PlutoUserStage, celebrate: Bool = false) {
        hasManuallySwitched = true
        if celebrate && newStage != activeStage {
            celebrationTargetStage = newStage
            showLevelUpCelebration = true
        }

        withAnimation(DS.Motion.settle) {
            activeStage = newStage
        }

        PlutoTelemetryEngine.shared.track(event: "evolutionary_stage_changed", properties: [
            "stage": AnyCodable(newStage.rawValue),
            "celebrated": AnyCodable(celebrate)
        ])
        Haptics.impact(.medium)
    }

    /// Advances to Hero Mode with level-up celebration.
    func advanceToHero() {
        setStage(.hero, celebrate: true)
    }

    /// Advances to Architect Pro Mode with level-up celebration.
    func advanceToArchitect() {
        setStage(.architect, celebrate: true)
    }

    /// Evaluates user behavior to determine if they are ready to level up from Spark -> Hero
    func isReadyForHero(habits: [HabitBoard]) -> Bool {
        guard activeStage == .spark else { return false }
        let maxStreak = habits.map(\.currentStreak).max() ?? 0
        let completedToday = habits.filter { habit in
            let logs = (habit.logs ?? []).filter { $0.timestamp.isToday() && $0.archivedAt == nil }
            return !logs.isEmpty
        }.count

        // Trigger: 3-day streak OR 3 habits completed today
        return maxStreak >= 3 || completedToday >= 3
    }

    /// Evaluates user behavior to determine if they are ready for Architect stage
    func isReadyForArchitect(habits: [HabitBoard], openTasksCount: Int) -> Bool {
        guard activeStage == .hero else { return false }
        let maxStreak = habits.map(\.currentStreak).max() ?? 0
        // Trigger: 7+ day streak OR 5+ tasks created in one day
        return maxStreak >= 7 || openTasksCount >= 5
    }

    /// Value visibility gain message for the current stage
    func valueGainedMessage(streak: Int) -> String {
        switch activeStage {
        case .spark:
            return streak > 0
                ? "Perfect start! You've built a \(streak)-day streak 🔥"
                : "Zero friction • Just get today's first keystone done 🌱"
        case .hero:
            return "You're leveling up! Timeline strip helps you see your day's rhythm 🌅"
        case .architect:
            return "Full command unlocked • AI agents & deep workspace now available 👑"
        }
    }

    /// Legacy toggling for keyboard shortcuts (⌘⇧P cycles Spark ➔ Hero ➔ Architect).
    func toggleMode() {
        switch activeStage {
        case .spark:
            setStage(.hero, celebrate: true)
        case .hero:
            setStage(.architect, celebrate: true)
        case .architect:
            setStage(.spark, celebrate: false)
        }
    }

    func enableProMode() {
        setStage(.architect, celebrate: false)
    }

    func enableSimplifiedMode() {
        setStage(.spark, celebrate: false)
    }
}
