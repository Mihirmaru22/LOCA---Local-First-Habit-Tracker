//
//  JournalTimelineView.swift
//  LOCA
//
//  Phase 5.4 — Journal Timeline
//
//  Displays a reverse-chronological, day-grouped list of LogEntry records
//  for a given HabitBoard. Notes are surfaced inline; entries without a note
//  still appear as time-stamped value indicators to give the timeline visual
//  density and allow swipe-to-delete of any entry.
//
//  Architecture notes:
//  - @Query filters on `boardID` (ADR-003) — not `board?.id`, which silently
//    returns empty results on iOS 17 due to a SwiftData framework limitation.
//  - Day-grouping runs on the already-fetched, already-sorted query result via
//    a computed property. No off-main-thread work is needed: this is O(n_entries)
//    with two cheap Array operations (filter via Dictionary grouping + map).
//    The Heatmap (Phase 5.2) owns the off-thread pre-computation story for
//    full-history aggregation; the journal's window is much smaller.
//  - List (not LazyVStack in ScrollView) is intentional: native swipe-to-delete,
//    platform-correct row chrome, and built-in laziness without manual LazyVStack
//    sizing hacks. LazyVGrid/LazyHGrid is reserved for the heatmap's 2D layout.
//  - Delete is a hard delete (modelContext.delete) — the append-only constraint
//    applies to LogEntry at the *check-in* path. Explicit user deletion of a
//    journal entry is a separate, deliberate action and performs a real store
//    removal per the soft-delete ADR-001 exemption for LogEntry.
//

import SwiftUI
import SwiftData

// MARK: - Day Section Model

/// A single day's log entries, used to drive `List` sectioning.
///
/// Not persisted — purely a view-layer grouping construct built from the
/// already-loaded `@Query` result. Conforms to `Identifiable` via `dayStart`,
/// which is Calendar-normalized (time components zeroed) and therefore unique
/// per calendar day.
struct JournalDaySection: Identifiable {
    /// Calendar-normalized day start (time components zeroed). Unique per section.
    let id: Date
    let dayStart: Date
    let entries: [LogEntry]
}

// MARK: - Grouping Helpers

enum JournalGrouping {

    /// Groups a timestamp-descending array of `LogEntry` into `JournalDaySection`
    /// values, preserving descending order for both sections and entries within
    /// each section.
    ///
    /// Input is expected to arrive sorted timestamp-descending from the `@Query`
    /// in `JournalTimelineView`. The output section order mirrors the input order:
    /// most-recent day first.
    ///
    /// Time complexity: O(n) — one pass to bucket, one pass to map.
    ///
    /// - Parameters:
    ///   - logs: Timestamp-descending `LogEntry` array from a `@Query`.
    ///   - calendar: Calendar for day boundary computation. Pass `.current`.
    /// - Returns: Day sections in descending order (most recent first).
    @MainActor
    static func groupByDay(
        _ logs: [LogEntry],
        calendar: Calendar = .current
    ) -> [JournalDaySection] {
        guard !logs.isEmpty else { return [] }

        var buckets: [Date: [LogEntry]] = [:]
        var order: [Date] = []

        for log in logs {
            let dayStart = calendar.startOfDay(for: log.timestamp)
            if buckets[dayStart] == nil {
                buckets[dayStart] = []
                order.append(dayStart)
            }
            buckets[dayStart]?.append(log)
        }

        return order.map { day in
            JournalDaySection(id: day, dayStart: day, entries: buckets[day] ?? [])
        }
    }

    /// Returns a human-readable section header string for a given day.
    ///
    /// - "Today" for `calendar.isDateInToday`
    /// - "Yesterday" for `calendar.isDateInYesterday`
    /// - "EEEE, MMM d" (e.g., "Monday, Jul 7") for all earlier dates
    ///
    /// - Parameters:
    ///   - dayStart: Calendar-normalized day start (time zeroed).
    ///   - calendar: Calendar for relativity checks. Pass `.current`.
    static func headerTitle(for dayStart: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(dayStart)     { return "Today" }
        if calendar.isDateInYesterday(dayStart) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEEMMMd")
        return formatter.string(from: dayStart)
    }
}

// MARK: - JournalTimelineView

struct JournalTimelineView: View {

    @Environment(\.modelContext) private var modelContext
    let board: HabitBoard

    /// ADR-003: predicate targets the denormalized `boardID` scalar.
    /// Using `$0.board?.id == boardID` silently returns empty results on iOS 17.
    @Query private var logs: [LogEntry]

