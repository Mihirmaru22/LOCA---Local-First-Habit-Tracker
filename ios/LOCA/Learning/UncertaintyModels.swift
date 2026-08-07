//
//  UncertaintyModels.swift
//  LOCA
//
//  Phase 3 — Uncertainty quantification
//  Epistemic vs. aleatoric uncertainty tracking throughout the stack
//

import Foundation
import SwiftData

// MARK: - Uncertainty Types

enum UncertaintyType: String, Codable {
    case epistemic    // Reducible: could know with more data
    case aleatoric    // Irreducible: inherent noise
}

// MARK: - Confidence Level (For Rendering)

enum ConfidenceLevel: String, Codable {
    case crisp        // ≥ 0.8 confidence (fully saturated rendering)
    case soft         // 0.5–0.8 confidence (hazy/blurred)
    case speculative  // < 0.5 confidence (very faint, ghosted)

    init(uncertainty: Double) {
        switch uncertainty {
        case 0..<0.2: self = .crisp
        case 0.2..<0.5: self = .soft
        default: self = .speculative
        }
    }
}

// MARK: - Uncertainty Estimate (Per-Value)

struct UncertaintyEstimate: Codable {
    let value: Double
    let epistemic: Double     // Reducible uncertainty
    let aleatoric: Double     // Irreducible uncertainty
    let total: Double         // Combined (sqrt of sum of squares)
    let confidence: ConfidenceLevel

    init(
        value: Double,
        epistemic: Double = 0,
        aleatoric: Double = 0
    ) {
        self.value = value
        self.epistemic = epistemic
        self.aleatoric = aleatoric
        self.total = sqrt(pow(epistemic, 2) + pow(aleatoric, 2))
        self.confidence = ConfidenceLevel(uncertainty: self.total)
    }
}

// MARK: - Uncertainty Tracker (Per Inference)

@Model
final class UncertaintyRecord {
    var id: UUID = UUID()
    var timestamp: Date

    // Signal level
    var signalCompleteness: Double  // % of signals present
    var signalQuality: Double       // Average signal confidence

    // Inference level
    var energyEpistemic: Double
    var energyAleatoric: Double
    var stressEpistemic: Double
    var stressAleatoric: Double
    var focusEpistemic: Double
    var focusAleatoric: Double
    var moodEpistemic: Double
    var moodAleatoric: Double

    // Event detection level
    var eventDetectionUncertainty: Double

    // Metadata
    var notes: String?

    init(
        timestamp: Date,
        signalCompleteness: Double,
        signalQuality: Double,
        energyEpistemic: Double, energyAleatoric: Double,
        stressEpistemic: Double, stressAleatoric: Double,
        focusEpistemic: Double, focusAleatoric: Double,
        moodEpistemic: Double, moodAleatoric: Double,
        eventDetectionUncertainty: Double
    ) {
        self.timestamp = timestamp
        self.signalCompleteness = signalCompleteness
        self.signalQuality = signalQuality
        self.energyEpistemic = energyEpistemic
        self.energyAleatoric = energyAleatoric
        self.stressEpistemic = stressEpistemic
        self.stressAleatoric = stressAleatoric
        self.focusEpistemic = focusEpistemic
        self.focusAleatoric = focusAleatoric
        self.moodEpistemic = moodEpistemic
        self.moodAleatoric = moodAleatoric
        self.eventDetectionUncertainty = eventDetectionUncertainty
    }
}
