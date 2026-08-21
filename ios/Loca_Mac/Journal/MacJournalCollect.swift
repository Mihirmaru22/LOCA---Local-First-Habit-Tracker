import SwiftUI
import SwiftData

// MARK: - JournalDailyLayout

enum JournalDailyLayout: String, CaseIterable, Identifiable {
    case weeklyMatrix = "Weekly Horizon Matrix"
    case zenHeatmap   = "Zen Heatmap Grid"
    case daylightFlow = "Daylight Ritual Flow"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .weeklyMatrix: return "calendar.day.timeline.leading"
        case .zenHeatmap:   return "square.grid.3x3.square"
        case .daylightFlow: return "sun.and.horizon"
        }
    }
}

// MARK: - MacJournalCollect   (J2/J3/J4)

/// Unified Journal Collect page containing both Sleep Tracker and Daily Routines with Layout switcher.
struct MacJournalCollect: View {

    let selectedDate: Date

    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<HabitBoard> { $0.habitKindRaw == 1 },
           sort: \HabitBoard.createdAt)
    private var dailyHabitCandidates: [HabitBoard]
    private var dailyRoutines: [HabitBoard] { dailyHabitCandidates.filter { $0.archivedAt == nil } }

    @Query(sort: [SortDescriptor(\JournalNote.date, order: .reverse)])
    private var allJournalNotes: [JournalNote]

    @AppStorage("mac_journal_daily_layout_v2") private var dailyLayout: JournalDailyLayout = .weeklyMatrix
    @State private var newRoutineName = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xl) {

                // 1. HERO SLEEP SECTION (Top Priority)
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    sectionLabel("SLEEP TRACKER")
                    SleepCard(selectedDate: selectedDate)
                }

                // 2. DAILY ROUTINES SECTION (with Layout Menu Button)
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    HStack {
                        sectionLabel("DAILY ROUTINES")

                        Spacer()

                        // Layout Dropdown Menu
                        Menu {
                            Picker("Daily Layout", selection: $dailyLayout) {
                                ForEach(JournalDailyLayout.allCases) { l in
                                    Label(l.rawValue, systemImage: l.icon).tag(l)
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: dailyLayout.icon)
                                    .font(.system(size: 11))
                                Text(dailyLayout.rawValue)
                                    .font(.system(size: 11, weight: .medium))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 9))
                            }
                            .foregroundStyle(DS.Color.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                        }
                        .menuStyle(.borderlessButton)
                    }

                    switch dailyLayout {
                    case .weeklyMatrix:
                        DailyWeeklyMatrixContainer(
                            routines: dailyRoutines,
                            selectedDate: selectedDate,
                            newRoutineName: $newRoutineName,
                            isInputFocused: $isInputFocused,
                            onAdd: addRoutine
                        )
                    case .zenHeatmap:
                        DailyZenHeatmapContainer(
                            routines: dailyRoutines,
                            selectedDate: selectedDate,
                            newRoutineName: $newRoutineName,
                            isInputFocused: $isInputFocused,
                            onAdd: addRoutine
                        )
                    case .daylightFlow:
                        DailyDaylightFlowContainer(
                            routines: dailyRoutines,
                            selectedDate: selectedDate,
                            newRoutineName: $newRoutineName,
                            isInputFocused: $isInputFocused,
                            onAdd: addRoutine
                        )
                    }
                }

                // 3. APPLE INTELLIGENCE · 7-DAY EXECUTIVE BRIEF
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    sectionLabel("APPLE INTELLIGENCE · 7-DAY EXECUTIVE BRIEF")
                    executiveBriefCard
                }

                Spacer(minLength: DS.Space.xxxl)
            }
            .padding(.horizontal, DS.Space.lg)
            .padding(.vertical, DS.Space.lg)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(DS.Text.caption)
            .fontWeight(.semibold)
            .foregroundStyle(DS.Color.textTertiary)
            .tracking(0.8)
    }

    // MARK: - Executive Brief Card (On-Device Writing Tools)

    private var executiveBriefCard: some View {
        let brief = LocaNeuralEngine.generateExecutiveSummary(notes: allJournalNotes, periodLabel: "Past 7 Days")

        return VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.accentColor)

                    Text("COGNITIVE SUMMARY & MOMENTUM BRIEF")
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

            VStack(alignment: .leading, spacing: DS.Space.sm) {
                ForEach(brief.bulletPoints) { bullet in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: bullet.icon)
                            .font(.system(size: 12))
                            .foregroundStyle(bullet.color)
                            .frame(width: 20, height: 20)
                            .background(bullet.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(bullet.category)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(DS.Color.textPrimary)

                            Text(bullet.text)
                                .font(.system(size: 11))
                                .foregroundStyle(DS.Color.textSecondary)
                                .lineSpacing(2)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(DS.Space.md)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(Color.white.opacity(0.04))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 2)
    }

    private func addRoutine(name: String) {
        let text = name.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        withAnimation(DS.Motion.settle) {
            let habit = HabitBoard(name: text, colorIndex: 1)
            habit.habitKindRaw = 1 // Daily
            modelContext.insert(habit)
            try? modelContext.save()
            newRoutineName = ""
        }
        Haptics.impact(.light)
    }
}

