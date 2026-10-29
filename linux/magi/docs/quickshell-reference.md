## Phase 14B — Audio routing and inline Tray toggle (2026-10-27)

Audio provides output/input selection, grouped application volumes, shared sliders,
content-fit sizing and contextual menu appearance controls. Super+A toggles Audio;
Super+T temporarily shows/hides Tray icons in the main-output Bar without saving
layout changes. Visibility modes are retired. Schema22 retains compatibility and
cleans the old field; WirePlumber remains routing authority and auto-switch is
deferred. The operator accepted the complete native checklist; native reload
evidence and all 22 final regression commands pass.
[Audit, decisions, tests and native evidence](design/phase14b-audio-tray-behaviour.md).

## Bluetooth 0.3.2 audit (2026-10-27)

Installed metadata confirms pair/cancelPair/connect/disconnect/forget, paired,
bonded, pairing, state and writable trusted. dbusPath supplies stable identity.
Pair is asynchronous; its implementation does not explicitly trust/connect. No
Agent1 QML types/challenges or structured operation errors are exported. MAGI
therefore uses GIO for application-scoped authentication and actions,
while keeping Quickshell device properties authoritative for presentation.
[Versioned sources, compatibility and remaining tests](design/bluetooth-pairing.md).

## Phase 12G accepted — final ownership

The operator accepted Ghostty background-only alpha/blur, shared MAGI outer-panel
transparency including the Bar, global blur amount and exact default restoration.
Text/icons/controls/artwork stay opaque. Individual surface styles are preserved.
Whole-client opacity remains rejected. Theme Orchestrator is the sole Ghostty
publisher. **Transparency → Transparency & blur** owns shared controls; global
amount is explicitly compositor-wide and separate from participation. Schema 19
is neutral on migration. Phase 12H activation work remains deferred.
[Final acceptance, compatibility, tests and history](design/phase12g-window-visuals.md).

## Current Phase 12G extension: shared transparency and blur

The operator included MAGI menus and the Bar in one shared background-only
opacity/blur policy. The unified **Transparency & blur** page also hosts the
previously approved global amount. Native per-surface blur regions exclude
transparent input catchers; wallpaper/lock remain separate. Individual styles
are preserved underneath. This supersedes earlier application-only shell
exclusions below. Implementation, offline checks and operator native acceptance are complete. See [design](design/phase12g-window-visuals.md).

# MAGI — Quickshell Technical Reference

## Phase 12G approved extension — global blur amount

After native Ghostty blur was visually confirmed working, the operator explicitly
approved a separate global control. **Appearance → Advanced shell styling → Global
blur** now offers opt-in amount (size 1–40). The UI clearly states that this affects
all blurred desktop surfaces. Passes, blur enablement, client opacity, fullscreen
and per-surface participation are untouched. Applications remains the separate
background-alpha/participation owner. Earlier prohibitions on global blur writes
below describe the application-only scope; this separate opt-in control supersedes
those prohibitions for blur size only.

See [Phase12G design](design/phase12g-window-visuals.md) for transactions and native acceptance.

## Phase 12G correction — application background alpha and blur

Whole-client opacity is rejected: native testing faded foreground content. Live
management was released and 1/1 opacity restored, with fullscreen 1 and blur 8/4
unchanged; the operator confirmed visual rollback. Corrected work is isolated.
Applications now proposes one native background alpha plus independent blur,
Ghostty as reference, and honest deferred/inherited support. Theme Orchestrator
remains the sole Ghostty generated-file writer; no competing overlay. The proposed
narrow no-blur handle never writes client opacity or global blur. Schema 19 is
redesigned before commit, production activation is unwired in this candidate,
and Phase 12H is not begun. Prior entries below are historical checkpoints.
[Current design, capability matrix, rollback and gallery](design/phase12g-window-visuals.md).



## Phase 12E: shared Hub presenters (2026-10-23)

Verified locally on Quickshell 0.3.2 (Arch Linux). `HubSelector.qml` and
`HubSurface.qml` extract the existing production QML without introducing new
Quickshell APIs. Runtime retains `modeButtons`, selector/surface aliases, focus
routing and service dispatch; editor uses local mode requests. `ClipboardCardFrame`
shares the existing card background/radius/SurfaceBorder contract. Notification
samples use the production NotificationCard with synthetic data and inert callbacks.
QtTest pointer, keyboard, lifecycle and palette regressions exercise these paths.
Software offscreen captures are architecture evidence, not native compositor acceptance.
See [Phase 12E](design/phase12e-hub-settings-ownership.md) for scope and limitations.


## Phase 12B — existing palette bindings (2026-10-22)

No new Quickshell API is introduced. ThemeRegistry FileView feeds Theme bindings;
Settings selectors consume labels and IDs. QtTest switches all 18 themes in an
isolated HOME/XDG setup, tests production presenters and the asynchronous Process
bridge. Software Qt capture cannot validate shader-rendered icons/artwork.

[Phase 12B evidence and limits](design/phase12b-theme-library.md).

## Phase 12A — preview configuration input (2026-10-22)

