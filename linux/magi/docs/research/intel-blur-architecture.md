# Intel compositor blur architecture audit

Prepared 2026-11-04 against production
`c1d72a829b5a19a65781251c50ebd32524b63641`. NVIDIA-primary and BIOS Discrete
experiments are cancelled. Hybrid/Intel is the compositor baseline; PRIME offload
is the intended separate mechanism for heavy applications. This phase changes no
GPU routing, BIOS, PRIME settings or monitor configuration. The already accepted
temporary monitor-directory link is left exactly as found.

## Current review decision — 2026-11-05

Retain Hybrid/Intel rendering and existing MAGI painted blur regions. Remove the
Ghostty CSS/native blur request path while retaining native background alpha and
Hyprland transparent-window blur. Keep the independent 0.56/0.57 effects API fix.
Native Ghostty A/B and MAGI layer visual/performance comparisons are complete;
normal launch-wrapper/desktop installation, full Ghostty quit/reopen and final
theme-switch/restore acceptance are complete. Commit/push awaits approval.
Dated checkpoints below preserve intermediate findings; the final deployment
acceptance section records the current result and remaining limits.

## Historical evidence and limits

The repository is not shallow. All reachable history starts at
`47937c58982eb63fca9f6fa222429974cfce6563` (2026-08-17). That initial commit already
contains `hyprland.lua`, headed “Migrated from hyprland.conf”, alongside Waybar and
SwayNC startup. No `hyprland.conf` exists in reachable paths or the inspected
unreachable commits. Reflogs reach the same initial commit. A copied old Neovim
swap for hyprland.conf recovered only one character plus newline, not settings;
the original swap was not changed. The operator confirms no other pre-Lua backup
is available. Consequently the last known-good **pre-Lua** configuration cannot
be recovered or reconstructed honestly from this evidence.

The earliest recoverable Lua configuration is exact evidence, not proof that
this was the smooth setup. Its blur values are identical to current static Lua:

| Setting | Earliest Git Lua | Current tracked Lua |
| --- | --- | --- |
| enabled | true | true |
| size / passes | 8 / 4 | 8 / 4 |
| ignore_opacity | true | true |
| new_optimizations | true | true |
| xray | false | false |
| brightness / contrast | 0.90 / 0.92 | 0.90 / 0.92 |
| noise | 0.015 | 0.015 |
| vibrancy / vibrancy_darkness | 0.15 / 0.50 | 0.15 / 0.50 |

Neither snapshot explicitly sets decoration active/inactive/fullscreen opacity,
nor an application opacity rule. Earliest Ghostty config sets native
`background-opacity = 0.95`, with no CSS or native blur request. Current static
Ghostty retains 0.95; managed generated output can override it (not multiply it).
Unspecified compositor defaults must not be projected backwards across versions.
Native runtime values are recorded separately by the new test helper.

Earliest Lua layer rules explicitly blur `swaync-control-center` with
ignore_alpha 0.08, and `swaync-notification-window` with ignore_alpha 0.12; both
disable layer animations. These obsolete SwayNC rules were removed during shell
retirement, not translated into broad rules for every Quickshell surface.
The workspace animation remains enabled, speed 6, default curve. The audit does
not change animations, shadows or other visual ownership.

`d4f22babf3f87e03154a8ee98a1590763694d2b5` (2026-10-24) introduced MAGI application
appearance, generated Ghostty CSS, the fixed Ghostty-only no-blur exclusion rule,
and MAGI protocol blur regions. Historical investigation in
`docs/design/phase12g-window-visuals.md` records why simply allowing blur had failed
on GTK 4.24.1. The later 0.57 border fix did not correct this separate appearance
executor's exact 0.56.2 build gate.

## What owns blur now

Ghostty supplies background alpha. MAGI publishes a Ghostty-only GTK stylesheet
with `window.window { backdrop-filter: blur(20px); }`. GTK turns qualifying nodes
into an ext-background-effect blur region. Hyprland computes compositor blur;
the protocol does not convey MAGI's global size/passes. The fixed window rule can
exclude Ghostty, and the separately managed global-blur service changes size only.
The latter and appearance rule executor still reject 0.57 in production.

