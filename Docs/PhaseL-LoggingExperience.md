# Phase L — Logging Experience

## Session L1 — Understanding the Logging Problem

*No UI. No code. No wireframes. This session defines the problem, the cases, the
pain, and the principles that any later interaction model must obey. L2 does not
begin until this foundation is approved.*

> LOCA's north star: **"Disappear by default. Speak only when genuinely worth
> hearing."** Logging is the highest-frequency interaction in the product. It is
> therefore the single place where "disappear by default" is most tested — and
> most often violated.

---

## 1. What the user is actually trying to accomplish

Logging is never the goal. Nobody opens a habit tracker because they want to fill
in a log. Logging is the tax paid to receive the reward. The real jobs-to-be-done,
in priority order:

1. **Acknowledge a completion.** "I did the thing — mark it." The defining mental
   state is *past tense, already true*. The event happened in the physical world;
   the user is **reporting** it, not deciding it. This reframes everything: a log is
   a **confirmation**, not an act of authoring.
2. **Receive reinforcement.** See the ring fill, the streak tick, the cell darken,
   feel the haptic. This feedback *is* the reason logging exists. It is the product's
   core loop.
3. **Keep the record honest.** Occasionally correct or backfill so the history the
   user trusts isn't a quiet lie. Trust in the data is a precondition for the reward
   meaning anything.
