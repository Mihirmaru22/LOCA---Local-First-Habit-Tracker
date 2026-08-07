# LOCA — Production Readiness Analysis
**Date:** July 21, 2026  
**Analyst:** Principal iOS/macOS Architect  
**Scope:** Full codebase audit — no code changes made

---

## SECTION 1: EXECUTIVE SUMMARY

LOCA is a well-architected local-first SwiftData app with genuine engineering thoughtfulness — the ADR documentation, incremental streak caching, CloudKit constraint awareness, and explicit grace-window DST handling all reflect mature decisions. However, the app is **not production-ready**. It has at minimum 6 critical blockers and 11 high-severity issues that must be resolved before a public release.

**The most urgent problem is architectural:** the codebase has grown two parallel view layers for the same screens (HabitDetailView vs. HabitAnalyticsView, the old LOCACard system vs. the new inline components), leaving dead code, navigation confusion, and unverified runtime paths. Several features are stubs writing state nobody reads (Layout picker, Review Reminder scheduler). Multiple coordinators are initialized in LOCAApp that reference classes which may not compile in the current state.

**The most dangerous problems are data integrity ones:** the `boardID` default value on LogEntry creates a valid-looking UUID that silently disconnects the entry from any board if initialization order is wrong. The `updateStreak` incremental path is explicitly documented as only valid for today-dated entries — but nothing enforces this contract at call sites.

---

## SECTION 2: ISSUES BY CATEGORY

---

### A. CRITICAL ISSUES (Ship-blockers)

---

#### ISSUE C-1: SwipeAction is a Custom Implementation Competing with Native Swipe
**Description:** `HabitCheckInsView` contains a hand-rolled `SwipeAction` view using `DragGesture`. It competes with the system's native swipe-to-delete and List row swipe actions, causing gesture conflicts.

**Root Cause:** Custom `ZStack + DragGesture + offset` implementation instead of `.swipeActions` modifier or `List`'s built-in swipe support.

**Impact:** The offset-based approach doesn't respect safe areas, causes swipe gesture conflicts with ScrollView, produces no accessibility actions (VoiceOver users cannot edit/delete), and has a hardcoded snap threshold of `-60` and resting position of `-132` regardless of content size.

**Severity:** Critical  
**Likelihood:** High — reproduced on every swipe action in check-ins view.

**Recommended Solution:** Replace with native `.swipeActions` modifier on the ForEach row, which provides system-consistent haptics, accessibility, snap points, and scroll gesture arbitration automatically.

**Expected Benefit:** Eliminates gesture conflict, restores accessibility, matches system UX.

---

#### ISSUE C-2: LOCAApp Initializes Undefined Coordinators
**Description:** `LOCAApp.init()` initializes `SignalCollectionCoordinator`, `ReflectionDelivery`, `InterventionDelivery`, `RelapseDetector`, `ReflectionGenerator`, `LifeSeeder`, and `SyncStatusCoordinator`. These are either Phase 4/5 concepts that were partially scaffolded or fully absent from the pulled codebase.

**Root Cause:** LOCAApp was forward-built during phases that defined coordinators in separate files. Many of those files either don't exist or don't compile cleanly in isolation.

**Impact:** If any coordinator class is missing from the build, the entire app fails to compile. The `while true` loops for reflection and intervention delivery run indefinitely consuming resources even when not needed. `LifeSeeder.seedIfNeeded` runs on every DEBUG launch against the mainContext.

**Severity:** Critical  
**Likelihood:** High — confirmed by recurring Xcode build errors.

**Recommended Solution:** Audit each coordinator reference in LOCAApp. If a coordinator doesn't have a complete, compiling implementation, replace it with a no-op stub or remove it. Remove the `while true` task loops until those phases are implemented.

**Expected Benefit:** Stable compilation, no background resource drain, clean launch.

---

