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
/// - **Content** (section list): list of habits / entries / entries for the day.
/// - **Detail** (item detail): selected-item detail or placeholder.
///
/// `columnVisibility` starts at `.all` so all three columns appear on first
/// launch; the user can collapse sidebar or detail via the View menu.
struct MacRootView: View {

    @State private var selectedSection: MacSection? = .habits
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
            MacContentColumn(section: selectedSection)
                .navigationSplitViewColumnWidth(min: DS.Mac.contentMinWidth, ideal: 320)
        } detail: {
            MacDetailPlaceholder()
        }
        .navigationTitle("LOCA")
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

    var body: some View {
        switch section {
        case .habits:
            HabitListView()
        case .today:
            MacTodayContentView()
        case .journal:
            MacJournalContentView()
        case .life:
            MacLifeContentView()
        case nil:
            MacEmptyContentView()
        }
    }
}

// MARK: - Stub content views
// These stubs keep the three-pane shell compilable before H/J/Life content
// columns are built out. Each stub is replaced in its own chapter.

struct MacTodayContentView: View {
    var body: some View {
        ContentUnavailableView("Today", systemImage: "sun.max", description: Text("Coming in H-chapter"))
    }
}

struct MacJournalContentView: View {
    var body: some View {
        ContentUnavailableView("Journal", systemImage: "book.closed", description: Text("Coming in J-chapter"))
    }
}

struct MacLifeContentView: View {
    var body: some View {
        ContentUnavailableView("Life", systemImage: "binoculars", description: Text("Coming in S-chapter"))
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
