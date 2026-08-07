//
//  PatternDetectionEngine.swift
//  LOCA
//
//  Phase 9, Session 9.1 — Pattern detection across life layers.
//
//  Synthesize cross-cutting patterns from habits, states, people, and chapters.
//  A pattern is a causal hypothesis: "your energy is higher on days you exercise"
//  or "stress drops after seeing Sarah". Patterns are shown honestly — soft where
//  uncertain, never prescriptive.
//
//  C5: all pattern confidence is produced by UncertaintyCalculus (Rules A + B).
//  Per-state uncertainty enters the computation and a pattern-level uncertainty is
//  carried on every LifePattern so downstream synthesis can propagate it further.
//

import Foundation
import SwiftData

// MARK: - Pattern Value Types

struct LifePattern: Identifiable {
    /// Stable across detection runs: derived from (layer, explorableQuestion) so that
    /// user feedback stored against a pattern in one run still matches the same pattern
    /// re-detected in a later run. (Previously a random UUID() per construction, which
    /// made the feedback join structurally dead.)
    let id: UUID

    /// The pattern statement in natural language
    let observation: String

    /// Which layers does this pattern cross?
    enum Layer: String {
        case habitState     // habit frequency ↔ state
        case personState    // time with a person ↔ state change
        case chapterState   // chapter ↔ state rhythm
        case habitChapter   // habit consistency across chapters
    }
    let layer: Layer

    /// How confident are we? (0–1) — produced by UncertaintyCalculus, never hardcoded.
    let confidence: Double

    /// Pattern-level uncertainty (0–1), propagated from the contributing states via Rule A.
    /// Carried so narratives/scenes can keep propagating uncertainty instead of dropping it.
    let uncertainty: Double

    /// Sample size underlying this pattern
    let sampleCount: Int

    /// The prefilled question to explore this pattern
    let explorableQuestion: String

    init(
        observation: String,
        layer: Layer,
        confidence: Double,
        uncertainty: Double,
        sampleCount: Int,
        explorableQuestion: String
    ) {
        self.id = LifePattern.stableID(layer: layer, explorableQuestion: explorableQuestion)
        self.observation = observation
        self.layer = layer
        self.confidence = confidence
        self.uncertainty = uncertainty
        self.sampleCount = sampleCount
        self.explorableQuestion = explorableQuestion
    }

    /// Deterministic identity for a pattern's semantic slot (layer + exploration question),
    /// which is stable across runs even as confidence/direction change.
    static func stableID(layer: Layer, explorableQuestion: String) -> UUID {
        deterministicUUID(from: "\(layer.rawValue)|\(explorableQuestion)")
    }
}

/// Deterministic UUID from a string via two FNV-1a-style 64-bit hashes.
/// Same input → same UUID, with no Foundation crypto dependency. Used for stable
/// pattern identity so the feedback join is live across detection runs.
func deterministicUUID(from key: String) -> UUID {
    var h1: UInt64 = 0xcbf29ce484222325
    var h2: UInt64 = 0x84222325cbf29ce4
    for b in key.utf8 {
        h1 = (h1 ^ UInt64(b)) &* 0x100000001b3
        h2 = (h2 &* 0x100000001b3) ^ UInt64(b)
    }
    func byte(_ v: UInt64, _ shift: UInt64) -> UInt8 { UInt8((v >> shift) & 0xff) }
    let bytes: uuid_t = (
        byte(h1, 56), byte(h1, 48), byte(h1, 40), byte(h1, 32),
        byte(h1, 24), byte(h1, 16), byte(h1, 8), byte(h1, 0),
        byte(h2, 56), byte(h2, 48), byte(h2, 40), byte(h2, 32),
        byte(h2, 24), byte(h2, 16), byte(h2, 8), byte(h2, 0)
    )
    return UUID(uuid: bytes)
}

// MARK: - Engine

@MainActor
final class PatternDetectionEngine {
    static let shared = PatternDetectionEngine()

    private let minDaysForPattern = 14
    // Minimum effect confidence (from Rule B) for a pattern to be surfaced at all.
    private let minSurfaceConfidence = 0.4

    // MARK: - Public API

