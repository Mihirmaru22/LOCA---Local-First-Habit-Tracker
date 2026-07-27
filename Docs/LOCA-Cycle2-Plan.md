# LOCA — Cycle 2: Phased Plan

*Cycle 1 (Phases 1–10) built the faculties. Cycle 2 builds the judgment: knowing which
faculty is competent for which claim, and what to do when none is. This plan does not
re-open the frozen vision, the ontology, or Phases 1–10. It is numbered **C1–C6** so
nothing in the frozen plan is renumbered.*

*Governed by `LOCA-Founding-Manifesto.md` (purpose, refusals, ontology),
`LOCA-Product-Experience.md` (the interaction), `THE-CENTRAL-QUESTION.md` (the test),
and `ENGINEERING_PRINCIPLES.md`. Sequencing conventions follow
`LOCA-Life-Implementation-Plan.md`.*

---

## What Cycle 2 is

**Cycle 2 is the epistemics layer: where LOCA stops having beliefs and starts having
justified beliefs.**

Every symptom the cycle addresses — infer vs. ask, when to stay silent, cold start,
missing data, low confidence, which source wins — is not six capabilities. It is one
capability with six symptoms: **a calibrated, first-person representation of the
system's own ignorance, and a policy that reads it.**

### The structural finding this plan is built on

The coordination Cycle 2 needs cannot be added on top, because the information required
to coordinate is **destroyed at the bottom**. Each inference model privately handles its
own ignorance and privately annihilates it (`MoodInferenceModel.swift:90` —
`guard !moodSignals.isEmpty else { return 0.5 }`; same shape at `FocusInferenceModel:87`,
`StressInferenceModel:125`, and throughout). By the time `ViewCompositionEngine` sees a
value, the fact that it was a fallback midpoint from zero evidence is gone. No
coordinator can recover it.

So this plan has **no orchestrator session.** The fix is at the bottom: stop destroying
ignorance, and the routing falls out of the accounting nearly for free.

### The three findings that set the order

1. **`UncertaintyType` is declared and never used.** `UncertaintyModels.swift:14` defines
   `epistemic` / `aleatoric`. Zero references exist outside that file. The distinction
   `PersonalLifeModel-LearningEngine.md` §3.1 calls "the most important distinction in P2"
   is vocabulary, not mechanism.
2. **User input is a write-only sink.** `AskView.saveCalibration` writes a `Calibration`;
   nothing reads one. `Calibration.isProcessed` is never set true and never queried.
   `FeedbackProcessor` adjusts only *display* confidence. `CalibrationManager` grades
   inferred states against `SignalEvent(source: .explicitLog)` — passive against passive.
   **The Focus gesture terminates in storage.**
3. **Cold start no-ops in silence.** `CalibrationManager` returns early on `logs.isEmpty`;
   `TraitInferenceEngine` on `< 14` samples. Nothing records that it declined.

### The one interpretation that changes

**"Passive-first, always" is a precedence rule that the implementation plan read as a
chronology rule.** Precedence: when a fact is available both ways, prefer inference.
Chronology: build all sensing before any asking. The manifesto asserts only the first —
*"learns most of the truth for free, and asks for the rest as a gift"* — and never says
*ask later*.

Read as chronology it produces a system that spends its first month guessing in silence:
the worst period to be guessing (no priors) and the worst to be silent (nothing else to
offer). The arc to near-silence in `PersonalLifeModel-LearningEngine.md` §7 is correct —
**but it has to start loud.** This is an interpretation correction, not a vision change.

### Sequencing rules for this cycle

1. **Repair the substrate before building on it.** C1 removes fabricated values. Every
   later phase is unsound until it lands.
2. **Close the loop before opening the valve.** C4 (user input reaches belief) precedes
   C5 (ask more). Asking harder into a sink is a regression, not a feature.
3. **Nothing new is coordinated.** No session in this cycle creates a coordinator,
   orchestrator, router, or policy engine as a component. Each session either removes a
   fabrication or connects two things that already exist.
