# Phase 12E — Hub visual editor and Settings ownership

Status: integrated and natively accepted; final regression passed with the two documented environment/baseline limits.
Baseline: `5d2a07bc0ee4d0b0d4c320964d7e7e4ee6bdcc94`.

## Ownership audit (recorded before implementation)

The visible feature owns its editing route. Central semantic tokens remain central.
All keys below are existing schema-18 keys; no migration or value reset is needed.
`appearance.` is abbreviated `a.` in the table.

| Old location | Setting | Key/token | Current consumers | New editing home | Scope |
|---|---|---|---|---|---|
| Surfaces | Navigation accent | a.navigationAccent | SettingsNavigationItem only | Appearance: Settings navigation accent | Settings navigation |
| Surfaces | Toggle style | a.toggleStyle | CompactToggle, SettingsToggle, Wi-Fi menu, Bluetooth menu | Hub: Toggles, explicitly labelled shared switch style | Shell-wide switches; not Hub-only |
| Surfaces | Expanded border colour/width | a.surfaceBorders.role/width | SurfaceBorder: CC, Wi-Fi, Bluetooth, Hub content/selector | Appearance: shared expanded-surface borders; accepted Bar/CC contextual shared editors retained | Shared expanded surfaces |
| Surfaces | Hub content border | a.surfaceBorders.hubContent | HubContent | Hub: content inspector | Hub host |
| Surfaces | Hub selector border | a.surfaceBorders.hubSelector | HubContent selector | Hub: selector inspector | All Hub modes |
| Surfaces | Card border colour/width | a.notificationBorders.role/width | NotificationCard (toast/history), ClipboardContent card | Notifications: cards — shared with Clipboard | Shared card family |
| Surfaces | Toast borders | a.notificationBorders.toasts | NotificationCard | Notifications: Toasts | Toast presentation |
| Surfaces | History borders | a.notificationBorders.history | NotificationCard | Notifications: History | History presentation |
| Surfaces | Clipboard card borders | a.notificationBorders.clipboard | ClipboardContent | Clipboard: Card appearance | Clipboard cards |
| Surfaces | Expanded surface roundness | a.roundness.roles.surface | Hub, Settings sidebar/popups, Calendar, launcher, Emoji, Clipboard, notifications, Bar expanded menus, CC | Appearance: shared surface/card roundness; accepted Bar/CC contextual controls retained and honestly shared | Cross-feature |
| Surfaces | Buttons/actions roundness | a.roundness.roles.action | Settings controls, CompactToggle, ActionChip, IconButton, Hub search, Calendar, launcher, Clipboard/notification actions, Wallpaper | Appearance: shared button roundness | Cross-feature (not CC Secondary) |
| Surfaces | Reset surface borders | a.surfaceBorders + a.notificationBorders | Both families above | Appearance: Reset shared borders | Same complete reset operation |
| Appearance → Hub | Selected mode colour | a.hubSelectionRole | Hub mode icons via Theme.hubSelectionColor | Hub: selector inspector | All selector modes |
| Appearance → Hub | Toggle colour | a.hubToggleRole | SettingsToggle via Theme.hubToggleColor | Hub: toggles inspector, labelled Hub-hosted Settings toggles | Hub-hosted Settings; Wi-Fi/BT retain their own accent |
| Appearance → Hub | Selector position | hub.selectorPosition | HubContent | Hub: Layout | Hub |
| Appearance → Hub | Vertical position | hub.verticalPosition | HubWindow selector anchor | Hub: Layout | Hub |
| Appearance → Hub | Selector roundness/default | a.roundness.roles.hubSelector | Hub selector pill | Hub: selector inspector | Selector family |
| Appearance → Hub | Reset Hub appearance | hub + selector roundness + Hub roles | As above | Hub: reset button | Same reset, not unrelated shared values |
| Appearance | Theme, icon pack/install, palette swatches, application theme following | a.theme, icons.*, applicationThemes.* | ThemeRegistry/IconRegistry/application theme orchestration | Appearance (unchanged) | Global |
| Appearance | Master roundness/reset appearance | a.roundness.master / a.* | Central Theme radius resolver | Appearance (unchanged) | Global |

