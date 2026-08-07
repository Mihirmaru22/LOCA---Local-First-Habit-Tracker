# Phase P — Craftsmanship & Polish

*The phase where LOCA stops being feature-complete and starts feeling first-party.*

Feature work is done. Phase P adds **no features, no new screens, no architecture
changes, no business-logic changes**. It closes the gap between "works" and "feels
like Apple built it," measured against `DESIGN_LANGUAGE.md` (the seven identity
dimensions) and Apple's Human Interface Guidelines.

**The objective is not beauty.** It is to make the application feel *inevitable* — as if
every interaction could only ever have been designed this way. A polished screen invites
admiration; an inevitable one goes unnoticed because nothing about it could be otherwise.
Phase P succeeds when a change is invisible: the user never thinks "that's a nice
animation," only moves through the app without friction. Decoration draws attention to
itself and therefore fails this test by definition.

**Governing rule for every task below:** an animation, haptic, or effect ships only
if it improves *clarity* or makes an interaction feel more inevitable. If it is
decoration — if it announces itself — it does not ship. Simplicity outranks spectacle.
When in doubt, leave it calmer. This applies as much to P0's reconciliation (the detail
screen should read as if it were never anything but DS-native) as to every animation
that follows.

---

## Part 1 — Audit

Each surface is evaluated against seven questions:
1. What feels unfinished?
2. What feels abrupt?
3. What feels static?
4. What interaction lacks feedback?
5. What animation is missing?
6. What visual hierarchy can be improved?
7. What would Apple polish here?

### The overarching finding: two visual languages

Before per-screen notes, the single largest craftsmanship issue spans the whole app.

LOCA currently runs **two incompatible visual systems**:

- **DS system** (semantic light/dark color, `DS.Space`, `DS.Radius.card` = 16,
  semantic `DS.Text` fonts). Used by: List layout, Timeline layout, all sheets,
  the Analytics tab, every contextual card (Recommendation, Reflection, Goal).
- **Hardcoded dark theme** (`Color.black` background, `Color(white: 0.105/0.13/0.18)`
  card fills, corner radii `20`/`22`/`26`, fixed font sizes `42`/`52`/`11`/`9`).
  Used by: `HabitDetailView` Overview tab (the `Ref*` cards) and `HabitGridLayoutView`.

Consequences, each a direct violation of the project's own design language:

- **`HabitDetailView` shows both languages on one screen.** Overview tab (tab 0) is
  hardcoded dark; Analytics tab (tab 3) is DS-based `LOCACard`/`MetricTile`. Same
  screen, two looks.
- **Light mode is broken on the detail screen.** `Color.black.ignoresSafeArea()`
  and `Color(white:)` fills ignore the color scheme entirely. DESIGN_LANGUAGE.md:
  *"Adapts light/dark automatically."*
- **Fixed point sizes break Dynamic Type.** `Ref*` cards use `.font(.system(size: 42…))`.
  DESIGN_LANGUAGE.md: *"Semantic styles only… No fixed point sizes."*
- **Off-scale radii.** Grid cards use `20`, detail cards use `26`, heatmap card uses
  `22` — none are `DS.Radius` tokens (`cell 4 · control 10 · card 16 · sheet 22`).
- **Duplicate labels.** In the Overview tab, `RefStreakCard` and `RefConsistencyCard`
  both render the header text `"CONSISTENCY"`. One of them is mislabeled.

**Decision (confirmed):** full reconciliation. The `Ref*` Overview cards and the Grid
cards migrate onto DS tokens — semantic color, `DS.Radius`, `DS.Text` — restoring light
mode and Dynamic Type. Layout, information architecture, and data logic are untouched;
only the styling primitives change. This is the backbone of **P3** below.

---

### Screen: Today / Habit List (`HabitListView` + list/grid/timeline layouts)

