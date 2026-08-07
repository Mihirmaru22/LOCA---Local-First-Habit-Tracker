# LOCA Version 3 · Design Phase
## Design6 — Surface Architecture

> **The single question Design6 answers:** *What are all the places a person interacts with LOCA, why does each exist, and how do they work together?*
>
> This is **surface architecture** — the first place the real product emerges — but it is still **not UI**. It contains **no mockups, no wireframes, no Figma, no SwiftUI, no implementation, no visual component design.** Every surface is derived from and consistent with the frozen foundation — Phase R (R1–R10), Phase S (S1–S7), Design1 (the five areas), Design2 (experience/rhythm), Design3 (information ownership), Design4 (interaction), Design5 (calm/minimal/deference) — and nothing is assumed correct because Version 2 had it.
>
> **What Design6 fixes:** the complete inventory of surfaces, each one's canonical purpose, and how they connect — the blueprint every eventual screen must fill.

---

## Part I — The Surface Philosophy (the constraints)

Before listing surfaces, the rules that govern which may exist (from Design1/5):

1. **A surface exists only if it is the canonical home of a real need.** No duplication; if information already has a home, another surface may *summarize and deep‑link* to it, never own a second copy. *(Design5 minimal; Design3 one canonical home.)*
2. **Few destinations, calm.** Three primary destinations (Today, Habits, Life) + two cross‑cutting capabilities (Ask, You/Trust), mirroring Design1. The person's mental model stays legible. *(Design1; Design5 deference.)*
3. **Today is home.** The default launch surface is the daily reflective moment — the primary value loop — not a dashboard. *(Design1/2; S3.)*
4. **Ambient and system surfaces are calm and minimal.** Widgets, Watch, notifications, and search exist to serve the person quietly, never to pull them in. *(Design2 ambient; Design5; P7.)*
5. **Every surface obeys the same laws:** deference, calm, one focal point, honesty, kindness (Design5), quiet intelligence (Design4), and the one‑way truth flow (Design3).

---

## Part II — The Complete Surface Inventory

Grouped by area. For each: **why · problem · frequency · belongs · never · actions · not‑actions · connects.**

### A. TODAY (the reflective home — default entry)
**Today**
- **Why:** the daily reflective moment — the primary loop that closes the meaning gap. **Problem:** reflection friction (S3). **Frequency:** Daily. **Belongs:** one seeded, hedged reflective prompt/observation‑as‑question; a way to capture a note or state; today's honest record (facts of the day). **Never:** a narrated verdict, a dashboard, a metric grid, streak pressure. **Actions:** reflect, capture a note, check in on state, log a habit (shortcut), open Ask. **Not‑actions:** browsing analytics, editing beliefs. **Connects:** → Habits (log), → Ask, → Life (via a gentle nostalgia/Review teaser), → Reflect moment, → State check‑in.

**Reflect moment** *(within Today)*
- **Why:** the actual act of reflection — seeded from the real record, authored by the person. **Problem:** blank‑page friction (R9). **Frequency:** Daily (optional). **Belongs:** one grounded prompt, space for the person's own words. **Never:** LOCA writing the reflection; multiple prompts. **Actions:** write, skip, save. **Not‑actions:** being told what it means. **Connects:** → the record (a saved reflection becomes part of the Timeline).

**State check‑in** *(within Today; also Watch/Siri)*
- **Why:** explicit input the person names for themselves (affect labeling) and that calibrates LOCA. **Problem:** self‑opacity + calibration. **Frequency:** Occasional. **Belongs:** the person's own state, in their words/rating. **Never:** LOCA asserting the state instead. **Actions:** name a state. **Not‑actions:** receiving a verdict. **Connects:** feeds Understanding + calibration (Design3).

**Today's record** *(within Today)*
- **Why:** the honest facts of the day, as material to reflect on. **Problem:** discontinuity (the day itself). **Frequency:** Daily. **Belongs:** what actually happened today (logs, notes, sensed facts with provenance). **Never:** inferred verdicts. **Actions:** review, add, correct an entry. **Connects:** → Timeline (today is the newest slice).

### B. HABITS (capture the doing)
**Habits Home**
- **Why:** honest capture + identity substrate. **Problem:** self‑opacity of the doing (S3). **Frequency:** Daily. **Belongs:** today's habits, quick log, gentle consistency‑as‑information. **Never:** coercive streak drama, guilt, a game. **Actions:** log, add/edit a habit, open a habit. **Not‑actions:** being scored/shamed. **Connects:** → Habit detail, → Today, → Understanding (habits as evidence).

