import SwiftUI
import SwiftData

// MARK: - MacJournalCollect   (J2/J3/J4)

/// Collect view — capture daily habits, sleep, moments, and wins.
///
/// Hosted in the detail column whenever the Collect tab is active.
/// `focusedRow` is passed in so a future scroll-to-section animation
/// can jump to the right block when the user taps Moments or Wins in
/// the content column.
struct MacJournalCollect: View {

    let focusedRow: JournalRow?

    @Query(filter: #Predicate<HabitBoard> { $0.habitKindRaw == 1 },
           sort: \HabitBoard.createdAt)
    private var dailyHabitCandidates: [HabitBoard]
    private var dailyHabits: [HabitBoard] { dailyHabitCandidates.filter { $0.archivedAt == nil } }

    @Query(sort: [SortDescriptor(\JournalNote.date, order: .reverse)])
    private var allNotes: [JournalNote]

    private var todayMoments: [JournalNote] {
        allNotes.filter {
            !$0.isArchived &&
            $0.noteKind == .moment &&
            Calendar.current.isDateInToday($0.date)
        }
    }

    private var todayWins: [JournalNote] {
        allNotes.filter {
            !$0.isArchived &&
            $0.noteKind == .win &&
            Calendar.current.isDateInToday($0.date)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xl) {

                // DAILY HABITS
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    sectionLabel("DAILY HABITS")
                    if dailyHabits.isEmpty {
                        Text("No daily routines yet. Create a habit and set its kind to Daily.")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textTertiary)
                            .padding(.vertical, DS.Space.xs)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(dailyHabits, id: \.id) { habit in
                                DailyHabitRow(habit: habit)
                                if habit.id != dailyHabits.last?.id {
                                    Divider().padding(.leading, 44)
                                }
                            }
                        }
                        .background(DS.Color.surface,
                                    in: RoundedRectangle(cornerRadius: DS.Radius.card))
                    }
                }

                // SLEEP
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    sectionLabel("SLEEP")
                    SleepCard()
                }

                // MOMENTS & WINS
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    sectionLabel("MOMENTS & WINS")
                    MomentsWinsSection(moments: todayMoments, wins: todayWins)
                }

                Spacer(minLength: DS.Space.xxxl)
            }
            .padding(DS.Space.lg)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(DS.Text.caption)
            .foregroundStyle(DS.Color.textTertiary)
            .tracking(0.8)
    }
}

// MARK: - DailyHabitRow

private struct DailyHabitRow: View {

    let habit: HabitBoard
    @Environment(\.modelContext) private var modelContext

    private var isCheckedToday: Bool {
        habit.activeLogs.contains { Calendar.current.isDateInToday($0.timestamp) }
    }

