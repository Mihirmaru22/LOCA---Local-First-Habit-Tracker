# The Personal Life Model — Founding Vision & Interaction Model

## Phase P — Session P1 · Inventing the Category

> *No UI. No SwiftUI. No wireframes. This document defines a new product category,
> its scientific foundations, and a novel interaction model. It is the counterpart
> to `PhaseL-LoggingExperience.md`: where Phase L governed how the user reports
> **what** they did, Phase P governs how LOCA comes to understand **why** their
> life looks the way it does — without ever asking them to keep a diary.*

> LOCA's north star: **"Disappear by default. Speak only when genuinely worth
> hearing."** The habit engine already honors this for *doing*. Phase P extends it
> to *understanding*: the app must build a deep model of a person's life while
> asking almost nothing.

---

## 0. Status

**Status:** Founding vision — not frozen. Session P1 establishes the thesis, the
research base, the model, the question economy, and the interaction primitives.
Later sessions converge on schema and implementation. Nothing here prescribes UI.

**Scope:** A new vertical alongside the habit system. It reuses LOCA's local-first
architecture (the device is the server; all inference is on-device; CloudKit is the
silent sync layer) and consumes the habit engine's outputs as priors.

---

## 1. The thesis

We are not building a journal, a mood tracker, or a reflection app. We are building
a **Personal Life Model**: a probabilistic, longitudinal representation of one
person's life that grows more accurate every month and asks less as it learns more.

Three sentences define the category:

1. **The model, not the entry, is the product.** The user is never authoring a
   record. They are correcting a model that is already trying to describe their day.
2. **The backend does the thinking; the frontend collects only high-value signal.**
   Every screen the user sees exists to reduce a specific uncertainty in the model —
   never to "capture" a generic feeling.
3. **The app is an active learner on a strict burden budget.** It knows what it does
   not know, it knows what that knowledge is worth, and it spends the user's seconds
   only where the return is highest.

The test for every interaction: **"Will this measurably improve the model's
understanding of this specific person?"** If not, it does not ship, and it does not
get asked.

### Why this is a new category, not an optimized journal

Existing apps are **storage-first**: the user produces content (text, a mood emoji,
a rating) and the app files it. Intelligence, if any, is a report generated *from*
what the user chose to write. The burden is on the human to know what is worth
recording, to remember it accurately, and to do it consistently — three things
humans are demonstrably bad at.

The Personal Life Model inverts this. It is **model-first**: the app maintains a
running hypothesis about the user's life and treats every interaction as an
*experiment* to test that hypothesis. The human is never asked to be a good
diarist. They are asked, occasionally and briefly, to confirm or correct a guess.
Storage is a byproduct of inference, not its purpose.

That inversion is the category. Everything below is how to build it.

---

## 2. Research foundations

This design is not invented from taste. Each principle traces to an established
body of work. The point of the review is not citation for its own sake — it is that
**every failure mode of self-tracking apps is a known, named phenomenon**, and each
has a corresponding countermeasure we adopt.

### 2.1 Ecological Momentary Assessment (EMA) & the Experience Sampling Method (ESM)

*Csikszentmihalyi & Larson; Stone & Shiffman; Shiffman, Stone & Hufford.*

Assessing experience **in the moment, in context** dramatically reduces the recall
and reconstruction bias that poisons retrospective self-report. A rating given at
9pm about "the whole day" is a fiction assembled by a tired brain. A rating given at
2pm about *right now* is data.

- **Lesson we adopt:** Probe *states* close to when they occur, not at a nightly
  "summary" moment.
- **Failure mode it warns of — prompt/alarm fatigue and compliance decay:** EMA
  studies show response rates fall the more, and the more randomly, you interrupt
  people. This is the single largest risk to the entire product. It is why the
  question economy (§5) is not a feature but the core engine.

### 2.2 The Day Reconstruction Method (DRM)

*Kahneman, Krueger, Schkade, Schwarz & Stone (2004).*

Instead of one global rating, the DRM has people **reconstruct the day as a sequence
of discrete episodes** ("commute," "meeting," "lunch with X"), then characterize
each. It recovers much of EMA's accuracy without EMA's constant interruption,
because episodic structure is a powerful memory scaffold.

- **Lesson we adopt:** The atomic unit is the **episode**, not the day. *Do not
  summarize the day; reconstruct it* — this is DRM, and it is the direct answer to
  the brief's "a day cannot be represented by one emotion."
- **The move that makes it effortless:** We pre-reconstruct the day from passive
  signal (calendar, location, motion, habits) so the user edits a draft rather than
  authoring a timeline. DRM's cost was always the reconstruction labor; sensors pay
  most of it for free.

### 2.3 The Peak–End Rule and affective forecasting error

*Kahneman; Redelmeier; Wilson & Gilbert.*

People's *remembered* experience is dominated by the peak and the end of an episode
and is a poor guide to its *lived* moment-to-moment reality. And people are bad at
predicting how future events will feel.

- **Lesson we adopt:** Trust momentary signal over remembered summaries where we can
  get it; and treat the model's job as capturing lived experience the user's own
  memory will later distort. This is a *reason the product has value*: LOCA remembers
  the day accurately when the user won't.

### 2.4 Digital phenotyping & passive sensing

