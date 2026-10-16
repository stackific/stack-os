# 03: Lock screen

**Context.** The M1 power menu needs Lock: the screen locks and unlocks with the user's password. Later: idle lock, lock before suspend, maybe fingerprint. The shell is Quickshell 0.3.x built from source, on Mango. PAM config must suit bootc: fixed at build time, nothing generated into `/etc` at runtime.

**Prior art.** References are copies without git metadata, so citations are unpinned.

- Every current shell in `references/` draws its own lock on ext-session-lock-v1 and calls PAM itself; none spawns an external locker.
  - Omarchy dropped hyprlock and hypridle (`omarchy-quattro/bin/omarchy-upgrade-to-quattro:888-889`) for Quickshell's `WlSessionLock` with separate password and fingerprint `PamContext`s (`omarchy-quattro/shell/plugins/lock/Service.qml:502-644`), using its own PAM files of `pam_faillock` plus `pam_unix` (`omarchy-quattro/bin/omarchy-apply-lock:31-41`). Its lock plugin stays loaded so a QML reload cannot orphan the lock (`omarchy-quattro/shell/plugins/README.md:84-93`).
  - DankMaterialShell re-locks on start when logind's LockedHint is set (`DankMaterialShell/quickshell/Modules/Lock/Lock.qml:79-91`), runs as a user unit with `Restart=on-failure` (`DankMaterialShell/assets/systemd/dms.service:1-22`), and builds a PAM service without fingerprint lines (`DankMaterialShell/core/internal/pam/pam.go:291-301,457-483`).
  - Noctalia (native C++) runs PAM in a helper process and holds a logind sleep delay inhibitor that it releases only once the lock is up (`noctalia/src/dbus/logind/logind_service.cpp:70-126,197-238`). The proof of concept uses Noctalia's lock and idle.
  - Quickshell already runs PAM in a forked subprocess (`quickshell/src/services/pam/subprocess.cpp:40-49`), lets `PamContext` read its config from any directory (`quickshell/src/services/pam/qml.hpp:32-45`), and has no logind binding. 0.3.1 and 0.3.2 fix session-lock crashes on sleep, wake, DPMS, unlock, reentrant locks and hotplug (`quickshell/changelog/v0.3.1.md:4,7`, `quickshell/changelog/v0.3.2.md:8-12`).
- Mango implements ext-session-lock-v1, ext-idle-notify-v1 and idle-inhibit. If the lock client dies, the session stays locked behind an opaque fill and a new lock client is accepted (`mango/src/manage/misc.c:458-532`); `bindl` bindings still fire while locked (`mango/src/input/keyboard.c:757-761`). The fill is opaque only while `allow_lock_transparent=0`, the default. Lock surfaces follow monitor hotplug (`mango/src/manage/monitor.c:1074-1077,1134-1139`).
- Fedora's `with-fingerprint` authselect feature puts `pam_fprintd` before `pam_unix`, so a lock using the `login` service waits on the fingerprint reader before taking a password (`noctalia-greeter/docs/user/troubleshooting.md:168-193`).
- Alternatives in Fedora 44: swaylock 1.8.6 with swayidle 1.9.0 (Mango upstream's suggestion, `mango/README.md:63`), gtklock 4.0.0. hyprlock and hypridle stopped at Fedora 41; waylock is not packaged.

| Option | Trend online | Trend in references | Compat | Custom | Perf | Engine |
|---|---|---|---|---|---|---|
| **Shell's own lock (Quickshell)** | H | H | H | H | H | H |
| swaylock + swayidle | M | M | H | L | H | H |
| gtklock + swayidle | M | L | H | M | M | H |
| hyprlock + hypridle | M | L | L | H | M | L |
| waylock | L | L | L | L | H | H |

**Decision.**

- The lock is part of the Stack OS shell: Quickshell `WlSessionLock` with a `PamContext`, exposed as an IPC call that the power menu and a Mango binding both use.
- The PAM file is Stack OS's own, password only (`pam_unix`), shipped under `/usr/share/stack-os/pam/` and passed through `PamContext.configDirectory`. It does not include `login` or `system-auth`, so no fingerprint wait and no `/etc` drift.
- The lock component is never unloaded or reloaded; the shipped shell runs without live QML reload.
- `allow_lock_transparent` stays 0 in the image's Mango config.
- The shell runs as a systemd user unit with `Restart=on-failure` and re-locks on start when LockedHint is set; a `bindl` key restarts it as recovery.

**Consequences.**

- One process draws the bar and the lock, in one look, with no extra package.
- A shell crash shows Mango's grey lock fill until the unit restarts and re-locks; nothing is exposed.
- No failed-attempt lockout until `pam_faillock` is added; no credential refresh (Kerberos, keyring) on unlock, since `PamContext` is auth only.
- Idle lock, lock before suspend (a user unit holding a logind delay inhibitor, `InhibitDelayMaxSec` raised by a drop-in under `/usr/lib/systemd/logind.conf.d/`), `loginctl lock-session` and fingerprint are Follow-ups.
- How the custom PAM file behaves under Fedora 44's authselect defaults is tested on the image in the lock step.
