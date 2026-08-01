# LOCA Version 3 · Build Phase
## Build3 — Subsystem Engineering Specification Handbook

> **The single question Build3 answers:** *What exactly does every subsystem do, what does it own, and how does it interact with the rest of LOCA?*
>
> This is the **engineering contract engineers build against** — not implementation. It contains **no Swift, no APIs, no database schema, no class diagrams, no file structure, no code.** Build1 defined the architecture; Build2 defined the runtime; Build3 defines every subsystem's precise responsibilities, contracts, and boundaries. Everything is derived from Research (R1–R10), Synthesis (S1–S7), Design (Design1–Design10), Build1, and Build2, and redesigns nothing.
>
> **The governing discipline:** *one subsystem · one owner · one responsibility.* No overlap, no circular ownership, no decision emerging from two systems.

---

## Part I — Complete Subsystem Inventory

Derived from Build1's layers/domains and Build2's runtime. Grouped; one‑line responsibility each. **Merges from the example list are noted** (to honor one‑responsibility).

**Core (the spine):**
1. **Record Engine** — holds the immutable truth (facts + provenance).
2. **Ingestion Engine** — the write gate: validates, consent‑gates, provenance‑tags, appends facts.
3. **Signal Engine** — normalizes raw *sensed* samples into comparable signals *before* ingestion (sensors only).
4. **Derivation Engine** — orchestrates inference/recompute over the Record; enforces the reasoning constitution (evidence gating, renormalization, abstention, the ceiling).
5. **AI Engine** — the *replaceable* on‑device inference computation Derivation calls behind a stable contract.
6. **Knowledge Engine** — holds the live derived model (beliefs/observations/patterns) with confidence, lineage, decay, retirement.
7. **Attention Engine** — decides what/when is worth surfacing (silence‑by‑default; the one weekly beat).
8. **Presentation Engine** — composes read‑models for surfaces under the content/visual contracts; captures user actions. *(read‑model/composition layer, not views.)*
9. **Runtime/Scheduler Engine** — owns Build2 execution: scheduling, coalescing, cancellation, battery‑awareness.

**Domain (thin producers/consumers over the spine):**
10. **Habit Engine** — habit definitions + deterministic habit math.
11. **Reflection Engine** — the reflective loop: seeds prompts, receives the person's words as facts. *(absorbs micro‑check‑ins.)*
12. **Review Engine** — builds weekly/monthly review artifacts.
13. **Memory/Timeline Engine** — the temporal read‑model over the Record + confirmed landmarks + nostalgia. *(Timeline + Memory merged — one temporal view.)*
14. **Direction Engine** — the person's authored aims + framing context. *(absorbs goals/forks.)*
15. **Relationship Engine** *(deferred/minimal — MC4)* — consent‑gated, provenance‑labeled people.
16. **Ask Engine** — self‑inquiry: grounded answer or honest abstention.
17. **Search Engine** — a rebuildable retrieval index over the Record (zero‑claim).

**Cross‑cutting:**
18. **Notification Engine** — delivers the one weekly beat + opt‑in habit reminders (obeys Attention).
19. **Permission Engine** — OS permission requests + priming/framing.
20. **Privacy/Consent Engine** — the consent ledger; gates ingestion + off‑device; export/delete/audit.
21. **Trust Engine** — routes corrections; owns the inspectable belief view + confidence/provenance presentation policy.
22. **Analytics Engine** — privacy‑preserving *internal* observability of honesty‑health (calibration, abstention/correction rates); never user tracking, never off‑device.

**Future (reserved, not in V3):**
23. **Sync Engine** — reserved seam for a future (V4) private sync; **must not exist in V3** (RJ5 forbids cloud self‑data).

*(Not subsystems: Onboarding and Widgets/Watch are Presentation‑layer flows/surfaces, not engines — SR1 defers most ambient surfaces.)*

---

## Part II — Engineering Contracts (per subsystem)

Compact contract per subsystem: **Purpose/Origin · Owns/Produces/Consumes/Refuses · Capabilities · Inputs · Outputs · Internal state · Dependencies · Runtime · Failure · Privacy.**

