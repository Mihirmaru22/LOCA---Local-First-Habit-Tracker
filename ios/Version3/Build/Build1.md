# LOCA Version 3 · Build Phase
## Build1 — The Engineering Blueprint & Engineering Constitution

> **The single question Build1 answers:** *How should LOCA actually be engineered?* — the complete engineering architecture, decided before a single line of production code.
>
> **This is not implementation.** It contains **no Swift, no code, no file creation, no class definitions, no database schema, no API implementation.** It is engineering *architecture* — the decisions a new engineer needs to understand how Version 3 is built *before opening Xcode.*
>
> **Authority:** every engineering decision traces to Research (R1–R10), Synthesis (S1–S7), and Design (Design1–Design10). **If an engineering shortcut violates Design, Design wins.** Where Design conflicts with the Constitution (it shouldn't), the Constitution (S7) wins. Build1 must also honor Design10's Must‑Change items (MC1–MC4) and strong recommendations (SR1–SR4).
>
> **Platform reality (architecture‑level, not implementation):** LOCA is a **local‑first, on‑device** application on Apple platforms; the existing V2 codebase already contains real assets this architecture reuses and re‑architects around — an event‑log of facts, a provenance ledger, and a consent ledger — while correcting the V2 defects (missing‑as‑low, non‑renormalized inference, verdict/trait claims) that Design forbids.

---

## Part I — Architecture Philosophy

The engineering shape is the direct realization of Design3 (information) and Design9 (system):

1. **The Record is the single source of truth.** Facts — the person's logs, words, check‑ins, corrections, confirmed events, and consented sensed context — live in one **append‑only, immutable fact store** with provenance. Nothing else is authoritative. *(Design3; P6.)*
2. **Everything else is a derived, recomputable view.** Observations, patterns, reviews, timelines, beliefs — all are *functions of the Record*, recomputed idempotently, never independently stored as a second truth. *(Design3; Design9.)*
3. **Data flows in one direction.** Facts flow *up* (ingestion → Record → derivation → presentation); corrections flow in as *new facts*, never as mutations of old ones; **nothing derived ever writes back into the Record.** This is an engineering invariant, not a guideline. *(Design3; Build Constitution rule.)*
4. **Local‑first, on‑device by default.** The self‑data never leaves the device without the specified explicit consent; the app is fully functional offline. *(S6; R8; Design10 RJ5.)*
5. **Strict domain boundaries, acyclic dependencies.** Domains depend on the Record and on abstractions — never on each other. No circular ownership. *(Design9.)*
6. **Determinism first; intelligence only where it earns it.** Prefer deterministic computation; use inference only where the value requires it, always behind the reasoning constitution (S4). *(Design4; Design10.)*

**The one‑sentence architecture:** *an immutable fact store at the center, surrounded by consented producers that write facts and honest consumers that derive recomputable, provenance‑bearing, confidence‑gated views — with data flowing one way and the self‑data staying on the device.*

---

## Part II — Overall Application Architecture (the layers)

A layered (clean) architecture with unidirectional flow. Four primary layers + three cross‑cutting concerns:

**Primary layers (facts flow upward):**
1. **Ingestion Layer** — producers that capture facts (habits, reflections, check‑ins, sensed signals). Responsibility: validate, consent‑gate, provenance‑tag, and write facts to the Record. Never derives, never interprets.
2. **Record Layer** — the immutable, append‑only fact store (the source of truth) + provenance + consent state + corrections. Responsibility: hold the truth faithfully and permanently; serve reads; accept appends and corrections (as new facts). Never derives, never mutates a prior fact.
3. **Derivation / Intelligence Layer** — consumers that compute knowledge *from* the Record: inference (state/patterns), landmarks, reviews, the belief model. Responsibility: derive hedged, provenance‑bearing, confidence‑gated views, idempotently and recomputably; enforce the reasoning constitution (S4). Never writes to the Record; never asserts above the ceiling.
4. **Presentation / Experience Layer** — surfaces that render facts + derivations under the content, attention, and visual constitutions (Design5–8). Responsibility: display honestly (confidence/provenance visible), enforce attention rules, capture user actions (which become ingestion). Never computes truth; never overstates.

**Cross‑cutting concerns (threaded through all layers):**
- **Trust / Provenance** — lineage and confidence travel with every derivation from Record to surface; a derivation without lineage is malformed. *(Design3/6/7.)*
- **Consent / Privacy** — gates all ingestion and any off‑device operation; per‑source, revocable. *(S6; R8.)*
- **Attention** — governs what the Presentation layer may surface and when (the silence‑by‑default and one‑weekly‑beat laws). *(Design8.)*

**The flow:** user action → Ingestion → Record → Derivation → Attention filter → Presentation → user action. Corrections re‑enter at Ingestion as new facts. No arrow points backward into the Record.

---

## Part III — The Domain Model

Core domains, each with responsibilities · inputs · outputs · dependencies · owns · must‑never‑own. Domains communicate only through the Record and shared abstractions (never directly).

- **Record** — *Owns truth.* Responsibilities: append‑only fact storage, provenance, corrections, retrieval. Inputs: validated facts from Ingestion. Outputs: facts to any consumer. Depends on: nothing (the base). Must never own: derived knowledge, interpretation, presentation.
- **Habits** — *Owns habit definitions & logs.* Inputs: user logs. Outputs: habit facts to the Record; deterministic consistency/history. Depends on: Record. Must never own: inferred state, traits, verdicts.
- **Reflection** — *Owns the reflective loop.* Inputs: seed material (from Record) + the person's words. Outputs: reflection facts (the person's meaning) to the Record; the daily prompt. Depends on: Record + (seed) Derivation. Must never own: interpretation of the person's meaning (it belongs to the person).
- **Ingestion / Signals** — *Owns capture & validation.* Inputs: user actions + consented sensors. Outputs: validated, provenance‑tagged, consent‑gated facts. Depends on: Consent, Record. Must never own: the truth itself (it writes to the Record) or interpretation.
- **Intelligence / Derivation** — *Owns derived knowledge.* Inputs: the Record. Outputs: hedged observations, patterns, landmarks, the belief model, review content — all recomputable, lineage‑bearing, confidence‑gated. Depends on: Record (read‑only). Must never own: the Record/facts; never assert causation, traits, verdicts, or predictions (the ceiling).
- **Timeline / Memory** — *Owns the record's temporal view + confirmed landmarks.* Inputs: Record + user confirmations. Outputs: the timeline, landmarks. Depends on: Record. Must never own: fabricated narrative.
- **Reviews** — *Owns review artifacts.* Inputs: a period's Record + derivations. Outputs: the weekly/monthly review artifact. Depends on: Record, Derivation. Must never own: scores/grades/judgments.
- **Direction** — *Owns the person's stated aims.* Inputs: user authoring. Outputs: direction facts; framing context. Depends on: Record. Must never own: prescription/advice.
- **Relationships / People** *(deferred/minimal per MC4)* — *Owns the people view.* Inputs: consented signals + confirmations. Outputs: provenance‑labeled people. Depends on: Consent, Record, Derivation. Must never own: a CRM, an asserted relationship nature.
- **Ask** — *Owns self‑inquiry.* Inputs: the question + Record + derivations. Outputs: a grounded, hedged, abstention‑ready answer. Depends on: Record, Derivation. Must never own: answers beyond evidence, conversation‑as‑default.
- **Search** — *Owns retrieval.* Inputs: a query + Record. Outputs: matching facts. Depends on: Record. Must never own: inference from a query.
- **Attention / Notifications** — *Owns surfacing decisions.* Inputs: candidate derivations + the person's tuning. Outputs: what/when to surface (one weekly beat). Depends on: Derivation, Consent, user tuning. Must never own: engagement optimization.
- **Trust / Consent / Provenance** — *Owns consent state, provenance, and the inspectable belief model.* Inputs: user grants/corrections. Outputs: gates, lineage, the "what LOCA believes" view. Depends on: Record. Must never own: hidden state (nothing about the person may be hidden).
- **Settings** — *Owns app preferences.* Minimal; depends on nothing structural.

