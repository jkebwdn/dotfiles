# Daily-use media and status styling candidate — 2026-10-29

Baseline: `b0ccfb8c707aa9360aeea3bf7078c5f6456ee022`; main and origin/main were
0/0 with a clean tree and empty index. Candidate remains isolated pending native
review. This document does not claim production acceptance or resolution of Zen's
missing MPRIS metadata.

## Media: two distinct findings

The operator reproduced the reported issue with **Zen playing YouTube**, both when
opening Control Centre and after restarting MAGI. Read-only native D-Bus snapshots
provided by the operator establish:

| State | PlaybackStatus | GetAll Position | explicit Get Position | mpris:length (GetAll and Get) |
| --- | --- | --- | --- | --- |
| Progress missing | Playing | absent | 0 | absent |
| After pause/resume | Playing | 228000000 µs | 228000000 µs | 3541000000 µs |

The browser service name was `org.mpris.MediaPlayer2.firefox.instance_1_45`.
`CanSeek` was true in both snapshots. Capability does not establish a valid duration.
The pre-workaround data does **not** meet the required valid-duration/valid-position
precondition. MAGI cannot derive an honest progress fraction from it. No guessed
track length, stale previous-track duration, automatic pause/play or browser-specific
polling loop is added. Browser startup reporting remains an unresolved upstream
limitation; test another source and confirm browser fixes separately.

A separate MAGI defect was reproduced in the production-controller fixture:
opening Control Centre while playing did not notify the position binding until the
first one-second tick. Quickshell's getter advances without continuous notifications,
so a previously hidden view could display a stale position initially. The new test
fails before the change and passes afterward. `MediaController` now sets
`triggeredOnStart: true` on the existing 1000 ms timer and requires a valid progress
fraction. It emits the documented local `positionChanged()` refresh immediately on
opening/resuming or late valid metadata, then once per second only while playing,
with valid progress and Control Centre selected. This does not perform D-Bus polling.
No timer runs while hidden, paused, or without valid duration. Player selection,
transport, metadata bindings, seek signals and artwork ownership remain unchanged.

The production presenter test covers already-playing appearance with known duration
and nonzero position, initial visible progress, pause, resume, seek, track replacement,
missing/late support flags and duration, player replacement/disappearance, immediate
refresh, and stopped timer work when hidden or durationless. Existing stopped-player
behavior is unchanged. Native acceptance of the immediate-refresh change is pending;
it cannot repair the browser's absent duration.

### Source/API evidence

Inspected 2026-10-29; installed `quickshell --version` reports **0.3.2**.

