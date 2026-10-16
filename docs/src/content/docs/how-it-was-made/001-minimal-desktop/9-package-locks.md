---
title: 9-Package locks
description: Every RPM in the image is locked to an exact version in two committed lock files, and the image check fails on any difference.
sidebar:
  order: 9
---

001-09: lock every package

## Goal

Make the image reproducible: every RPM in it, from Fedora and from Terra, is locked to an exact version in files committed to the repository, the build installs exactly those versions, and the image check fails if the built image differs. Nothing changes until someone deliberately updates the locks. This finishes what step 001-04 left out of the image decision.

## Context

Step 001-04 built the image from Fedora's minimal bootc manifest with four, later six, features, but every package came at whatever version Fedora's repositories held that day. Earlier decisions this step implements:

- **Every RPM is locked** in two committed files, written from the built image's package list by `task image:lock`: `rootfs.lock`, what the minimal root filesystem contains, and `image.lock`, the final image. A package added later is locked at the version current when it is added; updates repeat that on purpose.
- **The root filesystem is assembled with every entry of `rootfs.lock`** (`build-rootfs --lock`), and the feature installs run under dnf's versionlock for every entry of `image.lock`, cleared at the end of the build.
- **Fedora's updates-archive is enabled in every build stage**, so locked versions stay downloadable after Fedora's `updates` repository moves on.
- **The image check compares the image's packages with `image.lock`** and fails on any difference.
- **Fedora's `go-task`**, which runs the build, is installed at its locked version, and **Terra's release package**, which carries Terra's signing key, comes from a pinned URL whose checksum is verified, instead of being installed without any check.

## Expectations

Must:

- `task image:lock` writes `src/image/rootfs.lock` and `src/image/image.lock` (one `name-epoch:version-release.arch` per line, sorted) from the built image.
- The build uses them when present: `build-rootfs --lock` for every `rootfs.lock` entry with only Fedora's `fedora`, `updates` and `updates-archive` repositories, `dnf versionlock` for every `image.lock` entry during the feature installs (cleared in `finalize`), and `go-task` at its locked version.
- `versions.yml` pins the `terra-release` RPM by URL and sha256, and the build refuses a file that does not match.
- `task image:check` fails if the image's packages differ from `image.lock` in any way.
- A build with the lock files reproduces `image.lock` exactly (`task image:check` passes).

Must not:

- install `terra-release` without a checksum check;
- lock packages by hand: the files are written by `task image:lock` only.

## Prompt

```text title="Prompt" wrap
Implement 001-09: lock every package (decision 01).

Add `task image:lock`: it writes src/image/rootfs.lock (from the Containerfile's minimal stage) and src/image/image.lock (from the built image), each one `name-epoch:version-release.arch` per line, sorted, without gpg-pubkey entries. When present, the build uses them: the rootfs stage installs fedora-repos-archive and runs build-rootfs with `--repo fedora --repo updates --repo updates-archive` and `--lock` for every rootfs.lock entry; the image stage installs go-task at its locked version and runs `dnf versionlock add` for every image.lock entry before the features, and finalize clears the versionlock. Without lock files the build runs unlocked, so the first locks can be written.

Pin the terra-release RPM in versions.yml by URL and sha256; the repos feature downloads it, checks the sum and installs the local file. `task image:check` compares `rpm -qa` with image.lock and fails on any difference. Generate the lock files, rebuild with them, and show that the check passes. Document every file inline.
```

## Outcome

The image is now built from two committed lock files. `task image:lock` writes them from a built image: `src/image/rootfs.lock` (240 packages, the minimal root filesystem) and `src/image/image.lock` (438 packages, the final image), one `name-epoch:version-release.arch` per line. When they exist, the root filesystem is assembled with every `rootfs.lock` entry, from Fedora's `fedora`, `updates` and `updates-archive` repositories only; the image stage installs `go-task` at its locked version; and once the repositories are set up, every other `image.lock` entry is held by dnf's versionlock (with updates-archive enabled, and failing the build if any entry is not found) while the features install, until `finalize` clears it. The local Quickshell RPM is pinned by its own key instead. `task image:check` compares the image's packages with `image.lock` and fails on any difference. Without lock files the build runs unlocked, which is how the first ones are written; updating a package means rebuilding unlocked (or with the entry removed), running `task image:lock` and committing the result.

Terra's release package and the signing-key package it requires now come from URLs pinned in `versions.yml` and are installed only if their sha256 sums match, instead of being installed from Terra's repository without any check.

## Manual changes

None.

## Result

```
$ task image:build                    # no lock files yet: unlocked
Checks passed: 14
$ task image:lock
  240 src/image/rootfs.lock
  438 src/image/image.lock
$ task image:build                    # with the lock files
Adding versionlock on ...             # every entry but go-task and quickshell
Checks passed: 14
$ task image:check                    # includes the diff against image.lock
(exit 0)
```

A locked rebuild takes about six minutes. `task lint` passes.

Review: 9 fixed, 4 deferred (see Follow-ups). The review caught that dnf's versionlock silently skipped entries it could not find in an enabled repository: run before Terra was set up, it left Mango and Terra's packages unlocked. The lock now runs after the repositories are in place, with updates-archive enabled, and fails the build if any entry does not resolve.

## Deviations

- No screenshot: the step changes how packages are chosen, not anything on screen.
- Terra's signing keys come in a second package, `terra-gpg-keys`, which `terra-release` requires; it is pinned by URL and checksum as well.

## Follow-ups

- A task to update the locks on purpose (rebuild unlocked, rewrite, review the diff), and its place in the build workflow.
- Terra keeps no archive of old packages: a locked Terra version, or the pinned `terra-release` URL, can disappear when Terra publishes a newer one. Mirror the Terra RPMs the image locks, or fall back to re-locking.
- Build the Quickshell RPM against the locked Qt and add those versions to its key, so a new Fedora Qt cannot break a locked build in CI (also a follow-up of 001-04).
- Mount only the lock files into the rootfs stage, so editing a feature does not invalidate the cached root filesystem; and share one build invocation between `image:build` and `image:lock`.
- Sign the image and ship a container signature policy that `bootc switch` enforces, before installs track `ghcr.io/stackific/stack-os` (security review of 001-08).
