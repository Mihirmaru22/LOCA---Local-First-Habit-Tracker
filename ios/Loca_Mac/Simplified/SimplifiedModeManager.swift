//
//  SimplifiedModeManager.swift
//  PLUTO
//
//  Smart Mode Detection & Progressive Disclosure Manager for macOS.
//  Determines whether the user starts in Simplified Mode (Single-Column Focus Tunnel)
//  or Pro Mode (Full 3-Column NavigationSplitView).
//

import SwiftUI
import SwiftData

// MARK: - SimplifiedModeManager

@MainActor
final class SimplifiedModeManager: ObservableObject {

    static let shared = SimplifiedModeManager()

    @AppStorage("mac_is_simplified_mode_active") var isSimplifiedModeActive: Bool = true
    @AppStorage("mac_launch_count_v2") var launchCount: Int = 0
    @AppStorage("mac_has_manually_switched_mode") var hasManuallySwitched: Bool = false

    private init() {
        launchCount += 1
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
