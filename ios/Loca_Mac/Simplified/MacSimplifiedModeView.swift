//
//  MacSimplifiedModeView.swift
//  PLUTO
//
//  Single-Column Focus Tunnel & Simplified Mode for macOS.
//  Provides progressive disclosure for new users, eliminating cognitive overload
//  while keeping power-user features accessible via the Pro Mode toggle (⌘⇧P).
//

import SwiftUI
import SwiftData
import AppKit

// MARK: - MacSimplifiedModeView

struct MacSimplifiedModeView: View {

    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var modeManager = SimplifiedModeManager.shared

    // Queries
    @Query(filter: #Predicate<HabitBoard> { $0.archivedAt == nil }, sort: \HabitBoard.createdAt)
    private var habits: [HabitBoard]

    @Query(filter: #Predicate<TodoItem> { $0.archivedAt == nil }, sort: \TodoItem.createdAt)
    private var allTodos: [TodoItem]

    // Local UI State
    @State private var showCompletedSection: Bool = false
    @State private var quickAddText: String = ""
    @State private var quickAddType: QuickAddType = .task
    @State private var quickAddPriority: Int = 1
    @State private var selectedHabitForDetail: HabitBoard? = nil
    @State private var isQuickAddFocused: Bool = false

    private var openTasks: [TodoItem] {
        allTodos.filter { !$0.isCompleted && $0.parentID == nil }
    }

    private var completedTasks: [TodoItem] {
        allTodos.filter { $0.isCompleted && $0.parentID == nil }
    }

    private var completedHabitCount: Int {
        habits.filter { isHabitDoneToday($0) }.count
    }

    private var totalDailyItems: Int {
        habits.count + openTasks.count + completedTasks.count
    }

    private var completedDailyItems: Int {
        completedHabitCount + completedTasks.count
    }

    private var dailyProgress: Double {
        totalDailyItems == 0 ? 0 : Double(completedDailyItems) / Double(totalDailyItems)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Top Navigation & Mode Switcher Bar
                topHeaderBar

                // Contextual Welcome & Day Progress Card
                welcomeProgressCard

                // Card 1: Fast Frictionless Quick Add
                quickAddCard

                // Card 2: Starter Keystone Habit Launcher (if 0 habits)
                if habits.isEmpty {
                    starterHabitCard
                }

                // Card 3: Today's Keystone Habits
                if !habits.isEmpty {
                    habitsListCard
                }

                // Card 4: Today's Priority Tasks
                if !openTasks.isEmpty {
                    tasksListCard
                }

                // Card 5: Empty State Celebration (when everything done)
                if openTasks.isEmpty && !habits.isEmpty && completedHabitCount == habits.count {
                    allClearCelebrationCard
                }

                // Card 6: Completed Accomplishments Section
                if !completedTasks.isEmpty || completedHabitCount > 0 {
                    completedCollapsibleSection
                }

                // Card 7: Pro Mode Teaser & Discovery Card
                proModeTeaserCard

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .frame(maxWidth: 760)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: NSColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0)))
    }

    // MARK: - Top Header Bar

    private var topHeaderBar: some View {
        HStack(alignment: .center) {
            HStack(spacing: 8) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.77, blue: 0.25))

                Text("PLUTO")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)

                Text("• Simplified")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.4))
            }

            Spacer()

            // Pro Mode Toggle CTA
            Button {
                modeManager.enableProMode()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("Pro Mode")
                        .font(.system(size: 12, weight: .semibold))
                    Text("⌘⇧P")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 3))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.25, green: 0.45, blue: 0.85), Color(red: 0.45, green: 0.35, blue: 0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule()
                )
                .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help("Switch to the multi-column Pro workspace with Day Planner timeline, BrainStorm, and Trek Atlas (⌘⇧P)")
        }
        .padding(.bottom, 4)
    }

    // MARK: - Welcome & Daily Progress Card

    private var welcomeProgressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeOfDayGreeting)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.white)

                    Text(Date().formatted(date: .complete, time: .omitted))
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.55))
                }

                Spacer()

                // Progress Badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(dailyProgress * 100))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.95, green: 0.77, blue: 0.25))

                    Text("\(completedDailyItems) of \(totalDailyItems) done")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.45))
                }
            }

            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 6)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.77, blue: 0.25), Color(red: 0.45, green: 0.85, blue: 0.55)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(6, geo.size.width * dailyProgress), height: 6)
                        .animation(.spring(response: 0.4), value: dailyProgress)
                }
            }
            .frame(height: 6)
        }
        .padding(18)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - Card 1: Fast Frictionless Quick Add

    private var quickAddCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                // Type Selector Pill (Task vs Habit)
                Picker("", selection: $quickAddType) {
                    Text("Task").tag(QuickAddType.task)
                    Text("Keystone Habit").tag(QuickAddType.habit)
                }
                .pickerStyle(.segmented)
                .frame(width: 170)

                if quickAddType == .task {
                    // Priority Selector
                    Picker("", selection: $quickAddPriority) {
                        Text("Low").tag(0)
                        Text("Med").tag(1)
                        Text("High").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Image(systemName: quickAddType == .task ? "plus.circle.fill" : "sparkles")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.white.opacity(0.4))

                TextField(
                    quickAddType == .task
                        ? "What needs to get done today? (Press Enter)"
                        : "Name a daily keystone habit… (Press Enter)",
                    text: $quickAddText
                )
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(Color.white)
                .onSubmit {
                    submitQuickAdd()
                }

                if !quickAddText.isEmpty {
                    Button(action: submitQuickAdd) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(red: 0.95, green: 0.77, blue: 0.25))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
        .padding(16)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Card 2: Starter Habit Setup (when 0 habits exist)

    private var starterHabitCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.77, blue: 0.25))

                Text("START YOUR FIRST KEYSTONE HABIT")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Color.white.opacity(0.6))
            }

            Text("Keystone habits create positive ripple effects across your entire day. Pick a proven starter:")
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.75))

            // Starter Template Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                starterHabitButton(emoji: "🏃", name: "10,000 Steps", metric: .quantitative, target: 10000, unit: "steps")
                starterHabitButton(emoji: "💧", name: "2L Water", metric: .quantitative, target: 2000, unit: "ml")
                starterHabitButton(emoji: "📚", name: "20m Reading", metric: .quantitative, target: 20, unit: "mins")
                starterHabitButton(emoji: "🧘", name: "Daily Meditation", metric: .binary, target: 1, unit: nil)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.95, green: 0.77, blue: 0.25).opacity(0.25), lineWidth: 1))
    }

    private func starterHabitButton(emoji: String, name: String, metric: MetricType, target: Double, unit: String?) -> some View {
        Button {
            let board = HabitBoard(name: name, metricType: metric.rawValue, colorIndex: Int.random(in: 0...7))
            board.emoji = emoji
            board.targetValue = metric == .quantitative ? target : nil
            board.unitLabel = unit
            modelContext.insert(board)
            try? modelContext.save()
            Haptics.impact(.medium)
        } label: {
            HStack(spacing: 10) {
                Text(emoji)
                    .font(.system(size: 18))

                VStack(alignment: .leading, spacing: 1) {
                    Text(name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white)

                    Text(metric == .binary ? "Daily check-off" : "\(Int(target)) \(unit ?? "") goal")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.45))
                }

                Spacer()

                Image(systemName: "plus.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
            .padding(12)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Card 3: Today's Keystone Habits List

    private var habitsListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TODAY'S HABITS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Color.white.opacity(0.55))

                Spacer()

                Text("\(completedHabitCount)/\(habits.count) complete")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.4))
            }

            VStack(spacing: 8) {
                ForEach(habits) { habit in
                    simplifiedHabitRow(habit)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func simplifiedHabitRow(_ habit: HabitBoard) -> some View {
        let isDone = isHabitDoneToday(habit)

        return HStack(spacing: 12) {
            // Interactive 1-Tap Completion Checkbox
            Button {
                toggleHabitCompletion(habit)
            } label: {
                ZStack {
                    Circle()
                        .fill(isDone ? Color.accentColor : Color.white.opacity(0.08))
                        .frame(width: 28, height: 28)

                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.white)
                    } else if let emoji = habit.emoji {
                        Text(emoji)
                            .font(.system(size: 13))
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isDone ? Color.white.opacity(0.5) : Color.white)
                    .strikethrough(isDone, color: Color.white.opacity(0.3))

                if habit.metric == .quantitative, let unit = habit.unitLabel {
                    let todayLogs = (habit.logs ?? []).filter { $0.timestamp.isToday() && $0.archivedAt == nil }
                    let total = todayLogs.reduce(0.0) { $0 + $1.value }
                    Text("\(Int(total)) / \(Int(habit.effectiveTarget)) \(unit)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
            }

            Spacer()

            // Streak Flame Badge
            if habit.currentStreak > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(red: 0.95, green: 0.55, blue: 0.25))
                    Text("\(habit.currentStreak)d")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.75))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.06), in: Capsule())
            }
        }
        .padding(12)
        .background(Color.white.opacity(isDone ? 0.02 : 0.05), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Card 4: Today's Tasks List

    private var tasksListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TODAY'S PRIORITIES")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Color.white.opacity(0.55))

                Spacer()

                Text("\(openTasks.count) open")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.4))
            }

            VStack(spacing: 8) {
                ForEach(openTasks) { task in
                    simplifiedTaskRow(task)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func simplifiedTaskRow(_ task: TodoItem) -> some View {
        HStack(spacing: 12) {
            // 1-Tap Task Check-off
            Button {
                withAnimation(DS.Motion.settle) {
                    task.completedAt = Date()
                    try? modelContext.save()
                    Haptics.impact(.light)
                }
            } label: {
                Circle()
                    .stroke(priorityColor(task.priority), lineWidth: 1.5)
                    .frame(width: 20, height: 20)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title.isEmpty ? "Untitled task" : task.title)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(Color.white)

                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.45))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Priority Pill
            if task.priority > 0 {
                Text(task.priority == 2 ? "HIGH" : "MED")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(priorityColor(task.priority))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(priorityColor(task.priority).opacity(0.12), in: Capsule())
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Card 5: All Clear Celebration Card

    private var allClearCelebrationCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color(red: 0.45, green: 0.85, blue: 0.55))

            Text("All Clear for Today!")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.white)

            Text("You've completed all scheduled priorities and keystone habits. Rest up or jump into deep focus mode.")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Card 6: Completed Section

    private var completedCollapsibleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    showCompletedSection.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: showCompletedSection ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                    Text("COMPLETED TODAY (\(completedDailyItems))")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.6)
                }
                .foregroundStyle(Color.white.opacity(0.45))
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            if showCompletedSection {
                VStack(spacing: 6) {
                    ForEach(completedTasks) { task in
                        HStack(spacing: 10) {
                            Button {
                                task.completedAt = nil
                                try? modelContext.save()
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.accentColor)
                            }
                            .buttonStyle(.plain)

                            Text(task.title)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.white.opacity(0.4))
                                .strikethrough(true, color: Color.white.opacity(0.3))

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 6))
                    }
                }
                .transition(.opacity)
            }
        }
    }

    // MARK: - Card 7: Pro Mode Teaser Card

    private var proModeTeaserCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(red: 0.55, green: 0.65, blue: 0.95))

                VStack(alignment: .leading, spacing: 1) {
                    Text("READY FOR MORE POWER?")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(Color.white.opacity(0.6))

                    Text("Unlock the Full 3-Column Pro Canvas")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.white)
                }

                Spacer()

                Button("Open Pro Mode (⌘⇧P)") {
                    modeManager.enableProMode()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.35, green: 0.55, blue: 0.95))
                .font(.system(size: 12, weight: .semibold))
            }

            // Pro Features Teaser Grid
            HStack(spacing: 12) {
                proFeatureChip(icon: "calendar.day.timeline.left", title: "Day Planner", subtitle: "Visual time-blocking")
                proFeatureChip(icon: "timer.circle.fill", title: "Focus Studio", subtitle: "Pomodoro & 3D audio")
                proFeatureChip(icon: "note.text", title: "BrainStorm", subtitle: "Apple Notes canvas")
                proFeatureChip(icon: "mountain.2.fill", title: "Trek Atlas", subtitle: "Elevation & trails")
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.10), lineWidth: 1))
    }

    private func proFeatureChip(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(red: 0.55, green: 0.65, blue: 0.95))

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white)

            Text(subtitle)
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Actions & Helpers

    private func submitQuickAdd() {
        let text = quickAddText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        if quickAddType == .task {
            let task = TodoItem(title: text, priority: quickAddPriority)
            modelContext.insert(task)
        } else {
            let habit = HabitBoard(name: text, metricType: MetricType.binary.rawValue, colorIndex: Int.random(in: 0...7))
            habit.emoji = "✨"
            modelContext.insert(habit)
        }

        try? modelContext.save()
        quickAddText = ""
        Haptics.impact(.light)
    }

    private func toggleHabitCompletion(_ habit: HabitBoard) {
        do {
            if habit.metric == .binary {
                try CheckInWriter.toggleBinary(board: habit, context: modelContext)
            } else {
                let todayLogs = (habit.logs ?? []).filter { $0.timestamp.isToday() && $0.archivedAt == nil }
                let currentTotal = todayLogs.reduce(0.0) { $0 + $1.value }
                if currentTotal >= habit.effectiveTarget {
                    for entry in todayLogs {
                        try CheckInWriter.delete(entry, board: habit, context: modelContext)
                    }
                } else {
                    let remaining = max(1.0, habit.effectiveTarget - currentTotal)
                    try CheckInWriter.insert(value: remaining, board: habit, context: modelContext)
                }
            }
            Haptics.impact(.rigid)
        } catch {}
    }

    private func isHabitDoneToday(_ habit: HabitBoard) -> Bool {
        let todayLogs = (habit.logs ?? []).filter { $0.timestamp.isToday() && $0.archivedAt == nil }
        let total = todayLogs.reduce(0.0) { $0 + $1.value }
        return total >= habit.effectiveTarget
    }

    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    private func priorityColor(_ priority: Int) -> Color {
        switch priority {
        case 2: return Color(red: 0.95, green: 0.40, blue: 0.40)
        case 1: return Color(red: 0.95, green: 0.77, blue: 0.25)
        default: return Color(red: 0.55, green: 0.65, blue: 0.95)
        }
    }

    private enum QuickAddType {
        case task
        case habit
    }
}
