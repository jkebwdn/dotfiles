# Roundness Option A — historical central editor review

2026-11-10. Production baseline: `fa40a70a6e38a6faaaf145ff141c851ea4e31bb4`
(`magi: simplify appearance settings`). HEAD/origin were equal, divergence 0/0,
working tree clean and index empty before work. This phase uses only the new
`/tmp/magi-roundness-centralization-ll_scbly` worktree based on that commit.
Older Appearance/focus worktrees were not reused or removed.

**Superseded after native product review.** The operator requested feature ownership
instead of this centralized UI. Its eight source files were deployed for review,
then restored using the guarded rollback before the revised phase. Settings were
preserved exactly. No Option A commit/push occurred. See the
[replacement feature-owned candidate](roundness-feature-ownership.md).

The remaining text records the Option A preparation-time design, results and path
allocation. It is historical evidence, not current deployment/commit instructions;
the old helper must not be rerun.
Option A only: no field/default/schema/migration/renderer changes. Options B/C
are excluded. The historical [inventory](roundness-controls.csv) and
[consumer map](roundness-consumers.md) describe the pre-centralization layout.

## Central UI and exact fields

Appearance → Roundness keeps the existing global slider visible. Beneath it,
five collapsed SettingsSection groups use the accepted card/disclosure system
without nested identical cards: Shell surfaces, Bar, Controls, Artwork & identity,
Launcher. Descriptions explain shared ownership; lightweight radius samples/readouts
update immediately. The Launcher sample is half scale and explicitly uses pixels.

All multiplier sliders retain 0–2, step 0.05. Header remains 0–75 logical pixels,
step 1, presented as a SettingsNumber stepper. Nullable reset buttons still write
`null`; workspace follows Bar pills, all other specialized multipliers follow
Global. Constructing/opening these editors writes nothing. Global remains outside
disclosure, without numeric presets. Total: **11 sliders + 1 stepper**, one editor
per field; no duplicated shared-surface editor.

Stored before/after values below are identical after implementation and private
checks. `null` and absence are preserved, not expanded to effective defaults.

| Group / control | Persisted field | Before | After | Default |
| --- | --- | --- | --- | --- |
| Global | `appearance.roundness.master` | 1 | 1 | 1 |
| Shell surfaces / Shared shell surfaces | `appearance.roundness.roles.surface` | null | null | null |
| Shell surfaces / Hub selector | `appearance.roundness.roles.hubSelector` | 0.4 | 0.4 | null |
| Bar / Status pills | `appearance.roundness.roles.barPill` | 1 | 1 | null |
| Bar / Workspace pills | `bar.visual.workspacePills.roundness` | null | null | null |
| Controls / Primary controls | `appearance.roundness.roles.controlTile` | 1.25 | 1.25 | null |
| Controls / Secondary controls | `appearance.roundness.roles.secondaryControl` | 1.2000000000000002 | 1.2000000000000002 | null |
| Controls / Buttons and switches | `appearance.roundness.roles.action` | 1.2000000000000002 | 1.2000000000000002 | null |
| Controls / Sliders | `appearance.roundness.roles.slider` | 1.2000000000000002 | 1.2000000000000002 | null |
| Artwork & identity / Media artwork | `appearance.roundness.roles.albumArt` | 1.2000000000000002 | 1.2000000000000002 | null |
| Artwork & identity / Avatar / profile | `appearance.roundness.roles.avatar` | 1.2000000000000002 | 1.2000000000000002 | null |
| Launcher / Header corners (px) | `launcher.headerRadius` | absent (effective 12px) | absent (effective 12px) | 12px |

`RoundnessValue.qml` shares only editor plumbing, not geometry formulas or fields.
Existing Settings setters own save behavior. The pixel stepper retains its
existing `onValueModified` setter. Whole-feature resets (Appearance, Control
Centre, Hub, Launcher) retain their former scope; moving numeric editors does not
silently change those reset actions.

## Relocated editors and retained styles

- `AppearancePage.qml`: removes the old Advanced shell styling surface/action
  section; both fields now have their single central editor.
- `BarInspector.qml`: removes status/workspace numeric editors and their null
  reset buttons; removes the redundant shared-surface editor from menu styling.
- `CCInspector.qml`: removes avatar/artwork numeric editors and family numeric
  shape editor (surface, controlTile, secondaryControl, slider). This removes the
  second redundant shared-surface editor. Other appearance/layout controls remain.
- `HubPage.qml`: removes selector roundness editor/reset.
- `LauncherPage.qml`: removes only the header-radius number from the existing
  numeric row model; header border width remains local.
- Profile, Notifications and Clipboard had no separate numeric editor to move;
  their existing Appearance navigation remains. Quiet location notes appear only
  in the affected Bar/CC/Hub/Launcher editing contexts.

The three nonnumeric selectors remain in their original locations: Hub
`appearance.toggleStyle`; Lock Screen `lockScreen.effects.avatar` and
`lockScreen.effects.credential`. The developer-gated lock designer aliases remain
unchanged. No semantic shape selector was centralized.

## Runtime, masks and visual evidence

`appearance/roundness-equivalence` extracts production `fa40a70` via Git archive,
then runs the same fixture against baseline and candidate. It confirms **419
runtime/schema/native files byte-identical** outside the eight allowed UI files.
No old detached worktree supplies reference source. **24/24 image pairs are
pixel-identical**, with no intentional runtime redesign or observed pixel noise:

