# ADR-002 — `colorIndex: Int` Over `colorHex: String`

**Status:** Adopted  
**Date:** 2025-06-28  

## Context

The original spec defined `colorHex: String` on `HabitBoard` to store the board's theme colour. During heatmap rendering, each of the 365 `DayCell` views needs a `Color` value derived from the board's colour. With `colorHex`, this requires parsing a hex string into a `Color` on each cell render — 365 string operations per render cycle.

Additionally, freeform hex strings provide no guarantee that chosen colours meet WCAG AA contrast requirements or present a coherent visual palette.

## Decision

`colorHex: String` is replaced by `colorIndex: Int`, which indexes into a compile-time array of 12 predefined `Color` values in `ColorPalette.swift`.

`ColorPalette` provides an O(1) bounds-safe subscript:

```swift
ColorPalette[board.colorIndex]  // O(1), no allocation, no parsing
```

`ColorPalette.heatmapColor(forColorIndex:ratio:)` encapsulates the full colour math from Engineering Principles Appendix C in one testable, view-independent location.

## Consequences

**Positive:**
- Zero string parsing in the heatmap render path — each cell performs one array subscript.
- Palette entries can be WCAG-validated at design time before shipping, rather than accepting arbitrary user hex values.
- Out-of-bounds indices return index 0 gracefully, preventing crashes when a future app version adds palette entries and an older build receives the higher index via CloudKit.
- `ColorPalette.count` drives the `NewHabitForm` colour picker grid directly.

**Negative:**
- Users cannot choose arbitrary colours. The 12-entry palette is a creative constraint.
- Adding colours requires appending to `ColorPalette.colors` — insertion at any position other than the end changes existing boards' colours. This constraint is documented in the file.
- WCAG AA validation of the 12 colours against both light and dark backgrounds is required before `NewHabitForm` (Phase 7) ships. Not yet complete.
