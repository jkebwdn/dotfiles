# Settings refinement — accepted review

Baseline: `5e00c381f76830ba2a75e952e6f723efe2604ea1` (Roundness by feature,
accepted and pushed). The operator accepted the refined live UI on 2026-11-11
and approved committing this separate phase. Push requires separate approval.
Schema remains **22**.

## Bar ownership and workflow

One retained page replaces the Layout / Appearance / Behaviour tabs:

1. Layout card, including the existing pointer/keyboard reorder board. Its side
   lanes balance around the exact centre; headings align left/centre/right and
   the card fits the preview with a small bottom inset.
2. Available items, in its own compact card without a reserved second heading;
   the same board owns cross-region dragging.
3. Selected item, when selected, directly beneath Available items as one card;
   Fine tune is a subordinate disclosure. The card disappears on deselection.
4. Behaviour: the Tray/audio explanation sits immediately under the heading.
   Position, horizontal inset and edge offset sit inside Bar placement disclosure;
   external displays remain directly available.
5. Roundness: the existing `appearance.roundness.roles.barPill` editor;
   `bar.visual.workspacePills.roundness = null` continues to inherit it.
6. Global Bar options, always present: Bar background before Status items, both
   initially collapsed disclosures. Status icon size is first inside Status items.
   The foreground/artwork explanation follows the shared-background description;
   Menu borders remains a separate disclosure.

Clicking an empty part of the layout clears selection. Selection and disclosure do
not save preferences. Hidden/removed items clear the inspector. Custom Image retains
its existing asset picker, sizing, alpha and placement model. Workspaces retain
Bar roundness; Time/Date link conceptually to existing Date & time formatting.
No parallel layout model or second Custom Image inspector is introduced.

| Owner | Persisted fields | Runtime relationship |
| --- | --- | --- |
| Global Bar background | `bar.visual.host.enabled/role/opacity` | `Theme.barBackground`, Bar host |
| Global status backgrounds | `bar.visual.statusPills.enabled/role/opacity` | `Theme.statusPillBackground`, `barItemBackground`, connected pills |
| Status icon size | `appearance.visual.statusIconSize` | status presenters, shared across status items |
| Global menu borders | `appearance.surfaceBorders.{wifi,bluetooth,volume,role,width}` | existing `SurfaceBorder`; role/width also shared with other shell surfaces |
| Item background | `bar.modules[id].backgroundRole/backgroundShade` | null/absent role follows global status role; shade is independent |
| Wi-Fi/Bluetooth foreground | `bar.modules[id].accentRole/foregroundShade/foregroundOffShade` | non-null semantic accent, with existing live-state colouring |
| Other item foreground | `bar.modules[id].foregroundRole/foregroundShade/foregroundOffShade` where supported | null uses semantic fallback; not a nonexistent global foreground preference |
| Battery percentage | `percentageBackgroundRole/percentageBackgroundShade/percentageForegroundRole/percentageForegroundShade/showPercentage` | background role follows icon background when null; shade fallback unchanged |

Background inheritance is a checked “Use global background colour” toggle. Custom
mode starts at the effective global role; returning to inheritance sets the role
to null, without resetting shade. Battery names its icon-background parent.
Foreground toggles say “Use theme accent colour” for Wi-Fi/Bluetooth and “Use default
foreground colour” for the nullable semantic fallbacks. There is no global foreground
field to invent. For accentRole, entering custom mode without choosing another colour
is temporary UI state; no persisted Boolean or null value is added. Returning to the
theme accent writes the existing `accent` role. Previous custom roles are not cached.

## Appearance roundness

The previous “Use saved base value” was `appearance.roundness.master`, the hidden
compatibility multiplier. Every null role still falls directly back to that field;
Hub does **not** currently inherit the surface role, and Secondary does **not**
inherit Primary. Rewording must not silently change this geometry relationship.

Appearance keeps **Roundness — Cards, Menus, Notifications & Pop Ups.**, editing
`appearance.roundness.roles.surface`. Its slider is always editable, with no visible
inheritance control. A saved null displays its existing effective value and remains
null on passive visits. Deliberate adjustment creates the existing numeric override;
Reset roundness returns to the existing null default. Other role toggles accurately
say “Use base roundness (value×)”; the Workspace parent remains Bar pill roundness.
All 12 numeric fields, defaults, units, steps, native masks and runtime tokens remain.
No new parent relationship, clamp, field, default or migration is introduced.

## Wallpaper

Removed visible All / Favourites / Recents / Random / Refresh controls, favourite
stars and Library preferences. The grid uses the scanned entries without a filter.
The saved favourite/recent history and compatibility service methods remain, as do
existing thumbnail-size values; removing the editor does not reset them. Library
sources remain available in a disclosure because source paths are operationally
required. Manager enable/reset and per-monitor selection/fit behaviour remain.

