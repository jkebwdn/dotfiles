# Testing MAGI

Run from `~/dotfiles`. Tests, source and fixtures are self-contained in this repository;
old home-directory development worktrees are not required. Schema 22 is current.

## Fast and affected-area checks

List the explicit offline matrix:

```sh
python3 linux/magi/tests/run-all.py --list
python3 linux/magi/tests/run-all.py --only settings/catalogue --only calendar/schema
python3 linux/magi/tests/run-all.py --only phase14b/run --only phase14a/fleet
```

Repeat `--only` for exact suite IDs. Run affected subsystem checks after a change,
then the complete matrix for phase closeout. Historical phase names identify
regression coverage, not frozen historical UI contracts. Preserve old-schema
migration inputs; current-output assertions use current defaults and the independent
`tests/settings/expected-current.cjs` expectation helper.

## Complete offline matrix

```sh
python3 linux/magi/tests/run-all.py
```

The explicit 116-command allowlist excludes live helpers. FAIL begins classified as UNKNOWN until evidence supports a narrower triage classification. Each existing harness owns
its fixtures. The runner uses offscreen software rendering, nonexistent compositor
and D-Bus endpoints, removes live display variables and capture overrides, and
records each command, exit, duration, log and classification in `results.json`.
`summary.json` is a compatibility copy. Use `--logs /tmp/magi-regression-<unique>`
to choose a **new** result directory. No logs are committed.

A harness success marker cannot override nonzero exit, assertions or Qt failure
markers. Launcher lifecycle has a 180-second allowance for its 127-second delayed
write. Other commands have a 600-second outer bound; individual harnesses may impose
shorter limits. A timeout terminates the process group. Exit 0 means all selected
commands pass; exit 1 means failure; exit 2 means only classified environment limits.
Filtered-out suites are not reported as passes.

## Native components and session acceptance

The default matrix includes `native_lock`: a clean temporary CMake/Cargo build,
all CTest cases and Rust tests. It never installs, acquires a lock or invokes real
PAM; its build root is removed automatically. Run just this entry with `--only native_lock`.
Its ENVIRONMENT classification requires the independently denied SOCK_SEQPACKET
probe, unchanged audited native source, exact known failed case sets and error
signatures; any discrepancy remains FAIL. Detailed internal counts stay in the log.
For lower-level commands, use
`native/lock/README.md` only for **offline builds/tests**, never interpret its
historical live-lock deployment instructions as authorization. Build outside the
repository; do not install/redeploy for a test-only change. Real lock/PAM tests
require a separate explicit operator gate.

Hardware/session acceptance remains distinct from offline fixtures: actual audio
routing, paired Bluetooth devices, authenticated pairing hardware, native tray
menus, physical displays and fingerprint devices. Never invoke live helper scripts
through discovery. A test/doc-only change does not require restarting production.

## Current environment limits

See [known environment limits](known-warnings.md). Never turn an unknown assertion
into an environment skip merely because it ran in a sandbox. The Phase 15
[reconciliation record](review/phase15-regression-reconciliation.md) documents
baseline reproduction and each corrected old assumption.


`theme-orchestrator/bootstrap` covers current static source fixtures independently
of the historical legacy enrollment fixtures. It asserts byte-identical source across
round trips, no-journal recognition, journal conversion/recovery, foreign-hook refusal,
and fresh/active/disabled parser or startup behavior. Native GTK theme selection and
full workstation/plugin behavior still require the operator smoke gate.

`runtime-visual/run:quality.qml` covers Phase 16 keyboard/focus rendering, Wi-Fi
accessible labels and notification idle/expiry lifecycle without a live notification bus.

`theme-orchestrator/visuals` covers optional CAVA/ascii-splash discovery, all 26
palette payloads, native parser/theme validation when installed, guarded launch
fallbacks and behavior/source preservation across enrollment round-trips.

`fetch/run` covers the read-only animated terminal fetch, deterministic geometry
snapshots and isolated PTY cleanup/input/resize behavior. It never enables startup.


`daily-polish/run`, `daily-polish/schema` and
`runtime-visual/run:daily-polish.qml` cover initial media progress and timer gating,
status role persistence/preview, connected Battery regions and production module
activation. Native limitations and optional preview generation are recorded in
[the candidate review](review/daily-use-polish.md).

## Accepted lock/fingerprint integration — 2026-10-30

The host offline candidate passes 23 CTest and 18 Rust checks, including an isolated
mock fprintd broker and power-intent confirmation. No actual sensor is used by these
checks. Native source hashes in native_lock.py bind sandbox exemptions to that exact
host audit; changed source cannot inherit it. Split Corners/Caps/error/biometric
geometry and production Settings controls are exercised in phase13a/presentation
and fingerprint/run. [Evidence and physical gates](review/lock-fingerprint-production.md).