*Onnela & Rauch; Torous et al. (mindLAMP); Insel.*

Moment-to-moment behavior — movement, sleep, location entropy, communication
patterns, phone usage — yields **behavioral markers** of state without any active
input. The field's core promise is inferring psychological state from passive data.

- **Lesson we adopt:** Every signal LOCA can sense passively (HealthKit sleep, steps,
  workouts, heart-rate variability; habit logs; calendar density; location clusters;
  weather; daylight) becomes a *prior*. The active probe fills only the residual
  uncertainty the sensors cannot.
- **The field's honest limitation we respect:** passive markers are *correlates*, not
  ground truth. They set priors; they do not close the loop. Occasional active labels
  are what keep the passive model calibrated (this is the semi-supervised structure of
  §4).

### 2.5 Personal Informatics: the stage-based and "lived informatics" models

*Li, Dey & Forlizzi (2010); Rooksby et al. (2014); Epstein et al. (lapsing).*

Self-tracking has stages (preparation → collection → integration → reflection →
action), and each has distinct barriers. "Lived informatics" showed that real people
track intermittently, for shifting reasons, and **lapse** — and that tools which
shame lapsing get abandoned.

- **Lesson we adopt:** Collection must be near-zero-effort (the app collects, the
  user corrects). Reflection and action must be *delivered by the backend* as
  insight, because users rarely do the integration work themselves.
- **Failure mode it warns of — the lapse:** A model that degrades ungracefully when
  the user goes quiet for two weeks will be abandoned. The model must tolerate
  silence, widen its uncertainty honestly, and re-engage gently (§8.4).

### 2.6 Item Response Theory (IRT) & Computerized Adaptive Testing (CAT)

*Lord; Weiss; the GRE/GMAT adaptive engines.*

A well-designed test does not ask everyone every question. It estimates a latent
trait (θ) and, at each step, asks the **single item that carries the most
information about θ at the test-taker's current estimate** (maximal Fisher
information). High-confidence traits stop being probed; the test shortens itself.

- **Lesson we adopt:** This is the mathematical spine of "the app should ask less
  over time." Each latent variable in the life model is a θ; each candidate probe is
  an item with an information function; LOCA asks the highest-information item and
  retires items whose information has gone to zero. **Questions disappearing is not a
  UX nicety — it is CAT.**

### 2.7 Bayesian Optimal Experimental Design (OED) & active learning

*Lindley; Chaloner & Verdinelli; MacKay; Settles.*

Choose the experiment (query) that **maximizes expected information gain (EIG)** —
the expected reduction in posterior uncertainty. Active learning selects the
unlabeled point whose label would most improve the model.

- **Lesson we adopt:** Generalizes CAT beyond a single trait to the whole model. The
  probe scheduler is a Bayesian OED loop over the entire latent state (§5). "Never
  ask what the app already knows" is literally *EIG ≈ 0 ⇒ do not ask.*

### 2.8 Just-In-Time Adaptive Interventions (JITAI) & micro-randomized trials

*Nahum-Shani et al.; Klasnja, Murphy et al.*

Deliver the right support at the right moment based on the person's changing state;
learn *when* prompting helps versus annoys via micro-randomization.

- **Lesson we adopt:** Timing is itself a learnable policy. *When* to probe is not a
  fixed schedule; it is a decision the app improves over time by observing which
  moments yield honest answers and which get dismissed (§5.3). And LOCA's eventual
  *output* — nudges, recommendations — is a JITAI powered by the model.

### 2.9 Affective science: emotion is multidimensional and state-like

*Russell's circumplex (valence × arousal); Watson & Tellegen (PANAS); Barrett.*

"Mood" is not one scalar. At minimum it is **valence** (pleasant–unpleasant) and
**arousal** (activated–deactivated), it varies within a day, and momentary *state*
differs from dispositional *trait*.

- **Lesson we adopt:** Never collapse affect to a single emoji or a single daily
  number. Model affect as a low-dimensional continuous state attached to *episodes*,
  separate the fast state from the slow trait, and let the user express it through
  cheap proxies rather than a labeled scale (§7).

### 2.10 Chronobiology & sleep science

*Roenneberg (Munich ChronoType, social jetlag); Borbély (two-process model).*

Sleep timing, chronotype, and sleep debt are derivable from **bed time and wake
time** plus consistency — the exact example in the brief. Duration is an output, not
an input.

- **Lesson we adopt:** The canonical illustration of "ask for raw anchors, derive
  everything." This generalizes into the question grammar (§7.1).

### 2.11 Respondent burden & the ethics of measurement

*Total-burden literature in survey methodology; participant burden in EMA.*

Burden is cognitive, physical, temporal, and emotional. Beyond a threshold, more
measurement yields *less* data (via dropout) and worse data (via satisficing —
answering to dismiss the prompt).

- **Lesson we adopt:** Burden is a hard budget, tracked and enforced like a
  performance budget (§5.5). The 60-second ceiling and 30-second median from the
  brief are *engineering constraints*, not aspirations.

### Synthesis