### 1. Record Engine
- **Purpose/Origin:** the single source of truth (Design3; Build1). Solves memory/discontinuity (S3).
- **Owns:** all facts + their provenance. **Produces:** facts to readers; append acknowledgements. **Consumes:** validated facts from Ingestion. **Refuses to own:** any derivation, interpretation, or presentation.
- **Capabilities:** append a fact; read facts (by window/query); apply a correction (as a new fact); export; delete. *Nothing else.*
- **Inputs:** validated, provenance‑tagged facts — **only from Ingestion.** Validation: already validated upstream; Record enforces append‑only + ordering.
- **Outputs:** consistent read snapshots to any consumer. **Guarantees:** immutability of prior facts; durability; ordered by recorded timestamp; provenance on every fact.
- **Internal state:** the fact store — private; **never mutated externally**; a prior fact is never altered by anything derived.
- **Dependencies:** required — none (the base). Forbidden — everything (nothing may reach in). Direction: everything depends on it; it depends on nothing.
- **Runtime:** Immediate for writes (serialized single‑writer); concurrent reads (snapshots). *(Build2.)*
- **Failure:** if it fails, the app cannot capture — the gravest failure; recovery via durable storage; the person must never lose a fact silently. Survives: nothing above it works without it.
- **Privacy:** local‑only; encrypted at rest; exportable; deletable (real, complete); auditable (provenance).

### 2. Ingestion Engine
- **Purpose/Origin:** the honest write gate (Build1 pipeline stages 2–4). Ensures every fact is valid, consented, sourced.
- **Owns:** validation + consent‑gating + provenance‑tagging of inbound facts. **Produces:** validated facts to Record; a fact‑written event. **Consumes:** user actions + normalized signals + corrections. **Refuses to own:** the truth store, derivation.
- **Capabilities:** validate; check consent; tag provenance; append via Record; emit the fact event. Nothing else.
- **Inputs:** from Habit/Reflection/Direction/Ask (user facts), Signal Engine (sensed), Trust (corrections). Validation: well‑formedness, bounds, consent present.
- **Outputs:** facts → Record; fact events → Runtime/Derivation. **Guarantees:** nothing enters the Record un‑validated, un‑consented, or un‑sourced.
- **Internal state:** transient validation context — private.
- **Dependencies:** Record, Privacy/Consent. Forbidden: Derivation, Presentation.
- **Runtime:** Immediate (on the write path). *(Build2.)*
- **Failure:** a rejected input is honestly reported to the caller; a failed write is honest failure, never silent loss. Survives: reads; existing facts.
- **Privacy:** enforces consent; local‑only.

### 3. Signal Engine
- **Purpose/Origin:** normalize sensed samples (Build1 signal generation; R8). Solves fragmented sensor data.
- **Owns:** sensor sample normalization + dedup (by source+timestamp+value). **Produces:** normalized, provenance‑ and reliability‑tagged signals to Ingestion. **Consumes:** raw consented sensor updates. **Refuses to own:** interpretation, storage of truth.
- **Capabilities:** normalize; deduplicate; reliability‑tag. Nothing else.
- **Inputs:** OS sensor updates — only for consented sources.
- **Outputs:** normalized signals → Ingestion. **Guarantees:** dedup (no double‑count); reliability + provenance attached; **missing is never fabricated.**
- **Internal state:** a dedup window — private.
- **Dependencies:** Privacy/Consent (gate). Forbidden: Record (writes only via Ingestion), Derivation.
- **Runtime:** Deferred/Background, battery‑aware. *(Build2.)*
- **Failure:** a failed sensor read is treated as missing = unknown; degrades gracefully. Survives: all non‑sensor facts.
- **Privacy:** consent‑required; local‑only.

### 4. Derivation Engine
- **Purpose/Origin:** honest inference over the Record (Build1 derivation layer; S4). Solves self‑opacity — honestly.
- **Owns:** the recompute orchestration + the reasoning constitution (renormalize over present evidence, missing=unknown, calibrate, hedge, abstain, never cross the ceiling). **Produces:** hedged, lineage‑bearing, confidence‑gated derivations to Knowledge. **Consumes:** Record snapshots; AI Engine computations. **Refuses to own:** the truth (never writes facts), verdicts/traits/causation/prediction.
- **Capabilities:** read a Record window; call AI Engine; enforce evidence/confidence gates; produce or *abstain*. Nothing else.
- **Inputs:** Record snapshots; fact/consent/time events (triggers).
- **Outputs:** derivations → Knowledge, each with lineage + confidence. **Guarantees:** idempotent (same facts → same result); renormalized; never above the ceiling; abstains below threshold.
- **Internal state:** transient compute context — private; never a second store of truth.
- **Dependencies:** Record (read‑only), AI Engine. Forbidden: writing to Record; depending on Presentation or feature engines.
- **Runtime:** Deferred (post‑action, coalesced) + Background/Scheduled; never on the interaction path. *(Build2.)*
- **Failure:** on error, abstain; degrade to facts + reflection; recompute later. Survives: the Record, capture, reflection.
- **Privacy:** local‑only; operates on consented data only.

