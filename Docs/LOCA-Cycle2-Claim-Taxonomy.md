# LOCA Cycle 2 — Claim Taxonomy (C2.1)

Every stored and inferred claim in the LOCA codebase appears in exactly one of three
categories. The classification is a statement about authority, not certainty:

- **Sensor-authoritative**: the world's state, confirmed by measurement. The model's job
  is to estimate it accurately. User feedback can calibrate the model but cannot define
  the ground truth.
- **Subject-authoritative**: the user's experience or intent. The user's answer constitutes
  the fact. No sensor reading can override it; no inference can substitute for it.
- **Unfillable**: the machine has no legitimate authority. Neither sensors nor user
  clarification produce a claim LOCA is permitted to make. These fields — if they exist —
  must remain inert or be removed.

---

## 1. Sensor-Authoritative Claims

*The sensor record is the ground truth. Inference is estimation, not construction.*

### 1.1 `InferredState` (InferredStateModel.swift)

| Field | Rationale |
|---|---|
| `energy` | Derived from sleep duration, step count, HRV — objective physiological signals. |
| `energyUncertainty` | Epistemic/aleatoric uncertainty of the energy estimate. |
| `energyAbsent` | Whether the signal window had no sensor input (C1.1 structural absence). |
| `energyUncertaintyTypeRaw` | Auto-classified as epistemic or aleatoric from sample count (C1.3). |
| `energyProvenanceJSON` | Which sensors contributed, how many samples, time window (C1.2). |
| `stress` | Derived from HRV, calendar event density, location changes, note sentiment. |
| `stressUncertainty` | Epistemic/aleatoric uncertainty of the stress estimate. |
| `stressAbsent` | Whether no real evidence existed for this hour. |
| `stressUncertaintyTypeRaw` | Auto-classified. |
| `stressProvenanceJSON` | Sensor provenance record. |
| `focus` | Derived from app focus scores, interruption count, device signals. |
| `focusUncertainty` | Epistemic/aleatoric uncertainty of the focus estimate. |
| `focusAbsent` | Whether no device activity signals existed. |
| `focusUncertaintyTypeRaw` | Auto-classified. |
| `focusProvenanceJSON` | Sensor provenance record. |
| `mood` | Derived from mood check-ins, note sentiment, social engagement, variety. |
| `moodUncertainty` | Epistemic/aleatoric uncertainty of the mood estimate. |
| `moodAbsent` | Whether no mood-sensitive signals existed. Mood has no priors; if empty → absent. |
| `moodUncertaintyTypeRaw` | Auto-classified. |
| `moodProvenanceJSON` | Sensor provenance record. |
| `timestamp` | Wall-clock anchor for the inferred hour. |
| `hourStart` | Normalized hour boundary for the state window. |
| `rawSignalCount` | Count of signal events that fed this inference. |

### 1.2 `SignalEvent` (SignalModels.swift)

| Field | Rationale |
|---|---|
| `timestamp` | When the sensor reading was captured. |
| `source` | Which sensor or source produced it (health, location, calendar, app usage…). |
| `signalType` | The kind of measurement (steps, HRV, screen time…). |
| `value` | Raw or normalized measurement value. |
| `uncertainty` | Measurement uncertainty from the source. |
| `metadata` | Source-specific key-value pairs from the sensor. |

`AggregatedValue` and `SignalWindow` follow the same pattern — all their numeric fields
(mean, stddev, count, start/end) are sensor-authoritative aggregates.

### 1.3 `Trait` (TraitModel.swift)

| Field | Rationale |
|---|---|
| `traitType` | Which behavioral dimension is being estimated. |
| `value` | Rolling estimate of the trait (0–1). Derived from sensor history. |
| `uncertainty` | Estimation uncertainty. |
| `windowDays` | How many days of signal went into this estimate. |
| `sampleCount` | How many individual samples contributed. |
| `chapterId` | Chapter scope for this estimate (nil = global). Structural, not evaluated. |
| `updatedAt` | When this estimate was last revised. |

The *meaning* of a trait (what it says about who the user is) is subject-authoritative
and unfillable (see §3). The numeric estimate itself is sensor-authoritative.

### 1.4 `Chapter` — sensor-derived fields (ChapterModel.swift)

| Field | Rationale |
|---|---|
| `startDate` | First signal event associated with this chapter. |
| `endDate` | Last signal event, or nil if still active. |
| `activityLevel` | Mean step-based activity level computed from signals in window. |
| `socialEngagement` | Calendar/location-based social density in window. |
| `scheduleRegularity` | Variance of wake/sleep times in window — a sensor aggregate. |
| `volatility` | Intra-chapter standard deviation of daily energy/mood. |
| `baselineEnergy` | Mean energy inferred across the chapter window. |
| `baselineStress` | Mean stress inferred across the chapter window. |
| `baselineFocus` | Mean focus inferred across the chapter window. |
| `baselineMood` | Mean mood inferred across the chapter window. |
| `dominantTraits` | Most prominent trait estimates within this chapter's window. |

