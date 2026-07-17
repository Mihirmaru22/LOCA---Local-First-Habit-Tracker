import SwiftUI
import SwiftData
import os

// MARK: - DashboardView

/// The sidebar column's content: a selectable list of active `HabitBoard`s
/// rendered as rich `HabitCardView` rows.
///
/// Replaces `HabitSidebarView` (Phase 3) at its single call site in
/// `RootNavigationView` — see ADR-008. Selection mechanics, the `List`-based
/// native sidebar chrome (`.listStyle(.sidebar)`, Phase 3 finding H1), and the
/// before-the-List empty-state branch (Phase 3 finding H2) are preserved exactly;
/// only the row content changed, from `HabitSidebarRow` to the richer
/// `HabitCardView`.
struct DashboardView: View {

    let boards: [HabitBoard]
    @Binding var selection: UUID?

    /// Called after a habit is created so the caller can auto-select it.
    var onBoardCreated: ((UUID) -> Void)?

    @Environment(\.modelContext) private var modelContext

    @State private var showingCreateSheet = false

    /// The board awaiting delete confirmation (Phase 7.2). Non-nil presents the
    /// confirmation alert; the actual removal is a soft-delete via `archive(in:)`.
    @State private var boardPendingDeletion: HabitBoard?

    /// Presents the failure alert if the archive save throws.
    @State private var showArchiveError = false

    private let logger = Logger(subsystem: "com.mihirmaru.loca", category: "HabitManagement")

    var body: some View {
        Group {
            if boards.isEmpty {
                EmptyDashboardPlaceholderView()
            } else {
                List(selection: $selection) {
                    ForEach(boards, id: \.id) { board in
                        HabitCardView(board: board)
                            .tag(board.id)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    boardPendingDeletion = board
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .navigationTitle("Habits")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Label("New Habit", systemImage: "plus")
                }
                .accessibilityLabel("New Habit")
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            HabitFormView(mode: .create, onBoardCreated: onBoardCreated)
        }
        .alert(
            "Delete \(boardPendingDeletion?.name ?? "Habit")?",
            isPresented: deletionConfirmationPresented,
            presenting: boardPendingDeletion
        ) { board in
            Button("Delete", role: .destructive) { archive(board) }
            Button("Cancel", role: .cancel) { boardPendingDeletion = nil }
        } message: { _ in
            Text("This removes it from your habits. Your logged entries are kept, not deleted.")
        }
        .alert("Couldn't Delete Habit", isPresented: $showArchiveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The habit couldn't be removed. Please try again.")
        }
    }

    // MARK: - Deletion (soft-delete via archive, ADR-001)

    /// Binding that keeps the confirmation alert presented while a board is
    /// pending and clears the pending board when the alert is dismissed.
    private var deletionConfirmationPresented: Binding<Bool> {
        Binding(
            get: { boardPendingDeletion != nil },
            set: { presented in if !presented { boardPendingDeletion = nil } }
        )
    }

    /// Soft-deletes a board per ADR-001 — sets `archivedAt` and saves via the
    /// model's canonical `archive(in:)`, which rolls back on failure. The board
    /// leaves the active `@Query` reactively; its `LogEntry` history is retained
    /// (the relationship is `.nullify`, never `.cascade`). If the archived board
    /// was selected, selection is cleared so the detail column doesn't strand.
    private func archive(_ board: HabitBoard) {
        defer { boardPendingDeletion = nil }
        do {
            try board.archive(in: modelContext)
            if selection == board.id { selection = nil }
            logger.debug("Board archived: '\(board.name, privacy: .public)'.")
        } catch {
            logger.error("Board archive failed: \(error.localizedDescription, privacy: .public)")
            showArchiveError = true
        }
    }
}

// MARK: - EmptyDashboardPlaceholderView

private struct EmptyDashboardPlaceholderView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Habits Yet", systemImage: "plus.circle")
        } description: {
            Text("Create your first habit to get started.")
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selection: UUID?

    let running = HabitBoard(name: "Running", metricType: HabitBoard.MetricType.quantitative.rawValue,
                              targetValue: 5.0, unitLabel: "mi", colorIndex: 0)
    running.currentStreak = 5
    running.longestStreak = 12

    let reading = HabitBoard(name: "Reading", colorIndex: 2)
    reading.currentStreak = 1
    reading.longestStreak = 1

    let meditate = HabitBoard(name: "Meditate", colorIndex: 5)

    return NavigationStack {
        DashboardView(boards: [running, reading, meditate], selection: $selection)
    }
}

#Preview("Empty State") {
    @Previewable @State var selection: UUID?

    NavigationStack {
        DashboardView(boards: [], selection: $selection)
    }
}
