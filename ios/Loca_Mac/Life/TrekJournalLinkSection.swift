import SwiftUI
import SwiftData

// MARK: - TrekJournalLinkSection

/// Apple Journal cross-linking drawer embedded on the Summit Detail Card.
/// Displays linked journal reflections, provides 1-click Summit Journal creation
/// pre-populated with mountain GPS/altitude telemetry, and existing note linking.
struct TrekJournalLinkSection: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalNote.date, order: .reverse) private var allJournalNotes: [JournalNote]

    @Bindable var trek: TrekRecord

    @State private var isCreatingNote: Bool = false

    private var linkedNotes: [JournalNote] {
        allJournalNotes.filter { trek.linkedJournalNoteIDs.contains($0.id) && !$0.isArchived }
    }

    private var unlinkedCandidateNotes: [JournalNote] {
        allJournalNotes.filter { !trek.linkedJournalNoteIDs.contains($0.id) && !$0.isArchived }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            // Section Header & Action Menu
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.purple)
                    Text("LINKED JOURNAL REFLECTIONS (\(linkedNotes.count))")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                }

                Spacer()

                // Actions Menu
                Menu {
                    Button {
                        createSummitJournalEntry()
                    } label: {
                        Label("Write Summit Entry", systemImage: "square.and.pencil")
                    }

                    if !unlinkedCandidateNotes.isEmpty {
                        Menu("Link Existing Entry...") {
                            ForEach(unlinkedCandidateNotes.prefix(8)) { note in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        trek.linkJournalNote(id: note.id)
                                        try? modelContext.save()
                                    }
                                    Haptics.notification(.success)
                                } label: {
                                    Text(note.title.isEmpty ? note.date.formatted(date: .abbreviated, time: .omitted) : note.title)
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .bold))
                        Text("Journal")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(Color.purple)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
                }
                .menuStyle(.borderlessButton)
            }

            // Linked Notes List or Empty State
            if !linkedNotes.isEmpty {
                VStack(spacing: 5) {
                    ForEach(linkedNotes) { note in
                        LinkedJournalNoteRow(
                            note: note,
                            onUnlink: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    trek.unlinkJournalNote(id: note.id)
                                    try? modelContext.save()
                                }
                                Haptics.impact(.light)
                            }
                        )
                    }
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "pencil.line")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Color.textTertiary)
                    Text("No linked journal notes — click '+ Journal' to write or link reflections")
                        .font(.system(size: 10))
                        .foregroundStyle(DS.Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(DS.Color.surfaceRecessed.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    // MARK: - Actions

    private func createSummitJournalEntry() {
        let altitude = Int(trek.elevationMeters).formatted()
        let noteTitle = "Summit of \(trek.name) (\(altitude)m)"

        let newNote = JournalNote(
            date: trek.dateConquered ?? Date(),
            title: noteTitle,
            text: trek.personalNotes.isEmpty ? "Conquered the summit of \(trek.name) in \(trek.region), \(trek.country)." : trek.personalNotes,
            kind: .moment
        )

        newNote.location = "\(trek.region), \(trek.country)"
        newNote.locationAddress = "\(trek.name), \(trek.region)"
        newNote.latitude = trek.latitude
        newNote.longitude = trek.longitude

        modelContext.insert(newNote)
        trek.linkJournalNote(id: newNote.id)
        try? modelContext.save()

        Haptics.notification(.success)
    }
}

// MARK: - LinkedJournalNoteRow

struct LinkedJournalNoteRow: View {
    let note: JournalNote
    let onUnlink: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color.purple)

            VStack(alignment: .leading, spacing: 1) {
                Text(note.title.isEmpty ? "Journal Entry" : note.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(note.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 9))
                        .foregroundStyle(DS.Color.textTertiary)

                    if !note.text.isEmpty {
                        Text("· \(note.text)")
                            .font(.system(size: 9))
                            .foregroundStyle(DS.Color.textSecondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            if isHovered {
                Button(action: onUnlink) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                        .padding(4)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .help("Unlink Note from Summit")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.purple.opacity(isHovered ? 0.12 : 0.06), in: RoundedRectangle(cornerRadius: 6))
        .onHover { isHovered = $0 }
    }
}
