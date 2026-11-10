# Appearance simplification and roundness review

Review candidate, 2026-11-10. **Native Appearance acceptance passed; three components remain reversibly deployed. Awaiting commit approval; no roundness centralization.**
Production baseline: `eb19df4d0f5d9a15d042a4aa7acb826764976277` on synchronized
`main`. Initial five-commit log, equality with `origin/main`, divergence `0 0`,
clean working tree, empty index and worktree list were verified before editing.
Schema remains **22**. The previous focus/picker/cards push is complete.

Candidate: `/tmp/magi-appearance-roundness-xr5xnbb8`.
Private evidence: `$STATE/magi/audits/appearance-roundness-t2utt7bf/`.
Open `review.html` there for the complete visual gallery and wide inventory table.
The previous `/tmp/magi-focus-picker-settings-irfbn17q` worktree remains retained:
the host process-reference check could not read `/proc/1395/cwd`. A sandbox process
list does not resolve that host safety check. This phase creates one new worktree.

## Appearance implementation

Only three production components change:

- `ThemeGallery.qml` retains the registry, SettingsChoiceCard, selected highlight,
  palette previews, full gallery groups, filters and arrow/Tab navigation. Collapsed
  capacity is `clamp(floor((bodyWidth + 12) / 188), 2, 5)`. Actual Settings windows
  at 720, 1000 and 1400 logical pixels show **2, 3 and 5** cards respectively;
  intermediate body widths show four. The active theme is included, other cards
  come from registry order, and cards remain in registry order. The preview subset
  stays stable while choosing another already-visible card, preserving focus.
  Resizing or selecting a theme outside the subset rebuilds it deterministically.
  “Show all themes” follows the cards. Expansion focuses/reveals the first filter;
  collapse reveals the footer button. Selected accessibility metadata remains.
- `RoundnessPicker.qml` removes Sharp/Balanced/Rounded preset choices. The primary
  slider remains 0–2 in 0.05 steps, with an immediate rounded numeric preview and
  the existing Settings setter. Wider roundness controls are unchanged.
- `AppearancePage.qml` puts installation below the icon-pack cards and removes
  duplicate current-theme/success prose, Review applications and healthy counts.
  The existing icon installation dialog, validator and import owner are unchanged.
  Each application row has a 24px icon column, a name/disclosure button with the
  chevron next to its text, an optional attention mark and a separate right toggle.
  Long names elide. The toggle has no visible label but retains “Follow MAGI for
  <application>” accessibility text. Disclosure has its own label and focus outline.
  The existing LauncherIcons resolver supplies application artwork without semantic
  recolouring; its usual letter fallback applies when artwork is unavailable.

Healthy collapsed application rows show no Live, reload, next-launch, generated,
ready or enabled labels. Their real status/result, exposed integration/compatibility/
activation/configuration data, error diagnostic and existing actions are inside the
expanded row. Zen profile/workspace-colour explanation and btop result copy are
there too. Missing dependencies, unconfigured/unavailable targets and actual
activation/publication failures retain an attention mark/count and expanded details.
Busy/error feedback is retained. Enrollment confirmation still opens the relevant
row; disclosure does not toggle enrollment. No adapter data, ownership or activation
logic changed. The shared SettingsSection card system and navigation remain intact.
The retained window's global save indicator is unchanged; routine success prose
beneath the selected theme is removed.

## Complete inventory and counting method

[Full inventory, all required columns](roundness-controls.csv) contains one row per
logical user-facing binding, plus separate style selectors. [Consumer map](roundness-consumers.md)
links direct runtime bindings and traces their propagation, masks and border geometry.
The private JSON includes broad source/search evidence, schema-normalized snapshot
values, defaults, literal sites, conditional sites and per-role consumers.

Counts use canonical editor bindings, not every output, preview, repeated module
selection or rendered instance. Bar status/workspace editors share one QML template
but edit different fields and therefore count separately. Wi-Fi/Bluetooth/Audio
all reuse the same menu inspector binding. The locked presentation symlink is
counted once at native source. Style selectors are separated from numeric radii. Existing “Default”/“Follow master”
reset actions are inheritance resets, not named roundness presets.

