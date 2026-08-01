# Build5 — Engineering Operations & Evolution Manual

**Version 3 · Build Phase · Document 5 of 8**
**Status: Long-Term Engineering Operations Manual (no production code)**

---

## Preamble — What Build5 Is

Build1 froze the architecture. Build2 froze the runtime. Build3 froze subsystem ownership. Build4 froze the implementation discipline that gets code written faithfully.

All four assume a moment in time — the moment code is written. Build5 assumes **years**.

Every software system accumulates entropy. Boundaries that were crisp on day one soften under a hundred small deadlines. A cache added "temporarily" becomes authoritative. A subsystem that owned one thing quietly grows to own six. Provenance that was complete starts dropping fields under load. None of this is malice; it is gravity. Left unmeasured, a frozen architecture does not stay frozen — it *melts slowly, invisibly, and only becomes visible to users as the thing Version 3 was built to escape.*

Build5 answers one question:

> **"How do we know Version 3 is becoming healthier instead of slowly decaying?"**

The word that matters is *know*. Not hope, not assume — **measure, expose, and correct** engineering degradation before a user ever feels it. Build5 defines the **engineering health system**: the metrics, the drift detectors, the debt governance, the observability, the reliability standards, the complexity budgets, the continuous validation, the improvement process, the review cadence, and the operational constitution that together keep Version 3 excellent for the next five years.

This document introduces **no features and no implementation details.** It is operational discipline, and nothing else.

**One sentence:** *A frozen architecture is not preserved by freezing it once — it is preserved by continuously measuring its temperature and acting the moment it starts to thaw.*

---

## Part I — Engineering Health Philosophy

What "healthy engineering" means for Version 3. Health is not the absence of bugs; a system can be bug-free today and structurally rotting. Health is a set of *trends*, and the healthy direction is often the counter-intuitive one.

### HP1 — The architecture stays understandable
A new engineer can hold the system's shape in their head. If understanding the system requires tribal knowledge, the architecture has decayed regardless of what the diagrams still say. Understandability is measured, not assumed.

### HP2 — Boundaries stay intact
The subsystem ownership frozen in Build3 remains true in the code, not just in the document. A boundary that exists on paper but is routinely bypassed in practice is *worse* than no boundary, because it lies.

### HP3 — Complexity stays controlled — and ideally falls
The radical stance: a healthy Version 3 gets **simpler** over time, not more complex. Most systems treat complexity growth as inevitable. Version 3 treats every quarter that ends more complex than it began as a signal requiring explanation. Complexity is a budget, not a byproduct (Part VII).

### HP4 — Trust never erodes
The trust properties — provenance completeness, missing-stays-unknown, honest abstention, calibrated confidence, an intact ceiling — are health metrics of the *first rank*, weighted equal to or above performance. A faster system that has started inventing values is not healthier; it is sicker (HP-linked to Part II Trust Health).

### HP5 — Failures become *more* visible over time
A healthy system's failures get louder and clearer as it matures, never quieter. Every incident should leave behind better observability than it found. The trend line of "silent failures" points toward zero.

### HP6 — Every degradation is caught by the system, not by a user
The entire operational discipline exists so that engineering decay is detected internally, early, and corrected before it reaches a person. The day a user notices the decay is the day the health system failed.

### HP7 — Measure before you change
No structural change is made on intuition alone. Drift is asserted with a metric, debt is quantified, complexity is budgeted. Opinion proposes; measurement decides (echoed as the first article of the Operational Constitution).

---

## Part II — Engineering Metrics: The Version 3 Scorecard

The complete engineering scorecard. Every metric has a **direction** (which way is healthy), and every metric is a **trend**, not a snapshot — a single reading means little; the slope means everything. Metrics are grouped into four health domains.

### Architecture Health
| Metric | Healthy direction | What it catches |
|---|---|---|
| Boundary violations | → 0, and falling | Code reaching past its Build3 owner |
| Circular dependencies | = 0, absolute | Subsystems that can no longer be reasoned about or replaced independently |
| Contract violations | → 0, and falling | Producers/consumers drifting from Build3 contracts |
| Dependency growth | Flat or falling per subsystem | Creeping coupling |
| Coupling trend | Falling or flat | The slow slide toward a monolith |

