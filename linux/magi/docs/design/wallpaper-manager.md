# First-party Wallpaper Manager — 2026-10-12

> Phase 2E.1 supersedes legacy-tool references below: MFTrunk and Rofi are retired; MAGI Apps is the sole launcher route. Earlier references record historical state.

Implementation checkpoint; uncommitted for operator review. Automated and offscreen
checks pass. Native desktop validation is **pending**, because this execution
environment cannot connect to the compositor/renderer sockets. This is not a
claim that the live acceptance checklist has passed.

## Baseline and audit

Started at `c28950dda2153ea657331c647de5e32c39ea4cac`
(`magi: expand control centre action catalogue`), branch `main`, upstream
`origin/main`, zero local divergence against the existing upstream ref. No fetch,
commit or push. Initial status contained only these protected operator files;
all three retain their initial SHA-256 at completion:

| Path (repository-relative) | SHA-256 |
| --- | --- |
| `linux/magi/.config/quickshell/magi/settings.json` | `d84e2ac05c341eb08a7268b560209aaf7c457c71111659ba0818d8c6cc9a2796` |
| `linux/t15g/hypr/.config/hypr/hypridle.conf` | `eb6fa3c034957abaf48de818e690429c4a1c8b4815e72ead5e19d90a30cc17fb` |
| `linux/t15g/hypr/.config/hypr/hyprlock.conf` | `4093a0fec9821d286c47b53916057b8231ce792c71ce404fa940d72d3861262d` |

Installed: Quickshell 0.3.1, Hyprland 0.56.2-4, hyprpaper 0.8.4-9,
Qt base/declarative 6.11.2. Read both live `~/.config/hypr` and the tracked T15g
configuration, rather than deriving their contents from conventional paths.
`hyprland.lua:44` starts hyprpaper. `hyprpaper.conf` enables IPC and sets cover
wallpapers for eDP-1, HDMI-A-1 and fallback, pointing to
`/home/jkebwdn/Pictures/wallpapers/ThinkpadLaptopClose.png`. That directory exists
and contains this one PNG. These names are audit evidence, never application
constants. The existing `mftrunk` quick action can restart hyprpaper; no existing
wallpaper-selection keybind or script was found in the audited Linux configuration.
Nothing in that configuration or script was changed.

Previous architecture/checkpoints identify hyprpaper as active. Its **current
process/monitor activity cannot be independently confirmed here**: `hyprctl`
monitor/layer/configerrors calls fail with `Couldn't set socket timeout (2)`, and
hyprpaper IPC reports failed connection. The implementation therefore checks the
backend at runtime and surfaces errors, without starting/replacing a daemon.

Settings already use a singleton store with validated, atomic deferred writes.
Existing `RoundedArtwork` demonstrates bounded Qt `sourceSize`. `AssetManager` / `assets.py`
copy/hash bounded avatars/icons and cache media artwork; those import semantics
and size limits do not fit a read-only large-image library. No general wallpaper
index/cache existed. Monitor integration already uses
`Quickshell.Hyprland` raw events and `Hyprland.monitorFor(screen)` in
`FullscreenMonitor`. Wallpaper listens for topology events, with fresh
`hyprctl -j monitors` snapshots inside backend transactions.

## Architecture and opening

- `Wallpaper.qml`: independent service, serialized worker requests, UI state,
  decoded-image preflight, monitor events and IPC.
- `wallpaper_library.py`: read-only library discovery, no renderer commands.
- `wallpaper_backend.py`: hyprpaper-specific command building, monitor/current
  queries, timeouts, active-path verification.
- `wallpaper_state.py`: atomic XDG state, locking, selection/restore transaction,
  rollback and bounded favourites/history.
- `WallpaperTile`, `WallpaperContent`, `WallpaperWindow`: reusable tile/grid and
  a separate lazy overlay, using the existing shell theme.
- `WallpaperPage`: focused Settings page; no Settings redesign.