- [Quickshell v0.3.2 player.hpp](https://github.com/quickshell-mirror/quickshell/blob/v0.3.2/src/services/mpris/player.hpp): position documentation prescribes local positionChanged notifications while monitoring the advancing getter. Compatible with the installed API; not a request to change playback.
- [Quickshell v0.3.2 player.cpp](https://github.com/quickshell-mirror/quickshell/blob/v0.3.2/src/services/mpris/player.cpp): positionSupported follows property existence; lengthSupported follows metadata. Playback changes issue immediate and delayed position queries; track changes query position. This supports separating browser initialization from MAGI's timer start. It does not prove browser correctness.
- [Mozilla bug 2065930](https://bugzilla.mozilla.org/show_bug.cgi?id=2065930): reports Firefox returning zero position and sometimes losing duration, recovered by pause/play after seeking. Related symptoms, not proof that this startup case has the identical internal cause.

Both live bus access and a private `dbus-run-session` fail with Operation not
permitted in this environment. The native snapshots above are operator evidence,
not successful in-sandbox native tests.

## Status and Battery model

The existing sparse `bar.modules` map stores optional `backgroundRole` and
`foregroundRole`. Wi-Fi/Bluetooth retain their existing `accentRole` foreground
controls and connected/unavailable semantics. Volume retains mute warning ink.
Clock/Date, Notifications/Clipboard and Tray also consume the shared pill family;
Workspace pills remain outside this item-background model. Tray application artwork
is never recoloured. Theme helpers resolve the role using the same shared pill
opacity and shared surface transparency policy, with no output-local Settings.

`ExpandableModule` keeps nonvisual ownership; `ModulePill` supplies the presentation.
StatusPill and the existing production presenters resolve overrides. The Settings
preview consumes the same resolvers and Battery presenter. No Bar host, placement,
menu animation or service-lifetime redesign is included.

BatteryPillContent owns one outer shape. Following the operator’s preview feedback,
the icon region rounds its inside corners too. The percentage fill continues behind
those curves so the outer pill stays connected. A small background-only layer
composes opaque fills before applying shared alpha once; icons/text remain opaque. The icon is centered horizontally and vertically within its region, including when
the percentage is hidden. The default overall width is retained; percentage text is likewise centered within
its own region. Both regions share
height, roundness, hover and expansion state; the outer Rectangle remains the sole
outer border owner. No default divider is added. Icon selection still uses the
unchanged IconRegistry.batteryRole. Hidden percentage removes its width entirely
and restores full icon-region roundness.

Battery uses `backgroundRole` for the icon region and optional
`percentageBackgroundRole` for the percentage, falling back to the icon background.
`percentageForegroundRole` defaults to the existing text ink; `foregroundRole`
controls the icon. Optional `showPercentage` defaults true, preserving the previous
always-visible-when-available behavior; no prior percentage preference existed.

Bar → Appearance → selected item exposes Icon colour (Text colour for Time/Date)
and Background colour. Battery labels its background Icon background, offers Show
percentage, and displays both background and foreground role controls directly in
the item editor. Fine tune holds the optional shade refinements.
Use shared background / Follow icon background reset inheritance. Existing semantic
role swatch selectors are reused. Family geometry/opacity/roundness remain in the
existing family section, collapsed for individual selections.

Expandable pills have a shared hover/pressed overlay and two-tone focus outline;
Return/Enter/Space use existing module actions. Utility and Tray focus outlines use
two palette roles to remain visible against accent backgrounds. Tray pointer/menu
state and its keyboardInteraction guard are preserved; no sticky selection is added.
This is not completion of Bar-wide native keyboard-grab/traversal debt.

## Schema and migration

Schema remains **22**. The existing map already preserves sparse item keys through
serialization; additive optional fields need no document rewrite. Validation accepts
current semantic roles or null inheritance; malformed overrides fall back safely.
No defaults are added to existing documents, no schema migration runs, and old
appearance remains determined by the existing shared status style. Tests cover exact
schema-22 document preservation, inheritance, independent roles, invalid values and
save/reload. No live settings.json is staged or modified.

## Validation and evidence

- `daily-polish/run`: real presenter/controller tests and optional screenshots.
- `daily-polish/schema`: sparse persistence and neutral default-resolution tests.
- `runtime-visual/run:daily-polish.qml`: production module backgrounds, keyboard
  activation, open/close restoration including Control Centre and Bluetooth.
- Existing Phase12C editor checks cover responsive layouts and family/item ownership.
- Representative themes: Catppuccin Mocha, Everforest Dark Hard, Kanagawa Wave,
  One Light and Gruvbox Light. Screenshots include default, independent green/blue/
  yellow semantic backgrounds, split Battery and hidden percentage.

Generate evidence with `MAGI_DAILY_PREVIEWS=/path/to/existing/directory python3
linux/magi/tests/daily-polish/run.py`. The software-rendered gallery deliberately
uses the bundled MAGI Legacy glyph pack: the offscreen software backend does not
render MultiEffect semantic SVG tinting. An OpenGL attempt failed to create its
context. Production default SVG appearance and native interaction still require
native review; these screenshots are synthetic evidence, not native acceptance.

The final full canonical regression run completed: **92 PASS, 0 FAIL, 4 ENVIRONMENT,
0 UNKNOWN** (96 suites). Results: `/tmp/magi-daily-polish-final-regression/results.json`.
The four established limits are private Bluetooth D-Bus, clipboard image transport,
notification D-Bus and native-lock SOCK_SEQPACKET transport. The runner exits 2 for
these classified limits. The rounded-inner Battery follow-up also passed the focused
Phase12C, Tray and production runtime checks. Native acceptance is pending. Live
Settings, icon artwork, configuration symlinks and production source remain untouched.
The candidate is committed on its isolated branch for review. Production push/integration
and worktree removal await successful native closeout. Do not start
another feature automatically.


Preview follow-up: the operator accepted the rounded inner icon corners and requested
centering within that region. The fixed 9 px icon offset is replaced by region-based
centering; split and percentage-hidden center alignment are covered by the presenter test.

The subsequent accepted preview follow-up centers percentage text in its own region
as well. Presenter checks cover one-, two- and three-digit percentages and vertical
alignment; the existing hidden-percentage behavior remains intact.


## Native-review refinement — 2026-10-29

The initial approved source was fast-forwarded to local main and auto-reloaded with
Configuration Loaded. All 52 protected file/symlink records matched immediately
after integration. Subsequent operator testing changed only Bar item preferences.
The operator found the percentage-background control too hidden under Fine tune,
and requested CC-style light/dark refinement. Both Battery background controls and
percentage foreground are now directly visible in the main item editor.

Fine tune reuses Theme.shadeAccent: -1 lightens fully toward the palette's light
anchor, 0 preserves the role, +1 darkens toward its dark anchor. Optional item fields
backgroundShade, foregroundShade and foregroundOffShade default to zero. Wi-Fi and
Bluetooth retain connected accent versus disconnected state ink; Volume retains its
mute warning. The on/off shades refine those existing state colours. Tray background
can be refined but application artwork stays untouched. Battery adds independent
percentageBackgroundShade and percentageForegroundShade. An inherited percentage
background follows the icon shade unless overridden; selecting an explicit role
starts at neutral shade unless its own shade was configured. Shared alpha is applied
after colour shading, once for the composed Battery backgrounds.

All shade fields are sparse, validated to [-1,1], nullable for neutral/inheritance,
and require no schema migration. UI tests operate the visible role selectors and
refinement slider, runtime tests exercise connected/disconnected/muted states, and
all five requested themes have shaded presenter checks. Native acceptance and final
remote synchronization remain pending for this extension.