Installed Quickshell 0.3.2 / Qt 6.12.0. PreviewControlGrid reuses the existing
SettingsDragHandle MouseArea and keyboard signals; Qt Item.mapToItem maps pointer
coordinates into one grid. No native cross-window drag API or shell IPC is needed.
The test-only FloatingWindow host is unchanged in role; production stays inside
Settings/Hub. Offscreen software does not render the production MultiEffect
SVG/artwork shaders; OpenGL/EGL initialization was unavailable in the sandbox.
See [API sources, evidence and completed native visual gate](design/phase12a-control-centre-configurator.md#sources-and-compatibility).



## Phase 10B — accepted and complete (2026-10-21)

Optional external bars share the existing services. ShellScreen-keyed Variants,
origin-scoped status/Calendar and singleton Hub routing, Top/Bottom, horizontal
inset and edge offset are implemented with schema 14 defaults preserving the
single top bar. Each enabled output reserves 48 + edgeOffset logical px. The operator confirmed the physical dual-output, hotplug and geometry checks.
The operator accepted the standalone final state after leaving the office and
authorized the exact Phase 10B commit/push; protected local state is excluded.
[Architecture audit, policy, API evidence, tests, previews and vertical feasibility](design/phase10b-bar-multimonitor.md).
The startup guard is applied; the correction auto-reload was clean. Main output
prefers internal, then retained eligible main, then focused active output once,
then connector-name order. Keyboard shortcuts target the focused enabled output
without moving main; bar clicks retain their origin. The checkpoint records the initial live-reload incident
and authorized one-key settings repair. Physical checklist results and the final standalone snapshot are recorded there.
No lock/authentication, Hypridle or Phase 10C changes.

Phase 10A fallback correction: selected pack → same-ID MAGI Default → bundled
SVG placeholder. No parent inheritance or user overrides; [audit and previews](design/phase10a-icon-fallback.md).

## Phase 10A — accepted and complete (2026-10-20)

Baseline `649326c77022bd400bf241336894102d50ff0616` was synchronized at `0 0`.
MAGI Lock remains complete at production `magi-lock 0.1.0-3`; Hyprlock is retired,
Hypridle remains. This milestone does not change lock/authentication architecture.
Live review passed; Clipboard option B retains pinned-first ordering with newest-on-entry.
Phase 10C remains deferred; Phase 10B now has a separate review checkpoint above.
See [Phase 10A ownership, tests, previews and deferred work](design/phase10a.md).


> Phase 2E, including 2E.1/2E.2, is natively accepted. See the
> [final acceptance and source allowlist](design/runtime-phase2e-finalization.md).
> Dated earlier review status below is historical; final Hub persistence, Schema 12,
> explicit-location weather and retired-tool state are the accepted baseline.

## Phase 2E.2 verified patterns

Production Qt Quick Switch owns both runtime and Settings toggles. Native Font weight values 400/700, bound Text implicitHeight, and existing RowLayout vertical centring are verified in offscreen production fixtures. Weather follows existing Quickshell.Io Process/StdioCollector conventions: stdin JSON, one worker, Timer watchdog and stale-config rejection. Official Open-Meteo endpoints were checked 2026-10-17; [API evidence and limits](design/runtime-phase2e2.md#weather-investigation-and-implementation). Native GPU quality remains unverified.

## Phase 2E.1 — native review pending (2026-10-17)

Production QtTest verifies Region unions for Hub content/selector and its temporary child Popup overlay, natural QtQuick.Layouts measurements/centres, role swatches, and sidebar save states. WlrKeyboardFocus.OnDemand is compositor-mediated; offscreen focus tests are not native direct-shortcut certification. Shared anchored lifecycle tests still pass. [Phase 2E.1 checkpoint](design/runtime-phase2e1.md).

> Phase 2E.1: Hub uses Escape after child interactions; Super+Q is only an ordinary compositor application binding, not a Hub close requirement.

## Phase 2E production checks — 2026-10-17

Existing QtQuick Rectangle border overlays do not own input or affect layout. Existing
RoundedArtwork masks now also serve the single leading notification preview. Retained
status delegates interpolate with the shared surface; Hub growth uses production implicit
heights and output-clamped anchor coordinates. NotificationModel's Timer is independent of
presentation, with controlled timestamp tests and real private-bus protocol regressions.
No new Quickshell API assumptions or backend ownership changes. Offscreen geometry checks
do not establish native GPU mask/animation quality or compositor keybind dispatch.
[Focused verification and native limits](design/runtime-phase2e.md).

## Hub Settings composition verification — Phase 2C (2026-10-17)

Installed Quickshell 0.3.1 / Qt 6.11.2 metadata in
`/usr/lib/qt6/qml/Quickshell/quickshell-core.qmltypes` confirms Region's nested `regions`,
`Intersection.Subtract`, and TransformWatcher a/b/transform. Hub reuses the existing
[TransformWatcher v0.3.1 pattern](https://quickshell.org/docs/v0.3.1/types/Quickshell/TransformWatcher/)
already recorded below: read transform as a dependency before scene-coordinate mapping.
Its subtraction is a pointer-input region, not a compositor reservation or visual mask.

Existing PanelWindow/Exclusive focus, ExclusionMode.Ignore, retained Loaders, native
TextField/ComboBox handlers, AfterItem Escape and RoundedArtwork/MultiEffect remain.
No new native window API or external artwork dependency. Real offscreen Hub+Bar tests
exercise mask geometry, retained Settings pages, preview ownership and live tuning;
keyboard/pointer tests exercise the selector and child Escape. This does not establish
native layer focus, file chooser behaviour, click-through dispatch or GPU mask edges.
See [test scope and operator checks](design/runtime-phase2c.md).

Zen Copy uses the existing clipboard_backend.py --copy-text JSON/stdin boundary, as Emoji does. Production pointer tests capture the final wl-copy bytes for all ten palettes and verify reactive semantic background guidance; no second clipboard implementation or new Quickshell API was added.

## Theme Orchestrator bridge — installed 0.3.1, 2026-10-14

Enrollment pointer coverage now uses QtTest `mouseClick` on the real AppearancePage with an offscreen Window, validates viewport visibility of inline confirmation, and exercises the real Process backend in isolated XDG roots. Earlier service-only checks did not cover this interaction.

The orchestrator reuses existing `Process`/`StdioCollector` stdin JSON and exit
handling, `Connections` and `FileView.watchChanges` patterns. Installed API metadata
was inspected in `/usr/lib/qt6/qml/Quickshell/Io/quickshell-io.qmltypes` (started,
exited, write, stdinEnabled); existing SettingsStore demonstrates the file watcher.
A real offscreen QML test verifies asynchronous worker results, theme selection,
Follow persistence and newest-request handling. The Starship base watcher requests
recomposition without changing the user's base. This does not require a new
Quickshell API or native-window geometry. See [test commands and environment
limitations](design/theme-orchestrator.md#validation-and-acceptance--final-v1-refinement).



## Wallpaper APIs — 2026-10-12

Installed Quickshell 0.3.1 / Qt 6.11.2 production-component tests validate
`Process` JSON stdin/collectors, asynchronous `Image` with bounded `sourceSize`,
`GridView` delegate virtualization and raw Hyprland monitor-event connections.
Wallpaper reuses Hub's `PanelWindow`/exclusive-keyboard/ignore-exclusion pattern
but owns a separate window. Offscreen wrapper tests cannot establish native focus
or compositor reservation. [Versioned sources and test limits](design/wallpaper-manager.md#api-evidence-inspected-2026-10-12).

## Control Centre catalogue checkpoint (2026-10-10)

Installed Quickshell0.3.1 and Hyprland0.56.2 remain the target. No new native
window/focus API: catalogue navigation reuses Hub.open and the existing collapse
gate. All four routes pass a real SharedStatusSurface/HubContent fixture; the
live Hub regression passes native focus restoration and48px reservation.
Reboot extends the existing Process adapter with logind CanReboot and systemctl.
Versioned API sources, local systemd262 evidence and test limitations are in the
[catalogue checkpoint](design/control-centre-action-catalogue.md).

## Hub host checkpoint (2026-10-06)

Quickshell0.3.1 `PanelWindow` + `ExclusionMode.Ignore` + Exclusive layer keyboard
focus now belongs to one `HubWindow`; the input Region excludes the48px bar.
Persistent child content swaps visibility without replacing the native layer.
Native Hyprland0.56.2 tests verify stable layer identity, restored application
focus, menu handoffs, fullscreen suppression/recovery and unchanged48px reservation.
Offscreen QtTest covers actual selector/interior/outside pointer events; this is
not a native pointer acceptance claim. See [versioned source evidence, test scope
and limitations](design/magi-hub.md). Earlier dedicated-host entries below are
historical API checkpoints.

## Emoji API checkpoint (2026-10-05)

On installed Quickshell 0.3.1, Emoji reuses Launcher's Exclusive overlay focus and
ExclusionMode.Ignore pattern. FileView loads generated local Unicode metadata;
Process passes a JSON-line on stdin to the existing clipboard helper. Content and
search have no layer-shell dependencies. Exact sequence and real-component tests
pass; operator focus/dismissal/copy checks pass. See [versioned API/data evidence](research/emoji-picker-apis.md)
and [checkpoint](design/emoji-picker.md). The temporary host reserves no space.

## Calendar API checkpoint (2026-10-04)

SystemClock.Minutes supplies one shared Date; Qt locale methods provide weekday
and month labels. TransformWatcher keeps mapToItem anchoring reactive. Calendar
reuses SharedStatusSurface and the existing Bar PanelWindow; no native Calendar
window or additional reservation. Real Qt6.11 fixtures validate locale indices,
formatting, model navigation and Settings persistence; live Hyprland checks verify
48px reservation and no new layer. See [versioned API evidence and remaining
compatibility checks](research/calendar-apis.md).


## Launcher API checkpoint (2026-10-04)

Installed Quickshell 0.3.1 and Hyprland0.56.2 remain the target. The launcher uses
PanelWindow + overlay layer + temporary Exclusive keyboard focus with
ExclusionMode.Ignore. DesktopEntry.execute() is not used because the versioned
documentation explicitly omits terminal and field-code handling. GIO provides
both discovery and launch instead. Hidden-app context menus use Qt6.11
Controls Menu with explicit Popup.Item, contained in the existing layer. See [source evidence and compatibility](research/application-launcher-apis.md).


## Clipboard0.3.1 — inspected/tested 2026-10-03

Installed qmltypes and the official v0.3.1 core header expose `clipboardText` only;
the official0.3 docs warn that Wayland reads require a focused Quickshell window.
There is no first-party background MIME history API in this installed version.
Sources, version details and compatibility constraints are recorded in the
[Clipboard checkpoint](research/clipboard-manager-checkpoint.md).

Production uses existing `Process` with `stdinEnabled`, `write`, `SplitParser.read`
for structured messages from MAGI's backend. Its data-control helper uses installed
protocol XML, not private Quickshell APIs. Isolated service imports do not activate
capture. Existing `FloatingWindow`, plus a class+title Hyprland rule as used by
Settings, provides a normal floating surface with540×660 initial geometry. The
first Exclusive layer-shell experiment was corrected after operator feedback:
keyboard capture prevented typing elsewhere until closed. There is now no new
layer, full-output mask or reservation. Primary selection is not captured.

## Notifications0.3.1 — inspected/tested 2026-10-03

Detailed evidence and limitations are in the
[notification checkpoint](research/notifications-toasts-checkpoint.md).
Official [NotificationServer](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Notifications/NotificationServer/)
provides tracking and explicit advertised capabilities. Installed metadata agrees.
MAGI advertises body/actions/icon-static; no markup, sound, inline reply, hyperlinks
or persistence. Set tracked=true synchronously when accepting a new notification.

Tagged [server.cpp](https://github.com/quickshell-mirror/quickshell/blob/v0.3.1/src/services/notifications/server.cpp)
demonstrates same-object replacement, no new-notification signal for replacement,
registration of org.freedesktop.Notifications and retry after an existing owner
exits. Constructing the server is therefore a migration action, not passive discovery.
The QML API exposes no ownership status or original replaces_id. Verify owner
externally; MAGI keeps production construction gated until approved handoff.

The permanent-ownership close-out supersedes that migration gate: production
ShellRoot now calls the existing idempotent activation method on completion. A
private-bus fixture and clean live process restart prove automatic ownership.
The 2026-10-04 retirement removes SwayNC's package and D-Bus activation files;
the earlier temporary mask is retired. See the [host checkpoint](research/legacy-shell-retirement-checkpoint.md).

Tagged [notification.cpp](https://github.com/quickshell-mirror/quickshell/blob/v0.3.1/src/services/notifications/notification.cpp)
stores wire timeout directly in milliseconds despite a seconds comment in the
header. The installed-binary test confirms1234→1234. Native invoke emits action
and dismisses unless resident; expire/dismiss/client close use reasons1/2/3.
Closed objects must no longer be used. Quickshell exposes image/provider URLs;
MAGI drops provider images on close. Same-identifier changed action text stays
stale in the installed version; identical updates lack a reliable QML receipt signal.

The [Desktop Notifications1.3 protocol](https://specifications.freedesktop.org/notification/latest/protocol.html)
and [hints](https://specifications.freedesktop.org/notification/latest/hints.html)
define action pairs, IDs, close reasons, timeouts, transient and resident behavior.
Quickshell reports spec1.2; MAGI does not claim1.3 activation-token support. Private
bus tests exercise creation/replacement/actions/close, not native application focus.

`HyprlandToplevel.lastIpcObject` requires explicit refresh per the official
[0.3.1 reference](https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/HyprlandToplevel/).
FullscreenMonitor refreshes toplevels/monitors on relevant events and uses compositor
fullscreen=2 on a visible workspace of its output. Policy tests distinguish
maximized/off-output/hidden-workspace clients; live fullscreen2 suppression and
operator-confirmed exit/history/pointer recovery now pass on the single output.

Tagged [region.cpp](https://github.com/quickshell-mirror/quickshell/blob/v0.3.1/src/core/region.cpp),
`setItem/build`, maps Items to scene coordinates but observes only the immediate
Item's x/y/size, not its ancestors. ToastHost explicitly binds window-local region
x/y/width/height to the animated wrapper/card, avoiding stale native geometry on
stack reflow. Three-card removal/update/mask binding tests pass with the native
window wrapper substituted offscreen; native pointer checks subsequently passed
in the operator's bounded live acceptance, not through the offscreen fixture.

Official0.3.1 [PanelWindow](https://quickshell.org/docs/v0.3.1/types/Quickshell/PanelWindow/)
and [ExclusionMode](https://quickshell.org/docs/v0.3.1/types/Quickshell/ExclusionMode/)
(inspected2026-10-03) document that setting exclusiveZone changes exclusionMode to
Normal, whereas Ignore reserves nothing and ignores other reservations. Notification
panels must set Ignore alone: setting both produced native y110 instead of62.
After removing exclusiveZone, the live host measures y62 and bar reservation remains48.

## State, progress and image masking — inspected 2026-10-02

Quickshell 0.3.1 [ObjectModel.values](https://quickshell.org/docs/v0.3.1/types/Quickshell/ObjectModel/)
is a reactive list. [HyprlandWorkspace](https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/HyprlandWorkspace/)
raw `lastIpcObject` does not refresh automatically. Workspaces.qml therefore uses
native id/name objects, filters positive numeric workspaces and sorts the list;
creation/removal/order/special IDs are regression-tested. Live compositor evidence
on this output includes workspaces1 and2; operator dynamic checks remain pending.

[MprisPlayer0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Mpris/MprisPlayer/)
exposes position/length in seconds with explicit support flags. Position normally
requires polling for continuous progress. MediaController only monitors when a
supported player is playing and CC is selected; no progress is invented otherwise.
Tests cover supported/unsupported progress and nonlinear changes. Real-player
progress-border appearance is still an operator check.

[Qt MultiEffect](https://doc.qt.io/qt-6/qml-qtquick-effects-multieffect.html)
provides source masking/colorization. Installed Qt6.11.2 metadata and qmllint accept
the properties; RoundedArtwork uses a layered rounded alpha mask, not Rectangle.clip
(which clips a bounding rectangle). A live CC capture shows the rounded avatar.
Icon separates semantic RGB tint from state alpha so source alpha is multiplied.
The web page tracks current Qt6; local validation is on the installed runtime.

[PopupWindow0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell/PopupWindow/)
documents grabFocus dismissal and warns that changing it while open only applies
after a hide/show. This sprint leaves it unchanged; inline keyboard behavior in
the anchored fallback is **not established** by geometry-only regression tests.

## Idle inhibition (verified 2026-09-28)

Applicable version: installed Quickshell 0.3.1. The official
[IdleInhibitor reference](https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/IdleInhibitor/)
documents `import Quickshell.Wayland`, writable `window` and `enabled`
properties, a required non-null associated window, and compositor policy over
whether an inhibitor is respected. The
[0.3.1 changelog](https://quickshell.org/changelog/#v031) records Wayland idle
inhibition support. Both were inspected 2026-09-28.

Local installed metadata
`/usr/lib/qt6/qml/Quickshell/Wayland/_IdleInhibitor/quickshell-wayland-idle-inhibit.qmltypes`
exports the same properties, and public `Quickshell/Wayland/qmldir` imports
the implementation module. MAGI attaches one inhibitor to its existing bar
PanelWindow for Caffeine. The API guarantees request association; actual
inhibition remains compositor policy and requires
`idle-inhibit-unstable-v1`. A bounded local idle-timeout test remains required
to prove Hyprland honors this surface in the current session.

## Evidence baseline

Initially inspected **2026-09-24** and updated **2026-09-26**. The current
uncommitted implementation builds on repository HEAD
`35c282012f2d749081a3f8b1821f01bf0b8aa6ea`. Source paths below are relative
to `.config/quickshell/magi/`. Official findings use the **v0.3.1**
documentation and installed 0.3.1 QML type metadata.

The initial findings remain documentation evidence. Later sections identify
runtime behavior tested during the combined-host and production-plugin
checkpoints. Those tests cover one Hyprland output at integer scale 2, not
every compositor, output topology or scale.

## Installed environment

| Component | Local verification result |
| --- | --- |
| Quickshell | `quickshell --version`: 0.3.1, Arch Linux, blank revision; `pacman -Q quickshell`: 0.3.1-1 |
| Hyprland | `Hyprland --version`: 0.56.2, commit `efb50993780079460b0cbed1363e2166a2de1d9f`; package 0.56.2-3 |
| Qt base | `pacman -Q qt6-base`: 6.11.2-3 |
| Qt declarative | `pacman -Q qt6-declarative`: 6.11.2-2 |

The production-plugin checkpoint launched the same installed Quickshell
binary. Quickshell's exact upstream build commit is still not supplied by its
version output. Package revisions and upstream version numbers differ.

## F004 — Bluetooth adapter and device capabilities

- Sources: [Bluetooth v0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell.Bluetooth/Bluetooth/),
  [BluetoothAdapter v0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell.Bluetooth/BluetoothAdapter/)
  and [BluetoothDevice v0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell.Bluetooth/BluetoothDevice/),
  inspected 2026-09-26. Installed metadata:
  `/usr/lib/qt6/qml/Quickshell/Bluetooth/quickshell-bluetooth.qmltypes`.
- Documented behavior: Bluetooth exposes a default adapter and device models;
  adapter `enabled` and `discovering` are writable. Devices expose
  connected/paired/bonded state, names, connection state, connect/disconnect
  methods and optional battery data. `battery` is valid only when
  `batteryAvailable` is true.
- Local source: `services/Bluetooth.qml` wraps the default adapter, tracks
  connected devices and exposes real optional battery. The production plugin
  limits connection attempts to already paired/bonded devices and does not
  claim a pairing-agent flow.
- Locally tested behavior: real adapter enable/disable, discovery, known-device
  listing, paired-device connect/disconnect, live state, bounded scrolling and
  conditional pill width passed. The tested widened pill did not visibly show
  the device name, and the device/backend did not expose visible battery data.
- Compatibility: qmllint 0.3.1 reports the installed `BluetoothAdapter`
  return type as unresolved even though the runtime module loads and the
  tested operations work. Treat this as incomplete installed tooling metadata,
  not broader-version proof.
- Remaining tests: multiple adapters, adapter removal/hotplug, pairing-agent
  prompts, devices that expose battery, and connected name/header rendering.

## F001 — Window-relative popup anchors

- Source: [PopupAnchor v0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell/PopupAnchor/), inspected 2026-09-24.
- Documented behavior: window and item anchoring are mutually exclusive.
  Item-relative placement is calculated when shown; subsequent movement
  requires updateAnchor(). Rect coordinates are relative to the selected
  item/window. Adjustment controls how a popup fits on screen. Default
  edges are top/left and gravity bottom/right. Coordinate mapping itself
  is not reactive.
- Local source: `components/bar/ExpandablePlugin.qml:346` sets anchor.window;
  lines 348–374 map the pill's bottom-left and disable adjustment.
- MAGI relevance: explicit window coordinates avoid relying on the pill's
  original position while the right Row moves during expansion.
- Compatibility: the API explanation is for 0.3.1; screen-edge behavior
  still depends on geometry/compositor interactions. Legacy item-anchored
  Wi-Fi and tooltip windows use a different strategy.
- Required tests: neighbouring-pill movement, rapid switching, narrow
  outputs, fractional scaling and screen changes. No new local UI test.

## F002 — TransformWatcher as a binding dependency

- Source: [TransformWatcher v0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell/TransformWatcher/), inspected 2026-09-24.
- Documented behavior: watches geometry along the path between two items.
  The transform property's value is undefined; it exists to trigger
  expression updates. The algorithm favors `a` being an ancestor of `b`.
- Local source: `components/bar/ExpandablePlugin.qml:330` uses the bar's
  contentItem as `a` and pill as `b`. Both anchor bindings read transform
  before calling mapFromItem(). The read is intentional, not dead code.
- MAGI relevance: updates coordinates when row layout moves the pill.
- Compatibility: matches the documented 0.3.1 pattern; retain the actual
  barWindow reference rather than inventing an attached-window property.
- Required tests: motion during interrupted animations and window/screen
  lifecycle changes. Historical positioning tests were not repeated.

## F003 — Settings loading does not implement saving

- Source: [FileView v0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell.Io/FileView/), inspected 2026-09-24.
- Documented behavior: watchChanges emits fileChanged; calling reload()
  reads changes. An adapter receives loaded content; writeAdapter() writes
  adapter state. blockLoading covers initial text()/data() reads and does
  not make reload() blocking; blockAllReads is a separate option.
- Local source: `services/Settings.qml:17` sets watchChanges and blockLoading,
  reloads on fileChanged and exposes JsonAdapter properties. It has no
  writeAdapter(), setText() or setData() call.
- MAGI relevance: file-backed configuration and reload are implemented;
  runtime setting changes have no explicit disk-save path. The persistence
  comment in `theme/Theme.qml:10` is stronger than the implementation.
- Compatibility: do not infer adapter startup ordering or blocking reload
  from blockLoading alone. No settings mutation was performed in the audit.
- Required tests: startup/default timing, invalid JSON, external reload,
  invalid plugin IDs, and persistence if a save mechanism is later approved.

## Phase 1 — Windows, animation, input and lifecycle

Research completed 2026-09-24; no runtime tests performed. See the
[detailed report](research/quickshell-windows-and-lifecycle.md) for evidence,
compatibility limits, test matrix T01–T08 and the unimplemented design.
Current MAGI HEAD is `7c79b1e85623bf4ccff9c5d2d7c62e703fe3a848`; its QML is
unchanged from the initial audit. Package versions above were rechecked.

Upstream v0.3.1 resolves to commit
`1a4716cde794a59928d9d9fc15f2afc7a95de360`; this is the researched source
release, not a verified Arch build hash. Qt pages displayed 6.11.2 when read.

| Finding | Concise result and primary source | Detail / local test |
| --- | --- | --- |
| W01 | [Auto exclusion](https://quickshell.org/docs/v0.3.1/types/Quickshell/ExclusionMode/) attempts reservation from dimensions/anchors; Ignore does not reserve or respect other exclusion zones. | W01; T01/T07 |
| W02 | [PopupWindow](https://quickshell.org/docs/v0.3.1/types/Quickshell/PopupWindow/) requires a valid anchor. Source confirms screen assignment belongs to its parent despite conflicting documentation prose. | W02; T04/T07 |
| W03–W04 | Preserve window-relative watcher mapping. [Adjustment](https://quickshell.org/docs/v0.3.1/types/Quickshell/PopupAdjustment/) applies Flip, Slide, then Resize; enabling it changes the seam policy. | W03–W04; T01 |
| W05–W06 | [Animation](https://doc.qt.io/qt-6/qml-qtquick-animation.html) natural completion differs from cancellation. Existing standalone handlers cannot be copied unchanged into grouped transitions. | W05–W06; T02 |
| W07 | [Item opacity](https://doc.qt.io/qt-6/qml-qtquick-item.html#opacity-prop) does not disable actions; clip and surface input mask are separate concerns. | W07; T03 |
| W08 | [OnDemand](https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/WlrKeyboardFocus/) is compositor-mediated; item focus alone does not establish window keyboard eligibility. | W08; T04 |
| W09 | [HyprlandFocusGrab](https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/HyprlandFocusGrab/) can notify dismissal without hiding; native popup grabFocus may bypass the close animation. | W09; T03/T04/T06 |
| W10 | [Keys](https://doc.qt.io/qt-6/qml-qtquick-keys.html) supports explicit Escape routing for delivered events; no global Escape guarantee follows. | W10; T04 |
| W11 | [Loader](https://doc.qt.io/qt-6/qml-qtquick-loader.html) owns loaded content; deactivation releases it. Hiding a window is a separate lifecycle operation. | W11; T05 |
| W12 | [Tagged source](https://raw.githubusercontent.com/quickshell-mirror/quickshell/v0.3.1/src/window/proxywindow.cpp) preserves content while deleting hidden popup/layer-shell backing windows. | W12; T05/T06 |
| W13 | [LazyLoader](https://quickshell.org/docs/v0.3.1/types/Quickshell/LazyLoader/) is optional for whole windows; accessing a loading item can block. | W13; T05 |
| W14 | [ShellScreen](https://quickshell.org/docs/v0.3.1/types/Quickshell/ShellScreen/) references do not revive after reconnect. Keep geometry in logical pixels and choose an explicit host screen. | W14; T07 |

The report distinguishes API contracts, tagged implementation observations,
MAGI source, historical user tests and proposals. The preferred first test
keeps the current animation/geometry and evaluates a Hyprland dismissal
adapter. Keyboard delivery remains unresolved; preserve Wi-Fi's separate
password panel. No design implementation has been approved or performed.

## Remaining research and recording requirements

Review the phase-1 design and isolated test plan before proceeding. Networking
object lifetime/authentication/failure handling, Bluetooth, media and external
reference-project investigations remain separate future work. The
[WifiNetwork v0.3.1 page](https://quickshell.org/docs/v0.3.1/types/Quickshell.Networking/WifiNetwork/)
remains the networking starting point inspected during the initial audit. No conclusions
about their implementations are established here.

For each finding record source URL and inspection date, documentation version
or repository commit, exact component/function, demonstrated behavior, MAGI
relevance, compatibility and required tests. Keep actual test outcomes distinct
from suggested acceptance criteria.


## Shared status-surface presentation checkpoint — 2026-09-26

`components/bar/SharedStatusSurface.qml` reuses the existing QtQuick
NumberAnimation, Loader and Item patterns; no new Quickshell window API is
introduced. All module body Loaders stay instantiated, and hidden/outgoing
bodies are explicitly disabled (W07/W11). Individual host Loaders are inactive
in shared mode. Bar retains its PanelWindow/Region/OnDemand contract.

Local startup evidence: Quickshell 0.3.1, PID 171817, one logical 1920×1080
layer at (0,0), scale 2 and monitor reservation [0,48,0,0]. Fresh log contained
normal configuration-loaded messages only. Shared navigation/interruption,
focus/password handoff and fullscreen interaction are pending operator tests;
previous per-plugin acceptance must not be reported as testing this refactor.


Local follow-up: the shared-surface lifecycle test reproduced a dependent-binding
ordering failure in synchronous property-change handlers. Scheduling selection
and compact-width synchronization with the existing `Qt.callLater` pattern
passes 41 windowless regression steps on installed Quickshell 0.3.1/Qt 6.11.2.
This is local test evidence, not a universal binding-notification order claim.
See `tests/shared-status-surface/README.md` and the design checkpoint for details.


Operator follow-up accepted complete collapse, reliable repeated/rapid Control
Centre reopening and in-surface Bluetooth detail/Back navigation after the
binding-order fix. Correlated live logs remain clean. This bounded result does
not establish full focus/password/fullscreen or compatibility validation.


The subsequent literal-render CC pass changes presentation only. The existing
module width/height targets still animate in place; body-specific insets and
outer color/radius now have default-preserving overrides. The expanded
windowless regression passes 44 steps, including returning from taller details
to CC 244L/Volume 136L total height. No new Quickshell native API was introduced.
The subsequent operator screenshot shows the reference presentation, and the
operator confirms compact-height restoration on return from Wi-Fi/Bluetooth.
This establishes the bounded geometry recheck, not new API or full regression
guarantees.


## Settings spike — Quickshell 0.3.1 (2026-09-26)

Targeted documentation findings, **not local runtime tests**:

- [FloatingWindow](https://quickshell.org/docs/v0.3.1/types/Quickshell/FloatingWindow/)
  is the normal top-level window candidate for Settings. Its name does not imply
  that Hyprland must place it in floating mode. Test compositor focus/placement
  separately; no layer-shell or exclusive-zone ownership is proposed.
- [FileView](https://quickshell.org/docs/v0.3.1/types/Quickshell.Io/FileView/)
  supports atomic writes and save/error notification. A watcher may observe own
  writes; saving and reloading require explicit coordination. At the spike baseline Settings
  had no save path (F003); S1 now supplies the writer described below. Atomic writes do not resolve competing editors.
- [Mpris](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Mpris/Mpris/)
  and [MprisPlayer](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Mpris/MprisPlayer/)
  provide the future media backend; controls must check per-player capabilities.

The [evidence ledger](research/settings-spike-references.md) records exact APIs,
version limits and required tests. The [architecture proposal](design/settings-architecture.md)
contains the single-writer/reset/migration and future desktop-window design.
No API experiment or shell restart was performed for these findings.


## Settings foundation — locally tested 2026-09-27

Quickshell **0.3.1**, Qt 6.11.2, Hyprland 0.56.2. The earlier
[FileView evidence](research/settings-spike-references.md) remains the API source;
production uses FileView only as watcher. `settings/SettingsStore.qml` uses
[Process](https://quickshell.org/docs/v0.3.1/types/Quickshell.Io/Process/) and
[StdioCollector](https://quickshell.org/docs/v0.3.1/types/Quickshell.Io/StdioCollector/)
for a serialized JSON request/response with `persist.py`. Installed type metadata
and local tests verified `exec`, `onStarted`/`write`, `onStreamFinished` and
`onExited` on this runtime. Atomic rename, backup and conflict checks are MAGI's
Python-helper behavior, not additional Quickshell guarantees.

Actual isolated QML tests passed missing/legacy/current/partial/invalid settings,
save/reload, rapid in-flight edits, resets, all ten palettes and live radii.
Nonvisual module Scope ownership and password handoff passed mocked-backend tests.
The shared-surface regression passes 48 steps, including same-view geometry
retargeting. See [full results and limits](research/settings-foundation-checkpoint.md).

Runtime discovery: `Object.fromEntries` is unavailable in the installed QML JS
engine. The diagnostic IPC now builds its phase map with a plain loop. Final
normal launch and all module switches log no errors/warnings. qmllint exits 0
but reports existing type metadata/unqualified warnings and an unresolved
`QProcess::ExitStatus` signal-parameter type at SettingsStore.onExited; real
Process/store tests work. This is not a claim of a warning-free static scan.


## Settings normal-window implementation — 2026-09-27

The already selected [FloatingWindow v0.3.1 API](https://quickshell.org/docs/v0.3.1/types/Quickshell/FloatingWindow/)
is now used by `components/settings/SettingsWindow.qml`. Installed
`Quickshell/_Window/quickshell-window.qmltypes` confirms title/minimumSize and the
normal window interface. Local production observation: it maps as a separate
`org.quickshell` desktop client titled MAGI Settings; Hyprland tiles it normally.
It creates no extra shell layer or reservation. The operator subsequently passed
the requested window manipulation, page and live configuration checks; broader
focus/fullscreen compatibility remains separate. Isolated page/persistence
checks pass; the offscreen Qt backend emits its known unsupported-window-mask
warning, absent from production logs. No additional web research was performed.
See the [checkpoint](research/settings-application-checkpoint.md) for exact scope.


## Settings presentation verification — 2026-10-16

This phase introduces no new Quickshell APIs. Existing FloatingWindow and Loader patterns remain; Qt Basic subclasses retain native signals and keyboard interaction. Production offscreen QtTest coverage exercises page navigation, focus, reset and persistence paths. The RoundedArtwork GPU mask is reused unchanged and still requires native visual acceptance. See [test evidence and limits](design/settings-phase2a.md).


## Settings rendering evidence — Phase 2A.1

Installed Qt Basic ComboBox/SpinBox customization points and QtTest grabImage/save were inspected on 2026-10-16 (Qt 6.11.2-2; Quickshell 0.3.1-1). The test resizes the backing QQuickWindow through the Window attached property and verifies actual content dimensions; implicit size changes alone did not resize the mapped window. Framebuffer renders remain software evidence, not native acceptance. See [checkpoint](design/settings-phase2a1.md).


## Settings drag implementation — Phase 2A.2

Inspected the installed `/usr/lib/qt6/qml/QtQuick/plugins.qmltypes` on 2026-10-16 (Qt declarative 6.11.2-2; Quickshell 0.3.1-1). MouseArea preventStealing and coordinate mapping support a handle-owned grab with viewport-space coordinates; Window active changes support cancellation. No new Quickshell API or external code/assets are introduced. Real production QtTest mouse/key events verify stable delegates, scrolling and canonical persistence at 720×500 and 940×720. Compositor input/fractional-scale acceptance remains native work; see [evidence and limits](design/settings-phase2a2.md).


## Settings Escape ownership — Phase 2A.3

On the installed Qt 6.11.2 / Quickshell 0.3.1 environment, production QtTest events verify Keys.AfterItem on the outer Settings Pane closes only after child handling: ComboBox popup, Dialog, a consuming text editor and active drag each retain Escape. Idle drag handles let Escape propagate. The existing Hyprland Lua binding maps Super+Q to window.close; no new Quickshell API or compositor binding is introduced. Native compositor-key dispatch remains unverified by offscreen tests. See [checkpoint](design/settings-phase2a3.md).


Final Phase 2A.3 status labels use existing Qt Text.NoWrap/ElideRight presentation. Theme pointer coverage checks one-line labels at both Settings content widths, adapter wording normalization, full reload details and visible errors; no new Quickshell API is used.


## Runtime presentation API verification — 2026-10-17

No new Quickshell API is introduced. Installed QtQuick/Effects metadata confirms the existing layer and MultiEffect properties; installed Quickshell Networking metadata confirms WifiDevice.scannerEnabled. Qt 6.11.2 [Image documentation](https://doc.qt.io/qt-6.11/qml-qtquick-image.html) states that PreserveAspectCrop can paint beyond its bounds without clip. The [MultiEffect documentation](https://doc.qt.io/qt-6.11/qml-qtquick-effects-multieffect.html) describes hidden source items, layered texture sources and alpha masks. RoundedArtwork now explicitly clips and layers its source before the existing mask. This addresses source texture bounds; native edge quality remains unverified. No external code/assets were reused. Offscreen tests exercise existing focus/Keys and retained Loader dismissal; compositor pointer grabs and focus restoration still require operator review. See [Phase 2B evidence](design/runtime-phase2b.md).


2026-10-17 mask correction: inspected Qt 6.11 [QQuickMultiEffectPrivate::updateMaskThresholdSpread](https://raw.githubusercontent.com/qt/qtdeclarative/6.11/src/effects/qquickmultieffect.cpp) and its [fragment shader](https://raw.githubusercontent.com/qt/qtdeclarative/6.11/src/effects/data/shaders/multieffect.frag). Defaults produce a nearly zero-width lower smoothstep; faint antialiased mask pixels become opaque. Threshold 0.5 with spread 1 spans approximately alpha 0–1. RoundedArtwork combines this with an inset inner image/mask contour, separate from the frame. Existing installed Qt 6.11.2 properties suffice; no source code/assets copied (upstream dual commercial/LGPL/GPL). Software tests cover geometry and source isolation; native GPU/fractional-scale edge appearance remains an operator check. [Corrective checkpoint](design/runtime-phase2b.md#native-feedback-corrective-pass--2026-10-17).


The appearance follow-up uses existing Qt colour conversion/HSL, input Region, Connections, and retained Loader patterns; no new Quickshell API. Production offscreen tests exercise accent hue/contrast, variable geometry and Settings-owned preview lifecycle. Native layer-shell input regions, focus and GPU antialiasing remain operator checks. Installed versions remain Qt 6.11.2 / Quickshell 0.3.1. [Appearance/preview checkpoint](design/runtime-phase2b.md#control-centre-appearance-and-pinned-preview--2026-10-17).


Live-tuning correction uses existing Qt HSL colour properties, Settings session signals and footer controls; no new runtime API. Production tests observe actual Icon colours and navigate actual Settings pages. Offscreen results cannot certify compositor focus or GPU masking edges. [Live-tuning checkpoint](design/runtime-phase2b.md#settings-session-live-tuning-correction--2026-10-17).


Colour restoration uses existing 7afd1c6 Qt colour/alpha and Icon rendering APIs without additions. An isolated Git-source oracle compares exact resolved RGBA for 600 production tile pairs. Native screenshot quality remains outside the offscreen test claim. [Exact colour restoration checkpoint](design/runtime-phase2b.md#exact-7afd1c6-colour-restoration--2026-10-17).


Typography/spacing additions use existing Qt Text font.pixelSize, ColumnLayout implicitHeight and Item positions. Production tests check font properties, text bounds and section geometry; no new Quickshell API. Native font appearance and edge quality still require operator review. [Final tuning checkpoint](design/runtime-phase2b.md#final-profile-typography-and-section-gap-tuning--2026-10-17).


2026-10-17 Notifications native follow-up: The final Notifications refinement uses existing Qt Column.implicitHeight and ListView.contentHeight with the retained virtualized NotificationCard delegate. No new Quickshell API or reservation. Focused Hub tests verify measured short histories and bounded scrolling; native screenshot review remains separate. [Checkpoint](design/runtime-phase2c.md#native-notifications-refinement--2026-10-17).


## Phase 2D presentation verification — 2026-10-17

No new Quickshell APIs or dependencies. Existing Column implicitHeight, retained Settings
Loaders, GridView virtualization/keyboard, Qt Image sourceSize/asynchronous/cache, and
RoundedArtwork's layered MultiEffect mask are reused. Production tests verify measured
Calendar geometry, embedded Wallpaper routing and thumbnail delegate release, and media
size/radius/capability bounds on the installed Qt/Quickshell runtime. Software captures
cannot certify GPU mask edges or compositor dispatch. [Tests and native checkpoint](design/runtime-phase2d.md).


## Settings visual choices and wheel ownership — Phase 12F

Locally verified with Qt **6.12.0** on 2026-10-23. `WheelHandler` can accept Mouse
and TouchPad devices; `WheelEvent` exposes pixel/angle deltas. Blocking handlers and
explicit ancestor handoff avoid double application in nested Settings regions.
`Flickable` retains StopAtBounds and its default touch kinetics; wheel movement sets
content coordinates directly after cancelFlick. Tests cover fractional angle input,
normal/repeated detents, inner-bound handoff, sidebar and horizontal galleries.
Physical touchpad phases/frame pacing remain native-only acceptance.

Sources inspected 2026-10-23: [WheelHandler](https://doc.qt.io/qt-6/qml-qtquick-wheelhandler.html),
[WheelEvent](https://doc.qt.io/qt-6/qml-qtquick-wheelevent.html),
[Flickable](https://doc.qt.io/qt-6/qml-qtquick-flickable.html).
Implementation: `components/settings/ScrollInput.qml`, `SettingsScroll.js`,
`SettingsGallery.qml`; executable evidence: `tests/phase12f/presentation.qml`.
Software offscreen Qt cannot render MultiEffect-tinted SVGs; do not interpret missing
SVG pixels in software galleries as a successful native icon review. Icon resolver
and fallback assertions run separately from captures.

Phase 12F final refinement uses the same Qt Quick Controls button/focus path for
reset and navigation utilities (`SettingsButton.actionKind`). `SettingsPage.titleSize`
lets contextual inspectors use section hierarchy without another page-size title.
The Phase 12F fixture exercises Space activation of disclosures, hidden/revealed
precision controls, and settings invariance during disclosure. Scroll implementation
fingerprints are unchanged during this refinement. Subsequent operator native acceptance
covered gesture feel and actual SVG tint; those results are operator observations, not
claims established by the offscreen fixture.

Phase 12F scope fixture additionally exercises pointer/Tab/Space/Return selection of
CC regions and Bar family headings, family/item outline differences, disclosure scroll
clamping and invariant Settings revisions. `EditorSelection.familyKeys` is transient.
The existing reorder board accepts a read-only family-membership highlight callback;
no drag/drop or persisted model is replaced. Focus transfers to the existing drag handle
when entering Layout from a focused appearance item.

## Phase 12G isolated Windows presentation and lifecycle — 2026-10-24

Installed Quickshell 0.3.2 (Arch). Verified against local generated API descriptions:
`/usr/lib/qt6/qml/Quickshell/Io/quickshell-io.qmltypes` exposes Socket.connected,
path, connectionStateChanged and SplitParser; the Hyprland `_Ipc` qmltypes exposes
eventSocketPath. The service uses a passive event socket, bounded startup retry,
450 ms edit debounce and existing Process/StdioCollector patterns. Its lifecycle
is tested with a disposable fake worker; actual socket loss/reconnect is untested.
The service is not activated from shell.qml pending the controlled native gate.
The adapter uses pinned Lua hl.config/get_config and fixed rule handle toggles,
with persisted baseline ownership and reload generation checks. No runtime rule
effects are updated and no whole compositor reload is requested.
No new blur rendering API is claimed: the synthetic preview uses ordinary QML
rectangles/alpha and labels its blur treatment illustrative.
[Current capability gate and gallery](design/phase12g-window-visuals.md).

## Phase 13A synthetic editor pattern (2026-10-24)

Exercised with Quickshell 0.3.2 / Qt 6.12.0 in software/offscreen fixtures: QtQuick
MouseArea pointer capture with preventStealing, release-time commit (including
coalesced motion), Keys arrow/Shift/Escape handling, and an attached Screen geometry
aspect preview. The editor uses the existing SettingsPage Flickable/ScrollInput
primitives. The native presentation contains no pointer/key handlers; its original
display-only root property boundary remains unchanged. Settings and native rendering
reuse the same repository QML through a source link and native QRC embedding.
These tests demonstrate synthetic interaction, not ext-session-lock or compositor
pointer acceptance. [Phase 13A test scope](design/phase13a-lock-screen-designer.md).

## Launcher lifecycle checkpoint (2026-10-26)

Quickshell 0.3.2's tracked Process owns QProcess stream channels; it is suitable for
the bounded GIO dispatch helper, not for a long-running GUI inheriting those pipes.
GIO now supplies independent null-device streams to spawned apps. DesktopEntry.execute
still omits terminal/field-code support. The isolated lifecycle fixture uses the
installed `Quickshell.reload(true)` API to destroy/recreate the shell generation.
[Versioned source and tests](research/application-launcher-apis.md#long-running-application-stream-lifetime--2026-10-26).

## Phase 14A — installed 0.3.2 tray API audit

Installed qmltypes confirm SystemTray.items, reactive SystemTrayItem properties,
activate/secondaryActivate/scroll/display, QsMenuAnchor and QsMenuOpener. Tray icons
are already Qt Image sources; QsMenuAnchor takes the actual menu handle and an
originating item anchor. QsMenuOpener exposes children and is not needed for native
menus. Guard repeated anchor open/close calls. Native compositor placement and
handle destruction remain acceptance gates; session-bus ownership is inaccessible
from this sandbox. [Evidence and synthetic coverage](design/phase14a-system-tray.md).

Native correction (2026-10-27): `QsMenuAnchor.open()` requires the process to
start with `//@ pragma UseQApplication` in root shell.qml. A QML reload cannot
change QGuiApplication to QApplication. This was proven by the live error and
isolated old/new-mode regression, then verified by operator native menu testing
after restarting MAGI. Keep the root pragma in any full production startup.


## Daily-use media and status styling — 2026-10-29

See [the bounded review record](review/daily-use-polish.md) for Quickshell 0.3.2
position-refresh evidence, operator-provided Zen MPRIS snapshots, sparse item colour
and shade ownership, centered Battery regions and schema-22 compatibility. Native
review and the remaining browser reporting limitation are recorded explicitly.


Expanded status-header follow-up: one shared semantic foreground and optional shade
now separate the expanded menu header from custom Bar ink, including Battery text.
See [diagnosis and validation](review/daily-use-polish.md#expanded-status-header-follow-up--2026-10-29).