This is an additional **client-controlled region path**, not proof of two
independent compositor blur passes. Hyprland v0.57.0 CWindow::shouldBlur chooses
the client region when a background-effect object exists; otherwise it uses its
automatic transparent-window path. An empty client region suppresses blur.
GTK 4.24.1 creates that object even without a CSS blur request. This explains why
the earlier no-CSS test could feel responsive while losing Ghostty blur. It did
not test the desired compositor-only, still-blurred path.

The upstream documented alternative is to launch **only Ghostty** with
`GDK_WAYLAND_DISABLE=ext_background_effect_manager_v1`, remove CSS and native blur
requests, and keep native alpha. GTK's protocol filter is read at process startup;
reloading Ghostty cannot change an already negotiated connection. This is not a
renderer/GPU selector and is not exported into the session or other applications.

MAGI Bar, Hub, toast cards and anchored popup backgrounds currently send explicit
BackgroundEffect regions for painted shapes. They do not perform a QML background
blur shader on the desktop. The MultiEffect blur found in Settings is a wallpaper
preview inside the lock editor. Hub/Settings/launcher/clipboard share `magi-hub`;
notifications use `magi-toasts`; Bar currently uses the generic `quickshell`
namespace, and anchored popups are child surfaces. No production blanket
`hl.layer_rule` for Quickshell exists.

A layer-rule-only candidate needs explicit MAGI namespaces and removal of protocol
object creation, not just an additional `blur=true` rule: v0.57.0
CLayerSurface::shouldBlur gives the protocol region precedence over that rule.
The full-output transparent hosts also require an alpha threshold/appropriate
visible-region bounds, or blur scope may expand beyond painted panels. Do not
blindly add a generic quickshell rule or discard the current region safeguards.
The first controlled comparison keeps these panels identical across cases to
isolate Ghostty; the requested targeted layer policy remains a separate pending
evaluation after the application result. No live QML is changed or restarted.

## Isolated candidate and native test

The candidate incorporates the recovered 0.56/0.57 appearance/global-blur parser
fix, retaining generation checks, error handling and exact readback. Ghostty's
adapter emits background alpha and `background-blur = false`, with no generated
CSS; its renderer version is incremented so publication invalidation is explicit.
Release still omits managed keys. This candidate is not deployed to production:
its required per-application launch integration and performance acceptance are
pending. Schema stays 22.

`tests/blur_architecture_live.py` is an operator-only helper, excluded from the
offline runner. Its persistent bundle contains the isolated candidate services
and palette registry. It creates disposable Ghostty processes, preserving actual
static preferences/palette, with 80% background alpha and native blur false.
It never edits Settings, published theme generations or tracked config. All live
effect writes use Lua; the patched global-blur executor sets size 10 and the fixed
exclusion handle permits Ghostty blur. Original runtime values are recorded before
writes and restored on completion/interruption. Recovery refuses stale compositor
generations and only terminates the helper's own verified child process.

Cases, repeated three times in forward/reverse/forward order:

1. A: current MAGI CSS request, GTK background-effect enabled.
2. B: no CSS/native blur request, GTK protocol disabled for this Ghostty process,
   Hyprland's transparent-window blur path.
3. C: B plus the earliest recoverable Lua blur parameters above, with size 10 as
   requested. This is explicitly **not** a recovered pre-Lua known-good config.
   If current runtime parameters already equal that set, C is a repeat/control,
   not an invented third architecture.

Fresh protocol-traced probe windows verify A creates a surface effect and requests
a region, while B creates no surface effect and sends no region calls. Probe logging is off for all measured windows. Existing
Ghostty windows must be parked outside workspaces 1/2; workspace 1 has a fixed
comparison app and workspace 2 is reserved for the disposable test window.
The helper leaves animation settings unchanged, dispatches normal workspace
switches, records deduplicated Intel render-engine nanoseconds and CPU counters
for the compositor, Ghostty and mapped Quickshell, and asks about blur retention,
typing latency, workspace/pill response, readability and artifacts. Engine busy
percentages are not frametimes or proof of smoothness.

## Validation and pending gates

