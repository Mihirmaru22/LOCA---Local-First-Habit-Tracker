# Build4 — Implementation Strategy

**Version 3 · Build Phase · Document 4 of 8**
**Status: Engineering Execution Manual (no production code)**

---

## Preamble — What Build4 Is

Research told us what is true about people and systems (R1–R10).
Synthesis told us what LOCA must be (S1–S7).
Design told us what LOCA looks and feels like (Design1–Design10).
Build1 froze the **engineering architecture** (layers, domain model, one-way flow).
Build2 froze the **runtime** (execution categories, event taxonomy, concurrency, the 14-rule Runtime Constitution).
Build3 froze the **subsystem contracts** (~23 subsystems, one owner each, the Decision Ownership Matrix: Derivation computes, Knowledge holds, Attention surfaces).

Everything an engineer needs to know about *what to build* has been decided.

Build4 answers a single, different question:

> **"Exactly how will engineers implement Version 3 while preserving the architecture?"**

This is not code. It is not APIs, schema, file layout, or framework guidance. It is the **discipline of execution** — how work is decomposed, sequenced, validated, integrated, reviewed, and governed so that the implementation that ships is faithful to the architecture that was frozen.

The governing fear of this document: *architecture is easy to draw and easy to betray.* A frozen design degrades one convenient shortcut at a time — a subsystem reaches past its boundary "just this once," a value gets invented at the presentation layer "to save a round-trip," a failure gets swallowed "because it's rare." Build4 exists to make those betrayals visible, costly, and rare.

**One sentence:** *Implementation is the act of executing against frozen contracts, not the act of making architectural decisions — and this document is how we keep it that way.*

---

## Part I — Implementation Philosophy

The principles every engineer internalizes before writing a line of Version 3 code. These are not aspirations; they are the lens through which every implementation choice is judged.

### IP1 — Contracts before features
No feature is implemented until the contracts it depends on (from Build3) exist and are honored. You build the pipe before you push water through it. A feature that "works" by violating a contract is not done — it is debt wearing a demo.

### IP2 — Preserve subsystem boundaries absolutely
Build3 assigns exactly one owner to every responsibility. Implementation may never blur an owner. If code in subsystem A needs something subsystem B owns, it asks B — it does not reach in, cache a copy, or re-derive B's answer. Boundaries are the load-bearing walls; convenience is not a permit to move them.

### IP3 — Determinism over hidden behavior
Given the same Record, the system produces the same derivations, the same knowledge, the same surfacing decisions. No wall-clock nondeterminism inside computation, no hidden global state, no "it depends on what ran first." If behavior varies, the variance must be an explicit, recorded input — never an accident of scheduling.

### IP4 — The Record is the only truth
Nothing is real until it is a fact in the Record. Derivations, knowledge, and surfaced messages are downstream projections that can always be rebuilt from the Record. Engineers never treat a cache, a view-model, or a UI state as authoritative. Corrections flow *in* as new facts; nothing flows backward to mutate history.

### IP5 — Missing is unknown, not low
The single most consequential correctness rule inherited from the V2 defects. Absence of evidence is never treated as evidence of a low value. Computation renormalizes over present evidence only. An engineer who writes a default-to-zero, a fill-forward, or a "assume baseline" is reintroducing F1/F6 and must be stopped in review.

### IP6 — Simplicity over cleverness
The simplest implementation that honors the contract wins. Cleverness that saves a few lines but obscures the one-way flow, hides a coupling, or makes determinism harder to verify is a net loss. Version 3's value is legibility; code that only its author understands betrays that.

### IP7 — Trust over convenience
When a choice trades user trust for engineering convenience — surfacing an unverified value, retaining data the user didn't consent to, making a claim the ceiling forbids — trust wins, every time, without debate. The Constitution (S7) outranks the sprint.