### Other ownership checked

- Bar exclusively edits `appearance.visual.statusIconSize`, Bar visuals and Bar-pill
  roundness. Wi-Fi/Bluetooth expanded border toggles already live in BarInspector.
- CC exclusively edits primary `controlTile`, `secondaryControl`, `slider`, `avatar`
  and `albumArt` roundness in CCInspector. `controlTile` also styles Profile/Media
  containers; `avatar` is consumed by the Profile page thumbnail. These are existing
  shared semantic relationships, not new per-instance settings.
- `barPill` is Bar-owned; workspace-family styling remains in Bar. No Bar/CC editor
  changes are needed. Their existing explicitly shared surface controls are retained.
- Notifications behaviour (enabled, toast visibility, DND, body preview, critical
  bypass, retention, timeout/count limits) stays on Notifications.
- Clipboard collection/images/files/persistence/limits/history actions stay on Clipboard.
- Emoji has no feature-specific border/roundness field in Surfaces. Its host uses
  global `surface`/`action` tokens; no invented Emoji option is introduced.
- `navigationAccent`, `hubSelectionRole`, `hubToggleRole` are independent values.
  The latter currently styles SettingsToggle only, so its description must say so.

## Design decisions

Hub gets one first-class 22 px navigation entry. Layout, Colours & Look and Behaviour
share a production-presenter canvas, local mode selection and EditorSelection.
Preview sits left and the independently scrollable inspector sits right at ordinary
Settings widths, fitting the representative Hub into the available height. Compact
stacking is reserved for genuinely narrow content widths.

A narrow production presenter extraction will share Hub selector and content framing
without constructing live child services. Synthetic child content is explicitly a
sample, not a second implementation of Apps/Clipboard/etc. Notification samples use
NotificationCard with inert data/service; Clipboard samples share the production card
frame. Preview selection never persists, activates services or changes real Hub mode.

Hub content/selector use existing fixed Theme.surface backgrounds: no unsupported
background-role setting is invented. Shared border role/width and surface roundness
are linked to their clearly labelled shared home. Toggle style is accessed in Hub
but explicitly affects Settings, Wi-Fi and Bluetooth switches. Individual Hub toggle
colour affects only Hub-hosted Settings toggles. No per-mode geometry is added.

Schema remains **18**. UI redistribution does not alter persisted representation,
legacy CC compatibility projections, autosave, reset or discard/reload contracts.
Surfaces can retire: every control, including reset, has a mapped owner above.
Phase 12F application opacity/blur and all hardware work remain out of scope.

## Implemented architecture

- First-class Hub uses the existing 22 px SettingsNavigationItem and a `hub` semantic
  icon-manifest role in both shipped packs (no per-instance icon overrides).
- `VisualEditorFrame`, `EditorSelection`, SettingsPage/Section and semantic palette
  selectors are reused. Only SurfaceStyleSettings gains `showSharedControls`, default
  true, allowing a feature to edit its border flag without duplicating shared fields.
  Bar and CC use their unchanged default behavior; their source is untouched.
- Hub Layout edits existing above/below and vertical-anchor values. Canvas applies the
  same selector-anchor/clamped-content equations as HubWindow. No invented ordering
  or visibility system is needed for this host.
- Colours & Look selects Content, Selector or Toggles. Selection and Apps/Clipboard/
  Notifications/Emoji/Settings sample mode remain local, never settings.json fields.
- Host/selector backgrounds use the existing Theme.surface. No new role, opacity or
  individual mode geometry is introduced. Selector roundness is family-wide. Host
  border/roundness links lead to explicitly shared Appearance controls.
- Behaviour explains existing retained-mode, search and dismissal semantics; there
  are no additional persisted Hub behaviour switches to invent. Layout owns anchoring.
