# LOCA Version 3 · Design Phase
## Design8 — Attention Architecture

> **The single question Design8 answers:** *How should LOCA decide what deserves the person's attention?*
>
> This is **attention design and prioritization philosophy**, not mechanism. It contains **no UI, no implementation, no ranking algorithms, no SwiftUI, no notification‑scheduling code.** Every conclusion is consistent with the frozen foundation — Phase R (R1–R10), Phase S (S1–S7), and Design1–7 — drawing especially on **R3/R5** (calm technology, cognitive load, the attention‑economy critique), **R9** (notification fatigue), **Design4** (quiet intelligence, the one‑weekly‑beat proactivity bar), **Design5** (calm, deference), and **S6/S7** (no manipulation, serve the person not the metric).
>
> **The premise:** every modern product competes for attention by showing more. LOCA does the opposite — it competes by showing *less*, and earns trust by *withholding*. This document defines how LOCA earns every second of the person's attention, and how it decides, most of the time, to ask for none.

---

## Part I — The Attention Philosophy (the inversion)

The attention economy maximizes attention *captured*. LOCA minimizes attention *demanded* and maximizes the value of the little it asks. Four commitments define the inversion:

1. **Attention is the person's, borrowed reluctantly and repaid.** It is their scarcest, most exploited resource; LOCA treats every request for it as a debt it must be worth. *(R3 humane tech; R5 calm tech; P10.)*
2. **The default is silence.** LOCA's resting state is to show and say nothing. Something reaches the person only by clearing a high bar — *not* by default. **The burden of proof is on the interruption, never on the silence.** *(Design4; S4 — silence over low‑value speech.)*
3. **Attention flows downward.** By default, information settles *toward quiet* (toward the archive) as it ages; it rises *toward the person* only rarely and only when it earns it. The natural direction of the whole system is calmer, not louder. *(Design2 deepen‑without‑intensifying; Design5.)*
4. **Attention is spent, not captured.** LOCA never engineers its way into more of the person's attention; it spends the minimum honestly and lets the rest rest. *(P7; S6 anti‑dependency.)*

**The governing sentence:** *LOCA earns the person's attention by spending as little of it as possible — and the surest sign it is working is how often it stays quiet.*

The answer to the core question — *hundreds of logs, thousands of signals, dozens of insights, yet the person never overwhelmed* — is this: **almost none of it is ever surfaced.** It exists, it's findable, it's honest — but it waits, quietly, until the person comes to it or a weekly ritual gently gathers it.

---

## Part II — The Attention Hierarchy

Five levels, ordered by how much attention they ask. LOCA has **almost nothing** at the top — it is not an urgent product.

| Level | Name | What lives here | How the person meets it |
|---|---|---|---|
| **L1** | **Deserves a gentle interrupt** | essentially *only* the weekly Review; and, rarely, a genuinely significant, honest, earned moment | a calm, opt‑in notification — the one sanctioned beat *(Design4)* |
| **L2** | **Present when the person opens LOCA** | the day's single focal thing (Today's reflect prompt); a fresh Review if one is waiting | shown, once, when they arrive — not pushed |
| **L3** | **Worth a quiet ambient glance** | a calm widget/Watch presence — a prompt or a quiet piece of the record | seen only if they look *(Design2 ambient; Design5)* |
| **L4** | **Available if curious** | Understanding, patterns, People, Direction, Timeline depth | reached by deliberate exploration |
| **L5** | **Historical archive** | the full record — every fact, reflection, review, landmark | reached only when the person goes looking |

**Movement between levels — the critical asymmetry:** things move **down** easily and **up** almost never. An observation is born at L4 (available if curious), may be *gathered* into L2/L1 by a weekly Review, and *settles* to L5 (archive) as it ages. **Nothing climbs toward interruption on its own; time and irrelevance push everything toward quiet.** The only routine upward motion is the weekly ritual briefly lifting a *batch* of the week's noticing to L1 — and then releasing it back down.

**LOCA has essentially no "critical now."** Unlike the attention economy's fabricated urgency, LOCA is a companion to a life, and a life is rarely an emergency. There is no red badge, no "act now," no thing that cannot wait for the person to come to it or for the weekly beat to gather it. *(R3; S6.)*

---

## Part III — The Priority Framework (what earns attention)

What makes something worth the person's attention is not a score to *rank and surface* — it is a set of **gates that mostly resolve to "stay quiet."** A thing reaches attention only if it passes **all** gates; failing any leaves it at L4/L5, available but silent.