- **Unfinished:** The dashboard empty state ("All Set" / "No habits yet") is a
  hand-rolled `VStack` with a generic `checkmark.circle.fill`, while the Journal uses
  the native `ContentUnavailableView`. Two empty-state idioms in one app.
- **Abrupt:** Switching layout (list ↔ grid ↔ timeline) is an instant `switch` swap —
  no crossfade. The undo toast auto-dismiss uses a bare `withAnimation {}` (default
  timing, not a motion token). Habit archival removes the row with the `@Query`
  default animation, unrelated to the motion grammar.
- **Static:** The three section zones (To Do / In Progress / Needs Attention / Done)
  appear fully formed; rows do not settle in. Streak numbers never animate when they
  change.
- **Lacks feedback:** Rows and the mode-selection buttons are `.buttonStyle(.plain)`,
  which strips the platform's press dimming — tapping a row gives no pressed state.
  The binary check button flips its icon with no scale/haptic-linked animation.
- **Missing animation:** Row insertion/removal by state; a numeric transition on the
  quantitative percentage; a settle on layout change.
- **Hierarchy:** Grid and Timeline layouts drop the state-zone `SectionHeader`
  grouping that the List layout has, so the same data reads with three different
  levels of structure.
- **Apple would:** Use `ContentUnavailableView` for empty state; animate row and
  section changes with a single spring; give every tappable row a real pressed state.

### Screen: Habit Detail (`HabitDetailView`)

- **Unfinished:** The whole Overview tab is the hardcoded dark theme (see overarching
  finding). Two cards labeled `CONSISTENCY`. Several save paths "silent fail" with a
  code comment and no user feedback (goal inference, timing, reflection, goal tuning).
- **Abrupt:** The four tabs switch via a `switch selectedTab` inside a `Group` — an
  instant content swap with no transition. The custom capsule tab bar changes the
  active icon with no animation, no selection haptic.
- **Static:** The heatmap cells populate after an async task and simply appear. The
  consistency arc and the month bars draw at final value with no fill animation.
- **Lacks feedback:** Tab icons (`RefTabIcon`) are `.buttonStyle(.plain)` with no
  pressed/selected visual weight beyond color; the `+` and edit buttons have no press
  state. No haptic on tab change or on opening the check-in sheet.
- **Missing animation:** Tab crossfade/slide; heatmap cell fade-in (optionally a gentle
  stagger); arc and bar draw-in; numeric `contentTransition` on the big month total.
- **Hierarchy:** `selectedTab` is a magic `Int` (0–3). The active tab has weak visual
  distinction. Fixed font sizes flatten the type hierarchy the DS scale is designed to
  create.
- **Apple would:** Reconcile to one theme, give the tab bar an animated selection
  indicator + selection haptic, crossfade tab content, animate the data visualizations
  in, and surface a lightweight failure toast instead of silent-failing saves.

### Screen: Add / Edit Check-in Sheet (`AddCheckInSheetView`, `EditCheckInSheetView`)

- **Unfinished:** The sheet always presents at full height; a quick amount entry could
  use a `.medium` detent. `isSubmitting` is tracked but the Save button shows no
  spinner — the flag only disables the button.
- **Abrupt:** On save the sheet dismisses immediately; the confirmation haptic fires
  but there is no visual acknowledgment of success before the sheet leaves.
- **Static:** The notes `TextEditor` border is a plain stroke; focus produces no accent.
- **Lacks feedback:** No focus highlight on the amount/notes fields; no haptic on
  reaching a valid state; Save's disabled→enabled transition is a bare opacity flip.
- **Missing animation:** In-progress spinner on Save; a brief success state.
- **Hierarchy:** `Date`/`Time`/`Amount`/`Notes` are all `DS.Text.body` labels with
  `Divider()`s — reads flat, no clear primary field.
- **Apple would:** Add sheet detents, a Save spinner, a focus accent on active fields,
  and a success haptic (`.notificationOccurred(.success)`) on commit.

