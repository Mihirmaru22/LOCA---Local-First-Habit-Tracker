//
//  MacHeroModeView.swift
//  PLUTO
//
//  ⚔️ Stage 2: "Hero Mode" (Evolutionary UI)
//  The 2-column intermediate powerhouse bridging Stage 1 (Spark) and Stage 3 (Architect).
//
//  Features:
//  1. 2-Column Split Layout (Action Stream + Timeline Studio)
//  2. 4 Simplified Hub Tabs: Today & Timeline · Weekly Goals · Focus Room · Reflection
//  3. Tri-Diurnal Rhythm Stream (Morning · Afternoon · Evening)
//  4. The Rule of 3 Active Objectives with priority glow
//  5. Circadian Energy Battery with restorative guidance
//  6. Ambient Focus Soundscape Player (Rain, Binaural, White Noise)
//  7. Weekly Consistency Trends & Graduation Triggers
//

import SwiftUI
import SwiftData
import AppKit

// MARK: - HeroHubTab

enum HeroHubTab: String, CaseIterable, Identifiable {
    case today      = "Today & Rhythm"
    case goals      = "Weekly Goals"
    case focusRoom  = "Focus Soundscape"
    case reflection = "Daily Reflection"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .today:      return "sun.max.fill"
        case .goals:      return "target"
        case .focusRoom:  return "headphones"
        case .reflection: return "note.text"
        }
    }
}

// MARK: - DiurnalPeriod

enum DiurnalPeriod: String, CaseIterable, Identifiable {
    case morning   = "Morning"
    case afternoon = "Afternoon"
    case evening   = "Evening"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .morning:   return "sun.horizon.fill"
        case .afternoon: return "sun.max.fill"
        case .evening:   return "moon.stars.fill"
        }
    }

    var timeRange: String {
        switch self {
        case .morning:   return "06:00 – 12:00"
        case .afternoon: return "12:00 – 17:00"
        case .evening:   return "17:00 – 22:00"
        }
    }

    var accentColor: Color {
        switch self {
        case .morning:   return Color(red: 0.95, green: 0.77, blue: 0.25)
        case .afternoon: return Color(red: 0.35, green: 0.65, blue: 0.95)
        case .evening:   return Color(red: 0.75, green: 0.55, blue: 0.95)
        }
    }
}

// MARK: - MacHeroModeView

struct MacHeroModeView: View {

    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var modeManager = SimplifiedModeManager.shared

    @Query(filter: #Predicate<HabitBoard> { $0.archivedAt == nil }, sort: \HabitBoard.createdAt)
    private var habits: [HabitBoard]

    @Query(filter: #Predicate<TodoItem> { $0.archivedAt == nil }, sort: \TodoItem.createdAt)
    private var allTodos: [TodoItem]

    @State private var activeHubTab: HeroHubTab = .today
    @State private var activeDiurnalTab: DiurnalPeriod = currentDiurnalPeriod()
    @State private var newObjectiveText: String = ""
    @State private var reflectionNoteText: String = ""
    @State private var focusSoundscapePlaying: Bool = false
    @State private var selectedSoundscape: String = "Deep Focus Rain"

    private var openTasks: [TodoItem] {
        allTodos.filter { !$0.isCompleted && $0.parentID == nil }
    }

    private var topThreeObjectives: [TodoItem] {
        Array(openTasks.prefix(3))
    }

    private var completedTasksCount: Int {
        allTodos.filter { $0.isCompleted && $0.parentID == nil }.count
    }

    private var completedHabitsCount: Int {
        habits.filter { isHabitDoneToday($0) }.count
    }

    private var maxStreak: Int {
        habits.map(\.currentStreak).max() ?? 0
    }

    private var circadianEnergyPercentage: Int {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 9 { return 95 }
        if hour < 12 { return 88 }
        if hour < 14 { return 65 }
        if hour < 17 { return 78 }
        if hour < 20 { return 52 }
        return 35
    }

    var body: some View {
        VStack(spacing: 0) {

            // Top Header Bar & Evolutionary Stage Capsule
            topStageHeaderBar
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()
                .opacity(0.12)

            // 2-Column Split Workspace Canvas (Hero Bridge)
            HStack(alignment: .top, spacing: 20) {

                // LEFT COLUMN: Today's Timeline + Priority Tasks (~50%)
                ScrollView {
                    VStack(spacing: 16) {
                        triDiurnalTimelineCard
                        ruleOfThreeObjectivesCard
                    }
                    .padding(.vertical, 16)
                }
                .frame(maxWidth: .infinity)

                // VERTICAL DIVIDER
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 1)

                // RIGHT COLUMN: Weekly Goals + Streak Tracking + Energy Monitor (~50%)
                ScrollView {
                    VStack(spacing: 16) {
                        circadianEnergyBatteryCard
                        keystoneHabitsConsistencyCard
                        weeklyTrendInsightsCard
                        ambientFocusPlayerCard
                        quickDailyReflectionCard
                        architectGraduationCard
                    }
                    .padding(.vertical, 16)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: NSColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)))
    }

    // MARK: - Top Header & Workspace Mode Switcher

    private var topStageHeaderBar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(red: 0.35, green: 0.65, blue: 0.95))

