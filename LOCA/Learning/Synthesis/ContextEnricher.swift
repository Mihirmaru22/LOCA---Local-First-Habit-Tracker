//
//  ContextEnricher.swift
//  LOCA
//
//  Phase 10, Session 10.3 — Pattern context enrichment.
//
//  For patterns that resonate (high feedback), pull surrounding context
//  (related logs, state snapshots, chapter setting) to deepen narrative understanding
//  of why a pattern matters.
//

import Foundation
import SwiftData

@MainActor final class ContextEnricher {
    static let shared = ContextEnricher()

    private init() {}

    struct PatternContext {
        /// The pattern being enriched
        let pattern: LifePattern

        /// Recent log entries related to this pattern (if habit/person based)
        let relatedLogs: [LogEntry]

        /// State snapshots from dates when pattern was active
        let relatedStates: [InferredState]

        /// Chapter during which this pattern was strongest
        let contextChapter: Chapter?

        /// User's resonance feedback on this pattern (if any)
        let userResonance: Int?

        /// User's notes/refinements for this pattern (if any)
        let userNotes: [String]
    }

    // MARK: - Context Loading

    /// Load contextual evidence for a pattern.
    func enrichPattern(
        _ pattern: LifePattern,
        modelContext: ModelContext,
        feedback: [PatternFeedback] = []
    ) throws -> PatternContext {
        let logs = try modelContext.fetch(FetchDescriptor<LogEntry>())
        let states = try modelContext.fetch(
            FetchDescriptor<InferredState>(sortBy: [SortDescriptor(\.timestamp)])
        )
        let chapters = try modelContext.fetch(
            FetchDescriptor<Chapter>(sortBy: [SortDescriptor(\.startDate)])
        )

        // Extract logs and states related to this pattern
        let (relatedLogs, relatedStates) = extractRelatedData(
            pattern: pattern,
            allLogs: logs,
            allStates: states
        )

        // Find the chapter when this pattern was strongest
        let contextChapter = findContextChapter(
            pattern: pattern,
            states: relatedStates,
            chapters: chapters
        )

        // Extract user feedback signals
        let userResonance = feedback.first?.resonance
        let userNotes = feedback.compactMap { $0.refinement }

        return PatternContext(
            pattern: pattern,
            relatedLogs: relatedLogs,
            relatedStates: relatedStates,
            contextChapter: contextChapter,
            userResonance: userResonance,
            userNotes: userNotes
        )
    }

    // MARK: - Related Data Extraction

    private func extractRelatedData(
        pattern: LifePattern,
        allLogs: [LogEntry],
        allStates: [InferredState]
    ) -> (logs: [LogEntry], states: [InferredState]) {
        var relatedLogs: [LogEntry] = []
        var relatedStates: [InferredState] = []

        switch pattern.layer {
        case .habitState, .habitChapter:
            // Find logs that likely relate to the habit mentioned in pattern.
            // LogEntry has no title; match against the owning board's name and the optional note.
            relatedLogs = allLogs.filter { log in
                let boardName = log.board?.name ?? ""
                return pattern.observation.lowercased().contains(boardName.lowercased()) ||
                    (log.note?.lowercased().contains(pattern.observation.lowercased()) ?? false)
            }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(5)
            .map { $0 }

        case .personState:
            // Find logs with notes mentioning people or social context.
            relatedLogs = allLogs.filter { log in
                pattern.observation.lowercased().contains("time") ||
                pattern.observation.lowercased().contains("person") ||
                (log.note?.lowercased().contains("with") ?? false)
            }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(3)
            .map { $0 }

        case .chapterState:
            break
        }

        // Find state entries from recent window when pattern was active
        if !relatedLogs.isEmpty {
            let timeWindow = relatedLogs.map { $0.timestamp }.max() ?? Date()
            let threshold = timeWindow.addingTimeInterval(-7 * 86400) // Last 7 days

            relatedStates = allStates.filter { state in
                state.timestamp >= threshold && state.timestamp <= timeWindow
            }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(10)
            .map { $0 }
        } else if !allStates.isEmpty {
            // Fallback: recent state snapshots
            relatedStates = Array(allStates.suffix(10))
        }

        return (relatedLogs, relatedStates)
    }

    private func findContextChapter(
        pattern: LifePattern,
        states: [InferredState],
        chapters: [Chapter]
    ) -> Chapter? {
        // Find the chapter containing most of the related states
        guard let oldestState = states.last?.timestamp,
              let newestState = states.first?.timestamp else {
            return nil
        }

        return chapters.first { chapter in
            chapter.startDate <= newestState && (chapter.endDate ?? Date()) >= oldestState
        }
    }

    // MARK: - Context Summarization

    /// Compose a brief narrative context for a pattern.
    func summarizeContext(_ context: PatternContext) -> String {
        var summary = ""

        if let chapter = context.contextChapter, let chapterName = chapter.name {
            summary += "This pattern emerged during \"\(chapterName)\". "
        }

        if !context.relatedLogs.isEmpty {
            let recentActivity = context.relatedLogs.prefix(2).map { $0.note ?? "check-in" }.joined(separator: " and ")
            summary += "Recent activity: \(recentActivity). "
        }

        if let resonance = context.userResonance {
            if resonance == 1 {
                summary += "You've marked this as resonant. "
            } else if resonance == -1 {
                summary += "You've flagged this as off. "
            }
        }

        if !context.userNotes.isEmpty {
            summary += "Your note: \(context.userNotes.joined(separator: " "))"
        }

        return summary.isEmpty ? "This pattern reflects your recent rhythm." : summary
    }

    /// Count how many evidence points support this pattern.
    func confidenceIndicators(_ context: PatternContext) -> Int {
        var count = 0
        if !context.relatedLogs.isEmpty { count += 1 }
        if !context.relatedStates.isEmpty { count += 1 }
        if context.contextChapter != nil { count += 1 }
        if context.userResonance == 1 { count += 1 }
        if !context.userNotes.isEmpty { count += 1 }
        return count
    }
}
