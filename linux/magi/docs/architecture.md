# MAGI — Architecture

## Emoji Picker and future Hub boundary (2026-10-05)

`EmojiSearch.js` owns pure metadata preparation, normalized ranking, category and
Recents helpers; `Emoji` owns data/query/selection and copy completion. Reusable
`EmojiContent` consumes this service without window APIs. `EmojiWindow` temporarily
supplies overlay focus and dismissal, following Launcher with no reserved space.
The shell coordinates surface exclusion and fullscreen suppression. Clipboard
restore and Emoji share `clipboard_backend.copy_payload`; no new watcher.
Schema 9 persists modest Emoji preferences and bounded Recents in the existing store.

The dedicated host will be replaced/absorbed by **MAGI Hub** presentation. Apps,
Notifications, Emoji and Clipboard remain distinct subsystems; their shortcuts
open Hub directly in the requested mode. Control Centre and Calendar remain
separate anchored surfaces. No Hub or subsystem extraction is implemented now.
See [Emoji contract, validation and limitations](design/emoji-picker.md).

## Calendar / Date surface (2026-10-04)

`ClockState` owns one SystemClock and the shared time/date formats. `CalendarMath`
provides civil arithmetic, `CalendarModel` exposes selection/grid/navigation, and
`Calendar` coordinates open state through MenuController and fullscreen suppression.
`TimeDatePill` is reused in bar slots and the expanded header. Original slots retain
geometry with opacity0 while the shared surface is active; closing restores them.
`CalendarSurface` inherits SharedStatusSurface with optional left header alignment,
leaving the status cluster's default unchanged. The existing Bar PanelWindow owns
input, focus, stacking and the sole48px reservation. Schema 8 adds Date & time Settings.
Current placement support is left/centre/right within the top bar. See the
[checkpoint](design/calendar-date-surface.md) for interactions, validation and limits.


## Application launcher (2026-10-04)

`services/Launcher.qml` owns application selection and state, `LauncherSearch.js`
owns pure scoring, and `launcher_backend.py` delegates XDG metadata/execution to
GIO. The private terminal adapter supports installed Ghostty without parsing Exec.
`components/launcher` separates the overlay, content/layout and item rendering.
User-hidden desktop IDs live in Launcher preferences and are excluded before
ranking for both views; Settings resolves display names and restores IDs even
when the app is uninstalled. `LauncherIcons.resolve(app)` supplies a presentation
object to delegates, leaving a desktop-ID override point for future icon packs.
The output-local overlay reserves no space and takes keyboard focus only while
open. It is independent of Clipboard and the shared expandable bar host. Schema7
and the existing Settings writer own visual preferences. See the
[launcher specification](design/application-launcher.md) for settings and limits.


## Clipboard Manager — 2026-10-03

`ShellRoot` activates `Clipboard` only in production after Settings readiness.
The singleton owns one JSON-lines Python backend; presentation cannot capture or
store data itself. `clipboard_capture.c`, built against installed ext-data-control
v1, skips initial selections and rejects sensitive-marked offers before requesting
bytes. It supplies exact-offer bounded MIME payloads through a private framed pipe.
Python owns IDs, hashing, pins, count/byte eviction, search, thumbnails and optional
versioned SQLite persistence. wl-copy restores bytes through stdin with an explicit
MIME type. cliphist is neither a dependency nor a history source.

`ClipboardWindow` is a centred, bounded FloatingWindow, matched by class+title with
a narrow Hyprland float/centre rule. Search gains focus on opening; clicking another
client releases typing focus while Clipboard can stay visible. It owns no bar
reservation or desktop-sized catcher. `ClipboardContent` renders text and thumbnails;
it uses shared theme roles/radii and IconRegistry, with new Legacy fallback roles.
The existing output fullscreen monitor closes/suppresses it. Shared menus,
Notification Centre and Settings close it on opening. Model state outlives visibility.

Schema6 adds clipboard preferences through the established SettingsStore writer.
Memory-only is default, including pins; QML/process restart clears session history.
Opt-in persistent payloads live outside dotfiles in a private SQLite store; runtime
thumbnails are cleaned on shutdown/restart. Initial and re-enabled selection is
skipped, not backfilled. SUPER+SHIFT+V invokes service IPC, SUPER+V remains floating.
See [privacy/limits](design/clipboard-manager.md) and
[runtime evidence](research/clipboard-manager-checkpoint.md).

## Permanent notification ownership — 2026-10-03

Production `ShellRoot.Component.onCompleted` invokes the existing idempotent
`Notifications.activateServer()`. This gives lifecycle ownership to the shell
without making arbitrary singleton importers claim D-Bus and without delayed IPC
or persisted approval state. A clean process restart proves automatic ownership.

