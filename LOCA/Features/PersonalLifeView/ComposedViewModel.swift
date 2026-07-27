//
//  ComposedViewModel.swift
//  LOCA
//
//  Phase 4 — ComposedView entity (SwiftData @Model) and its plain-data payloads
//  Extracted from ViewCompositionEngine.swift so this file can be included in
//  every target whose ModelContainer registers RippleSchemaV1 (Main App + Widget)
//  without pulling the @MainActor engine class into extension targets.
//

import Foundation
import SwiftData

// MARK: - Composed View (Persistent)

@Model
final class ComposedView {
    var id: UUID = UUID()
    var timestamp: Date
    var question: String
    var startDate: Date
    var endDate: Date

    // Data layers
    var energyTimeline: [TimelinePoint]
    var stressTimeline: [TimelinePoint]
    var focusTimeline: [TimelinePoint]
    var moodTimeline: [TimelinePoint]
    var eventMarkers: [EventMarker]
    var annotations: [AnnotationPoint]

    // Counterfactual state
    var counterfactualVariable: String?
    var isShowingCounterfactual: Bool = false

    // Rendering metadata
    var colorScheme: [String: String] = [:]
    var renderingGuidance: String = ""

    init(
        question: String,
        startDate: Date,
        endDate: Date,
        energyTimeline: [TimelinePoint],
        stressTimeline: [TimelinePoint],
        focusTimeline: [TimelinePoint],
        moodTimeline: [TimelinePoint],
        eventMarkers: [EventMarker],
        annotations: [AnnotationPoint]
    ) {
        self.question = question
        self.startDate = startDate
        self.endDate = endDate
        self.energyTimeline = energyTimeline
        self.stressTimeline = stressTimeline
        self.focusTimeline = focusTimeline
        self.moodTimeline = moodTimeline
        self.eventMarkers = eventMarkers
        self.annotations = annotations
        self.timestamp = Date()

        self.colorScheme = [
            "energy": "#10B981",
            "stress": "#EF4444",
            "focus": "#3B82F6",
            "mood": "#F59E0B",
        ]
    }
}

// MARK: - Timeline Point

struct TimelinePoint: Codable {
    let timestamp: Date
    let value: Double
    let uncertainty: Double
    let confidence: ConfidenceLevel
    let renderingStyle: String
    // C1.4: Absence carried to the surface.
    // "absent" renderingStyle means "we genuinely have no data" —
    // distinct from "speculative" (low-confidence measured value).
    let isAbsent: Bool
    let uncertaintyType: String?    // UncertaintyType.rawValue or nil

    init(
        timestamp: Date,
        value: Double,
        uncertainty: Double,
        confidence: ConfidenceLevel,
        renderingStyle: String,
        isAbsent: Bool = false,
        uncertaintyType: String? = nil
    ) {
        self.timestamp = timestamp
        self.value = value
        self.uncertainty = uncertainty
        self.confidence = confidence
        self.renderingStyle = renderingStyle
        self.isAbsent = isAbsent
        self.uncertaintyType = uncertaintyType
    }
}

// MARK: - Event Marker

struct EventMarker: Codable {
    let timestamp: Date
    let eventType: String
    let label: String
    let metadata: [String: String]
}

// MARK: - Annotation Point

struct AnnotationPoint: Codable {
    let timestamp: Date
    let text: String
    let position: String
    let targetState: String
}
