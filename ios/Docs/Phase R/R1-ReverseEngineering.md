# Phase R · R1 — Reverse Engineering (Deep Reconstruction)

> **This is not the summary in `R1.md`.** Here we tear each product down to the machine and rebuild it: the scoring math, the data schema, the state machine of the user journey, the baseline/learning algorithm, the trust contract, the notification decision logic, the retention mechanism, and the value curve with *causes*. Every teardown ends with **"To rebuild in LOCA"** — the concrete engine LOCA would need, mapped to D1–D4.
>
> The goal: understand these products well enough to *re‑implement* them, then design LOCA's V3 machine deliberately instead of by accident.

---

## 0. The reconstruction framework

Every product in this space is, underneath, some composition of **five reusable engines**. Reverse‑engineering is mostly identifying which engines a product runs and how it tunes them.

1. **Capture engine** — how raw signal enters (passive stream vs explicit tap vs prompt‑response).
2. **Baseline engine** — how "normal for you" is estimated so deviations become meaningful.
3. **Inference/scoring engine** — how raw signal becomes a legible number or claim.
4. **Trust engine** — how the claim is bounded, sourced, hedged, and corrected.
5. **Return engine** — the psychological reason the user comes back tomorrow.

A product succeeds when these five are *balanced*. It dies when one is missing (Human: no inference engine; Google Now: no trust engine) or fraudulent (a scoring engine emitting numbers the signal can't support — **which is exactly LOCA's F1**).

