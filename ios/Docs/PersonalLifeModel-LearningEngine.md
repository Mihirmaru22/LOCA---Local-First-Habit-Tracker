# The Learning Engine — Passive Understanding as the Primary Objective

> **⚠ SUPERSEDED by `LOCA-Founding-Manifesto.md`.** The debt/asset framing below created
> a calibration paradox (a model that avoids labels cannot know when it is wrong) and,
> deeper, mis-located the beneficiary — it priced the *user's own voice* as debt. The
> manifesto resolves both: questions that serve the user's clarity are a gift, not a
> tax, and the label economy inverts. Retained as history.

## Phase P — Session P2 · Optimizing Inference, Not Interrogation

> *No UI. No SwiftUI. No code. This document reorients Phase P. `PersonalLifeModel.md`
> (P1) designed the question economy — how LOCA decides what to ask. This session
> designs the thing that should make most of those questions unnecessary: the
> **learning engine**. The governing law here is economic and directional:*
>
> **Every question is a debt. Every inference is an asset. Passive understanding is
> always preferred over active questioning.**

> LOCA's north star — *"Disappear by default. Speak only when genuinely worth
> hearing."* — has a corollary for understanding: **learn by default; ask only when
> learning has failed.** The ideal Personal Life Model asks almost nothing, not
> because it is polite, but because it already understands almost everything it
> reasonably can.

---

## 0. Status and relationship to P1

**Status:** Corrective and foundational. P2 does not discard P1; it demotes P1's
centerpiece. The question economy is no longer the engine — it is the **overflow
valve** on the engine. Everything P1 said about *which* question to ask (the
EIG × value × timeliness / burden priority) still holds *once we have already
decided a question is unavoidable*. P2 is about making that decision almost never
fire.

**The repositioning in one diagram:**

```
                 ┌──────────────────────────────────────────┐
                 │            THE LEARNING ENGINE             │   ← P2: the protagonist
                 │  passive sensing → self-supervised         │
                 │  prediction → fusion → personalization     │
                 │  → compounding inference                   │
                 └───────────────────┬──────────────────────┘
                                     │ residual epistemic uncertainty
                                     │ that is high-value, time-sensitive,
                                     │ and passively unreachable
                                     ▼
                 ┌──────────────────────────────────────────┐
                 │   THE QUESTION ECONOMY (P1 §5)             │   ← demoted: lender of last resort
                 │   only now do we ask "which probe?"        │
                 └──────────────────────────────────────────┘
```

The design goal of P2 is to **starve** the lower box. A healthy system routes almost
everything through the top box and lets the bottom box fire rarely and shrinkingly.

---

## 1. The economics: debt versus asset

Reframing the two kinds of "learning" as opposite entries on a balance sheet is not a
metaphor — it dictates the whole architecture.

### 1.1 A question is a debt

Every question incurs a real, compounding liability:

- **Burden principal.** It spends the user's scarce seconds against a hard budget
  (P1 §5.5). That principal is paid *now*.
- **Trust interest.** Each question is a small admission — *"I could not figure this
  out on my own."* A model that keeps asking feels less like it knows you, not more.
  Asking too much is how a "life model" degrades into "a survey with a nice UI."
- **Bias risk.** The answer is a *retrospective self-report*, which the science says
  is systematically distorted (peak–end, affective forecasting error, satisficing —
  P1 §2.3, §2.11). A question can return data that is *worse* than a good passive
  estimate. You can borrow bad information at a high price.
- **Default risk.** Ask past a threshold and the user disengages entirely (EMA
  compliance decay). The debt can bankrupt the relationship.

Debt is sometimes worth taking on — but only against a genuine, unmeetable need, at
the lowest possible principal, and never as a substitute for saving.

### 1.2 An inference is an asset

Every inference the engine makes from passive signal is capital that appreciates:

- **It's free at the point of use.** No burden principal, no trust interest. The
  streams arrive whether or not the user engages.
- **It compounds.** Each inference becomes a prior for the next (§5). Understanding
  accrues like invested capital: the more the engine already knows, the cheaper the
  next inference is to make.
- **It's often more accurate than the answer would have been.** A triangulated
  passive estimate of stress (§4.2) beats a tired 9pm self-rating, because it never
  had to pass through a biased memory.
- **It never fatigues the user.** You can save indefinitely without cost; you cannot
  borrow indefinitely without ruin.

