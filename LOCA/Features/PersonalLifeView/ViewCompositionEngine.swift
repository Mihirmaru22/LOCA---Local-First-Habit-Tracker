//
//  ViewCompositionEngine.swift
//  LOCA
//
//  Phase 4 — View composition engine
//  Renders bendable Views from inferred states and detected Life Events
//  Replaces Phase 1's hand-building with automatic generation
//

import Foundation
import SwiftData

// The ComposedView @Model and its plain-data payloads
// (TimelinePoint / EventMarker / AnnotationPoint) live in ComposedViewModel.swift
// so they can be registered in RippleSchemaV1 from targets that don't build
// this engine.

// MARK: - View Composition Engine

@MainActor
class ViewCompositionEngine {
    static let shared = ViewCompositionEngine()

    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Main Composition

    func composeView(
        question: String,
        startDate: Date,
        endDate: Date,
        modelContext: ModelContext
    ) async throws -> ComposedView {
        let ctx = self.modelContext ?? modelContext

        // Fetch inferred states in range
        let statesDescriptor = FetchDescriptor<InferredState>(
            predicate: #Predicate { state in
                state.timestamp >= startDate && state.timestamp <= endDate
            }
        )

        guard let states = try? ctx.fetch(statesDescriptor), !states.isEmpty else {
            throw ViewCompositionError.noData
        }

        // Fetch life events in range
        let eventsDescriptor = FetchDescriptor<LifeEvent>(
            predicate: #Predicate { event in
                event.timestamp >= startDate && event.timestamp <= endDate &&
                event.confidence >= 0.7  // Only high-confidence events
            }
        )

        let events = (try? ctx.fetch(eventsDescriptor)) ?? []

        // Build timeline layers
        let energyTimeline = buildTimeline(
            states: states,
            keyPath: \.energy,
            uncertaintyPath: \.energyUncertainty
        )

        let stressTimeline = buildTimeline(
            states: states,
            keyPath: \.stress,
            uncertaintyPath: \.stressUncertainty
        )

        let focusTimeline = buildTimeline(
            states: states,
            keyPath: \.focus,
            uncertaintyPath: \.focusUncertainty
        )

        let moodTimeline = buildTimeline(
            states: states,
            keyPath: \.mood,
            uncertaintyPath: \.moodUncertainty
        )

        // Build event markers
        let eventMarkers = events.map { event -> EventMarker in
            EventMarker(
                timestamp: event.timestamp,
                eventType: event.eventType.rawValue,
                label: event.eventType.rawValue.replacingOccurrences(of: "Change", with: ""),
                metadata: event.metadata
            )
        }

        // Build annotations (spike callouts, context notes)
        let annotations = buildAnnotations(
            states: states,
            events: events
        )

        let composedView = ComposedView(
            question: question,
            startDate: startDate,
            endDate: endDate,
            energyTimeline: energyTimeline,
            stressTimeline: stressTimeline,
            focusTimeline: focusTimeline,
            moodTimeline: moodTimeline,
            eventMarkers: eventMarkers,
            annotations: annotations
        )

        return composedView
    }

    // MARK: - Timeline Building

    private func buildTimeline(
        states: [InferredState],
        keyPath: KeyPath<InferredState, Double>,
        uncertaintyPath: KeyPath<InferredState, Double>
    ) -> [TimelinePoint] {
        return states.sorted(by: { $0.timestamp < $1.timestamp }).map { state in
            let value = state[keyPath: keyPath]
            let uncertainty = state[keyPath: uncertaintyPath]
            let confidence = ConfidenceLevel(uncertainty: uncertainty)

            let renderingStyle: String = {
                switch confidence {
                case .crisp: return "crisp"
                case .soft: return "soft"
                case .speculative: return "speculative"
                }
            }()

            return TimelinePoint(
                timestamp: state.timestamp,
                value: value,
                uncertainty: uncertainty,
                confidence: confidence,
                renderingStyle: renderingStyle
            )
        }
    }

    // MARK: - Annotation Building

    private func buildAnnotations(
        states: [InferredState],
        events: [LifeEvent]
    ) -> [AnnotationPoint] {
        var annotations: [AnnotationPoint] = []

        // Add event-driven annotations
        for event in events {
            let label = "\(event.eventType.rawValue): \(event.metadata["summary"] ?? "regime shift")"
            let annotation = AnnotationPoint(
                timestamp: event.timestamp,
                text: label,
                position: "above",
                targetState: "energy"
            )
            annotations.append(annotation)
        }

        // Add spike annotations (high stress or energy drops)
        let stressValues = states.map { $0.stress }
        let stressMean = stressValues.reduce(0, +) / Double(stressValues.count)
        let stressStddev = sqrt(
            stressValues.map { pow($0 - stressMean, 2) }.reduce(0, +) / Double(stressValues.count)
        )

        for state in states {
            if state.stress > (stressMean + 1.5 * stressStddev) {
                let annotation = AnnotationPoint(
                    timestamp: state.timestamp,
                    text: "High stress spike",
                    position: "above",
                    targetState: "stress"
                )
                annotations.append(annotation)
            }
        }

        return Array(annotations.prefix(3))  // Max 3 annotations per view
    }

    // MARK: - Counterfactual Support

    func applyCounterfactual(
        to view: ComposedView,
        variable: String
    ) -> ComposedView {
        let modifiedView = view
        modifiedView.counterfactualVariable = variable
        modifiedView.isShowingCounterfactual = true

        // Hypothetically project the timeline if the event hadn't happened
        if let eventMarker = view.eventMarkers.first {
            let eventTime = eventMarker.timestamp

            // Extract pre-event pattern (before the shift)
            let preEventStates = view.energyTimeline.filter { $0.timestamp < eventTime }
            guard !preEventStates.isEmpty else { return modifiedView }

            let preEventMean = preEventStates.map { $0.value }.reduce(0, +) / Double(preEventStates.count)

            // Project pre-event pattern forward (assume no shift occurred)
            modifiedView.energyTimeline = view.energyTimeline.map { point in
                if point.timestamp >= eventTime {
                    // Reduce saturation/opacity of post-event points to show speculation
                    var specPoint = point
                    specPoint = TimelinePoint(
                        timestamp: point.timestamp,
                        value: preEventMean,  // Hypothetical: stays at pre-event level
                        uncertainty: point.uncertainty + 0.3,  // Increase uncertainty
                        confidence: .speculative,  // Mark as speculative
                        renderingStyle: "speculative"
                    )
                    return specPoint
                }
                return point
            }
        }

        return modifiedView
    }
}

// MARK: - Errors

enum ViewCompositionError: LocalizedError {
    case noContext
    case noData
    case invalidDateRange

    var errorDescription: String? {
        switch self {
        case .noContext: return "No model context available"
        case .noData: return "No inferred states in this date range"
        case .invalidDateRange: return "Start date must be before end date"
        }
    }
}
