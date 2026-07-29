//
//  PresentComposer.swift
//  LOCA
//
//  Phase 8, Session 8.1 — Compose the Present from the life model.
//
//  This is the writer, not the reporter. It takes the life model snapshot
//  and produces natural-language observations anchored in the user's own
//  history — not stats, not verdicts, not charts.
//
//  Three rules on language output:
//  1. Never a verdict ("you're doing well").
//  2. Never a prescription ("you should rest").
//  3. Soft where uncertain ("tends to" not "is", "has been" not "is always").
//

import Foundation
import SwiftData

// MARK: - Present Composer

@MainActor
final class PresentComposer {
    static let shared = PresentComposer()

    // How many days of recent states to use for the "present" reading.
    private let recentWindowDays = 7
    // Minimum delta (vs. baseline) worth surfacing.
    private let noticeableThreshold = 0.05

    // MARK: - Public API

    func compose(modelContext: ModelContext) throws -> PresentScene {
        let tod = TimeOfDay.current
        let calendar = Calendar.current
        let now = Date()

        // Time context: "Tuesday evening"
        let weekday = calendar.weekdaySymbols[calendar.component(.weekday, from: now) - 1]
        let timeContext = "\(weekday) \(tod.label)"

        // Chapter context.
        let chapters = try modelContext.fetch(
            FetchDescriptor<Chapter>(predicate: #Predicate { $0.isCurrentChapter })
        )
        let currentChapter = chapters.first

        // Direction context.
        let directions = try modelContext.fetch(
            FetchDescriptor<Direction>(predicate: #Predicate { $0.isActive })
        )
        let activeDirection = directions.first

        // Fork context: unresolved forks that might need attention.
        let unresolvedForks = try modelContext.fetch(
            FetchDescriptor<Fork>(
                predicate: #Predicate { !$0.resolved },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
        )

        // Recent states.
        let windowStart = calendar.date(byAdding: .day, value: -recentWindowDays, to: now)!
        let recentDesc = FetchDescriptor<InferredState>(
            predicate: #Predicate { $0.timestamp >= windowStart },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        let recentStates = try modelContext.fetch(recentDesc)

        guard recentStates.count >= 4 else {
            return emptyScene(timeContext: timeContext, chapterName: currentChapter?.name)
        }

        // Compute signals.
        let signals = computeSignals(recent: recentStates, chapter: currentChapter)

        // Find the most notable signal and secondary signal.
        let ranked = signals.sorted { abs($0.delta) * $0.confidence > abs($1.delta) * $1.confidence }
        let primary = ranked.first
        let secondary = ranked.dropFirst().first(where: { abs($0.delta) >= noticeableThreshold })

        // Compose headline from the most notable signal.
        let headline = primary.map { composeHeadline($0, tod: tod) } ?? quietHeadline(tod: tod)

        // Support: secondary signal or a relational observation.
        let support: String?
        if let sec = secondary {
            support = composeSupport(sec, primary: primary)
        } else {
            support = nil
        }

        // Soft thread: offered only when something is genuinely worth investigating
        // and we have real confidence in it. Prioritize unresolved forks (self-turning mode).
        let softThread: SoftThread?
        if let fork = unresolvedForks.first {
            softThread = composeForkThread(fork)
        } else {
            softThread = composeSoftThread(ranked: ranked, chapter: currentChapter)
        }

        return PresentScene(
            timeContext: timeContext,
            chapterName: currentChapter?.name,
            directionStatement: activeDirection?.statement,
            headline: headline,
            support: support,
            softThread: softThread,
            signals: signals,
            generatedAt: now,
            timeOfDay: tod
        )
    }

    // MARK: - Reach Slices (8.2)

    func reachSlices(modelContext: ModelContext) throws -> [ReachSlice] {
        var slices: [ReachSlice] = []

        let chapters = try modelContext.fetch(
            FetchDescriptor<Chapter>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        )
        let events = try modelContext.fetch(
            FetchDescriptor<LifeEvent>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        )

        // Present slice — already composed elsewhere, just a placeholder.
        slices.append(ReachSlice(
            depth: .present,
            headline: "Now",
            body: nil,
            landmarks: []
        ))

        // Recent days.
        slices.append(recentDaysSlice(chapters: chapters))

        // Chapter slice.
        if let current = chapters.first(where: { $0.isCurrentChapter }) {
            slices.append(chapterSlice(current))
        }

        // Full life.
        slices.append(fullLifeSlice(chapters: chapters, events: events))

        return slices
    }

    // MARK: - Signal Computation

    private func computeSignals(recent: [InferredState], chapter: Chapter?) -> [StateSignal] {
        let baseline = StateBaseline(chapter: chapter)
        guard !recent.isEmpty else { return [] }

        let meanEnergy = mean(recent.map { $0.energy })
        let meanStress = mean(recent.map { $0.stress })
        let meanFocus  = mean(recent.map { $0.focus })
        let meanMood   = mean(recent.map { $0.mood })

        // Is the most recent 2 days more extreme than the week average?
        let veryRecent = recent.suffix(8) // ~2 days of 4 readings/day
        let trending: (Double, Double) -> Bool = { dim, baseline in
            guard veryRecent.count >= 4 else { return false }
            return abs(dim - baseline) > 0.12
        }

        let conf = min(1.0, Double(recent.count) / 28.0)

        return [
            StateSignal(dimension: .energy, delta: meanEnergy - baseline.energy,
                        confidence: conf,
                        trending: trending(mean(veryRecent.map { $0.energy }), baseline.energy)),
            StateSignal(dimension: .stress, delta: meanStress - baseline.stress,
                        confidence: conf,
                        trending: trending(mean(veryRecent.map { $0.stress }), baseline.stress)),
            StateSignal(dimension: .focus,  delta: meanFocus  - baseline.focus,
                        confidence: conf,
                        trending: trending(mean(veryRecent.map { $0.focus }),  baseline.focus)),
            StateSignal(dimension: .mood,   delta: meanMood   - baseline.mood,
                        confidence: conf,
                        trending: trending(mean(veryRecent.map { $0.mood }),   baseline.mood)),
        ]
    }

    // MARK: - Language Generation

    private func composeHeadline(_ signal: StateSignal, tod: TimeOfDay) -> String {
        let dim = signal.dimension.label.lowercased()
        let direction = signal.delta > 0 ? "above" : "below"
        let qualifier = abs(signal.delta) > 0.15 ? "noticeably " : ""

        // Night: never evaluative, never heavy.
        if tod == .night {
            if signal.delta < -0.1 {
                return "It's been a softer few days."
            } else {
                return "Things have been \(qualifier)steady."
            }
        }

        if signal.trending {
            let trend = signal.delta > 0 ? "building" : "easing"
            return "\(dim.capitalized) has been \(trend) — \(qualifier)\(direction) your baseline for this chapter."
        }

        return "\(dim.capitalized) has been \(qualifier)\(direction) your baseline for this chapter this week."
    }

    private func composeSupport(_ signal: StateSignal, primary: StateSignal?) -> String? {
        let dim = signal.dimension.label.lowercased()
        let direction = signal.delta > 0 ? "higher" : "lower"

        // Relational: does this second signal move with or against the primary?
        if let p = primary {
            let sameDirection = (p.delta > 0) == (signal.delta > 0)
            if p.dimension == .energy && signal.dimension == .focus && sameDirection {
                return "Focus has been tracking it."
            }
            if p.dimension == .stress && signal.dimension == .mood && !sameDirection {
                return "Mood has been holding against it."
            }
            if p.dimension == .stress && signal.dimension == .mood && sameDirection {
                return "Mood has followed."
            }
        }

        return "\(dim.capitalized) has been \(direction) than usual, too."
    }

    private func quietHeadline(tod: TimeOfDay) -> String {
        switch tod {
        case .morning:   return "Nothing unusual in the last few days. A steady start."
        case .afternoon: return "Things have been within your normal range."
        case .evening:   return "A quiet stretch — close to your baseline for this chapter."
        case .night:     return "It's been steady."
        }
    }

    private func composeForkThread(_ fork: Fork) -> SoftThread {
        let label: String
        if fork.kind == .decision {
            label = "You faced a choice: \"\(fork.statement)\""
        } else if fork.kind == .inflection {
            label = "Something shifted: \"\(fork.statement)\""
        } else { // question
            label = "A question remains: \"\(fork.statement)\""
        }

        let question = "About this fork: \(fork.statement) — how did I resolve it, or where is it now?"
        return SoftThread(label: label, prefilledQuestion: question)
    }

    private func composeSoftThread(ranked: [StateSignal], chapter: Chapter?) -> SoftThread? {
        // Only surface a thread when a signal is confident and meaningfully off-baseline.
        guard let top = ranked.first,
              abs(top.delta) >= 0.08,
              top.confidence >= 0.5 else { return nil }

        let dim = top.dimension
        let dirText = top.delta > 0 ? "higher than usual" : "lower than usual"
        let chCtx = chapter.map { " in \"\($0.name)\"" } ?? ""

        switch dim {
        case .mood:
            return SoftThread(
                label: "Mood has been \(dirText)\(chCtx) lately.",
                prefilledQuestion: "What's been going on with my mood recently?"
            )
        case .energy:
            return SoftThread(
                label: "Energy has been \(dirText) this week.",
                prefilledQuestion: "What has been driving my energy this week?"
            )
        case .stress:
            let label = top.delta > 0
                ? "Stress has been building above your baseline."
                : "Stress has been lower than your usual."
            return SoftThread(
                label: label,
                prefilledQuestion: "What's been happening with my stress lately?"
            )
        case .focus:
            return SoftThread(
                label: "Focus has been \(dirText) this week.",
                prefilledQuestion: "What has been shaping my focus this week?"
            )
        }
    }

    // MARK: - Reach Slice Helpers

    private func recentDaysSlice(chapters: [Chapter]) -> ReachSlice {
        let current = chapters.first(where: { $0.isCurrentChapter })
        let chapterTag = current.map { " in \"\($0.name)\"" } ?? ""
        return ReachSlice(
            depth: .recentDays,
            headline: "The last week\(chapterTag)",
            body: "Each day's texture — the grain of individual moments — is still vivid here.",
            landmarks: []
        )
    }

    private func chapterSlice(_ chapter: Chapter) -> ReachSlice {
        let duration: String
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: chapter.startDate, to: Date()).day ?? 0
        if days < 14 {
            duration = "\(days) days in"
        } else if days < 60 {
            duration = "\(days / 7) weeks in"
        } else {
            duration = "\(days / 30) months in"
        }

        let moodPct = Int((chapter.baselineMood * 100).rounded())
        let body = "Baseline mood: \(moodPct)%. \(duration)."

        return ReachSlice(
            depth: .chapter,
            headline: chapter.name ?? "This Chapter",
            body: body,
            landmarks: []
        )
    }

    private func fullLifeSlice(chapters: [Chapter], events: [LifeEvent]) -> ReachSlice {
        let count = chapters.count
        let chapterLabel = count == 1 ? "one chapter" : "\(count) chapters"

        let now = Date()
        var landmarks: [LifeLandmark] = []

        // Oldest date in the record.
        let oldest = chapters.map { $0.startDate }.min() ?? now
        let span = now.timeIntervalSince(oldest)
        guard span > 0 else {
            return ReachSlice(depth: .fullLife, headline: "Your life so far", body: "Just getting started.", landmarks: [])
        }

        for chapter in chapters {
            let pos = now.timeIntervalSince(chapter.startDate) / span
            landmarks.append(LifeLandmark(id: chapter.id, label: chapter.name ?? "—", position: min(1, pos), isEvent: false))
        }
        for event in events.prefix(6) {
            let pos = now.timeIntervalSince(event.timestamp) / span
            let label = event.metadata["summary"] ?? event.eventType.rawValue
            landmarks.append(LifeLandmark(id: event.id, label: label, position: min(1, pos), isEvent: true))
        }

        return ReachSlice(
            depth: .fullLife,
            headline: "Your life — \(chapterLabel)",
            body: "Chapters as distinct territories. The seams between them are the things that mattered.",
            landmarks: landmarks.sorted { $0.position < $1.position }
        )
    }

    // MARK: - Empty Scene

    private func emptyScene(timeContext: String, chapterName: String?) -> PresentScene {
        let headline: String
        switch TimeOfDay.current {
        case .morning:   headline = "Not enough history yet to read the present clearly. It builds every day."
        case .afternoon: headline = "Still early. The model needs a few more days to find your pattern."
        case .evening:   headline = "A few more days and the present will start to speak."
        case .night:     headline = "Getting there. The picture sharpens over time."
        }

        return PresentScene(
            timeContext: timeContext,
            chapterName: chapterName,
            directionStatement: nil,
            headline: headline,
            support: nil,
            softThread: nil,
            signals: [],
            generatedAt: Date(),
            timeOfDay: .current
        )
    }

    // MARK: - Helpers

    private func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
}

// MARK: - State Baseline

/// Chapter baselines, with population fallbacks for thin-data cases.
private struct StateBaseline {
    let energy: Double
    let stress: Double
    let focus:  Double
    let mood:   Double

    init(chapter: Chapter?) {
        energy = chapter?.baselineEnergy ?? 0.50
        stress = chapter?.baselineStress ?? 0.45
        focus  = chapter?.baselineFocus  ?? 0.50
        mood   = chapter?.baselineMood   ?? 0.55
    }
}
