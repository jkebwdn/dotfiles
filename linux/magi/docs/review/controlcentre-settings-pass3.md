# Control Centre Settings hierarchy — Pass 3 review candidate

Baseline `677ae1273139978d17d89ce9b831a9c76dfdf292` was verified equal to
origin/main, divergence 0/0, clean tree and empty index on 2026-11-11. This phase
changes Settings presentation only. Schema 22, migrations/defaults, saved values,
runtime presenters, theme tokens and accepted preview geometry remain unchanged.
No commit, push or Pass 4 is authorized by this review document.

## Inspector structure

1. **Available controls** — existing collapsible add/remove catalogue and instructions.
2. **Selected contextual inspector** — only while selected, retaining separate primary
   module versus individual-button ownership.
3. **Colours** — major card with persistent **Background** and **Border** subheadings.
   Background stays open; Border options disclose independently.
4. **Status Items** — standalone major card containing Icon colour, sample, Fine tune,
   shade and the existing Reset status row action.
5. **Roundness** — always-visible Controls and Artwork & Identity subheadings;
   only their options collapse.
6. **Decorative image** — original component and fields, last.

`CCGlobalSettings.qml` and its registration are removed, not hidden or renamed.
`CCColourSettings.qml` and `CCStatusSettings.qml` reuse existing selectors, writers
and the grouped Settings card system. The Colours footer retains the explicitly
labelled **Reset Control Centre appearance** action with its original broad scope:
visual module settings except statusIconSize, plus the five CC roundness overrides.
It is not relabelled as a colour-only reset. Each field has one editor within
Control Centre; existing shared-border editors on other pages are unchanged.

## Colour/status ownership

The [complete ownership table](controlcentre-settings-pass3-ownership.csv) includes
all six persisted fields and both reset actions from the former global area.

- Background: `appearance.controlCentreBackgroundRole` → live ControlCentre
  `viewSurfaceColor`, editor panel and status sample.
- Border: `appearance.surfaceBorders.role`, `.width`, `.controlcentre` → existing
  SurfaceBorder. Role and width remain shared across menu surfaces; the enable
  flag applies to Control Centre. Range 0–5 for width is unchanged. There was no
  separate opacity/shade field in this editor; no new one is invented.
- Status: `appearance.statusRowRole`, `.statusRowShade` →
  `Theme.expandedStatusForeground` → `statusRowForeground` in MorphingPillContent
  and BatteryPillContent. The expanded status header is shared with other expanded
  status menus. Collapsed Bar pills retain Bar styling. This is not the primary
  tile/secondary-action accent editor; those stay in the contextual inspector.
  Shade retains −1…1, step .05, null→0. Reset writes null to both original fields.

The Status Items help states this actual shared-header scope rather than claiming
CC-exclusive runtime behavior. Colours help likewise explains shared menu borders.
There are no new preferences or colour semantics.

## Shared contextual information pattern

`SettingsInfo.qml` is a reusable, Settings-independent ToolButton with a semantic
`info` icon. The new canonical SVG role is additive; selected packs lacking it use
normal MAGI-default fallback. All existing icon roles are unchanged. The simple
circle/i vector was authored for this component, with no external asset dependency.

Hover reveals a local ToolTip after 300ms; keyboard focus reveals it immediately.
Click/tap or Space shows help through button focus; Escape dismisses it. Leaving
hover closes it unless the button still has keyboard/click focus; moving focus
away closes it. Help is also exposed via Accessible.description and its button has
an explicit name. SettingsFocus supplies the existing Tab outline/reveal behavior.

The nonmodal Popup.Item uses semantic overlay/text/border, Appearance surface
roundness, plain wrapped 12px help text, at most 320px width and window margins.
It does not own keyboard focus, allocate layout height, or write Settings. Existing
card/subheading/roundness components have an optional `infoText`, empty by default.
Other pages are not mass-migrated. Existing permanent descriptions remain supported.

Preferred hierarchy: 26px page title → 16px bold card title → 15px demi-bold
subheading → 14px row label → 12px contextual help. Use a short label plus info for
non-obvious scope. Do not attach an icon to every obvious row. Keep useful task
instructions (such as Available controls drag guidance) visible.

## Roundness scope, reconfirmed from current source

| Concise label / field under `appearance.roundness.roles` | Actual runtime consumers | Contextual help |
| --- | --- | --- |
| Primary Controls / `controlTile` | RenderTokens.tileRadius → ControlTile; ProfileHeader and MediaSection container backgrounds | Shapes primary tiles and the profile and media container backgrounds. |
| Secondary Controls / `secondaryControl` | ActionButton background and glyph treatment | Shapes secondary action buttons and their glyph treatment. |
| Sliders / `slider` | RenderTokens.sliderRadius → IconSlider track and fill | Shapes Control Centre slider tracks and fills. |
| Media Artwork / `albumArt` | MediaSection → RoundedArtwork crop, border and progress path | Shapes artwork crops, borders and progress outlines. |
| Avatar / Identity / `avatar` | ProfileHeader, ProfilePage → RoundedArtwork; LockScreenPage previews; native `visual_data.cpp` and `presentation.cpp` avatar mask | Shapes profile and avatar masks, including native lock artwork. |

