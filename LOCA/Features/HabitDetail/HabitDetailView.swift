import SwiftUI
import SwiftData

// MARK: - HabitDetailView

/// Detail container for a selected habit.
///
/// ## Layout Architecture (Phase 5.5 — Integration)
///
/// Phase 5.1 used a `ScrollView { VStack { } }` shell that was correct for phases
/// that only embedded pure SwiftUI views. Phase 5.4's addition of `JournalTimelineView`
/// (which is itself a `List`) introduced a `List`-inside-`ScrollView` composition:
/// `List` has no intrinsic height, collapses to zero inside a `ScrollView`, and
/// renders the journal section as invisible on device.
///
/// The fix is to promote the root container to `List` with `Section`s — the exact
/// structure Apple uses in Health, Fitness, and Screen Time detail views. Each Phase 5.x
/// subview becomes a section or group of sections rather than a VStack child:
///
/// ```
/// List (.insetGrouped)
///   Section               ← header (board name, streak, target)
///   Section "History"     ← HeatmapView or empty-state label
///   Section               ← AnalyticsCardsView     } gated on !logs.isEmpty
///   Section "Today"       ← journal entries        }
///   Section "Yesterday"   ← journal entries        }
///   ...                                             }
/// ```
///
/// ## @Query Ownership (Phase 5.5)
///
/// `HabitDetailView` now owns a `@Query` on `LogEntry` filtered by `boardID`
/// (ADR-003 — not `board?.id`, which returns empty on iOS 17). This replaces
/// `!(board.logs ?? []).isEmpty` (a lazy-relationship read) for gating sections,
/// and provides the data for inlined journal sections without a nested view with
/// its own `List`. The query is timestamp-descending, matching journal display order.
///
/// `HeatmapView` and `AnalyticsCardsView` continue to manage their own `@State`
/// and `.task(id:)` triggers independently — this query does not replace their
/// internal data paths, only the gating logic and journal section data.
///
/// ## Check-In Integration (Phase 6.1)
///
/// `CheckInButton` is attached via `.safeAreaInset(edge: .bottom)`, which pushes
/// `List` content up and stays above the home indicator. The button manages its
/// own `@Query` on today's entries and `ModelContext` — `HabitDetailView` passes
/// only `board` to it.
struct HabitDetailView: View {

    let board: HabitBoard

    @Environment(\.modelContext) private var modelContext

    /// Drives the edit form sheet (Phase 7.2). The form is presented in
    /// `.edit(board)` mode and mutates the board in place on save.
    @State private var showingEditSheet = false

    /// ADR-003: filter on the denormalized `boardID` scalar.
    /// Sorted descending for journal display; HeatmapView and AnalyticsCardsView
    /// manage their own data paths and are not driven by this query.
    @Query private var logs: [LogEntry]

    private enum Layout {
        static let colorDotSize: CGFloat = 16
        static let horizontalPadding: CGFloat = 16
    }

    init(board: HabitBoard) {
        self.board = board
        let boardID = board.id
        _logs = Query(
            filter: #Predicate<LogEntry> { $0.boardID == boardID },
            sort: [SortDescriptor(\.timestamp, order: .reverse)]
        )
    }

    // MARK: - Derived State

    private var hasLogs: Bool { !logs.isEmpty }

    /// Day-grouped journal sections derived from the @Query result.
    /// Recomputed whenever `logs` changes (SwiftData @Query drives updates).
    private var journalSections: [JournalDaySection] {
        JournalGrouping.groupByDay(logs)
    }

    // MARK: - Body

    var body: some View {
        List {
            headerSection
            historySection
            if hasLogs {
                analyticsSection
                journalSections_
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(board.name)
        // Phase 6.1: CheckInButton attaches as a sticky bottom element via
        // .safeAreaInset. This modifier pushes List content up so nothing is
        // hidden behind the button, and the button stays above the home indicator.
        //
        // CheckInButton returns EmptyView for quantitative habits in Phase 6.1
        // (explicit scope gate). EmptyView has zero intrinsic height, so the
        // .safeAreaInset has no visual effect for quantitative boards until
        // Phase 6.2 replaces it with the sheet-presenting button.
        .safeAreaInset(edge: .bottom) {
            CheckInButton(board: board)
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(.thinMaterial)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEditSheet = true }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            HabitFormView(mode: .edit(board))
        }
    }

    // MARK: - Header Section

    // MARK: Accessibility: .contain, not .ignore
    //
    // HabitCardView (Phase 4) uses .accessibilityElement(children: .ignore) plus
    // a single synthesized label — the right call for a compact selectable List row.
    // This header is in a full-screen scrolling context; VoiceOver users benefit from
    // swiping through name, streak, best streak, and target as distinct grouped elements.
    // .contain preserves granularity while reading the group as a coherent unit.

    @ViewBuilder
    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
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
    }

    // MARK: - History Section (Phase 5.2)

    @ViewBuilder
    private var historySection: some View {
        Section("History") {
            if hasLogs {
                HeatmapView(board: board)
                    // Edge-to-edge insets: the heatmap's horizontal ScrollView needs
                    // full-width access. The default List row insets (16 pt each side)
                    // would clip the scrollable grid area.
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowSeparator(.hidden)
            } else {
                Label(
                    "Log \(board.name) to start building your history.",
                    systemImage: "square.grid.3x3"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Analytics Section (Phase 5.3)
    //
    // Gated on hasLogs. A board with zero entries has nothing meaningful to
    // summarize; "0%, 0, —" stat cards would be noise rather than information.
    // Not a Section with a header — consistent with Health app's unlabeled
    // stat-card blocks.

    @ViewBuilder
    private var analyticsSection: some View {
        Section {
            AnalyticsCardsView(board: board)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowSeparator(.hidden)
        }
    }

    // MARK: - Journal Sections (Phase 5.4)
    //
    // One Section per calendar day. `JournalGrouping.groupByDay` is called on the
    // already-sorted @Query result — no additional sort, no off-main-thread work.
    // `JournalEntryRow` is defined in JournalTimelineView.swift (internal access).
    // Swipe-to-delete works natively in a List context (not possible in LazyVStack,
    // which is why the root container is a List rather than a ScrollView).
    //
    // After deleting all entries for a day, that Section disappears automatically
    // because `journalSections` recomputes from `logs` (@Query updates reactively).
    // After deleting all entries, `hasLogs` becomes false and this entire block hides.

    @ViewBuilder
    private var journalSections_: some View {
        ForEach(journalSections) { daySection in
            Section {
                ForEach(daySection.entries) { entry in
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
                Text(JournalGrouping.headerTitle(for: daySection.dayStart))
            }
        }
    }

    // MARK: - Delete

    /// Hard-deletes a `LogEntry`. Exempt from the append-only check-in path constraint
    /// (ADR-001 exemption for LogEntry) — this is a deliberate user action.
    private func delete(_ entry: LogEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }

    // MARK: - Display Text
    //
    // Mirrors HabitCardView (Phase 4) exactly — same source data, same phrasing,
    // same "Best" visibility rule (shown only when it exceeds current).
    // Intentionally not extracted to a shared helper: Phase 4 was approved without
    // that extraction, and this is not a Phase 5.5 scope item.

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

