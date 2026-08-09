import SwiftUI
import SwiftData

// MARK: - MacHabitContentColumn   (H1)

/// Middle column of the Mac three-pane layout for the Habits section.
///
/// Renders a plain `List` of habits with native macOS row selection, so the
/// selected habit propagates to `MacHabitDetailColumn` via the `selection`
/// binding without any custom hit-testing or gesture work.
///
/// `@Query` here (not in the parent) keeps this column self-contained: when
/// the user adds a habit the list updates automatically without the parent
/// needing to thread the data through.
///
/// Check-in (binary tap) is handled in-list exactly as on iOS — `CheckInWriter`
/// writes the log entry, Haptics fires, and the detail column's query reacts.
struct MacHabitContentColumn: View {

    @Binding var selection: HabitBoard?

    @Query(filter: #Predicate<HabitBoard> { board in
        board.habitKindRaw == 0 && board.archivedAt == nil
    }, sort: [SortDescriptor(\HabitBoard.name)], animation: .default)
    private var boards: [HabitBoard]

    @Environment(\.modelContext) private var modelContext
    @State private var showingCreateSheet = false
    @State private var showCheckInError   = false

    var body: some View {
        List(boards, id: \.id, selection: $selection) { board in
            MacHabitRow(board: board, onCheckBinary: { checkInBinary(board) })
                .tag(board)
        }
        .listStyle(.inset)    // macOS: use .inset (.insetGrouped is iOS/Catalyst only)
        .navigationTitle("Habits")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("New Habit (⌘N)")
                .keyboardShortcut("n", modifiers: .command)
                .focusedValue(\.newHabitAction, { showingCreateSheet = true })
            }
        }
        .overlay {
            if boards.isEmpty {
                ContentUnavailableView {
                    Label("No Habits", systemImage: "checkmark.circle")
                } description: {
                    Text("Press ⌘N or the + button to create your first habit.")
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            MacHabitFormPanel()
        }
        .alert("Couldn't Save Check-in", isPresented: $showCheckInError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The check-in couldn't be saved. Please try again.")
        }
    }

    private func checkInBinary(_ board: HabitBoard) {
        do {
            try CheckInWriter.toggleBinary(board: board, context: modelContext)
            Haptics.impact(.rigid)
        } catch {
            showCheckInError = true
        }
    }
}

// MARK: - MacHabitRow

/// A single row in the habits content list.
///
/// Compact: colour dot + name + today-progress label + binary check circle.
/// Mirrors the information density of `HabitListRow` while fitting the
/// narrower middle column (min 280 pt).
private struct MacHabitRow: View {

    let board: HabitBoard
    let onCheckBinary: () -> Void

    private var todaysTotal: Double {
        (board.logs ?? [])
            .filter { $0.timestamp.isToday() }
            .reduce(0.0) { $0 + $1.value }
    }

    private var progressFraction: Double {
        max(0, min(1, todaysTotal / board.effectiveTarget))
    }

    private var isDone: Bool { progressFraction >= 1 }

    var body: some View {
        HStack(spacing: DS.Space.md) {
            // Colour indicator
            Circle()
                .fill(ColorPalette[board.colorIndex])
                .frame(width: 10, height: 10)

            // Name
            Text(board.name)
                .lineLimit(1)
                .foregroundStyle(isDone ? DS.Color.textSecondary : DS.Color.textPrimary)

            Spacer()

            // Progress / value label
            if board.metric == .quantitative {
                Text(todaysTotal.formatted(.number.precision(.fractionLength(0...1))))
                    .font(DS.Text.valueCompact)
                    .foregroundStyle(DS.Color.textSecondary)
                    + Text(" / \(board.effectiveTarget.formatted(.number.precision(.fractionLength(0...1))))")
                        .font(DS.Text.valueCompact)
                        .foregroundStyle(DS.Color.textTertiary)
            }

            // Binary check circle
            if board.metric == .binary {
                Button(action: onCheckBinary) {
                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(
                            isDone ? ColorPalette[board.colorIndex] : DS.Color.textTertiary
                        )
                }
                .buttonStyle(.plain)
                .help(isDone ? "Undo check-in" : "Mark done for today")
            }
        }
        .padding(.vertical, DS.Space.xs)
        .contentShape(Rectangle())
    }
}