Hyprland starts `quickshell -c magi`; `SUPER+N` invokes MAGI's Centre.
QuickActions uses Settings as its only DND state and has no SwayNC query path.
The 2026-10-04 retirement supersedes the package-preserving rollback: Waybar,
SwayNC, Noctalia and cliphist are retired, together with their legacy deployment
and SwayNC-only mask/greeting Stow package. wl-clipboard remains required for
MAGI restore and other desktop tools; existing cliphist history is preserved.
The subsequent hygiene pass also retired HyprPanel, AGS, Matugen and awww;
Hyprpaper remains the active wallpaper backend.
Hypridle, Hyprlock and Hyprpaper retain their existing responsibilities.
See the [retirement checkpoint](research/legacy-shell-retirement-checkpoint.md)
for actual host evidence; the earlier
[ownership checkpoint](research/permanent-notification-ownership-checkpoint.md)
remains historical migration/rollback evidence.

## Notifications milestone — 2026-10-03, operator-accepted implementation

Baseline is accepted `d539b9b`; earlier sections below retain their historical
milestone context. [Current design](design/notifications-toasts.md) and
[validation/resume ledger](research/notifications-toasts-checkpoint.md) supersede
the earlier deferred Bluetooth/state-style statements.

`Notifications` owns a `NotificationModel` independently of any bar delegate or
window. `NotificationBackend` wraps Quickshell 0.3.1 NotificationServer; per-live-ID
`NotificationRecord` observers coalesce replacement changes and copy bounded display
metadata. The model handles expiry, read/dismiss, actual action lookup, bounded
history (default100), stable toast IDs and exit retention. Closed objects/actions
are never retained for invocation. Expired snapshots remain in memory; dismissed,
client-closed and transient notifications leave history. No disk history store.

`ToastHost` and `NotificationCentre` are separate top-layer windows with zero
reservation, explicitly on the existing bar's screen. Toasts use one stack and a
union of animated card rectangles, with no keyboard focus or desktop-wide catcher.
The Centre uses a bounded scrolling surface and OnDemand focus. Neither enters
SharedStatusSurface or its module registry. The configurable bar bell opens the
Centre, closing status selection; opening a status menu closes the Centre.
`FullscreenMonitor` refreshes Hyprland raw client/monitor state on relevant events;
true compositor fullscreen on the target output suppresses every toast and closes
the Centre. The established bar fullscreen behavior remains compositor-owned.

Settings schema5 adds notification preferences and the bell placement. QuickActions
remains the DND action interface and shares `Settings.data.notifications.dnd` with
both views. `serverActivated` describes backend construction, not D-Bus proof;
runtime ownership is verified externally with `busctl`.

Bluetooth `barVisible` now follows connectedCount>0, while registry/service/detail
ownership stays unchanged. Collapsed rows animate reflow; the right-row move
transition is disabled during the accepted shared-surface morph. Theme's grouped
`stateColor/stateInk` resolves palette role→signed shade→strength. Primary uses
the existing `controlOn/Off` preferences plus OffShade; secondary has its own four
group settings. Primary per-control accent and tile/rim shades are unchanged.

Automated/private-bus checks passed. The operator reports all requested live checks
passed, including pointer/motion/fullscreen recovery, Bluetooth and state styling,
and supplied Centre/toast screenshots accepting the current presentation. Body
markup remains literal plain text; no markup capability is advertised. Multi-output
and fractional scaling remain unverified. Startup ownership is now migrated as
described above; multi-output presentation remains separate.

Updated **2026-10-03** for the visual/state/morph close-out.
The implementation below is operator-accepted except for the final bounded
per-control-accent/connected-Bluetooth review; see the
[sprint ledger](design/visual-refinement-checkpoint.md).
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
clock/date/workspaces/battery Components. A configured Bluetooth placement always
uses one 30px icon-only delegate; service and detail availability remain independent.

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
individual backgrounds blend into the common surface. Volume and Bluetooth are
icon-only; Battery displays percentage. Bluetooth connection state changes its
semantic icon, never compact width; its device name remains detail content.

`ExpandableModule.qml` owns plugin visuals/body Components and size requirements;
`ModulePill.qml` delegates compact presentation to `ExpandablePlugin.qml`. When `sharedSurface` is supplied, its individual animation driver
is bypassed and `MenuHostSelector.hostingEnabled` is false: no per-plugin adapter
or content Loader is instantiated. Plugin `phase` mirrors the common surface,
used by plugin presentation and lifecycle guards. Wi-Fi authentication now stays inline.

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
selected. This retains body state; Wi-Fi completion is observed by its module owner. The
surface grows to at least its expanded status-row width plus navigation/insets;
individual body widths/heights remain plugin-provided.

