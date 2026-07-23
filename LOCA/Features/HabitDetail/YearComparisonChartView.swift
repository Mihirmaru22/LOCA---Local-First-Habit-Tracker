//
//  YearComparisonChartView.swift
//  LOCA
//
//  Phase 13.3 — Year Comparison analytics chart.
//
//  Canvas-based bar chart showing monthly totals for current year vs previous
//  year side-by-side. Highlights growth or decline month-to-month.
//

import SwiftUI
import SwiftData

struct YearComparisonChartView: View {

    let board: HabitBoard

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var monthlyData: [(month: String, current: Double, previous: Double)] {
        var results: [(String, Double, Double)] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        for monthOffset in (0..<12).reversed() {
            guard let monthDate = Calendar.current.date(byAdding: .month, value: -monthOffset, to: .now) else {
                continue
            }

            let monthLabel = formatter.string(from: monthDate)

            // Current year total for this month
            guard let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: monthDate)) else {
                continue
            }
            guard let monthEnd = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
                continue
            }

            let currentTotal = (board.logs ?? [])
                .filter { $0.timestamp >= monthStart && $0.timestamp <= monthEnd }
                .reduce(0.0) { $0 + $1.value }

            // Previous year total for this month
            guard let previousYearDate = Calendar.current.date(byAdding: .year, value: -1, to: monthDate) else {
                continue
            }
            guard let prevMonthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: previousYearDate)) else {
                continue
            }
            guard let prevMonthEnd = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: prevMonthStart) else {
                continue
            }

            let previousTotal = (board.logs ?? [])
                .filter { $0.timestamp >= prevMonthStart && $0.timestamp <= prevMonthEnd }
                .reduce(0.0) { $0 + $1.value }

            results.append((monthLabel, currentTotal, previousTotal))
        }

        return results
    }

    private var maxValue: Double {
        max(
            monthlyData.map { $0.current }.max() ?? 0,
            monthlyData.map { $0.previous }.max() ?? 0
        )
    }

    var body: some View {
        LOCACard {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                // Header
                HStack(spacing: DS.Space.xs) {
                    Image(systemName: "chart.bar.fill")
                        .font(DS.Text.caption)
                        .foregroundStyle(ColorPalette[board.colorIndex])
                    Text("YEAR COMPARISON")
                        .font(DS.Text.footnote)
                        .foregroundStyle(DS.Color.textSecondary)
                        .tracking(0.5)
                }

                // Canvas chart
                Canvas { context, size in
                    let width = size.width
                    let height = size.height
                    let padding: CGFloat = 12
                    let maxHeight = height - padding * 2

                    guard monthlyData.count > 0, maxValue > 0 else { return }

                    let barPairWidth = (width - padding * 2) / CGFloat(monthlyData.count)
                    let barWidth = (barPairWidth - 4) / 2

                    for (index, data) in monthlyData.enumerated() {
                        let xBase = padding + CGFloat(index) * barPairWidth + barPairWidth / 2 - barWidth
                        let scale = maxHeight / maxValue

                        // Previous year bar (left, dimmed)
                        let prevHeight = data.previous * scale
                        let prevX = xBase - barWidth / 2 - 2
                        let prevY = height - padding - prevHeight

                        var prevPath = Path()
                        prevPath.addRect(CGRect(x: prevX, y: prevY, width: barWidth, height: prevHeight))
                        context.fill(prevPath, with: .color(ColorPalette[board.colorIndex].opacity(0.3)))

                        // Current year bar (right, full color)
                        let currHeight = data.current * scale
                        let currX = xBase + barWidth / 2 + 2
                        let currY = height - padding - currHeight

                        var currPath = Path()
                        currPath.addRect(CGRect(x: currX, y: currY, width: barWidth, height: currHeight))
                        context.fill(currPath, with: .color(ColorPalette[board.colorIndex]))

                        // Month label (every other month)
                        if index % 2 == 0 {
                            let text = Text(data.month)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(DS.Color.textSecondary)
                            context.draw(text, at: CGPoint(x: xBase, y: height - 2), anchor: .top)
                        }
                    }
                }
                .frame(height: 120)
                .padding(.vertical, DS.Space.sm)

                // Legend
                HStack(spacing: DS.Space.lg) {
                    HStack(spacing: DS.Space.xs) {
                        Rectangle()
                            .fill(ColorPalette[board.colorIndex])
                            .frame(width: 8, height: 8)
                        Text("This Year")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }

                    HStack(spacing: DS.Space.xs) {
                        Rectangle()
                            .fill(ColorPalette[board.colorIndex].opacity(0.3))
                            .frame(width: 8, height: 8)
                        Text("Last Year")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }

                    Spacer()
                }
            }
            .padding(DS.Space.md)
            .opacity(hasAppeared ? 1 : 0)
            .animation(DS.Motion.settle(reduceMotion: reduceMotion), value: hasAppeared)
            .onAppear { hasAppeared = true }
        }
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

        // Simulate 24 months of data
        for monthsAgo in 0..<24 {
            if let monthDate = Calendar.current.date(byAdding: .month, value: -monthsAgo, to: .now) {
                guard let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: monthDate)) else {
                    continue
                }
                guard let monthEnd = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
                    continue
                }

                var current = monthStart
                while current <= monthEnd {
                    if Double.random(in: 0...1) < 0.7 {
                        let value = Double.random(in: 20...45)
                        let entry = LogEntry(timestamp: current, value: value, boardID: habit.id, board: habit)
                        container.mainContext.insert(entry)
                    }
                    guard let next = Calendar.current.date(byAdding: .day, value: 1, to: current) else {
                        break
                    }
                    current = next
                }
            }
        }

        try? container.mainContext.save()
        return (container, habit)
    }

    let (container, habit) = makeContainer()
    return YearComparisonChartView(board: habit)
        .modelContainer(container)
}
