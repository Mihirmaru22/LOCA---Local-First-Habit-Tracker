# ADR-004 — Xcode Target Membership Over Local SPM Package

**Status:** Adopted  
**Date:** 2025-06-28  

## Context

The Main App and Widget Extension targets need to share SwiftData `@Model` types, the persistence factory, analytics actors, and App Intents. Two structural approaches were evaluated:

**Option A: Local Swift Package (`RippleCore`)**  
Model types live in a separate local package, imported by both targets.

**Option B: Xcode Target Membership**  
Source files are added directly to both targets' membership lists in Xcode — one file on disk, compiled into two targets.

## Decision

Option B: Xcode target membership.

The disqualifying issues with Option A:

1. **`@Model` schema visibility.** `ModelContainer(for: schema, ...)` requires all `@Model` types to be resolvable from the same module that declares the schema. With a local package, any `@Model` type added to the main app target but accidentally omitted from the package fails with a cryptic runtime crash at container initialization — not a compile error.

2. **SwiftUI Preview resolution.** Xcode's Preview system resolves module dependencies at build time. Local packages add a module boundary that historically increases Preview compilation latency. At this project's size the overhead is unjustified.

3. **`public` access overhead.** A local package requires `public` access modifiers on everything consumed by either target. This adds syntactic noise and is an ongoing maintenance burden with no meaningful API-discipline benefit at this project's scale.

## Consequences

**Positive:**
- Zero module boundaries for the shared core — `internal` access everywhere.
- `@Model` schema registration is impossible to get wrong — all types in the same compile unit are visible to the same `ModelContainer`.
- Previews resolve faster.

**Negative:**
- Target membership must be set correctly for every new shared file. A file accidentally added to only one target compiles silently for that target and fails to link in the other. The PR checklist enforces this check.
- No enforced API discipline between "public" (shared) and "private" (target-specific) code. This is acceptable at current project size.
