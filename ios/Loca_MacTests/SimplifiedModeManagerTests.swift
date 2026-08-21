//
//  SimplifiedModeManagerTests.swift
//  Loca_MacTests
//
//  Unit Tests for Hero vs Architect Workspace Mode state transitions.
//

import Testing
import Foundation
@testable import Pluto

struct SimplifiedModeManagerTests {

    @Test func testHeroAndArchitectTransitions() {
        let manager = SimplifiedModeManager.shared

        // Test Hero default
        manager.setStage(.hero)
        #expect(manager.activeStage == .hero)
        #expect(manager.isHeroModeActive == true)

        // Advance to Architect
        manager.advanceToArchitect()
        #expect(manager.activeStage == .architect)
        #expect(manager.isHeroModeActive == false)

        // Toggle back to Hero
        manager.toggleMode()
        #expect(manager.activeStage == .hero)
        #expect(manager.isHeroModeActive == true)

        // Toggle to Architect
        manager.toggleMode()
        #expect(manager.activeStage == .architect)
        #expect(manager.isHeroModeActive == false)

        // Reset to Hero for clean baseline
        manager.setStage(.hero)
        #expect(manager.activeStage == .hero)
    }

    @Test func testLaunchCountTracking() {
        let manager = SimplifiedModeManager.shared
        #expect(manager.launchCount > 0)
    }
}
