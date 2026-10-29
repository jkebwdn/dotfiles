# Daily-use media and status styling — 2026-10-29

Baseline: `b0ccfb8c707aa9360aeea3bf7078c5f6456ee022`; main and origin/main were
0/0 with a clean tree and empty index. The operator accepted the visual previews,
requested centered icon/percentage content, and authorized production integration.
Native review of the subsequent colour-refinement extension is recorded below.
Zen's missing MPRIS metadata remains a separate unresolved browser limitation.

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
composes opaque fills before applying shared alpha once; icons/text remain opaque.
The icon is centered horizontally and vertically within its region, including when
the percentage is hidden. The default overall width is retained; percentage text is
likewise centered within its own region. Both regions share
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

The initial full canonical regression run completed: **92 PASS, 0 FAIL, 4 ENVIRONMENT,
0 UNKNOWN** (96 suites). Results: `/tmp/magi-daily-polish-final-regression/results.json`.
The four established limits are private Bluetooth D-Bus, clipboard image transport,
notification D-Bus and native-lock SOCK_SEQPACKET transport. The runner exits 2 for
these classified limits. The rounded-inner Battery follow-up also passed the focused
Phase12C, Tray and production runtime checks. Production source has since been
fast-forwarded and auto-reloaded. Settings, icon artwork and configuration symlinks
were unchanged by integration; operator edits during native testing are retained.
Remote synchronization and worktree removal follow the guarded closeout procedure.
No further feature phase is authorized.


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
all five requested themes have shaded presenter checks. The operator confirmed
“The refinement works correctly” after the live reload, accepting the independently
visible Battery controls and shade adjustments. The reload logged Configuration
Loaded without new QML errors. All 52 protected records were checked: only
operator-edited live Settings changed; other files and symlinks remain unchanged.
The final stable-source canonical run completed with **92 PASS, 0 FAIL,
4 ENVIRONMENT, 0 UNKNOWN** across 96 suites. Results are retained at
`/tmp/magi-daily-polish-shades-final-regression/results.json`; the four limitations
are the same D-Bus/image/lock transport restrictions listed above. Responsive editor,
five-theme presentation, media transitions, status state shades, Battery geometry
and sparse serialization checks pass. Remote synchronization uses the guarded
normal-push procedure; the temporary worktree is removed only after verified 0/0.


## Expanded status header follow-up — 2026-10-29

Baseline `fdca9cf` was clean and synchronized 0/0. The operator's native screenshots
showed dark custom Bar foregrounds remaining dark when their pill backgrounds faded
into the expanded Control Centre surface. Source inspection confirmed the same live
MorphingPillContent delegates retained iconColor; Battery likewise retained both
Bar foregrounds throughout sharedExpansion. This was a missing presentation-context
colour, not an icon pack or opacity defect.

The operator selected one shared colour control. Control Centre → Appearance →
Surface now exposes Status row colour using the existing semantic swatch selector,
a live icon/percentage sample, and optional Status row shade under Fine tune.
The sparse appearance.statusRowRole and statusRowShade fields resolve to text and
zero when absent/null. Schema remains 22; no migration or operator Settings rewrite.
The default expanded row now deliberately uses readable theme text independently
of custom Bar foregrounds. Collapsed Bar colours are unchanged.

ExpandablePlugin exposes the existing shared expansion to its loaded content.
Theme.statusRowForeground blends compact ink toward the shared expanded ink using
that progress, in step with the disappearing pill backgrounds. Battery uses the
same resolver for icon and percentage. The header retains its colour when switching
to Wi-Fi/Bluetooth/Audio menus within the same shared surface and restores Bar ink
on closing. Anchored presentations without a shared surface retain existing ink.
Application-owned Tray artwork and primary Control Centre tile colours are untouched.
No menu ownership, geometry, timer or service changes are introduced.

Focused validation passes: production Settings selector/shade interaction and live
sample, sparse persistence/invalid-field fallback, all four live header icons,
Battery icon/text, open-time role changes, five representative themes, menu switching
and close restoration. The synthetic Settings capture is retained at
`/tmp/magi-status-context-previews/cc-host.png`; it uses the bundled legacy glyph pack
for offscreen rendering. After the production auto-reload logged Configuration
Loaded without new QML errors, the operator confirmed “Works correctly”: header
icons and Battery percentage update together and return to original Bar colours
on close. All 52 protected records were unchanged by integration. The final
canonical full regression completed with **92 PASS, 0 FAIL, 4 ENVIRONMENT,
0 UNKNOWN** (96 suites), recorded at `/tmp/magi-status-context-full/results.json`.
The same established Bluetooth/notification D-Bus, clipboard image and native-lock
transport restrictions remain. Normal guarded Git synchronization and merged
worktree removal complete closeout; no additional feature work is included.
