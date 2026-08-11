import SwiftUI
import SwiftData

// MARK: - MacJournalNotesView   (J6)

/// All-time list of Moments or Wins, shown when the user selects
/// "Moments" or "Wins" in the Journal sidebar.
///
/// Groups entries by calendar day (newest day first). Quick-add
/// field at the top lets the user capture new entries without leaving.
struct MacJournalNotesView: View {

    let kind: JournalNote.NoteKind

    @Environment(\.modelContext) private var modelContext

    // Fetch all notes; filter by kind + archived in memory
    // (compound #Predicate && nil-check causes type-check timeouts)
    @Query(sort: [SortDescriptor(\JournalNote.date, order: .reverse)])
    private var allNotes: [JournalNote]

    @State private var draft = ""

    // MARK: - Derived

    private var notes: [JournalNote] {
        allNotes.filter { !$0.isArchived && $0.noteKind == kind }
    }

    /// Entries grouped by calendar day, newest day first.
    private var groups: [(day: Date, entries: [JournalNote])] {
        let cal = Calendar.current
        var result: [(day: Date, entries: [JournalNote])] = []
        var index:  [Date: Int] = [:]
        for note in notes {
            let day = cal.startOfDay(for: note.date)
            if let i = index[day] {
                result[i].entries.append(note)
            } else {
                index[day] = result.count
                result.append((day: day, entries: [note]))
            }
        }
        return result
    }

    private var kindTitle:   String { kind == .moment ? "Moments"                  : "Wins" }
    private var placeholder: String { kind == .moment ? "Something that happened…" : "Something you're proud of…" }
    private var prefix:      String { kind == .moment ? "·"                        : "🏆" }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xl) {

                quickAddBar

                if notes.isEmpty {
                    Text("No \(kindTitle.lowercased()) yet.")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textTertiary)
                } else {
                    ForEach(groups, id: \.day) { group in
                        VStack(alignment: .leading, spacing: DS.Space.xs) {
                            Text(dayHeader(group.day))
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textTertiary)
                                .tracking(0.7)

                            VStack(spacing: 0) {
                                ForEach(group.entries, id: \.id) { note in
                                    NoteRowView(note: note, prefix: prefix) {
                                        note.archivedAt = Date()
                                        try? modelContext.save()
                                    }
                                    if note.id != group.entries.last?.id {
                                        Divider().padding(.leading, DS.Space.lg)
                                    }
                                }
                            }
                            .background(DS.Color.surface,
                                        in: RoundedRectangle(cornerRadius: DS.Radius.card))
                        }
                    }
                }

                Spacer(minLength: DS.Space.xxxl)
            }
            .padding(DS.Space.lg)
        }
    }

    // MARK: - Quick add

    private var quickAddBar: some View {
        HStack(spacing: DS.Space.sm) {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(DS.Color.textTertiary)
                .font(.body)

            TextField(placeholder, text: $draft)
                .font(DS.Text.body)
                .onSubmit(commit)
                .onExitCommand { draft = "" }
                .accessibilityLabel("New \(kindTitle.dropLast()) entry")

            if !draft.isEmpty {
                Button(action: commit) {
                    Image(systemName: "return")
                        .font(.caption)
                        .foregroundStyle(DS.Color.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add")
            }
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control))
    }

    // MARK: - Helpers

    private func commit() {
        let text = draft.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        modelContext.insert(JournalNote(date: Date(), text: text, kind: kind))
        try? modelContext.save()
        draft = ""
    }

    private func dayHeader(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "TODAY" }
        if cal.isDateInYesterday(date) { return "YESTERDAY" }
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: date).uppercased()
    }
}

// MARK: - NoteRowView

/// Single note entry with hover-revealed delete button.
private struct NoteRowView: View {

    let note:     JournalNote
    let prefix:   String
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: DS.Space.sm) {
            Text(prefix)
                .font(DS.Text.body)
                .foregroundStyle(DS.Color.textTertiary)

            Text(note.text)
                .font(DS.Text.body)
                .foregroundStyle(DS.Color.textPrimary)

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(DS.Text.footnote)
                    .foregroundStyle(DS.Color.textTertiary)
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0)
            .animation(.easeInOut(duration: 0.1), value: isHovered)
            .accessibilityLabel("Delete")
        }
        .padding(.horizontal, DS.Space.md)
        .padding(.vertical, DS.Space.sm)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}
