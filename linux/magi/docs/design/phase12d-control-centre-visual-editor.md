# Phase 12D — Control Centre visual editor v2

Isolated implementation from 008af02139ee0e83108f25ccd19ed684b41763da.
Architectural, functional and revised native visual review accepted on 2026-10-23.
Schema 18 is persisted and migration is verified. The isolated and intermediate
review records below are historical; the final acceptance record supersedes them.

## Pre-edit audit and ownership

Runtime has five fixed-position sections: Profile, Primary (`controls`), Sliders,
Secondary (`actions`), Media. SectionLayout supplies outgoing gaps. Five section
booleans plus media.enabled gate visibility; each array retains disabled records.
Primary controls use ControlTile, secondary controls ActionButton, sliders
IconSlider, ProfileHeader and MediaSection. ControlCatalog owns live actions;
preview already uses synthetic data and production presenters.

The catalogue includes Wi-Fi, Bluetooth, Power Saver, Airplane Mode, battery,
Settings, volume, brightness, VPN, DND, Caffeine, Lock, Hibernate, Shutdown,
Reboot, Apps, Notifications, Emoji and Clipboard. Volume/brightness are sliders.
Existing action routing supports both tile and compact presentations without
changing action semantics; network detail remains a secondary activation.
Per-group uniqueness previously allowed cross-group legacy duplicates. New editor
moves are singleton by module, preserving legacy records until deliberately moved.

| Current home / field | Phase 12D home |
| --- | --- |
| Appearance → Control Centre, section toggles | First-class Control Centre → Layout composition |
| controls/actions enabled flags and ordering | Placement in Primary/Secondary/Available; retained records, no visibility toggles |
| Primary/Secondary columns | Layout and selected region inspector |
| Profile avatar/typography/background/greeting | Profile Header selection |
| Primary controlOn/controlOff, off shade/opacity, tile shades/border, icon/container sizes | Primary family selection |
| Secondary on/off roles/shade/opacity, icon size | Secondary family selection |
| Slider track/fill/border/width | Slider selection |
| Four section gaps | Outgoing gap of the selected section; order independent |
| Media typography/artwork/progress/visibility/preferred player | Media selection (behaviour settings also reachable in Behaviour mode) |
| Surfaces: Control Centre border enabled | Control Centre host selection; same underlying surfaceBorders key |
| Surfaces: controlTile and slider roundness | Primary/Slider family inspector; same central tokens |
| Surfaces: Master roundness | Global Appearance |
| Surfaces: action roundness | Remains for other actions; new secondaryControl role migrates its existing value |
| Surfaces: expanded surface border colour/width/roundness | Shared tokens honestly labelled in host inspector; other owners retain contextual access |
| Profile identity/weather data | Existing Profile page; no Hub reorganization |


## Implemented composition and state contract

The first-class **Control Centre** navigation entry uses the established 22 px
navigation icon. Appearance retains theme, icon-pack and master-roundness controls;
the old Appearance → Control Centre configurator route is superseded. Surfaces
remains for other features and genuinely shared settings. No Hub redistribution.

One canvas serves Layout, Colours & Look and Behaviour. Layout has two tools:
**Arrange controls** exposes Primary, Secondary, Sliders and Available Controls;
**Arrange components** moves whole sections vertically and exposes Available
Components. Profile, Media and Sliders can be removed/restored as singleton
components. Primary/Secondary are derived containers: remove their members to
empty them, rather than toggling container visibility. Empty containers disappear
in production but remain editor drop targets. Legacy absent containers also have
editor-only targets; placing a control restores the container in composition.

The persisted schema-18 model retains `controlCentre.controls`, `.actions` and
`.sliders`, and adds `.layout`, an ordered unique array of
`profile / controls / sliders / actions / media`. Internal `actions` means the
user-facing Secondary Controls family. Existing per-entry `enabled` flags remain
internal placement records so removing/re-adding a module preserves its key,
accent and other preferences. No enabled/section switches are exposed. There is
one composition writer: `placeCCModule` atomically removes the identity from all
three arrays, moves its retained record to the chosen family, and publishes once.
Disabled entries are Available; entries in a legacy absent section are also
Available. Structural absence does not erase component preferences.

