import SwiftUI
import SwiftData
import Combine

// MARK: - MacDayDashboardHub (Executive Day Focus & Dashboard Hub)

/// Shown in the right detail column of Plan mode when no specific task is selected.
/// Replaces the empty black "No Task Selected" void with an executive command center.
struct MacDayDashboardHub: View {

    @Binding var selectedItem: TodoItem?

    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\TodoItem.startTime)]) private var allItems: [TodoItem]
    @Query(filter: #Predicate<HabitBoard> { $0.archivedAt == nil }) private var allHabits: [HabitBoard]

    @State private var focusTimeRemaining: Int = 25 * 60
    @State private var isTimerRunning: Bool = false
    @State private var timerEndTimestamp: Date? = nil
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var scratchpadText: String = ""

    private var today: Date { Calendar.current.startOfDay(for: .now) }

    private var activeTasks: [TodoItem] {
        allItems.filter { !$0.isArchived && $0.parentID == nil }
    }

    private var scheduledToday: [TodoItem] {
        activeTasks.filter {
            guard let s = $0.startTime else { return false }
            return Calendar.current.isDate(s, inSameDayAs: today)
        }
    }

    private var unscheduledTasks: [TodoItem] {
        activeTasks.filter { $0.startTime == nil && !$0.isCompleted }
    }

    private var completedToday: [TodoItem] {
        scheduledToday.filter(\.isCompleted)
    }

    private var totalPlannedMinutes: Int {
        scheduledToday.reduce(0) { total, item in
            let dur = item.durationMinutes > 0 ? item.durationMinutes : 30
            return total + dur
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xl) {

                // 1. Hero Date & Day Architecture Banner
                heroDayBanner

                // 2. Metrics & Velocity KPI Grid
                metricsKpiGrid

                // 3. Dual Hub: Unscheduled Backlog & Active Focus Sprint
                HStack(alignment: .top, spacing: DS.Space.lg) {
                    unscheduledBacklogCard
                        .frame(maxWidth: .infinity)

                    focusSprintWidget
                        .frame(width: 280)
                }

                // 4. Today's Keystone Habits Strip
                todayHabitsStrip

                Spacer(minLength: DS.Space.xxl)
            }
            .padding(DS.Space.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Color.background)
        .onReceive(timer) { _ in
            guard isTimerRunning, let end = timerEndTimestamp else { return }
            let remaining = Int(ceil(end.timeIntervalSinceNow))
            if remaining <= 0 {
                focusTimeRemaining = 0
                isTimerRunning = false
                timerEndTimestamp = nil
                Haptics.notify(.success)
            } else {
                focusTimeRemaining = remaining
            }
        }
    }

    // MARK: - 1. Hero Day Banner

    private var heroDayBanner: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle().fill(DS.Color.success).frame(width: 7, height: 7)
                    Text("DAY ARCHITECTURE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                        .tracking(0.6)
                }

                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(DS.Color.textPrimary)

                Text("\"Action is the foundational key to all success.\"")
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundStyle(DS.Color.textSecondary)
            }

            Spacer()

            // Quick New Block Button
            Button {
                createNewBlock()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Plan New Block")
                }
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .foregroundStyle(.white)
                .background(DS.Color.active, in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(DS.Space.lg)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - 2. Metrics KPI Grid

    private var metricsKpiGrid: some View {
        HStack(spacing: DS.Space.md) {
            kpiCard(
                title: "PLANNED TIME",
                value: String(format: "%.1fh", Double(totalPlannedMinutes) / 60.0),
                subtitle: "\(scheduledToday.count) schedule blocks",
                icon: "clock.fill",
                color: DS.Color.active
            )

            kpiCard(
                title: "COMPLETION",
                value: "\(completedToday.count)/\(scheduledToday.count)",
                subtitle: scheduledToday.isEmpty ? "0% done" : "\(Int((Double(completedToday.count) / Double(scheduledToday.count)) * 100))% velocity",
                icon: "checkmark.circle.fill",
                color: DS.Color.success
            )

            kpiCard(
                title: "UNSCHEDULED",
                value: "\(unscheduledTasks.count)",
                subtitle: "Tasks in backlog",
                icon: "tray.full.fill",
                color: DS.Color.streak
            )
        }
    }

    private func kpiCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(0.5)

                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(DS.Color.textPrimary)

                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(DS.Color.textSecondary)
            }
            Spacer()
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - 3. Unscheduled Backlog Card

    private var unscheduledBacklogCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack {
                Text("UNSCHEDULED BACKLOG")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(0.6)

                Spacer()

                Text("\(unscheduledTasks.count) tasks")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(DS.Color.textSecondary)
            }

            if unscheduledTasks.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(DS.Color.success.opacity(0.7))
                    Text("All tasks scheduled or done!")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Space.xl)
            } else {
                VStack(spacing: 6) {
                    ForEach(unscheduledTasks.prefix(6)) { task in
                        Button {
                            selectedItem = task
                            Haptics.impact(.light)
                        } label: {
                            HStack(spacing: 8) {
                                Circle().stroke(DS.Color.border, lineWidth: 1.5).frame(width: 12, height: 12)
                                Text(task.title.isEmpty ? "Untitled Task" : task.title)
                                    .font(.system(size: 12))
                                    .foregroundStyle(DS.Color.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Text("Schedule →")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(DS.Color.active)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
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

    // MARK: - 4. Active Focus Sprint Widget

    private var focusSprintWidget: some View {
        VStack(spacing: DS.Space.md) {
            HStack {
                Text("FOCUS SPRINT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(0.6)
                Spacer()
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(DS.Color.streak)
            }

            // Timer Clock Face
            ZStack {
                Circle()
                    .stroke(DS.Color.surfaceRecessed, lineWidth: 6)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: Double(focusTimeRemaining) / (25 * 60))
                    .stroke(DS.Color.streak, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text(formattedTime(focusTimeRemaining))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text(isTimerRunning ? "Focusing" : "Paused")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            // Play / Pause / Reset Controls
            HStack(spacing: 12) {
                Button {
                    if isTimerRunning {
                        isTimerRunning = false
                        timerEndTimestamp = nil
                    } else {
                        isTimerRunning = true
                        timerEndTimestamp = Date().addingTimeInterval(Double(focusTimeRemaining))
                    }
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(DS.Color.streak, in: Circle())
                }
                .buttonStyle(.plain)

                Button {
                    focusTimeRemaining = 25 * 60
                    isTimerRunning = false
                    timerEndTimestamp = nil
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(DS.Color.surfaceRecessed, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DS.Space.lg)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - 5. Today's Keystone Habits Strip

    private var todayHabitsStrip: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack {
                Text("TODAY'S HABITS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(0.6)
                Spacer()
                Text("\(allHabits.count) active")
                    .font(.system(size: 10))
                    .foregroundStyle(DS.Color.textSecondary)
            }

            if allHabits.isEmpty {
                Text("No habits configured yet.")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            } else {
                HStack(spacing: 10) {
                    ForEach(allHabits.prefix(4)) { habit in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(ColorPalette[habit.colorIndex])
                                .frame(width: 10, height: 10)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(habit.name)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(DS.Color.textPrimary)
                                    .lineLimit(1)
                                Text("\(habit.currentStreak)d streak")
                                    .font(.system(size: 9))
                                    .foregroundStyle(DS.Color.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                    }
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

    // Helpers
    private func formattedTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func createNewBlock() {
        let now = Date.now
        let item = TodoItem(title: "New Block", startTime: now, durationMinutes: 30)
        modelContext.insert(item)
        try? modelContext.save()
        selectedItem = item
    }
}
