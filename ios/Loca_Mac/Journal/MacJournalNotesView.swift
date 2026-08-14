import SwiftUI
import SwiftData

// MARK: - DailyDesignVariant

enum DailyDesignVariant: String, CaseIterable, Identifiable {
    case showAll  = "Show All 3"
    case daily1   = "Daily 1"
    case daily2   = "Daily 2"
    case daily3   = "Daily 3"

    var id: String { rawValue }
}

// MARK: - MacJournalDailyView

/// Permanent recurring daily routines and checklist with 3 distinct design options.
struct MacJournalDailyView: View {

    let selectedDate: Date

    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<HabitBoard> { $0.habitKindRaw == 1 },
           sort: \HabitBoard.createdAt)
    private var habitCandidates: [HabitBoard]

    private var dailyRoutines: [HabitBoard] {
        habitCandidates.filter { $0.archivedAt == nil }
    }

    @State private var selectedVariant: DailyDesignVariant = .showAll
    @State private var newRoutineName = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.lg) {

                // Top Variant Selector
                HStack {
                    Picker("Design Variant", selection: $selectedVariant) {
                        ForEach(DailyDesignVariant.allCases) { v in
                            Text(v.rawValue).tag(v)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()

                    Spacer()

                    Text("\(dailyRoutines.count) permanent routines")
                        .font(DS.Text.footnote)
                        .foregroundStyle(DS.Color.textTertiary)
                }

                // Render Selected Design(s)
                if selectedVariant == .showAll {
                    VStack(alignment: .leading, spacing: DS.Space.xl) {
                        variantHeader("DAILY 1 · ZEN HEATMAP GRID", subtitle: "Minimalist in-place list with emerald heatmap cells & live progress")
                        DailyZenHeatmapVariant(
                            routines: dailyRoutines,
                            selectedDate: selectedDate,
                            newRoutineName: $newRoutineName,
                            isInputFocused: $isInputFocused,
                            onAdd: addRoutine
                        )

                        variantHeader("DAILY 2 · WEEKLY HORIZON MATRIX", subtitle: "7-day mini heatmap strip for every routine showing weekly consistency")
                        DailyWeeklyMatrixVariant(
                            routines: dailyRoutines,
                            selectedDate: selectedDate,
                            newRoutineName: $newRoutineName,
                            isInputFocused: $isInputFocused,
                            onAdd: addRoutine
                        )

                        variantHeader("DAILY 3 · DAYLIGHT RITUAL FLOW", subtitle: "Structured morning, afternoon & evening phases with section progress")
                        DailyDaylightFlowVariant(
                            routines: dailyRoutines,
                            selectedDate: selectedDate,
                            newRoutineName: $newRoutineName,
                            isInputFocused: $isInputFocused,
                            onAdd: addRoutine
                        )
                    }
                } else if selectedVariant == .daily1 {
                    DailyZenHeatmapVariant(
                        routines: dailyRoutines,
                        selectedDate: selectedDate,
                        newRoutineName: $newRoutineName,
                        isInputFocused: $isInputFocused,
                        onAdd: addRoutine
                    )
                } else if selectedVariant == .daily2 {
                    DailyWeeklyMatrixVariant(
                        routines: dailyRoutines,
                        selectedDate: selectedDate,
                        newRoutineName: $newRoutineName,
                        isInputFocused: $isInputFocused,
                        onAdd: addRoutine
                    )
                } else if selectedVariant == .daily3 {
                    DailyDaylightFlowVariant(
                        routines: dailyRoutines,
                        selectedDate: selectedDate,
                        newRoutineName: $newRoutineName,
                        isInputFocused: $isInputFocused,
                        onAdd: addRoutine
                    )
                }

                Spacer(minLength: DS.Space.xxxl)
            }
            .padding(.horizontal, DS.Space.lg)
            .padding(.vertical, DS.Space.lg)
        }
    }

    private func variantHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.accentColor)
                .tracking(0.6)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(DS.Color.textTertiary)
        }
        .padding(.top, 4)
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

// MARK: - Design 1: DailyZenHeatmapVariant (Minimalist Zen)

private struct DailyZenHeatmapVariant: View {

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

            // Top Status Bar with Progress
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

                    // Progress Bar
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

                // Add Row
                addInputRow(placeholder: "Add a daily routine…")
            }
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        }
    }

    private func addInputRow(placeholder: String) -> some View {
        HStack(spacing: DS.Space.md) {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(DS.Color.textTertiary)

            TextField(placeholder, text: $newRoutineName)
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
            .opacity(newRoutineName.isEmpty ? 0.3 : 0.9)
            .disabled(newRoutineName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.md)
    }
}

private struct ZenHeatmapRow: View {
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
            // Title
            Text(routine.name.isEmpty ? "Untitled routine" : routine.name)
                .font(DS.Text.body)
                .foregroundStyle(isChecked ? DS.Color.textTertiary : DS.Color.textPrimary)
                .strikethrough(isChecked, color: DS.Color.textTertiary)

