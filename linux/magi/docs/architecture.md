# MAGI — Architecture

Updated **2026-09-26** for the shared status-surface structural review.
The bounded shared-composition checkpoint is operator-accepted: full collapse,
reliable repeated/rapid reopening and Control Centre → Bluetooth → Back.
Broader focus/fullscreen/password regression remains unverified for this refactor. Repository HEAD was
`35c282012f2d749081a3f8b1821f01bf0b8aa6ea`; the changes described here are
still an uncommitted working tree. Paths are relative to
`.config/quickshell/magi/`.

## Runtime surface and reservation

`shell.qml` selects `expandableHostMode: "combined"`. `Bar.qml:19-104`
creates one top-layer PanelWindow at output-local `(0,0)`. In combined mode
it spans the logical output height but uses an explicit
`exclusiveZone: 48`; only the transparent 48px `barStrip` represents the
reserved bar.

Bar owns the expandable-pill registry, resolves MenuController's semantic ID
to one registered pill, and builds the native input Region from:

1. the fixed bar strip;
2. the shared status-surface Item while revealed; and
3. the full-surface consuming catcher while a registered menu is requested.

The catcher is below bar pills, so a sibling click switches menus directly.
The bar requests `WlrKeyboardFocus.OnDemand` only while the selected plugin
is registered and keyboard-eligible. Fullscreen visibility remains
compositor-controlled; tested Hyprland fullscreen changed layer alpha without
changing reservation or leaving an interactive hidden Region.

The accepted single-output scale-2 runtime reported one logical 1920x1080
MAGI layer at `(0,0)` and monitor reservation `[0,48,0,0]`. Multi-output
association and fractional scaling are not validated.

## Registry and configurable composition

`Bar.qml:123` explicitly maps IDs to Components; there is no filesystem
discovery. The current IDs are clock, date, workspaces, volume, Wi-Fi,
Bluetooth, battery and Control Centre. Each Settings-driven Row uses a Repeater/Loader path; the right Row now
lives inside `SharedStatusSurface.qml`. Expandable Component wrappers pass
the same `barWindow`, `menuCoordinator`, `hostMode` and `sharedSurface` contract.

`settings.json` currently selects:

- left: clock, date;
- centre: workspaces;
- right: volume, Wi-Fi, Bluetooth, battery, Control Centre.

Bluetooth uses `ExpandablePlugin.barVisible` to remove its pill when no
device is connected. In combined mode, Control Centre detail navigation does not reveal a
disconnected Bluetooth pill: the registered body is selected directly. The registry remains
configurable; the order is data, not a hard-coded Row sequence.

Unknown and duplicate IDs are still not validated. The centre Row is centred
independently and has no collision policy.

## Shared composition and module lifecycle

`SharedStatusSurface.qml` owns the combined production silhouette and animation.
Its right Row contains the actual compact plugin visuals throughout opening,
view changes and closure. The Row moves inward/downward into the header while
individual backgrounds blend into the common surface. Volume is icon-only;
Battery displays percentage. Connected Bluetooth retains variable width.

`ExpandablePlugin.qml` still supplies compact visuals, body Component and size
requirements. When `sharedSurface` is supplied, its individual animation driver
is bypassed and `MenuHostSelector.hostingEnabled` is false: no per-plugin adapter
or content Loader is instantiated. Plugin `phase` mirrors the common surface,
which preserves Wi-Fi's wait-until-closed password handoff.

The shared opening sequence remains widen 180ms, reveal 140ms with a concurrent
90ms fade; closure remains fade 70ms, retract 120ms, narrow 160ms, all OutCubic.
Changing module while open fades out the outgoing body for 70ms, selects the
latest requested ID, retargets width/height from current values and fades in the
incoming body. It does not retract to zero or return to the compact bar. Only
the selected, fully revealed body is interactive. Repeated requests interrupt
from current animated values. Selection and compact-width handlers are deferred
with `Qt.callLater` so derived open/target-size bindings settle first; otherwise
synchronous handlers can act on the prior selection and stall after fade-out.
The windowless lifecycle regression is `tests/shared-status-surface/run.py`
(relative to the repository root); pointer/focus acceptance remains separate.

Body Loaders remain alive while their registered plugins exist, even when not
selected. This retains body state and Wi-Fi network-result Connections. The
surface grows to at least its compact status-row width plus navigation/insets;
individual body widths/heights remain plugin-provided.

MenuController owns only a requested semantic ID and an ID history. `navigate`
pushes a detail destination, `back` returns, and direct `open`/`toggle` clears
history. No Item/window references enter that singleton. Control Centre's
secondary Wi-Fi/Bluetooth tile actions use `navigate` within the same surface.

Anchored rollback still selects the existing per-plugin animation and
PopupWindow adapter, including TransformWatcher, rounded window-relative
`mapFromItem()`, `anchor.window` and `PopupAdjustment.None`. Its geometry and
host code were not changed by this structural pass. `CombinedMenuHost.qml`
remains available for the earlier per-plugin implementation but is not loaded
by the production shared status group.

The default right-group composition is the current visual target. Configured
left/centre modules still trigger the same surface, but coordinated migration
across sections, collisions, multi-output and fractional scaling remain
unverified. See [the structural checkpoint](design/shared-status-surface.md).

