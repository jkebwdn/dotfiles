# S1/S2 settings and appearance foundation

Completed **2026-09-27**, continuing the interrupted 2026-09-26 run. Source
baseline `5215bbef5fa3573295c1c1101059d62da502892c`; changes remain uncommitted.
The [approved design](../design/settings-architecture.md) includes later stages
that are deliberately not part of this checkpoint. Paths below are relative to
[the production shell](../../.config/quickshell/magi/) unless stated otherwise.

## Configuration contract and migration

`settings/SettingsSchema.js` defines schema v1:

- `appearance.theme`; `appearance.roundness.master` (0–2, default 1) and nullable
  per-role `barPill`, `surface`, `controlTile`, `slider`, `action` overrides.
- `icons.pack` (currently only `magi-legacy`), module-pack/override storage.
  Asset import and actual icon-resolution precedence are future S3 work.
- `bar.left/center/right`: ordered IDs. Unknown/duplicate IDs are diagnosed and
  omitted from effective placement, retained in the saved raw document.
- `controlCentre.columns` (1–16), ordered control/slider records. These are
  validated storage foundations; current CC does not yet render from them.

`settings/SettingsMigrations.js` maps legacy palette/three placement arrays into
v1. Catppuccin maps to Mocha; Everforest maps to Dark Hard. Explicit order and
empty arrays survive. Missing legacy centre defaults to the old empty array;
new v1 defaults include workspaces. Unknown keys survive. Ambiguous mixed
legacy/new documents require repair. Future schema versions are read-only with
safe effective defaults. Missing values receive defaults without startup writes;
invalid fields are diagnosed, safely defaulted for rendering and block ordinary
save until repaired. Malformed JSON retains last valid/default state and blocks
ordinary edits; an explicit full reset can repair it. Resetting a section replaces
that section with defaults. Full reset resets known sections and retains unknown
root keys; it does not silently discard future extension data.

`services/Settings.qml` is the one production `SettingsStore` owner. Consumers
read replacement snapshots through `data`/`revision` and use its setters/reset
methods. No two-way property aliases write the file. Bar compatibility accessors
remain. Known settings commit immediately in memory and debounce persistence by
250ms; later revisions supersede an in-flight save without being acknowledged
as already persisted. `saveState`, `error`, `diagnostics` and `dirty` expose state.

`settings/persist.py` uses Python's standard library (already installed). It
resolves the canonical target, locks cooperating MAGI writers, checks the previous
disk text, writes/fsyncs a same-directory temporary file, rechecks the baseline,
atomically replaces the file and fsyncs its directory. File mode and symlink
identity are preserved. A conflicting external edit stops persistence; explicit
reload discards pending in-memory edits. FileView watches, but never writes.
Atomic replacement prevents partial JSON; it cannot provide perfect compare-and-
swap against an unrelated editor that ignores MAGI's advisory lock.

The real `settings.json` is now sparse v1, preserving Mocha and the exact left
clock/date, centre workspaces, right volume/Wi-Fi/Bluetooth/battery/Control Centre
order. No test data was written into it. Its original byte-for-byte backup was
verified against Git HEAD at:

`~/.local/state/magi/settings-backups/8fe1a36701f6af3d5c0bfedc7d9c3503a731bc144f18fc8c7f330b829faa750a.json`

Backups are generated before pre-schema replacement; v1 saves are not a general
revision-history system. Tests use disposable config/state/runtime directories.

## Module and host ownership

`modules/ModuleRegistry.qml` owns four nonvisual `ExpandableModule` Scopes.
`ModulePill.qml` delegates bar presentation to the existing ExpandablePlugin;
removing a pill does not destroy its module session or body Component. There
are no invisible bar Items registering hidden detail views. Service state stays
in the existing service singletons; Network, Audio, Bluetooth, Brightness,
Battery and MenuController were not rewritten.

`Bar.syncPlacement()` waits for menus, animations and Wi-Fi password/pending
interaction to settle before changing placement. Unchanged placement is not
recreated for appearance updates. Bar still owns native Region, catcher and
OnDemand focus. Combined modules share one selected interactive body, with no
per-pill native adapter. The accepted shared-surface sequence remains intact.

Anchored visible pills use the unchanged PopupWindow/TransformWatcher path.
`AnchoredDetailHost.qml` supplies a hidden-from-bar detail anchored to the real
Control Centre pill. Limitation: if that trigger is also absent, an omitted
module has no anchored fallback anchor. Combined navigation remains independent
of any compact pill. Multi-output ownership remains unvalidated.