`Wallpaper.prepare()` requests a fresh scan on page creation/revisit. Directory
changes retain their existing scan path; the worker coalesces pending work. There
is no polling timer or new watcher. A file added while the page stays open appears
on the next visit. The integration fixture adds an actual PNG to its private library,
revisits the page, observes two entries and verifies retained favourite history.
No source artwork or library path is modified by deployment.

## Control Centre

Suspend is an available catalogue action (the catalogue also permits existing
non-slider actions as primary tiles), using the existing sleep glyph and confirmation
route. Default/current layouts are unchanged. `QuickActions` checks logind CanSuspend
through `system_actions.py`, then uses the existing system-action dispatcher with
`systemctl --no-ask-password --check-inhibitors=yes suspend`, matching the native
lock/session path. Tests use mocks or dry run; no real suspend is authorized/run.

The preview previously used a fixed width and added section editing headings into
its panel geometry. It also reserved space for empty groups and used different
column/height calculations. These diverged from the real four-primary-control panel.

`SectionLayout.geometry()` now owns the existing runtime width/column/row/gap/section
calculations for both callers. Measured ProfileHeader/MediaSection heights and output
room are inputs. Preview editing labels, section reorder handles and available/empty
module drop targets live beside the panel, outside its composition. The panel has
no editor-only heading padding. Preview content margins match the runtime exactly;
profile/media read current metadata without invoking their actions. Output routing,
decoration, blur and open/close ownership remain unchanged.

Regression compares actual runtime presenter x/y/width/height and order with preview
slots for 0/2/4/6 primary controls, 360/1920 logical-pixel outputs, media on/off,
editing on/off, and Suspend added/removed. Four primary controls form one row at
normal width. Runtime roundness captures use the live Control Centre body rather
than the intentionally corrected Settings preview. Before/after comparisons are
against this phase's synchronized `5e00c38` baseline.

## Evidence and native gate

Durable evidence: `~/.local/state/magi/audits/settings-refinement-r_oyjief/`.
Initial Settings and 701 protected entries were snapshotted before edits; source work
is isolated in `/tmp/magi-settings-refinement-gy7lyl8r`. No live Settings writes,
staging, commits or service restarts are part of development checks.

- Responsive software captures: Nord and One Light, 720×600 / 1000×760 / 1400×900.
- Twenty-eight runtime roundness before/after pairs are pixel-identical.
- Exact schema-default and migration preservation is checked independently.
- Full regression before the final Bar presentation follow-ups: **110 PASS, 4 ENVIRONMENT, 0 FAIL, 0 UNKNOWN**.
  The established limits are private BlueZ/notification D-Bus, the clipboard image
  decoder sandbox and native-lock private socket/bus restrictions (the clean native
  build and host audit passed).
- Six affected suites passed after the final Bar follow-ups, including Settings
  presentation, pointer/keyboard reordering in standalone and Hub hosts, responsive
  refinement, and Phase 10A/12F. Revised captures cover Nord/One Light at all three
  widths. The additional full rerun was stopped after 17 passes; it is not reported
  as a completed final-source full matrix.
- Development end-state: all 701 protected entries and live Settings bytes unchanged;
  12 roundness fields preserved (including null/absent values), migrations/defaults
  unchanged, production divergence 0/0 and both indexes empty.
- Native helper self-test and three private deployment/rollback/conflict guards pass.
  Exact four-commit staging allocation: `commit-allocation.json` in the audit directory.
- Native acceptance is operator-reported: “perfect, this round of changes passes
  and is approved.” This follows the requested Bar disclosure, placement, alignment
  and spacing refinements. The private helper has no completed six-case receipt,
  so no automated per-case native completion or real Suspend execution is claimed.

The guarded native helper lives in the audit directory, snapshots current Settings
at invocation, validates reviewed source hashes and offers source-only rollback.
Private review cases exercise selection/inheritance/reorder, wallpaper discovery and
selection, the surface slider, and temporary Suspend placement. Private power actions
and application activation are blocked; private wallpaper selection cannot change
the desktop. The live-source check uses the operator's original values and must not
invoke Suspend. Unexpected state drift is reported, never overwritten by an old copy.

## Approved commit allocation — push separately

1. `magi: simplify bar settings workflow`: BarCanvas, BarInspector, BarGlobalSettings,
   BarPage, CustomImageSettings help, component registration; corresponding Bar tests.
2. `magi: simplify wallpaper settings`: Wallpaper service/page/content/tile and
   discovery integration test. Backend history/schema remain intact.
3. `magi: refine appearance inheritance labels`: RoundnessPicker/Value and roundness
   editor tests; no runtime radius changes.
4. `magi: align control centre preview and actions`: shared geometry, CC preview,
   catalogue/QuickActions/backend, shared reorder-board geometry extension, cross-page
   regression/native review fixtures and canonical documentation.

The final exact path allocation is generated separately for staging review. No
`settings.json`, generated state or audit captures belong in any commit.
