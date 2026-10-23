# Phase 12C — Bar visual builder

## Native acceptance and completion — 2026-10-23

The operator explicitly accepted the native review and authorized finalization
(“yes accepted”). Phase 12C is complete. Phase 12D has not started.

All 68 allowlisted paths were integrated after confirmation of All changes saved.
The same single MAGI instance y610sddnt (PID 1546) reloaded successfully at 18:59:17.
No new QML errors or crash loop appeared. Existing Wayland text-input focus
warnings occurred during review; these were also present before integration.
Live IPC remains sandbox-blocked, so subjective native results below are operator
acceptance, supported by disk/log evidence and isolated production-component tests.

Accepted native review covers first-class Bar navigation; Layout canvas, Available
Modules, Left/Centre/Right editing, reversible drag/drop and keyboard fallback;
clear family versus instance inspection; full background and pill styling;
independent network accents; workspace-family styling; Wi-Fi/Bluetooth expanded
surface ownership; partial Surfaces redistribution; Behaviour controls; compact
stacking; light-theme presentation; and normal real Bar, Hub and Control Centre
operation. No physical display topology or hardware tests were performed.

### Final operator preferences and migration

Normal editor save persisted schema 17. Comparing the pre-integration snapshot
with final disk data, only schemaVersion, bar.visual and bar.modules changed.
Every prior preference, including layout, geometry and unrelated settings, remains
exactly preserved. Final preferences:

- Theme: Catppuccin Mocha.
- Left: clock, date; Centre: workspaces; Right: Bluetooth, Wi-Fi, volume, Control Centre, battery.
- Top Bar; horizontal inset 5; edge offset 0; external displays enabled.
- Full Bar background off; retained role elevated and opacity 0.35.
- Status/utility pills enabled, surface role, opacity 1; Bar roundness 1; status icon size 17.
- Workspace roundness inherits the Bar token.
- Wi-Fi accent peach; Bluetooth accent blue.
- Existing expanded-surface border role border, width 4; Wi-Fi/Bluetooth borders enabled; surface roundness 1.

settings.json is operator state and excluded from the commit. All other protected
regular-file hashes and the Yazi flavor symlink match the pre-integration snapshot.

### Reusable foundation and validation

Family resolution is configured by BarPage; palette identity and region alignment
are supplied by BarCanvas lane descriptors. Shared selection/reorder primitives
do not hard-code workspace/status families or Bar region IDs. No speculative
Control Centre structural editor was added.

All 16 post-integration regression runners passed: Phase12C; Settings schema/store/
persistence, presentation, reorder, appearance, modules; Phase10B synthetic policy
and lifecycle; Calendar Bar; Hub; shared-status/surface lifecycle; Power & Idle;
Displays; fingerprint/Security Settings; Phase12A; Phase12B; runtime visuals.
The module/runtime suites cover Wi-Fi, Bluetooth, volume, battery, clock/date,
workspaces and Control Centre. git diff --check passed.

Exact source set: 68 paths, 31 added / 37 modified / 0 deleted, including 18 PNG
previews and their HTML gallery. No temporary test artifacts, settings.json or
protected t15g files are included. See [path inventory](phase12c-path-inventory.txt).

## Initial isolated implementation record

Isolated implementation against c619375dbb052f0fdf7fb5b9161dc9807860601a.
No live integration or native acceptance. Phase 12D/E/F and hardware gates remain deferred.

## Pre-edit architecture and ownership audit

The Bar registry and schema support ten singleton IDs: clock, date, workspaces,
volume, wifi, bluetooth, battery, notifications, clipboard, controlcentre.
`Bar.qml` renders three ordered regions; right-hand modules participate in the
shared expanding status surface. Modules own services and menu lifecycles, while
`MorphingPillContent` owns status presentation. Volume has no expanded menu.
Clock/date use TimeDatePill; workspaces use one continuous chip with active cells;
battery owns a hover tooltip; notifications/clipboard are Hub launchers.

| Existing setting / current home | Proposed home / underlying ownership |
| --- | --- |
| Appearance → Bar: left/center/right order, placement and enablement | Bar → Layout; same singleton arrays; Available is registry minus placement |
| Appearance → Bar: top/bottom, horizontal inset, edge offset, external displays | Bar → Behaviour; same fields and 48 + edgeOffset reservation |
| Appearance → Bar: Status Icon Size | Bar → Colours & Look → shared Status / Utility Pills; existing visual.statusIconSize |
| Surfaces: Bar pills roundness | Bar → family inspector; existing roundness.roles.barPill for status/utility; workspace override defaults to inheriting that token |
| Surfaces: Wi-Fi/Bluetooth border toggles | Selected module → expanded menu; same surfaceBorders booleans |
| Surfaces: expanded border colour/width | Shared expanded-surface token; contextual controls explicitly disclose global scope |
| Surfaces: expanded roundness | Shared surface token; retained there and contextually identified as shared |
| Appearance: theme palette | Remains Appearance; Bar selectors refer to semantic roles |
| No existing Bar background fields | Bar host inspector; enabled/role/opacity, default transparent |
| No existing pill background fields | Shared status/utility family inspector; default surface at full opacity |
| No existing module accent fields | Wi-Fi/Bluetooth identity inspector; default accent preserves connected presentation |
| No existing Wi-Fi/Bluetooth surface background selector | Existing theme surface role retained; no invented per-module setting |
| Date/time formatting | Remains Date & time, alongside Calendar |
| Control Centre contents and appearance | Remain Control Centre; Phase 12D owns its editor |
| Hub launchers / battery tooltip | Their feature ownership stays unchanged |

