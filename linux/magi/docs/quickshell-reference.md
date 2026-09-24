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

## Source observations awaiting deeper API research

These are verified local declarations, not newly validated runtime contracts:

- `components/bar/Bar.qml:18`: Auto exclusion and a 48px implicit height.
- `components/bar/ExpandablePlugin.qml:77`: explicit animation stopping and
  phase-dependent restart; see [D004](decisions.md#d004--retain-the-current-animation-baseline).
- `components/bar/ExpandablePlugin.qml:397`: Loader with no explicit
  close-time deactivation; lifetime and focus semantics need investigation.
- `plugins/bar/wifi/Wifi.qml:495`: Ignore exclusion, OnDemand focus and
  forceActiveFocus() on showing the password window.
- `services/Network.qml:69`: connect()/connectWithPsk() routing; network
  lifetime, authentication coverage and failure delivery need verification.

Official pages opened during the audit, retained as starting points rather
than a completed analysis of every API:
[PopupWindow](https://quickshell.org/docs/v0.3.1/types/Quickshell/PopupWindow/),
[PanelWindow](https://quickshell.org/docs/v0.3.1/types/Quickshell/PanelWindow/),
[WlrLayershell](https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/WlrLayershell/),
[WifiNetwork](https://quickshell.org/docs/v0.3.1/types/Quickshell.Networking/WifiNetwork/).
All were inspected on 2026-09-24; deeper findings remain pending.

## Next research and recording requirements

Prioritize windows/geometry, focus/dismissal, Qt animation interruption and
Loader lifetime, then networking migration requirements. Later topics:
Bluetooth, media, service boundaries, plugin registration and nested pages.
For each finding record source URL and date, documentation version or
repository commit, exact component/function, demonstrated behavior, MAGI
relevance, compatibility and required tests. Clearly label official API
contracts, source observations, historical reports, new tests and proposals.
