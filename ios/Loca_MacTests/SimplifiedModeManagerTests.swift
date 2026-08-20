//
//  SimplifiedModeManagerTests.swift
//  Loca_MacTests
//
//  Unit Tests for SimplifiedModeManager state transitions and persistence.
//

import Testing
import Foundation
@testable import Pluto

struct SimplifiedModeManagerTests {

    @Test func testSimplifiedModeStateTransitions() {
        let manager = SimplifiedModeManager.shared

        // Initial state or state change test
        let initialMode = manager.isSimplifiedModeActive

        // Toggle
        manager.toggleMode()
        #expect(manager.isSimplifiedModeActive == !initialMode)
        #expect(manager.hasManuallySwitched == true)

        // Enable Pro Mode explicitly
        manager.enableProMode()
        #expect(manager.isSimplifiedModeActive == false)

        // Enable Simplified Mode explicitly
        manager.enableSimplifiedMode()
        #expect(manager.isSimplifiedModeActive == true)

        // Restore to desired test baseline
        manager.enableSimplifiedMode()
        #expect(manager.isSimplifiedModeActive == true)
    }

    @Test func testLaunchCountTracking() {
        let manager = SimplifiedModeManager.shared
        #expect(manager.launchCount > 0)
    }
}
