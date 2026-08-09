import SwiftUI

// MARK: - MacHabitFormPanel   (H6)

/// macOS wrapper for `SimpleHabitCreationView`.
///
/// On macOS, habit creation is presented as a sheet over the main window
/// (triggered by the + toolbar button or ⌘N). `SimpleHabitCreationView` is
/// fully cross-platform; this wrapper applies Mac-specific frame constraints
/// and disables the sheet's drag-to-dismiss behaviour (not applicable on macOS
/// but explicit for clarity).
///
/// Wiring path:
///  ⌘N in menu  → LOCACommands reads FocusedValue(\.newHabitAction)
///              → MacHabitContentColumn.showingCreateSheet = true
///              → .sheet { MacHabitFormPanel() }
///
/// If a future version needs a dedicated creation *window* (File → New Habit
/// in its own window), add a `WindowGroup("New Habit", id: "new-habit")`
/// scene to `LOCAMacApp.body` and open it with `openWindow(id: "new-habit")`.
struct MacHabitFormPanel: View {

    var body: some View {
        SimpleHabitCreationView()
            .frame(minWidth: 380, idealWidth: 480, minHeight: 440, idealHeight: 520)
            .interactiveDismissDisabled(false)
    }
}
