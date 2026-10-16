---
title: 8-Installer ISO
description: An interactive installer ISO built from the image, which installs Stack OS to a Btrfs root and can be tried in a virtual machine.
sidebar:
  order: 8
---

[001-08: installer ISO that installs to Btrfs](https://github.com/stackific/stack-os/commit/d966536359a22fbdfc0bd90f644706573db4566c)

## Goal

Make Stack OS installable: build an installer ISO from the image that asks for the language, the disk and the user account, installs the system with a Btrfs root, and boots to the login manager. A virtual machine with a blank disk tries it. This serves the milestone's "`task iso` writes an installer ISO to `output/`" and "the ISO installs in a UEFI VM and boots to the login manager" items.

## Context

Step 001-07 turned the image into a virtual machine disk with bootc-image-builder and booted it in QEMU. Earlier decisions this step implements:

- **The ISO comes from bootc-image-builder too**, as an Anaconda installer (Fedora's installer) with the image inside, so it installs offline. The root filesystem is Btrfs.
- **The install is interactive**: without a kickstart (Anaconda's answer file) the ISO would wipe the first disk unattended, so a minimal kickstart only selects the graphical installer.
- **Installs track the future registry image**, so `bootc upgrade` works once Stack OS is published; until then it fails.
- **A manually run build workflow** (`.github/workflows/build.yml`) runs `task iso` on a milestone branch and expects exactly one `output/*.iso`.

## Expectations

Must:

- `task iso` builds the image if needed and writes exactly one ISO, `output/stack-os.iso`, from `localhost/stack-os:latest` with bootc-image-builder (`--type anaconda-iso --rootfs btrfs`).
- The installer is interactive (language, disk, user), with Anaconda's subscription module off.
- `task vm:installer` boots the ISO in the VM container with a blank disk (`output/install/disk.qcow2`) and a VNC display, so the developer can install and then boot the installed disk.
- Installing in that VM ends at the login manager, on a Btrfs root.

Must not:

- wipe a disk without asking;
- push the ISO anywhere (the build workflow does that, on demand).

## Prompt

```text title="Prompt" wrap
Implement 001-08: the installer ISO that installs to Btrfs.

Add `vm:iso`: like `vm:disk`, but bootc-image-builder with `--type anaconda-iso --rootfs btrfs` and an iso.toml whose kickstart only says `graphical` (an interactive install) and which disables Anaconda's subscription module; the image's /etc/pki/rpm-gpg is mounted into the builder, as the installer reads the image's repository keys. It moves the result to output/stack-os.iso, the only ISO in output/, and hands output/ back to the developer. Add a root-level `task iso` that builds the image, then runs `vm:iso`, which is what the build workflow calls.

Add `vm:installer` (not `vm:install`, which every Taskfile keeps for checking its host tools): create a blank 40 GiB output/install/disk.qcow2 if missing and boot the ISO from a CD drive with that disk, UEFI and a VNC display, in the VM container; afterwards `vm:installer` with BOOT=disk boots the installed disk. Document every file inline.
```

## Outcome

`task iso` builds the image, then runs `vm:iso`, which copies it into root's container storage and has bootc-image-builder write an Anaconda installer ISO with the image inside and a Btrfs root. The image's repository keys are mounted into the builder, which runs on CentOS and lacks Fedora's. The result is moved to `output/stack-os.iso`, the only ISO in `output/`, which is what the on-demand build workflow renames and pushes. The installer is interactive: its kickstart selects the graphical installer, and Anaconda's Red Hat subscription screen is off. After installing, the kickstart points the system at `ghcr.io/stackific/stack-os:latest`, so `bootc upgrade` works once Stack OS is published (until then it fails).

`task vm:installer` boots that ISO in the VM container from a CD drive, with a blank 40 GiB disk in `output/install/` and a VNC display on `localhost:5900`; the disk and its UEFI variables persist there, so `task vm:installer BOOT=disk` then boots the installed system.

## Manual changes

None.

## Result

```
$ task --list
* iso:            Build the image and the installer ISO, output/stack-os.iso (uses sudo)
* vm:installer:   Install output/stack-os.iso into a blank VM disk over VNC (localhost:5900); BOOT=disk boots the result
* vm:iso:         Write output/stack-os.iso, an interactive installer, from the built image (uses sudo)
```

Building the ISO needs sudo, so `task iso`, the install in `task vm:installer` and its result are run by the operator; their output and a screenshot of the installed system's login belong here once run. `task lint` passes.

Review: 9 fixed, 2 deferred (see Follow-ups). The review caught that installs would have tracked the local build instead of the registry image.

## Deviations

- The VM install task is `vm:installer`, not the plan's `vm:install`: every Taskfile keeps `install` for checking its host tools.
- No screenshot yet: the install is interactive and needs the ISO, built with sudo.

## Follow-ups

- Run `task iso`, install it with `task vm:installer`, boot it with `BOOT=disk`, and add the output and a screenshot of the login here.
- Record the Btrfs subvolumes the installer creates, and set the storage choice in the kickstart if the installer ignores the Btrfs default (decision 01).
- Confirm the build workflow's `task iso` runs on GitHub's runner (rootless image build, then the ISO with sudo); it likely needs the proof of concept's disk clean-up and AppArmor steps and a newer runner.
