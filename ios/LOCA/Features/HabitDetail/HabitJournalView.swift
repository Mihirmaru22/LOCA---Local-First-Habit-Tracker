//
//  HabitJournalView.swift
//  LOCA
//
//  Phase 12.3 — Journal surface for habit details.
//
//  Shows the activity timeline: day-grouped entries with notes, timestamps,
//  and values. Provides swipe-to-delete and the ability to add quick notes.
//

import SwiftUI
import SwiftData

struct HabitJournalView: View {

    let board: HabitBoard

    var body: some View {
        JournalTimelineView(board: board)
    }
}

#Preview {
    @MainActor
    func makeContainer() -> (ModelContainer, HabitBoard) {
        let schema = Schema([HabitBoard.self, LogEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let habit = HabitBoard(name: "Reading", metricType: 1, targetValue: 30, unitLabel: "min", colorIndex: 4)
        container.mainContext.insert(habit)

        // Add some sample logs
        for daysAgo in 0..<7 {
            if let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) {
                let entry = LogEntry(timestamp: date, value: Double.random(in: 20...60), boardID: habit.id, board: habit)
                container.mainContext.insert(entry)
            }
        }

        try? container.mainContext.save()
        return (container, habit)
    }

    let (container, habit) = makeContainer()
    return HabitJournalView(board: habit)
        .modelContainer(container)
}