4. **The refusals remain gates.** Cycle 2 touches the surfaces where "never a preacher"
   and "never a black box" are easiest to violate. Each phase names how it honors them.
5. **Silence is a deliverable.** A session that makes LOCA say less, more honestly, has
   shipped something.

---

## Phase map

| Phase | Theme | Sessions | Output |
|---|---|---|---|
| **C1** | Honest Ignorance (the substrate) | C1.1–C1.4 | No fabricated value anywhere; unknown is representable end-to-end |
| **C2** | Authority (who settles what) | C2.1–C2.4 | Per-claim authority; unfillable slots stay unfilled |
| **C3** | The Instrument's Shape | C3.1–C3.4 | Denied ≠ absent ≠ empty; the model fits this person's actual faculties |
| **C4** | The Return Path | C4.1–C4.4 | User input reaches belief; the Focus gesture is real |
| **C5** | The Asking Policy | C5.1–C5.5 | When to ask, when to refuse, cold-start-loud → arc to quiet |
| **C6** | Verification | C6.1–C6.5 | The arc proven, not assumed; the face test re-run |

---

## Phase C1 — Honest Ignorance

**Intent.** Stop the destruction of ignorance at the point of inference. Until a value can
say *I don't know*, every downstream honesty mechanism is decoration.

**Serves:** manifesto refusal 3 (never a black box); `LearningEngine` §3.1; frozen plan
2.3 ("no inferred property is stored bare").

**Honors the refusals:** this phase is the refusal — an instrument that blurs when it is
blurry, instead of one that emits `0.5` and lets the UI soften a fabrication.

### Session C1.1 — The unknown value
- **Goal:** Make "no evidence arrived" representable and structurally distinct from
  "measured, and it was neutral."
- **Deliverables:** An absence-carrying result for every inference path that currently
  substitutes a midpoint; the convention that an empty-evidence path never returns a
  number.
- **Depends on:** nothing.
- **Done when:** a state computed from zero signals is distinguishable — in storage and in
  every consumer — from a state genuinely measured at the midpoint, and no
  `guard …isEmpty else { return 0.5 }` remains on an empty-evidence path.

### Session C1.2 — Provenance on every inferred value
- **Goal:** Every inferred value carries what produced it: which sources contributed, how
  many samples, over what window.
- **Deliverables:** Provenance travelling with the value through fusion and composition,
  not recoverable only by re-fetching.
- **Depends on:** C1.1.
- **Done when:** any value reaching the view layer can name its own evidence without a
  second query, and a value with zero contributing sources says so.

### Session C1.3 — Route the epistemic/aleatoric split
- **Goal:** Make `UncertaintyType` load-bearing. The tag is assigned at inference time and
  read by real consumers, so the two kinds of doubt produce **opposite** behavior
  (§3.1: epistemic → wait/sense/possibly ask; aleatoric → accept, never ask).
- **Deliverables:** Assignment of the tag at every site producing uncertainty; at least one
  consumer whose behavior branches on it.
- **Depends on:** C1.2.
- **Done when:** the tag changes downstream behavior, and a grep for `.epistemic` /
  `.aleatoric` returns references outside `UncertaintyModels.swift` (today: zero).

### Session C1.4 — Ignorance survives composition
- **Goal:** `ViewCompositionEngine` and `MultiEntityComposer` receive and preserve
  unknown-ness rather than coercing it into a renderable number.
- **Deliverables:** Composition paths that carry absence through to the surface; a
  rendering contract for "this is unknown" that is not "this is soft."
- **Depends on:** C1.1–C1.3.
- **Done when:** an unknown reaches the Present still labeled unknown, and no composition
  path can silently supply a default on its behalf.

> ### 🚦 GATE C-A — No fabricated values
> An audit of every path from sensor to surface: **zero paths convert absence into a
> value.** If any remain, C2 onward is building on sand — the authority model cannot
> assign authority over a number nobody produced. This gate blocks C2.

---

## Phase C2 — Authority