### 1.3 The directional law

From the balance sheet, one rule governs every design choice in the model:

> **When a fact can be plausibly obtained by inference *or* by asking, always prefer
> inference — even when asking is easy, even when the inference is only pretty good.**
> Reach for a question only when the asset path is genuinely exhausted (§6).

This is stronger than P1's "ask efficiently." It says: **the existence of a cheap
question is not a reason to ask it.** The question is financed by debt; the inference
is financed by an asset you already own. Prefer the asset.

---

## 2. The theoretical spine: perception before action

The claim "passive understanding should always be preferred over active questioning"
is not just a product preference — it is a well-formalized principle in the science
of adaptive systems.

**Active inference / the free-energy principle** *(Friston; predictive processing).*
An adaptive agent minimizes prediction error ("surprise") about its world. It has
exactly two ways to do so:

1. **Perception / learning** — *update beliefs to fit incoming observations.* Cheap,
   continuous, and passive: the world is already streaming data at you.
2. **Action** — *act on the world to get the observation you need.* In our setting,
   the only "action" available is **asking the user a question.** It is expensive and
   intrusive.

Predictive processing systems minimize free energy *primarily through perception* and
resort to *epistemic action* only when perception cannot reduce the uncertainty that
matters. Mapped onto LOCA:

- **Perception = the learning engine** consuming passive signal (§4).
- **Epistemic action = a probe** — the last resort, taken only when belief-updating
  from available observation cannot close the gap.

So "learn by default, ask only when learning fails" is the free-energy principle
applied to a Personal Life Model. The learning engine is *perception*; the question
economy is *action*; and the entire literature agrees action is the expensive path
you avoid when perception will do.

This also gives us the engine's heartbeat (§4.1): a system that minimizes prediction
error must be, first and always, a **prediction machine**.

---

## 3. What "everything it reasonably can" means

The user's phrasing is precise: the model should understand *almost everything it
reasonably can*. Two words carry the design: **reasonably**, and (implicitly) the
frontier of the knowable. The engine must know the difference between *what it hasn't
learned yet* and *what no amount of learning or asking could resolve* — because the
two demand opposite responses.

### 3.1 Epistemic vs aleatoric uncertainty (the most important distinction in P2)

- **Epistemic uncertainty** is *ignorance* — reducible by more data, better fusion, or
  (last resort) a question. The engine's job is to drive this toward zero, preferring
  passive means.
- **Aleatoric uncertainty** is *irreducible randomness* — genuine day-to-day variance
  in a life that no phone sensor and no question can explain away. Some of a person's
  mood variance simply is not a function of anything measurable.

**Design consequence:** the engine tags every uncertainty with its type, and the two
route completely differently:

| Uncertainty type | Correct response |
|---|---|
| Epistemic, and passively reducible soon | **Wait and keep sensing.** It will self-resolve as more data arrives. Never ask. |
| Epistemic, passively reducible but slow, low value | **Wait.** Let it resolve on its own timescale. Still don't ask. |
| Epistemic, passively **unreachable**, high value, time-sensitive | **Only here** consider a question (§6). |
| Aleatoric (irreducible) | **Accept it.** Never ask — asking cannot reduce randomness and only burns trust. Model it as noise. |

The single worst failure of a learning engine is to **mistake aleatoric noise for
epistemic ignorance** and interrogate the user about something no answer could ever
pin down. That is asking a debt you can never repay with understanding.

### 3.2 The knowable frontier

"Reasonably" defines a frontier. Some things are richly sensable from a phone (sleep
timing, movement, location, calendar, physiology). Some are inferable by fusing them
(§4.2). Some are, for now, genuinely only in the user's head (why a run felt
demoralizing) — but even these migrate inside the frontier over time as the engine
learns the person's behavior→experience mapping (§7). The engine's ambition is to
**push its understanding out to this frontier using passive means**, accept the
irreducible remainder beyond it, and spend a question only on the thin, shrinking band
that is *inside* the frontier yet *not yet* passively reachable.

---

## 4. The Learning Engine architecture

A passive-first stack. Each layer's purpose is to convert more of the world into
assets so the residual handed to the question economy shrinks. The layers are ordered
so that each one *retires questions* the layers below it would otherwise have to ask.

### 4.0 Layer 0 — Sensing: harvest every free stream first

Before any question is contemplated, exhaust what the device already knows. This is
the cheapest capital and the engine must be greedy about it:

