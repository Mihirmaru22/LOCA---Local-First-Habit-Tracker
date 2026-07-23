//
//  ConsistencyChartView.swift
//  LOCA
//
//  Phase 13.4 — Consistency Over Time analytics chart.
//
//  Canvas-based line chart showing monthly consistency scores (% of days
//  completed) trended over the past 12 months. Identifies improvement or decline.
//

import SwiftUI
import SwiftData

struct ConsistencyChartView: View {

    let board: HabitBoard

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var monthlyScores: [(month: String, score: Double)] {
        var results: [(String, Double)] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        for monthOffset in (0..<12).reversed() {
            guard let monthDate = Calendar.current.date(byAdding: .month, value: -monthOffset, to: .now) else {
                continue
            }

            let monthLabel = formatter.string(from: monthDate)

            guard let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: monthDate)) else {
                continue
            }
            guard let monthEnd = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
                continue
            }

            let daysInMonth = Calendar.current.range(of: .day, in: .month, for: monthDate)?.count ?? 30

            var daysCompleted = 0
            var current = monthStart

            while current <= monthEnd {
                let dayStart = Calendar.current.startOfDay(for: current)
                guard let dayEnd = Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: dayStart) else {
                    break
                }

                let dayTotal = (board.logs ?? [])
                    .filter { $0.timestamp >= dayStart && $0.timestamp <= dayEnd }
                    .reduce(0.0) { $0 + $1.value }

                if dayTotal >= board.effectiveTarget {
                    daysCompleted += 1
                }

                guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: current) else {
                    break
                }
                current = nextDay
            }

            let score = Double(daysCompleted) / Double(daysInMonth) * 100
            results.append((monthLabel, score))
        }

        return results
    }

    var body: some View {
        LOCACard {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                // Header
                HStack(spacing: DS.Space.xs) {
                    Image(systemName: "percent")
                        .font(DS.Text.caption)
                        .foregroundStyle(ColorPalette[board.colorIndex])
                    Text("CONSISTENCY")
                        .font(DS.Text.footnote)
                        .foregroundStyle(DS.Color.textSecondary)
                        .tracking(0.5)
                }

                // Canvas chart or low-data message
                if monthlyScores.count <= 1 {
                    VStack(spacing: DS.Space.md) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title2)
                            .foregroundStyle(DS.Color.textTertiary)
                        Text("Keep logging to see trends")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    .frame(height: 110)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Space.sm)
                } else {
                    Canvas { context, size in
                        let width = size.width
                        let height = size.height
                        let padding: CGFloat = 12

                    let xStep = (width - padding * 2) / CGFloat(monthlyScores.count - 1)
                    let yScale = (height - padding * 2) / 100.0

                    // 50% reference line (midpoint)
                    var refPath = Path()
                    let refY = height - padding - 50 * yScale
                    refPath.move(to: CGPoint(x: padding, y: refY))
                    refPath.addLine(to: CGPoint(x: width - padding, y: refY))
                    context.stroke(refPath, with: .color(DS.Color.textTertiary.opacity(0.2)), lineWidth: 1)

                    // Line path
                    var chartPath = Path()
                    for (index, data) in monthlyScores.enumerated() {
                        let x = padding + CGFloat(index) * xStep
                        let y = height - padding - data.score * yScale

                        if index == 0 {
                            chartPath.move(to: CGPoint(x: x, y: y))
                        } else {
                            chartPath.addLine(to: CGPoint(x: x, y: y))
                        }
                    }

                    context.stroke(chartPath, with: .color(ColorPalette[board.colorIndex]), lineWidth: 2)

                    // Points
                    for (index, data) in monthlyScores.enumerated() {
                        let x = padding + CGFloat(index) * xStep
                        let y = height - padding - data.score * yScale

                        let pointColor: Color
                        if data.score >= 80 {
                            pointColor = ColorPalette[board.colorIndex]
                        } else if data.score >= 50 {
                            pointColor = ColorPalette[board.colorIndex].opacity(0.6)
                        } else {
                            pointColor = DS.Color.textTertiary
                        }

                        context.fill(
                            Path(ellipseIn: CGRect(x: x - 3, y: y - 3, width: 6, height: 6)),
                            with: .color(pointColor)
                        )
                    }

                    // Month labels (every other)
                    for (index, data) in monthlyScores.enumerated() {
                        if index % 2 == 0 {
                            let x = padding + CGFloat(index) * xStep
                            let text = Text(data.month)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(DS.Color.textSecondary)
                            context.draw(text, at: CGPoint(x: x, y: height - 2), anchor: .top)
                        }
                    }
                    }
                    .frame(height: 110)
                    .padding(.vertical, DS.Space.sm)
                }

                // Stats
                HStack(spacing: DS.Space.lg) {
                    VStack(alignment: .leading, spacing: DS.Space.xs) {
                        Text("Current Month")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                        if let current = monthlyScores.last {
                            ValueText(String(format: "%.0f%%", current.score), font: DS.Text.body)
                                .foregroundStyle(ColorPalette[board.colorIndex])
                                .contentTransition(.numericText())
                        }
                    }

                    Divider()
                        .frame(height: 24)

                    VStack(alignment: .leading, spacing: DS.Space.xs) {
                        Text("12-Month Avg")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                        let avg = monthlyScores.map { $0.score }.reduce(0, +) / Double(monthlyScores.count)
                        ValueText(String(format: "%.0f%%", avg), font: DS.Text.body)
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
        let habit = HabitBoard(name: "Meditation", metricType: 0, colorIndex: 5)
        container.mainContext.insert(habit)

        for monthsAgo in 0..<12 {
            if let monthDate = Calendar.current.date(byAdding: .month, value: -monthsAgo, to: .now) {
                guard let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: monthDate)) else {
                    continue
                }
                guard let monthEnd = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
                    continue
                }

                var current = monthStart
                while current <= monthEnd {
                    if Double.random(in: 0...1) < (0.5 + Double(12 - monthsAgo) * 0.05) {
                        let entry = LogEntry(timestamp: current, value: 1, boardID: habit.id, board: habit)
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
    return ConsistencyChartView(board: habit)
        .modelContainer(container)
}