Final lock validation: full 96-suite matrix plus focused final visual and audited
native reruns yields 92 PASS / 4 evidenced ENVIRONMENT / 0 unresolved FAIL or UNKNOWN.
The final installed source passes 23 host CTest and 18 Rust tests without skips.
Native pixel checks include actual 2× rendering and first-frame clock/date ink gap;
internal visual, fingerprint/password and suspend/resume acceptance are confirmed.
See [exact coverage and limits](review/lock-fingerprint-production.md).

`lock-themes/model` and `runtime-visual/run:lock-themes.qml` cover curated theme
metadata/migration, the normal gallery and responsive production presentation.
The Phase 13 designer fixtures continue exercising the preserved internal designer.
Native theme acceptance is separate; see [acceptance record](review/lock-screen-themes.md).


## Accepted Hyprland 0.57 compatibility

The [adapter audit and native acceptance gate](review/hyprland-057.md) records the bounded
0.56–0.57 Lua border API policy, verified runtime readback, generated-state status
and unchanged XDG/bootstrap ownership. Native host acceptance passed with exact border readback and Nord restoration;
The operator approved closeout. Settings schema stays 22.


## Post-0.57 consolidation coverage

`ghostty-launch` preserves scoped environment/arguments and desktop-entry semantics.
`phase12h/run` covers real-binary reload discovery and current publication-failure
status taking precedence over older successful receipts. `phase12g/run` retains
0.56/0.57 and unknown-version coverage; its exact historical build hash is fixture
input only. No legacy migration, lock-layout or fingerprint security tests were removed.

`stow` installs MAGI/Ghostty into disposable homes to verify runtime/package boundaries,
including development-directory and license exclusions. It never changes operator links.
Suite IDs remain explicit and unique; Phase-named suites cover distinct accepted
contracts rather than duplicate invocations. See [audit](review/post-057-consolidation.md)
for this run's exact results and retained environment limits.

Post-0.57 consolidation full run: **96 PASS / 4 ENVIRONMENT / 0 FAIL / 0 UNKNOWN**,
100 unique suites with no skips. The unchanged environment limits are documented
in the [consolidation review](review/post-057-consolidation.md).


## Thunar backgrounds and Hub focus

`thunar/run` validates palette-relative, application-scoped alpha CSS with GTK's parser,
active/backdrop selectors, opaque foreground policy and independent fixed Lua blur rules.
`phase12g/run` covers enrolled GTK/Ghostty composition, publication barriers, rollback,
release and missing-bootstrap refusal. `hub/run` adds real key events on production
content for typing, navigation, Enter and Escape, reopen and mode handoff. Its offscreen
window substitution cannot prove Wayland keyboard ownership or absence of input in the
previous app. The normal-session native gate separately passed all six immediate-typing
cases, reopen/navigation and theme checks; see the
[acceptance record](review/thunar-hub-focus.md). Test-only GTK captures exercise installed
Thunar drawing and expose repeated-background painting that syntax tests cannot detect.

## Custom Image Bar

`bar-image/schema`, extended `settings/assets`, and `runtime-visual/run:bar-image.qml`
cover placement/persistence, all-frame bounds, byte-identical imports, Qt GIF playback,
source colour/alpha composition, static/animated replacement, preview and multiple
Bar presenters. Real mouse/keyboard input checks size slider/stepper synchronization,
immediate rendering and persisted height after reload. Import tests require installed
`python-pyqt6`.

The earlier full run passed **99 PASS / 4 ENVIRONMENT / 0 FAIL / 0 UNKNOWN** across
103 suites with no skips. Final slider coverage also passed in the focused native
Qt harness. The final complete matrix, including the finished size controls, passed **99 PASS / 4 ENVIRONMENT / 0 FAIL / 0 UNKNOWN / 0 SKIPPED** (`/tmp/magi-regression-3mb5bbpe`).

The operator confirmed native visual acceptance, including the deployed size controls.
The currently saved 20px preference is preserved exactly at commit closeout. Physical
mixed-DPI/output coverage remains separate. See the [implementation and acceptance
record](review/bar-custom-image.md) for exact logs, source-alpha evidence and the four
unchanged sandbox restrictions; no exemptions were broadened.

## Control Centre decorative image

