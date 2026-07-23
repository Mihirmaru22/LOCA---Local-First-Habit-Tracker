//
//  HabitDetailView.swift
//  LOCA
//
//  Phase 14.8 — Pixel-perfect match to reference.
//

import SwiftUI
import SwiftData

// MARK: - HabitDetail Tab Enum

enum HabitDetailTab: Hashable {
    case overview
    case checkIns
    case journal
    case analytics
}

// MARK: - HabitDetailView

struct HabitDetailView: View {
    let board: HabitBoard
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingEditSheet    = false
    @State private var showingCheckIn      = false
    @State private var selectedTab: HabitDetailTab = .overview
    @State private var showGoalInference: Bool?  // nil = not yet checked, true/false = decision made
    @State private var inferredGoal: Double = 0
    @State private var showTimingSuggestion: Bool? = nil
    @State private var suggestedHour: Int = 0
    @State private var suggestedMinute: Int = 0
    @State private var showReflectionPrompt: Bool? = nil
    @State private var showGoalTuning: Bool? = nil
    @State private var suggestedGoalValue: Double = 0
    @State private var goalTuningReason: String = ""
    @State private var toastMessage: String = ""
    @State private var showToast = false

    var body: some View {
        ZStack(alignment: .bottom) {
            DS.Color.background.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .checkIns:
                    HabitCheckInsView(board: board)
                        .padding(.bottom, 80) // clear toolbar
                case .journal:
                    HabitJournalView(board: board)
                        .padding(.bottom, 80)
                case .analytics:
                    HabitAnalyticsView(board: board)
                        .padding(.bottom, 80)
                case .overview:
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            if showGoalInference == true && board.metric == .quantitative && board.targetValue == nil {
                                GoalInferenceCard(
                                    board: board,
                                    inferredGoal: inferredGoal,
                                    onAccept: { acceptGoalInference($0) },
                                    onDismiss: { showGoalInference = false }
                                )
                                .padding(.horizontal, 18)
                            }

                            if showTimingSuggestion == true && board.preferredReminderTime == nil {
                                TimingSuggestionCard(
                                    board: board,
                                    suggestedHour: suggestedHour,
                                    suggestedMinute: suggestedMinute,
                                    onAccept: { hour, minute in acceptTimingSuggestion(hour, minute) },
                                    onDismiss: { showTimingSuggestion = false }
                                )
                                .padding(.horizontal, 18)
                            }

                            if showReflectionPrompt == true {
                                ReflectionPromptCard(
                                    board: board,
                                    onResponse: { sentiment in respondToReflection(sentiment) },
                                    onDismiss: { showReflectionPrompt = false }
                                )
                                .padding(.horizontal, 18)
                            }

                            if showGoalTuning == true && board.metric == .quantitative && board.targetValue != nil {
                                GoalTuningCard(
                                    board: board,
                                    suggestedGoal: suggestedGoalValue,
                                    currentGoal: board.targetValue ?? 1.0,
                                    reason: goalTuningReason,
                                    onAccept: { newGoal in acceptGoalTuning(newGoal) },
                                    onDismiss: { showGoalTuning = false }
                                )
                                .padding(.horizontal, 18)
                            }

                            // Weekly insight summary (Phase 3.3)
                            if let (daysCompleted, consistency) = computeWeeklyStats() {
                                WeeklyInsightCard(
                                    board: board,
                                    daysCompletedThisWeek: daysCompleted,
                                    weeklyConsistency: consistency,
                                    currentStreak: board.currentStreak
                                )
                                .padding(.horizontal, 18)
                            }

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
            .transition(.opacity)
            .animation(DS.Motion.settle(reduceMotion: reduceMotion), value: selectedTab)

            // Toolbar
            HStack(spacing: 0) {
                HabitDetailTabBar(selectedTab: $selectedTab, reduceMotion: reduceMotion)

                Spacer()

                // + button → add check-in
                Button(action: { showingCheckIn = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                        .frame(width: 56, height: 56)
                        .background(DS.Color.surface, in: Circle())
                }
                .buttonStyle(.pressable)
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
                        .foregroundStyle(DS.Color.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(DS.Color.surface, in: Circle())
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            SimpleHabitEditView(board: board)
        }
        .onChange(of: board.archivedAt) { _, newValue in
            if newValue != nil { dismiss() }
        }
        .sheet(isPresented: $showingCheckIn) {
            AddCheckInSheetView(board: board)
                .presentationDetents([.medium, .large])
        }
        .overlay(alignment: .top) {
            if showToast {
                VStack(spacing: DS.Space.sm) {
                    HStack(spacing: DS.Space.md) {
                        Image(systemName: "exclamation.circle.fill")
                            .font(DS.Text.body)
                            .foregroundStyle(ColorPalette[9])
                        Text(toastMessage)
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textPrimary)
                        Spacer()
                    }
                    .padding(DS.Space.md)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                    .padding(DS.Space.lg)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(DS.Motion.settle(reduceMotion: reduceMotion), value: showToast)
            }
        }
        .task {
            checkForGoalInference()
            checkForTimingSuggestion()
            checkForReflectionPrompt()
            checkForGoalTuning()
        }
    }

    private func checkForGoalInference() {
        guard showGoalInference == nil else { return }
        guard board.metric == .quantitative && board.targetValue == nil else {
            showGoalInference = false
            return
        }

        let logs = board.logs ?? []
        let snapshots = logs.map { LogSnapshot(from: $0) }

        guard let inferredValue = GoalInference.inferFromFirstWeek(logs: snapshots) else {
            showGoalInference = false
            return
        }

        inferredGoal = inferredValue
        showGoalInference = true
    }

    private func acceptGoalInference(_ value: Double) {
        board.targetValue = value
        do {
            try modelContext.save()
            showGoalInference = false
        } catch {
            showErrorToast("Couldn't save goal. Try again.")
            Haptics.notify(.error)
        }
    }

    private func checkForTimingSuggestion() {
        guard showTimingSuggestion == nil else { return }
        guard board.preferredReminderTime == nil else {
            showTimingSuggestion = false
            return
        }

        let logs = board.logs ?? []
        let snapshots = logs.map { LogSnapshot(from: $0) }

        guard let (hour, minute) = TimingInference.inferLoggingTime(logs: snapshots) else {
            showTimingSuggestion = false
            return
        }

        suggestedHour = hour
        suggestedMinute = minute
        showTimingSuggestion = true
    }

    private func acceptTimingSuggestion(_ hour: Int, _ minute: Int) {
        let timeString = String(format: "%02d:%02d", hour, minute)
        board.preferredReminderTime = timeString
        do {
            try modelContext.save()
            // Schedule the reminder (Phase 3.1). Capture a Sendable snapshot on
            // the MainActor before crossing into the ReminderScheduler actor.
            let request = ReminderRequest(id: board.id, name: board.name, time: timeString)
            Task {
                await ReminderScheduler.shared.scheduleReminder(request)
            }
            showTimingSuggestion = false
        } catch {
            showErrorToast("Couldn't save reminder time. Try again.")
            Haptics.notify(.error)
        }
    }

    private func checkForReflectionPrompt() {
        guard showReflectionPrompt == nil else { return }

        let logs = board.logs ?? []
        let snapshots = logs.map { LogSnapshot(from: $0) }

        guard ReflectionPrompt.shouldOffer(board: board, logs: snapshots) else {
            showReflectionPrompt = false
            return
        }

        showReflectionPrompt = true
    }

    private func respondToReflection(_ sentiment: String) {
        board.lastReflectionPromptTime = .now
        do {
            try modelContext.save()
            showReflectionPrompt = false
        } catch {
            showErrorToast("Couldn't save reflection. Try again.")
            Haptics.notify(.error)
        }
    }

    private func checkForGoalTuning() {
        guard showGoalTuning == nil else { return }
        guard board.metric == .quantitative && board.targetValue != nil else {
            showGoalTuning = false
            return
        }

        let logs = board.logs ?? []
        let snapshots = logs.map { LogSnapshot(from: $0) }

        // For Session 3.2, use empty reflections array (rely on consistency signals only).
        // Future enhancement: store and pass reflection history.
        guard let suggestedGoal = GoalTuning.suggestAdjustment(
            board: board,
            logs: snapshots,
            recentReflections: []
        ) else {
            showGoalTuning = false
            return
        }

        suggestedGoalValue = suggestedGoal
        let changePercent = Int(((suggestedGoal - board.targetValue!) / board.targetValue!) * 100)
        if changePercent > 0 {
            goalTuningReason = "You're consistently hitting your goal. Let's try a bit harder."
        } else {
            goalTuningReason = "This goal feels challenging. Let's ease up a bit."
        }
        showGoalTuning = true
    }

    private func acceptGoalTuning(_ newGoal: Double) {
        board.targetValue = newGoal
        do {
            try modelContext.save()
            showGoalTuning = false
        } catch {
            showErrorToast("Couldn't save new goal. Try again.")
            Haptics.notify(.error)
        }
    }

    private func showErrorToast(_ message: String) {
        toastMessage = message
        withAnimation(DS.Motion.settle(reduceMotion: reduceMotion)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(DS.Motion.settle(reduceMotion: reduceMotion)) {
                showToast = false
            }
        }
    }

    private func computeWeeklyStats() -> (daysCompleted: Int, consistency: Double)? {
        let logs = board.logs ?? []
        guard !logs.isEmpty else { return nil }

        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: .now) ?? .now
        let thisWeekLogs = logs.filter { $0.timestamp >= sevenDaysAgo }

        guard !thisWeekLogs.isEmpty else { return nil }

        // Days with logs
        let daysWithLogs = Set(thisWeekLogs.map { calendar.startOfDay(for: $0.timestamp) }).count

        // Consistency: % of goal met
        let dayTotals = Dictionary(grouping: thisWeekLogs, by: { calendar.startOfDay(for: $0.timestamp) })
            .mapValues { $0.reduce(0.0) { $0 + $1.value } }

        let goal = board.effectiveTarget
        let accuracyPerDay = dayTotals.map { min(1.0, $0.value / goal) }
        let averageAccuracy = accuracyPerDay.isEmpty ? 0.0 : accuracyPerDay.reduce(0.0, +) / Double(accuracyPerDay.count)

        return (daysCompleted: daysWithLogs, consistency: averageAccuracy)
    }
}

// MARK: - Tab icon

// MARK: - Animated Tab Bar

private struct HabitDetailTabBar: View {
    @Binding var selectedTab: HabitDetailTab
    let reduceMotion: Bool

    private let tabs: [(tab: HabitDetailTab, icon: String)] = [
        (.overview, "chart.line.uptrend.xyaxis"),
        (.checkIns, "checklist"),
        (.journal, "doc.text"),
        (.analytics, "chart.bar.xaxis.ascending")
    ]

    var body: some View {
        ZStack(alignment: .leading) {
            // Background pill that animates to the selected tab
            GeometryReader { geo in
                Capsule(style: .continuous)
                    .fill(ColorPalette[0].opacity(0.15))
                    .frame(width: geo.size.width / 4, height: geo.size.height)
                    .offset(x: tabOffset(in: geo.size.width), y: 0)
                    .animation(DS.Motion.settle(reduceMotion: reduceMotion), value: selectedTab)
            }

            // Tab icons
            HStack(spacing: 24) {
                ForEach(tabs, id: \.tab) { tab, icon in
                    RefTabIcon(icon: icon, active: selectedTab == tab) {
                        selectedTab = tab
                        Haptics.selection()
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
        }
        .background(DS.Color.surface, in: Capsule(style: .continuous))
    }

    private func tabOffset(in width: CGFloat) -> CGFloat {
        let tabWidth = width / 4
        let selectedIndex = tabs.firstIndex { $0.tab == selectedTab } ?? 0
        return CGFloat(selectedIndex) * tabWidth
    }
}

private struct RefTabIcon: View {
    let icon: String
    let active: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                // Active/inactive weight is carried by color: the selected surface reads
                // primary, the rest recede to secondary. The animated selection indicator
                // is P3.1; this is the baseline hierarchy the reconcile requires.
                .foregroundStyle(active ? DS.Color.textPrimary : DS.Color.textSecondary)
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
                            .font(DS.Text.footnote)
                            .foregroundStyle(DS.Color.textSecondary)
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
            // Surface background — inactive cells use DS.Color.heatmapCellEmpty
            // (neutral adaptive tone) so the grid hierarchy holds in both themes
            // without needing a distinct container background.
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                    .fill(DS.Color.surface)
            )
        }
        .frame(height: heatmapHeight())
        // 182 days (26 weeks) covers the widest reasonable grid on any iPhone width.
        .task(id: "\(board.id)-\(board.logs?.count ?? -1)-\(board.targetValue ?? -1)") {
            let snapshots = (board.logs ?? []).map(LogSnapshot.init(from:))
            let logs = board.logs ?? []

            // For quantitative habits without a goal, use average as intensity baseline.
            // For binary or habits with explicit goals, use effectiveTarget.
            let target: Double
            if board.metric == .quantitative && board.targetValue == nil && !logs.isEmpty {
                let average = logs.reduce(0.0) { $0 + $1.value } / Double(logs.count)
                target = max(average, 1.0)  // Floor at 1.0 to avoid extreme intensity values
            } else {
                target = board.effectiveTarget
            }

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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Week-anchor date: locale's week-start of the column's week + dayIndex days.
    private var cellDate: Date? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let todayWeekday = cal.component(.weekday, from: today)
        let daysFromWeekStart = (todayWeekday - cal.firstWeekday + 7) % 7
        guard let currentWeekStart = cal.date(byAdding: .day, value: -daysFromWeekStart, to: today),
              let columnWeekStart  = cal.date(byAdding: .weekOfYear, value: -(totalCols - 1 - weekIndex), to: currentWeekStart),
              let date             = cal.date(byAdding: .day, value: dayIndex, to: columnWeekStart)
        else { return nil }
        return date
    }

    private var daysFromWeekStartToday: Int {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: .now)
        return (weekday - cal.firstWeekday + 7) % 7
    }

    private var isToday: Bool {
        weekIndex == totalCols - 1 && dayIndex == daysFromWeekStartToday
    }

    private var isFuture: Bool {
        weekIndex == totalCols - 1 && dayIndex > daysFromWeekStartToday
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
                        // Future: neutral recessed tone (invisible in dark, faint in light)
                        ? DS.Color.heatmapCellFuture
                        : (cell?.intensity ?? 0) > 0
                            // Active: accent color at tiered opacity
                            ? ColorPalette[colorIndex].opacity(fillOpacity)
                            // Inactive: neutral tone — adapts to theme, always visible
                            : DS.Color.heatmapCellEmpty
                )
                .frame(width: cellSize, height: cellSize)

            // Today ring — adaptive so it reads on both light and dark surfaces
            // (a hardcoded white ring vanished in light mode).
            if isToday {
                RoundedRectangle(cornerRadius: cellSize * 0.27, style: .continuous)
                    .stroke(DS.Color.textPrimary.opacity(0.85), lineWidth: 1.5)
                    .frame(width: cellSize, height: cellSize)
            }
        }
        .transition(.opacity)
        .animation(DS.Motion.settle(reduceMotion: reduceMotion), value: cellsByDate)
    }
}

