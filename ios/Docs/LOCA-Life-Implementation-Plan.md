# LOCA — Life Vertical: Phased Implementation Plan

*The bridge from the frozen vision to shipped code. This plan does not re-open the
vision — it sequences its construction. Every phase serves `LOCA-Founding-Manifesto.md`
(purpose, refusals, ontology), `LOCA-Product-Experience.md` (the interaction), and the
learning/structure design in `PersonalLifeModel*.md`, under the constraints of
`ENGINEERING_PRINCIPLES.md` (Swift 6 strict concurrency, on-device inference,
performance & burden budgets, accessibility, test floors).*

---

## How this plan is sequenced

Five rules govern the order, and they are why the phases are shaped the way they are:

1. **De-risk the unproven bet first.** The whole product hinges on one question no
   document can answer: *does a "view" feel like seeing, not reading — and can it be
   bent?* Phase 1 builds that by hand on seeded data and gates everything after it. We
   do not build the engine until the interaction is proven.
2. **Passive-first, always.** Sensing and inference (the assets) come before any asking
   (the debt). The learning engine is built before the question surfaces exist.
3. **Every phase compounds.** Nothing is throwaway after Phase 1's proof; each phase is
   a foundation the next stands on.
4. **The refusals are gates, not guidelines.** No session ships if it makes LOCA a
   preacher, a second master, or a black box. Each phase names how it honors them.
5. **On-device or it doesn't ship.** The life model never leaves the device. This is a
   hard architectural invariant checked every phase, not a Phase 10 audit.

**Session anatomy.** Each session states: **Goal**, **Deliverables**, **Depends on**,
and **Done when** (its exit criteria). Cross-cutting gates (tests, perf, a11y, privacy)
in §Cross-Cutting apply to every session; they are not repeated per session.

**Go/No-Go gates** appear between phases where a decision must be made before spending
further. They are explicit and named.

---

## Phase map

| Phase | Theme | Sessions | Output |
|---|---|---|---|
| **1** | Prove the View (de-risk) | 1.1–1.4 | A hand-built, bendable View on seeded data + a go/no-go verdict |
| **2** | The Foundation (data + local-first spine) | 2.1–2.4 | The 8-entity on-device store with first-class uncertainty |
| **3** | Passive Sensing (streams → Moments) | 3.1–3.4 | On-device ingestion of every free signal |
| **4** | Reconstruction (Moments → the day) | 4.1–4.3 | The auto-built episodic day |
| **5** | The Learning Engine (States, Traits, honesty) | 5.1–5.5 | Calibrated inference with visible uncertainty |
| **6** | Structure over Time (Events, Chapters, graph) | 6.1–6.4 | Regime-aware model + the relationship graph |
| **7** | Direction (the first-person layer) | 7.1–7.2 | Values/intentions + forks, linked to the trajectory |
| **8** | The Perspective Interaction (production) | 8.1–8.7 | The real Present, Reach, Ask→View, Focus, Threads |
| **9** | Onboarding, Trust & the First 10 Minutes | 9.1–9.3 | The first-run experience and the trust surfaces |
| **10** | Hardening (perf, a11y, sync, safety, tests) | 10.1–10.5 | A shippable, audited, 20-year-durable vertical |

---

## Phase 1 — Prove the View

**Intent.** Before a single line of the engine, answer the one question that decides the
product. Build *one* View by hand, on hand-authored data, and put it in front of real
people. This phase is cheap by design and is allowed to be thrown away except for the
seeded dataset. **It is the most important phase in the plan.**

**Serves:** `LOCA-Product-Experience.md` §4, §10 (the Kay and Victor tests).

### Session 1.1 — The seeded life
- **Goal:** A deterministic, hand-authored life to prototype against — one fictional
  person, ~6 months, realistic Moments, a few States per day, one clear Life Event
  (e.g., "started internship").
- **Deliverables:** A fixed fixture (not random) of the raw material a real engine would
  later produce; enough texture that a View composed from it feels like a real life.
- **Depends on:** nothing.
- **Done when:** the dataset is deterministic, reviewable, and rich enough that a "before
  vs after the event" contrast is legible in the raw data by a human reader.

### Session 1.2 — The single hand-built View
- **Goal:** Compose *one* View — *"Am I happier since starting my internship?"* — as a
  scene the user reads and concludes from, **not** a verdict, **not** a chart. Uncertain
  parts render soft.
- **Deliverables:** A working, non-productionized View over the 1.1 fixture: the before/
  after composition, soft uncertainty, a few pull-able soft threads (non-functional stubs
  are fine).