- The canvas is left and the inspector right at 1080×780 and 720×500; the latter uses
  smaller fitted framing and independent inspector scrolling. Stacking is reserved
  for editor content narrower than 400 px. Preview actions are inert. Cross-page
  buttons lead to Notifications, Clipboard and Emoji rather than duplicating them.
- Production `HubContent` now uses `HubSelector` and `HubSurface`; selector keyboard
  handling, mode availability, aliases and focus dispatch are preserved. The editor
  never instantiates live Hub child features. Clipboard's existing card rectangle is
  a small shared `ClipboardCardFrame`, not a second full Clipboard implementation.
- Notification samples use actual NotificationCard with local records and no-op
  callbacks, plus an input shield. Clipboard samples use the shared production frame.

### No data migration

Schema/migration/store files are byte-unchanged from the accepted baseline. Schema-18
operator fixture, defaults and custom role/border/roundness inputs validate and migrate
idempotently without changes. No field is retired with the page. Existing save/debounce,
reset and discard/reload remain the sole persistence system. Preview selection and
mode changes are tested to leave the Settings revision/data and real Hub mode alone.

## Verification

Passed isolated entry points (including reruns after obsolete route assertions changed):

- Settings schema/store/persistence, modules, appearance, presentation/navigation and
  reorder: `tests/settings/{run,modules,appearance,presentation,reorder}.py`.
- `tests/phase10a/run.py`, `phase10b/run.py` (synthetic multi-output),
  `phase10c1/run.py` (Power & Idle), `displays/run.py`, `fingerprint/run.py`.
- `tests/phase12a/run.py` retained checks, `phase12b/run.py` all 18 themes,
  `phase12c/run.py` full Bar and `phase12d/run.py` full CC editor regressions.
- `tests/hub/run.py`: modes, retained state, selectors, keyboard/Escape, outside-click
  mask, search, singleton/monitor routing, Clipboard/Emoji dispatch fixtures, notification
  bounded growth and Clear All. No live service actions were exercised.
- `tests/shared-status-surface/run.py`, `calendar/bar.py`, `runtime-visual/run.py`,
  and `runtime-visual/run.py ../phase12d/runtime.qml` production CC composition.
- `tests/notifications/presentation.py`: toast/history, retention, Clear All,
  fullscreen/input masks; `node tests/notifications/policy.cjs` from linux/magi:
  DND/critical/fullscreen policy. `tests/clipboard/presentation.py`: pinned-first,
  newest-on-entry, search/browse preservation and card presentation.
- `tests/emoji/{backend,presentation}.py`: recent/categories/search/insertion fixtures.
- `tests/settings/icons.cjs` validates semantic manifest fallback including the new Hub role.
- The runtime visual suite additionally opens real (service-stubbed) Wi-Fi and Bluetooth
  menus and checks Pill/Filled/Minimal track/knob geometry for each switch. Changing
  Hub toggle colour does not recolour these switches. Phase12E tests check Settings
  toggle colour separately, covering every audited CompactToggle consumer.
- `tests/phase12e/run.py`: ownership, unchanged schema18 (operator fixture optional via
  `MAGI_PHASE12E_FIXTURE`), independent role scopes, actual selector/toggle pointer
  safety, family border flags and shared production overlays, local selection,
  save/discard and geometry at 1450×1000, 1080×780, 720×500. Both default and legacy
  production icon packs were exercised. Representative six palettes rendered.

Limits, not waived tests:

1. `tests/notifications/run.py` cannot start its PRIVATE D-Bus: socket bind returns
   `Operation not permitted` in this sandbox. It never touched the desktop bus.
   Protocol-level integration remains unverified here; synthetic policy/presentation
   tests pass. No approval helper or external notification traffic was requested.
2. `tests/clipboard/model.py`: 9/11 pass, two image-decoding errors (`Image unavailable
   or exceeds limits`). The same two errors reproduce on the untouched accepted main
   checkout. Backend and tests are unchanged; no assertions were weakened.
