# ENGINEERING PRINCIPLES — PROJECT RIPPLE-CLONE

**Revision:** 1.2.0
**Status:** IMMUTABLE — amendments require an explicit revision command to the Principal Architect  
**Effective:** 2026-06-28  
**Last Amended:** 2026-07-01 — Phase 0 identifier migration
**Scope:** All Swift files in the Main App target and Widget Extension target

---

## Revision History

**1.2.0 (2026-07-01)** — Phase 0 (Project Scaffolding) migrated internal identifiers from the original project working-title placeholders (`com.yourdomain.rippleclone` / `group.com.yourdomain.ripples`) to LOCA's naming convention. The logger subsystem example in §4.4 is updated accordingly. This amendment is purely a naming correction, matching the same scope discipline as the 1.1.0 amendment — no testing, performance, or review-checklist requirement was weakened, removed, or added.

**1.1.0 (2026-06-29)** — Phase 2 code review (finding H6) identified that this document referenced a type, `DailyAggregator`, that does not exist in the actual Phase 2 implementation. The closest analog — and the type that grew out of the original critique-session vocabulary — is the pair of free functions `aggregateByDay` (primary attribution only, used by `HeatmapDataProvider`) and `aggregateByDayWithGrace` (adds DST grace-window credits, used by `StreakCalculator`). All seven references across §2.1, §3.2, §5.1, §5.2, and §8.1 are updated accordingly. This amendment is purely a naming correction — no testing, performance, or review-checklist requirement was weakened or removed.

**1.0.0 (2026-06-28)** — Initial document.

---

## 0. Hierarchy of Authority

These principles take precedence over personal preference and over any pattern not explicitly described here. Where a situation is not covered, the question to ask is: *does this choice make the codebase more or less legible to an engineer reading it for the first time in six months?* The answer governs.

---

## 1. Swift Style

### 1.1 Platform Boundary

UIKit is imported only at API-level call sites: `UIImpactFeedbackGenerator`, `UIApplication.shared.open`. It is never used for layout, view hierarchy management, or lifecycle observation. All of those belong to SwiftUI. `AppKit` follows the same rule on macOS.

### 1.2 Type Semantics

Value semantics by default. `struct` is the first choice for any new type. `class` is used only when reference semantics are required by an external contract (e.g., `ObservableObject` bridging in a legacy context, which this project does not have) or when a type must be a `@Model`. Any `class` that is not designed for subclassing is `final`.

### 1.3 Optionals

Force unwrap (`!`) does not appear in production code paths. `guard let` or `if let` at the nearest unwrap boundary. `nil` coalescing is permitted when a sensible default exists. `try?` is permitted only when failure is genuinely inconsequential and an inline comment says why.

### 1.4 View Construction

`AnyView` is banned. Type erasure destroys SwiftUI's structural diffing and produces invisible performance regressions. Conditional view construction uses `@ViewBuilder` functions, `Group`, or `if/else` branches returning `some View`. Computed view properties that contain conditional branches are annotated `@ViewBuilder`.

```swift
// ✅ Correct
@ViewBuilder
private var completionIndicator: some View {
    if board.isCompletedToday {
        Image(systemName: "checkmark.circle.fill")
    } else {
        Circle().strokeBorder(lineWidth: 1.5)
    }
}

// ❌ Banned
private var completionIndicator: some View {
    AnyView(board.isCompletedToday ? Image(systemName: "checkmark.circle.fill") : AnyView(Circle()))
}
```

### 1.5 Constants

Magic numbers do not appear in view bodies or computation logic. All constants are named `let`s in a namespacing `enum`. The `enum` is placed in the file that owns the concept.

```swift
enum HeatmapLayout {
    static let cellSize: CGFloat = 10
    static let cellSpacing: CGFloat = 2
    static let cornerRadius: CGFloat = 2
    static let columnCount: Int = 7
}
```

### 1.6 Guard and Early Exit

`guard` is used for early exits. Nested `if let` chains are permitted only when the inner binding is consumed exclusively within that branch and the nesting depth is two or fewer.

### 1.7 Extensions for Conformances

Each protocol conformance lives in its own `extension` block, separated by a `// MARK: - [ProtocolName]` comment. This is not a stylistic preference — it is the mechanism that makes conformances discoverable via file structure.

