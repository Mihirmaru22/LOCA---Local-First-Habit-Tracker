//
//  ChapterBuilder.swift
//  LOCA
//
//  Phase 5 — Chapter construction from Life Events
//  Segments the user's life into named intervals automatically
//

import Foundation
import SwiftData
import os.log

@MainActor
class ChapterBuilder {
    static let shared = ChapterBuilder()

    private let logger = Logger(subsystem: "com.loca.entities", category: "chapters")

    // MARK: - Build Chapters from Life Events

    func buildChapters(modelContext: ModelContext) throws {
        // Fetch all confirmed + high-confidence Life Events, sorted by time
        let descriptor = FetchDescriptor<LifeEvent>(
            predicate: #Predicate { event in
                event.confidence >= 0.7
            },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        let events = try modelContext.fetch(descriptor)

        // Fetch existing chapters to avoid duplicates
        let existingDescriptor = FetchDescriptor<Chapter>()
        let existing = try modelContext.fetch(existingDescriptor)
        let existingOpeningIds = Set(existing.compactMap { $0.openingEventId })

        // Build new chapters for any event not yet serving as a chapter boundary
        var previousEventDate: Date? = nil

        for (index, event) in events.enumerated() {
            // Close previous chapter at this event
            if let previousDate = previousEventDate {
                // Find the chapter that started at previousDate and close it
                if let openChapter = existing.first(where: {
                    Calendar.current.isDate($0.startDate, inSameDayAs: previousDate) && $0.endDate == nil
                }) {
                    openChapter.endDate = event.timestamp
                    openChapter.closingEventId = event.id
                    openChapter.isCurrentChapter = false
                }
            }

            // Only create a new chapter if this event hasn't been used as an opening boundary
            guard !existingOpeningIds.contains(event.id) else {
                previousEventDate = event.timestamp
                continue
            }

            let chapterName = defaultName(for: event, index: index)
            let chapter = Chapter(
                startDate: event.timestamp,
                name: chapterName,
                openingEventId: event.id
            )

            // Mark previous chapter as closed
            chapter.isCurrentChapter = (index == events.count - 1)

            modelContext.insert(chapter)
            previousEventDate = event.timestamp
        }

        // Ensure there is always a "current chapter" if there are any events
        // or create a "Before everything" chapter starting from the earliest signal
        try ensureCurrentChapter(modelContext: modelContext, events: events)

        try modelContext.save()
        logger.info("Chapters rebuilt from \(events.count) life events")
    }

    // MARK: - Ensure Current Chapter

    private func ensureCurrentChapter(
        modelContext: ModelContext,
        events: [LifeEvent]
    ) throws {
        let allChaptersDescriptor = FetchDescriptor<Chapter>()
        let allChapters = try modelContext.fetch(allChaptersDescriptor)

        let hasCurrentChapter = allChapters.contains { $0.isCurrentChapter }
        guard !hasCurrentChapter else { return }

        // Create a "current chapter" from the latest event or earliest signal
        let startDate: Date
        if let latestEvent = events.last {
            startDate = latestEvent.timestamp
        } else {
            // No events yet — find earliest signal
            let signalDescriptor = FetchDescriptor<SignalEvent>(
                sortBy: [SortDescriptor(\.timestamp)]
            )
            let earliestSignal = try? modelContext.fetch(signalDescriptor).first
            startDate = earliestSignal?.timestamp ?? Date()
        }

        let current = Chapter(
            startDate: startDate,
            name: "Now"
        )
        current.isCurrentChapter = true
        modelContext.insert(current)
    }

    // MARK: - Default Name Generation

    private func defaultName(for event: LifeEvent, index: Int) -> String {
        switch event.eventType {
        case .workChange:    return "New Work Chapter"
        case .locationChange: return "New Place Chapter"
        case .socialChange:  return "Changed Relationships"
        case .healthChange:  return "Health Shift"
        case .scheduleChange: return "New Routine"
        case .habitChange:   return "New Habits"
        case .unknown:       return "Chapter \(index + 1)"
        }
    }

    // MARK: - Compute Chapter Baselines

    func computeBaseline(for chapter: Chapter, modelContext: ModelContext) throws {
        let start = chapter.startDate
        let end = chapter.endDate ?? Date()

        let descriptor = FetchDescriptor<InferredState>(
            predicate: #Predicate { state in
                state.timestamp >= start && state.timestamp <= end
            }
        )

        let states = try modelContext.fetch(descriptor)
        guard !states.isEmpty else { return }

        chapter.baselineEnergy = mean(states.map { $0.energy })
        chapter.baselineStress = mean(states.map { $0.stress })
        chapter.baselineFocus  = mean(states.map { $0.focus })
        chapter.baselineMood   = mean(states.map { $0.mood })
        chapter.volatility     = stddev(states.map { $0.mood })

        // Activity and social from signals
        let signalDescriptor = FetchDescriptor<SignalEvent>(
            predicate: #Predicate { signal in
                signal.timestamp >= start && signal.timestamp <= end
            }
        )
        let signals = try modelContext.fetch(signalDescriptor)

        let motionSignals = signals.filter { $0.source == .motionActivity }
        if !motionSignals.isEmpty {
            chapter.activityLevel = mean(motionSignals.map { $0.value })
        }

        let calendarSignals = signals.filter { $0.source == .calendar }
        if !calendarSignals.isEmpty {
            chapter.socialEngagement = mean(calendarSignals.map { $0.value })
        }

        try modelContext.save()
    }

    // MARK: - Helpers

    private func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0.5 }
        return values.reduce(0, +) / Double(values.count)
    }

    private func stddev(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let m = mean(values)
        let variance = values.map { pow($0 - m, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
}
