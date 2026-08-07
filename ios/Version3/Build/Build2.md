# LOCA Version 3 · Build Phase
## Build2 — Runtime Execution Model & Runtime Constitution

> **The single question Build2 answers:** *How will Version 3 actually be executed — at runtime — without creating engineering chaos?*
>
> **This is not implementation.** It contains **no Swift, no APIs, no database schema, no file structure, no code.** Build1 defined *what the architecture is* (the static structure); Build2 defines *how work flows through it while running* (the dynamic behavior). Every decision is grounded in Research (R1–R10), Synthesis (S1–S7), Design (Design1–Design10), and the **Build1 Engineering Constitution**, and may not redesign the architecture or introduce product ideas.
>
> **Inheritance from Build1 (non‑negotiable):** an immutable Record as the single source of truth; unidirectional flow (facts up, corrections in as new facts, nothing backward); derivations recomputable and idempotent; determinism first; local‑first/on‑device; battery‑aware; graceful degradation; the acyclic dependency tree rooted at the Record.

---

## Part I — Execution Architecture (the eight execution categories)

Work moves through LOCA in eight categories. Each: why · belongs · never · latency · failure.

| Category | Why | Belongs | Never | Latency | Failure |
|---|---|---|---|---|---|
| **Immediate** (on the interaction path) | the person must never wait to act | writing a fact (log, reflection, check‑in, correction); rendering already‑derived views | inference, network, heavy derivation | perceptibly instant | the write is durable or the action honestly reports failure — never silent loss |
| **Deferred** (soon after, off‑path) | derive from a new fact without blocking | the post‑action refresh (recompute affected derivations) | anything user‑visible‑blocking | seconds | retryable; coalesced; abstain if it can't complete |
| **Background** (opportunistic) | do heavier honest work when allowed | the periodic derivation cycle, review pre‑build, maintenance | user‑visible blocking; battery‑hostile work | minutes–hours OK | reschedule; the app stays valuable without it |
| **Scheduled** (time‑based) | the rituals and time‑relative views | weekly Review generation, day/week rollovers, the one weekly notification | anything the person didn't sanction | not latency‑sensitive | catch up on next opportunity |
| **User‑triggered** (explicit) | the person asks for something | Ask, search, manual reflect, opening a surface | fabricating to be fast | fast (search instant; Ask shows honest progress, never blocks other work) | honest abstention |
| **Event‑driven** (reactive) | everything begins with an event | a fact‑written event triggers deferred derivation; a consent event enables ingestion | uncontrolled cascades | event‑appropriate | events are retryable + idempotent |
| **Batch** (grouped) | gather, don't stream | the weekly Review batches a week's noticing; signal dedup/aggregation; lapse catch‑up | streaming interruptions | background | resumable |
| **Lazy** (on demand) | don't compute what no one will see | a specific answer, a chapter detail, search results | eager computation of unviewed things | on‑access, fast | recompute on next access |

**The execution law:** *nothing runs without purpose, and nothing that runs is allowed to make the person wait.* The interaction path holds only Immediate work; everything derivational is Deferred, Background, Scheduled, or Lazy.

---

## Part II — Event Architecture (the taxonomy)

Everything begins with an event. Events fall into four classes; the load‑bearing ones are specified with source · priority · consumers · side effects · ordering · retry · idempotency.