// MARK: - DailyWeeklyMatrixContainer (7-Day Horizon Matrix with Red X for Missed Past Days)

struct DailyWeeklyMatrixContainer: View {

    let routines: [HabitBoard]
    let selectedDate: Date
    @Binding var newRoutineName: String
    var isInputFocused: FocusState<Bool>.Binding
    let onAdd: (String) -> Void

    private var weekDays: [Date] {
        let cal = Calendar.current
        var comp = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)
        comp.weekday = 2 // Monday start
        guard let monday = cal.date(from: comp) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    var body: some View {
        VStack(spacing: 0) {

            // Header Strip with Day Names (M T W T F S S)
            HStack {
                Text("ROUTINE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(0.6)

                Spacer()

                HStack(spacing: 8) {
                    ForEach(weekDays, id: \.self) { day in
                        let isSelectedDay = Calendar.current.isDate(day, inSameDayAs: selectedDate)
                        Text(formatDayLetter(day))
                            .font(.system(size: 10, weight: isSelectedDay ? .bold : .medium))
                            .foregroundStyle(isSelectedDay ? Color.accentColor : DS.Color.textTertiary)
                            .frame(width: 20)
                    }
                }
            }
            .padding(.horizontal, DS.Space.lg)
            .padding(.vertical, DS.Space.sm)
            .background(DS.Color.surfaceRecessed)

            Divider()

            // Routine Matrix Rows
            if routines.isEmpty {
                VStack(spacing: 6) {
                    Text("No permanent routines yet")
                        .font(DS.Text.body)
                        .foregroundStyle(DS.Color.textSecondary)
                    Text("Add your recurring daily habits below to track your 7-day consistency")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Space.xl)
            } else {
                ForEach(routines) { routine in
                    WeeklyMatrixRow(
                        routine: routine,
                        selectedDate: selectedDate,
                        weekDays: weekDays
                    )
                    Divider().padding(.leading, DS.Space.lg)
                }
            }

            // Bottom Add Routine Input Row
            HStack(spacing: DS.Space.md) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)

                TextField("Add permanent recurring routine…", text: $newRoutineName)
                    .font(DS.Text.body)
                    .textFieldStyle(.plain)
                    .focused(isInputFocused)
                    .onSubmit { onAdd(newRoutineName) }

                Spacer()

                Button {
                    onAdd(newRoutineName)
                } label: {
                    Text("Add")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(newRoutineName.trimmingCharacters(in: .whitespaces).isEmpty ? DS.Color.textTertiary : Color.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            newRoutineName.trimmingCharacters(in: .whitespaces).isEmpty ? DS.Color.surfaceRecessed : Color.accentColor,
                            in: RoundedRectangle(cornerRadius: 4)
                        )
                }
                .buttonStyle(.plain)
                .disabled(newRoutineName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, DS.Space.lg)
            .padding(.vertical, DS.Space.md)
            .background(Color.white.opacity(0.03))
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(Color.white.opacity(0.04))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 2)
    }

    private func formatDayLetter(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEEE" // Single letter: M, T, W, T, F, S, S
        return f.string(from: date)
    }
}

// MARK: - WeeklyMatrixRow (Productivity-focused: Subtle – for missed, Crisp ✓ for done)

struct WeeklyMatrixRow: View {

    @Bindable var routine: HabitBoard
    let selectedDate: Date
    let weekDays: [Date]
    @Environment(\.modelContext) private var modelContext
    @State private var isHovered = false

    private static let greenCheck = Color(red: 0.18, green: 0.72, blue: 0.42)

