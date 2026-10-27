# Phase 15 regression reconciliation

Status: **Resolved.** Final canonical matrix: **85 commands; 81 PASS, 0 FAIL, 4 ENVIRONMENT, 0 SKIPPED; UNKNOWN=0**. No suites retired.

Accepted source: `4a26d6232c97266f011355b8fb932f8e0436c0e6`, schema 22. The full initial fresh run completed all 83 commands: **68 PASS, 13 FAIL, 2 ENVIRONMENT, 0 SKIPPED**. This supersedes the interrupted 57/20/2/4 count.

## Reproduction method

A disposable detached `/tmp` worktree at the accepted commit received only the canonical runner and the same operator settings fixture. No Phase 15 test corrections were copied. The 22 prior failures/environment commands completed: 3 PASS, 17 FAIL, 2 ENVIRONMENT. The three passes establish runner/environment corrections (Settings presentation, Hub, default runtime visual); they are not runtime fixes. Logs: `/tmp/magi-phase15-baseline-results`. Initial full logs: `/tmp/magi-phase15-triage-full`.

## Original 20 failures

| Suite / command (from linux/magi) | Exit | Assertion / component | Baseline reproduction | Classification | Correction |
| --- | --- | --- | --- | --- | --- |
| `settings/presentation` — `python3 tests/settings/presentation.py` | 1 | Unset compositor signature warning rejected after assertions passed | PASS, exit 0 | FIXTURE ISOLATION | Runner supplies a nonexistent synthetic compositor signature. |
| `settings/modules:catalogue` — `python3 tests/settings/modules.py catalogue` | 1 | Initial fully-open and handoff assertions; Timer continued after failure | FAIL, exit 1 | FIXTURE ISOLATION | Visible offscreen host, explicit output routing, QtTest readiness waits; all five handoffs retained. |
| `settings/catalogue` — `node tests/settings/catalogue.cjs` | 1 | Hub entries expected action-only eligibility | FAIL, exit 1 | STALE TEST | Assert accepted action and tile presentations. |
| `phase10b/run` — `python3 tests/phase10b/run.py` | 1 | expected18 helper overwrote custom lock and missed later schema | FAIL, exit 1 | STALE TEST | Use expected-current preserving existing lock customizations and retired-field scrub. |
| `phase10c1/run` — `python3 tests/phase10c1/run.py` | 1 | Current migration result expected schema18 | FAIL, exit 1 | STALE TEST | Derive current output/future version from defaults; keep historical input. |
| `phase12a/run` — `python3 tests/phase12a/run.py` | 1 | Current schema expected18 | FAIL, exit 1 | STALE TEST | Current defaults and expected-current helper; retain historical migration coverage. |
| `phase12e/run` — `python3 tests/phase12e/run.py` | 1 | Current schema expected19 | FAIL, exit 1 | STALE TEST | Derive fixture version from defaults; keep ownership assertions. |
| `phase10a/icon-fallback` — `python3 tests/phase10a/icon-fallback.py` | 1 | CC-open assertion lacked output owner; stale compositor reference | FAIL, exit 1 | FIXTURE ISOLATION | Supply SurfaceOrigin outputs, complete compositor substitution and fake TrayModel. Resolver/image-error checks preserved. |
| `phase14a/fleet` — `python3 tests/phase14a/fleet.py` | 1 | Incomplete Tray stub; retired shortcut popup/keyboard expectation | FAIL, exit 1 | STALE TEST | Use real TrayModel with fake items; assert inline toggle, unchanged layout, overflow/hotplug. |
| `displays/run` — `python3 tests/displays/run.py` | 1 | Nested phase10b policy current-schema expectation | FAIL, exit 1 | STALE TEST | Shared expected-current correction; no display production changes. |
| `hub/run` — `python3 tests/hub/run.py` | 1 | Unset compositor signature warning after passing assertions | PASS, exit 0 | FIXTURE ISOLATION | Synthetic signature contract; accepted baseline passes with corrected environment. |
| `clipboard/model` — `python3 tests/clipboard/model.py` | 1 | Two valid-PNG image tests fail with Image unavailable | FAIL, exit 1 | ENVIRONMENT LIMIT | Independent GdkPixbuf probe returns D-Bus Operation not permitted; classify only exact two-error signature plus probe. Nine non-image tests pass. |
| `theme-orchestrator/qml` — `python3 tests/theme-orchestrator/qml.py` | 1 | Registry before debounce; obsolete reload/status labels | FAIL, exit 1 | STALE TEST | Wait applyPending and busy; finite current activation labels; copied executor has no host processes. Enrollment, failure, clipboard-copy and changed-hook tests retained. |
| `calendar/schema` — `node tests/calendar/schema.cjs` | 1 | Current migration output expected16 | FAIL, exit 1 | STALE TEST | Derive current schema; keep v7/v8 input and validation. |
| `clipboard/schema` — `node tests/clipboard/schema.cjs` | 1 | Current migration output expected16 | FAIL, exit 1 | STALE TEST | Derive current schema; keep v5/v6 input and validation. |
| `emoji/schema` — `node tests/emoji/schema.cjs` | 1 | Current output expected16; version17 treated future | FAIL, exit 1 | STALE TEST | Derive current/future schema; retain v8/v9 history. |
| `wallpaper/schema` — `node tests/wallpaper/schema.cjs` | 1 | Current output expected16; version17 treated future | FAIL, exit 1 | STALE TEST | Derive current/future schema; retain v9/v10 history. |
| `runtime-visual/run:runtime.qml` — `python3 tests/runtime-visual/run.py runtime.qml` | 1 | Runner passed explicit runtime.qml absent from marker map | PASS, exit 0 | FIXTURE ISOLATION | Invoke default harness without argument, as designed. Accepted baseline passes. |
| `runtime-visual/run:appearance.qml` — `python3 tests/runtime-visual/run.py appearance.qml` | 1 | Removed contextual inspector/nav/sections assumptions | FAIL, exit 1 | STALE TEST | Select current families/disclosures, use top-level navigation and current section operation. Retain rendering, gap combinations, preview and focus assertions. |
| `runtime-visual/run:feedback.qml` — `python3 tests/runtime-visual/run.py feedback.qml` | 1 | Centered selector, Theme dropdown and removed CC subsections | FAIL, exit 1 | STALE TEST | Assert current left-aligned selector; use Date/time popup; current family disclosures with keyboard and no-write checks. |