            Spacer()

            // Streak Flame
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

            // Hover Delete
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

            // Green Heatmap Cell
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

// MARK: - Design 2: DailyWeeklyMatrixVariant (7-Day Horizon Strip)

private struct DailyWeeklyMatrixVariant: View {

    let routines: [HabitBoard]
    let selectedDate: Date
    @Binding var newRoutineName: String
    var isInputFocused: FocusState<Bool>.Binding
    let onAdd: (String) -> Void

    private var weekDays: [Date] {
        let cal = Calendar.current
        var comp = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)
        comp.weekday = 2 // Monday
        guard let monday = cal.date(from: comp) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    var body: some View {
        VStack(spacing: DS.Space.md) {

            // Weekly Header Strip
            HStack {
                Text("ROUTINE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(0.6)

                Spacer()

                HStack(spacing: 8) {
                    ForEach(weekDays, id: \.self) { day in
                        let isToday = Calendar.current.isDate(day, inSameDayAs: selectedDate)
                        Text(formatDayLetter(day))
                            .font(.system(size: 10, weight: isToday ? .bold : .medium))
                            .foregroundStyle(isToday ? Color.accentColor : DS.Color.textTertiary)
                            .frame(width: 18)
                    }
                }
            }
            .padding(.horizontal, DS.Space.lg)
            .padding(.vertical, DS.Space.sm)
            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: DS.Radius.card))

            // Routine Matrix Rows
            VStack(spacing: 0) {
                ForEach(routines) { routine in
                    WeeklyMatrixRow(routine: routine, selectedDate: selectedDate, weekDays: weekDays)
                    Divider().padding(.leading, DS.Space.lg)
                }

                // Add Input
                HStack(spacing: DS.Space.md) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)

                    TextField("Add recurring routine to matrix…", text: $newRoutineName)
                        .font(DS.Text.body)
                        .textFieldStyle(.plain)
                        .focused(isInputFocused)
                        .onSubmit { onAdd(newRoutineName) }

                    Spacer()
                }
                .padding(.horizontal, DS.Space.lg)
                .padding(.vertical, DS.Space.md)
            }
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        }
    }

    private func formatDayLetter(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEEE" // Single letter: M, T, W, T, F, S, S
        return f.string(from: date)
    }
}

private struct WeeklyMatrixRow: View {
    @Bindable var routine: HabitBoard
    let selectedDate: Date
    let weekDays: [Date]
    @Environment(\.modelContext) private var modelContext

    private static let heatmapGreen = Color(red: 0.18, green: 0.80, blue: 0.44)

    var body: some View {
        HStack(spacing: DS.Space.md) {
            Text(routine.name.isEmpty ? "Untitled routine" : routine.name)
                .font(DS.Text.body)
                .foregroundStyle(DS.Color.textPrimary)

            Spacer()

            // 7-Day Heatmap Strip
            HStack(spacing: 8) {
                ForEach(weekDays, id: \.self) { day in
                    let isChecked = isDayCompleted(day)
                    let isSelectedDay = Calendar.current.isDate(day, inSameDayAs: selectedDate)

                    Button {
                        withAnimation(DS.Motion.settle) {
                            try? CheckInWriter.toggleBinary(board: routine, date: day, context: modelContext)
                        }
                        Haptics.impact(.light)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(isChecked ? Self.heatmapGreen : DS.Color.surfaceRecessed)
                                .frame(width: 18, height: 18)

                            if isSelectedDay {
                                RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(isChecked ? Self.heatmapGreen : Color.accentColor, lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                            }

                            if isChecked {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.md)
    }

    private func isDayCompleted(_ date: Date) -> Bool {
        let cal = Calendar.current
        let target = routine.effectiveTarget
        let logs = routine.activeLogs.filter { cal.isDate($0.timestamp, inSameDayAs: date) }
        return logs.reduce(0.0) { $0 + $1.value } >= target
    }
}

// MARK: - Design 3: DailyDaylightFlowVariant (Morning / Afternoon / Evening Phases)

private struct DailyDaylightFlowVariant: View {

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

            // Morning Phase Card
            phaseCard(
                title: "MORNING RITUALS",
                icon: "sun.horizon.fill",
                color: Color(red: 0.98, green: 0.65, blue: 0.20),
                routines: morningRoutines
            )

            // Evening Wind-down Phase Card
            phaseCard(
                title: "EVENING WIND-DOWN",
                icon: "moon.stars.fill",
                color: Color(red: 0.45, green: 0.42, blue: 0.98),
                routines: eveningRoutines
            )

            // Add Input Row
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
            // Phase Header
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

            // Phase Items
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
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }

    private func completedCount(for list: [HabitBoard]) -> Int {
        let cal = Calendar.current
        return list.filter { habit in
            let logs = habit.activeLogs.filter { cal.isDate($0.timestamp, inSameDayAs: selectedDate) }
            return logs.reduce(0.0) { $0 + $1.value } >= habit.effectiveTarget
        }.count
    }
}


