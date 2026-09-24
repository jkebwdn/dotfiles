# MAGI — Architecture

Source-audited on 2026-09-24 at `e375e5ee95e82f5609c2aeb4b880b21eb38b1086`.
This describes source behavior, not a newly exercised running session.
Paths in this document are relative to `.config/quickshell/magi/`.

## Runtime and bar

`shell.qml:6` creates one `Bar.Bar` inside ShellRoot. There is no per-screen
instantiation or explicit screen assignment. `components/bar/Bar.qml:15`
creates a transparent top-layer PanelWindow anchored top/left/right, with
`implicitHeight: 48` and `exclusionMode: ExclusionMode.Auto`. Menu height
does not change bar height: expanded content uses separate windows.

`Bar.qml:47` (under `components/bar/`) explicitly maps six IDs to Components:
clock, date, workspaces, wifi, volume and battery. Repeaters and Loaders at
lines 107, 129 and 250 instantiate Settings' placement lists. This is a
fixed registry with configurable placement, not runtime plugin discovery.
There is no custom handling for unknown or duplicate IDs. Left/right rows
have 16px outer margins; all rows use 8px spacing. The centre row is centred
independently, without collision handling.

`settings.json:3` configures clock/date left, workspaces centre and
Wi-Fi/volume/battery right. Settings and Controls at `Bar.qml:162` and
`:203` are always-created inline test menus before the right plugin list.
They are not registered plugins or settings-driven entries.

## Services, settings and theme

`services/qmldir:1` registers five singletons:

| Service | Current responsibility and source |
| --- | --- |
| Settings | `services/Settings.qml:17`: FileView/JsonAdapter reads and watches settings.json; reloads on change; exposes palette and placement aliases. Defaults: Catppuccin, clock/date left, empty centre/right. No explicit save path, schema validation or custom error UI. |
| Network | `services/Network.qml:13`: radio/hardware state, first Wi-Fi device, available networks, active network, icons/status, scan switch and connection methods. |
| Audio | `services/Audio.qml:11`: default PipeWire sink and PwObjectTracker, mute and 5% volume steps clamped to 0–100%. |
| Battery | `services/Battery.qml:10`: UPower display-device availability, percentage, charging and remaining-time status. |
| MenuController | `services/MenuController.qml:10`: requested active menu string plus toggle/open/close/isOpen. |

System functionality is only partly centralized. Wi-Fi's selected/pending
network and result handling live in its UI. `plugins/bar/workspaces/Workspaces.qml:16`
refreshes and consumes Hyprland directly; its line 83 handler dispatches
`hl.dsp.focus(...)`. Clock and date use local timers (1s and 60s respectively).
Volume clicks toggle mute and wheel input adjusts volume; battery is a
status display. Both use separate hover PopupWindows.

`theme/Theme.qml:10` selects Catppuccin Mocha or Everforest Dark Hard and
exposes semantic colors, typography and spacing. Its persistence comment
must not be treated as implemented disk saving: Settings has no write call.
ExpandablePlugin and inline test content use hardcoded colors instead of
Theme. A service-owned system layer remains a design direction, not a
complete description of current ownership.

## Expandable menu state and content

`components/bar/ExpandablePlugin.qml:15` exposes barWindow, menuId, icon,
title, collapsedWidth (28), expandedWidth (220), menuHeight (180) and
menuContent (Component). The pill has a 28px implicit height.

At line 55, requestedOpen compares menuId to MenuController.activeMenu.
The controller does not wait for closure before requesting another menu.
Each instance owns its seven animation phases and interruption handling.
See [D004](decisions.md#d004--retain-the-current-animation-baseline) for timings.
One requested menu therefore does not imply one visible surface throughout
a transition. Wi-Fi's menuOpen is independent of this controller.

The Loader at line 397 uses menuContent or a fallback test Component. Its
host assigns 12px padding, width minus 24px, menuHeight minus 24px, opacity
and clipping. The source does not deactivate/unload content on closure or
provide explicit open/close callbacks, focus delegation, content-driven
sizing or navigation. Treat content lifetime as distinct from popup
visibility; actual lifecycle behavior still needs a dedicated test.

## Window-relative positioning

`components/bar/ExpandablePlugin.qml:330` implements the preserved baseline:

1. Bar passes its PanelWindow through barWindow.
2. TransformWatcher watches barWindow.contentItem (`a`) and the pill (`b`).
3. Both anchor coordinate bindings read watcher.transform, intentionally
   creating a reactive dependency.
4. `barWindow.contentItem.mapFromItem(root, 0, root.height)` maps the pill's
   bottom-left into the bar window, with coordinates rounded to integers.
5. PopupWindow uses anchor.window and PopupAdjustment.None. Its width is
   the pill width, height is max(1, revealedHeight), and visibility is
   revealedHeight > 0. The interior rectangle clips the reveal.

The popup attaches below the pill, not explicitly below the 48px bar edge.
Automatic edge adjustment is disabled. The mapping also tracks movement
caused by neighbouring pills in the Row. Version-specific documentation
supports this dependency pattern; historical user testing is recorded in
[decisions](decisions.md), not reproduced here.

## Wi-Fi: preservation boundary

`plugins/bar/wifi/Wifi.qml:13` owns menuOpen, selectedNetwork, pendingNetwork
and connectionError. `selectNetwork()` at line 47 routes known profiles to
connectKnown(), open networks to connectOpen(), and other networks to a
password prompt. `submitPassword()` at line 72 invokes connectWithPassword(),
clears input/selection and reopens browsing. `services/Network.qml:69`
implements these through connect() and connectWithPsk().

The selector at `Wifi.qml:182` is a 300×350 item-anchored PopupWindow.
The password PanelWindow at line 479 is 300×150, top/right anchored with
48px/16px margins, ExclusionMode.Ignore and OnDemand keyboard focus. Its
visibility handler requests input focus. TextInput masks passwords and
submits on Enter; Connect and Cancel are explicit controls.

Preserve scanning across both windows (visibility handlers at lines 195
and 501), radio control, known/open/PSK connections, duplicate-attempt
guards, list scrolling, signal/connected indicators, pending/error feedback,
input clearing, cancellation and keyboard entry. Result Connections are
inside network-row delegates at line 348. Wi-Fi has not migrated to
ExpandablePlugin; do not remove this flow before equivalent tests pass.

## Outstanding concerns and proposed work

These are source-derived risks requiring tests, not observed regressions:

- Rapid switching/reversal, overlapping outgoing/incoming surfaces,
  menu-ID validation and cleanup when an instance is destroyed.
- No explicit shared-menu Escape, click-away or keyboard-focus policy.
- No explicit per-screen architecture; password-window screen association
  and hardcoded margins need testing.
- No bar-row collision handling; disabled popup adjustment requires
  narrow-screen, scaling and oversized-content tests.
- Legacy Wi-Fi/tooltip item anchors may become stale when neighbours move.
- Wi-Fi result observation depends on delegate lifetime and has no explicit
  timeout; disabling Wi-Fi or losing a network mid-attempt may strand state.
- Removing the chosen adapter clears it, without explicitly selecting an
  already-existing second adapter (`services/Network.qml:96`).
- Unknown non-open networks all use the PSK prompt; enterprise and other
  authentication modes are not demonstrated.
- Define content lifetime, dimensions, focus and service ownership before
  migrating plugins; do not infer these from the dummy text menus.

Design direction remains left time/date, centred workspaces, right status,
a main Control Centre and Bluetooth device/detail menus. Render concepts
are not implemented specifications. Research and user review precede any
replacement of the expansion system or Wi-Fi migration.