3. Offscreen Qt has expected IPC/window-mask/backend limitations. The production legacy
   glyph pack is used for readable review captures because default SVG effects are not
   fully represented by the software renderer. Native rendering remains an integration
   gate. Preview fixtures are not evidence of a native acceptance or hardware test.

## Operator architecture review

Please assess the preview-left/options-right proportions, the single Content/Selector/
Toggles selection model, the shared switch-style explanation, and whether linking to
shared Appearance/card tokens is clear enough. Appearance contains global tokens in
addition to Theme/Icon Pack/Master; this is intentional because their consumers cross
feature boundaries. Notifications owns card role/width shared with Clipboard; Clipboard
owns only its enabled flag. This avoids invented duplicate state.

At the isolated review checkpoint, live integration, staging, commit and push were
deferred. The subsequently authorized finalization is recorded below. Phase 12F
has not started.

## Review gallery

21 intentional production-presenter captures; no temporary render output is included.

- [hub-layout](previews/phase12e/hub-layout.png)
- [hub-host](previews/phase12e/hub-host.png)
- [hub-selector](previews/phase12e/hub-selector.png)
- [hub-toggles](previews/phase12e/hub-toggles.png)
- [hub-clipboard](previews/phase12e/hub-clipboard.png)
- [hub-notifications](previews/phase12e/hub-notifications.png)
- [hub-emoji](previews/phase12e/hub-emoji.png)
- [hub-settings](previews/phase12e/hub-settings.png)
- [hub-above](previews/phase12e/hub-above.png)
- [notifications](previews/phase12e/notifications.png)
- [clipboard](previews/phase12e/clipboard.png)
- [appearance](previews/phase12e/appearance.png)
- [appearance-shared](previews/phase12e/appearance-shared.png)
- [catppuccin-mocha](previews/phase12e/catppuccin-mocha.png)
- [everforest-dark-hard](previews/phase12e/everforest-dark-hard.png)
- [rose-pine](previews/phase12e/rose-pine.png)
- [nord](previews/phase12e/nord.png)
- [tokyo-night-moon](previews/phase12e/tokyo-night-moon.png)
- [rose-pine-dawn](previews/phase12e/rose-pine-dawn.png)
- [compact](previews/phase12e/compact.png)
- [hub-behaviour](previews/phase12e/hub-behaviour.png)

The navigation capture is included in every full Settings image, notably Hub Layout.
Six palette captures cover Catppuccin Mocha, Everforest Dark Hard, Rosé Pine, Nord,
Tokyo Night Moon and Rosé Pine Dawn. Notification and Clipboard captures also use
Dawn. Baseline outside-click persistence is retained; no dismissal behavior changed.

## Final isolated path inventory

55 intended paths: 30 A, 24 M, 1 D. No index entries.

| Category | Paths |
|---|---:|
| Shared card presentation | 3 |
| Hub editor / production presenters | 6 |
| Settings navigation / icon manifests | 4 |
| Shared editor support | 2 |
| Ownership redistribution / feature pages | 3 |
| Surfaces retirement | 1 |
| Documentation | 6 |
| Preview assets | 21 |
| Tests | 9 |

### Shared card presentation

```text
A linux/magi/.config/quickshell/magi/components/clipboard/ClipboardCardFrame.qml
M linux/magi/.config/quickshell/magi/components/clipboard/ClipboardContent.qml
A linux/magi/.config/quickshell/magi/components/settings/CardStylePreview.qml
```

### Hub editor / production presenters

```text
M linux/magi/.config/quickshell/magi/components/hub/HubContent.qml
A linux/magi/.config/quickshell/magi/components/hub/HubSelector.qml
A linux/magi/.config/quickshell/magi/components/hub/HubSurface.qml
M linux/magi/.config/quickshell/magi/components/hub/qmldir
A linux/magi/.config/quickshell/magi/components/settings/HubPreview.qml
M linux/magi/.config/quickshell/magi/components/settings/pages/HubPage.qml
```