### Implementation Health
| Metric | Healthy direction | What it catches |
|---|---|---|
| Technical debt trend | Falling; never silently rising | Accumulating shortcuts (governed in Part IV) |
| Documentation coverage | High and current | Legibility decay (Build4 Part VIII) |
| Review quality | High; violations caught pre-merge | The Code Review Constitution weakening in practice |
| Validation completion | 100% of required dimensions | "I'll add the checks later" creeping in |
| Build success rate | High and stable | Pipeline erosion |

### Testing Health
| Metric | Healthy direction | What it catches |
|---|---|---|
| Regression coverage | Rising; every fixed defect guarded | F1–F8 silently returning |
| Property-test coverage | Rising across invariants | One-way flow / renormalization / determinism drifting |
| Failure-injection coverage | Rising across failure paths | Silent-swallow regressions |
| Long-history coverage | Rising; multi-year histories tested | The exact blind spot that produced V2's defects |
| Performance coverage | Rising across hot paths | Unmeasured performance regressions |

### Trust Health *(first-rank metrics)*
| Metric | Healthy direction | What it catches |
|---|---|---|
| Provenance completeness | = 100%, absolute | F8 regression — dropped lineage |
| Unknown preserved correctly | = 100%, absolute | F1/F5/F6 regression — missing becoming low |
| Abstention correctness | = 100% | LOCA speaking when it should stay silent |
| Confidence calibration | Well-calibrated; drift flagged | Overconfident or invented certainty |
| Ceiling violations | = 0, absolute | Any verdict/trait/causation/prediction leaking in |

**Rule:** the four "absolute" metrics (circular dependencies, provenance completeness, unknown-preserved, ceiling violations) have no acceptable non-zero value. A nonzero reading is an incident, not a trend to watch.

---

## Part III — Architectural Drift Detection

How architectural decay is detected *as it happens*. Each drift pattern is defined by three things: how it is **detected**, its **severity**, and the **required response**. Detection is continuous; the drift patterns are the specific ways Build1–Build4's guarantees erode in practice.

| Drift pattern | Detection | Severity | Required response |
|---|---|---|---|
| **Hidden coupling** | A dependency appears that isn't declared in a Build3 contract | High | Block/revert; make the dependency explicit in the contract via governance, or remove it |
| **God object** | A subsystem exceeds its complexity budget (Part VII) — too many responsibilities/exports | High | Split along Build3 ownership lines; no subsystem may absorb another's role |
| **Feature ownership erosion** | Two subsystems both implement a responsibility Build3 assigns to one | Critical | Restore single ownership; delete the duplicate (this is the V2 duplication failure returning) |
| **Runtime shortcut** | Code bypasses the event pipeline, coalescing, or concurrency discipline (Build2) | High | Route through the runtime; a shortcut around Build2 is never accepted for convenience |
| **AI bypassing contracts** | The AI subsystem is invoked or trusted outside the S4 reasoning-constitution contract | Critical | Revert; the AI is always behind its contract and always replaceable (IP9) |
| **Record bypass** | Authoritative state is written or read somewhere other than the Record | Critical | Revert; the Record is the only truth (IP4). No exceptions |
| **Cache becoming authoritative** | A cache/view-model is treated as truth rather than a rebuildable projection | Critical | Restore the cache to derived-and-disposable status; rebuild from the Record |
| **Duplicate logic** | The same derivation/decision is computed in two places | Medium→High | Consolidate to the single owning subsystem (Decision Ownership Matrix, Build3 Part III) |
| **Backward flow** | Data flows downstream→upstream (something mutates the Record or a producer) | Critical | Revert immediately; one-way flow is inviolable |

**The three Critical patterns — Record bypass, cache-as-truth, backward flow, feature-ownership erosion, AI-bypass — are treated as incidents,** not backlog items: they stop the line until corrected, because each one directly reintroduces a class of failure Version 3 exists to prevent.