    var body: some View {
        HStack(spacing: DS.Space.md) {

            // Routine Title
            Text(routine.name.isEmpty ? "Untitled routine" : routine.name)
                .font(DS.Text.body)
                .foregroundStyle(DS.Color.textPrimary)

            Spacer()

            // Streak Pill (Clean Muted Badge)
            if routine.currentStreak > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(DS.Color.textSecondary)
                    Text("\(routine.currentStreak)d")
                        .font(.system(size: 10, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.textSecondary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(DS.Color.surfaceRecessed, in: Capsule())
            }

            // Hover Delete Action
            if isHovered {
                Button {
                    withAnimation(DS.Motion.settle) {
                        routine.archivedAt = Date()
                        try? modelContext.save()
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textTertiary)
                }
                .buttonStyle(.plain)
                .help("Delete routine")
            }

            // 7-Day Matrix Strip
            HStack(spacing: 8) {
                ForEach(weekDays, id: \.self) { day in
                    cellForDay(day)
                }
            }
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.md)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }

    @ViewBuilder
    private func cellForDay(_ day: Date) -> some View {
        let cal = Calendar.current
        let isDone = isDayCompleted(day)
        let isToday = cal.isDate(day, inSameDayAs: selectedDate)
        let isPast = cal.startOfDay(for: day) < cal.startOfDay(for: selectedDate)

        Button {
            withAnimation(DS.Motion.settle) {
                try? CheckInWriter.toggleBinary(board: routine, date: day, context: modelContext)
            }
            Haptics.impact(.light)
        } label: {
            ZStack {
                if isDone {
                    // Completed: Clean emerald square with white checkmark
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Self.greenCheck)
                        .frame(width: 20, height: 20)

                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                } else if isPast {
                    // Past Missed Day: Subtle, calm recessed dash (no aggressive red clutter)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.Color.surfaceRecessed.opacity(0.7))
                        .frame(width: 20, height: 20)

                    Text("–")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                } else if isToday {
                    // Today pending: Clean interactive outlined box
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.Color.surfaceRecessed)
                        .frame(width: 20, height: 20)

                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(DS.Color.border.opacity(0.9), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                } else {
                    // Future day: Recessed placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.Color.surfaceRecessed.opacity(0.3))
                        .frame(width: 20, height: 20)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func isDayCompleted(_ date: Date) -> Bool {
        let cal = Calendar.current
        let target = routine.effectiveTarget
        let logs = routine.activeLogs.filter { cal.isDate($0.timestamp, inSameDayAs: date) }
        return logs.reduce(0.0) { $0 + $1.value } >= target
    }
}

// MARK: - DailyZenHeatmapContainer

struct DailyZenHeatmapContainer: View {

    let routines: [HabitBoard]
    let selectedDate: Date
    @Binding var newRoutineName: String
    var isInputFocused: FocusState<Bool>.Binding
    let onAdd: (String) -> Void

    private var completedCount: Int {
        let cal = Calendar.current
        return routines.filter { habit in
            let logs = habit.activeLogs.filter { cal.isDate($0.timestamp, inSameDayAs: selectedDate) }
            return logs.reduce(0.0) { $0 + $1.value } >= habit.effectiveTarget
        }.count
    }

    private var progressFraction: Double {
        guard !routines.isEmpty else { return 0 }
        return Double(completedCount) / Double(routines.count)
    }

    var body: some View {
        VStack(spacing: DS.Space.md) {
            // Progress Bar
            if !routines.isEmpty {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(completedCount == routines.count ? Color(red: 0.18, green: 0.80, blue: 0.44) : Color.accentColor)
                            .frame(width: 6, height: 6)
                        Text("\(completedCount) of \(routines.count) completed")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(DS.Color.textPrimary)
                    }

                    Spacer()

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(DS.Color.surfaceRecessed)
                            .frame(width: 80, height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.18, green: 0.80, blue: 0.44), Color.cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, 80 * CGFloat(progressFraction)), height: 6)
                    }

                    Text("\(Int(progressFraction * 100))%")
                        .font(.system(size: 12, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(Color(red: 0.18, green: 0.80, blue: 0.44))
                }
                .padding(.horizontal, DS.Space.lg)
                .padding(.vertical, DS.Space.md)
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            }

            // Routine Rows
            VStack(spacing: 0) {
                ForEach(routines) { routine in
                    ZenHeatmapRow(routine: routine, selectedDate: selectedDate)
                    Divider().padding(.leading, DS.Space.lg)
                }

                // Add Input
                HStack(spacing: DS.Space.md) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)

                    TextField("Add a daily routine…", text: $newRoutineName)
                        .font(DS.Text.body)
                        .textFieldStyle(.plain)
                        .focused(isInputFocused)
                        .onSubmit { onAdd(newRoutineName) }

                    Spacer()

                    Button { onAdd(newRoutineName) } label: {
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(DS.Color.border.opacity(0.8), lineWidth: 1.5)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .disabled(newRoutineName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, DS.Space.lg)
                .padding(.vertical, DS.Space.md)
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: DS.Radius.card)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: DS.Radius.card)
                        .fill(Color.white.opacity(0.04))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 2)
        }
    }
}

struct ZenHeatmapRow: View {
    @Bindable var routine: HabitBoard
    let selectedDate: Date
    @Environment(\.modelContext) private var modelContext
    @State private var isHovered = false

