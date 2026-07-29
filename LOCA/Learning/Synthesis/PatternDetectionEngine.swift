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

import Foundation
import SwiftData

// MARK: - Pattern Value Types

struct LifePattern: Identifiable {
    let id: UUID = UUID()

    /// The pattern statement in natural language
    let observation: String

    /// Which layers does this pattern cross?
    enum Layer: String {
        case habitState     // habit frequency ↔ state
        case personState    // person appearance ↔ state
        case chapterState   // chapter ↔ state rhythm
        case habitChapter   // habit consistency across chapters
    }
    let layer: Layer

    /// How confident are we? (0–1)
    let confidence: Double

    /// Sample size underlying this pattern
    let sampleCount: Int

    /// The prefilled question to explore this pattern
    let explorableQuestion: String
}

// MARK: - Engine

@MainActor
final class PatternDetectionEngine {
    static let shared = PatternDetectionEngine()

    private let minDaysForPattern = 14

    // MARK: - Public API

    func detectPatterns(modelContext: ModelContext) throws -> [LifePattern] {
        var patterns: [LifePattern] = []

        let states = try modelContext.fetch(
            FetchDescriptor<InferredState>(sortBy: [SortDescriptor(\.timestamp)])
        )
        let logs = try modelContext.fetch(FetchDescriptor<LogEntry>())
        let boards = try modelContext.fetch(FetchDescriptor<HabitBoard>())
        let people = try modelContext.fetch(FetchDescriptor<Person>())
        let appearances = try modelContext.fetch(FetchDescriptor<PersonAppearance>())
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

        // Person ↔ State patterns (beyond the graph)
        patterns.append(contentsOf: personStatePatterns(
            people: people,
            appearances: appearances,
            states: states,
            chapters: chapters
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

        // Apply feedback-adjusted confidence
        let processor = FeedbackProcessor.shared
        let feedbackMap = try processor.loadPatternFeedback(modelContext: modelContext)
        patterns = patterns.map { pattern in
            guard let feedback = feedbackMap[pattern.id] else { return pattern }
            let adjusted = processor.adjustedConfidence(for: pattern, feedback: feedback)
            return LifePattern(
                observation: pattern.observation,
                layer: pattern.layer,
                confidence: adjusted,
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
            var moodWithoutHabit: [Double] = []

            for state in states where !state.moodAbsent {
                let day = Calendar.current.startOfDay(for: state.timestamp)
                if logsByDay[day] != nil {
                    moodWithHabit.append(state.mood)
                } else {
                    moodWithoutHabit.append(state.mood)
                }
            }

            let withMean = mean(moodWithHabit)
            let withoutMean = mean(moodWithoutHabit)
            let delta = abs(withMean - withoutMean)

            guard delta >= 0.08, moodWithHabit.count >= 4 else { continue }

            let confidence = effectConfidence(magnitude: delta, sampleCount: moodWithHabit.count)
            let direction = withMean > withoutMean ? "higher" : "lower"

            patterns.append(LifePattern(
                observation: "Your mood tends to be \(direction) on days you do \(board.name.lowercased()).",
                layer: .habitState,
                confidence: confidence,
                sampleCount: moodWithHabit.count,
                explorableQuestion: "How does \(board.name) affect my mood?"
            ))
        }

        return patterns
    }

    // MARK: - Person × State Patterns (granular)

    private func personStatePatterns(
        people: [Person],
        appearances: [PersonAppearance],
        states: [InferredState],
        chapters: [Chapter]
    ) -> [LifePattern] {
        var patterns: [LifePattern] = []
        // C1: compute overall energy baseline from present measurements only.
        let overallEnergy = mean(states.filter { !$0.energyAbsent }.map { $0.energy })

        for person in people {
            let personApps = appearances.filter { $0.personId == person.id }
            guard personApps.count >= 3 else { continue }

            let appDates = Set(personApps.map { Calendar.current.startOfDay(for: $0.timestamp) })
            var energyWithPerson: [Double] = []
            var energyWithoutPerson: [Double] = []

            // C1: skip absent energy states — energy=0.0 is not evidence of low energy.
            for state in states where !state.energyAbsent {
                let day = Calendar.current.startOfDay(for: state.timestamp)
                if appDates.contains(day) {
                    energyWithPerson.append(state.energy)
                } else {
                    energyWithoutPerson.append(state.energy)
                }
            }

            let withMean = mean(energyWithPerson)
            let delta = abs(withMean - overallEnergy)
            guard delta >= 0.06, energyWithPerson.count >= 3 else { continue }

            let confidence = effectConfidence(magnitude: delta, sampleCount: energyWithPerson.count)
            let direction = withMean > overallEnergy ? "higher" : "lower"

            patterns.append(LifePattern(
                observation: "Your energy tends to be \(direction) on days around \(person.name).",
                layer: .personState,
                confidence: confidence,
                sampleCount: energyWithPerson.count,
                explorableQuestion: "How does spending time with \(person.name) affect my energy?"
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
            // C1: filter absent mood states before computing chapter and overall means.
            let inChapter = states.filter {
                $0.timestamp >= chapter.startDate && $0.timestamp < end && !$0.moodAbsent
            }
            guard inChapter.count >= 5 else { continue }

            let chapterMood = mean(inChapter.map { $0.mood })
            let overallMood = mean(states.filter { !$0.moodAbsent }.map { $0.mood })
            let moodDelta = chapterMood - overallMood

            guard abs(moodDelta) >= 0.08 else { continue }

            let confidence = effectConfidence(magnitude: abs(moodDelta), sampleCount: inChapter.count)
            let direction = moodDelta > 0 ? "higher" : "lower"

            if let chapterName = chapter.name {
                patterns.append(LifePattern(
                    observation: "Your mood was measurably \(direction) during \(chapterName).",
                    layer: .chapterState,
                    confidence: confidence,
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

            var chapterConsistency: [String: (days: Int, logs: Int)] = [:]
            for chapter in chapters {
                let end = chapter.endDate ?? Date.distantFuture
                let duration = Int(end.timeIntervalSince(chapter.startDate) / 86400)
                let logsInChapter = boardLogs.filter {
                    $0.timestamp >= chapter.startDate && $0.timestamp < end
                }
                if duration > 0 && !logsInChapter.isEmpty, let chapterName = chapter.name {
                    chapterConsistency[chapterName] = (duration, logsInChapter.count)
                }
            }

            guard chapterConsistency.count >= 2 else { continue }

            let frequencies = chapterConsistency.values.map { Double($0.logs) / Double($0.days) }
            let meanFreq = mean(frequencies)
            let variance = frequencies.map { pow($0 - meanFreq, 2) }.reduce(0, +) / Double(frequencies.count)
            let stdDev = sqrt(variance)

            // Low variance → consistent across chapters
            guard stdDev < meanFreq * 0.3 else { continue }

            patterns.append(LifePattern(
                observation: "\(board.name) is part of your rhythm — you do it consistently across different chapters.",
                layer: .habitChapter,
                confidence: 0.6,
                sampleCount: chapterConsistency.count,
                explorableQuestion: "Why has \(board.name) stayed steady across my life?"
            ))
        }

        return patterns
    }

    // MARK: - Helpers

    private func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private func effectConfidence(magnitude: Double, sampleCount: Int) -> Double {
        let sizeFactor = min(1.0, Double(sampleCount) / 30.0)
        let strengthFactor = min(1.0, magnitude / 0.2)
        return min(1.0, (0.25 + 0.75 * strengthFactor) * sizeFactor)
    }
}