    func detectPatterns(modelContext: ModelContext) throws -> [LifePattern] {
        var patterns: [LifePattern] = []

        let states = try modelContext.fetch(
            FetchDescriptor<InferredState>(sortBy: [SortDescriptor(\.timestamp)])
        )
        let logs = try modelContext.fetch(FetchDescriptor<LogEntry>())
        let boards = try modelContext.fetch(FetchDescriptor<HabitBoard>())
        let chapters = try modelContext.fetch(
            FetchDescriptor<Chapter>(sortBy: [SortDescriptor(\.startDate)])
        )

        guard states.count >= minDaysForPattern else { return [] }

        // Habit ↔ State patterns
        patterns.append(contentsOf: habitStatePatterns(
            boards: boards,
            logs: logs,
            states: states
        ))

        // Chapter rhythm patterns
        patterns.append(contentsOf: chapterStatePatterns(
            states: states,
            chapters: chapters
        ))

        // Habit consistency across chapters
        patterns.append(contentsOf: habitChapterPatterns(
            boards: boards,
            logs: logs,
            chapters: chapters
        ))

        // Apply feedback-adjusted confidence and consume refinement hints.
        // The join is now live because LifePattern.id is stable across runs.
        let processor = FeedbackProcessor.shared
        let feedbackMap = try processor.loadPatternFeedback(modelContext: modelContext)
        patterns = patterns.compactMap { pattern in
            guard let feedback = feedbackMap[pattern.id] else { return pattern }
            let adjusted = processor.adjustedConfidence(for: pattern, feedback: feedback)
            _ = processor.refinementHints(from: feedback)  // Consume hints for future pattern refinement
            return LifePattern(
                observation: pattern.observation,
                layer: pattern.layer,
                confidence: adjusted,
                uncertainty: pattern.uncertainty,
                sampleCount: pattern.sampleCount,
                explorableQuestion: pattern.explorableQuestion
            )
        }

        return patterns.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Habit × State Patterns

    private func habitStatePatterns(
        boards: [HabitBoard],
        logs: [LogEntry],
        states: [InferredState]
    ) -> [LifePattern] {
        var patterns: [LifePattern] = []

        for board in boards {
            let boardLogs = logs.filter { $0.boardID == board.id }
            guard boardLogs.count >= 5 else { continue }

            // Group logs by day
            let logsByDay = Dictionary(grouping: boardLogs) { log in
                Calendar.current.startOfDay(for: log.timestamp)
            }

            // C1: only include present mood measurements — absent states (mood=0.0)
            // are not low-mood evidence; they are no-data evidence.
            var moodWithHabit: [Double] = []
            var uncertaintyWithHabit: [Double] = []
            var moodWithoutHabit: [Double] = []
            var uncertaintyWithoutHabit: [Double] = []

            for state in states where !state.moodAbsent {
                let day = Calendar.current.startOfDay(for: state.timestamp)
                if logsByDay[day] != nil {
                    moodWithHabit.append(state.mood)
                    uncertaintyWithHabit.append(state.moodUncertainty)
                } else {
                    moodWithoutHabit.append(state.mood)
                    uncertaintyWithoutHabit.append(state.moodUncertainty)
                }
            }

            guard moodWithHabit.count >= 4, moodWithoutHabit.count >= 2 else { continue }

            // Rule A: aggregate each group (mean + propagated uncertainty).
            let withAgg = aggregateUncertainty(values: moodWithHabit, uncertainties: uncertaintyWithHabit)
            let withoutAgg = aggregateUncertainty(values: moodWithoutHabit, uncertainties: uncertaintyWithoutHabit)
            let delta = abs(withAgg.mean - withoutAgg.mean)

            guard delta >= 0.08 else { continue }

            // Rule B: effect size vs. combined noise floor → confidence.
            let confidence = differenceConfidence(
                delta: delta,
                uncertaintyA: withAgg.uncertainty,
                uncertaintyB: withoutAgg.uncertainty
            )
            guard confidence >= minSurfaceConfidence else { continue }

            // Pattern-level uncertainty, propagated through Rule A.
            let patternUncertainty = aggregateUncertainty(
                values: [withAgg.mean, withoutAgg.mean],
                uncertainties: [withAgg.uncertainty, withoutAgg.uncertainty]
            ).uncertainty

            let direction = withAgg.mean > withoutAgg.mean ? "higher" : "lower"

            patterns.append(LifePattern(
                observation: "Your mood tends to be \(direction) on days you do \(board.name.lowercased()).",
                layer: .habitState,
                confidence: confidence,
                uncertainty: patternUncertainty,
                sampleCount: moodWithHabit.count,
                explorableQuestion: "How does \(board.name) affect my mood?"
            ))
        }

        return patterns
    }

    // MARK: - Chapter × State Patterns

    private func chapterStatePatterns(
        states: [InferredState],
        chapters: [Chapter]
    ) -> [LifePattern] {
        var patterns: [LifePattern] = []

        for chapter in chapters {
            let end = chapter.endDate ?? Date.distantFuture
            // C1: filter absent mood states before computing chapter and outside means.
            let inChapter = states.filter {
                $0.timestamp >= chapter.startDate && $0.timestamp < end && !$0.moodAbsent
            }
            guard inChapter.count >= 5 else { continue }

            let outsideChapter = states.filter {
                ($0.timestamp < chapter.startDate || $0.timestamp >= end) && !$0.moodAbsent
            }
            guard !outsideChapter.isEmpty else { continue }

            // Rule A: aggregate each group.
            let chapterAgg = aggregateUncertainty(
                values: inChapter.map { $0.mood },
                uncertainties: inChapter.map { $0.moodUncertainty }
            )
            let outsideAgg = aggregateUncertainty(
                values: outsideChapter.map { $0.mood },
                uncertainties: outsideChapter.map { $0.moodUncertainty }
            )
            let moodDelta = chapterAgg.mean - outsideAgg.mean

            guard abs(moodDelta) >= 0.08 else { continue }

            // Rule B: effect vs. noise floor → confidence.
            let confidence = differenceConfidence(
                delta: moodDelta,
                uncertaintyA: chapterAgg.uncertainty,
                uncertaintyB: outsideAgg.uncertainty
            )
            guard confidence >= minSurfaceConfidence else { continue }

            let patternUncertainty = aggregateUncertainty(
                values: [chapterAgg.mean, outsideAgg.mean],
                uncertainties: [chapterAgg.uncertainty, outsideAgg.uncertainty]
            ).uncertainty

            let direction = moodDelta > 0 ? "higher" : "lower"

            if let chapterName = chapter.name {
                patterns.append(LifePattern(
                    observation: "Your mood was measurably \(direction) during \(chapterName).",
                    layer: .chapterState,
                    confidence: confidence,
                    uncertainty: patternUncertainty,
                    sampleCount: inChapter.count,
                    explorableQuestion: "What made \(chapterName) affect my mood this way?"
                ))
            }
        }

        return patterns
    }

    // MARK: - Habit × Chapter Patterns

    private func habitChapterPatterns(
        boards: [HabitBoard],
        logs: [LogEntry],
        chapters: [Chapter]
    ) -> [LifePattern] {
        var patterns: [LifePattern] = []

        for board in boards {
            let boardLogs = logs.filter { $0.boardID == board.id }
            guard boardLogs.count >= 3 else { continue }

            var frequencies: [Double] = []
            var uncertainties: [Double] = []

            for chapter in chapters {
                let end = chapter.endDate ?? Date.distantFuture
                let duration = Int(end.timeIntervalSince(chapter.startDate) / 86400)
                let logsInChapter = boardLogs.filter {
                    $0.timestamp >= chapter.startDate && $0.timestamp < end
                }

                guard duration > 0, !logsInChapter.isEmpty else { continue }

                let freq = Double(logsInChapter.count) / Double(duration)
                frequencies.append(freq)

                // Binomial standard error of the per-chapter frequency estimate.
                let binomialU = sqrt(freq * (1.0 - freq) / Double(duration))
                uncertainties.append(max(0.05, min(0.4, binomialU)))
            }

            guard frequencies.count >= 2 else { continue }

            // Rule A: aggregate the per-chapter frequencies.
            let agg = aggregateUncertainty(values: frequencies, uncertainties: uncertainties)
            let meanFreq = agg.mean

            // Observed spread of the frequencies across chapters.
            let stdDev = sqrt(frequencies.map { pow($0 - meanFreq, 2) }.reduce(0, +) / Double(frequencies.count))

            // Consistency = how much tighter the observed spread is than the estimation noise.
            let consistencyScore = max(0.0, agg.uncertainty - stdDev)
            guard consistencyScore > 0.01 else { continue }

            // Rule B: consistency margin vs. the estimation noise floor → confidence.
            let confidence = differenceConfidence(
                delta: consistencyScore,
                uncertaintyA: agg.uncertainty,
                uncertaintyB: 0.0
            )
            guard confidence >= minSurfaceConfidence else { continue }

            patterns.append(LifePattern(
                observation: "\(board.name) is part of your rhythm — you do it consistently across different chapters.",
                layer: .habitChapter,
                confidence: confidence,
                uncertainty: agg.uncertainty,
                sampleCount: frequencies.count,
                explorableQuestion: "Why has \(board.name) stayed steady across my life?"
            ))
        }

        return patterns
    }
}