| Field | One-line contribution to the design |
|---|---|
| EMA/ESM | Probe states in the moment; interruption is the enemy |
| DRM | The unit is the episode; reconstruct, don't summarize |
| Peak–End / forecasting | The model must out-remember the user; that's its value |
| Digital phenotyping | Passive signal sets priors; active probe fills the residual |
| Personal informatics | Near-zero collection; lapse-tolerant; backend does reflection |
| IRT / CAT | Retire high-confidence questions; the interview shortens itself |
| Bayesian OED / active learning | Ask the maximum-information question, or nothing |
| JITAI / micro-RT | *When* to ask is a learned policy; the payoff is timely support |
| Affective science | Affect is multi-dimensional, state-like, episode-attached |
| Chronobiology | Ask raw anchors (bed/wake), derive the rest |
| Burden research | Burden is a hard, enforced budget |

---

## 3. The central reframe

Three inversions turn "another journal" into a Personal Life Model. Each maps a
failure of the old category to a mechanism of the new one.

### 3.1 From **Entry** to **Probe**

- *Old:* an open surface ("How was your day?") that the user must fill.
- *New:* a **probe** — a single, disposable, high-information question the *system*
  generates because answering it will most improve the model right now. The user does
  not decide what is worth recording; the model does, and it is usually right because
  it knows where its own uncertainty is.

A probe is defined not by its wording but by its *target*: the latent variable it
resolves and the information it is expected to yield. Wording is generated; the
target is the design object.

### 3.2 From **Summary** to **Reconstruction**

- *Old:* compress a whole day into one mood/rating. Scientifically indefensible
  (§2.2, §2.9) and emotionally false — the brief's core complaint.
- *New:* the day is a **sequence of episodes**, most of them pre-filled from passive
  signal. The user's rare contribution is a nudge to an episode the app got wrong or
  couldn't see. We reconstruct the day at low resolution automatically and raise the
  resolution only where it matters and only when it's cheap.

### 3.3 From **Form** to **Loop**

- *Old:* a static questionnaire — the same fields forever, indifferent to what's
  already known.
- *New:* a **closed active-inference loop**:

```
   passive signals ─┐
   habit logs ──────┼──▶  update the model  ──▶  where is uncertainty
   prior answers ───┘            ▲                 that matters most?
                                 │                        │
                                 │                        ▼
                        answer (or non-answer)   is EIG × value > burden cost?
                                 ▲                        │  yes
                                 └──────  micro-probe  ◀───┘
```

The loop's defining property: **it is always running a best guess, and it only
surfaces to the user to check a guess it can't resolve itself.** As the model
sharpens, the right-hand branch fires less often. The app genuinely recedes.

---

## 4. The Self-Model (what the model actually is)

The "backend that does the thinking" is a layered probabilistic model. Every node
carries a **posterior** (a value *and* a calibrated confidence). Confidence is
first-class: it is what the question economy spends against.

### 4.1 Four layers, by timescale

1. **Episodes (minutes–hours, the raw material).**
   A day is an ordered set of episodes. Each episode is a bundle:
   *time bounds · activity type · environment/place · social context (alone / with
   whom) · and latent state during it (valence, arousal, energy, focus).*
   Most fields are inferred from sensors; few are ever asked. Episodes are the DRM
   scaffold and the join key for every correlation LOCA will ever compute.

2. **Daily states (hours–a day, fast-moving).**
   Energy, stress, focus, motivation, mood, sleep quality, social load. These are
   *aggregates over episodes* plus their own dynamics (e.g., sleep debt carries
   forward). They are the variables the user experiences as "how today went" — but
   held as a vector, never a scalar.

3. **Dispositions / traits (weeks–years, slow-moving).**
   Chronotype, baseline affect and its variance, stress reactivity, whether social
   contact recharges or drains, introversion/extraversion of energy, exercise→mood
   sensitivity, weather sensitivity. These are the θ's of CAT (§2.6): high-value,
   slowly-learned, and once learned, rarely re-probed.

4. **Context entities (persistent, accrue evidence).**
   People, places, activities, and recurring situations as **first-class objects**
   that accumulate an affective and behavioral track record. "Mornings at the gym,"
   "1:1s with a specific person," "the commute," "weekends at home" each become an
   entity with an estimated effect on the user's states. This layer is what lets LOCA
   eventually answer *"which people improve your mood"* and *"what environments make
   you happiest."*

### 4.2 The relationship graph (the payoff layer)

Over the layers sits a growing **associative/causal graph**: edges like
*sleep-timing → next-day focus*, *specific person → mood*, *outdoor daylight →
evening energy*, *late caffeine → sleep onset*. Edges start as weak correlations and
strengthen with evidence; some graduate to tentative causal claims where the data
structure allows (natural experiments, within-person contrasts, and — later —
opt-in micro-randomized nudges, §2.8). **This graph is the thing the user will feel
as "LOCA knows me."** It is never shown as a raw graph; it surfaces as sentences.

### 4.3 Confidence is the currency

Every node stores calibrated uncertainty. This single design choice powers the
entire question economy:

- **High confidence ⇒ stop asking** (the question's information is spent — §2.6).
- **Uncertainty rising ⇒ start asking again** (drift detection — §5.4).
- **Low confidence on a low-value node ⇒ still don't ask** (not everything uncertain
  is worth resolving — §5.2).

Confidence must be *calibrated*, not vibes: when the model says 80% it should be
right ~80% of the time. Miscalibration is a first-order bug because the whole
scheduler reasons over these numbers.

