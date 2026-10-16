---
title: 1-Dev environment
description: A toolbox with Mango, foot and a pinned Quickshell, running the shell from the repository in a nested window.
sidebar:
  order: 1
---

001-01: dev environment for the shell

## Goal

A fast local loop for the shell, before any image exists: one command sets up a development container, and one command opens the Mango compositor in a window on the developer's desktop, running the Stack OS shell straight from the repository and reloading it on every save. This serves the milestone's first "done when" item.

## Context

The repository had the docs site, the conventions and the M1 plan, but no code. Earlier decisions this step implements:

- **The shell is Stack OS's own QML on Quickshell 0.3.2**, built from source. Fedora 44 ships an older Quickshell snapshot (0.2.1, February 2026) that lacks 0.3's fixes, so it is not used.
- **Quickshell uses Qt's private APIs** and crashes if the Qt it runs with differs from the Qt it was built against. So it is built once as an RPM by `task quickshell:rpm`, inside a container, and the RPM requires exactly the Qt versions it was compiled with. The disk image, built in a later step, installs the same RPM; the image build itself never compiles.
- **Every input Stack OS controls is pinned**, by digest or commit, in one `versions.yml`; nothing moves until that file changes. (Qt itself is taken from Fedora when the RPM is built; locking it comes with the disk image.)
- **Mango comes from Terra**, Fyra Labs' Fedora repository, the only third-party repository.
- Development happens in a [toolbox](https://containertoolbx.org/) container, so nothing is installed on the developer's machine.

## Expectations

Must:

- `versions.yml` pins the `fedora-toolbox:44` image by digest, and Quickshell by tag (`v0.3.2`) and commit.
- `task quickshell:rpm` writes `output/rpms/quickshell-<key>.rpm`, where the key is a hash of every input of the build Stack OS controls; a second run with nothing changed builds nothing.
- The build fails if the pinned tag no longer points at the pinned commit.
- The RPM requires the exact `qt6-qtbase` and `qt6-qtdeclarative` versions it was built against.
- `task dev:setup` builds the toolbox image (Mango, foot, the Quickshell RPM) and creates the `stack-os-dev` toolbox; inside it, `qs --version` reports 0.3.2.
- `task dev:run` opens nested Mango in a window, with the shell loaded from `src/shell/` in the repository: a placeholder bar along the top.
- Saving a change to `src/shell/shell.qml` updates the bar within seconds, without a restart.
- Alt+Return inside nested Mango opens foot.
- The dev session sets `STACK_OS_DEV=1`, which later steps use so Restart and Shut down only print in development.

Must not:

- install anything on the host besides container images and the toolbox;
- use Fedora's `quickshell` package;
- compile anything in the toolbox image build;
- use npm or node.

## Prompt

> Implement M1-1, the dev environment for the Stack OS shell. All code lives under `src/`, one folder per project; every developer command goes through Task (`task <name>`, from taskfile.dev), never `bun` or `bunx` directly.
>
> Pin the inputs in a root `versions.yml`: the `fedora-toolbox:44` image by digest, and Quickshell v0.3.2 by tag and commit. Add `task quickshell:rpm`, which builds Quickshell from that tag in a container from the pinned image, using an RPM spec of our own (adapted from Fedora's, with 0.3.2's options, Wayland only, no crash handler, no Hyprland or i3 integrations) that requires the exact Qt versions it was built against. It verifies the tag's commit, writes `output/rpms/quickshell-<key>.rpm` keyed by a hash of the pin, the image, the spec and the build script, skips the build when that file exists, never leaves a half-written RPM behind, and keeps a working ccache between builds.
>
> Add `task dev:setup`, which builds a toolbox image from the same pinned image with Mango from Terra, foot, grim and that RPM (no compiling), tagged so that a change to the RPM or the Containerfile rebuilds it, and creates the `stack-os-dev` toolbox; `task dev:run`, which starts Mango nested in a window with a dev config that keeps Mango's stock bindings, sets `STACK_OS_DEV=1` and starts the shell from `src/shell/` with live reload; and `task dev:screenshot`, which runs the same session headless, saves a screenshot to `output/screenshots/shell.png` with grim and fails if none was taken. The shell itself is a placeholder bar for now.
>
> `task setup` at the root installs every dependency: Bun, uv, podman and toolbox when missing, the git hooks, the docs site, the Quickshell RPM and the dev toolbox. Drop the Task npm package; Task is installed from taskfile.dev. Keep the Taskfiles modular (one per folder, each with an `install` task, included from the root) and document every file inline.

## Outcome

A developer installs Task and runs `task setup`; then `task dev:run` opens Mango in a window on their desktop, running the Stack OS shell straight from `src/shell/`. The shell is a placeholder: a thin dark bar along the top reading "Stack OS (dev)". Saving `src/shell/shell.qml` updates it within seconds, and Alt+Return opens foot, both checked by hand in the nested window.

![The placeholder bar along the top of the Mango session, reading "Stack OS (dev)"](../../../../assets/how-it-was-made/001-minimal-desktop/1-dev-environment.png)

Quickshell 0.3.2 is built once, from the pinned tag, into an RPM that requires exactly the Qt it was compiled with (`qt6-qtbase = 6.11.2-3.fc44`, `qt6-qtdeclarative = 6.11.2-2.fc44`); the toolbox image installs that RPM and compiles nothing. Every build input is pinned in `versions.yml`, and nothing rebuilds until one of them, the spec, the build script or the Containerfile changes. `task dev:screenshot` lets anyone, an agent included, check the shell without a display.

## Manual changes

Task itself is installed by hand, from [taskfile.dev](https://taskfile.dev/docs/installation): it is the one tool that runs everything else.

## Result

```
$ task setup
task: Task "host:bun" is up to date
task: Task "host:uv" is up to date
task: Task "host:containers" is up to date
task: Task "docs:install" is up to date
task: Task "quickshell:rpm" is up to date
task: Task "dev:image" is up to date
task: Task "dev:toolbox" is up to date

$ rpm -qp --requires output/rpms/quickshell-<key>.rpm | grep qt6-qt
qt6-qtbase(x86-64) = 6.11.2-3.fc44
qt6-qtdeclarative(x86-64) = 6.11.2-2.fc44

$ toolbox run --container stack-os-dev qs --version
Quickshell 0.3.2 (revision 4f508be500dea6e5732cc3d50382a0048b17e7b1, distributed by Stack OS)

$ task dev:screenshot
output/screenshots/shell.png        # the bar along the top, "Stack OS (dev)"
```

Review: 14 fixed, 3 deferred (Qt in the RPM key, Bun and uv pins, the session-target check; see Follow-ups).

A live-reload check in the headless session logged `Reloading configuration...` then `Configuration Loaded` after an edit to `shell.qml`. `task lint` passes.

## Deviations

- Code moved from the repository root into `src/` (`src/shell/`, `src/dev/`, `src/quickshell/`); `versions.yml` stays at the root because it pins inputs for the whole repository, including the disk image built later.
- Every developer command goes through Task; the Task npm package was dropped and Task is installed from taskfile.dev.
- `task setup` installs missing host tools (Bun and uv into the home folder, podman and toolbox with `dnf`), relaxing the expectation that nothing but container images and the toolbox lands on the host. The goal is one command from a fresh clone to a working setup.
- grim and `task dev:screenshot` were added so the shell can be checked without a display.
- The Quickshell RPM is built in the pinned `fedora-toolbox:44` image, not in the disk image's `minimal` stage, which does not exist yet; the Qt it builds against is whatever Fedora's `updates` repository holds at build time and is not part of the RPM's key.
- The agent's command allow list now allows any `task` command instead of `bun install` and `bun run`, matching the Task-only rule.
- The unused prototypes' include was dropped from the root `Taskfile.yml`; their folder was deleted.

## Follow-ups

- Quickshell can start before nested Mango announces its output ("There are no outputs - creating placeholder screen"); Mango then places the bar itself. Harmless so far; fix if the bar ever lands in the wrong place.
- Pin the Bun and uv installers to exact versions in `versions.yml`.
- M1-4 (image skeleton): build the Quickshell RPM in the image's `minimal` stage and add the locked Qt versions to its key, so two machines can never build the same key against different Qt.
- Check that the real Mango session reaches `graphical-session.target` and exports its environment to the user's service manager; if not, start the shell under a restart loop. The nested session cannot test this; it moves to the login-manager step (M1-5).
- The host portal warns it cannot register `org.quickshell`, because the app's desktop file is inside the toolbox. Harmless in development; confirm it disappears on the installed image.
