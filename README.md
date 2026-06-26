# Jude Gao Routine

A tiny macOS **menu-bar app**. Work 45 min, then it nudges you to take a 10-min
break. Includes a **daily checklist** (e.g. "ensure room lighting") that resets
each day.

No Xcode, no App Store, no dependencies — just the Swift compiler that ships with
the Command Line Tools.

## Install

```bash
cd ~/workspace/JudeGaoRoutine
./build.sh
```

This compiles, installs `Jude Gao Routine.app` to `~/Applications`, ad-hoc signs
it, enables start-at-login, and launches it. You'll see `💻 45:00` in the menu bar.

Build without auto-start / auto-launch:

```bash
./build.sh --no-login
open "$HOME/Applications/Jude Gao Routine.app"
```

## How it works

- **💻 45:00** counts down work time. At zero you get a notification + sound
  ("Time for a break ☕").
- **☕ 10:00** counts down the break. At zero: "Break's over 💻" and it loops.
- Notifications use `osascript` banners + a system sound — reliable for an
  unsigned app. (Banners are attributed to "Script Editor"; that's expected for
  an ad-hoc-built app.)

## Menu

| Item | What it does |
|------|--------------|
| Status line | Current phase + time remaining |
| Pause / Resume | Freeze or resume the countdown |
| Start break now / End break now | Skip to the other phase |
| Reset timer | Restart a fresh 45-min work block |
| Daily checklist — n/total | Check items off; resets each day |
| Durations | Pick work (25/45/50/60) and break (5/10/15) minutes |
| Start at login | Toggle the LaunchAgent |
| Quit | Exit |

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
rm -rf "$HOME/Applications/Jude Gao Routine.app"
rm -rf ~/Library/Application\ Support/JudeGaoRoutine
```

## Customizing intervals

Defaults are 45 / 10 minutes (use the **Durations** menu for presets, or):

```bash
defaults write com.judegao.routine workMinutes -int 50
defaults write com.judegao.routine breakMinutes -int 10
```

Then pick "Reset timer" from the menu.