**Intent.** Establish who is entitled to settle each claim. The correct object is
**per-claim authority, not per-source authority** — because user input is not globally
ground truth, and treating it so would let a tired 9pm self-report overwrite an accurate
HRV-derived estimate (`LearningEngine` §1.1, bias risk — not overturned by the manifesto).

**Serves:** manifesto (questions as gift; never a preacher); frozen plan 9.3
(sensitive-event restraint), promoted here from a display rule to a representation rule.

**Honors the refusals:** C2.4 is where "never a preacher" stops being a UI convention.

### Session C2.1 — The claim taxonomy
- **Goal:** Classify every claim the model holds into three kinds:
  **sensor-authoritative** (timing, duration, frequency, magnitude, co-presence, location —
  the world confirms these on its own, which is what makes them self-supervising);
  **subject-authoritative** (whether something mattered, what a chapter is called, whether
  a person is close or draining, what you are moving toward — the user's answer does not
  describe the fact, it constitutes it); **unfillable** (the valence of a life event, the
  meaning of a relationship, Direction).
- **Deliverables:** The classification itself as a reviewable artifact — a document, not a
  component. Every existing inferred and stored claim appears in exactly one category.
- **Depends on:** Gate C-A.
- **Done when:** the taxonomy is complete, reviewed against the ontology, and no claim in
  the codebase is unclassified.

### Session C2.2 — Sensor-authoritative claims stay sensor-settled
- **Goal:** User input may annotate a sensor-authoritative claim but never overwrite it;
  a conflict is recorded as a conflict, not resolved by recency.
- **Deliverables:** The precedence rule enforced at the write path; conflicts retained as
  evidence (a persistent disagreement between instrument and memory is *information*).
- **Depends on:** C2.1.
- **Done when:** a self-report cannot overwrite an instrumented fact, and a recorded
  conflict is inspectable rather than silently discarded.

### Session C2.3 — Subject-authoritative slots become unfilled, not guessed
- **Goal:** Chapter names, relationship meaning, and event significance carry no machine
  default. An unnamed chapter is unnamed — not "Chapter 3," not an inferred label.
- **Deliverables:** Removal of machine defaults from subject-authoritative slots; a
  rendering treatment for genuinely unfilled that reads as an invitation, not a failure.
- **Depends on:** C2.1.
- **Done when:** no subject-authoritative slot is ever populated without a user act, and
  the empty state reads as awaiting the user rather than as broken.

### Session C2.4 — Retract the unfillable guesses
- **Goal:** `EventClassifier` valence and `RelationshipGraphEngine` closeness stop emitting
  machine verdicts about meaning. **Low confidence is not the same as no authority** — the
  architecture currently has only a dimmer, and some claims need an off switch. A
  0.3-confidence guess that a bereavement was positively-valenced is not a more honest
  version of the same failure; it is the same failure, whispered.
- **Deliverables:** Removal of the machine-verdict path for unfillable claims; where a
  downstream consumer needed valence, it consumes absence or the user's own word.
- **Depends on:** C2.1; C1.4 (the surface can render absence).
- **Done when:** no event can receive a machine valence at any confidence, closeness is
  never asserted as a verdict, and the removal breaks no surface (because C1.4 taught them
  all to render unknown).

---

## Phase C3 — The Instrument's Shape

**Intent.** Know which faculties exist for this person, permanently. Three states currently
collapse into one missing dictionary key: *you denied calendar access*, *you don't use a
calendar*, *your calendar is empty this week*. The first is a permission conversation, the
third is real signal (a quiet week), and the second is a permanent structural fact that
should change the model's shape.

**Serves:** frozen plan 3.4 (consent ledger), 10.3 (sensor churn over years);
`Product-Experience` §7 (the honest empty state).

**Honors the refusals:** a system that permanently and silently models someone as
"incomplete" against a standard they can never meet is a black box about its own limits.

### Session C3.1 — Denied, absent, empty
- **Goal:** Three distinct, durable states per source, distinguishable everywhere
  downstream.
