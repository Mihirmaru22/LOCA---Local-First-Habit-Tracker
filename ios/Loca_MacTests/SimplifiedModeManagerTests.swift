//
//  SimplifiedModeManagerTests.swift
//  Loca_MacTests
//
//  Unit Tests for Evolutionary UI Stages (Spark, Hero, Architect) state transitions.
//

import Testing
import Foundation
@testable import Pluto

struct SimplifiedModeManagerTests {

    @Test func testEvolutionaryStageTransitions() {
        let manager = SimplifiedModeManager.shared

        // Test Spark
        manager.setStage(.spark)
        #expect(manager.activeStage == .spark)
        #expect(manager.isSimplifiedModeActive == true)

        // Advance to Hero
        manager.advanceToHero()
        #expect(manager.activeStage == .hero)
        #expect(manager.isSimplifiedModeActive == true)

        // Advance to Architect
        manager.advanceToArchitect()
        #expect(manager.activeStage == .architect)
        #expect(manager.isSimplifiedModeActive == false)

        // Cycle toggle: Architect -> Spark
        manager.toggleMode()
        #expect(manager.activeStage == .spark)

        // Spark -> Hero
        manager.toggleMode()
        #expect(manager.activeStage == .hero)

        // Hero -> Architect
        manager.toggleMode()
        #expect(manager.activeStage == .architect)

        // Reset to Spark for clean baseline
        manager.setStage(.spark)
        #expect(manager.activeStage == .spark)
    }

    @Test func testLaunchCountTracking() {
        let manager = SimplifiedModeManager.shared
        #expect(manager.launchCount > 0)
    }
}