## Additional complete-run finding

`runtime-visual/run:typography.qml` exceeded its old 60-second harness timeout. Its existing exhaustive typography matrix passes in 60.8 seconds with a 180-second bound; assertions were unchanged. Baseline timeout reproduction is logged separately in `/tmp/magi-phase15-baseline-typography`.

## Environment and security boundaries

- Private D-Bus creation: Bluetooth bus and Notifications report both `Failed to start message bus` and `Operation not permitted`; not protocol passes.
- Clipboard decoding: exact two-error signature and independent decoder denial required before ENVIRONMENT classification.
- Native lock builds successfully. Existing native transport failures require host SOCK_SEQPACKET transport verification: sandbox send returns EPERM. Security assertions remain unchanged; no live lock/PAM request was made.

## Coverage and implementation boundary

No test suite retired. No production component restored or changed. Historical schema input versions remain explicit. `expected-current.cjs` replaces a helper that incorrectly froze schema18 and overwrote custom lock data. The runner records commands, exit codes, durations, reason/classification and logs in `results.json` (also `summary.json` for compatibility). Zero exit cannot override an assertion/QtTest failure marker. Timeouts terminate the test process group.

## Historical blocking finding: Profile layout recursion (resolved)

**UNKNOWN; not an environment classification.** Corrected appearance assertions
pass, including 96 layout/gap combinations, typography, preview lifetime, navigation
and keyboard dismissal. Qt nevertheless reports `Detected recursive rearrange.
Aborting after two iterations` from `ProfilePage.qml` rows 38 and54.
The strict harness therefore remains FAIL.

