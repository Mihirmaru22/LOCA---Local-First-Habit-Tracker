//
//  HabitAnalyticsView.swift
//  LOCA
//
//  Phase 12.3 — Analytics surface for habit details.
//
//  Displays charts and trend visualizations: timeline, streaks, year comparison,
//  consistency, amount ranges. Scrollable collection of analytic cards.
//

import SwiftUI
import SwiftData

struct HabitAnalyticsView: View {

    let board: HabitBoard

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.lg) {

                Text("Analytics coming in Phase 12.3.2")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(DS.Space.xl)

                Spacer(minLength: DS.Space.xxxl)
            }
            .padding(DS.Space.lg)
        }
    }
}

#Preview {
    @MainActor
    func makeContainer() -> (ModelContainer, HabitBoard) {
        let schema = Schema([HabitBoard.self, LogEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let habit = HabitBoard(name: "Boxing", metricType: 1, targetValue: 1, unitLabel: "sessions", colorIndex: 1)
        container.mainContext.insert(habit)
        try? container.mainContext.save()
        return (container, habit)
    }

    let (container, habit) = makeContainer()
    return HabitAnalyticsView(board: habit)
        .modelContainer(container)
}