```swift
// MARK: - AppEntity
extension HabitBoard: AppEntity { ... }

// MARK: - Identifiable
extension HabitBoard: Identifiable { ... }
```

### 1.8 One @Model Per File

Each `@Model` type occupies exactly one file. Extensions to that model may live in separate files named `[ModelName]+[Role].swift` (e.g., `HabitBoard+Streak.swift`).

---

## 2. Naming Conventions

### 2.1 Types

| Category | Pattern | Examples |
|----------|---------|---------|
| `@Model` types | Plain compound noun | `HabitBoard`, `LogEntry` |
| SwiftUI Views | `[Noun]View` or `[Adj][Noun]View` | `HeatmapGridView`, `StatsPanel` |
| Intents | `[Verb][Noun]Intent` | `LogHabitIntent` |
| AppEntity types | `[Noun]Entity` | `HabitBoardEntity` |
| Actors | `[Noun][Role]` | `aggregateByDayWithGrace` (free function), `HeatmapDataProvider` |
| Error enums | `[Domain]Error` | `PersistenceError`, `SyncError` |
| Value types (analytics) | `[Domain][Role]` | `DayCell`, `DayTotal`, `StreakResult` |

The suffix `Manager` is banned. It communicates nothing about what a type does.

### 2.2 Properties

Booleans carry an `is`, `has`, `can`, or `should` prefix without exception.

```swift
var isArchived: Bool = false      // ✅
var archived: Bool = false        // ❌ — ambiguous as noun or verb
```

Point-in-time `Date` properties use the `[noun]At` convention. Calendar-day semantics use `[noun]Date` only when the time component is intentionally irrelevant.

```swift
var createdAt: Date               // ✅ — exact timestamp
var archivedAt: Date?             // ✅ — exact timestamp, optional = not archived
```

Optionals are named for their value, not their optionality.

```swift
var unitLabel: String?            // ✅
var optionalUnitLabel: String?    // ❌
```

### 2.3 Functions

Async functions use imperative mood. The `async` suffix is never appended to a function name.

```swift
func buildDayGrid(...) async -> [DayCell]     // ✅
func buildDayGridAsync(...) async -> [DayCell] // ❌
```

Test function names follow the pattern `test[Subject]_[Condition]_[ExpectedOutcome]`:

```swift
func testStreakCalculator_DSTFallBack_DoesNotBreakStreak() { ... }
func testAggregateByDayWithGrace_EmptyLogs_ReturnsEmptyArray() { ... }
```

### 2.4 Prohibited

The following are banned regardless of context: `Manager`, `Helper`, `Utils`, `Misc`, `Data` as a standalone suffix, `Info` as a standalone suffix, `SCREAMING_SNAKE_CASE` for constants, abbreviated names that are not established Apple conventions (`URL`, `ID`, `UI`, `OS` are permitted; `img`, `btn`, `vc` are not).

---

## 3. Concurrency

### 3.1 Structured Concurrency Only

`async/await`, `Task`, and `withTaskGroup` are the only concurrency primitives used in new code. `DispatchQueue`, `OperationQueue`, `NSThread`, and callback-based async APIs are banned for new work. Existing system callbacks (e.g., `NSPersistentCloudKitContainerEvent` notifications) are bridged via `withCheckedContinuation` or `AsyncStream`, not wrapped in `DispatchQueue.main.async`.

### 3.2 Actor Boundaries

`@MainActor` is applied to all `@Observable` types whose properties are read in a SwiftUI `View.body`. This is non-negotiable: a `@MainActor`-isolated observable type guarantees that state reads and writes occur on the same actor, preventing data races without explicit synchronization.

Background computation types (`aggregateByDayWithGrace`, `aggregateByDay`, the `buildDayGrid` free function) are `actor`-isolated or `nonisolated async` functions that execute on the cooperative thread pool.

`ModelContext` is never captured in a closure, passed as a parameter to an `actor` method, or used off the main actor. Model objects fetched on the main actor stay on the main actor. If background work requires data from the model, the caller extracts a value-type snapshot before the actor hop.

```swift
// ✅ Correct pattern — value-type snapshot crosses the actor boundary
let logSnapshot: [LogEntry] = await MainActor.run {
    board.logs?.filter { $0.timestamp >= startDate } ?? []
}
let cells = await HeatmapDataProvider.buildDayGrid(logs: logSnapshot, target: board.targetValue ?? 1)

// ❌ Banned — passing ModelContext or @Model objects across actors
actor BadAggregator {
    func compute(context: ModelContext) { ... } // context is MainActor-bound, this crashes
}
```