Bar is promoted out of Appearance subnavigation using existing 22 px navigation.
No module duplicates or region visibility toggles. All-empty layout remains valid.
Surfaces is only partially redistributed; central semantic tokens remain central.

## Design

Canvas, structure editing and contextual inspection are distinct editor concerns.
Selection is transient `{scope, family, instance}` data, never a saved QML object.
Family edits affect all members; identity edits contain only meaningful accents.
The same canvas persists across Layout, Colours & Look and Behaviour.
Deterministic samples must never instantiate actionable network/audio modules.
Drag state is temporary; canonical edits publish atomically on drop and invalidate
stale gestures when ordering changes. Existing Settings autosave/reload remains
persistence authority. Preview geometry represents one output without native windows.

## Implemented architecture

- `VisualEditorFrame` composes the persistent canvas and inspector, switching to
  a vertical arrangement below 1050 px of page content. Bar alone opts into a
  1200 px page body; existing pages keep their accepted width.
- `EditorSelection` holds host/family/instance identity and retargets removed
  modules to the host. Selection does not write Settings. Module rows also
  support focus and Space/Return selection.
- `SettingsReorderBoard` retains its established pointer capture, stable keyed
  delegates, autoscroll, Escape/focus/resize cancellation, keyboard movement and
  canonical fingerprint validation. Its optional horizontal canvas mode supplies
  insertion markers and reflow; the default vertical mode remains for Control
  Centre. Handles are shown only in Layout.
- `BarCanvas` derives Available from `SettingsSchema.barIds`. All ten production
  IDs are supported, including optional Notifications and Clipboard. The canvas
  uses the actual `bar.left/center/right` arrays. Empty regions have no modules;
  Layout retains empty drop targets, with no persisted visibility switches.
- `placeBar(id, region, position)` removes the singleton from every region and
  inserts at the final index in one validated commit. Motion never invokes this
  writer. Any external canonical order change invalidates the active drag before
  drop; family/theme edits alone do not invalidate ordering.
- The page offers Layout, Colours & Look, Behaviour without replacing the canvas.
  The inspector separates shared family controls, identity, and expanded menu.
  Explicit region/remove buttons supplement Alt+arrow/Home/End handle movement.

## Presentation and inertness

`StatusPill` is a shared production frame. `TimeDatePill` gains an inert flag and
sample text; `Workspaces` gains a preview data/action boundary; battery content is
extracted into `BatteryPillContent` and used by both runtime and preview.
Expandable runtime modules and preview share `MorphingPillContent`; the preview
never instantiates Wi-Fi, Bluetooth, Volume or Control Centre service/action owners.
UtilityPill guards its Hub action when used inertly. No layer-shell window or
monitor apply operation is created by BarCanvas.

Preview samples are 10:24, 23/10/2026, workspaces 1–3 with 2 active, connected
network icons and battery 72%; volume shows its normal unmuted icon. Preview
placements include modules that runtime conditionally hides (e.g. disconnected
Bluetooth), so operators can still edit their structure.

Canvas geometry is a fit-to-width representative output: horizontal inset,
edge offset and top/bottom move the strip, and host fill occupies 48 logical px
before preview scaling. Drag handles/labels occupy editor-only space. Production
uses its unchanged OutputPolicy geometry, output routing and `48 + edgeOffset`
reservation. Production compact-output hiding remains untouched; editor preview
fits the entire composition to retain access to every configured object.

## Family, identity and schema

Schema bumps once, 16 → 17. Migration changes only the version; validated
fallbacks introduce absent fields without rewriting prior preferences or unknown
keys. Persistence's backup-version constant is aligned to 17 (it was still 15).

New fields:

```
bar.visual.host = { enabled: false, role: "surface", opacity: 1 }
bar.visual.statusPills = { enabled: true, role: "surface", opacity: 1 }
bar.visual.workspacePills = { roundness: null }
bar.modules.wifi = { accentRole: "accent" }
bar.modules.bluetooth = { accentRole: "accent" }
```

Status/utility roundness remains `appearance.roundness.roles.barPill`; null follows
Master. Status icon size remains `appearance.visual.statusIconSize`. Workspace
roundness defaults to inheriting the pre-existing Bar token, preserving tuning;
an explicit family override affects all workspace cells. There are no per-network
roundness, border, opacity or generic disabled-colour fields.

Host and status backgrounds accept existing semantic roles and finite opacity
0–1 only. Host has no invented border/roundness controls. Status pills have no
invented border controls either. Shared state ink keeps the accepted connected,
muted and volume-warning semantics. Wi-Fi and Bluetooth connected accents are
independent semantic roles, defaulting to the previous `accent`. Workspace
background/active colours remain their existing theme contract.

