//
//  HabitDetailView.swift
//  LOCA
//
//  Phase 14.8 — Pixel-perfect match to reference.
//

import SwiftUI
import SwiftData

// MARK: - HabitDetailView

struct HabitDetailView: View {
    let board: HabitBoard
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet    = false
    @State private var showingCheckIn      = false
    @State private var selectedTab         = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            Group {
                switch selectedTab {
                case 1:
                    HabitCheckInsView(board: board)
                        .padding(.bottom, 80) // clear toolbar
                case 2:
                    HabitJournalView(board: board)
                        .padding(.bottom, 80)
                case 3:
                    HabitAnalyticsView(board: board)
                        .padding(.bottom, 80)
                default:
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            RefHeatmapCard(board: board)
                                .padding(.horizontal, 18)

                            HStack(alignment: .top, spacing: 12) {
                                RefStreakCard(board: board)
                                RefConsistencyCard(board: board)
                            }
                            .padding(.horizontal, 18)

                            RefMonthCard(board: board)
                                .padding(.horizontal, 18)

                            Spacer(minLength: 110)
                        }
                        .padding(.top, 10)
                    }
                }
            }

            // Toolbar
            HStack(spacing: 0) {
                HStack(spacing: 24) {
                    RefTabIcon(icon: "chart.line.uptrend.xyaxis",   active: selectedTab == 0) { selectedTab = 0 }
                    RefTabIcon(icon: "checklist",                   active: selectedTab == 1) { selectedTab = 1 }
                    RefTabIcon(icon: "doc.text",                    active: selectedTab == 2) { selectedTab = 2 }
                    RefTabIcon(icon: "chart.bar.xaxis.ascending",   active: selectedTab == 3) { selectedTab = 3 }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 16)
                .background(Color(white: 0.13), in: Capsule(style: .continuous))

                Spacer()

                // + button → add check-in
                Button(action: { showingCheckIn = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color(white: 0.13), in: Circle())
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 28)
        }
        .navigationTitle(board.name)
        .inlineNavigationTitleDisplay()
        .toolbar {
            // pencil → edit habit
            ToolbarItem(placement: .confirmationAction) {
                Button(action: { showingEditSheet = true }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color(white: 0.18), in: Circle())
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            HabitFormView(mode: .edit(board), onBoardArchived: { dismiss() })
        }
        .onChange(of: board.archivedAt) { _, newValue in
            if newValue != nil { dismiss() }
        }
        .sheet(isPresented: $showingCheckIn) {
            AddCheckInSheetView(board: board)
        }
    }
}

// MARK: - Tab icon

private struct RefTabIcon: View {
    let icon: String
    let active: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Heatmap card

struct RefHeatmapCard: View {
    let board: HabitBoard
    private let dayLabels = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
    private let gap: CGFloat    = 3
    private let labelW: CGFloat = 30
    private let hPad: CGFloat   = 10
    private let vPad: CGFloat   = 10
    // Target cell size — drives column count
    private let targetCell: CGFloat = 11

    // Pre-aggregated off-main; O(1) lookup per cell at render time.
    @State private var cellsByDate: [Date: DayCell] = [:]

