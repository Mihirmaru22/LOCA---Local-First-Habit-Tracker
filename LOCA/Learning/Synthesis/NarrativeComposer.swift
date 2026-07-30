//
//  NarrativeComposer.swift
//  LOCA
//
//  Phase 9, Session 9.2 — Life narrative synthesis.
//
//  Weave detected patterns into multi-threaded narratives about life arcs,
//  themes, and trajectories. A narrative is not a summary — it's a shaped
//  observation of how different parts of your life connect and evolve.
//
//  C5: arc and thread confidence come from UncertaintyCalculus (Rule D conjunction
//  of the contributing patterns), and their uncertainty is aggregated from the real
//  pattern uncertainties (Rule A). Prose is hedged so that assertiveness rises with
//  confidence — the language contract — never the reverse.
//

import Foundation
import SwiftData

// MARK: - Life Narrative

struct LifeNarrative {
    /// The main story arc (e.g., "growing into rhythm")
    let arc: String

    /// Confidence in the arc (0–1): Rule D (weakest-link) over contributing patterns.
    let arcConfidence: Double

    /// Uncertainty in the arc (0–1): Rule A over the contributing patterns' uncertainties.
    let arcUncertainty: Double

    /// Supporting threads (2–3 key themes)
    let threads: [NarrativeThread]

    /// The full composed narrative
    let body: String

    /// When was this composed?
    let generatedAt: Date
}

struct NarrativeThread {
    /// Thread title (e.g., "Consistency across change")
    let title: String

    /// Thread body (detailed observation)
    let body: String

    /// Which patterns support this thread?
    let patternIds: [UUID]

    /// Confidence in this thread: Rule D (min) of its supporting patterns' confidence.
    let confidence: Double

    /// Uncertainty in this thread: Rule A over its supporting patterns' uncertainty.
    let uncertainty: Double
}

// MARK: - Engine

@MainActor
final class NarrativeComposer {
    static let shared = NarrativeComposer()

    // MARK: - Public API

    func composeNarrative(
        patterns: [LifePattern],
        chapters: [Chapter],
        direction: Direction?,
        modelContext: ModelContext
    ) -> LifeNarrative? {
        guard !patterns.isEmpty else { return nil }

        // Load and filter by user feedback
        let processor = FeedbackProcessor.shared
        var workingPatterns = patterns
        var narrativeFeedback: [NarrativeFeedback] = []

        do {
            let patternFeedback = try processor.loadPatternFeedback(modelContext: modelContext)
            narrativeFeedback = try processor.loadNarrativeFeedback(modelContext: modelContext)

            // Suppress low-resonance patterns; prioritize high-resonance
            let lowResonance = processor.lowResonancePatterns(patterns, feedback: patternFeedback)
            workingPatterns = workingPatterns.filter { pattern in
                !lowResonance.contains { $0.id == pattern.id }
            }

            guard !workingPatterns.isEmpty else { return nil }
        } catch {
            // Fallback: use all patterns if feedback load fails
        }

        // Cluster patterns into thematic threads
        let threads = identifyThreads(patterns: workingPatterns)
        guard !threads.isEmpty else { return nil }

        // Identify life arc from chapter progression + direction
        let arc = identifyArc(chapters: chapters, direction: direction, patterns: workingPatterns, narrativeFeedback: narrativeFeedback)

        // Rule D: arc confidence is the weakest-link of its contributing patterns.
        let arcConfidence = conjunctionConfidence(componentConfidences: workingPatterns.map { $0.confidence })
        // Rule A: arc uncertainty aggregates the real pattern uncertainties.
        let arcUncertainty = aggregateUncertainty(
            values: workingPatterns.map { $0.confidence },
            uncertainties: workingPatterns.map { $0.uncertainty }
        ).uncertainty

        // Compose narrative body from arc + threads, hedged by confidence.
        let body = composeBody(arc: arc, arcConfidence: arcConfidence, threads: threads, patterns: workingPatterns)

        // Mark narrative feedback as processed
        do {
            try processor.markNarrativeAsProcessed(narrativeFeedback, modelContext: modelContext)
        } catch {
            // Silently continue if marking fails
        }

        return LifeNarrative(
            arc: arc,
            arcConfidence: arcConfidence,
            arcUncertainty: arcUncertainty,
            threads: threads,
            body: body,
            generatedAt: Date()
        )
    }

    // MARK: - Thread Identification