### Screen: Create Habit (`SimpleHabitCreationView`)

- **Unfinished:** Multi-step flow (mode → name → metric → template) with no visible
  progress or step affordance; the user cannot tell how many steps remain.
- **Abrupt:** Steps swap with no transition; the `.mode` buttons and metric-type
  buttons are `.buttonStyle(.plain)` (no press feedback). The keyboard auto-focus fires
  after a hardcoded `400ms` sleep.
- **Static:** Metric-type selection toggles an icon (`circle` → `checkmark.circle.fill`)
  with no animation.
- **Lacks feedback:** No haptic on selecting a mode or a metric type; no confirmation
  flourish on habit creation.
- **Missing animation:** Step transitions (slide/push); selection state animation on
  the metric-type cards.
- **Hierarchy:** Fine — headings are `DS.Text.heading`, options are DS surfaces.
- **Apple would:** Animate step transitions in one direction (forward push), add a
  selection haptic, animate the radio-style selection, and celebrate creation.

### Screen: Check-ins History (`HabitCheckInsView`)

- **Unfinished:** Solid. Uses `List`, native `.swipeActions`, `LOCACard`. Empty state
  is a custom inline `VStack` rather than `ContentUnavailableView` (inconsistent with
  Journal).
- **Abrupt:** Quick-log commit clears the field instantly; the floating `+` has no
  press state.
- **Static:** The "TODAY" status card value doesn't animate when a new entry lands.
- **Lacks feedback:** Light haptic on quick-log exists (good); delete and duplicate
  have no haptic. Floating button uses a raw `Circle()` with no pressed scale.
- **Missing animation:** Numeric transition on the today total; row insert animation
  when a quick-log is added.
- **Hierarchy:** Good.
- **Apple would:** Unify the empty state, add `contentTransition(.numericText())` on the
  today total, and haptics on all destructive/duplicative actions.

### Screen: Journal (`JournalTimelineView`)

- **Unfinished:** Strong — native `ContentUnavailableView`, `List`, `.swipeActions`.
  This is the reference-quality screen; others should match it.
- **Abrupt:** Delete removes with the `List` default; acceptable.
- **Static/Feedback:** No haptic on delete. Otherwise clean.
- **Missing animation:** None material.
- **Hierarchy:** Good — rounded numeral value, secondary time/note.
- **Apple would:** Add a delete haptic. Little else — hold this screen up as the bar.

### Screen: Analytics (`HabitAnalyticsView` + chart views)

- **Unfinished:** No empty/first-run state — charts render flat lines / empty bars at
  zero data instead of a "not enough data yet" message.
- **Abrupt:** Charts appear at final state.
- **Static:** Every `Canvas` chart (`ConsistencyChartView`, timeline, streaks, year,
  weekdays) draws instantly with no path animation. The `ArcGaugeView` animates its
  fraction (good); the line/bar charts do not.
- **Lacks feedback:** Charts are non-interactive (acceptable), but there is no
  appear-transition to signal "this is live data."
- **Missing animation:** A single trim/opacity draw-in per chart on first appearance.
- **Hierarchy:** Good — `LOCACard` + `SectionHeader` + `MetricTile`.
- **Performance:** `monthlyScores` (and peers) are recomputed on the main thread inside
  computed properties — `ConsistencyChartView.monthlyScores` iterates 12 months × every
  day × all logs and is evaluated more than once per render (Canvas + stats row). On
  large histories this can jank the Analytics tab. Memoize per render.
- **Apple would:** Animate chart draw-in once, add a graceful low-data state, and
  compute series once per data change.

### Screen: Settings / Layout / Archive (`SettingsMenuView` and sub-sheets)

- **Unfinished:** `AppSettingsView` is a single "Version 1.0.0" row — spartan but
  acceptable for scope. Archive empty state is custom inline (not `ContentUnavailableView`).
