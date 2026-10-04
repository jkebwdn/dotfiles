# First-party application launcher

Implementation checkpoint: 2026-10-04. Base `c5bd0e2`. Uncommitted operator
review milestone; application launching only.

## Ownership and integration

- `services/launcher_backend.py`: GIO/GioUnix desktop application enumeration and
  ID-based launch. XDG overrides, `should_show()` (including NoDisplay, Hidden
  and desktop visibility), field codes, working directory and D-Bus activation
  remain GIO-owned. No query or raw Exec string is evaluated by MAGI.
- `services/LauncherSearch.js`: pure normalized token scoring, independent of UI.
- `services/Launcher.qml`: IPC, cached discovery, query, selection, session usage,
  launch/error state. Refresh on each opening; no background polling. Opening
  resets query/selection and closes status menus, notifications and Clipboard.
  Their opening, or a Settings request, dismisses the launcher in `shell.qml`.
- `LauncherWindow.qml`: output-local full-screen transparent overlay, present only
  while open. `ExclusionMode.Ignore` creates no reservation. Exclusive keyboard
  focus is deliberately temporary; Escape, outside press, successful launch,
  disable and toggle dismiss it. Outside presses are consumed. This avoids
  compositor-dependent initial focus on a normal floating window. It is a brief
  app-selection interaction, not a persistent modal desktop window.
- `LauncherContent.qml`: one GridView in one-column list or multi-column grid mode.
  `LauncherItem.qml`: shared application icon/name/description delegate. Selection
  scrolls into view. The shared theme supplies colors, font and roundness; panel
  fill is opaque for readability over application windows.
- `LauncherPage.qml`: existing Settings writer/validation/reset pipeline, schema7.
  No separate preferences writer. Older schema chains preserve existing choices.

`SUPER+SPACE` toggles via `quickshell ipc -c magi call launcher toggle`.
`SUPER+CTRL+SPACE` retains Rofi drun as an evaluation fallback. `launcher open`,
`close`, `toggle`, `status` IPC are supported. No package removal or shell restart.

## Search and interaction

Case/diacritic-normalized whitespace tokens must all match. Exact field matches
score above prefixes, word starts, then substrings. Name weight is 1, generic
name .7, keywords .6. Categories are exposed by the backend but not ranked.
Duplicate desktop IDs are discarded; similarly named distinct apps remain.
Ties use display name then desktop ID. A successful launch adds a small capped
frequency bonus (maximum9); history lives only in the shell session and can reset
on QML reload. This is not persistent recency tracking or fuzzy typo correction.

Up/Down navigate rows; grid Left/Right navigate cells; PageUp/PageDown move three
rows. In grid mode Left/Right belong to selection rather than the text cursor.
Enter launches, Escape closes. Mouse click launches; hover highlights without
moving keyboard selection. Hidden names retain accessible names and hover tips.
Empty matches cannot launch. Failures keep the launcher open with a message.
GIO success means dispatch succeeded, not that the application's startup succeeded.

GLib2.88's terminal list omits Ghostty, this machine's terminal. When a terminal
entry is launched and `xdg-terminal-exec` is absent, the installed Ghostty is
bridged through the private `services/launcher-terminal/xdg-terminal-exec` adapter.
GIO still expands fields and sets cwd. Only the launch context gets the temporary
PATH prefix; the adapter restores PATH and removes private variables before
executing Ghostty with an argv array. A real system xdg-terminal-exec takes
precedence. Other systems use GIO's terminal fallback list. This is an application
metadata path, not a user command mode.

## Settings (launcher section)

| Setting | Default | Range / behavior |
| --- | --- | --- |
| enabled | true | Disabled closes and ignores open requests |
| hiddenIds | [] | Persistent exact desktop-entry IDs; reset restores all |
| layout | list | list / grid, both implemented |
| panelWidth / gridWidth | 420 / 720 | 320–800 / 420–1200; clamp to output |
| rowHeight | 56 | 40–96; list icon clamps to fit |
| iconSize | 32 | 20–64; original application icon colors |
| visibleRows | 6 | 3–12; grid uses up to3 rows, scroll for the rest |
| gridColumns | 5 | 3–8; narrow panels reduce columns automatically |
| showIcons / showLabels | true / true | At least one must remain enabled |
| showSubtitles | true | Generic name, then comment; list with labels only |
| position | center | center / top (64 logical pixels from top) |
| headerEnabled / backgroundEnabled | false / false | Independent optional images |
| headerImage / backgroundImage | empty | Absolute local paths, no network URLs |
| headerPosition | top | top / bottom; 150px crop, inset inside panel |