All catalogue non-slider modules support Primary/Secondary presentation using
the same ControlCatalog dispatch. Volume and Brightness remain sliders; invalid
family targets are rejected. Informational battery keeps its production semantics.
Destructive actions are never executed by tests or preview. Legacy cross-family
duplicates are preserved on migration to avoid silently deleting configuration;
a deliberate move consolidates that identity into one record. New editor edits
cannot introduce duplicates. This compatibility choice needs operator review.

Pointer motion stays in SettingsReorderBoard's transient keyed map. It reflows
neighbours, highlights the target, shows insertion and lifts the dragged item.
Only release over a valid target invokes the existing Settings commit/autosave
path. Escape, outside drop, focus loss and changed canonical composition cancel.
The canonical revision includes structural order and all three module arrays, so
an edit in another family invalidates an active drag. Alt+arrow/Home/End and
contextual move/remove buttons provide alternatives. Selection is local
`scope / family / instance` data; it never enters settings.json.

## Family styling and contextual ownership

Primary tiles share centralized `controlTile` roundness, icon/container sizes,
ON/OFF roles, OFF shade/strength, tile background/border shades and border width.
Secondary controls share the new `secondaryControl` roundness role, ON/OFF roles,
OFF shade/strength, icon/minimum container sizes, accent-background opacity and
border role/width. Individual accent belongs only to the module and follows a
Primary↔Secondary move; no module owns radius, border width or generic state ink.
Existing secondary entries without an accent retain their transparent background
and shared accent indicator. Their selector honestly offers **Shared accent /
transparent background**, rather than claiming a configured lavender accent.

The selected-module summary and **Individual accent ↓** shortcut make the scope
explicit even when shared-family controls require scrolling. Region headings
select family properties, including columns, without requiring an individual
control. Selection alone never mutates configuration; removing a selected module
retargets the inspector safely.

Profile selection retains avatar size/border/roundness, greeting/weather/detail
size and weight, greeting style and semantic background. Identity/avatar source
and weather setup remain in Profile. Media selection retains artwork size and
roundness, progress border/role, title/artist typography and playback controls.
Behaviour exposes the existing preferred-player and Always / While playing /
Player available / Hidden playback-control semantics. The legacy `emptyState`
field is retained but not promoted into a nonfunctional setting: current runtime
does not implement that field as a visibility authority.

Slider selection exposes shared track/fill/border roles, border width and
roundness. No unnecessary per-slider geometry or accent is invented. Host
selection exposes Control Centre's semantic background and existing border toggle.
Expanded-surface border colour/width and surface roundness remain shared tokens,
explicitly labelled as such. The Control Centre border toggle and Primary/Slider
roundness editing rows leave Surfaces; unrelated surface/Hub/action controls stay.
The shared `action` radius remains for other controls; Secondary gets a separate
centralized role, not an inline radius per module.

## Migration: 17 → 18, once

The migration preserves existing arrays, enabled flags, presentation, order,
columns, accents, Profile/Media appearance and unrelated fields. Each legacy
`sections` boolean maps to structural presence; `media.enabled=false` also omits
Media. Obsolete `sections` and `media.enabled` are removed from the persisted
document. The effective state also omits these obsolete fields; Settings commit strips any
legacy copies supplied by callers, and production CC consumes `.layout`. There is
no second visibility authority.

`secondaryControl` inherits the old `action` override (or null/master). New defaults
keep the host's surface role, transparent unaccented Secondary controls, zero
Secondary border and the prior minimum action size. Existing outgoing section
gaps retain their values. A new Media outgoing gap only matters when Media is no
longer last, so migration does not alter its old geometry. The operator's current
schema-17 shape was copied only into a temporary isolated fixture; the live file
was not migrated or edited. Migration is idempotent and preserves the tested
unrelated fields exactly.