// MARK: - Consistency card (reframed from "streak")

struct RefStreakCard: View {
    let board: HabitBoard

    private var totalLogged: Int {
        (board.logs ?? []).count
    }

    private var lastSevenDays: (logged: Int, total: Int) {
        let calendar = Calendar.current
        var count = 0
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: .now) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }
            let hasDayLog = (board.logs ?? []).contains { log in
                log.timestamp >= dayStart && log.timestamp < dayEnd
            }
            if hasDayLog { count += 1 }
        }
        return (count, 7)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header — this card's metric is total times logged, not consistency
            // (the sibling card owns consistency). Relabelled to end the duplicate.
            HStack(spacing: 5) {
                Image(systemName: "checkmark.circle.fill")
                    .font(DS.Text.footnote)
                    .foregroundStyle(DS.Color.textSecondary)
                Text("TIMES LOGGED")
                    .font(DS.Text.footnote)
                    .foregroundStyle(DS.Color.textSecondary)
                    .tracking(0.5)
            }

            Spacer(minLength: 18)

            // Total times logged (primary metric)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                ValueText("\(totalLogged)", font: DS.Text.valueHero)
                    .foregroundStyle(ColorPalette[board.colorIndex])
                    .contentTransition(.numericText())
                Text("times")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(.bottom, 6)
            }

            Spacer(minLength: 14)

            // Recent pattern (last 7 days)
            HStack(spacing: 4) {
                Text("Last 7:")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                ValueText("\(lastSevenDays.logged)", font: DS.Text.valueCompact)
                    .foregroundStyle(DS.Color.textPrimary)
                    .contentTransition(.numericText())
                Text("of 7")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 158, alignment: .leading)
        .padding(16)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
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
                    .font(DS.Text.footnote)
                    .foregroundStyle(DS.Color.textSecondary)
                Text("CONSISTENCY")
                    .font(DS.Text.footnote)
                    .foregroundStyle(DS.Color.textSecondary)
                    .tracking(0.5)
            }

            Spacer(minLength: 10)

            // Open-bottom arc — stroke width 14, deliberately neutral (not accent) so
            // it doesn't compete with the accent-colored values elsewhere on the screen.
            // Greys are now adaptive tokens rather than fixed white levels.
            ZStack {
                // Track: open bottom (trim 0.125…0.875, rotated 90° = opens at bottom)
                Circle()
                    .trim(from: 0.125, to: 0.875)
                    .stroke(DS.Color.textPrimary.opacity(0.12),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(90))

                // Fill
                if ratio > 0 {
                    Circle()
                        .trim(from: 0.125, to: 0.125 + 0.75 * min(1, ratio))
                        .stroke(DS.Color.textSecondary,
                                style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(90))
                }

                VStack(spacing: 2) {
                    ValueText("\(Int((ratio * 100).rounded()))%", font: DS.Text.value)
                        .foregroundStyle(DS.Color.textPrimary)
                        .contentTransition(.numericText())
                    Text("this month")
                        .font(DS.Text.footnote)
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
            .frame(height: 90)
            .padding(.horizontal, 6)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 158, alignment: .leading)
        .padding(16)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
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
                    .font(DS.Text.footnote)
                    .foregroundStyle(DS.Color.textSecondary)
                Text("CURRENT MONTH")
                    .font(DS.Text.footnote)
                    .foregroundStyle(DS.Color.textSecondary)
                    .tracking(0.5)
            }

            Spacer(minLength: 10)

            // Value row + bars
            HStack(alignment: .bottom, spacing: 0) {
                // Big number
                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    ValueText(String(format: "%.0f", monthTotal), font: DS.Text.valueHero)
                        .foregroundStyle(
                            monthTotal > 0 ? ColorPalette[board.colorIndex] : DS.Color.textTertiary
                        )
                        .contentTransition(.numericText())
                    if let u = board.unitLabel, !u.isEmpty {
                        Text(u)
                            .font(DS.Text.heading)
                            .foregroundStyle(DS.Color.textSecondary)
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
                                        ? DS.Color.textPrimary.opacity(0.08)
                                        : (v > 0 ? DS.Color.textSecondary : DS.Color.textPrimary.opacity(0.12))
                            )
                            .frame(width: 16, height: barH)
                    }
                }
            }

            Spacer(minLength: 14)

            // Footer
            HStack(spacing: 4) {
                Text("Current week:")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                if weekTotal > 0 {
                    ValueText(String(format: "%.0f", weekTotal), font: DS.Text.valueSmall)
                        .foregroundStyle(DS.Color.textPrimary)
                        .contentTransition(.numericText())
                    if let u = board.unitLabel, !u.isEmpty {
                        Text(u)
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                } else {
                    Text("–")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
        }
        .padding(16)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HabitDetailView(board: HabitBoard(name: "Work on side project", metricType: 1, targetValue: 1, unitLabel: "h", colorIndex: 5))
    }
}
