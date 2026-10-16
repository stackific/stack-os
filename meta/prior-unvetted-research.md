# Stack Shell

Specification for Stack Linux's desktop: a Fedora bootc image that boots into Mango and one Quickshell process that hosts the bar, the panels, and a plugin layer like Omarchy's. It starts from scratch and bare: the first milestone is a bar with a workspace switcher, nothing else. Everything later is a plugin on the same host.

Status: draft for review. Nothing here is implemented. Open decisions are at the end. Companion documents: `STACK-CLI.md` (the `stack` command) and `REFERENCES.md` (the code to study).

## Principles

- One language stack: QML, JavaScript, and C++. No Go daemon, no Python, no Lua. Shell scripts only where the image build needs them.
- Fedora packages first, then RPM Fusion and Terra, then a build from source inside the image build. The image stays offline-installable: nothing downloads at first boot or login.
- The shell is a plugin host. The bar, the workspace switcher, the clock, and later the launcher and the lock screen are plugins with the same manifest and the same host API that a third party gets. Dogfooding keeps the API honest.
- Pure logic lives in plain JavaScript files that Node can load, so it is tested without a compositor. QML holds only rendering and bindings.
- Every default is a default: users change layout and settings in one JSON file that the shell watches, and nothing is rewritten by an update.
- Strangers' machines: no assumption about monitors, GPUs, keyboards, or languages. Per-monitor state is the rule, not the exception.
- Barebones first. Milestone 0 ships less than Omarchy 1.0 did. Breadth comes from plugins afterwards, not from the host.

## The stack

| Layer | Component | Why |
|---|---|---|
| Image | Fedora 44 bootc, built from the minimal manifest by the `features/` tree of this repository | Atomic updates, rollback, one tested image on every machine; Secure Boot through Fedora's signed chain |
| Login | greetd with `agreety` (greetd's own text greeter) in milestone 0; a Quickshell greeter later through `Quickshell.Services.Greetd` | Nothing to build on day one; the greeter becomes a shell plugin when the shell is stable |
| Compositor | Mango (`mangowm`, Terra), tags per monitor, `mmsg` and a JSON socket for IPC, ext-workspace implemented through wlroots | Already in the image and tested; dwm-style tags fit a bar; its IPC gives everything a bar needs |
| Shell | One Quickshell process, `stack-shell`, started by a systemd user service | Quickshell gives layer-shell windows, session lock, tray, notifications server, PipeWire, UPower, greetd, and process and socket helpers in one toolkit |
| Plugins | Directories with `manifest.json` and QML entry points, discovered from the image and from the user's home | Omarchy's model, trimmed |
| Apps | kitty and Brave in milestone 0; Thunar, Loupe, Celluloid and the rest return in later milestones as the image grows | Enough to use the desktop and report problems |

Quickshell version: Fedora 44 ships `quickshell` 0.2.1 (a February 2026 git snapshot). Upstream 0.3.x (March 2026 onward) adds the `Quickshell.WindowManager` module, which speaks ext-workspace. Milestone 0 builds on the Fedora package and Mango's socket; see open decision 1 for when to move.

## The session

1. greetd starts `mango` for the user after login. Mango runs `dbus-update-activation-environment --all` at startup, so the systemd user instance sees `WAYLAND_DISPLAY`, `MANGO_INSTANCE_SIGNATURE`, and the session variables from `environment.d`.
2. Mango's config (`/etc/mango/config.conf`, sourced by the user's copy) has one block for the shell: `exec_once=systemctl --user start stack-shell.service`. Nothing else in the compositor config belongs to the shell.
3. `stack-shell.service` (`/usr/lib/systemd/user/`): `ExecStart=/usr/bin/quickshell -p /usr/share/stack/shell`, `Restart=on-failure`, `RestartSec=1`, `PartOf=graphical-session.target`, `ConditionUser=!@system`, logs to the journal. A crash loses the bar for one second, not the session.
4. Stock Mango key bindings stay. The shell adds none in milestone 0. Later plugins that need a global key (launcher, lock) ship a Mango block with `bind=...,spawn,stack shell toggle <id>`.

## The shell host

### Files