    var body: some View {
        HStack(spacing: DS.Space.md) {

            // Checkbox
            Button {
                try? CheckInWriter.toggleBinary(board: habit, context: modelContext)
            } label: {
                let accent = ColorPalette[habit.colorIndex]
                ZStack {
                    Circle()
                        .fill(isCheckedToday ? accent : SwiftUI.Color.clear)
                        .frame(width: 22, height: 22)
                    Circle()
                        .strokeBorder(isCheckedToday ? accent : DS.Color.border, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isCheckedToday {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.12), value: isCheckedToday)

            // Optional emoji
            if let emoji = habit.emoji {
                Text(emoji).font(DS.Text.body)
            }

            // Name
            Text(habit.name)
                .font(DS.Text.body)
                .foregroundStyle(isCheckedToday ? DS.Color.textTertiary : DS.Color.textPrimary)
                .strikethrough(isCheckedToday, color: DS.Color.textTertiary)
                .animation(.easeInOut(duration: 0.12), value: isCheckedToday)

            Spacer()

            // Streak flame
            if habit.currentStreak > 0 {
                Label("\(habit.currentStreak)", systemImage: "flame.fill")
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, DS.Space.md)
        .padding(.vertical, DS.Space.sm)
    }
}

// MARK: - SleepCard   (J3)

/// Sleep entry card with dual input mode.
///
/// Bedtime + Wake: two time pickers; `SleepEntry.computeSleepHours` derives the
/// total, handling past-midnight crossings. Total hours: a stepper (0.5 h steps).
/// Both paths write one `sleepHours` value to a `SleepEntry` for today.
/// The last-used mode is remembered across launches via `SleepEntry.lastInputMode`.
private struct SleepCard: View {

    @Query(sort: [SortDescriptor(\SleepEntry.date, order: .reverse)])
    private var allEntries: [SleepEntry]

    @Environment(\.modelContext) private var modelContext

    @State private var inputMode:  SleepEntry.SleepInputMode = SleepEntry.lastInputMode
    @State private var bedtime:    Date = SleepCard.defaultBedtime
    @State private var wakeTime:   Date = SleepCard.defaultWakeTime
    @State private var totalHours: Double = 7.0

    private var todayEntry: SleepEntry? {
        allEntries.first { Calendar.current.isDateInToday($0.date) }
    }

    private static var defaultBedtime: Date {
        Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
    }
    private static var defaultWakeTime: Date {
        Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    }

    private var computedHours: Double {
        SleepEntry.computeSleepHours(bedtime: bedtime, wakeTime: wakeTime)
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: DS.Space.md) {
            modePicker
            if inputMode == .bedtimeWake {
                bedtimeWakeRow
            } else {
                totalHoursRow
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        // Sync local state when today's entry first appears (or changes day)
        .task(id: todayEntry?.id) { syncFromEntry() }
        .onChange(of: inputMode)   { _, _ in save() }
        .onChange(of: bedtime)     { _, _ in guard inputMode == .bedtimeWake else { return }; save() }
        .onChange(of: wakeTime)    { _, _ in guard inputMode == .bedtimeWake else { return }; save() }
        .onChange(of: totalHours)  { _, _ in guard inputMode == .totalHours  else { return }; save() }
    }

    // MARK: Mode picker

    private var modePicker: some View {
        HStack(spacing: 2) {
            modeChip(.bedtimeWake, label: "Bedtime + Wake")
            modeChip(.totalHours,  label: "Total hours")
        }
        .padding(3)
        .background(DS.Color.surfaceRecessed,
                    in: RoundedRectangle(cornerRadius: DS.Radius.control))
    }

    private func modeChip(_ mode: SleepEntry.SleepInputMode, label: String) -> some View {
        let selected = inputMode == mode
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                inputMode = mode
                SleepEntry.lastInputMode = mode
            }
        } label: {
            Text(label)
                .font(DS.Text.caption)
                .fontWeight(selected ? .semibold : .regular)
                .foregroundStyle(selected ? DS.Color.textPrimary : DS.Color.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Space.xs)
                .background(selected ? DS.Color.surface : SwiftUI.Color.clear,
                            in: RoundedRectangle(cornerRadius: DS.Radius.control - 2))
        }
        .buttonStyle(.plain)
    }

    // MARK: Bedtime + Wake

    private var bedtimeWakeRow: some View {
        HStack(alignment: .center, spacing: 0) {
            timePickerColumn("Asleep") {
                DatePicker("", selection: $bedtime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }

            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundStyle(DS.Color.textTertiary)
                .padding(.horizontal, DS.Space.sm)

            timePickerColumn("Woke") {
                DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }

            Spacer()

            // Computed total
            VStack(spacing: 2) {
                Text(hoursLabel(computedHours))
                    .font(DS.Text.value)
                    .foregroundStyle(.blue)
                    .contentTransition(.numericText())
                Text("total")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
    }

    private func timePickerColumn<P: View>(
        _ label: String,
        @ViewBuilder picker: () -> P
    ) -> some View {
        VStack(spacing: DS.Space.xs) {
            picker()
            Text(label)
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textTertiary)
        }
    }

    // MARK: Total hours

    private var totalHoursRow: some View {
        HStack {
            Spacer()
            Stepper(value: $totalHours, in: 0...24, step: 0.5) {
                Text(hoursLabel(totalHours))
                    .font(DS.Text.value)
                    .foregroundStyle(.blue)
                    .frame(minWidth: 80, alignment: .trailing)
            }
            Spacer()
        }
    }

    // MARK: Helpers

    private func hoursLabel(_ h: Double) -> String {
        let hours = Int(h)
        let mins  = Int((h - Double(hours)) * 60)
        return mins == 0 ? "\(hours)h" : "\(hours)h \(mins)m"
    }

    private func syncFromEntry() {
        guard let e = todayEntry else { return }
        inputMode  = e.inputMode
        totalHours = e.sleepHours
        if let bt = e.bedtime  { bedtime  = bt }
        if let wt = e.wakeTime { wakeTime = wt }
    }

    private func save() {
        let hours = inputMode == .bedtimeWake ? computedHours : totalHours
        if let existing = todayEntry {
            existing.sleepHours   = hours
            existing.inputModeRaw = inputMode.rawValue
            existing.bedtime      = inputMode == .bedtimeWake ? bedtime  : nil
            existing.wakeTime     = inputMode == .bedtimeWake ? wakeTime : nil
        } else {
            let entry = SleepEntry(
                date: Date(),
                sleepHours: hours,
                inputMode: inputMode,
                bedtime: inputMode == .bedtimeWake ? bedtime  : nil,
                wakeTime: inputMode == .bedtimeWake ? wakeTime : nil
            )
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }
}

// MARK: - MomentsWinsSection   (J4)

/// Fast-capture section for today's moments and wins.
///
/// Each kind gets a header, a text field (submit with Return or the + button),
/// and a list of today's captured entries that can be swiped/deleted.
private struct MomentsWinsSection: View {

    let moments: [JournalNote]
    let wins:    [JournalNote]

    @Environment(\.modelContext) private var modelContext
    @State private var momentDraft = ""
    @State private var winDraft    = ""

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            captureBlock(
                kind: .moment,
                draft: $momentDraft,
                notes: moments,
                placeholder: "Something that happened today…",
                prefix: "·"
            )
            Divider()
            captureBlock(
                kind: .win,
                draft: $winDraft,
                notes: wins,
                placeholder: "Something you're proud of…",
                prefix: "🏆"
            )
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    @ViewBuilder
    private func captureBlock(
        kind: JournalNote.NoteKind,
        draft: Binding<String>,
        notes: [JournalNote],
        placeholder: String,
        prefix: String
    ) -> some View {
        let kindLabel = kind == .moment ? "Moments" : "Wins"
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text(kindLabel)
                .font(DS.Text.body)
                .fontWeight(.medium)
                .foregroundStyle(DS.Color.textPrimary)

            // Text field
            HStack(spacing: DS.Space.xs) {
                TextField(placeholder, text: draft)
                    .font(DS.Text.body)
                    .onSubmit { commitDraft(draft: draft, kind: kind) }

                if !draft.wrappedValue.isEmpty {
                    Button { commitDraft(draft: draft, kind: kind) } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Captured entries
            if !notes.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    ForEach(notes, id: \.id) { note in
                        HStack(spacing: DS.Space.xs) {
                            Text(prefix)
                                .font(DS.Text.body)
                                .foregroundStyle(DS.Color.textTertiary)
                            Text(note.text)
                                .font(DS.Text.body)
                                .foregroundStyle(DS.Color.textPrimary)
                            Spacer()
                            Button {
                                note.archivedAt = Date()
                                try? modelContext.save()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(DS.Text.footnote)
                                    .foregroundStyle(DS.Color.textTertiary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.top, DS.Space.xs)
            }
        }
    }

    private func commitDraft(draft: Binding<String>, kind: JournalNote.NoteKind) {
        let text = draft.wrappedValue.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let note = JournalNote(date: Date(), text: text, kind: kind)
        modelContext.insert(note)
        try? modelContext.save()
        draft.wrappedValue = ""
    }
}