    var body: some View {
        GeometryReader { geo in
            let usable = geo.size.width - hPad * 2 - labelW - gap
            let cols   = max(1, Int((usable + gap) / (targetCell + gap)))
            let cSize  = (usable - gap * CGFloat(cols - 1)) / CGFloat(cols)
            let totalH = (cSize + gap) * 7 - gap + vPad * 2

            VStack(alignment: .leading, spacing: gap) {
                ForEach(0..<7, id: \.self) { d in
                    HStack(spacing: gap) {
                        Text(dayLabels[d])
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color(white: 0.45))
                            .frame(width: labelW, alignment: .leading)
                        ForEach(0..<cols, id: \.self) { w in
                            RefHeatCell(
                                colorIndex: board.colorIndex,
                                cellsByDate: cellsByDate,
                                dayIndex: d,
                                weekIndex: w,
                                totalCols: cols,
                                cellSize: cSize
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, hPad)
            .padding(.vertical, vPad)
            .frame(width: geo.size.width, height: totalH)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(ColorPalette[board.colorIndex].opacity(0.13))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(ColorPalette[board.colorIndex].opacity(0.25), lineWidth: 0.6)
            )
        }
        .frame(height: heatmapHeight())
        // 182 days (26 weeks) covers the widest reasonable grid on any iPhone width.
        .task(id: "\(board.id)-\(board.logs?.count ?? -1)") {
            let snapshots = (board.logs ?? []).map(LogSnapshot.init(from:))
            let target    = board.effectiveTarget
            let newCells  = await HeatmapDataProvider.buildDayGrid(
                snapshots:  snapshots,
                target:     target,
                windowDays: 182
            )
            cellsByDate = Dictionary(uniqueKeysWithValues: newCells.map { ($0.date, $0) })
        }
    }

    private func heatmapHeight() -> CGFloat {
        (targetCell + gap) * 7 - gap + vPad * 2
    }
}

struct RefHeatCell: View {
    let colorIndex: Int
    let cellsByDate: [Date: DayCell]
    let dayIndex: Int
    let weekIndex: Int
    let totalCols: Int
    let cellSize: CGFloat

    // Week-anchor date: Sunday of the column's week + dayIndex days.
    private var cellDate: Date? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let todayWeekday = cal.component(.weekday, from: today) - 1  // 0 = Sunday
        guard let currentSunday = cal.date(byAdding: .day, value: -todayWeekday, to: today),
              let columnSunday  = cal.date(byAdding: .weekOfYear, value: -(totalCols - 1 - weekIndex), to: currentSunday),
              let date           = cal.date(byAdding: .day, value: dayIndex, to: columnSunday)
        else { return nil }
        return date
    }

    private var isToday: Bool {
        let todayWeekday = Calendar.current.component(.weekday, from: .now) - 1 // 0=Sun
        return weekIndex == totalCols - 1 && dayIndex == todayWeekday
    }

    private var isFuture: Bool {
        let todayWeekday = Calendar.current.component(.weekday, from: .now) - 1
        return weekIndex == totalCols - 1 && dayIndex > todayWeekday
    }

    private var cell: DayCell? { cellsByDate[cellDate ?? .distantPast] }

    private var fillOpacity: Double {
        guard !isFuture else { return 0 }
        let intensity = cell?.intensity ?? 0
        if intensity <= 0 { return 0 }
        if intensity >= 1.0 { return 1.0 }
        if intensity >= 0.5 { return 0.55 }
        return 0.30
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cellSize * 0.27, style: .continuous)
                .fill(
                    isFuture
                        ? ColorPalette[colorIndex].opacity(0.07)
                        : (cell?.intensity ?? 0) > 0
                            ? ColorPalette[colorIndex].opacity(fillOpacity)
                            : ColorPalette[colorIndex].opacity(0.13)
                )
                .frame(width: cellSize, height: cellSize)

            // Today ring
            if isToday {
                RoundedRectangle(cornerRadius: cellSize * 0.27, style: .continuous)
                    .stroke(Color.white.opacity(0.85), lineWidth: 1.5)
                    .frame(width: cellSize, height: cellSize)
            }
        }
    }
}

// MARK: - Streak card

struct RefStreakCard: View {
    let board: HabitBoard

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 5) {
                Image(systemName: "flame")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(white: 0.55))
                Text("CURRENT STREAK")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(white: 0.55))
                    .tracking(0.5)
            }

            Spacer(minLength: 18)

            // Dash or number
            if board.currentStreak > 0 {
                Text("\(board.currentStreak)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(ColorPalette[board.colorIndex])
            } else {
                // Two thick white dashes
                HStack(spacing: 8) {
                    Capsule()
                        .fill(Color(white: 0.75))
                        .frame(width: 28, height: 7)
                    Capsule()
                        .fill(Color(white: 0.75))
                        .frame(width: 38, height: 7)
                }
            }

            Spacer(minLength: 14)

            // Longest
            HStack(spacing: 4) {
                Text("Longest:")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(white: 0.45))
                Text("\(board.longestStreak)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 158, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color(white: 0.105)))
    }
}

// MARK: - Consistency card

struct RefConsistencyCard: View {
    let board: HabitBoard

