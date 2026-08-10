//
//  MonthlyReviewView.swift
//  LOCA
//
//  V2.5E.3 — Cross-habit monthly rollup.
//  Navigable month-by-month (← →). Surfaces each habit's completion rate
//  vs the previous month, best habit highlight, and a horizontal bar for
//  each. All stats computed live from board.logs — no persisted rollup.
//

import SwiftUI
import SwiftData

struct MonthlyReviewView: View {

    @Query(sort: [SortDescriptor(\HabitBoard.createdAt)], animation: .default)
    private var allBoards: [HabitBoard]

    @State private var monthOffset: Int = 0   // 0 = this month, -1 = last, etc.

    private var activeBoards: [HabitBoard] { allBoards.filter { $0.archivedAt == nil } }

    // MARK: - Month boundaries

    private var monthStart: Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month], from: Date())
        comps.day = 1
        let thisMonth = cal.date(from: comps) ?? Date()
        return cal.date(byAdding: .month, value: monthOffset, to: thisMonth) ?? thisMonth
    }

    private var monthEndExclusive: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
    }

    private var prevMonthStart: Date {
        Calendar.current.date(byAdding: .month, value: -1, to: monthStart) ?? monthStart
    }

    private var isCurrentMonth: Bool { monthOffset == 0 }

    /// Days elapsed in the selected month. Clamps to today for the current month.
    private var elapsedDays: Int {
        let cal = Calendar.current
        if isCurrentMonth {
            return cal.component(.day, from: Date())
        } else {
            return cal.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        }
    }

    private var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: monthStart)?.count ?? 30
    }

    // MARK: - Per-habit stats

    private struct MonthStats {
        let goalDays: Int
        let total: Double
    }

    private func stats(for board: HabitBoard, from start: Date, to end: Date) -> MonthStats {
        let cal = Calendar.current
        var dayTotals: [Date: Double] = [:]
        for log in (board.logs ?? []) where log.archivedAt == nil {
            guard log.timestamp >= start, log.timestamp < end else { continue }
            let day = cal.startOfDay(for: log.timestamp)
            dayTotals[day, default: 0] += log.value
        }
        let target = board.metric == .binary ? 1.0 : board.effectiveTarget
        let goalDays = dayTotals.values.filter { $0 >= target }.count
        let total = dayTotals.values.reduce(0, +)
        return MonthStats(goalDays: goalDays, total: total)
    }

    /// Completion rate 0–1 for the elapsed portion of the month.
    private func completionRate(for board: HabitBoard) -> Double {
        guard elapsedDays > 0 else { return 0 }
        return Double(stats(for: board, from: monthStart, to: monthEndExclusive).goalDays) / Double(elapsedDays)
    }

    private var bestBoard: HabitBoard? {
        activeBoards.max { completionRate(for: $0) < completionRate(for: $1) }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                monthHeader

                if activeBoards.isEmpty {
                    emptyState
                } else {
                    summaryLine
                        .padding(.top, -DS.Space.xs)

                    if let best = bestBoard, completionRate(for: best) > 0 {
                        bestHabitCard(best)
                    }

                    habitList
                }

                Spacer(minLength: DS.Space.xxxl)
            }
            .padding(DS.Space.lg)
        }
        .navigationTitle("Monthly Review")
        .inlineNavigationTitleDisplay()
    }

    // MARK: - Month header + navigation

    private var monthHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(isCurrentMonth ? "This Month" : monthLabel)
                    .font(.title2).fontWeight(.semibold)
                    .foregroundStyle(DS.Color.textPrimary)
                if isCurrentMonth {
                    Text(monthLabel)
                        .font(.caption)
                        .foregroundStyle(DS.Color.textTertiary)
                }
            }
            Spacer()
            HStack(spacing: DS.Space.sm) {
                navButton(direction: .back)
                navButton(direction: .forward)
            }
        }
    }

    private enum NavDirection { case back, forward }

    private func navButton(direction: NavDirection) -> some View {
        let isBack = direction == .back
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                monthOffset = isBack ? monthOffset - 1 : min(monthOffset + 1, 0)
            }
        } label: {
            Image(systemName: isBack ? "chevron.left" : "chevron.right")
                .font(.caption)
                .frame(width: 32, height: 32)
                .background(DS.Color.surfaceRecessed, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(isBack ? monthOffset <= -24 : monthOffset == 0)
    }

    // MARK: - Summary

    private var summaryLine: some View {
        let onTrack = activeBoards.filter { completionRate(for: $0) >= 0.7 }.count
        let all = onTrack == activeBoards.count
        return Text(all
            ? (activeBoards.count == 1 ? "Habit on track" : "All \(activeBoards.count) habits on track")
            : "\(onTrack) of \(activeBoards.count) habits on track")
            .font(DS.Text.body)
            .foregroundStyle(DS.Color.textSecondary)
    }

    // MARK: - Best habit card

    private func bestHabitCard(_ board: HabitBoard) -> some View {
        let accent = ColorPalette[board.colorIndex]
        let rate = completionRate(for: board)
        return VStack(alignment: .leading, spacing: DS.Space.sm) {
            Label("Top habit this month", systemImage: "star.fill")
                .font(.caption2)
                .foregroundStyle(accent)

            Text(board.name)
                .font(DS.Text.body).fontWeight(.semibold)
                .foregroundStyle(DS.Color.textPrimary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(DS.Color.border)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(accent.opacity(0.85))
                        .frame(width: geo.size.width * CGFloat(min(rate, 1.0)))
                }
            }
            .frame(height: 6)

            Text("\(Int(rate * 100))% of days")
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
            .stroke(accent.opacity(0.4), lineWidth: 1))
    }

    // MARK: - Habit list

    private var habitList: some View {
        VStack(spacing: DS.Space.sm) {
            ForEach(activeBoards, id: \.id) { board in
                habitRow(board)
            }
        }
    }

    private func habitRow(_ board: HabitBoard) -> some View {
        let accent = ColorPalette[board.colorIndex]
        let current = stats(for: board, from: monthStart, to: monthEndExclusive)
        let prev = stats(for: board, from: prevMonthStart, to: monthStart)
        let rate = elapsedDays > 0 ? Double(current.goalDays) / Double(elapsedDays) : 0
        let prevRate = daysInMonth > 0 ? Double(prev.goalDays) / Double(daysInMonth) : 0
        let delta = rate - prevRate
        let showTrend = prev.goalDays > 0 && abs(delta) >= 0.05

        return VStack(alignment: .leading, spacing: DS.Space.xs) {
            HStack(spacing: DS.Space.sm) {
                Circle().fill(accent).frame(width: 8, height: 8)
                Text(board.name)
                    .font(DS.Text.body)
                    .foregroundStyle(DS.Color.textPrimary)
                Spacer()
                if showTrend {
                    Text(delta >= 0 ? "↑\(Int(delta * 100))pp" : "↓\(Int(abs(delta) * 100))pp")
                        .font(.caption2).monospacedDigit()
                        .foregroundStyle(delta >= 0 ? accent : DS.Color.textSecondary)
                }
                Text("\(current.goalDays)/\(elapsedDays)d")
                    .font(.caption2).monospacedDigit()
                    .foregroundStyle(DS.Color.textTertiary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(DS.Color.border)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(accent.opacity(0.75))
                        .frame(width: geo.size.width * CGFloat(min(rate, 1.0)))
                }
            }
            .frame(height: 5)
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
            .stroke(DS.Color.border, lineWidth: 1))
    }

    // MARK: - Helpers

    private var monthLabel: String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        return f.string(from: monthStart)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Habits Yet", systemImage: "checkmark.circle")
        } description: {
            Text("Add habits to see your monthly review.")
        }
    }
}