- **Depends on:** 1.1.
- **Done when:** it runs on device and a first viewer can reach a conclusion *without*
  being told one.

### Session 1.3 — Bend it
- **Goal:** Make one variable in the View manipulable — *"what if I'd kept the old
  commute?"* — and have the scene respond. This tests the Victor frontier: thinking-with,
  not just looking-through.
- **Deliverables:** One counterfactual control wired to a re-composition of the same View.
- **Depends on:** 1.2.
- **Done when:** changing the variable visibly, believably changes the scene.

### Session 1.4 — The verdict gate
- **Goal:** Put 1.2/1.3 in front of ~5–8 real people on their own reaction, and decide.
- **Deliverables:** A short, honest read: did they feel they **saw** something (vs read a
  chart)? Did bending it feel like insight? A written go/no-go.
- **Depends on:** 1.2, 1.3.
- **Done when:** a documented decision exists.

> ### 🚦 GO/NO-GO GATE A
> If the View reads as "a chart with softer edges," **stop and redesign the interaction**
> before building any engine. If it reads as *seeing*, proceed to Phase 2. This gate
> exists to prevent spending the expensive phases on an unproven interaction.

---

## Phase 2 — The Foundation

**Intent.** The on-device data spine for the 8-entity ontology, CloudKit-safe, with
**uncertainty as a first-class citizen** — because every later phase and the entire "soft
blur" UI depend on every inferred value carrying calibrated confidence.

**Serves:** manifesto ontology; `ENGINEERING_PRINCIPLES.md` §1, §3, §8, §9.

### Session 2.1 — The entity schema
- **Goal:** The eight entities as SwiftData `@Model` types — **Moments, States, Traits,
  People, Places, Life Events, Chapters, Direction** — with the relationships between them
  (a Life Event opens a Chapter; States/Traits attach to the self; People/Places
  participate in Moments).
- **Deliverables:** `@Model` types (one per file, per principles §1.8), a `LifeSchemaV1`
  versioned schema and migration plan, all CloudKit-safe (optionals/defaults, no
  `@Attribute(.unique)`, indexed enums as `Int` raw values).
- **Depends on:** Gate A.
- **Done when:** the schema builds, round-trips through an in-memory store, and an ADR
  records the States-vs-Traits "shared mechanism, separate concepts" decision.

### Session 2.2 — Persistence & the right to forget
- **Goal:** The store and its lifecycle, including deletion as a first-class operation
  (the trust requirement: a user can delete any node, person, or event and it stays gone).
- **Deliverables:** A life `ModelContainer` (shared App Group; ADR on shared-vs-separate
  store from the habit container), typed `LifeError`, soft-delete + hard-forget paths,
  `do/catch + rollback` at every save site.
- **Depends on:** 2.1.
- **Done when:** create/read/forget round-trips are tested against an in-memory store and
  forgetting is verifiably irreversible.

### Session 2.3 — Uncertainty as a first-class value
- **Goal:** The representation every inferred value uses — a value **plus calibrated
  confidence** plus an epistemic/aleatoric tag — so the engine and the "soft" UI share one
  honest primitive.
- **Deliverables:** A value type for estimates carrying `(estimate, confidence,
  uncertaintyKind)`; the convention that no inferred property is stored bare.
- **Depends on:** 2.1.
- **Done when:** States/Traits store estimates in this form and a test asserts confidence
  is always present and bounded.

### Session 2.4 — The seeded life store
- **Goal:** A deterministic seeder (the production analog of Phase 1's fixture and of
  `DebugSeeder`) that populates the real schema for every downstream test.
- **Deliverables:** `LifeSeeder` — deterministic, DEBUG/test only, no-op if data exists.
- **Depends on:** 2.1–2.3.
- **Done when:** it deterministically produces the same store every run, and is the source
  of truth for Phase 3+ tests.

---

## Phase 3 — Passive Sensing

**Intent.** Harvest every free stream on-device and turn it into **Moments** — the assets
that make questions unnecessary. Nothing here asks the user anything.

**Serves:** `PersonalLifeModel-LearningEngine.md` §4.0; the "passive-first" law.

### Session 3.1 — HealthKit ingestion
- **Goal:** Sleep timing, steps, workouts, heart rate/HRV, mindful minutes → Moments.
- **Deliverables:** An on-device HealthKit reader mapping samples to Moments; permission
  requests framed as *"the view this unlocks,"* with graceful degradation if declined.
