import SwiftUI
import SwiftData

// MARK: - MacJournalAnalyse   (J3 + J6)

/// Analyse mode for the Mac Journal section.
///
/// Three sections in one scrollable pane:
/// 1. **Weekly digest** — per-habit 7-day bar charts with week navigation (J3).
/// 2. **30-day grid** — cross-habit completion grid (`MacDailyHabitGrid`, J4).
/// 3. **Reflection card** — one honest sentence from `ReflectionGenerator` (J6).
struct MacJournalAnalyse: View {

    @Query(sort: [SortDescriptor(\HabitBoard.createdAt)], animation: .default)
    private var allBoards: [HabitBoard]

    @State private var weekOffset: Int = 0

    private var activeBoards: [HabitBoard] { allBoards.filter { $0.archivedAt == nil } }

    // MARK: - Week boundaries (ISO Monday start, locale-independent)

    private var weekStart: Date {
        let cal = Calendar.current
        let now = Date()
        let weekday = cal.component(.weekday, from: now)
        let daysBack = weekday == 1 ? 6 : weekday - 2
        let thisMonday = cal.date(byAdding: .day, value: -daysBack,
                                  to: cal.startOfDay(for: now)) ?? now
        return cal.date(byAdding: .weekOfYear, value: weekOffset, to: thisMonday) ?? thisMonday
    }

    private var weekEndExclusive: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
    }

    private var isCurrentWeek: Bool { weekOffset == 0 }

    private var elapsedDays: Int {
        guard isCurrentWeek else { return 7 }
        let wd = Calendar.current.component(.weekday, from: Date())
        return (wd - 2 + 7) % 7 + 1
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                weekNavHeader

                if activeBoards.isEmpty {
                    ContentUnavailableView {
                        Label("No Habits Yet", systemImage: "checkmark.circle")
                    } description: {
                        Text("Add habits to see your weekly digest.")
                    }
                } else {
                    summaryLine
                    habitRows

                    sectionLabel("30-Day Overview")
                    MacDailyHabitGrid()

                    reflectionCard
                }

                Spacer(minLength: DS.Space.xxxl)
            }
            .padding(DS.Space.md)
        }
    }

    // MARK: - Week navigation header

    private var weekNavHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(isCurrentWeek ? "This Week" : weekRangeLabel)
                    .font(DS.Text.heading)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Color.textPrimary)
                if isCurrentWeek {
                    Text(weekRangeLabel)
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textTertiary)
                }
            }
            Spacer()
            HStack(spacing: DS.Space.xs) {
                navButton(isBack: true)
                navButton(isBack: false)
            }
        }
    }

    private func navButton(isBack: Bool) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                weekOffset = isBack ? weekOffset - 1 : min(weekOffset + 1, 0)
            }
        } label: {
            Image(systemName: isBack ? "chevron.left" : "chevron.right")
                .font(.caption)
                .frame(width: 28, height: 28)
                .background(DS.Color.surfaceRecessed, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(isBack ? weekOffset <= -52 : weekOffset == 0)
    }

    // MARK: - Summary line

    private var summaryLine: some View {
        let onTrack = activeBoards.filter {
            guard elapsedDays > 0 else { return false }
            return Double(goalDays(for: $0)) / Double(elapsedDays) >= 0.7
        }.count
        let all = onTrack == activeBoards.count
        return Text(all
            ? (activeBoards.count == 1 ? "Habit on track" : "All \(activeBoards.count) habits on track")
            : "\(onTrack) of \(activeBoards.count) habits on track")
            .font(DS.Text.body)
            .foregroundStyle(DS.Color.textSecondary)
    }

    // MARK: - Per-habit weekly rows

    private var habitRows: some View {
        VStack(spacing: DS.Space.xs) {
            ForEach(activeBoards, id: \.id) { board in
                habitRow(board)
            }
        }
    }

    private func habitRow(_ board: HabitBoard) -> some View {
        let totals = dailyTotals(for: board)
        let days   = goalDays(for: board)
        let accent = ColorPalette[board.colorIndex]
        let target = board.metric == .binary ? 1.0 : board.effectiveTarget

        return VStack(alignment: .leading, spacing: DS.Space.xs) {
            HStack(spacing: DS.Space.xs) {
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
            WeeklyBarChart(dailyTotals: totals, target: target,
                           accentColor: accent, size: .compact)
            let labels = ["M", "T", "W", "T", "F", "S", "S"]
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Text(labels[i])
                        .font(.system(size: 8))
                        .foregroundStyle(DS.Color.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(DS.Space.sm)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
            .stroke(DS.Color.border, lineWidth: 1))
    }

    // MARK: - J6 Reflection card

    @ViewBuilder
    private var reflectionCard: some View {
        let allLogs = activeBoards.flatMap { board in
            board.activeLogs.map { LogSnapshot(from: $0) }
        }
        if let reflection = ReflectionGenerator.generateInsightReflection(
            boards: activeBoards,
            allLogs: allLogs
        ) {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Label("Reflection", systemImage: "lightbulb")
                    .font(DS.Text.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(DS.Color.textTertiary)

                Text(reflection.text)
                    .font(DS.Text.body)
                    .foregroundStyle(DS.Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(DS.Space.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.border, lineWidth: 1))
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(DS.Text.caption)
            .textCase(.uppercase)
            .foregroundStyle(DS.Color.textTertiary)
    }

    private var weekRangeLabel: String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        let endDay = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "\(f.string(from: weekStart)) – \(f.string(from: endDay))"
    }

    private func dailyTotals(for board: HabitBoard) -> [Double] {
        let cal = Calendar.current
        var totals = Array(repeating: 0.0, count: 7)
        for log in board.activeLogs {
            guard log.timestamp >= weekStart, log.timestamp < weekEndExclusive else { continue }
            let wd = cal.component(.weekday, from: log.timestamp)
            let idx = (wd - 2 + 7) % 7
            totals[idx] += log.value
        }
        return totals
    }

    private func goalDays(for board: HabitBoard) -> Int {
        let cal = Calendar.current
        var dayTotals: [Date: Double] = [:]
        for log in board.activeLogs {
            guard log.timestamp >= weekStart, log.timestamp < weekEndExclusive else { continue }
            let day = cal.startOfDay(for: log.timestamp)
            dayTotals[day, default: 0] += log.value
        }
        let target = board.metric == .binary ? 1.0 : board.effectiveTarget
        return dayTotals.values.filter { $0 >= target }.count
    }
}
