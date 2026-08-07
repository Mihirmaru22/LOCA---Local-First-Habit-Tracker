# LOCA Design Language

*The foundation every screen and every future module is accountable to. Phase 11.*

LOCA is a personal-improvement **platform**. Habits is its first module; Fitness,
Sleep, Nutrition, Journaling, and others will follow. Nothing in the design may
assume Habits is the permanent center. The system defined here is module-agnostic:
a run, a night's sleep, or a macro count must inhabit the same grammar a habit does.

---

## Identity — systemic, not singular

LOCA's identity is **not** any one hero element. It emerges from the disciplined
intersection of seven dimensions, each individually restrained so they compose
rather than compete. Someone should recognize a LOCA screenshot without the logo —
because every element obeys the same rules, not because one component shouts.

The seven identity-bearing dimensions:

1. **Numeric voice.** Every quantity — values, streaks, percentages, chart labels —
   renders in rounded SF numerals. LOCA tracks amounts; it speaks in numbers with a
   consistent rounded treatment. Prose stays default SF.

2. **Container restraint.** LOCA does not drown in nested rounded rectangles. Hairline
   dividers and whitespace separate content. A card appears only when its contents form
   a single tappable unit. The *absence* of gratuitous containers is part of the style.

3. **Spatial rhythm.** A strict 4-pt scale with slightly-more-generous-than-default
   vertical breathing. Calm is felt before it is noticed.

4. **The cell / contribution language.** The heatmap and its rounded-square cell
   vocabulary are an important, iconic LOCA motif — used deliberately where history
   matters. One important element among several, never asked to carry identity alone.

5. **A progress-visualization family.** The ring, the contribution cells, and
   quantitative bars are *one family*: shared stroke weights, rounded caps, and a
   single intensity ramp. A coherent visualization language, not scattered charts.

6. **Motion grammar.** Confirmations snap (tactile); transitions settle (soft).
   Nothing uses ad-hoc timing. Two named springs, enforced everywhere.

7. **Typographic hierarchy.** Decisive, confident contrast between tiers — never timid
   half-steps. Clear hierarchy is itself a signature.

**The discipline cost, stated honestly:** systemic identity is slower to build and
easier to erode than a single hero element. One screen that stacks gratuitous cards or
uses off-scale spacing breaks the spell. Every screen must obey all seven. This is the
deliberate trade for an original, premium, platform-grade product.

---

## Foundations (Apple HIG as the base)

Typography, spacing, navigation, accessibility, and interaction follow Apple's Human
Interface Guidelines as the substrate. LOCA's personality lives in *how* these are
tuned and composed, never in fighting the platform.

### Typography — `DS.Text`
- Semantic styles only (scale with Dynamic Type by construction). No fixed point sizes.
- **Numbers rounded, prose default.** `DS.Text.value(_)` applies rounded SF; body text uses system default.
- Decisive tier contrast: title → value → label are clearly distinct weights/sizes.

### Spacing — `DS.Space`
- 4-pt base scale: `xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32 · xxxl 48`.
- Referenced everywhere. No literal padding values in views.
- Vertical rhythm runs slightly generous; horizontal margins are consistent per surface.

### Radius — `DS.Radius`
- Role-based, concentric-correct: `cell 4 · control 10 · card 16 · sheet 22`.
- A control inside a card uses `control`; the card uses `card`; nesting stays visually concentric.

### Color — `DS.Color`
- Semantic roles layered **on top of** the frozen 12-entry `ColorPalette` (ADR-002 index
  stability is preserved — the palette is never reordered or replaced).
- Roles: `accent(for:)`, surface tiers, text tiers, separator. Adapts light/dark automatically.

### Motion — `DS.Motion`
- Two springs, promoted from `Animation+Extensions`: `.confirm` (tactile snap,
  0.3/0.5) and `.settle` (soft, 0.4/0.75).
- Reduce Motion is a **token**, not a per-view conditional: `DS.Motion.confirm(reduceMotion:)`
  returns a near-instant linear fallback. No view hand-writes the check.

### Iconography
- SF Symbols only, weight-matched to adjacent text. No custom icon set in Phase 11.
- Module glyphs (habit emoji today) are content, not chrome.

---

## Component library — `DS` components

Module-agnostic primitives. A future module reuses these unchanged.

- **`LOCACard`** — the single card container (radius `card`, one surface style). The only
  sanctioned rounded-rectangle container. If content is not a tappable unit, do not use it.
- **`SectionHeader`** — the one section-title treatment across every screen.
- **`MetricTile`** — a labeled value tile (value in rounded numerals + caption label).
  Habits use it for streaks; Fitness will use it for pace; Sleep for hours. Unchanged.
- **`ProgressRing`** — the arc ring (evolved from `ArcProgressView`), part of the
  visualization family (shared stroke weight + caps).
- **`ContributionField`** — the heatmap/cell grid, parameterized (full / mini / single-cell).
- **`ValueText`** — rounded-numeral text, the numeric-voice primitive.

---

## Interaction principles
- Every screen has **one** clear primary action and a single visual focus.
- Today's action outranks history: history *supports* the next action, never replaces it.
- Confirmations are tactile (`.confirm` + haptic on iOS). Navigation settles (`.settle`).
- Destructive actions confirm; nothing irreversible happens on a single unguarded tap.

## Accessibility (never an afterthought)
- Dynamic Type by construction (semantic styles only).
- Every interactive element has a label; composite rows collapse to one VoiceOver element.
- Reduce Motion honored via `DS.Motion` tokens.
- All palette colors meet WCAG AA (4.5:1) on LOCA surfaces, light and dark.

---

## Navigation & scalability
- Phase 11 root: a **"Today" surface** driven by a `ModuleDescriptor` seam, rendering
  exactly one section today (Habits). No placeholder tabs, no empty modules.
- Root container is `NavigationStack`, not a one-tab `TabView` (a single tab is the
  placeholder smell). When modules ≥ 3 arrive, the hub graduates to a Browse grid or
  `TabView` — a swap of *one* container, not the screens beneath it.
- Every component and token is module-agnostic so future modules plug in without redesign.
