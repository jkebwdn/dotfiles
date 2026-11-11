# Control Centre Settings pass 2 and the default roundness model

Accepted work based on synchronized `93ef0da1b29908e4908bb9923b26772835d9872b`,
2026-11-11. The operator approved this methodology, not a third refinement pass.
Native acceptance and final title-aligned preview were operator-confirmed; commits
and normal push authorized on 2026-11-11. No schema migration.
The prior [feature-ownership review](roundness-feature-ownership.md) and
[shared-controls audit](buttons-switches-roundness.md) remain historical evidence.

## Default and feature ownership

Appearance → Roundness is the one default MAGI UI editor. It writes the existing
`appearance.roundness.roles.surface`, with the description **Default roundness for
MAGI controls and shared UI.** Null still resolves to `appearance.roundness.master`.
Reset still writes null; opening a page never creates an override. There is no
Appearance inheritance checkbox or second shared-controls editor.

The old `appearance.roundness.roles.action` remains accepted by schema 22 and its
unchanged migrations/defaults (nullable, default null, historical range 0–2,
step .05). There is no production QML consumer or normal editor. Historical
migrations that copied action into albumArt/secondaryControl are intentionally
retained: old documents must still migrate with their historical meaning. Master
also remains hidden, but continues as the actual fallback for nullable roles,
including native avatar geometry. No existing null or stored number is rewritten.

| Editor owner | Persisted field | Runtime ownership |
| --- | --- | --- |
| Appearance → Roundness | `appearance.roundness.roles.surface` | Shared surfaces/cards and generic buttons, inputs, switches, results, popup/menu controls, hover/focus and generic ValueSlider |
| Bar → Roundness | `appearance.roundness.roles.barPill` | Status pills, connected joins; current `bar.visual.workspacePills.roundness=null` inherits this field |
| Hub → Selector roundness | `appearance.roundness.roles.hubSelector` | Mode-selector contour only |
| CC → Controls → Primary | `appearance.roundness.roles.controlTile` | Tiles and existing profile/media container backgrounds |
| CC → Controls → Secondary | `appearance.roundness.roles.secondaryControl` | Secondary action contours and glyph treatment |
| CC → Controls → Sliders | `appearance.roundness.roles.slider` | IconSlider track/fill geometry, through RenderTokens.sliderRadius |
| CC → Artwork & identity → Media artwork | `appearance.roundness.roles.albumArt` | Artwork crop, border, progress perimeter and masks |
| CC → Artwork & identity → Avatar / identity | `appearance.roundness.roles.avatar` | Profile/CC and native-lock avatar/mask linkage |
| Launcher → Header image corners | `launcher.headerRadius` | Pixel-valued header clipping, 0–75 step 1; absent → 12px |

Eight multiplier sliders (0–2, step .05) plus one pixel stepper; twelve numeric fields retained.
Zero duplicate editors. The three shape-style selectors stay with their features.
Feature-role nulls retain their original master fallback, not a new surface
inheritance. The visible “Use base roundness (value×)” labels report that real
compatibility parent; disabling inheritance seeds that parent, checking discards
the custom number, and no prior-number cache is introduced. Workspace retains its
separate Bar parent. Feature resets retain their existing writers and scope.

## Complete generic consumer migration

[Source-level consumer map](roundness-default-consumers.csv) records 47 baseline
binding/alias sites in 35 files, including the Theme.radiusSmall export and its
consumers. These are source sites, not new preferences. All old action callers
now request surface with the **same reference radius and geometry clamp**.
Theme.radiusSmall now derives surface too. Existing surface consumers already use
the correct owner. Generic ValueSlider track/knob move from slider to surface;
CC IconSlider remains slider-specific. No fixed implementation-radius sweep.

Token flow: saved surface or compatibility master → Theme.radius(surface,
reference, width, height) → existing half-size clamp → generic contour. The same
field feeds RenderTokens.outerRadius and radiusMedium/Large. Distinct reference
radii remain appropriate to nested controls; one multiplier does not make all
pixel radii equal. Native lock code, RenderTokens feature geometry, SectionLayout,
Bar joins, artwork masks and Launcher header clipping remain unchanged.

## Saved values and visual impact

Invocation audit snapshot, retained exactly (not a normalization request):

