//
//  TimelineChartView.swift
//  LOCA
//
//  Phase 13.1 — Timeline analytics chart.
//
//  Canvas-based line chart showing daily totals over a selectable period
//  (7 days, 30 days, 90 days, all time). Includes goal line overlay and
//  interactive period selection via pill buttons.
//

import SwiftUI
import SwiftData

struct TimelineChartView: View {

    let board: HabitBoard

    @State private var selectedPeriod: Int = 30  // days

    private let periodOptions = [7, 30, 90, 365]

    /// Daily totals for the selected period (oldest to newest)
    private var periodData: [Double] {
        var totals: [Double] = []
        for daysAgo in (0..<selectedPeriod).reversed() {
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

    private var maxValue: Double {
        max(board.effectiveTarget, periodData.max() ?? board.effectiveTarget)
    }

    var body: some View {
        LOCACard {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                // Header with period selector
                VStack(alignment: .leading, spacing: DS.Space.md) {
                    HStack(spacing: DS.Space.xs) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(DS.Text.caption)
                            .foregroundStyle(ColorPalette[board.colorIndex])
                        Text("TIMELINE")
                            .font(DS.Text.footnote)
                            .foregroundStyle(DS.Color.textSecondary)
                            .tracking(0.5)
                    }

                    HStack(spacing: DS.Space.xs) {
                        ForEach(periodOptions, id: \.self) { period in
                            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedPeriod = period } }) {
                                Text(periodLabel(period))
                                    .font(DS.Text.caption)
                                    .foregroundStyle(
                                        selectedPeriod == period
                                            ? DS.Color.textPrimary
                                            : DS.Color.textSecondary
                                    )
                                    .padding(.horizontal, DS.Space.md)
                                    .padding(.vertical, DS.Space.xs)
                                    .background {
                                        if selectedPeriod == period {
                                            Capsule(style: .continuous)
                                                .fill(DS.Color.surfaceRecessed)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                }

                // Canvas chart
                Canvas { context, size in
                    let width = size.width
                    let height = size.height
                    let padding: CGFloat = 12

                    // Goal line (horizontal)
                    let goalY = height - padding - (board.effectiveTarget / maxValue) * (height - padding * 2)
                    var goalPath = Path()
                    goalPath.move(to: CGPoint(x: padding, y: goalY))
                    goalPath.addLine(to: CGPoint(x: width - padding, y: goalY))
                    context.stroke(
                        goalPath,
                        with: .color(ColorPalette[board.colorIndex].opacity(0.4)),
                        lineWidth: 1
                    )

                    // Line chart path
                    guard periodData.count > 1 else { return }

                    let xStep = (width - padding * 2) / CGFloat(periodData.count - 1)
                    var chartPath = Path()

                    for (index, value) in periodData.enumerated() {
                        let x = padding + CGFloat(index) * xStep
                        let y = height - padding - (value / maxValue) * (height - padding * 2)

                        if index == 0 {
                            chartPath.move(to: CGPoint(x: x, y: y))
                        } else {
                            chartPath.addLine(to: CGPoint(x: x, y: y))
                        }
                    }

                    // Stroke the line
                    context.stroke(
                        chartPath,
                        with: .color(ColorPalette[board.colorIndex]),
                        lineWidth: 2
                    )

                    // Points along the line
                    for (index, value) in periodData.enumerated() {
                        let x = padding + CGFloat(index) * xStep
                        let y = height - padding - (value / maxValue) * (height - padding * 2)

                        context.fill(
                            Path(ellipseIn: CGRect(x: x - 3, y: y - 3, width: 6, height: 6)),
                            with: .color(
                                value >= board.effectiveTarget
                                    ? ColorPalette[board.colorIndex]
                                    : DS.Color.textTertiary
                            )
                        )
                    }
                }
                .frame(height: 140)
                .padding(.vertical, DS.Space.sm)

                // Legend
                HStack(spacing: DS.Space.lg) {
                    HStack(spacing: DS.Space.xs) {
                        Circle()
                            .fill(ColorPalette[board.colorIndex])
                            .frame(width: 6, height: 6)
                        Text("Daily total")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }

                    HStack(spacing: DS.Space.xs) {
                        Capsule(style: .continuous)
                            .stroke(ColorPalette[board.colorIndex].opacity(0.4), lineWidth: 1)
                            .frame(width: 12, height: 1)
                        Text("Goal")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }

                    Spacer()
                }
            }
            .padding(DS.Space.md)
        }
    }

    private func periodLabel(_ days: Int) -> String {
        switch days {
        case 7: return "7D"
        case 30: return "30D"
        case 90: return "90D"
        case 365: return "All"
        default: return "\(days)D"
        }
    }
}

#Preview {
    @MainActor
    func makeContainer() -> (ModelContainer, HabitBoard) {
        let schema = Schema([HabitBoard.self, LogEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let habit = HabitBoard(name: "Running", metricType: 1, targetValue: 5, unitLabel: "km", colorIndex: 0)
        container.mainContext.insert(habit)

        for daysAgo in 0..<30 {
            if let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) {
                let value = Double.random(in: 2...7)
                let entry = LogEntry(timestamp: date, value: value, boardID: habit.id, board: habit)
                container.mainContext.insert(entry)
            }
        }

        try? container.mainContext.save()
        return (container, habit)
    }

    let (container, habit) = makeContainer()
    return TimelineChartView(board: habit)
        .modelContainer(container)
}