### 4.4 Semi-supervised by construction

Passive signal is abundant but *unlabeled* (steps don't tell you the workout felt
demoralizing). Active probes are scarce but *labeled*. The model is trained
semi-supervised: passive data provides structure and priors; the occasional probe
provides ground-truth labels that keep the passive inferences calibrated. The
scheduler's job is to spend the scarce labels where they most improve the abundant
inferences.

---

## 5. The Question Economy — the system that decides

This is the heart of the product and the direct answer to the brief's central
instruction: *"Do not design questions. Design a system."* No question exists in a
fixed bank tied to a screen. Every prompt is **generated at runtime** by a scheduler
optimizing one quantity.

### 5.1 The governing equation

For every candidate probe *q* at moment *t*, compute a **priority**:

```
  priority(q, t)  =  EIG(q) × Value(target(q)) × Timeliness(q, t)
                     ────────────────────────────────────────────
                                    Burden(q, t)
```

- **EIG(q) — Expected Information Gain.** How much answering *q* is expected to
  reduce posterior uncertainty in its target node(s). Bayesian OED (§2.7) / Fisher
  information (§2.6). If the model already knows the answer, EIG ≈ 0.
- **Value(target) — long-term model value.** Not all uncertainty is worth resolving.
  Value is high for nodes that feed many downstream insights (a disposition, a
  high-degree graph node) and low for trivia. This enforces the brief's principle
  *"every question must have long-term value."*
- **Timeliness(q, t) — right-moment multiplier.** Some probes are only valid or only
  cheap at certain moments (an in-the-moment state probe now; a bed-time anchor near
  bedtime). Learned via JITAI-style adaptation (§5.3).
- **Burden(q, t) — cost to the user.** Cognitive + temporal + emotional cost *right
  now*, including a rising penalty as the day's burden budget is consumed (§5.5).

LOCA asks the top-priority probe **only if** its priority clears a threshold, and
only until the day's burden budget is spent. Most days, few probes clear the bar.
That is the design working, not failing.

### 5.2 What to ask / what NOT to ask

**Ask** the probe that maximizes the equation: high information, high value, timely,
cheap. In practice these cluster into a few kinds — resolving a disposition still in
doubt, labeling an episode the sensors flagged as anomalous, disambiguating a
correlation the graph is close to committing to, or catching up after a lapse.

**Do not ask** when any of these hold — each is a term going to zero:

- *The answer is known or inferable* (EIG ≈ 0). Habits already report exercise;
  HealthKit already reports sleep timing; the calendar already reports the meeting.
  **Never ask what the app already knows** falls out of the math for free.
- *The target isn't worth it* (Value low). No collecting data that will never
  produce an insight.
- *The moment is wrong* (Timeliness low). Don't ask about a workout's feel three days
  later; the answer would be reconstructed noise (§2.3).
- *The budget is spent* (Burden high). Silence is the default; the bar rises as the
  day fills.

### 5.3 When to ask (timing as a learned policy)

Timing is not a cron schedule. Candidate moments are **triggered by context**, then
*filtered* by a learned policy:

- **Natural close-of-episode moments** — a workout just ended (HealthKit), the user
  arrived home (geofence), a calendar block closed. These are the EMA-honest moments:
  the experience is fresh, the interruption is aligned with a real seam in the day.
- **Natural open-app moments** — the user is already in LOCA logging a habit. A probe
  here is nearly free because attention is already here (this echoes Phase L's
  principle *"log where attention already is"*).
- **A gentle daily reconstruction window** — one optional, dismissible moment (user's
  chosen time) to nudge the auto-built timeline, for people who prefer a single touch
  point over in-the-moment probes.

The policy learns, per user, which trigger types yield honest answers versus
dismissals (satisficing and dismissal are themselves signal — §5.6), and shifts its
timing accordingly. This is a JITAI/micro-randomization loop (§2.8) over *when*, not
*what*.

### 5.4 When uncertainty increases (drift → questions return)

The model is non-stationary; lives change. Uncertainty is *pushed back up* by:

- **Prediction error.** When passive signal starts contradicting the model's
  expectations (sleep timing shifts, activity patterns break), the affected nodes'
  posteriors widen. Rising variance raises EIG, which re-activates retired probes.
- **Elapsed time.** Every disposition's confidence *decays slowly* on its own
  timescale. A trait learned a year ago and never reconfirmed is quietly re-opened —
  which is exactly the brief's *"months later a question can return."*
- **Explicit life-change signals.** A large, sustained break in routine (a move, a
  new job inferred from calendar/location change) triggers a bounded re-learning
  burst: the model widens uncertainty across the affected subgraph and temporarily
  raises the burden budget to re-anchor — then recedes again.

### 5.5 The burden budget (hard, enforced)

Mirroring the engineering-principles performance budgets, burden is a **hard limit**:

| Metric | Limit |
|---|---|
| Total active interaction per day (median) | **< 30 s** |
| Total active interaction per day (ceiling) | **< 60 s** |
| Probes surfaced per day (steady state, mature model) | typically **0–2** |
| Probes per day (cold start, first weeks) | more, but still under the time ceiling |
| Consecutive dismissed probes before back-off | small; then the app goes quiet and widens uncertainty rather than pushing |

