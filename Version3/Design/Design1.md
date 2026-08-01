# LOCA Version 3 · Design Phase
## Design1 — Product Architecture

> **The single question Design1 answers:** *If LOCA were created today with everything we have learned, what should the product actually contain?* — its structure, not its interface.
>
> This is **product architecture**, not interface design. It contains **no UI, no wireframes, no SwiftUI, no components, no navigation chrome, no implementation.** Every decision is derived from and must obey the frozen foundation: Phase R (R1–R10) and Phase S (S1–S7). References use S7 articles, S1 principles (**P1–P12**), the S2 strata (**Record → Reflection → Understanding**), and the S3 problem (**the self‑understanding gap**).
>
> **The governing constraint (from S7).** Nothing here is protected because Version 2 had it. Every V2 concept is re‑evaluated against the constitution: a capability survives only if it helps a person **see, remember, or make honest sense of their own life** (S3), passes the Decision Framework (S7 Art. IX), and pushes toward no anti‑form (S7 Art. VI). Removing, merging, or replacing is not just allowed — it is the job.

---

## Part I — The derivation (how philosophy becomes structure)

Design1 does not start from V2's feature list. It starts from what the person *does* with a life companion, derived from the S2 architecture and the S3 problem.

**S2 gives three strata:** the **Record** (truth), the **Reflection** (meaning), the **Understanding** (the person's, sovereign). **S3 gives the loop that closes the gap:** *truthful record → honest reflection → self‑understanding.* Translated into what a person actually does, this yields a small set of **verbs**, and the product is the structure around those verbs:

- **Capture** — honestly record the life as it's lived (the Record).
- **Reflect** — turn today's record into the person's own meaning (Reflection). *The primary daily value loop.*
- **Revisit** — return to the truthful record over time; remember; see honestly (Record + Understanding across time).
- **Ask** — pose a question about one's own life and get an honest, grounded, hedged answer (self‑inquiry).
- **Own** — inspect, correct, export, delete; see what LOCA believes and where it came from (trust made concrete — S6).

Everything the product contains must serve one of these verbs. A capability that serves none is scope creep by definition (S7 Art. IX placement test). This is the lens through which every V2 feature is now judged.

---

## Part II — Re‑evaluating every inherited capability

Each V2 concept, judged against the constitution. Verdicts: **Survives · Merges · Renamed/Reframed · Removed · Demoted · Elevated.**

| V2 concept | What it was | Verdict | Why (traced) |
|---|---|---|---|
| **Habits** | Habit tracking/logging | **Survives · Reframed** | Foundational honest capture + identity substrate (S3; S5). Reframed from streak‑game to neutral, identity‑framed capture (S7 Art. VI "not a habit tracker"; P11 forgiveness). Habits are input, never the point. |
| **Today / Present / "Today's Read"** | AI‑narrated daily state verdict | **Renamed → Reflect · Redesigned** | Narration violates P1 (the person makes the meaning) and S7's anti‑oracle. Becomes the daily **reflective** home: seeded, hedged, calm — the Apple‑Journal loop (R1; S2 Stratum 2). The verdict is removed; the reflection replaces it. |
| **Life tab (12 Browse cards)** | A dashboard of 12 life surfaces | **Removed (as a structure)** | The build‑trap dashboard is precisely what R9/S7 forbid (Hick's/Miller's overload, R5; "not a dashboard," S7 Art. VI). Its worthy contents are merged below; the flat 12‑card grid disappears. |
| **Chapters** | Inferred life‑period segmentation | **Merges → Timeline** | A way to hold continuity (S5). Becomes user‑confirmable **landmarks on the Timeline**, not a standalone browse card. The person authors significance (S5; P1). |
| **Events** | Inferred turning points | **Merges → Timeline** | Same: derived landmarks on the record, user‑confirmable. Not a standalone surface. |
| **Patterns** | Habit↔state correlations | **Merges → Understanding · Reframed** | Survives as *hedged, evidence‑gated, correctable* observations (S4; S7 Art. VIII), never a confident feed. Abstains when thin (S4). Folded into one honest "Understanding" surface. |
| **Story / Narrative** | AI‑authored life story | **Removed** | AI authoring the person's understanding violates the Stratum 3 boundary (S2) and risks implanting false memory (R2 Schacter). The person's own accumulated reflections + named chapters *are* the story. |
| **Tendencies / Traits** | Inferred personality traits | **Removed (as asserted traits)** | Fixed‑trait claims violate the ceiling (S4/S5) and risk mood→trait harm (R2 Learned Optimism). Any tendency lives inside Understanding as a hedged, correctable observation held as *tendency, never trait*. |
| **People / Connections (Relationship graph)** | Inferred people + correlation graph | **Merge → People · Demoted** | Relationships in scope only as part of understanding one's own life, never a CRM (S3 non‑goal). People + Connections merge into one honest, **consent‑gated, provenance‑labeled** secondary surface (S6; the F7 mystery‑people failure). Correlational content moves to Understanding. |
| **Direction / Forks** | User‑authored where‑you're‑heading | **Merge → Direction · Survives** | User‑authored identity/meaning — aligns with S3 and P1. Direction + Forks merge into one surface. Secondary (occasional). |
| **Ask / ViewComposition** | Question your life → composed view | **Merge → Ask · Elevated** | Self‑inquiry keeps the person the author (they ask). Elevated to a first‑class, invoked capability; grounded, hedged, provenance‑bearing answers or honest abstention (S4). Absorbs the dead `showAsk`. |
| **Weekly Digest / Monthly Review** | Habit rollups | **Merge → Reviews · Elevated** | The retention **ritual** and compounding value LOCA lacked (R1/R9; S6). Reframed from metrics rollup to an honest reflective review. Elevated. |
| **Reach / Life Scene** | Immersive whole‑picture narration | **Removed / folded → Timeline+Reviews** | A narration/dashboard hybrid; its value (seeing the whole) folds into the Timeline and Reviews. |
| **Feedback Analytics** | Feedback on AI output | **Merge → You/Trust · Reframed** | Becomes the concrete home of S6's inspectable model: "what LOCA believes about you," correct it, and see provenance. |
| **Micro check‑ins / state logging** | Explicit state capture | **Merge → Reflect** | Explicit input + calibration (S4/S5); folded into the daily reflective moment, reframed as *for the person* (affect labeling; R2), not data harvest. |
| **DEBUG seeder / runtime check** | Dev verification | **Removed from product** | Development‑only; never part of the product (the F5/F7 seeded‑data confusion). |
| **The honest empty states** | Instructive empties | **Survives unchanged** | A genuine R5 strength; kept and extended to claim‑level "not enough yet" (S4). |
| **Consent ledger + provenance infra** | Source consent + provenance | **Survives · Surfaced** | The S6/S8 trust infrastructure survives and is made visible in You/Trust. |

**The pattern of the verdicts:** V2 tried to *show the person conclusions* across a dozen surfaces (narration, story, traits, patterns, graphs). V3 *helps the person reach their own conclusions* across a few honest ones (record, reflection, hedged understanding, their own questions). The number of surfaces collapses; the honesty rises.

---

## Part III — The Product Tree

Derived, not copied. Five top‑level areas: **three primary destinations** (the verbs the person lives in) and **two cross‑cutting capabilities** (invoked, not browsed).

```
LOCA
│
├── HABITS            — capture the doing            (daily · primary)
│     ├── Log a habit
│     ├── Today's habits
│     └── Habit detail            (history · consistency-as-information · identity framing)
│
├── TODAY  →  REFLECT — make today's meaning         (daily · primary)
│     ├── Reflect                 (one seeded, hedged, calm reflective moment — the core loop)
│     ├── State check-in          (explicit input · calibration · for the person)
│     └── Today's record          (the honest facts of the day, as material to reflect on)
│
├── LIFE   →  REVISIT — remember & understand        (weekly / occasional · primary)
│     ├── Timeline                (the truthful record over time; chapters & events as
│     │                            user-confirmable landmarks; "this time last year")
│     ├── Reviews                 (the weekly / monthly reflective ritual — the honest appointment)
│     ├── Understanding           (hedged, provenance-bearing, correctable observations;
│     │                            abstains when thin; NO verdicts, NO fixed traits)
│     ├── People                  (secondary · consent-gated · provenance-labeled;
│     │                            only as part of understanding one's own life)
│     └── Direction               (the person's own values / goals / where-heading — user-authored)
│
├── ASK               — question your own life        (invoked · cross-cutting)
│     └── Grounded, hedged, provenance-bearing answers — or honest abstention
│
└── YOU  /  TRUST     — own it & inspect it          (occasional · essential · cross-cutting)
      ├── What LOCA believes about you   (inspect + correct — the S6 model)
      ├── Privacy & consent              (per-source · revocable)
      ├── Your data                      (export · delete — ownership)
      └── Provenance / how this works    (honesty made legible)
```

**Why five, and why this shape:** the person immediately understands *capture (Habits) · reflect (Today) · revisit (Life)* as the three things they do, with *Ask* and *You* as capabilities available throughout rather than places to visit. This is the antidote to V2's 12‑card overload (R5; S7 Art. VII simplicity) and it maps cleanly onto the S2 strata (Habits+Today's‑record = Record; Reflect+Reviews+Ask = Reflection; Understanding+Timeline+Direction = the person's Understanding, with You/Trust guarding sovereignty).

---

## Part IV — The Product Hierarchy (Level 1 / 2 / 3)

A person should grasp the hierarchy instantly. Three levels, no feature‑dumping:

- **Level 1 — the five areas above.** Three destinations (Habits, Today, Life) + two capabilities (Ask, You). This is the entire mental model.
- **Level 2 — the major surfaces within each area** (the second tier of the tree: Reflect, Timeline, Reviews, Understanding, People, Direction, etc.). A person reaches these deliberately.
- **Level 3 — depth and detail** (a habit's history, a claim's evidence, a past chapter, the reasoning behind an observation). Reached only on demand, via progressive disclosure (S7 Art. VII; R5).

**The rule:** nothing at Level 3 is required to use the product; nothing at Level 1 is more than the five areas. Complexity lives at the bottom, optional; the top stays legible.

---

## Part V — Progressive Disclosure Strategy

Because LOCA's value is genuinely slow (S3/S6 honesty about the value curve), the product reveals itself as the record earns it:

- **Seen immediately (day one):** Habits (log), Today/Reflect (with the honest empty state that teaches — R5), the one Day‑1 intent question that seeds Direction, and Ask (available, even if it can only honestly say "not enough yet"). Nothing else.
- **Hidden until useful:** Understanding (empty‑with‑teaching until evidence earns a hedged observation); Timeline landmarks (chapters/events emerge as the record grows); Reviews (the first appears after roughly a week of data); People (only after consent *and* recurrence).
- **Unlocks gradually:** Understanding, Timeline landmarks, Reviews, and People accrue along the S5 learning curve — each appearing when, and only when, its evidence exists. The product visibly deepens with use (the compounding asset, R1/R10).
- **Never shown to beginners (and some never at all):** dense pattern feeds; any fixed‑trait claim (never, at any tenure — the ceiling); a populated "what LOCA believes about you" before there is anything true to show; advanced Direction/Forks before a Direction exists. What is empty is shown as *honestly empty and teaching*, never as broken.

**The disclosure principle:** the product never fabricates depth to look complete (the F1/F6 sin). It shows exactly what it has honestly earned, and says so where it hasn't (S4 abstention; S7 Art. VIII).

---

## Part VI — User Journey Map (Day 1 → Year 1)

Grounded in the S5 learning arc and the S3/S6 honesty about pacing. No screens — only what the person experiences and what LOCA does and doesn't know.

### Day 1
- **Experiences:** logs a first habit (instant, real value); is asked one honest question — *"what do you want to understand about yourself?"* (seeds Direction/Ask); receives one small, honest reflective moment grounded in that first log; is told plainly the read gets richer over days. No permissions demanded yet.
- **LOCA knows:** the first fact(s). **Doesn't know:** any pattern, baseline, state, or person — and says so honestly.
- **Prioritize:** an honest Day‑1 win (log → reflect) and seeding intent; *not* a fabricated life model (the F1 overpromise).
- **Unlocks:** Habits, Today/Reflect, Ask (as available), Direction (seeded).

### First week
- **Experiences:** a forming daily rhythm of log + reflect; the first honest observations begin only where evidence supports; the first weekly Review appears as a gentle, honest look‑back.
- **LOCA knows:** early facts and the first tentative patterns (hypothesis‑grade). **Doesn't know:** stable tendencies, a real baseline — held as tentative, disclosed.
- **Prioritize:** the reflection loop and the first Review ritual; keep confidence honest and low.
- **Unlocks:** Reviews (weekly), the first hedged Understanding observations, first Timeline entries.

### First month
- **Experiences:** a personal baseline forms; hedged, correctable observations appear in Understanding with their evidence; the first chapter/landmark may emerge on the Timeline (user‑confirmable); permissions are offered *at their point of value* (e.g. calendar → People, with the payoff named).
- **LOCA knows:** corroborated within‑person patterns; a baseline. **Doesn't know:** identity, values, or anything above the ceiling — never asserted.
- **Prioritize:** honest Understanding (with abstention where thin) and the compounding record; the monthly Review.
- **Unlocks:** Understanding (populated, hedged), Timeline landmarks, People (if consented), monthly Reviews.

### First year
- **Experiences:** a rich, trusted, revisitable record; nostalgia ("this time last year"); a felt sense of being understood; observations held humbly and correctably; a life story the person has authored through their own reflections and named chapters.
- **LOCA knows:** stable tendencies (as tendencies), routines, relationships (consented), a co‑authored Direction. **Doesn't know / never claims:** fixed traits, causation, verdicts, the future.
- **Prioritize:** the compounding record and the long‑term relationship; humility that grows with familiarity (S6).
- **Unlocks:** the full depth of Timeline, Reviews, and Understanding — each still honest, still correctable, still the person's.

**The through‑line:** at every horizon LOCA knows more and holds it *more humbly and more traceably* (S5/S6), and the person's independence *from* the tool is treated as success, never churn (S6).

---

## Part VII — Product Principles per area (why it exists · problem solved · cadence)

| Area | Why it exists | Problem it solves (S3 root) | Cadence |
|---|---|---|---|
| **Habits** | Honest capture + identity substrate | Self‑opacity (makes the doing visible) | Daily |
| **Today / Reflect** | The primary meaning‑making loop | Reflection friction & the meaning gap | Daily |
| **Timeline** | The truthful record over time | Discontinuity & fallible memory | Weekly / occasional |
| **Reviews** | The honest reflective ritual (retention) | Self‑opacity + the meaning gap, periodically | Weekly / monthly |
| **Understanding** | Hedged, correctable self‑observations | Self‑opacity (lifted honestly) | Weekly / occasional |
| **People** | Relationships as part of one's own life | Discontinuity (relational continuity) | Occasional |
| **Direction** | The person's own values/where‑heading | Meaning gap / identity | Occasional |
| **Ask** | Self‑inquiry, person as author | Self‑opacity via the person's own question | Invoked |
| **You / Trust** | Ownership + inspectable beliefs | Trust (makes S6 concrete) | Occasional, essential |

Every area names a real S3 root; none is a metric surface or a dashboard. Cadence honesty is built in — only two areas are daily, which is correct for a calm companion (S7 Art. VII; P10).

---

## Part VIII — The consolidated deliverables

### What to remove
- The 12‑card **Life Browse dashboard** (as a structure).
- **AI‑authored Story/Narrative** (Stratum 3 violation; false‑memory risk).
- **Traits/Tendencies as asserted fixed traits** (ceiling violation).
- The narrated **"Today's Read" verdict** (anti‑oracle; replaced by reflection).
- **Reach / Life Scene** as standalone narration.
- **DEBUG seeder / runtime check** from the product.

### What to merge
- Chapters + Events + Life‑Scene → **Timeline**.
- Patterns + Tendencies + Connections(correlational) → **Understanding**.
- People + Connections(relational) → **People**.
- Direction + Forks → **Direction**.
- Ask + ViewComposition + `showAsk` → **Ask**.
- Weekly Digest + Monthly Review → **Reviews**.
- Micro check‑ins + state logging → **Today/Reflect**.
- Feedback Analytics + the user‑model → **You/Trust**.

### What to redesign completely
- **Today** — from AI narration to the person's reflection.
- **Life** — from a 12‑card dashboard to three coherent surfaces (Timeline, Reviews, Understanding) plus two secondary (People, Direction).
- **Habits** — from streak‑game to neutral, identity‑framed capture.
- **Understanding** (née Patterns/Traits) — from hidden confident feed to hedged, provenance‑bearing, correctable, abstaining observations.
- **Onboarding** — from a conceptual explainer to an action‑first, intent‑seeding, permission‑deferring first run.

### What survives largely unchanged (in intent, not implementation)
- **Habit logging** as the core honest capture.
- **The honest empty states** (extended to claim‑level abstention).
- **Direction** as user‑authored.
- **Ask** as question‑anchored self‑inquiry.
- **The consent ledger + provenance infrastructure** — surfaced, not hidden.
- **The two‑area simplicity impulse** (now three primary + two cross‑cutting).

---

## The product, in one statement

> **LOCA V3 is five things, not twelve: a place to honestly capture the life you live (Habits), a daily place to reflect on it and make your own meaning (Today), a place to revisit and honestly understand it over time (Life — Timeline, Reviews, Understanding, People, Direction), a way to ask your own questions of your own life (Ask), and a place to own and inspect everything LOCA holds and believes about you (You). It shows what it has honestly earned and says so where it hasn't; it helps you reach your own conclusions instead of handing you its own; and it collapses V2's dashboard of conclusions into a small, legible structure organized around what a person actually does — capture, reflect, revisit, ask, and own.**

This architecture is the frame every subsequent Design document (Design2–Design10) must fill. Design2 onward may specify *how each area works and feels* — but may not add an area, revive a removed one, or violate the constitution (S7) to do so.

---

*Design1 complete. The complete product architecture, capability map, feature hierarchy, user‑journey map, progressive‑disclosure strategy, information architecture, product tree, and the remove/merge/redesign/survives lists are defined and derived entirely from Phase R (R1–R10) and Phase S (S1–S7). No UI, wireframes, SwiftUI, components, or implementation were specified. Stop here; do not begin Design2. Design1 is ready for review.*
