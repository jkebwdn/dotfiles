# MAGI — Architecture

Updated **2026-10-01** for the first-party MAGI SVG pack and semantic tint path.
The bounded shared-composition checkpoint is operator-accepted: full collapse,
reliable repeated/rapid reopening and Control Centre → Bluetooth → Back.
Broader focus/fullscreen/password regression remains unverified for this refactor.
Settings-spike source baseline is committed HEAD
`5215bbef5fa3573295c1c1101059d62da502892c` (2026-09-26). Paths are relative to
`.config/quickshell/magi/`.

## Current Settings/CC integration — 2026-09-28

The [new checkpoint](research/settings-application-checkpoint.md) supersedes the
S1/S2-only limitations below: IconRegistry and shared Icon rendering are active;
ControlCatalog drives presentation-aware primary controls, sliders, secondary
actions and detail views, responsive targets and safe live reflow; the duplicate
battery row is removed. Schema-v3 defaults are Wi-Fi/Bluetooth/Low Power/Airplane,
Volume/Brightness sliders and VPN/DND/Caffeine/Lock/Hibernate/Shutdown actions.
Unavailable system adapters remain visible but disabled. SettingsApplication
owns one lazy FloatingWindow with real configuration pages.
It shares SettingsStore and waits for transient/password readiness before opening.
Bar retains exclusive ownership of Region/focus/catcher and the 48px reservation.
Automated and startup checks pass. The operator subsequently passed the requested
window/pages, live settings/persistence, CC configuration and hidden-detail checks;
post-review logs and the one-layer/48px baseline remain clean.

## Runtime surface and reservation

`shell.qml` selects `expandableHostMode: "combined"`. `Bar.qml:19-104`
creates one top-layer PanelWindow at output-local `(0,0)`. In combined mode
it spans the logical output height but uses an explicit
`exclusiveZone: 48`; only the transparent 48px `barStrip` represents the
reserved bar.

Bar owns a stable nonvisual ModuleRegistry, resolves MenuController's semantic ID
to one registered module, and builds the native input Region from:

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

`modules/ModuleRegistry.qml` explicitly owns Wi-Fi, Bluetooth, Volume and
Control Centre sessions as nonvisual `ExpandableModule` Scopes. Their body
Components, password/connection state and service references survive removal
of a compact bar delegate. No invisible bar Items register detail views.
`Bar.qml` maps the existing IDs to `ModulePill` delegates or ordinary
clock/date/workspaces/battery Components. Conditional Bluetooth visibility
controls delegate creation only; its CC detail remains available.

Schema v1 retains the user's placement: left clock/date, centre workspaces,
right volume/Wi-Fi/Bluetooth/battery/Control Centre. Settings validates arrays;
unknown and duplicate IDs are retained in the document but omitted from the
effective placement with diagnostics. Bar applies changed placement only after
menus/animations and Wi-Fi password/pending interactions settle. Appearance
changes do not recreate unchanged placement. Centre-row collision policy is
still unresolved.

## Shared composition and module lifecycle

`SharedStatusSurface.qml` owns the combined production silhouette and animation.
Its right Row contains the actual compact plugin visuals throughout opening,
view changes and closure. The Row moves inward/downward into the header while
individual backgrounds blend into the common surface. Volume is icon-only;
Battery displays percentage. Connected Bluetooth retains variable width.

`ExpandableModule.qml` owns plugin visuals/body Components and size requirements;
`ModulePill.qml` delegates compact presentation to `ExpandablePlugin.qml`. When `sharedSurface` is supplied, its individual animation driver
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

CC adopts tile/slider geometry from `theme/RenderTokens.qml`; its dimensions now
derive from effective columns, enabled controls and sliders. Default targets are
322px wide, 152px body and 188px including the 36px expanded header. The compact cluster width
floor still applies. Colors now use the selected semantic Theme, with Mocha as the default. Anchored geometry/adapter is unchanged and retains
its prior host insets. See [the visual specification](design/render-visual-specification.md)
for measurements, deliberate omissions and pending visual acceptance.

## Services

| Service | Responsibility |
| --- | --- |
| Settings | Sole SettingsStore instance: schema/defaults/migration/validation, live snapshots, reset and serialized atomic persistence; compatibility placement accessors and IPC. |
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

`plugins/bar/volume/Volume.qml` is a 30px icon-only collapsed status pill with
a mute-aware icon. Its nominal 280px-wide, 100px-body view uses the shared
PipeWire service, a reusable `components/controls/ValueSlider.qml`, and an explicit
mute toggle. External mixer/media-key changes update the pill and slider.

### Bluetooth

`plugins/bar/bluetooth/Bluetooth.qml` requests a 326px-wide, 350px-body
view with a bounded device Flickable, adapter and discovery controls, live device state, optional
backend battery and paired-device connect/disconnect. Its connected state
widens the collapsed pill. The current connected pill uses the real device
name; the earlier functional checkpoint preceded that presentation. Final header/morph styling remains
follow-up work. Battery is shown only when BlueZ exposes it.
New-device pairing and device-specific listening modes are not implemented.