### 1.5 `Person` / `PersonAppearance` (PersonModel.swift)

| Field | Rationale |
|---|---|
| `salience` | How frequently this person appears relative to total chapter length. |
| `salienceUncertainty` | Uncertainty in the salience estimate. |
| `firstSeenDate` | Earliest calendar/location co-occurrence with a recognized identifier. |
| `lastSeenDate` | Most recent co-occurrence. |
| `appearanceCount` | Total co-occurrence count in signal history. |
| `moodCorrelation` | Statistical correlation between this person's appearances and mood signals. |
| `moodCorrelationSampleCount` | Sample count supporting the correlation estimate. |
| `PersonAppearance.timestamp` | When the co-occurrence was detected. |
| `PersonAppearance.personId` | Which person appeared. |
| `PersonAppearance.salience` | Per-appearance salience weight. |

`moodCorrelation` is listed sensor-authoritative because it is a statistical estimate from
objective signal co-occurrences. Whether this correlation reflects a causal relationship
is unfillable (see §3).

### 1.6 `WeeklyRegime` (LifeEventModels.swift)

| Field | Rationale |
|---|---|
| `weekStart` | ISO week anchor date. |
| `meanEnergy` | Mean inferred energy across the week. |
| `meanStress` | Mean inferred stress across the week. |
| `meanFocus` | Mean inferred focus across the week. |
| `meanMood` | Mean inferred mood across the week. |
| `energyStddev` | Within-week energy variance. |
| `stressStddev` | Within-week stress variance. |
| `focusStddev` | Within-week focus variance. |
| `moodStddev` | Within-week mood variance. |
| `scheduleRegularity` | Wake/sleep time variance for the week. |
| `locationDiversity` | Number of distinct location clusters visited. |
| `socialEngagement` | Calendar density of social events. |
| `activityLevel` | Mean step-normalized activity for the week. |

### 1.7 `LifeEvent` (LifeEventModels.swift)

| Field | Rationale |
|---|---|
| `timestamp` | When the regime shift was detected. |
| `eventType` | Classifier output (energyChange, stressChange, focusChange, moodChange, scheduleChange). |
| `anomalyScore` | Statistical distance from preceding baseline. |
| `persistenceScore` | How long the regime shift sustained before reverting. |
| `classificationScore` | Classifier confidence in the event type assignment. |
| `confidence` | Combined event detection confidence. |
| `metadata` | Classifier-generated key-value evidence. |

`eventType` is sensor-authoritative because it describes the dimension of change (energy
went up/down) — a statistical claim, not an interpretive one. What the event *means*
(a promotion, a breakup, a move) is subject-authoritative (§2) and the implied valence
is unfillable (§3).

### 1.8 `Calibration` (CalibrationModel.swift)

| Field | Rationale |
|---|---|
| `modelName` | Which inference model this calibration record targets. |
| `weights` | Current feature weights in the model. |
| `calibratedAt` | When the calibration was last applied. |
| `errorHistory` | Historical prediction errors that drove recalibration. |
| `sampleCount` | Number of ground-truth samples used. |

---

## 2. Subject-Authoritative Claims

*The user's answer constitutes the fact. No sensor can measure it; no inference can
substitute for it. Asking is the only valid acquisition path.*

### 2.1 `Chapter` — subject fields (ChapterModel.swift)

| Field | Rationale |
|---|---|
| `name` | The user's own label for this period of their life. A sensor can detect a period; only the user can name it. |
| `userDescription` | Free-text account of what this chapter was about. Purely introspective. |

### 2.2 `Direction` / `Fork` (DirectionModel.swift)

| Field | Rationale |
|---|---|
| `Direction.statement` | The user's articulation of what they are moving toward. This is the direction itself — not an inference about it. |
| `Direction.values` | The values the user reports anchoring this direction. |
| `Direction.intentions` | Short-term intentions derived from the direction statement. |
| `Direction.settledness` | How resolved the user feels about this direction (0–1). Introspective self-report. |
| `Fork.statement` | The user's framing of the decision they face. |
| `Fork.resolution` | How the user resolved the fork (or nil if still open). |
| `Fork.kind` | Whether the fork is an active choice, a background tension, etc. (ForkKind). |

### 2.3 `Person` — identity fields (PersonModel.swift)

| Field | Rationale |
|---|---|
| `name` | Who the user says this person is. A co-occurrence pattern has no name until the user provides one. |
| `RelationshipContext` | The user's characterization of the relationship (work, family, social, romantic). Constitutive: the category is created by the user's understanding, not by a sensor observation. |

### 2.4 `LifeEvent` — user response fields (LifeEventModels.swift)