Defaults preserve transparent host, opaque surface pills, existing radius,
icon size, accents, order and geometry. Operator settings were read only as an
isolated migration input; the exact raw migrated document equals the original
except its version. No live settings or copied operator fixture is included.

## Expanded surfaces and boundaries

Wi-Fi/Bluetooth border enable toggles leave Surfaces for their selected-module
inspector. Both keep the original `appearance.surfaceBorders` keys. Existing
border colour/width and `roundness.roles.surface` are **global shared tokens**;
the contextual menu section labels that scope explicitly. Their global controls
remain under Surfaces for Control Centre/Hub ownership. These are contextual
editors for one value, not independent per-menu configuration.

There were no independent Wi-Fi/Bluetooth background or radius settings to move.
Their background remains the theme Surface role, described in the inspector.
Volume has no expanded menu; battery tooltip remains runtime-only. Calendar and
Control Centre keep feature ownership. Hub, remaining Surfaces controls, window
opacity/blur, lock and deferred hardware work are unchanged.

## Persistence and validation

SettingsStore remains the only persisted/draft authority. Edits use its existing
validated commit and debounce; temporary drag order lives in the reorder board.
Reload from Disk/discard restores layout, family styling and identity through the
same store. No Save button or editor configuration file was added.

Focused `tests/phase12c/run.py` uses disposable HOME/XDG roots, production Settings
content and QtTest pointer input. It covers pointer cross-region moves, no writes
on motion, a single commit on drop, Available placement/removal, all region
reorders, singleton moves, invalid IDs, stale-drag cancellation, keyboard movement,
all-empty layout, selection without mutation, family propagation, independent
red Wi-Fi/lavender Bluetooth, workspace-family propagation, host fill/opacity,
pill background disable, removed selection, autosave and discard. The schema test
covers default-preserving/idempotent migration, semantic and numeric validation,
registry alignment and removal of old Bar-owned controls. Existing production
reorder tests also exercise within-region/cross-region pointer drops, Escape,
scroll, keyboard, persistence and compact Settings.

Representative captures cover Catppuccin Mocha, Everforest Dark Hard, Rosé Pine,
Nord, Tokyo Night Moon and Rosé Pine Dawn. Normal/large and actual 720 px compact
windows are captured; the compact inspector stacks below the fitted canvas and
the page has no horizontal scrolling. The software renderer omits some SVG icons
and shader effects, as in earlier phase previews. OpenGL capture was attempted but
could not create an offscreen context. Native rendering/interaction remains a
later gate; no physical-output acceptance is claimed.

## Review and next-phase reuse

[Preview gallery](previews/phase12c/index.html) includes Layout/Available, dragging,
host, Wi-Fi/Bluetooth, workspace, enabled host, disabled pills, geometry, sizes
and representative palettes. These are production-component captures, not drawn
mockups. Review the scaled compact canvas and the explicit shared expanded-menu
token scope. New menu-specific backgrounds or independent borders would require
an intentional later schema/design decision, not silently duplicated values.

Phase 12D can reuse the frame, transient selection and horizontal/vertical reorder
engine while retaining its own registry, presenters and atomic writer. Phase 12E
can apply the same composition pattern to Hub. No generic persistence layer or
speculative structural Control Centre editor was added in 12C.

## Validation result (isolated)

Passed: Phase12C schema and production pointer/presentation suite; operator-shaped
migration fixture; Settings schema/store/persistence, module ownership, appearance,
all-page navigation/presentation and production drag/reorder; Phase12A and Phase12B;
Phase10B policy and synthetic multi-output lifecycle; runtime visuals; shared-status
48-step lifecycle; Calendar real-Bar routing; Hub suite; Power & Idle; Displays;
Security/fingerprint groundwork. No physical hardware test was run.

Older test expectations were updated for current schema 17, Bar's promoted route,
horizontal canvas geometry and the already accepted 18-theme registry. Their
assertions remain active. Known sandbox IPC/backend and software-window-mask
messages are filtered by existing isolated runners; no new QML warnings remain in
the focused editor run.

Final protection check: live HEAD is still the accepted baseline with 0/0 remote
comparison; complete live Git status and binary diff match the initial snapshot.
SHA-256 hashes match for all 13 dirty regular files. The Yazi flavor symlink was
not edited. `settings.json` is unchanged in both live and isolated worktrees.
No staged changes, commits, pushes or live integration. Temporary test roots are
automatically deleted; diagnostic logs and initial protection snapshots live in
`/tmp`, outside the path inventory. The retained preview PNGs/HTML are intentional
review artifacts. See [exact categorized path inventory](phase12c-path-inventory.txt).

Post-integration regressions: all 16 runners passed (Phase12C; Settings store, presentation, reorder, appearance, modules; Phase10B; Calendar Bar; Hub; shared-status; Power & Idle; Displays; fingerprint Settings; Phase12A; Phase12B; runtime visuals). Exact pending allowlist: 68 paths, 31 added / 37 modified / 0 deleted. Native acceptance is complete; the entry above records finalization.
