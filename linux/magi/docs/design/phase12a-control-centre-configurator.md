# Phase 12A — Settings / Control Centre visual configurator

**Phase 12A accepted and complete, 2026-10-22.**
Initial isolated implementation evidence and final live acceptance are recorded separately below.
Baseline: `ca170a5625aab7fa37a7cb0d88faeeb199fb4016`,
`magi: add fingerprint authentication framework`; main `HEAD...origin/main = 0 0`.
Initial worktree: `/home/jkebwdn/magi-phase12a`. That initial pass performed no
staging, commit, push or integration. Finalization integrated the reviewed paths
after saved-state confirmation; explicit operator acceptance authorized commit/push.
No shell restart, package installation, hardware operation or authentication change.

## Before restructuring: audited production architecture

- `components/settings/SettingsContent.qml` retains visited pages in one Hub
  Settings surface. Appearance owns Theme, Surfaces, Bar, Control Centre and Hub
  subsections. Navigation rows were 34 px with 16 px icons and a 26 px label inset.
- `pages/ControlCentrePage.qml` previously mixed Profile and Media typography in
  Appearance, followed by Profile and playback, Layout, Visible sections, Primary
  controls, Sliders and Secondary actions. Progress and Hub toggle colours were on
  the general Appearance page. Greeting style was on Profile.
- `plugins/bar/controlcentre/ControlCentre.qml` remains the production expandable
  module. It owns runtime wiring through `ControlCatalog`, output-based width
  clamps, section visibility and `SectionLayout.arrange`. It uses ProfileHeader,
  ControlTile, IconSlider, ActionButton and MediaSection presenters.
- ProfileHeader reads the Settings profile and Weather. MediaSection already
  accepts a service property (default Services.Media). Production media selection
  uses `media.preferredPlayer`. The schema's `media.emptyState` currently has no
  consumer; it is preserved and deliberately not exposed as a working switch.
- `controlCentre.controls/sliders/actions` store stable keys, module IDs and enabled
  flags; controls also retain palette roles. `columns`, `actionColumns` and section
  flags remain canonical. Primary/action Settings boards already support pointer
  and keyboard reorder, removal and Available lists. Slider toggles existed.
- SettingsStore publishes edits immediately to `state.effective` and schedules an
  atomic save after **250 ms**. Runtime components already consume that effective
  state. There is no general staged Save button. Some separate path-entry editors
  have explicit-save semantics; those are unaffected. Reload/discard reads disk.
- The old page preview button pinned the **real** Control Centre. The new page
  embeds an inert preview instead. Existing pin/session/surface APIs remain intact
  and their tests exercise the service directly. No routing or singleton owner was
  replaced, and no second runtime Control Centre is created.

## Information architecture

**Live preview** stays alongside the editor on pages at least 800 px wide. Narrower
pages stack preview above the editor; Expand preview / Show settings provides room
for compact drag editing without shrinking controls to unreadable thumbnails.

**Profile Header** contains Avatar size, Avatar border width, Greeting/Weather/Detail
size and weight, Profile background and colour, greeting style and existing avatar
roundness. Identity/image selection and custom detail text remain in Profile.

**Controls** contains column settings, visible sections, primary tile appearance,
slider and secondary action appearance, section spacing, ordering and enablement.
The existing Available workflows remain; sliders now also have a keyboard reorder
board. Drag-to-enable/disable is deferred: add/remove/toggle controls already cover
it without introducing cross-type module conversion.

**Media Player** contains artwork size, title/artist size and weight, artwork/progress
border width, progress role, controls visibility, enabled state, preferred player
and existing artwork roundness. There are no duplicate typography or colour controls.
`active` is labelled **Player available** (including paused), preserving its actual
old semantics. **While playing** adds `playing` and checks available AND playing.
Always and Hidden retain their behaviour. No hover-only mode was added.

Navigation icons use `SettingsMetrics.navigationIconSize = 22` and an 8 px label
gap, retaining 34 px rows, centring, scroll/focus behaviour and selected-state
colours. This is a visual token, not another persisted preference.

## Schema 16 and colour responsibilities

Schema **15 → 16**, once. `appearance.hubSelectionRole` is the only new persisted
field. Its migration default is the old `hubToggleRole`, or `accent` when absent:
the old selected Hub icon used that exact role. All other document keys, including
unknown fields, layout metadata and unrelated settings, are preserved. The checked
operator shape is copied to an isolated fixture; live settings.json is untouched.
Loading a migrated document alone does not force a disk rewrite.

