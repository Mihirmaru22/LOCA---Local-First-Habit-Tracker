import SwiftUI
import SwiftData

// MARK: - RootNavigationView

/// The application's navigation shell. Adapts automatically to iPhone (compact),
/// iPad, and Mac (regular) via a single `NavigationSplitView` — see ADR-006 for
/// why this project does not branch into separate `NavigationStack`/
/// `NavigationSplitView` code paths per platform.
///
/// This is the project's "shared navigation infrastructure" referenced in the
/// Phase 3 scope: every other feature view eventually nests inside the detail
/// column this type owns. No separate router/`NavigationPath` abstraction exists
/// yet — at this phase, navigation is exactly one level deep (sidebar selection
/// → detail), so a router would be speculative complexity with nothing to route.
/// If a later phase needs multi-level drill-down within the detail column (e.g.,
/// Phase 6's journal entries), a `NavigationPath` can be introduced scoped to
/// that column specifically, without touching this type's sidebar/selection logic.
struct RootNavigationView: View {

    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    /// The selected board's identifier — not the board itself. See ADR-007 for
    /// why selection state holds `UUID?` rather than a live `HabitBoard?` reference.
    @State private var selectedBoardID: UUID?

    /// Determines whether auto-selection (see `autoSelectFirstBoardIfNeeded`) applies.
    /// `.compact` on iPhone; `.regular` on iPad (most orientations) and always on Mac.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// The single data source for the navigation shell. Uses `HabitBoard.activePredicate`
    /// (added in this phase, closing Phase 1 review finding M1) rather than an
    /// ad-hoc `archivedAt == nil` expression written here.
    @Query(filter: HabitBoard.activePredicate, sort: \HabitBoard.createdAt)
    private var activeBoards: [HabitBoard]

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // DashboardView (Phase 4) replaces HabitSidebarView (Phase 3) here —
            // see ADR-008. Same boards/selection signature; only the row content
            // changed, from HabitSidebarRow to the richer HabitCardView. Selection
            // mechanics (ADR-007), the @Query above, and autoSelectFirstBoardIfNeeded
            // below are unmodified by this swap.
            DashboardView(boards: activeBoards, selection: $selectedBoardID) { newID in
                selectedBoardID = newID
            }
            .navigationSplitViewColumnWidth(min: 280, ideal: 320)
        } detail: {
            if let board = selectedBoard {
                HabitDetailView(board: board)
            } else {
                EmptyDetailPlaceholderView(hasAnyBoards: !activeBoards.isEmpty)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .task {
            autoSelectFirstBoardIfNeeded()
        }
        // activeBoards.count (not the array itself) is observed here — @Model types
        // are not guaranteed Equatable, so onChange(of:) needs a comparable proxy
        // value. Covers the case where boards arrive asynchronously after this view's
        // first appearance (e.g. an initial CloudKit sync landing after launch),
        // which the one-time .task above would otherwise miss.
        .onChange(of: activeBoards.count) { _, _ in
            autoSelectFirstBoardIfNeeded()
        }
    }

    // MARK: Selection Resolution
    //
    // `selectedBoardID` is a UUID, not a live object — so resolving it back to a
    // HabitBoard means looking it up in `activeBoards` on every body evaluation.
    // This is intentionally cheap: activeBoards is bounded by realistic habit
    // counts (tens, not thousands), so a linear scan here is not a performance
    // concern. If the selected board is archived (or deleted) while selected,
    // this naturally resolves to nil next render — the detail column falls back
    // to EmptyDetailPlaceholderView with no special-case handling required.

    private var selectedBoard: HabitBoard? {
        guard let id = selectedBoardID else { return nil }
        return activeBoards.first { $0.id == id }
    }

    // MARK: Auto-Selection (Phase 3 review finding H3)
    //
    // Every first-party Apple split-view app (Mail, Notes, Reminders, Settings)
    // auto-selects the first item in a multi-column layout when nothing else is
    // selected and both columns are visible simultaneously. Omitting this made the
    // detail column show "No Habit Selected" even when habits existed and one was
    // immediately visible in the sidebar — a first launch on iPad/Mac looked
    // unfinished compared to the system apps it sits alongside.
    //
    // This must NOT apply on iPhone (compact width): NavigationSplitView collapses
    // to a single visible column there, and auto-selecting would skip the sidebar
    // list entirely on launch, jumping straight to detail content — the opposite of
    // how Mail/Notes/Reminders behave on iPhone, where the list is always the
    // starting point and detail requires an explicit tap. horizontalSizeClass is the
    // correct, idiomatic signal for this distinction: `.compact` only occurs on
    // iPhone; `.regular` covers iPad (non-slide-over) and is the only value macOS
    // ever reports.

    private func autoSelectFirstBoardIfNeeded() {
        guard horizontalSizeClass == .regular else { return }
        guard selectedBoardID == nil, let first = activeBoards.first else { return }
        selectedBoardID = first.id
    }
}