**The gates (all must pass to rise):**
- **Honest?** — sufficient evidence and calibrated confidence (Design3/4). Thin evidence → stays quiet. *(S4.)*
- **Relevant?** — connected to what the person cares about (their goals, their direction, their life right now). Irrelevant → stays quiet. *(S3; the person's own things weigh most.)*
- **Significant?** — a real magnitude of change or meaning, not a trivial true fact. Trivial → stays quiet. *(P10 calm.)*
- **Worth the interruption?** — does it repay the attention it would cost? If not → stays quiet. *(Design4.)*
- **Safe?** — does surfacing it do no harm (never a negative verdict, never rumination‑inducing)? If not → stays quiet or silent. *(P8.)*
- **The person's, not the product's?** — does it serve the person's understanding, not engagement? If the product's → never. *(P7.)*

**How the factors interact (conceptually, not algorithmically):**
- **Evidence strength & confidence** are *prerequisites* — no amount of the others compensates for thin evidence (an unearned claim never rises). *(S4.)*
- **Recency & magnitude of change** raise significance — but only *within* honesty; a big *inferred* swing on thin data is still silenced (the F1 guard).
- **The person's goals, interests, and direction** are the strongest *relevance* signal — the person's own concerns outrank system‑generated ones. *(P1, P5.)*
- **Novelty & emotional significance** are handled with suspicion, not enthusiasm — they are exactly what the attention economy exploits. Novelty alone never earns attention; emotional significance never earns it *for engagement's sake*, and a heavy emotional reading is more likely to warrant *silence* (do no harm) than a surface. *(R3; P8.)*
- **Long‑term relevance** favors patience — something that matters over months does not need to interrupt today; it waits for the Review or the person's own return.

**The priority law:** priority is a *filter toward silence*, not a *ranking toward the feed.* Run any candidate through the gates and most resolve to "stay quiet, stay findable." That is the correct, calm outcome.

---

## Part IV — The Notification Philosophy

Every notification is a withdrawal from trust (S6) and must justify its existence (Design4). The decisions:

| Disposition | What qualifies | Why |
|---|---|---|
| **Interrupt (a gentle notification)** | *only* the weekly Review (opt‑in); and, very rarely, a genuinely significant honest moment | the one sanctioned beat; the retention ritual done calmly *(Design4; R1/R9)* |
| **Silent delivery (waits in place)** | new observations, patterns, landmarks — everything the person will find when they come | the person meets it on their terms, not LOCA's *(Design4)* |
| **Batching (gathered, not streamed)** | the week's worth of noticing → delivered *once*, in the Review | one calm appointment replaces many interruptions *(R9 anti‑fatigue)* |
| **Waiting (the default)** | nearly everything | the burden of proof is on the interruption |
| **Never a notification** | streaks, guilt, re‑engagement, FOMO, "we miss you," a new pattern (waits for the Review), a decline, anything serving the product | these are the attention‑economy patterns LOCA refuses *(P7; R3; S6)* |

**The notification law:** LOCA interrupts on essentially **one gentle weekly beat** and almost never otherwise. The Review is not a stream of alerts — it is a *batch*, a single quiet gathering of a week's noticing, so the person is never pelted. Everything else waits, silently, to be found.

---

## Part V — The Insight Competition Model

When several things could take the limited attention (Today's one focal slot, or the Review's few), LOCA's first instinct is **to show fewer, or none — not to crown a winner.** But when it must choose, the ordering:

1. **The person's own things win.** A question they asked, a correction they made, a goal they set — these outrank any system‑generated insight, always. The person's agency is not in competition with the system's cleverness; it precedes it. *(P1, P5.)*
2. **Honest, significant, real change** (a genuine milestone, a confirmed life event) over a hedged observation. But a life event *waits for the person's confirmation* before it competes at all. *(S5.)*
3. **A hedged observation** only if it passes every Part III gate — and only one at a time (Today), or a few (Review).
4. **Emotional significance never wins by being emotional.** It is never used to grab attention; a heavy emotional reading more often earns silence (do no harm). *(P8; R3.)*

**The competition law:** the default resolution of competition is *restraint* — surface less. When one must be chosen, the person's own concerns outrank the system's, honesty gates everything, and nothing wins by exploiting emotion or novelty. A correction the person made always beats an insight LOCA generated.

---

## Part VI — The Time Sensitivity Framework

Different information ages differently; attention to it changes over time — and the direction is almost always *downward*.

| Horizon | What it governs | How attention behaves |
|---|---|---|
| **Immediate** | the current moment, raw signals | mostly never surfaced; transient context |
| **Daily** | today's reflect + record | one calm focal presence, then gone by tomorrow |
| **Weekly** | the Review's batch | the one appointment; rises to L1 briefly, then settles |
| **Monthly** | a deeper look‑back | gentle, optional |
| **Seasonal** | the wider arc | rare, for those who want it |
| **Permanent** | the record | always *available* (L5), never *urgent* — value grows, urgency never does |

**The time law:** *nothing in LOCA becomes more urgent with age* — the exact opposite of a feed, where staleness drives escalation. In LOCA, time moves everything *down* the hierarchy toward the calm archive, while the record's *value* (not its urgency) quietly grows. The past is precious and never pressing.

---

## Part VII — The Attention Recovery Model

People miss things. How LOCA handles it, without nagging:

- **Should important insights return?** Rarely, and gently. A genuinely important, honest observation may reappear *once*, in a natural context (the next Review) — never as a repeated nudge. *(Design4; R9 anti‑fatigue.)*
- **How often?** At most a small, bounded number of times, then it rests. LOCA surfaces something a few times at most and then trusts the person to find it. Repetition past that is nagging, and nagging is forbidden. *(P7; S6.)*
- **When does it disappear forever from surfacing?** After it has been available and unengaged, it retires to the discoverable archive (L5) — it stops being *surfaced*, but is never *deleted* and remains findable. *(Design3 retirement; Design7 lifecycle.)*
- **What stays discoverable without becoming repetitive?** Everything — the entire record and all past observations remain findable on demand (search, Timeline, Understanding), but *nothing is force‑repeated.* Discoverability is the person's to exercise; re‑surfacing is not LOCA's to impose.

**The recovery law:** LOCA offers something a few times at most, then lets it rest in a place the person can always find it — trusting the person over pestering them. Missing something is not a failure to be corrected with more alerts; it is the person's prerogative, respected.

---

## Part VIII — The Quiet Technology Philosophy

Silence is not the absence of the product — it is a core feature of it (R5 calm technology; Design2/5).

- **When LOCA should intentionally do nothing:** most of the time. On an ordinary day with nothing honestly worth the person's attention, the correct behavior is *nothing* — no prompt engineered to pull them in, no manufactured reason to open. *(Design4; P10.)*
- **When silence is the correct experience:** during difficulty the person hasn't invited LOCA into; during thin‑evidence stretches; whenever a surface would cost attention it can't repay. Silence protects the person and the calm the product is made of. *(P8; Design4.)*
- **When the absence of a notification builds more trust than a reminder:** almost always. Every day LOCA *doesn't* bother the person is a trust deposit — "it respects me, it isn't trying to hook me." A companion that stays quiet when it has nothing to say is trusted precisely *because* it can be relied on not to intrude. **The un‑sent notification is one of LOCA's most powerful trust‑building acts.** *(S6; R9.)*

**The quietness law:** LOCA's default is to do nothing, and its silence is a promise kept. A quiet day is not a disengaged user or a failed product — it is the product working exactly as intended.

---

## Part IX — The Attention Personalization Framework

Attention adapts over years — but in the *opposite* direction from every engagement product. LOCA personalizes toward **quieter**, not **louder.**

- **How attention adapts:** LOCA learns what the person *ignores* and surfaces it *less* — not what they engage with, to surface it *more.* The learning signal of an engagement app (what pulls you back) is inverted: LOCA reads disengagement as "don't surface this," and honors it. *(P7 inversion; S6.)*
- **How behavior changes prioritization:** the person's actions — what they reflect on, correct, ask about, set as a goal — raise the relevance of *related* things and lower everything they consistently pass over. *(Design3 learning; P1.)*
- **How goals influence attention:** the person's stated direction/goals make related honest observations more relevant (more likely to pass the relevance gate) — never more *insistent.* Relevance rises; volume never does. *(S3; Part III.)*
- **How trust influences attention:** LOCA's license to surface anything is *earned slowly and always conservatively* (Design2 intelligence evolution). More trust never means more interruption; it means LOCA is a more accurate judge of the rare thing worth surfacing. *(S6.)*
- **How ignored insights behave:** they get quieter and retire to the archive; a repeatedly ignored kind of observation is surfaced less and less, then not at all — the person can still find it, but LOCA stops offering it. *(Part VII.)*
- **The person can always tune it directly.** Attention is not only inferred; the person can turn any category of surfacing up or down explicitly, and that instruction is authoritative. *(P5.)*

**The personalization law:** LOCA's personalization of attention is a *dimmer that mostly turns down.* It learns the person's threshold for being worth interrupting and drifts, over years, toward the quiet that person prefers — never toward the escalation an engagement model would pursue.

---

## Part X — The Anti‑Manipulation Principles (what LOCA will never do)

Explicit and absolute, derived from R3/S6/S7. LOCA will **never**:

- **Optimize for engagement, session count, or return frequency.** These are not goals; healthy low usage is success. *(P7; S3.)*
- **Build an infinite feed** or any endlessly‑scrolling surface. *(R3; Design1.)*
- **Manufacture urgency without evidence** — no "act now," no fabricated timeliness. *(Part III; S4.)*
- **Use artificial scarcity** — no limited‑time anything, no "you're about to lose." *(R3.)*
- **Build addictive loops** — no variable‑reward mechanics, no dopamine engineering. *(R3 reward schedules; P7.)*
- **Use dark patterns** — no confirmshaming, no guilt, no roach‑motel, no hard‑to‑find opt‑outs. *(R9; S6.)*
- **Weaponize streaks, FOMO, or "we miss you."** *(R9; Design2.)*
- **Exploit emotional significance to capture attention.** *(P8; Part III.)*
- **Escalate to recover a lapsed user.** Absence is respected, never punished or pursued. *(S6; Design2.)*

**The anti‑manipulation law:** any attention decision that would increase usage at the cost of the person's interest is forbidden — regardless of how effective it would be. The test is S7's: *whose goal does this serve?* If the product's, it does not ship.

---

## Part XI — The Review Attention Model

How attention is organized across the natural cycles (Design2 rhythm), and what belongs in each:

| Cycle | Attention it carries | What belongs |
|---|---|---|
| **Daily use** | one calm focal presence | the reflect prompt; today's record; nothing more |
| **Weekly review** | the primary attention appointment — the batch | the week's honest facts (habits, notable moments) + ≤ a couple hedged observations + a reflection space |
| **Monthly review** | a deeper, gentler look‑back | the month's shape; forming chapters; the person's monthly reflection |
| **Quarterly / seasonal** | the wider arc (optional) | the season's landmarks; longer trends (honest); direction check |
| **Major life transitions** | a gentle, person‑confirmed acknowledgment | a chance to confirm the turn, open a chapter, and reflect — never a system declaration *(S5)* |

**The review law:** attention is *concentrated into cycles* so the rest of the time can be quiet. The weekly Review is the appointment that lets LOCA say almost nothing the other six days — a week's noticing gathered into one calm moment rather than scattered across seven. The larger the cycle, the rarer and gentler the attention, and transitions are always the person's to confirm.

---

## The attention architecture, in one statement

> **LOCA decides what deserves attention by starting from silence and demanding that anything earn its way out of it — passing every gate of honesty, relevance, significance, safety, and service‑to‑the‑person, most things failing and staying quietly findable rather than surfaced. It has almost no "now": nothing is urgent, nothing escalates with age, and time moves everything downward toward a calm archive whose value grows but whose urgency never does. It interrupts on essentially one gentle weekly beat that batches a week's noticing into a single quiet appointment, and otherwise waits — treating every un‑sent notification as a trust deposit and every quiet day as the product working as intended. It personalizes toward quieter, learning what the person ignores and offering it less, and it refuses every attention‑economy tool — no feeds, no urgency, no scarcity, no streaks, no dopamine, no dark patterns — because the only attention worth having is attention freely given to something genuinely worth it. LOCA earns every second of the person's attention by asking for almost none.**

This attention architecture governs every decision about what LOCA surfaces, when, and how loudly. Design9 onward may specify *how attention is expressed and organized within the interface* — but may not introduce a surfacing, a notification, or a prioritization that violates the silence‑by‑default, downward‑flow, one‑weekly‑beat, or anti‑manipulation laws.

---

*Design8 complete. The attention philosophy, attention hierarchy, priority framework, notification philosophy, insight‑prioritization model, time‑sensitivity framework, attention‑recovery model, quiet‑technology philosophy, personalization framework, anti‑manipulation principles, and review‑attention model are defined and derived entirely from Phase R, Phase S, and Design1–7. No UI, implementation, ranking algorithms, SwiftUI, or notification‑scheduling code were specified. Stop here; do not begin Design9. Design8 is ready for review.*