The same runtime presenters are used by CCSectionPreview/ControlCentrePreview.
All five multiplier ranges, steps, nullable master fallback, inheritance/reset
writers and native-lock relationship are unchanged. No `action` editor returns;
generic MAGI controls still use Appearance `roles.surface`. No old descriptive
paragraph remains under the CC roundness group/labels.

## Geometry and workflow

ControlCentrePreview, SettingsReorderBoard, EditorSelection, SectionLayout and
all live Control Centre source are byte-identical to baseline. The fixed panel,
independent inspector, compact top-preview fallback, title-aligned left edge,
panel-first scale, decoration compact-fit behavior, drop coordinate transforms,
keyboard reorder, add/remove, individual selection and selection reveal remain.
Reset composition remains under the preview. No new scroll owner or sidebar page.

## Verification and native gate

Evidence: `~/.local/state/magi/audits/controlcentre-settings-pass3-s6fgclmi/`.
The hierarchy test runs the real Settings page in private XDG roots: help hover,
leave/focus/Space/click/Escape, no layout jump or persistence writes, exact card
order, disclosures, field writers/save-reload and six palette/width cases.
Existing workflow/fit tests cover drag, keyboard reorder, invalid drops, Suspend,
selection, geometry and wide/tall/disabled decoration. Responsive captures include
selection, Colours, Border, Status Items, Roundness, help and decoration.

Runtime equivalence uses the current baseline and identical private operator
values: all 46 Nord/One Light comparison images are pixel-identical; 354 existing
runtime/schema/native files are byte-identical, with only the additive help-icon
manifest outside Settings changed. No runtime role rebinding occurs in Pass 3.
The initial targeted run caught a Roundness label-layout warning; the recursive
width constraint was removed and the affected suites pass. This was not hidden
as an environment limitation. Private file-read checks wait for asynchronous
FileView reload completion before comparing saved bytes.

Full regression totals and final protected checks are recorded in the phase
receipt. Native acceptance remains pending. Software rendering omits some existing
MultiEffect semantic SVG/alpha pixels; those captures certify layout, not native
icon rendering. Review the info glyphs and light/dark contrast in the native helper.
The helper takes fresh invocation-time snapshots, offers guarded source rollback,
and keeps interaction changes in private Settings. It never invokes Suspend or
rewinds live history. Review the real page passively after the private cases.

Proposed commit after acceptance: `magi: refine control centre settings hierarchy`.
The exact source/test/document allocation is retained with the review receipt;
Settings, assets imported by the operator and generated/audit state are excluded.

### Baseline decoration-test reconciliation

The full run exposed an obsolete `preview.visible` expectation in the decoration
fixture. Running the unmodified test against clean production `677ae12` reproduces
the same failure at line 151 (`decoration-baseline.log`). Pass 2's final accepted
left alignment intentionally leaves no left-side artwork space in this fixture.
The test now requires successful decode and `visible === fits`, preserving the
real shrink/hide fallback. Live decoration, alpha, animation, routing and geometry
assertions remain unchanged. No production source was changed to accommodate the
test. The corrected decoration suite and final complete matrix are recorded
separately; the failed diagnostic run is retained, not relabelled as ENVIRONMENT.

## Final automated gate

The final complete matrix records **113 PASS, 4 ENVIRONMENT, 0 FAIL, 0 UNKNOWN**
(`full-final/summary.json`). Established restrictions are Bluetooth private D-Bus,
clipboard transport/private D-Bus, notification bus and native-lock sandbox access.
The last Escape-dismissal refinement has a separate passing six-width/palette
hierarchy check (`final-help`): leaving a dismissed but still-focused info icon
does not reopen its tooltip. It follows the complete run; no broader rerun is
claimed. Six guarded source-deployment/rollback scenarios also pass, including
removed-component recovery. The six private review launches preserve Settings
and all 701 protected entries during each launch sequence, but are not native
operator acceptance.

Production remains clean/synchronized at `677ae12`, with empty index. Candidate
index is empty. The final phase-start comparison found one concurrent Settings
change: `appearance.mediaProgressRole` red → green. The operator explicitly
confirmed this adjustment; current green is preserved, not reset to the snapshot.
All other Settings values and the other 700 protected entries are unchanged.
Schema/defaults/migrations remain 22/unchanged. `git diff --check` passes. No live
source deployment, Settings write, staging, commit or push has occurred. Native
review takes a fresh invocation snapshot. The 31-path allocation and 60-image
gallery are retained in the audit directory.

## Native operator acceptance — 2026-11-11

All six native Nord/One Light cases passed at 720×600, 1000×760 and
1400×900, followed by a passing passive review of the deployed live page.
The operator accepted hierarchy, info glyph/help interaction and contrast,
sticky preview, selection/reorder/add/remove and decoration. Panel dimensions
were 204.34×285, 304×424 and 380×530 logical pixels respectively in both palettes.
Receipt: `native-review-t1t7imer/result.json` in the Pass 3 audit directory.

Invocation-time Settings and all 701 protected entries remained unchanged.
The confirmed green media progress colour remains preserved. Review source is
currently deployed reversibly; production HEAD/origin remain `677ae12`, with only
the expected review source changes in the production working tree. This supersedes
the earlier pre-deployment status above. No staging, commit or push occurred.
Native acceptance is complete; separate commit approval remains required.