## Reusable architecture and production boundary

Reuses Phase12C VisualEditorFrame, EditorSelection, SettingsDragHandle,
SettingsReorderBoard, SettingsSection and SettingsPage. SettingsReorderBoard gains
optional geometry/location adapters, target validation and a canonical revision
string for variable-height sections and embedded grids. Its default Bar geometry
is unchanged. The board owns no Control Centre catalogue, schema or persistence.
CC-specific composition geometry belongs in ControlCentrePreview. CCControlPreview
and CCSectionPreview are narrow inert adapters over production ControlTile,
ActionButton, IconSlider, ProfileHeader and MediaSection. SectionLayout.compose is
shared with runtime. Runtime action routing stays in ControlCatalog.

The preview uses synthetic Alex Morgan/weather, fixed slider values, active
Wi-Fi/Bluetooth and a sample track. Its presenters cannot toggle system services
or media. It includes editor-only section headings, selection outlines and empty
drop targets. Normal/wide layouts put the full-height canvas left and palette or
inspector right. The native-review revision keeps the complete canvas fitted on the left at all
window sizes, with the palette/inspector on the right and independent inspector
scroll, plus Expand preview. The page has no horizontal
scroll requirement. Primary cells keep production tile size; Secondary cells and
sliders distribute across their configured columns with production family gaps.

The shared geometry hooks are suitable for Phase12E Hub composition, while the
CC-specific catalogue/section adapters stay local. No Phase12E implementation,
application blur/opacity, lock changes, hardware activation or monitor topology
work is included.

## Validation and review artifacts

The Phase12D Node suite covers schema validation, composition order/uniqueness,
registry compatibility, inert presenter boundaries and migration fixtures:
defaults, each hidden legacy section, empty Primary/Secondary/Sliders, mixed
flags/custom ordering/accents and the temporary operator fixture. A separately
asserted expected transformation checks the intentional schema changes; all
unrelated fields and retained records are compared exactly.

QtTest exercises actual pointer cross-family and structural gestures, no-write
motion, singleton moves, stale-drag cancellation, keyboard moves, invalid targets,
selection, family radius/border propagation, distinct Wi-Fi/Bluetooth accents,
slider propagation, removal/restoration, empty targets, autosave and discard.
Production runtime coverage checks reordered section positions, all column counts,
empty/absent regions, family assignment, host colour and open/close. No destructive
runtime action is executed.

Regression coverage includes Settings schema/store/persistence, module ownership,
appearance, presentation/navigation, reorder, Phase10A, Phase10B, Phase10C.1,
Displays, Security/Fingerprint Settings, retained Phase12A contracts, Phase12B,
full Phase12C, Hub, shared-status/surface lifecycle, Calendar/Bar and runtime visual
suites. Old tests now navigate the first-class route and select contextual targets;
Phase12A pointer coverage is superseded by the more extensive Phase12D suite.

[Review gallery](previews/phase12d/index.html) contains production-component
captures of Layout/Available, lifted control/structural drags, host, Primary Wi-Fi,
Secondary Wi-Fi, individual accent, Profile, Sliders, Media, empty Primary,
Behaviour, compact and six representative palettes (including Rosé Pine Dawn).
The gallery explicitly uses the existing MAGI Legacy icon pack in its disposable
fixture because Qt's headless software renderer does not render the default SVG
MultiEffect tint pipeline completely. Default-pack tests also run. Artwork effects
still require native review. These are architecture captures, not native visual
acceptance or a change to the operator's icon pack/theme.

## Operator review decisions

- Two Layout tools distinguish whole-component composition from module assignment.
- Empty Primary/Secondary placeholders remain in Layout; production omits them.
- Existing enabled records are retained internally; removal is expressed through
  placement rather than a second user-facing visibility switch.
