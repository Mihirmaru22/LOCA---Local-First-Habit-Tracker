import SwiftUI

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

    @State private var showingCreateSheet = false

    var body: some View {
        Group {
            if boards.isEmpty {
                EmptyDashboardPlaceholderView()
            } else {
                List(selection: $selection) {
                    ForEach(boards, id: \.id) { board in
                        HabitCardView(board: board)
                            .tag(board.id)
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
            HabitFormView(mode: .create)
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