- **Abrupt:** Layout picker applies and dismisses instantly with no selection haptic.
- **Lacks feedback:** Selection rows are buttons with no pressed state; the checkmark
  appears with no animation.
- **Missing animation:** Selection checkmark transition; a settle on the layout change
  it triggers back on the dashboard.
- **Hierarchy:** Good.
- **Apple would:** Add a selection haptic + animated checkmark, and unify the archive
  empty state.

### Component: Contextual cards (Recommendation, ReflectionPrompt, Goal cards)

- **Unfinished:** Dismiss `X` buttons are `14pt` icons with no explicit hit frame —
  under the 44pt minimum touch target.
- **Abrupt:** Recommendation carousel advances with a bare `withAnimation {}` (default
  timing, not `.settle`); cards appear/disappear with no transition when shown/dismissed.
- **Static:** The recommendation page dots don't animate on change.
- **Lacks feedback:** No haptic on "Try it," dismiss, or reflection-sentiment selection.
- **Missing animation:** Card insertion/removal transition; carousel content transition.
- **Hierarchy:** Good.
- **Apple would:** Enforce 44pt targets, move animations onto motion tokens, and add
  a selection haptic to the reflection choices.

### Component: Sync status indicator (`SyncStatusIndicatorView`)

- **Abrupt:** State changes (idle→syncing→error) swap with no transition even though the
  consumer wraps assignment in `withAnimation`; the view itself has no `.transition`.
- **Static:** The error chip is fine; the syncing `ProgressView` is default.
- **Apple would:** Add a `.transition(.opacity)` and animate idle↔syncing↔error.

### Cross-cutting: Motion, Haptics, Touch Targets, Perceived Performance

- **Motion:** Named tokens exist (`DS.Motion.confirm`/`.settle`, reduce-motion aware) but
  are under-used. Many sites call bare `withAnimation {}` or rely on `@Query`/default
  animations. `contentTransition(.numericText())` — Apple's standard for changing
  numbers — is used **nowhere**, despite LOCA's entire identity being its numeric voice.
- **Haptics:** Present only for check-in (`.rigid`) and quick-log (`.light`). Missing on:
  delete, duplicate, undo, tab/layout selection, metric-type selection, goal completion
  (the emotional peak — currently celebrated with nothing), and streak milestones. No
  use of `UINotificationFeedbackGenerator` (`.success`/`.warning`/`.error`).
- **Touch targets:** Card dismiss `X`s and some inline icon buttons fall below 44pt.
- **Perceived performance:** Heatmap and charts compute async/main-thread then pop in;
  chart series recompute redundantly. No skeleton or fade masks the gap.
- **Accessibility:** Good foundation (labels, `accessibilityHidden` on decorative rings,
  reduce-motion tokens). Gaps: fixed point sizes in `Ref*`/Grid cards break Dynamic Type;
  `GridHabitCard` fixed `height: 236` will clip at large text sizes; haptics not gated
  on a user setting.

---

## Part 2 — Phase P Roadmap

Eight subphases, each a small, independently-shippable set of tasks. Ordering is
deliberate: **P0 first** (it unlocks light mode + Dynamic Type and removes the second
visual language), then motion/microinteraction layers on the now-consistent base.

> Every task is additive polish or a token migration. None changes what the app does,
> what screens exist, or how data flows.

### P0 — Design-System Reconciliation *(foundation; do first)*

The full-reconcile decision. Migrate the two off-system surfaces onto DS tokens without
touching their layout or logic.

- **P0.1** — Migrate `HabitDetailView` background from `Color.black.ignoresSafeArea()`
  to `DS.Color.background`; verify the screen in light mode.
- **P0.2** — Migrate `RefHeatmapCard`, `RefStreakCard`, `RefConsistencyCard`,
  `RefMonthCard` fills from `Color(white:)` to `DS.Color.surface`; radii `26`/`22` → the
  correct `DS.Radius` token (`card` for cards; keep the heatmap container concentric).
