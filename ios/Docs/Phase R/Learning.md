# Phase R — Learning & Research

> **Mission:** Become an expert in building a personal life‑intelligence product *before* making architectural decisions. The output of this phase is research, principles, and design knowledge — **not code**.
>
> **Status of the current app:** Treated as **Version 2.5**, not the final architecture. Everything is open to question.
>
> **Grounding:** This research is anchored to the code‑verified findings from the D1–D4 audit (see the audit thread). Every "Lessons for LOCA" block ties back to those findings so research stays concrete, not generic.

---

## The D‑ledger this phase must serve

| D | Category | One‑line problem (verified in code) |
|---|---|---|
| **D1** | User Value | Sophisticated backend, little value returned; Life tab doesn't justify itself. |
| **D2** | Provenance & Trust | User can't tell where anything came from (e.g. seeded "Sarah"/"Alex"). |
| **D3** | AI Honesty & Presentation | Confident prose over thin data; computed provenance/confidence is discarded. |
| **D4** | Inference & Model Correctness | The number is wrong *before* the UI: weight non‑renormalization (F1), dimension contamination (F2), mood‑only patterns (F3). |

---

## Task map

| Task | Focus | Question it must answer | D‑link | Deliverable |
|---|---|---|---|---|
| R1 | Existing products | Why do people open a life app *daily*? | D1 | Comparison matrix + per‑product deep dive (see `R1.md`) |
| R2 | Human psychology | What actually helps a person understand their life? | D1 | Notebook + lessons |
| R3 | Behavioral science | How to help without manipulating? | D1, D3 | Notebook + lessons |
| R4 | AI for personal intelligence | How do real memory/uncertainty/provenance systems work? | D3, D4 | Notebook + lessons |
| R5 | Design | Show complexity without overwhelming? | D1, D3 | Notebook + lessons |
| R6 | Onboarding | What value on Day 1 / 7 / 30 / 180? | D1 | Onboarding model |
| R7 | Trust | How to never sound more certain than the evidence? | D2, D3 | Trust model |
| R8 | Personal data | Which signals predict outcomes; which are noise? | D4 | Data‑value ranking |
| R9 | Failure | Why did quantified‑self products die? | D1 | Abandonment patterns |
| R10 | Synthesis | What should LOCA become / never become? | All | V3 Design Principles |

The full in‑depth **R1** lives in `Docs/Phase R/R1.md`. R2–R10 are summarized below and will be expanded into their own docs as the phase proceeds.

---

## R1 — Existing Products (summary; full version in R1.md)

**The pattern behind every daily‑opened survivor:** they deliver **one legible, personal, decision‑relevant artifact** — Oura's Readiness, WHOOP's strain target, Rise's sleep debt, Finch's pet, Daylio's streak. None narrate the user's inner state as fact. The interpreters (Oura/WHOOP) always show **baseline + contributing factors** and earn the number with dense passive physiological data first.

**The pattern behind every death** (Google Now, Human, Moves, Jawbone, Basis): opaque prediction, or capture without synthesis, or hardware dependence, or effort > payoff.

**Lessons for LOCA**
- LOCA has **no single legible daily artifact** → root of **D1**.
- Survivors show baseline + contributing factors; LOCA computes `InferenceProvenance` (sources, sampleCount) then **discards it** (F8/D3).
- Apple Health's source‑label‑on‑everything is the antidote to **D2**.
- Oura/WHOOP earn their score with dense passive data; LOCA emits a four‑dimension inner‑state model from **habit checkboxes**, which is why F1 deflation is catastrophic — the signal isn't there to justify the claim.

---

## R2 — Human Psychology

- **Reflection > dashboards.** Expressive‑writing and life‑review research: insight comes from the *person articulating* their experience, not from being told "mood 0.3."
- **Self‑perception theory (Bem):** people infer attitudes from their own behavior. Reflect behavior back accurately; don't compete for authority over inner state.
- **Identity‑based habit (Clear/Wood):** durable change is "I am the kind of person who…", not metrics.
- **Reconstructive memory (Loftus):** a truthful timestamped record corrects memory; a second inferred narrator competes with it.
- **Negativity bias:** an inaccurate negative reading ("mood much lower," F1) harms more than a positive one helps.