- **Physiology & sleep:** HealthKit — sleep stages/timing, heart rate, HRV, resting
  HR, respiratory rate, workouts, steps, active energy, mindful minutes.
- **Context:** calendar (event density, types, attendees), location clusters &
  transitions (home / work / gym / novel), significant-location dwell, motion type
  (still / walking / driving), weather, daylight/sunrise-sunset, timezone.
- **Device behavior:** screen-on patterns, app-category usage, pickup frequency,
  typing cadence, notification interaction — all as *state correlates*, on-device only.
- **LOCA's own habit engine:** every `LogEntry`, streak, and consistency figure is a
  certain fact about *what* happened — a free, high-confidence input (§9).

**Rule:** a question about anything derivable from these streams is a bug, not a
feature (P1's "never ask what the app already knows," now enforced as *never ask what
the streams already imply*).

### 4.1 Layer 1 — The self-supervised predictive core

The engine's beating heart is a **continuous prediction machine**. Every day it
predicts the person's near-future states and behaviors from their history — and is
then scored, for free, against what the passive streams actually deliver.

- **Self-supervised, so it needs no labels.** The supervision signal is the future
  itself: predict tomorrow's bedtime, today's afternoon energy, whether a habit will
  be kept — then observe the passive outcome. No user input required to train.
- **Prediction error is the only thing that can justify a question.** Where the engine
  predicts well, it understands — nothing to ask. Where it predicts *badly* and the
  error is epistemic and won't self-resolve, *there* and only there does a question
  earn consideration. **The engine must first fail to predict before it earns the
  right to ask.** This inverts P1: uncertainty alone doesn't summon a probe;
  *un-resolvable predictive failure* does.
- **It improves with zero questions.** Every day of passive outcomes is a free
  training example. The core gets more accurate month over month even if the user
  never taps a thing — which is precisely how the model "asks less over time" without
  the user doing the work.

### 4.2 Layer 2 — Sensor fusion: corroboration kills questions

Most states the old journals *asked about* are recoverable by **triangulating several
weak passive signals into one confident estimate.** A single stream is ambiguous;
three corroborating streams rarely are.

> **Worked example — the stress question, never asked.** Instead of *"How stressed
> were you today?"* the engine fuses: suppressed HRV + accumulated sleep debt + a
> back-to-back calendar + reduced evening movement + a later-than-usual bedtime →
> a high-confidence *elevated stress* estimate. Five weak passive signals beat one
> biased self-report — and cost the user nothing. The engine prefers this estimate
> **even though it could have asked**, because the fused estimate is both free *and*
> more accurate than a tired retrospective rating.

Fusion is the workhorse that moves states from "would need a question" to "already
inferred." The design imperative: **add and combine signal sources specifically to
retire questions** (§8), and always try harder fusion before reaching for a probe.

### 4.3 Layer 3 — Hierarchical priors: understand a lot on day one

A great learner does not start from scratch — it starts from what is true of humans in
general and personalizes the residual. **Empirical / hierarchical Bayes:** seed each
node with a **population prior** (circadian structure, the typical exercise→mood lift,
the typical sleep→focus link, weekday/weekend rhythms) and let *this* user's data pull
the estimate away from the population toward the personal.

- **Day-one understanding is already high.** From the first week the engine "already
  understands almost everything it reasonably can *about a generic human*." It is never
  a blank slate begging for input.
- **Personalization is the only residual worth chasing.** Questions (if any) target the
  *personal deviation* from the population prior — and only where that deviation is both
  large and consequential. Where a user is typical, the prior already suffices; asking
  would buy nothing.
- **Shrinkage protects against thin data.** With little personal data the estimate
  leans on the population and stays sensible; as personal evidence accumulates it takes
  over. No cold-start interrogation required.

### 4.4 Layer 4 — Personalized calibration: the same stream, more understanding

The mapping from *raw signal → latent state* is itself learned per person (a
meta-learning / personalized-calibration step). Early, the engine reads signals through
the population mapping ("HRV drop = stress"). Over time it learns *this* person's
resting baselines, their idiosyncratic stress signature, how *their* bad night shows up
in the data.

This is the mechanism behind the deepest promise of the whole product: **passive
understanding grows even when the user does nothing.** The identical HRV/sleep/calendar
stream yields a sharper state estimate in month twelve than in month one, because the
engine has personalized the lens it reads them through. Understanding increases while
the question rate falls — the two are not in tension; the learning engine is what makes
them move together.

