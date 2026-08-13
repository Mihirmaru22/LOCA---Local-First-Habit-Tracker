import SwiftUI

// MARK: - LOCACommands

/// LOCA's native macOS menu bar commands.
///
/// Registered on the `WindowGroup` scene via `.commands { LOCACommands() }`.
/// Each `CommandMenu` appears in the menu bar between the built-in Edit and
/// Window menus. Keyboard shortcuts follow macOS conventions:
/// - ⌘N  New Habit / New Block (context-sensitive via FocusedValue)
/// - ⌘L  Log Today (L for Log)
/// - ⌘1–4 Jump to sidebar section
struct LOCACommands: Commands {

    // MARK: - Focus values

    @FocusedValue(\.newHabitAction)    private var newHabitAction
    @FocusedValue(\.logTodayAction)    private var logTodayAction
    @FocusedValue(\.todayNewItemAction) private var todayNewItemAction

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

        // MARK: Today menu
        CommandMenu("Today") {
            Button("New Block") {
                todayNewItemAction?()
            }
            .keyboardShortcut("n", modifiers: [.command])
            .disabled(todayNewItemAction == nil)

            Button("Jump to Today") {
                NotificationCenter.default.post(name: .locaJumpToToday, object: nil)
            }
            .keyboardShortcut("t", modifiers: [.command])

            Divider()

            Button("Previous Day") {
                NotificationCenter.default.post(name: .locaShiftDay, object: -1)
            }
            .keyboardShortcut(.leftArrow, modifiers: [])

            Button("Next Day") {
                NotificationCenter.default.post(name: .locaShiftDay, object: 1)
            }
            .keyboardShortcut(.rightArrow, modifiers: [])

            Divider()

            Button("Nudge Block Earlier") {
                NotificationCenter.default.post(name: .locaNudgeBlock, object: -5)
            }
            .keyboardShortcut(.upArrow, modifiers: [.option])

            Button("Nudge Block Later") {
                NotificationCenter.default.post(name: .locaNudgeBlock, object: 5)
            }
            .keyboardShortcut(.downArrow, modifiers: [.option])

            Divider()

            Button("Complete Task") {
                NotificationCenter.default.post(name: .locaCompleteSelected, object: nil)
            }
            .keyboardShortcut(.return, modifiers: [.command])

            Button("Archive Task") {
                NotificationCenter.default.post(name: .locaArchiveSelected, object: nil)
            }
            .keyboardShortcut(.delete, modifiers: [.command])
        }
    }
}

// MARK: - FocusedValues extensions

extension FocusedValues {
    var newHabitAction: (() -> Void)? {
        get { self[NewHabitActionKey.self] }
        set { self[NewHabitActionKey.self] = newValue }
    }

    var logTodayAction: (() -> Void)? {
        get { self[LogTodayActionKey.self] }
        set { self[LogTodayActionKey.self] = newValue }
    }

    /// Vended by the active Today sub-pillar: creates a new block (Plan) or
    /// focuses the quick-add field (List). Drives the ⌘N shortcut context-sensitively.
    var todayNewItemAction: (() -> Void)? {
        get { self[TodayNewItemActionKey.self] }
        set { self[TodayNewItemActionKey.self] = newValue }
    }
}

private struct NewHabitActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

private struct LogTodayActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

private struct TodayNewItemActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

// MARK: - Notification names

extension Notification.Name {
    static let locaJumpToSection   = Notification.Name("com.mihirmaru.loca.mac.jumpToSection")
    static let locaJumpToToday     = Notification.Name("com.mihirmaru.loca.mac.jumpToToday")
    static let locaShiftDay        = Notification.Name("com.mihirmaru.loca.mac.shiftDay")
    static let locaNudgeBlock      = Notification.Name("com.mihirmaru.loca.mac.nudgeBlock")
    static let locaAddBlock        = Notification.Name("com.mihirmaru.loca.mac.addBlock")
    static let locaCompleteSelected = Notification.Name("com.mihirmaru.loca.mac.completeSelected")
    static let locaArchiveSelected  = Notification.Name("com.mihirmaru.loca.mac.archiveSelected")
    static let locaFocusQuickAdd   = Notification.Name("com.mihirmaru.loca.mac.focusQuickAdd")
    static let locaOpenTask        = Notification.Name("com.mihirmaru.loca.mac.openTask")
}
