//
//  HabitAnalyticsView.swift
//  LOCA
//
//  Phase 12.3 — Analytics surface for habit details.
//
//  Displays heatmap hero and key metrics at a glance: streak, consistency,
//  month total, and past week trend. Future phases add additional charts.
//

import SwiftUI
import SwiftData

struct HabitAnalyticsView: View {

    let board: HabitBoard

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
                LOCACard {
                    HeatmapView(board: board)
                        .frame(maxHeight: .infinity)
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

                // Clearance for the floating SurfaceSelector pill.
                Spacer(minLength: DS.Space.xxxl + DS.Space.xl)
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
