//
//  HabitDetailView.swift
//  LOCA
//
//  Phase 14.6 — Pixel-perfect match to reference screenshot.
//
//  Layout:
//    - Heatmap hero (52 weeks × 7 days, dark card, day labels left)
//    - 2-column metric row: CurrentStreakCard | ConsistencyCard
//    - Full-width CurrentMonthCard (real data, real bars)
//    - Bottom pill toolbar: 3 nav icons left, + button right
//

import SwiftUI
import SwiftData

// MARK: - HabitDetailView

struct HabitDetailView: View {
    let board: HabitBoard
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @State private var showingEditSheet = false
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Heatmap hero
                    DetailHeatmapCard(board: board)
                        .padding(.horizontal, 16)

                    // Metric row
                    HStack(spacing: 12) {
                        DetailStreakCard(board: board)
                        DetailConsistencyCard(board: board)
                    }
                    .padding(.horizontal, 16)

                    // Month card
                    DetailMonthCard(board: board)
                        .padding(.horizontal, 16)

                    Spacer(minLength: 100)
                }
                .padding(.top, 12)
            }

            // Bottom pill toolbar
            HStack(spacing: 0) {
                // Left pill: 3 nav icons
                HStack(spacing: 28) {
                    ToolbarIcon(icon: "chart.xyaxis.line", selected: selectedTab == 0, color: ColorPalette[board.colorIndex]) {
                        selectedTab = 0
                    }
                    ToolbarIcon(icon: "checklist", selected: selectedTab == 1, color: ColorPalette[board.colorIndex]) {
                        selectedTab = 1
                    }
                    ToolbarIcon(icon: "doc.text", selected: selectedTab == 2, color: ColorPalette[board.colorIndex]) {
                        selectedTab = 2
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color(white: 0.13), in: Capsule(style: .continuous))

                Spacer()

                // Right: + button
                Button(action: { showingEditSheet = true }) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(Color(white: 0.13), in: Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .navigationTitle(board.name)
        .inlineNavigationTitleDisplay()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color(white: 0.18), in: Circle())
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingEditSheet = true }) {
                    Image(systemName: "pencil")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color(white: 0.18), in: Circle())
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            HabitFormView(mode: .edit(board))
        }
    }
}

// MARK: - ToolbarIcon

private struct ToolbarIcon: View {
    let icon: String
    let selected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(selected ? color : Color(white: 0.45))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - DetailHeatmapCard

struct DetailHeatmapCard: View {
    let board: HabitBoard

    private let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let weeks = 52
    private let cellSize: CGFloat = 7
    private let cellSpacing: CGFloat = 2

    var body: some View {
        VStack(alignment: .leading, spacing: cellSpacing) {
            ForEach(0..<7, id: \.self) { dayIndex in
                HStack(spacing: cellSpacing) {
                    // Day label
                    Text(dayLabels[dayIndex])
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(white: 0.45))
                        .frame(width: 28, alignment: .leading)

                    // Cells
                    ForEach(0..<weeks, id: \.self) { weekIndex in
                        DetailHeatmapCell(
                            board: board,
                            dayIndex: dayIndex,
                            weekIndex: weekIndex,
                            cellSize: cellSize
                        )
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ColorPalette[board.colorIndex].opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(ColorPalette[board.colorIndex].opacity(0.18), lineWidth: 0.5)
        )
    }
}

// MARK: - DetailHeatmapCell

struct DetailHeatmapCell: View {
    let board: HabitBoard
    let dayIndex: Int
    let weekIndex: Int
    let cellSize: CGFloat

    private var cellDate: Date? {
        let today = Calendar.current.startOfDay(for: .now)
        let weeksBack = 52 - 1 - weekIndex
        let daysBack = weeksBack * 7 + dayIndex
        return Calendar.current.date(byAdding: .day, value: -daysBack, to: today)
    }

    private var totalValue: Double {
        guard let date = cellDate else { return 0 }
        return (board.logs ?? [])
            .filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
            .reduce(0.0) { $0 + $1.value }
    }

    private var fillOpacity: Double {
        guard totalValue > 0 else { return 0 }
        let ratio = totalValue / board.effectiveTarget
        // Three tiers matching screenshot: dim / mid / full
        if ratio >= 1.0 { return 1.0 }
        if ratio >= 0.5 { return 0.55 }
        return 0.28
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
            .fill(
                totalValue > 0
                    ? ColorPalette[board.colorIndex].opacity(fillOpacity)
                    : Color(white: 0.18)
            )
            .frame(width: cellSize, height: cellSize)
    }
}

// MARK: - DetailStreakCard

struct DetailStreakCard: View {
    let board: HabitBoard

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(white: 0.5))
                Text("CURRENT STREAK")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(white: 0.5))
                    .tracking(0.4)
                Spacer()
            }

            Spacer(minLength: 16)