Background art is cropped and drawn at16% opacity. Missing images leave the usable
panel intact. Assets are referenced in place; no import/copy/file chooser is
implemented. The default has no image because supplied screenshots are design
references, not licensed reusable artwork. Normal app icons use the installed
icon theme through Quickshell with initial-letter fallback. Custom icon packs
for application icons are a follow-up, separate from MAGI's semantic control pack.

## Hidden applications and application icon boundary

Right-click a result → **Hide application** (or Menu / Shift+F10 for the selected
result). The quiet single-action menu is a Qt Controls `Popup.Item` inside the
existing launcher surface; it adds no compositor window/reservation. It captures
the desktop ID, not a mutable result index. Closing it returns focus to search.
Hiding never uninstalls, edits a desktop file or invents a name/utility blacklist.

Schema7 gains additive `launcher.hiddenIds`, default `[]`; the milestone remains
uncommitted, so no additional version bump is needed. Existing schema7 documents
without the field get the empty default. IDs must be unique nonempty desktop-file
IDs without path separators/control characters. The shared search function removes
hidden IDs before scoring, even for exact name/keyword searches and high usage
scores, so both list and grid use the same exclusion.

Settings → Launcher → **Hidden applications** shows current display names and
individual **Restore** buttons. Opening the page refreshes discovery without
opening the launcher. Missing/uninstalled entries retain their stored ID and a
“Not currently available” label, and remain restorable. Reinstalling the same ID
keeps it hidden until restored. Only IDs are persisted, not stale names/icons.
The existing atomic Settings writer handles save/reload/errors.

**Reset Launcher restores every hidden application** along with visual defaults;
reset-all has the same effect. The Settings text and reset-button label explicitly
state this. Restoring removes the user exclusion; normal system desktop visibility
rules still apply. Changes to the operator's local settings.json are not part of
the intended code Git allowlist.

`LauncherIcons.resolve(app)` is the sole application-icon lookup boundary.
`LauncherItem.iconPresentation` receives `{source, fallbackText}`; layout code
handles geometry only. Today the resolver uses the installed icon theme and the
existing initial-letter fallback. Future user/pack mappings can key on `app.id`
before falling back to `app.icon`, with reactive override preferences read inside
the resolver. No icon pack subsystem, new artwork or Fraud O.G implementation was
added. Both accepted presentations retain their current geometry/style.

## Design grounding

The supplied current Rofi screenshot influenced centered narrow proportions,
search-first interaction, simple vertical selection and optional header artwork.
The two Rofi examples informed list/grid flexibility. The macOS application and
Launchpad examples informed icon-first grid cells, not a copied desktop or dock.
No implementation was inferred from screenshots; no external code/assets copied.

## Validation and limits

Automated checks run:

- `node tests/launcher/search.cjs`: token matching, accents, field weighting,
  deterministic ordering, deduplication and capped frequency.
- `node tests/launcher/schema.cjs`: migration/preservation, defaults, enums,
  bounds, local paths and identifiable-item guard.
- `python tests/launcher/backend.py`: disposable XDG fixtures for precedence,
  visibility, keywords, executable launch, field expansion, cwd, failures and
  terminal argv/PATH restoration through a fake Ghostty.
- `python tests/launcher/presentation.py`: production content in both layouts,
  focus/navigation/filtering/empty/launch/Escape; real Settings page persistence,
  reload/reset; real service discovery/open/reset/disable/launch/frequency with a
  harmless `/usr/bin/true` desktop fixture. Temporary settings/storage only.
- `python tests/settings/run.py`, `python tests/settings/modules.py window.qml`,
  `node tests/clipboard/schema.cjs`, `python tests/clipboard/presentation.py`,
  `python tests/notifications/presentation.py`, and
  `python tests/shared-status-surface/run.py` (48 steps).
