//
//  HabitDetailView.swift
//  LOCA
//
//  Phase 14.7 — Pixel-perfect habit detail view.
//

import SwiftUI
import SwiftData

// MARK: - HabitDetailView

struct HabitDetailView: View {
    let board: HabitBoard
    @Environment(\.modelContext) private var modelContext

    @State private var showingEditSheet = false
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // Heatmap — fills width, cells sized by geometry
                    DetailHeatmapCard(board: board)

                    // 2-col metric row
                    HStack(alignment: .top, spacing: 12) {
                        DetailStreakCard(board: board)
                        DetailConsistencyCard(board: board)
                    }
                    .padding(.horizontal, 16)

                    // Full-width month card
                    DetailMonthCard(board: board)
                        .padding(.horizontal, 16)

                    Spacer(minLength: 100)
                }
                .padding(.top, 8)
            }

            // Bottom pill toolbar
            HStack(spacing: 0) {
                HStack(spacing: 26) {
                    ToolbarTabIcon(icon: "chart.xyaxis.line", selected: selectedTab == 0, color: ColorPalette[board.colorIndex]) { selectedTab = 0 }
                    ToolbarTabIcon(icon: "checklist",         selected: selectedTab == 1, color: ColorPalette[board.colorIndex]) { selectedTab = 1 }
                    ToolbarTabIcon(icon: "doc.text",          selected: selectedTab == 2, color: ColorPalette[board.colorIndex]) { selectedTab = 2 }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 14)
                .background(Color(white: 0.14), in: Capsule(style: .continuous))

                Spacer()

                Button(action: { showingEditSheet = true }) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(Color(white: 0.14), in: Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .navigationTitle(board.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingEditSheet = true }) {
                    Image(systemName: "pencil")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Color(white: 0.18), in: Circle())
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            HabitFormView(mode: .edit(board))
        }
    }
}

// MARK: - ToolbarTabIcon

private struct ToolbarTabIcon: View {
    let icon: String
    let selected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(selected ? color : Color(white: 0.40))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - DetailHeatmapCard

struct DetailHeatmapCard: View {
    let board: HabitBoard

    private let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let weeks = 52
    private let cellSpacing: CGFloat = 2.5
    private let labelWidth: CGFloat = 30
    private let horizontalPad: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width - horizontalPad * 2 - labelWidth - cellSpacing
            let cellSize = max(4, (availableWidth - cellSpacing * CGFloat(weeks - 1)) / CGFloat(weeks))

            VStack(alignment: .leading, spacing: cellSpacing) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    HStack(spacing: cellSpacing) {
                        Text(dayLabels[dayIndex])
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color(white: 0.40))
                            .frame(width: labelWidth, alignment: .leading)

                        ForEach(0..<weeks, id: \.self) { weekIndex in
                            DetailHeatmapCell(board: board, dayIndex: dayIndex, weekIndex: weekIndex)
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
            .padding(12)
            .frame(width: geo.size.width - horizontalPad * 2)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ColorPalette[board.colorIndex].opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(ColorPalette[board.colorIndex].opacity(0.20), lineWidth: 0.5)
            )
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .frame(height: heatmapHeight())
        .padding(.horizontal, horizontalPad)
    }

    private func heatmapHeight() -> CGFloat {
        // 7 rows * (cellSize + spacing) + vertical padding
        // Approximate: screen-independent estimate
        let rowH: CGFloat = 9 + cellSpacing
        return rowH * 7 + 24 + 2
    }
}

// MARK: - DetailHeatmapCell

struct DetailHeatmapCell: View {
    let board: HabitBoard
    let dayIndex: Int
    let weekIndex: Int

    private var totalValue: Double {
        let today = Calendar.current.startOfDay(for: .now)
        let weeksBack = 52 - 1 - weekIndex
        let daysBack = weeksBack * 7 + dayIndex
        guard let date = Calendar.current.date(byAdding: .day, value: -daysBack, to: today) else { return 0 }
        return (board.logs ?? [])
            .filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
            .reduce(0.0) { $0 + $1.value }
    }

    private var fillOpacity: Double {
        guard totalValue > 0 else { return 0 }
        let ratio = totalValue / board.effectiveTarget
        if ratio >= 1.0 { return 1.0 }
        if ratio >= 0.5 { return 0.55 }
        return 0.30
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(
                totalValue > 0
                    ? ColorPalette[board.colorIndex].opacity(fillOpacity)
                    : Color(white: 0.17)
            )
    }
}

// MARK: - DetailStreakCard

struct DetailStreakCard: View {
    let board: HabitBoard

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 5) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(white: 0.45))
                Text("CURRENT STREAK")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color(white: 0.45))
                    .tracking(0.4)
                Spacer()
            }

            Spacer(minLength: 14)

            if board.currentStreak > 0 {
                Text("\(board.currentStreak)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(ColorPalette[board.colorIndex])
            } else {
                Text("– –")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(white: 0.30))
            }

            Spacer(minLength: 12)

            HStack(spacing: 4) {
                Text("Longest:")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(white: 0.40))
                Text("\(board.longestStreak)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(white: 0.11)))
    }
}