The budget is spent in priority order and then the app is *done for the day*. A probe
that can't be afforded today waits for a day its priority still clears the bar — or
is dropped if it decayed in the meantime.

### 5.6 Non-response is data

A dismissed or ignored probe is not a null. It updates the model in two ways:
(1) weak evidence about the *timing policy* (this moment was wrong for this user);
(2) in some cases weak evidence about the *answer* itself (e.g., a "confirm-or-
correct" left uncorrected is soft confirmation — used cautiously, never as strong as
an explicit tap). This is what lets the app get *most* of its value from users who
rarely tap: silence still teaches it when to stay silent.

### 5.7 Where questions come from (generation, not a bank)

Because probes are generated, there is a **grammar**, not a list. A probe is
instantiated from a slot template bound to a target node and rendered against
current context:

```
  target:      episode[2026-07-24 T18:10, "gym"].valence
  frame:       confirm-or-correct        (cheapest viable frame for this target)
  anchor:      passive prior             ("looked like a hard session")
  rendered:    "That gym session — leave you drained or good-tired?"
  response:    two taps (drained / good-tired) + implicit dismiss
```

The design objects are the **targets**, the **frames** (§6), and the **selection
policy** (§5.1) — never the sentences. Sentences are the disposable surface.

---

## 6. The Interaction Primitives (the new interaction model)

This is the invented interaction model. It is a small set of primitives, each tuned
to a different information shape, each obeying Phase L's cost discipline. None is a
"journal screen." The unifying idea: **the app states a belief; the user's only job
is to correct it when it's wrong.** Confirming is cheaper than authoring, and often
free (silence).

### 6.1 Confirm-or-Correct (the default frame)

The app shows its current best guess as a near-complete statement; the user taps only
to correct it.

> *"Home by 6, quiet evening in?"* → tap once if wrong, otherwise ignore.

- **Cost:** 0 taps if right (silence = soft-confirm), 1 tap if wrong.
- **Why it works:** exploits the confirm/author asymmetry and the peak-end insight —
  recognition is far cheaper than recall. It is the frame for any node where the model
  already has a strong prior and just needs calibration.

### 6.2 The Micro-Probe (single high-information question)

One question, answerable at a glance, targeting the single highest-EIG node.
Two-to-four tap-scale choices, or a coarse continuous gesture — never free text,
never a labeled 1–10 scale.

> *"Right now — wired or worn out?"* (a valence/arousal read on the current episode)

- **Cost:** 1 tap. < 5 s including reading.
- **Why it works:** it is one CAT item (§2.6) chosen for maximal information; it
  captures affect as a cheap 2-D proxy (§2.9) rather than a survey scale.

### 6.3 The Reconstruction Ribbon (DRM, pre-filled)

A horizontal, glanceable ribbon of the day already assembled from passive signal —
sleep block, commute, calendar events, workout, home. The user's *optional*
contribution is to tap a segment the app got wrong or to drop in one it couldn't see.

- **Cost:** 0 if the auto-build is right (common as sensing matures); a nudge or two
  otherwise. The whole interaction is bounded by the daily budget.
- **Why it works:** it is the Day Reconstruction Method with the reconstruction labor
  pre-paid by sensors — DRM's accuracy without DRM's effort. It is *reconstruct, not
  summarize* made literal.

### 6.4 The Anchor (raw datum, derive everything)

For the rare things worth an exact input, ask for the **rawest possible anchor** and
compute the rest. The canonical case is sleep: *"Lights out?" / "Up?"* → the backend
derives duration, timing, consistency, chronotype, and debt (§2.10). Never
*"how many hours did you sleep?"*

- **Cost:** a two-tap time set, and only near the relevant moment.
- **Why it works:** raw anchors are low-cognition and high-yield; every derived
  quantity is a free downstream product. Generalized in §7.1.

### 6.5 The Contrast (in-the-moment A/B for causal edges)

When the graph is close to committing to a correlation, resolve it with a single
contrast probe at a diagnostic moment. *After a poor-sleep night:* *"Foggy this
morning?"* One data point at exactly the moment that most sharpens a specific edge.

- **Cost:** 1 tap, rare, only fired when it decisively moves an edge.
- **Why it works:** this is active learning choosing the maximally-informative label,
  and (opt-in, later) the seed of micro-randomized causal tests (§2.8).

### 6.6 The Insight Return (the reward, and the reason to keep answering)

Not a question — the *payoff*. Periodically, and only when genuinely worth hearing,
the backend surfaces one earned sentence:

> *"You've had six good mornings in a row — all of them followed an evening walk."*

- **Cost:** zero; it *gives*. It closes the personal-informatics reflection→action
  loop the user would never close themselves (§2.5), and it is the felt experience of
  *"LOCA knows me better this month."*
- **Discipline:** obeys the north star — a real, evidenced, novel insight, or
  silence. Never horoscope filler. An insight that isn't earned corrodes trust in
  every future one.

### 6.7 The primitives as a system

| Primitive | Information shape | Frame | Typical cost |
|---|---|---|---|
| Confirm-or-Correct | strong prior, needs calibration | belief stated, correct if wrong | 0–1 tap |
| Micro-Probe | one high-EIG unknown | one question, 2–4 choices | 1 tap |
| Reconstruction Ribbon | the day's episode structure | pre-built timeline to nudge | 0–few taps |
| Anchor | one exact raw datum | rawest input, derive rest | 2-tap time set |
| Contrast | a specific causal edge | one diagnostic A/B | 1 tap |
| Insight Return | *output*, not input | earned sentence | 0 (it gives) |

