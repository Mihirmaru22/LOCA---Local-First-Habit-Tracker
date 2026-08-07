//
//  LOCAShortcuts.swift
//  LOCA
//
//  Phase 8.2 — App Intents: Shortcuts & Siri Surface
//
//  Registers LOCA's App Intents with the system so they appear in the
//  Shortcuts app and respond to Siri phrases with zero user setup.
//

import AppIntents

// MARK: - LOCAShortcuts

/// The app's `AppShortcutsProvider` — the single registration point that
/// exposes `LogHabitIntent` to Siri and the Shortcuts app.
///
/// ## Phrase Design
/// Every phrase embeds `\(.applicationName)` (required by App Intents) so the
/// app name anchors the utterance. The board-parameterised phrase
/// (`"Log \(\.$board) in \(.applicationName)"`) lets a spoken habit name
/// resolve directly through `HabitBoardEntityQuery.entities(matching:)`
/// (Phase 8.1) — e.g. "Log Running in LOCA" — while the bare phrases open the
/// intent with the habit picker.
///
/// ## Dynamic Parameter Updates (Phase 7 integration point)
/// `AppShortcutsProvider` supplies a static `updateAppShortcutParameters()`.
/// The Engineering Principles verification checklist requires it to be called
/// **after any `HabitBoard` insert or archive**, so Siri's cached set of
/// board-name phrases stays in sync with the user's actual habits.
///
/// That call belongs at the habit-mutation sites, which are **Phase 7**
/// (habit management — create / edit / archive). Phase 8 deliberately does not
/// wire it: there is no habit-mutation code in this phase to attach it to, and
/// adding a speculative call site would violate additive-scope discipline.
/// Phase 7 must invoke `LOCAShortcuts.updateAppShortcutParameters()` after its
/// board `insert` and `archive(in:)` paths save successfully.
struct LOCAShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogHabitIntent(),
            phrases: [
                "Log a habit in \(.applicationName)",
                "Log \(\.$board) in \(.applicationName)",
                "Check in with \(.applicationName)",
                "Record a habit in \(.applicationName)"
            ],
            shortTitle: "Log Habit",
            systemImageName: "checkmark.circle.fill"
        )
    }
}