**Habit detail**
- **Why:** one habit's honest history and its hedged patterns. **Problem:** understanding a specific behavior. **Frequency:** Occasional. **Belongs:** the habit's record over time, consistency (neutral), its L4 patterns (hedged, with provenance), identity framing. **Never:** a fixed trait, a causal claim, a verdict on discipline. **Actions:** log, edit, view history, ask‑why on a pattern, correct. **Connects:** → Understanding, → Timeline.

**Log / check‑in sheet** *(transient; from Habits/Today/Watch/Siri)*
- **Why:** the low‑friction act of capture. **Problem:** capture friction (R9 Daylio lesson). **Frequency:** Daily. **Belongs:** the minimum to log. **Never:** upsell, friction, a mandatory reflection. **Actions:** log. **Connects:** returns to origin.

### C. LIFE (revisit & understand — the hub)
**Life Home**
- **Why:** the hub for revisiting and understanding over time. **Problem:** discontinuity + self‑opacity (S3). **Frequency:** Weekly/occasional. **Belongs:** calm entry points to Timeline, Reviews, Understanding, People, Direction — *not* a 12‑card grid. **Never:** a dense dashboard. **Actions:** navigate to a sub‑surface. **Connects:** → all Life sub‑surfaces.

**Timeline**
- **Why:** the truthful record over time — the person's memory. **Problem:** fallible memory / discontinuity (S3). **Frequency:** Occasional. **Belongs:** the life as it happened; chapters & events as user‑confirmable landmarks; "this time last year." **Never:** an AI‑authored narrative overwriting the record; fabricated landmarks. **Actions:** revisit, confirm/name a chapter or event, reflect on a moment, correct an entry. **Not‑actions:** having the story told to them. **Connects:** → Chapter detail, → Event detail, → Today (newest), → Reviews.

**Reviews**
- **Why:** the weekly/monthly reflective ritual — the honest appointment and compounding moment. **Problem:** the meaning gap, periodically; the retention ritual LOCA lacked (R1/R9). **Frequency:** Weekly & monthly. **Belongs:** an honest look‑back the person reflects on; real habit rollups (facts); hedged observations in context. **Never:** a metrics scorecard, a grade. **Actions:** read, reflect, save, ask‑why, correct. **Connects:** → Timeline, → Understanding, → Today (teaser/notification).

**Understanding**
- **Why:** hedged, correctable observations about the person — self‑opacity lifted honestly. **Problem:** self‑opacity (S3). **Frequency:** Occasional. **Belongs:** L4 patterns with provenance + confidence; "not enough yet" where thin. **Never:** verdicts, fixed traits, causation, dense feeds. **Actions:** read, ask‑why (evidence), correct, reject, hide. **Not‑actions:** receiving a personality verdict. **Connects:** → Observation detail (evidence), → Ask, → the facts behind each claim.

**People** *(secondary, consent‑gated)*
- **Why:** relationships as part of understanding one's own life. **Problem:** relational continuity (S3). **Frequency:** Occasional. **Belongs:** people who recur in the person's life, provenance‑labeled, salience honest. **Never:** a CRM; a relationship's *nature* asserted without confirmation; anyone unexplained (the F7 fix). **Actions:** view, confirm, correct, hide, ask‑why. **Connects:** → Person detail, → Timeline, → Understanding.

**Direction** *(user‑authored)*
- **Why:** the person's own values/goals/where‑heading. **Problem:** meaning gap / identity (S3). **Frequency:** Occasional. **Belongs:** the person's stated direction, values, open questions (forks), goals; honest trajectory *context* (never advice). **Never:** prescription, judgment when behavior diverges. **Actions:** author, edit, add/resolve an open question. **Not‑actions:** being told what to do. **Connects:** → Reviews (framing), → Today (context).

**Detail destinations:** *Chapter detail · Event detail · Person detail · Observation detail · Saved answer* — each a deep destination reached from its parent, showing the thing plus its evidence/provenance and the actions (correct, ask‑why, reflect). Not top‑level.

### D. ASK (self‑inquiry — cross‑cutting, invoked)
**Ask**
- **Why:** the person questions their own life; keeps them the author. **Problem:** self‑opacity via the person's own inquiry (S3; R3 QS). **Frequency:** Invoked (occasional). **Belongs:** the question; a grounded, hedged, provenance‑bearing answer, or honest abstention. **Never:** a chatbot stream; a confident answer beyond evidence; conversation as the default medium. **Actions:** ask, read, save, ask‑why, refine. **Connects:** ← reachable from Today/Life; → Saved answers; → the facts behind the answer.

