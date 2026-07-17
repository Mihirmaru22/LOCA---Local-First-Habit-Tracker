# Phase 10 — Release Readiness: Context, Plan & QA Matrix

**Status:** Feature development complete (Phases 0–9). Phase 10 prepares LOCA for
release. No new features except genuine defect fixes; no architecture changes.

Subphases: **10.1** Runtime QA & Bug Fixes · **10.2** UI/UX Polish · **10.3**
Performance & Accessibility · **10.4** Release Readiness.

---

## Defect Log (seeded; append as QA proceeds)

| ID | Sev | Area | Description | Status | Routes to |
|----|-----|------|-------------|--------|-----------|
| D-01 | High | Widget / macOS | LOCA widget does not appear in the macOS widget gallery though the extension is embedded. Diagnostic `StaticConfiguration` widget pushed to bisect App-Intents-metadata vs extension registration. | Under diagnosis | 10.1 |
| D-02 | Low | macOS / Form | New Habit sheet goal field renders stretched full-width on macOS. | Fixed (10.2 P1: .formStyle(.grouped) + constrained goal field) | 10.2 |
| D-03 | Med | macOS / Sidebar | Habit cards truncate meaningful text in the narrow split-view sidebar. | Fixed (10.2 P1: sidebar min width 280) | 10.2 |
| D-04 | Low | Widget | Widget shows an empty "skeleton" in the gallery/pre-load. | Fixed (10.2 P1: representative placeholder + preview sample) | 10.2 |

Severity: **Critical** (crash/data loss) · **High** (feature broken) · **Med**
(degraded) · **Low** (cosmetic). Only genuine defects are fixed in 10.1;
cosmetic/layout items route to 10.2.

---

## Phase 10.1 — QA Validation Matrix

Execute each row on **iOS** (device or simulator) **and macOS (My Mac)** unless a
row is platform-specific. Mark Pass / Fail / N/A with a note. File any Fail into
the Defect Log above.

### A. Habit CRUD (Phase 7)

| # | Test | Expected |
|---|------|----------|
| A1 | Tap "+" → create binary habit ("Meditate") → Save | Appears in list; ring shows check state |
| A2 | Create quantitative habit with goal + unit ("Running", 3 mi) | Appears; goal "3 mi/day" shown |
| A3 | Save disabled with empty name / missing quant goal | Save stays disabled until valid |
| A4 | Detail → Edit → change name/goal/color → Save | Detail + list update reactively |
| A5 | Dashboard swipe → Delete → confirm | Board leaves list; **logs retained** (soft-delete, ADR-001) |
| A6 | Delete the currently-selected board | Detail column clears, no stranded state |

### B. Check-In Flow (Phase 6)

| # | Test | Expected |
|---|------|----------|
| B1 | Binary habit → tap check-in | Logs 1.0, marks done, streak updates, haptic (iOS) |
| B2 | Quantitative → open sheet → enter amount → save | Entry appears in journal; today total updates |
| B3 | Quantitative → multiple check-ins in a day | Totals accumulate; "Goal Met" when ≥ target |
| B4 | Check-in updates streak ring + heatmap immediately | Reactive update, no reload needed |

### C. Heatmap / Analytics / Journal (Phase 5)

| # | Test | Expected |
|---|------|----------|
| C1 | Detail heatmap renders last-N-days grid | Intensity scales with daily total/target |
| C2 | Analytics cards (30-day rate, check-ins, avg/entry) | Values match logged data |
| C3 | Journal lists entries grouped by day | Today + prior days, correct values/times |
| C4 | Empty habit (no logs) | Heatmap empty, analytics zeroed, no crash |

### D. App Intents / Shortcuts / Siri (Phase 8)

| # | Test | Expected |
|---|------|----------|
| D1 | Shortcuts.app → "Log Habit" → habit picker | Lists active boards only (archived excluded) |
| D2 | Run intent for quantitative → prompted for amount → enter | LogEntry persists; app reflects it |
| D3 | Run intent for binary | Logs 1.0; streak increments |
| D4 | Siri "Log Running in LOCA" | Same quantitative flow by voice |
| D5 | Archive a board → re-open Shortcuts picker | Board no longer offered |

### E. Widget (Phase 9)

| # | Test | Expected |
|---|------|----------|
| E1 | Widget appears in gallery (iOS + macOS) | LOCA "Habit Heatmap" listed | 
| E2 | Add widget → Edit → pick habit | Heatmap + streak + today progress render |
| E3 | No habit configured / none exist | Empty state shown, no crash |
| E4 | Tap widget check-in (binary) | Logs 1.0; app + widget update |
| E5 | Tap widget check-in (quantitative) | Logs one full goal (effectiveTarget); goal met |
| E6 | Day rollover | Grid + today reset at local midnight |

### F. Cross-Platform & Data

| # | Test | Expected |
|---|------|----------|
| F1 | Full build + run, iOS | No compile errors; app launches |
| F2 | Full build + run, macOS (My Mac) | No compile errors; app launches |
| F3 | Navigation: iOS NavigationStack, macOS NavigationSplitView | Correct per platform |
| F4 | CloudKit sync (2 signed-in devices, if available) | Habits/logs converge; no crash on merge |
| F5 | Kill + relaunch app | Data persists (local store) |

---

## Phase 10.1 Exit Criteria

- Matrix executed on iOS and macOS; results recorded.
- Every **Critical/High** defect fixed and re-verified (`one-build → one-root-cause-fix`).
- Remaining items fixed or explicitly logged as deferred with rationale.
- No regressions to previously runtime-validated phases (6, 7).