#### ISSUE C-3: `HabitDetailView` vs `HabitAnalyticsView` — Two Competing Implementations
**Description:** Two separate, structurally different implementations exist for the habit detail screen: `HabitDetailView` (Phase 14.8, the newer one with `RefHeatmapCard`, `RefStreakCard`, etc.) and `HabitAnalyticsView` (Phase 12.3, the older one with `LOCACard`, `HeatmapView`, `ArcGaugeView`, etc.). Both exist in the codebase. `HabitDetailView` calls `HabitAnalyticsView` via tab index 0, but also renders its own embedded analytics inline. `HabitAnalyticsView` in turn references `TimelineChartView`, `StreaksChartView`, `YearComparisonChartView`, `ConsistencyChartView`, and `WeekdaysChartView` — some of which may not exist or may be stubs.

**Root Cause:** Iterative phase development without cleanup, producing a double-detail architecture.

**Impact:** Code duplication, maintenance burden, unclear which is the canonical view, dead code accumulates, and if `HabitAnalyticsView` references missing chart types the build fails.

**Severity:** Critical  
**Likelihood:** Certain — the code is present.

**Recommended Solution:** Designate one view as canonical (Phase 14.8 `HabitDetailView`). Delete `HabitAnalyticsView` and all chart stubs it references that don't exist. The tab system in `HabitDetailView` should stand alone without delegating to the old view.

**Expected Benefit:** Single source of truth, no phantom chart references, clean build.

---

#### ISSUE C-4: Review Reminder Writes State That Is Never Read
**Description:** `AppSettingsView` (in `SettingsMenuView.swift`) provides a Review Reminder UI that requests notification permission and allows time selection. However, `ReminderScheduler.shared.rescheduleAllReminders` in LOCAApp only schedules reminders based on `board.preferredReminderTime` — a per-habit field, not a global reminder time. The review reminder UI writes to a different key that is never consumed.

**Root Cause:** The reminder UI was built targeting a global reminder concept, but the scheduler implementation targets per-habit times. The two were never connected.

**Impact:** Users see a permission request, grant it, pick a time — and nothing is scheduled. This is a trust violation: the app asks for notification permission under false pretenses.

**Severity:** Critical  
**Likelihood:** Certain — confirmed by code analysis.

**Recommended Solution:** Remove the Review Reminder UI from settings entirely until a real implementation exists, or implement the scheduling end-to-end. The permission request in LOCAApp.task should not run until an actual notification is being scheduled.

**Expected Benefit:** No false permission prompts, no user trust violation.

---

#### ISSUE C-5: `LogEntry.boardID` Default Value Creates Silent Data Corruption Risk
**Description:** `LogEntry.boardID` has a default value of `UUID()`. This satisfies the CloudKit "all properties must have a default" requirement. However, it means that if a `LogEntry` is ever initialized without explicitly passing `boardID:`, it silently receives a random UUID unrelated to any board. The entry will appear in the store but will never be associated with any board in `@Query` predicate results.

**Root Cause:** CloudKit requirement for defaults conflicts with the enforcement of ADR-003's contract. The contract says "the only permitted insertion path passes `boardID: board.id`", but Swift doesn't enforce this at compile time.

**Impact:** Silent data loss. An incorrectly initialized entry would be saved to CloudKit, propagated to other devices, and never display anywhere. Users would see missing check-ins with no error.

**Severity:** Critical  
**Likelihood:** Low in current code (all call sites pass `boardID`) but high risk if any new code path misses it.

**Recommended Solution:** Replace `boardID: UUID = UUID()` default with a required parameter (no default). Accept the CloudKit default requirement by using a sentinel value like `UUID.zero` or document explicitly that the default is for CloudKit compatibility only, not for use in init. Add a SwiftData migration if schema changes are needed. Alternatively add a runtime assertion in `updateStreak` that `board?.id == boardID`.

**Expected Benefit:** Compile-time enforcement of ADR-003, elimination of silent orphan entries.

---

#### ISSUE C-6: `updateStreak` Contract Violation Not Enforced
**Description:** `HabitBoard.updateStreak(using:)` is documented as only valid for today-dated entries (Contract C-2). It is called in `HabitCheckInsView.quickLog()`, `AddCheckInSheetView.submitCheckIn()`, `EditCheckInSheetView.save()`, and `HabitListView.checkInBinary()`. The edit sheet explicitly allows backdating entries to any past date. Calling `updateStreak` after saving a backdated or future entry silently leaves the streak cache in a wrong state.