**Saved answers** — kept compositions the person chose to retain; canonical under Ask, referenceable from Life.

### E. YOU / TRUST (own it & inspect it — cross‑cutting, essential)
**You/Trust Home** — the concrete home of S6. **Frequency:** Occasional, essential.
- **What LOCA believes about you** — inspect + correct the live model; the anti‑cage guarantee. **Actions:** inspect, correct, remove a belief, reset understanding, see confidence history.
- **Privacy & consent** — per‑source, revocable; what's used and why. **Actions:** grant/revoke, see payoff.
- **Your data** — export, delete (everything, including the record — sovereignty). **Actions:** export, delete.
- **How it works / provenance** — plain honesty about limits and reasoning. **Actions:** read.
- **Settings** — app‑level preferences. **Frequency:** Rare.
- **Never here:** anything hidden from the person about what LOCA knows/uses/believes.

### F. SYSTEM · ENTRY · AMBIENT
- **Onboarding** — the action‑first first run (log → reflect → seed intent → set honest expectations; permissions deferred). **Frequency:** Once. **Never:** a feature tour, a permission gauntlet, an overpromise. *(R6.)*
- **Notifications** — the *one* gentle weekly Review notification; plus optional, neutral habit reminders the person sets. **Frequency:** Weekly + contextual. **Never:** guilt, streak‑loss, FOMO, engagement nudges. *(Design4 proactivity; P7.)*
- **Home Screen widget** — a calm glance: today's reflect invitation or a quiet piece of the record. **Frequency:** Ambient. **Never:** metrics dashboards, alarming numbers. *(Design2 ambient; Design5.)*
- **Lock Screen widget** — a minimal glance (e.g. a single gentle prompt or nothing). **Ambient.**
- **Apple Watch** — quick habit log and state check‑in; nothing dense. **Contextual/daily‑lite.**
- **Siri / App Intents** — quick log, quick reflect, quick ask. **Contextual entry.**
- **Spotlight / Search** — search the person's *own* record (retrieval, zero‑claim; Rewind‑lite honesty). **Contextual.** **Never:** searching the world; inferring from a search.
- **Share‑in** *(minimal)* — attach a note/photo to today's record. **Contextual.** **Never:** a PKM importer of external content (S3 non‑goal). *(Kept deliberately small.)*

**Empty states** are a cross‑cutting *philosophy* (Part VII), not a surface.

---

## Part III — The Surface Relationship Map (the conceptual graph)

```
                        ┌─────────── ONBOARDING (once) ───────────┐
                        ▼                                          │
   ENTRY POINTS ──► [ TODAY ] ◄──────── default home ─────────────┘
   (launch, notif,     │  ▲
    widget, Watch,     │  │  (gentle nostalgia / Review teaser)
    Siri, Spotlight)   │  │
                       ▼  │
      ┌──────── [ HABITS ] ──► Habit detail ──► (patterns) ─┐
      │            (log)                                     │
      │                                                      ▼
      └──────────────────────────────────────────►  [ LIFE ] (hub)
                                                       ├─► Timeline ─► Chapter/Event detail
                                                       ├─► Reviews  ─► (weekly/monthly)
                                                       ├─► Understanding ─► Observation detail
                                                       ├─► People ─► Person detail
                                                       └─► Direction ─► open questions

   [ ASK ] ── invoked from Today & Life ──► Answer ──► Saved answers
   [ YOU / TRUST ] ── reachable from everywhere ──► Beliefs · Privacy · Data · How-it-works
```

- **Entry point:** Today (default), plus all system entries route to Today unless deep‑linked.
- **Natural next:** from Today → log a habit, or → a gentle look‑back (Review/Timeline). From a Review → Timeline or Understanding.
- **Feeders (produce inputs upward):** Habits, Today's record, State check‑ins, Direction → feed Understanding, Timeline, Reviews (Design3 one‑way flow).
- **Destinations (where the person dwells):** Today (daily), Reviews (weekly), Timeline (occasional).
- **Temporary surfaces:** log/check‑in sheet, Ask answer, the reflect moment — transient, return to origin.
- **Permanent homes:** Today, Habits, Life (+ its sub‑surfaces), You/Trust — always there.

**The flow law:** every path leads back to *reflect* (Today) or *revisit* (Life); no path leads into a feed, a scoreboard, or an endless surface (Design4/Design1).

---

## Part IV — The Surface Ownership Framework

Every piece of information has exactly one canonical home; other surfaces may show a summary that deep‑links to it (Design3 — no duplication).

