# Reference repositories

Third-party code to clone into `references/` (gitignored) and index with cocoindex-code. The goal is an Omarchy alternative on Fedora bootc: Mango, Quickshell, a plugin layer like Omarchy's, and wallpaper-derived colors across every app.

The list is organized by what Omarchy ships, from a scan of `references/omarchy-quattro` (530 `bin/` commands, 17 shell plugins, 20 theme templates, 23 themes, 41 hardware scripts, 14 docs, and `omarchy-pkgs` with about 200 PKGBUILDs). Each section names Omarchy's own implementation first, then the upstream projects to study or ship. "Fedora" notes whether a package exists in Fedora, RPM Fusion, or Terra, since the image installs RPMs.

Checked on 2026-10-16: none archived unless marked. Check each license before copying code; DankMaterialShell changed its license in late 2025, and the Omarchy apps are MIT unless noted.

## 1. The toolkit: Quickshell

| Repository | Why |
|---|---|
| https://github.com/quickshell-mirror/quickshell | The toolkit (C++, LGPL 3). `src/wayland/windowmanager/` is the ext-workspace client (June 2025): the basis of the workspace switcher. Canonical: https://git.outfoxxed.me/quickshell/quickshell |
| https://github.com/quickshell-mirror/quickshell-examples | Official examples (last push July 2025) |
| https://github.com/quickshell-mirror/quickshell-docs | Docs source, for the API of the version Fedora ships (0.2.1 git snapshot, February 2026) |
| https://github.com/KDAB/cxx-qt | Rust and Qt interop, if a QML module is ever written in Rust |

## 2. Shells built on Quickshell

| Repository | Why |
|---|---|
| https://github.com/omacom/omarchy | The target. `shell/` is the Quickshell plugin host: `plugins/{bar,dock,menu,panels,lock,notifications,osd,polkit,clipboard,emojis,image-picker,background,reminders,agents,services}`, `services/Plugin*Api.qml` (the capability facades third-party plugins get), `Commons/` and `Ui/` (the widget kit). `docs/omarchy-shell.md`, `menu.md`, `notifications.md`, `theming.md`, `update-process.md`, `cli-router.md`, `lifecycle-dispatch.md`, `file-layout.md` describe the architecture. Already cloned as `omarchy-quattro` |
| https://github.com/omacom/omarchy-plugin-marketplace and https://github.com/omacom/omarchy-plugin-registry | How plugins are listed, validated, and installed (`omarchy-plugin-*` commands) |
| https://github.com/omacom/omarchy-port-forward-plugin and https://github.com/omacom/omarchy-notification-center-plugin | Two real third-party plugins against the manifest API |
| https://github.com/AvengeMedia/DankMaterialShell | The closest existing thing to the plan, and it already supports MangoWC: Quickshell UI plus a Go daemon (`core/`), a plugin system with a JSON manifest (`quickshell/PLUGINS/`, ten example plugins), `Services/MangoService.qml` (native Mango JSON-socket IPC), `Services/CompositorService.qml`, `ThemeAutoService.qml`, `MatugenPreviewService.qml`, 26 matugen templates in `quickshell/matugen/configs/`, and a greeter mode |
| https://github.com/AvengeMedia/dank-qml-common | Their shared QML widgets |
| https://github.com/AvengeMedia/dank-greeter | greetd greeter in Go that follows the shell's theme |
| https://github.com/caelestia-dots/shell | Quickshell, Hyprland; generates its own schemes from the wallpaper |
| https://github.com/end-4/dots-hyprland | Quickshell, the most-starred (16k); Material You colors from the wallpaper |

## 3. Noctalia (what is being replaced)

| Repository | Why |
|---|---|
| https://github.com/noctalia-dev/noctalia | v5, C++. `assets/templates/` has 21 app templates with apply and undo hooks and `builtin.toml` describing them; its color engine turns a wallpaper into a Material palette with scheme variants |
| https://github.com/noctalia-dev/noctalia-greeter | greetd greeter with Auto-Sync of the user's colors |
| https://github.com/noctalia-dev/official-plugins and https://github.com/noctalia-dev/community-plugins | The Luau plugin API (`noctalia.d.luau`), a third design to compare with Omarchy's and DMS's |