---

## Part IV — System Boundaries & Ownership

Strict, acyclic ownership — one owner per concern, no circular ownership:

| Concern | Owner | Rule |
|---|---|---|
| **Truth (facts)** | Record | the only authoritative store; immutable; append‑only |
| **Derived knowledge** | Intelligence/Derivation | never authoritative; always recomputable from the Record |
| **AI observations** | Intelligence/Derivation | hedged, lineage‑bearing; never written to the Record |
| **Memories** | Record (via Timeline view) | permanent facts; Timeline is a view, not a second store |
| **Signals** | Ingestion → Record | validated + provenance‑tagged before entering the Record |
| **User data** | the person (Record is steward) | inspectable, correctable, exportable, deletable |
| **Settings** | Settings | isolated |
| **Reviews** | Reviews | artifacts referencing the Record; never a second copy of facts |
| **Search index** | Search | a derived, rebuildable index over the Record; never a source of truth |
| **Consent** | Trust/Consent | gates all ingestion + off‑device ops |
| **Provenance / belief model** | Trust/Provenance | lineage + the inspectable model |

**Ownership laws:** (1) one owner per concern; (2) the Record owns truth and nothing else owns truth; (3) Derivation owns knowledge and never owns truth; (4) domains depend on the Record and abstractions, never on each other — **the dependency graph is a tree rooted at the Record, never a cycle**; (5) every owner exposes an interface, so it is replaceable (dependency inversion).