`controlcentre-image/schema`, extended `settings/assets`, and
`runtime-visual/run:controlcentre-image.qml` cover default-off/additive persistence,
shared byte-identical PNG/GIF import, source alpha and real-border overlap, theme
invariance, unchanged panel/blur geometry, staged animation and repeats/reversal,
compact fallback, output routing/removal, missing assets and Settings controls.
Only the intentional missing-fixture diagnostic is expected in the new harness;
unrelated QML warnings and assertions remain failures. Native acceptance is separate.
Full feature matrix: **101 PASS / 4 ENVIRONMENT / 0 FAIL / 0 UNKNOWN / 0 SKIPPED**
across 105 suites (`/tmp/magi-regression-qoeishms`), after 14/14 affected passes.
See [review and native acceptance status](review/controlcentre-image.md).

The subsequent Control Centre reveal refinement passed all 3 affected suites
(`/tmp/magi-regression-sbbq2evx`): schema, shared status lifecycle and decoration
runtime. It verifies actual gradual progress at 80ms for the 320ms reveal, the
120–500ms Settings range, repeat/reversal and early close. The prior full matrix
precedes this small timing refinement.

The final GIF extension matrix (including the timing refinement) passes **101 PASS /
4 ENVIRONMENT / 0 FAIL / 0 UNKNOWN / 0 SKIPPED** across 105 suites
(`/tmp/magi-regression-h912wlzu`). Added coverage verifies native GIF looping,
closed-frame stability, pause on non-owning outputs, static Settings preview,
PNG/GIF replacement, all-frame bounds and rendered alpha/colours/later content.
The operator's actual six-frame GIF also passes an isolated Qt render/loop check.
The operator accepted the revised GIF artwork and tests on 2026-11-09. This
operator acceptance is separate from the automated results above; physical
multi-output and native CPU measurements are not claimed.

## Hub focus, picker and Settings cards candidate

`hub/run` covers simulated grab-clear dismissal alongside existing real Qt search
keys and mode/query lifecycle; external app key delivery remains a real Hyprland
gate. `settings/image-picker` exercises actual Qt FileDialog selection/cancel/reopen,
explicit parenting, retained import ownership, errors and byte-identical persistence.
`settings/cards` checks grouping and controls across three actual window sizes and
two palettes. Profile's long-text/pinned-preview check remains warning-strict.
The final 107-command run passed 103 with 0 FAIL / 0 UNKNOWN and four established
D-Bus/socket ENVIRONMENT limits. Native Hub focus, chooser and light/dark
compact/normal card review passed on 2026-11-10. See
[evidence and native acceptance](review/focus-picker-settings.md).

## Appearance simplification and roundness audit

The canonical matrix now contains 110 commands. New `appearance/run` covers the
production page, responsive active-theme row, gallery expansion focus, icon-picker
open/cancel, primary precision slider/save/reload, application status fixtures,
keyboard/mouse disclosure and compact/wide alignment. `appearance/roundness-audit`
reads schema/defaults and inventories source without modifying Settings.
`runtime-visual/run:roundness.qml` exercises actual shared geometry and produces
optional min/current/max captures from a supplied snapshot. Existing gallery,
Theme Orchestrator pointer, Settings and quality checks remain warning-strict.
See [review, evidence limitations and final results](review/appearance-roundness.md).

Final Appearance matrix: **106 PASS / 4 ENVIRONMENT / 0 FAIL / 0 UNKNOWN /
0 SKIPPED**, 110 commands (`/tmp/magi-regression-lzqv44r2`). Existing private D-Bus,
PNG transport and native socket restrictions only. Corrected item captures and
inventory export were also rechecked. Native operator acceptance subsequently passed
all six Nord/One Light × compact/normal/wide cases plus the deployed Appearance page
on 2026-11-10. See the review for native log limitations and protected-state receipts.

## Roundness UI centralization — historical Option A

The matrix contains 112 commands. `appearance/run:--roundness` checks the twelve
actual editors, keyboard adjustment, existing ranges/units, null resets, private
save/reload, six responsive palette/size cases, shape selectors and no construction
writes. `appearance/roundness-audit` now describes the central editor locations;
its previous committed CSV/report remains historical evidence.
`appearance/roundness-equivalence` extracts accepted `fa40a70` with Git archive,
compares 419 preserved runtime/schema/native files and 24 software-rendered image
pairs (12 consumers × two palettes), with zero Settings writes. It does not use
an old worktree or claim native GPU masks from software captures. Existing CC
presentation tests retain runtime shape checks while the central test owns input.
Full regression and native results: [phase review](review/roundness-centralization.md).

Final Option A matrix: **108 PASS / 4 ENVIRONMENT / 0 FAIL / 0 UNKNOWN /
0 SKIPPED**, 112 commands, evidence in
`$STATE/magi/audits/roundness-centralization-oj03ofrt/full`. The final editor/census
rerun passed both commands after strengthening completed-disk-read assertions.
Native helper self-test passed; operator GPU/lock acceptance is still pending.

## Feature-owned roundness revision

