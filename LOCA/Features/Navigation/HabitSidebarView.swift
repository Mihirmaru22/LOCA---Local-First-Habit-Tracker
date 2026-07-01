import SwiftUI

// MARK: - HabitSidebarView

/// The sidebar column: a selectable list of active (non-archived) `HabitBoard`s.
///
/// Receives `boards` and `selection` from `RootNavigationView` rather than running
/// its own `@Query` — keeping the data source single-sourced at the navigation
/// shell's root, with this view as a pure presentation layer over what it's given.
/// This also makes the view trivially previewable with synthetic data with no
/// `ModelContainer` required for the list-rendering logic itself.
///
/// The empty-state branch is resolved **before** entering `List`, not as a row
/// inside it (Phase 3 review finding H2). Embedding an untagged placeholder as
/// `List` row content leaves it sitting inside a selectable container despite not
/// being a selectable value, which produces incorrect interaction chrome (hover/press
/// highlight on macOS) on content that does nothing when interacted with. Apple's own
/// `NavigationSplitView` sample code consistently branches at the view level instead.
struct HabitSidebarView: View {

    let boards: [HabitBoard]
    @Binding var selection: UUID?

    var body: some View {
        Group {
            if boards.isEmpty {
                EmptySidebarPlaceholderView()
            } else {
                List(selection: $selection) {
                    // Explicit `id:` rather than relying on implicit inference —
                    // consistent with this project's established preference for
                    // explicit declarations over inferred behaviour (see Phase 1
                    // finding H2, where an inferred relationship inverse was made
                    // explicit for the same reason). Note: `HabitBoard` already
                    // conforms to `Identifiable` via its own `id: UUID` property,
                    // so this is a harmless, explicit restatement rather than an
                    // override of any macro-synthesized behaviour.
                    ForEach(boards, id: \.id) { board in
                        HabitSidebarRow(board: board)
                            .tag(board.id)
                    }
                }
                // Without this, a List used as a NavigationSplitView sidebar does NOT
                // automatically adopt native sidebar chrome (translucent vibrancy
                // background, sidebar row insets/selection style) on macOS or iPadOS —
                // it renders as a plain list instead. This was Phase 3 review finding H1.
                .listStyle(.sidebar)
            }
        }
        .navigationTitle("Habits")
    }
}

// MARK: - HabitSidebarRow

private enum Layout {
    static let colorDotSize: CGFloat = 10
}

/// A single row in the habit sidebar: colour swatch, name, and current streak.
///
/// Deliberately minimal — per Engineering Principles §6.4, a fuller accessibility
/// pattern including "today status" (logged/not logged) belongs to Phase 4's
/// `HabitCardView`, the Dashboard's documented home for that richer presentation.
/// This row exists purely for navigation: identify the habit, show its streak,
/// let the user select it.
private struct HabitSidebarRow: View {

    let board: HabitBoard

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(ColorPalette[board.colorIndex])
                .frame(width: Layout.colorDotSize, height: Layout.colorDotSize)

            VStack(alignment: .leading, spacing: 2) {
                Text(board.name)
                    .font(.body)
                Text(streakLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(board.name), \(streakLabel)")
    }

    private var streakLabel: String {
        board.currentStreak == 1 ? "1 day streak" : "\(board.currentStreak) day streak"
    }
}

// MARK: - EmptySidebarPlaceholderView

/// Shown when the user has no active habits at all (a brand-new install, or
/// every habit has been archived).
///
/// Informational only — no "+ New Habit" call-to-action button. That requires
/// navigating to `NewHabitForm`, which doesn't exist until Phase 7 (Habit
/// Management). A button that goes nowhere would fail the project's own
/// "feels like a first-party Apple feature" bar.
private struct EmptySidebarPlaceholderView: View {
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

    let running = HabitBoard(name: "Running", colorIndex: 0)
    running.currentStreak = 5
    let reading = HabitBoard(name: "Reading", colorIndex: 2)
    reading.currentStreak = 1
    let meditate = HabitBoard(name: "Meditate", colorIndex: 5)
    meditate.currentStreak = 0

    return NavigationStack {
        HabitSidebarView(boards: [running, reading, meditate], selection: $selection)
    }
}

#Preview("Empty State") {
    @Previewable @State var selection: UUID?

    NavigationStack {
        HabitSidebarView(boards: [], selection: $selection)
    }
}
