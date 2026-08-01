# Build6 — Production Engineering Manual

**Version 3 · Build Phase · Document 6 of 8**
**Status: Production Engineering & Release Manual (no code, CI/CD, or infrastructure detail)**

---

## Preamble — What Build6 Is

Build1–Build5 produced a system that can be *built* faithfully and *kept healthy* for years. But a healthy engineering system is not yet a product. Between "the code is correct" and "a person is trusting this with their inner life" sits an act that is itself an engineering discipline: **release**.

Version 3 lives on a person's device and holds the most private material a companion app can hold — someone's habits, reflections, and slowly-earned self-understanding. A careless release does not just ship a bug; it can quietly break the one thing the whole product is built on: **trust**. A release that surfaces an invented value, drops provenance, breaches the ceiling, or silently reinterprets a user's history has done more damage than any crash, because the user *believed* it.

Build6 answers one question:

> **"How does Version 3 safely move from engineering to production without compromising trust?"**

The operative word is *safely*, and the non-negotiable clause is *without compromising trust*. Engineering excellence alone does not produce a reliable product — release must itself become an engineered process, with a philosophy, a lifecycle, readiness gates, a rollout ladder, controlled exposure, migration safety, incident response, quality metrics, governance, and post-release learning.

This document introduces **no features, no code, no CI/CD, no deployment scripts, and no infrastructure.** It is the discipline of shipping, and nothing else.

**One sentence:** *A release is not the moment code leaves engineering — it is an engineered act whose first duty is to protect the trust a person has placed in the system.*

---

## Part I — Release Philosophy

What "ready for release" means for Version 3. The philosophy inverts the industry default: most products optimize releases for *speed and feature count*. Version 3 optimizes them for *integrity and trust*, and treats every release as an opportunity to make the system more trustworthy than the last.

### RP1 — Correct before complete
A release ships what is *correct*, never what is merely *finished-looking*. A half-built capability that is honest about being partial is releasable; a complete-looking capability that invents or oversells is not. Completeness is never a reason to ship incorrectness.

### RP2 — Trust before novelty
No new capability is worth a regression in a Trust-Health metric (Build5 Part II). Given a choice between a novel feature and preserved trust, trust wins without debate — the same rule as IP7, now at release scope.

### RP3 — Stability before speed
Version 3 ships when it is stable, not when the calendar says so. A release cadence is a servant, never a master; a date is never a reason to ship something that fails a readiness gate.

### RP4 — Quiet confidence over feature count
The product's value is *quiet intelligence* — it earns attention by withholding it. A release is judged by whether the system speaks more truthfully and more rarely, not by how many features it added. A release that made LOCA louder without making it more right is a regression, however many checkboxes it filled.

### RP5 — Every release improves integrity
The bar for every release: the system's integrity — correctness, provenance completeness, honest abstention, an intact ceiling — is *at least as good* after as before, and ideally better. A release that trades any integrity for any convenience has failed its first duty, regardless of what else it delivered.

### RP6 — Reversibility is a precondition, not a fallback
Nothing ships that cannot be taken back. Reversibility is designed *before* release, not improvised after an incident. If a change cannot be rolled back safely, it is not ready — the un-reversibility is the blocker.

---

## Part II — Feature Lifecycle

Every capability moves through a defined lifecycle. No capability skips stages, and each stage has **entry requirements, exit requirements, ownership, and success criteria.** The lifecycle exists so that nothing reaches a user that has not earned its way through research, design, engineering, and validation.

```
Idea → Research → Design → Engineering → Internal Validation →
Experimental → Limited Release → Stable → Deprecated → Removed
```