### 3.3 Task Discipline

`Task.detached` is permitted only when the work must genuinely outlive the calling actor's scope. Every use requires a comment: `// DETACHED: [reason work cannot be structured]`.

`Task.isCancelled` is checked at the top of every loop body in long-running tasks. Ignoring cancellation is a memory and CPU leak.

`@unchecked Sendable` requires a comment block that makes the manual safety argument explicit. Silent conformances are banned.

### 3.4 CloudKit Import Guard

Any state update triggered by an `NSPersistentCloudKitContainerEvent` is wrapped in `withAnimation(nil)`. Bulk remote imports must not drive SwiftUI layout recalculations mid-animation. The `ModelContainerFactory` observes `NSPersistentCloudKitContainerEvent` notifications and posts a `Notification` on the main actor that views can observe. Views never observe CloudKit events directly.

```swift
// In ModelContainerFactory — example notification handling
private func handleCloudKitEvent(_ event: NSPersistentCloudKitContainerEvent) {
    guard event.succeeded else { return }
    withAnimation(nil) {
        NotificationCenter.default.post(name: .cloudKitImportDidComplete, object: nil)
    }
}
```

---

## 4. Error Handling

### 4.1 Scope Rules

`do/catch` appears at the nearest point where recovery is meaningful — not at every call site, and not at the root of the call stack where context has been lost. `throws` propagates above the recovery boundary.

`modelContext.save()` is always inside `do/catch`. A failed save is logged at `.error` level and surfaces as a non-blocking in-app notification (a `View`-local overlay, not a `UIAlertController`). The user is informed that data may not be persisted. The app does not crash.

### 4.2 Banned Patterns

`fatalError()` does not appear in production code paths. It is permitted inside `#if DEBUG` guards when an invariant violation would make continued execution meaningless during development. `precondition()` and `assert()` are used for internal consistency checks that cannot occur given correct inputs — not for user-input validation.

```swift
// ✅ Development invariant check
#if DEBUG
precondition(board.targetValue ?? 0 > 0, "Target value must be positive before streak calculation")
#endif

// ❌ Banned in production
fatalError("Unexpected metric type")
```

### 4.3 Custom Error Types

```swift
enum PersistenceError: LocalizedError {
    case saveFailed(underlying: Error)
    case migrationFailed(version: String)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let error): return "Failed to save data: \(error.localizedDescription)"
        case .migrationFailed(let version): return "Schema migration to \(version) failed."
        }
    }
}
```

`LocalizedError` conformance is required on all custom error types. The `errorDescription` must be meaningful to a developer reading a log — not a user-facing string.

### 4.4 Logging

`Logger` from the `os` framework is the only logging mechanism. `print()` does not appear in any file. CI lint rejects it.

```swift
private let logger = Logger(subsystem: "com.mihirmaru.loca", category: "Persistence")

// Usage
logger.error("ModelContext save failed: \(error.localizedDescription, privacy: .public)")
logger.debug("Heatmap built: \(cells.count) cells in \(elapsed)ms")
```

Subsystem: `com.mihirmaru.loca`. Category matches the module: `"Persistence"`, `"Analytics"`, `"Widget"`, `"Intents"`, `"CheckIn"`, `"CloudKitSync"`.

CloudKit sync errors observed from `NSPersistentCloudKitContainerEvent` are logged at `.error` level and never surfaced to the user as alerts. Sync is silent.

### 4.5 Result vs throws

`throws` is the default for synchronous throwing functions. `Result<T, Error>` as a return type is used only when both the success and failure paths are consumed at the call site without a `do/catch` block — for example, in a `switch` statement. It is not used to avoid writing `do/catch`.

---

## 5. Performance Budgets

These are hard limits enforced by CI and manual Instruments profiling. They are not aspirational targets.

### 5.1 Budget Table

| Metric | Hard Limit | Profiling Tool |
|--------|-----------|----------------|
| App launch → first meaningful frame | < 400ms | Instruments: App Launch |
| Heatmap grid render (365 cells) | < 16ms | Instruments: SwiftUI Profiler |
| Single `@Query` result set size | ≤ 10,000 records | Core Data Profiler |
| Main thread synchronous work per call | < 1ms | Instruments: Time Profiler |
| Widget timeline generation (end-to-end) | < 200ms | Instruments: Time Profiler |
| Peak RSS (heatmap + chart visible) | < 100MB | Instruments: Allocations |
| `aggregateByDayWithGrace` on 10,000 `LogEntry` records | < 50ms | `XCTestCase.measure {}` |

