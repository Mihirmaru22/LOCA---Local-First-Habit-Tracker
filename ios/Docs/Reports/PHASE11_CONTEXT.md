# Phase 11 — Full UI/UX Redesign: Context & Plan

**Status:** Feature-complete app (Phase 10) → major visual redesign based on refined design spec.

**Design Direction:** Compact, premium, highly scannable habit tracking with inline progress visualization, horizontal habit pills, and enhanced detail-view analytics.

---

## Design Reference (from user images)

### Habit List View (Dashboard)
- **Current (Phase 10):** Vertical habit cards with large progress ring, text hierarchy, streaks
- **Target (Phase 11):** Horizontal pills with:
  - Habit icon/emoji + name (truncated)
  - Amount logged (e.g., "3.5 hrs") below name
  - Weekly bar chart (7 bars, last 7 days)
  - Check button (✓) on the right for quick logging
  - Compact: ~60pt height vs. ~100pt current
  - All data fits in one row

### Detail Page
- **Current:** Hero ring (64pt) + name/streak/status inline, then heatmap, stats, journal
- **Target:**
  - Full-width heatmap at top (grid with day labels: Sun/Mon/Tue/etc.)
  - Current Streak card (3 days) + Consistency gauge (arc, "Low/Medium/High") side-by-side
  - Current Month card (total "28 h" + weekly bar chart visualization)
  - Activity/Journal below
  - Navigation tabs at bottom (view modes)

### Edit/Settings
- **Color Picker:** Color wheel (not 6-color swatches)
- **Tinted Background Toggle:** Habit card background option
- **Unit Selector:** Hierarchical (Custom text input + predefined categories)
- **Review Reminder:** Setting to enable/disable daily reminders
- **Layout Toggle:** List vs. grid view option

### Main Menu
- **Settings Menu** (3-dot icon) with:
  - Layout (List/Grid/Timeline)
  - Review Reminder
  - Archive (view archived habits)
  - Settings (general app settings)

---

## Architecture Decisions

### ADR-011: Horizontal Pill Layout (HabitListView)
Replace vertical `HabitCardView` cards with horizontal `.rounded.pill` buttons containing:
- Left: Icon (emoji or system icon) + name + amount on 2 lines
- Center: Weekly bar chart (7 values, 6pt bars, spacing 2pt)
- Right: Checkmark button (quick log for binary) or "+X units" affordance

**Rationale:** Information density improves 3x; scrolling becomes faster; touch targets clearer.

### ADR-012: Weekly Chart Component (WeeklyBarChart)
New reusable component: 7 vertical bars representing the last 7 days, scaled by daily total.
- Input: `[Double]` array of daily totals
- Output: Rendered bars with appropriate tint (habit color or grayscale for incomplete)
- Used in: habit pill + detail month card + detail stats

**Rationale:** Inline visualization removes need to tap into detail for basic progress check.

### ADR-013: Detail Page Restructure (HabitDetailView v2)
Three primary zones:
1. **Heatmap Zone:** Full-width grid with day labels (Sun–Sat rows), scrollable right
2. **Metrics Zone:** 2×2 grid (Current Streak + Consistency Gauge, Current Month + bar chart)
3. **Activity Zone:** Scrollable journal entries below

**Rationale:** Makes history the primary focus; analytics secondary but visible without scrolling.

### ADR-014: Consistency Gauge (ArcGauge Component)
Arc-based gauge showing completion ratio or "streak health":
- Input: `fraction` (0…1), `label` ("Low" / "Medium" / "High")
- Output: Arc with text label
- Color: habit color tint or grayscale based on completeness

**Rationale:** More compact than progress ring; better for side-by-side layout.

### ADR-015: Color Wheel Picker (ColorWheelView)
Replace 12-swatch grid with continuous color wheel:
- Gesture: tap to select hue, drag to adjust saturation/brightness
- Fallback: predefined 12-color palette as quick-pick ring around the wheel
- Stores: HSB or hex value (mapped to closest palette color for consistency)

**Rationale:** Premium feel; infinite color space without redesigning for new colors; matches modern design systems.

### ADR-016: Tinted Background Toggle
Habit cards can have a subtle tinted background (10% opacity of the habit color).
- Default: OFF (clear/neutral background)
- Setting in edit form: "Use Habit Color Background"
- Applies to: habit pills, detail header

**Rationale:** Visual customization without overwhelming the UI; improves scannability when on.