---

## Part IV — Technical Debt Governance

Debt is not forbidden — *hidden* debt is. Version 3 makes debt **measurable, owned, and expiring.** The governing move is to convert every shortcut from an invisible liability into a tracked item with a name attached and a deadline.

### Debt taxonomy
- **Acceptable debt.** A conscious, documented shortcut that does not violate a contract, the Record, one-way flow, or the ceiling — taken to ship a vertical slice, with a defined retirement condition. *Allowed.*
- **Forbidden debt.** Any shortcut that violates a Critical drift pattern (Part III) — Record bypass, cache-as-truth, backward flow, ceiling breach, AI-off-contract, or "missing = low." *Never allowed, not even temporarily.* There is no deadline short enough to make these acceptable.
- **Temporary debt.** Acceptable debt with an explicit expiration *condition* (not just a date) — e.g. "removed when Stage 5 lands." Must be retired when the condition is met.
- **Permanent debt.** A deliberate, permanent trade-off, accepted through governance with full rationale. Rare, and never a Forbidden-class item relabeled as permanent to dodge its expiry.

### Every debt item carries
- **Owner** — a specific person accountable for it (HP-linked: every shortcut has an owner).
- **Reason** — why the shortcut was taken and why the clean path wasn't.
- **Risk** — what it threatens if left unretired, and its severity.
- **Expiration condition** — the concrete event or date that forces its retirement. *An item with no expiry is not temporary debt; it is either permanent debt (needing governance approval) or a defect.*

### Interest and retirement
- **Interest accumulation.** Debt's cost is tracked as a trend (Part II Implementation Health). Debt whose risk or blast-radius grows over time accrues "interest" and is prioritized for retirement accordingly.
- **Retirement strategy.** Temporary debt is retired when its condition fires; high-interest debt is scheduled into the improvement process (Part IX); the total debt trend must not silently rise (HP-linked). Debt reduction is normal, expected engineering work — not a special project.

---

## Part V — Operational Observability

What engineering must **continuously observe.** The purpose of observability in Version 3 is not to collect logs — it is to **explain the system to itself**, and in particular to distinguish *healthy quiet* from *broken quiet*. Because Version 3 is built on silence (it earns attention by withholding it), the hardest operational question is: *is the system quiet because nothing is worth surfacing, or quiet because it broke?* Observability must answer that.

Continuously observed:
- **Runtime health** — scheduler behavior, coalescing effectiveness, concurrency correctness (Build2 in the field).
- **Event pipeline** — events emitted, consumed, and any dropped or unknown events (a dropped event is a silent-failure risk).
- **Derivation pipeline** — recompute volume, correctness of renormalization, and — critically — how often derivation *correctly abstains*. Abstention is a healthy signal, not an error.
- **Attention decisions** — how often the system chooses silence vs. surfacing, with the reason. A sudden rise in surfacing is a trust-health alarm (invent-and-shout returning).
- **AI behaviour** — every AI invocation stays within the S4 contract; confidence calibration; ceiling adherence.
- **Failure rates** — every failure path's frequency and its landing state (did it degrade to the reflection floor, or did it do something undefined?).
- **Background execution** — what ran, when, how long, and whether it stayed within resource budgets.
- **Resource usage** — CPU, memory, storage, and battery, since Version 3 lives on-device and a calm companion that drains a phone is not calm.
- **Scalability** — behavior as history grows across months and years (tied to long-history testing).
- **Recovery events** — every degradation and recovery, so that graceful degradation is *observed working*, not merely assumed.

**Rule:** observability must **explain, not merely record.** A log that says "silence" is worthless; a signal that says "silence because no derivation crossed the attention threshold, all pipelines healthy" is the product. Every observable is designed to answer *why*, not just *what*.

---

## Part VI — Reliability Engineering

The reliability philosophy. Version 3's reliability standard is unusual because its worst failure is not a crash — it is a **quiet, confident wrongness** that a user trusts. Reliability engineering here protects *integrity* first and *availability* second.