### 5.2 Enforcement Rules

Any PR touching `HeatmapGridView`, `aggregateByDay`, `aggregateByDayWithGrace`, `buildDayGrid`, or `ModelContainerFactory` must include a Time Profiler screenshot in the PR description. PRs without it are returned without review.

`aggregateByDayWithGrace` has a `XCTestCase.measure {}` performance test seeded with 10,000 synthetic `LogEntry` records. This test runs in CI. A sustained 10% regression over the established baseline fails the build. `aggregateByDay` (the lighter, primary-attribution-only path used by `HeatmapDataProvider`) should be measured separately — its budget is tighter, since it omits the grace-window pass entirely.

`HeatmapCell` body must not: parse a `String` into a `Color`, allocate a new `Array`, create a `Task`, or call any method that accesses `modelContext`.

`@Query` predicates on `LogEntry` always include a date-range bound. Unbounded fetches are banned.

```swift
// ✅ Bounded — acceptable
#Predicate<LogEntry> { entry in
    entry.boardID == boardID &&
    entry.timestamp >= startDate &&
    entry.timestamp <= endDate
}

// ❌ Banned — unbounded scan of entire LogEntry table
#Predicate<LogEntry> { entry in
    entry.boardID == boardID
}
```

No `LazyVGrid` cell creates a `Task` in its `onAppear`. Cell-level async work routes through the parent view's `task` modifier, which the cell communicates to via a `Binding` or `Preference`.

### 5.3 Color Construction

`colorIndex: Int` maps to a compile-time palette array of `Color` values. No `Color(hex:)` parsing occurs at render time. The `ColorPalette` type exposes a static subscript.

```swift
enum ColorPalette {
    static let colors: [Color] = [
        Color(red: 0.22, green: 0.60, blue: 0.86),
        // ... 11 additional accessible colors
    ]

    static subscript(index: Int) -> Color {
        colors[max(0, min(index, colors.count - 1))]
    }
}
```

---

## 6. Accessibility Requirements

Accessibility is a first-class design constraint, not a retrofit. App Review automated accessibility audits will catch violations. These requirements are not negotiable.

### 6.1 Minimum Bar (All Views)

Every interactive element carries `accessibilityLabel` (what the element is) and `accessibilityHint` (what activation does). The label names the thing; the hint describes the action.

```swift
CheckInButton()
    .accessibilityLabel("Check in")
    .accessibilityHint("Logs today's entry for \(board.name)")
    .accessibilityValue(board.isCompletedToday ? "Logged" : "Not logged")
```

Minimum tap target is 44×44 points. `contentShape(Rectangle())` expands the hit area without changing visual size.

Color never serves as the sole conveyor of state. Every color-based state has a companion shape, label, or `accessibilityValue`. The heatmap cell intensity gradient is accompanied by the full `accessibilityLabel` describing the value in text.

All text uses system text styles (`Font.body`, `Font.caption`, etc.) or `.scaledMetric` for custom size values. Hardcoded point sizes that do not scale with Dynamic Type are banned.

WCAG AA contrast: all text achieves a minimum 4.5:1 contrast ratio against its background. The `ColorPalette` is validated at design time for all 12 entries against the app's background colors.

### 6.2 Heatmap Grid

`HeatmapGridView` conforms to `AXChartDescriptorRepresentable`. This is the mechanism VoiceOver uses to navigate the grid as a data chart rather than as 365 individual tap targets.

Each `DayCell` provides an `accessibilityLabel` constructed as:

```
"[Weekday], [Month] [D] · [value] [unitLabel] · [above / at / below] goal"
// Example: "Monday, March 15 · 3.2 miles · above goal"
// Empty day: "Tuesday, March 16 · no entry"
```

VoiceOver traversal order is calendar order (left-to-right within a week, top-to-bottom across weeks). `accessibilitySortPriority` is set explicitly on each cell — not left to SwiftUI's default spatial ordering, which is unreliable for grid layouts.

The grid container uses `.accessibilityElement(children: .contain)`.

