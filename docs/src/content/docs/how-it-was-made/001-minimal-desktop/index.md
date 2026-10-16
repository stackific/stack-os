---
title: 1-Minimal desktop
description: The smallest Stack OS that proves the image.
sidebar:
  order: 0
  label: Overview
---

The smallest Stack OS that proves the image: an installer ISO that installs a Fedora bootc system, logs in, and starts the Mango compositor with a bar that opens a terminal and powers the machine off.

**In scope:** Fedora 44 bootc from the minimal base, x86_64 only, Mesa graphics only, a Btrfs root, swap on zram, Mango, a Quickshell bar of Stack OS's own, the foot terminal, a login manager, monitor scale picked from each screen's physical size and a local build command for the ISO.

**Out of scope:** publishing the image or ISO, updates, theming, the `stack` command.

**Done when:**

- the shell runs in a nested Mango window from the repository, reloading on every edit;
- the image builds locally and passes `bootc container lint`;
- the ISO builds locally;
- the ISO installs in a UEFI virtual machine and boots to the login;
- logging in starts Mango with a bar of two icons: a terminal, and a power menu with Lock, Log out, Restart and Shut down;
- the root filesystem is Btrfs, swap is zram, and no GPU driver beyond Mesa is installed;
- each monitor starts at the scale its physical size calls for.
