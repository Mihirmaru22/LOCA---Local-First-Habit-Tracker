import SwiftUI
import SwiftData
import Charts

// MARK: - AnalyseDesignVariant

enum AnalyseDesignVariant: String, CaseIterable, Identifiable {
    case bentoHorizon = "Executive Bento Horizon"
    case splitKpi     = "Split KPI Dashboard"
    case dataMatrix   = "Minimalist Data Matrix"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .bentoHorizon: return "square.grid.2x2"
        case .splitKpi:     return "rectangle.split.2x1"
        case .dataMatrix:   return "tablecells"
        }
    }
}

// MARK: - MacJournalAnalyse (3 Modern Analytics Layouts)

/// Analytics & Monthly Trends view for Journal with 3 selectable design layouts.
struct MacJournalAnalyse: View {

    var selectedDate: Date = .now

    @Query(sort: [SortDescriptor(\SleepEntry.date)])
    private var allSleepEntries: [SleepEntry]

    @Query(sort: [SortDescriptor(\JournalNote.date, order: .reverse)])
    private var allNotes: [JournalNote]

    @Query(filter: #Predicate<HabitBoard> { $0.habitKindRaw == 1 },
           sort: \HabitBoard.createdAt)
    private var habitCandidates: [HabitBoard]
    private var dailyHabits: [HabitBoard] { habitCandidates.filter { $0.archivedAt == nil } }

    @AppStorage("mac_journal_analyse_layout_v2") private var selectedVariant: AnalyseDesignVariant = .bentoHorizon

    init(selectedDate: Date = .now) {
        self.selectedDate = selectedDate
    }

    // MARK: Month boundaries

    private var monthStart: Date {
        let comp = Calendar.current.dateComponents([.year, .month], from: selectedDate)
        let d = Calendar.current.date(from: comp) ?? selectedDate
        return Calendar.current.startOfDay(for: d)
    }

