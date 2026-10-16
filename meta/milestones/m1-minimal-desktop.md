# M1: Minimal desktop

The smallest Stack OS that proves the image: an installer ISO that installs a Fedora bootc system, logs in through greetd, and starts Mango with a Quickshell bar that launches kitty and powers the machine off.

Scope: Fedora 44 bootc from the minimal manifest; Mesa only (no NVIDIA or other GPU driver packages); Mango, Quickshell, kitty, greetd. A local `task` command and a manually triggered GitHub Action build the ISO. Out of scope: publishing the image or ISO, updates (`bootc upgrade` has no registry to pull from yet), theming, the `stack` command. Follows `references/terra-fedora` wherever it applies.

Done when:

- [ ] `task image:build` builds the image locally and `bootc container lint` passes in the build
- [ ] `task iso` writes an installer ISO to `output/`
- [ ] The manually run GitHub Action (`workflow_dispatch`) builds the ISO and attaches it to the run as an artifact; nothing is pushed to a registry or release
- [ ] The ISO installs in a UEFI VM (QEMU/virt-manager) and boots to the greetd login
- [ ] Logging in starts Mango with a Quickshell bar showing two icons
- [ ] The terminal icon opens kitty
- [ ] The power icon opens a menu: Lock locks the screen and unlocks with the password; Log out returns to greetd; Restart reboots; Shut down powers off
- [ ] No GPU driver beyond Mesa: `rpm -qa | grep -E 'akmod|kmod-nvidia|xorg-x11-drv-nvidia'` prints nothing

Decisions to settle first:

- 0001: Image layout. Fedora bootc minimal manifest (`bootc-base-imagectl build-rootfs --manifest=minimal`) plus one folder per feature (`features/<name>/` with `packages` and a `Taskfile.yml`), run in order by a build Taskfile, as in terra-fedora. Mango comes from Fyra Labs' Terra RPM repository, the only third-party repo in M1.
- 0002: Greeter. greetd with tuigreet (in Fedora, text-mode, no extra compositor) for M1; a Quickshell greeter later.
- 0003: Lock screen. swaylock (in Fedora, one command) for M1; Quickshell's own session lock later.

Steps:

- [ ] M1.1: image skeleton: Containerfile, feature layout, `task image:build` (decision 0001)
- [ ] M1.2: Mango session with kitty and Mesa
- [ ] M1.3: greetd login into Mango (decision 0002)
- [ ] M1.4: Quickshell bar with the kitty launcher icon
- [ ] M1.5: power menu: lock, log out, restart, shut down (decision 0003)
- [ ] M1.6: installer ISO with `task iso`
- [ ] M1.7: GitHub Action to build the ISO on demand