| Stage | Entry requirement | Exit requirement | Owner | Success criterion |
|---|---|---|---|---|
| **Idea** | A real user problem, traceable to a gap in the self-understanding mission (S3) | The idea is worth researching; it fits the mission and the ceiling | Whoever proposes it | The problem is real and in-scope, not a feature for its own sake |
| **Research** | An idea worth investigating (grounded in R1–R10 method) | Evidence about people and prior art; known failure modes surfaced | Research owner | We understand the problem and how others got it wrong |
| **Design** | Researched understanding | A design that honors S1–S7 and Design1–Design10, within the ceiling | Design owner | The capability is honest, calm, and traces to Synthesis |
| **Engineering** | A frozen-consistent design | A complete vertical slice (Build4 Part II), all required validation green | Subsystem owner | Correct, contract-honoring, abstains when evidence is missing |
| **Internal Validation** | A complete slice | Passes all Quality Gates (Build4 Part X) and continuous validation (Build5) | Engineering + review | Provably faithful to the architecture; all Trust metrics perfect |
| **Experimental** | Internally validated, behind a flag | Real-use signal with integrity intact; no ceiling breach in the wild | Feature owner | Behaves honestly under real (internal/dogfood) use |
| **Limited Release** | Experimental behaved | Stable trust/reliability metrics across a limited audience | Feature owner + production owner | No trust regression; reliability within budget at small scale |
| **Stable** | Proven in limited release | Fully documented, observed, and governed | Production owner | Reliable, honest, and quiet in general availability |
| **Deprecated** | A decision to retire the capability | Users migrated; a governed removal schedule set | Production owner | Users protected through the wind-down; nothing lost silently |
| **Removed** | Deprecation complete | Code and its governing documents cleaned up together | Engineering | The capability is gone without residue or dormant risk |

**Rule:** a capability may move *backward* (Stable → Experimental, or straight to Removed) the moment it fails its stage's success criterion — most of all if it breaches a Trust metric. There is no stage a capability is too advanced to be pulled from.

---

## Part III — Release Readiness

Everything required before a release ships. This is a **checklist of gates, not aspirations** — a single unmet item blocks the release. It composes Build4's per-feature Quality Gates and Build5's continuous validation into a release-level bar.

| Readiness area | The bar |
|---|---|
| **Architecture complete** | No open Critical or High drift (Build5 Part III); boundaries and one-way flow intact |
| **Runtime validated** | Build2's event/coalescing/concurrency/degradation guarantees proven under realistic load |
| **Contracts verified** | Every Build3 boundary honored, including the unknown/absent case |
| **Trust metrics healthy** | The four absolutes (provenance completeness, unknown-preserved, abstention correctness, zero ceiling violations) are perfect; confidence calibrated. *Non-negotiable* |
| **Performance acceptable** | Hot paths within budget; recompute coalescing prevents storms |
| **Accessibility verified** | The Design5 interface constitution met across the release surface |
| **Documentation current** | Contracts, assumptions, failure modes, and operational notes accurate (Build4 Part VIII, Build5 Part XI) |
| **Migration complete** | Any V2→V3 or intra-V3 migration proven: recompute-never-trust, provenance preserved, no silent reinterpretation |
| **Observability ready** | The release's behavior — including its silence and its degradation — is observable in production (Build5 Part V) |
| **Recovery validated** | Every failure path proven to land in a defined, observable, floor-preserving state; rollback proven |

**The release-blocking rule:** the Trust-metrics row is *absolute* — a release with any Trust-Health regression does not ship, no matter how strong every other row is. The remaining rows block by severity, but none may be waived silently; a waiver is a governed exception with an owner and an expiry (Build5 Part IV).

---

## Part IV — Rollout Strategy

How Version 3 reaches users — a **ladder of expanding exposure**, where each rung earns the next. Risk rises as audience grows, so confidence must rise faster. Each stage defines its **purpose, risk, approval, and exit criteria.**

| Stage | Purpose | Risk | Approval | Exit criteria |
|---|---|---|---|---|
| **Internal builds** | Fastest feedback for engineers | Lowest — no real users | Engineering | Builds and passes validation |
| **Developer builds** | Prove the slice works end-to-end for those building it | Low | Engineering | Vertical slice complete; gates green |
| **Dogfooding** | The team lives with it on their own real data | Low-moderate — real data, trusted users | Engineering + feature owner | Honest and calm in real daily use; no trust anomaly |
| **Beta** | Real external users who opted into unfinished work | Moderate — real users, real trust at stake | Production owner | Stable trust/reliability metrics; no ceiling breach in the wild |
| **Limited rollout** | A small fraction of general users; measure at real diversity | Moderate-high — real users who did *not* opt into risk | Production governance | Trust and reliability within budget across a diverse small audience |
| **General availability** | The full user base | High — everyone's trust | Production governance | Sustained health at limited scale; readiness checklist fully green |
| **Emergency release** | Ship an urgent correctness/trust/privacy fix out of normal cadence | High — speed pressure invites mistakes | Production governance (expedited) | The specific defect fixed and proven; no new trust regression introduced |
| **Hotfix** | Narrowly patch a live production defect | High — minimal testing window | Production owner (expedited) | The defect resolved, reversible, with a follow-up to fold it into normal flow |
| **Rollback** | Return to the last known-good state | The safety net for all of the above | Production owner (immediate) | Users restored to a healthy, honest state; integrity re-verified |

