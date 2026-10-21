# Phase 10B — bar geometry and output routing

## Review status and execution-boundary incident

Phase 10B is accepted and complete. The operator confirmed the physical checklist
and explicitly authorized the exact source/docs/tests commit and push on 2026-10-21. No restart/reload IPC or process-control command
was issued. Initial implementation discovered too late that the live symlinked
source tree is watched: edits caused automatic reloads, including an intermediate
SettingsHeading load failure (corrected). This was not an isolated initial pass.

The correction pass first identified the sole shell (PID 1573, instance
`p71s064nt`), captured log offset/time and settings bytes outside the repository,
and obtained operator IPC evidence: Settings `saved`, revision 23, no diagnostics
or pending edits. The reviewed patch applied cleanly and changed only the
undefined-list guard in OutputPolicy and its regression test. It is now applied;
the redundant patch artifact was removed. Main-output/reservation corrections
were validated in an isolated copy before touching watched runtime source.
The live log records automatic reload and `Configuration Loaded` at 19:47:22 on
2026-10-20, with no new OutputPolicy warning. The same sole PID remains running.

The original settings snapshot and existing backup establish schema 13→14 and
`appearance.mediaProgressRole` accent→green during initial development. Migration
is expected; no evidence establishes operator intent for green. Under the
operator's correction instruction, the role change is classified as unintended
live-state mutation during development/testing. A Phase 10A test fixture uses
green, but the exact writer is not proven. After an exact backup outside the
repository, the authorized repair replaced only that role value with accent;
all other bytes were preserved. Schema 14 and subsequent operator Bar choices
(top, inset 5, offset 0, external bars enabled) were retained. Live IPC subsequently
confirmed accent, schema 14, `saved`, revision 1 and empty errors/diagnostics.

Correction evidence and exact backups are in
`/tmp/magi10b-correction-20261020-194246/` (disposable local evidence, not source).
The repair backup is `settings-before-repair.json`. See protected-state record.

## Pre-10B architecture audit (before implementation)

Baseline 212496b0c170bad35ed328a0241f8c429282aa31, origin/main divergence 0 0.
ShellRoot creates one Bar.PanelWindow without an explicit screen. Thus output
selection is delegated to Qt/Quickshell/compositor; there is no configured primary
output or universal Hyprland primary concept. The accepted laptop output is eDP-1.
Production selects the combined host: full logical output height, top/left/right
anchors, transparent strip, explicit 48px exclusive zone. The visible background
is individual rounded pills, not a full-width rectangle. Theme.barEdgeMargin is
internal padding and is not a screen inset.

Bar owns ModuleRegistry sessions and SharedStatusSurface. Network, Bluetooth,
audio, Settings, theme, icons, Calendar/model, Hub and other services are QML
singletons. Calendar is a separate shared-surface family inside the same native
window; MenuController provides global exclusivity. Hub is a separate singleton
zero-reservation overlay, with Settings preview borrowing the bar status surface.
Toast/fullscreen state currently follows the sole bar. Wi-Fi authentication is
inline; pending operations live in its module session. Registry instances include
no duplicate NetworkManager/BlueZ/PipeWire backend. Module-level scanning writes
must be coordinated before multiple presentations are safe. Bar currently owns
one magi IPC handler and one IdleInhibitor; both need deliberate multi-bar handling.

WorkspaceModel lists global normal numbered workspaces; highlighting currently
uses Hyprland.focusedWorkspace. Clicking dispatches the existing Lua focus route.
There is no production SystemTray import or tray module. Clock/status/utility
modules can repeat using shared singleton data. Settings Bar currently configures
status icon size and Left/Centre/Right module lanes, not screen-edge placement.
Schema is 13; tests cover Settings, modules, shared-surface lifecycle, Calendar,
Hub and runtime visuals, but no production multi-output host exists.

Implementation and validation findings follow below.

## Shared state and per-output presentation

`BarFleet` is one Scope under the existing ShellRoot. It supplies active
`ShellScreen` objects directly to `Variants`. Each delegate is one existing Bar
presentation, never another ShellRoot. `SurfaceOrigin` holds only presentation
routing. Settings, theme, icon packs, Calendar/model, clock, NetworkManager,
BlueZ, PipeWire, MPRIS, notifications, Clipboard, Emoji, Wallpaper and system
actions retain their existing singleton ownership and activation paths.