| Category | Baseline | Candidate |
| --- | ---: | ---: |
| User-facing roundness sliders | 13 | 13 |
| Pixel-valued radius number stepper | 1 | 1 |
| Numeric roundness preset groups / buttons | 1 / 3 | 0 / 0 |
| Persisted numeric roundness fields | 12 | 12 |
| Other shape-style fields / normal selectors / choices | 3 / 3 / 10 | 3 / 3 / 10 |
| Developer-gated designer aliases / choices | 2 / 9 | 2 / 9 |
| Exported derived radius tokens | 9 | 9 |
| Unused exported tokens (included above) | 1 | 1 |
| Fixed/internal radius definition sites | 48 | 48 |
| Dead/unreferenced persisted numeric fields | 0 | 0 |
| Fields edited on multiple pages | 1 | 1 |
| Editors for that field / redundant copies | 3 / 2 | 3 / 2 |

The 48 internal sites comprise 39 literal QML assignments/defaults, seven conditional
fixed/fallback branches and two native C++ defaults/branches. This counts definition
sites, not unique numeric literals, every coefficient in a formula, or preferences.
There are 190 runtime QML radius-bearing binding starts; 151 are derived/propagated
(including the seven conditional sites). Blur kernel sizes and SVG icon artwork are
not corner controls. Test-only radii, historical experiments and documentation are
categorized separately. A second unrestricted-extension `rg --hidden --no-ignore`
search also checked HTML, CSS-style names, manifests and historical TSV files; its
additional hits are documentation/registration, not extra runtime controls.
`Theme.radiusLarge` is the unused exported token; it is
not a dead saved field. No internal constants or tokens are removed in this phase.

### Numeric controls at a glance

All multiplier controls use 0–2, step 0.05. Null defaults inherit the global master;
workspace null inherits Bar pills first. Values shown here are the untouched
operator snapshot. The CSV retains exact floating-point storage, explicit nulls
and absent fields, not just these formatted effective values.

| # | Page / group | Field (abbreviated) | Current effective | Default | Main visible scope |
| --- | --- | --- | ---: | --- | --- |
| 1 | Appearance / Roundness | `appearance.roundness.master` | 1 | 1 | Inheriting shell roles/native avatar |
| 2 | Appearance / Shared shell roundness | `roles.surface` | 1 | null | Shared surfaces/cards/menus |
| 3 | Appearance / Shared shell roundness | `roles.action` | 1.20 | null | Buttons/toggles/inputs/small cards |
| 4 | Bar / Status pills | `roles.barPill` | 1 | null | Status/date/time/utility/tray contours |
| 5 | Bar / Workspace pills | `bar.visual.workspacePills.roundness` | 1 | null | Workspace container and active segment |
| 6 | Bar / Menu disclosure | `roles.surface` | 1 | null | Same shared field as #2/#12 |
| 7 | Control Centre / Profile Header | `roles.avatar` | 1.20 | null | Avatar crop; also profile/native lock |
| 8 | Control Centre / Media Player | `roles.albumArt` | 1.20 | null | Artwork crop/frame/progress perimeter |
| 9 | Control Centre / Primary controls | `roles.controlTile` | 1.25 | null | Tiles AND profile/media backgrounds |
| 10 | Control Centre / Secondary controls | `roles.secondaryControl` | 1.20 | null | Action buttons and inner glyph shape |
| 11 | Control Centre / Sliders | `roles.slider` | 1.20 | null | CC slider and ValueSlider geometry |
| 12 | Control Centre / Surface | `roles.surface` | 1 | null | Same shared field as #2/#6 |
| 13 | Hub / Selector appearance | `roles.hubSelector` | 0.40 | null | Hub selector outer contour |
| 14 | Launcher / Header image | `launcher.headerRadius` | 12px | 12px | Header image crop/frame; 0–75px, step 1 |