**Governing rules:** (1) exposure only expands one rung at a time — no jumping from internal to GA. (2) Emergency releases and hotfixes are *narrow*: they fix one thing and carry the *same* Trust bar as any release — urgency never licenses shipping a new dishonesty. (3) Rollback is always available at every rung and is preferred over "explaining" a live trust regression (RP6, and the Production Constitution).

---

## Part V — Feature Flags & Controlled Exposure

How unfinished and experimental work stays safely hidden — without leaving permanent experimental code behind. Flags are a **temporary containment tool**, never a permanent architectural fixture.

- **When unfinished work stays hidden.** Any capability not yet through Internal Validation is invisible to users behind a flag. It may exist in the codebase (to keep slices integrating continuously, Build4 Part IV) but it does not reach a person until it has earned its lifecycle stage.
- **How experimental AI behaves.** Experimental AI stays *strictly* within the S4 reasoning-constitution contract even while behind a flag: it never breaches the ceiling, never invents confidence, always carries provenance, and degrades to determinism when uncertain. "Experimental" governs *exposure*, never *honesty* — there is no flag that turns off the ceiling.
- **How dangerous features stay isolated.** Any capability that could threaten trust, privacy, or the Record is isolated behind a flag *and* cannot affect the Record or one-way flow while experimental. Blast radius is contained by construction, not by hope. A flagged feature that could corrupt the Record is not flag-ready; it is not ready.
- **How long a flag may exist.** Every flag has an **owner and an expiration condition** the day it is created — it is temporary debt (Build5 Part IV) by definition. A flag is either promoted (its capability reaches Stable and the flag is removed) or retired (the capability is removed and the flag with it).
- **When a flag must be removed.** The moment its capability reaches Stable, or the moment its expiration condition fires. A flag that has outlived its condition is a drift signal, surfaced in the monthly architecture review (Build5 Part X).

**Rule — no permanent experimental code.** A flag with no expiry, or one that has quietly become load-bearing, violates the Operational Constitution ("every exception expires"). Version 3 does not accumulate a graveyard of dead flags and half-live experiments.

---

## Part VI — Migration & Compatibility

How Version 3 protects long-term users as it evolves. The governing principle is inherited directly from Build4 Part VII and made permanent: **recompute, never trust; preserve provenance; never silently reinterpret a user's past.**

- **How old data stays usable.** The Record is append-only and old facts remain readable forever (Build3). A user who has trusted LOCA for years never loses access to their history across a release. Backward readability of facts is a permanent guarantee, not a per-release effort.
- **How schema evolution is handled (conceptually).** Fact representations evolve *additively*: new fact shapes may be added; existing facts are never rewritten or reinterpreted in place. Old facts are read as they were recorded, with their original provenance intact. Evolution never mutates history.
- **How historical correctness is preserved.** Because understanding is a *projection* of facts (Build1), historical correctness is preserved by keeping the facts immutable and honest. A release may improve *how* the system reasons over history, but it never changes *what happened* — the facts are sovereign.
- **How recomputation occurs.** When reasoning improves, derivations and knowledge are **recomputed from the immutable Record** — never migrated from prior (possibly defective) derivations. This is idempotent and deterministic (Build2); replaying the same facts through the improved engine yields the same, better-reasoned result. This is how V2's F1–F8 defects were purged and how every future improvement propagates safely.
- **How incompatible assumptions are retired.** An assumption baked into old reasoning is retired by *not reproducing it* in the recompute — it simply ceases to exist unless the corrected engine re-derives it honestly from facts. Retirement is governed (Build5 Part IX) and, where it changes what a user sees about their past, honest and visible — never a silent rewrite of their story.

**The protection promise:** a long-term user's history only ever gets *more* honestly understood across releases, never quietly re-storied, and never lost.

---

## Part VII — Incident Response

The engineering philosophy for production incidents. Version 3's defining incident is unusual: its worst production failure is not downtime — it is a **quiet, confident wrongness a user believes.** Incident response is therefore tuned to detect and contain *trust* failures as urgently as availability failures.

### Severity levels
- **SEV-Trust (highest).** Any breach of the four absolutes in production — an invented value surfaced, provenance lost, honest abstention failed, or the ceiling breached (a verdict/trait/causation/prediction shown to a user). Treated as the most severe class *regardless of scale*, because a single user shown a dishonest claim is a fundamental failure.
- **SEV-Integrity.** Record corruption, backward flow, or a migration that silently reinterpreted history. Threatens the truth itself.
- **SEV-Reliability.** Crashes, data-access failures, or degradation that did not land in a defined floor state.
- **SEV-Degraded.** Performance, battery, or capability degradation within integrity but outside budget.