ModuleRegistry remains per bar: these are presentation/session objects (including
inline Wi-Fi form state), not service backends. Network scanning now has leases
from requesting sessions, so closing an old presentation cannot disable the new
origin's scan. A removed presentation releases its lease; an already-submitted
NetworkManager operation continues independently. Password text is never copied
between outputs. One fleet-owned Caffeine inhibitor follows the main bar; one
fleet-owned `magi` IPC endpoint preserves the existing interface.

## Output eligibility and main-output rule

Only current Quickshell.screens objects with positive logical width/height are
eligible. No object is reconstructed from coordinates, scale, list index or display
order. The old configuration has no explicit output preference to preserve.
The deliberate default selection is:

1. An active internal connector (`eDP`, `LVDS`, `DSI`), sorted by actual name if
   more than one is present. This preserves accepted eDP-1 laptop placement
   without hard-coding that connector as a universal rule.
2. The previously selected main object, while it remains eligible.
3. Currently focused **active** connector, sampled only when a new main must be
   selected because no eligible prior main remains.
4. Deterministic connector-name order among eligible outputs; null with none.

Focus changes alone never resynchronize or move the main bar. The retained object
wins over focus. Active recognized internal panels always take priority.

Internal connector detection is a convention, not a universal hardware guarantee.
On machines without a recognized internal panel, initial selection samples focus
then falls back to connector-name ordering. No user-configured primary setting is
being discarded. Deterministic tests cover retention, removal, inactive focus and
output enumeration changes.

`bar.externalDisplays` defaults to false. False selects only main; true selects
all eligible active objects, including main. Width/height eligibility changes are
reactive. Removed objects leave Variants and are destroyed; reconnect supplies a
fresh object/delegate even when the connector name is identical. Disabling the
setting removes external presentations immediately and leaves services and main
presentation alive. A removed origin closes its status/Calendar family or Hub,
clears routing references and closes a pinned Settings preview. No invisible
retained popup is rehomed. Reopening selects a valid output again.

## Geometry, reservation and rounding

Schema 14 adds only four Bar keys:

| Key | Default | Valid values |
| --- | --- | --- |
| position | top | top, bottom |
| horizontalInset | 0 | integer 0–64 logical px |
| edgeOffset | 0 | integer 0–32 logical px |
| externalDisplays | false | boolean |

Settings → Appearance → Bar exposes Position, Horizontal inset, Edge offset and
Show bar on external displays, followed by the existing status-icon and module
controls. Canonical Settings setters provide live updates. The single 13→14
migration preserves existing values, unknown fields and unrelated preferences;
normal schema filling supplies new defaults. Schema remains 14 for these
corrections. The only authorized direct operator settings edit is the surgical
media-progress-role repair documented above.

The native combined host stays full width/full logical height to support its
existing dismissal/input region. Its **bar strip and presentations** are inset;
this is external bar geometry, in addition to unchanged internal Theme padding.
The strip is 48px high. Offset moves the strip inward from the selected edge.
No scale multiplication or raw-pixel conversion is used. Left/right plus exactly
one of top/bottom anchors select the reserved edge. The explicit exclusive zone
is **48 + edgeOffset** logical pixels, on that edge only: offsets 0/12/32 reserve
48/60/80 respectively. Horizontal inset does not change reservation thickness.
There is one reservation per enabled output, zero on an output with no bar;
removal or disabling external bars destroys that output's reservation. Position
changes release the old edge and reserve the new one without another window.
The previous experimental fixed-48 policy was rejected because a nonzero offset
would let tiled content overlap the displaced strip. The strip itself stays 48px.
On impossibly short synthetic outputs the effective offset is bounded by available
height; ordinary supported outputs use the configured offset unchanged.