The 13 reconstruction lenses (the user's list) are how we *observe* those five engines from the outside:

`user journey · IA · backend assumptions · data model · learning model · trust model · notification strategy · retention loop · onboarding philosophy · Day 1 · Day 7 · Day 30 · Month 6 · Year 2`

---

## 1. Oura — reconstructed as a spec

**The one sentence:** a *baseline‑deviation engine* over dense nocturnal physiology, rendered as one morning decision.

### User‑journey state machine
```
[SLEEP] --overnight passive capture--> [SYNC on wake]
   --> [READINESS COMPUTED] --> (S0) Morning Glance
(S0) --tap--> (S1) Contributor Breakdown --tap--> (S2) Metric Trend
(S0) --live day--> [ACTIVITY ACCRUES] --> [BEDTIME nudge] --> [SLEEP]
```
The entire product is engineered so **S0 answers the day's decision without ever reaching S1.** S1/S2 exist only to *justify* S0 when the user doubts it.

### Data model (reconstructed schema)
```
Night { date, tempDelta, hrvSamples[], restingHR, sleepStages{deep,rem,light,awake}, latency, efficiency }
Baseline { metric, rollingMean, rollingSD, nDays }            // per-metric adaptive normal
Score { date, kind: Readiness|Sleep|Activity, value(0-100), contributors[Contributor] }
Contributor { metric, valueVsBaseline(z), weight, direction }
```

### Baseline engine (the heart)
```
baseline.rollingMean = EMA(metric, halfLife ≈ 14 nights)
baseline.rollingSD   = EMA(|metric - rollingMean|, ...)
z = (tonight.metric - baseline.rollingMean) / max(rollingSD, floor)
confidence = f(nDays)          // low until ~14 nights, disclosed to the user
```
**Key insight:** the score is *never absolute*. "82" means "82 for *you*," and the app spends two weeks earning the right to say it, and *says so*.

### Scoring engine
```
readiness = clamp( Σ_i weight_i * contributorScore_i , 0, 100 )   // weights SUM TO 1
```
Crucially the weights are a proper convex combination; a missing contributor is handled by **renormalizing the remaining weights** — the exact discipline **LOCA's F1 violates.**

### Trust engine
- Every score → named contributors, each shown as deviation‑vs‑your‑baseline.
- Confidence explicitly suppressed during baseline‑building.
- Claims restricted to *physiological readiness* — never emotion. It never says "you feel tired," only "HRV and resting HR are below your baseline."

### Return engine
Morning glance → plan today → behave → **tonight's measurement grades yesterday's choice** → next morning. The loop *closes on the user's own decision*, which is why it's sticky: it's a feedback controller on the user's behavior.

### Value curve (with causes)
| Horizon | Value | Cause |
|---|---|---|
| D1 | "Collecting" | baseline engine has n=1 |
| D7 | provisional scores | n≈7, SD still wide |
| D30 | trustworthy deviations | baseline converged |
| M6 | cycles, seasonality, illness pre‑warning | enough history for periodicity |
| Y2 | deep physiological self‑model | multi‑year archive |

### To rebuild in LOCA
- LOCA needs a **real baseline engine** (per‑dimension EMA + SD with disclosed n) *before* any "above/below baseline" language. Today it uses fixed constants (F6). → **D3/D4**.
- Adopt **convex‑weight renormalization** so a missing source doesn't deflate the score (F1). → **D4**.
- Restrict interpretive claims to what the signal supports (Oura never claims emotion from movement) → LOCA should not claim emotion from checkboxes. → **D4/D1**.

---

## 2. WHOOP — reconstructed as a spec

**The one sentence:** Oura's baseline engine **plus a per‑user causal‑covariate engine** fed by explicit yes/no behavior toggles.

### The extra engine WHOOP runs that Oura doesn't
```
Journal { date, behaviors: {alcohol:bool, caffeineLate:bool, ...} }
Effect { behavior, ΔrecoveryVsAbsent, n, ci }                 // per-user
Effect.compute = mean(recovery | behavior=true) - mean(recovery | behavior=false)
surface(behavior) iff n >= nMin AND ci excludes 0            // hedged
```
This is the **explicit‑input → personal‑evidenced‑insight loop**. The user answers 5 seconds of toggles; weeks later the app pays them back with *"alcohol costs you 22% recovery."* The payback is what makes the toggles worth answering — a self‑reinforcing return engine.

### Data / trust / return
- **Trust engine:** effects are your‑data‑only, shown with n and hedged until significant — never "alcohol is bad," always "for you, so far, n=14."
- **Return engine:** the correlation payback *is* the retention loop, plus a weekly/monthly assessment as an appointment.

### Value curve
D1 collecting → D7 recovery trends → **D30 first personalized correlations** → M6 a behavior↔recovery map → Y2 longitudinal coaching.

### To rebuild in LOCA
- This is **the exact loop LOCA's micro‑check‑ins should power** but currently don't: LOCA collects energy/stress/focus but only surfaces mood patterns (F3), and hides confidence/n (F8). WHOOP shows LOCA precisely what "explicit input becomes a trusted personal insight" looks like end‑to‑end. → **D4 (F3) / D3 (F8)**.
- Copy the **significance gate** (`n >= nMin AND ci excludes 0`) as the rule for *ever* showing a Pattern. → **D3**.

---

## 3. Apple Journal — reconstructed as a spec (the model LOCA should probably become)

**The one sentence:** a *prompt‑ranking engine* over on‑device signals whose only durable output is the user's own writing. **No inference engine at all.**

### The inversion
Oura/WHOOP run a scoring engine and *tell* you something. Journal runs a **ranking engine** and *asks* you something. It never emits a claim, so it has **no trust surface to violate** — the cleverest risk‑elimination move in the category.

### Data model
```
Suggestion { id, kind: photo|workout|place|music|contact|significantLocation, ts, salience, ephemeral:true }
Entry { id, ts, text(user-authored), attachedSuggestions[] }   // the only durable, trusted data
```
Suggestions are disposable scaffolding; the **Entry is the asset.**

### Prompt‑ranking engine (reconstructed)
```
candidates = gather(photos, workouts, visits, nowPlaying, upcomingSignificant)
score(c) = recency * salience(c) * (writePropensityGivenKind(c)) * noveltyPenalty(seen)
surface top-k where k small (calm)
```
It learns *what to prompt*, not *who you are* — a ranking model, not a state model. Failure mode is at worst "a boring prompt," never "a false claim about your feelings."

### Return engine
signal → well‑timed prompt → reflection → **a growing record you reread.** The reward is intrinsic (reflection + autobiography), which is why it compounds without gamification.

### Value curve
D1 a prompt → D7 a few entries → D30 a browsable month → M6 a real record → **Y2 an autobiography** (the compounding, churn‑proof asset).

### To rebuild in LOCA (highest‑leverage borrow in the entire study)
- **Route around D4 entirely.** LOCA already generates the hard part — *well‑timed, personally‑grounded moments* (a completed streak, a chapter boundary, a state shift). Feeding those into a **prompt** instead of a **verdict** converts LOCA's existing pipeline into value **without needing correct inner‑state inference.** → directly answers **D1**, sidesteps **D4**.
- The durable artifact becomes the user's reflections on their own habit data — which is exactly the "truthful long‑term record" the failure analysis (R9) says is the moat.

---

## 4. Exist.io — reconstructed as a spec

**The one sentence:** a *pairwise‑correlation engine* across heterogeneous daily attributes, gated hard on data sufficiency.

### Correlation engine (reconstructed)
```
DailyAttribute { date, key, value }        // sleep, steps, mood, weather, productivity...
for (a, b) in pairs(keys):
    r, n = pearson(alignedDailyValues(a, b, window))
    if n >= nMin and |r| >= rMin and significant(r, n):
        emit Insight(a, b, r, n, direction, strengthWord(r))
    else:
        emit "not enough data yet for a↔b"        // honesty as a first-class state
```
**The exemplary move:** "not enough data yet" is a *rendered state*, not a silence. The product makes its own ignorance visible.

### Trust / return
- **Trust engine:** strength word derived from |r|, sample count shown, weak/insufficient links refused. Never causal — always "these move together."
- **Return engine:** the **weekly review** is a standing appointment; correlations visibly strengthen as data accrues (progressive confidence you can *watch*).

### To rebuild in LOCA
- LOCA's `PatternDetectionEngine` already computes confidence + uncertainty + sampleCount — it should present them exactly like Exist (strength word + n + "not enough data yet"), instead of hiding them (F8) and only doing mood (F3). → **D3/D4**.
- Steal the **"not enough data yet" as a visible state** for every Life surface — it turns emptiness into honesty (LOCA's empty states already lean this way; extend it to claims, not just cards).

---

## 5. Daylio — reconstructed as a spec

**The one sentence:** a *friction‑minimized capture engine* + streak return engine, with **zero** inference and therefore zero trust risk.

### Why it wins with no AI
```
Entry { ts, mood: enum(1..5), activities: tag[] }   // ~2 taps, <5s
Stat  = literal counts & averages (mood by activity, mood over time)
```
There is nothing to hallucinate. The scoring engine is `AVG()`. The genius is that it never pretends to be more than a diary — and diaries, kept, are valuable (R2).

### Return engine
daily reminder → 5‑second entry → streak → loss aversion. The **capture engine's low friction is the whole moat**; every added second of friction would kill the streak.

### To rebuild in LOCA
- LOCA's own habit‑logging *is already this* (fast, honest, real). The lesson is **restraint**: the parts of LOCA that make *no* claims (streaks, counts, weekly/monthly rollups) are its most trustworthy surfaces. Lead with them; don't bury them under fragile inference. → **D1**.

---

## 6. Finch — reconstructed as a spec

**The one sentence:** a *relatedness engine* — an emotional debtor (the pet) that converts self‑care into caring‑for‑another.

### The mechanism (SDT relatedness, operationalized)
```
Pet { energy, growthStage, bond }
onSelfCareAction(user): pet.energy += ; pet advances; bond +=
onAbsence: pet waits (never punishes harshly)                 // guilt-light
```
No inference, no analytics — a **pure return engine.** It answers "why open tomorrow?" with "something depends on you," which outperforms metrics for the anxious/younger segment.

### To rebuild in LOCA (carefully)
- LOCA's return engine is currently *empty* on the Life side. Finch shows a return engine need not be analytical — but **gamification must not substitute for insight** (R9 anti‑pattern). The honest LOCA analog is not a pet; it's the **reflection record that grows** (Journal's intrinsic version), which is a healthier relatedness ("my life story is accumulating") than an artificial dependent. → **D1**.

---

## 7. Rise Sleep, Apple Health, RescueTime, Rewind — compact reconstructions

- **Rise Sleep:** `sleepDebt = Σ(need − actual)`; circadian model → predicted energy curve. One transparent formula → one plannable number. *Borrow:* a single legible daily number beats a paragraph.
- **Apple Health:** `Sample{value, source, ts}` with **source mandatory**; engine = trends, inference ≈ none. *Borrow:* provenance is a schema constraint, not a screen — the structural fix for Sarah/Alex (F7). → **D2**.
- **RescueTime:** category rules + **user relabeling** (user‑as‑corrector) → productivity score. *Borrow:* make the user the corrector of LOCA's classifications (dimension tags, people). → **D4** (feedback loop LOCA has in backend, `FeedbackProcessor`, but doesn't surface).
- **Rewind:** pure **retrieval** (index + search), no claims. *Borrow:* "search your own logged life" is a zero‑hallucination feature LOCA could offer over its truthful record.

---

## 8. The graveyard — reconstructed as failed machines

| Dead product | Which of the 5 engines was missing/broken | The fatal consequence |
|---|---|---|
| Google Now | **Trust engine absent** (opaque prediction) | users couldn't tell why a card appeared → distrust → abandonment |
| Human, Moves | **Inference + return engines absent** (capture only) | novelty wore off, nothing to return for → churn |
| Jawbone, Basis | external dependency (hardware) broke the **capture engine** | device/company failure ended the product |

**LOCA's current exposure:** its **trust engine is inverted** (computes then discards provenance — F8), its **scoring engine is fraudulent** for sensor‑poor users (F1 deflation), and its **return engine is absent** on the Life side. That is *three* of the four historical death patterns simultaneously. This is the single most important output of the reverse‑engineering: **LOCA today is assembled like the products that died, not the ones that lived.**

---

## 9. LOCA V3 — the machine, assembled deliberately

Reverse‑engineering lets us *specify LOCA's five engines on purpose* instead of by accident:

1. **Capture engine:** keep habit logging (fast, real — Daylio‑grade) + optional passive Health + explicit micro‑check‑ins (WHOOP‑style toggles for state).
2. **Baseline engine:** *new, required* — per‑dimension EMA+SD with disclosed n (Oura). No "vs baseline" language until it exists. Kills F6.
3. **Scoring engine:** convex‑renormalized weights (Oura discipline) — or, preferably, **no inner‑state score at all** until earned signal exists. Kills F1/F2.
4. **Trust engine:** provenance‑by‑schema (Apple Health) + hedged, n‑gated correlations (Exist) + user‑as‑corrector (RescueTime, surfacing LOCA's existing `FeedbackProcessor`/`SensorConflict`). Kills F7/F8.
5. **Return engine:** *new, required* — **Apple Journal's prompt→reflect→record loop** as the primary Life beat, giving a daily reason to return that needs no correct inference. Answers D1.

**The thesis of the whole teardown:** LOCA has been building engines #1 and #3 (capture + scoring) heavily, #4 (trust) backwards, and #2 and #5 (baseline + return) not at all. The living products are strong on #2, #4, #5. **V3 is not new features — it is building the three engines LOCA is missing and inverting the one it built backwards.**

### Engine‑by‑engine scoreboard

| Engine | Living products | LOCA today | V3 action |
|---|---|---|---|
| Capture | strong | strong (habits real) | keep + add earned signal |
| Baseline | strong (Oura/WHOOP) | **absent** (F6 constants) | **build** |
| Scoring | convex, earned | **fraudulent** (F1/F2) | fix or **remove** |
| Trust | by‑construction | **inverted** (F7/F8) | **invert back** |
| Return | strong (Journal/Finch/Oura) | **absent** on Life side | **build (Journal model)** |

---

*Next deep teardown candidates if you want to keep going far: a full reconstruction of Oura's readiness math and WHOOP's correlation gating as reference algorithms LOCA can port, and a "LOCA V3 engine spec" doc that turns section 9 into an implementable design.*