- **Depends on:** Phase 2.
- **Done when:** granting/denying each type behaves correctly and Moments appear from real
  Health data on device.

### Session 3.2 — Context ingestion
- **Goal:** Calendar (event density/types/attendees), location clusters & transitions,
  motion type, weather, daylight → Moments, entirely on-device.
- **Deliverables:** Context readers with the same permission framing; People/Places
  entities begin accruing from calendar/location.
- **Depends on:** 3.1.
- **Done when:** a real day produces a coherent stream of context Moments with no network
  egress (verified).

### Session 3.3 — The habit-engine bridge
- **Goal:** Consume the habit vertical's `LogEntry`/streak data as **high-confidence**
  Moments and priors — the two verticals meet; habits are never re-asked.
- **Deliverables:** A read-only bridge from the habit store to life Moments (respecting the
  shared App Group), tagged as certain facts.
- **Depends on:** 3.1; the habit store.
- **Done when:** habit logs surface as Moments and are marked high-confidence in the
  uncertainty primitive.

### Session 3.4 — The ingestion scheduler & the consent ledger
- **Goal:** Background, on-device ingestion under the concurrency rules, plus a durable
  **consent ledger** (what the user allowed, revocable per source).
- **Deliverables:** A structured-concurrency ingestion coordinator (no `DispatchQueue`),
  a consent record per source, and a hard assertion of on-device-only processing.
- **Depends on:** 3.1–3.3.
- **Done when:** ingestion runs on background refresh within budget, and toggling a source
  off immediately stops its ingestion.

---

## Phase 4 — Reconstruction

**Intent.** Turn raw Moments into the **auto-built episodic day** (the DRM pre-fill) — the
legible day the user will later nudge, not author.

**Serves:** `PersonalLifeModel.md` §2.2 (DRM); the Reconstruction Ribbon precursor.

### Session 4.1 — Episode segmentation
- **Goal:** Segment a day's Moments into episodes at real seams (location/motion/calendar
  transitions), off the main actor.
- **Deliverables:** A `nonisolated async` segmentation function producing ordered episodes
  from a Moment snapshot (snapshot pattern, per principles §3.2, §5).
- **Depends on:** Phase 3.
- **Done when:** deterministic segmentation over the seeded store matches a recorded
  fixture; DST boundaries covered.

### Session 4.2 — Episode enrichment
- **Goal:** Infer each episode's activity type, environment, and social context by fusing
  its Moments.
- **Deliverables:** Enrichment producing estimates in the uncertainty primitive (soft where
  ambiguous).
- **Depends on:** 4.1.
- **Done when:** enriched episodes carry calibrated confidence and low-confidence episodes
  are visibly soft in fixtures.

### Session 4.3 — The reconstruction snapshot & budget
- **Goal:** A bounded, performant day reconstruction the interaction layer can consume.
- **Deliverables:** A snapshot API with a documented performance budget; no unbounded
  fetches (principles §5.2).
- **Depends on:** 4.1–4.2.
- **Done when:** reconstructing a day stays within budget on device and is covered by a
  perf test.

---

## Phase 5 — The Learning Engine

**Intent.** The core inference — States, Traits, and the honesty machinery — built
passive-first and calibrated. This is where "understands almost everything it reasonably
can" becomes real.

**Serves:** `PersonalLifeModel-LearningEngine.md` §4; the calibration resolution in the
manifesto.

### Session 5.1 — The self-supervised predictive core
- **Goal:** Predict the **passively-verifiable** (next bedtime, next-day activity) and
  score against what actually arrives — **free calibration**, and prediction error that
  localizes ignorance.
- **Deliverables:** A prediction+scoring loop over passive outcomes; the rule that the
  engine must *fail to predict* before anything is considered uncertain.
- **Depends on:** Phases 3–4.
- **Done when:** predictions are scored automatically and calibration on verifiable
  quantities is measurable and improving on the seeded history.

### Session 5.2 — State estimation via fusion
- **Goal:** Estimate fast States (energy, stress, focus, social load) by fusing weak
  signals into confident estimates — corroboration replacing questions.
- **Deliverables:** Fusion producing States in the uncertainty primitive; the worked
  "stress from HRV+calendar+sleep+movement" case as a test.
- **Depends on:** 5.1.
- **Done when:** fused State estimates beat any single-signal estimate on the seeded
  fixture and carry honest confidence.

### Session 5.3 — Trait estimation with hierarchical priors
- **Goal:** Slow Traits (chronotype, sensitivities) via population priors → personalization
  (warm start, shrinkage).