Inset is reduced when the measured module widths need more room. On still
narrower outputs, centre and then left presentations become transparent and
noninteractive while retaining their measurements, avoiding circular layout
changes. The configured module lists are not rewritten. System/status controls
remain available. The existing bar consists of individually rounded pills on a
transparent strip; there are no hidden full-width background corners to expose.
Existing semantic pill/surface rounding remains, without a new floating capsule.

## Origin routing, lifecycle and workspace semantics

Bar triggers pass their actual output object to MenuController/Calendar/Hub.
MenuController still owns one global selected menu and history; only its owning
bar can request an expanded presentation, catcher or keyboard focus. Changing
origin immediately clears the old presentation's animations/body before the new
presentation opens. Same-origin clicks toggle; a different-origin click retargets.
Calendar remains its own surface family with its own shared CalendarModel.

Hub remains one retained native host. It binds its screen, readiness and pinned
CC preview to the Hub origin. CC action catalogue routes inherit the menu origin;
right-click Settings and utility bar buttons supply explicit origin. Keyboard IPC requests (`magi open/toggle`, `hub open/toggle`) sample the currently
focused monitor and resolve its actual enabled ShellScreen at invocation. They
fall back to main if that output has no enabled bar. Explicit bar clicks and
in-surface navigation retain their originating output. Focus changes alone move
neither an open surface nor the main bar. A shortcut on a new output retargets the
singleton; repeating it on the same output toggles normally. This changes no
Hyprland keybindings and adds no service/backend instances.
Origin removal closes Hub. Toasts stay main-only; Calendar and Hub fullscreen
suppression follow their selected output. Hub retains its accepted explicit
Escape dismissal / desktop click-through behavior; it does not gain a global
outside-click catcher. Status/Calendar retain consuming outside-click dismissal.

Bottom geometry positions the surface above its trigger, moves the shared header
to the bottom and places its content above. Text/icons are upright. Calendar's
header close target moves with that header. Top retains downward expansion.
Hub keeps its independent configured vertical selector placement on the chosen
output; it is not an edge-anchored bar popup.

Workspaces retain the existing global numbered catalogue and existing Lua
`hl.dsp.focus({workspace=...})` dispatch. Each bar highlights only its associated
HyprlandMonitor.activeWorkspace, via Hyprland.monitorFor(output). Selecting an
already-associated workspace focuses that workspace/monitor; it does not silently
move workspaces to the clicked bar's monitor. Backend discovery is shared and the
initial workspace refresh is fleet-owned. No synthetic workspace IDs are added.

There is no production tray module to repeat. This milestone adds none. Any future
tray implementation must audit menu/window ownership before choosing all-bars or
main-only presentation; current application/utility buttons use shared models.

## Left / Right Bar Feasibility

**Classification B: substantial component redesign. Recommendation: implement
later in a separately reviewed phase; do not expose Left/Right now.**

| Component | Orientation coupling and likely changes |
| --- | --- |
| Bar lanes | Three horizontal Row/centre anchors must become an axis-aware layout with independent vertical ordering and bounded overflow. |
| Workspaces | Horizontal 28px cells can form a Column; pill radius and keyboard/pointer geometry need vertical tests. |
| Clock/date | Current full time/date strings exceed 48px. Need a designed compact upright representation or alternating/time-only affordance, with full date in Calendar. |
| CC/status | Horizontal persistent status header widens into a panel. A vertical rail cannot reuse this width morph; needs an icon stack and a side-opening surface/header composition. |
| Calendar | Adjacent clock/date absorption assumes one horizontal header and similar y coordinates; requires new origin/absorption contract. |
| Media | Currently inside CC, not a separate bar module. Full media body can remain horizontal in a side surface; compact rail media needs a separate design if added. |
| Battery/utility buttons | Percentage text and horizontal content must fit a 48px cross axis or use icon-only modes. |
| Tray | Absent today; future tray icon ordering, context menus and overflow need orientation-aware ownership. |
| Popup hosts | Side openings, x/y expansion axes, focus masks, screen bounds, dismissal and pinned Hub preview all need coverage. |
| Settings | True four-way preview, major/cross-axis inset labels and orientation-specific module constraints, not a rotated screenshot. |

