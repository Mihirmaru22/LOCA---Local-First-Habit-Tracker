//
//  SimplifiedModeManager.swift
//  PLUTO
//
//  Smart Mode Detection & Progressive Disclosure Manager for macOS.
//  Determines whether the user starts in Simplified Mode (Single-Column Focus Tunnel)
//  or Pro Mode (Full 3-Column NavigationSplitView).
//

import SwiftUI
import Combine

// MARK: - SimplifiedModeManager

final class SimplifiedModeManager: ObservableObject {

    static let shared = SimplifiedModeManager()

    private let simplifiedKey = "mac_is_simplified_mode_active"
    private let launchCountKey = "mac_launch_count_v2"
    private let manualSwitchKey = "mac_has_manually_switched_mode"

    @Published var isSimplifiedModeActive: Bool {
        didSet {
            UserDefaults.standard.set(isSimplifiedModeActive, forKey: simplifiedKey)
        }
    }

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

    private init() {
        let defaults = UserDefaults.standard
        let savedMode = defaults.object(forKey: simplifiedKey) as? Bool ?? true
        let count = defaults.integer(forKey: launchCountKey) + 1
        let switched = defaults.bool(forKey: manualSwitchKey)

        self.isSimplifiedModeActive = savedMode
        self.launchCount = count
        self.hasManuallySwitched = switched

        defaults.set(count, forKey: launchCountKey)
    }

    /// Toggles between Simplified Mode and Full Pro Mode with smooth motion.
    func toggleMode() {
        hasManuallySwitched = true
        withAnimation(DS.Motion.settle) {
            isSimplifiedModeActive.toggle()
        }
        Haptics.impact(.medium)
    }

    /// Switches explicitly to Pro Mode.
    func enableProMode() {
        hasManuallySwitched = true
        withAnimation(DS.Motion.settle) {
            isSimplifiedModeActive = false
        }
        Haptics.impact(.medium)
    }

    /// Switches explicitly to Simplified Mode.
    func enableSimplifiedMode() {
        hasManuallySwitched = true
        withAnimation(DS.Motion.settle) {
            isSimplifiedModeActive = true
        }
        Haptics.impact(.light)
    }
}