- Control Centre composition (profile, primary controls, sliders, media/actions);
- status and workspace pills;
- Settings card;
- buttons, switch, input and focused secondary control;
- Hub selector and Hub content surface;
- notification card;
- shared slider;
- Launcher header crop/frame;
- avatar, media artwork and native-sourced lock profile presentation.

Each is captured in Nord and One Light with the operator's twelve values supplied
read-only. Captures use deterministic fixtures and Qt software rendering; they
are not compositor screenshots and cannot establish native GPU alpha masks.
There are **zero Settings writes** during these comparisons, including the
private document. Original artwork/animation content is outside this geometry
fixture; live acceptance checks the existing operator assets separately.

The unchanged Theme/RenderTokens/RoundedArtwork code retains parent/child clamps,
inner mask radius subtraction, border and progress-perimeter agreement. The
avatar role still reaches `native/lock/src/visual_data.cpp` → LockTokens/LockProfile
and `presentation.cpp`'s native premultiplied-alpha mask; plain and frame treatments
remain distinct. No authentication code is modified or invoked by these tests.
Connected Bar join geometry and blur/input masks are unchanged; the existing
shared-status-surface and CC composition suites pass. Header stays an independent
pixel radius; it is never multiplied by Global.

The actual Settings UI is checked at 720×600, 1000×760 and 1400×900 in Nord and
One Light. Global and every group remain readable; controls fit without horizontal
scrolling. QtTest verifies disclosure, Tab/Backtab order, keyboard slider/stepper
adjustment, reset inheritance, immediate preview bindings, automatic save/reload,
unique editors and shape selectors. Test-only value changes are restored to the
original private bytes, including the absent headerRadius.

Evidence root: `$STATE/magi/audits/roundness-centralization-oj03ofrt`:
`captures/` (six overview and ten group captures), `equivalence/` (before/after
pairs + result.json), `inventory/`, `roundness-before.json`, `settings-before.json`,
`protected-before.json`, `targeted/` and `full/`. These generated/private files are
not commit candidates.

## Native gate and protected state

A guarded host helper is prepared at `/tmp/magi-roundness-native-review.py`.
Its default action checks synchronized main, exact reviewed candidate hashes,
clean index/tree and successful full regression, then snapshots current Settings
and protected state (recording any intervening operator/history changes);
then reversibly deploys only the eight UI files through the existing watcher.
It does not restart Quickshell or edit Hyprland. `--rollback` restores only those
source files, checking hashes first; it never restores Settings or activation
receipts. The full helper/rollback manifest remains in this phase's audit folder.

The helper presents six private Settings review windows and retains captures/logs.
Palette/min/max experiments use disposable HOME/XDG Settings; application-theme
activation actions are disabled. Ctrl+R reloads private values; Ctrl+Shift+R
restores the original private document after save completes. Asset copies retain
original bytes. Finally the operator checks the deployed live page and unchanged
Bar/Hub/CC/media/profile/header geometry without adjusting live values, and uses
their normal lock action for native avatar/profile review. No actual lock action
is triggered by the helper. Native acceptance remains pending until that report.

Before deployment: live Settings are byte-identical, ignored and untracked; all
701 protected entries remain unchanged. Production remains clean `fa40a70`,
divergence 0/0, empty index. Theme, icons, application toggles, assets, recent/history
state, all roundness values, generated payloads, monitor/GPU and authentication
state are preserved. Any owner-written receipt refresh caused by the existing
watcher will be reported separately after deployment, never overwritten.

## Regression and commit gate

Targeted: **16 PASS, 0 FAIL, 0 UNKNOWN, 0 ENVIRONMENT**.
Full 112-command regression: **108 PASS, 4 ENVIRONMENT, 0 FAIL, 0 UNKNOWN,
0 SKIPPED**. The established limits are private D-Bus (Bluetooth/notifications),
clipboard PNG transport and independently proven native Unix-socket/D-Bus denial.
Native sources match the audited baseline; no warning exemptions were added.
The final editor/census rerun is **2 PASS** after strengthening the test to wait
for completed disk reload; production code did not change during the full run.
Schema **22**, byte-identical schema/defaults/migrations. `git diff --check` passes.
Native helper self-test passes in a private offscreen home; this is not native
operator acceptance.

Proposed single commit after native acceptance and explicit approval:
`magi: centralize roundness settings`. No staging/commit/push yet.
Exact source/test/documentation allocation follows; ignored Settings, audit
snapshots/captures, deployment helper and rollback data are excluded.

<!-- PATH_ALLOCATION -->

```text
linux/magi/.config/quickshell/magi/components/settings/BarInspector.qml
linux/magi/.config/quickshell/magi/components/settings/CCInspector.qml
linux/magi/.config/quickshell/magi/components/settings/RoundnessPicker.qml
linux/magi/.config/quickshell/magi/components/settings/RoundnessValue.qml
linux/magi/.config/quickshell/magi/components/settings/pages/AppearancePage.qml
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
linux/magi/docs/review/roundness-centralization.md
linux/magi/docs/technical-debt.md
linux/magi/docs/testing.md
linux/magi/tests/appearance/native-roundness.qml
linux/magi/tests/appearance/roundness-audit.py
linux/magi/tests/appearance/roundness-equivalence.py
linux/magi/tests/appearance/roundness.qml
linux/magi/tests/appearance/run.py
linux/magi/tests/phase12f/presentation.qml
linux/magi/tests/run-all.py
linux/magi/tests/runtime-visual/roundness.qml
linux/magi/tests/runtime-visual/run.py
```
