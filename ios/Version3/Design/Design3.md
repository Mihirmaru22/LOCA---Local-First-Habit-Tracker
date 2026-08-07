# LOCA Version 3 · Design Phase
## Design3 — Information Architecture

> **The single question Design3 answers:** *How should information flow through LOCA — where does every piece belong, how does it move, and how does it transform over time?*
>
> This is the architecture of **knowledge itself**, independent of how it is ever displayed. It contains **no UI, no implementation, no database schema, no Swift, no screen layouts, no navigation.** Every conclusion is consistent with the frozen foundation — Phase R (R1–R10), Phase S (S1–S7), Design1 (product architecture), and Design2 (experience architecture) — and draws especially on **S4** (the evidence, confidence, and inference hierarchies), **S5** (knowledge lifecycles, memory, forgetting), and **S2** (the three strata).
>
> **What Design3 fixes:** every future engineering decision must be able to trace its data flow back to this document. Design3 defines how a fact enters, what it may become, what it may never become, when it decays, and how any conclusion can be traced back to its evidence.

---

## Part I — The foundational flow (the spine)

All information in LOCA lives on **one spine and two axes**, derived directly from Phase S.

**The spine — the three strata (S2):**
- **The Record** — raw, truthful, timestamped, provenance‑bearing facts. *Immutable and permanent.*
- **The Reflection** — derivations that turn the record into honest, hedged material for meaning. *Provisional and decaying.*
- **The Understanding** — the person's own meaning. *Sovereign; the system serves it, never writes it.*

**The two axes crossing the spine:**
- **The vertical axis — the Knowledge Hierarchy** (Part II): how raw information rises toward understanding, gated by evidence, and *capped by the ceiling* (no verdicts, traits, causation, prediction).
- **The horizontal axis — Time** (Part V): how information gains or loses value, decays, or persists, across minutes to years.

**The one invariant that governs everything (from S5):** *the Record is permanent and never changes; everything derived from it is provisional and may strengthen, weaken, decay, or be corrected.* Every rule in this document is a consequence of this invariant. **Information enters LOCA as exactly one of two things:** a **fact** (into the Record) or a **derivation** (into Reflection/Understanding). Facts are kept forever; derivations live and die by their evidence.

---

## Part II — The Knowledge Hierarchy

Not all information is equal. It rises through levels, each demanding more evidence and confidence, and the system may only *assert* up to a hard line — above which meaning belongs to the person.

```
L0  RAW SIGNAL        a sensed or logged input, unprocessed
      ↓  (record it, with provenance)
L1  FACT              what happened — recorded/confirmed          [CERTAIN · the Record]
      ↓  (derive a single reading, hedged)
L2  OBSERVATION       one derived reading, with confidence         [hedged]
      ↓  (corroborate across independent observations)
L3  EVIDENCE          observations that agree                      [strengthening]
      ↓  (repeat within-person, across contexts, over time)
L4  PATTERN           a corroborated within-person regularity      [the highest the SYSTEM may assert]
─────────────────────────  THE ASSERTION LINE  ─────────────────────────
L5  UNDERSTANDING     the person's own meaning, made from L1–L4    [CO-AUTHORED · person leads]
─────────────────────────  THE CEILING  ────────────────────────────────
✗   VERDICT · TRAIT · CAUSATION · PREDICTION · IDENTITY · "WISDOM-as-claim"
      the system never produces these — they belong to the person, or to no one
```

**Movement between levels:**
- **Up requires evidence.** L0→L1 requires capture with provenance. L1→L2 requires a defensible derivation. L2→L3 requires independent corroboration. L3→L4 requires repetition, within‑person, across contexts, over time (S4 Ev.4).
- **The system asserts only to L4.** It may state facts (L1) plainly and offer observations/patterns (L2–L4) hedged and provenance‑bearing. **L5 (Understanding) is the person's** — the system supplies the material (L1–L4) and the reflection space; the person makes the meaning (P1; S2).
- **The ceiling never opens.** No amount of evidence promotes a pattern into a verdict, a trait, a cause, or a prediction. "Wisdom" is the person's summit, never a system output. *(S4 ceiling; S7 Art. VIII.)*

**Confidence requirements per level:** L1 certain; L2 tentative→probable by evidence; L3 rising; L4 probable only when strongly corroborated. Below the required confidence, information *stays at the lower level or abstains* — it never gets promoted to look more certain than it is. *(S4 Part III.)*

**Failure conditions:** insufficient evidence → remain low or abstain ("not enough to say yet"); contradiction → drop confidence or abstain and record the conflict; correction → the derived level is overridden by the person. Failure is never "guess to fill the gap" (that is the F1 sin). *(S4; S5.)*

