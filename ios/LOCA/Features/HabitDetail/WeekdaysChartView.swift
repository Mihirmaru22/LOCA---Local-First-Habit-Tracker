//
//  WeekdaysChartView.swift
//  LOCA
//
//  Phase 13.5 — Weekdays Distribution analytics chart.
//
//  Canvas-based bar chart showing total activity by day of week (Sun-Sat)
//  over the past 12 weeks. Highlights workday vs weekend patterns.
//

import SwiftUI
import SwiftData

struct WeekdaysChartView: View {

    let board: HabitBoard

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var weekdayTotals: [Double] {
        var totals = [Double](repeating: 0, count: 7)  // Sun-Sat

        guard let start = Calendar.current.date(byAdding: .weekOfYear, value: -12, to: .now) else {
            return totals
        }

        var current = start
        let end = Date()

        while current <= end {
            let weekday = Calendar.current.component(.weekday, from: current) - 1  // 0=Sun, 6=Sat

            let dayStart = Calendar.current.startOfDay(for: current)
            guard let dayEnd = Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: dayStart) else {
                guard let next = Calendar.current.date(byAdding: .day, value: 1, to: current) else {
                    break
                }
                current = next
                continue
            }

            let dayTotal = (board.logs ?? [])
                .filter { $0.timestamp >= dayStart && $0.timestamp <= dayEnd }
                .reduce(0.0) { $0 + $1.value }

            totals[weekday] += dayTotal

            guard let next = Calendar.current.date(byAdding: .day, value: 1, to: current) else {
                break
            }
            current = next
        }

        return totals
    }

    private let weekdayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private var maxTotal: Double {
        weekdayTotals.max() ?? 1
    }

    var body: some View {
        LOCACard {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                // Header
                HStack(spacing: DS.Space.xs) {
                    Image(systemName: "calendar.circle")
                        .font(DS.Text.caption)
                        .foregroundStyle(ColorPalette[board.colorIndex])
                    Text("WEEKDAY PATTERN")
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

                    let barWidth = (width - padding * 2) / 7
                    let scale = maxHeight / maxTotal

                    for (index, total) in weekdayTotals.enumerated() {
                        let x = padding + CGFloat(index) * barWidth + barWidth / 2 - (barWidth - 4) / 2
                        let barHeight = total * scale
                        let y = height - padding - barHeight

                        // Determine color: workday (Mon-Fri) vs weekend
                        let isWeekend = index == 0 || index == 6
                        let barColor = isWeekend
                            ? ColorPalette[board.colorIndex].opacity(0.3)
                            : ColorPalette[board.colorIndex]

                        var barPath = Path()
                        barPath.addRect(CGRect(x: x, y: y, width: barWidth - 4, height: barHeight))
                        context.fill(barPath, with: .color(barColor))

                        // Day label
                        let text = Text(weekdayLabels[index])
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(DS.Color.textSecondary)
                        context.draw(text, at: CGPoint(x: x + (barWidth - 4) / 2, y: height - 2), anchor: .top)
                    }
                }
                .frame(height: 100)
                .padding(.vertical, DS.Space.sm)

                // Stats
                HStack(spacing: DS.Space.lg) {
                    VStack(alignment: .leading, spacing: DS.Space.xs) {
                        Text("Weekday Avg")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                        let weekdayAvg = (weekdayTotals[1...5].reduce(0, +)) / 5
                        ValueText(String(format: "%.1f", weekdayAvg), font: DS.Text.body)
                            .foregroundStyle(ColorPalette[board.colorIndex])
                            .contentTransition(.numericText())
                    }

                    Divider()
                        .frame(height: 24)

                    VStack(alignment: .leading, spacing: DS.Space.xs) {
                        Text("Weekend Avg")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                        let weekendAvg = (weekdayTotals[0] + weekdayTotals[6]) / 2
                        ValueText(String(format: "%.1f", weekendAvg), font: DS.Text.body)
                            .foregroundStyle(DS.Color.textPrimary)
                            .contentTransition(.numericText())
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
        let habit = HabitBoard(name: "Exercise", metricType: 1, targetValue: 1, unitLabel: "sessions", colorIndex: 0)
        container.mainContext.insert(habit)

        for weeksAgo in 0..<12 {
            if let weekStart = Calendar.current.date(byAdding: .weekOfYear, value: -weeksAgo, to: .now) {
                for dayOffset in 0..<7 {
                    if let day = Calendar.current.date(byAdding: .day, value: dayOffset, to: weekStart) {
                        let weekday = Calendar.current.component(.weekday, from: day)
                        let probability = weekday > 2 && weekday < 7 ? 0.7 : 0.4  // More on weekdays
                        
                        if Double.random(in: 0...1) < probability {
                            let entry = LogEntry(timestamp: day, value: 1, boardID: habit.id, board: habit)
                            container.mainContext.insert(entry)
                        }
                    }
                }
            }
        }

        try? container.mainContext.save()
        return (container, habit)
    }

    let (container, habit) = makeContainer()
    return WeekdaysChartView(board: habit)
        .modelContainer(container)
}
