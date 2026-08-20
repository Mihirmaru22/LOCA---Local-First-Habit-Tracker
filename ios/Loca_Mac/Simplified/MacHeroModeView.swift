//
//  MacHeroModeView.swift
//  PLUTO
//
//  ⚔️ Stage 2: "Hero Mode" (Evolutionary UI)
//  The missing link between ultra-minimal Spark Mode and full Architect Pro Mode.
//  Features:
//  1. Tri-Diurnal Horizontal Timeline Strip (Morning · Afternoon · Evening)
//  2. The Rule of 3 Active Objectives (Prioritized Mission Targets)
//  3. Circadian Energy Battery Gauge with restorative break prompts
//  4. Keystone Habit Consistency Matrix
//

import SwiftUI
import SwiftData
import AppKit

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

    @State private var activeDiurnalTab: DiurnalPeriod = currentDiurnalPeriod()
    @State private var newObjectiveText: String = ""
    @State private var selectedPriority: Int = 2

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

    private var circadianEnergyPercentage: Int {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 9 { return 95 }
        if hour < 12 { return 88 }
        if hour < 14 { return 65 } // Post-lunch dip
        if hour < 17 { return 78 } // Second wind
        if hour < 20 { return 52 }
        return 35 // Wind down
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Evolutionary Stage Navigation Bar
                stageNavigationBar

                // Circadian Energy Battery Banner
                circadianEnergyBanner

                // Tri-Diurnal Horizontal Timeline Strip
                triDiurnalTimelineStrip

                // The Rule of 3 Active Objectives Card
                ruleOfThreeObjectivesCard

                // Keystone Habit Consistency Strip
                if !habits.isEmpty {
                    heroHabitsStrip
                }

                // Graduation CTA to Stage 3 (Architect)
                architectGraduationCard

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .frame(maxWidth: 820)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: NSColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)))
    }

    // MARK: - Stage Navigation Bar

    private var stageNavigationBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(red: 0.35, green: 0.65, blue: 0.95))

                Text("PLUTO")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)

                Text("• Hero Stage")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(red: 0.35, green: 0.65, blue: 0.95))
            }

            Spacer()

            // 3-Stage Evolutionary Switcher Capsule
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
        }
    }

    // MARK: - Circadian Energy Battery Banner

    private var circadianEnergyBanner: some View {
        HStack(spacing: 14) {
            // Battery Dial
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 4)
                    .frame(width: 42, height: 42)

                Circle()
                    .trim(from: 0, to: CGFloat(circadianEnergyPercentage) / 100.0)
                    .stroke(
                        circadianEnergyPercentage > 60
                            ? Color(red: 0.45, green: 0.85, blue: 0.55)
                            : (circadianEnergyPercentage > 40 ? Color(red: 0.95, green: 0.77, blue: 0.25) : Color(red: 0.95, green: 0.40, blue: 0.40)),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 42, height: 42)

                Text("\(circadianEnergyPercentage)%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("CIRCADIAN FOCUS BATTERY")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(Color.white.opacity(0.5))

                    Text("• \(completedHabitsCount + completedTasksCount) actions logged today")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Color(red: 0.45, green: 0.85, blue: 0.55))
                }

                Text(energyGuidanceMessage)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.85))
            }

            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - Tri-Diurnal Horizontal Timeline Strip

    private var triDiurnalTimelineStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TRI-DIURNAL RHYTHM")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(Color.white.opacity(0.5))

            HStack(spacing: 10) {
                ForEach(DiurnalPeriod.allCases) { period in
                    let isSelected = activeDiurnalTab == period
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            activeDiurnalTab = period
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: period.icon)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(period.accentColor)

                                Text(period.rawValue)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.white)

                                Spacer()

                                if isCurrentPeriod(period) {
                                    Text("NOW")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color.black)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1.5)
                                        .background(period.accentColor, in: Capsule())
                                }
                            }

                            Text(period.timeRange)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.45))
                        }
                        .padding(12)
                        .background(
                            isSelected
                                ? period.accentColor.opacity(0.12)
                                : Color.white.opacity(0.03),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? period.accentColor.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - The Rule of 3 Active Objectives Card

    private var ruleOfThreeObjectivesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ACTIVE PRIMARY OBJECTIVES")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(Color.white.opacity(0.5))

                    Text("The Rule of 3 — Focus only on high-leverage missions")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.7))
                }

                Spacer()

                Text("\(topThreeObjectives.count)/3 active")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.35, green: 0.65, blue: 0.95))
            }

            // 3 Objectives List
            VStack(spacing: 8) {
                if topThreeObjectives.isEmpty {
                    Text("No active missions. Set your top priorities below.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    ForEach(Array(topThreeObjectives.enumerated()), id: \.element.id) { index, task in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(red: 0.35, green: 0.65, blue: 0.95))
                                .frame(width: 18)

                            Button {
                                withAnimation(DS.Motion.settle) {
                                    task.completedAt = Date()
                                    try? modelContext.save()
                                    Haptics.impact(.medium)
                                }
                            } label: {
                                Circle()
                                    .stroke(Color(red: 0.35, green: 0.65, blue: 0.95), lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                            }
                            .buttonStyle(.plain)

                            Text(task.title)
                                .font(.system(size: 13.5, weight: .medium))
                                .foregroundStyle(Color.white)

                            Spacer()

                            Text("HIGH PRIORITY")
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(red: 0.95, green: 0.40, blue: 0.40))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(red: 0.95, green: 0.40, blue: 0.40).opacity(0.12), in: Capsule())
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            // Quick Add Input for Objectives (if < 3)
            if topThreeObjectives.count < 3 {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(red: 0.35, green: 0.65, blue: 0.95))

                    TextField("Add mission objective \(topThreeObjectives.count + 1) of 3… (↵ to save)", text: $newObjectiveText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white)
                        .onSubmit {
                            submitNewObjective()
                        }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Keystone Habit Strip

    private var heroHabitsStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("DAILY KEYSTONE CADENCE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Color.white.opacity(0.5))

                Spacer()

                Text("\(completedHabitsCount)/\(habits.count) complete")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.45))
            }

            HStack(spacing: 8) {
                ForEach(habits) { habit in
                    let isDone = isHabitDoneToday(habit)
                    Button {
                        toggleHabitCompletion(habit)
                    } label: {
                        HStack(spacing: 6) {
                            Text(habit.emoji ?? "✨")
                                .font(.system(size: 13))

                            Text(habit.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(isDone ? Color.white.opacity(0.5) : Color.white)

                            if isDone {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color(red: 0.45, green: 0.85, blue: 0.55))
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(isDone ? Color.white.opacity(0.08) : Color.white.opacity(0.04), in: Capsule())
                        .overlay(Capsule().stroke(isDone ? Color(red: 0.45, green: 0.85, blue: 0.55).opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Graduation Card to Stage 3 (Architect)

    private var architectGraduationCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "crown.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color(red: 0.95, green: 0.77, blue: 0.25))

            VStack(alignment: .leading, spacing: 2) {
                Text("READY FOR TOTAL ARCHITECTURE?")
                    .font(.system(size: 9.5, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(Color.white.opacity(0.5))

                Text("Unlock Stage 3: Architect (Full 3-Column OS & Notes)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.white)
            }

            Spacer()

            Button("Enter Architect (⌘⇧P)") {
                modeManager.advanceToArchitect()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.95, green: 0.77, blue: 0.25))
            .foregroundStyle(.black)
            .font(.system(size: 11.5, weight: .bold))
        }
        .padding(14)
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

    private func isCurrentPeriod(_ period: DiurnalPeriod) -> Bool {
        Self.currentDiurnalPeriod() == period
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