### 6.3 Reduce Motion

`@Environment(\.accessibilityReduceMotion)` is checked before every `withAnimation` call. When `reduceMotion` is true, spring animations are replaced with a 0.1-second linear opacity transition. The `CheckInButton` scale effect is removed entirely when `reduceMotion` is true. Haptic feedback fires regardless of reduce motion setting.

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

private var checkInAnimation: Animation {
    reduceMotion ? .linear(duration: 0.1) : .rippleConfirm
}
```

### 6.4 HabitCardView

In list context, `HabitCardView` is readable as a single VoiceOver element with a synthesized label:

```
"[Habit name], [currentStreak] day streak, [today status]"
// Example: "Running, 14 day streak, not logged today"
```

This is achieved via `.accessibilityElement(children: .ignore)` on the card combined with a computed `accessibilityLabel` property.

---

## 7. Animation Standards

### 7.1 Canonical Springs

Two spring animations are defined at the project level. No other spring parameters are used without an explicit revision to this document.

```swift
extension Animation {
    /// Tactile confirm: check-in button press, log confirmation feedback.
    /// High energy, quick settle. Used where the gesture demands a physical response.
    static let rippleConfirm = Animation.spring(response: 0.3, dampingFraction: 0.5)

    /// Smooth settle: navigation transitions, sheet appearances, list insertions.
    /// Lower energy, overdamped. Used where smoothness matters more than impact.
    static let rippleSettle = Animation.spring(response: 0.4, dampingFraction: 0.75)
}
```

All `withAnimation` call sites use one of these two animations. Ad-hoc `.spring(response:dampingFraction:)` calls with custom parameters are banned.

### 7.2 Rules

Maximum animation duration is 0.5 seconds measured from gesture recognition to final rest position. This is a hard limit.

`.easeInOut` is banned for layout transitions. Springs only for element-level motion. `.linear` is permitted for looping or ambient animations (e.g., a loading pulse) and for the Reduce Motion fallback.

Stagger is capped at three elements. A cascade of more than three staggered elements crosses from choreography into noise.

`withAnimation(nil)` is required around any state change driven by a remote CloudKit import event or a bulk `ModelContext` mutation that did not originate from a user gesture.

Haptic feedback fires at the moment of gesture recognition — specifically, when the check-in is confirmed, not when the animation completes. The two are independent. Never block the haptic on animation state.

No animation modifiers (`withAnimation`, `.animation()`, `.transition()`) are applied to `LazyVGrid` cells in the heatmap. Cell-level animation invalidates lazy evaluation. If a cell needs to animate a state change (e.g., today's cell being filled in), the animation is on the cell's content layer (`fill` opacity), not on the cell's identity.

Scale values for press states are in the range [0.90, 1.0]. The `CheckInButton` uses `0.94` on press.

```swift
// ✅ Canonical press effect
CheckInButton()
    .scaleEffect(isPressed ? 0.94 : 1.0)
    .animation(.rippleConfirm, value: isPressed)