- Offscreen tests filter the known sandbox IPC-socket and unsupported-window-mask
  messages; these are not asserted as successful Wayland focus tests.
- Hidden-app follow-up reran all focused launcher commands above and both Settings
  store/window suites. Added invalid/duplicate/missing-ID schema tests,
  hidden-before-ranking checks, and `hidden.qml`: actual contextual action,
  list/grid/search exclusion, persistence/reload, missing-app restoration via the
  Settings Restore button, duplicate hide, reset and focus restoration. The item
  presentation test also verifies resolver fallback/reactivity and injected icon
  presentation in grid mode. Fixtures use disposable default settings, not the
  operator's chosen artwork/layout.
- `git diff --check`.

Live eDP-1 scale2: existing MAGI PID143717 auto-reloaded, IPC discovery returned24
visible apps. Launcher mapped as `magi-launcher` in overlay layer3, 1920×1080;
main bar remained one layer with reservation `[0,48,0,0]`. Injected `z` produced5
results and Escape closed. Hyprland config errors empty, production logs INFO-only.
Operator explicitly reported all SUPER+SPACE, immediate search, Enter launch,
reopen and outside-click checks passed. List screenshot and isolated grid render inspected. The operator has now manually accepted grid mode as the foundation for future
icon-forward presentation, and verified Neovim launches in Ghostty from the live
launcher. Both are accepted; no broad grid redesign is part of this milestone.

Known follow-ups: multi-output/fractional scaling; focus/activation across apps
with stricter activation policies; optional imported
artwork and file picker; persistent usage/recency; richer grid/icon packs. Discovery
refreshes on reopen rather than watching installs while open. No providers,
calculator, files, commands, emoji or unrelated shell milestones were introduced.

## Exact intended Git allowlist

Paths below are relative to the dotfiles repository root. No staging, commit or
push performed. Existing untracked Hypridle/Hyprlock files are explicitly excluded,
as are local preferences, screenshots and temporary test outputs.

```text
linux/magi/.config/quickshell/magi/components/launcher/LauncherContent.qml
linux/magi/.config/quickshell/magi/components/launcher/LauncherItem.qml
linux/magi/.config/quickshell/magi/components/launcher/LauncherWindow.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsApplication.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsWindow.qml
linux/magi/.config/quickshell/magi/components/settings/pages/LauncherPage.qml
linux/magi/.config/quickshell/magi/services/Launcher.qml
linux/magi/.config/quickshell/magi/services/LauncherIcons.qml
linux/magi/.config/quickshell/magi/services/LauncherSearch.js
linux/magi/.config/quickshell/magi/services/launcher-terminal/xdg-terminal-exec
linux/magi/.config/quickshell/magi/services/launcher_backend.py
linux/magi/.config/quickshell/magi/services/qmldir
linux/magi/.config/quickshell/magi/settings/SettingsMigrations.js
linux/magi/.config/quickshell/magi/settings/SettingsSchema.js
linux/magi/.config/quickshell/magi/settings/SettingsStore.qml
linux/magi/.config/quickshell/magi/shell.qml
linux/magi/README.md
linux/magi/docs/README.md
linux/magi/docs/architecture.md
linux/magi/docs/decisions.md
linux/magi/docs/design/application-launcher.md
linux/magi/docs/quickshell-reference.md
linux/magi/docs/research/README.md
linux/magi/docs/research/application-launcher-apis.md
linux/magi/tests/clipboard/schema.cjs
linux/magi/tests/launcher/backend.py
linux/magi/tests/launcher/content.qml
linux/magi/tests/launcher/hidden.qml
linux/magi/tests/launcher/presentation.py
linux/magi/tests/launcher/schema.cjs
linux/magi/tests/launcher/search.cjs
linux/magi/tests/launcher/service.qml
linux/magi/tests/launcher/settings.qml
linux/magi/tests/settings/run.py
linux/magi/tests/settings/schema.cjs
linux/magi/tests/settings/store.qml
linux/t15g/hypr/.config/hypr/hyprland.lua
```