**Root Cause:** The contract is enforced only by documentation. `EditCheckInSheetView.save()` calls `board.updateStreak(using: .current)` regardless of whether `selectedDate` is today.

**Impact:** Incorrect streak values after any edit to a past entry. Streaks may appear inflated or deflated. `longestStreak` may be permanently corrupted (streak cache never self-corrects).

**Severity:** Critical  
**Likelihood:** High — any user who edits a past check-in hits this.

**Recommended Solution:** In `EditCheckInSheetView.save()`, replace the `updateStreak` call with `board.needsStreakRecalculation = true` and route through `StreakMaintenanceCoordinator`. Apply the same fix to any `AddCheckInSheetView.submitCheckIn()` call where `selectedDate` is not today.

**Expected Benefit:** Correct streaks after any edit or backdated entry.

---

### B. HIGH SEVERITY ISSUES

---

#### ISSUE H-1: `RootNavigationView` vs `TodayView` — Parallel Navigation Roots
**Description:** `LOCAApp` uses `TodayView()` as the root scene content. `RootNavigationView` also exists and provides `NavigationSplitView` for iPad/Mac, which `TodayView` presumably wraps or conflicts with. Both embed navigation stacks. The relationship is unclear — if `TodayView` is a `NavigationStack` and `RootNavigationView` is a `NavigationSplitView`, one of them is the real root and the other is dead.

**Root Cause:** Navigation architecture evolved across phases without fully resolving the split between the iPhone-first `TodayView` path and the split-view `RootNavigationView` path.

**Impact:** On iPad/Mac, users may see the wrong navigation shell. Double navigation bars, broken back-button behavior, or split view not appearing where expected.

**Severity:** High  
**Likelihood:** High on iPad/Mac.

**Recommended Solution:** Determine which is the canonical root per platform and ensure LOCAApp conditionally injects the correct one, or unify them into a single adaptive root.

---

#### ISSUE H-2: `HeatmapDataProvider.buildDayGrid` is `async` but Called Synchronously
**Description:** `RefHeatmapCard` (in `HabitDetailView`) computes heatmap data inline during `body` evaluation by accessing `board.logs` directly in a ForEach loop. This does not use `HeatmapDataProvider.buildDayGrid` (the async off-thread path). Instead it performs O(N × W) work (N = logs count, W = weeks count = 52) inside the view's body on the main thread, for every render.

**Root Cause:** The async provider exists but was not wired to the new `RefHeatmapCard` implementation.

**Impact:** Main thread blocking during heatmap render. With hundreds of log entries and 52 weeks × 7 days = 364 cells, each accessing `board.logs` via optional chaining and filter, this is O(52 × 7 × N) work per render frame.

**Severity:** High  
**Likelihood:** Certain — visible in any habit with meaningful history.

**Recommended Solution:** Wire `RefHeatmapCard` to use `HeatmapDataProvider.buildDayGrid` with a `.task(id: board.logs)` modifier to pre-compute cells off the main thread, storing the result as `@State`.

---

#### ISSUE H-3: DateFormatter Allocation in Hot Render Paths
**Description:** `HabitCheckInsView` allocates new `DateFormatter` instances inside `formattedTime()` and `dateLabel()`. These are called for every entry in the grouped log list on every render. `DateFormatter` initialization is among the most expensive object constructions in Foundation (~2ms per instance on older hardware).

**Root Cause:** DateFormatter was extracted from inside a @ViewBuilder (fixing the type-check error) but remains allocated-per-call rather than cached.

**Impact:** Jank during scrolling in Check-ins view if the user has many entries. Each scroll frame that triggers a re-render reinitializes formatters.

**Severity:** High  
**Likelihood:** Medium — noticeable with 30+ entries.

**Recommended Solution:** Cache both `DateFormatter` instances as `private static let` on `HabitCheckInsView` or as a shared singleton. Static let is thread-safe in Swift.

---