- **Deliverables:** Trait estimators seeded with shipped population priors, personalizing
  from this user's data; ADR on how priors ship without anyone's data leaving device.
- **Depends on:** 5.1.
- **Done when:** a thin-data user gets sensible prior-leaning Traits that shift correctly
  as personal evidence accrues.

### Session 5.4 — Calibration & honesty
- **Goal:** The epistemic/aleatoric split, **visible uncertainty**, value-of-information
  self-doubt on high-stakes beliefs, and **re-narration** (revising a belief when
  contradicted).
- **Deliverables:** Uncertainty tagging that routes correctly (never "ask" about aleatoric
  noise); a belief-revision path; the confidence-does-not-only-rise behavior.
- **Depends on:** 5.1–5.3.
- **Done when:** a contradicted belief widens rather than digs in, and aleatoric
  uncertainty is never surfaced as a resolvable question.

### Session 5.5 — Personalized calibration
- **Goal:** Personalize the signal→state lens so the *same* passive stream yields sharper
  understanding over time (understanding grows with zero questions).
- **Deliverables:** A per-user calibration that overrides the population mapping as
  evidence accrues.
- **Depends on:** 5.2–5.4.
- **Done when:** State accuracy on held-out seeded data improves with tenure at constant
  input.

---

## Phase 6 — Structure over Time

**Intent.** Make the model regime-aware: detect **Life Events**, bound **Chapters**, and
build the **relationship graph** honestly (within-regime, confounder-controlled).

**Serves:** `PersonalLifeModel-LifeEvents.md`; manifesto ontology (Events vs Chapters).

### Session 6.1 — Change-point detection
- **Goal:** Detect **coordinated, multi-stream, sustained** breaks as candidate Life
  Events; classify noise vs drift vs event.
- **Deliverables:** An on-device change-point detector over fused signals producing
  candidate events with confidence and an onset *window*.
- **Depends on:** Phase 5.
- **Done when:** the seeded event is detected with a correct onset window and ordinary
  wobble does not over-fire.

### Session 6.2 — Life Event characterization
- **Goal:** Characterize each event — onset shape, valence (incl. mixed), reversibility —
  and segment the timeline into regimes.
- **Deliverables:** Event enrichment + regime segmentation; temporary regimes (vacation/
  illness) that quarantine rather than overwrite the standing baseline.
- **Depends on:** 6.1.
- **Done when:** a temporary regime does not corrupt the standing baseline and a permanent
  one re-baselines forward.

### Session 6.3 — Chapters
- **Goal:** The intervals a Life Event opens — bounded, nameable, with regime-scoped
  baselines ("your normal, this chapter").
- **Deliverables:** Chapter entities linked to their opening events; baseline queries
  scoped by chapter.
- **Depends on:** 6.2.
- **Done when:** baselines answer per-chapter and chapters are navigable by meaning.

### Session 6.4 — The relationship graph
- **Goal:** Associations between States/People/Places/Traits computed **within regime** and
  checked for the event as a common cause; edges held as revisable hypotheses.
- **Deliverables:** A graph whose edges carry confidence and are re-examined across event
  boundaries.
- **Depends on:** 6.1–6.3.
- **Done when:** a cross-event confound (mood/exercise/sleep after a break) does not
  manufacture a false edge.

---

## Phase 7 — Direction

**Intent.** The first-person layer the old model lacked — what the user values, is moving
toward, and the forks where agency acts. Captured as a **gift**, never a survey.

**Serves:** manifesto (Direction entity); the agency reframe.

### Session 7.1 — Direction capture & representation
- **Goal:** The Direction entity — values, intentions, the felt "toward-what" — populated
  by the lightweight "where are you in your life" input, not interrogation.
- **Deliverables:** Direction `@Model` + a minimal, dismissible capture logic that treats
  answers with weight; forks/decisions represented as tagged Moments.
- **Depends on:** Phase 2.
- **Done when:** a named chapter/direction persists and links to the trajectory; skipping
  is fully supported.

### Session 7.2 — Direction ↔ trajectory linkage
- **Goal:** Connect Direction to the model so a fork can be met with *"here's what your
  history says"* — never *"here's what you should do."*
- **Deliverables:** The linkage that lets a decision surface relevant past without advice.
- **Depends on:** 7.1, Phase 6.
- **Done when:** a fork can be accompanied by evidence and the "no preacher" refusal is
  verifiably honored (no prescriptive output path exists).

---

