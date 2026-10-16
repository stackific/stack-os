# M1 open questions

Each question has a recommendation. Answer by accepting, changing or rejecting it; the answer goes into the decision or step it names and is noted here as **Answered**.

## Decisions to approve

1. **Approve decisions 01–05?** 01 and 04 are accepted; 02, 03 and 05 are proposed.
   Recommendation: approve as drafted, with the answers below folded in.
   **Answered:** approved; 02, 03 and 05 accepted.

2. **Quickshell or Noctalia v5 for the shell (05)?** The proof of concept already runs Mango with Noctalia v5, packaged in Fedora 44, native, lighter on memory. Quickshell gives full control and is the toolkit most shells use, but we must build and pin it ourselves.
   Recommendation: Quickshell. The shell is Stack OS's own product; Noctalia stays the fallback if the Quickshell build or memory budget fails in M1.
    **Answered:** Quickshell only; no Noctalia, not even as a fallback (05).

## Display scale (04)

3. **One reference DPI (110) for every screen, or 135 for laptop panels?** Every reference (Mutter, niri, Plymouth, KWin, cosmic-comp) aims higher for built-in panels; with 110 a 13" 2560×1600 laptop gets 2 instead of 1.75, a 15.6" 1080p gets 1.25 instead of 1.
   Recommendation: 135 for built-in panels (`eDP`, `LVDS`, `DSI` connectors) and screens under 20", 110 otherwise. It is still one formula, and laptops come out where users expect.
    **Answered:** accepted: 135 for built-in panels and screens under 20", 110 otherwise (04).

4. **Scale TVs up?** A 55" 4K TV is about 80 DPI and comes out at 1.
   Recommendation: no in M1; a Follow-up for screens taller than 500 mm (2 for 4K).
    **Answered:** accepted (04).

5. **Feed the computed scale to the login screen?** Plymouth and the login screen may show a different size from the session.
   Recommendation: not in M1 (tuigreet is text). When the shell's own login screen lands, it runs the same script.
    **Answered:** accepted (04).

## Login and lock (02, 03)

6. **tuigreet or agreety for M1?**
   Recommendation: tuigreet. Session list, remembered user and asterisks for about 1 MB; agreety needs the session hard-coded.
   **Answered:** tuigreet for M1 (02).

7. **Lock PAM file under `/usr` or in `/etc/pam.d/stack-lock`?**
   Recommendation: `/usr/share/stack-os/pam/`, passed through Quickshell's `PamContext.configDirectory`. Fixed by the image, no `/etc` drift, no fingerprint wait from Fedora's `login` stack.
   **Answered:** accepted (03).

8. **Autologin on encrypted installs, as Omarchy does?**
   Recommendation: no in M1. Revisit with the installer's encryption option.
   **Answered:** accepted.

9. **Add `pam_faillock` to the lock now?**
   Recommendation: no; password only in M1, faillock as a Follow-up.
   **Answered:** accepted; faillock is a Follow-up (03).

## Image and install (01)

10. **Fedora 44 or 45?** Fedora 45 is due on 20 October 2026 (fallback 27 October) with Plasma 6.7, GNOME 51 and labwc 0.20.
    Recommendation: build M1 on 44, which the proof of concept proves; move to 45 in its own step after M1, once its bootc base and the Terra repo for 45 are out.
    **Answered:** Fedora 44, with every package and dependency pinned (01).

11. **Where do installed systems look for updates?** Nothing is published, so `bootc upgrade` has no source.
    Recommendation: install with the origin set to the future registry ref (`ghcr.io/stackific/stack-os:latest`), so no migration is needed when publishing starts; upgrades fail until then, which is accepted for M1. Local `containers-storage` switching stays a dev-only trick.
    **Answered:** accepted (01).

12. **Btrfs subvolumes and compression?** The image sets Btrfs as the default; subvolumes and `zstd:1` compression can ship as `/usr/lib/repart.d/` but only apply to `bootc install`, not the ISO's installer.
    Recommendation: in M1, accept whatever layout the ISO installer creates and record it in the ISO step; add `/` and `/home` subvolumes with `zstd:1` once we know which install paths we support.
    **Answered:** accepted (01).

13. **What if the interactive ISO installer ignores the Btrfs default?** Unverified anywhere.
    Recommendation: test in step 8; if ignored, add the storage choice to the ISO's kickstart and keep the rest interactive.
    **Answered:** accepted (01).

14. **Install all packages in one earlier cached build step?** It would make config-only rebuilds take seconds; no reference does it.
    Recommendation: not in M1. Measure build times in step 4 and decide then.
    **Answered:** accepted (01).

## Shell (05)

15. **How is the shell started: systemd user unit or Mango `exec_once`?** A user unit restarts it on failure and logs to the journal, but needs Mango to reach `graphical-session.target`, which is unverified.
    Recommendation: a user unit with `Restart=on-failure`, started from Mango's `exec_once` with `systemctl --user start`; verify the target in step 1, fall back to `exec_once` plus a restart loop.
   **Answered:** accepted; the unit is `stack-os-shell.service` (05).

16. **`qs ipc` or our own socket for `stack shell` calls?** Omarchy measured about 45 ms per `qs ipc` call against 5 ms on its own socket.
    Recommendation: `qs ipc` in M1; a socket only if a keybinding feels slow.
   **Answered:** accepted (05).

17. **Prebuild the QML cache in the image?** Otherwise the first launch after every update takes 1.7–3.0 s longer.
    Recommendation: measure first launch in step 4; prebuild only if it is noticeable.
   **Answered:** accepted; measured in step 4.

18. **Turn off transparent huge pages for the shell process?** Measured at about half the memory with them off, but only when the system default is `always`; Fedora's default is `madvise`.
    Recommendation: check the default on our image in step 2; act only if it is `always`.
   **Answered:** accepted; checked in step 2.

## Process and docs

19. **Docs numbering clash:** `1-Bootstrap` and `2-Placeholder` now sit in M1 next to step pages numbered from 1.
    Recommendation: make bootstrap and placeholder steps 1 and 2 of M1 and renumber the plan's steps 3–11.
   **Answered:** the two pages were placeholders and are removed; M1's steps start at 1, so every page number equals its step number (dev environment is M1-1).

20. **What happens to `meta/prior-unvetted-research.md`?** It is the operator's draft Stack Shell spec, untracked and unvetted.
    Recommendation: keep it untracked as input; take what survives review into decisions, then delete it.
   **Answered:** ignored; not an input to M1.