`roles.*` above means `appearance.roundness.roles.*`. The three additional shape
selectors (#15–17 in the CSV) are Lock Screen profile-picture treatment, credential
marks, and Hub switch appearance. Frame/dots/ring/pill styles affect more than a
numeric radius. They are not interchangeable global-roundness presets. The internal
Lock Designer offers extra avatar treatments and edits the same credential field;
those two aliases do not add persisted fields or normal-page sliders.

## Runtime relationships, overlap and geometry

The full linked map is authoritative for individual consumers; this summarizes
why controls cannot be merged from their names alone:

- Global is a multiplier, not a universal pixel radius. `Theme.radius` chooses a
  non-null role or master, multiplies a component-specific reference and clamps
  to non-negative half-width/half-height. Explicit overrides block master changes.
- Shared surface has genuine duplicate editors (#2/#6/#12), not three independent
  values. It also controls Hub, Settings, menus, notification/clipboard/emoji/launcher
  backgrounds and associated border/blur/input contours. Deleting duplicate UI is
  low risk; changing the field has a broad visual scope.
- Bar pills and workspaces are related through null inheritance but can differ.
  Connected Bar expansion forces lower corner joins square where needed. Shared
  status transitions interpolate pill and popup radius; inner focus outlines use
  inset radii. These joins must remain even if the number of preferences shrinks.
- Primary controls also style profile/media container backgrounds. Secondary
  controls use a 10px outer reference plus a 1px inner glyph treatment. Generic
  action uses different references and saturation. Their current equal multipliers
  do not prove identical output.
- CC sliders and ValueSlider tracks/handles consume the slider role. SettingsSlider
  itself uses fixed 2px track/7px knob geometry and an action-based focus contour.
  The name “Sliders” currently overstates its scope.
- RoundedArtwork bounds outer radius and frame width by half size, uses
  `max(0, outerRadius - frameWidth)` for its inner mask, and adjusts the progress
  perimeter by half the frame. Avatar and album-art controls therefore affect real
  image masking and border geometry, not just decorative outlines.
- Avatar affects CC/profile and the native lock bridge (12px reference, cap 48),
  while normal CC avatar uses a 10px reference. The square-frame lock treatment
  forces 4px in QML and native rendering. Native premultiplied-alpha masking and
  inset/scale mapping must remain synchronized. Credential style is presentation;
  authentication authority is untouched.
- Launcher header is already pixels, not a multiplier; its 150px height explains
  the 75px maximum. It cannot simply reuse a 0–2 value without an explicit mapping.
- Separate parent/card/button/artwork roles can make an inner radius larger than
  its parent. There is no universal cross-role constraint; padding often separates
  them. Do not add a global clamp. Existing artwork inner/outer matching and Bar
  join constraints must survive any future migration.

All 12 numeric fields have live consumers. Historical schema 10→11 (action to
albumArt) and 17→18 (action to secondaryControl) migrations explain separate defaults;
they are not dead fields. Generated application-theme adapters do not consume these
shell roundness preferences. No palette writer, adapter or native lock source changes.

## Visual-impact evidence

`review.html` provides **36 min/current/max images** across the 12 numeric fields
and **nine first/current/last style comparisons**. Duplicate controls #2/#6/#12 share
the surface comparison. Samples use production components, the captured operator
multipliers, native lock presentation QML and synthetic artwork in private XDG
homes. The header sample is 150px high like runtime. Master samples intentionally
retain explicit overrides: they demonstrate inheritance rather than silently nulling
all roles. Focused crops use QQuickItem.grabToImage (QtTest grabImage on a nested item
captured incorrect window coordinates in the initial draft). Secondary-control
comparisons show the focused outline because its normal background is transparent.
All twelve numeric triplets differ in rendered pixels. Avatar/global need a wider
scene. Software captures show artwork contour placeholders; shader image masking
is covered by bindings/geometry here, not claimed as native rendered-alpha proof.

Representative expected pixel radii (other consumers use their own base dimensions):

| Field / sample | Minimum | Current | Maximum |
| --- | ---: | ---: | ---: |
| Master / inheriting Settings card, 12px base | 0 | 12 | 24 |
| Surface / Settings card, 12px base | 0 | 12 | 24 |
| Bar pill, 28px high | 0 | 8 | 14 (clamped) |
| Workspace pill, 28px high | 0 | 8 | 14 (clamped) |
| Control tile, 10px base | 0 | 12.5 | 20 |
| Slider / CC, 10px base | 0 | 12 | 20 |
| Action / SettingsButton, 8px base | 0 | 9.6 | 16 |
| Avatar / CC, 10px base | 0 | 12 | 20 |
| Album art, 10px base | 0 | 12 | 20 |
| Hub selector, 44px high | 0 | 8.8 | 22 (clamped) |
| Secondary control, 10px base, 36px sample height | 0 | 12 | 18 (clamped) |
| Launcher header, 150px high | 0 | 12 | 75 |

These are isolated Qt software-rendered captures, **not native Hyprland acceptance**,
GPU/compositor blur proof, or a replacement for native lock-mask acceptance. The
isolated home often lacks application icon files and deliberately shows the existing
letter fallback; production resolution uses installed desktop artwork. Appearance
captures include Nord and One Light at compact/normal/wide sizes, collapsed apps,
a healthy expansion, a publication-failure expansion and the preset-free slider.

## Consolidation options — proposals only

| Option | Remaining numeric UI | Fields retained | Fields removed / derived | Migration / visual risk |
| --- | --- | --- | --- | --- |
| A — UI centralization only | **11 sliders + 1 pixel stepper** | All 12 | None; remove two redundant editor copies | No schema/migration; all current values and contours preserved |
| B — Global + necessary overrides | **8 sliders + 1 pixel stepper** | master, barPill, action, controlTile, slider, avatar, albumArt, hubSelector, headerRadius | surface from master; workspace from barPill; secondaryControl from action | Moderate; current snapshot happens to match these relationships, other saved overrides may not |
| C — Aggressive simplification | **2 sliders + 1 pixel stepper** | master, avatar, headerRadius | Remaining nine numeric fields derived | High; changes accepted .4 Hub and 1.2/1.25 control geometry; largest consistency gain and customization loss |

These are proposed product choices, not proof that B's eight sliders are universally
necessary. All options keep distinct shape-style choices and internal mask/join
formulas. UI counts exclude the pixel stepper from “sliders” explicitly.

**Recommendation: A first.** It removes duplicated controls and scattered discovery
without changing accepted visual output. B is a defensible later reduction after
comparing specialized silhouettes and reviewing other users' saved overrides. C
would substantially change this operator's current appearance.

Sparse Settings already represent inheritance: nullable/absent roles follow master,
workspace null follows Bar pills. A “Use global / Custom override” interface for
existing nullable roles needs no new field. Preserve explicit numbers and nulls
exactly; identical effective output today does not imply identical behavior after
future global changes. HeaderRadius has no existing nullable inheritance contract.

A needs no schema bump or migration. B/C can retain hidden legacy overrides to
preserve arbitrary old values, but then they have not really removed those fields.
True removal requires an explicit migration/conversion policy and schema review
(likely the next version), possibly opt-in inheritance. No universal reduction can
both discard distinct fields and preserve every old value exactly. Runtime complexity
is modest for shared multipliers but remains significant at connected Bar joins,
image masks/native lock and the pixel-valued header. No migration is written now.

Proposed A layout under **Appearance → Roundness**:

1. Global slider and compact preview.
2. Shell surfaces: shared surface, Hub selector.
3. Bar: status pills, workspace override (inherits Bar pills).
4. Controls: primary tiles, buttons/switches, secondary controls, sliders.
5. Artwork/avatar: profile/avatar, media artwork, Launcher header pixel stepper.

Specialized groups are collapsed/subordinate. Existing null reset/override behavior
is retained. Component pages would replace numeric editors with a read-only summary
and link here; they would not retain duplicate controls. Lock credential/avatar
styles and switch styles remain at their owning pages because they are categorical
presentation choices. **None of this layout or consolidation is implemented yet.**

## Validation and review gate

Affected checks passed: Settings/schema/appearance/assets/cards, primary precision
control, application presentation, real Theme Orchestrator pointer/enrollment flow,
Settings finish, gallery, roundness matrix and quality. Final gallery expansion,
long-name containment and 150px header refinements passed three focused suites at
`/tmp/magi-regression-cvu34l15`. The earlier 14-suite affected matrix is
`/tmp/magi-regression-5h6xdivi`.

The new appearance test exercises real mouse/keyboard events, selected accessibility,
2/3/5 columns, active-theme visibility/order, below-card buttons, full gallery focus,
icon-picker open/cancel, slider immediate preview/save/reload, all-row alignment,
independent toggles/disclosures, healthy/reload/next-launch/missing/activation/publication
fixtures, hidden Zen copy and restored isolated Settings. Existing real importer and
Theme Orchestrator tests continue covering installation/ownership/failure actions.

Final full-matrix and protected-state results are recorded below at completion.
No native deployment was requested for this review gate; visual operator acceptance
is pending. No screenshot is claimed as native acceptance.

## Proposed commit allocation

After operator review only: one focused `magi: simplify appearance settings` commit,
containing the three production components, their affected/new tests, canonical docs
and the inventory/consumer review. Exact candidate paths are retained in private
`candidate-paths.json` at completion. No consolidation source or migrations; no live
Settings, imported artwork, generated payload, private snapshots or PNG captures.
No staging, commit or push has occurred. Roundness consolidation requires a separate
operator choice and implementation review.

Exact proposed allowlist (all paths relative to `linux/magi`, nothing staged):

```text
.config/quickshell/magi/components/settings/RoundnessPicker.qml
.config/quickshell/magi/components/settings/ThemeGallery.qml
.config/quickshell/magi/components/settings/pages/AppearancePage.qml
docs/README.md
docs/architecture.md
docs/architecture/current-system.md
docs/current-roadmap.md
docs/decisions.md
docs/generated-state.md
docs/quickshell-reference.md
docs/review/appearance-roundness.md
docs/review/roundness-consumers.md
docs/review/roundness-controls.csv
docs/technical-debt.md
docs/testing.md
tests/appearance/appearance.qml
tests/appearance/roundness-audit.py
tests/appearance/run.py
tests/phase12f/presentation.qml
tests/phase12h/presentation.qml
tests/run-all.py
tests/runtime-visual/roundness.qml
tests/runtime-visual/run.py
tests/runtime-visual/settings-finish.qml
tests/runtime-visual/theme-gallery.qml
tests/theme-orchestrator/pointer.qml
```

## Pre-deployment verification (historical checkpoint)

Full canonical run `/tmp/magi-regression-lzqv44r2`: **106 PASS, 4 ENVIRONMENT,
0 FAIL, 0 UNKNOWN, 0 SKIPPED**, 110 commands. Logs and results are retained in the
private audit's `regression/` and `regression-result.json`. The four restrictions
remain the established private D-Bus / PNG-decoder transport / native socket limits;
no warning exemptions were broadened. The corrected roundness capture fixture ran
in the full matrix; its 45 capture exports also passed separately. Inventory CSV
label/null serialization was rechecked after its matrix entry; numeric counts and
production code are unchanged. New-file whitespace checks and `git diff --check`
pass. Frozen source/test hashes match the reviewed candidate.

Protected-state receipt: **701 entries unchanged**, live Settings byte-identical,
exact-ignored and untracked. This preserves theme/icon choices, every saved roundness
value, application toggles, emoji history, generated-theme state, wallpaper, Bar and
Control Centre artwork/layouts, application appearance, lock/fingerprint and monitor/
GPU configuration. No live deployment or restart occurred. Schema source is
unchanged at 22; no migrations.

Production main and candidate HEAD remain `eb19df4d0f5d9a15d042a4aa7acb826764976277`;
HEAD/origin divergence is **0 0**. Production working tree/index are clean. The
candidate has exactly the 26 source/test/doc paths listed above, with an empty
index. `review-state.json`, `candidate-paths.json` and source/capture hashes retain
the check results. No commit or push. Native/operator visual acceptance is pending;
stop here for Appearance review and the operator's roundness direction.

## Operator direction and reversible native deployment

The operator accepted Appearance in principle and authorized reversible live review.
At 13:34:15 on 2026-11-10, only RoundnessPicker.qml, ThemeGallery.qml and
AppearancePage.qml were atomically copied to persistent source after exact baseline
and reviewed-hash checks. The normal watcher logged Configuration Loaded at
13:34:15.532; no restart, Settings write or new QML warning accompanied that reload.
Rollback originals and guarded restoration are in the private audit. Main now has
exactly these three intended modifications; both indexes remain empty and HEADs
remain at `eb19df4`, divergence 0/0. Tests/docs remain in the candidate worktree.

Fresh deployment snapshot: 701 protected entries, three intended source changes,
698 identical, no unexpected changes; live Settings remain byte-identical. Use
`native-deployment.json` and `protected-before/after-native-deploy.json` for this
checkpoint rather than the earlier clean-main receipt. The 106 PASS / 4 ENVIRONMENT
full regression applies to the identical deployed source; schema remains 22.

Native six-case review is pending. Sandbox Hyprland socket/user-bus access is denied.
One private host review tool opens the real SettingsContent in native Wayland windows
at 720×600, 1000×760 and 1400×900 in Nord and One Light. It uses copied preferences
and private HOME/XDG stores, disables external application/clipboard actions in its
review copy and labels application statuses as fixtures. It records geometry,
captures and per-case operator feedback, then requests a check of the actual deployed
page without changing its saved theme. It checks current protected state before/after
and never restores a stale Settings snapshot. Its offscreen self-test passed; this
is not native acceptance. Review helper/captures are private evidence, not commit paths.

The operator selected **Option A only** for a separate phase after Appearance native
acceptance and commit. Retain all twelve numeric fields with no schema/migration;
centralize their UI under Appearance → Roundness, remove duplicate component editors,
and preserve every value, mask, artwork/border and Bar join relationship. Proposed
groups: Global, Shell surfaces, Bar, Controls, Artwork / Avatar, and a clearly separate
pixel-valued Launcher header group. Specialized groups may be disclosed. Keep the
three shape-style selectors unchanged. Options B/C are not authorized. No roundness
centralization is implemented or included in this Appearance commit.

After native acceptance, recheck Settings/protected state and report all six cases,
regression/schema and the exact existing 26-path allowlist. Stop for commit approval:
`magi: simplify appearance settings`.

## Native acceptance and current commit gate — 2026-11-10

The operator passed all six native cases and the actual deployed Appearance page:

| Window | Cards | Nord | One Light |
| --- | ---: | --- | --- |
| 720×600 | 2 | PASS | PASS |
| 1000×760 | 3 | PASS | PASS |
| 1400×900 | 5 | PASS | PASS |

Acceptance covers the selected/highlighted theme, cards and below-card actions,
primary slider without presets, quiet healthy rows, adjacent disclosure chevron,
right-aligned toggle and visible failure/attention details. The host receipt is
`native-captures/result.json` (`native: true`, `complete: true`, six pass answers,
`live_answer: pass`). Native captures/logs are retained beside it. Application status
rows in the six private windows are declared fixtures; the operator also accepted
normal deployed Settings in the unchanged saved theme.

Live Settings are byte-identical to the pre-deployment snapshot, still ignored and
untracked. All 701 entries stayed unchanged during the native review and still match
its start snapshot. A later comparison with the *earlier deployment baseline*
identified two owner-written receipt updates at 13:34:18, three seconds after the
13:34:15 shell reload: `theme-activation/status.json` and
`theme-orchestrator/state.json`. They update activation-generation receipts and the
GTK publication summary; generated payloads, active links, adapter ownership,
application configuration and Settings are unchanged. The existing shell startup
calls ThemeOrchestrator.activate(); its code is unchanged. The initial immediate
post-copy check preceded these asynchronous writes and must not be read as the
final settled-state result.

Final comparison against pre-deployment: **696 identical entries, three approved
source changes, two reload receipt changes, no other changes**. Do not restore older
receipt files. Exact prior bytes were identified by matching the deployment manifest
hashes to retained host-push snapshots, then compared structurally. Evidence:
`native-reload-receipt-diff.json`, `native-acceptance-verification.json` and
`protected-after-native-acceptance.json`.

Native logs retain the pre-existing Qt Wayland text-input disableSurface warnings.
The compact Nord private review also logged missing Bar/decoration assets when those
pages were visited: their private XDG asset directories were intentionally not copied.
These paths belong to the disposable preview, not production; real assets and their
Settings descriptors remain unchanged. Neither finding is silently suppressed or
claimed as an asset/native-lock acceptance test. The operator accepted Appearance.

The frozen runtime/test source hashes match the complete regression input:
**106 PASS / 4 ENVIRONMENT / 0 FAIL / 0 UNKNOWN / 0 SKIPPED**. Schema remains 22,
with no migration. Documentation-only acceptance updates require no runtime rerun.
Both indexes remain empty; main has exactly the three deployed source edits. The
candidate contains the same 26-path allowlist above. HEAD/origin divergence stays
0/0 at `eb19df4d0f5d9a15d042a4aa7acb826764976277`.

Ready for one commit, **only after explicit approval**:
`magi: simplify appearance settings`. No private evidence, live Settings, generated
receipts or artwork belong in staging. Option A remains reserved for a separate
phase after this commit; no centralization or B/C implementation is included.

## Subsequent product decision — feature ownership

The Appearance simplification was accepted, committed and synchronized at `fa40a70`.
A separate Option A candidate then proved geometry-preserving relocation, but native
product review reconsidered its UI ownership. Its review deployment was rolled back
without changing Settings. The [feature-owned revision](roundness-feature-ownership.md)
retains all twelve fields, hides only the base editor, uses explicit inheritance
switches and keeps specialized editors with their features. The original inventory,
A/B/C options and visual evidence above remain historical findings. No B/C field
merge/removal or schema migration is authorized by this revision.
