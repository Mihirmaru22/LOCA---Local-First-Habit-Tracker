//
//  StreaksChartView.swift
//  LOCA
//
//  Phase 13.2 — Streaks analytics chart.
//
//  Canvas-based visualization showing monthly streak timeline over the past
//  12 months. Longest streak highlighted. Current streak marked with accent
//  color. Breaks shown as gaps.
//

import SwiftUI
import SwiftData

struct StreaksChartView: View {

    let board: HabitBoard

    private var monthStreaks: [(month: Date, streak: Int)] {
        var results: [(Date, Int)] = []
        for monthsAgo in (0..<12).reversed() {
            guard let monthDate = Calendar.current.date(byAdding: .month, value: -monthsAgo, to: .now) else {
                continue
            }
            guard let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: monthDate)) else {
                continue
            }
            guard let monthEnd = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
                continue
            }

            var streak = 0
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
                    streak += 1
                } else {
                    break
                }

                guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: current) else {
                    break
                }
                current = nextDay
            }

            results.append((monthStart, streak))
        }
        return results
    }

    private var longestStreak: Int {
        monthStreaks.map { $0.streak }.max() ?? 0
    }

    private var monthLabels: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return monthStreaks.map { formatter.string(from: $0.month) }
    }

    var body: some View {
        LOCACard {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                // Header
                HStack(spacing: DS.Space.xs) {
                    Image(systemName: "flame.fill")
                        .font(DS.Text.caption)
                        .foregroundStyle(ColorPalette[board.colorIndex])
                    Text("STREAKS")
                        .font(DS.Text.footnote)
                        .foregroundStyle(DS.Color.textSecondary)
                        .tracking(0.5)
                }

                // Canvas chart
                Canvas { context, size in
                    let width = size.width
                    let height = size.height
                    let padding: CGFloat = 8
                    let barHeight: CGFloat = 16

                    let maxStreak = max(board.effectiveTarget > 1 ? board.effectiveTarget : 10, Double(longestStreak))
                    let yScale = (height - padding * 2) / maxStreak

                    for (index, monthData) in monthStreaks.enumerated() {
                        let xStep = (width - padding * 2) / CGFloat(monthStreaks.count)
                        let x = padding + CGFloat(index) * xStep + xStep / 2 - barHeight / 2
                        let barLength = CGFloat(monthData.streak) * yScale
                        let y = height - padding - barLength

                        // Bar background (subtle)
                        var bgPath = Path()
                        bgPath.addRect(CGRect(x: x - barHeight / 2, y: height - padding - maxStreak * yScale, width: barHeight, height: maxStreak * yScale))
                        context.fill(bgPath, with: .color(DS.Color.textTertiary.opacity(0.1)))

                        // Bar fill
                        let barColor: Color
                        if monthData.streak == longestStreak && longestStreak > 0 {
                            barColor = ColorPalette[board.colorIndex]
                        } else if monthData.streak == board.currentStreak && monthData.month.isCurrentMonth {
                            barColor = ColorPalette[board.colorIndex].opacity(0.7)
                        } else if monthData.streak > 0 {
                            barColor = ColorPalette[board.colorIndex].opacity(0.4)
                        } else {
                            barColor = DS.Color.textTertiary.opacity(0.2)
                        }

                        var barPath = Path()
                        barPath.addRect(CGRect(x: x - barHeight / 2, y: y, width: barHeight, height: barLength))
                        context.fill(barPath, with: .color(barColor))

                        // Month label
                        if (index % 3) == 0 || index == monthStreaks.count - 1 {
                            let text = Text(monthLabels[index])
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(DS.Color.textSecondary)
                            context.draw(text, at: CGPoint(x: x, y: height - 2), anchor: .top)
                        }
                    }
                }
                .frame(height: 100)
                .padding(.vertical, DS.Space.sm)

                // Stats row
                HStack(spacing: DS.Space.lg) {
                    VStack(alignment: .leading, spacing: DS.Space.xs) {
                        Text("Longest Streak")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                        ValueText("\(board.longestStreak)", font: DS.Text.body)
                            .foregroundStyle(ColorPalette[board.colorIndex])
                    }

                    Divider()
                        .frame(height: 24)

                    VStack(alignment: .leading, spacing: DS.Space.xs) {
                        Text("Current Streak")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                        ValueText("\(board.currentStreak)", font: DS.Text.body)
                            .foregroundStyle(DS.Color.textPrimary)
                    }

                    Spacer()
                }
            }
            .padding(DS.Space.md)
        }
    }
}

extension Date {
    fileprivate var isCurrentMonth: Bool {
        Calendar.current.dateComponents([.year, .month], from: self)
            == Calendar.current.dateComponents([.year, .month], from: Date())
    }
}

#Preview {
    @MainActor
    func makeContainer() -> (ModelContainer, HabitBoard) {
        let schema = Schema([HabitBoard.self, LogEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let habit = HabitBoard(name: "Boxing", metricType: 0, colorIndex: 1)
        habit.longestStreak = 45
        habit.currentStreak = 12
        container.mainContext.insert(habit)

        // Simulate streaks throughout the year
        var current = Calendar.current.date(byAdding: .day, value: -200, to: .now) ?? .now
        let end = Date()
        var currentStreak = 0
        var breakIn = Int.random(in: 5...15)

        while current <= end {
            if breakIn > 0 {
                let entry = LogEntry(timestamp: current, value: 1, boardID: habit.id, board: habit)
                container.mainContext.insert(entry)
                currentStreak += 1
            } else {
                // Break
                if Int.random(in: 0...1) == 0 {
                    breakIn = -Int.random(in: 1...3)
                }
            }

            breakIn -= 1

            guard let next = Calendar.current.date(byAdding: .day, value: 1, to: current) else {
                break
            }
            current = next
        }

        try? container.mainContext.save()
        return (container, habit)
    }

    let (container, habit) = makeContainer()
    return StreaksChartView(board: habit)
        .modelContainer(container)
}
