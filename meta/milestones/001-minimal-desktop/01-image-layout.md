# 01: Image layout

**Context.** M1 builds a Fedora 44 bootc image, x86_64 only: Mesa only, Btrfs root, zram swap, Mango from Fyra Labs' Terra repository (the only third-party repo), foot, greetd, and a Quickshell 0.3.x shell built from source. Everything runs through `task`: `image:build`, `image:check`, `disk:qcow2`, `iso`, and a `workflow_dispatch` Action that uploads the ISO as a run artifact. Nothing is published.

**Prior art.** References are copies without git metadata, so citations are unpinned.

- The proof of concept (`terra-fedora/`) works end to end:
  - three stages: a `fedora-bootc:44` builder running `bootc-base-imagectl build-rootfs --manifest=minimal`, then `FROM scratch` with that rootfs and one `go-task` RUN over a bind-mounted build context with a dnf cache mount (`Containerfile:14-32`);
  - `features/<name>/` with `packages` (`name | source | function`), a `Taskfile.yml` with `install` and `check`, and a `rootfs/` overlay; the order is explicit in `build/Taskfile.yml:56-90`; weak dependencies off (`build/bin/dnf-install:1-6`);
  - `finalize`: dracut with `hostonly=no`, `/var`, `/tmp` and `/run` emptied, `bootc container lint --fatal-warnings` (`build/Taskfile.yml:127-151`);
  - `image:check` runs every feature's `check` inside the built image (`taskfiles/image.yml:31-41`);
  - zram from `zram-generator-defaults`, plus `HOME=/var/home` in `/etc/default/useradd` and `semodule -B` so homes on the minimal base get the right SELinux labels (`features/system/Taskfile.yml:12-29`);
  - Terra added with `terra-release` via `--repofrompath` (`features/repos/Taskfile.yml:6-16`), left enabled;
  - a compile stage `FROM base` whose RPM alone reaches the final image (`Containerfile:34-48`, the NVIDIA module);
  - qcow2 and ISO from bootc-image-builder with `--rootfs btrfs` and an interactive `graphical` kickstart (`taskfiles/disk.yml:24-42`, `disk/iso.toml:1-11`); the Action runs on `ubuntu-26.04`, frees disk, unloads AppArmor (`.github/workflows/build.yml:7-100`).
- Bluefin and Bazzite disable every third-party repo at the end of the build and fail the build if one is left enabled (`bluefin/build_files/base/17-cleanup.sh:41-65`, `bluefin/build_files/shared/validate-repos.sh:1-121`, `bazzite/Containerfile:490-509`). Bluefin builds on Fedora's images pinned by digest rather than ublue `*-main` (`bluefin/THEPATTERN.md:17,34-38`).
- bootc reads the default root filesystem from `/usr/lib/bootc/install/*.toml` (`bootc/docs/src/man/bootc-install-config.5.md:7-20,56-66`); Fedora bootc images set none. With `/usr/lib/repart.d/*.conf` present, `bootc install` partitions with systemd-repart, which can declare Btrfs subvolumes and compression (`bootc/docs/src/bootc-installation.7.md:471-577`); Readymade does this with `/` and `/home` subvolumes and `compress=zstd:1` (`readymade/crates/libreadymade/templates/bootcwholedisk/50-root.conf:1-9`), Bazzite's Anaconda profile likewise.
- `bootc container lint` flags users without a sysusers.d entry and `/var` content without tmpfiles.d (`bootc/crates/lib/src/lints.rs:710-724,740-769`); static config belongs in `/usr`, `/etc` is merged three ways (`bootc/docs/src/building/bootc-building-images.7.md:124-162`).
- Pinning: Bluefin pins upstream images by digest in `image-versions.yml` and fails without one, pins Actions by commit, and bumps both with Renovate (`bluefin/image-versions.yml:1-21`, `bluefin/AGENTS.md:286-305`, `bluefin/.github/renovate.json5:1-84`); Bluefin and Bazzite lock only the kernel, Qt and Mesa with `dnf5 versionlock` and clear it at the end (`bazzite/Containerfile:117-131`, `bluefin/build_files/shared/clean-stage.sh:9`); ublue keeps prebuilt RPMs in OCI images so no mirror can drop them (`bluefin/build_files/base/03-install-kernel-akmods.sh:18-34`); the proof of concept pins nothing but fetches an exact kernel from `updates-archive` (`terra-fedora/features/nvidia/Taskfile.yml:26-28`). No reference locks the whole package set. Upstream `bootc-base-imagectl build-rootfs` takes `--lock NEVRA`, passed to rpm-ostree as a lockfile; `updates-archive` keeps every Fedora update that reached stable (checked: it still serves `qt6-qtbase` 6.10.3 and 6.11.1).
- Without a registry, `bootc switch --transport containers-storage` points a system at a local image (`bootc/docs/src/bootc-local-builds.7.md:28-91`); image-template re-points the origin in kickstart `%post` (`image-template/disk_config/iso-gnome.toml:1-6`).

| Choice | Options | Winner |
|---|---|---|
| Base | `fedora-bootc:44` standard; minimal via `build-rootfs`; ublue `*-main` | minimal: proven here, nothing unused, no other desktop's opinions |
| Structure | feature folders + Taskfiles; numbered scripts; one long Containerfile; BlueBuild | feature folders: fits `task`, explicit order, per-feature checks |
| Third-party repo | left enabled; disabled with a check | disabled, checked by `image:check` |
| Btrfs default | builder flag only; bootc install config + flag; Anaconda profile | bootc install config + flag |
| Rechunking | chunkah now; later | later: it only speeds up update downloads |