## 4. Theming: wallpaper colors across apps

Omarchy: `themes/<name>/colors.toml` is the palette; `default/themed/*.tpl` renders 20 files from it (alacritty, btop, chromium, claude, fcitx5, foot, ghostty, gum, helix, hermes, hyprland, hyprland-preview-share-picker, keyboard RGB, kitty, neovim, obsidian, pi, shell, t3code, vscode); `bin/omarchy-theme-set` stages, renders, and retints running apps in two parallel groups (`docs/theming.md`). Theme switcher with previews, intro videos, per-theme icon sets and keyboard backlight. Our image: Noctalia's templates for btop, gtk3, gtk4, kitty, qt, starship, Mango, and the greeter; gaps are Flatpak apps, open GTK4 apps, Brave's pages, Celluloid's OSD, the cursor and icons, 16-color terminal programs, and the boot splash.

| Repository | Why |
|---|---|
| https://github.com/omacom/aether | Go. Omarchy's theming app: extracts colors from a wallpaper and writes a theme |
| https://github.com/omacom/omarchy-theme-registry and https://github.com/omacom/omarchy-theme-marketplace | Theme distribution |
| https://github.com/omacom/omarchy-theme-sync | Pushes the desktop palette into websites through CSS variables, the web-page half of "every app" |
| https://github.com/omacom/omarchy-chromium-bin (PKGBUILD) | Chromium with Omarchy's theming patches; the browser-chrome half |
| https://github.com/omacom/pixel.nvim | A Neovim colorscheme that adapts to the terminal palette: the 16-color route |
| https://github.com/InioX/matugen | Rust. Material You and base16 palettes from an image, template engine, JSON export. Fedora: yes |
| https://github.com/material-foundation/material-color-utilities | Google's reference algorithms (quantize, score, scheme variants, tonal palettes) |
| https://github.com/lassekongo83/adw-gtk3 | The GTK3 theme that reads libadwaita color names; in the image already |
| https://github.com/nix-community/stylix | Nix, not reusable directly; `modules/` is the most complete catalog of what can be themed |
| https://github.com/tinted-theming/schemes and https://github.com/tinted-theming/tinty | base16 and base24 schemes and manager; the template convention hundreds of apps support |
| https://github.com/catppuccin/whiskers | Template tool for ports; a second convention with wide app coverage |
| https://github.com/eylles/pywal16 | Maintained pywal fork; the escape sequences that recolor running terminals |
| https://github.com/ozwaldorf/lutgen-rs | Recolors images to a palette (icons, mismatched assets) |

## 5. Wallpaper, lock screen, boot splash, greeter

Omarchy: OWE (C) renders still, GIF, and video wallpapers with login intro videos and a lock-screen video feed; the lock is the shell's own plugin with fingerprint support; Plymouth has a themed splash per theme (`bin/omarchy-plymouth-*`); SDDM with a theme. Our image: Noctalia's wallpaper and lock, greetd with the Noctalia greeter, Fedora's stock Plymouth.

| Repository | Why |
|---|---|
| https://github.com/omacom/owe | The wallpaper engine (C) and `owe-lockfeed`; `docs/theming.md` describes the login intro handoff |
| https://github.com/LGFae/swww | Rust wallpaper daemon with transitions (last push October 2025). Fedora: yes |
| https://github.com/GhostNaN/mpvpaper | Video wallpapers on wlroots. Fedora: no, Terra: check |
| https://github.com/kennylevinsen/greetd | greetd (mirror of sr.ht); we already use it |
| https://gitlab.freedesktop.org/plymouth/plymouth | Boot splash; a themed Plymouth theme like Omarchy's `default/plymouth/` |

## 6. Compositor and workspaces

Omarchy: Hyprland with Lua config (`default/hypr/*.lua`, `workspace-modes.lua`), a titlebars plugin for floating workspaces, `uwsm` session management. Ours: Mango, which implements ext-workspace through wlroots and has `mmsg` plus a JSON socket.

