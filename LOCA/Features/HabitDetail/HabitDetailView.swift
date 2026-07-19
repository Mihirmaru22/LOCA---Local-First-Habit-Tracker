//
//  HabitDetailView.swift
//  LOCA
//
//  Phase 14.5 — Habit Detail: Full analytics view with heatmap and metric cards.
//
//  Single unified detail view showing:
//  - Large week-labeled heatmap (7 rows × ~52 weeks)
//  - Current Streak card
//  - Consistency gauge card
//  - Current Month bar chart card
//  - Bottom toolbar for chart/checkins/journal navigation
//

import SwiftUI
import SwiftData

struct HabitDetailView: View {
    let board: HabitBoard
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var showingEditSheet = false
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    // Heatmap with day labels
                    HabitHeatmapWithLabels(board: board)
                        .padding(.horizontal, DS.Space.lg)

                    // Metrics cards
                    VStack(spacing: DS.Space.md) {
                        HStack(spacing: DS.Space.md) {
                            CurrentStreakCard(board: board)
                            ConsistencyCard(board: board)
                        }

                        CurrentMonthCard(board: board)
                    }
                    .padding(.horizontal, DS.Space.lg)

                    Spacer(minLength: DS.Space.xxxl)
                }
                .padding(.vertical, DS.Space.lg)
            }

            // Bottom toolbar
            HStack(spacing: DS.Space.lg) {
                Button(action: { selectedTab = 0 }) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.title2)
                        .foregroundStyle(selectedTab == 0 ? ColorPalette[board.colorIndex] : DS.Color.textSecondary)
                }

                Button(action: { selectedTab = 1 }) {
                    Image(systemName: "checklist")
                        .font(.title2)
                        .foregroundStyle(selectedTab == 1 ? ColorPalette[board.colorIndex] : DS.Color.textSecondary)
                }

                Button(action: { selectedTab = 2 }) {
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundStyle(selectedTab == 2 ? ColorPalette[board.colorIndex] : DS.Color.textSecondary)
                }

                Spacer()

                Button(action: { showingEditSheet = true }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundStyle(ColorPalette[board.colorIndex])
                }
            }
            .padding(DS.Space.lg)
            .background(DS.Color.surface)
        }
        .navigationTitle(board.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(ColorPalette[board.colorIndex])
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingEditSheet = true }) {
                    Image(systemName: "pencil")
                        .foregroundStyle(ColorPalette[board.colorIndex])
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            HabitFormView(mode: .edit(board))
        }
    }
}

// MARK: - Heatmap with Day Labels

struct HabitHeatmapWithLabels: View {
    let board: HabitBoard

    private var weeksToShow: Int {
        52
    }

    private var dayLabels: [String] {
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    }

    var body: some View {
        VStack(spacing: 1) {
            ForEach(0..<7, id: \.self) { dayIndex in
                HStack(spacing: 1) {
                    // Day label
                    Text(dayLabels[dayIndex])
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(width: 40)

                    // Week cells
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: weeksToShow), spacing: 1) {
                        ForEach(0..<weeksToShow, id: \.self) { weekIndex in
                            HeatmapWeekCell(
                                board: board,
                                dayIndex: dayIndex,
                                weekIndex: weekIndex
                            )
                        }
                    }
                }
            }
        }
        .padding(DS.Space.md)
        .background(ColorPalette[board.colorIndex].opacity(0.08), in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(ColorPalette[board.colorIndex].opacity(0.2), lineWidth: 0.5)
        )
    }
}

// MARK: - Heatmap Week Cell

struct HeatmapWeekCell: View {
    let board: HabitBoard
    let dayIndex: Int
    let weekIndex: Int

    private var cellDate: Date? {
        let today = Calendar.current.startOfDay(for: .now)
        let weeksBack = 52 - 1 - weekIndex
        let daysBack = weeksBack * 7 + dayIndex
        return Calendar.current.date(byAdding: .day, value: -daysBack, to: today)
    }

    private var dayLogs: [LogEntry]? {
        guard let date = cellDate else { return nil }
        return (board.logs ?? [])
            .filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
    }