28 appearance tests and 11 global-blur tests pass. Five affected canonical suites
pass (Settings appearance, appearance model/presentation, theme orchestration and
bootstrap). Sixteen helper tests cover process-scoped protocol filtering, GPU-counter
deduplication, real Lua dispatch parsing, command/readback rejection and generation-safe restoration. Full canonical
regression follows the accepted native candidate, before any permanent change;
the previous monitor phase's full result is not this candidate's full regression.
Native A/B results, layer-only evaluation and final Lua policy are pending. No
commit/push is authorized or performed. Production remains clean at the baseline.

## First native attempt and helper correction — 2026-11-05

The run `native-test/run-2a4p7s9o` passed Intel/Lua/config preflight and recorded
active/inactive/fullscreen opacity 1.0, blur variant 0, special/popups/input-method/
proportional blur all false, and the expected static blur parameters (size 8,
four passes). It failed before launching a probe or collecting a sample: the
helper incorrectly used `hyprctl dispatch workspace 2`, which this Lua provider
parses as invalid Lua. This is a helper bug, not a compositor performance result.

Restoration read back the original blur parameters and exclusion rule, then hit
the same syntax error when returning to workspace 3. The corrected helper uses
`hyprctl eval 'hl.dispatch(hl.dsp.focus({workspace=3}))'` (or the requested numeric
workspace), checks `ok` and active workspace, and persists each verified recovery
step. Real Lua tests exercise the generated dispatch expression. A constructor
probe now runs before any effect changes. Native recovery must be verified before
resuming comparison; no successful A/B result is claimed.

