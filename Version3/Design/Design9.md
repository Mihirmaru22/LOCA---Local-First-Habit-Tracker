# LOCA Version 3 · Design Phase
## Design9 — System Architecture of the User Experience

> **The single question Design9 answers:** *How does the entire product behave as one living system — one intelligence observing one life — rather than a collection of features?*
>
> This is **system‑level product design**, not engineering. It contains **no UI, no implementation, no database schema, no API design, no SwiftUI, no technical architecture.** Every conclusion is consistent with the frozen foundation — Phase R (R1–R10), Phase S (S1–S7), and Design1–8.
>
> **The premise:** a person should never think "now I'm using Habits," "now I'm using Life," "now I'm using Memory." They should feel one intelligence attending to one life. Design9 defines how the parts cohere into that single thing.

---

## Part I — The Unifying Principle: one record, one life

The coherence of LOCA does not come from *integrating features with each other.* It comes from a single structural fact: **every capability is a producer or consumer of one shared record of one life.** Capabilities never couple to each other directly; they connect only *through the record* (Design3's Record stratum). This is the whole secret of the system's unity:

- There is **one record** — the person's truthful, timestamped life (Design3).
- Every capability **writes to it or reads from it** — nothing else.
- Because there is one source of truth and one‑way flow (facts up into derivations, never sideways or down — Design3), **consistency is automatic**: change the record, and everything derived from it re‑derives; there is nothing to keep "in sync" because there is only one copy of the truth.

The person experiences "one intelligence observing one life" because there *literally is* one life‑record, and every surface is a different honest view onto it. **LOCA is not a suite of features that share data; it is one record that the person meets in several ways.** That distinction is the entire system architecture.

---

## Part II — The Ecosystem Architecture (producers & consumers)

Every capability, classified by its role in the one ecosystem. **P** = produces facts into the record; **C** = consumes/derives from it; **P+C** = both.

| Capability | Role | Produces | Consumes / derives | Contribution to the whole |
|---|---|---|---|---|
| **Habits** | P | logged behavior (facts) | — | the doing, honestly recorded |
| **Reflections** | P | the person's own meaning (facts) | seeded from the record | the person's authored understanding |
| **State check‑ins** | P | explicit self‑reports (facts) | — | ground truth + calibration |
| **Direction / Goals** | P | the person's stated aims (facts) | trajectory context | intent that frames everything |
| **Sensed signals** (Health, Calendar, Location) | P | provenance‑tagged context (facts) | — | honest context, consented |
| **Understanding** | C | — | patterns over the record | hedged self‑observations |
| **Reviews** | C | (a saved artifact) | the period's record + observations | the reflective ritual |
| **Timeline / Memory** | C | (confirmed landmarks) | the whole record | continuity and revisiting |
| **People** | P+C | confirmations | recurrence over the record + consent | relational continuity |
| **Ask** | C | (saved answers) | the record + hedged derivations | the person's own inquiry |
| **Search** | C | — | the record | retrieval |
| **Notifications** | C | — | the weekly batch of noticing | the one gentle beat |
| **You / Trust** | P+C | corrections | the live model | ownership + inspection |

**The ecosystem law:** producers feed the *one record*; consumers derive honest views *from it*; the record is the sole meeting point. No capability depends on another capability — each depends only on the record. This is why the product feels like one thing and why any part can be added, changed, or removed without breaking the others (Parts VIII–IX).

---

## Part III — The Information Ownership Model

Every concept has exactly **one canonical owner** (the single place it is created/edited/reasoned about), any number of **consumers** (read‑only), **derived views** (recomputed from the record, never stored copies), and a **synchronization philosophy** that is trivially simple because there is one source of truth.

| Concept | Canonical owner | Consumers | Derived view? |
|---|---|---|---|
| **Habits (definitions & logs)** | Habits | Understanding, Reviews, Timeline | facts (not derived) |
| **Reflections** | the Record (Timeline) | Today, Reviews | facts |
| **Insights / observations** | Understanding | Habit detail, Reviews, Today (≤1) | derived (recomputed) |
| **Patterns** | Understanding | Habit detail, Ask | derived |
| **Events** | Timeline (confirmed) | Reviews, Understanding | derived candidate → confirmed fact |
| **Chapters** | Timeline (confirmed) | Understanding (baseline context), Reviews | derived candidate → confirmed fact |
| **Relationships / People** | People | Understanding, Timeline | derived (from consented signals) + confirmation |
| **Goals** | Direction | Reviews, Today (framing) | facts |
| **Memories / the record** | Timeline | everything | facts |
| **Traits** | *no owner (do not exist)* | — | — |
| **Questions & answers** | Ask | Life (references) | answers are derived (re‑derivable) |
| **Reviews** | Reviews | Today (teaser), Timeline | artifacts (kept) over derived content |
| **What LOCA believes** | You/Trust › Beliefs | (any corrected claim) | the live model (derived + corrections) |

**Synchronization philosophy:** *there is nothing to synchronize.* Facts live once in the record; every view is either a fact shown in place or a derivation recomputed on demand from the record. A change to a fact automatically changes every view of it, because no view holds its own copy. **The absence of duplication is not a discipline to maintain — it is a structural property of the one‑record design.** Two editable copies of anything would be a defect, and the architecture makes them impossible by construction. *(Design3; Design6/7.)*

---

## Part IV — The Cross‑System Dependency Model

What happens when one area changes — and the answer is always the same shape, because everything flows through the record:

- **A habit changes / is logged →** a fact enters the record → *derivations that depend on it re‑derive*: its patterns (Understanding), the current Review, the Timeline's newest slice. Nothing else is touched; nothing is directly coupled. *(Design3 one‑way flow.)*
- **A candidate life event appears →** it is *not* asserted; it waits at the record's edge until the person confirms significance → on confirmation, it becomes a landmark (Timeline) and may reset baselines and open a chapter, which re‑frames future observations (Understanding). *(S5; Design3.)*
- **A relationship becomes important →** more consented recurrence in the record raises a person's salience (People) → that person becomes available as honest context in Understanding and Timeline. Nothing is asserted about the relationship's nature without confirmation. *(Design3; Design6.)*
- **A goal / direction changes →** a fact enters (Direction) → it re‑frames what reflection attends to (Today, Reviews) and what counts as relevant to surface (Design8 relevance gate). It never rewrites the record or prescribes. *(S3; Design8.)*
- **A user correction →** enters as the highest‑authority fact → immediately overrides the corrected derivation and is retained to prevent re‑learning; every view of that belief updates at once. *(S4/S5; Design3.)*

**The dependency law:** every change propagates **upward through the record and its derivations, never sideways between features.** Because derivations are recomputed from facts (Design3), the system is *self‑consistent by construction* — there are no feature‑to‑feature dependencies to break, and a change in one area can only affect areas that honestly derive from the same facts. This is graceful coherence, not managed coupling.

---

## Part V — The User Mental Model

The person should never learn LOCA's architecture; the product should feel obvious because it maps to their actual life, not to modules. The mental model LOCA should cultivate:

1. **"It remembers my life and helps me understand it."** The single sentence that explains the whole product. *(S3.)*
2. **Everything is connected — because it's all one life.** The person doesn't experience "modules that link"; they experience one life reflected several ways. Connection is the natural state, not a feature. *(Part I.)*
3. **Every action has context.** What they do carries its time, place, and relevance with it (Design7 context preservation) — nothing is context‑free.
4. **Every insight has evidence.** Nothing is asserted without a traceable why (Design3) — so the person learns to trust that they can always ask "why?"
5. **Every memory has a place, and every observation belongs somewhere.** There is one home for each thing (Part III), so the person always knows where to find it and never encounters it twice.

**The mental‑model law:** the person's model of LOCA should be *their model of their own life* — a continuous story with a memory and an honest observer — not a map of features. If the person ever has to think about *where a capability lives* rather than *what they want to understand*, the system has failed to be one thing. The product feels obvious precisely because it has no architecture the person must hold in mind.

---

## Part VI — The System Consistency Framework

Every subsystem obeys the same conventions, so the person never feels they entered a different application:

- **Naming & terminology:** one vocabulary throughout — plain, human, the person's words for their life (a *reflection*, a *habit*, a *review*, a *moment*), never internal engine names. The same thing is called the same thing everywhere. *(R5; Design5.)*
- **Time:** one timeline, one sense of "now," "this week," "this chapter" — the same time model everywhere (Design3), so a "week" means the same thing on every surface.
- **Evidence:** every claim is traceable to the record the same way, everywhere. *(Design3.)*
- **Confidence:** the same calibrated language and the same honesty about uncertainty on every surface. *(S4; Design4.)*
- **Actions:** the same agency everywhere — the person can always correct, ignore, save, hide, ask‑why, revisit. *(Design4.)*
- **Empty states:** the same honest, teaching, never‑broken pattern on every surface. *(Design5/7.)*
- **Explanations:** "ask why?" always yields the same faithful, evidence‑bearing answer, on any claim. *(Design3/4.)*
- **AI observations:** always hedged, provenance‑bearing, correctable — the same voice everywhere. *(Design4.)*
- **User corrections:** always authoritative, immediate, visibly updating — the same behavior everywhere. *(S4/S6.)*
- **Navigation language:** the same calm, conventional movement; deep‑links always lead to the one canonical home. *(Design5/6.)*

**The consistency law:** the person learns LOCA's conventions once, on any surface, and they hold everywhere — the same calm, the same honesty, the same agency, the same words. Consistency is what makes many surfaces feel like one intelligence.

---

## Part VII — The Long‑Term Evolution Framework

How the ecosystem scales as data grows from a week to a decade — **by deepening the same few surfaces, never by adding surfaces.**

| Horizon | Complexity | Discoverability | Old knowledge |
|---|---|---|---|
| **1 week** | minimal; mostly empty‑teaching | trivial (little to find) | n/a |
| **1 month** | first hedged depth beneath calm surfaces | search + Timeline emerge | recent, fresh |
| **1 year** | rich depth, still calm on top | Timeline + search + Understanding carry it | nostalgia begins; the record appreciates |
| **5 years** | deep, humble; surfaces unchanged in number | discovery is retrieval, not more menus | a life's record, revisitable |
| **10 years** | vast beneath, quiet above | the person finds by asking/searching/revisiting | legacy‑grade; more valuable than ever |

**The evolution laws:** (1) **complexity grows downward, not outward** — the surface count and the top‑level calm never change; depth accretes in L2/L3 (Design5/7). (2) **discoverability scales through retrieval** (search, Timeline, Ask), not through more navigation. (3) **old knowledge stays useful** because the record appreciates (Design3 time model) — a ten‑year‑old fact is more precious, not less. The system scales like a life scales: more history, same person, one continuous record. *(Design2; R10.)*

---

## Part VIII — Extensibility Principles (how Version 4+ enters)

The architecture must accept new capabilities for years without redesign. It can, because the stable core is small and everything else plugs into it:

- **The stable core is two things:** the **one record** and the **Constitution (S7)**. Everything else is a producer or consumer over the record, bound by the Constitution.
- **How a new module enters:** as a new producer or consumer over the *same record*, obeying the same laws (one canonical home, one‑way flow, honesty, calm, the attention bar). It never couples to existing features — only to the record — so existing flows are undisturbed. *(Part II; Design3.)*
- **How existing flows stay stable:** because nothing depends on a *feature*, only on the *record*, adding a capability cannot break an existing one. New views are new derivations; old views are unchanged. *(Part IV.)*
- **How future AI models integrate:** the interface to intelligence is the **reasoning constitution (S4)**, not a specific model. Any model — better, cheaper, on‑device — plugs in *behind* the same rules (evidence‑bounded, hedged, provenance‑preserving, abstaining). The model may change; the honesty contract may not. *(S4; R4.)*
- **How new sensors fit:** as new provenance‑tagged, consent‑gated inputs to the record — honest context, weighted by reliability (Design3/R8). A new sensor is just a new producer; it changes nothing downstream except the evidence available.
- **How future life domains appear:** as new honest derivations over the record (e.g. a new kind of pattern), gated by the same evidence and attention laws. A domain earns a surface only if it is the canonical home of a real need (Design6).

**The extensibility law:** LOCA grows by *adding producers and consumers over the one record, under the one Constitution* — never by bolting on disconnected features. The record and the Constitution are the load‑bearing constants; everything else is replaceable and additive. This is why the architecture stays coherent for years.

---

## Part IX — Graceful Degradation & Failure Containment

No subsystem may break the whole experience — and none can, because everything rests on the record, and the record is the person's own facts, which no external failure can touch.

| Failure | What is lost | What continues (the floor) |
|---|---|---|
| **Calendar disappears / never granted** | People, calendar context | everything else; People shows its honest, payoff‑named empty |
| **Health data stops** | health‑derived context, some patterns | everything else; confidence on affected observations drops honestly |
| **AI / inference fails entirely** | derivations (observations, patterns) | **the entire capture + reflect + record loop** — the core product — plus honest facts, reviews‑of‑facts, Timeline, search |
| **Inference confidence drops** | claims fall below threshold → abstain | honest "not enough to say"; facts and reflection unaffected |
| **The person stops logging** | new inputs | the whole existing record — revisit, reflect, remember; value persists with zero new input |
| **The person deletes data** | what they chose to delete | whatever remains, honestly; deletion is sovereignty, not failure |

**The degradation law:** because every capability depends only on the record, a failure removes only *what honestly derived from the missing input* — never the core. **The record + the capture/reflect loop are the floor, and nothing external can break them.** LOCA always degrades to "an honest record of your life you can revisit and reflect on" — which is still genuinely valuable (Design2 — valuable even when the person stops). Every failure is contained to the derivations that depended on the lost input; the one life, and the person's ability to see it, always remain. *(Design3; S6; R8 graceful degradation.)*

---

## Part X — The Product Integrity Audit

Challenging the whole V3 system against the Constitution:

- **Does every capability justify its existence?** Yes — each maps to an S3 root (Habits/Today → self‑opacity & reflection; Timeline → memory; Understanding → self‑opacity; Reviews → the ritual; People → relational continuity; Direction → meaning; Ask → self‑inquiry; You/Trust → ownership). No capability is orphaned. *(Design1/6; S3.)*
- **Is anything duplicated?** No — one canonical home per concept, enforced structurally by the one‑record design (Part III). Duplication is impossible by construction.
- **Is anything disconnected?** No — every capability connects through the record; there are no islands. *(Part I.)*
- **Is anything too tightly coupled?** No — nothing couples to a *feature*, only to the *record*, which is the loosest possible coupling. *(Part IV.)*
- **Is anything solving the wrong problem?** The one to watch: **Understanding** must not drift toward a feed of insights (the V2 failure) — it is held in check by the attention laws (Design8) and the evidence gates (Design3). **People** must not drift toward a CRM — held in check by consent‑gating and confirmation‑only nature (Design6/7). These are the two integrity risks, and both are constrained by prior design; they must be watched in Build.
- **Does the product still feel human?** Yes — it is organized around a life and its meaning, in plain language, with the person as author (Design5/S3). It maps to the person's life, not to a system.
- **Does every feature support the Constitution (S7)?** Yes — each was derived from it; the anti‑forms (oracle, dashboard, feed, CRM, coach) are structurally excluded.

**Recommendations:** no mergers or removals beyond those already made in Design1 (the V2 collapse). Two things to *watch* in Build, not redesign: Understanding's feed‑risk and People's CRM‑risk — both already fenced, both to be verified against the attention and consent laws when implemented.

**The integrity verdict:** the V3 system is coherent, non‑duplicative, loosely coupled, human, and constitutional — because it is *one record met several ways*, not a federation of features. The design is sound to build.

---

## Part XI — The Future Governance Framework

Every future feature (V4+) must pass this gate before entering LOCA. A single "no" rejects it, however impressive:

1. **Which user problem does it solve?** — must map to an S3 root (see, remember, or make honest sense of one's life). If none → reject.
2. **Which existing capability does it strengthen?** — it should deepen the ecosystem, not sit apart. If it's an island → reconsider.
3. **Does it duplicate something?** — if a concept already has a canonical home → it may summarize/link, never own a copy. If it duplicates → reject.
4. **Does it fit the ecosystem?** — is it a producer or consumer over the one record, under the Constitution? If it couples to features or breaks the one‑way flow → reject.
5. **Does it preserve simplicity?** — does it add depth, not a new top‑level surface? A new surface must be the canonical home of a real need (Design6). If it adds density/complexity at the top → reject.
6. **Does it increase trust?** — or does it risk a withdrawal (overclaim, hidden reasoning, privacy drift, manipulation)? If it withdraws trust → reject. *(S6.)*
7. **Does it strengthen long‑term understanding?** — does it serve the person's self‑understanding over years, not short‑term engagement? If it serves the metric → reject. *(S7 Art. IX.)*

**The governance law:** LOCA grows only through features that map to a real problem, strengthen the ecosystem, avoid duplication, fit the one‑record architecture, preserve calm, increase trust, and serve long‑term understanding. Anything else — however clever, however much it might increase usage — does not enter. This is S7's Decision Framework applied at the system level, and it is what keeps LOCA one coherent product for years. *(S7 Art. IX; Design8 anti‑manipulation.)*

---

## The system, in one statement

> **LOCA is not a collection of features that share data — it is one truthful record of one life, met in several honest ways. Every capability is only a producer or a consumer over that single record; none couples to another; and because there is one source of truth and one‑way flow, the whole system is consistent by construction — nothing to synchronize, nothing to duplicate, nothing that can break the core. The person never navigates an architecture; they meet their own life, remembered and reflected. New capabilities, new sensors, and new AI models plug into the same record under the same Constitution without disturbing what exists, and any external failure removes only what honestly derived from the lost input, never the record or the reflection that rest beneath everything. LOCA holds together as one living system for years because it was never many things — it is one record, one life, one honest observer, and one set of laws that everything obeys.**

This system architecture is the final coherence constraint on Version 3. Design10 may specify the remaining design synthesis — but may not introduce a capability that couples to features rather than the record, duplicates a canonical home, breaks the one‑way flow, or fails the governance gate.

---

*Design9 complete. The complete ecosystem architecture, cross‑system dependency model, information‑ownership model, user mental model, system‑consistency framework, long‑term‑evolution framework, extensibility principles, graceful‑degradation philosophy, product‑integrity audit, and future‑governance framework are defined and derived entirely from Phase R, Phase S, and Design1–8. No UI, implementation, database schema, API design, SwiftUI, or technical architecture were specified. Stop here; do not begin Design10. Design9 is ready for review.*