    private static let heatmapGreen = Color(red: 0.18, green: 0.80, blue: 0.44)

    private var isChecked: Bool {
        let cal = Calendar.current
        let target = routine.effectiveTarget
        let logs = routine.activeLogs.filter { cal.isDate($0.timestamp, inSameDayAs: selectedDate) }
        return logs.reduce(0.0) { $0 + $1.value } >= target
    }

    var body: some View {
        HStack(spacing: DS.Space.md) {
            Text(routine.name.isEmpty ? "Untitled routine" : routine.name)
                .font(DS.Text.body)
                .foregroundStyle(isChecked ? DS.Color.textTertiary : DS.Color.textPrimary)
                .strikethrough(isChecked, color: DS.Color.textTertiary)

            Spacer()

            if routine.currentStreak > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    Text("\(routine.currentStreak)d")
                        .font(.system(size: 10, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.12), in: Capsule())
            }

            if isHovered {
                Button {
                    withAnimation(DS.Motion.settle) {
                        routine.archivedAt = Date()
                        try? modelContext.save()
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textTertiary)
                }
                .buttonStyle(.plain)
            }

            Button {
                withAnimation(DS.Motion.settle) {
                    try? CheckInWriter.toggleBinary(board: routine, date: selectedDate, context: modelContext)
                }
                Haptics.impact(.light)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isChecked ? Self.heatmapGreen : SwiftUI.Color.clear)
                        .frame(width: 22, height: 22)

                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(isChecked ? Self.heatmapGreen : DS.Color.border, lineWidth: 1.5)
                        .frame(width: 22, height: 22)

                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.md)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}

// MARK: - DailyDaylightFlowContainer

struct DailyDaylightFlowContainer: View {

    let routines: [HabitBoard]
    let selectedDate: Date
    @Binding var newRoutineName: String
    var isInputFocused: FocusState<Bool>.Binding
    let onAdd: (String) -> Void

    private var morningRoutines: [HabitBoard] {
        guard !routines.isEmpty else { return [] }
        let split = (routines.count + 1) / 2
        return Array(routines.prefix(split))
    }

    private var eveningRoutines: [HabitBoard] {
        guard routines.count > 1 else { return [] }
        let split = (routines.count + 1) / 2
        return Array(routines.dropFirst(split))
    }

    var body: some View {
        VStack(spacing: DS.Space.lg) {
            phaseCard(
                title: "MORNING RITUALS",
                icon: "sun.horizon.fill",
                color: Color(red: 0.98, green: 0.65, blue: 0.20),
                routines: morningRoutines
            )

            phaseCard(
                title: "EVENING WIND-DOWN",
                icon: "moon.stars.fill",
                color: Color(red: 0.45, green: 0.42, blue: 0.98),
                routines: eveningRoutines
            )

            HStack(spacing: DS.Space.md) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)

                TextField("Add new routine to daylight flow…", text: $newRoutineName)
                    .font(DS.Text.body)
                    .textFieldStyle(.plain)
                    .focused(isInputFocused)
                    .onSubmit { onAdd(newRoutineName) }

                Spacer()
            }
            .padding(.horizontal, DS.Space.lg)
            .padding(.vertical, DS.Space.md)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        }
    }

    private func phaseCard(title: String, icon: String, color: Color, routines: [HabitBoard]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(color)

                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color)
                    .tracking(0.7)

                Spacer()

                let comp = completedCount(for: routines)
                Text("\(comp)/\(routines.count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(comp == routines.count && !routines.isEmpty ? Color(red: 0.18, green: 0.80, blue: 0.44) : DS.Color.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.12), in: Capsule())
            }
            .padding(.horizontal, DS.Space.lg)
            .padding(.vertical, DS.Space.sm)
            .background(color.opacity(0.06))

            Divider()

            if routines.isEmpty {
                Text("No routines assigned yet")
                    .font(DS.Text.footnote)
                    .foregroundStyle(DS.Color.textTertiary)
                    .padding(DS.Space.lg)
            } else {
                ForEach(routines) { routine in
                    ZenHeatmapRow(routine: routine, selectedDate: selectedDate)
                    if routine.id != routines.last?.id {
                        Divider().padding(.leading, DS.Space.lg)
                    }
                }
            }
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(Color.white.opacity(0.04))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.35), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 2)
    }

    private func completedCount(for list: [HabitBoard]) -> Int {
        let cal = Calendar.current
        return list.filter { habit in
            let logs = habit.activeLogs.filter { cal.isDate($0.timestamp, inSameDayAs: selectedDate) }
            return logs.reduce(0.0) { $0 + $1.value } >= habit.effectiveTarget
        }.count
    }
}