### ADR-017: Settings Menu (not a separate page)
Three-dot menu on dashboard (and detail) opens a popover/sheet with:
- Layout (Radio: List / Grid / Timeline)
- Review Reminder (Toggle + time picker if enabled)
- Archive (Link to archived habits)
- Settings (Link to app-level settings)

**Rationale:** Keeps navigation shallow; settings are infrequently accessed.

---

## Subphase Breakdown

### Phase 11.1 — Habit List Redesign (HabitListView → HabitPillView)
- **Objective:** Replace vertical cards with horizontal pills
- **Scope:** New `HabitPillView` component, refactor `DashboardView` layout
- **Files:** HabitPillView.swift (new), DashboardView.swift (modified)
- **Dependencies:** Existing data model (no changes); WeeklyBarChart (11.2)
- **Deliverable:** Horizontal pill list with name, amount, 7-day visualization
- **Gate:** Pills render correctly on iOS and macOS; swipe-to-delete wired

### Phase 11.2 — Weekly Bar Chart Component (WeeklyBarChart)
- **Objective:** Reusable 7-day bar visualization
- **Scope:** Component definition, colors, scaling logic
- **Files:** WeeklyBarChart.swift (new)
- **Dependencies:** ColorPalette
- **Deliverable:** Compact chart used in pills and detail stats
- **Gate:** Bars scale correctly for habits with 0–100+ units

### Phase 11.3 — Detail Page Heatmap Prominence
- **Objective:** Expand heatmap to full-width top section with day labels
- **Scope:** Restructure `HabitDetailView`; add day-of-week labels to heatmap
- **Files:** HabitDetailView.swift (major refactor), HeatmapView.swift (label additions)
- **Dependencies:** Existing heatmap logic
- **Deliverable:** Heatmap grid with visible day labels; scrollable right
- **Gate:** Heatmap usable on narrow screens; labels don't clip

### Phase 11.4 — Consistency Gauge Component (ArcGauge)
- **Objective:** Arc-based metric indicator
- **Scope:** `ArcGaugeView` component (similar to `ArcProgressView`); compute consistency ratio
- **Files:** ArcGaugeView.swift (new)
- **Dependencies:** Canvas drawing, habit data
- **Deliverable:** Gauge rendering streak health or completion consistency
- **Gate:** Arc draws correctly; label updates on data change

### Phase 11.5 — Detail Metrics Grid (Streak + Consistency + Month)
- **Objective:** Lay out 2×2 metrics grid below heatmap
- **Scope:** Replace 3-card analytics row with new structure
- **Files:** HabitDetailView.swift (continued), AnalyticsCardsView.swift (refactor)
- **Dependencies:** ArcGauge (11.4), WeeklyBarChart (11.2)
- **Deliverable:** Current Streak card + Consistency gauge left column; Current Month + bar chart right column
- **Gate:** Cards stack correctly on narrow screens; no text truncation

### Phase 11.6 — Detail Activity Journal (Unchanged Structure)
- **Objective:** Keep journal section but refine positioning after metrics redesign
- **Scope:** Adjust spacing and layout post-redesign; no feature changes
- **Files:** HabitDetailView.swift (continued), JournalTimelineView.swift (minor tweaks)
- **Dependencies:** Prior phases
- **Deliverable:** Journal remains below metrics, fully scrollable
- **Gate:** Scroll performance smooth; no layout shifts

### Phase 11.7 — Color Wheel Picker (Edit Form Enhancement)
- **Objective:** Replace 12-swatch grid with color wheel
- **Scope:** `ColorWheelView` component; HSB/palette mapping; integration into edit form
- **Files:** ColorWheelView.swift (new), HabitFormView.swift (integrate)
- **Dependencies:** ColorPalette (mapping)
- **Deliverable:** Interactive color wheel in edit sheet
- **Gate:** Wheel responds to taps; selected color persists

### Phase 11.8 — Tinted Background Toggle
- **Objective:** Add UI option to enable habit card background tint
- **Scope:** Add `useColorBackground` field to `HabitBoard`; UI toggle in edit form; apply tint rendering in `HabitPillView`
- **Files:** HabitBoard.swift (migration), HabitFormView.swift (toggle), HabitPillView.swift (tint rendering)
- **Dependencies:** Model migration (Phase 1 update)
- **Deliverable:** Toggle in edit form; pill background changes on/off
- **Gate:** Migration doesn't corrupt existing data; tint visible at 10% opacity