- Migration retains pre-existing cross-family duplicate records until explicitly moved.
- Secondary identity accents use a family-opacity background and active indicator;
  unspecified old secondary accents remain transparent/shared.
- Shared expanded-surface tokens remain honestly labelled, not falsely CC-specific.
- Fitted viewport/inspector balance, pointer lift/insertion feel and native icon/
  artwork rendering require direct review before any live integration.

This is an isolated implementation awaiting operator architecture review. No native
acceptance, staging, commit or push is claimed. Phase12E has not begun.

## Isolated acceptance record (2026-10-23)

- Verified baseline and tracking reference: `008af02139ee0e83108f25ccd19ed684b41763da`,
  `magi: add bar visual builder`, `HEAD...origin/main = 0 0`.
- All 18 listed regression entry points passed (Phase12A's compact assertions were
  updated to the new bounded 100 px minimum inspector; its retained typography,
  media semantics, inertness, theme, reset and persistence checks pass).
- Additional production composition run passed:
  `python linux/magi/tests/runtime-visual/run.py ../phase12d/runtime.qml`.
- Additional migration run passed against the temporary operator settings fixture:
  11 fixtures total; the committed test default has 10 synthetic fixtures.
- Phase12D's default-pack run and Legacy-pack capture run both passed. The capture
  set has 27 PNGs plus the HTML gallery. Six representative theme captures include
  Catppuccin Mocha, Everforest Dark Hard, Rosé Pine, Nord, Tokyo Night Moon and
  Rosé Pine Dawn; Phase12B validates the full theme registry.
- `git diff --check` passed. Both indexes are empty. No live code was copied and
  no live schema migration occurred. Live status and binary diff match the initial
  snapshot; all 13 protected regular-file hashes and the Yazi flavour symlink match.
- [Exact allowlist](phase12d-path-inventory.md): **74 paths**, **38 added / 36 modified /
  0 deleted**: 1 reusable primitive, 8 CC implementation, 10 settings/schema/shared
  tokens, 21 tests, 6 documentation and 28 preview assets. No protected state,
  caches, temporary logs or sandbox data is included.

Operator architecture/native review is still pending. Do not treat headless tests
as acceptance of native drag feel, SVG effects or artwork rendering.

## Finalization — integration evidence

Operator confirmed “all changes saved” before watched source was copied.
Preflight verified baseline `008af02139ee0e83108f25ccd19ed684b41763da`, divergence
`0 0`, empty index and exactly one registered live MAGI instance: `y610sddnt`,
PID 1546. Protected state, settings.json, current preferences and log position were
snapshotted under `/tmp/magi12d-finalization.fdJPik`.

The exact 74-path allowlist matched the isolated inventory and was integrated.
All copied bytes matched the reviewed source hashes. The same live instance logged
`Reloading configuration` at 20:11:22.351 and `Configuration Loaded` at 20:11:22.549.
No QML load error or crash loop appeared; existing Wayland text-input warnings
continued. Immediately after reload the on-disk schema-17 document was unchanged.
Normal editor saving, not direct file modification, will publish schema 18.

Compatibility audit: there are **no remaining effective compatibility projections**.
Migration maps then removes old `controlCentre.sections` and `media.enabled`;
validation strips them from effective state and commit strips legacy copies.
Production consumers use composition directly. No future projection-removal task
is needed. This is stricter than the permitted read-only compatibility fallback.

Native acceptance and final semantic migration comparison remain pending. No
staging, commit or push is authorized by this integration record alone.

Post-integration regression result: all 19 runs passed from the main checkout:
Settings schema/persistence, module ownership, appearance, presentation, reorder;
Phase10A, Phase10B, Phase10C.1, Displays, Security/Fingerprint; retained Phase12A,
Phase12B, full Phase12C, Phase12D; Hub, shared-status/surface, Calendar/Bar, runtime
visuals and the additional production CC composition fixture. The temporary
operator migration fixture also passed. `git diff --check` is clean. At this gate
the disk document is still unchanged schema 17; native review and a legitimate
saved editor change are required before migration acceptance or staging.