The scheduler (§5) chooses **which primitive, which target, which moment** — or none.
The user experiences a calm surface that occasionally states a belief or asks one
tiny thing, and periodically tells them something true about themselves they didn't
know. They never experience a form, a diary, or a survey.

---

## 7. Question-design grammar

Even though sentences are disposable, *how a target becomes a cheap question* follows
rules. These generalize the brief's sleep example into a reusable discipline.

### 7.1 Ask for anchors; derive the constructs

Never ask for a computed quantity. Ask for the raw event that produces it.

| Don't ask | Ask | Backend derives |
|---|---|---|
| "How many hours did you sleep?" | "Lights out?" / "Up?" | duration, timing, consistency, chronotype, sleep debt |
| "How productive were you?" | (infer from episodes) or "Which block was the real work?" | focus windows, output cadence, deep-work timing |
| "How social were you?" | "Alone or with people just now?" | social load, recharge/drain disposition |
| "Rate your stress 1–10" | "Wired or worn out right now?" | valence/arousal state, stress reactivity |
| "How was your day?" | (never — reconstruct via §6.3) | the whole episode sequence |

### 7.2 Prefer recognition over recall; coarse over precise

Offer a small set to *recognize* among, not a blank to *recall* into. Offer coarse
buckets ("now / this morning / earlier") in the UI while storing precise timestamps
(Phase L principle 8: *never sacrifice accuracy for convenience* — coarse input,
precise storage). False precision (minute-wheels, 1–10 scales) is cognitive tax the
model can't even use.

### 7.3 One target per probe

