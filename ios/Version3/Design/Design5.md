# LOCA Version 3 · Design Phase
## Design5 — Visual Philosophy & Interface Constitution

> **The single question Design5 answers:** *What should LOCA feel like?*
>
> This is the **visual philosophy and interface constitution** — how a person should *emotionally experience* the interface — decided **before a single screen exists.** It contains **no mockups, no Figma, no SwiftUI, no implementation, no component library, no color palette, no typography selection.** Every conclusion is consistent with the frozen foundation — Phase R (R1–R10, especially R5), Phase S (S1–S7), and Design1–4 — and it extracts *principles* from the named references, never their surfaces.
>
> **What Design5 fixes:** the emotional identity and the evaluation rules for every interface decision, so that Design6+ and every eventual screen can be judged against a philosophy rather than taste.

---

## Part I — The Emotional Identity of the Interface

Before pixels, the feeling. LOCA is an **honest mirror that remembers** (Design2), speaking with **quiet intelligence** (Design4), for the intimate act of **understanding one's own life** (S3). The interface must feel like that relationship. From the candidate feelings:

**LOCA should feel: calm · warm · minimal · personal · reflective · invisible · timeless.**
**LOCA should not feel: clinical, scientific, dense, playful/gamified, or corporate‑professional.**

- **Calm** — the primary register; a companion to a life must lower the temperature, not raise it. *(P10; R3/R5 calm technology; Calm/Headspace's register.)*
- **Warm, not clinical** — personal and human, like a well‑made private notebook, not a medical dashboard. LOCA holds intimate material; coldness would betray the intimacy. *(Design2; the register of Day One, Bear, Craft.)*
- **Minimal** — "as little design as possible" (Rams). The interface earns nothing by adding; it earns by removing. *(R5; Rams; Things.)*
- **Personal, not scientific** — honest about data without *looking* like data; the person's life, not a lab report. Numbers and charts, where they appear, serve the person, never impress them. *(S3; the anti‑QS‑dashboard stance, R9.)*
- **Reflective** — the interface should induce the contemplative state it exists to serve, not the scanning, transacting state of a feed. *(S2 Stratum 2; Reflect/Readwise register.)*
- **Invisible / receding** — the interface should *disappear* so the person and their life are the content. Deference to content over chrome is the deepest principle here (Rams' "unobtrusive," Ive's recessive craft, HIG's deference). **The person's life is the hero; the UI is the frame.**
- **Timeless** — built on principles, not trends, so it still feels right in ten years (Part X). *(Rams "long‑lasting.")*

**The metaphor that governs the whole aesthetic:** *paper and light, not dashboard and neon* — a quiet, well‑made private room for reflection. If a design decision would make LOCA feel like a productivity tool, a science instrument, a game, or a chatbot, it is wrong by identity.

---

## Part II — The Visual Philosophy

Answered as principles, each justified:

- **Emotions the interface should create:** calm, safety, warmth, focus, quiet, clarity, and the sense of a private space that is *mine.* *(Design2 emotional design; S3.)*
- **Emotions it must never create:** anxiety, pressure, overwhelm, clinical coldness, urgency, or the busy‑ness of a feed. *(Design2; R3; P8.)*
- **Visual complexity:** as low as the content allows — complexity is a cost paid only when it genuinely serves understanding. *(Rams; R5 cognitive load.)*
- **Information visible by default:** *little.* One thing at a time; depth on demand (progressive disclosure). The default view is spacious and singular, never a grid of everything. *(R5; Design1 anti‑12‑card.)*
- **Whitespace:** *generous.* Space is not emptiness to be filled — it is the calm the product is made of, and the room reflection needs. Whitespace is a feature, not waste. *(Rams; Things; Calm.)*
- **Motion:** *minimal and purposeful* (Part VII). Stillness is the default; motion is used only to orient or confirm. *(R5.)*
- **Animation:** *subtle, brief, and meaningful* — never decorative, never attention‑grabbing. *(Part VII; P7 no attention manipulation.)*
- **Color:** *restrained and meaningful, never decorative.* Color carries meaning (state, confidence, emphasis) or it doesn't appear; it is never used to excite or to brand loudly. *(Rams "honest"; R5 semantic color; the anti‑Material stance.)*
- **Decoration:** *near‑zero.* "Information before decoration" (Rams). Nothing exists to look impressive; every mark serves understanding or is removed. *(R5.)*

**The visual philosophy in one line:** *remove until only the truthful content and the calm around it remain.*

---

## Part III — The Cognitive Load Framework

People abandon products that make them think too hard (Krug; R5; R9). Every screen must *reduce* cognitive load. Principles by activity:

- **Reading:** short, plain, scannable, human language; one idea per unit; never a wall of prose (the V2 Today's‑Read failure). The person should grasp the point at a glance and choose to go deeper. *(Krug; R5.)*
- **Decision‑making:** minimize decisions; one clear primary choice per moment; sensible defaults; never a buffet of options (Hick's law; decision fatigue). *(R5; R3.)*
- **Navigation:** shallow, conventional, predictable — the person should never wonder where they are or how to return (Jakob's law; Krug). Five areas, legible (Design1). *(R5.)*
- **Reflection:** protect it from load — a calm, uncluttered space with a single seeded prompt, not a form to fill. Cognitive load is the enemy of the contemplative state. *(R2; Design2.)*
- **Learning (the product itself):** teach by doing and just‑in‑time, never by tour or manual; the interface should be self‑evident. *(Krug; R6.)*

**The load law:** the interface's job is to make understanding *one's own life* the only thing the person has to think about — never the interface itself.

---

## Part IV — The Interface Principles (immutable)

Derived from the references and Phase R/S, each with its reason:

1. **Deference — content over chrome.** The person's life is the hero; the UI recedes. *(Rams/Ive/HIG; the emotional identity.)*
2. **One primary action per moment.** A single obvious thing to do; everything else is secondary or absent. *(R5; decision‑load.)*
3. **Progressive disclosure.** Conclusion first; evidence and depth on demand. *(R5; Design3.)*
4. **Calm by default.** Stillness, space, and quiet are the resting state. *(P10; calm tech.)*
5. **Never overwhelm.** One thing at a time; respect attention and working memory. *(R5; Miller's law.)*
6. **Information before decoration.** Every mark serves understanding or is removed. *(Rams.)*
7. **Honesty in the surface.** Confidence, provenance, and uncertainty are shown, not hidden; the interface never looks more certain than the data. *(S6; Design3; Rams "honest.")*
8. **Motion with purpose.** Animation orients or confirms; never entertains. *(R5; Part VII.)*
9. **Empty states teach.** Emptiness instructs and invites; it is never blank or broken. *(R5 strength; Design1.)*
10. **Consistency over novelty.** Familiar, conventional patterns beat clever new ones. *(Jakob's law; Rams "long‑lasting.")*
11. **Clarity over density.** When in doubt, show less, more clearly. *(R5; the anti‑dashboard stance.)*
12. **Forgiveness in the surface.** No guilt cues, no red‑alarm shaming, no streak‑loss drama; the interface is kind. *(P8, P11; Design2.)*

---

## Part V — The Information Density Framework

Density is a decision, not a default. When each register applies, and which *form* fits which content:

- **Minimal (the default):** the daily reflective moment, a single observation, an honest empty state, the home of each area. Most of LOCA is minimal. *(P10; Design1.)*
- **Structured (earned):** the truthful *fact* surfaces — a habit's history, the record — where honest structure aids understanding. Structure serves facts, never inference. *(Design3; R8.)*
- **Expanded (on demand):** evidence, provenance, and depth reached only when the person asks. *(R5 progressive disclosure.)*
- **Compact (collections):** lists of like things (habits, saved reflections) held quietly.

**Which form for which content:**
- **Plain text — the default expression**, especially for reflection and hedged observation. Prose that is short and human beats structure for meaning. *(R2; Design4.)*
- **Lists** — for collections of like items (habits, saved reflections, questions).
- **Timelines** — for the truthful record over time (the person's life as it happened; landmarks). *(Design1 Timeline; Design3 time model.)*
- **Charts** — **only for honest FACT rollups** (habit totals, consistency, sleep over time), and only when a shape aids understanding. **Never chart inferred or hedged data as if precise** — the F1/deflation sin made visual. Charts are for what is measured, not what is inferred. *(R8; S6; Design3.)*
- **Cards** — sparingly, for distinct honest objects (a Review, a saved answer). **Never a grid of many cards** (the V2 12‑card failure). *(Design1; R5 Hick's.)*

**The density law:** minimal by default; structure only where honest facts earn it; and *never* the dashboard grid that flattens a life into tiles.

---

## Part VI — Visual Hierarchy Principles

How attention is guided — without choosing a single font or color:

- **Importance:** exactly one focal point per view; everything else is visibly subordinate. The eye should land on the one thing that matters. *(R5; Refactoring‑UI's emphasize‑by‑de‑emphasizing.)*
- **Typography (as a hierarchy device):** size, weight, and rhythm carry the hierarchy; a small, disciplined type scale; running text set for comfortable reading. Typography does the work of structure so decoration doesn't have to. *(R5; Rams.)*
- **Color (as a meaning device):** color encodes meaning (state, confidence, emphasis) and separates semantic signal from any brand accent; it is never the primary hierarchy device and never decorative. *(R5 semantic color; Rams "honest.")*
- **Motion (as a hierarchy hint):** motion may briefly draw the eye to a change or a new element — sparingly (Part VII).
- **Spacing (the primary structural tool):** grouping and separation are achieved with space before lines, boxes, or color. Space does the quiet work of organization. *(Rams; Things.)*
- **Grouping:** related things sit together; unrelated things are given room; the structure is legible without chrome. *(R5.)*
- **Attention:** the interface asks for attention rarely and returns it quickly; it never competes with the person's life for their focus. *(P10; Design4.)*

**The hierarchy law:** one focal point, hierarchy carried by *space and type* before color or lines, and attention treated as the scarcest, most respected resource.

---

## Part VII — The Motion Philosophy

- **When animation exists:** to *orient* (show where something came from or went), to *confirm* (acknowledge an action), and to *ease transitions* between disclosure layers. *(R5; Norman feedback.)*
- **When it disappears:** everywhere else — and always under Reduced Motion. Stillness is the default state. *(R5; accessibility.)*
- **What moves:** only what carries meaning — a state change, a confirmation, a transition. **What stays static:** everything else; the resting interface is calm and still.
- **Meaningful motion:** brief, subtle, physically plausible, and informative — it tells the person something true about what happened. *(R5; Ive material honesty.)*
- **Distraction:** any motion that entertains, loops, pulses for attention, or celebrates without cause. This is forbidden — it manipulates attention (P7) and breaks calm (P10). *(R3; Design4 no dopamine hits.)*

**The motion law:** motion is a quiet servant of understanding — it orients and confirms, then vanishes. If an animation's purpose is to be noticed, it should not exist.

---

## Part VIII — The Feedback Philosophy

How the interface communicates state — calmly and honestly (this is where the S6/Design3 trust‑surface becomes felt):

- **Success:** quiet and honest — a small, calm acknowledgment, never confetti or celebration engineered for a dopamine hit. *(P7; Design4.)*
- **Failure:** honest and kind — plain, non‑punishing, with a way forward; never alarming, never blaming the person. *(P8; R5 error recovery.)*
- **Progress:** shown as honest, real movement toward what the person chose — never a manufactured gauge or a streak to protect. *(P11; R3.)*
- **Learning (the model improving):** communicated gently when the person corrects LOCA — "updated" — so they see their input matters, without fanfare. *(S6 repair.)*
- **Confidence:** shown honestly and calmly — the person can always sense how sure LOCA is, in a way that informs without alarming. *(S4; S6; Design3.)*
- **Uncertainty:** shown as *softening*, not as an error state — "still learning," "not enough yet" — dignified, never a red flag. Uncertainty visible is trust earned. *(S4; Design3.)*
- **Waiting:** calm and honest — the interface is patient and says so; it never fakes activity or urgency. *(R5; calm tech.)*
- **Completion:** gentle closure — a quiet sense of "done," never a demand to do the next thing. *(P10, P11.)*

**The feedback law:** the interface tells the truth about state — success, failure, confidence, and uncertainty alike — always calmly, never alarmingly, and never manufacturing an emotion the situation doesn't warrant.

---

## Part IX — The Accessibility Philosophy

Accessibility is **fundamental, not a feature** — and designing for it improves the design for everyone (R5; HIG).

- **Cognitive accessibility:** the whole product's low cognitive load *is* cognitive accessibility — plain language, one thing at a time, forgiving flows serve every mind. *(R5; Part III.)*
- **Visual accessibility:** ample contrast, scalable text, no meaning carried by color alone; legible at every size. *(WCAG; R5.)*
- **Motor accessibility:** generous, reachable targets; primary actions within easy reach; nothing requiring precision or haste (Fitts's law). *(R5.)*
- **Screen readers:** everything meaningful is available non‑visually, in a sensible reading order; the interface is fully operable by voice/assistive tech. *(HIG; WCAG.)*
- **Color blindness:** color is never the sole carrier of meaning; state and confidence are conveyed by shape, text, or position as well. *(R5; Part VI.)*
- **Dynamic Type:** the layout honors the person's chosen text size without breaking; type scales, space adapts. *(HIG.)*
- **Reduced Motion:** honored completely — motion is decorative‑enough to remove entirely, and the still version is a first‑class experience. *(R5; Part VII.)*

**The accessibility law:** the accessible design *is* the good design — calm, legible, forgiving, and operable by everyone is the same set of choices that make LOCA excellent for anyone.

---

## Part X — Timeless Design Principles

LOCA must not look dated in ten years (Rams "long‑lasting"; R10 lifelong). How it stays timeless:

- **Principles over trends.** Build on the durable — clarity, hierarchy, space, honesty, restraint — never on the current fashion (a gradient, a style, a motion fad). Trends are precisely what dates. *(Rams.)*
- **Content, not chrome, is the identity.** Because the interface defers to the person's life, its "look" ages slowly — the content is theirs and always current. *(deference.)*
- **Restraint ages well; exuberance dates fast.** The less decoration, the less there is to go out of style. "As little design as possible" is also the most timeless. *(Rams.)*
- **Convention over novelty.** Familiar patterns remain familiar; clever novelties become period pieces. *(Jakob's law.)*
- **Honest materials.** An interface that honestly represents its content (no faux‑texture, no decorative mimicry) doesn't chase eras. *(Rams/Ive material honesty.)*

**The timeless law:** design LOCA the way a good notebook or a Braun object is designed — quiet, honest, restrained, and defined by the content it serves — so it reads as *right* rather than *current*, and stays right for years.

---

## Part XI — The Interface Constitution

The immutable rules every interface decision must pass. A design that fails any is wrong by philosophy, not taste:

1. **Does it recede so the person's life is the content?** (deference) — if it competes with the content, no.
2. **Is it calm?** — if it raises the temperature, no.
3. **Does it show one thing clearly rather than many things densely?** — if it's a dashboard grid, no.
4. **Is every mark serving understanding?** — if it's decoration, remove it.
5. **Is it honest** — confidence, provenance, and uncertainty visible, nothing looking more certain than the data? — if it overstates, no.
6. **Does motion orient or confirm, then vanish?** — if it entertains or pulses for attention, no.
7. **Is it kind** — no guilt, no alarm, no manufactured urgency? — if it pressures, no.
8. **Is it accessible to everyone** by the same choices? — if accessibility is bolted on, redo it.
9. **Will it still feel right in ten years?** — if it's a trend, no.
10. **Whose attention does it serve — the person's understanding, or the product's engagement?** — if the product's, no. *(P7 — the final tie‑breaker.)*

---

## The visual philosophy, in one statement

> **LOCA should feel like a quiet, warm, well‑made private room for reflection — calm, minimal, and personal, built of space and light rather than density and color. The interface recedes so that the person's own life is the only thing in the foreground; it shows one honest thing at a time, tells the truth about how sure it is, moves only to orient and then goes still, never pressures or performs, and is kind by default. It is designed the way a good notebook or a Braun object is designed — with as little as possible, honestly, and for the content it serves — so that it feels not *current* but *right*, and stays right for years. Every screen ever built for LOCA must be judged against this feeling before it is judged against anything else.**

This visual philosophy and interface constitution is the frame every subsequent Design and every eventual screen must honor. Design6 onward may specify *how areas and flows are structured and expressed within this feeling* — but may not introduce a density, a decoration, a motion, or a tone the constitution forbids.

---

*Design5 complete. The visual philosophy, interface philosophy, cognitive‑load framework, motion philosophy, feedback philosophy, accessibility philosophy, visual‑hierarchy principles, information‑density framework, timeless‑design principles, and interface constitution are defined and derived entirely from Phase R, Phase S, and Design1–4. No mockups, Figma, SwiftUI, implementation, component library, color palette, or typography selection were specified. Stop here; do not begin Design6. Design5 is ready for review.*