            // Streak value — dashes if 0
            if board.currentStreak > 0 {
                ValueText(String(board.currentStreak), font: DS.Text.valueHero)
                    .foregroundStyle(ColorPalette[board.colorIndex])
            } else {
                Text("– –")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(white: 0.35))
            }

            Spacer(minLength: 12)

            // Longest
            HStack(spacing: 4) {
                Text("Longest:")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(white: 0.45))
                Text("\(board.longestStreak)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(white: 0.11))
        )
    }
}

// MARK: - DetailConsistencyCard

struct DetailConsistencyCard: View {
    let board: HabitBoard

    private var consistencyRatio: Double {
        let now = Date()
        guard let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now)) else {
            return 0
        }
        let components = Calendar.current.dateComponents([.day], from: monthStart, to: now)
        let daysElapsed = max(1, (components.day ?? 0) + 1)

        var dailyTotals = [Date: Double]()
        for log in board.logs ?? [] {
            guard log.timestamp >= monthStart else { continue }
            let day = Calendar.current.startOfDay(for: log.timestamp)
            dailyTotals[day, default: 0] += log.value
        }
        let completed = dailyTotals.filter { $0.value >= board.effectiveTarget }.count
        return Double(completed) / Double(daysElapsed)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(white: 0.5))
                Text("CONSISTENCY")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(white: 0.5))
                    .tracking(0.4)
                Spacer()
            }

            Spacer(minLength: 10)

            // Open-bottom arc gauge
            ZStack {
                // Track arc (open bottom: 225° → 315°, so 270° sweep)
                Circle()
                    .trim(from: 0.125, to: 0.875)
                    .stroke(Color(white: 0.22), style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(90))

                // Fill arc
                Circle()
                    .trim(from: 0.125, to: 0.125 + 0.75 * consistencyRatio)
                    .stroke(
                        ColorPalette[board.colorIndex].opacity(consistencyRatio > 0 ? 1 : 0),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))

                Text("Average")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(white: 0.4))
            }
            .frame(height: 70)
            .padding(.horizontal, 8)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(white: 0.11))
        )
    }
}

// MARK: - DetailMonthCard

struct DetailMonthCard: View {
    let board: HabitBoard

    private var weekDayTotals: [Double] {
        // Last 7 days (Mon-Sun of current week)
        let today = Calendar.current.startOfDay(for: .now)
        let sunday = Calendar.current.date(
            from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        ) ?? today

        return (0..<7).map { offset -> Double in
            guard let day = Calendar.current.date(byAdding: .day, value: offset, to: sunday) else { return 0 }
            return (board.logs ?? [])
                .filter { Calendar.current.isDate($0.timestamp, inSameDayAs: day) }
                .reduce(0.0) { $0 + $1.value }
        }
    }

    private var currentMonthTotal: Double {
        let now = Date()
        guard let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now)) else {
            return 0
        }
        return (board.logs ?? [])
            .filter { $0.timestamp >= monthStart }
            .reduce(0.0) { $0 + $1.value }
    }

    private var currentWeekTotal: Double {
        weekDayTotals.reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(white: 0.5))
                Text("CURRENT MONTH")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(white: 0.5))
                    .tracking(0.4)
                Spacer()
            }

            Spacer(minLength: 12)

            HStack(alignment: .bottom, spacing: 0) {
                // Left: total value
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(String(format: "%.0f", currentMonthTotal))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(ColorPalette[board.colorIndex])
                        if let unit = board.unitLabel {
                            Text(unit)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Color(white: 0.5))
                        }
                    }
                    Spacer(minLength: 0)
                }

                Spacer()

                // Right: 7-bar week chart
                let maxVal = max(weekDayTotals.max() ?? 1, 1)
                HStack(alignment: .bottom, spacing: 5) {
                    ForEach(0..<7, id: \.self) { i in
                        let ratio = weekDayTotals[i] / maxVal
                        let isToday = i == Calendar.current.component(.weekday, from: .now) - 1
                        let isFuture = Calendar.current.date(
                            from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Calendar.current.startOfDay(for: .now))
                        ).map { Calendar.current.date(byAdding: .day, value: i, to: $0)! > Date() } ?? false

                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(
                                weekDayTotals[i] > 0
                                    ? ColorPalette[board.colorIndex].opacity(isToday ? 1.0 : 0.45)
                                    : Color(white: isFuture ? 0.10 : 0.18)
                            )
                            .frame(width: 18, height: max(8, 52 * ratio))
                    }
                }
            }

            Spacer(minLength: 14)

            // Footer
            HStack(spacing: 4) {
                Text("Current week:")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(white: 0.45))

                if currentWeekTotal > 0 {
                    Text(String(format: "%.0f", currentWeekTotal))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                    if let unit = board.unitLabel {
                        Text(unit)
                            .font(.system(size: 12))
                            .foregroundStyle(Color(white: 0.45))
                    }
                } else {
                    Text("–")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(white: 0.45))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(white: 0.11))
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HabitDetailView(board: HabitBoard(name: "Work on side project", metricType: 1, targetValue: 1, unitLabel: "h", colorIndex: 5))
    }
}