| Repository | Why |
|---|---|
| https://github.com/mangowm/mango | Ours. `src/ext-protocol/ext-workspace.c`, `mmsg`, the socket IPC that DMS's `MangoService.qml` talks to |
| https://github.com/niri-wm/niri | Reference ext-workspace server and a clean IPC design |
| https://github.com/labwc/labwc | Another ext-workspace server; its integration docs list client bars |
| https://github.com/Alexays/Waybar, https://github.com/LBCrion/sfwbar, https://github.com/JakeStanger/ironbar | ext-workspace clients in C++, C, Rust |
| https://gitlab.freedesktop.org/wayland/wayland-protocols | The protocol text, `staging/ext-workspace/` |
| https://github.com/omacom/omarchy-hyprland-titlebars | What titlebars on floating windows look like when the compositor draws them (Hyprland-only, for ideas) |
| https://github.com/Vladimir-csp/uwsm | Session manager Omarchy uses; shows what a managed Wayland session sets up (environment, units, shutdown). We use greetd plus environment.d |

## 7. Launcher, menu, clipboard, emoji, OSD, notifications

Omarchy: all inside the shell (`shell/plugins/menu` driven by `default/omarchy/omarchy-menu.jsonc`, `clipboard`, `emojis`, `osd`, `notifications` as the freedesktop notification server, `image-picker`). Before 4.0 it used Walker, Mako, SwayOSD. Ours: Noctalia's launcher, clipboard, notifications, OSD; Emojify (Flatpak).

| Repository | Why |
|---|---|
| https://github.com/abenz1267/walker | The launcher Omarchy used before the shell took over; its providers (apps, files, clipboard, calc, web) are the feature list |
| https://github.com/sentriz/cliphist | Clipboard history daemon (Go). Fedora: yes |
| https://github.com/charmbracelet/gum | TUI prompts Omarchy scripts use everywhere (`omarchy-menu-select`, installers). Fedora: yes |

## 8. Capture: screenshots, recording, OCR, QR, webcam

Omarchy: `bin/omarchy-capture-*` (region, screenshot, recording with and without webcam, OCR, QR), `omasnap` for annotation, `omareel` for polished recordings, `monologue` for webcam, `v4l2-relayd` for virtual cameras. Ours: Noctalia's screenshot and recorders, gpu-screen-recorder with the wf-recorder fallback.

| Repository | Why |
|---|---|
| https://github.com/omacom/omasnap | Native Wayland screenshot and annotation overlay (C++, 565 stars); Hyprland-specific parts need replacing |
| https://github.com/jondkinney/tensaku | Another Wayland screenshot annotator Omarchy packages |
| https://github.com/Satty-org/Satty and https://github.com/jtheoof/swappy | Annotators that are compositor-neutral. Fedora: swappy yes, satty check |
| https://github.com/omacom/omareel | Screen recorder with synthetic cursor and auto zoom (C++) |
| https://github.com/omacom/monologue | Theme-synced webcam recorder (C++) |
| https://git.dec05eba.com/gpu-screen-recorder | What we ship (Terra) |
| https://github.com/SeaDve/Kooha | GTK4 recorder through the portal, compositor-neutral. Fedora: yes |
| https://github.com/tesseract-ocr/tesseract and https://github.com/mchehab/zbar | OCR and QR decoding behind `capture-text` and `capture-qr`. Fedora: yes |
| https://gitlab.com/vicamo/v4l2-relayd | Virtual webcam feed (with `v4l2loopback`, one of the Omarchy choices still open) |
| https://github.com/hyprwm/hyprpicker | Color picker; wlroots-compatible despite the name. Fedora: check |

## 9. Audio, network, bluetooth, power, brightness, night light

Omarchy: panels in `shell/plugins/panels/{audio,bluetooth,network,power,wifiqr,speedtest,...}`, `bin/omarchy-audio-*`, `-network-*`, `-brightness-*`, `-powerprofiles-*`, speaker tunings as PipeWire filter chains (`default/audio/tunings`, `docs/audio-tuning.md`), `hyprsunset` for night light, `omarchy-power-profiles-daemon` fork. Ours: Noctalia's control center, power-profiles-daemon, NetworkManager.