### Phase 11.9 — Enhanced Unit Picker with Hierarchical Categories
- **Objective:** Refactor unit picker: Custom text input + predefined + currency/duration/distance hierarchies
- **Scope:** Expand `UnitOption` enum with more categories; redesign picker UI in edit form
- **Files:** UnitOption.swift (major expansion), HabitFormView.swift (picker redesign)
- **Dependencies:** Phase 10.2 `UnitOption` foundation
- **Deliverable:** Hierarchical picker with custom option
- **Gate:** All categories render; custom text input works

### Phase 11.10 — Settings Menu (Dashboard 3-Dot)
- **Objective:** Add popover/sheet menu for Layout, Review Reminder, Archive, Settings
- **Scope:** `SettingsMenuView`, integrate into dashboard toolbar
- **Files:** SettingsMenuView.swift (new), DashboardView.swift (integrate)
- **Dependencies:** Navigation patterns
- **Deliverable:** Menu accessible from dashboard; routes to subscreens
- **Gate:** Menu opens/closes smoothly; all options navigate correctly

### Phase 11.11 — Layout Toggle (List/Grid/Timeline)
- **Objective:** Add Layout choice to settings; implement Grid and Timeline views
- **Scope:** New view modes for dashboard; preference storage
- **Files:** DashboardGridView.swift, DashboardTimelineView.swift (new); DashboardView.swift (mode selection)
- **Dependencies:** Data model (state for layout preference)
- **Deliverable:** Toggle between List (11.1), Grid, Timeline; preference persists
- **Gate:** All three layouts render; swipe actions work in each

### Phase 11.12 — Archive Screen (Settings Submenu)
- **Objective:** New screen to view and restore archived habits
- **Scope:** Filtered list of archived boards; restore button
- **Files:** ArchiveListView.swift (new), navigation integration
- **Dependencies:** Soft-delete model (Phase 7)
- **Deliverable:** Archive view accessible from settings; restore action unarchives
- **Gate:** Archived habits visible; restore works; app reflects immediately

### Phase 11.13 — Review Reminder (Settings Submenu)
- **Objective:** Time-based daily notification to review progress
- **Scope:** User Notifications API; time picker in settings; on/off toggle
- **Files:** NotificationManager.swift (new), SettingsView.swift (time picker)
- **Dependencies:** iOS/macOS notification permission handling
- **Deliverable:** Toggle + time picker in settings; sends daily notification
- **Gate:** Notification fires at set time; permission prompt handled gracefully

### Phase 11.14 — Cross-Platform Validation (11.1–11.13)
- **Objective:** Ensure all redesigned views work on iOS and macOS
- **Scope:** Test responsive layouts, navigation, platform-specific modifiers, sidebar on Mac
- **Files:** All from 11.1–11.13 (tweaks for platform adaptation)
- **Dependencies:** `View+PlatformAdaptations` (Phase 10)
- **Deliverable:** All screens responsive; no iOS-only modifiers raw; macOS sidebar works
- **Gate:** Build clean on both platforms; no layout jank

### Phase 11.15 — Final UI Polish (Pass 1)
- **Objective:** Refine spacing, typography, color consistency across new design
- **Scope:** Audit button sizes, padding, color palette usage; match Apple design system
- **Files:** Multiple (minor adjustments across all redesigned components)
- **Dependencies:** Prior phases
- **Deliverable:** Polished, cohesive visual language
- **Gate:** Screenshots on iPhone and Mac show premium appearance; no rough edges

### Phase 11.16 — Accessibility & Performance (Final)
- **Objective:** Ensure Dynamic Type, VoiceOver, Reduce Motion work with new design
- **Scope:** Semantic font sizes (Phase 10.3 pattern), a11y labels for new components, perf profile
- **Files:** All redesigned components (audits + fixes)
- **Dependencies:** Phase 10.3 patterns
- **Deliverable:** Full a11y coverage; performance maintained
- **Gate:** VoiceOver navigation complete; Dynamic Type scales correctly; no performance regression

---

## Architecture Stability
- No data model changes (beyond `useColorBackground` field — backward compatible).
- No breaking changes to APIs; Phase 0–10 remain intact.
- All existing features preserved; redesign is **visual only** (minus settings menu, which is new).

---

## Estimated Effort
- Subphases 11.1–11.16: ~2 weeks (aggressive) to 4 weeks (deliberate polish)
- Each subphase should be testable and committable independently
- Performance and accessibility integrated throughout (not deferred)

---

## Next Step
**Phase 11.1** begins after this plan is approved. Starting with the horizontal pill redesign and `DashboardView` restructuring.