```

---

## 8. Testing Strategy

### 8.1 What Gets Tested

**Analytics module — unit tested to 80% line coverage:**

`StreakCalculator` — all public methods fully covered. The DST date set listed in §8.3 is mandatory, not optional. A `StreakCalculatorTests` file that does not cover DST transitions is incomplete.

`aggregateByDay` and `aggregateByDayWithGrace` (the lighter primary-attribution-only path and the full grace-window path respectively — see ADR-006) — unit tested with synthetic `[LogSnapshot]` arrays. Boundary conditions required: empty array, single entry, two entries on the same calendar day, entry exactly at midnight, entry during a DST transition hour. `StreakCalculator.calculate` additionally requires a `referenceDate` parameter injected explicitly in every test — never relying on the system clock at test-run time — to make the four mandatory DST dates below deterministic and repeatable.

`buildDayGrid` free function — snapshot test: given a deterministic `[LogEntry]` input, assert the output `[DayCell]` array matches a recorded fixture. This test guards against color math regressions.

**Persistence — integration tested with in-memory store:**

`ModelContainerFactory` with in-memory configuration: verify that `archivedAt == nil` predicate filters archived boards, that nullifying the relationship on archive does not crash, and that `boardID` on `LogEntry` matches the owning `HabitBoard.id` after insertion.

**Intents — tested with in-memory ModelContainer:**

`LogHabitIntent.perform()`: verify that a new `LogEntry` is inserted, `boardID` is populated, the streak update method is called, and the debounced `reloadTimelines()` path is triggered.

**Performance — enforced in CI:**

`aggregateByDayWithGrace` is measured with a `SeededModelContainer` containing 10,000 `LogEntry` records spread across two `HabitBoard` objects over three years. The `XCTestCase.measure {}` baseline is established on first successful CI run and stored in the repository. A 10% sustained regression fails the build.

### 8.2 What Is Not Unit Tested

SwiftUI view bodies are not unit tested. They are covered by snapshot tests (`HeatmapGridView`) and UI tests (critical user paths).

`ModelContainerFactory` against a live CloudKit container is not automated. It is manually validated before every schema change against the development CloudKit environment.

Test doubles: the only permitted test double is `ModelContainer` in in-memory configuration. No mock objects. No protocol extraction whose sole purpose is test injection. Real types with controlled inputs.

### 8.3 Mandatory DST Test Dates

Every test file covering `StreakCalculator` or any function using `Calendar.startOfDay` must include test cases anchored to these dates:

| Date | Transition | Direction |
|------|-----------|-----------|
| 2024-04-07 | AEDT → AEST (Australia) | Clocks back |
| 2024-11-03 | EDT → EST (US Eastern) | Clocks back |
| 2024-03-10 | EST → EDT (US Eastern) | Clocks forward |
| 2024-03-31 | CET → CEST (Central Europe) | Clocks forward |

The grace window (±90 minutes around midnight) must be verified to not break a streak on the transition date.

### 8.4 Seeded Test Data

A `SeededModelContainer` helper in the test target creates a deterministic set of `HabitBoard` and `LogEntry` records. It is the source of truth for snapshot tests and integration tests. It is never randomized. Same inputs, same outputs, every run.

### 8.5 UI Tests (Critical Paths Only)

Four user paths are covered by UI test automation. No others are added to UI test suites without explicit architectural review — UI tests are slow and fragile.

1. Cold launch → tap first board → check in (binary) → verify `currentStreak` increments.
2. Cold launch → tap quantitative board → enter value → confirm → verify today's total matches input.
3. New habit creation → fill all required fields → save → board appears in list.
4. `LogHabitIntent` execution via `XCUIApplication` shortcut trigger → verify `LogEntry` appears in board's journal section.

### 8.6 Coverage Floor

Analytics module: 80% line coverage enforced in CI via `--enable-code-coverage` and a coverage gate. All other modules: 60% line coverage. View files are excluded from coverage measurement.

---

## 9. Documentation Expectations

### 9.1 What Requires a Doc Comment

Any declaration that crosses a file boundary — used by code outside the file where it is defined — and whose name alone does not fully communicate its contract requires a `///` doc comment.

Required for: all `internal` and higher declarations on `@Model` types; all `actor` method signatures; `AppIntent.perform()` implementations; `ModelContainerFactory`'s factory method; the `buildDayGrid` free function; all `AppEntity` conformance methods.

Not required for: `private` helpers; SwiftUI `body` implementations; trivial computed properties whose names are fully self-documenting.

### 9.2 Doc Comment Format

```swift
/// Groups a flat array of log entries by calendar day and sums values per day.
///
/// This function runs off the main actor on the cooperative thread pool.
/// The caller is responsible for providing a pre-filtered array containing
/// entries from a single board only (filtered by `boardID`). Results are
/// sorted ascending by date.
///
/// - Parameters:
///   - logs: Pre-filtered `LogEntry` values for a single `HabitBoard`.
///   - target: The daily target value from `HabitBoard.targetValue`. Must be > 0.
///   - calendar: The `Calendar` used for day boundary computation.
///              Pass `Calendar.current` from the call site — never hardcode `.autoupdatingCurrent`.
/// - Returns: A `[DayCell]` array sorted ascending by date. Empty days are included
///            as cells with `intensity: 0`.
func buildDayGrid(logs: [LogEntry], target: Double, calendar: Calendar) async -> [DayCell]
```

Doc comments that restate the function name are noise and are prohibited.

```swift
// ❌ Noise — this communicates nothing
/// Returns the current streak.
var currentStreak: Int
```

### 9.3 Algorithm Comments

Any algorithm that is not immediately derivable from its function signature requires an explanatory comment block immediately before the implementation, introduced by a `// MARK:` header.

