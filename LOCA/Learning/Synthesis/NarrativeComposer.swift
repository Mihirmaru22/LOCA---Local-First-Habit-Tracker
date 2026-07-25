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

import Foundation
import SwiftData

// MARK: - Life Narrative

struct LifeNarrative {
    /// The main story arc (e.g., "growing into rhythm")
    let arc: String

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

        // Compose narrative body from arc + threads
        let body = composeBody(arc: arc, threads: threads, patterns: workingPatterns)

        return LifeNarrative(
            arc: arc,
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
            let habits = habitPatterns.prefix(3).map { $0.observation }.joined(separator: " Also, ")
            threads.append(NarrativeThread(
                title: "Your anchoring habits",
                body: habits + " These habits appear to be part of what sustains your baseline.",
                patternIds: habitPatterns.prefix(3).map { $0.id }
            ))
        }

        // Thread 2: People theme (if multiple person-state patterns)
        let peoplePatterns = patterns.filter { $0.layer == .personState }.sorted { $0.confidence > $1.confidence }
        if !peoplePatterns.isEmpty {
            let people = peoplePatterns.prefix(2).map { $0.observation }.joined(separator: " Similarly, ")
            threads.append(NarrativeThread(
                title: "The people in your rhythm",
                body: people + " The specific people around you shape your inner states.",
                patternIds: peoplePatterns.prefix(2).map { $0.id }
            ))
        }

        // Thread 3: Consistency theme (if habit-chapter patterns exist)
        let consistencyPatterns = patterns.filter { $0.layer == .habitChapter }.sorted { $0.confidence > $1.confidence }
        if !consistencyPatterns.isEmpty {
            let consistency = consistencyPatterns.first?.observation ?? "Something stays constant"
            threads.append(NarrativeThread(
                title: "What persists",
                body: consistency + " This consistency across your life's chapters suggests a core thread running through everything.",
                patternIds: consistencyPatterns.prefix(1).map { $0.id }
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

        // Otherwise, infer from chapter progression + patterns
        let chapterCount = chapters.count

        if chapterCount <= 1 {
            // Early story
            let moodPatterns = patterns.filter { $0.layer == .chapterState }
            if let moodPattern = moodPatterns.first {
                return "Beginning to find your rhythm"
            }
            return "Finding your way"
        }

        if chapterCount <= 3 {
            // Mid story: multiple chapters
            let consistentHabits = patterns.filter { $0.layer == .habitChapter }
            if !consistentHabits.isEmpty {
                return "Discovering what stays steady through change"
            }
            return "Learning what matters across different chapters"
        }

        // Longer story: explicit narrative
        let strongPatterns = patterns.filter { $0.confidence >= 0.6 }
        if strongPatterns.count >= 3 {
            return "Your life is shaped by consistent patterns beneath the changing chapters"
        }

        return "Growing through different chapters"
    }

    // MARK: - Narrative Composition

    private func composeBody(
        arc: String,
        threads: [NarrativeThread],
        patterns: [LifePattern]
    ) -> String {
        var body = ""

        body += "The arc of your life, as reflected in your data: \(arc).\n\n"

        body += "Several themes support this arc:\n\n"

        for (i, thread) in threads.enumerated() {
            body += "**\(thread.title).**\n"
            body += thread.body + "\n\n"
        }

        let mostConfident = patterns.sorted { $0.confidence > $1.confidence }.prefix(1)
        if let pattern = mostConfident.first {
            body += "The strongest pattern emerging: \(pattern.observation) "
            body += "(based on \(pattern.sampleCount) observations, with \(String(format: "%.0f", pattern.confidence * 100))% confidence).\n\n"
        }

        body += "These patterns aren't fixed — they're living observations of your life as it actually unfolds. As you add more data and new experiences, the patterns shift, the threads reweave, and your narrative deepens."

        return body
    }
}