| Path | Holds |
|---|---|
| `/usr/share/stack/shell/` | `shell.qml`, `Commons/` (singletons: `Color`, `Style`, `Config`, `Log`, `Util`), `Ui/` (the widget kit), `Services/` (host services), `qmldir` files |
| `/usr/share/stack/plugins/<id>/` | First-party plugins, each with `manifest.json` |
| `/usr/share/stack/themes/<name>/colors.toml` | Shipped palettes |
| `~/.config/stack/shell.json` | Layout, enabled plugins, plugin settings. Created on first change; absent means defaults |
| `~/.config/stack/shell.toml` | Per-machine token overrides (font size, spacing); wins over the theme |
| `~/.config/stack/plugins/<id>/` | Plugins the user is developing; highest precedence for an id |
| `~/.local/share/stack/plugins/<id>/` | Installed third-party plugins (`stack plugin add` later) |
| `~/.local/state/stack/` | Current theme name, rendered theme files, notification history later |

`shell.json` follows Omarchy's rules because they are simple and have survived contact with users: `version: 1` required; `bar.layout.<section>` lists bar widgets with settings inline on the entry; `plugins[]` lists enabled third-party non-bar plugins; `disabledPlugins[]` lists switched-off first-party ones; no merge layers, the file is canonical once it exists.

```json
{
  "version": 1,
  "bar": {
    "position": "top",
    "layout": {
      "left": [ { "id": "stack.workspaces", "style": "pills" } ],
      "center": [ { "id": "stack.clock" } ],
      "right": []
    }
  },
  "plugins": [],
  "disabledPlugins": []
}
```

Milestone 0 has three sections, `left`, `center`, `right`. Omarchy's `centerBegin`, `centerEnd`, and `tray` are added when a widget needs them; the section names are the only part of the schema expected to grow.

### Startup

1. `shell.qml` loads `Commons`, reads `shell.json` (or defaults), reads the theme, and starts the host services.
2. `Services/PluginRegistry.qml` walks the three plugin directories, parses every `manifest.json`, validates it against the schema (bad manifests are logged and skipped, never fatal), and resolves id precedence: user dev, then installed, then first-party.
3. Services declared by manifests load first, then the bar plugin, then bar widgets in layout order. Panels, overlays, and menus load when summoned and unload when closed, unless `keepLoaded` is set.
4. Quickshell's own file watching reloads QML when a file under a plugin directory changes. `shell.json` and `shell.toml` are watched with `FileView` and reapplied without a restart.

### IPC

Quickshell's `IpcHandler` registers a target per plugin, named by plugin id, plus the host's `shell` target. The `stack` command (see `STACK-CLI.md`) wraps `quickshell ipc call`: `stack shell toggle stack.launcher` and `stack shell ping`. Host methods in milestone 0: `ping`, `summon <id> <payloadJson>`, `hide <id>`, `toggle <id> <payloadJson>`, `call <id> <method> <arg>`, `rescanPlugins`, `reloadConfig`, `listPlugins`, `applyTheme <name>`. Methods answer `ok`, `unknown`, or an error string on stdout, as Omarchy's do, so scripts can branch on them.

### Logging

`Commons/Log.qml` prefixes every line with the plugin id and writes to stderr, which the service sends to the journal. `journalctl --user -u stack-shell` is the one place to look. A plugin that throws during load is logged with its id and disabled for the session; the bar renders without it.

## The plugin layer

### Manifest

`manifest.json` at the plugin's root. Adapted from Omarchy's (`docs/omarchy-shell.md` in `references/omarchy-quattro`), with two additions: `hostApi`, so a plugin says which host API version it was written against, and `settings` at the top level, so a service or panel can have settings without being a bar widget.

```json
{
  "schemaVersion": 1,
  "id": "stack.workspaces",
  "name": "Workspaces",
  "version": "0.1.0",
  "author": "Stack Linux",
  "description": "Mango tags per monitor, as pills",
  "hostApi": 1,
  "kinds": ["bar-widget"],
  "entryPoints": { "barWidget": "Widget.qml" },
  "barWidget": {
    "displayName": "Workspaces",
    "category": "Compositor",
    "allowMultiple": false,
    "defaultSection": "left"
  },
  "settings": {
    "defaults": { "style": "pills", "hideEmpty": false },
    "schema": [
      { "key": "style", "type": "enum", "values": ["pills", "numbers", "names"], "label": "Style" },
      { "key": "hideEmpty", "type": "bool", "label": "Hide empty tags" }
    ]
  }
}
```