#### ISSUE H-4: `groupedLogs` Computed Property Has O(N log N) on Every Body Eval
**Description:** `HabitCheckInsView.groupedLogs` performs full grouping and sorting of all logs on every view body evaluation: dictionary construction, map, and two sorts. There is no memoization.

**Root Cause:** Pure computed property with no caching. SwiftUI can evaluate `body` frequently.

**Impact:** Every SwiftUI re-render caused by any state change (keyboard appearing, timer ticks from parent, sheet presentation) triggers an O(N log N) pass through all logs.

**Severity:** High  
**Likelihood:** Certain — happens on every state change in the view.

**Recommended Solution:** Move grouped computation into a `.task(id: board.logs)` with results stored in `@State`, so the grouping only re-runs when the underlying log data changes, not on arbitrary re-renders.

---

#### ISSUE H-5: SwipeAction Fixed Height Clips Variable Content
**Description:** The `SwipeAction` view in `HabitCheckInsView` sets `.frame(height: 44)` and `.clipped()`. Log entries with notes render a separate note bubble beneath the swipeable row. The note bubble is outside the `SwipeAction` and not swipeable, creating an inconsistent UX where swipe is only possible on part of the entry.

**Root Cause:** The custom `SwipeAction` wrapper was designed for a fixed-height row and doesn't accommodate variable-height content.

**Impact:** Confusing interaction model. Note bubbles appear unrelated to their parent entry. Swiping the wrong area appears to do nothing.

**Severity:** High  
**Likelihood:** Certain for any entry with a note.

**Recommended Solution:** Revert to native List-based swipe actions, which handle variable row heights natively.

---

#### ISSUE H-6: Consistency Ring Shows Static "Average" Label Regardless of Data
**Description:** `RefConsistencyCard` calculates a `ratio` (correctly using days-elapsed as denominator, not days-in-month — the bug from the audit history was fixed). However, the arc label is hardcoded as `"Average"` regardless of what the ratio actually is. A user with 100% consistency sees "Average"; a user at 10% also sees "Average".

**Root Cause:** Label was left as a placeholder during implementation.

**Impact:** Misleading metric. The card's purpose is to show consistency level, but the label provides no actionable information.

**Severity:** High  
**Likelihood:** Certain.

**Recommended Solution:** Map the ratio to a meaningful label: "Excellent" (>80%), "Good" (>60%), "Average" (>40%), "Needs Work" (<40%), or show the actual percentage.

---

#### ISSUE H-7: `DebugSeeder` and `LifeSeeder` Run on `mainContext` at Launch
**Description:** In DEBUG builds, `DebugSeeder.seedIfNeeded(context:)` and `LifeSeeder.seedIfNeeded(context:)` are called synchronously on `container.mainContext` inside `LOCAApp.init()`. This is a blocking synchronous operation on the main actor during app launch, before any view appears.

**Root Cause:** Convenience of seeding before the first render.

**Impact:** Delays time-to-first-frame. If the seeder crashes (malformed data, schema mismatch), it takes the whole app down at init. Seeders may insert duplicate data if their "is already seeded" checks are imprecise.

**Severity:** High  
**Likelihood:** Medium — only in DEBUG, but every team member hits it.

**Recommended Solution:** Move seeding into a `.task` modifier on the root view, running asynchronously after the UI is visible.

---

#### ISSUE H-8: `AddCheckInSheetView` Minute Picker Only Offers 15-Minute Intervals
**Description:** The time picker in `AddCheckInSheetView` uses `stride(from: 0, to: 60, by: 15)` for minutes, offering only 0, 15, 30, and 45. A user who ran at 8:37 AM cannot log that time accurately.

**Root Cause:** Convenience over precision — 4 options instead of 60.

**Impact:** Users cannot log accurate times for backdated entries, reducing the value of the journal and timeline features.

**Severity:** High  
**Likelihood:** Certain.

**Recommended Solution:** Replace the segmented minute picker with a native `DatePicker(.date, in:...)` or use `.datePickerStyle(.wheels)` which handles time naturally, or at minimum offer 5-minute increments (12 options).

---

