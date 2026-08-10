import SwiftUI
import SwiftData

// MARK: - JournalRow

/// The four fixed rows shown in the Journal middle column.
///
/// Selecting a row drives the detail column; the row's `defaultDetailMode`
/// determines which tab (Collect / Analyse) opens first.
enum JournalRow: String, CaseIterable, Identifiable {
    case todaysLog = "Today's log"
    case analyse   = "Analyse"
    case moments   = "Moments"
    case wins      = "Wins"

    var id: String { rawValue }

    var defaultDetailMode: JournalDetailMode {
        self == .analyse ? .analyse : .collect
    }
}

// MARK: - JournalDetailMode

enum JournalDetailMode: String, CaseIterable, Identifiable {
    case collect = "Collect"
    case analyse = "Analyse"
    var id: String { rawValue }
}

// MARK: - MacJournalContentColumn

/// Middle column for the Journal section.
///
/// Shows four fixed rows (Today's log, Analyse, Moments, Wins) with trailing
/// annotations (date, "month", today's counts). Selection drives `MacJournalDetailColumn`.
struct MacJournalContentColumn: View {

    @Binding var selectedRow: JournalRow?

    @Query(sort: [SortDescriptor(\JournalNote.date, order: .reverse)])
    private var allNotes: [JournalNote]

    private var todayMomentCount: Int {
        allNotes.filter {
            !$0.isArchived &&
            $0.noteKind == .moment &&
            Calendar.current.isDateInToday($0.date)
        }.count
    }

    private var todayWinCount: Int {
        allNotes.filter {
            !$0.isArchived &&
            $0.noteKind == .win &&
            Calendar.current.isDateInToday($0.date)
        }.count
    }

    var body: some View {
        List(JournalRow.allCases, selection: $selectedRow) { row in
            JournalRowCell(
                row: row,
                momentCount: todayMomentCount,
                winCount: todayWinCount
            )
            .tag(row)
        }
        .listStyle(.sidebar)
        .navigationTitle("Journal")
    }
}

// MARK: - JournalRowCell

private struct JournalRowCell: View {

    let row: JournalRow
    let momentCount: Int
    let winCount: Int

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    var body: some View {
        HStack {
            Text(row.rawValue)
                .font(DS.Text.body)
                .foregroundStyle(DS.Color.textPrimary)
            Spacer()
            Text(trailingLabel)
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textTertiary)
        }
        .padding(.vertical, DS.Space.xs)
    }

    private var trailingLabel: String {
        switch row {
        case .todaysLog: return Self.shortDateFormatter.string(from: Date())
        case .analyse:   return "month"
        case .moments:   return momentCount > 0 ? "\(momentCount)" : ""
        case .wins:      return winCount > 0 ? "\(winCount)" : ""
        }
    }
}