### Settings navigation / icon manifests

```text
M linux/magi/.config/quickshell/magi/components/settings/SettingsContent.qml
M linux/magi/.config/quickshell/magi/icons/packs/magi-default/manifest.json
M linux/magi/.config/quickshell/magi/icons/packs/magi-legacy/manifest.json
M linux/magi/.config/quickshell/magi/services/SettingsWindowState.qml
```

### Shared editor support

```text
M linux/magi/.config/quickshell/magi/components/settings/SurfaceStyleSettings.qml
M linux/magi/.config/quickshell/magi/components/settings/qmldir
```

### Ownership redistribution / feature pages

```text
M linux/magi/.config/quickshell/magi/components/settings/pages/AppearancePage.qml
M linux/magi/.config/quickshell/magi/components/settings/pages/ClipboardPage.qml
M linux/magi/.config/quickshell/magi/components/settings/pages/NotificationsPage.qml
```

### Surfaces retirement

```text
D linux/magi/.config/quickshell/magi/components/settings/pages/SurfacesPage.qml
```

### Documentation

```text
M linux/magi/README.md
M linux/magi/docs/README.md
M linux/magi/docs/architecture.md
M linux/magi/docs/decisions.md
A linux/magi/docs/design/phase12e-hub-settings-ownership.md
M linux/magi/docs/quickshell-reference.md
```

### Preview assets

```text
A linux/magi/docs/design/previews/phase12e/appearance-shared.png
A linux/magi/docs/design/previews/phase12e/appearance.png
A linux/magi/docs/design/previews/phase12e/catppuccin-mocha.png
A linux/magi/docs/design/previews/phase12e/clipboard.png
A linux/magi/docs/design/previews/phase12e/compact.png
A linux/magi/docs/design/previews/phase12e/everforest-dark-hard.png
A linux/magi/docs/design/previews/phase12e/hub-above.png
A linux/magi/docs/design/previews/phase12e/hub-behaviour.png
A linux/magi/docs/design/previews/phase12e/hub-clipboard.png
A linux/magi/docs/design/previews/phase12e/hub-emoji.png
A linux/magi/docs/design/previews/phase12e/hub-host.png
A linux/magi/docs/design/previews/phase12e/hub-layout.png
A linux/magi/docs/design/previews/phase12e/hub-notifications.png
A linux/magi/docs/design/previews/phase12e/hub-selector.png
A linux/magi/docs/design/previews/phase12e/hub-settings.png
A linux/magi/docs/design/previews/phase12e/hub-toggles.png
A linux/magi/docs/design/previews/phase12e/nord.png
A linux/magi/docs/design/previews/phase12e/notifications.png
A linux/magi/docs/design/previews/phase12e/rose-pine-dawn.png
A linux/magi/docs/design/previews/phase12e/rose-pine.png
A linux/magi/docs/design/previews/phase12e/tokyo-night-moon.png
```

### Tests

```text
M linux/magi/tests/phase10a/refinement.qml
M linux/magi/tests/phase12a/boundary.cjs
M linux/magi/tests/phase12c/schema.cjs
A linux/magi/tests/phase12e/ownership.cjs
A linux/magi/tests/phase12e/presentation.qml
A linux/magi/tests/phase12e/run.py
M linux/magi/tests/runtime-visual/hub.qml
M linux/magi/tests/runtime-visual/runtime.qml
M linux/magi/tests/settings/presentation.qml
```

Protected main-checkout state: byte/hash comparison confirmed all 13 regular files
and 1 symlink unchanged, including settings.json and the Yazi flavour link.
Main status and binary diff match the initial snapshot exactly. Both indexes are empty.
Snapshot, logs, fixtures and extra renders live under /tmp, outside this inventory.
No schema/store changes, protected operator files, generated caches or temporary scripts
are included. At that checkpoint main remained on the accepted baseline; isolated HEAD is detached there.