    private var monthEnd: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: monthStart) ?? selectedDate
    }

    private var monthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: selectedDate).uppercased()
    }

    // MARK: Derived values

    private var monthlySleep: [SleepEntry] {
        allSleepEntries.filter {
            !$0.isArchived && $0.date >= monthStart && $0.date < monthEnd
        }
    }

    private var monthlyNotes: [JournalNote] {
        allNotes.filter {
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
        monthlyNotes.filter { $0.noteKind == .moment }.count
    }

    private var winCount: Int {
        monthlyNotes.filter { $0.noteKind == .win }.count
    }

    private var daysJournaledCount: Int {
        let cal = Calendar.current
        var loggedDays: Set<Date> = []
        for note in monthlyNotes {
            loggedDays.insert(cal.startOfDay(for: note.date))
        }
        for sleep in monthlySleep {
            loggedDays.insert(cal.startOfDay(for: sleep.date))
        }
        for habit in dailyHabits {
            for log in habit.activeLogs {
                if log.timestamp >= monthStart && log.timestamp < monthEnd {
                    loggedDays.insert(cal.startOfDay(for: log.timestamp))
                }
            }
        }
        return loggedDays.count
    }

    private var totalPossibleHabitCompletions: Int {
        let daysInMonth = Calendar.current.dateComponents([.day], from: monthStart, to: min(monthEnd, Date())).day ?? 1
        return max(1, daysInMonth * dailyHabits.count)
    }

    private var totalActualHabitCompletions: Int {
        let cal = Calendar.current
        var count = 0
        for habit in dailyHabits {
            let target = habit.effectiveTarget
            var dailyTotals: [Date: Double] = [:]
            for log in habit.activeLogs {
                guard log.timestamp >= monthStart && log.timestamp < monthEnd else { continue }
                dailyTotals[cal.startOfDay(for: log.timestamp), default: 0] += log.value
            }
            count += dailyTotals.filter { $0.value >= target }.count
        }
        return count
    }

    private var habitSuccessRate: Double {
        guard !dailyHabits.isEmpty else { return 0 }
        return min(1.0, Double(totalActualHabitCompletions) / Double(totalPossibleHabitCompletions))
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {

            // Top Header
            HStack(spacing: DS.Space.sm) {
                Text("\(monthLabel)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(0.8)

                Spacer()
            }
            .padding(.horizontal, DS.Space.xl)
            .padding(.vertical, DS.Space.sm)

            Divider()

            // Main Scrollable Content
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xl) {
                    switch selectedVariant {
                    case .bentoHorizon:
                        analyse1BentoHorizon
                    case .splitKpi:
                        analyse2SplitKpi
                    case .dataMatrix:
                        analyse3DataMatrix
                    }

                    Spacer(minLength: DS.Space.xxxl)
                }
                .padding(.horizontal, DS.Space.xl)
                .padding(.vertical, DS.Space.lg)
            }
        }
    }

    // MARK: - Design 1: Executive Bento Horizon (Analyse 1)

    private var analyse1BentoHorizon: some View {
        VStack(alignment: .leading, spacing: DS.Space.xl) {
            // 4 Monochrome Stat Cards (Clean High-Contrast)
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: DS.Space.md),
                    GridItem(.flexible(), spacing: DS.Space.md)
                ],
                spacing: DS.Space.md
            ) {
                ExecutiveStatCard(
                    label: "DAYS JOURNALED",
                    value: "\(daysJournaledCount)",
                    unit: daysJournaledCount == 1 ? "day" : "days",
                    icon: "calendar.badge.checkmark"
                )
                ExecutiveStatCard(
                    label: "AVG SLEEP",
                    value: avgSleep > 0 ? String(format: "%.1f", avgSleep) : "—",
                    unit: avgSleep > 0 ? "hrs / night" : "no data",
                    icon: "moon.fill"
                )
                ExecutiveStatCard(
                    label: "MOMENTS & WINS",
                    value: "\(momentCount + winCount)",
                    unit: "\(momentCount) moments · \(winCount) wins",
                    icon: "sparkles"
                )
                ExecutiveStatCard(
                    label: "BEST HABIT STREAK",
                    value: bestStreak > 0 ? "\(bestStreak)" : "—",
                    unit: bestStreak == 1 ? "day streak" : "days streak",
                    icon: "flame.fill"
                )
            }

            // Sleep Trend Chart (Slate Gradient Line & Area)
            VStack(alignment: .leading, spacing: DS.Space.sm) {
                sectionLabel("SLEEP TREND · \(monthLabel)")
                sleepChartClean
            }

            // Apple Neural Engine Semantic Clarity & Habit Correlation Module
            VStack(alignment: .leading, spacing: DS.Space.sm) {
                sectionLabel("APPLE NEURAL ENGINE · SEMANTIC COGNITIVE INSIGHTS")
                neuralInsightsCard
            }

            // Daily Habits Month Heatmap
            if !dailyHabits.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    sectionLabel("DAILY HABITS · \(monthLabel)")
                    DailyHabitMonthGrid(
                        habits:     dailyHabits,
                        monthStart: monthStart,
                        monthEnd:   monthEnd
                    )
                }
            }

            // Month Highlights
            VStack(alignment: .leading, spacing: DS.Space.sm) {
                sectionLabel("MONTH HIGHLIGHTS · \(monthLabel)")
                highlightsSectionClean
            }
        }
    }

    // MARK: - Design 2: Split KPI Dashboard (Analyse 2)

    private var analyse2SplitKpi: some View {
        VStack(alignment: .leading, spacing: DS.Space.xl) {
            // Top Split: Sleep Health Gauge + Habit Discipline Matrix
            HStack(spacing: DS.Space.md) {

                // Left: Sleep Recovery Module
                VStack(alignment: .leading, spacing: DS.Space.md) {
                    HStack {
                        Image(systemName: "moon.stars.fill")
                            .font(.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                        Text("SLEEP PERFORMANCE")
                            .font(DS.Text.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(DS.Color.textSecondary)
                            .tracking(0.5)
                        Spacer()
                    }

                    HStack(spacing: DS.Space.lg) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(avgSleep > 0 ? String(format: "%.1f", avgSleep) : "—")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(DS.Color.textPrimary)
                            Text("hours / night avg")
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textTertiary)
                        }

                        Spacer()

                        // Circular Progress Benchmark (8h target)
                        let pct = min(1.0, avgSleep / 8.0)
                        ZStack {
                            Circle()
                                .stroke(DS.Color.surfaceRecessed, lineWidth: 6)
                                .frame(width: 54, height: 54)
                            Circle()
                                .trim(from: 0, to: CGFloat(pct))
                                .stroke(Color(red: 0.28, green: 0.32, blue: 0.42), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .frame(width: 54, height: 54)
                                .rotationEffect(.degrees(-90))
                            Text("\(Int(pct * 100))%")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(DS.Color.textPrimary)
                        }
                    }

                    Divider()

                    // Min & Max sleep
                    let hoursList = monthlySleep.map(\.sleepHours)
                    let minH = hoursList.min() ?? 0
                    let maxH = hoursList.max() ?? 0
                    HStack {
                        Text("Min: \(String(format: "%.1f", minH))h")
                            .font(DS.Text.footnote)
                            .foregroundStyle(DS.Color.textTertiary)
                        Spacer()
                        Text("Max: \(String(format: "%.1f", maxH))h")
                            .font(DS.Text.footnote)
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                }
                .padding(DS.Space.lg)
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.card)
                        .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
                )

                // Right: Habit Discipline Module
                VStack(alignment: .leading, spacing: DS.Space.md) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                        Text("HABIT CONSISTENCY")
                            .font(DS.Text.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(DS.Color.textSecondary)
                            .tracking(0.5)
                        Spacer()
                    }

                    HStack(spacing: DS.Space.lg) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Int(habitSuccessRate * 100))%")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(DS.Color.textPrimary)
                            Text("overall success rate")
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textTertiary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.caption2)
                                    .foregroundStyle(DS.Color.textSecondary)
                                Text("\(bestStreak)d streak")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(DS.Color.textPrimary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(DS.Color.surfaceRecessed, in: Capsule())

                            Text("\(totalActualHabitCompletions) total logs")
                                .font(DS.Text.footnote)
                                .foregroundStyle(DS.Color.textTertiary)
                        }
                    }

                    Divider()

                    // Linear progress bar
                    GeometryReader { p in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(DS.Color.surfaceRecessed)
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(red: 0.18, green: 0.72, blue: 0.42))
                                .frame(width: max(0, p.size.width * CGFloat(habitSuccessRate)), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(DS.Space.lg)
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.card)
                        .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
                )
            }

            // Sleep Chart
            VStack(alignment: .leading, spacing: DS.Space.sm) {
                sectionLabel("SLEEP LOG · \(monthLabel)")
                sleepChartClean
            }

            // Habits Grid
            if !dailyHabits.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    sectionLabel("DAILY HABITS · \(monthLabel)")
                    DailyHabitMonthGrid(
                        habits:     dailyHabits,
                        monthStart: monthStart,
                        monthEnd:   monthEnd
                    )
                }
            }
        }
    }

    // MARK: - Design 3: Minimalist Data Matrix (Analyse 3)

    private var analyse3DataMatrix: some View {
        VStack(alignment: .leading, spacing: DS.Space.xl) {

            // Top Linear Summary Ribbon
            HStack(spacing: DS.Space.xl) {
                summaryMetricItem(title: "JOURNALED", value: "\(daysJournaledCount)d")
                Divider().frame(height: 32)
                summaryMetricItem(title: "AVG SLEEP", value: avgSleep > 0 ? String(format: "%.1fh", avgSleep) : "—")
                Divider().frame(height: 32)
                summaryMetricItem(title: "HABIT RATE", value: "\(Int(habitSuccessRate * 100))%")
                Divider().frame(height: 32)
                summaryMetricItem(title: "BEST STREAK", value: "\(bestStreak)d")
                Divider().frame(height: 32)
                summaryMetricItem(title: "WINS & MOMENTS", value: "\(momentCount + winCount)")
            }
            .padding(.horizontal, DS.Space.xl)
            .padding(.vertical, DS.Space.md)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
            )

            // Executive Habit Performance Table
            VStack(alignment: .leading, spacing: DS.Space.sm) {
                sectionLabel("HABIT PERFORMANCE MATRIX · \(monthLabel)")

                VStack(spacing: 0) {
                    // Table Header
                    HStack {
                        Text("HABIT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                            .frame(width: 140, alignment: .leading)

                        Text("LOGS")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                            .frame(width: 60, alignment: .trailing)

                        Text("STREAK")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                            .frame(width: 70, alignment: .trailing)

                        Text("CONSISTENCY")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, DS.Space.md)
                    }
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.vertical, DS.Space.sm)
                    .background(DS.Color.surfaceRecessed)

                    Divider()

                    if dailyHabits.isEmpty {
                        Text("No active daily habits")
                            .font(DS.Text.footnote)
                            .foregroundStyle(DS.Color.textTertiary)
                            .padding(DS.Space.lg)
                    } else {
                        ForEach(dailyHabits) { habit in
                            let count = habitMonthlyLogsCount(habit)
                            let daysInMonth = Calendar.current.dateComponents([.day], from: monthStart, to: min(monthEnd, Date())).day ?? 1
                            let rate = min(1.0, Double(count) / Double(max(1, daysInMonth)))

                            HStack {
                                Text(habit.name)
                                    .font(DS.Text.body)
                                    .foregroundStyle(DS.Color.textPrimary)
                                    .frame(width: 140, alignment: .leading)
                                    .lineLimit(1)

                                Text("\(count)d")
                                    .font(.system(size: 12, weight: .semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(DS.Color.textSecondary)
                                    .frame(width: 60, alignment: .trailing)

                                Text("\(habit.currentStreak)d")
                                    .font(.system(size: 12, weight: .bold))
                                    .monospacedDigit()
                                    .foregroundStyle(habit.currentStreak > 0 ? DS.Color.textPrimary : DS.Color.textTertiary)
                                    .frame(width: 70, alignment: .trailing)

                                HStack(spacing: 8) {
                                    GeometryReader { p in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(DS.Color.surfaceRecessed)
                                                .frame(height: 6)
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(Color(red: 0.18, green: 0.72, blue: 0.42))
                                                .frame(width: max(0, p.size.width * CGFloat(rate)), height: 6)
                                        }
                                    }
                                    .frame(height: 6)

                                    Text("\(Int(rate * 100))%")
                                        .font(.system(size: 11, weight: .bold))
                                        .monospacedDigit()
                                        .foregroundStyle(DS.Color.textSecondary)
                                        .frame(width: 36, alignment: .trailing)
                                }
                                .padding(.leading, DS.Space.md)
                            }
                            .padding(.horizontal, DS.Space.lg)
                            .padding(.vertical, DS.Space.md)

                            if habit.id != dailyHabits.last?.id {
                                Divider().padding(.leading, DS.Space.lg)
                            }
                        }
                    }
                }
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.card)
                        .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
                )
            }

            // Sleep Trend Chart
            VStack(alignment: .leading, spacing: DS.Space.sm) {
                sectionLabel("SLEEP CONTINUITY · \(monthLabel)")
                sleepChartClean
            }
        }
    }

    private func summaryMetricItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(DS.Color.textTertiary)
                .tracking(0.6)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(DS.Color.textPrimary)
                .monospacedDigit()
        }
    }

    private func habitMonthlyLogsCount(_ habit: HabitBoard) -> Int {
        let cal = Calendar.current
        let target = habit.effectiveTarget
        var dailyTotals: [Date: Double] = [:]
        for log in habit.activeLogs {
            guard log.timestamp >= monthStart && log.timestamp < monthEnd else { continue }
            dailyTotals[cal.startOfDay(for: log.timestamp), default: 0] += log.value
        }
        return dailyTotals.filter { $0.value >= target }.count
    }

    // MARK: - Sleep Chart (Clean Monochrome Productivity Style)

    @ViewBuilder
    private var sleepChartClean: some View {
        if monthlySleep.isEmpty {
            HStack(spacing: DS.Space.sm) {
                Image(systemName: "moon.stars")
                    .foregroundStyle(DS.Color.textTertiary)
                Text("No sleep data logged for \(monthLabel).")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DS.Space.lg)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
            )
        } else {
            VStack(alignment: .leading, spacing: DS.Space.md) {
                Chart {
                    // 8h Benchmark Line
                    RuleMark(y: .value("Target", 8))
                        .foregroundStyle(DS.Color.textTertiary.opacity(0.35))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("8h benchmark")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(DS.Color.textTertiary)
                                .padding(.trailing, 4)
                        }

                    // Sleep Curve & Smooth Area
                    ForEach(monthlySleep, id: \.id) { entry in
                        AreaMark(
                            x: .value("Day", entry.date, unit: .day),
                            y: .value("Hours", entry.sleepHours)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.28, green: 0.32, blue: 0.42).opacity(0.35),
                                    Color(red: 0.28, green: 0.32, blue: 0.42).opacity(0.02)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Day", entry.date, unit: .day),
                            y: .value("Hours", entry.sleepHours)
                        )
                        .foregroundStyle(Color(red: 0.40, green: 0.46, blue: 0.58))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Day", entry.date, unit: .day),
                            y: .value("Hours", entry.sleepHours)
                        )
                        .foregroundStyle(Color.white)
                        .symbolSize(24)
                    }
                }
                .chartXScale(domain: monthStart...monthEnd)
                .chartYScale(domain: 0...12)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 5)) { _ in
                        AxisValueLabel(format: .dateTime.day())
                            .font(.system(size: 10))
                            .foregroundStyle(DS.Color.textTertiary)
                        AxisGridLine().foregroundStyle(DS.Color.border.opacity(0.5))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [0, 3, 6, 8, 10, 12]) { value in
                        AxisValueLabel {
                            if let h = value.as(Double.self) {
                                Text("\(Int(h))h")
                                    .font(.system(size: 10))
                                    .foregroundStyle(DS.Color.textTertiary)
                            }
                        }
                        AxisGridLine().foregroundStyle(DS.Color.border.opacity(0.5))
                    }
                }
                .frame(height: 160)
            }
            .padding(DS.Space.lg)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
            )
        }
    }

    // MARK: - Highlights Section (Clean Monochrome)

    @ViewBuilder
    private var highlightsSectionClean: some View {
        if monthlyNotes.isEmpty {
            HStack(spacing: DS.Space.sm) {
                Image(systemName: "sparkles")
                    .foregroundStyle(DS.Color.textTertiary)
                Text("No moments or wins logged for \(monthLabel).")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DS.Space.lg)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
            )
        } else {
            VStack(spacing: 0) {
                ForEach(Array(monthlyNotes.prefix(10).enumerated()), id: \.element.id) { idx, note in
                    if idx > 0 {
                        Divider().padding(.leading, 36)
                    }
                    HStack(spacing: DS.Space.md) {
                        Image(systemName: note.noteKind == .win ? "trophy.fill" : "sparkles")
                            .font(.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                            .frame(width: 16)

                        Text(note.text)
                            .font(DS.Text.body)
                            .foregroundStyle(DS.Color.textPrimary)

                        Spacer()

                        Text(note.date.formatted(.dateTime.month(.abbreviated).day()))
                            .font(DS.Text.footnote)
                            .foregroundStyle(DS.Color.textTertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DS.Color.surfaceRecessed, in: Capsule())
                    }
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.vertical, DS.Space.md)
                }
            }
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
            )
        }
    }

    // MARK: - Apple Neural Engine Insights Card

    private var neuralInsightsCard: some View {
        let report = LocaNeuralEngine.analyzeJournalNotes(monthlyNotes, habitCompletionRate: habitSuccessRate)

        return VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Color.textSecondary)
                    Text("SEMANTIC COGNITIVE CLARITY & EXECUTION CORRELATION")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                        .tracking(0.6)
                }

                Spacer()

                Text("Apple Silicon Neural Engine · 100% On-Device")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(DS.Color.surfaceRecessed, in: Capsule())
            }

            HStack(alignment: .top, spacing: DS.Space.xl) {
                // Left: Sentiment Metric & Tone
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: report.toneIcon)
                            .font(.system(size: 14))
                            .foregroundStyle(report.toneColor)

                        Text(report.toneLabel)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(DS.Color.textPrimary)
                    }

                    Text("Clarity Index: \(report.averageSentiment >= 0 ? "+" : "")\(String(format: "%.2f", report.averageSentiment)) (range: -1.0 to +1.0)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(DS.Color.textSecondary)

                    // Sentiment Indicator Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(DS.Color.surfaceRecessed)
                                .frame(height: 6)

                            let normalized = CGFloat((report.averageSentiment + 1.0) / 2.0)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(report.toneColor)
                                .frame(width: max(8, geo.size.width * normalized), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                .frame(maxWidth: 300)

                Divider()

                // Right: Extracted Themes & Execution Correlation
                VStack(alignment: .leading, spacing: 6) {
                    if !report.topKeywords.isEmpty {
                        HStack(spacing: 4) {
                            Text("Key Themes:")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(DS.Color.textTertiary)

                            ForEach(report.topKeywords, id: \.self) { kw in
                                Text(kw)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(DS.Color.textSecondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }

                    Text(report.correlationInsight)
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Color.textSecondary)
                        .lineSpacing(2)
                }
            }
        }
        .padding(DS.Space.lg)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(DS.Text.caption)
            .fontWeight(.semibold)
            .foregroundStyle(DS.Color.textTertiary)
            .tracking(0.8)
    }
}