### Control Centre

`plugins/bar/controlcentre/ControlCentre.qml` uses the same host lifecycle and
derives its target height from independently optional Profile, primary tile,
slider, secondary action and Media regions. One ControlCatalog declares supported
presentation forms and live action/state adapters. The default primary row is
Wi-Fi, Bluetooth, Low Power and Airplane Mode; Volume and Brightness remain
dedicated sliders; the secondary row is VPN, DND, Caffeine, Lock, Hibernate and
Shutdown. Settings can replace, order, enable and reflow both rows while open.
Wi-Fi/Bluetooth detail navigation still uses MenuController. Destructive actions
share a five-second two-activation arm rather than executing on one click.

### Wi-Fi

`plugins/bar/wifi/Wifi.qml` owns the browser session state and routes the
same Network service calls as before. `WifiMenuContent.qml` supplies the
328px-wide, 390px-body combined view with a bounded network Flickable. It retains
radio, scan, known/open/PSK selection, pending/error and retry behavior.

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
- Preserve the real connected Bluetooth name and backend-only battery data
  through future configurable icon/header presentation.
- Pairing new Bluetooth devices requires an explicit agent/prompt design.
- Classify enterprise and other non-open Wi-Fi security modes; current
  behavior, preserved from the original implementation, routes unknown
  secured networks through PSK.
- Add timeout/cancellation policy for Wi-Fi connection attempts and adapter
  failover only as separately tested Network-service work.
- Build semantic icons and CC configuration on the completed Settings foundation
  before further render refinement; preserve the accepted lifecycle throughout.
- Decide when the anchored fallback can be retired. It remains a rollback
  path and is not the target for new plugins.


## Configuration and appearance foundation — implemented through schema v3

`services/Settings.qml` owns `settings/SettingsStore.qml`, pure schema/migration
JS and a Python standard-library atomic I/O helper. Schema v3 has appearance,
icons, bar, Control Centre, profile and media sections, with ordered primary,
slider and secondary-action groups. Defaults are effective values, not an
automatic startup rewrite. Unknown fields survive migration and ordinary edits;
malformed/newer documents are protected from silent overwrites. Reset is explicit.
The helper backs up pre-schema content, checks the prior disk snapshot and
atomically replaces the canonical file; conflicts are surfaced for reload.
See [persistence and validation evidence](research/settings-foundation-checkpoint.md).

`ThemeRegistry.qml` loads ten bundled data definitions; `Theme.qml` is a one-way
semantic facade over Settings. RenderTokens contains no palette colors.
Master roundness (0–2) and nullable barPill/surface/controlTile/slider/action
multipliers drive live radii, clamped to geometry. Padding, font baselines, gaps
and nominal dimensions stay internal. IconRegistry combines bundled and
validated managed packs; incomplete packs inherit from a declared parent and
ultimately MAGI Legacy. The [pack contract](design/icon-pack-contract.md) fixes
the normal UI canvas at 24×24 without cropping internal whitespace.
`magi-default` is the partial built-in first-party pack and inherits missing
roles from `magi-legacy`. Icon descriptors explicitly select `semantic` or
`fixed` color mode. The shared Icon component applies semantic colors through
the SVG's rendered alpha mask, retaining internal opacity; fixed mode preserves
source RGB for future multicolor assets. Bundled, managed and individual assets
continue through one resolver and the existing override/pack/fallback order.

A module can bind `expandedWidth`/`menuHeight` or call `requestGeometry(w,h)`.
`SharedStatusSurface.retargetGeometry()` coalesces target changes and animates
from current dimensions without changing view, phase, focus or content opacity.
The 48-step regression includes open-view growth and interrupted shrink.

Visible anchored pills retain the original PopupWindow/TransformWatcher adapter.
For a module omitted from the bar, `AnchoredDetailHost.qml` anchors its detail to
the real Control Centre pill. This requires that trigger to exist; no invisible
anchor is fabricated when both placements are absent. Combined hosting has no
such dependency. The bounded fallback check passed native 48px geometry and
hidden Bluetooth detail, not a fresh full pointer/focus acceptance.

CC column/order/slot and optional-region settings drive ControlCatalog delegates.
ProfileHeader consumes explicit user profile data. Media wraps Quickshell MPRIS
through one deterministic MediaController and disappears when no suitable player
exists; both regions use same-view geometry retargeting. The duplicated battery
summary has been removed. The initial Settings GUI and IconRegistry are
implemented. AssetManager validates and copies avatars/SVG overrides into XDG-
managed storage; bounded override UI covers an initial role subset. Host lifecycle,
MenuController semantics, Network and other system services remain unchanged.