**Lessons for LOCA:** the defensible asset is the **truthful behavioral record** (FACT/USER DATA). Inferring inner state from checkboxes is an authority contest LOCA can't win → reframes D4 as "should these four dimensions exist on the habit‑only path at all?" Highest‑value move: convert data into **well‑timed reflection prompts**, not verdicts.

---

## R3 — Behavioral Science

- **Personal Informatics model (Li/Dey/Forlizzi):** Preparation → Collection → Integration → Reflection → Action. LOCA over‑invests Collection/Integration, under‑invests Reflection/Action → exactly D1.
- **Quantified Self wisdom:** durable tracking ties to a *specific question*; "track everything" burns out. LOCA's Ask is aligned — *if* it answers.
- **Persuasive tech, read critically (Fogg → Humane Tech):** help the user pursue *their* goal; don't manufacture engagement. Direction is the ethical anchor.
- **Self‑Determination Theory (Deci/Ryan):** autonomy/competence/relatedness. Verdicts erode autonomy; accurate feedback builds competence.

**Lessons for LOCA:** shift investment to Reflection/Action; anchor to a user question/Direction; treat honest uncertainty as a **trust asset**, not a UX problem.

---

## R4 — AI for Personal Intelligence

- **Memory/PKM:** durable personal AI = **temporal knowledge graph** (entities, timestamped events, typed relations) where every node carries **source + confidence + last‑updated**.
- **Provenance & epistemics:** best practice is *provenance‑by‑construction*. LOCA computes provenance then discards it (F8) — the inverse.
- **Uncertainty/confidence:** communicate in **calibrated, legible words** ("likely," "some evidence," "not enough data yet"); widen when thin. LOCA's `UncertaintyCalculus` is an asset the UI ignores.
- **Causal vs correlational:** never overclaim causation; surface correlational + user‑verifiable. `PatternDetectionEngine` language is right in spirit; defects are mood‑only (F3) + hidden confidence.
- **Human‑as‑corrector:** AI proposes, user confirms/denies, corrections feed back. LOCA has `FeedbackProcessor`/`SensorConflict` but no visible loop.

**Lessons for LOCA:** adopt provenance‑and‑confidence‑by‑construction; make the correction loop visible; prefer **retrieved specifics over inferred scores** (sidesteps F1).

---

## R5 — Design

- **Progressive disclosure (HIG):** conclusion → drill to evidence. LOCA's Reach gesture is aligned; needs the evidence layer.
- **Calm technology (Weiser/Brown):** interrupt only when worth it. Prose that says "steady" violates this.
- **Empty‑state design:** LOCA's `LifeReadEmptyCard`/`LifeEmptyState` are genuinely good — preserve.
- **Information hierarchy:** summary first; state encoded in form (chips/severity), not just number. Leading with prose gives no scannable hierarchy → D1.
- **Trust design:** source, freshness, confidence, correction (Apple Health reference).

**Lessons for LOCA:** keep empty states; add a **scannable daily summary object** above prose with drill‑to‑evidence; adopt **calm‑tech gating** (today `PresentComposer` always emits a headline regardless of confidence — F8).

---

## R6 — Onboarding

Shape of great onboarding: **ask little, infer nothing risky, postpone permissions to the moment of value, deliver something Day 1.**

| Horizon | Great onboarding | LOCA today |
|---|---|---|
| Day 1 | Immediate win + "what's coming" | Habit logging instant (good); no Life win |
| Day 7 | First baseline / honest pattern‑in‑progress | Today's Read deflated/misleading (F1) |
| Day 30 | First real correlations, first chapter | Possible *if* inference fixed |
| Day 180 | A life record worth revisiting | Strongest potential; depends on truthful record |

