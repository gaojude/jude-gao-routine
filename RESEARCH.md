# The science behind Jude Gao Routine

Why the app behaves the way it does. Each design choice is tied to evidence, with
the strength of that evidence flagged honestly. Several popular "rules" in this
space are weak or non-peer-reviewed — those are labelled as such rather than
dressed up as science.

## The core tension

You get "locked in" and ignore gentle nudges, so the obvious answer is *force*.
But two well-established findings say pure force backfires:

- **Mid-task interruption is expensive.** Stopping someone mid-task leaves
  "attention residue" that degrades the *next* task — and the residue follows you
  into the break, so you detach less and recover less. Leroy (2009),
  *Org. Behavior and Human Decision Processes* 109(2):168–181.
  <https://www.sciencedirect.com/science/article/abs/pii/S0749597809000399>
  Interrupting *between* subtasks costs far less than mid-subtask (more errors,
  longer resumption, higher annoyance) — Adamczyk & Bailey (2004); Iqbal &
  Bailey. <https://www.interruptions.net/literature/Iqbal-TOCHI10.pdf>
- **Coercion triggers reactance.** Removing autonomy provokes a push to restore
  it — including ignoring or disabling the app (the "boomerang effect"). Brehm,
  Psychological Reactance Theory (1966).
  <https://en.wikipedia.org/wiki/Reactance_(psychology)>

**Design answer:** firm *structure* with a small escape valve, and a warning
*before* the interruption so you can reach a stopping point.

## What the app does, and why

| Feature | Why | Evidence (confidence) |
|---------|-----|-----------------------|
| **1-min pre-break warning** | Lets you hit a natural boundary instead of being yanked mid-task | Leroy 2009; Iqbal & Bailey (high) |
| **Full-screen break overlay** | Structured breaks beat self-regulated ones for a lock-in-prone person; gentle pings get ignored | Biwer et al. 2023, *Br. J. Educational Psych.* — systematic breaks → higher concentration/motivation, lower fatigue (med-high) |
| **20s skip friction + limited Postpone** | Firm but keeps autonomy, so it doesn't boomerang | Brehm 1966 (high, foundational) |
| **Rotating "move / look away / step outside" prompts** | Detachment + movement are the active ingredients of recovery | Sonnentag & Fritz 2007 (detachment most consistent recovery driver); Diaz et al. 2017, *Annals of Internal Medicine* — uninterrupted sitting ≥30 min linked to higher mortality (high) |
| **Editable "break plan" on the screen** | A specific "when the timer ends, I'll ___" plan strongly raises follow-through | Gollwitzer & Sheeran 2006 meta-analysis, **d = 0.65**, 94 tests, >8,000 people (high) |
| **20-20-20 eye reminders (opt-in)** | Cheap habit for digital eye strain | AAO/AOA endorse it; benefit is real but *temporary* and only while reminders continue — Talens-Estarelles 2023 (med-high). Origin is a mnemonic, not a trial. |
| **Default 45/10, presets up to 90 min** | No single validated ratio; 45/10 sits in the supported range | Pomodoro cites 20–45 min windows; ultradian/BRAC ~90 min is a sensible ceiling (medium) |

## Honest caveats (claims this app deliberately does NOT make)

- **Microbreaks make you "more productive."** A 2022 meta-analysis (Albulescu
  et al., *PLOS ONE*, 22 samples, N=2,335) found microbreaks reliably improve
  **vigor (d≈0.36)** and **fatigue (d≈0.35)** but **not** overall performance
  (d=0.16, *n.s.*). So this app sells **well-being and energy**, not output.
  Heavy cognitive work likely needs longer than a 10-min break to restore
  performance (meta-regression b=.07, p=.006).
  <https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0272460>
- **"52/17 is the scientifically optimal ratio."** That figure is DeskTime
  vendor telemetry (observational, productivity-proxy, and it drifted to 112/26
  and 75/33 later). Offered as a preset, not as law.
- **"It takes 23 min 15 sec to refocus."** No traceable peer-reviewed source;
  appears only in interviews. Interruptions are costly — but not via that number.
- **90-min ultradian rhythm governs waking focus.** Solid for sleep (Kleitman),
  contested for waking cognition. Used only as an upper bound.

## Top principles (ranked)

1. Warn before interrupting; aim breaks at natural boundaries, never mid-keystroke.
2. Preserve autonomy — always allow snooze/skip — to avoid reactance.
3. Provide structure (a scheduled cadence), not just reminders.
4. Sell well-being, not productivity; make breaks restorative (detach + move).
5. Engineer follow-through with implementation intentions (the break plan).
6. Break up sitting roughly every 30 min; make "stand and move" the default action.
7. Be honest about weak evidence in-product — overclaiming invites distrust and reactance.