## Native visual revision — 2026-10-23

Operator accepted functionality and requested a visual correction: fit the entire
Control Centre preview to the available window height, with palette/options on
the right in Layout, Colours & Look and Behaviour. The earlier compact stacking
choice is superseded by this explicit request.

ControlCentrePreview now uses stable logical composition geometry with an aspect-
preserving fit transform bounded by available width and height. All sections,
including Media, remain visible together. The inspector stays in the right column
at compact sizes; only the options scroll. No Settings window height increase was
needed. Drag coordinates are mapped into the scaled board's coordinate space.
Neither composition nor styles nor persisted preferences are changed by resizing.

Tests assert full composition bounds and right-side inspector placement at
1080×780 and 720×500 in all three modes. Phase12D pointer/layout tests, full Bar
regression, retained Phase12A checks and Settings presentation passed. Three new
fit-layout/look/behaviour captures document the revision. The live instance
`y610sddnt` / PID 1546 reloaded at 20:19:30.370 without QML errors; settings.json
was byte-identical before/after the fix. Native visual re-acceptance and the normal
schema-18 save gate remain pending. Functionality acceptance is retained.

## Final native acceptance — 2026-10-23

Operator accepted functionality, identified only the canvas sizing/stacking issue,
then confirmed “confirmed, accepted” after the fitted preview revision was live.
The two Components/Controls tools, structural reorder/remove/restore, Available
state, singleton Primary↔Secondary moves and empty production regions are retained.
Shared-family and individual-accent ownership, the selected-item explanation and
Secondary accent treatment are accepted without redesign. Profile Header, Sliders,
Media and host inspectors retain their contextual settings. Behaviour exposes the
existing functional Media options. The old Appearance route is retired and only
CC-owned controls were redistributed from Surfaces.

The final visual arrangement keeps the full Control Centre on the left and options
on the right in all three modes, including compact widths. Fit assertions pass at
1080×780 and 720×500. Operator native visual acceptance covers the revised page;
the automated palette suite covers Mocha and Rosé Pine Dawn alongside the other
representative themes. Real Control Centre functionality and Bar editor functionality
were accepted; their production/regression suites pass. No destructive actions or
physical monitor tests were performed.

Final saved preferences preserve the preflight composition, enabled records, module
ordering, columns, individual module accents, Profile/Media typography, host and Bar
appearance, and preferred theme. The one retained review preference is Media progress
colour `red` (previously `accent`). Five new visual defaults were materialized normally:
Media outgoing gap 20, Secondary minimum container 38, accent background opacity .18,
border width 0 and border role `border`. These reproduce default prior presentation.

A semantic comparison of the live saved schema-18 effective document against the
migrated preflight document passes after accounting for that Media colour choice.
No unrelated effective values changed. Persisted `controlCentre.sections` and
`media.enabled` are absent; there are no effective compatibility projections either.
The same MAGI instance/PID remained live through both reloads, without QML errors.

All 19 post-integration regression entry points passed. The final visual revision
also passes Phase12D fit/pointer checks, full Phase12C, retained Phase12A and Settings
presentation/reorder checks. The operator snapshot remains protected: settings.json
contains only the verified migration/default materialization and accepted Media
colour change; all other protected file hashes and the Yazi symlink are unchanged.
settings.json and all t15g state are excluded from the commit.

Final allowlist: **77 paths, 41 added / 36 modified / 0 deleted**: 1 shared editor
primitive, 8 CC implementation, 10 Settings/schema/shared tokens, 21 tests, 6 docs,
31 preview assets (30 PNGs and one HTML gallery). Three fitted-layout captures were
added during native correction. No Phase12E implementation is included.