The dispatch syntax is documented in the [current upstream hyprctl guide](https://wiki.hypr.land/configuring/core/advanced-configuration/using-hyprctl/),
inspected 2026-11-05, and matches the production Lua workspace keybindings.

## Constructor preflight correction — 2026-11-05

The operator successfully recovered `run-2a4p7s9o`: original blur, exclusion rule,
workspace and protected files were verified. The next run, `run-ca0lwomj`, stopped
before any effect writes because the helper asserted Lua binding/action type
names. That assertion was an unsupported implementation assumption. No samples
were collected and the report confirms no compositor changes were made.

The preflight now evaluates only `hl.dsp.focus({workspace=...})`, without executing
the action or assuming its representation. Actual switching still executes the
native-recovery-proven dispatch expression and checks runtime workspace readback.
Thirteen offline helper tests pass, including callable bindings returning opaque
objects and rejection of constructor errors. Native comparison remains pending.

## Native protocol evidence and gate correction — 2026-11-05

`run-f36z4ev3` restored original blur, exclusion rule and workspace, with protected
files unchanged. No timing samples were collected. Both private Ghostty probe
windows mapped and attached buffers. A created a background-effect surface and
submitted blur regions. B still bound a manager through another registry, but
created **no** background-effect surface and issued **no** blur-region calls.
The previous check incorrectly equated manager binding with surface activation.

The gate now checks actual effect creation/region calls, retaining manager binding
as evidence. B rejects even an empty surface effect, which would suppress automatic
blur; incomplete traces also fail. This follows Hyprland v0.57.0
`CWindow::shouldBlur`, rechecked 2026-11-05 in the upstream Window.cpp linked below.
The remaining manager binding is not evidence of a second blur operation. Its exact
client-side owner has not been established. Both full captured logs pass the
corrected gate. Sixteen offline helper tests pass, including trace-derived request
sequences, rejection of empty effects and incomplete evidence. Native blur appearance
and performance remain unmeasured; do not infer success from protocol evidence alone.

## Successful Ghostty native comparison — 2026-11-05

Report: `native-test/run-388ouv5d/report.json` in the durable audit directory.
All three cases retained 80% native background alpha, size 10, four passes and
normal workspace animation, with Intel rendering and workspaces 1/2. Three samples
per case used forward/reverse/forward order. Exact runtime blur readbacks were
identical in A/B/C; C is therefore a reference repeat, not a different recipe.

| Case | Hyprland Intel render busy, median | Ghostty Intel render busy, median | Operator observation |
| --- | ---: | ---: | --- |
| A: current CSS request | 51.8% | 21.2% | Blur/transparency present; typing, workspace switch and pill laggy |
| B: alpha + compositor-only blur | 62.0% | 1.78% | Blur/transparency present; no typing lag; workspace/pill responsive |
| C: earliest Lua reference | 62.0% | 1.81% | Blur/transparency present; typing good; workspace/pill fairly responsive |

Quickshell render busy stayed approximately 0.26–0.28%. The client-side change
reduced Ghostty engine time by about 92%, while compositor engine time increased.
These counters do not measure input latency/frame pacing and should not be added
as a claim about total GPU utilization. The operator's observations establish the
practical improvement on this workload. This supports removing the Ghostty-specific
request path, without proving a second physical blur pass or GPU saturation.

Protocol probes confirm A attached an effect and submitted regions; B attached no
effect and sent no region calls. Original blur/rule/workspace and protected files
were restored and verified. No permanent candidate installation occurred.

### Normal launch candidate

The isolated Ghostty Stow package now includes a `~/.local/bin/ghostty` wrapper
that adds the GTK protocol opt-out only when a Hyprland instance is present. It
executes `/usr/bin/ghostty`, preserving argv and GPU/PRIME variables. Existing
protocol filters are retained. A user desktop entry retains the installed entry's
metadata/actions and single-instance flag, setting `DBusActivatable=false` so
normal launcher execution passes through the wrapper before GTK initializes.
The upstream MIT attribution is retained. The user's login sources `.bashrc`,
which already puts `~/.local/bin` first on PATH. Direct `/usr/bin/ghostty` or direct
D-Bus activation bypasses this wrapper; no session-wide environment is changed.
Like ordinary process environment, the filter is inherited by terminal children;
this launch integration still needs native acceptance and scope review before
permanent installation. Existing Ghostty processes require a complete quit/reopen
once; config reload cannot renegotiate GTK's connection.

Generated output retains alpha/cell behavior and explicitly sets native blur false,
with no generated CSS. The 0.56/0.57 appearance/global-size executor correction
remains in the isolated candidate. No schema bump or border-adapter change.

### Additional Lua layer experiment requested by operator

The operator selected a separate MAGI layer-rule trial. `control.py --layers`
keeps Ghostty on case B and compares production MAGI regions against a copy of
the full MAGI shell with four attached blur bindings removed. It uses exact audit
namespaces for Bar, Hub and toasts, with `blur=true`, `ignore_alpha=0.01`, and
`blur_popups=true` only for Bar/Hub. It changes no geometry, alpha, animation,
wallpaper, GPU or monitor policy. The alpha cutoff may alter antialiased/fading
edges versus rounded region masks; visual equivalence is explicitly unproven.

The helper restarts MAGI through its normal `quickshell -c magi` entry, temporarily
switching the config symlink to a complete copy. It retains all production services
and keybindings, copies Settings without writing the original, and restores the
original link/shell plus runtime state automatically. It persists recovery before
mutations. Trial rule handles are disabled on recovery; inactive named rules remain
until the next normal compositor reload. No reload is requested by this test.

A protocol-traced visual check must show no candidate background-effect attachment.
Timing runs turn protocol logging off and use P/Q/Q/Q/P/P ordering. The operator
must inspect panels, rounded edges, empty padding, menus/popups and click behavior
before timing Q. No Settings edits, locking or suspension during this short trial.
This is a test-only prototype: production blur-toggle reconciliation for layer
rules is not yet implemented and will depend on acceptance. Native panel/blur
performance remains pending. Direct offscreen PanelWindow loading is unavailable
(no backend); the existing adapted runtime harness loaded the candidate Bar/Hub
and passed its daily-polish interaction checks. Offline checks are not native
layer geometry acceptance.

## Sources

Inspected 2026-11-04. Own historical files are recovered verbatim; upstream source
is used to establish behavior, not copied into MAGI.

- [Hyprland FAQ](https://wiki.hypr.land/faq/): documents GTK empty-region behavior
  and the application protocol filter alternative.
- [GTK 4.24.1 gdkdisplay-wayland.c](https://github.com/GNOME/gtk/blob/4.24.1/gdk/wayland/gdkdisplay-wayland.c):
  init_skip_protocols reads GDK_WAYLAND_DISABLE and filters interface binding.
- [GTK 4.24.1 gdksurface-wayland.c](https://github.com/GNOME/gtk/blob/4.24.1/gdk/wayland/gdksurface-wayland.c):
  surface creation, content-region calculation and set_blur_region behavior.
- [Hyprland v0.57.0 Window.cpp](https://github.com/hyprwm/Hyprland/blob/v0.57.0/src/desktop/view/window/Window.cpp):
  CWindow::shouldBlur applies exclusions, then protocol/automatic-path choice.
- [Hyprland v0.57.0 LayerSurface.cpp](https://github.com/hyprwm/Hyprland/blob/v0.57.0/src/desktop/view/LayerSurface.cpp):
  CLayerSurface::shouldBlur prioritizes client regions over the layer rule.
- [Hyprland v0.57.0 SurfacePassElement.cpp](https://github.com/hyprwm/Hyprland/blob/v0.57.0/src/render/pass/SurfacePassElement.cpp):
  optimized precomputed versus live blur selection; no claim that a protocol
  region automatically implies an additional blur pass.

Additional sources inspected 2026-11-05:

- [Current Lua layer rules](https://wiki.hypr.land/configuring/core/rules/layer-rules/): named handles, scoped namespace matching, blur/popups and alpha cutoff.
- [Quickshell background-effect implementation](https://github.com/quickshell-mirror/quickshell/blob/master/src/wayland/background_effect/qml.cpp): attachment creates the surface effect even with an empty region; candidate removes the attachment entirely. Installed Quickshell is 0.3.2; native protocol acceptance remains required.

## Regression checkpoint — 2026-11-05

The canonical full run recorded 93 PASS, 1 FAIL, 4 ENVIRONMENT. The failure was
Phase12H expecting the removed Ghostty CSS file; its assertion now requires
alpha/cells output, native blur false and no CSS. Its 24 tests passed on rerun.
The newly registered helper suite also passed; latest direct run has 23 tests.
Combining the full run with these targeted results accounts for all 99 current
suites: **95 PASS, 4 ENVIRONMENT, 0 remaining FAIL, 0 UNKNOWN**. Original failing
logs are retained alongside the explicit reconciliation. Environment cases are
Bluetooth private-bus transport, clipboard decoder transport, notification bus
transport and native lock sandbox prerequisites. `git diff --check` passes.

Production remains clean at c1d72a829b5a19a65781251c50ebd32524b63641, equal to
origin/main, with empty index. Candidate work is isolated and uncommitted. No
schema change (22). Native Lua-layer and normal-launch acceptance remain pending.

## Layer visual gate stopped — 2026-11-05

`layers-oiu3uzr1` collected one P baseline sample only. Ghostty remained responsive
with blur/alpha. The operator saw MAGI menus as solid in both original P and Lua Q
and stopped at the visual gate. Q was not timed or accepted. Restoration verified
the original MAGI link/IPC, runtime effects/workspace and protected files; trial
layer rules were disabled. Saved and copied Settings both contain managed=true,
backgroundOpacity=0.79, blurEnabled=true. The Q trace shows audit Bar/Hub layers
and no background-effect attachments; no EGL presentation failure was logged.

A separate offline render of the production HubSurface using these exact saved
Settings reports computed and actual QML alpha 0.7900053, sharedBlur=true, no
Settings diagnostics, and PNG center alpha 201/255 (0.788235). This verifies the
component's alpha in software rendering, not its native compositor presentation.
The user report cannot yet be attributed to missing alpha, missing compositor blur
or a visually uniform backdrop. No production alpha/blur values have been changed
to conceal the symptom. Opaque child controls and Settings sidebar remain intentional.

`control.py --layers-inspect` now provides a short diagnostic without workspace
timing loops: original regions and Lua layers over the same private terminal
contrast pattern, with read-only native QML alpha telemetry in each copied shell.
It preserves 79% panel alpha and 80% Ghostty background alpha; explicit coloured
terminal cells are opaque reference content. It does not change wallpaper, GPU,
monitors or saved Settings. Both shell copies retain full normal services, and
the original shell/runtime is restored automatically. Native alpha/visual evidence
and final layer-policy acceptance remain pending. The helper has 25 passing offline
tests; the instrumented shell parses with installed qmlformat. Prior production
regression results are unchanged because this follow-up changes test helpers only.

## Native panel-alpha and visual confirmation — 2026-11-05

`layers-tr4zgf46` completed the controlled-background inspection. Both P (original
client regions) and Q (Lua layer rules) read back hub/expanded-panel colour alpha
0.7900053 and transparent window backgrounds (alpha 0), with sharedBlur=true.
The operator confirmed the contrast pattern visible through menu backgrounds and
blur working in both cases; opaque borders behaved as expected. Thus the earlier
solid-looking panels do not establish absent alpha/blur. The inspection did not
prove why the first backdrop made these effects hard to see.

Protocol evidence independently distinguishes the cases: P created a background
effect object; Q did not. The Q Bar used the exact `magi-audit-bar` namespace.
Original MAGI config/IPC, runtime values and workspace were restored; protected
files were unchanged and trial rules disabled. No timing loops were run.

Rounded-edge pixelation was observed in P. The operator described Q as the same
overall behavior, but no pixel-level comparison or cause was established. Do not
attribute it to the Lua candidate, change radii, or lower blur quality on this
evidence. Layer performance comparison remains pending via `control.py --layers`;
Ghostty stays on the responsive compositor-only path for both cases. The result
will determine whether a MAGI ownership change is justified beyond the already
supported Ghostty fix. Native launch integration still needs separate acceptance.

## Trial token and absent-rule recovery correction — 2026-11-05

`layers-5ia6zmf_` recorded one responsive P baseline. The temporary directory suffix
contained `_`, which the helper's token validator incorrectly rejected after P.
No Lua rule-creation command was sent and MAGI was not stopped or redirected.
However, the old helper had already journaled `rules_created=true`, so cleanup
incorrectly dereferenced an absent global. This is a helper failure, not a layer
performance or compositor failure. The original report separately verifies blur,
Ghostty exclusion and workspace restored, with protected files unchanged. The
production MAGI link is unchanged. An untouched pre-correction report is preserved.

The helper now accepts the safe underscore character, prevalidates rule commands
before runtime changes, and separately journals an attempt versus confirmed
creation. Cleanup accepts absent/partially created handles, is idempotent, and
rejects foreign tokens before touching any rules. Tests execute generated Lua
for the exact failing token, partial creation and foreign ownership, and cover
recovery of old reports. All 30 helper tests pass; `git diff --check` passes.
Native cleanup re-verification and the remaining layer timing comparison still
require the operator terminal. Production code and saved Settings are unchanged.

## Completed MAGI layer comparison and final review checkpoint — 2026-11-05

`layers-f3uky85y` completed P/Q/Q/Q/P/P with identical blur settings and Ghostty
on its compositor-only path. The operator accepted both paths' appearance and
responsiveness; menus/readability/padding/clicks were reported good. Median Intel
render busy: P Hyprland 59.860%, Ghostty 1.724%, Quickshell 0.292%; Q Hyprland
63.844%, Ghostty 1.736%, Quickshell 0.301%. Q increased compositor engine time by
3.984 percentage points (approximately 6.7% relative), without a reported
responsiveness benefit. Three samples each are not a frame-latency benchmark.

Decision: retain MAGI's precisely bounded client regions. The Lua layer approach
is valid but does not improve this workload enough to justify additional policy
and toggle ownership. Do not permanently install the audit namespaces or rules.
Restoration verified original MAGI config/IPC, runtime blur and exclusion values,
workspace, and protected files. Trial rules were disabled. No saved Settings,
BIOS, GPU, PRIME or monitor settings were changed. Existing corner pixelation is
recorded separately; this comparison does not establish its cause.

Final production proposal:

- Ghostty supplies background alpha; generated output omits GTK blur CSS and sets
  `background-blur=false`. Terminal foreground/cell opacity behavior is retained.
- The Ghostty-only launch wrapper applies the GTK protocol opt-out before process
  startup. The desktop entry uses Exec rather than bypassing it via D-Bus startup,
  retaining Ghostty's own single-instance behavior. Direct absolute-binary/D-Bus
  launches bypass the wrapper; descendant processes inherit its environment.
- MAGI retains its existing outer-surface alpha/region behavior. No Lua layer-rule,
  geometry, radius, animation or quality change is proposed for production.
- The audited stable 0.56/0.57 effects executor retains error, instance, generation
  and readback guards. Unknown/future/malformed versions fail closed. The separate
  border adapter is unchanged.
- Static Lua remains size 8/four passes; opted-in saved global amount 10 now becomes
  applicable on 0.57 through the existing runtime setter. No reload/full reset.
  Test quality was size 10/four passes with optimizations enabled throughout.
- Generated palette/appearance payloads stay in XDG stores; tracked Ghostty files
  are stable bootstrap/launch policy. Schema remains 22.

Private native acceptance proves the underlying Ghostty path and preserves blur
quality. The normal MAGI desktop-launch path was installed and exercised in the
production session on 2026-11-05, including final theme-switch acceptance. Existing
Ghostty processes were completely stopped before normal launcher use; ordinary
reload cannot change GTK protocol negotiation. That one-time deployment gate passed.

Experiment helpers and their 30 checks are preserved in the durable audit store,
not included as permanent production test tooling. The focused launcher regression
is registered with the canonical runner. Full regression plus affected reruns are
reconciled separately; original failure logs are retained. No schema bump, commit or push. The reviewed source is now deployed as an
unstaged production diff; normal use must not change that diff.

Final focused checks: phase12g/run, phase12h/run, theme-orchestrator/run,
theme-orchestrator/bootstrap and ghostty-launch all PASS. Reconciled current
99-suite coverage remains 95 PASS, 4 ENVIRONMENT, 0 outstanding FAIL/UNKNOWN.
The full run's single obsolete CSS assertion was corrected and rerun; this is
not represented as a separate clean full-run execution.


### Deployment acceptance — 2026-11-05

The operator launched a fresh Ghostty through MAGI. Native PID/environment evidence
confirmed `GDK_WAYLAND_DISABLE=ext_background_effect_manager_v1`; effective config
reported 0.79 alpha with no CSS/native blur request. Typing, workspace transitions,
workspace pills, Ghostty/MAGI blur and appearance controls were accepted. Settings,
normal animations and monitor geometry were preserved.

The first theme acceptance attempt did not pass: MAGI changed to One Light but Ghostty remained Nord.
The stored report identifies a publication-barrier failure: Hyprland's enrollment
still recorded its original config identity, while the current config resolves via
the earlier monitor trial. No external palette was published. A stale prior Live
receipt and a border comparison against the old payload were insufficient checks.
The native gate now requires no enabled-target errors and verifies the selected
palette in both published metadata and payloads before accepting runtime borders.
An explicit, backed-up enrollment-metadata repair was applied; monitor/config bytes,
links and routing remain unchanged. It is not an automatic compatibility bypass.

A second, independent integration defect was found in reload discovery: PATH now
resolves Ghostty to MAGI's launcher wrapper, but `/proc/PID/exe` identifies the real
binary. The reload executor recognizes that installed wrapper and matches its audited
`/usr/bin/ghostty` destination. Existing UID, unique D-Bus owner, action signature
and owner-race checks remain intact; unrecognized wrappers are not assumed equivalent.
Focused tests cover wrapper discovery and retain all owner-validation tests.

The final native gate passed on 2026-11-05. The operator confirmed Ghostty and MAGI
both changed to One Light, opacity/blur persisted, and all responsiveness and Settings
checks passed. Nord was restored. Hyprland reports Live with exact canonical border
readback; Ghostty reports Reload requested with its existing GApplication action
accepted, corroborated by the operator's visible colour-change check. Ghostty has no
loaded-generation introspection, so the report does not claim such a readback.

Final runtime policy: native background alpha 0.79, blur size 10, four passes, normal
workspace animations and the original MAGI regions. Settings bytes, monitor geometry,
protected config files and the intentional deployment Git diff were unchanged by
normal use. Native evidence is retained outside Git in deployment-2_jjtzhr/native.json.
The follow-up correction passed all five affected suites, including the added wrapper
reload tests; nine gate/repair safety checks passed. Schema remains 22. Commit/push
remain unapproved and were not performed.