| Role | Consumer |
| --- | --- |
| navigationAccent | Settings primary navigation; existing subsection treatment remains |
| hubSelectionRole | Hub selected mode icon |
| hubToggleRole | Hub/Settings toggle controls |
| mediaProgressRole | Media artwork progress border |

Hub settings presents Selected mode colour and Toggle colour using the existing
SemanticPaletteSelector and accepted palette list. Reset Hub appearance resets
both Hub colour roles without changing navigationAccent. Theme resolution remains
centralized in Theme. No arbitrary hex input or new theme family.

## Production component reuse and safety boundary

`ControlCentrePreview.qml` hosts the **same five production presenters**, plus the
same SectionLayout helper and Theme/RenderTokens. ProfileHeader gains only injected
profile data and a preview flag to stop its clock timer. MediaSection gains an
interactive guard on each of its three action handlers; runtime defaults remain
unchanged. No live CC or Bar/Hub surface logic is refactored.

The preview injects a generic jkebwdn identity, evening hour, cloudy weather and
realistic detail text; a configured profile image may be displayed safely. Synthetic
Wi-Fi/Bluetooth are on, other toggles off, Volume 65%, Brightness 80%. A deterministic
media object supplies sample text, original bundled SVG artwork and 42% progress.
Its transport methods are no-ops. Playing/Paused is local UI state, never persisted.

There is **no ControlCatalog dispatch, process, system action handler or live media
service** in the preview host. Renderer loaders cannot receive input; tile/slider
interactive flags and the MediaSection guard also deny activation. Separate
SettingsDragHandle overlays own configuration. Even direct programmatic media
activation reaches only the inert service. Preview data is not a separate config
file. Synthetic values do not replace runtime backend state.

Tiles/actions keep production dimensions; columns clamp to readable available
width, as the runtime does. The caption reports fitted columns. Sliders share the
remaining width. A centred content region uses production section positions and
outgoing gaps, collapsing hidden/empty groups. The card scrolls vertically when
needed; there is no horizontal scrollbar or distorted tile scaling. Wide and compact
previews can show fewer columns than a much wider physical output.

## Drag and Settings lifecycle

`PreviewControlGrid` owns temporary ordered keys, original-order fingerprint,
pointer and insertion target. Motion reflows only this transient order. On valid
release it emits `(group, key, position)`; the page maps visible positions back to
the existing full list, preserving hidden entries and per-entry metadata. One
canonical Settings mutation occurs on drop, followed by the usual auto-save.

Cross-group keys, missing keys and out-of-range targets are rejected. Escape,
outside release, hidden/resized view, lost window focus and external ordering
changes cancel. Dragged cells highlight and other cells animate to insertion
positions. Profile/Media are structural, never draggable. Alt+Up/Down/Home/End and
the existing list boards remain available. No new public IPC or drag-to-run action.

Appearance edits, drop, reload/discard and reset all flow through existing Settings
methods. Because MAGI intentionally live-applies and auto-saves, **both preview and
runtime reflect normal edits immediately** after future integration; this phase
does not promise Save-gated runtime changes. Pointer motion is the exception: it
never publishes Settings. Discard can revert a pending edit before auto-save; after
save it reloads the new saved values. Tests exercise both cases.

## Validation and previews

Hardware-free tests run in disposable HOME/XDG/config copies; none use operator
settings or invoke destructive actions. New Phase12A tests cover:

- exact schema preservation and idempotence, including a copy of operator settings;
- independent three-way colour consumers and theme changes;
- production leaf/helper reuse and absence of preview backend dispatch;
- avatar/border, all typography sizes/weights, background toggle/role;
- media artwork/progress, four control visibility modes and paused simulation;
- column geometry and hidden-section layouts;
- controls/sliders/actions reorder, pointer drop, transient motion, Escape,
  invalid cross-type/key/index rejection and keyboard restoration;
- auto-save and discard/reload, compact expand/collapse and 720×500,
  940×720, 1400×900 geometry;
- Catppuccin Mocha, Catppuccin Frappé and Everforest Dark Hard.

