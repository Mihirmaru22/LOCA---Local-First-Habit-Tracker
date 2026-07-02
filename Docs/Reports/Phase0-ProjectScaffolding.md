# Phase 0 Report — Project Scaffolding

**Phase:** 0 (executed after Phase 3 approval, before Phase 4 — see Docs/Phase0-ProjectScaffolding.md for the scheduling rationale)
**Status:** ✅ Complete — reviewed, H1 fixed, verified
**Date Completed:** 2026-07-01
**Next:** Phase 4 — Dashboard

---

## What Was Built

Phase 0 delivered runtime integration: the app entry point, CloudKit event
observation wiring, App Group/CloudKit entitlements, and the identifier migration
from the project's original working-title placeholders to LOCA's naming
convention. No feature logic — strictly making the existing Phase 1–3 architecture
runnable, per explicit scope agreement.

| File | Role |
|------|------|
| `App/LOCAApp.swift` | `@main` entry point — single `ModelContainerFactory.makeSharedContainer()` call site, hosts `RootNavigationView`, never `try!` |
| `App/CloudKitSyncCoordinator.swift` | Observes `NSPersistentCloudKitContainerEvent`, flags active boards via `HabitBoard.activePredicate` after CloudKit imports |
| `Core/Persistence/ModelContainerFactory.swift` (modified) | Identifier migration only — `appGroupIdentifier`, logger subsystem, doc-comment file references |
| `Core/Models/HabitBoard.swift` (modified) | One doc-comment reference migrated (`RippleCloneApp` → `LOCAApp`/`CloudKitSyncCoordinator`) |
| `LOCA.entitlements` | App Groups + CloudKit capability for the Main App target |
| `Docs/TargetMembershipManifest.md` | Every existing file mapped to its required Xcode target(s), with rationale |
| `ENGINEERING_PRINCIPLES.md` (modified) | Revision 1.1.0 → 1.2.0 — logger subsystem identifier migrated, per the document's own amendment process |

### Architecture Compliance Verified
- `ModelContainerFactory`'s "pure namespace, never instantiated" contract preserved — no logic added to it, identifiers only
- `CloudKitSyncCoordinator` is `@MainActor`-isolated, uses `NotificationCenter.notifications(named:)` (structured concurrency bridge) — zero `DispatchQueue`
- `withAnimation(nil)` applied around the CloudKit-triggered mutation per Engineering Principles §3.4
- Zero remaining `rippleclone`/`yourdomain`/`RippleCloneApp` references anywhere in the codebase (confirmed via full-repo grep; the four matches during verification were all historical/explanatory changelog text, not missed migrations)

---

## Resolved Architectural Tension

`HabitBoard.swift`'s Phase 1 H1 documentation stated the CloudKit event observer
lives "in `RippleCloneApp`." Engineering Principles §3.4 stated it lives inside
`ModelContainerFactory`. These conflicted: `ModelContainerFactory` is explicitly
documented as "a pure namespace of static factory methods... never instantiated,"
and adding stateful `NotificationCenter` observation to it would contradict that
contract. Resolved by introducing `CloudKitSyncCoordinator` as a dedicated type,
owned and started by `LOCAApp` — matching the framing already established in
`HabitBoard.swift`, leaving `ModelContainerFactory` untouched except for
identifiers. Flagged explicitly before implementation rather than resolved
silently.

---

## Review Findings

A formal review focused specifically on app lifecycle correctness, SwiftData
integration, CloudKit observer correctness, actor isolation, notification
handling, App Group configuration, error handling, target membership, runtime
behavior, and Apple platform conventions — explicitly excluding UI/feature-logic
commentary, per this phase's scope. Zero Critical findings. One High, two Medium,
two Low.

### High — 1 finding, resolved

| ID | Finding | Resolution |
|----|---------|-----------|
| H1 | `CloudKitSyncCoordinator.start()` was invoked from a `.task` attached to `RootNavigationView` — a per-window view, not a per-app one. `WindowGroup` provides a "New Window" command by default on macOS 14+ (a platform this project explicitly targets), with zero opt-in required. Opening a second window created a second call to `start()` on the same shared coordinator instance, producing duplicate `NotificationCenter` subscriptions — every CloudKit import would be fetched, mutated, and saved once per open window instead of once per app | Added an `isObserving: Bool` idempotency guard, checked and set as the first two statements inside `start()`, before the notification subscription is created. A second call while already observing is now a no-op, regardless of how many windows are open |

### Medium — 2 findings, deferred

