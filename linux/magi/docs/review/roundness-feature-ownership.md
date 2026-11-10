# Roundness settings by feature — accepted review

2026-11-10. Baseline `fa40a70a6e38a6faaaf145ff141c851ea4e31bb4` (accepted Appearance).
The operator reconsidered the all-in-Appearance UI after native product review.
The prior [Option A evidence](roundness-centralization.md), original
[inventory](roundness-controls.csv) and [consumer map](roundness-consumers.md)
remain historical evidence; they are not instructions to deploy the old editor.

The eight Option A UI files were found deployed. Its guarded `--rollback` restored
production source without writing Settings or owner receipts. HEAD/origin are
`fa40a70`, divergence 0/0, clean tree and empty index. Work continues in the same
uncommitted `/tmp/magi-roundness-centralization-ll_scbly`, with the former candidate
paths copied into the original audit's `option-a-source/` evidence folder first.
No commit or push. No new Git worktree and no use of the older Appearance checkout.

## Ownership and unchanged values

**9 multiplier sliders + 1 pixel stepper; 12 persisted numeric fields; zero duplicate
numeric editors.** Two fields have no numeric editor: compatibility base (`master`)
and the retained Workspace override, currently inherited. Three nonnumeric shape
selectors stay unchanged: Hub switch style and Lock Screen avatar/credential styles.

| Owner / control | Persisted field | Stored before | Stored after | Effective current |
| --- | --- | --- | --- | --- |
| Hidden compatibility base | `appearance.roundness.master` | 1 | 1 | 1× |
| Appearance / Roundness | `appearance.roundness.roles.surface` | null | null | 1× |
| Hub / Selector roundness | `appearance.roundness.roles.hubSelector` | 0.4 | 0.4 | 0.4× |
| Bar / Bar roundness | `appearance.roundness.roles.barPill` | 1 | 1 | 1× |
| Hidden Workspace override | `bar.visual.workspacePills.roundness` | null | null | Bar: 1× |
| CC / Primary controls | `appearance.roundness.roles.controlTile` | 1.25 | 1.25 | 1.25× |
| CC / Secondary controls | `appearance.roundness.roles.secondaryControl` | 1.2000000000000002 | 1.2000000000000002 | 1.20× |
| CC / Sliders | `appearance.roundness.roles.slider` | 1.2000000000000002 | 1.2000000000000002 | 1.20× |
| CC / Media artwork | `appearance.roundness.roles.albumArt` | 1.2000000000000002 | 1.2000000000000002 | 1.20× |
| CC / Avatar / identity | `appearance.roundness.roles.avatar` | 1.2000000000000002 | 1.2000000000000002 | 1.20× |
| CC / Shared buttons & switches · review | `appearance.roundness.roles.action` | 1.2000000000000002 | 1.2000000000000002 | 1.20× |
| Launcher / Header image corners | `launcher.headerRadius` | absent | absent | default 12px |

Values above compare the fresh post-rollback snapshot with the revised source/test
phase, not the obsolete Option A Settings snapshot. Current values will be captured
again at native-helper invocation. All fields/defaults/ranges/units remain intact:
master default 1; nine role overrides and workspace default null; multipliers 0–2,
step 0.05; Launcher header default 12px, range 0–75, step 1. Schema **22**, no migration.

Appearance has exactly one numeric roundness editor. Its heading is **Roundness**
and description is exactly **Cards, Menus, Notifications & Pop Ups.** It edits
surface, not master. Hub selector stays beside its appearance controls, with
“Shapes the mode selector.” Bar has one editor in Appearance mode. Control Centre
has one Roundness card with Controls, Artwork & identity and temporary shared-controls
disclosures. The independent slider role is retained there rather than silently
removing an audited field omitted from the suggested four-control grouping.
Launcher owns its pixel stepper beside header-image controls, with a half-size
corner sample. No new sidebar page or expensive duplicate live shell.

The central specialist groups and global slider are gone from Appearance. The old
Bar/CC shared-surface editor copies remain removed; component surfaces still consume
the same surface field. Existing broad Reset Appearance/Bar/Hub/CC/Launcher actions
retain their former scope. Profile/notifications/clipboard shared-surface links and
all border/style controls remain intact.

## Explicit inheritance

Every visible nullable editor uses SettingsToggle; no large Follow action button.
The true parent for every visible role is the saved compatibility base, so the
label is **Use saved base value**. It would be incorrect to say “Use Shell surface”
or “Use Primary controls”: those are separate fields and no such inheritance exists.
The checked toggle disables its slider and shows the effective multiplier. Unchecked
means Custom override; keyboard/automatic save and the same setters remain in use.