The current matrix has 113 commands. `appearance/run:--roundness` now verifies the
10 feature-owned editors, hidden base/workspace fields, exact Appearance copy,
inheritance switches/disabled sliders, retained styles, null/absent persistence,
keyboard/save/reload and 30 page/width/palette combinations with no passive writes.
`runtime-visual/run:roundness-features.qml` adds shared-action min/current/max and
unified Bar min/current/max at compact/normal widths, workspace active/inactive
cells and expanded surfaces. `appearance/roundness-equivalence` now compares
417 unchanged runtime/schema/native files and 28 pixel-identical image pairs,
including collapsed/expanded connected surfaces, against `fa40a70`.
Targeted: 14 PASS. Full regression and revised native acceptance are recorded in
the [feature ownership review](review/roundness-feature-ownership.md). Historical
Option A logs/captures remain under their original audit paths.

Final feature-ownership matrix: **109 PASS / 4 ENVIRONMENT / 0 FAIL / 0 UNKNOWN /
0 SKIPPED**, 113 commands, evidence in
`$STATE/magi/audits/roundness-centralization-oj03ofrt/feature-ownership/full`.
Established Bluetooth/notifications private-bus, clipboard PNG transport and native
lock socket/private-bus limits remain explicitly classified. Revised native operator
acceptance was subsequently confirmed by the operator. The deployment source
hashes match, but the helper did not save a completed six-case result; automated
case-by-case native completion is not claimed.

## Settings refinement

`settings/refinement` runs real Settings pages in private XDG directories, checks
passive byte preservation, 720/1000/1400 widths in Nord/One Light, contextual Bar
selection/empty clicks and checked colour inheritance. It compares actual live CC
presenter coordinates with editor slots across empty/two/four/six-control layouts,
media and output widths, and adds/removes Suspend without executing it. Defaults
and migrations are compared to synchronized `5e00c38`. `wallpaper/presentation`
adds a private PNG and verifies discovery on page revisit. Roundness equivalence
uses the actual CC body, so the intentional preview correction does not masquerade
as a runtime redesign. `tests/settings/native-refinement.qml` is host-review only;
it is not automatically discovered as compositor acceptance. Final counts and the
native gate are recorded in [the refinement review](review/settings-refinement.md).

The full refinement matrix before the last Bar presentation follow-ups has
**110 PASS, 4 ENVIRONMENT, 0 FAIL, 0 UNKNOWN**. Six affected suites passed after
those follow-ups; no completed second full matrix is claimed. The operator accepted
the revised live UI on 2026-11-11. This is operator-reported acceptance, not inferred
from disconnected tests or a completed six-case helper receipt.

## Control Centre workflow pass 1

`settings/controlcentre-workflow` adds private real-QML coverage for unified card
ordering, passive Settings preservation, contextual selection, section drag/keyboard
movement, catalogue add/remove and invalid destinations. Initial catalogue delegate
size is checked before interaction as well as across responsive/light/dark cases.
No system action runs. Existing tests follow the new page scroll owner and disclosures,
without weakening runtime geometry or schema checks. `native-controlcentre-workflow.qml`
is a host-only private review fixture; it is not an automated compositor acceptance.
The operator accepted the live refinements. The full matrix before these small
presentation follow-ups passed 111 checks with four established ENVIRONMENT limits;
all seven affected suites and the refreshed capture fixture pass afterward. No
second full rerun is claimed. See [ownership, evidence and acceptance](review/controlcentre-settings-workflow.md).

## Control Centre pass 2 and default roundness

`settings/controlcentre-workflow:--fit` adds private transparent PNG wide/tall/disabled
stress fixtures, panel-only scaling and sticky-preview checks across six sizes/themes.
The ordinary workflow suite retains pointer/keyboard module editing, palette clipping,
selection while scrolled and exact passive Settings preservation. Legacy presentation
fixtures now address the inspector scroll owner explicitly. `appearance/roundness-audit`
enforces nine unique numeric editors (eight sliders/one stepper), twelve retained
fields and no production action binding/editor. `roundness-features.qml` checks
Appearance min/current/max, retired-field invariance and independent feature tokens.
`appearance/roundness-equivalence` compares 46 captures against `93ef0da`, recording
approved generic differences while requiring feature images to match. It rejects
other runtime/schema/native changes; Settings composition is tested separately.
The guarded native helper uses a fresh invocation snapshot and private interaction
values. Native acceptance remains pending in the [Pass 2 review](review/controlcentre-settings-pass2.md).

Pass 2 offline result: 112 PASS / 4 established ENVIRONMENT / 0 FAIL / 0 UNKNOWN;
four final affected preview/reorder checks also pass. Native review remains pending.