**Lessons for LOCA:** ask **one Day‑1 question** ("What do you want to understand about yourself?") → seeds Direction + Ask + engine intent. **Postpone** HealthKit/Calendar to the first visible payoff and **name it** ("Grant Calendar → see who you spend time with") — fixes People‑empty confusion (D2/F7). Make the Day‑7 promise truthful.

---

## R7 — Trust

Earned by **progressive confidence**: say less early, more later, always show the ladder. Reference behaviors: provenance (Apple Health), calibrated words (Tetlock), evidence on demand (Perplexity/Arc citations), user correction, freshness + data‑density disclosure, and the cardinal rule — **never exceed the evidence.**

**Lessons for LOCA:** LOCA structurally violates the cardinal rule (F1 deflation + F6 placeholder baseline + F8 discarded evidence). Institute a **trust contract**: every Life statement renders origin, a confidence word from `UncertaintyCalculus`, tap‑through evidence, and a "that's wrong" correction. The backend already has the pieces.

---

## R8 — Personal Data: signal vs noise

- **High signal:** sleep (esp. regularity), physical activity, social interaction, sunlight/outdoors, **explicit mood/notes.**
- **Medium:** HRV/resting HR, calendar density, location variety.
- **Low/noise alone:** step‑count‑as‑mood, screen‑time‑as‑focus, single‑day HRV, and **habit‑checkbox‑completion as an emotional‑state proxy.**

**Lessons for LOCA:** the most predictive available signal is the **explicit note + mood micro‑check‑in** — and the note→People path is broken (F4), while notes feed only a 7‑word lexicon (`simpleSentimentScore`). Habit completion is being over‑asked to carry inner‑state inference (D4 root). Sleep regularity + social interaction are high‑value and largely uncollected.

---

## R9 — Failure

- **Human, Moves:** passive capture, no synthesis, no reason to return → novelty churn.
- **Jawbone, Basis:** hardware dependence + device failures.
- **Google Now:** opaque prediction → distrust.
- **Generic mood trackers:** effort > payoff.
- **Gyroscope‑style aggregators:** dashboards aren't decisions.

**Recurring abandonment:** effort in > value out; opacity → distrust; novelty without compounding; no daily decision‑relevant artifact.

**Lessons for LOCA:** exposed to **all four** modes today. The compounding, churn‑resistant asset is the **truthful long‑term record** (Day‑180 value). Lead with it.

---

## R10 — Synthesis

### Recurring principles
1. One legible, personal, decision‑relevant artifact per day beats a rich backend.
2. Provenance and confidence by construction.
3. Never exceed the evidence; stay quiet when uncertain.
4. Reflect behavior; don't narrate inner state without earned signal.
5. The user is the authority; the AI proposes, the user corrects.
6. Invest in Reflection/Action, not more Collection/Integration.
7. Anchor to a user goal/question.
8. Postpone permissions to visible payoff; name the payoff.
9. The truthful long‑term record is the compounding asset.
10. Retrieved specifics > inferred scores.

### Anti‑patterns
- Confident prose over thin/deflated data (F1+F8).
- Inferring four emotional dimensions from checkboxes (D4 root).
- Discarding computed provenance/confidence (F8).
- Seeded entities indistinguishable from real (Sarah/Alex — F7).
- Attention‑costing prose/notifications that return "steady."
- Dashboards mistaken for insight.
- Hardware/permission dependence without payoff.
- Gamification substituting for value.

### V2.5 ideas: survive / redesign / delete
- **Survive:** truthful habit record; honest empty states; Direction; Ask (question‑first); `UncertaintyCalculus`, `InferenceProvenance`, `FeedbackProcessor`, `SensorConflict` (backend assets); Reach progressive disclosure.
- **Redesign:** Today's Read → evidence‑linked, confidence‑gated artifact; People → provenance‑labeled + Calendar‑payoff framing + fixed note path; Patterns → all dimensions + confidence + user‑verifiable.
- **Delete (as conceived):** four‑dimension inner‑state inference from checkbox‑only data; any surface rendering a state number without evidence; the discarded‑provenance headline path.