    init(board: HabitBoard) {
        self.board = board
        let boardID = board.id
        _logs = Query(
            filter: #Predicate<LogEntry> { $0.boardID == boardID },
            sort: [SortDescriptor(\.timestamp, order: .reverse)]
        )
    }

    private var sections: [JournalDaySection] {
        JournalGrouping.groupByDay(logs)
    }

    var body: some View {
        Group {
            if sections.isEmpty {
                ContentUnavailableView(
                    "No Entries Yet",
                    systemImage: "text.book.closed",
                    description: Text("Log \(board.name) to start building your journal.")
                )
            } else {
                List {
                    ForEach(sections) { section in
                        Section {
                            ForEach(section.entries) { entry in
                                JournalEntryRow(entry: entry, board: board)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            delete(entry)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        } header: {
                            Text(JournalGrouping.headerTitle(for: section.dayStart))
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Delete

    /// Hard-deletes a `LogEntry` from the store and saves immediately.
    ///
    /// This is a deliberate user-initiated action, exempt from the append-only
    /// invariant that governs the check-in path. The owning board's streak cache
    /// is not re-computed here: a deletion older than today cannot affect
    /// `currentStreak`, and `StreakCalculator` handles full recalculation on
    /// the next launch cycle if `needsStreakRecalculation` is set.
    private func delete(_ entry: LogEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }
}

// MARK: - Row

struct JournalEntryRow: View {

    let entry: LogEntry
    let board: HabitBoard

    private var isBinary: Bool { board.metric == .binary }

    private var timeString: String {
        entry.timestamp.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            valueIndicator
                .frame(width: 52, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(timeString)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    /// Renders a checkmark for binary habits; a rounded numeric value + unit for
    /// quantitative habits. Both use the board's palette color (ADR-002).
    @ViewBuilder
    private var valueIndicator: some View {
        if isBinary {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(ColorPalette[board.colorIndex])
        } else {
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.value.formatted(.number.precision(.fractionLength(0...2))))
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(ColorPalette[board.colorIndex])
                if let unit = board.unitLabel, !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Preview

// JournalTimelineView uses @Query, which requires a ModelContainer in the
// environment. Previews use in-memory containers via @MainActor helper
// functions per the established preview helper pattern (Engineering Principles §6).

@MainActor
private func makeQuantitativePreviewContainer() -> (ModelContainer, HabitBoard) {
    let schema = Schema([HabitBoard.self, LogEntry.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])

    let board = HabitBoard(
        name: "Running",
        metricType: HabitBoard.MetricType.quantitative.rawValue,
        targetValue: 5.0,
        unitLabel: "mi",
        colorIndex: 0
    )
    container.mainContext.insert(board)

    let calendar = Calendar.current
    let notes = [
        "Felt strong today, great pace.",
        nil,
        "Tough morning but pushed through.",
        nil,
        "Personal best — 6.2 miles.",
        nil,
        "Easy recovery run."
    ]
    for (offset, note) in notes.enumerated() {
        guard let day = calendar.date(byAdding: .day, value: -offset, to: .now) else { continue }
        let entry = LogEntry(
            timestamp: day,
            value: Double.random(in: 2...7),
            note: note,
            boardID: board.id,
            board: board
        )
        container.mainContext.insert(entry)
    }

    try? container.mainContext.save()
    return (container, board)
}

@MainActor
private func makeBinaryPreviewContainer() -> (ModelContainer, HabitBoard) {
    let schema = Schema([HabitBoard.self, LogEntry.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])

    let board = HabitBoard(name: "Meditate", colorIndex: 3)
    container.mainContext.insert(board)

    let calendar = Calendar.current
    for offset in 0..<4 {
        guard let day = calendar.date(byAdding: .day, value: -offset, to: .now) else { continue }
        let entry = LogEntry(
            timestamp: day,
            value: 1.0,
            note: offset == 0 ? "10 minutes, focused." : nil,
            boardID: board.id,
            board: board
        )
        container.mainContext.insert(entry)
    }

    try? container.mainContext.save()
    return (container, board)
}

#Preview("Quantitative") {
    let (container, board) = makeQuantitativePreviewContainer()
    return JournalTimelineView(board: board)
        .modelContainer(container)
}

#Preview("Binary") {
    let (container, board) = makeBinaryPreviewContainer()
    return JournalTimelineView(board: board)
        .modelContainer(container)
}

#Preview("Empty") {
    let schema = Schema([HabitBoard.self, LogEntry.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let board = HabitBoard(name: "Reading", colorIndex: 1)
    container.mainContext.insert(board)
    return JournalTimelineView(board: board)
        .modelContainer(container)
}
