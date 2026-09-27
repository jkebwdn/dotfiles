# Semantic icons, configurable Control Centre and initial Settings

Implementation checkpoint **2026-09-27**, on accepted S1/S2 commit
`2012023cacd4b5b32599d701ccad83cd29c75da2`. **Automated tests and production
startup pass; the requested operator interaction checks are accepted.** No commit/push.
Paths below are relative to `.config/quickshell/magi/` unless prefixed `tests/`.

## Implemented contracts

### Semantic icons

`icons/IconRegistry.qml` loads `icons/packs/registry.json` and delegates pure
resolution to `IconResolver.js`. `components/controls/Icon.qml` renders a glyph
or bundled SVG descriptor. Consumers supply a semantic role, module ID, size and
theme color. SVGs retain their asset colors; no automatic SVG tinting is claimed.

Resolution order is module+role override, global role override, selected module
pack, selected global pack, built-in module/core fallback, neutral missing icon.
A pack can define module defaults and named SVG assets. Only manifest-relative
SVG paths are accepted; arbitrary settings paths/QML are never loaded. Individual
bundled override descriptors already resolve; the import/browser/editor is not
implemented. User asset descriptors deliberately fall back with a diagnostic
until validated import exists. Missing image rendering shows a neutral fallback.

The initial **MAGI Legacy** pack uses existing glyph code points and the installed
Nerd Font; no third-party font or artwork is bundled. Only this pack ships today.
The selected-pack setting now feeds actual rendering, and adding manifest packs
requires no consumer changes. Unknown global pack selection is shown in Appearance;
per-icon resolver diagnostics are available to future override tooling.

Roles include Wi-Fi signal/off/disconnected variants, Bluetooth/connected/off,
volume levels/mute, brightness, battery levels/charging/unknown, settings, night
light, DND, power profile, media transport, back, scan and connect/disconnect.
Reserved roles do not imply those future features have been implemented.

Migrated production consumers: status morph content for Wi-Fi/Bluetooth/Volume/CC,
battery status, Wi-Fi list/scan icons, Volume endpoints/mute, Bluetooth scan,
ControlTile, IconSlider, ActionChip, shared-surface Back and Settings previews.
Network/Battery's old glyph accessors remain unused compatibility properties;
system service operations are unchanged. Textual action labels/arrows remain
ordinary text. The old generic non-production ExpandablePlugin fallback label
still uses its icon string; current production plugins supply semantic Icon-based
pill Components. Future plugins should use that shared renderer.

### Configurable Control Centre

`modules/ControlCatalog.qml` describes stable IDs, labels, semantic icons/colors,
live availability/status, primary callbacks and optional detail destinations.
Its callbacks use existing Network, Bluetooth, Audio and Brightness services.
No executable action or QML path is accepted from JSON.

Supported controls: Wi-Fi, legacy read-only Battery status, mute/sound, Bluetooth,
Settings, volume down/up and brightness down/up. These nine real choices permit
4–8 controls without fabricated features or duplicate service owners. Default
assignments remain Wi-Fi/Battery/Sound/Bluetooth. The existing Battery tile is
retained as an optional legacy status control to preserve the requested defaults;
the **duplicated battery/time row is removed**. No richer Power module was added.

`ControlCentre.qml` renders ordered enabled slot records (stable `key`, `module`,
`enabled`, `presentation`) from Settings. Module IDs are unique per tile group.
Assignment/reorder affects delegates only, not module sessions. Volume/Brightness
sliders also consume their stored enabled/order records. The UI exposes slider
visibility; slider ordering currently remains a settings-data capability.

Columns are requested 1–16; effective columns clamp to output width. Tiles retain
60px hit geometry with 18px gaps and 14px insets; excess controls wrap. The body
scrolls when height exceeds its available limit. Four-column default target is
322px wide, 152px body, 188px including the expanded header; compact-row width
floor still applies. Removing the old power row removes its empty space as well.
No menu geometry contributes to exclusive reservation.

Layout changes apply while CC is open via S2 width/height bindings and retargeting;
the surface does not collapse/reopen. Changes are deferred during Wi-Fi password,
candidate or pending-connection sessions. Bar placement retains its stricter
idle-menu/animation deferral. Colors/icons/radii remain immediate.

### Settings application

`components/settings/SettingsApplication.qml` lazily creates one
`SettingsWindow.qml` using the already-selected Quickshell 0.3.1 FloatingWindow.
It is a normal desktop client, not a layer-shell surface. Hyprland may tile it;
no floating rules or configuration changes are injected. It shares the existing
Settings singleton and services, so closing the window cannot cancel its writer.

Entry points:

- Right-click the Control Centre bar trigger.
- Add the Settings tile to CC and activate it.
- `quickshell ipc -c magi call settingsWindow open`

`SettingsWindowState.qml` stores only ephemeral open/page intent. Opening first
closes the transient menu and waits for Bar.settingsReady; password/pending
interactions defer presentation. Repeated requests reuse the same window. There
is no additional global focus grab. The operator passed normal window manipulation and page interaction; a request
does not forcibly raise an already visible window.

Pages:

- **Appearance:** ten registered themes, live semantic palette swatches, icon-pack
  selector, master and five per-role radius controls, Default and section reset.