## View-specific reference presentation

The accepted state machine, timings and native host are frozen for the literal
render pass. `ExpandablePlugin` adds optional presentation-only `viewPadding`,
`viewTopPadding`, `viewBottomPadding`, `viewRadius` and `viewSurfaceColor`.
SharedStatusSurface reads each body's own insets and the displayed view's outer
color/radius; defaults preserve the other views. Existing expandedWidth and
menuHeight remain the geometry targets, including shrinking when navigating.

CC alone adopts `theme/RenderTokens.qml`: nominal width 320, body 208, total 244
logical pixels with the existing 36px expanded header. The compact cluster width
floor still applies. Its muted palette is scoped and does not change the global
Theme or detail-view colors. Anchored geometry/adapter is unchanged and retains
its prior host insets. See [the visual specification](design/render-visual-specification.md)
for measurements, deliberate omissions and pending visual acceptance.

## Services

| Service | Responsibility |
| --- | --- |
| Settings | Watches settings.json and exposes palette and placement arrays. Runtime writes are still not persisted explicitly. |
| Network | Owns Quickshell Networking device/radio/scan/active-network access and known/open/PSK connection calls. Its semantics were unchanged during migration. |
| Audio | Tracks the default PipeWire sink and exposes live volume, mute, absolute volume setting and stepped adjustment. |
| Bluetooth | Wraps Quickshell 0.3.1 Bluetooth/BlueZ adapter and device objects, tracks connected devices, exposes real optional battery data, and limits connect actions to paired/bonded devices. |
| Brightness | Polls the installed `brightnessctl` backend, debounces slider writes and exposes live percentage. It currently assumes a working brightnessctl-compatible backlight. |
| Battery | Exposes UPower display-device percentage, charge state and remaining time. |
| MenuController | Owns semantic selected-view ID, ID history, open/toggle/close and navigate/back operations. |

Wi-Fi selection, pending connection and error state remain plugin-owned
because they are view-session state. Durable radio/device/audio/power state
is shared through services and reused by Control Centre.

## Production expandable plugins

### Volume

`plugins/bar/volume/Volume.qml` is a 64px collapsed status pill with live
percentage and mute-aware icon. Its 260x126 menu uses the shared PipeWire
service, a reusable `components/controls/ValueSlider.qml`, and an explicit
mute toggle. External mixer/media-key changes update the pill and slider.

### Bluetooth

`plugins/bar/bluetooth/Bluetooth.qml` requests a 320x350 menu with a bounded
device Flickable, adapter and discovery controls, live device state, optional
backend battery and paired-device connect/disconnect. Its connected state
widens the collapsed pill. Runtime function passed, but the connected device
name was not visibly presented in the tested widened pill; final header/name
styling remains follow-up work. Battery is shown only when BlueZ exposes it.
New-device pairing and device-specific listening modes are not implemented.

### Control Centre

`plugins/bar/controlcentre/ControlCentre.qml` is a 380x380 menu on the same
host lifecycle. It contains live Wi-Fi and Bluetooth tiles, shared Volume and
Brightness sliders, mute, and Battery status. `ControlTile.qml` separates
primary and secondary triggers so future detail/long-press behavior does not
require a host rewrite. Secondary Bluetooth and Wi-Fi actions route through
MenuController to their registered detail plugins.

### Wi-Fi

`plugins/bar/wifi/Wifi.qml` owns the browser session state and routes the
same Network service calls as before. `WifiMenuContent.qml` supplies the
320x400 combined menu with a bounded network Flickable. It retains radio,
scan, known/open/PSK selection, pending/error and retry behavior.

`WifiPasswordWindow.qml` remains a separate 300x150 top/right PanelWindow
with Ignore exclusion, OnDemand keyboard focus, masked TextInput, Enter,
Connect, Cancel and Escape. Selecting a secured network closes the semantic
combined browser and waits until its animation reaches phase 0 before showing
and focusing the password window. A candidate keeps scanning active during
that handoff. Cancel or submission reopens the browser.

The operator passed scanning, known/open/PSK connection, incorrect-password
feedback, retry, successful connection, input masking, Enter/Connect/Cancel
and scanning-handoff equivalence on 2026-09-26. `Network.qml` was not
modified.

## Remaining risks and planned work

- Test explicit output association, multiple monitors, hotplug and fractional
  scaling before claiming compatibility beyond the accepted eDP-1 scale-2
  session.
- Refine the connected Bluetooth pill so the real device name is visibly
  represented; show battery only when supplied by BlueZ.
- Pairing new Bluetooth devices requires an explicit agent/prompt design.
- Classify enterprise and other non-open Wi-Fi security modes; current
  behavior, preserved from the original implementation, routes unknown
  secured networks through PSK.
- Add timeout/cancellation policy for Wi-Fi connection attempts and adapter
  failover only as separately tested Network-service work.
- Replace the temporary styling with the render's final spacing, typography,
  tile states and icon/header motion without changing the accepted lifecycle.
- Decide when the anchored fallback can be retired. It remains a rollback
  path and is not the target for new plugins.