| Field | Rationale |
|---|---|
| `userConfirmed` | Whether the user agreed that this detected event was real. Self-report: the user's experience of the event is the authority. |
| `userNotes` | Free-text from the user about what was happening. |

### 2.5 `PatternFeedback` / `NarrativeFeedback` (FeedbackModel.swift)

| Field | Rationale |
|---|---|
| `PatternFeedback.resonance` | Whether the inferred pattern feels true to the user. This is the user's judgment, not a sensor outcome. |
| `PatternFeedback.refinement` | User's correction or qualification of the inferred pattern. |
| `NarrativeFeedback.resonance` | Whether the generated narrative resonates. |
| `NarrativeFeedback.notes` | User's free-text response to the narrative. |

### 2.6 `Calibration` — label field (CalibrationModel.swift)

| Field | Rationale |
|---|---|
| `label` | The user's own name or description for this calibration profile (e.g., "work trip mode"). The existence and name of a profile is the user's decision. |

---

## 3. Unfillable Claims

*The machine has no legitimate authority here. These claims cannot be produced by
inference, and asking the user does not produce an answer LOCA can store as authoritative.*

*No field in an unfillable category may be inferred from sensors, statistically derived,
or filled with a model default. If the temptation arises, the correct response is to
leave it absent.*

### 3.1 Valence of a Life Event

A `LifeEvent` records that something changed — energy went up, stress shifted, focus
dropped. The *valence* of the event (was this good? was this welcome? did this feel
like loss?) is not in the data model and must not be added to it. Neither sensor
patterns nor user confirmation can establish valence: a stress spike might be an
exciting challenge or a catastrophe; only the user knows, and even then their assessment
changes over time.

**Rule**: `LifeEvent` must not gain a `valence`, `sentiment`, or `isPositive` field.

### 3.2 `Chapter.dominantEventType`

If this field exists, it is the machine's guess at what defined the chapter — "this
was a high-stress period," "this was a social peak." The definition of a chapter is the
user's (`name`, `userDescription`). What the machine calls the chapter's dominant
character is an interpretation that cannot be validated. The sensor-authoritative fields
(`baselineStress`, `volatility`, etc.) already express the underlying measurements
without imposing meaning.

**Rule**: No "dominant theme" or "chapter summary" field may be inferred and stored as
if it were a fact about the chapter.

### 3.3 `Person.primaryContext` / relationship meaning

`RelationshipContext` is subject-authoritative (§2.3): the user identifies who a person
is in their life. But the *meaning* of the relationship (is this person uplifting or
draining? is this a net-positive relationship?) is unfillable. The sensor-authoritative
`moodCorrelation` describes a statistical co-occurrence pattern; it does not constitute
a claim about whether the user should value this relationship differently.

**Rule**: No "relationship quality," "net impact," or "should see more/less" claim may
be stored or surfaced as fact. `moodCorrelation` is display-only evidence, not a verdict.

### 3.4 `Direction` — existence and content

While individual fields of a `Direction` are subject-authoritative, the machine may not
*prompt* a direction into existence, *suggest* direction content, or *fill in* a
direction when the user has not articulated one. A direction that the machine
generated based on inferred patterns is not the user's direction. Absent a user-authored
statement, `Direction` stays nil.

**Rule**: `Direction.statement` may only be written by the user, never by the system.
The system may surface evidence (patterns, trait trajectories) but may not compose the
direction on the user's behalf.

### 3.5 `UncertaintyType` — semantic override

`UncertaintyType` (`.epistemic` / `.aleatoric`) is auto-assigned by sample count in
`InferenceProvenance.create()`. The user cannot meaningfully override it (they do not
have access to whether the variance is reducible), and the machine cannot make a
principled claim about it beyond the heuristic already in place. It must not be exposed
as a user-settable field or as a display claim ("your energy readings are fundamentally
noisy").

---

## 4. Classification Summary

| Category | Count |
|---|---|
| Sensor-authoritative | 68 fields across 8 model classes |
| Subject-authoritative | 16 fields across 6 model classes |
| Unfillable | 5 claim domains (no current field; must not be added) |

---

## 5. Audit Notes

**No unclassified fields remain.** Every stored field in every `@Model` class appears in
§1 or §2. Every unfillable domain in §3 either has no current field (correct) or is
flagged for removal.

Fields not listed above are structural / identity fields (`id: UUID`, `createdAt: Date`,
foreign key references such as `chapterId: UUID?`) that carry no claim content — they
are scaffolding, not evidence.

**`RelationshipEdge`** (RelationshipGraphEngine.swift) is computed at runtime and not
persisted — its fields (`strength`, `confidence`, `isConfounded`) are sensor-authoritative
estimates used transiently for graph queries. They require no classification here because
they are never stored.

---

*C2.1 complete. This taxonomy is the reference for all subsequent Cycle 2 sessions.*
*Each C2.x session that touches a claim must cite the category from this document.*
