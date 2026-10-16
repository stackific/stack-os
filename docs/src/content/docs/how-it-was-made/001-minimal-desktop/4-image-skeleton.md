---
title: 4-Image skeleton
description: The Stack OS bootc image builds locally from the minimal Fedora base, with the shell, Mango and zram swap, and checks itself.
sidebar:
  order: 4
---

001-04: image skeleton

## Goal

Produce the first Stack OS bootc container image: a Fedora 44 bootc image built locally from the minimal base, carrying Mango, foot, the Quickshell RPM, the Stack OS shell and its lock PAM file, with zram swap and Btrfs as the install default, and a check that asserts all of that inside the built image. This serves the milestone's "`task image:build` builds the image locally and `bootc container lint` passes", "swap is zram" and "no GPU driver beyond Mesa" items, checked in the image.

## Context

Steps 001-01 to 001-03 built the shell and its development loop: the pinned Quickshell RPM in `output/rpms/`, the bar, the power menu and the lock. Earlier decisions this step implements:

- **The image starts from Fedora's minimal bootc manifest**: Fedora's `fedora-bootc:44` image, pinned by digest, only assembles a minimal root filesystem; the Stack OS image starts from that, not from the full Fedora bootc image.
- **One folder per feature**, each with a `packages` list and a Taskfile with `install` and `check`; a build Taskfile runs them in order, inside the image build. Weak dependencies are never installed.
- **The image build never compiles**: it installs the Quickshell RPM built earlier.
- **Mango comes from Terra**, Fyra Labs' Fedora repository, which is disabled again at the end of the build.
- **Btrfs is the install default** and **swap is zram**.
- **Static defaults live under `/usr`**: the shell under `/usr/share/stack-os/shell`, the lock's PAM file under `/usr/share/stack-os/pam`.
- **The last build step** rebuilds the initramfs, empties `/var`, `/tmp` and `/run`, and runs `bootc container lint`.

## Expectations

Must:

- `versions.yml` pins `fedora-bootc:44` by digest.
- `task image:build` builds `localhost/stack-os:latest` from `src/image/Containerfile` in three stages (rootfs tool, minimal system, image), and `bootc container lint --fatal-warnings` passes inside the build.
- Features live in `src/image/features/<name>/` with `packages` and a Taskfile (`install`, `check`); `src/image/build/Taskfile.yml` runs them in order.
- The image installs the Quickshell RPM from `output/rpms/` and compiles nothing.
- `task image:check` runs every feature's `check` inside the built image and passes: Mango, foot and Quickshell 0.3.2 installed; the shell under `/usr/share/stack-os/shell` and the PAM file under `/usr/share/stack-os/pam`; zram configured; Btrfs the install default; no third-party repository enabled; no GPU driver beyond Mesa.

Must not:

- compile anything in the image build;
- leave Terra enabled;
- add the login manager (next step), lock files, signing or a registry push.

## Prompt

```text title="Prompt" wrap
Implement 001-04: the Stack OS image skeleton.

Pin quay.io/fedora/fedora-bootc:44 by digest in versions.yml. Add src/image/ with its own Taskfile (included from the root as `image`): a three-stage Containerfile (rootfs: fedora-bootc running `bootc-base-imagectl build-rootfs --manifest=minimal`; minimal: FROM scratch with that rootfs; image: FROM minimal, Fedora's go-task installed, then one go-task RUN over the bind-mounted src/image and output/rpms with a dnf cache mount, then finalize), and the bootc labels.

Features under src/image/features/<name>/, each with a `packages` list (name | source | function) and a Taskfile with install and check, run in order by src/image/build/Taskfile.yml: system (zram-generator-defaults, btrfs-progs and the Btrfs install default in /usr/lib/bootc/install/00-stack-os.toml, homes under /var/home), repos (terra-release and Fedora's updates-archive), desktop (mangowm, foot, a font and Mesa), shell (the Quickshell RPM from output/rpms, the shell QML to /usr/share/stack-os/shell, the lock's PAM file to /usr/share/stack-os/pam). Weak dependencies off. finalize disables Terra, rebuilds the initramfs, empties /var, /tmp and /run, and runs `bootc container lint --fatal-warnings`.

`task image:build` builds localhost/stack-os:latest (after `task quickshell:rpm`); `task image:check` runs every feature's check inside the built image, including that no third-party repo is enabled and no GPU driver beyond Mesa is installed. No login manager, lock files, signing or push yet. Document every file inline.
```

## Outcome

The image is now described in `src/image/`, built by `task image:build` and checked by `task image:check`. Its Containerfile has three stages: Fedora's bootc image, pinned by digest, only assembles the minimal root filesystem; the image starts from that root filesystem alone; and one Task run inside the build installs four features in order, then finalizes.

- `repos`: Fedora's updates-archive, so pinned versions stay installable, and Terra for Mango.
- `system`: zram swap, Btrfs as the install default (`/usr/lib/bootc/install/00-stack-os.toml`), account tools, and homes under `/var/home` with their SELinux labels fixed.
- `desktop`: Mango, foot, fonts and Mesa, the only graphics driver.
- `shell`: the Quickshell RPM from `output/rpms/` (nothing is compiled in the build), the shell's QML under `/usr/share/stack-os/shell` and the lock's PAM file under `/usr/share/stack-os/pam`.

`finalize` turns Terra off, rebuilds the initramfs, empties `/var`, `/tmp` and `/run`, and runs `bootc container lint --fatal-warnings`. Each feature's `check` asserts its result inside the built image, including that only Fedora's repositories are enabled and that no GPU driver beyond Mesa is installed.

The image has no screen of its own yet: it gets one when it boots in a virtual machine (001-07), so this step has no screenshot.

## Manual changes

None.

## Result

```
$ task image:build
...
Checks passed: 14                     # bootc container lint --fatal-warnings
Successfully tagged localhost/stack-os:latest

$ task image:check                    # every feature's check, inside the image
(exit 0)
```

The first build took about six minutes; with dnf's cache warm, a rebuild takes about two. The build runs as the developer's own user (rootless podman). `task lint` passes.

Review: 15 fixed, 6 deferred (see Deviations and Follow-ups), 1 not changed: a reviewer expected the minimal root filesystem to need a root (sudo) build, but the rootless build works.

## Deviations

- No screenshot: the image has no screen until it boots in a virtual machine (001-07).
- The lock files of decision 01 (`rootfs.lock`, `image.lock`, versionlock during the build, `image:check` comparing against them, and Fedora's `go-task` at a pinned version) are not part of this step; they get their own step, 001-09.
- The Quickshell RPM is still built in the development toolbox image rather than the image's `minimal` stage.
- Fedora's `go-task` stays installed in the image, since the build runs on it.

## Follow-ups

- Build the Quickshell RPM in the image's `minimal` stage with its locked Qt, and add those Qt versions to the RPM's key.
- Split the package installs into an earlier cached step if build times grow.
- The dnf install options are repeated in three places, and the Quickshell RPM's file name is built in two; keep each in one place.
- Decide whether `go-task` stays in the shipped image.
- The Quickshell RPM pins only `qt6-qtbase` and `qt6-qtdeclarative`; its other Qt dependencies follow Fedora until the lock files land.