Open **Settings → Wallpaper → Open Wallpaper Manager**, or:

```sh
qs -c magi ipc call wallpaper open
qs -c magi ipc call wallpaper toggle
qs -c magi ipc call wallpaper status
qs -c magi ipc call wallpaper refresh
qs -c magi ipc call wallpaper restore
```

The manager is neither a Hub mode nor Control Centre content. No catalogue change
was necessary; an optional Wallpaper action is a small future follow-up. Status →
Control Centre, time/date → Calendar, Apps/Notifications/Emoji/Clipboard → Hub
remain intact. Opening Wallpaper closes anchored menus/Hub; their opening closes
Wallpaper. The overlay ignores exclusion, leaves the top 48px reachable and
releases focus on Escape/outside click. It waits for existing bar readiness.
Content is destroyed on close, releasing thumbnail images. Arrow keys navigate;
Enter applies; clicking a tile applies immediately and leaves the manager open.

## Library and thumbnails

Schema 10 adds `wallpaper.enabled` (true), `directories`
(default `["~/Pictures/wallpapers"]`, verified against this machine), and
`thumbnailSize` (220; range 160–320). Preferences migrate in memory; operator-local
settings are not rewritten just by loading the new schema. Reset changes these
preferences only, preserving wallpaper state and favourites. Directory editing
uses one absolute or `~/` path per line, with an explicit Save button.

At most 16 explicit roots; **nonrecursive**. Canonical roots are deduplicated;
files deduplicate by device/inode, including symlink/hardlink aliases. No directory
symlink traversal or recursive cycles. Scans stop at 10,000 images or 50,000 visited
entries with a visible warning. Missing/inaccessible directories produce warnings;
unreadable files and non-images are skipped. Refresh is manual or triggered by
changed directories, not every frame/open. There is no filesystem watcher/indexing
daemon. Scanning occurs in a separate Python process.

PNG and JPEG/JPG are supported, with case-insensitive extensions and a header gate.
Qt does final decoding and reports corrupt/missing previews. WebP is deferred:
the audited Qt plugin directory contains JPEG, GIF, ICO and SVG but no WebP plugin.
No packages or heavyweight processors were added. A 32px asynchronous Qt preflight
must succeed before interactive apply, including Random/keyboard selection.

`GridView` virtualizes delegates with `cacheBuffer: 0`. Images load asynchronously,
use crop previews and a fixed 320×200 `sourceSize`, and disable the shared Qt image
cache. Thus thumbnail textures are bounded rather than retained full-resolution
images. Some decoders (notably PNG) still need transient source decode memory;
this is not a guarantee of constant-memory decoding. No disk thumbnail cache is
created, so there is no cache cleanup policy/storage to manage. Grid density does
not continuously resize/redecode each thumbnail. Current, keyboard-selected and
hover states remain distinguishable; filenames appear on relevant tiles.

## Backend, selection and persistence

Target is **hyprpaper 0.8.4** and installed hyprctl's protocol v2:
`hyprctl hyprpaper wallpaper 'MONITOR,ABSOLUTE_PATH,FIT'`.
Its new runtime API replaces the old preload/apply/unload workflow. MAGI does not
issue obsolete preload/unload commands or retain a growing preload list. Renderer
resources remain hyprpaper-owned. Settings expose only verified `cover`, `contain`,
`stretch` and `tile`; changing the mode affects the next selection. No center mode.

Command arguments are passed as an argv array, never shell interpolation. The
comma-delimited backend cannot represent commas/newlines or outer whitespace in
paths; such selections produce an explicit error. Monitor names are live values.
Backend subprocesses have five-second timeouts. IPC acknowledgement alone is not
success: the adapter polls `listactive` for the selected monitor's actual path.
This cannot independently verify the displayed pixels or fit geometry.