| Nullable field(s) | Parent / null meaning | Checking inheritance | Unchecking |
| --- | --- | --- | --- |
| surface, hubSelector, barPill, controlTile, secondaryControl, slider, albumArt, avatar, action | `appearance.roundness.master`; effective multiplier is role number when present, otherwise master | Store null; discard the custom number, as before | Store the current parent multiplier; no old custom number is restored |
| workspace | `barPill` (then master if barPill null); effective painted radius follows Theme.barPillRadius | Already null and retained; no separate Workspace editor in the unified model | Not exposed; independent Workspace overrides require separate review |

There is no hidden custom-value cache or new schema field. Opening pages, expanding
cards or loading inherited values never writes Settings. Master/header are nonnullable;
header absence still resolves to 12px without materializing the field. Global is
removed only from the UI; compatibility APIs and broad reset behavior remain.

## Hidden base consumer audit

The base is **not unused**. Current surface=null makes it an active fallback today.
After redistribution the complete direct source-read/write classification is:

| Source | Classification | Relationship |
| --- | --- | --- |
| `theme/Theme.qml:radius` | Fallback-only direct read; consumers inherit through role fields | Any null/undefined role uses `roundness.master`; then reference scaling and half-size clamps. Surface currently exercises this path |
| `components/settings/RoundnessValue.qml` | Direct UI effective-value/override-seeding read | Displays the base for null roles; unchecking inheritance copies its current value, not a new derivation |
| `components/settings/pages/LockScreenPage.qml:avatarRadius` | Fallback-only via avatar | Lock previews use avatar override, else master, then existing 12px reference and 48px cap |
| `native/lock/src/visual_data.cpp` | Fallback-only via avatar | Native avatar-radius publication feeds LockTokens/LockProfile and the native alpha mask |
| `settings/SettingsSchema.js` | Compatibility definition/validation, not a painted consumer | Retains default/range/invalid-value handling |
| `settings/SettingsStore.qml:setRoundness` | Compatibility writer | Supports master writes; no numeric Settings editor invokes it for master |
| `services/Settings.qml` IPC `roundness(role, value)` | Existing IPC writer | Explicit master/default commands remain supported; no numeric Settings master editor |
| `tests/*` and historical review fixtures | Test-only | Exercise fallback behavior, min/current/max and schema compatibility |

Theme.radiusSmall(action), radiusMedium(surface), RenderTokens surface/control/slider
exports and painted consumers inherit through their role fields. Workspace null
inherits through barPill. Native avatar consumers inherit through avatar. The unused
Theme.radiusLarge export remains an unused internal token; it does not make master
dead. Generated application-theme adapters do not read the base. No token, schema
field, default, migration or runtime fallback is deleted or reassigned.

## Unified Bar semantics — case A

Stored Status=1; stored Workspace=null. Effective multipliers are both 1× and both
painted pill radii are 8px (existing maximum clamp 14px). Therefore **case A applies**:
keep Workspace null and expose only the Status/barPill editor. There is no numeric→null
normalization, Settings semantic change or pixel change. Min/current/max of barPill
move active/inactive workspace and status contours together. Shared/expanded surfaces
retain their surface-radius interpolation and connected joins.

No arbitrary custom Workspace value is overwritten. The unified editor is disabled
if an independent Workspace override exists, with a short explanation. The review
helper stops before deployment if Workspace is no longer null, printing stored and
effective values. Equal explicit values would require a separately reviewed case-B
normalization; differing values require operator direction (case C). Neither path
is automatically implemented for this operator's inherited configuration.

Tests cover 720/1200px Bar widths, 0/1/2 multipliers, active workspace changes, expanded
status opening/closing, and retained null. Existing synthetic fleet/routing checks
pass. Native physical output coverage remains a separate hardware limitation.

## Shared Buttons and switches audit

The [focused report and complete direct consumer map](buttons-switches-roundness.md)
finds 45 direct binding/alias sites in 34 files, plus the generic editor preview
(46 sites in 35 files). This is shared across MAGI, not just CC.
It affects buttons, switch tracks/knobs, inputs/steppers/selectors, some result/cards,
tray hover and Bar popup controls; native lock avatar/credentials and Primary/
Secondary contours are independent. Switches/chips often saturate at multiplier 1,
explaining why current 1.2 and maximum 2 can look identical there.

Classification is **INVESTIGATE FURTHER** for permanent editor placement; preserve
it temporarily under CC as explicitly requested. Its label/description says shared
across MAGI. No merge/remove decision is made before operator review. Focused real
component min/current/max captures in both palettes accompany this report.

## Geometry and validation

The revised comparison extracts the accepted `fa40a70` source via Git archive and
runs the identical fixture against it and this candidate. **417 runtime/schema/native
files remain byte-identical** outside the ten editor files. **28/28 before/after
pairs are pixel-identical** in Nord/One Light: existing 24 consumer pairs plus four
collapsed/expanded connected-surface pairs. No rendering-only pixel differences
were observed. These deterministic software captures are not native GPU mask proof.