// MARK: - EmptyDetailPlaceholderView

/// Shown in the detail column when no habit is selected in the sidebar.
///
/// Private to this file: it has exactly one call site (`RootNavigationView`'s
/// `detail:` closure) and no platform-conditional logic, so it does not earn a
/// separate file under this project's "files don't earn their existence unless
/// reused or genuinely complex" discipline (the same reasoning that kept
/// `HapticEngine.swift` and `CloudKitConfig.swift` out of Phase 1).
///
/// Copy varies by `hasAnyBoards` (Phase 3 review finding M1): with `autoSelectFirstBoardIfNeeded`
/// now selecting the first board whenever one exists on regular-width layouts, this
/// view's "no selection" state should only genuinely occur when the user has zero
/// habits at all. In that case, telling them to "choose a habit from the sidebar" is
/// contradictory — the sidebar has nothing to choose, and already displays its own
/// "Create your first habit" guidance. The zero-boards copy here avoids repeating or
/// conflicting with that message.
private struct EmptyDetailPlaceholderView: View {

    /// `true` if at least one active board exists — even if none is currently selected
    /// (e.g. transiently, before `autoSelectFirstBoardIfNeeded` runs, or on compact
    /// width where auto-selection intentionally does not apply).
    let hasAnyBoards: Bool

    var body: some View {
        ContentUnavailableView {
            Label("No Habit Selected", systemImage: "checklist")
        } description: {
            Text(hasAnyBoards
                 ? "Choose a habit from the sidebar to see its details."
                 : "Your habit details will appear here once you create one.")
        }
    }
}

// MARK: - Preview

// MARK: Preview Fixture Setup (root-cause fix)
//
// #Preview's macro-synthesized closure applies a ViewBuilder-style transform
// to every statement inside it. Declarations and function calls pass through,
// but a bare property assignment (e.g. `running.currentStreak = 5`) is an
// expression evaluating to Void — the transform attempts to treat it as a
// buildExpression argument, which requires View conformance, producing
// "Type '()' cannot conform to View." The real issue wasn't that one line:
// it's that imperative fixture setup doesn't belong inside a View-building
// closure at all. Extracting it into this plain function removes it from the
// ViewBuilder transform entirely — ordinary Swift functions have no such
// restriction. Called once, synchronously, before the Preview closure ever
// starts building a view; no .task/.onAppear needed, since this is static
// fixture data with no reason to introduce async timing into a Preview.

@MainActor
private func makeSeededPreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainerFactory.makeInMemoryContainer() else {
        return nil
    }
    let context = container.mainContext

    let running = HabitBoard(name: "Running", metricType: HabitBoard.MetricType.quantitative.rawValue,
                              targetValue: 3.0, unitLabel: "mi", colorIndex: 0)
    running.currentStreak = 5
    let reading = HabitBoard(name: "Reading", colorIndex: 2)
    reading.currentStreak = 12
    let meditate = HabitBoard(name: "Meditate", colorIndex: 5)

    context.insert(running)
    context.insert(reading)
    context.insert(meditate)

    return container
}

#Preview {
    if let container = makeSeededPreviewContainer() {
        RootNavigationView()
            .modelContainer(container)
    } else {
        // Avoids `try!` per Phase 1 review finding M4 — a failed Preview container
        // degrades to a visible error state rather than crashing the canvas.
        ContentUnavailableView(
            "Preview Unavailable",
            systemImage: "exclamationmark.triangle"
        )
    }
}

#Preview("Zero Boards") {
    // Exercises the M1 fix: EmptyDetailPlaceholderView's non-contradictory copy
    // when hasAnyBoards is false, alongside HabitSidebarView's own empty state.
    if let container = try? ModelContainerFactory.makeInMemoryContainer() {
        RootNavigationView()
            .modelContainer(container)
    } else {
        ContentUnavailableView(
            "Preview Unavailable",
            systemImage: "exclamationmark.triangle"
        )
    }
}
