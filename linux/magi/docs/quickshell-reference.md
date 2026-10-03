# MAGI — Quickshell Technical Reference

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
SwayNC's packaged D-Bus unit is masked so retry/activation cannot race startup.

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

Quickshell0.3.1 [ObjectModel.values](https://quickshell.org/docs/v0.3.1/types/Quickshell/ObjectModel/)
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
