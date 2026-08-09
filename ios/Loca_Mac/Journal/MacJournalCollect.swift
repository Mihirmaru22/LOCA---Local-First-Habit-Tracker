import SwiftUI
import SwiftData

// MARK: - MacJournalCollect   (J2 — placeholder pending step 3 redesign)

/// Collect mode for the Mac Journal section.
///
/// Step 3 will replace this with the daily-habit checklist + sleep entry +
/// moments & wins capture. For now this shows the legacy note view so the
/// column compiles and displays something useful.
struct MacJournalCollect: View {

    /// Which content-column row triggered this view. Step 3 will use this to
    /// scroll to the relevant section (moments, wins, etc.).
    let focusedRow: JournalRow?

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

    private var todayNote: JournalNote? {
        activeNotes.first { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        List {
            Section("Today") {
                todayWriteArea
            }

            let pastNotes = activeNotes.filter { !Calendar.current.isDateInToday($0.date) }
            if !pastNotes.isEmpty {
                Section("Previous") {
                    ForEach(pastNotes, id: \.id) { note in
                        MacJournalNoteRow(note: note)
                    }
                }
            }

            let checkinNotes = logEntriesWithNotes
            if !checkinNotes.isEmpty {
                Section("Check-in Notes") {
                    ForEach(checkinNotes, id: \.id) { entry in
                        MacCheckinNoteRow(entry: entry)
                    }
                }
            }
        }
        .listStyle(.inset)
        .onAppear {
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