// MARK: - SleepCard Section (Hero Timeline Horizon)

struct SleepCard: View {

    let selectedDate: Date

    @Query(sort: [SortDescriptor(\SleepEntry.date, order: .reverse)])
    private var allEntries: [SleepEntry]

    @Environment(\.modelContext) private var modelContext

    @State private var bedtime: Date = SleepCard.defaultBedtime(for: Date())
    @State private var wakeTime: Date = SleepCard.defaultWakeTime(for: Date())
    @State private var isSyncing: Bool = false

    private var dateEntry: SleepEntry? {
        let cal = Calendar.current
        return allEntries.first { cal.isDate($0.date, inSameDayAs: selectedDate) && !$0.isArchived }
    }

    private static func defaultBedtime(for base: Date) -> Date {
        let cal = Calendar.current
        return cal.date(bySettingHour: 23, minute: 0, second: 0, of: base) ?? base
    }

    private static func defaultWakeTime(for base: Date) -> Date {
        let cal = Calendar.current
        let startNight = defaultBedtime(for: base)
        return cal.date(byAdding: .minute, value: Int(8.5 * 60), to: startNight) ?? base
    }

    private var computedHours: Double {
        SleepEntry.computeSleepHours(bedtime: bedtime, wakeTime: wakeTime)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {

            // Spacious Hero Timeline Horizon
            SleepTimelineHorizonView(
                selectedDate: selectedDate,
                bedtime: $bedtime,
                wakeTime: $wakeTime,
                hours: computedHours,
                onTimeChanged: save,
                onPreset: { hrs in
                    let cal = Calendar.current
                    if let newWake = cal.date(byAdding: .minute, value: Int(hrs * 60), to: bedtime) {
                        wakeTime = newWake
                        save()
                    }
                }
            )

            // Clear button if entry exists
            if dateEntry != nil {
                HStack {
                    Spacer()
                    Button(action: clearSleep) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.caption2)
                            Text("Clear log")
                                .font(DS.Text.footnote)
                        }
                        .foregroundStyle(DS.Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
            }
        }
        .onAppear { syncFromEntry() }
        .onChange(of: selectedDate) { _, _ in syncFromEntry() }
    }

    private func syncFromEntry() {
        isSyncing = true
        if let e = dateEntry {
            if let bt = e.bedtime  { bedtime  = bt }
            if let wt = e.wakeTime { wakeTime = wt }
        } else {
            bedtime  = SleepCard.defaultBedtime(for: selectedDate)
            wakeTime = SleepCard.defaultWakeTime(for: selectedDate)
        }
        DispatchQueue.main.async {
            isSyncing = false
        }
    }

    private func save() {
        guard !isSyncing else { return }
        let hours = computedHours
        if let existing = dateEntry {
            existing.sleepHours   = hours
            existing.inputModeRaw = SleepEntry.SleepInputMode.bedtimeWake.rawValue
            existing.bedtime      = bedtime
            existing.wakeTime     = wakeTime
        } else {
            let entry = SleepEntry(
                date: selectedDate,
                sleepHours: hours,
                inputMode: .bedtimeWake,
                bedtime: bedtime,
                wakeTime: wakeTime
            )
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }

    private func clearSleep() {
        if let existing = dateEntry {
            existing.archivedAt = Date()
            try? modelContext.save()
            syncFromEntry()
        }
    }
}

// MARK: - Timeline Horizon View (9 PM to 12 PM Next Day)

private struct SleepTimelineHorizonView: View {

    let selectedDate: Date
    @Binding var bedtime: Date
    @Binding var wakeTime: Date
    let hours: Double
    let onTimeChanged: () -> Void
    let onPreset: (Double) -> Void

    @State private var showBedtimePopover = false
    @State private var showWakePopover = false

    private enum DragTarget {
        case bedtime
        case wakeTime
        case span
        case none
    }
    @State private var activeDragTarget: DragTarget = .none
    @State private var dragInitialBedtime: Date?
    @State private var dragInitialWakeTime: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {

            // Top Header: Spacious Time Badges & Duration Readout
            HStack(alignment: .center, spacing: DS.Space.md) {

                // 🌙 Bedtime Card (Sleep at Night / PM)
                timeBadge(
                    title: "BEDTIME (NIGHT)",
                    time: bedtime,
                    icon: "moon.stars.fill",
                    showPopover: $showBedtimePopover,
                    binding: $bedtime,
                    onStep: { mins in
                        let cal = Calendar.current
                        if let d = cal.date(byAdding: .minute, value: mins, to: bedtime) {
                            if d < wakeTime {
                                bedtime = d
                                onTimeChanged()
                            }
                        }
                    }
                )

                // Connector
                VStack(spacing: 2) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                    Text("\(max(1, Int(round(hours / 1.5)))) cyc")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                }

                // ☀️ Wake Up Card (Wake in Morning / AM)
                timeBadge(
                    title: "WAKE UP (MORNING)",
                    time: wakeTime,
                    icon: "sun.max.fill",
                    showPopover: $showWakePopover,
                    binding: $wakeTime,
                    onStep: { mins in
                        let cal = Calendar.current
                        if let d = cal.date(byAdding: .minute, value: mins, to: wakeTime) {
                            if d > bedtime {
                                wakeTime = d
                                onTimeChanged()
                            }
                        }
                    }
                )

                Spacer(minLength: 12)

                // Hero Total Sleep Stat (Clean High-Contrast White)
                HStack(spacing: 8) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatHours(hours))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(DS.Color.textPrimary)
                            .lineLimit(1)
                            .fixedSize()