Accepted production source reproduces this with the corrected fixture and no
runtime edits: `/tmp/magi-phase15-baseline-profile-warning2`, exit 1, 73.8 seconds.
This is a newly exposed baseline finding, not a Phase 15 runtime regression.
A smaller Hub/Bar/Profile fixture reproduces the warnings when switching from
Appearance to Profile with a pinned Control Centre preview and long display-name /
message values. A standalone Profile page with the same text and width changes does
not. Final fields settle at 240px in 520px rows; visible corruption is not established.

Likely area to inspect: `SettingsRow` chooses one/two columns from its own width and
conditionally changes child preferred/maximum widths; the surrounding Settings
page is being laid out during navigation. This is a hypothesis, not a proven fix.
Do not suppress warnings or alter production layout without review. Proposed next
step: inspect a focused native Profile navigation reproduction and instrument the
row/parent size negotiation, then review the smallest constraint correction if a
real layout cycle is confirmed.

Logs: `/tmp/magi-phase15-appearance-completion`,
`/tmp/magi-phase15-hub-profile-probe.log`, and the baseline reproduction above.
The temporary detached baseline worktree was removed after all jobs completed;
its only modifications were copied test/runner/settings inputs, checked against
retained originals. Only `~/dotfiles` remains registered.

## Minimal diagnostic fixture

The following fixture uses the existing `runtime-visual/run.py` disposable window/service adapters. Substitute it as the harness input; do not load it in the live shell. It asserts navigation while leaving Qt layout warnings visible.

```qml
import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/bar" as Bar
import "../../.config/quickshell/magi/components/hub" as UI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
 Bar.Bar {id:bar;expandableHostMode:"combined"}
 UI.HubWindow {id:hub;readyToOpen:bar.settingsReady;previewSurface:bar.activeCombinedRegion}
 Timer{id:finish;interval:100;onTriggered:Qt.quit()}
 TestCase{name:"HubProfileProbe";when:Services.Settings.ready
 function collect(item){let a=item.maximumLength===80||item.maximumLength===160?[item]:[];for(const c of item.children||[])a=a.concat(collect(c));return a}
 function test_profile(){try{
 Services.Settings.setValue('profile','displayName','A long display name '.repeat(4).trim())
 Services.Settings.setValue('profile','subtitleMode','custom')
 Services.Settings.setValue('profile','subtitle','A long optional profile line '.repeat(4))
 Services.SettingsWindowState.page='Control Centre';Services.SettingsWindowState.open();wait(150)
 Services.SettingsWindowState.toggleControlCentrePreview();tryCompare(bar.expandablePillRegistry.controlcentre,'phase',3)
 for(const name of ['Appearance','Profile','Bar','Date & time','Notifications','Profile','Control Centre']){
  console.log('NAV',name)
  const nav=findChild(hub.contentItem,'settingsNav-'+name)
  nav.forceActiveFocus();wait(30);mouseClick(nav);wait(80)
  compare(Services.SettingsWindowState.page,name)
  if(name==='Profile')for(const f of collect(findChild(hub.contentItem,'settingsPage-Profile')).filter(f=>f.text.startsWith('A long'))){
   f.forceActiveFocus();keyClick(Qt.Key_A,Qt.ControlModifier);for(const c of 'Operator')keyClick(c);wait(30)
   console.log('FIELD',f.width,f.parent.width,f.parent.columns)
  }
 }
 console.log('CC appearance and preview PASS')
 }catch(e){console.error('FAIL:',e,e.stack)}finally{finish.start()}}
 }
}
```

## Final complete matrix and stop decision

Command (from `~/dotfiles`):

```sh
python3 linux/magi/tests/run-all.py --logs /tmp/magi-phase15-reconciled-full
```