### 4.5 Layer 5 — Credit assignment: amortize every rare label across the model

Because questions are debt, the few answers the engine *does* obtain must be made to do
enormous work. When a correction arrives — the rare Confirm-or-Correct tap "actually,
that run felt great" — it is never a single data point:

- it updates this person's **exercise → valence** mapping,
- it re-weights the **context entity** (this route, this time of day),
- it **recalibrates the passive detector** that had flagged the session as "hard,"
- and it sharpens the **prior** for every future run.

One label, many updated beliefs. The engineering objective is to **maximize marginal
understanding per label** through structure and credit assignment — because the better
each answer propagates, the fewer answers the engine ever needs to request. A learning
engine that treats each answer as an isolated fact is leaving most of the asset on the
table and will end up asking far more than it should.

### 4.6 The stack as a question-retirement pipeline

| Layer | What it converts to an asset | Questions it retires |
|---|---|---|
| L0 Sensing | raw device streams | anything directly observable (sleep timing, workouts, location, weather) |
| L1 Predictive core | history → forecast; error localizes ignorance | anything the engine can already predict; strips uncertainty down to true residual |
| L2 Fusion | many weak signals → one confident state | states like stress, energy, focus, social load |
| L3 Hierarchical priors | population structure → warm start | everything a *typical* human's prior already answers |
| L4 Calibration | personalized signal→state lens | states that were ambiguous under the generic mapping |
| L5 Credit assignment | one label → many beliefs | future questions the propagated label preempts |

By the time uncertainty reaches the question economy, five layers have already tried to
resolve it for free. Whatever is left is, by construction, the thin residual that is
genuinely worth a question — if anything is.

---

## 5. Inference as compounding capital

Assets compound; that is what makes the passive-first strategy win over years, not just
feel nicer.

- **The relationship graph is capital equipment.** Each learned edge (sleep-timing →
  focus; a person → mood; daylight → evening energy) makes the *next* inference cheaper,
  because a new observation can be explained through structure the engine already owns
  rather than learned from scratch.
- **Priors beget priors.** Today's posterior is tomorrow's prior. A well-run engine
  spends its early passive data building the structure that makes all later data cheap
  to interpret — the informational equivalent of investing early.
- **Questions are consumption; inferences are investment.** A question is spent the
  moment it's answered and leaves only its (biased) datum. An inference is retained,
  reused, and appreciates. A model funded by questions consumes its user's goodwill; a
  model funded by inference builds an appreciating understanding that asks less every
  year. The compounding is why the endgame (§7) is near-silence rather than a steady
  drip of efficient probes.

---

## 6. The debt ledger: when a question is actually justified

Questioning is not banned — a lender of last resort is a real part of a healthy system.
But it must be *accounted as debt* and *underwritten strictly*.

### 6.1 The four-gate underwriting test

A probe may be issued only if **all four** hold. If any fails, the engine waits, senses,
or accepts — it does not ask.

1. **Reducible.** The uncertainty is **epistemic**, not aleatoric (§3.1). Asking about
   irreducible variance is forbidden.
2. **Unreachable passively.** No fusion of existing streams, and no reasonable amount of
   *waiting for more passive data*, will resolve it. The asset path is genuinely
   exhausted — not merely slower.
3. **High value.** The target feeds many downstream inferences (a disposition, a
   high-degree graph edge). Low-value residuals are left unresolved (P1 §5.2).
4. **Time-sensitive.** Waiting for the passive path costs more than asking — the answer
   is only valid now (an in-the-moment affect label) or a decision downstream needs it
   soon. Absent time pressure, **default to waiting**, because the passive estimate is
   improving on its own.

Only for uncertainty that clears all four gates does the P1 question economy engage to
choose *which* probe and *when*. The gates sit **in front of** the P1 scheduler; P1
decides form and timing, P2 decides whether to borrow at all.

### 6.2 Questions-per-understanding as the primary KPI

Because each question is debt, the engine's headline health metric is the **question
rate**, and the North Star is to drive it down:

- On a **stable** life, the question rate must **fall over time.** A flat or rising rate
  is a *learning-engine regression* — treated as seriously as a performance-budget
  regression in the engineering principles.
