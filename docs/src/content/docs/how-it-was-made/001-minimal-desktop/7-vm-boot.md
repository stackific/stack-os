---
title: 7-VM boot test
description: The image becomes a Btrfs disk that boots in a QEMU virtual machine, logs in, and shows the Stack OS bar, checked automatically.
sidebar:
  order: 7
---

[001-07: VM boot test on a Btrfs root](https://github.com/stackific/stack-os/commit/d3e6cd5109c23fe0cf7c7f3efc2cac5fde31aa07)

## Goal

Prove that the image boots: turn it into a virtual machine disk with a Btrfs root, boot it with QEMU and KVM, and check automatically that it reaches the login, that logging in starts Mango with the bar's two icons, and that the installed system has a Btrfs root, zram swap and no GPU driver beyond Mesa. This serves the milestone's Btrfs, zram, GPU-driver and "a VM boots at scale 1" items, and the screen check of "logging in starts Mango with a Quickshell bar showing two icons".

## Context

Steps 001-04 to 001-06 built the image: Mango, the shell as a user service, a text login, and per-monitor scaling. Nothing has booted it yet. Earlier decisions this step implements:

- **Disks come from bootc-image-builder**, Fedora and CentOS's tool that turns a bootc image into a disk, pinned by digest, with a Btrfs root (`--rootfs btrfs`).
- **The developer's machine provides only podman**: QEMU and the UEFI firmware run in a pinned container, so nothing is installed on the host.

## Expectations

Must:

- `versions.yml` pins bootc-image-builder by digest.
- `task vm:disk` writes `output/qcow2/disk.qcow2` from `localhost/stack-os:latest` with a Btrfs root and a throwaway test user (`test`), copying the image into root's container storage first.
- `task vm:boot` boots that disk headless with KVM in a container (QEMU, OVMF), without changing the disk, and fails unless it reaches a login prompt.
- Logged in on the serial console, it checks that `findmnt -no FSTYPE /sysroot` prints `btrfs` and `swapon --show` lists only `/dev/zram0`.
- It then logs in at the text greeter, waits until Mango runs and the user's `stack-os-shell.service` is active, and saves a screenshot of the session: the bar with the terminal and power icons.
- `task vm:run` boots the disk with a display the developer can open, for trying it by hand.

Must not:

- install QEMU or firmware on the host;
- use the test user's disk for anything but boot tests;
- change `disk.qcow2` when testing (the VM runs on a snapshot).

## Prompt

```text title="Prompt" wrap
Implement 001-07: the VM boot test on a Btrfs root.

Pin quay.io/centos-bootc/bootc-image-builder by digest in versions.yml. Add src/vm/ with its own Taskfile (included from the root as `vm`): `vm:disk` copies localhost/stack-os:latest into root's container storage and runs bootc-image-builder (privileged, root storage mounted) with `--type qcow2 --rootfs btrfs` and a config with a throwaway user `test`/`test` in wheel, writing output/qcow2/disk.qcow2 owned by the developer; it uses sudo, so the developer runs it. A small container image from the pinned Fedora toolbox image provides QEMU, OVMF and Python (`vm:setup`).

`vm:boot` runs that container with /dev/kvm and boots the disk headless on a snapshot with a serial console and a monitor socket; a Python script waits for the serial login prompt, logs in as test, checks Btrfs on /sysroot, zram as the only swap and no NVIDIA or kmod driver packages, then types the test user's login into tuigreet through the QEMU monitor and saves a screendump of the session to output/screenshots/vm-session.png. `vm:run` boots it with a VNC display on localhost. Document every file inline.
```

## Outcome

`src/vm/` holds the boot test. `task vm:disk` copies the built image into root's container storage and runs bootc-image-builder, pinned by digest, to write `output/qcow2/disk.qcow2` with a Btrfs root and a throwaway `test` user, then hands the file back to the developer. `task vm:setup` builds a small container, from the pinned Fedora toolbox image, with QEMU, UEFI firmware (OVMF) and Python, so the host needs only podman and access to KVM.

`task vm:boot` boots the disk in that container on a snapshot, so the disk never changes, with a serial console and a QEMU monitor. A Python script waits for the login prompt on the serial console, logs in as `test`, and checks that the root is Btrfs and that zram is the only swap (the package checks stay in `task image:check`). It then types the same login into tuigreet on the graphical console through the monitor, waits on the serial console until Mango runs and the user's `stack-os-shell.service` is active, and only then saves a screenshot of the session to `output/screenshots/vm-session.png`. It fails at once if QEMU stops. `task vm:run` boots the same machine with a VNC display on `localhost:5900` for trying it by hand.

## Manual changes

None.

## Result

```
$ task vm:setup
Successfully tagged localhost/stack-os-vm:<key>
$ podman run --rm --device /dev/kvm localhost/stack-os-vm:<key> qemu-system-x86_64 --version
QEMU emulator version 10.2.2 (qemu-10.2.2-1.fc44)
```

`task vm:disk` needs sudo, so the disk, `task vm:boot` and its screenshot are run by the operator; their output belongs here once run. `task lint` passes.

Review: 15 fixed, 2 deferred (see Follow-ups). The fixes include waiting until Mango and the shell service run before the screenshot (a screenshot alone proved nothing), UEFI firmware loaded as flash with its own variable store, and failing at once when QEMU stops.

## Deviations

- The tasks are `vm:disk`, `vm:boot` and `vm:run`, all in one `vm` Taskfile, rather than the plan's `disk:qcow2` and `vm:run`.
- No screenshot yet: `task vm:boot` writes it, once the operator has built the disk.
- QEMU runs in a container instead of on the host, so the host needs only podman.
- The image now adds `console=ttyS0,115200n8 console=tty0` to the kernel command line (`/usr/lib/bootc/kargs.d/`), so a login prompt reaches the serial console the test uses; the screen stays the main console.

## Follow-ups

- Run `task vm:disk` and `task vm:boot`, and add their output and the session screenshot to this entry.
- Keep the image name in one place: `vm:disk` and `image:build` both spell `localhost/stack-os:latest`.
- Check that the session comes up at scale 1 in the VM (a virtual display reports no size).
