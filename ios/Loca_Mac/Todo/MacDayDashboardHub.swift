import SwiftUI
import SwiftData
import Combine

// MARK: - MacDayDashboardHub (100% Apple Liquid Glass Day Architecture Hub)

/// Shown in the right detail column of Plan mode when no specific task is selected.
/// Replaces empty dark voids with a high-density, multi-layered Liquid Glass executive command center.
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
        .background(
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.38),
                        Color(nsColor: NSColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 0.85))
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
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

    // MARK: - 1. Hero Day Banner (Liquid Glass)

    private var heroDayBanner: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(red: 0.95, green: 0.75, blue: 0.25))
                        .frame(width: 7, height: 7)
                        .shadow(color: Color.orange.opacity(0.6), radius: 3)

                    Text("DAY ARCHITECTURE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.95, green: 0.75, blue: 0.25))
                        .tracking(0.8)
                }

                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.white)

                Text("\"Action is the foundational key to all success.\"")
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundStyle(Color.white.opacity(0.60))
            }

            Spacer()

            // Quick New Block Button (Glass Action Capsule)
            Button {
                createNewBlock()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Plan New Block")
                }
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(Color.white)
                .background(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.85),
                            Color.accentColor.opacity(0.65)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: Color.accentColor.opacity(0.35), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(DS.Space.lg)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.04))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.20), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 2)
    }

    // MARK: - 2. Metrics KPI Grid (Glass Cards)

    private var metricsKpiGrid: some View {
        HStack(spacing: DS.Space.md) {
            kpiCard(
                title: "PLANNED TIME",
                value: String(format: "%.1fh", Double(totalPlannedMinutes) / 60.0),
                subtitle: "\(scheduledToday.count) schedule blocks",
                icon: "clock.fill",
                color: Color(red: 0.95, green: 0.75, blue: 0.25)
            )

            kpiCard(
                title: "COMPLETION",
                value: "\(completedToday.count)/\(scheduledToday.count)",
                subtitle: scheduledToday.isEmpty ? "0% done" : "\(Int((Double(completedToday.count) / Double(scheduledToday.count)) * 100))% velocity",
                icon: "checkmark.circle.fill",
                color: Color(red: 0.35, green: 0.85, blue: 0.55)
            )

            kpiCard(
                title: "UNSCHEDULED",
                value: "\(unscheduledTasks.count)",
                subtitle: "Tasks in backlog",
                icon: "tray.full.fill",
                color: Color(red: 0.35, green: 0.65, blue: 0.95)
            )
        }
    }

    private func kpiCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.16))
                    .frame(width: 38, height: 38)

                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.50))
                    .tracking(0.6)

                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.white)

                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.60))
            }
            Spacer()
        }
        .padding(DS.Space.md)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.04))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.20), radius: 6, x: 0, y: 2)
    }

    // MARK: - 3. Unscheduled Backlog Card (Liquid Glass)

    private var unscheduledBacklogCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack {
                Text("UNSCHEDULED BACKLOG")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .tracking(0.6)

                Spacer()

                Text("\(unscheduledTasks.count) tasks")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.70))
            }

            if unscheduledTasks.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color(red: 0.35, green: 0.85, blue: 0.55).opacity(0.85))
                    Text("All tasks scheduled or done!")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.60))
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
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                    .frame(width: 12, height: 12)

                                Text(task.title.isEmpty ? "Untitled Task" : task.title)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.90))
                                    .lineLimit(1)

                                Spacer()

                                Text("Schedule →")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.accentColor)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 7))
                            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(DS.Space.lg)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.04))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.20), radius: 6, x: 0, y: 2)
    }

    // MARK: - 4. Active Focus Sprint Widget (Liquid Glass Dial)

    private var focusSprintWidget: some View {
        VStack(spacing: DS.Space.md) {
            HStack {
                Text("FOCUS SPRINT")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .tracking(0.6)
                Spacer()
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.orange)
            }

            // Timer Clock Face with Refractive Ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 6)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: Double(focusTimeRemaining) / (25 * 60))
                    .stroke(
                        LinearGradient(
                            colors: [Color.orange, Color.yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color.orange.opacity(0.4), radius: 4)

                VStack(spacing: 2) {
                    Text(formattedTime(focusTimeRemaining))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white)
                    Text(isTimerRunning ? "Focusing" : "Paused")
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.60))
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
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            in: Circle()
                        )
                        .shadow(color: Color.orange.opacity(0.4), radius: 4)
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
                        .foregroundStyle(Color.white.opacity(0.70))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08), in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DS.Space.lg)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.04))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.20), radius: 6, x: 0, y: 2)
    }

    // MARK: - 5. Today's Keystone Habits Strip (Liquid Glass)

    private var todayHabitsStrip: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack {
                Text("TODAY'S HABITS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .tracking(0.6)
                Spacer()
                Text("\(allHabits.count) active")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.65))
            }

            if allHabits.isEmpty {
                Text("No habits configured yet.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.40))
            } else {
                HStack(spacing: 10) {
                    ForEach(allHabits.prefix(4)) { habit in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(ColorPalette[habit.colorIndex])
                                .frame(width: 10, height: 10)
                                .shadow(color: ColorPalette[habit.colorIndex].opacity(0.6), radius: 3)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(habit.name)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color.white.opacity(0.90))
                                    .lineLimit(1)
                                Text("\(habit.currentStreak)d streak")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.white.opacity(0.50))
                            }
                            Spacer()
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }
                }
            }
        }
        .padding(DS.Space.lg)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.04))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.20), radius: 6, x: 0, y: 2)
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