### What LOCA should become
> A truthful, provenance‑first personal life record that turns your own behavior and chosen signals into well‑timed reflection — **never a confident narrator of your inner state.** It earns interpretive claims only where it has earned signal (explicit check‑ins or passive physiology), always shows why, and gets smarter when you correct it.

### What LOCA must never become
> An opaque oracle that tells you how you feel, manufactures engagement, hides uncertainty, or presents seeded/inferred data as fact.

### Falsified assumptions
- "A sophisticated backend creates value." (No — the artifact does.)
- "We can infer emotional state from habit logs." (Signal isn't there.)
- "Prose is the right daily surface." (No scannable hierarchy/decision.)
- "Provenance is later polish." (It's the trust foundation.)

### Validated assumptions
- Truthful behavioral record is valuable.
- Uncertainty machinery is an asset.
- Progressive disclosure / Reach is the right interaction.
- Direction/Ask (goal‑anchored) is the right frame.

---

## Version 3 Design Principles

1. **Evidence or silence.** Every Life statement renders origin + calibrated confidence word + tap‑through evidence — or it doesn't render.
2. **Reflect, don't verdict.** Default output is a prompt or a retrieved specific, not an inner‑state score.
3. **Earn the claim.** Interpretive readings require earned signal (explicit check‑ins or passive physiology). No emotion from checkboxes alone.
4. **One daily artifact.** A single legible, personal, decision‑relevant object leads the Life surface.
5. **The user is authority and corrector.** Surface conflicts; make "that's wrong" first‑class and visibly improving.
6. **Provenance by construction.** Seeded / inferred / user / imported / composed are visually distinct, always.
7. **Postpone with payoff.** Ask for permissions/data only at the moment of visible value, and name the value.
8. **Protect the compounding asset.** The truthful long‑term record is the moat; never pollute it with fabrication.
9. **Calm by default.** Interrupt only when the reading clears both a confidence and a relevance bar.
10. **Autonomy over engagement.** Serve the declared direction; never manufacture return.

### Reading list
- *Atomic Habits* — Clear; *Good Habits, Bad Habits* — Wood.
- *Thinking, Fast and Slow* — Kahneman; *Nudge* — Thaler & Sunstein; *Superforecasting* — Tetlock.
- *Drive* — Pink; Deci & Ryan, Self‑Determination Theory.
- Pennebaker, *Opening Up by Writing It Down*.
- Li, Dey & Forlizzi, "A Stage‑Based Model of Personal Informatics Systems" (CHI 2010).
- Choe et al., "Understanding Quantified‑Selfers' Practices" (CHI 2014); Epstein et al., "A Lived Informatics Model of Personal Informatics" (2015).
- Weiser & Brown, "The Coming Age of Calm Technology."
- Guo et al., "On Calibration of Modern Neural Networks" (2017); Amershi et al., "Guidelines for Human‑AI Interaction" (CHI 2019).
- Apple Human Interface Guidelines; Center for Humane Technology materials (persuasive tech, read critically).

### Roadmap shift
V3 is not "more Life features." In order: **(1)** fix the signal/claim mismatch (fix F1–F2 renormalization *or* retire checkbox‑based state inference); **(2)** wire provenance + confidence + evidence into every Life surface; **(3)** replace the prose verdict with one evidence‑linked daily artifact; **(4)** make correction visible; **(5)** only then extend the knowledge graph with high‑value signals (sleep regularity, social interaction, notes).

---

*Phase R success test — "do we understand the problem far better?" — is met: LOCA's value was mislocated in the inference backend when it actually lives in the truthful record and well‑timed reflection. D1–D4 are symptoms of one root assumption: that a confident inner‑state model could be built from habit checkboxes. Building stays out of scope until the direction is approved.*