    private func identifyThreads(patterns: [LifePattern]) -> [NarrativeThread] {
        var threads: [NarrativeThread] = []

        // Thread 1: Habit theme (if multiple habit-state patterns)
        let habitPatterns = patterns.filter { $0.layer == .habitState }.sorted { $0.confidence > $1.confidence }
        if !habitPatterns.isEmpty {
            let top = Array(habitPatterns.prefix(3))
            let confidence = conjunctionConfidence(componentConfidences: top.map { $0.confidence })
            let uncertainty = aggregateUncertainty(
                values: top.map { $0.confidence }, uncertainties: top.map { $0.uncertainty }
            ).uncertainty
            let habits = top.map { $0.observation }.joined(separator: " Also, ")
            threads.append(NarrativeThread(
                title: "Your anchoring habits",
                body: habits + " " + hedge("These habits appear to be part of what sustains your baseline.", confidence: confidence),
                patternIds: top.map { $0.id },
                confidence: confidence,
                uncertainty: uncertainty
            ))
        }

        // Thread 2: People theme (if multiple person-state patterns)
        let peoplePatterns = patterns.filter { $0.layer == .personState }.sorted { $0.confidence > $1.confidence }
        if !peoplePatterns.isEmpty {
            let top = Array(peoplePatterns.prefix(2))
            let confidence = conjunctionConfidence(componentConfidences: top.map { $0.confidence })
            let uncertainty = aggregateUncertainty(
                values: top.map { $0.confidence }, uncertainties: top.map { $0.uncertainty }
            ).uncertainty
            let people = top.map { $0.observation }.joined(separator: " Similarly, ")
            threads.append(NarrativeThread(
                title: "The people in your rhythm",
                body: people + " " + hedge("The specific people around you shape your inner states.", confidence: confidence),
                patternIds: top.map { $0.id },
                confidence: confidence,
                uncertainty: uncertainty
            ))
        }

        // Thread 3: Consistency theme (if habit-chapter patterns exist)
        let consistencyPatterns = patterns.filter { $0.layer == .habitChapter }.sorted { $0.confidence > $1.confidence }
        if let topPattern = consistencyPatterns.first {
            let confidence = topPattern.confidence
            threads.append(NarrativeThread(
                title: "What persists",
                body: topPattern.observation + " " + hedge("This consistency across your life's chapters suggests a core thread running through everything.", confidence: confidence),
                patternIds: [topPattern.id],
                confidence: confidence,
                uncertainty: topPattern.uncertainty
            ))
        }

        return Array(threads.prefix(3))
    }

    // MARK: - Arc Identification

    private func identifyArc(
        chapters: [Chapter],
        direction: Direction?,
        patterns: [LifePattern],
        narrativeFeedback: [NarrativeFeedback] = []
    ) -> String {
        // If there's a Direction, use it as the primary arc
        if let direction = direction {
            return direction.statement
        }

        // Generate candidate arcs based on chapter progression + patterns
        var candidates: [String] = []
        let chapterCount = chapters.count

        if chapterCount <= 1 {
            // Early story
            let moodPatterns = patterns.filter { $0.layer == .chapterState }
            candidates.append(moodPatterns.first != nil ? "Beginning to find your rhythm" : "Finding your way")
        } else if chapterCount <= 3 {
            // Mid story: multiple chapters
            let consistentHabits = patterns.filter { $0.layer == .habitChapter }
            candidates.append(consistentHabits.isEmpty ? "Learning what matters across different chapters" : "Discovering what stays steady through change")
        } else {
            // Longer story: explicit narrative
            let strongPatterns = patterns.filter { $0.confidence >= 0.6 }
            candidates.append(strongPatterns.count >= 3 ? "Your life is shaped by consistent patterns beneath the changing chapters" : "Growing through different chapters")
        }

        // Use narrative feedback to prefer high-resonance arcs
        if !narrativeFeedback.isEmpty {
            let processor = FeedbackProcessor.shared
            for candidate in candidates {
                if processor.arcHasConsistentResonance(candidate, feedback: narrativeFeedback) {
                    // This arc has consistent positive feedback history
                    return candidate
                }
            }

            // Filter for high-resonance arcs if feedback exists
            let highResonanceArcs = narrativeFeedback
                .filter { $0.resonance >= 0.6 }
                .map { $0.arc }
            if let preferredArc = highResonanceArcs.first, candidates.contains(preferredArc) {
                return preferredArc
            }
        }

        return candidates.first ?? "Growing through different chapters"
    }

    // MARK: - Language Contract (Hedging)

    /// Hedge a statement so that assertiveness rises MONOTONICALLY with confidence.
    /// This is the corrected language contract: crisp only when confidence is high,
    /// increasingly tentative as it falls. (The prior implementation inverted this —
    /// it made the weakest claims the most assertive.)
    ///
    ///   confidence >= 0.85  → crisp    ("clearly …")
    ///   confidence >= 0.55  → soft     (leave the hedged wording as written)
    ///   confidence >= 0.30  → speculative ("One possible reading: …")
    ///   confidence <  0.30  → tentative  ("Very tentatively, …")
    private func hedge(_ text: String, confidence: Double) -> String {
        if confidence >= 0.85 {
            return text.replacingOccurrences(of: "appear to be", with: "are")
                       .replacingOccurrences(of: "appears", with: "clearly")
                       .replacingOccurrences(of: "suggests", with: "shows")
        } else if confidence >= 0.55 {
            return text
        } else if confidence >= 0.30 {
            return "One possible reading: " + lowercaseFirst(text)
        } else {
            return "Very tentatively, " + lowercaseFirst(text)
        }
    }

    private func lowercaseFirst(_ s: String) -> String {
        guard let first = s.first else { return s }
        return first.lowercased() + s.dropFirst()
    }

    // MARK: - Narrative Composition

    private func composeBody(
        arc: String,
        arcConfidence: Double,
        threads: [NarrativeThread],
        patterns: [LifePattern]
    ) -> String {
        var body = ""

        // Hedge the arc statement by the arc's confidence.
        body += hedge("The arc of your life, as reflected in your data: \(arc).", confidence: arcConfidence) + "\n\n"

        body += "Several themes support this arc:\n\n"

        for thread in threads {
            body += "**\(thread.title).**\n"
            body += thread.body + "\n\n"
        }

        if let pattern = patterns.sorted(by: { $0.confidence > $1.confidence }).first {
            let hedged = hedge(pattern.observation, confidence: pattern.confidence)
            body += "The strongest pattern emerging: \(hedged) "
            body += "(based on \(pattern.sampleCount) observations).\n\n"
        }

        body += "These patterns aren't fixed — they're living observations of your life as it actually unfolds. As you add more data and new experiences, the patterns shift, the threads reweave, and your narrative deepens."

        return body
    }
}
