# 05: Shell toolkit

**Context.** Stack OS draws its own desktop shell on Mango: in M1 a bar with a terminal launcher and a power menu, and the lock screen (decision 03); later a launcher, notifications, OSD, a login screen and settings. Mango is fixed. The shell is Stack OS's own code, not an adopted shell. The proof of concept ships Mango with Noctalia v5, so any other choice departs from a proven path and must say why.

**Prior art.** References are copies without git metadata, so citations are unpinned.

- The proof of concept runs the Fedora `noctalia` RPM, started by `exec_once=noctalia`, with `noctalia-greeter` from Terra under greetd (`terra-fedora/README.md:3,55`, `terra-fedora/features/mango/blocks/10-noctalia.conf:1`, `terra-fedora/features/greeter/packages:3`). `meta/roadmaps/refs.md` already lists Noctalia as what is being replaced.
- Quickshell (QML on Qt 6, LGPL-3.0) is the most adopted shell toolkit: Omarchy 4's shell is a Quickshell plugin host (`omarchy-quattro/shell/`, `omarchy-quattro/agents/skills/shell-dev.md:5-51`), as are DankMaterialShell, Caelestia and end-4. 0.3.0 added idle, polkit, networking and an ext-workspace `WindowManager`; 0.3.1 and 0.3.2 fix session-lock crashes and socket reconnection (`quickshell/changelog/`). Its author is now employed by Omarchy's foundation; it still has about one core maintainer.
- Quickshell links Qt private APIs and must be rebuilt for every Qt release (`quickshell/BUILD.md:42-51`). Fedora 44 ships a February 2026 snapshot of 0.2.1, without 0.3's idle, polkit and lock fixes. No reference compiles it inside an image build.
- Noctalia v5 left Quickshell for native C++ with no Qt, citing memory per monitor and immunity to distro Qt updates; it has native Mango backends and is current in Fedora 44 (`noctalia/README.md:3-9,62-75`, `noctalia/src/compositors/mango/`). It is an application, not a toolkit.
- Shells talk to Mango over its JSON socket at `$MANGO_INSTANCE_SIGNATURE` (`watch all-tags`, `all-clients`, `all-monitors`): DankMaterialShell in QML (`DankMaterialShell/quickshell/Services/MangoService.qml:12-62`), Noctalia and Waybar in C++. Mango also implements ext-workspace, so Quickshell's `WindowManager` shows tags with no Mango-specific code (`quickshell/src/windowmanager/module.md:1-10`). Quickshell has no output-management client.
- Measured cost: `qs` settles at 44–45 MB PSS with transparent huge pages off for the process and about 101–104 MB with them set to `always`; a GTK platform theme adds about 7 MB and 60 ms; the first launch after an update spends 1.7–3.0 s writing the QML cache (`flea/AGENTS.md:190-201,1201-1205,7144-7154`).
- Running it: DankMaterialShell ships a systemd user unit (`Type=notify`, `Restart=on-failure`, `QS_DISABLE_CRASH_HANDLER=1`, bound to `graphical-session.target`) (`DankMaterialShell/assets/systemd/dms.service:1-23`); Omarchy uses a supervisor script that sets `QS_DISABLE_FILE_WATCHER=1` so a package update cannot crash a live reload (`omarchy-quattro/bin/omarchy-launch-shell:6-93`), and its own IPC socket at about 5 ms per call against about 45 ms for `qs ipc` (`omarchy-quattro/shell/shell.qml:1649-1661`).

| Option | Trend online | Trend in references | Compat | Custom | Perf | Engine |
|---|---|---|---|---|---|---|
| **Quickshell, own shell** | H | H | M | H | M | H |
| Noctalia v5 (adopt or fork) | H | M | H | M | H | H |
| DankMaterialShell (adopt) | H | M | H | M | M | H |
| Custom native (C++ or Rust) | M | L | H | H | H | H |
| Waybar + separate tools | M | M | H | L | H | M |
| AGS / Astal | M | L | M | H | M | M |
| ironbar, sfwbar, Eww, Fabric, Ignis | L | L | L–M | M | M–H | M |

**Decision.**

- The Stack OS shell is written in QML on Quickshell, pinned to the `v0.3.2` tag and its commit hash, built from source by `task quickshell:rpm` against the image's pinned Qt (decision 01). The dev toolbox uses the same recipe. Fedora's package is not used, and no adopted shell (Noctalia, DankMaterialShell) is used or kept as a fallback.
- Build and cache: `task quickshell:rpm` (decision 01) builds the RPM once per key, a hash of the Quickshell tag and commit, the locked Qt and build-dependency versions, and the recipe; an existing RPM for the key is reused locally and in CI, and ccache shortens real rebuilds.
- Quickshell moves only when Stack OS bumps the pin: a new Quickshell release, or a Qt bump in the pinned package set, is a deliberate change with a rebuild and the shell's checks. Between bumps nothing changes.
- One long-running Quickshell process owns the bar, the power menu and the lock; later components are added as lazily loaded parts of the same process.
- Mango state: Quickshell's `WindowManager` (ext-workspace) for tags; Mango's JSON socket for anything Mango-specific. Monitor configuration goes through Mango's config, not the shell.
- The shell's QML ships under `/usr/share/stack-os/shell`. Live reload is for the dev loop only; the shipped shell runs with the file watcher off.
- The shell runs as the systemd user unit `stack-os-shell.service` (`Restart=on-failure`, logs to the journal), started from Mango's `exec_once` with `systemctl --user start`. The dev environment step verifies that the Mango session reaches `graphical-session.target` and exports its environment to the user manager; if not, `exec_once` runs the shell under a restart loop instead.
- `stack shell` calls go through `qs ipc`; a socket of our own only if a keybinding feels slow.
- M1's shell is plain QML modules: one folder per component (the bar, each bar widget, the power menu, the lock), with shared services and singletons in their own folders, and pure logic in plain JavaScript files tested with `bun test`. There is no plugin layer yet; a plugin convention (manifest, discovery, host API) is a later decision, and the module layout is kept so components can become plugins without a rewrite.

**Consequences.**

- Full control of the look and behaviour, in the toolkit most current shells use, with hot reload in development.
- Stack OS builds and pins Quickshell itself, about 61,000 lines of C++ and QML. Fedora 44 already moved Qt from 6.10.2 to 6.11.2 within the release, which needs a Quickshell rebuild; with Qt pinned, that happens only when Stack OS bumps Qt, and a Qt/Quickshell mismatch fails `image:check`.
- Higher memory per monitor than Noctalia's native shell; Stack OS measures idle memory and cold start on its own image (one and two monitors) and sets a budget.
- The first launch after each image update pays the QML cache cost unless the cache is prebuilt in the image.
- Depends on one maintainer whose employer is Hyprland-focused; the LGPL licence, the pin and active forks limit the risk. If upstream stalls, Stack OS can carry the pinned version and patch it.