    private var totalValue: Double {
        dayLogs?.reduce(0.0) { $0 + $1.value } ?? 0
    }

    private var cellOpacity: Double {
        guard let logs = dayLogs, !logs.isEmpty else { return 0 }
        let ratio = totalValue / board.effectiveTarget
        return min(1.0, max(0.3, ratio))
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(
                (dayLogs?.isEmpty ?? true)
                    ? DS.Color.surface
                    : ColorPalette[board.colorIndex].opacity(cellOpacity)
            )
            .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Current Streak Card

struct CurrentStreakCard: View {
    let board: HabitBoard

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack(spacing: DS.Space.sm) {
                Image(systemName: "flame.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                
                Text("CURRENT STREAK")
                    .font(DS.Text.caption)
                    .tracking(0.5)
                    .foregroundStyle(DS.Color.textSecondary)
                
                Spacer()
            }

            ValueText(
                String(board.currentStreak),
                font: DS.Text.valueHero
            )
            .foregroundStyle(ColorPalette[board.colorIndex])

            Spacer(minLength: 0)

            HStack {
                Text("Longest:")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                
                ValueText(
                    String(board.longestStreak),
                    font: DS.Text.body
                )
                .foregroundStyle(DS.Color.textPrimary)
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }
}

// MARK: - Consistency Card

struct ConsistencyCard: View {
    let board: HabitBoard

    var body: some View {
        VStack(alignment: .center, spacing: DS.Space.md) {
            HStack {
                Image(systemName: "shield.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
                
                Text("CONSISTENCY")
                    .font(DS.Text.caption)
                    .tracking(0.5)
                    .foregroundStyle(DS.Color.textSecondary)
                
                Spacer()
            }

            // Ring gauge (simple arc representation)
            ZStack {
                Circle()
                    .stroke(DS.Color.surface, lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(ColorPalette[board.colorIndex], lineWidth: 8)
                    .rotationEffect(.degrees(-90))
                
                Text("Average")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .frame(height: 60)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }
}

// MARK: - Current Month Card

struct CurrentMonthCard: View {
    let board: HabitBoard

    private var currentMonthTotal: Double {
        let calendar = Calendar.current
        let now = Date()
        let monthRange = calendar.range(of: .day, in: .month, for: now)!
        let daysInMonth = monthRange.count

        var total = 0.0
        for day in 1...daysInMonth {
            let components = DateComponents(year: calendar.component(.year, from: now),
                                          month: calendar.component(.month, from: now),
                                          day: day)
            if let date = calendar.date(from: components) {
                let dayLogs = (board.logs ?? [])
                    .filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
                total += dayLogs.reduce(0.0) { $0 + $1.value }
            }
        }
        return total
    }

    private var currentWeekTotal: Double {
        let today = Calendar.current.startOfDay(for: .now)
        let sunday = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!

        var total = 0.0
        for offset in 0..<7 {
            if let date = Calendar.current.date(byAdding: .day, value: offset, to: sunday) {
                let dayLogs = (board.logs ?? [])
                    .filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
                total += dayLogs.reduce(0.0) { $0 + $1.value }
            }
        }
        return total
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                    .foregroundStyle(.gray)
                
                Text("CURRENT MONTH")
                    .font(DS.Text.caption)
                    .tracking(0.5)
                    .foregroundStyle(DS.Color.textSecondary)
                
                Spacer()
            }

            HStack(spacing: DS.Space.lg) {
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    ValueText(
                        String(format: "%.0f", currentMonthTotal),
                        font: DS.Text.valueHero
                    )
                    .foregroundStyle(ColorPalette[board.colorIndex])
                    
                    if let unit = board.unitLabel {
                        Text(unit)
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }

                Spacer()

                // Simple bar chart
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(0..<7, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(DS.Color.surface)
                            .frame(height: CGFloat.random(in: 20...50))
                    }
                }
            }

            HStack {
                Text("Current week:")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                
                Text("–")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                
                Spacer()
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HabitDetailView(board: HabitBoard(name: "Running", metricType: 1, targetValue: 5.0, unitLabel: "km", colorIndex: 0))
    }
}