### IP8 — Correctness before optimization
No optimization is written before the correct, contract-honoring version exists and is verified. Optimizations must preserve observable behavior exactly (see IP-linked Quality Gate 4). A faster wrong answer is still wrong.

### IP9 — Every unit stays replaceable
Every subsystem is built so it could be swapped for a different implementation behind the same contract. This is especially true of the AI subsystem, which sits behind the S4 reasoning-constitution contract. If replacing a component requires touching its consumers, the boundary has leaked.

### IP10 — Failures are surfaced, never swallowed
Every failure path degrades explicitly and observably (Build2's graceful degradation to "facts + reflection floor"). Silent catches, empty error handlers, and "this should never happen" comments are prohibited. If it can happen, it has a defined, observable outcome.

### IP11 — Everything traces back
Every line of implementation must be traceable to a Design decision, which traces to Synthesis, which traces to Research. Code with no upstream justification is either undocumented scope creep or a misunderstanding — both are caught in review.

---

## Part II — Vertical Slice Strategy

Version 3 is implemented as **complete vertical slices**, never as horizontal layers built in isolation. A layer built alone (all of Derivation, then all of Knowledge, then all of Attention) hides integration failure until the end — the "big bang" this program is designed to avoid. A vertical slice proves the whole pipeline for one capability end to end.

### The canonical slice

Every capability travels the same path, and a slice is only "complete" when it travels the whole path:

```
User interaction
   ↓            (Presentation captures intent)
Fact creation
   ↓            (Ingestion forms a candidate fact)
Validation
   ↓            (fact is well-formed, provenance attached)
Record
   ↓            (append-only, immutable, the truth)
Events
   ↓            (Runtime emits the change event)
Derivation
   ↓            (computes signals/observations — renormalized, deterministic)
Knowledge
   ↓            (holds what is known, with confidence + provenance)
Attention
   ↓            (decides whether this is worth surfacing — usually not)
Presentation
   ↓            (renders honestly, within the ceiling)
Verification
                (the slice is proven at every stage)
```

### Where a slice begins and ends

- **Begins** at the earliest real user interaction or ingestion event that can produce the capability's defining fact.
- **Ends** at verification: automated proof that a fact entered at the top produces the correct, honest outcome at the bottom — including the correct outcome when evidence is *absent* (the value stays unknown, nothing is surfaced).

### What "complete" means for a slice

A slice is complete when **all** of the following hold:
1. The fact type is defined, validated, and provenance-bearing in the Record.
2. The event is emitted and consumed deterministically.
3. Derivation computes the correct value *and* correctly abstains when evidence is missing.
4. Knowledge holds the result with confidence and provenance intact (F8 fixed by construction).
5. Attention's default is silence; surfacing happens only when the contract's threshold is genuinely met.
6. Presentation renders within the ceiling (no verdict/trait/causation/prediction) and shows provenance on demand.
7. Verification exists for every stage, including the "unknown" and degraded paths.

### The rule

**No subsystem is left partially implemented for long.** A half-built subsystem is invisible debt: it looks present, passes casual demos, and collapses under the next slice. Slices are sized so that each one either completes a subsystem's role for that capability or is explicitly marked as a known, tracked stub with a failing-by-design test guarding it.

---

## Part III — Incremental Build Strategy

The safest order of implementation. Each stage produces a **working system** — degraded in capability, never broken in integrity — and no stage depends on architecture that a later stage has not yet frozen (nothing does; the architecture is already frozen — this is purely about build order).

### Stage 0 — Foundation
Determinism harness, event plumbing skeleton, the observability spine, and the validation scaffolding. Nothing user-facing. **Why first:** every later stage is validated *through* this; building it last would mean everything before it was unverified. Working system: an empty but observable, deterministic shell.

### Stage 1 — Record
The append-only, immutable, provenance-bearing fact store and its validation. **Why here:** IP4 makes the Record the only truth; nothing downstream can be trusted before the truth exists. Working system: facts can be created, validated, and read back; corrections append; history is immutable.

### Stage 2 — Runtime
Event taxonomy, the scheduler, recompute coalescing, concurrency discipline, and graceful degradation — all per Build2. **Why here:** derivations need deterministic, coalesced triggering before they can be trusted. Working system: facts entering the Record emit correct events that drive (still-empty) recompute deterministically.

### Stage 3 — Core domains
The honest, deterministic domains that need no inference: Habit, Reflection, basic Memory/Timeline, Direction. **Why here:** these deliver real user value on top of Record + Runtime alone, with no dependence on the intelligence layer. Working system: LOCA is already a useful, honest habit-and-reflection companion — the "facts + reflection floor" that Build2 names as the permanent fallback.

### Stage 4 — Intelligence
Signal, Derivation, Knowledge, and the AI subsystem behind the S4 contract. **Why here:** only now, atop a proven Record/Runtime/domain base, do we add computation — and it is built with F1/F5/F6/F8 fixed by construction (renormalize over present evidence, missing=unknown, provenance preserved). Working system: LOCA now understands, but every understanding is confidence-bearing, provenance-bearing, and abstains when evidence is thin.

### Stage 5 — Presentation & Attention
Attention (the surfacing decision) and Presentation (honest rendering within the ceiling), plus Ask and Search. **Why here:** surfacing is the *last* thing built, because quiet intelligence means the hard part is deciding **not** to speak — and that decision needs the full knowledge layer beneath it to be meaningful. Working system: LOCA now speaks, rarely, and only when it has earned attention.

### Stage 6 — Refinement
Performance work, long-history hardening, migration completion, and polish. **Why last:** IP8 — optimization only after correctness is proven across all prior stages. Working system: the same system, faster and hardened, with observably identical behavior.

**Invariant across all stages:** at the end of every stage the system is shippable in principle — never in a state where integrity is compromised, only in a state where capability is intentionally partial.

---

## Part IV — Integration Strategy

Subsystems are built isolated (Build3), but they must ultimately work together. Integration is treated as a **continuous discipline, never an event.**

### When integration happens
**Continuously, at the seam of every vertical slice.** Because slices are vertical (Part II), integration across subsystem boundaries is exercised the moment a slice is built — not deferred. There is no phase called "integration"; there is only the ongoing proof that the seams hold.

### How frequently
Every slice integrates. Every merge re-proves all existing integrations (regression, Part VI). The system is never allowed to sit in a state where two subsystems have diverged and no one has noticed.

### How integration failures are detected
- **Contract tests at every boundary** (Build3's communication contracts made executable): each producer/consumer pair is verified to agree on shape, meaning, and the "unknown" case.
- **One-way-flow assertions:** automated checks that no data flows backward (nothing mutates the Record from downstream; no derivation writes into ingestion).
- **Event-taxonomy conformance:** every emitted event matches Build2's taxonomy; consumers reject unknown events loudly.
- **Determinism replay:** the same event log replayed produces byte-identical downstream state.

### How interfaces evolve
Interfaces evolve **additively and versioned**. A contract may gain optional inputs or a new event type; it may never silently change the meaning of an existing field. Any breaking change to a Build3 contract is not an implementation decision — it triggers Build governance (Part XI) and, if it changes a boundary, a Build3 amendment.

### How compatibility is maintained
- Consumers tolerate absent-but-expected fields by treating them as **unknown**, never as defaults (IP5 again, at the integration layer).
- Producers never remove a field that a consumer depends on without a governed deprecation (Part VII).
- The Record's fact schema is append-only in spirit: old facts remain readable forever.

**The anti-goal, stated plainly:** there is never a "big bang integration." If integration is ever scary, the process has already failed — it means slices stopped being vertical.

---

## Part V — Validation During Development

Every implementation unit carries **required validation**. A unit is not "done" — it does not merge — until every validation dimension required for its subsystem passes. Validation is not a stage; it is a property of doneness.

| Dimension | What it proves | Applies to |
|---|---|---|
| **Architecture validation** | The unit respects subsystem ownership and one-way flow. | Every unit |
| **Runtime validation** | Events, coalescing, concurrency, and degradation behave per Build2. | Anything touching the pipeline |
| **Contract validation** | The unit honors its Build3 producer/consumer contracts, including the unknown case. | Every unit at a boundary |
| **Correctness validation** | The unit computes the right answer *and* correctly abstains when evidence is missing. | Derivation, Knowledge, domains |
| **Performance validation** | The unit meets its budget without changing behavior. | Refinement, hot paths |
| **Privacy validation** | No data leaves the device improperly; consent boundaries honored; provenance retained. | Every unit touching user data |
| **Accessibility validation** | Presentation units meet the Design5 interface constitution. | Presentation |
| **Trust validation** | Nothing violates the ceiling; nothing invents, oversells, or hides provenance. | Knowledge, Attention, Presentation |
| **Regression validation** | No previously-passing behavior changed unexpectedly. | Every unit |

**Rule:** the *required* subset is defined by the subsystem (a pure-domain unit may not need accessibility validation; a Presentation unit certainly does). But a unit is **incomplete** until its required subset is fully green. "It works, I'll add the checks later" is not an accepted state — it is precisely how frozen architecture erodes.

---

## Part VI — Testing Strategy

Build3 defined *what* must be tested (testing contracts). Build4 defines the *engineering expectations* for each testing discipline. **No frameworks are named** — only what each discipline must prove.

- **Unit testing.** Every subsystem's internal logic is proven in isolation, including its abstain/unknown behavior. Expectation: a unit's correctness does not depend on any other subsystem being present.
- **Integration testing.** Every Build3 boundary is proven at the seam — producer and consumer agree on shape, meaning, and the unknown case. Expectation: no boundary is trusted without a test that fails if either side drifts.
- **System testing.** The assembled pipeline behaves per Build1/Build2 for representative facts. Expectation: proves the whole flow, including degradation to the reflection floor.
- **End-to-end testing.** A real user interaction produces the correct, honest, ceiling-respecting outcome — including the outcome where LOCA correctly says nothing. Expectation: silence-when-appropriate is tested as rigorously as speech.
- **Property testing.** Invariants hold across generated inputs: one-way flow never reverses; missing evidence never becomes a low value; renormalization always sums correctly; determinism holds under replay. Expectation: the F1–F8 defect classes are guarded by properties, not just examples.
- **Performance testing.** Hot paths meet budgets; recompute coalescing prevents storms. Expectation: performance is measured, not assumed, and never traded against correctness.
- **Reliability testing.** Failure injection proves graceful degradation: every failure path lands in a defined, observable, floor-preserving state. Expectation: no injected failure produces a silent swallow or a corrupt Record.
- **Long-history testing.** The system is proven against large, long, realistic histories — the condition V2 was never tested under. Expectation: derivations, knowledge, and performance stay correct and bounded as history grows for years.
- **Privacy testing.** Consent boundaries, on-device guarantees, and provenance retention are proven. Expectation: a test fails if any data path would cross a boundary the user did not consent to.
- **AI validation.** The AI subsystem is validated behind the S4 reasoning-constitution contract: it never breaches the ceiling, never invents confidence, always carries provenance, and degrades to determinism when uncertain. Expectation: the AI is tested as a *replaceable component behind a contract*, not as a trusted oracle.
- **Regression testing.** Every fixed defect and every shipped behavior gains a guarding test. Expectation: the F1–F8 fixes can never silently regress.

---

## Part VII — Migration Strategy

Version 2 exists. Migration is governed by one principle above all: **migration preserves trust.** A migration that silently reinterprets a user's history, or carries forward a V2 defect as if it were truth, breaks the sovereignty the whole system is built on.

| Category | Decision | Rationale |
|---|---|---|
| **Migrated** | Raw user facts that were honestly recorded in V2 — habit logs, reflections, explicit user entries — re-ingested **as facts**, with provenance marking them as V2-origin. | These are the user's truth; they belong in the Record. |
| **Rebuilt** | All derivations, patterns, inferences, and "understanding." Nothing computed by V2 is trusted; everything is recomputed by V3's corrected engine from the migrated facts. | V2's derivations carry F1–F8. Recomputing from raw facts is the only way to guarantee correctness. |
| **Discarded** | Seeded/synthetic data (F7 — Sarah/Alex and any placeholder baselines, F6), and any V2 value whose provenance cannot be established. | Fabricated or unprovenanced data must never enter V3's Record. Trust forbids it. |
| **Deprecated** | V2 code paths that violate V3 contracts (invent-and-shout surfacing, mood-only patterns, non-renormalized weights). Removed on a governed schedule, not silently. | Old assumptions must be *removed*, not left dormant to leak back in. |
| **Untouched** | The user's underlying device data and anything V3 has no consented reason to read. | Least-privilege; migration reads only what it must. |

### How migration protects users
- **No silent reinterpretation.** If V3 would present a migrated history differently than V2 did, that difference is honest and, where it matters, visible — the user is never quietly told a new story about their past.
- **Provenance on everything migrated.** Every migrated fact is marked V2-origin so its lineage is never lost (F8 fixed even retroactively).
- **Recompute, never trust.** Understanding is rebuilt from facts, so no V2 defect survives migration.
- **Reversible in principle.** Migration reads V2 and writes V3's Record; it never destroys the V2 source as a precondition, so a failed migration cannot cost the user their history.

**How old assumptions are removed:** by construction. Because understanding is rebuilt rather than migrated, every V2 assumption baked into a derivation simply does not exist in V3 unless V3's own corrected engine reproduces it from facts.

---

## Part VIII — Documentation Strategy

Every implementation leaves documentation behind. Documentation **evolves alongside implementation** — it is part of "done," never a later chore. Version 3's core value is legibility; undocumented code is illegible by definition.

Standards for what every unit documents:
- **Architecture decisions.** Any choice that touches a boundary, a flow direction, or a contract — with its trace back to Build1–Build3.
- **Engineering decisions.** Non-obvious implementation choices and *why the simpler alternative was not taken* (guards IP6).
- **Public contracts.** Every producer/consumer contract a unit exposes, including the unknown/absent case.
- **Internal assumptions.** Every assumption the code relies on — especially any assumption about evidence presence, which is where F1/F6 hide.
- **Future extension points.** Where the design anticipates growth, and where it deliberately does not.
- **Failure modes.** Every failure path and its defined, observable, floor-preserving outcome (mirrors IP10).
- **Operational notes.** What to watch, what degradation looks like in observability, how to tell healthy silence from broken silence.

**Rule:** a contract change with no documentation change is an incomplete change. Documentation drift is treated as a defect, not a cosmetic gap.

---

## Part IX — Code Review Constitution

The rules **every pull request must satisfy** to merge. A reviewer's job is not taste — it is to defend the frozen architecture. Any single violation blocks the merge; there are no "minor" boundary violations.

**RC1 — Respects subsystem ownership.** The change touches only what its subsystem owns; it asks other subsystems rather than reaching in (IP2).

**RC2 — Does not violate one-way flow.** No data flows backward; nothing downstream mutates the Record or an upstream producer (IP4).

**RC3 — Does not bypass the Record.** No authoritative state lives outside the Record; caches and view-models are clearly non-authoritative and rebuildable (IP4).

**RC4 — Preserves determinism.** No new wall-clock dependence, hidden global state, or order-dependence inside computation (IP3).

**RC5 — Missing stays unknown.** No default-to-zero, fill-forward, or assumed-baseline; computation renormalizes over present evidence only (IP5). *This is the single most scrutinized rule in review.*

**RC6 — Maintains explainability.** Every surfaced value can trace to its facts with confidence and provenance intact (IP4, F8).

**RC7 — Preserves the ceiling.** No verdict, trait, causation, or prediction is introduced anywhere in Knowledge, Attention, or Presentation (S7).

**RC8 — Preserves privacy.** No new data path crosses a consent boundary or leaves the device improperly (IP7).

**RC9 — Preserves accessibility.** Presentation changes meet the Design5 interface constitution.

**RC10 — Avoids hidden coupling.** No new dependency that isn't declared in the subsystem's Build3 contract; nothing "just knows" about another subsystem's internals (IP9).

**RC11 — Adds appropriate validation.** The change ships with the required validation for its subsystem, including the unknown and degraded paths (Part V).

**RC12 — Improves (never degrades) readability.** Simplicity over cleverness; the reviewer can understand the change without the author present (IP6).

**RC13 — Surfaces, never swallows, failures.** No empty catch, no silent fallback, no "can't happen" (IP10).

**RC14 — Traces back.** The change references the Design/Build decision it implements (IP11).

---

## Part X — Engineering Quality Gates

Every feature passes these gates, in order, before merge. A gate is a **binary, defensible checkpoint** — not a vibe. Each exists to catch a specific class of architectural betrayal.

**Gate 1 — Architecture.** *Does the change respect boundaries and one-way flow?* Exists because boundary erosion is the primary way frozen architecture dies (RC1–RC3, RC10).

**Gate 2 — Runtime.** *Do events, coalescing, concurrency, and degradation behave per Build2?* Exists because pipeline misbehavior is invisible until it corrupts state under load (RC4).

**Gate 3 — Correctness.** *Right answer when evidence is present, honest abstention when it's absent?* Exists to permanently kill the F1/F5/F6 defect class (RC5, RC6).

**Gate 4 — Performance.** *Meets budget with observably identical behavior?* Exists because optimization is where correctness quietly dies (IP8).

**Gate 5 — Trust.** *Ceiling intact, provenance intact, nothing invented or oversold?* Exists because the invent-and-shout failure is what V3 is fundamentally built to prevent (RC6, RC7).

**Gate 6 — Accessibility.** *Meets the interface constitution?* Exists because a calm companion that excludes people is not calm — it's negligent (RC9).

**Gate 7 — Documentation.** *Contracts, assumptions, and failure modes documented?* Exists because undocumented code is illegible, and legibility is the product (Part VIII).

**Gate 8 — Observability.** *Can we see this behaving — including its silence and its degradation — in production?* Exists so that "healthy quiet" is distinguishable from "broken quiet" (IP10, Part VIII operational notes).

**Gate 9 — Regression.** *Does every prior behavior still hold, and is every fixed defect still guarded?* Exists so the F1–F8 fixes can never silently return (Part VI).

**Gate 10 — Release readiness.** *Is the vertical slice complete, the system still shippable in integrity, and the change traceable end to end?* Exists as the final integrity check before the change becomes part of the frozen base (Part II, IP11).

---

## Part XI — Build Governance

How engineering decisions are managed once implementation is underway. The architecture is frozen — but "frozen" needs a defined, disciplined thaw procedure, or it will be broken informally instead.

- **When may architecture change?** Only when implementation reveals that a frozen contract is *wrong* (not merely inconvenient) — an impossibility, a contradiction, or a correctness threat. Inconvenience is never grounds; that is what IP6 and slices are for.
- **Who approves it?** A change to a Build1–Build3 contract or boundary requires an explicit, documented governance decision — never a unilateral implementation choice buried in a PR. The change amends the relevant Build document first, then implementation follows.
- **How are exceptions documented?** Every deviation from a frozen contract is recorded as a governed exception with its rationale, its scope, and its expiry — an exception with no expiry is technical debt (below), not a decision.
- **How are implementation discoveries fed back?** Discoveries that clarify or refine (without breaking) a contract are documented back into the relevant Build/Design document in the same change that discovers them (Part VIII). Documentation and code move together.
- **When must Design be revisited?** When implementation reveals that a Design decision (Design1–Design10) rests on a false assumption about feasibility or user reality. This escalates *out* of Build back to Design — Build4 does not silently override Design.
- **How is technical debt tracked?** Every knowingly-incomplete slice, every governed exception, and every deferred optimization is tracked explicitly with the condition for its resolution. Debt is allowed; *hidden* debt is not.
- **How are engineering principles enforced?** Through the Code Review Constitution (Part IX) and Quality Gates (Part X), which are the mechanical enforcement of the philosophy (Part I). Principles that aren't enforced at a gate are wishes.

**The governing stance:** the architecture is not brittle-frozen (never touchable) nor soft-frozen (touchable on a whim). It is **governed-frozen** — changeable only through a visible, documented, accountable process that keeps every Build document true.

---

## Part XII — The Implementation Constitution

The highest engineering authority for Version 3. Where Part I is the philosophy an engineer holds and Parts IX–X are the mechanics that enforce it, the Implementation Constitution is the set of **absolutes** that govern every line of Version 3 code. It is subordinate only to the LOCA Constitution (S7); where they touch, S7 wins.

1. **Never violate a subsystem contract.** Boundaries are absolute; ask, never reach in.
2. **Never bypass validation.** A unit without its required validation is not done, regardless of demos.
3. **Never bypass the Record.** The Record is the only truth; everything else is a rebuildable projection.
4. **Never let missing become low.** Absence is unknown; renormalize over present evidence, always.
5. **Never breach the ceiling.** No verdict, trait, causation, or prediction — anywhere, ever.
6. **Never invent or oversell.** Every surfaced value carries its provenance and honest confidence, or it is not surfaced.
7. **Never optimize before correctness,** and never let an optimization change observable behavior.
8. **Never hide a failure.** Every failure degrades explicitly, observably, to the reflection floor.
9. **Never introduce hidden coupling.** Every dependency is declared in a contract or it does not exist.
10. **Never weaken trust for convenience.** When trust and convenience conflict, trust wins without debate.
11. **Every unit remains replaceable** behind its contract — most of all the AI.
12. **Every feature traces back** to Design, to Synthesis, to Research. Code without lineage does not ship.

This constitution governs every line of Version 3 code. An implementation that satisfies every framework, passes every demo, and ships on time but violates one article of this constitution has not built Version 3 — it has built the thing Version 3 was designed to replace.

---

## Closing — What Build4 Delivered

Build4 translated a frozen architecture into an **engineering execution manual**:

- an **implementation philosophy** (Part I) — the lens;
- a **vertical slice strategy** (Part II) — the unit of work;
- an **incremental build strategy** (Part III) — the order, each stage shippable in integrity;
- an **integration strategy** (Part IV) — continuous, never a big bang;
- a **validation strategy** (Part V) — validation as a property of "done";
- a **testing strategy** (Part VI) — expectations, no frameworks, F1–F8 guarded by properties;
- a **migration strategy** (Part VII) — recompute never trust, provenance on everything, trust preserved;
- a **documentation strategy** (Part VIII) — legibility as a deliverable;
- a **Code Review Constitution** (Part IX) — 14 rules that defend the architecture;
- **Engineering Quality Gates** (Part X) — 10 defensible checkpoints;
- **Build governance** (Part XI) — governed-frozen, with a disciplined thaw;
- the **Implementation Constitution** (Part XII) — 12 absolutes over every line.

It answers *"How do we build this correctly?"* — without a single line of production code, without an API, schema, file layout, or framework name.

Everything here is consistent with Research (R1–R10), Synthesis (S1–S7), Design (Design1–Design10), Build1, Build2, and Build3. Nothing was redesigned; no subsystem boundary moved.

**Stop here; do not begin Build5. Build4 is ready for review.**