## Finalization — live integration (2026-10-23)

Baseline reverified as `5d2a07bc0ee4d0b0d4c320964d7e7e4ee6bdcc94`, origin/main 0/0.
The allowlist is 55 paths (30 A / 24 M / 1 D), with SurfacesPage.qml the sole deletion.
The operator confirmed All changes saved before integration. One MAGI shell was
registered: y610sddnt, PID 1546, launched 17:57:36. Live IPC is sandbox-blocked.
The existing log recorded one reload and Configuration Loaded at 21:08:32, with the
same instance retained and no new QML errors. Wayland text-input focus warnings
were observed; no shell restart or monitor/hardware operation was performed.

Schema was 18 before and after. Integration itself preserved settings.json byte-for-byte
and all 13 protected regular files plus the Yazi symlink. A fresh snapshot and exact
allowlist are held outside the repository in /tmp/magi12e-finalization.6elpemca.
Pre-review preferences: Catppuccin Mocha; selector above at 10%; selected-mode red,
Hub toggle green, Settings navigation blue; Pill switch style; shared border role
border and width 4. Native review changes/preferences will be recorded on acceptance.

At this integration checkpoint native acceptance was pending and post-integration
regressions were running in disposable copies with synthetic services; nothing was
staged. The acceptance and final results follow.

### Native acceptance

The operator explicitly confirmed “Accepted — native review passed; preferences
restored” before staging. This covers the Hub as a first-class editor, fitted
preview-left/inspector-right layout at normal/compact sizes, unclipped selection,
content/selector/toggle inspectors and all five inert preview modes.

The accepted wording makes Switch style shared across Hub-hosted Settings, Wi-Fi
and Bluetooth switches, while Hub toggle colour remains independent from selected
mode colour and Settings navigation accent. Pill/Filled/Minimal scope is accepted.
Behaviour correctly says outside clicks pass through without dismissal and Escape
closes Hub. Selector placement and vertical anchoring remain unchanged in runtime.

Notifications owns Toast/History flags and shared card role/width; Clipboard owns
its flag and links to shared fields. The shared-border explanation, inert cards,
global Appearance controls and complete Surfaces retirement are accepted. Emoji
has no invented appearance controls. Master and shared surface/action roundness
remain centralized; Bar status sizing and Wi-Fi/Bluetooth surfaces remain Bar-owned.
CC's host/Profile/Primary/Secondary/Slider/Media contextual ownership is unchanged.

Rosé Pine Dawn native review and brief real Bar/Control Centre sanity reviews passed
according to the operator. Catppuccin Mocha and all recorded preferences were restored.
Post-review hash comparison found zero changes in the 13 protected regular files
(including settings.json) or the Yazi symlink. Schema remains 18; no migration occurred.

### Final regression and reviewed set

After live integration, 23 of 25 main suite invocations passed. The other two are
exactly the documented limits: private notification D-Bus socket binding denied by
the sandbox, and Clipboard model image-decoding errors (9/11 pass, two baseline
errors). No test was weakened. Additional Hub production runtime, CC composition
and notification policy runs all passed. Full Phase12C and Phase12D regressions,
Phase12E, schema/store/persistence, page presentation/navigation, appearance,
reorder, Hub lifecycle, Notifications presentation/retention, Clipboard UI, Emoji,
shared-status, Calendar, Phase10A/B/C.1, Displays, Fingerprint and theme suites passed.

Final reviewed set remains **55 paths: 30 added, 24 modified, 1 deleted**. It includes
21 intentional preview assets; the only deletion is the retired SurfacesPage.qml.
No schema/store, protected settings.json, operator-local t15g state, temporary logs,
caches or Phase12F work is included. The explicit native acceptance precedes staging.
`git diff --check` passes. Protected-state hashes and the same single MAGI instance
were reverified after native review and automated tests.
