//
//  FeedbackProcessor.swift
//  LOCA
//
//  Phase 10, Session 10.2 — Feedback processing and integration.
//
//  Use stored user feedback on patterns and narratives to refine future detection
//  and composition. Resonance scores boost or suppress confidence; refinements
//  are annotations that guide the engines toward better observations.
//

import Foundation
import SwiftData

@MainActor final class FeedbackProcessor {
    static let shared = FeedbackProcessor()

    private init() {}

    // MARK: - Pattern Feedback Integration

    /// Fetch all stored pattern feedback, grouping by pattern ID.
    func loadPatternFeedback(modelContext: ModelContext) throws -> [UUID: [PatternFeedback]] {
        let allFeedback = try modelContext.fetch(FetchDescriptor<PatternFeedback>())
        var grouped: [UUID: [PatternFeedback]] = [:]
        for feedback in allFeedback {
            grouped[feedback.patternId, default: []].append(feedback)
        }
        return grouped
    }

    /// Compute confidence adjustment from resonance feedback.
    /// Positive resonance (+1) → +0.10, Neutral (0) → +0.02, Negative (-1) → -0.15.
    func confidenceAdjustment(for resonances: [Int]) -> Double {
        guard !resonances.isEmpty else { return 0 }
        let weights = resonances.map { res -> Double in
            switch res {
            case 1: return 0.10
            case -1: return -0.15
            default: return 0.02
            }
        }
        return weights.reduce(0, +) / Double(weights.count)
    }

    /// Apply feedback-adjusted confidence to a pattern using Rule E (feedback clamp).
    /// Under the certainty ceiling, positive resonance is bounded by the evidence
    /// (corroboration cannot manufacture statistical certainty); negative resonance
    /// lowers confidence freely. Previously this was an unbounded
    /// `pattern.confidence + adjustment`, which let affirmation inflate a claim
    /// above what its evidence supports.
    func adjustedConfidence(for pattern: LifePattern, feedback: [PatternFeedback]) -> Double {
        guard !feedback.isEmpty else { return pattern.confidence }
        let adjustment = confidenceAdjustment(for: feedback.map { $0.resonance })
        return feedbackClamp(evidenceConfidence: pattern.confidence, resonanceAdjustment: adjustment)
    }

    /// Extract refinement hints (user corrections) that might apply to this pattern.
    func refinementHints(from feedback: [PatternFeedback]) -> [String] {
        feedback.compactMap { $0.refinement }
    }

    // MARK: - Narrative Feedback Integration

    /// Fetch all stored narrative feedback.
    func loadNarrativeFeedback(modelContext: ModelContext) throws -> [NarrativeFeedback] {
        try modelContext.fetch(FetchDescriptor<NarrativeFeedback>())
    }

    /// Compute average resonance across all narrative feedback.
    func averageNarrativeResonance(feedback: [NarrativeFeedback]) -> Double? {
        guard !feedback.isEmpty else { return nil }
        let sum = feedback.map { $0.resonance }.reduce(0, +)
        return sum / Double(feedback.count)
    }

    /// Collect all notes/refinements from narrative feedback.
    func narrativeRefinements(from feedback: [NarrativeFeedback]) -> [String] {
        feedback.compactMap { $0.notes }
    }

    // MARK: - Feedback Signals

    /// Identify high-resonance patterns (average resonance >= 0.5).
    func highResonancePatterns(_ patterns: [LifePattern], feedback: [UUID: [PatternFeedback]]) -> [LifePattern] {
        patterns.filter { pattern in
            guard let patternFeedback = feedback[pattern.id] else { return false }
            let avgResonance = Double(patternFeedback.map { $0.resonance }.reduce(0, +)) / Double(patternFeedback.count)
            return avgResonance >= 0.5
        }
    }

    /// Identify problematic patterns (average resonance <= -0.3).
    func lowResonancePatterns(_ patterns: [LifePattern], feedback: [UUID: [PatternFeedback]]) -> [LifePattern] {
        patterns.filter { pattern in
            guard let patternFeedback = feedback[pattern.id] else { return false }
            let avgResonance = Double(patternFeedback.map { $0.resonance }.reduce(0, +)) / Double(patternFeedback.count)
            return avgResonance <= -0.3
        }
    }

    /// Check if a narrative arc has consistent feedback (for reuse or replay).
    func arcHasConsistentResonance(_ arc: String, feedback: [NarrativeFeedback]) -> Bool {
        let matching = feedback.filter { $0.arc == arc }
        guard matching.count >= 2 else { return false }
        let resonances = matching.map { $0.resonance }
        let avg = resonances.reduce(0, +) / Double(resonances.count)
        let variance = resonances.map { pow($0 - avg, 2) }.reduce(0, +) / Double(resonances.count)
        return variance < 0.04 // Low variance = consistent
    }

    // MARK: - Mark Feedback as Processed

    /// Mark all processed feedback as handled (prevents re-processing).
    func markAsProcessed(_ feedback: [PatternFeedback], modelContext: ModelContext) throws {
        for f in feedback {
            f.isProcessed = true
        }
        try modelContext.save()
    }

    func markNarrativeAsProcessed(_ feedback: [NarrativeFeedback], modelContext: ModelContext) throws {
        for f in feedback {
            f.isProcessed = true
        }
        try modelContext.save()
    }
}