## Phase 8 — The Perspective Interaction

**Intent.** Build the real interaction the Phase 1 prototype proved. This is the product
surface: no tabs, cards, dashboard, feed, chat, or charts.

**Serves:** `LOCA-Product-Experience.md` §2, §4, §5, §6, §9.

### Session 8.1 — The Present
- **Goal:** The vantage the user arrives at — alive-but-stable, at most one soft thread,
  exactly two moves (Reach / Ask).
- **Deliverables:** The Present surface, truthfully different each day, with no tiles.
- **Depends on:** Phases 4–6.
- **Done when:** it renders the real present, offers only Reach and Ask, and never shows a
  second panel.

### Session 8.2 — The Reach
- **Goal:** One continuous time-distance gesture where resolution is *felt granularity*,
  navigable by **meaning-landmarks** (events), not a date slider.
- **Deliverables:** The continuous Reach interaction from now → life, dissolving Moments →
  texture → Chapters.
- **Depends on:** 8.1; Phase 6 (landmarks).
- **Done when:** pulling back is continuous (no discrete day/week/month modes) and holds
  60fps.

### Session 8.3 — Ask → View
- **Goal:** Aiming a question composes a **View** (a scene you conclude from), never a
  verdict; uncertain parts render soft.
- **Deliverables:** The ask affordance + the View composer over the real model.
- **Depends on:** Phases 5–6.
- **Done when:** a real question yields a composed, soft-where-uncertain View and no
  sentence-verdict is ever produced.

### Session 8.4 — Threads & branching curiosity
- **Goal:** Soft elements in a View are pull-able; pulling composes the adjacent View. The
  current View is the only menu; nothing autoplays.
- **Deliverables:** Thread-following that walks question→question with no feed.
- **Depends on:** 8.3.
- **Done when:** a walk of ≥3 Views works and the app never pulls a thread for the user.

### Session 8.5 — Focus (learning as a gift)
- **Goal:** Sharpening a soft part = confirming/correcting = the calibration label. The
  focus gesture feeds Phase 5's engine.
- **Deliverables:** The focus interaction wired to belief updates; corrections propagate
  (credit assignment).
- **Depends on:** 8.3; Phase 5.
- **Done when:** focusing sharpens the View *and* measurably updates the model, and the
  user experiences it as clarifying, not surveying.

### Session 8.6 — The self-turning mode
- **Goal:** Rarely, at a genuine fork, the Present turns toward the user with a relevant
  View — the "second seat" — precise and infrequent.
- **Deliverables:** A conservative trigger for unbidden Views, rate-limited hard.
- **Depends on:** Phases 6–7.
- **Done when:** it fires only at real forks and never becomes a feed.

### Session 8.7 — The bendable View (frontier)
- **Goal:** If Gate A validated bending, ship counterfactual manipulation — grab a variable,
  bend it, watch the View respond.
- **Deliverables:** Manipulable variables on select Views with honest re-composition.
- **Depends on:** 8.3; Gate A (bend validated).
- **Done when:** bending is believable and clearly labeled as counterfactual (no false
  certainty). *(Deferrable to post-v1 if 1.3 was inconclusive.)*

---

## Phase 9 — Onboarding, Trust & the First 10 Minutes

**Intent.** The first-run experience and the surfaces that make an intimate model
trustworthy. This is where the refusals become visible product.

**Serves:** `LOCA-Product-Experience.md` §1, §7; manifesto trust section.

### Session 9.1 — The first 10 minutes
- **Goal:** The exact arc: quiet arrival → one human question → first View → minimal
  permissions (framed by what they unlock) → one true small thing → release. No streak,
  no nag, no checklist.
- **Deliverables:** The first-run flow, ending by letting the user go.
- **Depends on:** Phases 7, 8.
- **Done when:** a new user reaches "felt seen once, understood the promise, released"
  with no dopamine mechanics present.

### Session 9.2 — The empty state & the promise
- **Goal:** Honest day-one — reflect the present with clarity, name the chapter, and show
  the Reach filling over time. No faked depth.
- **Deliverables:** The zero-data Present and the visible "first mark" promise.
- **Depends on:** 8.1, 8.2, 9.1.
- **Done when:** day-one feels like an honest beginning, not a barren dashboard.

### Session 9.3 — Trust surfaces & duty of care
- **Goal:** Legibility ("why did you infer that?"), edit/delete the model, sensitive-event
  restraint (negative events default to silent re-baselining), **late-night care** (never
  surface anything heavy after dark), and a **crisis-restraint** policy (what the app does,
  and refuses to do, if it senses someone in danger).
