# MAGI — Quickshell Technical Reference

## Evidence baseline

Inspected on **2026-09-24**. Local source snapshot:
`e375e5ee95e82f5609c2aeb4b880b21eb38b1086`. Source paths below are relative
to `.config/quickshell/magi/`. Official findings below use the **v0.3.1**
documentation, not an unversioned/latest API assumption.

The audit read source and ran version queries. It did not launch/restart
Quickshell, exercise menus, change radio state or test connections. Earlier
user reports are historical evidence only. API documentation establishes
contracts; it does not prove MAGI's live behavior under every compositor.

## Installed environment

| Component | Local verification result |
| --- | --- |
| Quickshell | `quickshell --version`: 0.3.1, Arch Linux, blank revision; `pacman -Q quickshell`: 0.3.1-1 |
| Hyprland | `Hyprland --version`: 0.56.2, commit `efb50993780079460b0cbed1363e2166a2de1d9f`; package 0.56.2-3 |
| Qt base | `pacman -Q qt6-base`: 6.11.2-3 |
| Qt declarative | `pacman -Q qt6-declarative`: 6.11.2-2 |

Installed versions were verified, but versions loaded by existing processes
were not. Quickshell's exact upstream build commit was not supplied by its
version output. Package revisions and upstream version numbers differ.

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