- Every proposed new passive signal source is justified by **how many questions it
  retires** (§8). "Does adding HRV-during-sleep let us stop asking about sleep quality?"
  is the correct review question for any sensing addition.
- A spike in questions is only legitimate when it tracks a **genuine life change**
  (drift, P1 §5.4) that widened epistemic uncertainty about something high-value — i.e.,
  new principal against a new, real need. Borrowing to cover old ground is a defect.

### 6.3 Asking is a confession of failure — and that's the right framing

Internally, every issued question should be logged as *"the learning engine could not
infer this."* That framing keeps the incentives honest: the team optimizes to make the
engine so good that the confession is rarely needed. An organization that measures
"engagement via questions answered" will build a survey; an organization that measures
"understanding achieved per question asked" will build a Personal Life Model.

---

## 7. The shrinking residual: the arc to near-silence

The endgame the user described — *asks almost nothing because it understands almost
everything it reasonably can* — is the mathematical limit the learning engine converges
to, and here is the mechanism by which even the "subjective" residual shrinks.

Early on, some things genuinely need a question: whether a workout felt good, whether a
person lifted the mood, why a habit was skipped. These are inside the knowable frontier
but not yet passively reachable — the legitimate domain of the last-resort probe. But
each such answer, propagated by credit assignment (§4.5), teaches the engine **this
person's mapping from behavior to experience.** Once it has learned that *when this user
runs this route at this time in this state, they usually feel good*, it can **infer the
valence it used to ask about** — and that question retires (P1's CAT-style retirement,
now driven by the learning engine rather than the scheduler).

So the residual band — "inside the frontier, not yet passively reachable" — **shrinks
monotonically for a stable person.** The engine learns to predict the subjective from
the behavioral. The limit:

> The engine predicts most of the day *and* how it likely felt, checks itself silently
> against the occasional volunteered correction, and asks essentially nothing. Not
> because questioning was optimized away — because **understanding made it unnecessary.**

That is the difference between P1's ceiling and P2's. An optimized question economy
asymptotes at "asks efficiently." An optimized learning engine asymptotes at "**barely
needs to ask.**" Only the second is the Personal Life Model.

---

## 8. Failure modes of a lazy learning engine

Named so they can be caught in review, in the spirit of the engineering-principles bug
catalogue. Each is a way the engine leans on debt instead of building assets.

1. **Asking what fusion could have inferred.** The canonical failure: a "stress" probe
   when HRV + calendar + sleep already imply it (§4.2). Any question whose answer is
   corroborated by existing streams is a lazy-engine defect.
2. **Interrogating aleatoric noise.** Repeatedly asking about variance no answer can
   explain (§3.1). Burns trust to buy nothing.
3. **Cold-start interrogation.** Blasting questions in week one instead of leaning on
   population priors (§4.3). The engine should *start* understanding, not start asking.
4. **Isolated labels.** Treating each answer as a single fact instead of propagating it
   across the model (§4.5). Guarantees the engine needs far more answers than it should.
5. **Static calibration.** Reading every user through the population signal→state mapping
   forever (§4.4). The engine stops getting smarter from passive data, so the question
   rate never falls.
6. **Over-trusting the prior.** The opposite error — refusing to let strong personal
   evidence overrule the population prior, so the model never becomes *this* person's.
7. **Preferring the answer over the estimate.** Asking because a question is *easy* even
   though a passive estimate exists — and worse, the biased answer degrades a good
   estimate (§1.1). Violates the directional law (§1.3).
8. **Impatience.** Asking now what waiting a week of passive data would resolve for free
   (§6.1 gate 4). The engine must be willing to remain uncertain while it saves.
9. **Engagement-via-questions.** Measuring success by answers collected rather than
   understanding achieved (§6.3). This single incentive error rebuilds the survey.

---

## 9. Integration with LOCA

- **On-device by necessity.** The learning engine is the person; it runs where the
  person's data lives. LOCA's local-first spine (device-as-server, CloudKit as silent
  private sync) is exactly the substrate a passive-first engine needs — the streams
  (HealthKit, location, calendar, device behavior) are already on the phone, and none of
  it should leave to be understood elsewhere. Passive-first and local-first are the same
  commitment seen from two sides.
- **Habits are the highest-grade free asset.** The habit engine reports *what* happened
  with certainty. The learning engine consumes every `LogEntry`, streak, and consistency
  figure as ground truth — never re-asking it, and using it as anchor labels that
  calibrate the passive state estimators (a kept-vs-skipped habit is a strong,
  free signal about energy, motivation, and context).
