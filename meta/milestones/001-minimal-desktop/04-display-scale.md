# 04: Default display scale from physical DPI

**Context.** Mango starts every monitor at scale 1 unless a `monitorrule` matches it, so a 4K laptop panel or a 27" 4K monitor comes up with tiny text. Stack OS should start each monitor at the scale its physical DPI calls for and let the user change it afterwards. Viewing distance is not measured; like every reference, Stack OS approximates it with two screen classes. The distro ships Mango as packaged; patching and building our own Mango is out.

**Prior art.** References are copies without git metadata, so citations are unpinned.

- Mutter, and niri, which ports it (`niri/src/utils/scale.rs:8-58`): DPI along the diagonal divided by a target DPI (135 under 20", 110 from 20" up), nearest of the scales 1 to 4 in quarter steps, 1 when the size is 0 mm. Runs inside the compositor when an output appears; the configured scale wins (`niri/src/niri.rs:1960-1969`).
- KWin: separate targets for built-in panels (125 or 150) and external monitors (96), TV class for outputs taller than 500 mm, rounding to 0.05, 1 below 1.2.
- Hyprland `auto`, which Omarchy ships (`omarchy-quattro/config/hypr/monitors.lua`): three PPI bands (above 200 gives 2, above 140 gives 1.5, otherwise 1), then a clean-division search. Omarchy adds hotkeys that cycle 1, 1.25, 1.6, 2, 3, 4 snapped to clean values (`omarchy-quattro/bin/omarchy-hyprland-monitor-scaling`).
- Mango has no automatic scale. A new output takes the first matching `monitorrule` (`mango/src/manage/monitor.c:675-713`); on reload the last match wins (`mango/src/config/reapply.c:213-233`). Every file loaded with `source` or `source_optional`, even one that does not exist yet, is watched and reloads the config when it changes (`mango/src/config/load.c:186-202`, `mango/src/config/watcher.c:426-440`).
- DankMaterialShell and Noctalia never pick a scale; DankMaterialShell writes `monitorrule` lines from its settings UI.

Stack OS follows Mutter's continuous formula and its two targets rather than Hyprland's three bands, which leave a 32" 4K at 1.

**Decision.**

- A bash script computes one `monitorrule` per connected monitor and writes it to a generated file that only the script writes; the Stack OS Mango config loads it with `source_optional=`. Rules match by connector name (`eDP-1`, `DP-2`); make and model would need the PNP vendor table that wlroots decodes.
- It runs before Mango starts, from the session launch command (and from the greeter's, once the greeter runs in Mango), and again on hotplug from a user-session watcher on `mmsg watch all-monitors`, which emits when an output is added or removed (`mango/src/manage/monitor.c:857,970`). Omarchy watches Hyprland's event socket the same way (`omarchy-quattro/bin/omarchy-hyprland-monitor-watch:96-115`). No udev rule: udev jobs run as root outside the session. Mango picks up the rewritten file by itself.
- Inputs come from sysfs, readable without root:
  - physical size: EDID base-block bytes 21–22 (cm × 10) from `/sys/class/drm/card*-*/edid`, read with `od`. This is the value the kernel and Mango use (`linux-aurora/drivers/gpu/drm/drm_edid.c:6762-6763`), accurate to 1 cm;
  - mode: the first line of `/sys/class/drm/card*-*/modes`, the kernel's preferred mode and the one Mango picks with no rule (`linux-aurora/drivers/gpu/drm/drm_modes.c:1841-1849`, `mango/src/manage/monitor.c:698-702`). The EDID's detailed timing is not used: it stops at 4095 px and misses kernel quirks.
  - Math in `awk`.
- Formula:
  1. Scale 1 when either size byte is 0 (undefined size or aspect ratio only, as on projectors and most VMs) or the size is an aspect ratio stored as a size (1600×900, 1600×1000, 160×90, 160×100, 16×9, 16×10 mm), as Mutter and Plymouth do (`plymouth/src/libply/ply-utils.c:1074-1083`).
  2. DPI = diagonal pixels ÷ diagonal inches. Target DPI: 135 for built-in panels (`eDP`, `LVDS` or `DSI` in the connector name) and any screen under 20" diagonal; 110 otherwise. Ideal scale = DPI ÷ target.
  3. Candidates: 1 to 3 in quarter steps that divide the mode width and height exactly. Pick the nearest to the ideal; below 1.2 becomes 1.
- The user overrides a monitor through a Stack OS setting that the script reads; the script then writes the user's value instead of its own. Hand-written `monitorrule` lines for the same connector are not supported, because Mango applies the first matching rule to a new output and the last on reload (`mango/src/manage/monitor.c:684-695`, `mango/src/config/reapply.c:213-233`); the script writes no rule for a connector the user's own config already matches.
- The same formula is offered to Mango upstream as built-in auto-scaling. If it lands, the script goes.

| Display | DPI | Target | Scale |
|---|---|---|---|
| 13" 2560×1600 laptop | 227 | 135 | 2 |
| 14" 2880×1800 laptop | 243 | 135 | 2 |
| 16" 3840×2400 laptop | 283 | 135 | 2 |
| 15.6" 1920×1080 laptop | 141 | 135 | 1 |
| 24" 1920×1080 | 92 | 110 | 1 |
| 27" 2560×1440 | 109 | 110 | 1 |
| 27" 3840×2160 | 163 | 110 | 1.5 |
| 32" 3840×2160 | 138 | 110 | 1.25 |

**Consequences.**

- Monitors present at login come up at the right scale from Mango's first frame; nothing is stored, so it suits bootc.
- A hotplugged monitor shows at scale 1 for a moment, until the watcher, the script and Mango's reload finish.
- Exact division rules out most fractional steps on laptop panels (1.75 never divides 2560×1600), so laptops often land on 2 where Mutter, which allows near-exact scales, gives 1.75; the user lowers it once.
- TVs come out at 1 (a 55" 4K is about 80 DPI); KWin and cosmic-comp scale TVs up. Scaling screens taller than 500 mm to 2 at 4K is a Follow-up.
- The boot splash (Plymouth, Mutter's targets) and any greeter that guesses its own scale can show a different size from the session. The M1 login screen is text; the shell's own login screen will run the same script.
- Monitors that report a wrong but plausible size get a wrong scale; the override fixes it.
- Overrides cannot be plain `monitorrule` lines until Mango matches rules consistently.