---

## Part V — The Data Pipeline (information lifecycle)

Every stage, its single responsibility, and the invariant:

```
1. USER ACTION            capture intent (log, reflect, check-in, correct, confirm)
        ↓
2. VALIDATION             well-formed? within bounds? — reject malformed input honestly
        ↓
3. CONSENT + PROVENANCE   gate by consent; tag source, quality, timestamp
        ↓
4. RECORD (append)        write an immutable fact — the point of no backward flow
        ↓
5. SIGNAL GENERATION      (for sensed/bridged facts) normalize into comparable signals
        ↓
6. DERIVATION / INFERENCE recompute views from the Record — evidence-gated, renormalized,
                          missing = unknown (NOT low), calibrated, hedged, lineage-attached
        ↓
7. KNOWLEDGE              hedged observations/patterns/landmarks/beliefs with confidence
        ↓
8. ATTENTION FILTER       decide what (if anything) is worth surfacing, and when
        ↓
9. PRESENTATION           render honestly — confidence/provenance visible; calm; contract-bound
        ↓
10. USER FEEDBACK          reflection, correction, confirmation, dismissal
        ↓
11. LEARNING               a correction re-enters at stage 1 as a NEW fact (highest authority)
        ↓
12. RE-EVALUATION          idempotent recompute of affected derivations (stage 6)
```

**Pipeline invariants:** (a) stage 4 is a one‑way gate — after a fact enters the Record, no later stage may alter it; (b) stage 6 must renormalize over present evidence and treat missing as unknown (the F1/F2/F6 fixes are engineering requirements here); (c) stage 6 never crosses the ceiling; (d) every artifact from stage 7 carries its lineage back to stage 4; (e) stages 6/12 are idempotent — recomputing yields the same result, no duplication (a V2‑verified property to preserve). *(Design3; S4; R8.)*

---

## Part VI — AI Integration Strategy

Intelligence is used deliberately, behind an abstraction, and never with the self‑data leaving the device.

- **Deterministic (no AI):** the Record, all facts, corrections, consent, provenance; habit math (streaks, consistency, totals); rollups; search/retrieval; the confidence/evidence gating logic. *Most of LOCA is deterministic.* *(Design4; Design10.)*
- **Requires inference (bounded, calibrated computation — on‑device):** state/pattern derivation, landmark/chapter detection, the belief model. This is *statistical/probabilistic inference*, not necessarily an LLM — implemented as a calibrated, renormalizing, abstention‑capable computation behind the reasoning constitution (S4). *(S4; R4; Design10 MC3.)*
- **The reflection‑prompt engine (the value crux, MC3):** V3 seeds prompts *deterministically from the real Record* (a grounded moment + a reflective frame). Any future generative enhancement (NH1) must be **on‑device and grounded** (RAG‑style over the record), behind the same S4 contract; V3 does not require it and never sends the self‑data to a cloud model.
- **Never uses AI:** the Record and facts; corrections; consent; provenance; anything above the ceiling (causation, traits, verdicts, prediction, diagnosis).
- **When AI/inference runs:** on the existing organic cycle (post‑action refresh + a background cadence), idempotently, on‑device, opportunistically (respecting battery). **When it never runs:** it never fabricates to fill a gap; below evidence threshold it abstains rather than computes a claim.
- **Offline vs cloud:** everything the person needs works **offline**; **no cloud processing of the self‑data** in V3 (RJ5). Any future cloud/remote step is opt‑in, privacy‑preserving, and never for the self‑data by default.
- **Graceful degradation of AI:** if inference fails or is unavailable, the app degrades to the **facts + Record + reflection loop** (Design9) — still valuable; derivations simply abstain. **AI is replaceable:** because it sits behind the S4 abstraction, any model/algorithm can be swapped without touching the Record or the surfaces. *(Design9; Design10.)*