### Response framework
- **Ownership.** Every incident has one accountable owner from detection to postmortem — no anonymous incidents (mirrors Build5 Part XI).
- **Communication.** Honest, plain, and timely — to the team always, and to users when their trust or data was affected. Version 3 never hides a trust incident from the people it affected; that would compound the original dishonesty.
- **Investigation.** Grounded in observability (Build5 Part V) — the system's own signals explain what happened, including whether a silence was healthy or broken.
- **Containment.** Stop the harm first: pull the feature, flip the flag off, or roll back. Containment precedes root-cause; a live trust breach is contained before it is understood.
- **Recovery.** Return users to a defined, honest, integrity-preserving state — the "facts + reflection floor" is always available to fall back to (Build2, Build5 Part VI).
- **Postmortem.** Blameless, focused on the structural gap that let the incident happen, not on who typed it.
- **Learning.** Every incident produces a durable defense — a new property test, drift detector, readiness-checklist item, or tightened budget (feeds Part X and Build5 Part IX).

**The stance:** *roll back faster than you explain* — contain the harm to trust immediately; understand it thoroughly afterward; and ensure the system is stronger for having failed.

---

## Part VIII — Release Quality Metrics

What every release measures. Release quality is **measured, not assumed** — a release earns a scorecard, and a regression in any first-rank dimension blocks or reverts it. These compose the Build5 scorecard into a per-release readout.

| Dimension | What it proves for the release |
|---|---|
| **Reliability** | Failure rates within budget; recovery paths proven |
| **Trust** *(first-rank)* | The four absolutes perfect; confidence calibrated; abstention correct |
| **Performance** | Hot paths within budget; no unmeasured regression |
| **Battery** | On-device resource use within budget — a calm companion doesn't drain the phone |
| **Accessibility** | The interface constitution met across the release surface |
| **Regression** | Every prior behavior holds; every fixed defect still guarded (F1–F8) |
| **Privacy** | Consent boundaries and on-device guarantees intact; no new leak path |
| **AI behaviour** | Stays within the S4 contract; ceiling-respecting; calibrated |
| **User-visible correctness** | What a user sees is honest, provenance-backed, and within the ceiling |
| **Engineering health** | The Build5 scorecard trend is flat or improving — no release ships while decay accelerates |

**Rule:** the **Trust** and **Engineering-health** dimensions gate the release. A release that improved every performance number while regressing a Trust metric, or while accelerating architectural decay, is *not* a quality release — it is a fast step backward.

---

## Part IX — Production Governance

Who decides what, and when. Governance exists so that release decisions are **accountable and deliberate**, never a unilateral shortcut under deadline pressure. It extends Build5's governed-frozen stance into production.

- **Who approves releases.** Production governance — the accountable authority for the release surface — signs off against the Release Readiness checklist (Part III) and the Quality scorecard (Part VIII). No release ships without an explicit sign-off; silence is not approval.
- **Who approves hotfixes.** The production owner, on an expedited path — but the *same Trust bar* applies. A hotfix may compress the process; it may never compress integrity.
- **Who approves architectural exceptions.** Any deviation from a frozen contract (Build1–Build3) required to ship requires a governed exception with owner, rationale, scope, and expiry (Build5 Part IV) — and amends the relevant Build document first (Build5 Part IX). A frozen contract is never bent silently to make a release.
- **When a release is blocked.** Any unmet Release Readiness item, any Trust-metric regression, any open Critical drift, or any un-reversible change blocks the release — automatically and without negotiation.
- **When a rollback must occur.** The moment a production trust or integrity breach is detected (SEV-Trust or SEV-Integrity), rollback is initiated before root-cause analysis. Rollback is the default response to a trust breach, not a last resort.
- **Who owns production health.** A single accountable production owner owns the ongoing health of what users are running — the living counterpart to the engineering-health ownership in Build5. Production health is never ownerless.

---

## Part X — Post-Release Learning

Version 3 keeps learning after release. Production is the ultimate validation — it reveals truths that no internal testing can — and every production lesson must flow back into the phases that produced the system, or the same failure will recur.

