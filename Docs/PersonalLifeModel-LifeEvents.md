# The Life Events Engine — Change Points as First-Class Anchors

## Phase P — Session P3 · The Fifth Entity

> *No UI. No SwiftUI. No code. This session adds a subsystem the first two documents
> only hinted at. P1 (`PersonalLifeModel.md`) mentioned "explicit life-change signals"
> as a trigger for a re-learning burst (§5.4); P2 (`…-LearningEngine.md`) folded them
> into generic "drift." That is underpowered. **Life events are not drift. They are a
> distinct kind of object** — dated, rare, high-impact structural breaks that change
> the statistics of everything after them — and they must be a first-class entity
> alongside episodes, daily states, dispositions, and context entities.*

> New job · graduation · promotion · breakup · marriage · moving cities · vacation ·
> illness · death of someone close · financial milestones. These are not big days.
> They are the punctuation of a life, and they explain why behavior shifts over months
> and years.

---

## 0. Status and relationship to P1/P2

**Status:** Foundational addition. This session **elevates** life events from a
detection trigger to a first-class model entity with its own engine. It does not
contradict P1/P2; it completes their model layer. Two small forward-pointers are added
to P1 (§4.1 gains a fifth entity; §5.4's "life-change" hint now routes here).

**The one-sentence thesis:** *Every other entity in the model describes the life; life
events are the operator that rewrites it.* A move retires a whole set of place-entities
and creates new ones. A breakup collapses a person-entity's positive edges. A new job
resets the baselines of half the daily states. Life events are not another noun in the
model — they are the **verbs that edit the model**, and a system that cannot represent
its own edits cannot stay coherent across years.

---

## 1. Why a life event is a distinct entity (the ontology)

The load-bearing claim is that a life event is *none of the existing four things*. The
cleanest technical statement: **everything else in the model assumes a locally
stationary data-generating process; a life event is exactly a point where stationarity
breaks.**

| Existing entity | What it is | Why a life event is not this |
|---|---|---|
| **Episode** (min–hrs) | A lived experiential unit; a data *point* | An event is dated but its effects are **non-local** — it changes the *distribution* of all future episodes. An episode is a sample; an event changes the process the samples come from. |
| **Daily state** (hrs–day) | A transient variable that reverts to baseline | An event doesn't fluctuate around the baseline — it **moves the baseline itself.** States vary around a mean; events reset the mean. |
| **Disposition / trait** (wks–yrs) | A slow-moving *property* of the person | An event is not a property — it's a dated *occurrence*. Events and traits interact (events *cause* trait shifts; traits govern the *response* to events), which is precisely why the event must be its own object connecting to traits rather than being one. |
| **Context entity** (persistent) | A *recurring* participant (person, place) accruing effect through repeated encounters | An event is (mostly) **singular and dated**; its effect is its *aftermath*, not repeated encounters. And events **act on** context entities — creating, destroying, or re-weighting them — so they cannot live at the same layer. |

The final row is the decisive one. Because a life event **operates on the other
entities** — it is the thing that rewrites your places, your people, and your baselines
— it categorically cannot be one of them. It sits above the daily model and edits it.

### The data-generating-process framing

The learning engine (P2) is a stationarity machine: it learns baselines, personalizes
a signal→state mapping, and predicts the near future by assuming tomorrow is drawn from
roughly the same process as last month. Life events are the **regime boundaries** where
that assumption is false by design. The model must represent them explicitly, because
the alternative is to let the stationarity assumption quietly corrupt itself (§2).

---

## 2. What breaks without a first-class Life Events Engine

If life events are treated as ordinary anomalous episodes or as slow drift, three
failures follow — each severe, each silent:

1. **Averaging across a discontinuity.** The single worst statistical error a
   longitudinal model can make: fitting one baseline through data that has a clear
   break. A person who moved cities has two sleep regimes; a model without the event
   blends them into a muddy mean that describes *neither* — and then reports low
   confidence forever, unable to explain why the person "got inconsistent." The break
   isn't noise; it's the most important structure in the series.

2. **Spurious cross-regime correlations.** After a breakup, mood *and* exercise *and*
   sleep all drop together. A model that computes correlations across the unmarked
   break will "learn" that exercise causes mood causes sleep — a Simpson's-paradox
   confound where the true common cause is the event. Uncontrolled regime boundaries
   manufacture false edges in the relationship graph, poisoning exactly the causal
   understanding P2 works to keep honest.

3. **Lost explanations — the biggest one.** The brief's own payoff list asks *"what
   life changes made the biggest difference?"* That question is *unanswerable* without
   life events as entities, because the answer literally is a life event. A model that
   can't name the change can only say "something shifted in March" — the difference
   between an app that tracks you and one that **understands your life**.

A first-class Life Events Engine exists to prevent all three: it marks the breaks,
scopes learning to regimes, controls correlations for regime, and turns the break into
a named anchor the whole model can explain the future against.

---

## 3. Scientific spine

- **Change-point / structural-break detection** *(Bai–Perron; CUSUM; Bayesian online
  change-point detection, Adams & MacKay).* A time series can be segmented into regimes
  separated by change points; detecting them is a well-posed statistical problem. A
  life event is the *cause* behind a detected change point — often a **coordinated**
  break across many series at once (§7).
- **Regime-switching models** *(Hamilton).* Behavior is generated by a latent regime
  that occasionally switches; parameters are regime-specific. The Life Events Engine is
  a regime layer over the daily model.
- **Interrupted time-series & natural experiments** *(quasi-experimental design).* A
  dated exogenous shock lets you estimate its effect by contrasting pre- and post-event
  trajectories — the cleanest causal leverage available without randomization. Life
  events are the naturally-occurring interruptions that make within-person causal claims
  possible (§9).
- **Stress & adjustment literature** *(life-events / SRRS lineage; grief and recovery
  trajectories; hedonic adaptation).* Major life changes have characteristic **onset
  shapes and recovery curves** — steps, ramps, shocks-with-partial-recovery — and people
  adapt over time. This dictates that an event is modeled as a *trajectory*, not a flag
  (§10).

---

## 4. A taxonomy that changes the modeling

The user's list is not a flat set — organizing it along **modeling-relevant dimensions**
is what makes the engine work, because each dimension changes how the event is fit.

### 4.1 By onset shape (what curve to fit)

- **Step** — sharp, near-instant regime change: *moving cities, marriage, graduation,
  starting/ending a job.* Fit a level shift at a datable point.
- **Ramp** — gradual adjustment into a new regime: *a new job's first months, a
  promotion's added load.* Fit a transition slope, not a step.
- **Shock + recovery** — a large dip then partial return toward (a possibly new)
  baseline: *bereavement, illness, breakup, financial loss.* Fit a drop and a recovery
  trajectory; the recovery *rate* is itself valuable (§9).
- **Pulse / temporary regime** — a bounded interval that reverts: *vacation, acute
  illness.* Model a temporary sub-regime that must **not** overwrite the standing
  baseline (§6b).

### 4.2 By valence (how to interpret and how to speak)

- **Positive:** promotion, marriage, graduation, financial milestone.
- **Negative:** breakup, bereavement, illness, job loss.
- **Mixed / disruptive-positive:** a new job, moving, even marriage — good *and*
  destabilizing at once. Valence must be allowed to be **mixed**; forcing it to a sign
  is a modeling and a tact error (§12).

### 4.3 By reversibility (permanent vs temporary re-baseline)

- **Permanent regime change:** move, marriage, bereavement, career change → re-baseline
  the model going forward.
- **Temporary regime:** vacation, acute illness → a bounded sub-regime that reverts; the
  pre-event baseline is preserved and resumed.

### 4.4 By anticipation (look for pre-event effects?)

- **Anticipated:** planned wedding, graduation, scheduled surgery, booked vacation —
  often show a **pre-event ramp** (wedding stress, exam-period changes) that the engine
  should attribute to the coming event, not mistake for unexplained drift.
- **Sudden:** unexpected death, sudden illness, layoff — no pre-signal; a clean shock.

None of this is bureaucratic labeling. Onset shape picks the fit; reversibility picks
permanent vs temporary baseline; anticipation decides whether to hunt for pre-event
signal; valence governs both interpretation and the tact rules for ever speaking of it.

---

## 5. The Life Event entity (schema-level, conceptual)

A first-class entity, sibling to the others, carrying at minimum:

- **Identity & type** — from the taxonomy (§4), with its onset-shape, reversibility, and
  anticipation tags.
- **Onset as a distribution, not a point.** Events have fuzzy starts — a breakup is a
  process, not a timestamp. Store an estimated onset *window* with uncertainty; the
  segmentation boundary (§6a) is placed within it.
- **Detection confidence & provenance** — how the event was surfaced (coordinated
  passive break, semantic hook, user-authored) and how sure the engine is *that* it
  happened and *what* it was — kept separate.
- **Valence** — signed or **mixed** (§4.2).
- **Magnitude & scope** — how large the break, and **which subgraph** it re-baselined
  (which states, traits, context entities, and by how much).
- **Onset & recovery trajectory** — the fitted curve (step / ramp / shock+recovery /
  pulse) and, for shocks, the recovery rate and whether baseline fully returned.
- **Expected-vs-observed impact** — the population prior for this event type ("moving
  disrupts sleep for ~N weeks") against this person's actual response (§8, §9).
- **Edges to other entities and events** — what it created/destroyed/re-weighted, and
  causal links to other events (§11).

Note the deliberate separation of *"something broke"* (high-confidence, passive) from
*"it was a new job"* (the label, sometimes needing one question) from *"here's its
effect"* (estimated over the following weeks). These three have different confidences
and arrive at different times.

---

## 6. The four jobs of a life-event anchor

Once anchored, a life event does four things no other entity can:

**(a) Regime segmentation.** It splits the timeline into before/after (or brackets a
temporary sub-regime). All baselines, priors, and notions of "normal" become
**regime-scoped**. "Your normal bedtime" is answered per regime, not globally.

**(b) Regime-aware re-baselining.** Post-event data trains a *new* baseline instead of
polluting the old one; the learning engine stops averaging across the break (§2.1). For
temporary regimes (vacation), the ten anomalous days are quarantined so they never
corrupt the standing baseline — and the pre-event baseline resumes automatically on
reversion.

**(c) Confounder control for correlations.** Any relationship-graph edge whose evidence
spans an event is re-examined **within regime** and checked for the event as a common
cause (§2.2). This is the mechanism that keeps the causal graph from manufacturing false
edges around every life change.

**(d) Explanation & narrative anchoring.** The event becomes the *why* behind sustained
shifts — the anchor an Insight Return points to: *"your evenings have been calmer since
you moved in March."* This is what turns a pile of numbers into an understood life, and
what finally answers *"what life changes made the biggest difference?"*

---

## 7. Detection — passive-first, per P2

The Life Events Engine obeys P2's discipline: **detect passively; the streams reveal
events before the user reports them.** The signature of a life event is distinctive.

- **Coordinated multi-signal break is the fingerprint.** Ordinary drift is *one* node
  wandering. A life event is **many nodes breaking at once, coherently.** A move: home
  location cluster changes + commute changes + sleep timing shifts + a new set of places
  appears. A new job: calendar structure changes + wake time shifts + location changes +
  stress rises. A breakup: communication with one person-entity collapses + location
  patterns change + mood/sleep shift. Bereavement: comms collapse + a calendar anomaly
  (funeral/travel) + a sustained negative shift. **Simultaneity and coherence across
  streams** is what separates an event from noise and from slow drift.
- **Cheap semantic hooks.** Calendar strings ("Move day", "First day", "Wedding"),
  significant contact/relationship changes, photo-event clusters, PTO/holiday patterns
  for vacation. These are low-cost passive labels that often *name* the event for free.
- **Habits as corroboration.** A coordinated break in habit adherence (P1's certain
  *what*) is strong evidence a regime changed and helps date it.
- **Classification: noise vs drift vs event.** The detector's job is a three-way call.
  Small/incoherent → **noise** (model as aleatoric, P2 §3.1). Single-node, gradual →
  **drift** → slow re-personalization (P2 §4.4). Multi-node, coherent, sustained →
  **event** → segment, characterize, anchor. *This is the elevation the user asked for:
  drift detection is the sensor; the Life Events Engine is the interpreter that decides
  a break deserves to become an anchor.*
- **Onset as a window.** Because events have fuzzy starts, detection yields an onset
  *distribution*; the segmentation boundary is placed to best separate the two regimes
  within that window.

---

## 8. Labeling — the one question worth its debt

Detecting *that* a coordinated break happened is passive (an asset). Naming *what* it
was is sometimes passively unreachable — the streams can show a move, a new job, and an
illness as similar disruptions. This is the **premier legitimate borrower** under P2's
four-gate underwriting test (§6.1):

1. **Reducible** — the ambiguity is epistemic, not noise. ✓
2. **Passively unreachable** — no fusion reliably distinguishes the candidate labels, and
   waiting won't name it. ✓
3. **High value** — a single label anchors *years* of correct re-baselining and
   explanation. The highest-ROI question in the entire system. ✓
4. **Time-sensitive** — best anchored near the event, while the person can still confirm
   it, and before months of data are mis-attributed. ✓

So a suspected high-magnitude event may justify **one** gentle, once-per-event probe —
never "how was your day," but a single high-density confirm: *"Something seems to have
shifted around early March — did something big change?"* Often the label is already
free (the calendar said "First day at Acme"); often the user volunteers it. And
**population priors warm-start both the signature and the impact** (P2 §4.3): the engine
ships knowing what a move looks like across streams and that moves disrupt sleep for a
while, then personalizes. Even a person's first life event is interpretable.

Critically, per the debt/asset law: the engine still **prefers not to ask.** If the
label is inferable or the re-baselining works without a name, it stays silent and
anchors an *unlabeled* regime change — a valid, useful object on its own.

---

## 9. Life events as natural experiments (the asset framing)

Life events are not only structure to control for — they are the **most information-rich
passive experiments the world runs for free**, and the learning engine should exploit
them as such.

You cannot measure how someone responds to stress without stress. Reactivity, recovery
rate, adaptability, resilience, and the *load-dependence* of every sensitivity
(does exercise still lift mood under grief? does this person's sleep collapse or hold
under a new job?) are **only observable through perturbation.** Each life event is an
interrupted time-series (§3) that lets the engine estimate these otherwise-hidden
dispositions from the pre/post contrast — no question required.

This closes a loop with P2: dispositions that looked un-learnable in a stationary life
become learnable *because* life events perturb the system. The Life Events Engine is
therefore both a **confound controller** (§6c) and a **disposition discovery engine**.
A person's resilience is not asked; it is measured from how their trajectory recovered
after the shocks life already delivered.

---

## 10. Recovery dynamics and temporary regimes

- **Model trajectories, not flags.** A bereavement is a drop and a slow, often partial,
  recovery — not a step. Fitting the recovery curve yields the recovery *rate* (a trait,
  §9) and whether baseline fully returned or permanently shifted. An engine that models
  the event as an instantaneous flag throws away its richest signal.
- **Temporary regimes must quarantine, not overwrite.** Vacation and acute illness are
  bounded sub-regimes (§4.3). Their days must be walled off from the standing baseline
  and the pre-event normal resumed on reversion — otherwise two weeks of vacation sleep
  redefine "normal" and the model reports false drift for a month afterward.
- **Anticipation windows.** For anticipated events (§4.4), attribute pre-event ramps
  (wedding stress, exam period) to the coming event rather than logging them as
  unexplained drift.

---

## 11. Events cause events

Life events are nodes that can link to **each other**, not only to states: a breakup →
a move → a new job is a common chain. Representing an event graph lets the engine avoid
double-counting three coordinated breaks as three independent shocks when they are one
cascade, and lets explanations trace a root cause (*"the changes this spring trace back
to the move"*). This is higher-order and can arrive after the core engine, but the
entity model should leave room for event→event edges from the start.

---

## 12. Trust, sensitivity, and consent — at maximum force

Life events include the most vulnerable moments a person has: death, illness, breakup,
job loss. P1 §11's creepiness-line discipline applies here with the least tolerance for
error anywhere in the product.

- **Detection is never a pronouncement.** The engine may infer a bereavement from the
  signal; it must **never** blurt "did someone die?", never surface a sensitive inferred
  event unprompted, and never be cheerful or nudge-y in the aftermath of a negative
  event. Model privately; speak modestly, or not at all.
- **The one justified probe (§8) is handled with the most care in the product.** Gentle,
  optional, instantly dismissable, never prying. *"Something seems to have shifted
  lately"* is safer than naming a painful thing the user may not want named by an app.
  For clearly-negative detected events, the correct default is often to **re-baseline
  silently and ask nothing.**
- **Full user authorship and the right to be forgotten.** Users can add, rename,
  re-date, correct, or **delete** any life event — including redacting a painful one so
  it is never referenced again — and the model must honor the deletion (forgetting is
  first-class, P1 §11). A user may also mark an event *"use to understand me, but never
  mention."*
- **No exploitation of vulnerability.** A detected negative event must **never** be used
  to drive engagement, retention, or upsell. This is a hard line.
- **Sensitive-band consent.** Some events the model may quietly use to re-baseline and
  improve predictions without ever naming them aloud; anything more explicit is opt-in.

The governing rule, sharpened for this subsystem: **the model's understanding of a life
event may be deep, but what it says about it must always stay a large step behind what
it could say — and around grief and loss, that step is largest.**

---

## 13. Integration — how the model changes

- **The model gains a fifth entity (updates P1 §4.1).** The layer list becomes:
  episodes, daily states, dispositions/traits, context entities, **and life events** —
  the regime layer that sits above the daily model and scopes all baselines.
- **The relationship graph gains event nodes and regime scoping (updates P1 §4.2).**
  Edges are computed within regime; events appear as high-degree explanatory nodes and
  as common-cause controls.
- **Drift is repositioned (updates P1 §5.4 / P2 §3–4).** The "explicit life-change
  signal" P1 hinted at is now this subsystem. Drift detection is the *sensor*; the Life
  Events Engine is the *interpreter* that classifies a break as noise, drift, or event
  and, if an event, anchors it. P2's re-personalization handles gradual drift; the Life
  Events Engine handles structural breaks — two different responses to two different
  phenomena the earlier docs had conflated.
- **The learning engine consumes events as its highest-value structure.** Regime
  segmentation makes every baseline and correlation honest; natural-experiment leverage
  (§9) makes dispositions learnable. Events *improve* the passive engine rather than
  competing with it.
- **Habits corroborate and date events** (§7) and, conversely, events explain habit
  failures — directly answering P1's *"what causes habit failures?"* (a job change, an
  illness) by pointing at the anchor rather than a daily state alone.
- **On-device and local-first, necessarily.** Life events are the most sensitive data in
  the model; they never leave the device. Passive-first and local-first remain the same
  commitment (P2 §9).

---

## 14. Failure modes / anti-patterns

1. **Treating an event as an anomalous episode.** Loses the regime break; the model
   averages across the discontinuity (§2.1). The defining failure this subsystem exists
   to prevent.
2. **Treating every break as slow drift.** Under-reacts to sharp regime changes; chases a
   step with a slow personalization loop and stays wrong for months.
3. **Overwriting the baseline on a temporary regime.** Letting a vacation redefine
   "normal" (§10). Quarantine, don't absorb.
4. **Forcing valence to a sign.** Coding marriage or a new job as purely positive erases
   its real disruption and mis-fits the trajectory (§4.2).
5. **Fitting a flag instead of a trajectory.** Throws away recovery-rate and adaptation
   signal — the very things that make events valuable for learning traits (§9, §10).
6. **Manufacturing false edges across an unmarked break.** Uncontrolled regime confounds
   (§2.2). Every cross-event correlation must be regime-checked.
7. **Over-detecting events from single-stream wobble.** Requiring only *coherent,
   multi-stream, sustained* breaks to promote to an event (§7) is the guard.
8. **Tactless disclosure.** Any insensitive surfacing of a sensitive inferred event
   (§12). The gravest possible trust failure in the product.
9. **Nagging for a label the engine could infer or live without.** Violates the debt/
   asset law; an unlabeled regime anchor is a valid object (§8).

---

## 15. Evaluation

Extends P2 §10 with event-specific metrics:

| Criterion | Target |
|---|---|
| **Detection precision/recall** | Coordinated breaks map to real events (recall) without over-firing on wobble (precision); confirmed against user-authored/known events. |
| **Onset dating accuracy** | Estimated onset window contains the true event date. |
| **Re-baselining benefit** | Post-event predictive accuracy is higher *with* the regime split than without — the direct payoff of anchoring. |
| **Confound reduction** | Cross-event correlations that vanish under regime control (false edges prevented). |
| **Label economy** | Events correctly anchored (labeled or usefully unlabeled) **per question asked** — should be ≫ the naive one-question-per-event. |
| **Disposition gain from events** | Traits like recovery rate/resilience become estimable after events that were un-learnable before (§9). |
| **Sensitivity compliance** | Zero tactless disclosures; negative events default to silent re-baselining; deletions fully honored (§12). |

---

## 16. Open questions for the next session

1. **Detector mechanics.** What on-device multi-stream change-point method yields
   coordinated-break detection with calibrated confidence cheaply (a Bayesian online
   change-point model over fused signals, a CUSUM ensemble, something lighter)?
2. **Regime representation in schema.** How do regimes and the event entity map onto
   SwiftData `@Model` types, and how do baselines become regime-scoped without
   recomputing history on every query?
3. **Onset-window estimation.** How is the fuzzy onset distribution estimated and the
   segmentation boundary placed?
4. **Population priors for events.** Where do shipped event *signatures* and *impact
   curves* come from (offline-learned, on-device personalized), and how are they kept
   non-stereotyped and current (P2 §11)?
5. **Trajectory fitting.** Minimal viable models for step / ramp / shock+recovery /
   pulse, and how recovery-rate is extracted as a trait.
6. **The label decision.** Concretely, when does the four-gate test (§8) fire a probe vs
   anchor an unlabeled regime, and how is the sensitive-event tact policy encoded?
7. **Event graph.** How and when to introduce event→event causal edges (§11) without
   overfitting cascades.
8. **Temporary-regime lifecycle.** How a bounded sub-regime is opened, quarantined, and
   auto-closed on reversion (§10).

Like P1 and P2, this document is foundational but not frozen. Feedback on the ontology
(§1), the drift-vs-event split (§7), the natural-experiment framing (§9), or the
sensitivity discipline (§12) is welcome before the next session commits to mechanics.
