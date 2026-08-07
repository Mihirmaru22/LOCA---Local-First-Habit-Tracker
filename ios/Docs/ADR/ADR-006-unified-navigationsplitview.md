# ADR-006 — Unified `NavigationSplitView` Across All Platforms

**Status:** Adopted
**Date:** 2026-06-30

## Context

The original System Context Document specified per-platform navigation topology:
`NavigationSplitView` for macOS/iPadOS, `NavigationStack` for iOS, implying two
separate layout trees selected via `#if os(macOS)` (or an equivalent size-class
branch) at the call site.

An architectural critique of that spec identified this as the wrong abstraction:
Apple's own multiplatform guidance, and `NavigationSplitView`'s built-in adaptive
column-collapsing behavior, handle iPhone, iPad (compact and regular), and Mac in
a single code path. `NavigationSplitView` on a compact-width device (iPhone)
automatically collapses to show one column at a time with stack-like push/pop
behavior — there is no scenario it cannot already represent without a parallel
`NavigationStack` implementation.

This decision was agreed during the critique exchange but was never written down
as a numbered ADR. Phase 3 is the first phase that actually implements navigation,
making it the correct point to formalize the decision already in effect.

## Decision

A single `NavigationSplitView` (`RootNavigationView`) is used for every platform
and size class. `columnVisibility` is left at `.automatic`, letting the system
choose collapsed-vs-expanded presentation per device. `.navigationSplitViewStyle(.balanced)`
keeps sidebar and detail at reasonable proportions when both are visible.

`#if os(macOS)` / `#if canImport(UIKit)` are reserved strictly for genuine API-level
differences (e.g., `UIImpactFeedbackGenerator` vs `NSHapticFeedbackManager` in a
later phase) — never for layout branching. No layout-level platform conditional
exists anywhere in the navigation shell.

## Consequences

**Positive:**
- One layout tree to maintain, test, and reason about instead of two.
- iPhone, iPad, and Mac all inherit any future navigation change automatically —
  no risk of the two trees drifting out of sync with each other.
- Matches Apple's own documented multiplatform guidance rather than working
  against the framework's adaptive behavior.

**Negative:**
- Less fine-grained control over iPhone-specific navigation chrome than a
  hand-built `NavigationStack` would offer, should a future phase need iPhone-only
  navigation UI that diverges meaningfully from the collapsed split-view
  presentation. No such need has arisen through Phase 3; if one does, it should
  be solved within the existing `NavigationSplitView` (e.g., via `.toolbar`
  conditionals) before reconsidering this ADR.