- **Deliverables:** The three-state representation at the source boundary; consumers that
  branch correctly on each.
- **Depends on:** C1.2 (provenance).
- **Done when:** a denied calendar, a never-used calendar, and a quiet week are three
  different facts in storage and produce three different behaviors.

### Session C3.2 — The persistent instrumentation account
- **Goal:** Replace the per-window completeness check (`SignalModels.swift:92` —
  `valuesBySource.count >= 4`, recomputed forever) with a durable account of which
  faculties this person actually has.
- **Deliverables:** A persistent per-user record of available faculties; completeness
  judged against *what is possible for this person*, not a fixed 4-of-7.
- **Depends on:** C3.1.
- **Done when:** a two-source person is modeled as fully instrumented *for a two-source
  person*, rather than permanently and silently incomplete with no path to discovering it.

### Session C3.3 — Reshape on permanent absence
- **Goal:** For a faculty that will never exist, stop weighting it, stop planning to ask
  about it, and stop rendering its gap.
- **Deliverables:** Model reshaping on permanent absence — not merely zero inputs, but a
  changed shape.
- **Depends on:** C3.2; C2.1 (so reshaping respects claim authority).
- **Done when:** permanently disabling a source changes what the model is, not just what it
  receives, and no surface displays a hole for a faculty this person will never have.

### Session C3.4 — Sensor churn across years
- **Goal:** A source appearing or disappearing mid-life does not corrupt history or
  retroactively invalidate prior beliefs.
- **Deliverables:** Provenance-aware handling of instrumentation changes over time; beliefs
  formed under a richer instrument remain legible when it is lost.
- **Depends on:** C3.1–C3.3; frozen plan 10.3.
- **Done when:** a simulated source loss and a simulated source gain both leave the model
  coherent, and values keep the provenance of the instrument that produced them.

---

## Phase C4 — The Return Path

**Intent.** User input reaches belief. Today the nerve is severed: the Focus gesture — the
manifesto's *"it listened"* moment — writes a `Calibration` that nothing reads. This phase
is not new capability. It is the repair of a connection the anatomy already assumes.