**The AI law:** intelligence is an *interchangeable, on‑device, honesty‑bound computation over the Record* — the interface to it is the reasoning constitution (evidence‑bounded, calibrated, provenance‑preserving, abstaining), so the model may change but the honesty contract may not.

---

## Part VII — Engineering Principles (immutable)

Each derived and justified:

1. **Single source of truth; the Record is immutable.** One authoritative store; facts never mutate. *(Design3; P6.)*
2. **Unidirectional data flow.** Facts up, corrections in as new facts, nothing backward. *(Design3.)*
3. **Single ownership; acyclic dependencies.** One owner per concern; the dependency graph is a tree rooted at the Record. *(Design9.)*
4. **Determinism first; inference only when necessary.** Prefer deterministic computation; AI where the value requires it. *(Design4/10.)*
5. **Dependency inversion / replaceability.** Domains, models, and sensors sit behind interfaces and are swappable. *(Design9 extensibility.)*
6. **Explainability by construction.** Every derivation carries lineage + confidence; a derivation that can't be explained faithfully may not exist. *(Design3; S6.)*
7. **Provenance‑preserving.** Source/quality travel with every fact and every derived view. *(P4.)*
8. **Consent‑gated ingestion; on‑device by default.** Nothing enters without consent; the self‑data stays local. *(S6; R8.)*
9. **Missing is unknown, not low; renormalize over present evidence.** The F1/F2/F6 fixes are hard engineering rules. *(R8; S4.)*
10. **No hidden side effects; explicit data flow.** Every effect is traceable; no surface silently mutates state. *(testability.)*
11. **Idempotent recomputation.** Deriving twice yields once; no duplication. *(Design3; V2‑verified.)*
12. **Graceful degradation.** Every subsystem fails to a still‑valuable state (Part IX). *(Design9.)*
13. **Honesty invariants are non‑negotiable in code.** Confidence display, abstention, the ceiling, and correctability are enforced, not optional. *(S4/S6; Design10.)*

---

## Part VIII — Quality Standards (engineering requirements)

- **Performance:** surfaces respond to a glance instantly; derivation runs off the interaction path (background/idempotent). Calm implies *fast and unobtrusive.* *(Design5.)*
- **Memory:** bounded; the Record grows over years, so views are windowed/paged and derivations operate on relevant windows, not the whole history at once.
- **Battery:** efficient, duty‑cycled sensing; opportunistic derivation; a wellbeing app must not drain the device. *(R8; R3.)*
- **Accessibility:** full Dynamic Type, VoiceOver, contrast, Reduced Motion — a hard requirement, not a feature (the accessible design *is* the design). *(Design5; R5.)*
- **Reliability:** the Record and capture loop must never lose a fact; writes are durable; the app is robust to interruption.
- **Privacy:** the self‑data never leaves the device without explicit consent; no telemetry on the self‑data; the privacy promise is architecturally enforced. *(S6; R8.)*
- **Security:** the Record is protected at rest; deletion is real and complete (sovereignty). *(S6.)*
- **Offline capability:** the full core (capture, reflect, revisit, ask‑over‑local, review) works with no network. *(local‑first.)*
- **Data integrity:** immutability + provenance + idempotent derivation guarantee the record is never corrupted by the system; corrections are additive, never destructive. *(Design3.)*
- **Observability:** internal, privacy‑preserving monitoring of *honesty health* — calibration (do readings match check‑ins?), abstention rates, correction rates — so the team can verify the product stays honest, without surveilling the person. *(R4/R7 calibration.)*
- **Test coverage:** the derivation/reasoning layer and the honesty invariants (renormalization, missing=unknown, the ceiling, confidence gating, abstention, one‑way flow, idempotency) are the **most‑tested** parts of the system — because these are exactly where V2 failed. *(Design10; testability.)*

---

## Part IX — Failure Philosophy

Every failure degrades to a still‑valuable state; the Record + reflection loop are the floor.

| Failure | Engineering behavior |
|---|---|
| **Missing sensors** | derivations that depended on them lower confidence or abstain; everything else continues |
| **Missing permissions** | the dependent surface shows its honest, payoff‑named empty; no nagging; core unaffected *(R6)* |
| **Missing AI / inference** | degrade to facts + Record + reflection; derivations abstain; app stays useful *(Design9)* |
| **Missing internet** | normal operation — local‑first; nothing core requires the network |
| **Corrupted data** | the append‑only log + provenance aid detection/recovery; a corrupted derivation is recomputed from facts; a corrupted *fact* is surfaced honestly, never silently guessed |
| **Conflicting information** | lower confidence, record the conflict, the person's word wins; never silently pick a side *(S4)* |
| **Deleted history** | honored as sovereignty; the system operates on what remains, honestly; never resists deletion *(P5)* |
| **Large datasets (years of data)** | the Record scales append‑only; views are windowed/paged; derivations operate on relevant windows; performance stays calm |

