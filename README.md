# Jude Gao Routine

A tiny macOS **menu-bar app** for working in healthy cycles. Work 45 min, then a
**hard-to-ignore full-screen break screen** makes you actually stop for 10 min —
firm, but with a small escape valve so it doesn't backfire. Includes a **daily
checklist** (e.g. "ensure room lighting") that resets each day.

Every behavior is grounded in break/recovery research — see
[RESEARCH.md](RESEARCH.md) for the evidence and honest caveats.

No Xcode, no App Store, no dependencies — just the Swift compiler that ships with
the Command Line Tools.

## Install

```bash
cd ~/workspace/JudeGaoRoutine
./build.sh
```

This compiles, installs `Jude Gao Routine.app` to `/Applications`, ad-hoc signs
it, enables start-at-login, and launches it. You'll see `💻 45:00` in the menu bar.

Build without auto-start / auto-launch:

```bash
./build.sh --no-login
open "/Applications/Jude Gao Routine.app"
```

## How it works

1. **💻 45:00** counts down work time.
2. **1 minute before** the break, a gentle warning fires so you can reach a
   stopping point instead of being yanked mid-task.
3. At zero, a **full-screen break screen** covers every display (and floats over
   full-screen apps) with a big countdown, a rotating restorative prompt, and
   your personal break plan. **Skip** is locked for the first 20 seconds; you can
   **Postpone 5 min** up to twice if you're truly mid-thought.
4. **☕ 10:00** counts down; at zero the screen clears, "Break's over 💻", loops.

Notifications use `osascript` banners + a system sound — reliable for an unsigned
app. (Banners are attributed to "Script Editor"; expected for an ad-hoc build.)

If the full-screen screen is too much, turn off **Strict break screen** in
*Break behavior* and it falls back to a plain notification.

## Menu

| Item | What it does |
|------|--------------|
| Status line | Current phase + time remaining |
| Pause / Resume | Freeze or resume the countdown |
| Start break now / End break now | Skip to the other phase |
| Reset timer | Restart a fresh 45-min work block |
| Daily checklist — n/total | Check items off; resets each day |
| Break behavior | Strict screen, pre-break warning, 20-20-20, edit break plan |
| Durations | Pick work (25/45/50/60) and break (5/10/15) minutes |
| Start at login | Toggle the LaunchAgent |
| Quit | Exit |

## Break behavior

| Setting | Default | What it does |
|---------|---------|--------------|
| Strict break screen | On | Full-screen blocking break vs a plain notification |
| Warn 1 min before break | On | Heads-up so you hit a natural stopping point |
| 20-20-20 eye reminders | Off | Every 20 min, "look ~20 ft away for 20 s" |
| Edit break plan… | — | Your "when the timer ends, I'll ___" plan, shown on the break screen |

## Daily checklist

Default items: ensure room lighting, adjust monitor to eye level, fill water
bottle, clear desk clutter, set posture. Completion resets at each new day, and
you get one nudge per day if nothing is checked.

Edit the items via the menu ("Edit items…") or directly:

```
~/Library/Application Support/JudeGaoRoutine/checklist.json
```

It's a plain JSON array of strings. Changes apply the next time you open the menu.

## Uninstall

```bash
launchctl unload -w ~/Library/LaunchAgents/com.judegao.routine.plist
rm -f ~/Library/LaunchAgents/com.judegao.routine.plist
rm -rf "/Applications/Jude Gao Routine.app"
rm -rf ~/Library/Application\ Support/JudeGaoRoutine
```

## Customizing intervals

Defaults are 45 / 10 minutes (use the **Durations** menu for presets, or):

```bash
defaults write com.judegao.routine workMinutes -int 50
defaults write com.judegao.routine breakMinutes -int 10
```

Then pick "Reset timer" from the menu.