---

## Part III — The Information Lifecycle (per type)

Every input type, with: where it **enters**, how it **evolves**, what it **influences**, what it **may never influence**, when it **expires**, and whether it becomes **permanent knowledge.**

| Type | Enters as | Evolves into | Influences | Never influences | Expires / decays | Permanent? |
|---|---|---|---|---|---|---|
| **Habit log** | Fact (Record) | consistency (derived fact); evidence for habit‑patterns | habit understanding, identity *reflection*, patterns (as one signal) | a mood/state as a proxy beyond its own dimension; any trait; causation | fact never expires; "current habit" status decays if logging stops | Yes (as fact); habit‑as‑current is provisional |
| **Journal entry / reflection** | Fact — the person's own words & meaning (Record; Stratum 2/3) | the person's authored story; recall material | Understanding (as the person's *own* meaning — high authority); People (names, with consent) | inferred state as if it were measurement; never overwritten by the system | never | Yes |
| **State check‑in** | Fact — explicit input (high authority) | ground truth for calibration; evidence for state patterns | state understanding, calibration, patterns | a trait; a verdict | the *reading* is momentary; calibration value persists | Yes (as fact); current‑state is momentary |
| **Calendar event** | Sensed signal (consent‑gated) | context (busyness/social); evidence for People | stress/social context (hedged); People | a confident state claim alone; a relationship's *nature* (confirmation‑only) | as live context, decays; as a past event, kept if relevant | No (context transient); event kept per retention |
| **Health signals (sleep, exercise, HR/HRV)** | Sensed signal (consent‑gated, reliability‑tagged) | baseline‑relative context; evidence for health/state patterns | state understanding (hedged, baseline‑relative); health patterns | a single day → a trait; clinical claims; causation | raw samples age; baselines adapt | Baselines evolve (not permanent); samples kept per retention |
| **Location signal** | Sensed (consent‑gated) | mobility/context; environments | environment understanding; mobility‑as‑context (hedged) | confident mood claims; anything surveillant | context transient | No |
| **Goal** | Fact — user‑authored (confirmation‑only; never inferred) | part of Direction; a lens for reflection | reflection framing, Reviews | judgment (divergence is reflected, never judged) | completes or expires → retired to "past goals" | Kept in record as past |
| **Direction** | Fact — user‑authored | the person's stated where‑heading; trajectory context | reflection, Reviews, trajectory context | prescription | updated by the person → old becomes "past direction" | Kept |
| **AI observation** | Derivation (L2, hedged, provenance‑bearing) | evidence → pattern (if corroborated) or decays | the Understanding surface (hedged) | the Record (never written into facts); a verdict | decays if unsupported; overridden by correction | No — provisional |
| **Pattern** | Derivation (L4, corroborated) | a stable hedged observation; may inform Reviews/Ask | Understanding (hedged); trajectory context | a trait; a cause; the Record | decays if it stops recurring; re‑examined each period | No — provisional |
| **User correction** | Fact (highest authority) + control signal | overrides the corrected belief; retained as a guard against re‑learning | everything it corrects (immediately); calibration | the Record's facts (a corrected *interpretation* never rewrites what happened; a corrected wrong *entry* fixes that one entry) | never (the correction is kept) | Yes |
| **Life event** | Derivation (candidate landmark) → confirmed by the person | a Timeline landmark; may open a chapter / reset baselines *once confirmed* | chapters, baselines (on confirmation), reflection | a unilateral reset without the person's confirmation | landmark persists in the record | Yes (once confirmed) |
| **Chapter** | Derivation → user‑confirmable segmentation | continuity structure; per‑chapter baseline context | interpretation framing, Timeline | a verdict; a unilateral identity claim | historical chapters persist; "current chapter" updates | Yes (as record structure) |
| **Trait** | *not a stored type* | — | — | — | — | **No — traits are not a knowledge category (Design1). Tendencies live only as hedged L4 patterns.** |
| **Relationship** | Derivation (recurring presence, consent‑gated) + user confirmation for *nature* | a person‑in‑your‑life node (salience, provenance) | People understanding; context | the relationship's *nature* without confirmation; any CRM/social use | salience decays with absence | Kept in record; salience provisional |
| **Memory** | *is* the Record (episodic facts) | revisitable record; nostalgia cues | reflection, continuity | being overwritten by a system narrative | never | Yes |
| **Question** | User input — self‑inquiry (transient intent) | an Answer; optionally a saved view | reflection; may signal interest (could seed Direction, with the person's intent) | a stored belief about the person (a question is not evidence about them) | the question is a moment; saved views persist if kept | Only if the person saves it |
| **Answer** | Derivation — composed at answer‑time from Record + hedged L1–L4 | a saved artifact (if kept) | reflection | becoming a "fact" about the person (it is re‑derivable, not evidence) | re‑derivable; saved copies persist | Only if saved |
| **Conversation (Ask session)** | Transient interaction | nothing, unless the person makes an explicit statement/correction (which enters as Fact) | reflection in the moment | rewriting years of evidence; becoming belief on its own | transient | No (only explicit statements within it persist, as facts) |

**Two lifecycle laws visible across the table:**
1. **Facts and the person's words/corrections are permanent; system derivations are provisional.** *(S5.)*
2. **Nothing the system derives is ever written back into the Record.** Interpretation flows *up* from facts; it never flows *down* to alter them. This one‑way flow is what keeps the record trustworthy and prevents a narrative from corrupting memory (R2 Schacter; P6).

---

## Part IV — The Information Relationship Map

How types influence each other — and, as importantly, the **boundaries** on that influence. Influence always flows *upward through evidence* (L0→L4), never downward into facts, and is always *gated*.

**Permitted influences (all hedged, evidence‑proportional):**
- **Sleep / exercise / activity → state understanding** — yes, baseline‑relative and hedged (R8 high‑signal). Never a confident or causal claim from one day.
- **Habits → patterns & identity reflection** — yes, as evidence and as the person's identity material (S5). Never habits → a fixed trait.
- **Journal entries → Understanding & People** — yes; the person's own words are high‑authority meaning, and may surface named people (with consent). Never journal → an inferred *sensor‑grade* state (words are meaning, not measurement).
- **Calendar → stress/social context & People** — yes, hedged, consent‑gated. Never calendar → a relationship's nature without confirmation.
- **Chapters → interpretation framing** — yes; a chapter provides the baseline context an observation is read against (a mood is read relative to *this chapter's* baseline). Never a chapter → a verdict.
- **Confirmed life events → baselines & chapters** — yes, but only on the person's confirmation of significance (S5).
- **Relationships → context** — yes, hedged, consent‑gated; the person's time with people is context for reflection. Never a CRM.
- **Direction / goals → reflection framing** — yes; the person's stated direction frames what reflection attends to. Never → judgment when behavior diverges (it is reflected, not scored).
- **User correction → everything it touches** — yes, with highest authority, immediately.

**Forbidden influences (the boundaries — Part VII expands):**
- **Nothing → a trait.** Traits are not a knowledge type; no input produces one.
- **No single day / event → long‑term understanding or identity.** One data point never moves a stable belief (Part VII).
- **No derivation → the Record.** Interpretation never rewrites facts.
- **No conversation/answer → stored belief.** Only explicit statements/corrections persist.
- **No sensed signal → a causal claim about the person's life.** Association only (R4 Pearl; S4).
- **No influence across the ceiling.** Ever.

**The answers to the map's guiding questions:** *Can habits influence traits?* No — there are no traits, and habits inform only hedged patterns and identity *reflection*. *Can journal entries influence patterns?* Yes, as the person's own meaning, high‑authority. *Can sleep influence mood?* Yes — as hedged, baseline‑relative context, never as a confident cause. *Can relationships influence goals?* Only through the person's own reflection; the system never rewires goals. *Can chapters influence interpretations?* Yes — a chapter sets the baseline an observation is read against. *Can life events reset previous understanding?* Only *confirmed* significant events, and only the person confirms them.

---

## Part V — The Time Model

How information behaves across time — the horizontal axis.

| Horizon | What lives here | Behavior |
|---|---|---|
| **Minutes / hours** | raw signals, the current moment | high immediacy, low permanence; most is transient context that never becomes belief |
| **Days** | recent readings, short‑term understanding | provisional; corroborates or decays quickly |
| **Weeks** | forming baselines, corroborating patterns | consolidates (esp. at the weekly Review); confidence begins to be earnable |
| **Months** | long‑term understanding, chapters, stable tendencies | matured, hedged; baselines settle |
| **Years** | the compounding record; nostalgia; continuity; legacy | the record's value peaks; understanding is deep but held humbly |

**What gains value with time:** the **Record** (nostalgia, continuity, legacy — R2/R10) and *well‑corroborated* understanding. **What loses value:** raw signals as live context (they age out) and *unsupported* beliefs (they decay). **What decays:** every derivation not re‑corroborated, at a rate matched to its volatility (S5). **What remains forever:** the Record — facts, the person's words, corrections (unless the person deletes them). **What is archived:** old raw signals may be summarized/aged as *live context* while the *events themselves* are kept. **What stays immediately accessible:** the person's own facts, the recent record, current understanding, and — always — the ability to inspect and correct.

**The time law:** *derivations decay; the record appreciates.* Time is the force that separates the provisional from the permanent — it erodes stale beliefs and enriches the truthful record.

---

## Part VI — The Knowledge Evolution Model

Every important knowledge type moves through the same six stages (S5 applied to information flow):

1. **Birth** — a first observation forms a hypothesis (L2). *Trigger: one piece of evidence.*
2. **Growth** — repetition and corroboration raise it toward a pattern (L2→L4). *Trigger: independent, within‑person repetition.*
3. **Validation** — the person confirms it, or strong corroboration + calibration against check‑ins support it. *Trigger: confirmation or calibrated corroboration.*
4. **Maturity** — a stable, hedged pattern held with earned confidence (L4). *Trigger: sustained support.*
5. **Decay** — evidence ages or stops; confidence weakens back toward hypothesis. *Trigger: staleness, or the pattern ceasing to recur.*
6. **Retirement** — the belief drops from the *live* model (kept in history); the *record* it was built from remains. *Trigger: sustained non‑recurrence, a confirmed life change, or correction.*

**What moves knowledge forward:** independent, recent, within‑person evidence, and the person's confirmation. **What reverses progress:** contradiction, staleness, and correction (each lowers confidence or retires the belief). **What permanently changes understanding:** the person's correction (authoritative and kept) and *confirmed* significant life events (which may reset baselines and open a chapter). **What can never happen:** a belief maturing into a verdict/trait/cause — maturity tops out at a hedged L4 pattern. Evolution is a loop, not a ratchet: knowledge can move backward (decay, retirement) as readily as forward, and only facts and corrections are exempt.

---

## Part VII — Information Boundaries (the anti‑overreaction rules)

Not everything may influence everything. These boundaries prevent the system from over‑reacting to single events — the most important safety property of the whole architecture (F1; R2 Learned Optimism; S5).

- **One emotional day never changes "personality."** A mood is L2 at most; it never rises to a trait (no trait exists), never touches identity, and requires sustained cross‑context repetition to become even a hedged tendency. *(S5; the ceiling.)*
- **One missed habit never redefines "discipline."** A single lapse is one data point; consistency is a corroborated pattern; a lapse adjusts a neutral consistency figure but never a characterological judgment (which the system never makes anyway). *(P8, P11.)*
- **One stressful week never redefines identity.** A week is short‑term; identity is years‑long and person‑authored; the two are separated by the assertion line and the ceiling. *(S5.)*
- **One conversation never rewrites years of evidence.** Answers are re‑derivable compositions; only an explicit *correction/statement* the person makes persists, and even that overrides a *belief* (with history preserved), never the *record*. *(S5; P6.)*

**The general boundary rules (derived):**
1. **Evidence‑proportional influence** — influence scales with corroboration; a single instance moves nothing stable.
2. **The ceiling** — nothing ever becomes a verdict, trait, cause, or prediction.
3. **Volatility‑matched inertia** — the more stable the knowledge, the more evidence required to move it (identity resists single events; a mood does not).
4. **Confirmation for significant resets** — only the person confirms a turning point; the system never unilaterally declares a life changed.
5. **Recency‑weighted, not recency‑dominated** — recent evidence counts more, but one recent instance is never decisive.

These rules are the structural guarantee against the exact failure that plagued Version 2: a thin or single signal producing a confident, sweeping claim.

---

## Part VIII — The Explainability Framework

Because the Record is immutable and every derivation carries its lineage, **every conclusion in LOCA is traceable by construction** (Kleppmann's log→views; S4; S6). This is an architectural property, not a feature.

- **Trace an insight → its evidence → the raw facts.** Every derived node (observation, pattern, answer) holds pointers to the L1 facts that formed it; the chain is always walkable down to the record. *(P4.)*
- **Inspect supporting *and* conflicting evidence.** A conclusion carries both what supports it and what contradicts it; conflict is shown, never hidden. *(S4; S6.)*
- **Challenge any conclusion.** The person can correct any derived belief; correction is authoritative and immediate (Part III). *(P5, P12.)*
- **See confidence evolution.** Every belief carries a history of how its confidence rose and fell as evidence accrued and aged. *(S4/S5.)*
- **Understand why something changed.** Belief changes are recorded with their cause ("this changed because you corrected it / because it stopped recurring"), never silently swapped. *(S5; S6.)*

**How explainability lives in the IA:** it is not a layer added on top — it is the *shape* of the information itself. A derivation that cannot name its evidence is malformed and may not exist; a claim that cannot be explained faithfully may not be made. Explainability is a precondition of a claim's existence, not a report about it.

---

## Part IX — The Information Quality Framework

Every piece of information carries a quality status that governs how it may be used:

- **Strong information** — multiple, independent, reliable, corroborated, recent, within‑person. *May support higher‑level (up to L4) claims.* *(S4 Ev.4.)*
- **Weak information** — single‑source, noisy, short‑window, low‑reliability. *Hypothesis‑grade only (L2); never supports a confident claim.* *(S4 Ev.5.)*
- **Conflicting information** — genuine disagreement between sources. *Lower the confidence; record the conflict; the higher authority wins (person > sensor); abstain if conflict remains.* *(S4; S6 SensorConflict.)*
- **Missing information** — absent. *Unknown, never low; lowers confidence toward abstention; never filled with a guess.* The single most important quality rule (the F1 fix). *(R8; S4.)*
- **Outdated information** — aged past its subject's volatility. *Decays in influence; retired when stale.* *(S5.)*
- **Incorrect information** — wrong. *If a wrong belief: corrected → removed from the live model, correction retained to prevent re‑learning. If a wrong fact (bad entry): the person fixes that entry — the one case a fact changes.* *(S5; P12.)*

**The quality law:** *the system's confidence in anything is a function of the quality of the information beneath it.* Strong information licenses hedged claims; weak, missing, or conflicting information licenses only hypotheses or silence. Quality gates confidence, and confidence gates what may be said (S4).

---

## Part X — The Information Flow Blueprint (the whole picture)

Seen whole, information moves through LOCA like this:

> Every input **enters as a fact or a derivation.** Facts — the person's logs, words, check‑ins, goals, corrections, and confirmed events — flow into the **Record**, where they are kept faithfully, forever, with their provenance, and are never altered by anything the system infers. Derivations — observations, patterns, answers — rise *upward* from those facts through the **Knowledge Hierarchy**, gaining confidence only as independent, within‑person, recent evidence corroborates them, and are held **provisionally**: they strengthen, weaken, decay, and retire as the evidence changes, and they are overridden the instant the person corrects them. This upward flow is **capped by the ceiling** — no evidence ever produces a verdict, a trait, a cause, or a prediction — and the summit above the assertion line, **Understanding**, belongs to the person, who makes the meaning from the material the system honestly supplies. **Time** runs through the whole structure, eroding stale derivations and enriching the permanent record. **Provenance** threads up every derivation so any conclusion can be traced back to the facts that formed it. **Boundaries** gate every influence so that no single day, week, or conversation can overturn what years of evidence and the person's own word have established. And nothing — ever — flows *downward* to rewrite the truth of what happened.

**The blueprint's five invariants:** (1) the Record is permanent and never altered by derivation; (2) information rises through evidence and is capped by the ceiling; (3) derivations are provisional and decay; (4) every conclusion is traceable to its facts; (5) the person's word overrides any inference and their meaning sits above the system's reach.

---

## The information architecture, in one statement

> **Inside LOCA, truth flows in one direction and meaning in the other: facts enter the permanent, immutable Record and never change; honest, hedged interpretations rise from those facts through a hierarchy gated by evidence and capped by a ceiling that forbids verdicts, traits, causes, and predictions; every interpretation is provisional — strengthening, decaying, and retiring as evidence changes, and overridden the moment the person corrects it — while the Record it was built from is never touched; time erodes the stale and enriches the true; every conclusion carries its lineage so it can always be traced back to what actually happened; strict boundaries ensure no single day or conversation can overturn years of evidence; and the summit — the meaning of a life — is reached by the person, from material the system supplies but never presumes to conclude.**

This information architecture is the frame every subsequent Design and engineering decision must honor. Design4 onward may specify *how information is captured, computed, and surfaced* — but may not violate the one‑way flow (derivation never rewrites the Record), the ceiling, the boundaries, or the traceability guarantee.

---

*Design3 complete. The complete information architecture, information lifecycle, knowledge hierarchy, information‑relationship map, time model, knowledge‑evolution model, information‑quality framework, explainability framework, information boundaries, and information‑flow blueprint are defined and derived entirely from Phase R, Phase S, Design1, and Design2. No UI, implementation, database schema, Swift, layouts, or navigation were specified. Stop here; do not begin Design4. Design3 is ready for review.*
