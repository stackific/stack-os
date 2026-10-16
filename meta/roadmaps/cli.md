# The `stack` command

Specification for Stack OS's maintenance command. Stack OS (stack-os.org) is the Fedora bootc desktop that this repository builds. The command replaces the `terra` Taskfile wrapper in `features/cli`.

Status: draft for review. Nothing here is implemented yet. Open decisions are listed at the end.

## Goals

- One command for everything a user does to the system after installation: update, roll back, install and remove software, revert to an older release, enroll the Secure Boot key, and diagnose problems.
- Hide the image-based model. A user types `stack install wlr-randr` and does not need to know about layering, Flatpak, or deployments, unless they ask.
- Work for a GUI as well as a terminal: every read-only command has `--json` output, and every privileged action can be run without a terminal (polkit), so a Quickshell or Noctalia widget can be built on it.
- Say what happens next. Any change that needs a reboot says so, once, in the last line.
- Never reboot, never download without saying so, and never remove something the user installed without asking.

## Names and paths

| Item | Value |
|---|---|
| Command | `/usr/bin/stack` |
| Short alias | `sl`, as a shell alias in `/etc/profile.d/stack-os.sh` (not a file in `/usr/bin`: Fedora's `sl` package, the steam locomotive joke, owns that name and would conflict) |
| Images | `ghcr.io/stackific/stack-os` and `ghcr.io/stackific/stack-os-nvidia` |
| Tags | `latest`, `44`, and `44.<YYYYMMDD>` per build; `44.<YYYYMMDD>.<n>` when a day has more than one build |
| Shipped data | `/usr/share/stack-os/` (release metadata, the public signing key, completions) |
| System state | `/var/lib/stack-os/` (last update check, cached version list, settings the user changed) |
| Admin config | `/etc/stack-os/stack.toml` (optional overrides: registry, channel, timers) |
| Systemd units | `stack-os-update.timer` / `.service`, `stack-os-flatpak-update.timer` / `.service` |
| Environment | `STACK_REGISTRY` overrides the registry for testing |

The image carries `/usr/share/stack-os/release.json`:

```json
{
  "name": "Stack OS",
  "version": "44.20261015",
  "variant": "base",
  "fedora": "44",
  "image": "ghcr.io/stackific/stack-os",
  "built": "2026-10-15T20:48:56Z",
  "commit": "88edfb0",
  "changelog_url": "https://github.com/stackific/stack-os/releases/tag/44.20261015"
}
```

The same values are set as OCI labels on the image (`org.opencontainers.image.version`, `org.opencontainers.image.revision`, `org.opencontainers.image.created`, `org.stack-os.variant`, `org.stack-os.changelog`), so `stack versions` can describe a release without downloading it.

## Commands

`stack` with no arguments prints a one-screen summary: the running version, whether an update is staged, how many Flatpak updates are pending, and the command list.

### `stack status`

Shows, in this order:

- Running: version, variant, build date, image reference.
- Staged: the version that takes effect at the next reboot, if any.
- Previous: the version `stack rollback` would boot.
- Pinned: locally kept versions (see `stack pin`).
- Layered packages: what `stack install` added as RPMs, if any.
- Flatpak: installed app count, updates pending.
- Secure Boot: on or off; on the NVIDIA image, whether Stack's module key is enrolled.
- Updates: when the timer last staged one, and when it runs next.

`--json` prints the same as one object. This is the call a GUI widget polls.

### `stack update`

Stages the next image, updates Flatpak apps, and reports what changed.

- Image: `bootc upgrade`, or `rpm-ostree upgrade` when packages are layered (bootc does not re-apply layered packages; rpm-ostree does).
- Flatpak: `flatpak update --system --noninteractive -y` and the same for the user installation.
- Firmware: `--firmware` also runs `fwupdmgr refresh` and `fwupdmgr update`. Off by default, because firmware updates can require the machine to be plugged in and can brick a device if interrupted.
- `--check`: only reports whether a newer version exists and prints its changelog. Downloads nothing.
- `--reboot`: reboots when the update is staged, after a 10-second countdown that Ctrl+C cancels.
- The last line is one of: `Nothing to do.`, `Update staged: 44.20261016. Reboot to finish.`, or the error.
- The daily timer runs exactly this command (without `--firmware`) and sends a desktop notification to active sessions when something was staged: "Stack OS 44.20261016 is ready. Restart to finish."

### `stack rollback`

Boots the previous version at the next reboot (`bootc rollback`). Prints which version that is and asks for confirmation unless `--yes`. `--reboot` reboots afterwards. Running it a second time swaps back; the command says so.

### `stack versions`

Lists published versions of the running image's variant, newest first, from the registry (`skopeo list-tags`, cached in `/var/lib/stack-os/versions.json` for an hour). Marks the running, staged, previous, and pinned versions. With `--changelog`, prints each version's changelog summary. Needs the network for anything beyond what is cached.

### `stack revert <version>`

Switches the machine to an older published version: `bootc switch ghcr.io/stackific/stack-os:44.20261010` (or `rpm-ostree rebase` when packages are layered). The image is downloaded, staged, and takes effect at the next reboot.

The command states two consequences before asking for confirmation:

- The machine now tracks that exact version. Daily updates stop until `stack latest` is run.
- The system goes back; the home folder, settings, and Flatpak apps do not.

`stack latest` switches back to the `latest` tag and resumes updates. `stack status` shows "tracking 44.20261010 (updates paused)" while reverted.

### `stack pin [<version>]` and `stack unpin <version>`

Keeps a locally installed version on disk so `stack revert` to it works offline and survives further updates (`ostree admin pin`). Without an argument, pins the running version. `stack status` lists pins; `stack versions` marks them. At most three pins; the command refuses a fourth and says which to unpin.

### `stack install <name>...`

Installs software, choosing the method:

1. If `<name>` is a Flatpak application id (`org.gimp.GIMP`) or matches exactly one Flathub app by name, install it with Flatpak. Desktop apps belong here.
2. Otherwise, if it is an RPM in the enabled repositories (Fedora, RPM Fusion, Terra), layer it with `rpm-ostree install`. It is part of the system from the next reboot, and stays through updates.
3. If both match, or several Flathub apps match, list the candidates with their source and ask, unless `--flatpak` or `--rpm` was given.
4. If nothing matches, say so and suggest `stack search`.

Options:

- `--flatpak`, `--rpm`: force the method.
- `--now`: for RPMs, also apply to the running system without a reboot (`rpm-ostree install --apply-live`). Flatpak installs are always immediate.
- `--transient`: install an RPM only until the next reboot (`dnf install --transient`). For trying a tool.
- `--user`: install the Flatpak for this user only instead of system-wide.

The last line says what happened: `Installed GIMP (Flatpak).`, `Added wlr-randr to the system. Reboot to use it, or run with --now.`, or `wlr-randr is available until the next reboot.`

Before layering the first RPM on a machine, the command explains once that layered packages are re-applied on every update and that `stack list` shows them.

### `stack remove <name>...`

The inverse: `flatpak uninstall` or `rpm-ostree uninstall`, chosen by looking at what is installed. Refuses to remove packages that are part of the image ("`thunar` is part of Stack OS; it cannot be removed, only hidden from the launcher") and points at `stack search` for alternatives.

### `stack search <term>`

Searches Flathub and the enabled RPM repositories and prints one table with a Source column (Flathub, Fedora, RPM Fusion, Terra), the name, the version, and a one-line summary. Flathub results come first. Needs the network.

### `stack list`

Lists what the user added: Flatpak apps (system and user), layered RPMs, transient RPMs for this boot, and pins. `--json` for GUIs.

### `stack enroll-key`

NVIDIA image only (the base image says it is not needed). Queues Stack's kernel module signing key with `mokutil --import`, after checking it is not already enrolled or queued. Explains the one-time password and the blue MOK screen at the next boot, as the current `terra enroll-key` does.

### `stack doctor`

Runs checks and prints a report suitable for pasting into a bug report. Each check is a line with OK, WARN, or FAIL:

- Release metadata readable; running version matches `bootc status`.
- No staged update older than seven days (the user forgot to reboot).
- Failed systemd units (system and user).
- SELinux: enforcing; count of denials this boot, with the last three.
- Disk: free space on `/`, `/var`, and the home folder; warn under 10% or 5 GB.
- Secure Boot state; on NVIDIA, whether the `nvidia` module is loaded and the key is enrolled.
- Graphics: the DRM driver in use (so "recording does not work" reports show nouveau vs nvidia vs virtio).
- Network: can resolve and reach the registry (skipped with `--offline`).
- Timers: `stack-update.timer` and `stack-flatpak-update.timer` enabled and when they last ran.
- Layered packages present (a hint when updates fail).

`--json` for tooling. Never changes anything.

### `stack version`

Prints the command's version and the release metadata in one line: `stack 1.0.0 (Stack OS 44.20261015, base)`.

### `stack help [command]`

Help text. Each command's help ends with what it runs underneath, so advanced users can go straight to `bootc`, `rpm-ostree`, or `flatpak`.

## Behavior shared by every command

- Privileges: the command runs as the user and escalates only for the step that needs it. In a terminal it uses `sudo` (one prompt per invocation). Without a terminal (`--no-tty`, or stdin not a TTY) it uses `pkexec` with the polkit action `org.stack-os.stack.manage`, which the `wheel` group may use with its password. A GUI calls `stack --no-tty --json ...`.
- Output: plain text, no colors when stdout is not a terminal, one summary line last. `--json` prints a single object or array and nothing else on stdout; progress and warnings go to stderr. `--quiet` suppresses progress.
- Confirmation: changes that affect the next boot (`rollback`, `revert`, `latest`, layered `install` and `remove`) ask once; `--yes` skips. Flatpak installs do not ask.
- Network: commands that need it say so in their help and fail fast with `No network: <what was needed>` rather than hanging. The daily timer only runs with `network-online.target`.
- Exit codes: 0 success, 1 error, 2 bad usage, 3 needs reboot first (a change is pending that conflicts), 4 no network.
- Locking: one `stack` change at a time (`flock /run/lock/stack`). A second invocation waits and says so.
- Logging: every change appends one line to `/var/log/stack.log` (time, user, command, result), so `stack doctor` and bug reports can show recent actions.
- Completion: bash completion in `/usr/share/bash-completion/completions/stack`, generated by the binary (`stack completion bash`).

## Implementation

- Language: Go, as one static binary with no runtime dependencies, built in CI and installed as `/usr/bin/stack`. The reasons: it parses the JSON that `bootc status --json`, `rpm-ostree status --json`, `skopeo`, and `flatpak` produce, talks to polkit and the registry without shelling out to curl, and ships as one file. DankMaterialShell's `dms` command is the same shape. The alternative is a single Python 3 file using only the standard library (`/usr/bin/python3 -I`), which needs no build step; it is slower to start and harder to keep tidy as commands grow.
- Underneath: `bootc`, `rpm-ostree`, `flatpak`, `skopeo`, `ostree admin pin`, `mokutil`, `fwupdmgr`, `dnf --transient`. The command never reimplements these; it chooses between them and explains the result.
- Packages to add to the image: `rpm-ostree` (layering, and the only way layered packages survive updates), `skopeo` (registry tag listing), `polkit` rules for the action. `go-task` leaves the image unless kept for users on purpose.
- Image build: `features/cli` installs the binary, `release.json`, the polkit action and rule, the profile.d alias, the completion file, and the timers (moved from `features/updates`). Its `check` runs `stack version`, `stack status --json` (works inside the build container with a fake `release.json` and no `bootc`, reporting "not booted"), and `stack doctor --offline`.
- CI: the build writes `release.json` and the OCI labels from the version tag, and publishes a GitHub release per version whose notes are the changelog (package differences against the previous build, from the `meta/packages` tables). `stack versions --changelog` reads those notes.
- Tests: Go unit tests for method selection (`install` name resolution), JSON parsing, and output; a VM test that runs `stack status`, `stack install --transient`, `stack doctor`, and `stack update --check` against a booted disk image.

## Migration from `terra`

- `terra` disappears; the image never shipped to anyone with it. The Taskfile in `/usr/share/terra` and the `go-task` dependency go with it.
- `terra update` and `terra rollback` map to `stack update` and `stack rollback` unchanged. `terra status` becomes richer. `terra enroll-key` is `stack enroll-key`.
- The timers are renamed; `features/updates` keeps the mask of `bootc-fetch-apply-updates.timer`.

## Not in scope

- A graphical settings app. The command's `--json` and `--no-tty` support exist so one can be built later, inside the shell.
- Managing user dotfiles or per-user config. That stays with the shell's own settings.
- Snapshots of the home folder. The system reverts; files do not.
- Building images on the machine (`stack build`). Images come from CI.

## Open decisions

1. Go or Python for the implementation (Go recommended above).
2. Keep `go-task` and the `task` command in the image for users once `stack` no longer needs it?
3. How many pins to allow (three proposed) and how much disk a pin may use.
4. ~~Registry owner and image names.~~ Settled: `ghcr.io/stackific/stack-os`, with `stack-os` as the name for every system path and unit.
5. Whether `stack update` should include firmware by default on laptops that are plugged in, or stay opt-in.
6. Whether the daily timer should also run `stack doctor` and notify on FAIL lines.