Run `python linux/magi/tests/phase12a/run.py` from the repository root. Set
`MAGI_PHASE12A_PREVIEWS` to an output directory to retain captures. These are test
fixtures, not an operator helper or a live launch entrypoint. The runner permits
`MAGI_TEST_RENDERER` / `MAGI_TEST_QPA` for a future graphics-capable test environment.

**Rendering limitation:** captures use Qt's offscreen software scene graph.
MultiEffect-dependent SVG icons/artwork are not rendered by that backend. Geometry,
text, colours, controls and model behaviour are tested using production components;
the PNGs are not evidence of native shader quality. OpenGL RHI failed context
creation and surfaceless minimalegl failed EGL surface creation in this sandbox.
No production renderer was changed to hide this limit. Native visual review was subsequently accepted after coherent integration,
as recorded in the finalization section below.

Intentional captures (all generated from production presenters):

- [Overall page / larger navigation icons](previews/phase12a/overall.png)
- [Default preview](previews/phase12a/default.png)
- [Profile Header changes](previews/phase12a/profile.png)
- [Media Player changes](previews/phase12a/media.png)
- [Transient reorder](previews/phase12a/reorder.png)
- [Independent Hub role selectors](previews/phase12a/hub.png)
- [Compact layout](previews/phase12a/compact.png), [expanded preview](previews/phase12a/compact-expanded.png)
- [Frappé](previews/phase12a/frappe.png), [Everforest](previews/phase12a/everforest.png)

Final hardware-free results (2026-10-22):

| Suite | Result |
| --- | --- |
| Phase12A schema, boundary, QML presentation | PASS; 10 captures |
| Separate operator-shape 15→16 preservation fixture | PASS |
| Settings schema/store/persistence (`tests/settings/run.py`) | PASS; zero failures in all fixtures |
| Settings presentation, all pages including Security, keyboard, 5 palettes, compact/normal | PASS |
| Existing Settings reorder (standalone and `--hub`) | PASS; pointer/keyboard/cancel/scroll/metadata/persistence |
| Settings modules / media / assets | PASS |
| Shared status surfaces | PASS; 48 lifecycle steps |
| Hub suite | PASS |
| Phase10A icon/fallback suite | PASS |
| Phase10B policy and lifecycle | PASS |
| Phase10C.1 schema, policy and Settings fixtures | PASS |
| Phase11A fingerprint Settings presentation | PASS; synthetic only |
| Runtime visual default, appearance, Hub, feedback, typography, polish, secondary, colour equivalence | PASS |
| Calendar, Clipboard, Emoji, Launcher, Wallpaper schema regressions | PASS |
| `git diff --check` | PASS |

The legacy appearance fixture now uses the retained pin service rather than the
removed page button, reveals controls inside the new editor viewport and navigates
to Security instead of the retired Icons page. All previous runtime assertions,
including 96 hidden-section/gap combinations, remain. Its timeout is 120 seconds
for the longer page traversal; other fixtures retain their original limits.
Migration regression expectations explicitly allow the one new role while still
comparing every prior document field. No transport tests or hardware tests were
weakened or bypassed; lock/PAM suites are outside this visual-only change.
Known offscreen IPC/window-mask/D-Bus diagnostics are filtered by existing test
patterns, not counted as native environment validation.

## Review decisions and deferred scope

Review the existing auto-save/live-apply contract, compact expansion affordance,
fit-column policy, moved controls and lossless Player available label. The old real
CC pin API remains solely for compatibility; the page now directs users to the safe
embedded preview. Existing emptyState semantics remain unimplemented, unexposed
and unchanged rather than pretending that a schema field already works.

No new themes (12B), Bar/pill controls (12C), application opacity/blur (12D), lock
customisation, Greeter, fingerprint activation (11B), display hardware acceptance
(10C.2B), PAM or enrollment changes. Production authentication stays password-only.

## Sources and compatibility

Inspected 2026-10-22, installed Quickshell 0.3.2 / Qt 6.12.0. Existing MAGI baseline
source is the authority for the saved configuration, module wiring and surface
contracts described above.