                        Text(hours >= 7.5 ? "Restful · 8h goal" : "\(Int(min(100, (hours / 8.0) * 100)))% of goal")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 8))
            }

            // Spacious Nocturnal Timeline Track (9 PM to 12 PM - 15 Hours)
            GeometryReader { proxy in
                let totalWidth = proxy.size.width
                let bedHoursFrom9PM = dateToTimelineHours(bedtime)
                let wakeHoursFrom9PM = dateToTimelineHours(wakeTime)

                let bedOffset = max(0, min(totalWidth - 28, (bedHoursFrom9PM / 15.0) * totalWidth))
                let wakeOffset = max(bedOffset + 20, min(totalWidth, (wakeHoursFrom9PM / 15.0) * totalWidth))
                let spanWidth = max(24, wakeOffset - bedOffset)

                ZStack(alignment: .leading) {

                    // Base 15h Track (Deep Neutral Slate)
                    RoundedRectangle(cornerRadius: 9)
                        .fill(DS.Color.surfaceRecessed)
                        .frame(height: 28)

                    // Focused Sleep Duration Span (Muted Graphite/Slate)
                    RoundedRectangle(cornerRadius: 9)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.28, green: 0.32, blue: 0.42),
                                    Color(red: 0.32, green: 0.36, blue: 0.48)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: spanWidth, height: 28)
                        .offset(x: bedOffset)

                    // 🌙 Bedtime Handle Pin (Left - Night PM)
                    ZStack {
                        Circle()
                            .fill(Color(white: 0.90))
                            .frame(width: 20, height: 20)
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                        Circle()
                            .fill(Color(white: 0.18))
                            .frame(width: 14, height: 14)
                        Image(systemName: "moon.fill")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(Color(white: 0.90))
                    }
                    .offset(x: max(0, bedOffset - 10))

                    // ☀️ Wake Handle Pin (Right - Morning AM)
                    ZStack {
                        Circle()
                            .fill(Color(white: 0.90))
                            .frame(width: 20, height: 20)
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                        Circle()
                            .fill(Color(white: 0.18))
                            .frame(width: 14, height: 14)
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(Color(white: 0.90))
                    }
                    .offset(x: min(totalWidth - 20, wakeOffset - 10))

                    // Time Markers along the 15h Window
                    HStack {
                        Text("9 PM").font(.system(size: 8, weight: .bold)).foregroundStyle(DS.Color.textTertiary)
                        Spacer()
                        Text("12 AM").font(.system(size: 8, weight: .bold)).foregroundStyle(DS.Color.textTertiary)
                        Spacer()
                        Text("3 AM").font(.system(size: 8, weight: .bold)).foregroundStyle(DS.Color.textTertiary)
                        Spacer()
                        Text("6 AM").font(.system(size: 8, weight: .bold)).foregroundStyle(DS.Color.textTertiary)
                        Spacer()
                        Text("9 AM").font(.system(size: 8, weight: .bold)).foregroundStyle(DS.Color.textTertiary)
                        Spacer()
                        Text("12 PM").font(.system(size: 8, weight: .bold)).foregroundStyle(DS.Color.textTertiary)
                    }
                    .padding(.horizontal, 8)
                    .allowsHitTesting(false)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleDragChanged(value: value, totalWidth: totalWidth, bedOffset: bedOffset, wakeOffset: wakeOffset)
                        }
                        .onEnded { _ in
                            activeDragTarget = .none
                            dragInitialBedtime = nil
                            dragInitialWakeTime = nil
                            onTimeChanged()
                        }
                )
            }
            .frame(height: 28)

            // Preset Chips & Quick Resets
            HStack(spacing: 8) {
                Text("Presets:")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(DS.Color.textTertiary)

                ForEach([6.0, 7.0, 7.5, 8.0, 8.5, 9.0], id: \.self) { preset in
                    let isSelected = abs(hours - preset) < 0.1
                    Button {
                        withAnimation(DS.Motion.settle) {
                            onPreset(preset)
                        }
                        Haptics.impact(.light)
                    } label: {
                        Text("\(preset == Double(Int(preset)) ? "\(Int(preset))" : String(format: "%.1f", preset))h")
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? Color.black : DS.Color.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                isSelected ? Color.white : DS.Color.surfaceRecessed,
                                in: RoundedRectangle(cornerRadius: 6)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isSelected ? Color.white : DS.Color.border.opacity(0.4), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Standard Recommended Reset (11:00 PM – 7:30 AM)
                Button {
                    withAnimation(DS.Motion.settle) {
                        let cal = Calendar.current
                        let startNight = cal.date(bySettingHour: 23, minute: 0, second: 0, of: selectedDate) ?? selectedDate
                        let morning = cal.date(byAdding: .minute, value: Int(8.5 * 60), to: startNight) ?? selectedDate

                        bedtime = startNight
                        wakeTime = morning
                        onTimeChanged()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text("11PM - 7:30AM (Standard)")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DS.Color.surfaceRecessed, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DS.Space.lg)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(Color.white.opacity(0.04))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 2)
    }

    // MARK: - Time Badge with Popover & Inline Steppers

    private func timeBadge(
        title: String,
        time: Date,
        icon: String,
        showPopover: Binding<Bool>,
        binding: Binding<Date>,
        onStep: @escaping (Int) -> Void
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(DS.Color.textSecondary)
                .frame(width: 26, height: 26)
                .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .lineLimit(1)

                Button {
                    showPopover.wrappedValue.toggle()
                } label: {
                    Text(formatTime(time))
                        .font(.system(size: 14, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.textPrimary)
                        .lineLimit(1)
                        .fixedSize()
                }
                .buttonStyle(.plain)
                .popover(isPresented: showPopover) {
                    VStack(spacing: 8) {
                        DatePicker("", selection: binding, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .onChange(of: binding.wrappedValue) { _, _ in
                                onTimeChanged()
                            }
                    }
                    .padding(DS.Space.md)
                }
            }

            VStack(spacing: 2) {
                Button { onStep(15) } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(width: 16, height: 12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Add 15m")

                Button { onStep(-15) } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(width: 16, height: 12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Subtract 15m")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Drag Gesture Logic (Strict Bedtime PM < Wake AM Invariant)

    private func handleDragChanged(value: DragGesture.Value, totalWidth: CGFloat, bedOffset: CGFloat, wakeOffset: CGFloat) {
        let currentX = value.location.x

        if activeDragTarget == .none {
            dragInitialBedtime = bedtime
            dragInitialWakeTime = wakeTime

            let distToBed = abs(currentX - bedOffset)
            let distToWake = abs(currentX - wakeOffset)

            if distToBed < 28 {
                activeDragTarget = .bedtime
            } else if distToWake < 28 {
                activeDragTarget = .wakeTime
            } else if currentX > min(bedOffset, wakeOffset) && currentX < max(bedOffset, wakeOffset) {
                activeDragTarget = .span
            } else {
                if distToBed < distToWake {
                    activeDragTarget = .bedtime
                } else {
                    activeDragTarget = .wakeTime
                }
            }
        }

        let fraction = max(0, min(1.0, currentX / totalWidth))
        let targetHoursFrom9PM = fraction * 15.0

        let currentBedHours = dateToTimelineHours(bedtime)
        let currentWakeHours = dateToTimelineHours(wakeTime)

        switch activeDragTarget {
        case .bedtime:
            let clampedTarget = min(currentWakeHours - 0.5, targetHoursFrom9PM)
            bedtime = timelineHoursToDate(hoursFrom9PM: clampedTarget, forDate: selectedDate)
        case .wakeTime:
            let clampedTarget = max(currentBedHours + 0.5, targetHoursFrom9PM)
            wakeTime = timelineHoursToDate(hoursFrom9PM: clampedTarget, forDate: selectedDate)
        case .span:
            guard let initBed = dragInitialBedtime, let initWake = dragInitialWakeTime else { return }
            let deltaFraction = value.translation.width / totalWidth
            let deltaMinutes = Int(round(deltaFraction * 15.0 * 60.0 / 15.0)) * 15
            if deltaMinutes != 0 {
                let cal = Calendar.current
                if let newBed = cal.date(byAdding: .minute, value: deltaMinutes, to: initBed),
                   let newWake = cal.date(byAdding: .minute, value: deltaMinutes, to: initWake) {
                    let newBedH = dateToTimelineHours(newBed)
                    let newWakeH = dateToTimelineHours(newWake)
                    if newBedH >= 0.0 && newWakeH <= 15.0 && newBedH < newWakeH {
                        bedtime = newBed
                        wakeTime = newWake
                    }
                }
            }
        case .none:
            break
        }
    }

    private func dateToTimelineHours(_ date: Date) -> Double {
        let cal = Calendar.current
        let h = Double(cal.component(.hour, from: date))
        let m = Double(cal.component(.minute, from: date))
        let timeOfDay = h + m / 60.0

        if timeOfDay >= 21.0 {
            return timeOfDay - 21.0
        } else if timeOfDay <= 12.0 {
            return 3.0 + timeOfDay
        } else {
            return (timeOfDay < 16.5) ? 15.0 : 0.0
        }
    }

    private func timelineHoursToDate(hoursFrom9PM: Double, forDate: Date) -> Date {
        let clamped = max(0.0, min(15.0, hoursFrom9PM))
        let snappedHours = round(clamped * 4.0) / 4.0
        let totalMinutes = Int(round(snappedHours * 60.0))

        let cal = Calendar.current
        let startOfNight = cal.date(bySettingHour: 21, minute: 0, second: 0, of: forDate) ?? forDate
        return cal.date(byAdding: .minute, value: totalMinutes, to: startOfNight) ?? forDate
    }

    private func formatTime(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: d)
    }

    private func formatHours(_ h: Double) -> String {
        let hrs = Int(h)
        let mins = Int(round((h - Double(hrs)) * 60))
        return mins == 0 ? "\(hrs)h" : "\(hrs)h \(mins)m"
    }
}

// MARK: - Design 3: Circular Sleep Dial Variant (Compact & Non-Wrapping)

private struct SleepDialVariant: View {

    @Binding var bedtime: Date
    @Binding var wakeTime: Date
    let hours: Double
    let onTimeChanged: () -> Void

    var body: some View {
        HStack(spacing: 10) {

            // Mini Dial
            ZStack {
                Circle()
                    .stroke(DS.Color.surfaceRecessed, lineWidth: 4.5)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0.05, to: 0.05 + CGFloat(min(0.90, hours / 24.0)))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [Color.indigo, Color.cyan, Color.orange]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                    )
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .animation(DS.Motion.settle, value: hours)

                Image(systemName: "moon.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.indigo)
            }
            .frame(width: 44, height: 44)

            // Time Chips
            HStack(spacing: 8) {
                timeChip(title: "BED", time: bedtime, icon: "moon.fill", color: .indigo) {
                    if let d = Calendar.current.date(byAdding: .minute, value: -15, to: bedtime) {
                        bedtime = d; onTimeChanged()
                    }
                } onPlus: {
                    if let d = Calendar.current.date(byAdding: .minute, value: 15, to: bedtime) {
                        bedtime = d; onTimeChanged()
                    }
                }

                timeChip(title: "WAKE", time: wakeTime, icon: "sun.max.fill", color: .orange) {
                    if let d = Calendar.current.date(byAdding: .minute, value: -15, to: wakeTime) {
                        wakeTime = d; onTimeChanged()
                    }
                } onPlus: {
                    if let d = Calendar.current.date(byAdding: .minute, value: 15, to: wakeTime) {
                        wakeTime = d; onTimeChanged()
                    }
                }
            }

            Spacer(minLength: 4)

            // Stat Pill
            VStack(alignment: .trailing, spacing: 1) {
                Text(formatHours(hours))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.cyan)
                    .lineLimit(1)
                    .fixedSize()

                Text(hours >= 7.0 ? "Optimal rest" : "Short rest")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(DS.Color.textTertiary)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .padding(DS.Space.sm)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(Color.white.opacity(0.04))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func timeChip(
        title: String,
        time: Date,
        icon: String,
        color: Color,
        onMinus: @escaping () -> Void,
        onPlus: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .lineLimit(1)
                Text(formatTime(time))
                    .font(.system(size: 11, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(1)
                    .fixedSize()
            }

            HStack(spacing: 1) {
                Button(action: onMinus) {
                    Image(systemName: "minus")
                        .font(.system(size: 7, weight: .bold))
                        .frame(width: 12, height: 12)
                        .foregroundStyle(DS.Color.textSecondary)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: onPlus) {
                    Image(systemName: "plus")
                        .font(.system(size: 7, weight: .bold))
                        .frame(width: 12, height: 12)
                        .foregroundStyle(DS.Color.textSecondary)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
    }

    private func formatTime(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: d)
    }

    private func formatHours(_ h: Double) -> String {
        let hrs = Int(h)
        let mins = Int(round((h - Double(hrs)) * 60))
        return mins == 0 ? "\(hrs)h" : "\(hrs)h \(mins)m"
    }
}