| Numeric field suffix | Stored value | Resolved before |
| --- | --- | --- |
| `appearance.roundness.master` | 1 | 1× |
| `roles.surface` | null | 1× |
| `roles.action` | 1.2000000000000002 | 1.20×; now compatibility-only |
| `roles.barPill` | null | 1× |
| `bar.visual.workspacePills.roundness` | null | Bar 1× |
| `roles.hubSelector` | 0.4 | .40× |
| `roles.controlTile` | 1.2000000000000002 | 1.20× |
| `roles.secondaryControl` | 1.2000000000000002 | 1.20× |
| `roles.slider` | 1.2000000000000002 | 1.20× |
| `roles.albumArt` | 1.2000000000000002 | 1.20× |
| `roles.avatar` | 1.2000000000000002 | 1.20× |
| `launcher.headerRadius` | absent | 12px |

Generic controls intentionally change from 1.20× to 1.00×. For example, an 8px
Settings button/input reference becomes 8px rather than 9.6px; Hub search becomes
10px rather than 12px; a 12px result card becomes 12px rather than 14.4px.
Already-saturated pill/switch/ValueSlider geometry can be pixel-identical at these
values. Surface cards themselves were already 1×. This is an approved change in
ownership, not universal visual equivalence.

The committed test harness compares identical private inputs against `93ef0da`:
46 Nord/One Light image pairs, 36 identical and 10 intentionally different (the
button/input/search/result samples and their composite in each palette). All
feature-specific comparison pairs remain identical, including CC, joined Bar,
workspace/status, Hub selector, artwork/avatar, lock presentation and Launcher.
Native lock source and the avatar reader/mask linkage remain byte-identical;
software images do not substitute for a native lock-session acceptance test.
Appearance min/current/max tests also hold all feature tokens fixed and vary the
retired action field to prove it has no active effect.

## Fixed preview and scrolling ownership

SettingsContent still retains one page Loader. ControlCentrePage is now an Item,
not a SettingsPage Flickable. Its fixed title/editor host owns sibling preview and
inspector columns. Only `ccInspectorScroll` owns vertical content scrolling.
Normal/wide use side-by-side when the editor has at least 680px; compact keeps the
preview above the independently scrolling inspector. No preview-y/contentY trick.

Selection is still EditorSelection view-local state. Simple clicks/keyboard
selection reveal the contextual card if necessary after Available controls;
revealing waits until pointer drags finish so it cannot displace a grabbed palette
item. Empty clicks clear selection without forcing the inspector to the top.
A common non-scrolling drag viewport supplies coordinates; a separate
scrollViewport supplies edge scrolling and keyboard reveal. Palette delegates are
visually parented into clipped inspector content; stable Repeater wrappers retain
ownership, and moving delegates return to the common drag layer. Drop bounds are
intersected with the visible inspector, so scrolled-away cards cannot intercept
unrelated controls. Existing Settings.placeCCModule/placeCCSection remain the only
composition writers. The live Control Centre never becomes editable.

Panel fit uses SectionLayout's panel width/height, never decoration union width.
Native-size cap is 1× at normal width; wide preview columns (at least 500px) can
reach 1.25×. Page gutter is 12px, column gap 12px. Decoration still uses the real
ControlCentreDecoration renderer, alpha union and existing compact-fit fallback:
only artwork shrinks/hides when space is insufficient, preserving all frame
content instead of cropping it. Disabled artwork leaves a centered panel with no
reserved artwork width. Runtime decoration source, sizing, timing and storage are
unchanged. Narrow preview art may be smaller than runtime art; panel geometry is
still accurately scaled, and this limitation is visible during native review.

The saved operator panel is 304×424 logical pixels. At 1000×760 Settings it was
168.18×234.57 painted pixels before, and is now 304×424. At 1400×900 it was
210.89×294.13 and now reaches 380×530. Compact at 720×600 uses a 204.34×285 persistent top preview (previously
235.14×327.96 inside the page scroller), leaving the lower inspector usable. The previous compact preview scrolled away entirely.

## Settings heading standard

Page title: 26px bold; card title: 16px bold; subheading: 15px demi-bold; row label:
14px; help: 12px semantic subdued text. `SettingsSubheading` is a shared semantic
component with optional help/disclosure, an Accessible.Heading label and a separate
keyboard-focusable disclosure button. Title/help remain visible; only options
collapse. Focus is outlined. It is used for CC Controls and Artwork & identity;
other pages are not mass-migrated. There is no generic Buttons and switches group.