    private var ratio: Double {
        guard let monthStart = Calendar.current.date(
            from: Calendar.current.dateComponents([.year,.month], from: .now)
        ) else { return 0 }
        let elapsed = max(1, (Calendar.current.dateComponents([.day], from: monthStart, to: .now).day ?? 0) + 1)
        var daily = [Date: Double]()
        for log in board.logs ?? [] {
            guard log.timestamp >= monthStart else { continue }
            let day = Calendar.current.startOfDay(for: log.timestamp)
            daily[day, default: 0] += log.value
        }
        return Double(daily.filter { $0.value >= board.effectiveTarget }.count) / Double(elapsed)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 5) {
                Image(systemName: "leaf")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(white: 0.55))
                Text("CONSISTENCY")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(white: 0.55))
                    .tracking(0.5)
            }

            Spacer(minLength: 10)

            // Open-bottom arc — stroke width 14, neutral greys
            ZStack {
                // Track: open bottom (trim 0.125…0.875, rotated 90° = opens at bottom)
                Circle()
                    .trim(from: 0.125, to: 0.875)
                    .stroke(Color(white: 0.20),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(90))

                // Fill
                if ratio > 0 {
                    Circle()
                        .trim(from: 0.125, to: 0.125 + 0.75 * min(1, ratio))
                        .stroke(Color(white: 0.42),
                                style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(90))
                }

                Text("Average")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(white: 0.42))
            }
            .frame(height: 90)
            .padding(.horizontal, 6)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 158, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color(white: 0.105)))
    }
}

// MARK: - Month card

struct RefMonthCard: View {
    let board: HabitBoard

    private var monthTotal: Double {
        guard let start = Calendar.current.date(
            from: Calendar.current.dateComponents([.year,.month], from: .now)
        ) else { return 0 }
        return (board.logs ?? []).filter { $0.timestamp >= start }.reduce(0) { $0 + $1.value }
    }

    private var weekTotals: [Double] {
        let today = Calendar.current.startOfDay(for: .now)
        guard let sunday = Calendar.current.date(
            from: Calendar.current.dateComponents([.yearForWeekOfYear,.weekOfYear], from: today)
        ) else { return Array(repeating: 0, count: 7) }
        return (0..<7).map { i -> Double in
            guard let day = Calendar.current.date(byAdding: .day, value: i, to: sunday) else { return 0 }
            return (board.logs ?? [])
                .filter { Calendar.current.isDate($0.timestamp, inSameDayAs: day) }
                .reduce(0, { $0 + $1.value })
        }
    }

    private var weekTotal: Double { weekTotals.reduce(0,+) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 5) {
                Image(systemName: "chart.bar")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(white: 0.55))
                Text("CURRENT MONTH")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(white: 0.55))
                    .tracking(0.5)
            }

            Spacer(minLength: 10)

            // Value row + bars
            HStack(alignment: .bottom, spacing: 0) {
                // Big number
                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    Text(String(format: "%.0f", monthTotal))
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            monthTotal > 0 ? ColorPalette[board.colorIndex] : Color(white: 0.28)
                        )
                    if let u = board.unitLabel, !u.isEmpty {
                        Text(u)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Color(white: 0.50))
                            .padding(.bottom, 6)
                    }
                }

                Spacer()

                // 7 bars
                let todayIdx = Calendar.current.component(.weekday, from: .now) - 1 // 0=Sun
                let maxV = max(weekTotals.max() ?? 1, board.effectiveTarget, 1)

                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(0..<7, id: \.self) { i in
                        let v       = weekTotals[i]
                        let isToday = i == todayIdx
                        let isFut   = i > todayIdx
                        let barH: CGFloat = v > 0 ? max(8, 56 * CGFloat(v / maxV)) : 6

                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(
                                isToday && v > 0
                                    ? ColorPalette[board.colorIndex]
                                    : isFut
                                        ? Color(white: 0.13)
                                        : Color(white: v > 0 ? 0.26 : 0.18)
                            )
                            .frame(width: 16, height: barH)
                    }
                }
            }

            Spacer(minLength: 14)

            // Footer
            HStack(spacing: 4) {
                Text("Current week:")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(white: 0.40))
                if weekTotal > 0 {
                    Text(String(format: "%.0f", weekTotal))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                    if let u = board.unitLabel, !u.isEmpty {
                        Text(u)
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
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color(white: 0.105)))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HabitDetailView(board: HabitBoard(name: "Work on side project", metricType: 1, targetValue: 1, unitLabel: "h", colorIndex: 5))
    }
}