#### ISSUE H-9: `ColorPalette` Index Out-of-Bounds Not Guarded
**Description:** Throughout the codebase, `ColorPalette[board.colorIndex]` is called directly. If `board.colorIndex` is corrupt (e.g., a future app version adds colors then syncs to an older build), this subscript crashes.

**Root Cause:** No bounds check on `colorIndex` at point of use.

**Impact:** Crash at any rendering site that reads `ColorPalette[board.colorIndex]`.

**Severity:** High  
**Likelihood:** Low in current build, high after future schema changes or CloudKit sync with newer app versions.

**Recommended Solution:** Add a safe subscript to ColorPalette that returns a default color for out-of-range indices, or clamp `colorIndex` in `HabitBoard.metric`-style computed accessor.

---

#### ISSUE H-10: `LOCAApp.body` Has 7 Concurrent `.task` Modifiers
**Description:** `LOCAApp.body` applies 7 separate `.task` modifiers to `TodayView`. Some contain `while true` loops. Tasks are automatically cancelled when the view disappears — but `TodayView` is the root scene content and never disappears during normal use. The reflection and intervention tasks run `try? await Task.sleep(for: .seconds(86400))` — if the app is backgrounded and the task is suspended, iOS may kill it, causing the loop to restart on next foreground.

**Root Cause:** App lifecycle tasks modeled as view-scoped tasks rather than actor-isolated background services.

**Impact:** Undefined behavior in background execution. Memory retained by 7 simultaneous `@MainActor` tasks. If any task throws unexpectedly, it silently dies with `try?` suppressing the error.

**Severity:** High  
**Likelihood:** Medium.

**Recommended Solution:** Consolidate coordinator startup into a single `AppCoordinator` actor or background service. Remove `while true` loops from view tasks. Use `BGTaskScheduler` or `UNUserNotificationCenter` for timed background work.

---

#### ISSUE H-11: `HabitGridLayoutView` Wave Animation Uses `DispatchQueue.main.asyncAfter`
**Description:** The wave animation in `HabitGridCardWithHeatmap` schedules 28 `DispatchQueue.main.asyncAfter` calls (14 to start + 14 to end) per check-in tap. These are not cancellable. If the user taps multiple times quickly, callbacks pile up on the main queue.

**Root Cause:** Staggered animation implemented with raw GCD instead of SwiftUI animation infrastructure.

**Impact:** Memory leak accumulation of non-cancellable closures. Visual artifacts if cards are dismissed before animations complete. Possible crash if `waveIndices` `Set` is mutated from overlapping callbacks.

**Severity:** High  
**Likelihood:** Medium — any user who taps the check button more than once.

**Recommended Solution:** Replace with a single `.animation` modifier with an explicit delay per cell using SwiftUI's `.delay()` on the animation, or use `withAnimation` + `.delay()` inside a single `Task` that can be cancelled.

---

### C. MEDIUM SEVERITY ISSUES

---

#### ISSUE M-1: No Empty State in HabitDetailView When Board Has No Logs
**Description:** All three cards in `HabitDetailView` (`RefStreakCard`, `RefConsistencyCard`, `RefMonthCard`) handle zero data, but the heatmap renders 364 empty cells with no indication to the user that they haven't logged yet. A new user's first habit detail screen shows a wall of empty gray boxes with no guidance.

**Severity:** Medium | **Likelihood:** Certain for all new users.

---

#### ISSUE M-2: `ReminderScheduler` Is Initialized But Reminders Are Never Verified
**Description:** `ReminderScheduler` is called in LOCAApp to request permission and reschedule all reminders. No UI exists to show users which reminders are active, or to let them manage them per-habit from within the app.

**Severity:** Medium | **Likelihood:** Certain.

---

#### ISSUE M-3: `HabitFormView` Emoji Validation Has Incomplete Logic
**Description:** The `onChange` handler for `draft.emoji` attempts to keep only the first character using `unicodeScalars.prefix(while: { $0.value > 127 })`. This condition (`value > 127`) is not a valid test for "is the first emoji" — ASCII text has `value <= 127`, so this prefix would be empty for ASCII characters, and the logic falls back to `trimmed.prefix(1)`. Multi-codepoint emoji (e.g., 👨‍👩‍👧 = family emoji = 8 scalar values) would be truncated to one scalar, rendering as a partial/broken glyph.

