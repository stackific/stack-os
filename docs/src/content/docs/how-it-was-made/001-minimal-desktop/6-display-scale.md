---
title: 6-Display scale
description: Each monitor starts at the scale its physical size calls for, computed from its EDID before Mango starts and again on hotplug.
sidebar:
  order: 6
---

[001-06: display scale from physical DPI](https://github.com/stackific/stack-os/commit/0e80201d8e626bf126fc3072e8b3f6dc778625e1)

## Goal

Every monitor should start at a sensible scale without the user configuring anything: a 13-inch laptop panel at 2, a 27-inch 4K screen at 1.5, an ordinary 24-inch 1080p screen and a virtual machine at 1. This serves the milestone's "each monitor starts at the scale its physical DPI calls for" item.

## Context

Step 001-05 made the image boot to a login that starts Mango with the Stack OS shell. Mango has no automatic scaling; it applies `monitor_rule` lines from its config. Earlier decisions this step implements:

- **A script computes one `monitor_rule` per connected monitor** into a file only it writes, which the Stack OS Mango config loads if present. Rules match by connector name (`eDP-1`, `DP-2`).
- **It runs before Mango starts**, from the session's launch command, and **again on hotplug**, from a user-session watcher on Mango's monitor events. No udev rule: udev runs as root outside the session.
- **Inputs come from sysfs**, readable without root: the physical size from EDID bytes 21–22 (centimetres) and the preferred mode from the first line of the connector's `modes`.
- **The formula**: scale 1 when the size is missing or is only an aspect ratio stored as a size (as projectors and most virtual machines report); otherwise DPI is the diagonal in pixels over the diagonal in inches, against a target of 135 DPI for built-in panels and screens under 20 inches and 110 otherwise. The scale is the quarter step from 1 to 3 nearest to DPI ÷ target that divides the mode exactly; anything below 1.2 becomes 1.
- **The user can override a monitor** through a Stack OS setting the script reads.

## Expectations

Must:

- `src/scale/stack-os-scale` writes `monitor_rule=name:^<connector>$,scale:<n>` lines for connected monitors to `~/.local/state/stack-os/monitors.conf`, and rewrites the file only when its content changes.
- `task scale:test` passes on EDID samples: a 13-inch 2560×1600 laptop panel (2), a 27-inch 3840×2160 screen (1.5), a 24-inch 1920×1080 screen (1), and a size of 0 mm (1).
- A line `<connector> <scale>` in `~/.config/stack-os/scale.conf` overrides that monitor.
- The session launches through a wrapper that runs the script, then starts Mango; the Mango config loads the file with `source_optional=`.
- A user service watches `mmsg watch all-monitors` and reruns the script on hotplug, bound to Mango's session target.
- The image installs the script, the watcher and the wrapper, and `task image:check` asserts them.

Must not:

- need root or udev;
- read the EDID's detailed timings for the mode;
- write rules for disconnected connectors.

## Prompt

```text title="Prompt" wrap
Implement 001-06: display scale from physical DPI.

Add src/scale/ with its own Taskfile (install, test; included from the root as `scale`). `stack-os-scale` (bash) reads every connected connector under /sys/class/drm (overridable for tests): the physical size from EDID bytes 21-22 (cm) with od, the preferred mode from the first line of `modes`; computes the scale in awk (scale 1 for a 0 size or an aspect ratio stored as a size; DPI against 135 for eDP/LVDS/DSI and screens under 20 inches, 110 otherwise; the nearest quarter step from 1 to 3 that divides the mode exactly; below 1.2 becomes 1), applies overrides from ~/.config/stack-os/scale.conf (`<connector> <scale>`), and writes `monitor_rule=name:^<connector>$,scale:<n>` lines to ~/.local/state/stack-os/monitors.conf, only when the content changes. `task scale:test` builds fake sysfs trees for a 13-inch 2560x1600 laptop (2), a 27-inch 4K screen (1.5), a 24-inch 1080p screen (1) and a 0 mm size (1), plus an override, and compares the output.

Add an image feature `scale`: the script and a watcher (`mmsg watch all-monitors`, rerunning the script) under /usr/libexec/stack-os/, and the watcher as a user service bound to mango-session.target. The session file now runs /usr/libexec/stack-os/session, which runs the script and then execs Mango; the Mango config loads the generated file with source_optional. Checks assert it in the image. Document every file inline.
```

## Outcome

`stack-os-scale` (in `src/scale/`) reads each connected monitor's physical size from its EDID and its preferred mode from sysfs, picks a scale with decision 04's formula, and writes one `monitor_rule` per monitor to `~/.local/state/stack-os/monitors.conf`. It rewrites the file only when the rules change, so Mango's reload of that file never loops back. A line such as `eDP-1 1.25` in `~/.config/stack-os/scale.conf` overrides a monitor; only a number from 0.5 to 4 is accepted, and the last line for a connector wins.

In the image, the session file now starts `/usr/libexec/stack-os/session`, which runs the script and then becomes Mango; the Stack OS Mango config loads the generated file, so monitors present at login come up at their scale from Mango's first frame. The user service `stack-os-scale-watch` runs the script once when it starts, then again whenever the set of monitors Mango reports changes (Mango's monitor stream also fires on every focus or tag change, so it compares monitor names first); it is bound to Mango's session target like the shell, and restarts if the stream ends.

## Manual changes

None.

## Result

```
$ task scale:test
ok: scale from physical size; disconnected skipped
ok: unchanged rules leave the file alone
ok: override wins
ok: last override wins; invalid ones are ignored

$ task image:build
Checks passed: 14                     # bootc container lint --fatal-warnings
$ task image:check                    # includes the installed script on a fake 27" 4K
(exit 0)                              # monitor, and Mango parsing its rule with no errors
```

The samples: a 13-inch 2560×1600 laptop panel gets 2, a 27-inch 3840×2160 screen 1.5, a 24-inch 1920×1080 screen 1, and a monitor reporting no size (as most virtual machines do) 1. `task lint` passes.

Review: 10 fixed, 1 deferred (see Follow-ups); decision 04's text and the missing screenshot are left as recorded under Deviations. The review caught that Mango's keyword is `monitor_rule`, not `monitorrule` as decision 04 writes it: the image's Mango rejects `monitorrule` as an unknown keyword, and `mango -p` exits 0 even then, so the config checks now require empty output.

## Deviations

- Rules use Mango's actual keyword, `monitor_rule`; decision 04 writes `monitorrule`.
- No screenshot: scaling shows only on a real or virtual display; the virtual machine step (001-07) checks that it boots at scale 1.
- Rules are written for every connected monitor; the decision's "no rule for a connector the user's own Mango config already matches" does not apply, because the Stack OS session starts Mango with its own config and never reads the user's.

## Follow-ups

- Check on real hardware that a hotplugged monitor gets its scale, and how long it shows at 1 first.
- Scale screens taller than 500 mm (TVs) to 2 at 4K, as decided.
- Test the watcher's event filtering with fake `mmsg` output.
- The pre-commit shellcheck and shfmt only see `*.sh` files; extend them to the extension-less scripts (`stack-os-scale`, `scale-watch`, `session`).
- Offer the formula to Mango upstream as built-in auto-scaling.