- **Bar:** existing eight module IDs, Hidden/Left/Centre/Right assignment and
  earlier/later ordering; reset. Hiding placement never unregisters its detail.
- **Control Centre:** columns/effective fit, enabled count, enable/disable, unique
  module assignment, move earlier/later, add/remove, slider visibility, reset and
  Preview. Stable keys permit a future drag-and-drop UI.

Theme/radius/button styling uses MAGI's semantic Theme. Native Qt controls provide
keyboard interaction; there are no empty future pages. Save/conflict/error status
is visible in the footer, with explicit discard-and-reload recovery. All edits
call SettingsStore setters; no second writer, Apply button or schema replacement.
New `placeBar`, `moveBar`, `editControl`, `moveControl`, `addControl` and
`removeControl` methods produce validated atomic snapshots through the existing
commit/debounce/helper path. v1 remains compatible; old settings need no rewrite.

Preview does not exempt Settings from the shell's outside-click policy: clicking
the Settings window while a menu is open may dismiss the transient surface. The
layout API itself retargets an open view; the automated test verifies this directly.
No catcher/focus exception was introduced for Settings.

## Validation performed

All final commands passed:

- `python3 tests/settings/run.py`: existing migration/persistence/reset tests.
- `python3 tests/settings/appearance.py`: ten palettes and live semantic radii.
- `python3 tests/settings/modules.py`: stable session ownership and mocked password handoff.
- `python3 tests/settings/modules.py control-layout.qml`: 4/5/6/7/8 columns,
  eight controls, enable/disable, reorder while open, geometry settling without
  fade/collapse, hidden originating pill → Bluetooth detail → Back, clean closure.
- `python3 tests/settings/modules.py window.qml`: real Settings components/pages,
  theme/radius/placement/layout writes, close-save-reload-reopen persistence and
  deferred opening while interaction readiness is false.
- `node tests/settings/icons.cjs .config/quickshell/magi/icons`: required roles,
  global/module/individual precedence, missing fallback, SVG path guards.
- `python3 tests/shared-status-surface/run.py`: all 48 lifecycle/retarget steps.
- Whole-production qmllint exits 0 with existing metadata/unqualified warnings;
  no new Settings-page warnings remain. `git diff --check` passes.

The QML fixtures use temporary config/state/runtime directories and mocked system
services for ownership/layout/window checks. No real user configuration is reset
or replaced with fixtures. The window test permits exactly Qt offscreen's
“This plugin does not support setting window masks” warning; all other warnings
and errors fail it. It cannot establish Wayland pointer/focus behavior.

Production launched with `quickshell -c magi -d`: PID **242555**, instance
**n575gok0mt**. Opening Settings maps one `org.quickshell` desktop client titled
**MAGI Settings**, same PID, accepting input. Hyprland tiled it under existing
rules. One shell layer remains **1920×1080 at (0,0)**; eDP-1 scale 2 reservation
**[0,48,0,0]**. Fresh runtime log contains only startup information. Mocha remains
the selected palette at launch. No pointer injection, device/network actions or
compositor configuration edits were used.

Operator confirmation received 2026-09-27: navigated all pages, resized the
window, and reported all requested checks working. Record the bounded operator
checklist as PASS: normal window manipulation/pages, live theme/radius edits and
close/reopen persistence, CC column/enable/assignment/order controls, and hidden
Wi-Fi/Bluetooth bar placement retaining CC detail navigation. This is operator
observation, distinct from the automated assertions above; it is not a claim of
pixel-perfect render acceptance or exhaustive testing of every configuration.

Post-review read-only checks: same healthy PID 242555; one 1920×1080 MAGI layer
at (0,0); reservation [0,48,0,0] on eDP-1 scale 2. Settings revision 234 reports
saved, no error and empty diagnostics. Operator-selected radius values and CC
order remain intact. The shell is combined/Mocha, phase 0 with catcher/keyboard
eligibility off; Settings remains open on Appearance. Runtime log is clean.
No new fullscreen, anchored runtime, fractional-scale or multi-output acceptance
is claimed.

## Scope and remaining work

New production files: icons registry/resolver/manifest/qmldir; shared Icon;
ControlCatalog/modules qmldir; SettingsWindowState; SettingsApplication,
SettingsWindow, SettingsButton and three page components. Modified: shell.qml,
Bar readiness, module/pill secondary-action forwarding, shared Back renderer,
common icon consumers, five bar plugins/menu presentations, settings schema/store
and services qmldir. Tests add icons.cjs, control-layout.qml and window.qml;
modules.py supports reusable isolated harnesses and the precise offscreen warning.

Preserved: semantic MenuController, shared lifecycle, Region/catcher/native
geometry, Network connection/password operations, Bluetooth operations, Audio,
Brightness, atomic persistence helper and anchored host adapters. No MPRIS,
profile, pairing, final morph or broad styling pass.

Remaining deliberate limits: one bundled pack; no SVG import/tint/override GUI;
fixed built-in action catalogue; reorder buttons rather than drag-and-drop;
optional legacy battery tile; compact width floor can exceed extremely narrow
outputs; exhaustive focus/compatibility testing remains separate from the passed
operator checklist. Multi-output and fractional scaling remain unvalidated.
Recommended next milestone
is bounded icon override/default UX and validated SVG import, with further Settings
polish driven by actual operator findings rather than another host redesign.
