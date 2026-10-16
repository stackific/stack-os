---
title: 5-Login manager
description: The image boots to a text login (greetd with tuigreet) that starts Mango with the Stack OS shell running as a user service.
sidebar:
  order: 5
---

001-05: login manager into Mango with the shell as a service

## Goal

Make the image a usable session: it boots to a login screen, and logging in starts Mango with the Stack OS shell. The shell runs as a systemd user service, so it restarts if it crashes and logs to the journal. This serves the milestone's "logging in starts Mango with a Quickshell bar showing two icons" item; that item is checked when the image boots in a virtual machine (001-07).

## Context

Step 001-04 built the image with Mango, foot, the Quickshell RPM and the shell's files under `/usr/share/stack-os/`, but nothing started them. Earlier decisions this step implements:

- **greetd is the login engine, with tuigreet as its greeter**: a text-mode login with no compositor, listing sessions and remembering the last user. greetd's own PAM file from Fedora stays unchanged; its greeter user comes from the package.
- **The shell runs as the systemd user unit `stack-os-shell.service`**, restarting on failure and logging to the journal, with live reload off (only development reloads QML on save).
- **Apps started from the shell get their own systemd scope**, so a shell restart does not close them (a follow-up from 001-02).
- **Static defaults live under `/usr`**; `/etc` only where a program reads nowhere else.

## Expectations

Must:

- The image enables `greetd.service`, boots to `graphical.target`, and ships `/etc/greetd/config.toml` with tuigreet as the greeter (`--remember --asterisks`), offering only the Stack OS session.
- The greeter user `greetd` exists (from the package's sysusers entry, no `useradd`).
- The Stack OS session starts Mango with an image-owned config under `/usr/share/stack-os/mango/`, which keeps Mango's stock bindings and adds Super+L for the lock.
- `stack-os-shell.service` (a user unit under `/usr/lib/systemd/user/`) runs `qs -p /usr/share/stack-os/shell` with the file watcher off and `Restart=on-failure`, starts with Mango's session target, after Mango has exported its environment, and is enabled for every user.
- Outside the dev session, the terminal button opens foot in its own systemd scope.
- `task image:check` asserts all of the above inside the built image.

Must not:

- edit Fedora's `/etc/pam.d/greetd`;
- create the greeter user with `useradd`;
- run live QML reload in the shipped session.

## Prompt

```text title="Prompt" wrap
Implement 001-05: the login manager into Mango, with the shell as a user service.

Add an image feature `session` (packages greetd and tuigreet): /etc/greetd/config.toml with vt 1, user greetd and `tuigreet --remember --asterisks --sessions /usr/share/stack-os/wayland-sessions`; that folder holds only a Stack OS session file whose Exec is `mango -c /usr/share/stack-os/mango/config.conf`. The Mango config sources Mango's stock config, keeps allow_lock_transparent at 0 and binds Super+L to `qs -p /usr/share/stack-os/shell ipc call lock lock`. Enable greetd.service and set graphical.target; leave Fedora's greetd PAM file alone; the greeter user comes from the package.

Add /usr/lib/systemd/user/stack-os-shell.service: ExecStart `qs -p /usr/share/stack-os/shell`, QS_DISABLE_FILE_WATCHER=1, Restart=on-failure, part of the graphical session, WantedBy mango-session.target (which Mango starts only after exporting its environment), enabled globally. Outside the dev session, the terminal button starts foot with `systemd-run --user --scope`.

The checks of the session feature assert all of it inside the built image; build and check with `task image:build` and `task image:check`. Document every file inline.
```

## Outcome

The image now boots to a login. greetd starts tuigreet, a text-mode greeter, on the first virtual terminal; it remembers the last user and offers only the Stack OS session, which runs Mango with the image's own config, `/usr/share/stack-os/mango/config.conf`. That config keeps Mango's stock bindings, adds Super+L for the lock, and never lets the desktop show through the lock screen. The greeter user comes from greetd's package, and its home, where tuigreet remembers the last user, is created at boot (the image ships `/var` empty). Fedora's greetd PAM file is unchanged.

The shell runs as the user service `stack-os-shell.service` for every user, with live QML reload off and a restart if it fails. Mango's own session target starts it, and Mango starts that target only after exporting its display variables, so the shell always finds the compositor; the service is bound to that target, so it stops with Mango instead of restarting against a compositor that is gone. When the shell runs as that service, the terminal button opens foot in its own systemd scope, so restarting the shell leaves foot open.

## Manual changes

None.

## Result

```
$ task image:build
Checks passed: 14                     # bootc container lint --fatal-warnings
Successfully tagged localhost/stack-os:latest

$ task image:check
enabled                               # greetd.service
greetd:x:981:981:greetd daemon:/var/lib/greetd:/usr/sbin/nologin
(exit 0)
```

`task dev:screenshot RUN=foot` still shows the bar with foot open (the dev session is not a service, so foot starts without a scope). `task lint` passes.

Review: 8 fixed; decisions 02 and 05 are not amended for the changes below (no new decision records, by the operator's rule), which are recorded under Deviations instead.

## Deviations

- No screenshot: the login and the session have no screen until the image boots in a virtual machine (001-07), where logging in is checked.
- The shell starts with Mango's `mango-session.target` instead of a `systemctl --user start` in Mango's `exec_once`: Mango starts that target only after importing its environment, while an `exec_once` command could run before, leaving the shell without `WAYLAND_DISPLAY`.
- tuigreet reads sessions from `/usr/share/stack-os/wayland-sessions`, which holds only the Stack OS session, instead of `/usr/share/wayland-sessions`, where Mango's own plain session also lives.
- The shell's service is wanted by Mango's session target through a link shipped under `/usr/lib/systemd/user/` rather than enabled with `systemctl --global enable`, which writes to `/etc`.
- Whether foot gets its own scope depends on the shell running as a systemd service, not on the dev flag; if `systemd-run` fails, foot starts without a scope.
- The `profile.d` script that imports `environment.d` variables into the session is not added: no variable needs it yet.

## Follow-ups

- Check logging in, the bar's two icons, and the shell service in the virtual machine (001-07).
- Re-lock on shell restart when the session is marked locked, and a recovery key that restarts the shell (decision 03).
- Add the `profile.d` import once a session variable lives in `environment.d`.