### 5. AI Engine
- **Purpose/Origin:** the replaceable inference computation (Build1 AI boundaries; Design9 extensibility). The seam that lets models change without touching the architecture.
- **Owns:** the pluggable on‑device model/computation. **Produces:** raw computed estimates + uncertainty to Derivation. **Consumes:** prepared inputs from Derivation. **Refuses to own:** the honesty policy (that is Derivation's), the Record, presentation, any off‑device call.
- **Capabilities:** compute an estimate with uncertainty, on‑device, cancelable. Nothing else — **no policy, no gating** (those belong to Derivation).
- **Inputs:** windowed, prepared evidence from Derivation only.
- **Outputs:** estimates + uncertainty → Derivation. **Guarantees:** on‑device; bounded; cancelable; **deterministic/reproducible or seeded‑bounded** (no reproducibility‑breaking randomness).
- **Internal state:** model parameters/weights — private; swappable.
- **Dependencies:** none external. Forbidden: Record access, network, presentation.
- **Runtime:** Background/Deferred, opportunistic, cancelable, battery‑aware.
- **Failure:** on failure Derivation abstains; the app is unaffected beyond lost derivations.
- **Privacy:** on‑device only; the self‑data never leaves via this engine (V3).

### 6. Knowledge Engine
- **Purpose/Origin:** the live derived model (Design3 Understanding; S5 learning). Holds what LOCA currently believes.
- **Owns:** current beliefs/observations/patterns with confidence, lineage, and decay/retirement state. **Produces:** the current knowledge to consumers (Attention, Presentation, Ask, Reviews). **Consumes:** derivations from Derivation; corrections (via Trust). **Refuses to own:** the truth (facts), presentation, the decision to surface.
- **Capabilities:** store/update a derivation; decay/retire stale beliefs; serve current knowledge + confidence + lineage; apply a correction override. Nothing else.
- **Inputs:** derivations (Derivation); corrections (Trust).
- **Outputs:** current beliefs with confidence/lineage. **Guarantees:** every belief carries confidence + lineage; stale beliefs decay; corrections override immediately; nothing above the ceiling is ever held.
- **Internal state:** the belief model — recomputable (never authoritative); inspectable (Trust exposes it).
- **Dependencies:** Derivation, Trust. Forbidden: writing to Record; surfacing decisions (Attention owns that).
- **Runtime:** updated Deferred/Background; served Lazily on read.
- **Failure:** discardable and rebuildable from the Record; a lost model is not a lost fact.
- **Privacy:** local‑only; fully inspectable and deletable by the person.

### 7. Attention Engine
- **Purpose/Origin:** the surfacing filter (Design8). Prevents overwhelm; earns attention by withholding it.
- **Owns:** the decision of *what/when* is worth surfacing (the gates, the one weekly beat, silence‑by‑default). **Produces:** surfacing decisions to Presentation + Notification. **Consumes:** candidate knowledge + the person's tuning. **Refuses to own:** the knowledge itself, its computation, its delivery.
- **Capabilities:** evaluate candidates against the attention gates; decide surface/wait/silent; schedule the weekly batch. Nothing else.
- **Inputs:** candidate derivations (Knowledge); user tuning; goals/direction (relevance).
- **Outputs:** surfacing decisions. **Guarantees:** silence by default; ≤ one gentle weekly beat; no engagement optimization; the person's own things outrank system insights.
- **Internal state:** attention thresholds/tuning — private, user‑adjustable.
- **Dependencies:** Knowledge, Direction, user tuning. Forbidden: computing knowledge, delivering notifications directly.
- **Runtime:** Scheduled (weekly) + evaluated Lazily/Deferred.
- **Failure:** on failure, default to silence (the safe state).
- **Privacy:** local‑only.

### 8. Presentation Engine
- **Purpose/Origin:** compose honest read‑models for surfaces (Design5–7). The person's window onto the record.
- **Owns:** read‑model composition per the content contracts (L1/L2/L3, confidence/provenance visible, calm). **Produces:** surface read‑models; user actions → Ingestion. **Consumes:** facts (Record), knowledge (Knowledge), surfacing decisions (Attention). **Refuses to own:** truth, computation, surfacing decisions.
- **Capabilities:** compose a surface's content per its contract; render honestly; forward user actions. Nothing else — no interpretation, no overclaim.
- **Inputs:** Record reads, Knowledge, Attention decisions.
- **Outputs:** read‑models to the UI layer; actions to Ingestion. **Guarantees:** confidence/provenance shown; calm/one‑focal‑point; empty states honest; never overstates.
- **Internal state:** transient view state — private.
- **Dependencies:** Record, Knowledge, Attention. Forbidden: writing facts (except via Ingestion), computing derivations.
- **Runtime:** Immediate (render from caches); never triggers derivation on‑path.
- **Failure:** on missing knowledge, shows honest empty/abstention; never fabricates depth.
- **Privacy:** local‑only.

### 9. Runtime/Scheduler Engine
- **Purpose/Origin:** own Build2 execution. Prevents chaos.
- **Owns:** scheduling, coalescing, cancellation, battery/idle‑awareness, priority. **Produces:** run/cancel decisions. **Consumes:** events + system conditions. **Refuses to own:** any domain logic, the Record.
- **Capabilities:** schedule/preempt/coalesce/cancel work per Build2. Nothing domain‑specific.
- **Inputs:** events; battery/thermal/idle state.
- **Outputs:** execution decisions. **Guarantees:** interaction preempts all; deferred work coalesced; background cancelable; battery‑aware.
- **Internal state:** the work queue — private.
- **Dependencies:** OS conditions. Forbidden: domain logic.
- **Runtime:** it *is* the runtime coordinator.
- **Failure:** on failure, foreground still works (interaction is Immediate and independent); background simply doesn't run.
- **Privacy:** local‑only.

### 10–17. Domain Engines (compact)
Each is a *thin* producer/consumer over the spine; all share: **local‑only, consent‑where‑applicable, exportable/deletable, no ownership of truth or surfacing.**
- **Habit** — owns habit definitions + deterministic math; produces habit facts (via Ingestion); consumes Record; refuses inferred state/traits. Runtime: Immediate (log) + Lazy (history). Failure: deterministic, robust.
- **Reflection** — owns the reflective loop; produces reflection facts (the person's meaning) + the daily prompt (seeded from Record/Knowledge); consumes Record + Knowledge (seed); refuses interpreting the person's meaning. Runtime: Immediate (write) + Lazy (seed). **The prompt‑quality bar (MC3) is this engine's central obligation.** Failure: if seeding fails, offer a plain honest prompt; never block the write.
- **Review** — owns review artifacts; produces the weekly/monthly review; consumes a period's Record + Knowledge; refuses scores/grades. Runtime: Scheduled/Background (pre‑built). Failure: a thin week → a shorter honest review.
- **Memory/Timeline** — owns the temporal read‑model + confirmed landmarks + nostalgia; produces the timeline view + landmark confirmations (facts); consumes Record; refuses fabricated narrative. Runtime: Lazy (windowed/paged). Failure: shows the record as‑is.
- **Direction** — owns the person's authored aims + framing; produces direction facts + trajectory context (hedged); consumes user authoring + Record; refuses prescription. Runtime: Immediate (author) + Lazy (context). Failure: shows only what's authored.
- **Relationship** *(deferred/minimal)* — owns the people view; produces provenance‑labeled people; consumes consented signals + confirmations; refuses a CRM / asserted nature. Runtime: Background (derive) + Lazy (view). Failure: without consent → payoff‑named empty. **Ships only if MC4 approves; else reserved.**
- **Ask** — owns self‑inquiry; produces grounded/hedged answers (or abstention) + saved answers (facts, if saved); consumes the question + Record + Knowledge; refuses answers beyond evidence / conversation‑as‑default. Runtime: User‑triggered (honest progress, non‑blocking). Failure: honest abstention.
- **Search** — owns a rebuildable retrieval index; produces matching facts; consumes Record + query; refuses inference from a query. Runtime: Lazy (instant, indexed). Failure: rebuild the index from the Record.

### 18–22. Cross‑cutting Engines (compact)
- **Notification** — owns delivery of the sanctioned beats only; produces the weekly notification + opt‑in habit reminders; consumes Attention decisions; refuses any un‑sanctioned notification. Runtime: Scheduled. Failure: silent (safe). Privacy: local scheduling.
- **Permission** — owns OS permission requests + priming; produces permission results; consumes user grants; refuses raw prompts without priming. Runtime: User‑triggered (at point of value). Failure: graceful degradation on deny. Privacy: n/a (gatekeeper).
- **Privacy/Consent** — owns the consent ledger + gating + export + delete + audit; produces consent state + export/delete actions; consumes user grants/revocations; refuses hidden data use. Runtime: Immediate (gate) + User‑triggered (export/delete). Failure: default to *deny/most‑private* on ambiguity. Privacy: it *is* the privacy authority.
- **Trust** — owns correction routing + the inspectable belief view + confidence/provenance presentation policy; produces corrections (facts) + the "what LOCA believes" model view; consumes user corrections + Knowledge; refuses hiding any belief. Runtime: Immediate (correction) + Lazy (inspection). Failure: corrections must never be lost. Privacy: fully inspectable/deletable.
- **Analytics** — owns *internal, on‑device, privacy‑preserving* honesty‑health observability (calibration, abstention/correction rates); produces internal metrics; consumes derivation outcomes vs check‑ins; refuses user tracking + any off‑device telemetry of self‑data. Runtime: Background. Failure: benign (metrics only). Privacy: **on‑device only; never the self‑data off‑device.**

### 23. Sync Engine (reserved)
- **Purpose:** a future (V4) private, opt‑in sync seam. **In V3: does not exist and must not.** *(RJ5.)* Its contract is reserved so V4 can add it as a new producer/consumer without redesign (Part VII).

---

## Part III — The Decision Ownership Matrix

Every decision has exactly one owner; no decision emerges from two systems.

| Decision | Sole owner | Basis |
|---|---|---|
| Which insight/observation *exists* | Derivation Engine | evidence gates (S4) |
| Which observation is *promoted/held* | Knowledge Engine | corroboration + decay (S5) |
| Which insight *appears* (is surfaced) | **Attention Engine** | attention gates (Design8) |
| Which notification is *sent* | Notification Engine (per Attention's decision) | one weekly beat |
| Which review *section appears* | Review Engine | period facts + Knowledge |
| Which memory *resurfaces* (nostalgia) | Memory/Timeline Engine (surfaced via Attention) | real past relevance |
| Which correction *overrides a belief* | Trust Engine (authority) → Knowledge applies | highest authority (S4) |
| Which derivations *rerun, and when* | Runtime/Scheduler Engine | Build2 scheduling |
| Which AI answer *is shown* (Ask) | Ask Engine (composes) → Presentation (renders) | grounded/abstain (S4) |
| Whether data *is used at all* | Privacy/Consent Engine | consent ledger |
| Whether a life event *is real* | the **person** (via Confirmation) | S5 — never the system |

**The decision law:** *computation, holding, and surfacing are three different decisions with three different owners* (Derivation → Knowledge → Attention). This separation is what prevents the V2 failure of a system both inventing and shouting an insight. Surfacing is never decided by the thing that computed it.

---

## Part IV — Communication Contracts

Subsystems communicate only in sanctioned forms; hidden coupling is forbidden.

**Allowed:**
- **Published facts** — Ingestion appends to the Record; consumers read. The primary, canonical channel. *(Design9 one‑record.)*
- **Events** — a fact/consent/time change emits an event that triggers deferred work (Build2). One‑way, fire‑and‑forget.
- **Queries / read‑models** — a consumer reads a snapshot or a composed read‑model. Read‑only.
- **Derived knowledge** — Derivation → Knowledge → consumers, always with lineage + confidence.

**Forbidden:**
- **Direct feature‑to‑feature calls** — no domain engine calls another; they meet only through the Record. *(no cycles — Build1.)*
- **Commands that mutate another subsystem's private state** — no reaching in.
- **Back‑channels** — nothing derived writes to the Record; no hidden shared mutable state.

**The communication law:** everything flows through **published facts, one‑way events, and read‑only queries** — so coupling is always visible, always through the Record, and never cyclic. If two subsystems need to talk directly, the design is wrong.

---

## Part V — Lifecycle Contracts

Every subsystem's transitions are explicit:
- **Creation → Initialization:** established with its dependencies (which point only toward the Record); no work yet.
- **Ready:** dependencies satisfied; accepting inputs.
- **Running:** performing its one responsibility under Runtime scheduling.
- **Paused / Background:** yields to interaction; may be suspended by the Scheduler; cancelable.
- **Recovery:** on fault, rebuild derived state from the Record (Build2); facts are never rebuilt (they're durable).
- **Shutdown:** cancel in‑flight work (cancelable by contract); persist nothing derived (recomputable); the Record is already durable.
- **Migration:** on version upgrade, the **Record migrates carefully (facts are sacred); derived state is discarded and recomputed** — never migrated, since it's a pure function of facts.
- **Deletion:** the person may delete facts (sovereignty); derived state that depended on them is recomputed/retired.

**The lifecycle law:** only the **Record has a durable lifecycle**; every other subsystem's state is transient and reconstructable, so lifecycle management reduces to "protect the Record, recompute everything else." Migrations touch facts with utmost care and treat all derived state as disposable.

---

## Part VI — Validation Contracts

Each subsystem proves (conceptually): preconditions · postconditions · invariants · failure conditions · recovery · success. The universal contracts:
- **Precondition:** inputs are valid, consented, in‑scope for the subsystem's one responsibility.
- **Postcondition:** outputs carry required metadata (facts → provenance; derivations → lineage + confidence).
- **Invariants (system‑wide):** the Record is never mutated by derivation; nothing crosses the ceiling; missing = unknown; derivations are idempotent; every claim is explainable; the person's word overrides inference.
- **Failure conditions:** honest failure (reject/abstain), never silent loss or fabrication.
- **Recovery guarantee:** derived state is recomputable from the Record; facts are durable.
- **Success guarantee:** the subsystem does its *one* thing correctly and nothing else.

**The validation law:** every subsystem is contractually bound to the system invariants (immutability, one‑way flow, the ceiling, missing=unknown, idempotency, explainability, the person's authority) — these are not per‑feature choices but universal preconditions on *existing at all.*

---

## Part VII — The Replaceability Framework

Assuming V4 brings new models, sensors, storage, inference engines, cloud:
- **Replaceable subsystems:** AI Engine (any model), Signal Engine (any sensor), Search Engine (any index), the Record's *storage substrate* (behind its contract), Presentation surfaces. These change without touching the rest.
- **Stable interfaces that must never break:** the **Record's fact contract** (append/read/immutable/provenance); the **reasoning constitution contract** Derivation exposes (evidence‑bounded, calibrated, abstaining, ceiling‑capped); the **consent contract**; the **event/query contract**.
- **Contracts that may never break, ever:** the one‑way flow; the ceiling; missing=unknown; the person's sovereignty over data and meaning; on‑device‑by‑default for self‑data.

**The replaceability law:** V4 evolves by **replacing components behind stable contracts, never by redesigning the architecture** — a new AI model, sensor, or storage engine plugs into the same Record and the same honesty contract, so the product's character survives every technology change. *(Design9 extensibility; Build1.)*

---

## Part VIII — The Observability Framework

Every subsystem exposes conceptual observability (internal, privacy‑preserving — Analytics owns aggregation):
- **Health** — is the subsystem functioning? **Freshness** — how current is its derived output vs the Record? **Latency** — is it staying off the interaction path? **Failures** — error/abstention rates. **Confidence** — calibration health (do readings match check‑ins? — R4/R7). **Throughput** — work processed. **Queue health** — backlog under the Scheduler. **Dependency health** — is the Record reachable? **Recovery status** — recompute progress after a fault.

**The observability law:** the system can be asked, at any time and *without surveilling the person*, whether it is *honest and healthy* — is it calibrated, is it abstaining appropriately, are corrections sticking, is the interaction path clean. **Nothing is a black box, least of all the honesty.** *(Build1; the V2 failures were invisible precisely because this didn't exist.)*

---

## Part IX — Testing Contracts (what each must prove)

Without writing tests, what each subsystem must demonstrably prove:
- **Record:** immutability, durability, ordering, provenance, real deletion — *data integrity.*
- **Ingestion/Signal:** validation, consent‑gating, dedup, missing=unknown — *privacy + integrity.*
- **Derivation:** **renormalization, missing≠low, the ceiling, calibration, abstention, idempotency, determinism/reproducibility** — the most‑tested subsystem (these are the exact V2 failures — Design10).
- **AI:** boundedness, cancelability, reproducibility, on‑device‑only — *privacy + determinism.*
- **Knowledge:** confidence/lineage on every belief, decay, correction override — *explainability.*
- **Attention:** silence‑by‑default, ≤ one weekly beat, no engagement optimization — *anti‑manipulation.*
- **Presentation:** confidence/provenance visible, no overclaim, honest empties, accessibility (Dynamic Type/VoiceOver/contrast/Reduced Motion), calm/performance — *accessibility + honesty.*
- **Runtime:** interaction preemption, coalescing, cancelability, battery‑awareness — *concurrency safety + performance.*
- **Privacy/Consent/Trust:** consent enforced, corrections never lost, full inspect/export/delete, no hidden belief — *privacy + trust.*
- **All:** graceful degradation + fault recovery (recompute from the Record).

**The testing law:** every subsystem has *measurable engineering expectations*, and the honesty invariants (Derivation's renormalization/ceiling/abstention, Attention's restraint, Presentation's no‑overclaim, Privacy's enforcement) carry the **highest** test priority — because these are precisely where Version 2 failed and where trust lives.

---

## Part X — System Readiness Review

Challenging every subsystem: one responsibility? one owner? unnecessary behavior? absorbable? too large/small? replaceable? testable? independently evolvable?

- **Verdict:** the inventory is clean. Each subsystem has one responsibility and one owner; the three‑way split (Derivation computes · Knowledge holds · Attention surfaces) resolves the V2 "invent‑and‑shout" coupling.
- **Merges applied** (to avoid over‑splitting): Timeline+Memory → one; goals/forks → Direction; micro‑check‑ins → Reflection.
- **Splits applied** (to avoid over‑large): Derivation vs AI (policy vs computation — the replaceability seam); Derivation vs Knowledge (compute vs hold); Attention vs Notification (decide vs deliver). These splits are load‑bearing, not bureaucratic.
- **Watch‑items (from Design10, re‑confirmed at subsystem level):** Knowledge must cap live observations (SR4, anti‑feed); Relationship ships only if MC4 approves; Reflection's prompt‑quality (MC3) is its make‑or‑break obligation.
- **Recommended changes:** none structural. The subsystem set is coherent, minimal, replaceable, testable, and independently evolvable.

**The readiness verdict:** every subsystem is one responsibility, one owner, one contract — the specification is sound to implement.

---

## Part XI — The Engineering Specification Handbook (framing)

This document *is* the handbook. A new engineer, reading Build1 (architecture) + Build2 (runtime) + Build3 (subsystems), understands — **without any implementation code** — every subsystem, its responsibility, its contract, its dependencies (always toward the Record), its runtime behavior (Build2 category), its ownership rules (the Decision Matrix), its failure modes (degrade to the Record + reflection), and its validation invariants (the system‑wide contracts). Nothing is a black box; every decision has one owner; every subsystem does one thing.

---

## The subsystem specification, in one statement

> **Version 3 is built from a small set of single‑responsibility subsystems arranged around one immutable Record: producers (Habit, Reflection, Direction, Ingestion, Signal) that validate and record facts; a three‑part intelligence (Derivation computes honestly, Knowledge holds provisionally, Attention decides what — if anything — to surface) so that inventing, holding, and shouting an insight are three separate decisions with three separate owners; feature engines (Timeline, Reviews, Ask, Search, People) that are thin honest views over the record; cross‑cutting guardians (Privacy/Consent, Trust, Permission, Notification, Analytics) that enforce consent, corrections, honest observability, and the one weekly beat; a Runtime that keeps the person first and nothing waiting; and a replaceable AI seam behind a stable honesty contract. Every subsystem owns exactly one thing, depends only on the Record, communicates only through published facts, one‑way events, and read‑only queries, degrades to the record‑and‑reflection floor when it fails, and is bound — as a precondition of existing at all — to the system invariants of immutability, one‑way flow, the ceiling, missing‑is‑unknown, idempotency, explainability, and the person's final authority.**

This subsystem specification is the authoritative engineering contract; every Build phase (Build4–Build8) and every line of eventual code must obey it, and where any conflicts with Build1, Build2, Design, or the Constitution, those win.

---

*Build3 complete. The complete subsystem inventory, per‑subsystem engineering contracts, Decision Ownership Matrix, communication contracts, lifecycle contracts, validation contracts, replaceability framework, observability framework, testing contracts, system readiness review, and Engineering Specification Handbook are defined and derived entirely from Phase R, Phase S, Design1–10, Build1, and Build2. No Swift, APIs, database schema, class diagrams, file structure, or implementation were written. Stop here; do not begin Build4. Build3 is ready for review.*