// MARK: - ExecutiveStatCard (High-Contrast Monochrome)

private struct ExecutiveStatCard: View {

    let label: String
    let value: String
    let unit:  String
    let icon:  String

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            // Label & Icon
            HStack(spacing: DS.Space.xs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                Text(label)
                    .font(DS.Text.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(DS.Color.textSecondary)
                    .tracking(0.5)
                    .lineLimit(1)
            }

            // Value & Unit
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(value)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(DS.Color.textPrimary)
                    .contentTransition(.numericText())

                Text(unit)
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textTertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Space.lg)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - DailyHabitMonthGrid

/// Month-scoped heatmap for daily habits only.
private struct DailyHabitMonthGrid: View {

    let habits:     [HabitBoard]
    let monthStart: Date
    let monthEnd:   Date

    private let cellSize:  CGFloat = 12
    private let cellGap:   CGFloat = 3
    private let nameWidth: CGFloat = 90

    private static let emeraldCheck = Color(red: 0.18, green: 0.72, blue: 0.42)

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
            VStack(alignment: .leading, spacing: 4) {
                columnHeaders
                ForEach(habits, id: \.id) { habit in
                    habitRow(habit)
                }
            }
            .padding(.vertical, DS.Space.xs)
        }
        .padding(DS.Space.lg)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
        )
    }

    private var columnHeaders: some View {
        HStack(spacing: 0) {
            Text("").frame(width: nameWidth)
            HStack(spacing: cellGap) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { idx, day in
                    let dom = Calendar.current.component(.day, from: day)
                    Text(idx % 5 == 0 || idx == 0 || idx == monthDays.count - 1 ? "\(dom)" : "")
                        .font(.system(size: 8, weight: .medium))
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
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .foregroundStyle(DS.Color.textSecondary)
                .frame(width: nameWidth, alignment: .trailing)
                .padding(.trailing, DS.Space.sm)

            HStack(spacing: cellGap) {
                ForEach(monthDays, id: \.self) { day in
                    let done   = completed.contains(day)
                    let future = day > todayStart
                    let today  = Calendar.current.isDateInToday(day)
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(done
                              ? Self.emeraldCheck
                              : future
                                  ? DS.Color.surfaceRecessed.opacity(0.4)
                                  : DS.Color.surfaceRecessed)
                        .frame(width: cellSize, height: cellSize)
                        .overlay(
                            today
                                ? RoundedRectangle(cornerRadius: 2.5)
                                    .strokeBorder(DS.Color.border.opacity(0.8), lineWidth: 1)
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