**Severity:** Medium | **Likelihood:** Medium — any user who types family/profession/flag emoji.

---

#### ISSUE M-4: `HabitCheckInsView.quickLog` Does Not Validate Against Target Exceeding
**Description:** Binary habits have `metricType == 0` and should only be logged once per day (value = 1.0). The quick log input field appears conditionally based on `groupedLogs.first?.date`, but does not check `board.metric`. A binary habit incorrectly shows the quick log amount input if today's group already exists but has no entry with value == 1.

**Severity:** Medium | **Likelihood:** Low.

---

#### ISSUE M-5: `RefMonthCard` Weekly Bar Heights Use `CGFloat.random` for Demo Bars
**Description:** The 7 bars in `RefMonthCard` compute heights from `weekTotals[i]`. However, the bar height formula for empty days is `6` (a fixed minimum), and for non-empty days is `max(8, 56 * CGFloat(v / maxV))`. When `maxV = board.effectiveTarget` and all totals are zero, `v / maxV` is always 0/1 = 0. The bars display as flat lines but their heights are not random — the documentation comment is misleading. The chart is functionally correct but visually poor: all bars look identical until any log exists.

**Severity:** Medium | **Likelihood:** Certain for new users.

---

#### ISSUE M-6: `RootNavigationView` Auto-Selection Fires `.onChange(of: activeBoards.count)`
**Description:** `autoSelectFirstBoardIfNeeded()` is called on every change to `activeBoards.count`. This also fires when a board is archived (count decreases). If the user archives the currently-selected board, `activeBoards.count` decreases, the function fires, finds a new first board, and auto-selects it — potentially surprising the user who may have intended to see the empty state.

**Severity:** Medium | **Likelihood:** Low.

---

#### ISSUE M-7: No Confirmation Before Deleting a LogEntry
**Description:** `HabitCheckInsView.deleteEntry()` hard-deletes immediately on swipe (or will, once the swipe action is fixed). There is no undo, no confirmation alert, and no soft-delete implementation (the `LogEntry.archivedAt` field exists but `deleteEntry` calls `modelContext.delete(entry)` directly rather than setting `archivedAt`).

**Severity:** Medium | **Likelihood:** Certain — accidental swipe deletes are a known iOS UX failure mode.

---

#### ISSUE M-8: `SettingsMenuView.ArchiveListView` References `board.archivedAt` But `HabitBoard` Archive Is One-Way
**Description:** `ArchiveListView` has an `unarchive(_ board:)` function that sets `board.archivedAt = nil`. The `archive(in:)` method on `HabitBoard` is documented as the canonical archiving path, but the unarchive path bypasses it, writing directly to the property. This is fine structurally but inconsistent — the `archive()` method's rollback logic is not mirrored in unarchive.

**Severity:** Medium | **Likelihood:** Low.

---

#### ISSUE M-9: `TodayView` Actor Isolation Warning
**Description:** The Xcode build log shows "Call to main actor-isolated initializer 'init()' in a synchronous nonisolated context" in `TodayView`. This warning indicates `TodayView` may be constructing an object (likely a coordinator or query result) outside a guaranteed `@MainActor` context, creating a potential Swift concurrency violation.

**Severity:** Medium | **Likelihood:** Confirmed by build log.

---

#### ISSUE M-10: `HabitListLayoutView` Passes Empty Closure for Non-checkable Habits
**Description:** In `HabitListLayoutView`, `HabitListRow` receives `onCheckBinary: {}` for `inProgress` and `done` boards. If `HabitListRow` displays a check button for all habits regardless of state, tapping it silently does nothing. Users may believe the button is broken.

**Severity:** Medium | **Likelihood:** Medium.

---

### D. LOW SEVERITY ISSUES

---

