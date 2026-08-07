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
| `isCalibrated` | Whether user calibration has been applied to this state record. |
| `calibrationError` | Residual error after calibration; nil if uncalibrated. |

### 1.2 `SignalEvent` (SignalModels.swift)

| Field | Rationale |
|---|---|
| `timestamp` | When the sensor reading was captured. |
| `source` | Which sensor or source produced it (`SignalSource` enum: health, location, calendar, app usage…). |
| `value` | Raw or normalized measurement value. |
| `uncertainty` | Measurement uncertainty from the source. |
| `metadata` | Source-specific key-value pairs from the sensor. |

`dayBucket` is a derived grouping date used for query optimization — structural scaffolding.

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
| `isCurrentChapter` | True when `endDate` is nil — a structural fact about whether the chapter is open. |
| `activityLevel` | Mean step-based activity level computed from signals in window. |
| `socialEngagement` | Calendar/location-based social density in window. |
| `scheduleRegularity` | Variance of wake/sleep times in window — a sensor aggregate. |
| `volatility` | Intra-chapter standard deviation of daily energy/mood. |
| `baselineEnergy` | Mean energy inferred across the chapter window. |
| `baselineStress` | Mean stress inferred across the chapter window. |
| `baselineFocus` | Mean focus inferred across the chapter window. |
| `baselineMood` | Mean mood inferred across the chapter window. |

### 1.5 `Person` / `PersonAppearance` (PersonModel.swift)

| Field | Rationale |
|---|---|
| `salience` | How frequently this person appears relative to total chapter length. |
| `salienceUncertainty` | Uncertainty in the salience estimate. |
| `nameVariants` | Raw strings from signal sources that resolved to this person. Sensor-derived clustering output. |
| `detectedContexts` | Raw context strings observed in signal sources (calendar titles, note fragments). |
| `firstSeenDate` | Earliest calendar/location co-occurrence with a recognized identifier. |
| `lastSeenDate` | Most recent co-occurrence. |
| `appearanceCount` | Total co-occurrence count in signal history. |
| `moodCorrelation` | Statistical correlation between this person's appearances and mood signals. |
| `moodCorrelationSampleCount` | Sample count supporting the correlation estimate. |
| `PersonAppearance.timestamp` | When the co-occurrence was detected. |
| `PersonAppearance.personId` | Which person appeared. |
| `PersonAppearance.source` | Which signal source recorded the appearance ("calendar", "note", "explicitLog"). |
| `PersonAppearance.context` | Inferred `RelationshipContext` at time of appearance. |
| `PersonAppearance.rawText` | Snippet of source text (calendar title, note excerpt) from which the appearance was extracted. |
| `PersonAppearance.moodAtTime` | Inferred mood value at the time of the appearance (from co-located `InferredState`). |
| `PersonAppearance.stressAtTime` | Inferred stress value at the time of the appearance. |

`moodCorrelation` is listed sensor-authoritative because it is a statistical estimate from
objective signal co-occurrences. Whether this correlation reflects a causal relationship
is unfillable (see §3.3). Per C2.4 it is raw evidence only — never surfaced as a label.

`Person.initials` is structural (derived from `name`).

### 1.6 `WeeklyRegime` (LifeEventModels.swift)

| Field | Rationale |
|---|---|
| `weekStart` | ISO week anchor date. |
| `weekEnd` | Computed end of the week window (weekStart + 6 days). |
| `energyMean` | Mean inferred energy across the week. |
| `stressMean` | Mean inferred stress across the week. |
| `focusMean` | Mean inferred focus across the week. |
| `moodMean` | Mean inferred mood across the week. |
| `energyStddev` | Within-week energy variance. |
| `stressStddev` | Within-week stress variance. |
| `focusStddev` | Within-week focus variance. |
| `moodStddev` | Within-week mood variance. |
| `scheduleRegularity` | Wake/sleep time variance for the week. |
| `locationDiversity` | Number of distinct location clusters visited. |
| `socialEngagement` | Calendar density of social events. |
| `activityLevel` | Mean step-normalized activity for the week. |
| `anomalyScore` | Statistical distance from the preceding baseline regime. |

### 1.7 `LifeEvent` (LifeEventModels.swift)

