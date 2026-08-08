import SwiftUI

// MARK: - MacSection

/// Top-level navigation sections shown in the Mac sidebar.
/// Ordered to match the natural daily workflow: check habits first,
/// then review today's completions, then journal.
enum MacSection: String, CaseIterable, Identifiable {
    case habits  = "Habits"
    case today   = "Today"
    case journal = "Journal"
    case life    = "Life"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .habits:  "checkmark.circle"
        case .today:   "sun.max"
        case .journal: "book.closed"
        case .life:    "binoculars"
        }
    }
}

// MARK: - MacRootView

/// Three-pane root for the macOS app.
///
/// Column roles:
/// - **Sidebar** (`MacSidebarView`): section picker (Habits, Today, Journal, Life).
/// - **Content** (`MacHabitContentColumn` etc.): list for the active section.
/// - **Detail** (`MacHabitDetailColumn` etc.): selected-item detail.
///
/// `selectedHabit` is owned here so it spans both the content and detail columns
/// without either column owning the other. The content column writes it via a
/// `@Binding`; the detail column reads it as a plain `let`.
struct MacRootView: View {

    @State private var selectedSection: MacSection? = .habits
    @State private var selectedHabit:   HabitBoard? = nil
    @State private var selectedTodo:    TodoItem?   = nil
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            MacSidebarView(selection: $selectedSection)
                .navigationSplitViewColumnWidth(
                    min:   DS.Mac.sidebarMinWidth,
                    ideal: DS.Mac.sidebarIdealWidth,
                    max:   DS.Mac.sidebarMaxWidth
                )
        } content: {
            MacContentColumn(section: selectedSection,
                             selectedHabit: $selectedHabit,
                             selectedTodo:  $selectedTodo)
                .navigationSplitViewColumnWidth(min: DS.Mac.contentMinWidth, ideal: 320)
        } detail: {
            MacDetailColumn(section: selectedSection,
                            selectedHabit: selectedHabit,
                            selectedTodo:  selectedTodo)
                .navigationSplitViewColumnWidth(min: DS.Mac.detailMinWidth)
        }
        .navigationTitle("LOCA")
        .onChange(of: selectedSection) { _, _ in
            // Clear all item selections when the user switches sections.
            selectedHabit = nil
            selectedTodo  = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: .locaJumpToSection)) { note in
            if let section = note.object as? MacSection {
                selectedSection = section
            }
        }
    }
}

// MARK: - MacContentColumn

/// Picks the correct content list for the active sidebar section.
private struct MacContentColumn: View {

    let section: MacSection?
    @Binding var selectedHabit: HabitBoard?
    @Binding var selectedTodo:  TodoItem?

    var body: some View {
        switch section {
        case .habits:
            MacHabitContentColumn(selection: $selectedHabit)
        case .today:
            MacTodoContentColumn(selection: $selectedTodo)
        case .journal:
            MacJournalContentView()
        case .life:
            MacLifeContentView()
        case nil:
            MacEmptyContentView()
        }
    }
}

// MARK: - MacDetailColumn

/// Picks the correct detail view for the active section and selection.
private struct MacDetailColumn: View {

    let section: MacSection?
    let selectedHabit: HabitBoard?
    let selectedTodo:  TodoItem?

    var body: some View {
        switch section {
        case .habits:
            MacHabitDetailColumn(habit: selectedHabit)
        case .today:
            MacTodoDetailColumn(item: selectedTodo)
        default:
            MacDetailPlaceholder()
        }
    }
}

// MARK: - Stub content views
// Replaced as their chapters land: MacTodayContentView → MacTodoContentColumn (T2).

struct MacJournalContentView: View {
    var body: some View {
        ContentUnavailableView("Journal", systemImage: "book.closed",
                               description: Text("Coming in J-chapter"))
    }
}

struct MacLifeContentView: View {
    var body: some View {
        ContentUnavailableView("Life", systemImage: "binoculars",
                               description: Text("Coming in S-chapter"))
    }
}

private struct MacEmptyContentView: View {
    var body: some View {
        ContentUnavailableView("No Section Selected", systemImage: "sidebar.left")
    }
}

// MARK: - MacDetailPlaceholder

struct MacDetailPlaceholder: View {
    var body: some View {
        ContentUnavailableView(
            "Select an Item",
            systemImage: "arrow.left.to.line",
            description: Text("Choose a habit from the list to see its detail.")
        )
    }
}

// MARK: - Preview

#Preview {
    MacRootView()
}