## Validation and review

New fit coverage uses private PNG fixtures, wide/tall/disabled artwork, all six
width/palette combinations, fixed preview while scrolled and panel-scale invariance.
Workflow coverage retains real Qt pointer/keyboard reorder, add/remove, selection,
no passive Settings writes, correct palette clipping, and save/reload. Existing
0/2/4/6-primary and narrow-output parity fixtures remain in settings/refinement.
Schema/defaults/migrations are compared byte-for-byte with production.

Evidence root: `$STATE/magi/audits/controlcentre-settings-pass2-z1n5prn0/`:
`equivalence/`, `roundness-impact/`, `fit-before/`, `fit-after-final/`, workflow
captures, full regression, protected manifests and native-review helper/receipts.
Qt software captures omit some semantic-icon/MultiEffect shader pixels; geometry,
source ownership and alpha fixtures are independently checked. Native review is
pending. It must check real icons/alpha, sticky layout, private edits, primary vs
individual selection, drag/reorder/add/remove, then restore private values.
The helper takes fresh invocation snapshots and never writes live settings.json.
No actual Suspend event is part of review. Preserve the operator's current
Suspend-enabled/Hibernate-disabled choice and all unrelated histories.

Planned commits, only after review: shared roundness default, then CC Settings
layout. Exact per-path/hunk allocation and final regression/protected results are
saved with the review receipt. No commit, push or Pass 3 is authorized here.

## Offline closeout before native review

Canonical full run: **112 PASS, 4 ENVIRONMENT, 0 FAIL, 0 UNKNOWN** (116 suites).
The environment cases are the established Bluetooth bus, clipboard model,
notification bus and native-lock sandbox restrictions. The initial diagnostic run
found three obsolete page-scroller/disclosure assertions; their corrected targeted
checks and the final full run pass. No failure was relabelled as environment.
After the final empty-viewport deselection addition, four affected reorder/workflow,
fit and composition suites also pass. Updated audit/comparison reporting checks
pass separately. `git diff --check` passes. Six rollback guard scenarios pass;
the six private preview launches are self-tests, **not native acceptance**.

Production remains synchronized and clean at `93ef0da`; the candidate is uncommitted
in `/tmp/magi-controlcentre-settings-pass2-ggclol9d`, index empty. Live settings.json
is ignored/untracked, exact bytes and all 701 protected entries unchanged. The
reversible native helper uses a fresh invocation snapshot, and its `--rollback`
restores only reviewed source, preserving newer Settings/history. Native review is
still pending. Exact allocations are in the audit's `commit-allocation.md/json`
and two patches, validated to reconstruct the full candidate without staging.

## Native review follow-up — 11 November 2026

The operator accepted the Pass 2 review, requesting only a smaller left preview
gutter. The preview column now uses 12 logical pixels of the existing outer
gutter, bringing the panel closer to the sidebar. Panel scale, inspector width,
scroll ownership and runtime geometry are unchanged. The existing workflow test
checks selection, drag/reorder and responsive layouts with this placement.
This is a source-only refinement; saved values and schema are unchanged.
No commit or push is authorized by this visual acceptance.

The subsequent alignment review supersedes the 12px offset: the panel itself now
starts at the same x coordinate as the page title. The preview column retains its
normal page inset; unused width is no longer placed before the panel. Scale and
inspector position are unchanged. Decoration still obeys the existing insufficient-
left-space fallback; runtime decoration geometry is untouched.

## Final operator acceptance and authorization

The operator accepted the final title-aligned preview in conversation, then
authorized the two commits and normal push. The still-open private review helper
has no completed six-case receipt; acceptance is operator-reported, not inferred
from automated captures. The final responsive workflow check also passed with an
explicit panel/title alignment assertion. Existing full regression remains
112 PASS, 4 ENVIRONMENT, 0 FAIL, 0 UNKNOWN.

During review the operator changed `appearance.roundness.roles.surface`. Preserve
its latest live value, not the earlier audit snapshot. No code in this phase wrote
that live value. All other protected state was unchanged at acceptance. The
earlier pending-gate and 12px-offset notes above are chronological evidence.