**The failure law:** because every derivation depends only on the Record, a failure removes only what honestly derived from the lost input — never the Record, never the reflection loop. The engineering target is *containment*: no subsystem failure may cascade beyond the derivations that depended on it. *(Design9.)*

---

## Part X — Build Governance

No code enters the project unless it answers all of these; a single "no" blocks it:

1. **Which Design document requires this?** — no orphan code; everything traces to Design/S/R. *(S7.)*
2. **Which user problem does it solve?** — must map to an S3 root.
3. **Which subsystem owns it?** — one owner; fits the domain model (Part III).
4. **Can it be tested independently?** — if it can't be isolated and tested, its boundaries are wrong.
5. **Does it increase complexity?** — if so, is the complexity justified against Design5/10? Prefer the simpler realization.
6. **Does it violate modularity or the one‑way flow?** — if it couples domains or writes derived data into the Record, reject.
7. **Does it preserve user trust?** — confidence, provenance, abstention, correctability intact? If it withdraws trust, reject regardless of effort. *(S6; Design10 Build Constitution.)*

**The governance law:** implementation is the *faithful realization of a frozen, validated design* — never a place to add features, simplify away trust, or overclaim. New needs go back through the Design9 governance gate, not into the code.

---

## Part XI — The Engineering Constitution

The highest‑authority engineering document:

- **Architecture philosophy:** an immutable Record at the center; recomputable derivations around it; unidirectional flow; local‑first; strict acyclic domain boundaries; determinism first.
- **Engineering principles:** the thirteen of Part VII — immutable.
- **Domain ownership:** one owner per concern (Part IV); the Record owns truth and nothing else does; Derivation owns knowledge and never truth; a dependency tree rooted at the Record.
- **AI boundaries:** on‑device, honesty‑bound, replaceable, abstention‑capable; deterministic where possible; never above the ceiling; the self‑data never leaves the device without consent (Part VI).
- **Data boundaries:** facts are immutable and one‑way; derivations are provisional and recomputable; corrections are additive; missing is unknown; consent gates everything (Part V).
- **Testing philosophy:** the honesty invariants and the derivation layer are the most‑tested; every derivation is independently testable; the F1/F2/F6 fixes have explicit tests; determinism enables regression safety.
- **Reliability philosophy:** never lose a fact; degrade gracefully; contain failures to their dependent derivations; offline is normal.
- **Performance philosophy:** instant to the person, background for derivation; calm means fast and unobtrusive; windowed over years of data.
- **Security philosophy:** the Record protected at rest; deletion real and complete; no self‑data leakage; privacy enforced architecturally.
- **Maintainability philosophy:** replaceability via interfaces (models, sensors, surfaces swap without touching the Record); explicit data flow; single ownership; the Record + Constitution are the stable core, everything else is additive.

---

## The engineering blueprint, in one statement

> **LOCA Version 3 is engineered as an immutable, on‑device Record of a life at the center, surrounded by consented producers that validate and provenance‑tag every fact before it enters, and honest consumers that derive recomputable, lineage‑bearing, confidence‑gated views from it — with data flowing strictly one way, derivations that renormalize over present evidence and treat missing as unknown, intelligence that is deterministic where it can be and calibrated‑and‑abstaining where it can't, all behind replaceable interfaces so models and sensors can change but the honesty contract cannot, and every subsystem depending only on the Record so that any failure degrades to the still‑valuable floor of facts and reflection. It is built local‑first, tested hardest exactly where V2 failed, and governed by the rule that engineering is the faithful realization of a validated design — never a second design phase, never a place to add, simplify away trust, or overclaim.**

This engineering constitution is the highest‑authority engineering document; every Build phase (Build2–Build8) and every line of eventual code must obey it, and where any of them conflicts with Design or the Constitution, Design and the Constitution win.

---

*Build1 complete. The complete engineering architecture, domain model, module/system architecture, data pipeline, AI‑integration strategy, engineering principles, quality standards, failure philosophy, build governance, and Engineering Constitution are defined and derived entirely from Phase R, Phase S, and Design1–10. No Swift, code, files, class definitions, database schema, or API implementation were written. Stop here; do not begin Build2. Build1 is ready for review.*