```swift
// MARK: - Streak Calculation
//
// A calendar day is "completed" if the sum of all LogEntry.value for that day
// is >= HabitBoard.targetValue.
//
// Grace window: entries within ±90 minutes of midnight on a DST transition date
// are attributed to the calendar day that produces a completed day. This prevents
// DST clock shifts from creating phantom missed days.
//
// The streak counter is a cached stored property (currentStreak: Int) updated
// incrementally on each LogEntry insertion. A full historical walk is performed
// only on first launch or after a schema migration.
//
// A day "in progress" (today, where it is not yet midnight) does not break the
// streak even if the target has not been reached.
```

### 9.4 Issue References

```swift
// TODO: #42 — migrate colorIndex to per-category palette in v2 schema
// FIXME: #67 — grace window needs adjustment for UTC+5:30 / UTC+5:45 (India, Nepal)
```

`TODO` and `FIXME` without a GitHub issue number are rejected in code review.

### 9.5 Architecture Decision Records

Maintained in `Docs/ADR/`. Required ADRs for this project:

| ADR | Decision | Status |
|-----|---------|--------|
| ADR-001 | Soft delete via `archivedAt` over `modelContext.delete()` | Adopted |
| ADR-002 | `colorIndex: Int` over `colorHex: String` | Adopted |
| ADR-003 | `boardID: UUID` denormalization on `LogEntry` | Adopted |
| ADR-004 | Target membership over local SPM package | Adopted |
| ADR-005 | Actor-isolated `HeatmapDataProvider` as `nonisolated async` free function | Adopted |

Each ADR is a single Markdown file with sections: **Status**, **Context**, **Decision**, **Consequences**. Status is one of: `Proposed`, `Adopted`, `Deprecated`, `Superseded by ADR-NNN`.

### 9.6 Banned in All Files

- Commented-out code. Delete it; Git history exists.
- `print()` statements.
- `// TODO` or `// FIXME` without a GitHub issue number.
- Doc comments that restate the function or property name.
- `// MARK: -` sections in files under 80 lines. Reserve them for files that genuinely need structural division.

---

## 10. Review Checklist

This checklist is run by the **author before opening a PR** and by the **reviewer before approving**. Both parties sign off explicitly.

### Author Self-Review

**Schema and Data**
- [ ] New `@Model` property has a default value or is explicitly `Optional`. No non-optional, non-defaulted properties.
- [ ] `modelContext.delete()` does not appear in the diff. All "deletions" set `archivedAt = Date()`.
- [ ] New `LogEntry` insertion populates `boardID` with the owning board's `id` before save.
- [ ] `@Attribute(.unique)` does not appear anywhere in the diff.
- [ ] If the diff modifies a `@Model` type: `VersionedSchema` is updated and a `MigrationPlan` has been tested against a seeded in-memory store.
- [ ] New CloudKit container field (any new property) has been validated in the development CloudKit environment before merge.

**Concurrency**
- [ ] No `DispatchQueue`, `OperationQueue`, or callback-based async primitives introduced.
- [ ] `ModelContext` is not passed to an `actor` method or captured in a `Task` that hops off the main actor.
- [ ] State update from a `NSPersistentCloudKitContainerEvent` is wrapped in `withAnimation(nil)`.
- [ ] `Task.detached` usage, if any, carries a `// DETACHED:` comment explaining the justification.
- [ ] `@unchecked Sendable` conformance, if any, carries a comment block making the safety argument explicit.

**Error Handling**
- [ ] `try?` usage, if any, carries an inline comment explaining why the failure is safely ignorable.
- [ ] `modelContext.save()` is inside a `do/catch` block.
- [ ] No `fatalError()` outside a `#if DEBUG` guard.
- [ ] New error types conform to `LocalizedError` with a meaningful `errorDescription`.
- [ ] New `Logger` call uses the correct subsystem and an appropriate category string.

**Performance**
- [ ] New `@Query` on `LogEntry` includes a date-range bound predicate. No unbounded fetch.
- [ ] `HeatmapCell` body does not parse `String → Color`, allocate a new collection, or access `modelContext`.
- [ ] No `LazyVGrid` cell contains an `onAppear { Task { ... } }` pattern.
- [ ] If the PR touches a file in the performance budget table (§5.1), a Time Profiler screenshot is attached to the PR description.