| Field | Rule |
|---|---|
| `id` | Reverse-DNS-like, lowercase, `vendor.name`. `stack.` is reserved for first-party plugins |
| `kinds` | One or more of `bar-widget`, `bar`, `panel`, `overlay`, `menu`, `service` |
| `entryPoints` | One QML file per declared kind: `barWidget`, `bar`, `panel`, `overlay`, `menu`, `service` |
| `hostApi` | Integer. The host refuses a plugin whose `hostApi` is newer than its own and warns on one more than one version older |
| `keepLoaded` | Keep a summoned surface or a service alive across summons and hot reloads |
| `settings.schema` | Typed keys (`bool`, `int`, `string`, `enum`, `color`) with labels; the settings UI (a later milestone) is generated from it, and `shell.json` entries are validated against it |

### Kinds

| Kind | What the host does with it |
|---|---|
| `bar-widget` | Instantiates the entry point inside a bar section, as many times as the layout lists it (`allowMultiple`) |
| `bar` | A full bar that replaces `stack.bar`; at most one active, chosen by `bar.id` |
| `panel` | A floating window the host opens on `summon` with a payload and closes on `hide` |
| `overlay` | A fullscreen layer-shell surface (picker, lock, OSD), same lifecycle as a panel |
| `menu` | A summoned surface that receives keyboard focus and closes on Escape |
| `service` | A headless singleton loaded at startup; other plugins reach it through the host |

### Entry point contract

Every entry point is a QML `Item`. On load the host sets these properties:

| Property | What it is |
|---|---|
| `manifest` | The parsed manifest, read-only |
| `settings` | This instance's effective settings: schema defaults overlaid by the `shell.json` entry. A plugin writes back with `host.saveSettings(key, value)` |
| `host` | The facade (below). Third-party plugins never see the host's internal objects |
| `screen` | For bar widgets and per-screen surfaces, the `ShellScreen` the instance is on |

Panels, overlays, and menus implement `open(payloadJson)` and `close()`. Services expose whatever they like; the host reaches them only through `host.service(id)`.

### The host facade

Deliberately small in milestone 0. Everything a plugin may use is on `host`; anything not listed is private and may change without notice.

| Member | Meaning |
|---|---|
| `host.compositor` | The `Compositor` service: outputs, tags, windows, `dispatch()` |
| `host.theme` | `Color` and `Style` tokens, and `themeChanged` |
| `host.config` | Read-only view of `shell.json`; `saveSettings(key, value)` for the plugin's own entry |
| `host.ipc` | `register(method, fn)` on the plugin's own IPC target |
| `host.log` | `info`, `warn`, `error`, prefixed with the plugin id |
| `host.service(id)` | Another plugin's service object, or `null` if not loaded |
| `host.summon(id, payload)`, `host.hide(id)` | Open or close another plugin's surface |
| `host.run(argv)` | Spawn a detached process (`Quickshell.execDetached`) |

Omarchy documents that its facades are API boundaries, not sandboxes: a visual widget shares the host's scene and can walk its parent hierarchy. The same is true here, and the stance is the same: plugins run as the user with the shell's access, a plugin that is added is disabled until the user enables it, and `stack plugin update` shows a diff before it fast-forwards. Settings, not capabilities, are the only thing the host validates.

### Precedence and hot reload

A plugin id found in `~/.config/stack/plugins/` shadows the same id in `~/.local/share/stack/plugins/`, which shadows `/usr/share/stack/plugins/`. That is how a user forks a built-in: copy `stack.clock` to `~/.config/stack/plugins/me.clock/`, change the id, and enable it. Saving a file under any plugin directory reloads that plugin's QML; `stack shell rescanPlugins` picks up new directories.

## Host services in milestone 0

### `Compositor`

A singleton in `Services/Compositor.qml` with a compositor-neutral surface and a Mango backend. Its model, shared by the bar and by every future plugin:

```
outputs: { [name]: { name, active, scale, activeTags: [int], inOverview: bool,
                     tags: [ { index: int (1-based), name: string, active: bool,
                               occupied: bool, urgent: bool, clients: int } ] } }
activeOutput: string
windows: [ { id, title, appId, output, tags: [int], focused, floating, visible } ]
```

Methods: `viewTag(output, index)`, `toggleTag(output, index)`, `focusOutput(name)`, `dispatch(output, command)` for anything else, and `outputForScreen(screen)`, which maps a Quickshell `ShellScreen` to the Mango output by name.