| Repository | Why |
|---|---|
| https://github.com/omacom/omarchy-audio-tuner | Builds the speaker tuning profiles |
| https://github.com/lsp-plugins/lsp-plugins | The LV2 plugins the tunings run on. Fedora: yes |
| https://github.com/saivert/pwvucontrol | PipeWire mixer (GTK4, Rust). Fedora: yes |
| https://github.com/tsowell/wiremix, https://github.com/pythops/bluetui, https://github.com/pythops/impala | TUIs for audio, bluetooth, wifi that Omarchy launches from the menu |
| https://github.com/hyprwm/hyprsunset | Night light (Hyprland-only). For Mango: `wlsunset` (https://sr.ht/~kennylevinsen/wlsunset) or `gammastep`. Fedora: both yes |

## 10. Apps: Omarchy's own and the ones it installs

Omarchy writes small Qt Quick apps rather than shipping GNOME ones. All are QML plus C++, themed by the same palette, and are the clearest examples of apps built for a Quickshell desktop. Our image uses Thunar, Loupe, Celluloid, kitty, GNOME Software.

| Repository | Why |
|---|---|
| https://github.com/omacom/omawrite | Markdown writing app (267 stars) |
| https://github.com/omacom/hype and https://github.com/jethrojones/omapresent | Markdown presentations |
| https://github.com/omacom-io/omacalc | Calculator |
| https://github.com/omacom/omacut | Video trimmer on ffmpeg |
| https://github.com/omacom/signed | PDF signing |
| https://github.com/gabamnml/omakeyboard | Keyboard remapping and shortcuts UI |
| https://github.com/tcballard/omarchy-task-manager | Floating task manager |
| https://github.com/lgse/strata and https://github.com/thisisgm/flea | Keyboard-first file managers built for Omarchy |
| https://github.com/jorgemanrubia/omacharts, https://github.com/fredimachado/omairc, https://github.com/michaelmonetized/omadesign | More community Qt Quick apps in the same style |
| https://github.com/tobi/disktree | Disk space treemap |
| https://github.com/bjarneo/cliamp | Terminal music player |
| https://github.com/localsend/localsend | AirDrop-style sharing behind `omarchy-menu-share`. Fedora: Flathub |
| https://github.com/omacom/gliff | Remote desktop over SSH with GPU H.264 (Rust); Hyprland-specific capture |

Web apps: Omarchy turns URLs into desktop entries run by Chromium in app mode (`bin/omarchy-webapp-*`, `omarchy-launch-or-focus-webapp`). Brave supports the same `--app=` flag; Web App Manager is in `meta/future.md`. TUIs get desktop entries the same way (`omarchy-tui-*`).

## 11. Terminal and developer workflow

Omarchy: a prebuilt LazyVim (`omarchy-nvim`), tmux and the `herdr` agent workspace, mise for toolchains, `try` for scratch directories, `ttfx` for terminal effects, starship, zoxide, fzf, eza, bat, fd, ripgrep, lazygit, lazydocker, Docker. Ours: bash with ble.sh and Starship; pnpm; the rest is in `meta/future.md` or quarantine.

| Repository | Why |
|---|---|
| https://github.com/LazyVim/LazyVim | What `omarchy-nvim` packages with cached plugins |
| https://github.com/herdrdev/herdr | Terminal workspace manager for coding agents (Rust) |
| https://github.com/jdx/mise | Toolchain manager that replaces fnm, uv, and friends in one tool. Fedora: no, Terra: check |
| https://github.com/tobi/try | Scratch directories |
| https://github.com/omacom/ttfx | Terminal text effects (Rust) |

## 12. Dictation, text-to-speech, AI agents

Omarchy: `bin/omarchy-dictation-*` (voxtype local, Superwhisper), `bin/omarchy-agent-*` (Claude, Codex, Grok account switching and usage), `omaspeak`, `omawake`, and `shell/plugins/agents`. Whether any of this belongs in Stack is an open decision.

