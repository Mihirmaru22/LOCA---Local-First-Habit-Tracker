# PHASE 0 — Project Scaffolding

**Status:** Not started
**Type:** Numbered roadmap phase (position 0) — not off-roadmap release engineering
**Execution Order:** Deferred — runs immediately after Phase 3 approval, before Phase 4 begins

---

## Why Phase 0 Executes Out of Numeric Order

Phase 0 occupies position 0 in the roadmap because Phase 1's `ModelContainerFactory`
has a real runtime dependency on it, and every later phase inherits that dependency.
It is not, however, executed first chronologically.

Phases 1 (Data Layer), 2 (Compute Layer), and 3 (Navigation Shell) were deliberately
built and reviewed entirely against `ModelContainerFactory.makeInMemoryContainer()`
via SwiftUI Previews. This was a valid substitute for every review those phases
needed — schema correctness, algorithmic correctness, DST/concurrency correctness,
navigation structure and selection-state correctness — none of which requires a
running app, a real entitlement, or a live CloudKit container to verify. Running
Phase 0 upfront, before any of that existed, would have added Xcode-project and
provisioning ceremony to three phases that were correctly and fully reviewable
without it.

Phase 4 (Dashboard) breaks that pattern: it is the first phase where the deliverable
must be reviewed as a running experience, not a Preview canvas. Phase 0 is therefore
scheduled as the deliberate bridge — executed immediately after Phase 3's formal
review is approved, and completed before Phase 4's build command is issued. This
is a scheduling decision, not a scope relaxation: Phase 0's exit criteria (below)
are unchanged by when it runs.

---

## Scope

1. **Xcode project structure.** Main App target (iOS + macOS) and Widget Extension
   target, per ADR-004 target membership — no local SPM package. All Phase 1–3
   files added to correct target membership (`Core/`, `Analytics/` shared; `Features/`
   Main App only).

2. **`LOCAApp.swift`** — the `@main App` struct. Calls
   `ModelContainerFactory.makeSharedContainer()` exactly once (the single call site
   rule from Phase 1), injects the result via `.modelContainer()`, and hosts
   `RootNavigationView` (Phase 3) as the root view.

3. **App Group entitlement**, both targets, real identifier — replacing the
   `group.com.yourdomain.ripples` placeholder in `ModelContainerFactory.appGroupIdentifier`.

4. **CloudKit container entitlement**, verified against `cloudKitDatabase: .automatic`
   in `ModelContainerFactory.makeSharedContainer()`. This has been an open risk
   since the Phase 1 report; Phase 0 is where it gets closed.

5. **`NSPersistentCloudKitContainerEvent` observer**, per Engineering Principles §3.4
   and §4.4. Lives in `LOCAApp.swift` or a small adjacent coordinator it owns. Sets
   `HabitBoard.needsStreakRecalculation = true` on relevant boards after a bulk
   import event, and posts a main-actor notification per the immutable
   Engineering Principles pattern — views never observe CloudKit events directly.
   This is the mechanism that makes Phase 1's H1 fix and Phase 2's M4 finding
   actually functional; without it, `needsStreakRecalculation` is set nowhere
   and remains permanently `false`.

6. **Naming resolution.** Internal identifiers (`com.yourdomain.rippleclone` bundle
   ID, `"rippleclone"`/`"ripples"` group identifier and logger subsystem strings)
   resolved to LOCA's real identifiers. This closes the known naming drift between
   the original System Context Document's working title and the shipped product name.

7. **Basic app shell assets** — Info.plist, app icon, launch configuration. Not
   architecturally interesting; required for the app to install and run.

---

## Explicitly Out of Scope

Anything with feature logic. Phase 0 produces zero user-facing behavior beyond
"the app launches and shows the Phase 3 navigation shell against a real,
CloudKit-backed store instead of an in-memory Preview container." No dashboard
content, no check-in flow, no widgets, no App Intents — those remain scoped to
their own numbered phases exactly as before.

---

## Review Discipline

Phase 0 follows the same build → review → fix → push discipline as every other
phase. Given its scope (project configuration and a single entry-point file
rather than algorithmic code), the review should focus specifically on:

- Correct App Group / CloudKit entitlement configuration matching
  `ModelContainerFactory`'s expectations exactly (a one-character mismatch here
  was flagged as Phase 1 risk R4 — silent empty database, no crash)
- `NSPersistentCloudKitContainerEvent` observer correctness against Engineering
  Principles §3.4 (`withAnimation(nil)` guard, main-actor notification, no direct
  view observation)
- Target membership correctness for every Phase 1–3 file (per the PR checklist
  item in Engineering Principles §10, "Widget and Intents" section)

---

## Exit Criteria

Reviewed and pushed as its own phase — after Phase 3's approval, before Phase 4's
build command — following the identical build → review → fix → push discipline
as every other phase:

- [ ] App builds and runs on iOS simulator and macOS
- [ ] `RootNavigationView` (Phase 3) displays correctly against the real
      `ModelContainerFactory.makeSharedContainer()` container, not the in-memory Preview container
- [ ] CloudKit container verified reachable in the development environment
- [ ] `NSPersistentCloudKitContainerEvent` observer confirmed firing on a real sync event
- [ ] All internal identifiers reflect LOCA naming — no remaining `rippleclone`/`ripples` strings
- [ ] Phase 0 report written and pushed alongside the above, following the same
      report format as Phase 1 and Phase 2