- [Qt QQuickItem](https://doc.qt.io/qt-6/qquickitem.html): coordinate mapping
  preserves transforms; PreviewControlGrid maps handle points into its grid.
  New tests exercise that mapping through actual pointer events and resize.
- [Qt MouseArea](https://doc.qt.io/qt-6/qml-qtquick-mousearea.html): press/move/release,
  cancellation and preventStealing underpin the existing SettingsDragHandle.
  Reused without a separate drag daemon or dependence on Wayland native DnD.
- [Quickshell FloatingWindow 0.3.1 API](https://quickshell.org/docs/v0.3.1/types/Quickshell/FloatingWindow/):
  used only by the existing isolated window fixture. The installed 0.3.2 accepts
  it in tests; production remains the existing Hub surface. No new native window
  or routing API is introduced. Native appearance was operator-accepted at finalization; hardware tests remain deferred.

The sample SVG is original project fixture artwork, not a copied external asset.

## Final proposed path inventory

52 paths: 18 added, 34 modified, 0 deleted. The exact reviewed commit allowlist; protected local settings are excluded.

### Implementation (16)

```text
M linux/magi/.config/quickshell/magi/components/hub/HubContent.qml
A linux/magi/.config/quickshell/magi/components/settings/ControlCentrePreview.qml
A linux/magi/.config/quickshell/magi/components/settings/PreviewControlGrid.qml
M linux/magi/.config/quickshell/magi/components/settings/SettingsMetrics.qml
M linux/magi/.config/quickshell/magi/components/settings/SettingsNavigationItem.qml
M linux/magi/.config/quickshell/magi/components/settings/pages/AppearancePage.qml
M linux/magi/.config/quickshell/magi/components/settings/pages/ControlCentrePage.qml
M linux/magi/.config/quickshell/magi/components/settings/pages/HubPage.qml
M linux/magi/.config/quickshell/magi/components/settings/pages/ProfilePage.qml
A linux/magi/.config/quickshell/magi/components/settings/preview-artwork.svg
M linux/magi/.config/quickshell/magi/components/settings/qmldir
M linux/magi/.config/quickshell/magi/plugins/bar/controlcentre/MediaSection.qml
M linux/magi/.config/quickshell/magi/plugins/bar/controlcentre/ProfileHeader.qml
M linux/magi/.config/quickshell/magi/settings/SettingsMigrations.js
M linux/magi/.config/quickshell/magi/settings/SettingsSchema.js
M linux/magi/.config/quickshell/magi/theme/Theme.qml
```

### Tests (20)

```text
M linux/magi/tests/calendar/schema.cjs
M linux/magi/tests/clipboard/schema.cjs
M linux/magi/tests/emoji/schema.cjs
M linux/magi/tests/launcher/schema.cjs
M linux/magi/tests/phase10b/policy.cjs
M linux/magi/tests/phase10c1/schema.cjs
A linux/magi/tests/phase12a/boundary.cjs
A linux/magi/tests/phase12a/presentation.qml
A linux/magi/tests/phase12a/run.py
A linux/magi/tests/phase12a/schema.cjs
M linux/magi/tests/runtime-visual/appearance.qml
M linux/magi/tests/runtime-visual/feedback.qml
M linux/magi/tests/runtime-visual/hub.qml
M linux/magi/tests/runtime-visual/run.py
M linux/magi/tests/runtime-visual/typography.qml
M linux/magi/tests/settings/presentation.qml
M linux/magi/tests/settings/run.py
M linux/magi/tests/settings/schema.cjs
M linux/magi/tests/settings/store.qml
M linux/magi/tests/wallpaper/schema.cjs
```

### Documentation (6)

```text
M linux/magi/README.md
M linux/magi/docs/README.md
M linux/magi/docs/architecture.md
M linux/magi/docs/decisions.md
A linux/magi/docs/design/phase12a-control-centre-configurator.md
M linux/magi/docs/quickshell-reference.md
```

### Preview assets (10)

```text
A linux/magi/docs/design/previews/phase12a/compact-expanded.png
A linux/magi/docs/design/previews/phase12a/compact.png
A linux/magi/docs/design/previews/phase12a/default.png
A linux/magi/docs/design/previews/phase12a/everforest.png
A linux/magi/docs/design/previews/phase12a/frappe.png
A linux/magi/docs/design/previews/phase12a/hub.png
A linux/magi/docs/design/previews/phase12a/media.png
A linux/magi/docs/design/previews/phase12a/overall.png
A linux/magi/docs/design/previews/phase12a/profile.png
A linux/magi/docs/design/previews/phase12a/reorder.png
```

Protected state is not part of this inventory. All 14 snapshotted main-checkout
file hashes and the original tracked dirty diff match exactly. Main remains at
`ca170a5625aab7fa37a7cb0d88faeeb199fb4016`, `HEAD...origin/main = 0 0`;
both indexes are empty. settings.json, t15g files, enrollment and production
packages/PAM are untouched. Runtime logs, temporary fixtures, preview generation
outputs and failed graphics experiments remain outside Git under `/tmp/magi12a`
or deleted temporary directories. The generated assets.py bytecode cache was
removed from this worktree. No generated state or deployment fixtures are included.

## Finalization gate — native review accepted

The operator accepted the isolated architecture and confirmed All changes saved
before integration. Main baseline and origin/main were both
`ca170a5625aab7fa37a7cb0d88faeeb199fb4016` (`0 0`), with an empty index.
The 52 reviewed paths were copied as one prepared set, excluding settings.json.
The original sample SVG is intentional preview artwork.

Preflight recorded the sole MAGI instance `d817zobnt`, PID 1597, and log position
15,751 bytes / 84 lines. The same instance logged Reloading configuration followed
by Configuration Loaded at 2026-10-22 21:07:24, without QML load errors or a restart.
Wayland text-input disableSurface focus warnings appeared afterward; these are
recorded separately from QML errors and require checking during native review.
Disk settings initially remained byte-identical at schema 15: normal loading
migrates effective values without writing until the next settings save.

Fresh snapshots cover the 13 dirty regular files, original diff, live settings,
and the protected Yazi flavor symlink plus its target content. Unlike the initial
isolated development snapshot, this gate explicitly records that symlink identity.
Unrelated local state remains excluded from the Phase12A inventory and staging.
The operator then changed Selected mode colour Blue → Red and confirmed All changes
saved. (Selecting the already-selected Red had correctly been a no-op.) The resulting
JSON matched the preflight document exactly after adding only schemaVersion 16 and
appearance.hubSelectionRole = red. Every unrelated value was preserved, including
theme/icons/navigation/toggle roles, Bar, Power & Idle, layouts, Profile, Media and
any other stored framework or unknown keys. settings.json is excluded from Git.

The operator explicitly answered **“accept”** to the native visual/behaviour gate,
covering larger aligned navigation icons; readable shader-rendered preview; Profile
Header / Controls / Media Player organisation; reversible immediate profile/media
updates; visibility simulation; tile/slider/action drag, invalid cross-type drag,
Escape and keyboard fallback; compact expansion; independent Hub colours; inert
preview actions; and real Control Centre/Hub opening, rendering and order. This is
operator-confirmed native acceptance; sandbox fixtures do not substitute for it.
No destructive runtime actions or hardware acceptance were requested or performed.

The final local preference comparison retained navigationAccent=red,
hubSelectionRole=red and hubToggleRole=red. The only difference beyond migration was
the accepted quick-control order: Wi-Fi, Bluetooth, Airplane Mode, Power Saver;
the disabled Battery entry remains intact. Other stored values and all unrelated
protected files/symlink content remained unchanged. No test colours were left.

Post-integration focused regressions: Phase12A, Settings schema/store/persistence,
presentation, reorder, Media, assets/Profile, shared status/surface lifecycle,
Hub, Phase10A, Phase10B, Phase10C.1, fingerprint Security navigation, runtime CC
appearance and typography/colour consumers all passed. The first concurrent run
of the modules fixture reported one failure, “CC opens without bar delegates” at
its fixed 500 ms checkpoint. An unchanged standalone rerun passed with zero
failures. This timing-sensitive result is recorded, not relabelled as an initial
pass; no assertions or fixture timing were weakened during finalization.

The same sole shell instance remained PID 1597 / d817zobnt. Exactly one automatic
configuration reload occurred, with no QML errors or crash loop. disableSurface
focus warnings also occurred before integration (72 in the saved log prefix), so
they are existing Wayland diagnostics rather than new QML load errors. No deliberate
shell restart occurred. Final inventory remains 52 paths (18 A / 34 M / 0 D), with
16 implementation, 20 tests, 6 docs and 10 intentional previews. No generated
artifacts or protected local settings are in the allowlist. Phase12B and every
deferred hardware milestone remain deferred.