| Repository | Why |
|---|---|
| https://voxtype.io (binary) and https://github.com/ggml-org/whisper.cpp | Local push-to-talk dictation and the engine under it |
| https://github.com/jacob-vincent-mink/omaspeak and https://github.com/jacob-vincent-mink/omawake | Local text-to-speech and wake word |
| https://github.com/AltanS/collie | Phone UI for terminal agents |

## 13. Input methods, keyboard, fonts, locale

Omarchy: fcitx5 with a themed candidate window, `default/input-methods/*.py`, `bin/omarchy-setup-input`, `-setup-keyboard`, `-font-*`, `-font-cjk`, `docs/input-methods.md`. Ours: fontconfig only; no input method framework.

| Repository | Why |
|---|---|
| https://github.com/fcitx/fcitx5 and https://github.com/fcitx/fcitx5-configtool | The input method framework. Fedora: yes |

## 14. Hardware support and quirks

Omarchy: `install/hardware/*.sh` and `bin/omarchy-hw-*` (41 scripts: Apple Silicon, ASUS, Dell XPS, Framework, Surface, Tuxedo, NVIDIA with and without GSP, hybrid GPU, fingerprint, touchpad, touchscreen, Elgato, Intel PTL), speaker firmware packages, DKMS drivers, `linux-omarchy` kernel with the BORE scheduler. Ours: `features/hardware` and `features/quirks` carry the Omarchy-derived udev, libinput, and sleep hooks that fit our rules.

| Repository | Why |
|---|---|
| https://github.com/omacom/omarchy-mac and https://github.com/omacom/linux-aurora | Apple Silicon support (out of scope, but the deferral model in `docs/lifecycle-dispatch.md` is the pattern for per-model work on a shared image) |
| https://github.com/omacom/omarchy-power-profiles-daemon | Their fork; shows what they changed |

## 15. Install, update, rollback, factory reset

Omarchy: `omarchy-iso` builds the live ISO; `omarchy-pkgs` builds and signs its package repo (`bin/` has release, promote, sign, mirror); `docs/update-process.md` describes the update pipeline with migrations, restart markers, and a pacman guard; snapper plus Limine for bootable snapshots; `omarchy-system-factory-reset`. Ours: bootc images from CI, `terra update` and `rollback`, the `stack` command spec in `STACK-CLI.md`.

| Repository | Why |
|---|---|
| https://github.com/omacom/omarchy-iso | Their live ISO build (archiso) |
| https://github.com/omacom/omarchy-pkgs | Package build and release pipeline; `pkgbuilds/` is the full catalog of what they package |
| https://github.com/omacom/omarchy-mirror | How they mirror Arch's repos for reliability |
| https://github.com/ublue-os/image-template | The standard custom bootc image: Justfile, cosign signing, ISO output |
| https://github.com/ublue-os/bluefin and https://github.com/ublue-os/bazzite | Production bootc desktops; update tooling, `ujust` commands, hardware quirks |
| https://github.com/bootc-dev/bootc | bootc itself |
| https://github.com/osbuild/bootc-image-builder | Disk and ISO builder |
| https://github.com/CentOS/centos-bootc | The base-image manifests `bootc-base-imagectl` uses |
| https://github.com/FyraLabs/readymade and https://github.com/FyraLabs/katsu | Installer and live-ISO builder, for a live desktop before install |

## 16. Testing

Omarchy: `test/shell.d/*.sh` runs the shell's pure JavaScript models under Node without a compositor (`MenuModel.js`, `NotificationLogic.js`, `elsewhen`), `test/acceptance.d/` runs in a disposable VM, `docs/testing.md`. Worth copying: keep plugin logic in plain JS files that Node can load, so tests need no display.

## Clone