The pending selection is separate from confirmed current state. Successful apply
updates current state, saves and emits the selection event; while applying, UI
shows progress. A failed request preserves the saved last valid selection and
keeps the manager open. If some monitors changed before failure (including a disk
save failure), the worker attempts rollback on every attempted target. Rollback
failures are explicit, and current state is re-queried where possible. A wallpaper
outside MAGI has no queryable fit mode, so its rollback uses cover. Transactions
across renderer and disk are not atomic against process death: reopening/restarting
restores the last committed choice.

State is separate from preferences, in
`$XDG_STATE_HOME/magi/wallpaper/state.json` (default
`~/.local/state/magi/wallpaper/state.json`), with an adjacent `state.lock`.
Writes use a private temporary file, fsync and atomic rename; concurrent processes
fail safely at a nonblocking lock. Malformed/future/oversized state is preserved
and reported instead of silently overwritten. A reload loads state and reapplies
saved selections. One delayed startup retry accommodates daemon ordering; no
scheduled rotation or continuous renderer enforcement. Use Restore IPC or choose
again after a later external daemon restart. External changes are observed on
manager opening; there is no continuous external-change watcher.

## Monitors, favourites and recents

All monitors explicitly applies to each connected monitor, avoiding wildcard
precedence against existing per-output hyprpaper config. It stores a shared
fallback and clears saved overrides. Per-monitor selection stores connector name
plus exact reported description; a different description does not inherit that
override. Up to 32 mappings survive disconnects. Reconnection/topology events
restore matching overrides, otherwise shared fallback. A missing override falls
back to an available shared image while retaining the mapping for recovery; if
both are missing, the existing desktop is left alone and a warning shown. Connector
renames do not migrate overrides. Full physical multi-monitor/hotplug testing is
still required.

Favourites are canonical paths, limited to 512, toggled with the tile star. Recents
are unique, newest-first, fixed at 24; only successfully saved applies enter history.
Their filtered grids retain missing/out-of-library paths so files can recover or
favourites can be removed. Failed decoding cannot change the desktop. Random
chooses from the available indexed entries in the current filter (excluding stale
saved-only entries); it has no timer. Settings can clear Recents.

## Theme Orchestrator boundary

Future consumers use `Wallpaper.currentPath` for the chosen scope,
`currentByMonitor`, `currentKnown`, the saved `state.shared` / `state.monitors`, and
`selectionChanged(path, monitor, assignments)` after successful interactive apply.
Empty monitor means shared/all-monitor selection. Map property changes also expose
restore/status changes. Unknown/unconfirmed state is explicitly marked. No palette
extraction, Matugen calls, propagation or wallpaper-driven theme changes exist.

## Verification and remaining native checklist

Passed:

- Nine Python tests: directory validation, image filtering, aliases, nonrecursion,
  missing paths, safe argv, transport failures/timeouts, persistence, monitor identity
  and reconnect, fallback, rollback including disk failure, state corruption,
  favourites and bounded/deduplicated history.
- Wallpaper schema migration/validation and production QML Settings reset/reload.
- Offscreen production service, worker and grid with a simulated hyprctl:
  apply/current state/event, failure reporting, missing-image preflight, thumbnail
  decoding, source immutability, fresh-process restore, Enter/Escape/outside click.
- Existing Settings store/schema (five isolated fixtures); Control Centre catalogue;
  Emoji/Calendar schemas; Hub content/actions/pointer tests; Calendar presentation
  and actual Bar handoff/geometry regression.
- `git diff --check`; protected-file SHA-256 checks.

Offscreen tests substitute only the native layer wrapper and renderer transport;
known sandbox IPC and unsupported-window-mask messages are expected. The intentional
missing-image test logs a Qt decode warning. No production restart was attempted.
Static inspection confirms unchanged Bar `exclusiveZone: fullSurface ? 48 : 0`
and Wallpaper `ExclusionMode.Ignore`; the isolated Bar test passes. **Exactly 48px
of live compositor reservation remains unverified**, as do `hyprctl configerrors`
and current monitor state, due to the socket limitation described above.

