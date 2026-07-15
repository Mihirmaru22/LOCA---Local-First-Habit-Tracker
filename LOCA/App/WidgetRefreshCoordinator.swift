import WidgetKit
import os

// MARK: - WidgetRefreshCoordinator
//
// Canonical implementation per Engineering Principles Appendix B.
//
// Debounces `WidgetCenter.shared.reloadAllTimelines()` so that rapid
// consecutive check-ins (e.g., a user logging several quantitative entries
// in quick succession) do not spam the widget update budget. The 500ms
// debounce matches the Appendix B reference implementation exactly.
//
// ## Why Here, Not in CheckInButton
//
// `CheckInButton` fires on every successful save. If the debounce lived
// inside `CheckInButton`, a user with multiple boards visible simultaneously
// (e.g., on iPad split-view where both Detail columns could theoretically
// be active) could have concurrent debounce timers that interfere. The
// singleton pattern ensures one debounce window regardless of how many
// call sites exist.
//
// ## Phase 9 Note
//
// `reloadAllTimelines()` is a no-op until Phase 9 ships real WidgetKit
// extensions. It is wired at the check-in layer now so every Phase 9
// widget automatically receives fresh data with zero additional call sites
// to audit or add.
//
// ## Thread Safety
//
// `@MainActor` isolated. `scheduleReload()` is always called from
// `CheckInButton`'s action handler, which runs on the main actor.
// No cross-actor access occurs.

@MainActor
final class WidgetRefreshCoordinator {

    // MARK: - Singleton

    static let shared = WidgetRefreshCoordinator()

    private init() {}

    // MARK: - State

    private var debounceTask: Task<Void, Never>?

    private let logger = Logger(
        subsystem: "com.mihirmaru.loca",
        category: "Widget"
    )

    // MARK: - Public API

    /// Schedules a `WidgetCenter.shared.reloadAllTimelines()` call after a
    /// 500ms debounce window.
    ///
    /// Cancels any previously scheduled reload — if `scheduleReload()` is
    /// called again within 500ms, the timer resets, and only one reload
    /// fires at the end of the final burst.
    ///
    /// Safe to call after every `LogEntry` insertion. The debounce ensures
    /// widget budget is not exhausted by rapid consecutive check-ins.
    func scheduleReload() {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(500))
            } catch {
                // Task.sleep throws CancellationError when cancelled —
                // this is the expected path when a newer scheduleReload()
                // call pre-empts this one. Exit without reloading.
                return
            }

            guard !Task.isCancelled else { return }

            WidgetCenter.shared.reloadAllTimelines()
            self?.logger.debug("Widget timelines reloaded after check-in debounce.")
        }
    }
}