- **P0.3** — Replace fixed font sizes in the `Ref*` cards (`42`/`52`/`22`/`13`/`11`/`9`)
  with `DS.Text` tokens (`valueHero`/`value`/`caption`/`footnote`) so they scale with
  Dynamic Type; keep the rounded numeral voice via `ValueText`.
- **P0.4** — Fix the duplicate `CONSISTENCY` header: `RefStreakCard` should read
  `CONSISTENCY`-family only once; relabel the streak/total card to its true metric
  (e.g. `TIMES LOGGED`).
- **P0.5** — Migrate `GridHabitCard` from `Color(.systemGray6)` + radius `20` to
  `DS.Color.surface` + `DS.Radius.card`; replace fixed header/label point sizes with
  `DS.Text` tokens; make the fixed `height: 236` a min-height so large type does not clip.
- **P0.6** — Sweep for remaining literal radii/`Color(white:)`/`.font(.system(size:))`
  across `Features/` and route through DS tokens. (Charts' internal `Canvas` numeric
  constants are exempt — they are geometry, not chrome.)

### P1 — Motion & Animation

- **P1.1** — Crossfade `HabitDetailView` tab content on `selectedTab` change using
  `DS.Motion.settle` + `.transition(.opacity)`.
- **P1.2** — Animate the layout switch in `HabitListView` (list/grid/timeline) with a
  settle transition instead of an instant swap.
- **P1.3** — Animate `SyncStatusIndicatorView` state changes with `.transition(.opacity)`.
- **P1.4** — Draw-in animation for the Analytics `Canvas` charts on first appear (single
  trim or opacity ramp, reduce-motion aware). One pass, no per-point choreography.
- **P1.5** — Fade heatmap cells in when `cellsByDate` populates (optional gentle stagger,
  capped so it never feels slow); reduce-motion → instant.
- **P1.6** — Replace every bare `withAnimation {}` (undo toast, recommendation carousel,
  archival) with the appropriate `DS.Motion` token.

### P2 — Microinteractions

- **P2.1** — Introduce a reusable pressed-state button style (subtle scale + opacity,
  reduce-motion aware) and apply it to habit rows, grid cards, timeline cards, and the
  mode/metric-selection cards currently using `.buttonStyle(.plain)`.