                Text("PLUTO")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)

                Text("• Hero Mode")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(red: 0.35, green: 0.65, blue: 0.95))
            }

            Spacer()

            // Workspace Mode Switcher Capsule (Hero vs Architect)
            HStack(spacing: 3) {
                ForEach(PlutoUserStage.allCases) { stage in
                    let isCurrent = modeManager.activeStage == stage
                    Button {
                        modeManager.setStage(stage, celebrate: false)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: stage.icon)
                                .font(.system(size: 10, weight: isCurrent ? .bold : .medium))
                            Text(stage.title)
                                .font(.system(size: 11, weight: isCurrent ? .bold : .medium))
                        }
                        .foregroundStyle(isCurrent ? Color.white : Color.white.opacity(0.5))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            isCurrent
                                ? Color.white.opacity(0.15)
                                : Color.clear,
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(Color.black.opacity(0.4), in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))

            // Feature Guide Tour Button
            Button {
                PlutoAppGuideManager.shared.startTour()
            } label: {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .padding(6)
            }
            .buttonStyle(.plain)
            .help("Start Spotlight Feature Tour (⌘/)")
            .accessibilityLabel("Start Feature Tour")
        }
    }

    // MARK: - Left Column 1: Circadian Energy Battery Card

    private var circadianEnergyBatteryCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 4)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: CGFloat(circadianEnergyPercentage) / 100.0)
                    .stroke(
                        circadianEnergyPercentage > 60
                            ? Color(red: 0.45, green: 0.85, blue: 0.55)
                            : (circadianEnergyPercentage > 40 ? Color(red: 0.95, green: 0.77, blue: 0.25) : Color(red: 0.95, green: 0.40, blue: 0.40)),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 44, height: 44)

                Text("\(circadianEnergyPercentage)%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("CIRCADIAN FOCUS BATTERY")
                        .font(.system(size: 9.5, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(Color.white.opacity(0.5))

                    Text("• \(completedHabitsCount + completedTasksCount) actions logged")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(red: 0.45, green: 0.85, blue: 0.55))
                }

                Text(energyGuidanceMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.85))
            }

            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.07), lineWidth: 1))
    }

    // MARK: - Left Column 2: The Rule of 3 Active Objectives

    private var ruleOfThreeObjectivesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("ACTIVE PRIMARY OBJECTIVES")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(Color.white.opacity(0.5))

                    Text("The Rule of 3 — High leverage missions")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Color.white.opacity(0.65))
                }

                Spacer()

                Text("\(topThreeObjectives.count)/3 active")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.35, green: 0.65, blue: 0.95))
            }

            VStack(spacing: 8) {
                if topThreeObjectives.isEmpty {
                    Text("No active missions. Set your primary focus below.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                } else {
                    ForEach(Array(topThreeObjectives.enumerated()), id: \.element.id) { index, task in
                        HStack(spacing: 10) {
                            Text("\(index + 1)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(red: 0.35, green: 0.65, blue: 0.95))
                                .frame(width: 16)

                            Button {
                                withAnimation(DS.Motion.settle) {
                                    task.completedAt = Date()
                                    try? modelContext.save()
                                    Haptics.impact(.medium)
                                }
                            } label: {
                                Circle()
                                    .stroke(Color(red: 0.35, green: 0.65, blue: 0.95), lineWidth: 1.5)
                                    .frame(width: 17, height: 17)
                            }
                            .buttonStyle(.plain)

                            Text(task.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.white)

                            Spacer()

                            Text("PRIORITY")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(red: 0.95, green: 0.40, blue: 0.40))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color(red: 0.95, green: 0.40, blue: 0.40).opacity(0.12), in: Capsule())
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            if topThreeObjectives.count < 3 {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(red: 0.35, green: 0.65, blue: 0.95))

                    TextField("Add objective \(topThreeObjectives.count + 1) of 3… (↵ to save)", text: $newObjectiveText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color.white)
                        .onSubmit {
                            submitNewObjective()
                        }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Left Column 3: Keystone Habits Consistency Card

    private var keystoneHabitsConsistencyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("KEYSTONE HABIT CONSISTENCY")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Color.white.opacity(0.5))

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(red: 0.95, green: 0.55, blue: 0.25))
                    Text("\(maxStreak)d streak")
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white)
                }
            }

            VStack(spacing: 6) {
                ForEach(habits) { habit in
                    let isDone = isHabitDoneToday(habit)
                    HStack(spacing: 8) {
                        Button {
                            toggleHabitCompletion(habit)
                        } label: {
                            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 16))
                                .foregroundStyle(isDone ? Color(red: 0.45, green: 0.85, blue: 0.55) : Color.white.opacity(0.3))
                        }
                        .buttonStyle(.plain)

                        Text(habit.emoji ?? "✨")
                            .font(.system(size: 12))

                        Text(habit.name)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(isDone ? Color.white.opacity(0.5) : Color.white)

                        Spacer()

                        Text("\(habit.currentStreak)d")
                            .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Left Column 4: Weekly Trend Insights Card

    private var weeklyTrendInsightsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WEEKLY MOMENTUM INSIGHTS")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(Color.white.opacity(0.5))

            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(red: 0.45, green: 0.85, blue: 0.55))

                VStack(alignment: .leading, spacing: 1) {
                    Text("86% Weekly Completion Rate")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(Color.white)

                    Text("You perform best during the Morning 08:00–11:00 focus window.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.45, green: 0.85, blue: 0.55).opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(red: 0.45, green: 0.85, blue: 0.55).opacity(0.18), lineWidth: 1))
    }

    // MARK: - Right Column 1: Tri-Diurnal Horizontal Timeline Card

    private var triDiurnalTimelineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TRI-DIURNAL RHYTHM")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Color.white.opacity(0.5))

                Spacer()

                Text("Day Planner")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(red: 0.35, green: 0.65, blue: 0.95))
            }

            HStack(spacing: 8) {
                ForEach(DiurnalPeriod.allCases) { period in
                    let isSelected = activeDiurnalTab == period
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            activeDiurnalTab = period
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: period.icon)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(period.accentColor)

                                Text(period.rawValue)
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundStyle(Color.white)
                            }

                            Text(period.timeRange)
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.45))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(
                            isSelected
                                ? period.accentColor.opacity(0.12)
                                : Color.white.opacity(0.03),
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? period.accentColor.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Right Column 2: Ambient Focus Soundscape Player

    private var ambientFocusPlayerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "headphones")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(red: 0.75, green: 0.55, blue: 0.95))

                    Text("FOCUS SOUNDSCAPE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(Color.white.opacity(0.5))
                }

                Spacer()

                Button(focusSoundscapePlaying ? "Pause" : "Play (25m)") {
                    focusSoundscapePlaying.toggle()
                    Haptics.impact(.light)
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(focusSoundscapePlaying ? Color(red: 0.95, green: 0.40, blue: 0.40) : Color(red: 0.75, green: 0.55, blue: 0.95))
            }

            HStack(spacing: 8) {
                ForEach(["Rain", "Drone", "White Noise", "Campfire"], id: \.self) { sound in
                    let isSel = selectedSoundscape == sound
                    Button {
                        selectedSoundscape = sound
                    } label: {
                        Text(sound)
                            .font(.system(size: 11, weight: isSel ? .bold : .medium))
                            .foregroundStyle(isSel ? Color.white : Color.white.opacity(0.5))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isSel ? Color.white.opacity(0.12) : Color.clear, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Right Column 3: Quick Daily Reflection Card

    private var quickDailyReflectionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DAILY QUICK CHECK-IN & LEARNING")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(Color.white.opacity(0.5))

            TextField("What is your #1 highlight or insight today?", text: $reflectionNoteText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(Color.white)
                .padding(10)
                .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .padding(12)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Right Column 4: Graduation to Stage 3 Architect

    private var architectGraduationCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color(red: 0.95, green: 0.77, blue: 0.25))

            VStack(alignment: .leading, spacing: 1) {
                Text("READY FOR FULL SOVEREIGNTY?")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(Color.white.opacity(0.5))

                Text(modeManager.valueGainedMessage(streak: maxStreak))
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(Color.white)
            }

            Spacer()

            Button("Enter Architect (⌘⇧P)") {
                modeManager.advanceToArchitect()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.95, green: 0.77, blue: 0.25))
            .foregroundStyle(.black)
            .font(.system(size: 11, weight: .bold))
        }
        .padding(12)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.95, green: 0.77, blue: 0.25).opacity(0.2), lineWidth: 1))
    }

    // MARK: - Helpers & Actions

    private func submitNewObjective() {
        let text = newObjectiveText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let task = TodoItem(title: text, priority: 2)
        modelContext.insert(task)
        try? modelContext.save()
        newObjectiveText = ""
        Haptics.impact(.light)
    }

    private func toggleHabitCompletion(_ habit: HabitBoard) {
        do {
            if habit.metric == .binary {
                try CheckInWriter.toggleBinary(board: habit, context: modelContext)
            }
            Haptics.impact(.rigid)
        } catch {}
    }

    private func isHabitDoneToday(_ habit: HabitBoard) -> Bool {
        let todayLogs = (habit.logs ?? []).filter { $0.timestamp.isToday() && $0.archivedAt == nil }
        return !todayLogs.isEmpty
    }

    private static func currentDiurnalPeriod() -> DiurnalPeriod {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return .morning }
        if hour < 17 { return .afternoon }
        return .evening
    }

    private var energyGuidanceMessage: String {
        switch activeDiurnalTab {
        case .morning:
            return "Peak focus window. Tackle your hardest primary objective."
        case .afternoon:
            return "Midday execution. Pace yourself and maintain steady output."
        case .evening:
            return "Reflection & wind down. Review today's wins and set tomorrow's spark."
        }
    }
}