**Accessibility**
- [ ] New interactive element has `accessibilityLabel` and `accessibilityHint`.
- [ ] No state is communicated by color alone — companion shape, label, or `accessibilityValue` present.
- [ ] All interactive elements have a tap target ≥ 44×44pt.
- [ ] New animation has an `accessibilityReduceMotion` guard with an appropriate fallback.
- [ ] New text uses a system text style or `scaledMetric` — no hardcoded point sizes.

**Animations**
- [ ] All `withAnimation` calls use `Animation.rippleConfirm` or `Animation.rippleSettle`. No ad-hoc spring parameters.
- [ ] No animation duration exceeds 0.5 seconds.
- [ ] No `.animation()` or `withAnimation` modifier applied to `LazyVGrid` cells.
- [ ] Haptic and animation are independent — haptic fires at gesture confirmation, not at animation end.

**Widget and Intents**
- [ ] Any shared file (Core/, Analytics/, Intents/) has target membership verified on both Main App and Widget Extension targets.
- [ ] New `LogEntry` write triggers the debounced `reloadTimelines()` path, not a direct `WidgetCenter.shared.reloadAllTimelines()` call.
- [ ] `LogHabitIntent.perform()` initializes its own `ModelContext` from the App Group URL — it does not access any singleton.
- [ ] `AppShortcuts.updateAppShortcutParameters()` is called after any `HabitBoard` insert or archive.

**Code Quality**
- [ ] No `!` force unwrap outside `#if DEBUG`.
- [ ] No `print()` statements.
- [ ] No commented-out code.
- [ ] All `TODO` / `FIXME` comments include a GitHub issue number.
- [ ] New crossing-boundary declarations have a `///` doc comment.
- [ ] New non-obvious algorithm has an explanatory comment block before the implementation.
- [ ] Naming follows conventions in §2 — no `Manager`, no `Helper`, no magic number literals.

---

### Reviewer Sign-Off

- [ ] Naming in the diff follows §2 conventions without exception.
- [ ] Error handling in the diff follows §4 — no silent `try?` on any operation affecting persistent data.
- [ ] Animation parameters in the diff use only the canonical springs from §7.
- [ ] Any `Calendar` or date arithmetic in the diff accounts for DST. Confirm test coverage exists.
- [ ] Accessibility requirements are satisfied — VoiceOver traversal is logical, labels are present and correct.
- [ ] Performance budget is not regressed — Instruments screenshot present where §5.2 requires it, or a written explanation of why this diff is exempt.
- [ ] Architecture Decision Records are up to date if the PR introduces a new cross-cutting decision.

---

## Appendix A: Soft Delete Pattern (Reference)

This is the canonical pattern for all "deletion" operations in this project. No deviation.

```swift
// ✅ Canonical soft delete
extension HabitBoard {
    func archive(in context: ModelContext) throws {
        archivedAt = Date()
        do {
            try context.save()
        } catch {
            archivedAt = nil // rollback in-memory state
            throw PersistenceError.saveFailed(underlying: error)
        }
    }
}

// In @Query
@Query(filter: #Predicate<HabitBoard> { $0.archivedAt == nil },
       sort: \.createdAt)
private var activeBoards: [HabitBoard]
```

## Appendix B: Widget Timeline Debounce (Reference)

This is the canonical implementation for widget timeline invalidation. No direct `WidgetCenter.shared.reloadAllTimelines()` call sites exist outside this pattern.

```swift
// In a shared location, main actor isolated
@MainActor
final class WidgetRefreshCoordinator {
    static let shared = WidgetRefreshCoordinator()
    private var debounceTask: Task<Void, Never>?

    func scheduleReload() {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
```

## Appendix C: Heatmap Color Math (Reference)

The formula is locked. Any change to the color intensity calculation requires a revision to this document and a new snapshot test baseline.

```swift
// Cell intensity: linear scale from 0.0 (no entry) to 1.0 (at or above target)
// Clamped to [0, 1] — exceeding the target is not visually distinguished from meeting it.
let intensity: Double = min(1.0, dayTotal.value / max(1.0, target))

// Application to color: opacity over the board's palette color
ColorPalette[board.colorIndex]
    .opacity(intensity > 0 ? max(0.15, intensity) : 0)
    // Minimum opacity of 0.15 ensures any logged entry is visually distinguishable
    // from a zero-entry day, even for very small values relative to target.
```