- **Failure budgets.** Each failure class has an explicit budget; exceeding it is an incident, not a statistic. The budget for integrity-violating failures (a corrupted Record, a lost provenance, a ceiling breach) is **zero** — these are never "within budget."
- **Recovery objectives.** Every degradation has a defined path back to full function, and the system always has a floor to degrade *to*: "facts + reflection" (Build2). Recovery is a designed behavior with an objective, not an emergency improvisation.
- **Data integrity.** The Record is append-only and immutable; its integrity is the highest reliability guarantee in the system. No failure is allowed to mutate or corrupt history. Integrity outranks availability, always.
- **Consistency guarantees.** Downstream projections (derivations, knowledge) are always rebuildable from the Record and are eventually consistent with it. A projection may lag; it may never contradict the Record's truth.
- **Graceful degradation.** Every failure lands in a defined, observable, floor-preserving state (IP10). The system never fails into undefined behavior — it fails into *less capability, preserved integrity*.
- **Retry discipline.** Retries are bounded, backed off, and idempotent by construction. A retry never produces a duplicate fact or a double-applied derivation.
- **Idempotency validation.** Idempotency is continuously validated, not assumed: replaying the same event log must produce identical state. This is a property test that runs forever, because idempotency is the guarantee that makes recompute, retry, and recovery all safe.

**Reliability stance:** *reliability is designed, not hoped for* (Operational Constitution). The question is never "will it fail?" but "when it fails, does it land somewhere defined, observable, and integrity-preserving?"

---

## Part VII — Complexity Management

