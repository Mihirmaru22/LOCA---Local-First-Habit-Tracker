//
//  HabitDetailView.swift
//  LOCA
//
//  Phase 11.3b — Habit Detail: Heatmap-First Redesign
//
//  Restructures the detail page around the heatmap as the hero visualization.
//  Flow: Heatmap (history, primary focus) → Metrics 2×2 (today's snapshot,
//  secondary) → Journal (activity details, tertiary).
//
//  This inverts the Phase 10 hierarchy (ring → heatmap → stats) to reflect
//  the actual information value for decision-making: patterns matter more
//  than today's data point.
//

import SwiftUI
import SwiftData

// MARK: - HabitDetailView

struct HabitDetailView: View {

    let board: HabitBoard
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditSheet = false

    // MARK: - Computed metrics

    /// Days completed this month (value >= target).
    private var daysCompletedThisMonth: Int {
        let now = Date()
        guard let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now)) else {
            return 0
        }
        guard let monthEnd = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            return 0
        }

        let logsThisMonth = (board.logs ?? []).filter { log in
            log.timestamp >= monthStart && log.timestamp <= monthEnd
        }

        // Group by day and sum values
        var dailyTotals = [Date: Double]()
        for log in logsThisMonth {
            let day = Calendar.current.startOfDay(for: log.timestamp)
            dailyTotals[day, default: 0] += log.value
        }

        return dailyTotals.filter { $0.value >= board.effectiveTarget }.count
    }

    /// Days in the current month.
    private var daysInMonth: Int {
        let now = Date()
        guard let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now)) else {
            return 30
        }
        guard let range = Calendar.current.range(of: .day, in: .month, for: monthStart) else {
            return 30
        }
        return range.count
    }

    /// Total logged this month.
    private var totalThisMonth: Double {
        let now = Date()
        guard let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now)) else {
            return 0
        }
        guard let monthEnd = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            return 0
        }

        return (board.logs ?? [])
            .filter { $0.timestamp >= monthStart && $0.timestamp <= monthEnd }
            .reduce(0.0) { $0 + $1.value }
    }

    /// Last 7 days' daily totals (oldest to newest) for the weekly chart.
    private var weeklyTotals: [Double] {
        var totals: [Double] = []
        for daysAgo in (0..<7).reversed() {
            guard let dayDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) else {
                totals.append(0)
                continue
            }
            let dayStart = Calendar.current.startOfDay(for: dayDate)
            guard let dayEnd = Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: dayStart) else {
                totals.append(0)
                continue
            }

            let dayTotal = (board.logs ?? [])
                .filter { $0.timestamp >= dayStart && $0.timestamp <= dayEnd }
                .reduce(0.0) { $0 + $1.value }
            totals.append(dayTotal)
        }
        return totals
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xxl) {

                // MARK: - Heatmap Hero
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    HeatmapView(board: board)
                }

                // MARK: - Metrics Grid (2×2)
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    SectionHeader("Metrics")

                    HStack(spacing: DS.Space.lg) {
                        // Left column
                        VStack(spacing: DS.Space.lg) {
                            // Streak
                            LOCACard {
                                MetricTile(
                                    icon: "flame.fill",
                                    value: "\(board.currentStreak)",
                                    label: "Current Streak",
                                    accent: ColorPalette[board.colorIndex]
                                )
                            }

                            // Consistency gauge
                            LOCACard {
                                ArcGaugeView(
                                    completedCount: daysCompletedThisMonth,
                                    totalCount: daysInMonth,
                                    accentColor: ColorPalette[board.colorIndex],
                                    label: "Days"
                                )
                            }
                        }

                        // Right column
                        VStack(spacing: DS.Space.lg) {
                            // Month total
                            LOCACard {
                                VStack(alignment: .leading, spacing: DS.Space.sm) {
                                    HStack(spacing: DS.Space.xs) {
                                        Image(systemName: "calendar")
                                            .font(DS.Text.caption)
                                            .foregroundStyle(ColorPalette[board.colorIndex])
                                        Text("THIS MONTH")
                                            .font(DS.Text.footnote)
                                            .foregroundStyle(DS.Color.textSecondary)
                                            .tracking(0.5)
                                    }

                                    ValueText(
                                        totalThisMonth.formatted(.number.precision(.fractionLength(0...1))),
                                        font: DS.Text.value
                                    )
                                    .foregroundStyle(DS.Color.textPrimary)

                                    if let unitLabel = board.unitLabel, !unitLabel.isEmpty {
                                        Text(unitLabel)
                                            .font(DS.Text.caption)
                                            .foregroundStyle(DS.Color.textSecondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            // Weekly chart
                            LOCACard {
                                VStack(alignment: .leading, spacing: DS.Space.md) {
                                    Text("PAST WEEK")
                                        .font(DS.Text.footnote)
                                        .foregroundStyle(DS.Color.textSecondary)
                                        .tracking(0.5)

                                    WeeklyBarChart(
                                        dailyTotals: weeklyTotals,
                                        target: board.effectiveTarget,
                                        accentColor: ColorPalette[board.colorIndex],
                                        size: .normal
                                    )
                                    .frame(height: 48)
                                }
                            }
                        }
                    }
                }

                // MARK: - Journal Timeline
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    SectionHeader("Activity")

                    JournalTimelineView(board: board)
                }

                Spacer(minLength: DS.Space.xxxl)
            }
            .padding(DS.Space.lg)
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
