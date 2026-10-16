# M1: Minimal desktop

The smallest Stack OS that proves the image: an installer ISO that installs a Fedora bootc system, logs in through a login manager, and starts Mango with a Quickshell bar that launches foot and powers the machine off.

Scope: Fedora 44 bootc from the minimal manifest, x86_64 only (no ARM); Mesa only (no NVIDIA or other GPU driver packages); Btrfs root filesystem; swap on zram only (no swap partition or file); Mango, Quickshell, foot, a login manager. The bar and its buttons are Stack OS's own Quickshell code: no Noctalia, DankMaterialShell or similar shells. The shell is developed first in a fast local loop; image production comes last. A local `task` command builds the ISO; on-demand CI builds are a separate chore, not part of this milestone. Out of scope: publishing the image or ISO, updates (`bootc upgrade` has no registry to pull from yet), theming, the `stack` command.

Done when:

- [x] `task dev:run` starts Mango nested in a window with the shell loaded from the repo, and QML edits reload live
- [ ] `task image:build` builds the image locally and `bootc container lint` passes in the build
- [ ] `task iso` writes an installer ISO to `output/`
- [ ] The ISO installs in a UEFI VM (QEMU with KVM) and boots to the login manager
- [ ] Logging in starts Mango with a Quickshell bar showing two icons
- [ ] The terminal icon opens foot
- [ ] The power icon opens a menu: Lock locks the screen and unlocks with the password; Log out returns to the login manager; Restart reboots; Shut down powers off
- [ ] The installed system's root is Btrfs: `findmnt -no FSTYPE /sysroot` prints `btrfs`
- [ ] Swap is zram: `swapon --show` lists only `/dev/zram0`
- [ ] Each monitor starts at the scale its physical DPI calls for: `task scale:test` passes on EDID samples (laptop, 27" 4K, 1080p, 0 mm), and a VM boots at scale 1
- [ ] No GPU driver beyond Mesa: `rpm -qa | grep -E 'akmod|kmod-nvidia|xorg-x11-drv-nvidia'` prints nothing

Decisions (all accepted):

- [01](01-image-layout.md): Image layout. Minimal Fedora 44 bootc base with every package locked, Quickshell built once per pinned version by `task quickshell:rpm`, feature folders run by a build Taskfile, Terra disabled after installing Mango, Btrfs default set in the image.
- [02](02-login-manager.md): Login manager. greetd with tuigreet now; later a login screen drawn by the Stack OS shell inside Mango.
- [03](03-lock-screen.md): Lock screen. The shell's own lock (Quickshell `WlSessionLock`) with a password-only PAM file shipped under `/usr`.
- [04](04-display-scale.md): Display scale. A script writes a Mango `monitorrule` per monitor from its EDID DPI (135 DPI target for laptop panels and screens under 20", 110 otherwise; clean quarter steps) before Mango starts and on hotplug.
- [05](05-shell-toolkit.md): Shell toolkit. Stack OS's own QML shell on Quickshell 0.3.2+, built from source against the image's Qt.

Open questions, each with a recommendation: `open-questions.md`.

Steps:

- [x] 1 (b6e67e9): dev environment: toolbox with Mango, Quickshell and foot; Quickshell 0.3.x built from source against the exact Qt it runs with (not Fedora's 0.2.1 snapshot), by one recipe the image build (step 4) reuses; `task dev:setup`, `task dev:run` runs Mango nested with the shell from the repo (Restart and Shut down only print in dev mode)
- [x] 2 (b15b840): Quickshell bar with the foot launcher icon
- [x] 3 (92c6d28): power menu: lock, log out (`mmsg dispatch quit`), restart, shut down (`systemctl`) (decision 03)
- [x] 4 (08cfc10): image skeleton: Containerfile, feature layout, `task image:build`, `task image:check` (assertions inside the built image), zram swap via `zram-generator` (decision 01)
- [x] 5 (4860587): login manager into Mango (decision 02)
- [ ] 6: display scale from physical DPI, `task scale:test` (decision 04)
- [ ] 7: VM boot test on a Btrfs root: `task disk:qcow2`, `task vm:run` (QEMU with KVM)
- [ ] 8: installer ISO that installs to Btrfs: `task iso`, `task vm:install`
- [ ] 9: lock every package: `task lock`, `rootfs.lock`, `image.lock`, versionlock in the build, `image:check` fails on any difference, Fedora's `go-task` pinned, `terra-release` installed from a checksum-pinned RPM instead of without a GPG check (decision 01)