```sh
mkdir -p references && cd references
clone() { git clone -q --depth 1 "$1" "${1##*/}" 2>/dev/null || echo "skip $1"; }
for r in \
  quickshell-mirror/quickshell quickshell-mirror/quickshell-examples quickshell-mirror/quickshell-docs KDAB/cxx-qt \
  omacom/omarchy-plugin-marketplace omacom/omarchy-plugin-registry omacom/omarchy-port-forward-plugin omacom/omarchy-notification-center-plugin \
  AvengeMedia/DankMaterialShell AvengeMedia/dank-qml-common AvengeMedia/dank-greeter caelestia-dots/shell end-4/dots-hyprland \
  noctalia-dev/noctalia noctalia-dev/noctalia-greeter noctalia-dev/official-plugins noctalia-dev/community-plugins \
  omacom/aether omacom/omarchy-theme-registry omacom/omarchy-theme-sync omacom/pixel.nvim \
  InioX/matugen material-foundation/material-color-utilities lassekongo83/adw-gtk3 nix-community/stylix \
  tinted-theming/schemes tinted-theming/tinty catppuccin/whiskers eylles/pywal16 ozwaldorf/lutgen-rs \
  omacom/owe LGFae/swww GhostNaN/mpvpaper kennylevinsen/greetd \
  mangowm/mango niri-wm/niri labwc/labwc Alexays/Waybar LBCrion/sfwbar JakeStanger/ironbar omacom/omarchy-hyprland-titlebars Vladimir-csp/uwsm \
  abenz1267/walker sentriz/cliphist charmbracelet/gum \
  omacom/omasnap jondkinney/tensaku Satty-org/Satty jtheoof/swappy omacom/omareel omacom/monologue SeaDve/Kooha tesseract-ocr/tesseract mchehab/zbar hyprwm/hyprpicker \
  omacom/omarchy-audio-tuner lsp-plugins/lsp-plugins saivert/pwvucontrol tsowell/wiremix pythops/bluetui pythops/impala hyprwm/hyprsunset \
  omacom/omawrite omacom/hype jethrojones/omapresent omacom-io/omacalc omacom/omacut omacom/signed gabamnml/omakeyboard tcballard/omarchy-task-manager \
  lgse/strata thisisgm/flea jorgemanrubia/omacharts fredimachado/omairc michaelmonetized/omadesign tobi/disktree bjarneo/cliamp localsend/localsend omacom/gliff \
  LazyVim/LazyVim herdrdev/herdr jdx/mise tobi/try omacom/ttfx \
  ggml-org/whisper.cpp jacob-vincent-mink/omaspeak jacob-vincent-mink/omawake AltanS/collie \
  fcitx/fcitx5 fcitx/fcitx5-configtool \
  omacom/omarchy-mac omacom/linux-aurora omacom/omarchy-power-profiles-daemon \
  omacom/omarchy-iso omacom/omarchy-pkgs omacom/omarchy-mirror \
  ublue-os/image-template ublue-os/bluefin ublue-os/bazzite bootc-dev/bootc osbuild/bootc-image-builder CentOS/centos-bootc FyraLabs/readymade FyraLabs/katsu; do
  clone "https://github.com/$r"
done
clone https://gitlab.freedesktop.org/wayland/wayland-protocols
clone https://gitlab.freedesktop.org/plymouth/plymouth
clone https://gitlab.com/vicamo/v4l2-relayd
clone https://git.dec05eba.com/gpu-screen-recorder
clone https://git.sr.ht/~kennylevinsen/wlsunset
```

`omacom/omarchy` itself is already present as `omarchy-quattro`. `linux-aurora` is a kernel tree (large); drop it from the loop if disk matters.

The clones are read-only snapshots, so drop their `.git` folders: it halves the disk use and keeps the indexer out of git internals. Run it from the repo root, where `references/` is:

```sh
find references -mindepth 2 -maxdepth 2 -name .git -exec rm -rf {} +
```

`-mindepth 2 -maxdepth 2` limits it to each clone's own `.git`, so the repo's `.git` at the root and anything deeper are never touched. To update a snapshot afterwards, delete its folder and clone it again.

## Index

```sh
uv tool install --upgrade 'cocoindex-code[full]'   # local embeddings; uses CUDA or Apple's GPU when present
for d in references/*/; do (cd "$d" && ccc index); done
claude mcp add cocoindex-code -- ccc mcp
```

cocoindex-code lists C, C++, Go, and Lua but not QML or Luau, so those files may be split by lines rather than by syntax. On macOS use Homebrew's Python: Apple's lacks the SQLite extension support it needs.
