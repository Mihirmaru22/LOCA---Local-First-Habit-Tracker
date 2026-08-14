import SwiftUI
import SwiftData

// MARK: - JournalRow

/// The fixed rows shown in the Journal middle column.
enum JournalRow: String, CaseIterable, Identifiable {
    case todaysLog = "Today's log"
    case notes     = "Notes"
    case analyse   = "Analyse"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .todaysLog: return "book.pages"
        case .notes:     return "square.and.pencil"
        case .analyse:   return "chart.xyaxis.line"
        }
    }

    var defaultDetailMode: JournalDetailMode {
        switch self {
        case .analyse:   return .analyse
        case .notes:     return .notes
        case .todaysLog: return .collect
        }
    }
}

// MARK: - JournalDetailMode

enum JournalDetailMode: String, CaseIterable, Identifiable {
    case collect = "Collect"
    case notes   = "Notes"
    case analyse = "Analyse"
    var id: String { rawValue }
}

// MARK: - MacJournalContentColumn

/// Middle column for the Journal section.
struct MacJournalContentColumn: View {

    @Binding var selectedRow: JournalRow?

    @Query(filter: #Predicate<HabitBoard> { $0.habitKindRaw == 1 },
           sort: \HabitBoard.createdAt)
    private var habitCandidates: [HabitBoard]

    @Query(sort: [SortDescriptor(\JournalNote.date, order: .reverse)])
    private var allJournalNotes: [JournalNote]

    private var dailyRoutines: [HabitBoard] {
        habitCandidates.filter { $0.archivedAt == nil }
    }

    private var todayPendingDailyCount: Int {
        let cal = Calendar.current
        return dailyRoutines.filter { habit in
            let logs = habit.activeLogs.filter { cal.isDateInToday($0.timestamp) }
            return logs.reduce(0.0) { $0 + $1.value } < habit.effectiveTarget
        }.count
    }

    private var notesCount: Int {
        allJournalNotes.filter { !$0.isArchived }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Header: Label
            HStack(spacing: DS.Space.sm) {
                Text("JOURNAL")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(0.6)

                Spacer()
            }
            .padding(.horizontal, DS.Space.md)
            .padding(.vertical, DS.Space.sm)

            Divider()

            // Main Rows List with Unified Theme
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(JournalRow.allCases) { row in
                        JournalRowButton(
                            row: row,
                            pendingDailyCount: todayPendingDailyCount,
                            notesCount: notesCount,
                            isSelected: selectedRow == row
                        ) {
                            selectedRow = row
                            Haptics.selection()
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 12)
            }
        }
        .navigationTitle("Journal")
    }
}

// MARK: - JournalRowButton

private struct JournalRowButton: View {

    let row: JournalRow
    let pendingDailyCount: Int
    let notesCount: Int
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: row.icon)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(rowIconColor)
                    .frame(width: 20, height: 20)

                Text(row.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? DS.Color.textPrimary : (isHovered ? DS.Color.textPrimary : DS.Color.textSecondary))

                Spacer()

                if let badge = badgeText {
                    Text(badge)
                        .font(.system(size: 11, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(rowBadgeColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(rowBadgeBackground, in: Capsule())
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? DS.Color.surfaceRecessed
                    : (isHovered ? DS.Color.surfaceRecessed.opacity(0.5) : Color.clear),
                in: RoundedRectangle(cornerRadius: 8)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private var rowIconColor: Color {
        switch row {
        case .todaysLog: return Color.purple
        case .notes:     return Color(red: 0.38, green: 0.45, blue: 0.98)
        case .analyse:   return Color.indigo
        }
    }

    private var badgeText: String? {
        switch row {
        case .todaysLog:
            return pendingDailyCount > 0 ? "\(pendingDailyCount)" : Self.shortDateFormatter.string(from: Date())
        case .notes:
            return notesCount > 0 ? "\(notesCount)" : nil
        case .analyse:
            return "month"
        }
    }

    private var rowBadgeColor: Color {
        switch row {
        case .todaysLog: return pendingDailyCount > 0 ? Color.purple : DS.Color.textTertiary
        case .notes:     return Color(red: 0.68, green: 0.45, blue: 0.98)
        default:         return DS.Color.textTertiary
        }
    }

    private var rowBadgeBackground: Color {
        switch row {
        case .todaysLog: return pendingDailyCount > 0 ? Color.purple.opacity(0.18) : Color.clear
        case .notes:     return Color(red: 0.38, green: 0.45, blue: 0.98).opacity(0.18)
        default:         return Color.clear
        }
    }
}