- **Fusion respects the compute discipline.** Self-supervised prediction, fusion, and
  calibration run off the main actor on the cooperative pool, the same way analytics
  aggregation does (engineering principles §3.2). The learning engine obeys the
  performance budgets; the question rate obeys the burden budget.
- **It powers the interventions layer.** The existing intervention/reflection scaffolding
  becomes a real JITAI only when driven by a genuine model of state — and a model built
  mostly from passive inference is both cheaper and more trustworthy than one built from
  interrogation.

---

## 10. Evaluation: measuring the learning engine

P1's evaluation measured the *asker*. P2's measures the *learner* — and the burden
metrics from P1 §13.2 now read as *outputs* of a good learning engine, not targets to
hit by rationing questions.

### 10.1 Learning-engine quality

| Criterion | Target |
|---|---|
| **Inference coverage** | Fraction of the model's high-value nodes held at good confidence **by passive inference alone** — rises over time. |
| **Predictive accuracy** | The self-supervised core predicts held-out passive outcomes (bedtime, next-day energy, habit adherence) better each month. |
| **Passive-vs-asked accuracy** | Where both exist, the passive estimate matches later ground truth **at least as well** as the retrospective answer would have. If asking isn't more accurate, it isn't justified. |
| **Calibration** | Epistemic/aleatoric tagging is honest; confidence is on the reliability diagonal (P1 §13.1). |
| **Label amortization** | Average number of model beliefs meaningfully updated per user answer — should be ≫ 1 and rising (§4.5). |
| **Personalization gain** | State-estimate accuracy from the *same* passive streams improves with tenure, holding questions at zero (§4.4). |

### 10.2 The debt metrics (outputs of the above)

| Criterion | Target |
|---|---|
| **Question rate on a stable life** | Falls monotonically toward near-zero (§6.2). A flat/rising rate is a regression. |
| **Question justification rate** | ~100% of issued probes clear all four gates (§6.1); any avoidable probe is a bug. |
| **Questions retired per new signal source** | Every sensing addition is scored by how many questions it eliminates (§8). |
| **Burden (P1 §5.5)** | Met *as a consequence* of high inference coverage, not by starving a still-hungry model. |

### 10.3 The single governing ratio

**Maximize understanding achieved per unit of question-debt incurred.** P1 maximized
model quality per second of burden; P2 sharpens it: the numerator is understanding, the
denominator is *debt*, and the entire strategy is to grow the numerator through assets
so the denominator can fall toward zero. An ideal Personal Life Model drives this ratio
toward infinity — total understanding, near-zero asking.

---

## 11. Open questions for the next session

P2 establishes the primacy of inference and the debt/asset discipline. It leaves the
mechanics open:

1. **The predictive core.** What is the simplest on-device model that yields calibrated
   forecasts *and* an honest epistemic/aleatoric split — per-node Bayesian state-space
   estimators, a small shared latent-dynamics model, or a hybrid?
2. **Fusion mechanics.** How are weak signals combined into calibrated state estimates
   cheaply on-device, and how is each fused estimate's confidence computed so the gates
   (§6.1) can trust it?
3. **Population priors.** Where do the day-one hierarchical priors come from without
   sending anyone's data off-device — shipped priors learned offline, then personalized
   locally? How are they kept from being stereotyped or stale?
4. **Calibration/meta-learning.** What is the minimum viable personalized signal→state
   calibration loop, and how fast should it override the population mapping?
5. **Credit assignment.** Concretely, how does one answer propagate to many beliefs —
   what structure (a factor graph? explicit edges?) makes §4.5 real without overfitting
   a single label?
6. **The waiting policy.** How does the engine decide an uncertainty will "self-resolve
   soon" (gate 2/4) versus needs a probe now — the estimator that values patience?
7. **Retirement from learning, not scheduling.** How does a learned behavior→experience
   mapping formally retire a question (§7), and how is its return triggered by drift?
8. **Debt accounting.** What is the concrete ledger — how is the question rate tracked,
   attributed to model regions, and surfaced as a health metric the way perf budgets are?

Like P1, this document is foundational but not frozen. Feedback on the debt/asset
framing, the perception-before-action spine, the four-gate test, or the layer stack is
welcome before the next session commits to mechanics.