| ID | Finding | Disposition |
|----|---------|------------|
| M1 | No debouncing on `.import` event handling — every CloudKit sync check-in (including ones delivering zero new records, which the public API provides no signal to distinguish) triggers a full fetch + mutation + save | Deferred — genuine Apple platform API limitation, not an implementation error. Track empirically; the same debounce pattern already used for `WidgetRefreshCoordinator` (Engineering Principles Appendix B) applies directly if it proves to matter in practice |
| M2 | `HabitBoard.activePredicate` (introduced in Phase 3, deferred there as low-probability) is now load-bearing in a real runtime path against a production `ModelContainer` for the first time, still empirically unverified | Deferred — no code change needed. Closes naturally on first real-device/simulator run against a provisioned CloudKit container |

### Low — 2 findings, both accepted as expected/mandated, not defects

| ID | Finding | Disposition |
|----|---------|------------|
| L1 | `CloudKitSyncCoordinator` imports `SwiftUI` solely for `withAnimation(nil)`, coupling a sync/persistence-layer type to a UI framework | Accepted — direct, explicit consequence of Engineering Principles §3.4's mandate, not a defect introduced by this implementation |
| L2 | `withAnimation(nil)`'s wrapped mutation currently has no observable effect, since no Phase 3 view reads `needsStreakRecalculation` yet | Accepted — correct, forward-looking, expected until a later phase reads the flag |

---

## Explicitly Verified During Review (Not Assumed)

Given the review's focus on actor isolation and notification handling, four
subtle Swift 6 concurrency questions were deliberately checked rather than
assumed correct:

- `App.init()` is `@MainActor`-isolated by protocol declaration, so constructing the `@MainActor`-isolated `CloudKitSyncCoordinator` synchronously inside `LOCAApp.init()` requires no `await` — confirmed correct
- SwiftUI's `.task` modifier closure runs on the MainActor per its own concurrency annotations, so `await cloudKitCoordinator?.start()` inside it needs no manual `MainActor.run` wrapping — confirmed correct, and using the modern `NotificationCenter.notifications(named:)` async-sequence API (rather than the legacy block-based `addObserver(forName:object:queue:using:)`, which delivers on an arbitrary thread with no automatic actor hop) avoided a real pitfall a less careful implementation would have hit
- A `@MainActor`-isolated class stored as a property on a non-`@MainActor` struct (`LOCAApp`) is valid under Swift 6 — confirmed correct
- Global (`object: nil`) `NotificationCenter` observation correctly receives events from SwiftData's internally-managed `NSPersistentCloudKitContainer` without a direct reference to that internal instance — confirmed correct, matching Apple's own documented pattern for this scenario

---

## Fix Verification (Re-Review Summary)

- **H1**: `isObserving` guard confirmed present as the first two statements in `start()`, before the notification subscription is created — a second call while already observing is confirmed to be a no-op. The guard is a `private var` on an `@MainActor`-isolated class with no external mutation path, introducing no new concurrency surface

No regressions: brace balance verified, no new force-unwrap/`print`/`fatalError`/`DispatchQueue` introduced, `handle(_:)` and `markActiveBoardsForRecalculation()` confirmed byte-for-byte unchanged, `LOCAApp.swift` confirmed untouched (the fix is fully self-contained to the coordinator).

---

## Deferred Items (Carried Forward)

- **Bundle/App Group/CloudKit identifiers** (`com.mihirmaru.loca` convention) — structurally correct, requires confirmation against a real registered Apple Developer Team before real-device/CloudKit testing
- **Widget Extension target + `LOCAWidget.entitlements`** — deferred to Phase 9, documented in `Docs/TargetMembershipManifest.md`
- **Info.plist** — deferred to actual Xcode project creation (build-setting-driven generation in modern Xcode, not a standalone file to hand-author)
- **The `.xcodeproj`/`.pbxproj` file itself** — requires Xcode's GUI or `xcodegen`/`tuist` tooling; cannot be reliably hand-authored as text
- **M1, M2** — see disposition table above

---

## Phase 4 Entry Criteria

- [x] Phase 0 formally approved
- [x] H1 resolved and verified
- [x] All internal identifiers reflect LOCA naming — zero remaining `rippleclone`/`ripples`/`yourdomain` strings anywhere in the codebase
- [x] `NSPersistentCloudKitContainerEvent` observer implemented, idempotent, and correctly actor-isolated
- [x] Target membership manifest complete for all existing files
- [ ] M2 (real-container `activePredicate` verification) — expected to close on first real-device build, not blocking Phase 4's start