// MARK: - DetailConsistencyCard

struct DetailConsistencyCard: View {
    let board: HabitBoard

    private var consistencyRatio: Double {
        let now = Date()
        guard let monthStart = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: now)
        ) else { return 0 }

        let elapsed = max(1, (Calendar.current.dateComponents([.day], from: monthStart, to: now).day ?? 0) + 1)

        var daily = [Date: Double]()
        for log in board.logs ?? [] {
            guard log.timestamp >= monthStart else { continue }
            let day = Calendar.current.startOfDay(for: log.timestamp)
            daily[day, default: 0] += log.value
        }
        let completed = daily.filter { $0.value >= board.effectiveTarget }.count
        return Double(completed) / Double(elapsed)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 5) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(white: 0.45))
                Text("CONSISTENCY")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color(white: 0.45))
                    .tracking(0.4)
                Spacer()
            }

            Spacer(minLength: 8)

            // Open-bottom arc
            ZStack {
                Circle()
                    .trim(from: 0.125, to: 0.875)
                    .stroke(Color(white: 0.20), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(90))

                if consistencyRatio > 0 {
                    Circle()
                        .trim(from: 0.125, to: 0.125 + 0.75 * min(1, consistencyRatio))
                        .stroke(ColorPalette[board.colorIndex], style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(90))
                }

                Text("Average")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(white: 0.38))
            }
            .frame(height: 80)
            .padding(.horizontal, 4)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(white: 0.11)))
    }
}

// MARK: - DetailMonthCard

struct DetailMonthCard: View {
    let board: HabitBoard

    private var currentMonthTotal: Double {
        guard let monthStart = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: Date())
        ) else { return 0 }
        return (board.logs ?? [])
            .filter { $0.timestamp >= monthStart }
            .reduce(0.0) { $0 + $1.value }
    }

    private var weekDayTotals: [Double] {
        let today = Calendar.current.startOfDay(for: .now)
        guard let sunday = Calendar.current.date(
            from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        ) else { return Array(repeating: 0, count: 7) }

        return (0..<7).map { offset -> Double in
            guard let day = Calendar.current.date(byAdding: .day, value: offset, to: sunday) else { return 0 }
            return (board.logs ?? [])
                .filter { Calendar.current.isDate($0.timestamp, inSameDayAs: day) }
                .reduce(0.0) { $0 + $1.value }
        }
    }

    private var currentWeekTotal: Double { weekDayTotals.reduce(0, +) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 5) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(white: 0.45))
                Text("CURRENT MONTH")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color(white: 0.45))
                    .tracking(0.4)
                Spacer()
            }

            Spacer(minLength: 10)

            // Value + bars
            HStack(alignment: .bottom, spacing: 0) {
                // Left: big number
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .lastTextBaseline, spacing: 5) {
                        Text(String(format: "%.0f", currentMonthTotal))
                            .font(.system(size: 46, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                currentMonthTotal > 0
                                    ? ColorPalette[board.colorIndex]
                                    : Color(white: 0.30)
                            )
                        if let unit = board.unitLabel, !unit.isEmpty {
                            Text(unit)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color(white: 0.45))
                        }
                    }
                }

                Spacer()

                // Right: 7-bar week chart
                let maxVal = max(weekDayTotals.max() ?? 1, board.effectiveTarget)
                let todayWeekday = Calendar.current.component(.weekday, from: .now) - 1 // 0=Sun

                HStack(alignment: .bottom, spacing: 5) {
                    ForEach(0..<7, id: \.self) { i in
                        let val = weekDayTotals[i]
                        let ratio = val / maxVal
                        let barH = max(6, 56 * ratio)
                        let isToday = i == todayWeekday
                        let hasFill = val > 0

                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(
                                hasFill
                                    ? (isToday
                                        ? ColorPalette[board.colorIndex]
                                        : ColorPalette[board.colorIndex].opacity(0.40))
                                    : Color(white: 0.18)
                            )
                            .frame(width: 18, height: hasFill ? barH : 8)
                    }
                }
            }

            Spacer(minLength: 14)

            // Footer
            HStack(spacing: 4) {
                Text("Current week:")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(white: 0.40))

                if currentWeekTotal > 0 {
                    Text(String(format: "%.0f", currentWeekTotal))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                    if let unit = board.unitLabel, !unit.isEmpty {
                        Text(unit)
                            .font(.system(size: 12))
                            .foregroundStyle(Color(white: 0.40))
                    }
                } else {
                    Text("–")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(white: 0.40))
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(white: 0.11)))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HabitDetailView(board: HabitBoard(name: "Cardio", metricType: 1, targetValue: 1, unitLabel: "kcal", colorIndex: 5))
    }
}