Shared orientation tokens (axis, edge, cross size, inward direction) would help
Bar/Workspace layout and reservation, but **are insufficient** for compact
clock/date and the morphing shared status header. Keep service/model APIs shared;
introduce explicit horizontal/vertical presenter interfaces and popup geometry.
A planning estimate is 5–8 focused implementation days plus separate visual and
multi-output acceptance, subject to agreeing the compact status/clock design.
No code rotation/stretching or purported vertical preview is included.

## API evidence (inspected 2026-10-20)

Installed: Quickshell 0.3.1 / Arch 0.3.1-1; Hyprland 0.56.2 / Arch 0.56.2-4.
Official v0.3.0 family documentation was checked against installed QML metadata
(`/usr/lib/qt6/qml/Quickshell/quickshell-core.qmltypes` and
`Hyprland/_Ipc/quickshell-hyprland-ipc.qmltypes`). No upstream code was copied.

- [Variants](https://quickshell.org/docs/v0.3.0/types/Quickshell/Variants/):
  creates/destroys delegates from unique model values; instancesChanged exists
  locally. BarFleet uses this for output lifetimes. Documented reload caveat:
  do not mutate the variant model during delegate creation.
- [ShellScreen](https://quickshell.org/docs/v0.3.0/types/Quickshell/ShellScreen/):
  name/model/serial and logical geometry are exposed; disconnected cached wrappers
  become dangling and reconnect does not revive them. Local C++ metadata calls
  this QuickshellScreenInfo, exported to QML as ShellScreen. Hence membership and
  identity, not name caches, govern presentation lifetime.
- [QsWindow](https://quickshell.org/docs/v0.3.0/types/Quickshell/QsWindow/): screen
  is writable; devicePixelRatio describes Qt logical coordinates. Hub retargets
  one host; no physical-pixel arithmetic is needed.
- [PanelWindow](https://quickshell.org/docs/v0.3.0/types/Quickshell/PanelWindow/):
  anchors select edge, explicit exclusiveZone uses Normal mode and requires one
  or three anchors. Production has three, with no native margins. Offscreen tests
  cannot prove the compositor's final reserved rectangle.
- [HyprlandMonitor](https://quickshell.org/docs/v0.3.0/types/Quickshell.Hyprland/HyprlandMonitor/):
  activeWorkspace is monitor-local and nullable; installed monitorFor accepts
  QuickshellScreenInfo. This supports local highlighting over a global catalogue.

## Live acceptance plan and initial correction checks

This was the original plan; completed operator-reported results are recorded in
the physical acceptance session below.

Do not deliberately reload/restart without separate authorization. Source edits
can automatically reload and therefore require the preflight described above.
The operator's read-only desktop health check found **two** connected outputs,
not a standalone laptop: eDP-1 at scale 2 (logical 1920×1080), HDMI-A-1 at scale 1.5
(logical 2560×1440). Existing external-bars=true yielded exactly one MAGI layer
per output, both PID 1573, and each top reservation `[0,48,0,0]` at offset 0.
Internal MAGI status reported a 1920×1080 combined host, reservation 48, closed
Calendar/status, no input catcher or keyboard capture, and no theme diagnostic.
No output connection or Bar-setting changes were requested for this check.
This establishes current mixed-scale health, not completed physical acceptance
or an actual standalone-output test.

Operator visual feedback: bars display normally, but keyboard shortcuts opened
controls/Settings on the laptop despite an external focused window. The operator
confirmed this was **keyboard invocation**, not a failed HDMI bar click. The
cause was explicit mainBar routing for `magi` IPC and retained/main routing for
Hub IPC. The focused-output shortcut correction above addresses these paths;
the operator subsequently confirmed Control Centre and Settings shortcuts now
follow the focused display on both HDMI and the laptop. This targeted check does
not sign off the full physical acceptance sequence. The main-output
retention policy is intentionally independent of shortcut destination.

The subsequent operator-approved live gate started with external bars OFF to
confirm laptop-only presentation, then enable external bars and inspect one
48+offset reservation per enabled output.
Exercise mixed scale (2 / 1.5), Top→Bottom→Top, inset 0/16/64 and offset 0/12/32,
Calendar/CC/Wi-Fi/Bluetooth/Hub from both bars, rapid retargeting, Escape/outside
click, Settings pinned preview and workspaces on both monitors. Disable/re-enable
external bars with a popup open; disconnect/reconnect with Calendar, Wi-Fi form
and Hub open. Confirm no orphan windows, stale input mask, extra reservation or
service restart. Confirm normal bars remain beneath the independent secure lock
surfaces without changing lock code. Hypridle, PAM, display profiles, Hyprmon,
fingerprints, Power & Idle and all Phase 10C work remain untouched.

## Automated validation and previews

The runners use temporary shell copies and offscreen Qt; system adapter fixtures
replace NetworkManager/BlueZ/audio/actions. The new harness exercises real
Variants, Bar, ModuleRegistry, SharedStatusSurface, CalendarSurface, HubWindow,
Settings controls and workspace presentation. Native PanelWindows become
FloatingWindows only in the fixture; fake output objects are supplied through
the presentation identity boundary. FloatingWindow keeps its user-resized width,
so the narrow-output test explicitly emulates the compositor's resize. Captures
use an extra fixture Item around the unchanged production visual children.

Coverage includes: eDP-only; two outputs OFF/ON; ON→OFF→ON; disconnect/reconnect
with a new object; removal of all outputs; one reservation property per enabled
presentation; scale-independent logical geometry; per-monitor workspace highlight
and unchanged click dispatch; actual CC/Wi-Fi/Bluetooth trigger clicks on each
bar; Calendar trigger and toggle; singleton CC retarget; scan lease handoff;
status/Hub origin removal; actual singleton Hub output binding and visibility;
top/bottom Calendar/CC bounds; inset 0/16/64; edge offset 0/12/32; 320px narrow
layout; Settings control bounds and persistence. Pure policy tests additionally
cover offset 32, invalid/zero-size outputs, 80×60 geometry and invalid settings.
The applied guard has undefined-output initialization regression checks.
Additional tests cover focused-once main selection, no migration on focus changes,
Settings reload retaining existing presentations, and top/bottom reservations
48/60/80 with zero on the opposite edge.

Existing 48-step shared-surface tests and runtime pointer tests cover Escape,
outside dismissal, rapid transitions and pending Wi-Fi authentication. The new
suite supplements those rather than claiming offscreen native focus/mask proof.
Existing schema tests retain their assertions with current-version expectations
advanced to 14 (future-version fixtures to 15). The old Hub preview navigation
test now covers the Phase 10A Surfaces/Hub routes instead of the retired Icons
page. No runtime behavior was changed to satisfy obsolete fixture routes.

[Preview gallery](previews/phase10b/index.html) includes top/no inset, top with
inset/offset, bottom Calendar and CC, two-output representation, and the actual
Settings Bar page. All PNGs are direct offscreen captures. Qt software rendering
omits some masked/tinted icon effects; these are geometry evidence, not final
GPU/visual acceptance or actual mixed-DPI rendering. Left/Right has no preview.

### Results

The initial implementation ran the following suites; correction reruns are
recorded separately below. All listed initial commands exited 0:

| Command (from linux/magi unless stated) | Result |
| --- | --- |
| `python tests/phase10b/run.py` | Policy/schema plus production multi-output lifecycle PASS; previews captured |
| `python tests/settings/run.py` | Schema, atomic persistence and five store fixtures PASS |
| `python tests/settings/presentation.py` | All Settings pages, keyboard, palettes, reset/drafts: 0 failures |
| `python tests/settings/modules.py` | Module ownership/inline authentication: 0 failures |
| `python tests/settings/modules.py wifi-inline.qml` | Secret clearing, retry, late completion and geometry: 0 failures |
| `python tests/shared-status-surface/run.py` | 48 lifecycle steps, 0 failures |
| `python tests/calendar/bar.py` | Production bar, slot absorption, family handoff, rapid toggles, fallback PASS |
| `python tests/calendar/presentation.py` | Content/keyboard/locale and Settings/persistence PASS |
| `python tests/hub/run.py` | Six host/interaction fixtures and exact copy/restore checks PASS |
| `python tests/runtime-visual/run.py` | Workspace transitions, utility routing, pointer/Escape/outside and pending Wi-Fi PASS |
| `python tests/runtime-visual/run.py hub.qml` | Pinned production preview and updated navigation PASS |
| `python tests/phase10a/run.py` | Phase 10A regression PASS |
| `node tests/{calendar,emoji,clipboard,wallpaper,launcher}/schema.cjs` (each separately) | All five schema regressions PASS |
| Reviewed startup guard `git apply --check`, then `git apply` | Applied cleanly during correction; redundant artifact removed |

Qmllint on shell/fleet reported no diagnostics; direct Bar/Hub host lint retains
the installed metadata's “PanelWindow is not creatable” warning. Runtime fixtures
successfully instantiate the adapted hosts. No lint result is substituted for
native compositor validation. Expected offscreen mask/no-IPC/no-compositor
messages are filtered by the established runners; other warnings/errors fail.

### Correction regression results (2026-10-20)

The isolated `review/` copy ran nine focused runners, all exit 0:
`tests/phase10b/run.py`, `tests/settings/run.py`,
`tests/settings/presentation.py`, `tests/calendar/bar.py`,
`tests/shared-status-surface/run.py` (48 steps),
`tests/settings/modules.py wifi-inline.qml`, `tests/hub/run.py`,
`tests/runtime-visual/run.py`, and `tests/phase10a/run.py`.
These cover output lifecycle/hotplug/toggles, main selection, schema preservation,
Bar controls, logical geometry/reservations, top/bottom surface bounds, Calendar,
CC/Wi-Fi/Bluetooth origin routing, singleton Hub, monitor-local workspace behavior,
inline authentication, outside-click/Escape and Phase 10A regression.
The changed production/test files were copied byte-for-byte from this tested copy.
No unrelated assertions were weakened. Test adapters now retain the production
reservation binding; migration assertions distinguish defaults from existing
operator Bar choices instead of expecting the live user's settings to be defaults.
Logs are `/tmp/magi10b-correction-*.log`.

The shortcut follow-up adds production-entry-point tests for CC, Wi-Fi,
Bluetooth, Calendar and all five Hub modes: HDMI→internal retargeting, same-output
toggle, no movement from focus changes alone, disabled external bar fallback,
and missing/null focus fallback. Its larger lifecycle fixture has a 150-second
runner timeout (previously 90); no assertion is removed. The affected Phase 10B,
Hub, runtime visual and 48-step shared-surface suites are rerun in the isolated
copy: all four exited 0. Results are retained in `/tmp/magi10b-shortcut-*.log`.
After the saved-state/PID/log/settings preflight, the tested correction was applied.
Automatic reload completed at 20:13:50 with no new warnings and the same sole
PID 1573. Settings bytes remained identical to the repaired snapshot.


### Protected-state record

Original pre-10B settings SHA-256:
`4c81c18696ff40a5a809f3c019c7591ac813eb740c6e104fd1ed9a2b9345f32f`.
The original bytes match the existing operator backup
`~/.local/state/magi/settings-backups/1a422e0b68f6b5416ba21730daac37a3b136cc33a886e9f7de71a5dd986d7e3f.json`.
This was audited, not restored over later user choices.
Before authorized repair:
`b33d12702a825860a5d071ff1924bdefe364c7d8c0e7337616cc4e863d5311af`.
After repair:
`dce1ae0c7ba71ff5fe413d710baba9eddd46b3d1ddf73a6dca813d591f6d8ece`.
The exact replacement was `"mediaProgressRole": "green"` →
`"mediaProgressRole": "accent"`, with all other bytes unchanged, including
schema 14, theme, icons, Hub toggle red and custom Bar values. settings.json stays
unstaged and excluded from the eventual Phase 10B commit.

The twelve other protected regular files match the original hash manifest
`/tmp/magi-10b-protected.json`. The untracked flavor remains a symlink to
`~/.local/share/magi/theme-orchestrator/yazi/current/flavor`; neither entry nor
target was edited. No staging, commit or push. No PAM, lock, Hypridle,
Hyprmon/profile or Phase 10C edits. The initial live-reload/settings incident is
retained explicitly above; the correction does not erase it.

## Physical acceptance session — 2026-10-20

The committed preflight remains `212496b0c170bad35ed328a0241f8c429282aa31`,
origin/main divergence 0 0. One normal MAGI shell remains PID 1573. Operator
preflight IPC reports Settings saved, schema 14, no error/diagnostics, Top,
horizontal inset 5, edge offset 0, external bars enabled. Native output evidence
shows eDP-1 scale 2 and HDMI-A-1 scale 1.5, with one MAGI bar layer per output and
48px top reservations. The already accepted focused CC/Settings shortcuts were
not needlessly repeated.

On 2026-10-21 the operator explicitly confirmed that “all tests” includes the
full physical checklist, including geometry and unplug/reconnect actions.

| Physical check | Result and evidence |
| --- | --- |
| Both bar presentations, eDP scale 2 / HDMI scale 1.5 | Operator PASS; initial native snapshot shows one bar layer per output. |
| HDMI Calendar/CC/Wi-Fi/Bluetooth and applicable Hub bar-click routing; representative laptop routing; singleton handoff/dismissal | Operator PASS. |
| Focused CC/Settings shortcuts | Previously confirmed on both outputs; not redundantly repeated. |
| External bars OFF/ON | Operator PASS. OFF snapshot proves HDMI reservation `[0,0,0,0]` while eDP stays `[0,48,0,0]`. |
| Shortcut fallback while external bar disabled | Operator PASS; fallback accepted at the final gate. |
| Horizontal inset 16, both outputs, no clipping/overlap, anchors and 48px reservation | Operator PASS; restored to 5. |
| Edge offset 12, 60px top reservation, no tiled overlap | Operator explicitly confirmed this action and measured-reservation check passed; no separate 60px compositor snapshot was saved. Restored to 0. |
| Bottom, released top reservation, 48px bottom reservation, upward Calendar/CC and usable modules | Operator PASS; restored to Top. |
| Monitor-local workspace highlights and existing workspace click action | Operator PASS. |
| HDMI unplug/reconnect, stable laptop/main, fresh external bar and restored routing | Operator PASS. |
| Unplug HDMI with CC open, safe closure and immediate laptop reopening | Operator PASS. |

The snapshot labelled external-on was captured while OFF and is not used as
native proof of ON. The subsequent `final.json` snapshot on 2026-10-21 reports
only eDP-1 active: logical 1920×1080 at scale 2, one MAGI layer, reservation
`[0,48,0,0]`, closed Calendar/menu, and the same sole PID 1573. It proves healthy
standalone state after testing, not final simultaneous dual-output presence.
The operator explicitly accepted this standalone final state after leaving the
office, relying on the completed physical dual-output checks. No repeat connection
is required. The final acceptance authorizes staging the exact 52-path allowlist,
committing `magi: add multi-monitor bar support`, and pushing after the divergence
check. Protected settings.json and all t15g state remain excluded.

Final preferred Bar values are Top, horizontal inset 5, edge offset 0, external
bars ON. Settings reports saved, schema 14, error empty, diagnostics empty. All
settings bytes match the acceptance preflight. The other twelve protected
regular-file hashes and flavor symlink are unchanged. The live log from acceptance
preflight through the final standalone check has no new entries or warnings.

All eight isolated final regression runners exited 0: Phase 10B lifecycle/policy
(including hotplug, origin/shortcut routing, geometry and workspaces), Settings
schema/store, Settings presentation, Calendar bar, Hub, Wi-Fi inline lifecycle,
shared-status 48-step lifecycle and Phase 10A. `git diff --check` passes. No lock
or native security suites were run. Local evidence and runner logs are retained
outside the repository in `/tmp/magi10b-acceptance-20261020-201938/`.

## Exact Phase 10B path set

Repository-relative paths; excludes all protected operator-local state.

### Modified (37)

```text
linux/magi/.config/quickshell/magi/components/bar/Bar.qml
linux/magi/.config/quickshell/magi/components/bar/ExpandableModule.qml
linux/magi/.config/quickshell/magi/components/bar/ExpandablePlugin.qml
linux/magi/.config/quickshell/magi/components/bar/SharedStatusSurface.qml
linux/magi/.config/quickshell/magi/components/bar/UtilityPill.qml
linux/magi/.config/quickshell/magi/components/calendar/CalendarSurface.qml
linux/magi/.config/quickshell/magi/components/hub/HubWindow.qml
linux/magi/.config/quickshell/magi/components/settings/pages/BarPage.qml
linux/magi/.config/quickshell/magi/plugins/bar/controlcentre/ControlCentre.qml
linux/magi/.config/quickshell/magi/plugins/bar/wifi/Wifi.qml
linux/magi/.config/quickshell/magi/plugins/bar/workspaces/Workspaces.qml
linux/magi/.config/quickshell/magi/services/Calendar.qml
linux/magi/.config/quickshell/magi/services/Hub.qml
linux/magi/.config/quickshell/magi/services/MenuController.qml
linux/magi/.config/quickshell/magi/services/Network.qml
linux/magi/.config/quickshell/magi/services/SettingsWindowState.qml
linux/magi/.config/quickshell/magi/services/qmldir
linux/magi/.config/quickshell/magi/settings/SettingsMigrations.js
linux/magi/.config/quickshell/magi/settings/SettingsSchema.js
linux/magi/.config/quickshell/magi/shell.qml
linux/magi/README.md
linux/magi/docs/README.md
linux/magi/docs/architecture.md
linux/magi/docs/decisions.md
linux/magi/docs/quickshell-reference.md
linux/magi/tests/calendar/bar.py
linux/magi/tests/calendar/schema.cjs
linux/magi/tests/clipboard/schema.cjs
linux/magi/tests/emoji/schema.cjs
linux/magi/tests/launcher/schema.cjs
linux/magi/tests/hub/run.py
linux/magi/tests/runtime-visual/hub.qml
linux/magi/tests/runtime-visual/run.py
linux/magi/tests/settings/run.py
linux/magi/tests/settings/schema.cjs
linux/magi/tests/settings/store.qml
linux/magi/tests/wallpaper/schema.cjs
```

### Added (15)

```text
linux/magi/.config/quickshell/magi/components/bar/BarFleet.qml
linux/magi/.config/quickshell/magi/components/bar/OutputPolicy.js
linux/magi/.config/quickshell/magi/services/SurfaceOrigin.qml
linux/magi/docs/design/phase10b-bar-multimonitor.md
linux/magi/docs/design/previews/phase10b/bottom-calendar.png
linux/magi/docs/design/previews/phase10b/bottom-controlcentre.png
linux/magi/docs/design/previews/phase10b/external-top.png
linux/magi/docs/design/previews/phase10b/index.html
linux/magi/docs/design/previews/phase10b/settings-bar.png
linux/magi/docs/design/previews/phase10b/top-inset-calendar.png
linux/magi/docs/design/previews/phase10b/top-inset-controlcentre.png
linux/magi/docs/design/previews/phase10b/top-no-inset.png
linux/magi/tests/phase10b/lifecycle.qml
linux/magi/tests/phase10b/policy.cjs
linux/magi/tests/phase10b/run.py
```

### Deleted (0)

None.

### Protected dirty paths (excluded) (14)

```text
linux/magi/.config/quickshell/magi/settings.json
linux/t15g/bash/.bashrc
linux/t15g/ghostty/.config/ghostty/config.ghostty
linux/t15g/gtk3/.config/gtk-3.0/gtk.css
linux/t15g/gtk3/.config/gtk-3.0/settings.ini
linux/t15g/hypr/.config/hypr/hyprland.lua
linux/t15g/hypr/.config/hypr/hyprland.lua.bak.1792314927
linux/t15g/hypr/.config/hypr/hyprmon.lua
linux/t15g/hyprmon/.config/hyprmon/profiles/Home Office Docked.json
linux/t15g/hyprmon/.config/hyprmon/profiles/Norm t15g Screen.json
linux/t15g/nvim/.config/nvim/init.lua
linux/t15g/yazi/.config/yazi/flavors/magi.yazi
linux/t15g/yazi/.config/yazi/init.lua
linux/t15g/yazi/.config/yazi/theme.toml
```
