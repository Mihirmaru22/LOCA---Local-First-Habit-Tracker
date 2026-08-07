//
//  CalibrationModel.swift
//  LOCA
//
//  Phase 8.5 — User calibration of soft (uncertain) elements.
//
//  When the user sharpens a soft part of a composed view (annotation, signal,
//  or soft thread), they provide a label that feeds back to the inference engine.
//  Calibrations are lightweight: timestamp, element ID, and user label.
//

import Foundation
import SwiftData

@Model final class Calibration {
    var id: UUID = UUID()

    /// What did the user sharpen? (e.g., "annotation", "signal", "thread")
    var elementType: String

    /// The text of the element that was calibrated
    var elementText: String

    /// The user's clarification or label
    var label: String

    /// Which dimension (for signals) or context (for annotations)
    var dimension: String?

    /// When was this calibration recorded
    var calibratedAt: Date

    /// Confidence boost (0–1) this calibration provides
    var confidenceBoost: Double = 0.15

    /// Has this calibration been consumed by the inference engine?
    var isProcessed: Bool = false

    init(
        elementType: String,
        elementText: String,
        label: String,
        dimension: String? = nil
    ) {
        self.elementType = elementType
        self.elementText = elementText
        self.label = label
        self.dimension = dimension
        self.calibratedAt = Date()
    }
}
