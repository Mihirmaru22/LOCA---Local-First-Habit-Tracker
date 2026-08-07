//
//  FeedbackModel.swift
//  LOCA
//
//  Phase 10, Session 10.1 — User feedback on patterns and narratives.
//
//  Feedback is the inverse of inference: the user labels what resonates,
//  what's wrong, or what's missing. Feedback flows back to pattern detection
//  and composition engines to refine future outputs.
//

import Foundation
import SwiftData

@Model final class PatternFeedback {
    var id: UUID = UUID()

    /// Which pattern is being rated?
    var patternId: UUID

    /// Reaction: 1 (rejected), 0 (neutral), 1 (resonates)
    var resonance: Int

    /// User's optional refinement or correction
    var refinement: String?

    /// Was this feedback used by the engines?
    var isProcessed: Bool = false

    var createdAt: Date

    init(patternId: UUID, resonance: Int, refinement: String? = nil) {
        self.patternId = patternId
        self.resonance = resonance
        self.refinement = refinement
        self.createdAt = Date()
    }
}

@Model final class NarrativeFeedback {
    var id: UUID = UUID()

    /// Which narrative arc resonated?
    var arc: String

    /// Did the narrative feel true? (0–1)
    var resonance: Double

    /// What was missing or off?
    var notes: String?

    var isProcessed: Bool = false

    var createdAt: Date

    init(arc: String, resonance: Double, notes: String? = nil) {
        self.arc = arc
        self.resonance = resonance
        self.notes = notes
        self.createdAt = Date()
    }
}
