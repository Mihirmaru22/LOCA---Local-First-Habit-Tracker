import SwiftUI
import SwiftData

// MARK: - HabitDetailView

/// Detail container for a selected habit.
///
/// Phase 5.1 scope: layout, section structure, and empty states only — no
/// heatmap grid (Phase 5.2). The header section reuses the exact streak/target
/// display logic established in Phase 4's `HabitCardView` (no new computation),
/// scaled up for a full-screen detail context. The history section distinguishes
/// two genuinely different empty states: a board with zero log entries ("No
/// History Yet") versus a board with logs but no grid to show them in yet
/// ("Heatmap Coming Soon") — these are not the same state and should not share
/// the same message.
///
/// Phase 5.4 addition: `journalSection` embedded below `analyticsSection`,
/// gated on the same `hasAnyLogs` guard. `JournalTimelineView` owns its own
/// `@Query` against `LogEntry` — `HabitDetailView` passes `board` only.
struct HabitDetailView: View {

    let board: HabitBoard

    private enum Layout {
        static let sectionSpacing: CGFloat = 24
        static let headerSpacing: CGFloat = 8
        static let colorDotSize: CGFloat = 16
        static let horizontalPadding: CGFloat = 16
        static let placeholderMinHeight: CGFloat = 200
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                headerSection
                historySection
                if hasAnyLogs {
                    analyticsSection
                    journalSection
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.vertical, Layout.sectionSpacing)
        }
        .navigationTitle(board.name)
    }

    // MARK: - Analytics Section (Phase 5.3)
    //
    // Gated on hasAnyLogs — the same property historySection already uses.
    // No new empty-state needed: a board with zero logs has nothing
    // meaningful to summarize, and showing "0%, 0, —" stat cards would be
    // noise rather than useful information.

    private var analyticsSection: some View {
        AnalyticsCardsView(board: board)
    }

    // MARK: - Journal Section (Phase 5.4)
    //
    // Also gated on hasAnyLogs: a board with no entries has no journal to display.
    // JournalTimelineView shows its own ContentUnavailableView if the @Query
    // returns empty results after the gate passes (e.g., all entries deleted
    // within the session before the board relationship flushes).

    private var journalSection: some View {
        VStack(alignment: .leading, spacing: Layout.headerSpacing) {
            Text("Journal")
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)
            JournalTimelineView(board: board)
        }
    }

    // MARK: - Header Section

    // MARK: Accessibility: .contain, not .ignore (contrast with HabitCardView)
    //
    // HabitCardView (Phase 4) uses .accessibilityElement(children: .ignore) plus
    // a single synthesized label because it is compact List row content — one
    // collapsed announcement is the efficient choice for scanning a sidebar list.
    // This header sits in a full-screen scrolling detail context instead, where
    // VoiceOver users benefit from swiping through name, streak, best streak, and
    // target as distinct but grouped elements rather than one dense sentence.
    // .contain preserves that granularity while still reading the group as a
    // single coherent unit when swiped past.

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Layout.headerSpacing) {
            HStack(spacing: 10) {
                Circle()
                    .fill(ColorPalette[board.colorIndex])
                    .frame(width: Layout.colorDotSize, height: Layout.colorDotSize)
                Text(board.name)
                    .font(.title2.bold())
            }

            Label(streakText, systemImage: "flame.fill")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if board.longestStreak > board.currentStreak {
                Label(bestStreakText, systemImage: "trophy.fill")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(targetText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - History Section (Phase 5.2 replaced the placeholder)

    private var historySection: some View {
        VStack(alignment: .leading, spacing: Layout.headerSpacing) {
            Text("History")
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)

            if hasAnyLogs {
                HeatmapView(board: board)
            } else {
                ContentUnavailableView {
                    Label("No History Yet", systemImage: "square.grid.3x3")
                } description: {
                    Text("History for this habit will appear here once you start logging it.")
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: Layout.placeholderMinHeight)
            }
        }
    }

    // MARK: - Derived State

    /// `true` if this board has at least one log entry, regardless of when it
    /// was recorded. Distinguishes the two history-section empty states above.
    /// A single boolean check over an already-loaded relationship — not a new
    /// compute algorithm.
    private var hasAnyLogs: Bool {
        !(board.logs ?? []).isEmpty
    }

    // MARK: - Display Text
    //
    // Mirrors HabitCardView's (Phase 4) streakText/bestStreakText/targetText
    // exactly — same source data, same phrasing, same "Best" visibility rule
    // (shown only when it differs from current). Intentionally duplicated rather
    // than extracted into a shared helper: Phase 4 was approved without that
    // extraction being requested, and this phase's scope is layout/foundation,
    // not a refactor of Phase 4's approved architecture.

    private var streakText: String {
        board.currentStreak == 1 ? "1 day streak" : "\(board.currentStreak) day streak"
    }

    private var bestStreakText: String {
        "Best: \(board.longestStreak) days"
    }

    private var targetText: String {
        switch board.metric {
        case .binary:
            return "Check off daily"
        case .quantitative:
            let unit = board.unitLabel ?? ""
            let target = board.effectiveTarget.formatted(.number.precision(.fractionLength(0...1)))
            return "Goal: \(target) \(unit)/day"
        }
    }
}

// MARK: - Preview

// JournalTimelineView (embedded in Phase 5.4) uses @Query, which requires a
// ModelContainer in the environment. All previews below use in-memory containers
// via @MainActor helper functions per the established preview helper pattern.

@MainActor
private func makeDetailWithHistoryContainer() -> (ModelContainer, HabitBoard) {
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
    board.currentStreak = 5
    board.longestStreak = 12
    container.mainContext.insert(board)

    let calendar = Calendar.current
    let notes: [String?] = ["Felt great today.", nil, "Rain but worth it.", nil, "Easy 3 miles."]
    for (offset, note) in notes.enumerated() {
        guard let day = calendar.date(byAdding: .day, value: -offset, to: .now) else { continue }
        let entry = LogEntry(
            timestamp: day,
            value: Double.random(in: 2...6),
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
private func makeDetailNoHistoryContainer() -> (ModelContainer, HabitBoard) {
    let schema = Schema([HabitBoard.self, LogEntry.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let board = HabitBoard(name: "Meditate", colorIndex: 5)
    container.mainContext.insert(board)
    try? container.mainContext.save()
    return (container, board)
}

#Preview("With History") {
    let (container, board) = makeDetailWithHistoryContainer()
    return NavigationStack {
        HabitDetailView(board: board)
    }
    .modelContainer(container)
}

#Preview("No History") {
    let (container, board) = makeDetailNoHistoryContainer()
    return NavigationStack {
        HabitDetailView(board: board)
    }
    .modelContainer(container)
}
