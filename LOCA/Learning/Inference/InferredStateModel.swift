//
//  InferredStateModel.swift
//  LOCA
//
//  Phase 3 — Inferred State entity (SwiftData @Model)
//  Extracted from StateInferenceEngine.swift so this file can be included in
//  every target whose ModelContainer registers RippleSchemaV1 (Main App + Widget)
//  without pulling the @MainActor engine class and its inference-model
//  dependencies into extension targets.
//

import Foundation
import SwiftData

@Model
final class InferredState {
    var id: UUID = UUID()
    var timestamp: Date
    var hourStart: Date

    var energy: Double  // 0–1
    var energyUncertainty: Double

    var stress: Double  // 0–1
    var stressUncertainty: Double

    var focus: Double  // 0–1
    var focusUncertainty: Double

    var mood: Double  // 0–1
    var moodUncertainty: Double

    var isCalibrated: Bool = false
    var calibrationError: Double?

    // C1.1: Absence flags — true when no real signals contributed to that dimension.
    // Absence is structurally distinct from a measured value of 0.0 or 0.5.
    var energyAbsent: Bool = false
    var stressAbsent: Bool = false
    var focusAbsent: Bool = false
    var moodAbsent: Bool = false

    // C1.2: Provenance — JSON-encoded InferenceProvenance per dimension.
    // Available without a second query so view-layer callers can name their evidence.
    var energyProvenanceJSON: String?
    var stressProvenanceJSON: String?
    var focusProvenanceJSON: String?
    var moodProvenanceJSON: String?

    var energyProvenance: InferenceProvenance? {
        energyProvenanceJSON.flatMap { InferenceProvenance.decode(from: $0) }
    }
    var stressProvenance: InferenceProvenance? {
        stressProvenanceJSON.flatMap { InferenceProvenance.decode(from: $0) }
    }
    var focusProvenance: InferenceProvenance? {
        focusProvenanceJSON.flatMap { InferenceProvenance.decode(from: $0) }
    }
    var moodProvenance: InferenceProvenance? {
        moodProvenanceJSON.flatMap { InferenceProvenance.decode(from: $0) }
    }

    init(
        timestamp: Date,
        energy: Double,
        energyUncertainty: Double,
        stress: Double,
        stressUncertainty: Double,
        focus: Double,
        focusUncertainty: Double,
        mood: Double,
        moodUncertainty: Double
    ) {
        self.timestamp = timestamp
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour], from: timestamp)
        self.hourStart = Calendar.current.date(from: comps) ?? timestamp
        self.energy = Self.clamp(energy)
        self.energyUncertainty = Self.clamp(energyUncertainty)
        self.stress = Self.clamp(stress)
        self.stressUncertainty = Self.clamp(stressUncertainty)
        self.focus = Self.clamp(focus)
        self.focusUncertainty = Self.clamp(focusUncertainty)
        self.mood = Self.clamp(mood)
        self.moodUncertainty = Self.clamp(moodUncertainty)
    }

    private static func clamp(_ value: Double) -> Double {
        max(0, min(1, value))
    }
}