Each production lesson is routed to where it can prevent recurrence:
- **Into Research.** Lessons about *people* — how users actually behave, misunderstand, or are harmed — feed the research corpus (R1–R10 method), correcting our model of the person LOCA serves.
- **Into Design improvements.** Lessons about *experience* — where the honest, calm design failed to land, or where the ceiling needed to hold firmer — feed Design (Design1–Design10), through governance.
- **Into Engineering improvements.** Lessons about *structure* — a boundary that eroded, a contract that was ambiguous, a determinism gap — feed the Build documents and the codebase (Build5 Part IX).
- **Into Operational improvements.** Lessons about *running the system* — a drift we detected too late, an observability blind spot, a budget set wrong — feed the operational discipline (Build5 Parts III–X).
- **Into Documentation updates.** Every lesson that changes a decision updates the governing document *in the same motion* — the documents never lag the running truth (Build5 Part XI).

**The guarantee against repeated failure:** no incident closes until its lesson has become a durable, structural defense — a test, a detector, a gate, a budget, or an amended document. A lesson that lives only in someone's memory is not learned; it is merely survived.

---

## Part XI — The Production Constitution

Immutable principles governing every Version 3 release. Where Build4's Implementation Constitution governs every line of code and Build5's Operational Constitution governs every year of operation, the Production Constitution governs every *act of shipping*. It is subordinate only to the LOCA Constitution (S7).

1. **Never ship known dishonesty.** A capability that invents, oversells, drops provenance, or breaches the ceiling does not ship — at any stage, behind any flag, under any deadline.
2. **Roll back faster than you explain.** A live trust or integrity breach is contained by rollback first and understood afterward.
3. **Every incident leaves the system stronger.** No incident closes without a durable structural defense against its recurrence.
4. **Experimental work is temporary.** Every flag has an owner and an expiry; no permanent experimental code, ever.
5. **Production is the ultimate validation** — and its lessons always flow back into Research, Design, Engineering, Operations, and the documents.
6. **User trust is never traded for release speed.** A date is never a reason to ship something that fails a Trust gate.
7. **Release quality is measured, not assumed.** Every release earns a scorecard; a Trust or engineering-health regression blocks or reverts it.
8. **Every release is reversible.** Un-reversibility is a release blocker, not a risk to accept.
9. **Every production change is explainable.** What a user sees can always be traced to their facts, with provenance and honest confidence.
10. **Every release improves integrity, or at minimum preserves it.** A release that trades any integrity for any convenience has failed its first duty.
11. **The Trust absolutes are absolute in production too.** Zero ceiling violations, complete provenance, unknown-preserved, honest abstention — no production reading other than perfect is ever acceptable.

This constitution governs every Version 3 release. A release that ships on time, delights on first glance, and passes every performance target but violates one of these principles has not shipped Version 3 — it has shipped the erosion of the trust Version 3 exists to protect.

---

## Closing — What Build6 Delivered

Build6 defined the **Production Engineering Manual** that carries Version 3 safely from engineering to a trusted, living product:

- a **release philosophy** (Part I) — correct before complete, trust before novelty, integrity improved every release, reversibility as a precondition;
- a **feature lifecycle** (Part II) — ten stages, each with entry/exit/ownership/success, and free backward movement the instant trust is threatened;
- a **release readiness framework** (Part III) — a ten-area checklist with an absolute Trust gate;
- a **rollout strategy** (Part IV) — a nine-rung exposure ladder, one rung at a time, rollback always available;
- **feature flag governance** (Part V) — containment that is always temporary, honesty that is never flagged off;
- a **migration philosophy** (Part VI) — recompute-never-trust, immutable facts, no silent re-storying of a user's past;
- an **incident response framework** (Part VII) — SEV-Trust as the highest class, contain-before-explain, blameless learning;
- a **release quality scorecard** (Part VIII) — ten dimensions, Trust and engineering-health gating;
- **production governance** (Part IX) — accountable sign-off, expedited-but-not-compromised hotfixes, rollback-on-breach;
- a **post-release learning framework** (Part X) — every lesson routed back to Research, Design, Engineering, Operations, and the documents;
- the **Production Constitution** (Part XI) — 11 immutable principles over every act of shipping.

It answers *"How do we safely ship and continuously improve LOCA Version 3 in production?"* — with no Swift, no APIs, no CI/CD, no deployment scripts, and no infrastructure detail.

Everything here is consistent with Research (R1–R10), Synthesis (S1–S7), Design (Design1–Design10), Build1, Build2, Build3, Build4, and Build5. Nothing was redesigned; no subsystem boundary moved; no feature was introduced.

**Stop here; do not begin Build7. Build6 is ready for review.**