Unchanged contracts include native avatar publication/LockProfile/alpha-mask linkage,
plain/frame treatments, media crop/border/inner-mask/perimeter agreement, parent/child
clamps, Bar joins, output routing, and Launcher header pixel radius. No renderer,
mask, theme definition, asset importer, authentication or monitor/GPU code changed.

QtTest exercises 30 page/width/palette combinations, exact ownership, no global editor,
no duplicate numeric editors, checked inheritance/disabled sliders, keyboard Tab/
Backtab/arrow/stepper controls, null reset and override seeding, completed disk
save/reload, absent header semantics and zero passive-visit writes. All interaction
values are restored in private documents. The three shape selectors remain local.

Targeted: **14 PASS, 0 FAIL, 0 UNKNOWN**. Full matrix: **109 PASS, 4 ENVIRONMENT,
0 FAIL, 0 UNKNOWN, 0 SKIPPED**, 113 commands. The four established environment
limits are private D-Bus Bluetooth/notifications, clipboard PNG transport and native
lock SOCK_SEQPACKET/private-bus denial. Native clean build and exact audited source
comparison pass; denied native cases are not claimed as passes.
`git diff --check` passes. New native helper self-test passes. The operator subsequently
confirmed acceptance of the revised UI and authorized the focused commit. All ten
deployed source hashes match the reviewed candidate. The deployment receipt remained
incomplete and no six-case native result was saved: acceptance is operator-reported,
not a claimed completed helper sequence. Prior Option A review is separate evidence.

## Native gate, state and proposed commit

Fresh helper: `/tmp/magi-roundness-feature-review.py`; rollback via `--rollback`.
It snapshots **current** Settings/protected state at invocation, records intervening
history changes without restoring stale state, checks the Bar precondition, exact
candidate hashes, synchronized main and empty index, and deploys ten UI files
reversibly through the existing watcher. No restart or Hyprland edits. Private
Nord/One Light compact/normal/wide review windows permit safe adjustment; Ctrl+R
reloads and Ctrl+Shift+R restores the private starting values. Application activation
is disabled there. The final live review is passive and includes native lock avatar
via the operator's normal lock action. The helper never locks the session itself.

Evidence is under the original audit's `feature-ownership/` folder: fresh exact
Settings and 12-field snapshots, protected manifest, focused impact captures,
responsive captures, pixel pairs, test logs, helper and rollback data. Before native
deployment all 701 protected entries and Settings matched the post-rollback snapshot.
At commit preparation the ten intended UI files are deployed; all twelve roundness
values still match. Only recent-emoji history has changed in Settings. The current
Settings bytes and 701-entry manifest are freshly snapshotted and preserved, without
restoring old history. Settings remain ignored/untracked. Owner-written receipts are
never overwritten. Push is not authorized.

The operator accepted the revised UI and approved one commit:
`magi: organize roundness settings by feature`. Exact allocation follows; runtime
Settings, helper/evidence/captures/rollback snapshots are excluded.

<!-- PATH_ALLOCATION -->

```text
linux/magi/.config/quickshell/magi/components/settings/BarInspector.qml
linux/magi/.config/quickshell/magi/components/settings/CCInspector.qml
linux/magi/.config/quickshell/magi/components/settings/RoundnessPicker.qml
linux/magi/.config/quickshell/magi/components/settings/RoundnessValue.qml
linux/magi/.config/quickshell/magi/components/settings/pages/AppearancePage.qml
linux/magi/.config/quickshell/magi/components/settings/pages/BarPage.qml
linux/magi/.config/quickshell/magi/components/settings/pages/ControlCentrePage.qml
linux/magi/.config/quickshell/magi/components/settings/pages/HubPage.qml
linux/magi/.config/quickshell/magi/components/settings/pages/LauncherPage.qml
linux/magi/.config/quickshell/magi/components/settings/qmldir
linux/magi/docs/README.md
linux/magi/docs/architecture.md
linux/magi/docs/architecture/current-system.md
linux/magi/docs/current-roadmap.md
linux/magi/docs/decisions.md
linux/magi/docs/generated-state.md
linux/magi/docs/quickshell-reference.md
linux/magi/docs/review/appearance-roundness.md
linux/magi/docs/review/buttons-switches-roundness.md
linux/magi/docs/review/roundness-centralization.md
linux/magi/docs/review/roundness-feature-ownership.md
linux/magi/docs/technical-debt.md
linux/magi/docs/testing.md
linux/magi/tests/appearance/appearance.qml
linux/magi/tests/appearance/native-roundness.qml
linux/magi/tests/appearance/roundness-audit.py
linux/magi/tests/appearance/roundness-equivalence.py
linux/magi/tests/appearance/roundness.qml
linux/magi/tests/appearance/run.py
linux/magi/tests/phase12f/presentation.qml
linux/magi/tests/run-all.py
linux/magi/tests/runtime-visual/roundness-features.qml
linux/magi/tests/runtime-visual/roundness.qml
linux/magi/tests/runtime-visual/run.py
```