All **83** commands finished: **79 PASS, 1 FAIL, 3 ENVIRONMENT, 0 SKIPPED**.
Overall exit 1, as required. `results.json` and its compatibility `summary.json`
contain every command, exit, duration, log and reviewed classification/reason.
The sole FAIL is `runtime-visual/run:appearance.qml`, classified **UNKNOWN** for
the Profile layout warnings. All assertions pass, which does not override warnings.
The other original failures are resolved or specifically classified; totals for the
original 20 causes are 14 STALE TEST, 5 FIXTURE ISOLATION, 1 ENVIRONMENT LIMIT.
Typography timeout was additionally reproduced on baseline and resolved by allowing
the unchanged exhaustive matrix to complete.

Environment results are Bluetooth private-bus transport, Notifications private-bus
transport and Clipboard PNG decoder transport. No suite was retired or silently
skipped. No genuine user-visible production regression is established. This is not
a clean regression acceptance: consolidation/staging/commit/push remain blocked.

Launcher delayed-write no-EPIPE passed at 127.2 seconds after shell exit. Native lock
clean Cargo/CMake builds from the earlier Phase 15 audit remain valid (native source
unchanged). Its separate 21-case CTest result was 15 PASS, 5 transport-dependent failures,
1 fingerprint transport SKIPPED; Rust protocol proofs 6 PASS/10 transport failures.
The sandbox SOCK_SEQPACKET send denial remains a host-verification limitation,
not permission to weaken lock tests or claim full native security acceptance.

Protected-state recheck: all 21 entries retain their snapshot bytes/modes/symlink
values. Schema 22 and baseline HEAD are unchanged; tracking divergence 0 0; index
empty. Runtime differences are only pre-existing protected Settings and three
battery artworks. No source reload or live smoke was needed for test/docs edits.
The temporary baseline worktree is removed; only `~/dotfiles` remains registered.
Audit logs and the prior native build are retained for the unresolved review.

**Historical stop decision:** operator review was required at this point. The later
focused investigation below resolves that gate; this paragraph preserves the earlier result.

## Authorized resolution

The operator authorized a focused investigation and minimal production correction.
The exact measurement cycle is documented in [Profile layout review](phase15-profile-layout.md).
The parent width stays 520px while content-dependent row width alternates above and
below the420px column breakpoint. Conditional field constraints cause the feedback.
This is a baseline production layout defect, not fixture-only geometry.

One production file changes: SettingsRow.qml reads parent available width for its
column count. A negative control using the old row emits four warnings; the fixed
focused regression and complete appearance suite emit none. The new regression
covers first creation with long values, short/long/empty variants, three widths,
Dawn, conditional visibility, bounds and pinned preview. The operator accepted
native smoke. No authentication/routing/launcher/tray implementation changed.

The subsequent 84-command run completed 81 PASS, 0 FAIL, 3 ENVIRONMENT, 0 SKIPPED;
UNKNOWN=0. Regression reconciliation is complete. The final canonical runner also
includes clean native build/tests with exact evidenced sandbox classification.


## Final canonical matrix

`python3 linux/magi/tests/run-all.py --logs /tmp/magi-phase15-final-full`
completed all 85 commands: **81 PASS, 0 FAIL, 4 ENVIRONMENT, 0 SKIPPED**.
The runner returns 2 to distinguish environment limitations from an all-pass run.
Machine-readable commands, durations, classifications and log names are in
`/tmp/magi-phase15-final-full/results.json`.

Environment entries are Bluetooth private-bus transport, Notifications private-bus
transport, Clipboard's two image decoder checks, and native lock transport. Each
requires its specific denial signature; Clipboard/native also run independent probes.
Native clean Cargo/CMake builds pass. Internally CTest has 15 passes, 5 transport
failures and 1 fingerprint transport skip; Rust has 8 passes and 10 transport
failures. These failures remain visible and are not security-test passes. Native
source matches the audited accepted baseline and SOCK_SEQPACKET send independently
returns EPERM. No authentication assertion was relaxed.

Launcher delayed-write testing passes after 127 seconds without EPIPE. Profile
warnings disappear in the new focused test and full appearance suite, with all
compact/normal/wide and Dawn geometry checks retained. Native smoke is accepted.
Regression reconciliation complete; Phase 15 consolidation may continue.
