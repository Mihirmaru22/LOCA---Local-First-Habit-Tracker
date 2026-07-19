//
//  HabitDetailView.swift
//  LOCA
//
//  Phase 12.3 — Habit Detail: Three-Surface Redesign
//
//  Restructures the detail page into three surfaces accessible via bottom tabs:
//  - Analytics: charts and trend visualizations
//  - Check-ins: today's status and quick logging interface
//  - Journal: day-grouped activity timeline
//
//  This separation allows each surface to focus on its purpose without
//  compression, and provides a natural workflow: review trends → log today →
//  reflect on history.
//

import SwiftUI
import SwiftData

// MARK: - HabitDetailView

struct HabitDetailView: View {

    let board: HabitBoard
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditSheet = false
    @State private var _selectedTab = 0


    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $_selectedTab) {
                // Analytics Tab
                HabitAnalyticsView(board: board)
                    .tag(0)

                // Check-ins Tab
                HabitCheckInsView(board: board)
                    .tag(1)

                // Journal Tab
                HabitJournalView(board: board)
                    .tag(2)
            }
            .pagedTabView()
        }
        .navigationTitle(board.name)
        .largeNavigationTitleDisplay()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingEditSheet = true }) {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            HabitFormView(mode: .edit(board))
        }
    }
}

// MARK: - Preview

@MainActor
private func makeDetailPreviewContainer() -> (ModelContainer, HabitBoard) {
    let schema = Schema([HabitBoard.self, LogEntry.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let context = container.mainContext

    let habit = HabitBoard(name: "Morning Run", metricType: 1, targetValue: 5, unitLabel: "km", colorIndex: 0)
    habit.currentStreak = 12
    habit.longestStreak = 45
    context.insert(habit)

    // Add logs across this month
    let now = Date()
    let calendar = Calendar.current
    guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
        return (container, habit)
    }

    for daysAgo in 0..<30 {
        if daysAgo % 2 == 0 { // Log every other day
            guard let logDate = calendar.date(byAdding: .day, value: daysAgo, to: monthStart) else { continue }
            let value = Double.random(in: 3...7)
            context.insert(LogEntry(timestamp: logDate, value: value, boardID: habit.id, board: habit))
        }
    }

    try? context.save()
    return (container, habit)
}

#Preview {
    let (container, habit) = makeDetailPreviewContainer()
    return NavigationStack {
        HabitDetailView(board: habit)
    }
    .modelContainer(container)
}