4. **Capture context, rarely.** Attach a note when something was notable ("knee hurt
   today"). The exception, not the rule.

**The core insight that governs the phase:** the completion already happened. The
software's only job is to *witness* it with the least possible ceremony. If logging
feels like data entry, we have mistaken the software's problem (storing a record) for
the user's problem (being acknowledged and reinforced).

### The two moments (they are different products)

| | **Completion moment** | **Bookkeeping moment** |
|---|---|---|
| Trigger | Just did the habit, or "yes, done today" | Noticed the record is wrong |
| Frequency | ~95% of all logs | ~5% |
| Deliberation | None. Reflex. | Deliberate, considered |
| Context | On the go, one-handed, glancing, maybe from a widget/notification | Seated, focused, in the app |
| Fields in play | Which habit (usually already known) + at most one number | Date, time, amount, note, delete |
| UI tolerance | Near-zero. Any friction is multiplied by frequency. | High. Rare, so more UI is acceptable. |

**The current design's fatal error is serving the 5% moment as if it were the 95%
moment.** The Add Check-in sheet opens with *"When?"* — the one thing that is
*already known* 95% of the time (today, now) — and buries the only genuinely variable
field (amount) beneath it. It leads with the least-relevant decision.

---

## 2. Common vs. uncommon cases

Logging has, at most, four degrees of freedom. Decomposing them by how often each
actually needs the user's attention is the heart of L1.

| Degree of freedom | Needs attention when… | Frequency it matters |
|---|---|---|
| **Which habit** | Entering from a global surface | Free when entered from the habit / its widget / its notification; a pick otherwise |
| **Did it / how much** | Binary: never (implicitly "yes, once"). Quantitative: the amount. | Binary: **0 fields, ever.** Quantitative: **exactly 1 field.** |
| **When** | Backfilling or correcting a past day | Today + now **~95%**. Backdate ~4%. Future <1% (arguably invalid — see §5). |
| **Note** | Something notable happened | Empty **>90%**. (The app already treats notes as optional and the journal only surfaces entries that *have* a note — the product's own behavior confirms notes are the exception.) |

### The common case collapses to almost nothing

- **Binary habit:** *"It happened, today."* A check-off's value is always `1.0`. It
  carries **zero variable information**. There is literally nothing to fill in. The
  ideal cost is a **single confirming gesture with no screen at all**.
- **Quantitative habit:** *"This amount, today."* One number. Everything else
  (date, time, note) defaults. The ideal cost is **one input, then done** — and
  even the number is often predictable (a repeated 3.2 km loop; hitting the target).

Everything else — the exact time, the note, editing, backfilling a missed day,
deleting a mistake — is the **long tail**. It must remain reachable, but it must
never sit in the primary path.

### Grounding in the codebase

This is not a hunch. The data model already encodes it:

- `LogEntry.value` defaults to `1.0`; for binary it is *always* `1.0`. The schema
  itself says a binary log has no payload.
- `HabitBoard.updateStreak(using:)` has a documented fast path valid **only for an
  entry dated today**. Any backdate, edit, or delete is explicitly the slow path
  (full historical recalculation via `StreakCalculator`). The engine is already
  optimized for "today, now" and treats bookkeeping as the expensive exception. The
  interface should mirror the engine's own priorities.

### Representative scenarios (to keep "common" concrete)

- **Commuter, one hand, subway.** Checks off *Meditate* from a widget or the habit
  card without looking closely. Wants: one thumb, one tap, a haptic, done. *(common)*
- **Runner, just back, sweaty.** Punches *5.1* into *Running* and is gone. Wants:
  one number, no wheels, no Save hunt. *(common)*
- **In bed at 11pm.** Realizes they forgot to mark *Floss* yesterday. Wants:
  yesterday, quickly, without it cluttering the everyday path. *(uncommon)*
- **The occasional journaler.** Wants to note "knee hurt" on today's run. Wants the
  note to be *available* but not *demanded*. *(uncommon)*

Design for the first two. Accommodate the last two without letting them shape the
default.

---

## 3. Pain points in the current model

Grounded in `AddCheckInSheetView`, `HabitTodaySection`, and the shared data model.

1. **Field-order inversion.** The sheet leads with *"When"* — a graphical month
   calendar plus hour/minute wheels — i.e., the most-known, least-needed information
   is given the most prominence and the top of the screen. Attention is spent
   confirming a decision that was never in question.
2. **Binary habits are given a form at all.** A check-off has nothing to enter, yet a
   heavyweight "Add Check-in" sheet exists as a sibling to the one-tap quick button.
   Two ways to do a thing that needs zero fields is one too many, and the ceremonial
   one legitimizes ceremony.
3. **False-precision time.** Hour + 15-minute wheels imply the exact minute matters.
   It essentially never does, and quick logs already just store `Date()`. Presenting
   precision the product doesn't use is a false affordance and a pure cognitive tax.
4. **"Save" gates a fact.** *Save* implies a draft that might not be committed — a
   document model. A completion is not a draft; it already happened. The button turns
   an acknowledgment into a transaction with a commit step, adding a tap and a beat
   of "did it actually save?"
5. **The calendar is always visible.** A full month grid occupies the sheet's prime
   vertical space to serve a value that is "today" 95% of the time.
6. **Modality cost.** A sheet is a context switch: it covers the very thing the user
   was looking at (their progress), demands focus, and must be dismissed. For a
   sub-second acknowledgment, the modal frame costs more than its contents.
7. **The second interaction is unowned.** The far more common *follow-up* — "undo, I
   mis-tapped" or "it was 4, not 3" — isn't the design's center. Logging is treated as
   add-only. (A 5-second undo exists in the model; it isn't the interaction's spine.)
8. **One flow for two different problems.** Binary (0 fields) and quantitative
   (1 field) are pushed through comparable ceremony for tidiness. This underserves
   both: overkill for binary, mis-focused for quantitative.
9. **Friction is multiplied by frequency.** This is the app's highest-frequency
   interaction. A flow that feels fine once is corrosive at many logs per day across a
   habit set. Each extra tap/second is paid over and over. This is the precise inverse
   of the north star: the software insists on being *noticed* at the one moment it
   should disappear.
10. **Ambiguous entry points.** Quick button, sheet, editor, App Intent, widget — several
    write paths with different capabilities mean "how do I log" isn't singular. The
    fast path isn't obviously *the* path, which hurts learnability.

---

## 4. Design principles (the constraints L2 must honor)

Each is testable and traceable to the philosophy or Apple's HIG.

1. **Log = acknowledge, not author.** Every log confirms a past event; it does not
   compose a record. Language, defaults, and commit model all follow — including the
   removal of an explicit "Save."
2. **Assume the common case; reveal the rest.** *Today, now, no note, one entry* are
   defaults, never prompts. The 5% (backdate, note, edit, exact time) is reachable
   only on demand — progressive disclosure that earns its place, never in the primary
   path. *(HIG: progressive disclosure.)*
3. **Interaction cost must match information content.** A binary log ≈ 0 bits → it
   should cost ≈ 0 (one gesture, no screen). A quantitative log ≈ one number → it
   should cost exactly one input. Never charge more interaction than the data's
   entropy.
4. **Different metric types deserve different flows.** Do not unify for neatness.
   Binary and quantitative are different problems; a shared sheet is a false economy.
5. **Reversibility over prevention; confirmation over commitment.** Let the log land
   instantly and make it trivially undoable (undo, re-tap to toggle) instead of gating
   it behind Save + validation. Removes the "did it save?" anxiety. *(HIG: forgiving
   over preventive.)*
6. **Feedback is the reward — immediate, proportionate, on the surface already in
   view.** The reinforcement must land in the same breath as the gesture, where the
   user is already looking, not after a modal dismiss. Calm, not celebratory-spam: a
   streak milestone may speak; the 400th ordinary log stays silent. *("Speak only when
   worth hearing.")*
7. **Log where attention already is.** The best logging surface is adjacent to where
   the habit is already seen — its card, its ring, its widget, its notification — not
   behind navigation + a modal. Minimize the distance between *seeing* the habit and
   *marking* it; ideally introduce no new surface at all.
8. **One-handed, glanceable, forgiving of aim.** The primary gesture completes with
   one thumb, in motion, without reading, without precise targeting. Targets ≥44pt,
   bottom-weighted, no tiny wheels. *(HIG: touch targets, ergonomics.)*
9. **Optimize the aggregate, not the instance.** Judge every candidate by
   (taps × time × cognitive load) × logs-per-day — not by how it feels once in a demo.
10. **Disappear on success.** After acknowledgment the software recedes: no lingering
    sheet, no forced next step. The interaction ends by returning the user to their
    life. *("Disappear by default.")*
11. **Honesty is a feature, kept in its own lane.** Correction and backfill must exist
    — trust depends on them — but they live in the bookkeeping lane and never tax the
    completion lane.

---

## 5. Product decisions L1 proposes (assumptions to kill)

These are decisions about the *problem*, not the UI — commitments L2's interaction
models must respect. Each answers a "challenge every component" question.

- **"When?" leaves the primary path.** Today+now is assumed; date/time is
  disclosure-only, reached deliberately. *(Confidence: high.)*
- **No "Save" for logging.** The act of logging *is* the commit. *(High.)*
- **Binary needs no sheet, ever.** A check-off is a single confirming gesture with
  live, in-place feedback. *(High.)*
- **Drop minute-level time precision from the primary path.** Store the real moment;
  never make the user set it. Coarse buckets only if ever shown. *(High.)*
- **Future dates are not loggable in the primary path.** You cannot acknowledge a
  not-yet-done thing; the philosophy is witnessing what happened. *(Medium — confirm.)*
- **The calendar is not visible by default.** It appears only when the user has
  chosen to change the day. *(High.)*
- **The number is the only thing a quantitative log asks for** — and it should offer
  smart defaults (target value, last amount) so even that is often one tap. *(Medium.)*
- **Notes are opt-in and out of the default path.** *(High.)*
- **Undo is a first-class, always-present affordance,** not a buried edit flow.
  *(High.)*

---

## 6. Evaluation rubric (defined now, applied in L2)

Every interaction model proposed in L2 is scored on the criteria from the brief,
against explicit targets for the **common case** so grading isn't subjective:

| Criterion | Target — binary (common) | Target — quantitative (common) |
|---|---|---|
| **Taps** | 1 | ≤ 2 + entering the number |
| **Time to complete** | < 1 s | < 5 s |
| **Cognitive load** | ~none (recognition, not decision) | one decision (the amount) |
| **One-handed** | Fully, without aiming | Fully; number entry thumb-reachable |
| **Learnability** | Obvious on first sight | Obvious on first sight |
| **Accessibility** | ≥44pt, VoiceOver one element, Dynamic Type, Reduce Motion | + labeled value field, no wheel-only input |
| **Error recovery** | Instant undo / re-tap | Instant undo + easy correct |
| **Apple HIG** | Progressive disclosure, forgiving, ergonomic | same |
| **LOCA philosophy** | Disappears; speaks only on milestones | same |

The bookkeeping path (backdate, edit, delete, note) is scored separately and is
allowed to be richer — but only ever reached deliberately.

---

## 7. What L1 deliberately does **not** decide

Per the constraints, L1 proposes **no** interaction model, bottom sheet, gesture,
inline control, or layout. Those are L2's job. L1 fixes only the problem definition,
the case frequencies, the pain, the principles, and the product decisions above — the
frame inside which L2 must "explore, reject, compare" multiple fundamentally different
models (progressive disclosure, bottom sheet, inline, floating card, one-screen quick
logger, gesture-first, and others), then converge.

**Gate:** proceed to L2 only after this foundation is approved.
