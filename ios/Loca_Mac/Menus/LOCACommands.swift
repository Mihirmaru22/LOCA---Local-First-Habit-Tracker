import SwiftUI

// MARK: - LOCACommands

/// LOCA's native macOS menu bar commands.
///
/// Registered on the `WindowGroup` scene via `.commands { LOCACommands() }`.
/// Each `CommandMenu` appears in the menu bar between the built-in Edit and
/// Window menus. Keyboard shortcuts follow macOS conventions:
/// - ⌘N  New Habit (mirrors typical "New Item" across Mac apps)
/// - ⌘L  Log Today (L for Log)
/// - ⌘1–4 Jump to sidebar section
struct LOCACommands: Commands {

    // MARK: - Focus values

    /// Allows views deep in the hierarchy to vend actions up to the menu bar
    /// without tightly coupling to specific parent views. Commands read these
    /// values; views write them via `.focusedValue(_:_:)`.
    @FocusedValue(\.newHabitAction) private var newHabitAction
    @FocusedValue(\.logTodayAction) private var logTodayAction

    var body: some Commands {
        // MARK: Habit menu
        CommandMenu("Habit") {
            Button("New Habit") {
                newHabitAction?()
            }
            .keyboardShortcut("n", modifiers: [.command])
            .disabled(newHabitAction == nil)

            Button("Log Today") {
                logTodayAction?()
            }
            .keyboardShortcut("l", modifiers: [.command])
            .disabled(logTodayAction == nil)

            Divider()

            // Section jump shortcuts mirror standard Mac sidebar navigation.
            Button("Habits") { NotificationCenter.default.post(name: .locaJumpToSection, object: MacSection.habits) }
                .keyboardShortcut("1", modifiers: [.command])

            Button("Today") { NotificationCenter.default.post(name: .locaJumpToSection, object: MacSection.today) }
                .keyboardShortcut("2", modifiers: [.command])

            Button("Journal") { NotificationCenter.default.post(name: .locaJumpToSection, object: MacSection.journal) }
                .keyboardShortcut("3", modifiers: [.command])

            Button("Life") { NotificationCenter.default.post(name: .locaJumpToSection, object: MacSection.life) }
                .keyboardShortcut("4", modifiers: [.command])
        }
    }
}

// MARK: - FocusedValues extensions

extension FocusedValues {
    /// Action vended by the habits list to create a new habit when ⌘N fires.
    var newHabitAction: (() -> Void)? {
        get { self[NewHabitActionKey.self] }
        set { self[NewHabitActionKey.self] = newValue }
    }

    /// Action vended by the habits list to open the log-today sheet when ⌘L fires.
    var logTodayAction: (() -> Void)? {
        get { self[LogTodayActionKey.self] }
        set { self[LogTodayActionKey.self] = newValue }
    }
}

private struct NewHabitActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

private struct LogTodayActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

// MARK: - Notification names

extension Notification.Name {
    /// Posted by the Habit menu's section-jump commands.
    /// `MacRootView` observes this to update `selectedSection`.
    static let locaJumpToSection = Notification.Name("com.mihirmaru.loca.mac.jumpToSection")
}
