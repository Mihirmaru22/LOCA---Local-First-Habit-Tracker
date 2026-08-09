import SwiftUI
import SwiftData
import Charts

// MARK: - MacJournalAnalyse   (J5)

/// Analyse view for the Mac Journal section.
///
/// Three sections shown in one scrollable pane:
/// 1. **Stat cards** — avg sleep this month, best daily-habit streak, moment count.
/// 2. **Sleep line chart** — one point per `SleepEntry` in the current month.
/// 3. **Daily-habit month heatmap** — one row per daily habit, one cell per day.
struct MacJournalAnalyse: View {

    @Query(sort: [SortDescriptor(\SleepEntry.date)])
    private var allSleepEntries: [SleepEntry]

    @Query(filter: #Predicate<JournalNote> { $0.noteKindRaw == 1 && $0.archivedAt == nil },
           sort: [SortDescriptor(\JournalNote.date)])
    private var allMoments: [JournalNote]

    @Query(filter: #Predicate<HabitBoard> { board in
        board.habitKindRaw == 1 && board.archivedAt == nil
    }, sort: \HabitBoard.createdAt)
    private var dailyHabits: [HabitBoard]

    // MARK: Month boundaries (recomputed only when needed — value types)

    private var monthStart: Date {
        Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: Date())
        ) ?? Date()
    }

    private var monthEnd: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: monthStart) ?? Date()
    }

    private var monthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f.string(from: Date()).uppercased()
    }

    // MARK: Derived values

    private var monthlySleep: [SleepEntry] {
        allSleepEntries.filter {
            !$0.isArchived && $0.date >= monthStart && $0.date < monthEnd
        }
    }

    private var avgSleep: Double {
        guard !monthlySleep.isEmpty else { return 0 }
        return monthlySleep.map(\.sleepHours).reduce(0, +) / Double(monthlySleep.count)
    }

    private var bestStreak: Int {
        dailyHabits.map(\.currentStreak).max() ?? 0
    }

    private var momentCount: Int {
        allMoments.filter { $0.date >= monthStart && $0.date < monthEnd }.count
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xl) {

                statRow

                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    sectionLabel("SLEEP (HRS) · \(monthLabel)")
                    sleepChart
                }

                if !dailyHabits.isEmpty {
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        sectionLabel("DAILY HABITS — \(monthLabel)")
                        DailyHabitMonthGrid(
                            habits:     dailyHabits,
                            monthStart: monthStart,
                            monthEnd:   monthEnd
                        )
                    }
                }

                Spacer(minLength: DS.Space.xxxl)
            }
            .padding(DS.Space.lg)
        }
    }

    // MARK: Stat row

    private var statRow: some View {
        HStack(spacing: DS.Space.md) {
            AnalyseStatCard(
                label: "AVG SLEEP",
                value: avgSleep > 0 ? String(format: "%.1fh", avgSleep) : "—",
                icon:  "moon.fill",
                color: .blue
            )
            AnalyseStatCard(
                label: "BEST STREAK",
                value: bestStreak > 0 ? "\(bestStreak)" : "—",
                icon:  "flame.fill",
                color: .orange
            )
            AnalyseStatCard(
                label: "MOMENTS",
                value: "\(momentCount)",
                icon:  "sparkles",
                color: .purple
            )
        }
    }

    // MARK: Sleep chart

    @ViewBuilder
    private var sleepChart: some View {
        if monthlySleep.isEmpty {
            Text("No sleep data logged yet.")
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DS.Space.md)
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        } else {
            Chart(monthlySleep, id: \.id) { entry in
                LineMark(
                    x: .value("Day", entry.date, unit: .day),
                    y: .value("Hours", entry.sleepHours)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Day", entry.date, unit: .day),
                    y: .value("Hours", entry.sleepHours)
                )
                .foregroundStyle(.blue)
                .symbolSize(28)
            }
            .chartXScale(domain: monthStart...monthEnd)
            .chartYScale(domain: 0...12)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 5)) { _ in
                    AxisValueLabel(format: .dateTime.day())
                        .font(.system(size: 9))
                        .foregroundStyle(DS.Color.textTertiary)
                    AxisGridLine().foregroundStyle(DS.Color.border)
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 2, 4, 6, 8, 10]) { value in
                    AxisValueLabel {
                        if let h = value.as(Double.self) {
                            Text("\(Int(h))h")
                                .font(.system(size: 9))
                                .foregroundStyle(DS.Color.textTertiary)
                        }
                    }
                    AxisGridLine().foregroundStyle(DS.Color.border)
                }
            }
            .frame(height: 140)
            .padding(DS.Space.md)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        }
    }

    // MARK: Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(DS.Text.caption)
            .foregroundStyle(DS.Color.textTertiary)
            .tracking(0.8)
    }
}

