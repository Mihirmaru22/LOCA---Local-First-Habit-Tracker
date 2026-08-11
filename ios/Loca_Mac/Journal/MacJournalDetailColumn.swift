import SwiftUI

// MARK: - MacJournalDetailColumn

/// Detail column for the Journal section.
///
/// Header: "Journal" title + today's day/date + Collect / Analyse segmented toggle.
/// Body: `MacJournalCollect` or `MacJournalAnalyse` based on the active mode.
///
/// The toggle defaults to the row's `defaultDetailMode` whenever the selection
/// changes; the user can then switch freely within the same row selection.
struct MacJournalDetailColumn: View {

    let selectedRow: JournalRow?

    @State private var detailMode: JournalDetailMode = .collect

    private var isNotesRow: Bool {
        selectedRow == .moments || selectedRow == .wins
    }

    var body: some View {
        VStack(spacing: 0) {
            journalHeader
            Divider()

            if selectedRow == .moments {
                MacJournalNotesView(kind: .moment)
            } else if selectedRow == .wins {
                MacJournalNotesView(kind: .win)
            } else {
                switch detailMode {
                case .collect:
                    MacJournalCollect(focusedRow: selectedRow)
                case .analyse:
                    MacJournalAnalyse()
                }
            }
        }
        .onChange(of: selectedRow) { _, newRow in
            if let newRow, !isNotesRow {
                detailMode = newRow.defaultDetailMode
            }
        }
    }

    // MARK: - Header

    private var journalHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text("Journal")
                    .font(DS.Text.heading)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Color.textPrimary)
                Text(isNotesRow ? notesLabel : todayLabel)
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }
            Spacer()
            if !isNotesRow {
                Picker("Mode", selection: $detailMode) {
                    ForEach(JournalDetailMode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.md)
    }

    private var todayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE · MMMM d"
        return f.string(from: Date())
    }

    private var notesLabel: String {
        selectedRow == .moments ? "All moments" : "All wins"
    }
}

// MARK: - Placeholder (no row selected)

struct MacJournalDetailPlaceholder: View {
    var body: some View {
        ContentUnavailableView(
            "Select a Row",
            systemImage: "book.closed",
            description: Text("Choose Today's log, Moments, Wins, or Analyse.")
        )
    }
}