MenuController owns only a requested semantic ID and an ID history. `navigate`
pushes a detail destination, `back` returns, and direct `open`/`toggle` clears
history. No Item/window references enter that singleton. Control Centre's
secondary Wi-Fi/Bluetooth tile actions use `navigate` within the same surface.

Anchored rollback still selects the existing per-plugin animation and
PopupWindow adapter, including TransformWatcher, rounded window-relative
`mapFromItem()`, `anchor.window` and `PopupAdjustment.None`. Its geometry and
anchor mapping remains unchanged; animation owners now retarget open geometry for inline forms. `CombinedMenuHost.qml`
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

`plugins/bar/volume/Volume.qml` is a 30px compact control: left-click toggles mute,
wheel changes volume via Audio's existing 5% steps. The semantic icon uses central
muted/low/medium/high thresholds in `icons/IconState.js`. `expandsOnClick: false`
prevents the obsolete slider-only detail view; Control Centre retains the slider.
The nonvisual module and registry identity remain available for a future real mixer.

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

`plugins/bar/wifi/Wifi.qml` owns selection, pending connection and error state.
`WifiMenuContent.qml` supplies a 344px-wide bounded view with a content-dependent
height. `WifiAuthentication.qml` lives beneath the selected row, with masked input,
Enter/Connect, Cancel, Escape and inline retry/error feedback. Secrets live only in
TextInput and are cleared on submission/cancel/navigation. The old PasswordWindow
file is not instantiated. The combined surface and OnDemand focus remain active.

Pending-network Connections live in the session owner, independent of row lifetime.
Navigating away clears the auth UI but does not falsely cancel an in-flight
NetworkManager request. Late completion cannot reopen the view. Scanning continues
while the browser or a pending operation exists. Known/open/PSK Network calls are
unchanged. Real-component mocked lifecycle/geometry tests pass; real password,
compositor keyboard and anchored-inline-focus acceptance remain pending for this
change. The 2026-09-26 password-window acceptance is historical, not evidence for
this new inline UI.

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
- Complete operator validation of the new inline authentication and header morph.
- The supplied pack lacks battery-high artwork; that semantic state uses Legacy.
- Bluetooth's empty/off view still uses its earlier fixed-height composition.
- Decide when the anchored fallback can be retired. It remains a rollback
  path and is not the target for new plugins.


## Configuration and appearance foundation — implemented through schema v4

`services/Settings.qml` owns `settings/SettingsStore.qml`, pure schema/migration
JS and a Python standard-library atomic I/O helper. Schema v4 has appearance,
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
through one deterministic MediaController. The section keeps an intentional empty state when no suitable player
exists; explicit region/layout settings still use same-view geometry retargeting. The duplicated battery
summary has been removed. The initial Settings GUI and IconRegistry are
implemented. AssetManager validates and copies avatars/SVG overrides into XDG-
managed storage; bounded override UI covers an initial role subset. Host lifecycle,
MenuController semantics, Network and other system services remain unchanged.

## Current presentation ownership and tokens — 2026-10-02

`SharedStatusSurface.headerProgress` is independent of a changing module target.
The same status Loader/Row survives every transition; spacing6→12px, inset0→12px,
y0→8px and header28→44px interpolate without recomputing icon positions from a
new body width. Compact metrics ignore animated spacing. Body lifecycle durations
and single interactive owner remain unchanged. Anchored adapters now retarget
open width/height for inline forms; TransformWatcher/rounded positioning and native
bar reservation are unchanged. Fallback keyboard behavior requires runtime review.

`appearance.visual` adds bounded status icon size, primary rim width, on/off semantic
roles/opacity, slider track/fill/rim roles and width, avatar border width. Existing
roundness gains an avatar role. Schema v4 additionally stores one registry-validated
semantic accent role on every primary Control Centre entry. Theme changes resolve
that name through the new palette; global background/border shades remain downstream.
The v3→v4 migration supplies the catalogue defaults without changing order,
visibility or unrelated settings. These are additive effective defaults;
SettingsStore remains the sole writer. No automatic overwrite of live preferences.
`profile.subtitleMode` defaults to local greeting, with saved custom subtitle selectable.
`RoundedArtwork` masks source alpha with rounded geometry and draws a theme border;
media alone adds progress when supported position and duration exist. Explicit
user section-disable settings still apply; player absence alone never removes media.

The legacy `media.emptyState` field remains preserved for schema compatibility;
player absence no longer follows its old `collapse` value.

Deferred after the accepted visual-refinement checkpoint: Bluetooth compact
visibility will become connected-only without coupling service/detail availability
to bar placement. Primary and secondary controls will also share an inherited
semantic icon-state style combining ON/OFF roles, signed palette shade and state
strength/opacity. Neither change is part of the current implementation.