A probe resolves one node. Double-barreled questions ("how was work and how did you
sleep?") destroy the clean attribution of the answer and violate the EIG accounting.
If two nodes are uncertain, that's two candidate probes competing in the scheduler —
and usually only the higher-priority one ever fires.

### 7.4 Every probe must feed a downstream insight

A probe with no path to the relationship graph (§4.2) is banned regardless of how
easy it is to ask. Curiosity is not a reason to spend a user's second. This is the
enforcement of *"every question must have long-term value."*

### 7.5 State versus trait: ask states in the moment, infer traits over time

Never ask for a disposition directly ("are you a morning person?") — that's a
self-report of a construct the person may be wrong about (§2.3). Ask for cheap states
at the right moments and let the trait *emerge* from their accumulation. Traits are
**earned by inference, not collected by survey.**

---

## 8. Evolution over time

The model's defining promise — *smarter every month, asks less over time* — is a
direct consequence of §4 (confidence) and §5 (CAT-style retirement). Here is its
character across the life of the relationship.

### 8.1 Cold start (weeks 1–4): learn cheaply, earn trust fast

Uncertainty is high everywhere, so many probes clear the bar — but the burden budget
still caps daily cost. Priority favors **high-value dispositions** (chronotype,
baseline affect, exercise/social/weather sensitivities) because resolving a trait
pays off for years. Crucially, the app must **return an insight within the first
week** (§6.6) — even a modest one — so the user learns the loop *gives*, not just
takes. Passive signal is doing most of the work from day one; probes fill the gaps
that make early insights possible.

### 8.2 Maturation (months 2–12): the interview shrinks

As disposition posteriors sharpen, their EIG collapses and those probes retire (CAT,
§2.6). The scheduler shifts from *learning who you are* to *tracking how today
differs from your baseline* — mostly Confirm-or-Correct on an increasingly accurate
auto-reconstruction, plus the occasional Contrast to firm up a graph edge. Daily
active time drifts toward the 30-second median and below. The relationship graph
thickens; Insight Returns get sharper and more specific.

### 8.3 Maturity (year 2+): mostly silence, occasional depth

The app already predicts most of the day. It asks almost nothing — only when passive
signal is genuinely ambiguous, when a high-value edge is one contrast from resolving,
or when drift reopens a node. The felt experience is an app that **knows you**, is
quiet, and speaks with authority when it does. This is *"disappear by default,
speak only when worth hearing"* fully realized for understanding.

### 8.4 The lapse (graceful silence, gentle return)

Lived-informatics reality: users go quiet (§2.5). The model must:

- **Tolerate silence** — keep inferring from passive signal, which never stops.
- **Widen uncertainty honestly** — don't pretend to know a state it hasn't sampled;
  let posteriors decay so confidence stays calibrated.
- **Never shame the lapse** — no "you broke your streak" for *understanding*; that
  framing belongs (carefully) to habits, never here.
- **Re-engage gently** — on return, one low-friction, high-value probe or a warm
  Insight Return, not a backlog of missed questions. The app catches *itself* up from
  sensors; it does not ask the user to.

### 8.5 The character arc, at a glance

| Phase | Model state | Probe volume | User feeling |
|---|---|---|---|
| Weeks 1–4 | high uncertainty everywhere | highest (budget-capped) | "it's getting to know me — and it already told me something" |
| Months 2–12 | dispositions sharpening | falling | "it's mostly right; I just fix the edges" |
| Year 2+ | predicts most of the day | near-zero | "it knows me; it's quiet; it's right" |
| Any lapse | widened, honest uncertainty | ~zero, then one gentle re-entry | "it didn't nag me; it welcomed me back" |

---

## 9. A day in the life (concrete, sub-30-second)

**Tuesday, mature model, ~18 seconds of total interaction.**

- *7:12am* — HealthKit already logged sleep timing; the model updated overnight. No
  probe. The habit widget shows the day.
- *8:40am* — the user opens LOCA to check off *Meditate*. Attention is already here,
  so one nearly-free Confirm-or-Correct rides along: *"Slow start this morning?"* —
  the model's guess from a late bedtime. One tap: *"actually, good."* (**~4s**) The
  model just learned this user recovers from short sleep better than its prior
  assumed — a real update.
- *1:30pm* — a two-hour focus block just closed on the calendar. A single Micro-Probe:
  *"Was that the real work, or spinning?"* One tap. (**~4s**) Sharpens the
  focus-timing disposition.
- *6:05pm* — geofence: home. The Reconstruction Ribbon is already correct end-to-end;
  the user glances and does nothing. (**0s**)
- *9:50pm* — no probe. Instead, an Insight Return: *"Your three sharpest afternoons
  this month all started with a walk at lunch."* (**~10s to read**, 0 to answer.)

Total input: **~8 seconds of taps.** Total value: a disposition update, a focus-edge
sharpened, and one earned insight. No diary. No survey. No "how was your day?"

**Contrast — the same day, month one:** more probes fire (chronotype anchor at
bedtime, a couple of state Micro-Probes, a few Ribbon nudges because sensing is still
learning this person's places) — but still under the 60-second ceiling, and the week
still closes with a first real insight.

---

## 10. What LOCA can answer over the years

The relationship graph (§4.2), fed by cheap signal over time, is what lets LOCA
eventually answer the brief's questions — none of which the user ever has to
remember:

- **What environments make you happiest?** → context-entity valence estimates over
  places.
- **When is your focus naturally highest?** → focus-state distribution over
  time-of-day, conditioned on chronotype.
- **What predicts your bad sleep?** → in-edges to sleep-quality (late caffeine,
  screen-late, evening stress, irregular timing).
- **Which people improve your mood?** → person-entity → affect edges.
- **What causes your habit failures?** → state/context predictors of habit lapses
  (the two verticals join here: the habit engine's *what* meets the life model's
  *why*).
- **Which routines actually improve your life?** → within-person contrasts and,
  opt-in, micro-randomized tests of candidate routines.
- **What life changes made the biggest difference?** → change-point analysis across
  the longitudinal record.
- **What is changing about you over time?** → drift in dispositions the user can't
  see from inside their own life.

The strategic point: **these answers are byproducts of the model, not features to be
built one by one.** Build the model and the question economy well, and the answers
accrue on their own as evidence accumulates.

---

## 11. Trust, consent, and the creepiness line

A model this intimate lives or dies on trust. This is not a compliance appendix; it
is a design constraint as hard as the burden budget. A Personal Life Model that feels
like surveillance is worse than no product.

- **Local-first is the moat.** The model *is* the person; it must live on the person's
  device. LOCA's existing architecture already makes the device the server and
  CloudKit a silent, private sync layer. **On-device inference is non-negotiable** —
  no life model leaves the phone to be processed on someone else's computer. This is
  both an ethical stance and LOCA's genuine differentiator.
- **Legible, not black-box.** The user can always ask *"why did you infer that?"* and
  see the evidence. A model that explains itself is trusted; one that pronounces is
  feared. Insight Returns cite their evidence for the same reason.
- **The user owns and can edit the model.** They can see what LOCA believes, correct
  it, and delete any node, entity, or edge — including a *person* they don't want
  modeled. Forgetting is a first-class operation.
- **Sensitive inference requires consent and restraint.** The model could infer
  health or mood states that are sensitive. It must never *surface* an inference the
  user hasn't opted into hearing, never pathologize, and never present a correlation
  as a diagnosis. Some things it can quietly hold to improve predictions without ever
  saying them aloud.
- **The creepiness line: model privately, speak modestly.** The deep model can be
  rich; what it *says* must stay a step behind what it *could* say. Under-claiming
  builds trust; over-claiming ("we noticed you seem depressed") destroys it
  permanently. When in doubt, hold the inference and stay silent.
- **No dark patterns around engagement.** Because this vertical is about
  *understanding*, not *doing*, it must never manufacture streaks, guilt, or FOMO to
  drive input. The only legitimate reason to ask is model value; the only legitimate
  reason to speak is a genuine insight.

---

## 12. Anti-patterns — what would collapse this back into "another journal"

Named so they can be caught in review, the way the engineering principles catalogue
compiler bugs:

1. **The daily "How was your day?"** — the exact thing we reject. If it ever appears,
   the reframe (§3) has failed.
2. **A fixed question bank on a fixed screen.** Kills the question economy; questions
   stop adapting; EIG stops mattering. If probes aren't *generated*, this is a survey.
3. **A single mood scalar / one emoji per day.** Violates the multidimensional,
   episode-attached model (§2.9, §4.1). This is Daylio; we are not Daylio.
4. **Asking what's already known.** Any probe about exercise (habits know), sleep
   duration (HealthKit knows), or a logged event (calendar knows) means EIG accounting
   isn't wired to the passive layer.
5. **Insight spam / horoscope filler.** Speaking when there's nothing earned to say
   destroys the trust that makes the *next* real insight land. Silence beats filler.
6. **Streaks/guilt for understanding.** Importing habit-loop pressure into the life
   model punishes the lapse and drives satisficing (§2.11) — answers given to dismiss
   the prompt, which are *worse than no data* because they miscalibrate the model.
7. **Precision theater.** Minute-wheels, 1–10 sliders, exact-number prompts — false
   precision the model can't use and the user resents (§7.2).
8. **Blowing the burden budget.** Optimizing any single interaction's richness at the
   expense of the daily total. Judge the aggregate, never the instance (Phase L
   principle 9).
9. **A visible graph / dashboard as the main surface.** The graph is internal; the
   user meets it as *sentences* (§6.6). A raw analytics wall re-imposes the
   integration labor personal informatics showed people won't do (§2.5).

---

## 13. Evaluation criteria

Like Phase L, the model is judged objectively. Two families of metric, in tension by
design — the whole product is the pursuit of both at once.

### 13.1 Model quality (is it actually learning?)

| Criterion | Target |
|---|---|
| **Predictive accuracy** | The model predicts held-out passive signal (next-day sleep timing, activity) better each month. |
| **Calibration** | When the model says 80%, it's right ~80% of the time. Reliability curve on the diagonal. |
| **Confidence growth** | Aggregate posterior uncertainty on high-value nodes falls over time (barring genuine drift). |
| **Insight hit-rate** | Insight Returns the user marks true / "didn't know that" ≫ marked wrong / obvious. |
| **Drift responsiveness** | After a real life change, the model detects it and re-anchors within a bounded window. |

### 13.2 Burden (is it staying invisible?)

| Criterion | Target |
|---|---|
| **Daily active time** | Median < 30s; ceiling < 60s (§5.5). |
| **Probe frequency** | Falls over time for a stable life; steady-state 0–2/day at maturity. |
| **Dismissal rate** | Low and *falling* — evidence the timing policy is learning honest moments. |
| **Retention through lapse** | Users who go quiet return and re-engage — no shame-driven churn. |
| **"Never asked what it knew" rate** | ~0 probes about already-known facts. Any such probe is a bug. |

### 13.3 The single governing trade-off

**Maximize model quality per second of user burden.** Every design decision is scored
by whether it moves that ratio. It is the quantitative form of the thesis: *understand
the person as deeply as possible while asking as little as possible.*

---

## 14. Integration with the existing system

- **Reuses the local-first spine.** SwiftData on-device, App-Group SQLite, CloudKit
  as silent private sync (README §Persistence). The model and its inference live on
  the device; no new backend, consistent with LOCA's founding constraint.
- **Consumes habits as priors, never re-asks them.** The habit engine reports the
  *what* with certainty (`LogEntry`, streaks, consistency). The life model treats
  those as high-confidence evidence and spends its questions elsewhere — the two
  verticals meet only in the graph, where *why* explains *what* (habit-failure
  prediction, §10).
- **Feeds the interventions layer.** LOCA already has intervention/reflection
  delivery scaffolding (`App/InterventionDelivery.swift`, `ReflectionDelivery.swift`,
  `Features/HabitManagement/InterventionGenerator.swift`). The life model is the brain
  that makes those interventions a real JITAI (§2.8) instead of generic prompts.
- **Respects the engineering principles.** On-device inference obeys the concurrency,
  performance-budget, and off-main-actor computation rules the same way analytics
  aggregation does; the burden budget is enforced with the same seriousness as the
  performance budget.

---

## 15. Open questions for the next session

P1 sets the category, the science, the model, the economy, and the primitives. It
deliberately does **not** yet fix:

1. **Model mechanics.** How rich is the probabilistic model in v1 — a pragmatic set of
   Bayesian per-node estimators and a correlation graph, or something closer to a
   joint latent-state model? What's the simplest thing that yields calibrated
   confidence and honest EIG?
2. **EIG in practice.** How is Expected Information Gain approximated cheaply enough to
   run on-device, every day, over many candidate probes?
3. **The affect representation.** Exactly which low-dimensional state vector (valence ×
   arousal plus energy/focus?), and what cheap gestures express it without a scale?
4. **The reconstruction pipeline.** Which passive sources feed the auto-built Ribbon in
   v1 (HealthKit, calendar, location, motion, weather, daylight), and how is episode
   segmentation done on-device?
5. **The timing policy.** How much JITAI/micro-randomization is v1 versus later? What's
   the minimum viable "learn when to ask" loop?
6. **Insight generation.** How does the backend decide an insight is *earned* and
   novel enough to speak — the threshold that keeps §6.6 honest?
7. **Schema & migration.** How do episodes, states, dispositions, and context entities
   map onto SwiftData `@Model` types and a versioned schema, CloudKit-safe?
8. **Cold-start defaults.** What population priors seed the model before it has any of
   *this* user's data, and how fast do they get overwritten?

Like Phase L, this document is foundational but not frozen. Feedback on the thesis,
the research framing, the question economy, or the primitives is welcome before the
next session commits to mechanics.