**Decision.**

- Fedora 44, with every input pinned; nothing changes until a deliberate bump:
  - base images by digest in one `versions.yml`; the build fails if a digest is missing;
  - every RPM, Fedora and Terra, at an exact version in two committed lock files written by `task lock` from the built image's `rpm -qa`: `rootfs.lock` (what the minimal rootfs contains) and `image.lock` (the final image). When a package is first added, the latest version in the Fedora 44 or Terra repositories is taken and locked; bumps repeat that on purpose;
  - the rootfs is built with `build-rootfs --lock` for every entry of `rootfs.lock`; feature installs run under `dnf5 versionlock` for every entry of `image.lock`, cleared in `finalize`;
  - Fedora's `updates-archive` repository is enabled in every build stage, so locked versions stay downloadable after `updates` moves on;
  - `image:check` diffs the image's `rpm -qa` against `image.lock` and fails on any difference;
  - Quickshell at a tag and commit; GitHub Actions by commit hash; bootc-image-builder by digest; go-task by version; the runner named exactly.
- `Containerfile`, three stages:
  1. `rootfs`: `fedora-bootc:44` (by digest) running `bootc-base-imagectl build-rootfs --manifest=minimal /target-rootfs`. This image is only the tool that assembles the root filesystem;
  2. `minimal`: `FROM scratch`, `COPY --from=rootfs /target-rootfs/ /`: the minimal system the image and the Quickshell build start from;
  3. `image`: `FROM minimal`, one `go-task` RUN over the bind-mounted `build/` and `features/` with a dnf cache mount, installing the Quickshell RPM from `output/rpms/`, then `finalize`. The image build never compiles.
- Quickshell is built outside the image build by `task quickshell:rpm`, inside a container from the `minimal` stage with the locked Qt `-devel` and `-private-devel` packages and build tools, so it compiles against exactly the Qt the image ships and the compilers never reach the image. It writes `output/rpms/quickshell-<key>.rpm`, where `<key>` hashes the Quickshell tag and commit, the Qt and build-dependency entries of `image.lock`, and the recipe; it does nothing if that file exists. A ccache directory kept between builds speeds up real rebuilds. The GitHub Action restores `output/rpms/` and the ccache with `actions/cache` under the same key. The dev toolbox installs the same RPM. The image build's layer cache is not relied on: podman's cache key ignores bind-mounted files, and CI runners start empty.
- One folder per feature, `features/<name>/`: `packages`, `Taskfile.yml` (`install`, `check`), `rootfs/`. `build/Taskfile.yml` lists the order. Weak dependencies off.
- `finalize`: dracut (`--no-hostonly`), empty `/var`, `/tmp` and `/run`, `bootc container lint --fatal-warnings`.
- Config placement: static defaults under `/usr` (`/usr/lib/systemd`, sysusers.d, tmpfiles.d, `/usr/share/stack-os`); `/etc` only where a program reads nowhere else (greetd, Mango); `/var` filled by tmpfiles.d and first-boot units; SELinux contexts with `semanage fcontext` at build time.
- Names: `stack-os` for every system path and unit (`/usr/share/stack-os/`, `/etc/stack-os/`, `/var/lib/stack-os/`, `stack-os-shell.service`), as Fedora names a package's files after the package; the bare `stack` is only the user command, since it is a common name (Haskell's build tool) that could clash as a namespace.
- Terra: installed through `terra-release`; `mangowm` installed from it; Terra disabled at the end of the build; `image:check` fails if any third-party repo is enabled.
- Btrfs: `/usr/lib/bootc/install/00-stack-os.toml` sets `type = "btrfs"`; `btrfs-progs` in the image; bootc-image-builder keeps `--rootfs btrfs`.
- zram: `zram-generator-defaults`, with the proof of concept's `HOME` and SELinux fix.
- No rechunking, signing or registry push in M1.
- Update source: installs set their origin to the future registry ref (`ghcr.io/stackific/stack-os:latest`); `bootc upgrade` fails until it is published.
- Btrfs layout: M1 takes whatever subvolumes the ISO installer creates and records them in the ISO step; `/` and `/home` subvolumes with `zstd:1` come later. If the interactive installer ignores the Btrfs default, the ISO's kickstart sets the storage choice and the rest stays interactive.
- One `go-task` RUN for all features in M1; build times are measured in step 4 before splitting package installs into an earlier cached step.
- GitHub Action: runs on GitHub's `ubuntu-26.04` runner, the newest available (GitHub hosts no Fedora runners). The host only provides podman; every build step runs inside the pinned Fedora containers.

**Consequences.**

- A config-only change still reruns every feature, since there is one RUN.
- Pinning means security updates arrive only when Stack OS bumps the locks; a scheduled `lock:bump` (weekly, and on demand for security fixes) and Renovate for digests and Actions are Follow-ups that must land before anything is published.
- Unverified: that Fedora 44's `bootc-base-imagectl` already has `--lock` (it is in upstream source), how long `updates-archive` is kept after Fedora 44's end of life, and how long Terra keeps old builds. Storing Terra's RPMs and the Quickshell RPM in an OCI image on GHCR removes the last two risks later.
- Quickshell and Qt are pinned together: bumping Qt changes the key and rebuilds the Quickshell RPM once; `image:check` asserts the installed Qt equals the one it was built against.
- The minimal manifest is not a stable interface and may change upstream.
- Whether the interactive ISO installer honours the Btrfs default is unverified; the ISO step tests it. Subvolumes and compression via `/usr/lib/repart.d/` apply only to `bootc install`, not to the ISO's installer.
- Installed M1 systems cannot update until the image is published.
