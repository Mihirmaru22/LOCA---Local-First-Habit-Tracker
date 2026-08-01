//
//  WeeklyDigestView.swift
//  LOCA
//
//  V2.5E.2 — Cross-habit weekly rollup.
//  Navigable week-by-week (← →). Shows each habit's 7-day WeeklyBarChart plus
//  goal-day count and streak. All stats computed live from board.logs — no
//  persisted rollup entity needed.
//

import SwiftUI
import SwiftData

struct WeeklyDigestView: View {

    @Query(sort: [SortDescriptor(\HabitBoard.createdAt)], animation: .default)
    private var allBoards: [HabitBoard]

    @State private var weekOffset: Int = 0   // 0 = this week, -1 = last week, etc.

    private var activeBoards: [HabitBoard] { allBoards.filter { $0.archivedAt == nil } }

    // MARK: - Week boundaries (ISO Monday start, locale-independent)

    private var weekStart: Date {
        let cal = Calendar.current
        let now = Date()
        let weekday = cal.component(.weekday, from: now)   // 1=Sun … 7=Sat
        let daysBack = weekday == 1 ? 6 : weekday - 2     // days to go back to Monday
        let thisMonday = cal.date(byAdding: .day, value: -daysBack,
                                  to: cal.startOfDay(for: now)) ?? now
        return cal.date(byAdding: .weekOfYear, value: weekOffset, to: thisMonday) ?? thisMonday
    }

    private var weekEndExclusive: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
    }

    private var isCurrentWeek: Bool { weekOffset == 0 }

    /// Days elapsed in the selected week (1–7). Clamps to today for the current week.
    private var elapsedDays: Int {
        guard isCurrentWeek else { return 7 }
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday - 2 + 7) % 7 + 1   // Mon = 1, Sun = 7
    }

    // MARK: - Per-habit stats

    /// Daily totals Mon[0]…Sun[6] for the selected week.
    private func dailyTotals(for board: HabitBoard) -> [Double] {
        let cal = Calendar.current
        var totals = Array(repeating: 0.0, count: 7)
        for log in (board.logs ?? []) where log.archivedAt == nil {
            guard log.timestamp >= weekStart, log.timestamp < weekEndExclusive else { continue }
            let wd = cal.component(.weekday, from: log.timestamp)
            let idx = (wd - 2 + 7) % 7   // Mon=0 … Sun=6
            totals[idx] += log.value
        }
        return totals
    }

    /// Distinct days in the week where the daily total met or exceeded the target.
    private func goalDays(for board: HabitBoard) -> Int {
        let cal = Calendar.current
        var dayTotals: [Date: Double] = [:]
        for log in (board.logs ?? []) where log.archivedAt == nil {
            guard log.timestamp >= weekStart, log.timestamp < weekEndExclusive else { continue }
            let day = cal.startOfDay(for: log.timestamp)
            dayTotals[day, default: 0] += log.value
        }
        let target = board.metric == .binary ? 1.0 : board.effectiveTarget
        return dayTotals.values.filter { $0 >= target }.count
    }

    /// Habits that are 70 %+ complete through the elapsed days of the week.
    private var onTrackCount: Int {
        guard elapsedDays > 0 else { return 0 }
        return activeBoards.filter { Double(goalDays(for: $0)) / Double(elapsedDays) >= 0.7 }.count
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                weekHeader

                if activeBoards.isEmpty {
                    emptyState
                } else {
                    summaryLine
                        .padding(.top, -DS.Space.xs)
                    habitList
                }

                Spacer(minLength: DS.Space.xxxl)
            }
            .padding(DS.Space.lg)
        }
        .navigationTitle("This Week")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Week header + navigation

    private var weekHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(isCurrentWeek ? "This Week" : weekRangeLabel)
                    .font(.title2).fontWeight(.semibold)
                    .foregroundStyle(DS.Color.textPrimary)
                if isCurrentWeek {
                    Text(weekRangeLabel)
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
                weekOffset = isBack ? weekOffset - 1 : min(weekOffset + 1, 0)
            }
        } label: {
            Image(systemName: isBack ? "chevron.left" : "chevron.right")
                .font(.caption)
                .frame(width: 32, height: 32)
                .background(DS.Color.surfaceRecessed, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(isBack ? weekOffset <= -52 : weekOffset == 0)
    }

    // MARK: - Summary + habit rows

    private var summaryLine: some View {
        let all = onTrackCount == activeBoards.count
        return Text(all
            ? (activeBoards.count == 1 ? "Habit on track" : "All \(activeBoards.count) habits on track")
            : "\(onTrackCount) of \(activeBoards.count) habits on track")
            .font(DS.Text.body)
            .foregroundStyle(DS.Color.textSecondary)
    }

    private var habitList: some View {
        VStack(spacing: DS.Space.sm) {
            ForEach(activeBoards, id: \.id) { board in
                habitRow(board)
            }
        }
    }

    private func habitRow(_ board: HabitBoard) -> some View {
        let totals  = dailyTotals(for: board)
        let days    = goalDays(for: board)
        let accent  = ColorPalette[board.colorIndex]
        let target  = board.metric == .binary ? 1.0 : board.effectiveTarget

        return VStack(alignment: .leading, spacing: DS.Space.xs) {
            // Name + stats row
            HStack(spacing: DS.Space.sm) {
                Circle().fill(accent).frame(width: 8, height: 8)
                Text(board.name)
                    .font(DS.Text.body)
                    .foregroundStyle(DS.Color.textPrimary)
                Spacer()
                Text("\(days)/\(elapsedDays)d")
                    .font(.caption2).monospacedDigit()
                    .foregroundStyle(DS.Color.textTertiary)
                if board.currentStreak > 1 {
                    Label("\(board.currentStreak)", systemImage: "flame.fill")
                        .font(.caption2).monospacedDigit()
                        .foregroundStyle(.orange)
                        .labelStyle(.titleAndIcon)
                }
            }

            // 7-day bar chart
            WeeklyBarChart(dailyTotals: totals, target: target,
                           accentColor: accent, size: .normal)

            // Day labels (M T W T F S S)
            let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Text(dayLabels[i])
                        .font(.system(size: 9))
                        .foregroundStyle(DS.Color.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
            .stroke(DS.Color.border, lineWidth: 1))
    }

    // MARK: - Helpers

    private var weekRangeLabel: String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        let endDay = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "\(f.string(from: weekStart)) – \(f.string(from: endDay))"
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Habits Yet", systemImage: "checkmark.circle")
        } description: {
            Text("Add habits to see your weekly review.")
        }
    }
}