#### ISSUE L-1: `ModelContainerFactory.appGroupIdentifier` Is a Placeholder
**Description:** `group.com.mihirmaru.loca` is documented as "a structurally correct placeholder derived from this project's GitHub identity, not a verified, registered identifier." If this doesn't match the registered App Group exactly, the widget and main app read from different SQLite files silently.

**Severity:** Low (documentation risk, not code risk) | **Likelihood:** Low if entitlements match.

---

#### ISSUE L-2: `LogEntry.archivedAt` Field Exists But Is Never Used
**Description:** `LogEntry` has a `archivedAt: Date?` field with documentation describing a soft-delete model and 5-second undo window. `deleteEntry` in `HabitCheckInsView` calls hard-delete instead. The soft-delete machinery is built but not wired.

**Severity:** Low | **Likelihood:** Feature gap, not a crash risk.

---

#### ISSUE L-3: `HabitBoard.preferredReminderTime` and `lastReflectionPromptTime` Are Written but Gated Features
**Description:** These fields exist on the model and sync via CloudKit but the feature implementations (personalized reminder time inference from logging patterns, reflection prompts) are not implemented in the pulled codebase.

**Severity:** Low | **Likelihood:** Certain to accumulate as dead schema weight.

---

#### ISSUE L-4: `ValueText` Uses `.monospacedDigit()` which Can Cause Layout Jumps
**Description:** `ValueText` applies `.monospacedDigit()` globally. This is correct for streak counters and values that change over time. However for static display contexts (e.g., month total that isn't animated) it causes unnecessary fixed-width digit rendering that can look wider than needed.

**Severity:** Low | **Likelihood:** Low.

---

#### ISSUE L-5: `HabitGridLayoutView` Has No Empty State
**Description:** If `boardsWithState` is empty (archived all habits), the grid layout renders nothing — no message, no illustration, no CTA.

**Severity:** Low | **Likelihood:** Low.

---

#### ISSUE L-6: `SwipeAction` Action Buttons Are Fixed Width, Not Equal-Width
**Description:** The three swipe action buttons (duplicate, edit, delete) use `frame(maxWidth: .infinity)` inside a fixed-height `HStack`. On narrow screens the buttons may be smaller than Apple's minimum tappable area (44pt) in width.

**Severity:** Low | **Likelihood:** Low.

---

#### ISSUE L-7: `HabitFormView` Has Two Competing Toolbar Declarations
**Description:** `HabitFormView.body` applies `.toolbar { toolbarContent }` twice — once for Cancel/Save and once for the keyboard "Done" button. Multiple `.toolbar` modifiers on the same view can produce unexpected results depending on placement enum resolution.

**Severity:** Low | **Likelihood:** Low.

---

## SECTION 3: PRODUCTION READINESS ASSESSMENT

| Dimension | Score | Notes |
|---|---|---|
| Compilation stability | 4/10 | Multiple coordinator references may not compile |
| Data integrity | 5/10 | boardID default, streak contract violations |
| UI correctness | 5/10 | Frozen screen bugs, gesture conflicts, dead UI |
| Performance | 6/10 | Heatmap O(N×W) on main thread, formatter alloc |
| Accessibility | 3/10 | Custom SwipeAction breaks VoiceOver |
| Error handling | 7/10 | ModelContext failures handled; coordinator failures swallowed |
| Code maintainability | 5/10 | Dual view architecture, dead code, stub features |
| CloudKit/Sync | 7/10 | Architecture is correct; entitlement matching untested |
| User experience | 5/10 | Layout freeze, dead buttons, no onboarding |

**Overall: NOT PRODUCTION READY**

---

## SECTION 4: RISK ASSESSMENT — BLOCKERS BEFORE DEPLOYMENT

| # | Risk | Type | Block Level |
|---|---|---|---|
| 1 | LOCAApp missing coordinator types | Compilation | HARD BLOCK |
| 2 | Dual HabitDetailView / HabitAnalyticsView | Architecture | HARD BLOCK |
| 3 | Frozen main screen (GeometryReader regression) | Stability | HARD BLOCK |
| 4 | Review Reminder prompts without scheduling | Trust | HARD BLOCK |
| 5 | Streak corruption on backdated edits | Data integrity | HARD BLOCK |
| 6 | No accessibility on swipe actions | App Store | SOFT BLOCK |
| 7 | Main thread heatmap computation | Performance | SOFT BLOCK |
| 8 | Undefined task loop behavior in background | Stability | SOFT BLOCK |

---

## SECTION 5: PRIORITIZED ISSUE LIST

1. **[C-2]** Remove/stub undefined coordinators in LOCAApp (compilation)
2. **[C-3]** Consolidate HabitDetailView + HabitAnalyticsView into one (architecture)
3. **[C-6]** Fix streak corruption on backdated entry edits (data integrity)
4. **[C-4]** Remove non-functional Review Reminder UI (trust)
5. **[C-5]** Enforce boardID non-default (data integrity)
6. **[C-1]** Replace custom SwipeAction with native .swipeActions (UX + accessibility)
7. **[H-11]** Replace DispatchQueue wave animation with SwiftUI animation (stability)
8. **[H-2]** Wire RefHeatmapCard to async HeatmapDataProvider (performance)
9. **[H-3]** Cache DateFormatter as static let (performance)
10. **[H-4]** Move groupedLogs computation to .task with @State (performance)
11. **[H-1]** Resolve RootNavigationView vs TodayView root navigation (architecture)
12. **[H-10]** Consolidate 7 .task modifiers into AppCoordinator (stability)
13. **[H-6]** Add meaningful label to consistency ring (UX)
14. **[H-8]** Fix minute picker to allow precise time selection (UX)
15. **[H-9]** Guard ColorPalette subscript against out-of-bounds (stability)
16. **[H-5]** Fix SwipeAction height clipping variable content (UX)
17. **[H-7]** Move debug seeders to .task modifier (launch time)
18. **[M-7]** Implement soft-delete or confirmation on LogEntry deletion (UX)
19. **[M-9]** Fix TodayView actor isolation warning (concurrency)
20. **[M-1]** Add empty state to HabitDetailView for new users (UX)
21. **[M-3]** Fix emoji validation for multi-codepoint emoji (correctness)
22. **[M-5]** Improve zero-state bar chart visual (UX)
23. **[M-6]** Review auto-selection on archive edge case (UX)
24. **[L-1]** Verify App Group identifier matches registered entitlement (deployment)
25. **[L-2]** Wire soft-delete for LogEntry or remove the field (debt)

---

## SECTION 6: PRE-DEVELOPMENT CHECKLIST

Before making any further code changes, confirm the following:

**Compilation**
- [ ] All types referenced in LOCAApp.init() exist and compile
- [ ] HabitAnalyticsView's chart dependencies all exist
- [ ] No `try!` in production code paths (only in #Preview)
- [ ] No unreferenced @State variables producing unused-variable warnings

**Architecture**
- [ ] Single canonical view for habit detail (not two competing implementations)
- [ ] Single navigation root (TodayView vs RootNavigationView resolved)
- [ ] All Layout picker options (List/Grid/Timeline) have working implementations
- [ ] No UI element writes state that nothing reads

**Data Integrity**
- [ ] boardID default value risk acknowledged and mitigated
- [ ] updateStreak contract enforced at all call sites
- [ ] Backdated entry edits route through StreakMaintenanceCoordinator
- [ ] LogEntry deletion uses soft-delete (archivedAt) not hard-delete

**Performance**
- [ ] No DateFormatter allocation in view body or computed properties
- [ ] No O(N×W) computation on main thread during heatmap render
- [ ] groupedLogs computed off main thread
- [ ] Wave animation uses SwiftUI-native mechanism

**User Experience**
- [ ] No permission prompt for features not yet implemented
- [ ] New user sees meaningful empty states, not blank screens
- [ ] All swipe actions accessible to VoiceOver users
- [ ] Minute picker allows accurate time entry

**Deployment**
- [ ] App Group identifier matches entitlement in both targets
- [ ] CloudKit container identifier matches Developer Portal
- [ ] DebugSeeder/LifeSeeder absent from Release builds
- [ ] No stub/TODO views visible to end users