Complexity naturally grows; Version 3 refuses to let it grow *unbudgeted*. These are **architectural budgets** — soft ceilings that, when exceeded, force an explicit decision rather than a silent slide. Budgets are set by architecture, and breaching one is a drift signal (Part III's God Object), not an automatic failure — but it always demands a response.

| Budget | What it caps | Why it exists |
|---|---|---|
| **Maximum subsystem size** | How large one subsystem may grow | A subsystem past its budget can no longer be held in one head (HP1) or replaced cleanly (IP9) |
| **Maximum dependencies** | How many other subsystems one may depend on | Caps coupling; keeps the dependency graph legible |
| **Maximum exported responsibilities** | How many things a subsystem exposes to others | Enforces "one subsystem, one responsibility" (Build3) against scope creep |
| **Maximum ownership** | How many responsibilities a subsystem owns | Prevents God objects and feature-ownership drift |
| **Maximum public surface** | How much of a subsystem is visible to others | A smaller surface is a smaller betrayal opportunity; keeps replaceability real |
| **Maximum cognitive load** | How much one must understand to change a unit safely | The ultimate budget — HP1 made measurable |

**Rule:** exceeding a budget is not automatically wrong, but it is never silent. It forces one of three governed outcomes: **split** the subsystem along Build3 lines, **justify** the overage as governed permanent debt with rationale, or **reduce** it back under budget. A budget breach with no decision attached is itself a drift signal.

**The ambition (HP3):** budgets are meant to *tighten* over time, not loosen. A healthy Version 3 spends effort making subsystems smaller and simpler, treating simplification as first-class engineering work.

---

## Part VIII — Continuous Validation

Build4's validation was about *development*. Build5's is about *forever*. Validation does not stop when a feature ships — the properties Version 3 promises must be re-proven continuously, because a property that passed on merge day can silently break six months later under new data, new scale, or new code.

Continuously validated:
- **Contracts** — every Build3 boundary still honored, including the unknown case.
- **Runtime** — Build2's event/coalescing/concurrency/degradation guarantees still hold under real load.
- **Privacy** — consent boundaries and on-device guarantees never regress; no new data path leaks.
- **Accessibility** — the Design5 interface constitution stays met as the UI evolves.
- **Trust** — provenance completeness, unknown-preserved, abstention, calibration, and the ceiling — the first-rank properties, validated relentlessly (Part II Trust Health made continuous).
- **AI** — the AI stays within the S4 contract, calibrated and ceiling-respecting, as models or prompts change.
- **Performance** — hot paths stay within budget across releases.
- **Battery** — on-device resource use stays within budget as capability grows.
- **Long-history behaviour** — the system stays correct and bounded against years-long histories (the V2 blind spot, permanently guarded).
- **Migration assumptions** — the assumptions the V2→V3 migration relied on remain true, so migrated histories never silently drift in meaning.

**Rule:** any continuous-validation failure is triaged by which health domain it hits. A Trust-domain failure (ceiling breach, lost provenance, missing-became-low) is an **incident** that stops the line; other domains are triaged by severity. Continuous validation is the immune system — its alarms are acted on, not muted.

---

## Part IX — Continuous Improvement

How Version 3 *evolves* without decaying. Evolution is necessary — a system that never changes dies too — but uncontrolled evolution is exactly how frozen architectures melt. The improvement process makes evolution **deliberate, measured, and traceable.**

- **How improvements are proposed.** Any engineer may propose an improvement, but a proposal must be grounded in a metric (Part II) or a drift signal (Part III) — *measure before you change* (HP7). "I think this would be nicer" is not a proposal; "boundary violations in subsystem X are trending up, here is the structural fix" is.
- **How architectural improvements are evaluated.** Against the frozen documents: does it preserve boundaries, one-way flow, the Record, determinism, the ceiling? An improvement that betters one metric while breaching a Critical invariant is rejected outright. Trade-offs across metrics are decided by governance (Build4 Part XI), with Trust Health weighted first.
- **How lessons are incorporated.** Every incident, drift correction, and retired debt item produces a lesson. Lessons become new property tests, new drift detectors, or tightened budgets — so the system's immune response strengthens with every illness (HP5).
- **How Build documents are updated.** When an improvement changes a frozen decision, the relevant Build (or Design) document is amended *first*, through governance, and the code follows. The documents are never allowed to lie about the running system — a change that updates code but not its governing document is an incomplete change (Build4 Part VIII).

**The guard against uncontrolled evolution:** nothing structural changes without a metric behind it, a governance decision above it, and a document update beside it. Evolution is welcome; drift wearing evolution's clothes is not.

---

## Part X — Engineering Review System

Recurring engineering reviews turn the scorecard from data into decisions. Each review has a **cadence, objective, participants, deliverable, and escalation criteria.** The cadences are deliberately matched to how fast each kind of decay moves.

### Weekly — Runtime & Operational Health
- **Objective:** catch fast-moving operational decay — failure rates, event-pipeline health, resource/battery trends, recovery events, abstention/surfacing balance.
- **Participants:** the engineers actively building; whoever owns runtime observability.
- **Deliverable:** a short health readout and any incidents opened.
- **Escalation:** any Trust-domain anomaly or Critical drift pattern escalates immediately, not to next week.

### Monthly — Architecture Health
- **Objective:** review Architecture and Testing Health metrics — boundary/contract violations, coupling and dependency trends, coverage trends. Detect drift patterns early (Part III).
- **Participants:** engineers plus whoever holds architectural authority.
- **Deliverable:** a drift report with required responses assigned and owned.
- **Escalation:** any Critical drift pattern, or any absolute metric gone nonzero, escalates to an incident with a stop-the-line response.

### Quarterly — Complexity & Debt Review
- **Objective:** review complexity budgets (Part VII) and the debt ledger (Part IV). Ask the HP3 question: *is the system simpler than last quarter?* Retire debt; tighten budgets where possible.
- **Participants:** architectural authority plus subsystem owners.
- **Deliverable:** budget adjustments, debt-retirement schedule, and an explicit answer to whether complexity rose or fell — with a reason.
- **Escalation:** unexplained complexity growth, or debt trending silently upward, escalates to governance.

### Per Release — Constitution Review
- **Objective:** before any release, verify nothing violates the Implementation Constitution (Build4 Part XII), the Operational Constitution (Part XI), or the LOCA Constitution (S7). Confirm all first-rank Trust metrics are perfect and all Quality Gates (Build4 Part X) passed.
- **Participants:** everyone accountable for the release.
- **Deliverable:** a release-readiness sign-off, or a blocked release with named blockers.
- **Escalation:** any constitutional violation blocks the release, without exception or negotiation.

---

## Part XI — The Operational Constitution

Immutable principles governing the operational life of Version 3. Where Build4's Implementation Constitution governs every *line of code*, the Operational Constitution governs every *year of operation*. It is subordinate only to the LOCA Constitution (S7).

1. **Measure before changing.** No structural change without a metric or drift signal behind it. Intuition proposes; measurement decides.
2. **Drift is detected early.** Decay is caught by the system, internally, before a user ever feels it. The day a user notices is the day we failed.
3. **Every shortcut has an owner.** No anonymous debt. A shortcut nobody owns is a defect, not debt.
4. **Every exception expires.** Temporary debt has an expiration condition; an exception without an expiry is either permanent debt (governed) or a lie.
5. **Complexity has a budget,** and the healthy direction is down. Every budget breach forces a decision; unexplained growth is a defect.
6. **Documentation remains current.** The Build and Design documents never lie about the running system. Code and its governing document move together.
7. **Engineering health is visible.** The scorecard is public to the team and acted upon — health that isn't visible isn't managed.
8. **Trust metrics matter as much as performance** — and outrank it when they conflict. Provenance, unknown-preserved, abstention, calibration, and the ceiling are first-rank.
9. **Reliability is designed, not hoped for.** Every failure lands somewhere defined, observable, and integrity-preserving. Integrity outranks availability.
10. **The absolutes stay absolute.** Zero circular dependencies, zero ceiling violations, zero lost provenance, zero backward flow — no reading other than zero is ever "within budget."
11. **Evolution is governed, not spontaneous.** The architecture is governed-frozen: it changes only through metric, governance, and document — never through convenience.

This constitution governs the operational life of Version 3. A system that ships every feature, hits every performance target, and runs for five years but has quietly let one absolute go nonzero, one boundary erode, or one shortcut lose its owner has not stayed healthy — it has decayed politely into the thing Version 3 was built to replace.

---

## Closing — What Build5 Delivered

Build5 defined the **engineering health system** that keeps Version 3 excellent for years:

- an **engineering health philosophy** (Part I) — health as a trend, complexity that falls, trust as first-rank, decay caught internally;
- the **Version 3 scorecard** (Part II) — Architecture, Implementation, Testing, and Trust Health metrics, each with a healthy direction and four absolutes;
- an **architectural drift framework** (Part III) — nine drift patterns, each with detection, severity, and required response, five of them line-stopping;
- **technical debt governance** (Part IV) — acceptable/forbidden/temporary/permanent debt, every item owned and expiring, debt made measurable;
- an **operational observability strategy** (Part V) — observability that explains, distinguishing healthy quiet from broken quiet;
- a **reliability engineering framework** (Part VI) — integrity over availability, zero budget for integrity failures, idempotency validated forever;
- **complexity budgets** (Part VII) — architectural ceilings that force decisions and are meant to tighten;
- a **continuous validation framework** (Part VIII) — the development validations, re-proven forever, triaged by health domain;
- a **continuous improvement process** (Part IX) — evolution that is measured, governed, and document-first;
- an **engineering review system** (Part X) — weekly/monthly/quarterly/per-release, cadence matched to decay speed;
- the **Operational Constitution** (Part XI) — 11 immutable principles over Version 3's operational life.

It answers *"How do we keep LOCA Version 3 excellent for the next five years?"* — with no Swift, no APIs, no schema, no file structure, no implementation detail, and no product redesign.

Everything here is consistent with Research (R1–R10), Synthesis (S1–S7), Design (Design1–Design10), Build1, Build2, Build3, and Build4. Nothing was redesigned; no subsystem boundary moved; no feature was introduced.

**Stop here; do not begin Build6. Build5 is ready for review.**