| Information | Canonical home | Secondary summary appears in | Deep‑links to |
|---|---|---|---|
| Today's reflection (as created) | **Today** | — (momentary); once saved → the record | Timeline |
| Saved reflections | **Timeline** (the record) | Today (today's), Reviews | the moment |
| Habit trends / consistency | **Habit detail** | Habits Home, Reviews | Habit detail |
| Weekly / monthly review | **Reviews** | Today (a fresh‑Review teaser / notification) | the Review |
| Relationships / people | **People** | Understanding, Timeline (references) | Person detail |
| Memories / the record | **Timeline** | Today (today's slice), Reviews (nostalgia) | Timeline / a moment |
| Questions & answers | **Ask** (saved answers) | Life (references) | Saved answer |
| Goals | **Direction** | Reviews (framing) | Direction |
| Chapters | **Timeline** (landmarks) | Reviews, trajectory context | Chapter detail |
| Events | **Timeline** (landmarks) | Reviews | Event detail |
| Traits | **— (none; removed)** | — | — |
| Observations / patterns | **Understanding** | Habit detail, Reviews | Observation detail |
| Body / health metrics | **— (no dashboard)**; appear as provenance‑tagged *context* in Understanding & Reviews; raw lives in Health | Understanding, Reviews | source (with provenance) |
| Calendar context | **— (no surface)**; provenance‑tagged context in Understanding & People | Understanding, People | source |
| What LOCA believes | **You/Trust › Beliefs** | (referenced when a claim is corrected) | Beliefs |

**Ownership laws:** (1) one canonical home each; (2) summaries deep‑link, never duplicate; (3) inferred context (health, calendar) has *no standalone dashboard* — it appears only where it honestly serves understanding, always provenance‑tagged (the anti‑QS‑dashboard stance, R9/S3); (4) traits have no home because they are not a knowledge type (Design3).

---

## Part V — The Entry Point Architecture

Every way in, and what it shows first:

| Entry point | Shows first | Why |
|---|---|---|
| **Cold launch** | Today | the daily reflective home; the primary loop *(Design1)* |
| **Weekly Review notification** | that Review | the one sanctioned proactive beat *(Design4)* |
| **Habit reminder** (opt‑in) | the log sheet for that habit | frictionless capture; neutral, not coercive |
| **Home/Lock widget tap** | Today (or the specific glance's target) | calm continuation |
| **Apple Watch** | quick log / check‑in | minimal capture on the wrist |
| **Siri / App Intent** | the requested act (log / reflect / ask) | intent‑direct |
| **Spotlight / Search** | the search of one's own record | retrieval, zero‑claim |
| **Deep link** (from a summary/teaser) | the canonical destination | ownership routing |
| **Share‑in** | attach‑to‑today | minimal capture |

**Entry law:** every entry either lands on **Today** (the calm home) or performs the **one specific act** the person invoked — never a promotional interstitial, never an upsell, never a feed. *(Design4; P7.)*

---

## Part VI — The Frequency Model

| Frequency | Surfaces | Why |
|---|---|---|
| **Daily** | Today, Reflect moment, Today's record, Habits Home, Log sheet | the capture+reflect loop; the only things that earn daily presence *(Design2 — two areas daily)* |
| **Weekly** | Reviews (weekly), the Review notification | the ritual heartbeat *(R1/R9)* |
| **Monthly** | Reviews (monthly) | deeper look‑back |
| **Occasional** | Life Home, Timeline, Understanding, People, Direction, Habit detail, Ask, You/Trust | revisiting/understanding, invoked as wanted |
| **Rare** | Settings, export/delete, Onboarding (once) | one‑time or seldom |
| **Contextual** | Notifications, widgets, Watch, Siri, Spotlight, Share‑in, People (only after consent+recurrence), detail destinations | appear only when appropriate |

**Frequency law:** only the capture+reflect loop is daily; everything deeper is weekly, occasional, or contextual — the shape of a calm companion, not an everyday demand (Design2; P10).

---

## Part VII — The Empty‑State Philosophy

Every surface must answer *"what if there is no data?"* — because empty products that feel broken are abandoned (R9), and LOCA's value is honestly slow (S6). Principles for every empty state:

- **Teach** — explain what this surface will hold. *(R5 strength.)*
- **Guide** — offer the one honest next step (never a demand).
- **Build trust** — being honest about emptiness *earns* trust; a fabricated "insight" would destroy it (the F1/F6 sin). *(S6.)*
- **Explain why it's empty** — "not enough yet," in plain, kind language (epistemic, not failure). *(S4 abstention; Design3.)*
- **Show progress** — where honest, hint at what's accruing ("a few more days and…").
- **Explain what unlocks it** — what evidence or consent will bring it to life (e.g. "grant Calendar to see who you spend time with" — payoff‑named). *(R6.)*

**Per‑surface:** Today teaches the reflect loop; Understanding says "not enough yet" and what will unlock it; Timeline shows the record accruing; People explains the Calendar payoff (consent‑gated); Reviews appears only once a week of data exists. **Empty law:** an empty surface is *honest, teaching, and never broken* — and never filled with fabricated depth to look complete.

---

## Part VIII — The Surface Evolution Framework

How each surface changes across the relationship (Design2 arc; Design4 progression) — along four dimensions: **density, intelligence, confidence, visual complexity** (which stays *low* throughout — Design5).

| Horizon | Today | Habits | Life / Understanding | Reviews |
|---|---|---|---|---|
| **Day 1** | honest empty + one reflect prompt | log + first habit | empty, teaching | none yet |
| **Week 1** | forming rhythm; tentative | consistency emerging | first "not enough yet" → first faint hedged note | first gentle weekly Review |
| **Month 1** | grounded reflect from real record | patterns (hedged) on a habit | first corroborated observations, provenance‑borne | settled weekly ritual; first monthly |
| **Year 1** | rich, humble reflect; nostalgia works | deep honest history | stable tendencies (as tendencies), correctable | meaningful yearly look‑back |
| **Year 5** | trusted, near‑invisible | long record | deep understanding, held most humbly | a life's worth of honest reviews |

**Evolution laws:** across every surface, **density stays minimal** and **visual complexity stays low** (Design5) — what grows is **depth, intelligence, and earned confidence**, never clutter or claim. Every surface *deepens without intensifying* (Design2). Empty‑with‑teaching precedes populated‑and‑hedged on every surface; nothing fabricates depth to appear complete.

---

## Part IX — Cross‑Surface Consistency Rules (the universal mental model)

Every surface follows the same mental model, so the whole product feels like one thing. Adapted for a reflection product (not every surface makes a claim), each surface makes legible — *where applicable*:

1. **What is this?** — clarity of purpose, at a glance. *(Design5; Krug.)*
2. **Where did it come from?** — provenance on any fact or claim. *(P4; Design3.)*
3. **How sure is it?** — calibrated confidence on any claim; facts stated plainly; "not enough yet" where thin. *(S4; Design3.)*
4. **What changed / what's new?** — honest, non‑alarming, where relevant. *(S6.)*
5. **What can I do with it?** — the person's agency, always present: correct, ignore, save, hide, ask‑why, revisit. *(Design4 agency; P5.)*
6. **What's empty, and why?** — honest emptiness, teaching, never broken. *(Part VII.)*

And every surface obeys the invariant laws from prior Designs: **deference, calm, one focal point, honesty, kindness** (Design5); **quiet intelligence** (Design4); **one‑way truth flow, the ceiling, traceability** (Design3); **serve the person, not the metric** (S7). A surface that cannot answer "what is this / where from / how sure / what can I do" — or that violates an invariant — is malformed by construction.

**Consistency law:** the person learns the mental model once (on any surface) and it holds everywhere — the same calm, the same honesty, the same agency, the same one canonical home per thing.

---

## The surface architecture, in one statement

> **LOCA is a small set of calm surfaces organized around what a person does: a reflective home they open daily (Today), a place to capture the doing (Habits), a hub to revisit and understand their life over time (Life — Timeline, Reviews, Understanding, People, Direction), a way to ask their own questions (Ask), and a place to own and inspect everything LOCA holds (You/Trust) — reached through calm entry points and quiet ambient surfaces, each the single canonical home of one need, each teaching honestly when empty, each deepening in understanding but never in clutter or claim, and every one answering the same questions in the same calm voice: what is this, where did it come from, how sure is it, and what can I do with it.**

This surface architecture is the blueprint every screen in Version 3 must fill. Design7 onward may specify *how each surface is structured and expressed within the interface constitution* — but may not add a surface without a canonical need, duplicate an owned one, or violate the frequency, empty‑state, or consistency laws.

---

*Design6 complete. The complete surface architecture, surface‑relationship map, surface‑ownership framework, product‑flow map, entry‑point architecture, empty‑state philosophy, surface‑evolution framework, frequency model, and cross‑surface consistency rules are defined and derived entirely from Phase R, Phase S, and Design1–5. No mockups, wireframes, Figma, SwiftUI, implementation, or visual component design were specified. Stop here; do not begin Design7. Design6 is ready for review.*