## Theme, appearance and layout

`ThemeRegistry.qml` reads `theme/palettes/registry.json` (format v1) and validates
complete role maps. Registered palettes:

- Catppuccin Mocha, Macchiato, Frappé, Latte.
- Everforest Dark Hard/Medium/Soft and Light Hard/Medium/Soft.

Palette source evidence inspected 2026-09-26, data only, MIT licenses bundled:

| Source | Pinned data / license | MAGI mapping |
| --- | --- | --- |
| Catppuccin palette 1.8.0 | [palette.json at 07d02aa](https://github.com/catppuccin/palette/blob/07d02aa110ef9eb7e7427afca5c73ba9cf7f8ebd/palette.json), [license](https://github.com/catppuccin/palette/blob/07d02aa110ef9eb7e7427afca5c73ba9cf7f8ebd/LICENSE) | Base/surface/text and named accent colors; lavender default accent. |
| Everforest | [autoload/everforest.vim at 85a86eb](https://github.com/sainnhe/everforest/blob/85a86eb62409e3ec88713bff3d1b9d7374e112e4/autoload/everforest.vim), [license](https://github.com/sainnhe/everforest/blob/85a86eb62409e3ec88713bff3d1b9d7374e112e4/LICENSE) | Contrast-specific backgrounds; purple→lavender, orange→peach, aqua→teal. |

These sources define color data, not MAGI interaction or Qt compatibility.
MAGI's semantic mappings/contrast ink choices are implementation decisions.
All ten mappings were locally tested on Quickshell 0.3.1. Additional palettes
need a data entry with complete roles, not theme-name branches in controls or
the settings schema. Unknown theme IDs remain stored and resolve visibly to
Mocha with a diagnostic. Incomplete bundled definitions are rejected.

`Theme.qml` exposes semantic surfaces/text/accent/colors/ink/slider roles and
radius calculation. `RenderTokens.qml` contains geometry/typography only, with
role-aware radius references. CC stays nominally 320px wide, 208px body, 36px
expanded status header, 60px tiles and 48px sliders. The compact-row width floor
still applies. User roundness does not expose padding, baselines, gaps, animation
timings or exclusive zone. Role overrides inherit master when null; radii clamp
to half the available dimensions. ActionChip, ValueSlider, IconSlider and
ControlTile consume the relevant semantic role.

Live commands (no Apply operation, writes through Settings):

```sh
quickshell ipc -c magi call settings status
quickshell ipc -c magi call settings theme catppuccin-mocha
quickshell ipc -c magi call settings roundness master 1
quickshell ipc -c magi call settings roundness surface default
quickshell ipc -c magi call settings iconPack magi-legacy
```

Reset/reload operations are explicit APIs, not actions performed on the user's
config during this final validation. Tests exercise them in isolated fixtures.

A module may bind `expandedWidth`/`menuHeight` or call
`ExpandableModule.requestGeometry(width,height)`. SharedStatusSurface queues
`retargetGeometry()` after bindings settle, reusing horizontal/vertical animations
from current values. An already-open view stays phase 3 with full content opacity;
selection, focus and reservation do not change. The regression grows the open
view to 440×346 total, interrupts a shrink, and settles at CC 320×244.
This supplies the future configured-layout path without implementing CC editing.

## Final validation and evidence boundaries

Final suite on **2026-09-27**, after resuming and reviewing the current tree:

| Check | Result |
| --- | --- |
| `python3 tests/settings/run.py` | PASS: 11 pure schema assertions; atomic helper read/write/backup/conflict/symlink/temp cleanup; five actual QML fixtures (missing, legacy, valid, invalid, partial), save/reload, 50 rapid edits during an in-flight save, section/full reset and change notifications. |
| `python3 tests/settings/appearance.py` | PASS: all ten role maps, selected color-contrast checks, real QML live palette/radius changes, reset, unknown-theme fallback, geometry tokens retained. |
| `python3 tests/settings/modules.py` | PASS: stable real module owners with no compact delegates; hidden Bluetooth navigation, Wi-Fi identity and close-before-password/cancel handoff using mocked hardware/password window. |
| `python3 tests/shared-status-surface/run.py` | PASS: 48 steps, including same-view growth and interrupted shrink. |
| qmllint over all 40 production QML files | Exit 0. Existing PanelWindow/anchor/Bluetooth metadata and Network unqualified warnings; SettingsStore adds unresolved QProcess::ExitStatus signal metadata warning. Actual Process tests pass. |
| `git diff --check` | PASS after final documentation review. |

S1's successful checkpoint was completed in the prior run before S2 began.
On resumption, the legacy test fixture was made explicit instead of reading the
now-migrated production file. One final diagnostic-runtime bug was found:
`Object.fromEntries` is unavailable in this QML engine. Bar IPC uses a plain loop
instead. No host/service behavior change was required.

Bounded anchored runtime check: disposable config with Wi-Fi/Bluetooth omitted
from placement, CC → close → Bluetooth detail → close → CC → close. Native bar
1920×48; all views reach phase 3 then return to 0; compositor reservation stays
`[0,48,0,0]`; logs clean. `exclusiveZone: 0` on the anchored Auto-mode bar is
expected—Hyprland derives its 48px reservation from native height. This was IPC/
compositor evidence, not pointer or visual acceptance. Temporary instance removed.

Final production instance **rp35kpi0mt**, PID **238095**, launched normally using
`quickshell -c magi -d`, combined mode. Quickshell 0.3.1; installed Hyprland
0.56.2/Qt 6.11.2; one eDP-1 output at integer scale 2. Twenty-six samples across
closed/opening/open/switching/closing CC→Wi-Fi→Bluetooth→Volume→CC showed one
1920×1080 quickshell layer at output-local `(0,0)` and `[0,48,0,0]` reservation.
Requested views became interactive at phase 3. Final phase 0 has catcher and
keyboard eligibility off, one healthy normal instance, no temporary fallback
instance, Mocha surface `#313244`, pill radius 8. Fresh log contains only startup
information. Settings reports `saved`, empty diagnostics/error, original placement.

No pointer injection, real connection/disconnection, password submission or new
fullscreen test was performed. Previous operator acceptance is not a new result
for this sprint. Multi-output, fractional scaling and full light-theme visual
contrast remain unverified. Tests of selected text/colored-control contrast are
not a blanket accessibility assessment.

## Exact source/test change inventory

Added:

- `settings/{SettingsSchema.js,SettingsMigrations.js,SettingsStore.qml,persist.py}`
- `modules/ModuleRegistry.qml`
- `components/bar/{ExpandableModule.qml,ModulePill.qml}`
- `components/bar/menu/AnchoredDetailHost.qml`
- `theme/ThemeRegistry.qml`, `theme/palettes/{registry.json,LICENSE-Catppuccin,LICENSE-Everforest}`
- repository `tests/settings/{run.py,schema.cjs,store.qml,modules.py,modules.qml,appearance.py,appearance.qml}`

Modified:

- `services/Settings.qml`, `settings.json`
- `components/bar/{Bar.qml,SharedStatusSurface.qml}`
- `components/controls/{ActionChip.qml,IconSlider.qml,ValueSlider.qml}`
- `plugins/bar/{wifi/Wifi.qml,bluetooth/Bluetooth.qml,volume/Volume.qml,controlcentre/ControlCentre.qml,controlcentre/ControlTile.qml}`
- `theme/{Theme.qml,RenderTokens.qml,qmldir}`
- repository `tests/shared-status-surface/lifecycle.qml`

Documentation reconciled: README, architecture, decisions, quickshell-reference,
research index, Settings architecture and render visual specification; this
checkpoint added. The prior spike's schema example and reference ledger remain
uncommitted as well. No unrelated dotfiles, Hyprland configuration, system-service
implementation, password-window implementation or experiment fixture was changed.

## Remaining work and review boundary

S1/S2 are complete within the tested scope. Internal layout dimensions, fonts,
legacy glyph strings, four CC tile assignments and the duplicated battery row
remain fixed. The two old palette QML definitions are unused compatibility-era
files; active palette literals live in registry data. User SVG assets/overrides,
a true IconRegistry, CC descriptor rendering/column consumption, Settings GUI,
profile and MPRIS are not implemented. No final pill-to-header morph work occurred.

Next bounded implementation is **S3: semantic IconRegistry backed initially by
magi-legacy, incremental role consumers and fallback tests**, followed separately
by validated CC layout/ordering (S4) and the Settings window (S5). Preserve the
accepted host and services throughout. Review this checkpoint before proceeding;
no commit or push was performed.