// MARK: - AnalyseStatCard

private struct AnalyseStatCard: View {

    let label: String
    let value: String
    let icon:  String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            HStack(spacing: DS.Space.xs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(label)
                    .font(DS.Text.footnote)
                    .foregroundStyle(DS.Color.textSecondary)
                    .tracking(0.5)
            }
            Text(value)
                .font(DS.Text.value)
                .foregroundStyle(color)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }
}

// MARK: - DailyHabitMonthGrid

/// Month-scoped heatmap for daily habits only.
///
/// One row per daily habit (habitKindRaw == 1), one cell per calendar day
/// in the given month. Completed days are filled with the habit's accent color;
/// future days show a faint placeholder; today's cell has a subtle border.
private struct DailyHabitMonthGrid: View {

    let habits:     [HabitBoard]
    let monthStart: Date
    let monthEnd:   Date

    private let cellSize:  CGFloat = 10
    private let cellGap:   CGFloat = 2
    private let nameWidth: CGFloat = 64

    private var monthDays: [Date] {
        var days: [Date] = []
        var cursor = monthStart
        while cursor < monthEnd {
            days.append(cursor)
            cursor = Calendar.current.date(byAdding: .day, value: 1, to: cursor) ?? monthEnd
        }
        return days
    }

    private var todayStart: Date {
        Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: cellGap) {
                columnHeaders
                ForEach(habits, id: \.id) { habit in
                    habitRow(habit)
                }
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    private var columnHeaders: some View {
        HStack(spacing: 0) {
            Text("").frame(width: nameWidth)
            HStack(spacing: cellGap) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { idx, day in
                    let dom = Calendar.current.component(.day, from: day)
                    Text(idx % 5 == 0 ? "\(dom)" : "")
                        .font(.system(size: 7))
                        .foregroundStyle(DS.Color.textTertiary)
                        .frame(width: cellSize)
                }
            }
        }
    }

    private func habitRow(_ board: HabitBoard) -> some View {
        let completed = completedDaySet(for: board)
        return HStack(spacing: 0) {
            Text(board.name)
                .font(.system(size: 10))
                .lineLimit(1)
                .foregroundStyle(DS.Color.textSecondary)
                .frame(width: nameWidth, alignment: .trailing)
                .padding(.trailing, DS.Space.xs)

            HStack(spacing: cellGap) {
                ForEach(monthDays, id: \.self) { day in
                    let done   = completed.contains(day)
                    let future = day > todayStart
                    let today  = Calendar.current.isDateInToday(day)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(done
                              ? ColorPalette[board.colorIndex]
                              : future
                                  ? DS.Color.heatmapCellFuture
                                  : DS.Color.heatmapCellEmpty)
                        .frame(width: cellSize, height: cellSize)
                        .overlay(
                            today
                                ? RoundedRectangle(cornerRadius: 2)
                                    .strokeBorder(DS.Color.textTertiary, lineWidth: 0.5)
                                : nil
                        )
                }
            }
        }
    }

    private func completedDaySet(for board: HabitBoard) -> Set<Date> {
        let cal    = Calendar.current
        let target = board.effectiveTarget
        var totals: [Date: Double] = [:]
        for log in board.activeLogs {
            guard log.timestamp >= monthStart, log.timestamp < monthEnd else { continue }
            totals[cal.startOfDay(for: log.timestamp), default: 0] += log.value
        }
        return Set(totals.filter { $0.value >= target }.keys)
    }
}
