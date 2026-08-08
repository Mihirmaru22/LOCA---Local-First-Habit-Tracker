import SwiftUI
import SwiftData

// MARK: - MacJournalCollect   (J2)

/// Collect mode — write today's note and browse past notes.
///
/// Two sources are blended into one reverse-chronological list:
/// 1. `JournalNote` records (free-form daily notes written here).
/// 2. `LogEntry` records with non-nil `note` (habit check-in notes).
///
/// Both sources are day-grouped so the user sees a unified journal,
/// not two separate lists. The "Today" group always appears first and
/// shows an inline text field for writing today's note.
struct MacJournalCollect: View {

    @Binding var selectedNote: JournalNote?

    @Query(sort: [SortDescriptor(\JournalNote.date, order: .reverse)], animation: .default)
    private var notes: [JournalNote]

    @Query(sort: [SortDescriptor(\LogEntry.timestamp, order: .reverse)], animation: .default)
    private var logEntries: [LogEntry]

    @Environment(\.modelContext) private var modelContext
    @State private var todayDraft: String = ""
    @FocusState private var draftFocused: Bool

    private var activeNotes: [JournalNote] {
        notes.filter { !$0.isArchived }
    }

    private var logEntriesWithNotes: [LogEntry] {
        logEntries.filter { $0.note != nil && $0.archivedAt == nil }
    }

    // Today's existing JournalNote, if any
    private var todayNote: JournalNote? {
        activeNotes.first { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        List(selection: $selectedNote) {
            // Today's write field
            Section("Today") {
                todayWriteArea
            }

            // Past notes (most recent first)
            let pastNotes = activeNotes.filter { !Calendar.current.isDateInToday($0.date) }
            if !pastNotes.isEmpty {
                Section("Previous") {
                    ForEach(pastNotes, id: \.id) { note in
                        MacJournalNoteRow(note: note)
                            .tag(note)
                    }
                }
            }

            // Habit check-in notes blended in
            let checkinNotes = logEntriesWithNotes
            if !checkinNotes.isEmpty {
                Section("Check-in Notes") {
                    ForEach(checkinNotes, id: \.id) { entry in
                        MacCheckinNoteRow(entry: entry)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .onAppear {
            // Pre-fill draft from existing today note
            todayDraft = todayNote?.text ?? ""
        }
    }

    // MARK: - Today write area

    @ViewBuilder
    private var todayWriteArea: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            TextEditor(text: $todayDraft)
                .font(DS.Text.body)
                .frame(minHeight: 80, maxHeight: 160)
                .scrollContentBackground(.hidden)
                .focused($draftFocused)
                .onChange(of: todayDraft) { _, newValue in
                    saveTodayNote(text: newValue)
                }

            HStack {
                Text(todayDraft.isEmpty ? "What's on your mind today?" : "")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textTertiary)
                Spacer()
                Text("\(todayDraft.count) chars")
                    .font(DS.Text.footnote)
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
        .padding(.vertical, DS.Space.xs)
    }

    // MARK: - Persistence

    private func saveTodayNote(text: String) {
        if let existing = todayNote {
            existing.text = text
        } else if !text.isEmpty {
            let note = JournalNote(date: Date(), text: text)
            modelContext.insert(note)
        }
        try? modelContext.save()
    }
}

// MARK: - MacJournalNoteRow

private struct MacJournalNoteRow: View {
    let note: JournalNote

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text(note.date, style: .date)
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textSecondary)
            Text(note.text)
                .font(DS.Text.body)
                .lineLimit(2)
                .foregroundStyle(DS.Color.textPrimary)
        }
        .padding(.vertical, DS.Space.xs)
    }
}

// MARK: - MacCheckinNoteRow

private struct MacCheckinNoteRow: View {
    let entry: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            HStack(spacing: DS.Space.xs) {
                if let board = entry.board {
                    Circle()
                        .fill(ColorPalette[board.colorIndex])
                        .frame(width: 8, height: 8)
                    Text(board.name)
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }
                Spacer()
                Text(entry.timestamp, style: .date)
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }
            if let note = entry.note {
                Text(note)
                    .font(DS.Text.body)
                    .lineLimit(2)
                    .foregroundStyle(DS.Color.textPrimary)
            }
        }
        .padding(.vertical, DS.Space.xs)
    }
}
