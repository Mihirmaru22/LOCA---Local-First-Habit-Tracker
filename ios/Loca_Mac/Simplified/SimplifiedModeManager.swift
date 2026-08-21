//
//  SimplifiedModeManager.swift
//  PLUTO
//
//  Pluto Workspace Mode Manager:
//  ⚔️ Stage 1: "Hero Mode" (2-Column Focus Engine · Timeline · Rule of 3 Objectives · Energy Battery)
//  👑 Stage 2: "Architect Mode" (Full 3-Column Sovereign Desktop Operating System)
//

import SwiftUI
import Combine

// MARK: - PlutoUserStage

enum PlutoUserStage: String, CaseIterable, Identifiable, Codable {
    case hero      = "Hero"
    case architect = "Architect"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hero:      return "Hero"
        case .architect: return "Architect"
        }
    }

    var icon: String {
        switch self {
        case .hero:      return "shield.fill"
        case .architect: return "crown.fill"
        }
    }

    var tagline: String {
        switch self {
        case .hero:      return "2-Column Focus Engine · Timeline & Rule of 3 Objectives"
        case .architect: return "Full 3-Column Sovereign Operating System"
        }
    }
}

// MARK: - SimplifiedModeManager (Hero & Architect Mode Manager)

final class SimplifiedModeManager: ObservableObject {

    static let shared = SimplifiedModeManager()

    private let stageKey = "mac_pluto_user_stage_v2"
    private let launchCountKey = "mac_launch_count_v2"
    private let manualSwitchKey = "mac_has_manually_switched_mode"

    @Published var activeStage: PlutoUserStage {
        didSet {
            UserDefaults.standard.set(activeStage.rawValue, forKey: stageKey)
        }
    }

    @Published var showLevelUpCelebration: Bool = false
    @Published var celebrationTargetStage: PlutoUserStage = .architect

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

    /// True when Hero Mode is active
    var isHeroModeActive: Bool {
        activeStage == .hero
    }

    /// Backward compatibility flag
    var isSimplifiedModeActive: Bool {
        get { activeStage == .hero }
        set { activeStage = newValue ? .hero : .architect }
    }

    private init() {
        let defaults = UserDefaults.standard
        let savedStageRaw = defaults.string(forKey: stageKey) ?? PlutoUserStage.hero.rawValue
        let stage = PlutoUserStage(rawValue: savedStageRaw) ?? .hero
        let count = defaults.integer(forKey: launchCountKey) + 1
        let switched = defaults.bool(forKey: manualSwitchKey)

        self.activeStage = stage
        self.launchCount = count
        self.hasManuallySwitched = switched

        defaults.set(count, forKey: launchCountKey)
    }

    /// Transition to a specific workspace stage with smooth motion and haptics.
    func setStage(_ newStage: PlutoUserStage, celebrate: Bool = false) {
        hasManuallySwitched = true
        if celebrate && newStage != activeStage {
            celebrationTargetStage = newStage
            showLevelUpCelebration = true
        }

        withAnimation(DS.Motion.settle) {
            activeStage = newStage
        }

        PlutoTelemetryEngine.shared.track(event: "workspace_stage_changed", properties: [
            "stage": AnyCodable(newStage.rawValue),
            "celebrated": AnyCodable(celebrate)
        ])
        Haptics.impact(.medium)
    }

    /// Advances to Architect Pro Mode.
    func advanceToArchitect() {
        setStage(.architect, celebrate: true)
    }

    /// Advances / returns to Hero Mode.
    func enableHeroMode() {
        setStage(.hero, celebrate: false)
    }

    /// Evaluates user behavior to determine if they are ready for Architect stage
    func isReadyForArchitect(habits: [HabitBoard], openTasksCount: Int) -> Bool {
        guard activeStage == .hero else { return false }
        let maxStreak = habits.map(\.currentStreak).max() ?? 0
        // Trigger: 7+ day streak OR 5+ tasks created
        return maxStreak >= 7 || openTasksCount >= 5
    }

    /// Value gain message for current stage
    func valueGainedMessage(streak: Int) -> String {
        switch activeStage {
        case .hero:
            return streak > 0
                ? "Hero momentum active • \(streak)-day streak 🔥"
                : "2-Column Focus Engine • Dial in your diurnal rhythm & top 3 missions ⚔️"
        case .architect:
            return "Full command unlocked • 3-column OS, AI agents & deep workspaces 👑"
        }
    }

    /// Toggles between Hero Mode and Architect Pro Mode (⌘⇧P).
    func toggleMode() {
        switch activeStage {
        case .hero:
            setStage(.architect, celebrate: true)
        case .architect:
            setStage(.hero, celebrate: false)
        }
    }

    func enableProMode() {
        setStage(.architect, celebrate: false)
    }

    func enableSimplifiedMode() {
        setStage(.hero, celebrate: false)
    }
}
