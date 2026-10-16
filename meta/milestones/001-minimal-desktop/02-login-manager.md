# 02: Login manager

**Context.** M1 needs a login that starts Mango with the user's session and that Log out returns to. Constraints: Fedora 44 bootc image, Mango only (no GNOME or Plasma stack), the smallest thing that works now, and a path to a login screen drawn by the Stack OS shell later. Config must suit bootc: users from sysusers.d, static files in the image, nothing mutated at runtime.

**Prior art.** References are copies without git metadata, so citations are unpinned.

- Every Quickshell or Noctalia shell in `references/` logs in through greetd, with a greeter running as an unprivileged user inside a throwaway compositor started by greetd's `default_session`.
  - DankMaterialShell's greeter runs Quickshell inside Mango with an empty config, so the user's keybinds are not live on the login screen, and quits Mango when the greeter exits (`dank-greeter/core/internal/launcher/compositor.go:169-178`). Mango does not quit when its `-s` command exits (`mango/src/main.c:389-423`), hence the explicit `mmsg dispatch quit`.
  - noctalia-greeter bundles its own small compositor (`noctalia-greeter/scripts/noctalia-greeter-session:42-93`).
  - The proof of concept ships greetd plus noctalia-greeter: `/etc/greetd/config.toml` with `vt = 1` and `user = "greetd"`, `systemctl enable greetd.service` and `set-default graphical.target` at build time, `/var` state from tmpfiles.d and a first-boot unit, SELinux labels via `semanage fcontext --equal /var/lib/greetd` (`terra-fedora/features/greeter/`). Fedora's `/etc/pam.d/greetd` already has `pam_systemd` and `pam_gnome_keyring`. greetd sources `/etc/profile`, and Mango ignores environment.d, so a `profile.d` shim imports the environment (`terra-fedora/features/shell/rootfs/etc/profile.d/terra-environment.sh:1-14`).
  - Quickshell's Greetd service (`quickshell/src/services/greetd/`) is built by default (`quickshell/CMakeLists.txt:79`). DankMaterialShell works around Quickshell's cancel race by checking state before every `createSession`, cancelling on failure, and timing out auth and launch (`dank-greeter/quickshell/Modules/Greetd/GreeterContent.qml:621-645,1120-1203`).
  - Omarchy uses SDDM with a theme inside a minimal Hyprland, autologin only on encrypted installs, and a US layout fallback on the login screen (`omarchy-iso/manifests/fresh-4-semantic.json:508-551`, `omarchy-quattro/default/sddm/hyprland.lua:1-63`).
  - DankMaterialShell's Fedora RPM writes `/etc/greetd/config.toml` and PAM from scriptlets (`dank-greeter/distro/fedora/dms-greeter.spec:117-243`); Stack OS does not follow that on an image.
- Elsewhere: KDE replaced SDDM with Plasma Login Manager; COSMIC uses greetd with its own greeter; GDM and Plasma Login Manager pull their desktops in. In Fedora 44: greetd 0.10.3, tuigreet 0.9.1, agreety (with greetd).

| Option | Trend online | Trend in references | Compat | Custom | Perf | Engine |
|---|---|---|---|---|---|---|
| greetd + agreety | M | H | H | L | H | H |
| **greetd + tuigreet** | H | L | H | M | H | H |
| greetd + Quickshell greeter in Mango | M | H | H | H | M | H |
| greetd + cage + Quickshell greeter | M | M | H | H | M | H |
| ly | M | L | M | M | H | M |
| GDM / Plasma Login Manager / SDDM | H | M | L | L–M | L | L |

**Decision.**

- greetd is the login engine. M1 uses tuigreet as its greeter: text mode, no compositor, a session list from `/usr/share/wayland-sessions`, the last user remembered.
- The image ships `/etc/greetd/config.toml` (`vt = 1`, `user = "greetd"`, `command = "tuigreet --remember --asterisks --sessions /usr/share/wayland-sessions"`, flags checked against 0.9.1), enables `greetd.service` and sets `graphical.target` at build time, and leaves Fedora's `/etc/pam.d/greetd` unchanged.
- The greeter user comes from the greetd package's sysusers.d entry, verified in the build with `getent passwd greetd`. No `useradd` in the build.
- A `profile.d` script imports environment.d into the Mango session.
- Later, a login screen drawn by the Stack OS shell replaces tuigreet: Quickshell's Greetd service inside Mango, started with an image-owned Mango config that has no spawn binds, chained `qs … ; mmsg dispatch quit` so greetd restarts it after a crash, with DankMaterialShell's state checks and timeouts around cancel.

**Consequences.**

- Login works with two small Fedora packages and no graphics stack before the session.
- The login screen does not match the desktop's look until the shell's greeter lands.
- `/etc/greetd/config.toml` merges three ways on upgrade; a local edit freezes it. Users are told not to edit it.
- Fedora's greetd packaging (sysusers name, default config, SELinux policy) is unverified until checked with `rpm -ql greetd` and `rpm -q --scripts greetd` in the build container.
- Autologin on encrypted installs and a keyboard layout fallback are Follow-ups.