Operator native acceptance still needs: open manager; inspect thumbnails on real
DPI; select another image and confirm actual pixels/current state; change fit mode;
reload MAGI and verify restoration; check backend failure/recovery; test focus and
outside dismissal; verify CC, Calendar and Hub; query configerrors/layers/monitors
and confirm exactly 48px reservation. The audited library has only one image, so a
second operator-provided image is needed for a visible change comparison. No source
wallpapers, Hyprland configs or packages were modified.

## API evidence (inspected 2026-10-12)

- [Hyprland v0.56.2 hyprctl Hyprpaper.cpp](https://github.com/hyprwm/Hyprland/blob/v0.56.2/hyprctl/src/hyprpaper/Hyprpaper.cpp):
  `doWallpaper`, `fitFromString`, `doListActive` verify argv protocol, fit names,
  acknowledgements and `monitor: path` output. Matches installed Hyprland.
- [hyprpaper v0.8.4 IPC.cpp](https://github.com/hyprwm/hyprpaper/blob/v0.8.4/src/ipc/IPC.cpp)
  and [WallpaperMatcher.cpp](https://github.com/hyprwm/hyprpaper/blob/v0.8.4/src/config/WallpaperMatcher.cpp):
  runtime state replacement and explicit-monitor precedence explain the per-output
  adapter and absence of preload commands. Matches installed hyprpaper. Physical
  rendering/rollback remains a native test, not a source-based claim.
- [Qt Image](https://doc.qt.io/qt-6/qml-qtquick-image.html): `sourceSize`,
  `asynchronous`, `cache`, `PreserveAspectCrop` support bounded thumbnail textures.
  Rolling docs checked against Qt 6.11.2's local runtime via production-component
  tests; decoder allocation costs remain format-dependent.
- [Quickshell Process 0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell.Io/Process/):
  stdin JSON, collectors and exit handling follow existing MAGI patterns and passed
  worker tests on installed 0.3.1. Processes do not outlive shell reloads.

## Exact intended Git path allowlist

All paths below are repository-relative. The three operator exclusions above are
not part of this milestone. No commit or push is authorized.

```text
linux/magi/.config/quickshell/magi/components/settings/SettingsApplication.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsWindow.qml
linux/magi/.config/quickshell/magi/components/settings/pages/WallpaperPage.qml
linux/magi/.config/quickshell/magi/components/wallpaper/WallpaperContent.qml
linux/magi/.config/quickshell/magi/components/wallpaper/WallpaperTile.qml
linux/magi/.config/quickshell/magi/components/wallpaper/WallpaperWindow.qml
linux/magi/.config/quickshell/magi/services/Wallpaper.qml
linux/magi/.config/quickshell/magi/services/qmldir
linux/magi/.config/quickshell/magi/services/wallpaper_backend.py
linux/magi/.config/quickshell/magi/services/wallpaper_library.py
linux/magi/.config/quickshell/magi/services/wallpaper_state.py
linux/magi/.config/quickshell/magi/settings/SettingsMigrations.js
linux/magi/.config/quickshell/magi/settings/SettingsSchema.js
linux/magi/.config/quickshell/magi/settings/SettingsStore.qml
linux/magi/.config/quickshell/magi/shell.qml
linux/magi/README.md
linux/magi/docs/README.md
linux/magi/docs/architecture.md
linux/magi/docs/decisions.md
linux/magi/docs/design/settings-architecture.md
linux/magi/docs/design/wallpaper-manager.md
linux/magi/docs/quickshell-reference.md
linux/magi/tests/calendar/schema.cjs
linux/magi/tests/emoji/schema.cjs
linux/magi/tests/settings/run.py
linux/magi/tests/settings/schema.cjs
linux/magi/tests/settings/store.qml
linux/magi/tests/wallpaper/backend.py
linux/magi/tests/wallpaper/integration.qml
linux/magi/tests/wallpaper/presentation.py
linux/magi/tests/wallpaper/reload.qml
linux/magi/tests/wallpaper/schema.cjs
```