**Class A — User‑authored facts** (highest authority; written immediately; the truth):
- **Habit logged** — src: user; priority: high; consumers: Derivation, Timeline, Reviews; side effects: a fact appended, deferred refresh; ordering: by timestamp in the Record; retry: write retries until durable; idempotent: a re‑submitted identical log dedups.
- **Reflection written** — src: user; high; consumers: Timeline (the person's meaning), Reflection seed history; side effects: a fact appended; idempotent: distinct entries are distinct; a duplicate save is dropped.
- **State check‑in** — src: user; high; consumers: Derivation (calibration + patterns); side effects: fact + calibration input; idempotent by timestamp.
- **Correction submitted** — src: user; **highest**; consumers: the corrected derivation + everything depending on it; side effects: override the belief, retain the correction, incremental re‑derive; ordering: applies to current state; retry: safe; **idempotent: applying twice equals once.**
- **Confirmation** (landmark/chapter/relationship‑nature) — src: user; high; consumers: Timeline, Derivation (baselines); side effects: a candidate becomes a fact; idempotent.
- **Direction/Goal changed** — src: user; medium; consumers: Reflection/Reviews framing; side effects: a fact appended; idempotent.

**Class B — Sensed signals** (consent‑gated; deferred; lower authority):
- **Sensor / Health / Motion / Location / Calendar update** — src: OS (consented); priority: low; consumers: Derivation (as hedged context); side effects: validated + provenance‑tagged fact, deferred refresh; ordering: by sample timestamp; retry: best‑effort; **idempotent: deduplicated by (source, timestamp, value)** — a re‑read never double‑counts (a V2‑verified property to preserve).

**Class C — System‑derived** (background; provisional):
- **Observation/Pattern produced · Landmark candidate · Belief updated/retired · Review generated** — src: Derivation; priority: background; consumers: Attention, Presentation; side effects: a recomputable view updated (never a fact); ordering: n/a (recomputed wholesale for the window); retry: idempotent recompute; idempotent: yes.

**Class D — Lifecycle / system** (reactive):
- **Permission/Consent granted or revoked** — src: user/OS; high; consumers: Ingestion (enable/disable a source), Derivation (evidence changes); side effects: source toggled, dependent derivations recompute (gain/lose evidence → confidence/abstention); idempotent.
- **Time/clock change (new day/week)** — src: system; medium; consumers: time‑relative derivations; side effects: scheduled recompute; idempotent.
- **App foreground/background · Data deleted/exported** — src: user/OS; consumers: scheduler / Record; side effects: schedule work / honor sovereignty; idempotent.

**The event law:** user‑authored fact events are written to the Record *before* any derivation begins (Build1 rule), are the highest authority, and — with corrections and sensor dedup — are **idempotent**, so replay, retry, and reordering can never corrupt the truth or duplicate work.

---

## Part III — Runtime Scheduling

The runtime decides *when* work happens by purpose and condition; nothing executes without purpose:

- **Immediate work** — user interactions (capture, render): run now, preempt everything. *(interaction always wins.)*
- **User‑visible work** — Ask, search, opening a surface: run promptly, off the write path, with honest progress.
- **Background work** — the derivation cycle, review pre‑build: run when the app/OS allows, cancelable, reschedulable.
- **Opportunistic work** — non‑urgent derivation and maintenance: run at natural idle moments.
- **Battery‑aware work** — heavier derivation/sensing: prefer idle/charging; back off under battery/thermal pressure. *(battery is first‑class — R3/R8.)*
- **Idle‑time work** — index rebuilds, belief decay, dedup: run when the person isn't waiting.
- **Maintenance work** — compaction, stale‑cache cleanup, decay of unsupported beliefs: lowest priority, opportunistic.

**Scheduling priority order:** interaction ▸ deferred post‑action refresh ▸ scheduled rituals ▸ background derivation ▸ maintenance. **The scheduling law:** the person's foreground work always preempts everything below it, so foreground can never be starved; background work is a courtesy the app can always do without. *(Build1; Design8 calm.)*

---

## Part IV — Concurrency Philosophy (immutable principles)

- **The Record is the synchronization point.** Writes are **serialized** (single‑writer, append‑only, ordered); reads are **concurrent** and see a consistent snapshot. *(Build1 immutable Record.)*
- **May run simultaneously:** independent derivations (each reads an immutable snapshot); reads and writes (readers see a consistent prior snapshot); UI rendering and background derivation.
- **Must remain serialized:** fact writes to the Record; a single derivation pass against itself (a reentrancy guard prevents overlapping passes — a V2 property to preserve).
- **Synchronization is owned by the Record**, not scattered across features; because domains never call each other (only the Record), there is one place synchronization lives.
- **Races are prevented structurally:** the one‑way flow means derivations never write facts, so there is no write‑write race on truth; single‑writer discipline serializes the only writes; idempotent recompute makes even an accidental duplicate derivation harmless.
- **Duplicate computations are prevented by** reentrancy guards + idempotency + dedup — a superseded in‑flight derivation may be canceled or allowed to finish, since re‑running is safe.
- **Cancellation:** every background/derivation task is cancelable; a new fact may supersede an in‑flight derivation (cancel‑and‑restart or finish‑then‑recompute — both correct because idempotent).
- **Priorities interact by preemption:** interaction preempts derivation; derivation yields; no priority inversion because nothing the person waits on depends on a lower‑priority task completing.

**The concurrency law:** correctness comes from *structure, not locks* — an immutable Record read as snapshots, serialized single‑writer writes, a one‑way flow, and idempotent recompute make most concurrency hazards impossible by construction rather than merely guarded against.

---

## Part V — Recomputation Strategy

When derived knowledge recomputes, and how much:

| Trigger | Scope | Timing |
|---|---|---|
| **New fact** | **incremental** — only derivations that depend on it | deferred (coalesced) |
| **Correction** | **incremental** — the corrected belief + its dependents | immediate override + deferred re‑derive |
| **Permission/consent change** | the derivations using that source | deferred |
| **Time change (day/week)** | time‑relative views (baselines, "this week") | scheduled |
| **Review generation** | **batch** for the period | scheduled/background |
| **Background maintenance** | occasional **complete** recompute (safety net) | idle/opportunistic |

**Principles:** prefer **incremental over complete** (recompute only what changed); recompute over a **relevant window**, not the whole history (live views need recent data, not ten years); **complete recompute is a background safety net**, not the norm; and because every recompute is **idempotent**, recomputation can never explode into inconsistency — the worst case is redundant work, never wrong state. *(Build1; Design3.)*

**Recompute coalescing (the one execution refinement, Part XI):** rapid successive facts (e.g. logging several habits at once) coalesce into *one* deferred derivation pass, so a burst of captures triggers one recompute, not a storm.

---

## Part VI — Caching Philosophy

*The Record is truth; caches are disposable* (Build1).

- **What deserves caching:** expensive, recomputable **derived views** — observations, patterns, rendered timelines, reviews, search indexes.
- **What must never be cached (as truth):** the Record itself (it *is* the source, not a cache); consent state; anything where staleness would misrepresent certainty.
- **When a cache is invalid:** when a fact it depends on changes (detected via the event/lineage), or when time advances past its window. Each cached view carries the "as‑of" state it was computed from.
- **How freshness is determined:** by comparing a cache's as‑of against the Record's current state; if the Record advanced in a way the cache depended on, the cache is stale.
- **How stale information appears:** it is normally recomputed before display; if ever shown while recomputing, it is labeled honestly ("updating…") — **stale is never presented as current with false confidence.** *(S6.)*
- **How cache failure behaves:** fall back to recompute from the Record — the source of truth is always available, so a lost or corrupt cache is never a lost fact and never a crash.

**The cache law:** caches accelerate; they never authorize. Any cache can be discarded at any moment and fully rebuilt from the Record, so the system's correctness never depends on a cache being present or valid.

---

## Part VII — Performance Architecture (measurable goals)

The design's performance promises become engineering targets (conceptual, not benchmarks‑as‑code):

- **Opening Today** renders from cached derived views **instantly**; it never triggers a full recompute on the interaction path.
- **Habit logging** is **immediate** — an instant durable write and confirmation; derivation is deferred.
- **Reflection writing** **never waits on inference** — the prompt is pre‑seeded; the write is immediate.
- **AI/inference never blocks interaction** — it is always Deferred/Background.
- **Reviews build in the background** and are **instant to open.**
- **Search is instantaneous** — indexed retrieval over the local record.
- **Large histories scale gracefully** — windowed/paged, so surface performance is independent of total history size.

**Measurable engineering goals:** an interaction is *acknowledged* perceptibly instantly and a cached view *renders* in well under a second; a capture is durable within the interaction; no interaction ever awaits inference or network; background derivation is bounded and cancelable. **The performance law:** the interaction path touches only the Record and caches — never derivation, never inference, never the network.

---

## Part VIII — Resource Management

LOCA must stay efficient after years of use:

- **CPU:** derivation off the interaction path, incremental, yielding to UI; opportunistic and cancelable.
- **Memory:** windowed/paged views; the whole history is never resident; a bounded working set regardless of record size.
- **Storage:** the Record grows append‑only over years — planned for; old raw *live* signals may be summarized/compacted while the *events* are kept with provenance (Design3 archiving); deletion is real (sovereignty).
- **Battery:** a first‑class constraint — duty‑cycled sensing, opportunistic/idle/charging‑preferred derivation, no aggressive polling; a wellbeing app must not drain the device. *(R3/R8.)*
- **Background execution:** cooperative with the OS, cancelable, reschedulable, never assumed to run.
- **Sensor usage:** consent‑gated, minimal (data minimization — SR2), efficient.
- **AI computation:** on‑device, opportunistic, bounded, cancelable, never on the interaction path.

**The resource law:** the person's device is a shared, precious resource; LOCA spends CPU, memory, storage, and battery as reluctantly as it spends attention (Design8), and stays light after a decade because derivation cost is bounded by a window, not by history.

---

## Part IX — Scalability

Version 3 scales without redesign because **derivation cost is decoupled from history size**:

| Scale | Behavior |
|---|---|
| **10 → 100 habits** | linear, small; habit math is trivial and per‑habit |
| **10 years of logs / millions of facts** | the append‑only Record grows linearly; reads are windowed/paged/indexed → surface performance stays bounded |
| **Thousands of reflections** | facts in the Record; retrieved by window/search, never all at once |
| **Hundreds of reviews** | per‑period artifacts; a slowly‑growing, bounded set |
| **Large relationship graphs** | bounded by the person's real social graph (dozens), inherently small |

**The scalability law:** the Record scales append‑only (no rewrite as it grows), and every live derivation and surface operates on a *relevant window* (recent data), so the app's runtime cost is a function of the *active window*, not the *total history* — it performs the same at year ten as at week one, and no redesign is needed to get there. *(Build1; Design9 evolution.)*

---

## Part X — Fault Recovery

Every runtime fault detected, recovered, and consistency preserved — anchored by the immutable Record + idempotent recompute:

| Fault | Detection → Recovery → Consistency |
|---|---|
| **Interrupted computation** | a pass didn't finish → discard partial derived state, re‑run (idempotent) → the Record is the anchor; no partial‑derived corruption persists |
| **App termination / battery death** | restart → recompute affected views from facts → derived state is always reconstructable; facts are durable or the write cleanly failed |
| **Storage pressure** | low‑space signal → compact/summarize live caches + old raw signals (keep events) → **never lose a fact silently**; surface honestly if the person must free space |
| **Permission / consent revocation** | source stops → dependent derivations lose evidence → **lower confidence / abstain**; core unaffected |
| **AI / inference failure** | derivation errors → degrade to facts + Record + reflection; derivations abstain |
| **Sensor disappearance** | signal stops → treated as missing = unknown (not low); graceful |
| **Clock changes** | detected via inconsistency → time‑relative views recompute; **recorded timestamps remain the truth; a backward jump never reorders facts** |
| **Corrupted derived state** | lineage/idempotent‑recompute mismatch → discard the cache, recompute from the Record → fully recoverable; a corrupted *fact* is surfaced honestly, never silently guessed |

**The recovery law:** because all derived state is a pure function of the immutable Record and is idempotently recomputable, **any runtime corruption is fully recoverable by discarding derived state and recomputing** — the only unrecoverable loss is a fact the *person* chose to delete. The Record + the capture/reflect loop are the runtime floor nothing can break.

---

## Part XI — Build Order Validation (challenging Build1 from execution)

Challenging the frozen architecture from a runtime perspective:

- **Can it actually be executed?** Yes — a layered, event‑driven, one‑way‑flow system over an immutable store is a well‑understood, executable shape.
- **Any dependency deadlocks?** No — the acyclic dependency tree rooted at the Record + single‑writer Record + no feature‑to‑feature calls means no cyclic waits → **deadlock‑free by construction.**
- **Can work be parallelized safely?** Yes — derivations read immutable snapshots (safe to parallelize); writes are serialized (no write races).
- **Can recomputation explode?** No — incremental + windowed + idempotent recompute bounds a change to affected‑only, window‑bounded re‑derivation; coalescing prevents burst storms.
- **Can battery usage become excessive?** Guarded by opportunistic/battery‑aware scheduling and data minimization.
- **Can background work starve foreground?** No — interaction preempts everything; foreground can't be starved.
- **Can the runtime remain deterministic?** Yes — determinism‑first + idempotent derivations → reproducible given the same facts; any future stochastic model must be seeded/bounded so reproducibility holds.

**Recommended architecture adjustments:** **none.** The Build1 architecture executes cleanly. **One execution‑level refinement (not an architecture change):** the deferred post‑action derivation must be **debounced/coalesced** so a burst of rapid facts triggers a single recompute — recorded here as a runtime requirement.

---

## Part XII — The Runtime Constitution (immutable runtime rules)

These govern every future implementation's runtime behavior:

1. **User interactions always win.** Interaction preempts all other work; foreground is never starved.
2. **Facts are written before derivation begins.** The Record is updated first; derivation reacts to it. *(Build1.)*
3. **No inference blocks interaction.** Inference is always Deferred/Background; the interaction path touches only Record + caches.
4. **Every background task is cancelable.** And reschedulable; none is assumed to run.
5. **Every recomputation is idempotent.** Re‑running yields the same result; replay/retry/reorder can't corrupt state.
6. **Caches are disposable.** Correctness never depends on a cache; any cache rebuilds from the Record.
7. **Expensive work is incremental and windowed.** Recompute only what changed, over a relevant window; complete recompute is a background safety net.
8. **Deferred derivation is coalesced.** A burst of facts triggers one recompute, not a storm.
9. **The runtime is deterministic/reproducible.** Same facts → same derivations; no hidden randomness that breaks reproducibility.
10. **Performance never compromises correctness.** When fast and honest conflict, abstain rather than fake‑fast; a slower true answer beats an instant wrong one.
11. **Battery is a first‑class constraint.** Heavy work is battery‑ and idle‑aware; the app stays light for years.
12. **Nothing runs without purpose.** Every scheduled, background, or lazy task justifies its execution; the default runtime state is quiet, like the product.
13. **The Record write is durable or an honest failure.** A capture is never silently lost.
14. **All derived state is recoverable by recomputation.** The Record + idempotent recompute guarantee that no runtime fault can lose anything but a fact the person deleted.

**The runtime law:** LOCA at runtime behaves the way LOCA behaves toward the person — *the person comes first, the truth is protected first, work is done quietly and only with purpose, and nothing that runs is ever allowed to make the person wait, lose a fact, or receive a claim faster than it can be made honestly.*

---

## The runtime model, in one statement

> **At runtime, LOCA writes the person's facts immediately and durably to an immutable Record, then does all derivation off the interaction path — deferred, background, scheduled, or lazy — coalesced, incremental, windowed, idempotent, cancelable, and battery‑aware, so the interaction path never touches inference or the network and the person never waits. Concurrency is safe by structure, not locks: an immutable Record read as snapshots, a single serialized writer, a strictly one‑way flow, and idempotent recompute make most hazards impossible rather than merely guarded. Caches accelerate but never authorize; the Record alone is truth, and every derived view can be discarded and rebuilt from it, so any fault is fully recoverable and the runtime floor of facts and reflection can never break. It scales the same at year ten as week one because derivation cost follows a window, not a history — and through all of it the runtime keeps the product's character: the person first, the truth first, quiet by default, and never fast at the expense of honest.**

This runtime constitution is the authoritative reference for how LOCA behaves while running; every Build phase (Build3–Build8) and every line of eventual code must obey it, and where any conflicts with Build1, Design, or the Constitution, those win.

---

*Build2 complete. The execution architecture, event architecture, runtime‑scheduling philosophy, concurrency philosophy, recomputation framework, cache architecture, performance architecture, resource‑management philosophy, scalability framework, fault‑recovery strategy, build‑order validation, and Runtime Constitution are defined and derived entirely from Phase R, Phase S, Design1–10, and Build1. No Swift, APIs, database schema, file structure, or implementation were written. Stop here; do not begin Build3. Build2 is ready for review.*
