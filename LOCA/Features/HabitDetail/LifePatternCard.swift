//
//  LifePatternCard.swift
//  LOCA
//
//  V2.0A.3 + V2.0B — Per-type habit intelligence card.
//  T1 (deterministic from board.logs) is always visible.
//  T2 (PatternDetectionEngine correlation) appears as P0 data accrues.
//

import SwiftUI
import SwiftData

// MARK: - Private: Habit type classification

private enum HabitType {
    case binaryStreak
    case distance   // km, mi
    case duration   // hr, min, sec
    case count      // steps, reps, sets
    case weight     // kg, lb
    case generic

    init(board: HabitBoard) {
        guard board.metric != .binary else { self = .binaryStreak; return }
        let unit = (board.unitLabel ?? "").lowercased().trimmingCharacters(in: .whitespaces)
        switch true {
        case unit == "km", unit.hasPrefix("km"), unit == "mi", unit.hasPrefix("mi"), unit == "m":
            self = .distance
        case unit.contains("hr"), unit.contains("hour"), unit == "min", unit.contains("min"), unit.contains("sec"):
            self = .duration
        case unit.contains("step"), unit.contains("rep"), unit.contains("set"):
            self = .count
        case unit == "kg", unit == "lb", unit == "lbs":
            self = .weight
        default:
            self = .generic
        }
    }
}

// MARK: - Private: T1 stats (deterministic, from board.logs)

private struct T1Stats {
    let thisWeekTotal: Double
    let lastWeekTotal: Double
    let bestDayName: String?
    let thisWeekDays: Int         // binary: distinct days checked in this week
    let totalDays: Int            // ever, for "best day" threshold guard
    let recentSessionAvg: Double  // last-30-day avg per session (duration display)
    let lastValue: Double?        // most recent log
    let prevValue: Double?        // second most recent log

    var weekTrend: Double? {
        guard lastWeekTotal > 0 else { return nil }
        return (thisWeekTotal - lastWeekTotal) / lastWeekTotal
    }

    var hasThisWeekData: Bool { thisWeekTotal > 0 }

    static func compute(for board: HabitBoard) -> T1Stats {
        let cal = Calendar.current
        let now = Date()
        let logs = (board.logs ?? []).filter { $0.archivedAt == nil }
        let sorted = logs.sorted { $0.timestamp < $1.timestamp }

        let weekStart = cal.dateComponents(
            [.calendar, .yearForWeekOfYear, .weekOfYear], from: now
        ).date ?? now
        let lastWeekStart = cal.date(byAdding: .weekOfYear, value: -1, to: weekStart) ?? weekStart

        let thisWeekLogs = logs.filter { $0.timestamp >= weekStart && $0.timestamp <= now }
        let lastWeekLogs = logs.filter { $0.timestamp >= lastWeekStart && $0.timestamp < weekStart }

        let thisWeekDays = board.metric == .binary
            ? Set(thisWeekLogs.map { cal.startOfDay(for: $0.timestamp) }).count
            : 0

        var dayTotals: [Int: Double] = [:]
        for log in logs {
            dayTotals[cal.component(.weekday, from: log.timestamp), default: 0] += log.value
        }
        let bestDayName: String? = dayTotals.max(by: { $0.value < $1.value }).map { entry in
            let idx = (entry.key - 1 + cal.shortWeekdaySymbols.count) % cal.shortWeekdaySymbols.count
            return cal.shortWeekdaySymbols[idx]
        }

        let totalDays = Set(logs.map { cal.startOfDay(for: $0.timestamp) }).count

        let thirtyDaysAgo = cal.date(byAdding: .day, value: -30, to: now) ?? now
        let recentLogs = logs.filter { $0.timestamp >= thirtyDaysAgo }
        let recentSessionAvg = recentLogs.isEmpty ? 0
            : recentLogs.reduce(0.0) { $0 + $1.value } / Double(recentLogs.count)

        return T1Stats(
            thisWeekTotal: thisWeekLogs.reduce(0.0) { $0 + $1.value },
            lastWeekTotal: lastWeekLogs.reduce(0.0) { $0 + $1.value },
            bestDayName: bestDayName,
            thisWeekDays: thisWeekDays,
            totalDays: totalDays,
            recentSessionAvg: recentSessionAvg,
            lastValue: sorted.last?.value,
            prevValue: sorted.count >= 2 ? sorted[sorted.count - 2].value : nil
        )
    }
}

// MARK: - LifePatternCard

struct LifePatternCard: View {
    let board: HabitBoard
    @Environment(\.modelContext) private var modelContext
    @State private var t2Pattern: LifePattern? = nil
    @State private var t2Loading = true
    @State private var showMicroCheckIn = false