**Serves:** frozen plan 8.5 (Focus), 5.4 (re-narration); manifesto (*"an instrument that
adjusts to you rather than insisting"*); `Product-Experience` §8.

**Honors the refusals:** never a black box — a correction the user cannot see land is
indistinguishable from being ignored.

### Session C4.1 — Calibration reaches inference
- **Goal:** `Calibration` rows are consumed by the inference layer. `isProcessed` becomes a
  real lifecycle rather than a field nothing sets.
- **Deliverables:** The consumption path from stored calibration into belief update;
  reconciliation of the two parallel user-input representations that currently do not know
  about each other (`Calibration`, and `SignalEvent(source: .explicitLog)`).
- **Depends on:** C1.3 (a correction must know which kind of doubt it resolves);
  C2.1 (it must know whether it is entitled to settle the claim).
- **Done when:** a Focus correction measurably changes a subsequent inference, and no
  user-input row remains permanently unprocessed.

### Session C4.2 — Correction propagates
- **Goal:** One label updates the beliefs related to it, not only the value touched —
  credit assignment, so a rare answer is amortized across the model.
- **Deliverables:** Propagation from a single correction to the beliefs that depended on
  the corrected value, bounded and inspectable.
- **Depends on:** C4.1; `LearningEngine` §4.5.
- **Done when:** correcting one value demonstrably moves the beliefs downstream of it, and
  the propagation is bounded (no unbounded cascade).

### Session C4.3 — Contradiction widens, not digs in
- **Goal:** A correction contradicting a confident belief **increases** uncertainty rather
  than being averaged into the old estimate. Confidence must not only rise.
- **Deliverables:** The belief-revision path from frozen plan 5.4, now actually reachable
  because a contradiction can arrive.
- **Depends on:** C4.1, C4.2.
- **Done when:** a contradicted belief widens, and a belief corrected twice in the same
  direction re-narrates rather than oscillating.

### Session C4.4 — The correction is visible
- **Goal:** The user sees the instrument take it. Focus must *feel* like adjusting an
  instrument, not like filing a report.
- **Deliverables:** The felt response to a correction in the view that prompted it.
- **Depends on:** C4.1–C4.3.
- **Done when:** correcting something produces a visible change in the current view, in the
  same interaction — never a silent write followed by a later, unattributed difference.

> ### 🚦 GATE C-B — The loop is closed
> **No user input terminates in storage.** Every path from a user act reaches a belief and
> is visible to the person who made it. This gate blocks C5: opening the asking valve while
> the return path is severed collects more input into a sink, which makes finding #2 worse
> rather than better.

---

## Phase C5 — The Asking Policy

**Intent.** When to ask, when to refuse to ask, when to stay silent. Only now — with the
substrate honest (C1), authority assigned (C2), the instrument's shape known (C3), and the
loop closed (C4) — is the system entitled to ask more.

**Serves:** `LearningEngine` §6 (the four gates), §7 (the arc to near-silence);
`Product-Experience` §1, §3; manifesto (gift, not tax).

**Honors the refusals:** never a preacher (a question is not a nudge); never a second
master (question rate is never an engagement metric — §6.2 makes a *rising* rate a
regression).

### Session C5.1 — The four gates, enforced
- **Goal:** A question may issue only if all four hold: **reducible** (epistemic, not
  aleatoric), **passively unreachable** (the asset path is exhausted, not merely slower),
  **high value**, **time-sensitive**.
- **Deliverables:** The gates as an enforced precondition on every question path, with each
  rejection logged against the gate that failed.
- **Depends on:** Gate C-B; C1.3 (the epistemic tag is what gate 1 reads).
- **Done when:** no question can be issued without clearing all four, and the rejection log
  shows which gate stopped each one.

### Session C5.2 — The refusal cases
- **Goal:** Encode what the system must never ask: about aleatoric variance (asking cannot
  reduce randomness and only burns trust); about anything a sensor already settles;
  anything heavy after dark; anything at all near a bereavement or a sensitive event.
- **Deliverables:** The refusals enforced in policy — not in the UI, where they can be
  bypassed by a new surface.
- **Depends on:** C5.1; C2.1; frozen plan 9.3.
- **Done when:** each refusal is enforced below the presentation layer, and a new question
  surface inherits every refusal without re-implementing it.

### Session C5.3 — Cold start is loud
- **Goal:** Restore "passive-first" to its precedence reading. The first weeks ask the
  **most**, because that is when the asset path is thinnest and the system has the least
  else to offer. The rate then decays as the sensors learn to predict what they used to
  ask about.
- **Deliverables:** Asking volume as a function of accumulated evidence rather than a
  fixed policy; the early questions chosen to build the personal prior fastest.
- **Depends on:** C5.1, C5.2; C3.2 (what is possible for this person at all).
- **Done when:** week one asks materially more than month six on the same simulated life,
  and the early answers measurably accelerate the passive estimates.

### Session C5.4 — Asking as a gift, in form
- **Goal:** A question arrives as clarity the user wanted — attached to something they were
  already looking at — never as a survey, a queue, or a prompt out of nowhere.
- **Deliverables:** Questions surfaced only in the context that motivates them; skipping is
  always free, costs nothing, and is never immediately re-asked.
- **Depends on:** C5.1–C5.3; `Product-Experience` §1 (the single human question).
- **Done when:** no question appears outside a context that explains it, skipping leaves no
  residue, and no surface accumulates unanswered questions.

### Session C5.5 — The arc to quiet
- **Goal:** Question rate must **decay** on a stable life. A flat or rising rate is a
  learning-engine regression, treated as seriously as a performance-budget regression.
- **Deliverables:** Rate limits; the decay as an asserted property rather than a hoped-for
  emergent one.
- **Depends on:** C5.1–C5.4.
- **Done when:** the rate provably falls with tenure on a stable seeded life, and a
  legitimate spike occurs only against a genuine detected life change.

---

## Phase C6 — Verification

**Intent.** Prove the arc rather than assume it. Cycle 2's claims are all empirical and all
falsifiable; this phase falsifies them or does not.

**Serves:** `LearningEngine` §10; frozen plan 10.5; `THE-CENTRAL-QUESTION.md`.

### Session C6.1 — No fabricated values remain
- **Goal:** Re-run Gate C-A across everything built since, including surfaces added in
  C2–C5.
- **Done when:** zero paths convert absence into a value, asserted by a test that fails CI
  rather than by inspection.

### Session C6.2 — Calibration is honest
- **Goal:** Stated confidence matches observed accuracy on held-out seeded data — the
  reliability check the codebase currently cannot perform, because nothing grades beliefs
  against user-supplied truth.
- **Done when:** reliability is asserted, not assumed, and miscalibration fails CI.

### Session C6.3 — The question rate decays
- **Goal:** Measure C5.5's claim across simulated tenure on a stable life.
- **Done when:** the decay is a passing test, and a synthetic regression (a model made
  artificially worse) makes it fail.

### Session C6.4 — Cold start, in anger
- **Goal:** Day 1, day 3, week 2, month 2 on a real device with a real, thin life — not the
  seeded one. The seeder cannot test cold start, because it begins full.
- **Done when:** each checkpoint is honest — nothing fabricated, nothing pretending to
  depth, and day 3 is recognizably different from month 2 (`Product-Experience` §7).

### Session C6.5 — Re-run the face test
- **Goal:** `THE-CENTRAL-QUESTION.md`'s own instruction: open the app on real months of
  data, ask one real question, watch your own face. Cycle 2's wager is that honest
  ignorance is the **precondition** for the Present being "truthfully different every day"
  — a layer that manufactures the same neutral value whenever it is ignorant will be
  literally identical on exactly the days it has nothing, which early on is most days.
- **Done when:** a written verdict exists on whether the difference between *"huh, a
  chart"* and *"…oh"* moved — and, if it did not, the honest statement that the remaining
  problem is the interaction grammar (Phases 7–8), not the epistemics.

> ### 🚦 GATE C-C — Cycle 2 exit
> Exit only if: no fabricated value survives anywhere; every user input reaches a belief
> and is visible; the question rate demonstrably decays; unfillable slots are still
> unfilled; and none of the three refusals is violated on any surface added in C1–C6.

---

## Cross-cutting gates

The frozen plan's cross-cutting gates apply unchanged (concurrency, errors, performance,
accessibility, privacy, testing). Three are added for this cycle:

