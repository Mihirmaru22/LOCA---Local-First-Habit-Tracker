import SwiftUI
import SwiftData

// MARK: - MacJournalDetailColumn   (J5)

/// Detail column for the Journal section.
///
/// Shows the full text of the selected `JournalNote` and lets the user edit it in
/// place. Changes are persisted immediately via `modelContext.save()` after every
/// keystroke (same debounce-free pattern used by `MacTodoDetailColumn`).
///
/// When `note` is `nil` (nothing selected in the collect list), a placeholder
/// is shown instead.
struct MacJournalDetailColumn: View {

    let note: JournalNote?

    var body: some View {
        if let note {
            MacJournalEditor(note: note)
        } else {
            MacJournalDetailPlaceholder()
        }
    }
}

// MARK: - MacJournalEditor

private struct MacJournalEditor: View {

    let note: JournalNote

    @Environment(\.modelContext) private var modelContext

    @State private var text: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: date + metadata
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text(note.date, style: .date)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Color.textPrimary)

                HStack(spacing: DS.Space.xs) {
                    Text("\(wordCount) words")
                    Text("·")
                    Text("\(text.count) characters")
                }
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textTertiary)
            }
            .padding(DS.Space.lg)

            Divider()

            // Editor
            TextEditor(text: $text)
                .font(DS.Text.body)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, DS.Space.lg)
                .padding(.vertical, DS.Space.md)
                .onChange(of: text) { _, newValue in
                    note.text = newValue
                    try? modelContext.save()
                }

            Divider()

            // Footer: archive button
            HStack {
                Spacer()
                Button(role: .destructive) {
                    note.archivedAt = Date()
                    try? modelContext.save()
                } label: {
                    Label("Archive", systemImage: "archivebox")
                        .font(DS.Text.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(DS.Color.textTertiary)
            }
            .padding(.horizontal, DS.Space.lg)
            .padding(.vertical, DS.Space.sm)
        }
        .onAppear { text = note.text }
        .onChange(of: note.id) { _, _ in text = note.text }
    }

    private var wordCount: Int {
        text.split(separator: " ").count
    }
}

// MARK: - MacJournalDetailPlaceholder

private struct MacJournalDetailPlaceholder: View {
    var body: some View {
        ContentUnavailableView(
            "No Note Selected",
            systemImage: "book.closed",
            description: Text("Select a journal entry from the list to read or edit it.")
        )
    }
}