| Field | Rationale |
|---|---|
| `timestamp` | When the regime shift occurred. |
| `detectedDate` | When the event was detected (may be later than timestamp). |
| `eventType` | Classifier output (scheduleChange, locationChange, socialChange, healthChange, workChange, habitChange). |
| `anomalyScore` | Statistical distance from preceding baseline. |
| `persistenceScore` | How long the regime shift sustained before reverting. |
| `classificationScore` | Classifier confidence in the event type assignment. |
| `confidence` | Combined event detection confidence. |
| `metadata` | Classifier-generated key-value evidence. |

`eventType` is sensor-authoritative because it describes the dimension of change —
a statistical claim, not an interpretive one. What the event *means* is subject-authoritative
(§2.4); the implied valence is unfillable (§3.1).

### 1.8 `Calibration` (CalibrationModel.swift)

| Field | Rationale |
|---|---|
| `elementType` | Which type of soft element was sharpened ("annotation", "signal", "thread") — system classification. |
| `dimension` | Which inference dimension this calibration relates to; nil if not dimension-specific. |
| `calibratedAt` | When the calibration was recorded. |
| `confidenceBoost` | Model-assigned confidence increment this calibration contributes. |
| `isProcessed` | Whether the inference engine has consumed this record. |

`label` (the user's clarification) is subject-authoritative — see §2.6.
`elementText` (a copy of the calibrated element's text) and `isProcessed` are structural.

### 1.9 `UncertaintyRecord` (UncertaintyModels.swift)

| Field | Rationale |
|---|---|
| `timestamp` | When this uncertainty snapshot was taken. |
| `signalCompleteness` | Fraction of expected signals present in this window. |
| `signalQuality` | Mean confidence across contributing signals. |
| `energyEpistemic` | Reducible uncertainty component for the energy estimate. |
| `energyAleatoric` | Irreducible uncertainty component for the energy estimate. |
| `stressEpistemic` | Reducible uncertainty for stress. |
| `stressAleatoric` | Irreducible uncertainty for stress. |
| `focusEpistemic` | Reducible uncertainty for focus. |
| `focusAleatoric` | Irreducible uncertainty for focus. |
| `moodEpistemic` | Reducible uncertainty for mood. |
| `moodAleatoric` | Irreducible uncertainty for mood. |
| `eventDetectionUncertainty` | Combined uncertainty in the event detection pipeline for this window. |

`notes` is structural metadata appended by the system during recording.

### 1.10 `SensorConflict` (SensorConflict.swift)

| Field | Rationale |
|---|---|
| `timestamp` | The hour anchor the conflict refers to (matches an `InferredState.timestamp`). |
| `dimension` | Which dimension disagreed ("energy", "stress", "focus", or "mood"). |
| `sensorValue` | The sensor-derived value from `InferredState` for that hour. Sensor authority: this value is never changed by a conflict record. |
| `userValue` | What the user self-reported for this dimension in an explicit log. |
| `magnitude` | `abs(sensorValue − userValue)` — the disagreement magnitude on a 0–1 scale. |
| `recordedAt` | When the conflict was detected and stored. |

`SensorConflict` is an audit record created by C2.2 conflict detection. All fields are
sensor-authoritative: the record is machine-generated evidence of a disagreement.
`userValue` is captured as evidence, not as a subject-authoritative override; the sensor
value remains authoritative for `InferredState`.

### 1.11 `HabitBoard` — derived fields (HabitBoard.swift)

| Field | Rationale |
|---|---|
| `preferredReminderTime` | Inferred from logging time patterns in historical log data. |
| `currentStreak` | Consecutive completed days, computed from the log history. |
| `longestStreak` | All-time maximum streak, computed from the log history. |
| `lastCheckedDate` | The most recent day on which a streak completion was recorded. |

User-defined configuration fields are subject-authoritative — see §2.7.
`needsStreakRecalculation`, `lastReflectionPromptTime`, `colorIndex`, `useColorBackground`,
`emoji`, `archivedAt`, and the `logs` relationship are structural.

### 1.12 `ComposedView` — sensor-derived fields (ComposedViewModel.swift)

| Field | Rationale |
|---|---|
| `energyTimeline` | Sequence of `TimelinePoint` values drawn from `InferredState` records. |
| `stressTimeline` | Same, for stress. |
| `focusTimeline` | Same, for focus. |
| `moodTimeline` | Same, for mood. |
| `eventMarkers` | `LifeEvent` records projected as markers onto the view's time axis. |
| `annotations` | Engine-generated `AnnotationPoint` records identifying notable moments. |
| `renderingGuidance` | Engine-generated display hint (e.g., which dimension to emphasize). |

User-selected fields are subject-authoritative — see §2.9.
`colorScheme`, `timestamp`, and `isShowingCounterfactual` are structural.

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
| `Fork.kind` | Whether the fork is a decision, an inflection, or an open question (ForkKind). |
| `Fork.resolved` | Whether the user has resolved this fork (true/false). |
| `Fork.resolution` | What happened, in the user's own words, if they chose to note it. |

`Direction.settlednessUncertainty` is a system-assigned prior (defaults 0.3) and is
structural scaffolding — it does not represent a user-reported claim.

### 2.3 `Person` — identity fields (PersonModel.swift)

| Field | Rationale |
|---|---|
| `name` | Who the user says this person is. A co-occurrence pattern has no name until the user provides one. |
| `primaryContext` | The user's characterization of the relationship (work, family, social, recurring). Constitutive: the category is created by the user's understanding, not by sensor observation. Per C2.3, this field may only be written by a user act — never populated by inference. |

### 2.4 `LifeEvent` — user response fields (LifeEventModels.swift)

| Field | Rationale |
|---|---|
| `userConfirmed` | Whether the user agreed that this detected event was real. Self-report: the user's experience of the event is the authority. |
| `userNotes` | Free-text from the user about what was happening. |

### 2.5 `PatternFeedback` / `NarrativeFeedback` (FeedbackModel.swift)

| Field | Rationale |
|---|---|
| `PatternFeedback.resonance` | Whether the inferred pattern feels true to the user (−1, 0, 1). This is the user's judgment, not a sensor outcome. |
| `PatternFeedback.refinement` | User's correction or qualification of the inferred pattern. |
| `NarrativeFeedback.resonance` | Whether the generated narrative resonates (0–1). |
| `NarrativeFeedback.notes` | User's free-text response to the narrative. |

`PatternFeedback.patternId` and `NarrativeFeedback.arc` are structural references
to the entities being evaluated.

### 2.6 `Calibration` — label field (CalibrationModel.swift)

| Field | Rationale |
|---|---|
| `label` | The user's own clarification or name for this calibration event (e.g., "that was a tough week, not my baseline"). The user's interpretation constitutes the label. |

### 2.7 `HabitBoard` — configuration fields (HabitBoard.swift)

| Field | Rationale |
|---|---|
| `name` | The user's chosen name for the habit ("Running", "Reading"). Defines what is being tracked. |
| `metricType` | The user decides whether this habit is binary (done/not done) or quantitative. |
| `targetValue` | The daily goal the user sets for themselves. |
| `unitLabel` | The unit the user chooses for a quantitative habit ("mi", "mins", "cal"). |

### 2.8 `LogEntry` (LogEntry.swift)

| Field | Rationale |
|---|---|
| `timestamp` | When the user reported performing the habit. May be set by the user for backdated entries. |
| `value` | The amount the user logged. For binary habits: always 1.0 (the fact of doing it). For quantitative: the amount they entered. |
| `note` | Optional journal text the user attached to this check-in. |

### 2.9 `ComposedView` — user-selected fields (ComposedViewModel.swift)

| Field | Rationale |
|---|---|
| `question` | The question the user asked. Defines what the view is answering. |
| `startDate` | The start of the time range the user selected. |
| `endDate` | The end of the time range the user selected. |
| `counterfactualVariable` | Which dimension the user chose to explore as a counterfactual (nil if not in counterfactual mode). |

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

### 3.2 Chapter dominant characterization

`Chapter.dominantEventType` was a field that asserted what "defined" a chapter —
the machine's guess at the dominant theme. This field was removed (C2.4) because it
is the machine imposing meaning on a period the user has not yet interpreted. The
sensor-authoritative fields (`baselineStress`, `volatility`, etc.) already express
the underlying measurements without imposing meaning.

**Rule**: No "dominant theme," "chapter summary," or "chapter type" field may be inferred
and stored as if it were a fact about the chapter.

### 3.3 `Person.primaryContext` / relationship meaning

`RelationshipContext` is subject-authoritative (§2.3): the user identifies who a person
is in their life. But the *meaning* of the relationship (is this person uplifting or
draining? is this a net-positive relationship?) is unfillable. The sensor-authoritative
`moodCorrelation` describes a statistical co-occurrence pattern; it does not constitute
a claim about whether the user should value this relationship differently.

**Rule**: No "relationship quality," "net impact," or "should see more/less" claim may
be stored or surfaced as fact. `moodCorrelation` is raw evidence only — never a verdict.
Per C2.4, person-state pattern observations ("your energy tends to be lower around X")
are also forbidden.

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

| Category | Model classes covered |
|---|---|
| Sensor-authoritative | `InferredState`, `SignalEvent`, `Trait`, `Chapter` (sensor fields), `Person`/`PersonAppearance` (sensor fields), `WeeklyRegime`, `LifeEvent` (sensor fields), `Calibration` (sensor fields), `UncertaintyRecord`, `SensorConflict`, `HabitBoard` (streak fields), `ComposedView` (derived fields) |
| Subject-authoritative | `Chapter` (name/description), `Direction`, `Fork`, `Person` (name/primaryContext), `LifeEvent` (user fields), `PatternFeedback`, `NarrativeFeedback`, `Calibration` (label), `HabitBoard` (configuration), `LogEntry`, `ComposedView` (user-selected fields) |
| Unfillable | 5 claim domains — see §3 |

---

## 5. Audit Notes

**All 18 `@Model` classes registered in `RippleSchemaV1` are now classified.**
The previous version of this document omitted `HabitBoard`, `LogEntry`, `UncertaintyRecord`,
`ComposedView`, and `SensorConflict` entirely, and contained the following errors that
are corrected here:

- `§1.1`: `rawSignalCount` was listed but does not exist; `isCalibrated` and
  `calibrationError` were present in the model but absent from the taxonomy.
- `§1.2`: `signalType` was listed but does not exist; the model uses `source` only.
- `§1.4`: `dominantTraits` was listed but never existed. The removed field was
  `dominantEventType` (deleted by C2.4). `isCurrentChapter` was missing.
- `§1.5`: `PersonAppearance.salience` was listed but does not exist. Six real
  `PersonAppearance` fields were absent. `Person.nameVariants`,
  `detectedContexts`, and `moodCorrelationSampleCount` were absent.
- `§1.6`: Field names were wrong throughout — `meanEnergy/Stress/Focus/Mood` versus
  the actual `energyMean/stressMean/focusMean/moodMean`. `weekEnd` and `anomalyScore`
  were absent.
- `§1.7`: `detectedDate` was absent.
- `§1.8`: Described a completely different model (weights, errorHistory, sampleCount)
  that was never implemented. Corrected to match the actual `Calibration` entity.
- `§2.2`: `Fork.resolved` and `Fork.resolution` were absent.

Fields not listed above are structural / identity fields (`id: UUID`, `createdAt: Date`,
foreign key references such as `personId: UUID`, `boardID: UUID`) that carry no claim
content — they are scaffolding, not evidence.

**`RelationshipEdge`** (RelationshipGraphEngine.swift) is computed at runtime and not
persisted — its fields (`strength`, `confidence`, `isConfounded`) are sensor-authoritative
estimates used transiently for graph queries. They require no classification here because
they are never stored.

**Enforcement note**: The drift that caused this document to diverge from the schema
accumulated because there is no seam (test, lint rule, or schema check) binding the
taxonomy to the actual `@Model` declarations. Any future addition of a `@Model` field
should be accompanied by a one-line entry in this document before the PR is merged.

---

*C2.1 complete. This taxonomy is the reference for all subsequent Cycle 2 sessions.*
*Each C2.x session that touches a claim must cite the category from this document.*
*Last reconciled: C2 taxonomy reconciliation pass — all 18 `@Model` classes verified.*