Mango backend (`Services/Compositor/MangoBackend.js` for parsing, `MangoBackend.qml` for the sockets), following DankMaterialShell's `MangoService.qml`:

- The socket path is `MANGO_INSTANCE_SIGNATURE`. Each connection sends one verb and receives a full JSON snapshot, then one line per change. Two long-lived `Socket`s: `watch all-monitors` and `watch all-clients`. A third, short-lived socket per `dispatch <command>` request, serialized through a queue, reads one `{"success": ...}` line.
- Each monitor line carries `active_tags` and `tags[]` with `index`, `state`, `clients`, `focused`, `urgent`, `layout`. `active_tags == [0]` means the overview is open; the model exposes it as `inOverview` and keeps the last real active tags.
- `view,N` and `toggleview,N` take 1-based tags; `dispatchOnOutput` focuses the output first when it is not the active one.
- Reconnect with backoff when the socket closes (Mango reload). The model keeps the last snapshot meanwhile, so the bar does not blank.
- Tag names come from Mango's `tags[]` config through the monitor snapshot; the default is `1` to `9`.

Why not ext-workspace first: Fedora's Quickshell lacks the `WindowManager` module, and ext-workspace carries no occupancy (`clients`), which the switcher needs for "occupied". When the image moves to Quickshell 0.3+, an `ExtWorkspaceBackend` fills `tags` from `Quickshell.WindowManager` (`Windowset.name`, `active`, `urgent`, `activate()`, grouped by `WindowsetProjection.screens`) and keeps occupancy from the socket. The surface above does not change.

### `Theme`

`Commons/Color.qml` and `Commons/Style.qml` singletons, filled from the active theme's `colors.toml` and the shell's `shell.toml`, with `~/.config/stack/shell.toml` overriding single keys. Milestone 0 ships one theme, `stack-default`, written by hand. The palette keys are Omarchy's (`accent`, `selection`, `muted`, `background` and its `dark`, `darker`, `lighter` variants, `foreground` and its variants, the eight named colors and their `bright_` forms, and `mode`), because they are simple, template-friendly, and already map onto two dozen app templates in `references/`. Wallpaper-derived palettes come in milestone 2.

### `Config`, `PluginRegistry`, `Ipc`

Described above. `Config` parses `shell.json` with the schema, reports errors to the log and the journal, and falls back to defaults for the broken part only.

## The bar: `stack.bar`

A first-party plugin of kind `bar`. `Variants` over `Quickshell.screens` creates one `PanelWindow` per monitor on `WlrLayershell` layer `top`, anchored to the configured edge, height from `Style.bar.size`, and reserving space (`exclusiveZone`). Three `RowLayout`s for the sections; `center` is centered as a group. Widgets come from `host.config.bar.layout`; an unknown id renders a small placeholder with the id, so a typo is visible rather than silent. The bar has no settings of its own beyond `position` in milestone 0.

## The first plugin: `stack.workspaces`

The Noctalia-style switcher, per monitor.

### Data

`host.compositor.outputs[host.compositor.outputForScreen(screen)].tags`, filtered and shaped by `WorkspacesModel.js`:

```js
// rows(tags, activeTags, inOverview, settings) -> [{ index, label, active, occupied, urgent, visible }]
// next(rows, current, { occupiedOnly }) / prev(...) -> index
```

`visible` applies `hideEmpty` (hide tags with no clients that are not active). Labels follow `style`: `pills` has none, `numbers` is the index, `names` is Mango's tag name.

### Rendering

A row of pills. Each pill is a `Rectangle` with `radius` half its height. The active tag is wider (28 to 12 at default font size), occupied tags are filled with `Color.foreground`, empty tags with `Color.muted`, the active one with `Color.accent`, urgent with `Color.red` and a short pulse. Widths and colors animate with `Behavior` over 150 ms, which is what makes a switch feel attached to the compositor. In the overview (`inOverview`), the row dims to 60% and an extra pill labeled `overview` appears at the start; clicking any pill leaves the overview and views that tag. Sizes derive from `Style.bar.size` and `Style.spacing`, never hard-coded pixels, so a 1.5 scale factor and a 14 pt font both work.

### Interaction