    private var habitType: HabitType { HabitType(board: board) }
    private var t1: T1Stats { T1Stats.compute(for: board) }
    private var accent: Color { ColorPalette[board.colorIndex] }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            Text("Life")
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textSecondary)
                .textCase(.uppercase)

            t1Section

            if t2Loading {
                Divider()
                Text("Checking for patterns\u{2026}")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            } else if let pattern = t2Pattern {
                Divider()
                t2PatternView(pattern)
            } else {
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    Text(t2EmptyMessage)
                        .font(.caption)
                        .foregroundStyle(DS.Color.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)

                    if board.dimension != nil {
                        Button(action: { showMicroCheckIn = true }) {
                            Text("Log your state \u{2192}")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(accent)
                                .padding(.horizontal, DS.Space.sm)
                                .padding(.vertical, 5)
                                .background(accent.opacity(0.1), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border, lineWidth: 1))
        .task { await loadT2() }
        .sheet(isPresented: $showMicroCheckIn) {
            MicroCheckInView(board: board)
                .presentationDetents([.height(380)])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - T1 section

    @ViewBuilder
    private var t1Section: some View {
        switch habitType {
        case .binaryStreak: binaryT1
        case .duration:     durationT1
        case .weight:       weightT1
        default:            volumeT1
        }
    }

    private var binaryT1: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            HStack(alignment: .firstTextBaseline, spacing: DS.Space.xs) {
                Text("\(board.currentStreak)")
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(board.currentStreak > 0 ? accent : DS.Color.textTertiary)
                    .monospacedDigit()
                Text(board.currentStreak == 1 ? "day streak" : "days in a row")
                    .font(DS.Text.body)
                    .foregroundStyle(DS.Color.textSecondary)
            }
            if t1.thisWeekDays > 0 {
                Text("\(t1.thisWeekDays) of 7 days this week")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
            }
            if let best = t1.bestDayName, t1.totalDays >= 7 {
                Text("Best day: \(best)")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
    }

    private var volumeT1: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            let unit = board.unitLabel.map { " \($0)" } ?? ""
            let fmt = t1.thisWeekTotal.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f"

            HStack(alignment: .firstTextBaseline, spacing: DS.Space.xs) {
                Text(String(format: fmt, t1.thisWeekTotal))
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(t1.hasThisWeekData ? accent : DS.Color.textTertiary)
                    .monospacedDigit()
                Text("this week\(unit)")
                    .font(DS.Text.body)
                    .foregroundStyle(DS.Color.textSecondary)
                if let trend = t1.weekTrend {
                    trendBadge(trend)
                }
            }
            if !t1.hasThisWeekData {
                Text("No logs this week yet")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }
            if let best = t1.bestDayName, t1.totalDays >= 7 {
                Text("Peak day: \(best)")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
    }

    private var durationT1: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            let unit = board.unitLabel.map { " \($0)" } ?? ""
            let fmt = t1.thisWeekTotal.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f"
            let avgFmt = t1.recentSessionAvg.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f"

            HStack(alignment: .firstTextBaseline, spacing: DS.Space.xs) {
                Text(String(format: fmt, t1.thisWeekTotal))
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(t1.hasThisWeekData ? accent : DS.Color.textTertiary)
                    .monospacedDigit()
                Text("this week\(unit)")
                    .font(DS.Text.body)
                    .foregroundStyle(DS.Color.textSecondary)
                if let trend = t1.weekTrend {
                    trendBadge(trend)
                }
            }
            if t1.recentSessionAvg > 0 {
                Text("Avg \(String(format: avgFmt, t1.recentSessionAvg))\(unit) per session")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }
            if let best = t1.bestDayName, t1.totalDays >= 7 {
                Text("Most consistent: \(best)")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
    }

    @ViewBuilder
    private var weightT1: some View {
        let unit = board.unitLabel.map { " \($0)" } ?? ""
        if let last = t1.lastValue {
            let fmt = last.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f"
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                HStack(alignment: .firstTextBaseline, spacing: DS.Space.xs) {
                    Text(String(format: fmt, last))
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(accent)
                        .monospacedDigit()
                    Text("last logged\(unit)")
                        .font(DS.Text.body)
                        .foregroundStyle(DS.Color.textSecondary)
                }
                if let best = t1.bestDayName, t1.totalDays >= 7 {
                    Text("Most logged: \(best)")
                        .font(.caption)
                        .foregroundStyle(DS.Color.textTertiary)
                }
            }
        } else {
            Text("No logs yet")
                .font(DS.Text.body)
                .foregroundStyle(DS.Color.textTertiary)
        }
    }

    // MARK: - T2 pattern view

    private func t2PatternView(_ pattern: LifePattern) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text(pattern.observation)
                .font(DS.Text.body)
                .foregroundStyle(DS.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: DS.Space.sm) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(DS.Color.border)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(accent.opacity(0.7))
                            .frame(width: geo.size.width * CGFloat(pattern.confidence))
                    }
                }
                .frame(height: 4)

                Text("\(Int(pattern.confidence * 100))%")
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
                    .monospacedDigit()
            }

            Text("\(pattern.sampleCount) days of data")
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
        }
    }

    private var t2EmptyMessage: String {
        switch habitType {
        case .binaryStreak:
            return "Patterns between this habit and your energy or mood will appear after a few weeks."
        case .distance:
            return "Keep logging \u{2014} LOCA will find connections to your energy over time."
        case .duration:
            let dim = board.dimension ?? ""
            return dim == "stress" || board.name.localizedCaseInsensitiveContains("meditat")
                ? "Correlations with your stress level will appear as data builds."
                : "Connections to next-day energy will emerge as you keep logging."
        case .count, .weight, .generic:
            return "Patterns will appear after a few weeks of consistent logging."
        }
    }

    // MARK: - Helpers

    private func trendBadge(_ trend: Double) -> some View {
        let up = trend >= 0
        return Text("\(up ? "↑" : "↓")\(Int(abs(trend * 100)))%")
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(up ? accent : DS.Color.textSecondary)
    }

    // MARK: - Load T2

    private func loadT2() async {
        let engine = PatternDetectionEngine.shared
        let all = (try? engine.detectPatterns(modelContext: modelContext)) ?? []
        let name = board.name.lowercased()
        t2Pattern = all.first {
            $0.layer == .habitState &&
            $0.observation.localizedCaseInsensitiveContains(name)
        }
        t2Loading = false
    }
}