- **P2.2** — Add `contentTransition(.numericText())` to changing numbers: streak counts,
  today totals, month totals, percentages. (Directly serves identity dimension #1.)
- **P2.3** — Animate the metric-type radio selection in `SimpleHabitCreationView`
  (`circle` ↔ `checkmark.circle.fill`) with `.confirm`.
- **P2.4** — Animate the layout-picker checkmark and the settings selection states.
- **P2.5** — Add a focus accent to `AddCheckInSheetView` amount/notes fields on focus.
- **P2.6** — Animate the recommendation page dots on carousel change.

### P3 — Visual Hierarchy

- **P3.1** — Give `HabitDetailView`'s custom tab bar an animated selection indicator
  (moving pill or underline) and clearer active/inactive weight; replace the magic
  `Int` `selectedTab` with a named enum.
- **P3.2** — Add state-zone `SectionHeader` grouping to the Grid and Timeline layouts so
  all three layouts share one structural rhythm.
- **P3.3** — Strengthen the Add/Edit sheet field hierarchy (clear primary field; group
  secondary fields) using existing DS type tiers — no new layout.
- **P3.4** — Audit accent-color overuse on the detail screen post-P0 so the habit color
  reads as an accent, not a fill.

### P4 — Haptics

- **P4.1** — Centralize haptics in one `Haptics` helper (`impact(_)`, `selection()`,
  `notify(_)`), UIKit-gated, so call sites stop hand-writing generators.
- **P4.2** — Add a `.success` notification haptic on **goal completion** (the emotional
  peak) — fired when a check-in crosses the target, paired with a small ring/checkmark
  flourish (P2/P1). Once per crossing, never on every log.
- **P4.3** — Add selection haptics to tab change, layout change, metric-type selection,
  and reflection-sentiment selection.
- **P4.4** — Add impact haptics to delete, duplicate, and undo.
- **P4.5** — Gate all haptics behind a single setting (default on) surfaced in
  `AppSettingsView`; respect it in the `Haptics` helper.

### P5 — Empty & Loading States

- **P5.1** — Replace the dashboard, check-ins, and archive custom empty states with
  `ContentUnavailableView` (match the Journal's reference treatment).
- **P5.2** — Add a low-data state to the Analytics charts ("Keep logging to see trends")
  instead of flat zero-lines.
- **P5.3** — Add a light skeleton/placeholder (or a measured fade) for the heatmap and
  charts while their async/computed data loads, so nothing pops in from empty.

### P6 — Navigation & Flow

- **P6.1** — Add `.presentationDetents([.medium, .large])` to the Add Check-in sheet for
  quick entry.
- **P6.2** — Add a Save spinner (`ProgressView`) to `AddCheckInSheetView` while
  `isSubmitting`, and a brief success acknowledgment before dismiss.
- **P6.3** — Add forward/back step transitions to `SimpleHabitCreationView`; consider a
  lightweight step indicator (dots) if it reads as clarifying, not decorative.
- **P6.4** — Replace the goal-inference / timing / reflection / goal-tuning **silent
  save failures** with a small non-blocking failure toast (reuse the undo-toast pattern).

### P7 — Accessibility & Performance

- **P7.1** — Verify every screen at the largest Dynamic Type size after P0; fix any
  clipping (grid card height, tab bar, sheet fields).
- **P7.2** — Memoize chart series (`monthlyScores` and peers) so they compute once per
  data change, not multiple times per render.
- **P7.3** — Full VoiceOver pass: confirm composite rows collapse to one element, the
  new tab-bar selection announces state, and animated numbers announce final value.
- **P7.4** — Confirm every `DS.Motion` call site has a reduce-motion fallback (audit the
  new P1/P2 animations against the token contract).
- **P7.5** — Confirm palette accents still meet WCAG AA on the reconciled (now
  light/dark-adaptive) detail surfaces.

### P8 — Final Consistency Audit

- **P8.1** — Grep sweep: no remaining literal corner radii, `Color(white:)`, `Color.black`,
  or `.font(.system(size:))` outside `Canvas` geometry.
- **P8.2** — Confirm one empty-state idiom, one card container, one section-header
  treatment, one motion vocabulary across all screens.
- **P8.3** — Confirm haptics fire consistently for equivalent actions app-wide.
- **P8.4** — Side-by-side screenshot pass (light + dark, small + large type) of every
  screen against `DESIGN_LANGUAGE.md`'s seven dimensions; log any residual drift.
- **P8.5** — Update `DESIGN_LANGUAGE.md` only if a token was added (e.g. a pressed-state
  style or a haptics contract), keeping the doc the source of truth.

---

## Part 3 — Cross-Cutting Dependencies & Sequencing *(freeze addendum)*

Reviewed before implementation to avoid doing the same work twice. This section is
part of the **frozen** roadmap; the subphase ordering (P0 → P8) is unchanged. What
follows governs *how* the sequential work is executed, not *what order* the subphases
run in.

### The carry-forward rule

When a subphase opens a file that a later frozen subphase will also edit **on the same
element**, make both changes in that single pass and check the later item off early.
No element is edited twice. Subphases remain sequential in intent; files are touched
once. Any item pulled forward this way is annotated in the subphase it lands in, so the
roadmap stays the record of what happened.

### Shared primitives — build once, reuse everywhere

Two primitives are consumed across many subphases and by surfaces that P0/P3 already
restyle. They belong to the **design-system layer** (same tier as `LOCACard`,
`MetricTile`, `ValueText`) and are therefore created up front so later subphases *apply*
rather than *author* them:

- **`PressableButtonStyle`** (formally introduced by P2.1) — created as a DS primitive
  in P0; applied opportunistically wherever a `.buttonStyle(.plain)` currently strips the
  platform press state (rows, grid/timeline cards, selection cards). When P0 reconciles
  the Grid card and P3 regroups rows, the style is applied in the same pass.
- **`Haptics` helper** (formally introduced by P4.1) — created the first time a haptic is
  needed (that is **P2.3**, ahead of P4). P4 then extends and gates it; it does not
  re-create it. All new haptics route through this helper; the three existing hand-written
  `UIImpactFeedbackGenerator` sites (`HabitListView`, `HabitCheckInsView`,
  `AddCheckInSheetView`) are folded into it when those files are next opened.

Two more shared decisions, applied inline rather than as deferred passes:

- **`contentTransition(.numericText())`** (P2.2) is attached during P0 wherever the number
  is already being re-typed to a `DS.Text` token (month total, streak, grid values). P2.2
  then only sweeps the numbers P0 did not touch.
- **Reduce-motion fallback** (P7.4) is applied *inline* with every animation added in
  P1/P2 via the existing `DS.Motion.confirm/settle(reduceMotion:)` tokens. P7.4 becomes a
  verification checklist, not a re-touch of every animation.

### Multi-touch files — one editing pass each

These files are targeted by three or more subphases. All Phase P edits to each are made
in a single pass, driven by the carry-forward rule:

- **`HabitDetailView.swift`** — P0 (reconcile `Ref*` cards + background + tab-bar chrome),
  P1.1 (tab-content crossfade), P1.5 (heatmap cell fade-in via `RefHeatmapCard`), P3.1
  (tab-bar selection indicator), P4.3 (tab selection haptic). **Dependency A:** the
  `selectedTab` `Int` → named-enum refactor (nominally P3.1) is performed with P1.1, since
  both edit the same `switch`; only the animated indicator visual remains P3.1.
- **The five `Canvas` charts** (`ConsistencyChartView`, `TimelineChartView`,
  `StreaksChartView`, `YearComparisonChartView`, `WeekdaysChartView`) — P1.4 (draw-in),
  P5.2 (low-data state), P7.2 (series memoization). Each chart file is opened once and all
  three concerns are addressed together.
- **`AddCheckInSheetView.swift`** — P2.5 (focus accent), P6.1 (detents), P6.2 (Save
  spinner + success). One pass.
- **`SimpleHabitCreationView.swift`** — P2.3 (metric-selection animation + first haptic),
  P6.3 (step transitions). One pass.

### Net effect on P0

P0's task list gains two foundational primitives (created, not yet widely applied) so the
rest of the phase consumes them:

- **P0.7** — Add `PressableButtonStyle` as a DS primitive (subtle scale + opacity,
  reduce-motion aware). Apply it to any `.buttonStyle(.plain)` surface P0 already opens
  (Grid card); leave the remaining call sites for P2.1.
- **P0.8** — Add a `Haptics` helper stub (UIKit-gated `impact/selection/notify`), not yet
  gated on a setting. It exists so P2.3 (the first consumer) routes through it. Full
  gating + call-site consolidation remains P4.

Nothing else in P1–P8 changes. Roadmap is now **frozen**.

---

## Definition of done for Phase P

- One visual language: light/dark-adaptive, Dynamic-Type-correct, DS-tokenized, on every
  screen including Habit Detail and Grid.
- Every state change that matters (tab, layout, sync, data load, number change) has an
  intentional, reduce-motion-aware transition on a named motion token.
- Every equivalent action has consistent, setting-gated haptic feedback; goal completion
  is actually celebrated.
- One empty-state idiom, one card, one section header, one motion vocabulary.
- No fixed sizes, off-scale radii, or hardcoded colors outside chart geometry.
- Nothing new was added. Every change made an existing thing clearer or more felt.