Left click views the tag. Right click toggles it into the current view (Mango's `toggleview`). Scroll over the widget moves to the next or previous tag, occupied-only when `hideEmpty` is on, wrapping at the ends. Keyboard switching stays in Mango's bindings; the bar reflects it within one socket update.

### Settings

From the manifest above: `style` and `hideEmpty`. Both are inline in the `shell.json` entry and editable there in milestone 0; the generated settings UI comes later.

### Tests

`test/shell.d/workspaces-model-test.sh` runs `WorkspacesModel.js` under Node against recorded Mango snapshots: nine tags with two occupied; overview open; urgent on an inactive tag; `hideEmpty` on and off; `next` and `prev` wrapping; a monitor with a custom tag count of five. `test/shell.d/mango-backend-test.sh` feeds recorded `watch all-monitors` lines into `MangoBackend.js` and checks the model shape, the overview detection, and that a malformed line is skipped without clearing state.

## Theming (later milestone, defined now so the host does not block it)

- Milestone 2 adds `stack theme set <name>` and wallpaper-derived palettes: `matugen` (Fedora) turns the wallpaper into `colors.toml` in Omarchy's key set, Material You scheme by default.
- Templates render to `~/.local/state/stack/theme/` from `/usr/share/stack/themed/*.tpl`, starting with the shell's own `shell.toml`, kitty, GTK 3 and 4 CSS, qt6ct, btop, and Starship, which the current image already themes through Noctalia. Retinting follows Omarchy's two groups: what is on screen first and in parallel, the rest in the background with a log.
- The shell takes a new palette through `applyTheme`, without a restart, and every plugin that binds to `Color.*` recolors by itself.

## Repository layout (new repository, `stack`)

```
Containerfile, Taskfile.yml, build/, taskfiles/, scripts/   from this repository
features/<name>/            from this repository, minus noctalia and greeter; plus features/shell
shell/                      the host: shell.qml, Commons/, Ui/, Services/
plugins/<id>/               first-party plugins: stack.bar, stack.workspaces, stack.clock
themes/<name>/colors.toml
themed/*.tpl                milestone 2
test/shell.d/*.sh           Node tests for every *.js model
docs/                       this document, the plugin author guide, the host API reference
```

`features/shell` installs `shell/`, `plugins/`, and `themes/` under `/usr/share/stack/`, the user unit, the Mango block, and runs `qmllint` over every QML file and the Node tests as its `check`.

## Milestones

| Milestone | Delivers | Done when |
|---|---|---|
| 0 Barebones | Image with Mango, greetd and `agreety`, kitty, Brave; `stack-shell` with the host, `stack.bar`, `stack.workspaces`, `stack.clock`; one theme; Node tests; `features/shell` check | Boots in UTM and on an x86 desktop from the offline ISO; the bar shows the right tags on every monitor; switching from the bar and from the keyboard stay in sync; `journalctl --user -u stack-shell` is clean after ten minutes of use; a user can fork `stack.clock` into `~/.config/stack/plugins` and see it reload |
| 1 Daily use | Tray, audio and battery indicators, notifications server, OSD, session lock, a launcher (menu kind), Thunar and the apps back in the image | A day of work without opening a terminal to fix the desktop |
| 2 Theme | Wallpaper palettes, templates, `stack theme`, GTK and Qt retint, the Quickshell greeter in sync | Change the wallpaper and every open app follows within three seconds, Flatpak apps on relaunch |
| 3 Plugins for others | `stack plugin add/update/remove/enable`, the generated settings UI, the plugin author guide, a registry | A third party ships a bar widget without reading the host's source |

## Open decisions

1. Quickshell source: stay on Fedora's 0.2.1 snapshot (milestone 0), or build 0.3.2 from source in the image build (adds `WindowManager`, about 150 lines of Containerfile and a longer build) or take the `errornointernet/quickshell` COPR (not under our control). Recommendation: Fedora's package until a plugin needs 0.3, then build from source, pinned to a tag.
2. Greeter for milestone 0: `agreety` (zero work) or keep `noctalia-greeter` from the current image (works, but ties the login screen to the shell being replaced). Recommendation: `agreety`.
3. Brave in milestone 0 (464 MB) or kitty only.
4. Bar sections: three now, Omarchy's six later, or six from the start.
5. Name of the shell process and directories: `stack-shell` and `/usr/share/stack` as written, or a separate product name for the shell.
6. Whether `stack.workspaces` shows Mango's `overview` as a pill or only dims the row.