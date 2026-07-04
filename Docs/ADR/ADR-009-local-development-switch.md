# ADR-009 — `LOCAL_DEVELOPMENT` Compile-Time Persistence Switch

**Status:** Adopted
**Date:** 2026-07-03

## Context

CloudKit and App Group entitlements cannot be provisioned under a Personal Team, blocking local builds while a paid Apple Developer account is pending. The production architecture (CloudKit sync, App Group shared storage) must not change.

## Decision

`ModelContainerFactory` gains two additions: `makeLocalContainer()` (persistent on-disk, no App Group, no CloudKit) and `makeConfiguredContainer()` — the single centralized switch, containing the only `#if` in the codebase:

```swift
static func makeConfiguredContainer() throws -> ModelContainer {
    #if LOCAL_DEVELOPMENT
    return try makeLocalContainer()
    #else
    return try makeSharedContainer()
    #endif
}
```

`LOCAL_DEVELOPMENT` is a **custom** Active Compilation Condition, set only on the project-level Debug configuration — deliberately not the built-in `DEBUG` flag, since "optimized build" and "has real entitlements" are orthogonal. A paid-account developer building in Debug mode should still be able to exercise real CloudKit sync.

`LOCAApp.init()` is the only caller, redirected from `makeSharedContainer()` to `makeConfiguredContainer()` — one line. `LOCAApp` no longer knows which container variant it receives. No other file changes. `CloudKitSyncCoordinator` needs no changes: its own existing documentation already establishes that `NSPersistentCloudKitContainerEvent` notifications simply never fire against a non-CloudKit container — expected, not a defect, already covered.

## Re-Enabling Production

Remove `LOCAL_DEVELOPMENT` from the project-level Debug configuration's `SWIFT_ACTIVE_COMPILATION_CONDITIONS` build setting. Zero code changes. `makeConfiguredContainer()` resolves to `makeSharedContainer()` again immediately.

## Consequences

**Positive:** Production architecture (CloudKit, App Groups, entitlements) completely unmodified and undocumented-as-changed — because it hasn't changed. Every feature file remains fully unaware of which mode is active. Reverting to production is a single build-setting edit.

**Negative:** Local-development builds have no cross-device sync and no streak-recalculation-on-import behavior (since that's CloudKit-event-triggered) — expected and inherent to running without CloudKit, not a defect in this switch.