- **No fabrication.** No path may convert absence into a value. This is the cycle's
  governing invariant and is checked every session, not at C6.
- **No new coordinator.** No session may introduce an orchestrator, router, or policy
  engine as a component. If a session appears to need one, the ignorance it wants to route
  is being destroyed somewhere below it — fix that instead.
- **Silence is shippable.** A session that makes LOCA say less, more honestly, has
  delivered. Reduced output is never treated as reduced scope.

---

## Explicitly out of scope for Cycle 2

- **New entities.** The ontology is frozen and sufficient. Cycle 2 adds no ninth kind of
  thing.
- **New inference models.** Cycle 2 makes existing inference honest; it does not make it
  more capable. Accuracy work is not this cycle.
- **The interaction grammar.** The Present, Reach, Ask→View, Threads, and Focus belong to
  Phases 7–8. Cycle 2 supplies the honest substrate they stand on and touches their
  surfaces only where a correction must become visible (C4.4) or an unknown must render
  (C1.4).
- **Any conversational surface.** Permanently out of scope — a refusal, not a backlog item.
  C5's questions are aimed, answered, and gone; they are never a thread.

---

## The one dependency that dominates this cycle

**Gate C-B.** If user input still terminates in storage, every later session makes the
product worse: C5 asks more into a sink, and each unanswered-into-nothing question spends
trust the manifesto says a question is supposed to *earn*. Close the loop before opening
the valve, or do not run C5 at all.