- **Deliverables:** The inspection/correction/forget surfaces; the tact and care policies
  encoded as interaction rules.
- **Depends on:** Phases 5–8.
- **Done when:** every belief is inspectable and correctable, negative events never trigger
  cheerful prompts, and the crisis-restraint policy is documented and enforced.

---

## Phase 10 — Hardening

**Intent.** Make it shippable and durable for decades: fast, accessible, sync-safe,
private, and tested.

**Serves:** `ENGINEERING_PRINCIPLES.md` §5, §6, §8; the 20-year scalability concerns.

### Session 10.1 — Performance
- **Goal:** On-device inference and view composition within budget; the Reach at 60fps.
- **Deliverables:** Perf tests + Instruments traces for ingestion, reconstruction, State
  fusion, and Reach.
- **Done when:** every budgeted path passes and regressions fail CI.

### Session 10.2 — Accessibility
- **Goal:** The View and Reach are fully accessible — VoiceOver reads a View as a scene
  (not 300 tap targets), uncertainty is conveyed non-visually (not soft-blur alone),
  Dynamic Type and Reduce Motion honored.
- **Deliverables:** A11y passes for every new surface.
- **Done when:** uncertainty and composition are perceivable without sight and without
  color alone.

### Session 10.3 — Sync & the 20-year spine
- **Goal:** CloudKit sync for the life store, schema-migration discipline, and continuity/
  backup so the compounding asset survives device migrations and sensor churn.
- **Deliverables:** Migration tests against seeded stores; a documented resilience story
  for sources appearing/disappearing over years.
- **Done when:** a simulated migration and a dropped-sensor scenario both preserve the
  model coherently.

### Session 10.4 — Privacy & safety audit
- **Goal:** Verify the invariants: on-device only (no life data egress), the consent
  ledger, the no-second-master position, and the duty-of-care restraint.
- **Deliverables:** An egress audit, a consent-revocation test, and a safety review.
- **Done when:** zero life-data network egress is proven and revocation is immediate and
  complete.

### Session 10.5 — Test coverage & fixtures
- **Goal:** Meet the coverage floor (engine/analytics to the principles' bar), with
  deterministic seeded fixtures as the source of truth and explicit calibration tests.
- **Deliverables:** The test suite, calibration reliability tests, and CI gates.
- **Done when:** coverage floors pass in CI and calibration is asserted, not assumed.

> ### 🚦 GO/NO-GO GATE B (pre-ship)
> Ship only if: the View still reads as *seeing* with real personal data (not just seeded);
> calibration is honest; on-device egress is zero; and none of the three refusals is
> violated anywhere in the surface. Any failure blocks release.

---

## Cross-cutting gates (apply to every session)

- **Concurrency:** structured concurrency only; `ModelContext` never crosses actors;
  value-type snapshots for off-main work (principles §3).
- **Errors:** every `save()` in `do/catch + rollback`; typed `LifeError: LocalizedError`;
  no `fatalError` in production; `Logger` only, correct subsystem/category (§4).
- **Performance:** no unbounded `@Query`; bounded date ranges; budgeted hot paths carry a
  perf test (§5).
- **Accessibility:** labels/hints, ≥44pt targets, no state by color alone, Reduce-Motion
  guards on every animation, Dynamic Type (§6).
- **Privacy/refusals:** on-device only; no prescriptive/preacher output path; no
  engagement dark patterns; every belief inspectable (manifesto refusals).
- **Testing:** deterministic seeded fixtures; no mocks beyond in-memory `ModelContainer`;
  DST dates where calendars are involved (§8).

---

## Explicitly out of scope for v1

To keep the plan honest about what it is *not* doing yet:

- The bendable View (8.7) is **frontier**, deferrable to post-v1 if Gate A was inconclusive
  on bending.
- Opt-in micro-randomized causal tests (JITAI experiments) — post-v1; v1 uses only
  observational within-regime contrasts.
- Cross-user/population learning beyond shipped static priors — never, unless it can be done
  without any life data leaving the device.
- A conversational surface of any kind — permanently out of scope (a refusal, not a
  backlog item).

---

## The one dependency that dominates everything

Phase 1 and Gate A. If the View is not a genuinely new way to see one's life, no later
phase matters — they would be building a very good engine behind a chart. Spend Phase 1
cheaply, judge it ruthlessly, and let its verdict govern whether the other nine phases are
worth their thousands of hours.
