# Phase 10C.2A — Display Manager (non-authoritative)

## Pre-implementation audit, 2026-10-22

Baseline: 4f5ffbc692bc6b62172de76f3eb26c9c81b13b13, origin/main divergence 0 0.
Work is isolated because the production QML tree auto-reloads. Hyprmon remains
production authority; no production monitor commands or startup edits are allowed.

Installed: Hyprland 0.56.2-4, Quickshell 0.3.1-1. `/usr/share/hypr/stubs/hl.meta.lua`
HL.MonitorSpec exposes output, disabled, mode, scale, position, transform, mirror.
`hyprctl --help` documents `eval <code>` and `monitors all` for inactive outputs.
A read-only monitors query was denied by the sandbox socket; no operator RPC or
physical HDMI manipulation is necessary. Current effective compositor state is
therefore not claimed as observed evidence in this pass.

Installed /usr/bin/hyprmon is a Go binary v0.0.17, revision
3131caffc371695b0acac9e61bc23de3910e4128 (go version -m). Local profile evidence:
Home Office Docked disables eDP-1 (3840×2160@60, scale2,0,0), enables Samsung
Odyssey G81SF HDMI-A-1 (3840×2160@239.995, scale1.5,1920,32). Norm t15g Screen
has only eDP-1 enabled at 4K60 scale2. All saved transforms0, no mirrors; advanced
color/VRR fields are default. UI-only drag offsets are also serialized.
Hyprland starts `hyprmon` and loads `require("hyprmon")` after its initial monitor
rules. The protected generated sidecar currently contains the laptop-only rule.
Saved profiles are not evidence of current connected state. No explicit auto-match
or hotplug daemon rule was found in these local files. Startup restores the sidecar;
manual TUI/profile invocation selects profiles. Installed-source retrieval failed;
exact automatic matching/hotplug behavior remains an audit gap, not an assumption.

## Primary references

Inspected 2026-10-22; local versioned stubs take precedence over moving docs:
- https://wiki.hypr.land/configuring/core/monitors/ — hl.monitor fields,
  connector/description selectors, disabled, fractional/auto scale, transforms0–7.
- https://wiki.hypr.land/configuring/core/monitors/modes/ — real availableModes,
  preferred/highres/highrr/maxwidth tokens and mirror aspect-ratio stretching.
- https://wiki.hypr.land/configuring/core/monitors/positioning/ — scaled/transformed
  logical positioning, negative positions and prohibition of non-mirror overlap.
- https://quickshell.org/docs/v0.3.0/types/Quickshell/ShellScreen/ — name, model,
  serialNumber and logical geometry; removed screen objects become dangling.
- https://github.com/erans/hyprmon and its main README — manual profiles, visual
  editing, mirror validation, previous-state revert/backups, Lua sidecar storage.
  Moving upstream documentation is not proof of every installed v0.0.17 feature.
  No upstream implementation code is copied (upstream Apache-2.0).

Required parity includes the two actual profiles, mode/refresh/scale/position,
enable/disable, mirror/rotation, identity across ports, hotplug, startup restore
and recoverability. HDR/VRR/color fields are reported by import but not discarded
silently or implemented opportunistically. The old tool advertises manual revert;
a backend watchdog surviving the UI must be proven before retirement.

## Architecture decision before implementation

Separate observed discovery, editable proposed layout, known-good runtime snapshot
and versioned saved profile. Runtime identity uses connector names per discovery
lifetime; profiles prefer make/model/serial, then unique description, then explicit
connector fallback. Ambiguity never auto-selects a profile. No universal primary
monitor is invented; Phase10B main-bar selection remains independent.

Python owns validation, narrow Lua command planning (never execution), profiles,
synthetic state and transactions. Settings communicates by structured JSON with
one preview service; QML never runs hyprctl. The only real backend operation is a
fixed read-only monitors-all query. Its apply method always refuses; there is no
environment flag to unlock it. Main Settings remains schema15. Profiles live in a
separate version1 directory under XDG_STATE_HOME/magi/display-preview/profiles.
The preview label and Apply preview make the boundary explicit.

A detached, narrowly scoped Python watchdog owns a synthetic transaction journal
and deadline independently of the QML host. It can restore a file-backed fake
layout after UI exit/crash; tokens prevent stale Keep/Revert. Actual compositor
rollback, daemon deployment and fresh-session ownership are Phase10C.2B work.

## Implemented groundwork

The Displays page uses production Settings foundations and theme, with a proportional
logical-coordinate canvas, output selector, enabled checkbox, real resolution/refresh
pairs, scale, eight transform values, and root-target mirroring. Drag performs one
integer-coordinate update on drop; snap threshold is 24 logical pixels with deterministic
tie breaking. The canvas captures its scale at press, avoiding conversion drift while
moving. Arrow keys move 32 logical pixels; labeled left/right/above/below buttons are
the non-drag alternative. Negative positions are valid. Non-mirror overlap blocks the
proposed move or Apply, rather than silently changing another display's position.
Scale and rotation edits may temporarily overlap; the diagnostic remains until the
user repositions. Disable-all and disabling a mirror source are rejected. Selection
moves to an enabled root after disabling the selected output.

Mode values are actual catalog entries, represented as physical width/height and
integer millihertz; controls never manufacture a resolution/refresh cross product.
Position and canvas dimensions are logical; 4K/2 = 1920×1080 and 4K/1.5 = 2560×1440.
Rotation swaps logical dimensions for odd transforms. Scale UI offers 1,1.25,1.5,
1.75,2,2.5,3; the model retains finite observed numeric scales in [1,3]. Those are
bounded proposal choices, not a claim every monitor/compositor accepts every fraction.
Phase2B must check compositor effective scale/readback and reject or mark deviations.
Auto scale and preferred/highres/highrr/maxwidth are audited but deliberately not
exposed: automatic geometry needs compositor readback before the canvas can represent
it accurately. If current mode is unreported, discovery marks modeReview and uses the
first available catalog entry for review, without calling it EDID-preferred. No custom
modelines are accepted. Missing saved modes choose the newly observed/current entry
and require explicit review before Apply preview; profile success is marked degraded.

Runtime identity is connector name for one discovery lifetime, never index or geometry.
Profile matching prefers make/model/serial, then description, then connector fallback.
Duplicates are ambiguous and block profile save/matching. An identical no-serial pair
cannot be distinguished reliably; no connector-order heuristic pretends otherwise.
Port changes with a unique stable identity restore edits and remap mirror targets.
A different physical external starts from observed state. Missing outputs leave no
object references; unsaved edits on surviving uniquely identified outputs remain.
Lost mirror targets are cleared with a review warning. Hotplug during a simulated
confirmation first reverts the transaction, then reconciles the new observed set.
No hotplug event ever applies a physical layout in this phase.

The Python session holds observed, proposed, last-known-good and profiles separately.
A move changes only proposed state. Revert edits copies observed. Keep preview makes
the simulated candidate known-good. The file backend stores complete layout snapshots;
apply-failure injection leaves previous state unchanged. Pending transactions reject
competing edits, and stale tokens cannot Keep or Revert a newer transaction. Timeout
wins over a late Keep. Revert failure enters recovery-required, blocks another Apply
and retains the previous snapshot with a diagnostic. No recursive recovery loop exists.

### External transaction authority

Each simulated transaction persists its previous/candidate state, random confirmation
token and monotonic deadline before writing the candidate backend state. A detached
Python watchdog starts before that write; a writer flock serializes Keep/revert/timeout.
A 15-second timeout is owned by that process, not QML. Closing the input channel reverts;
killing the host process also leaves the independent watchdog able to revert at deadline.
A test actually kills a separate transaction-host process and verifies restoration.
A reaper thread avoids child zombies during ordinary operation. UI switches do not
stop the singleton preview process or reset the deadline.

This is a real external watchdog over a **file-only synthetic backend**. It is not a
production daemon deployment or proof of hardware recovery. Killing the watchdog or
rebooting can require explicit journal recovery; the physical backend must add persistent
service ownership/startup recovery and compositor readback before activation. The future
live guardian must own both write and revert; QML must never obtain a raw apply capability.

### Planner and production gate

The planner produces an argv array for `/usr/bin/hyprctl eval` with validated `hl.monitor`
statements. Connector names are restricted, modes come from the validated catalog,
positions/transforms/scales are numeric, and fixed field names are encoded without a
shell. Enabled roots precede mirrors; disabled rules are last. This is a desired-rule
plan, not a compositor-atomic commit. Intermediate overlap and multi-rule failure/readback
are explicit physical-acceptance concerns; no claim of atomic Hyprland application is made.

HyprlandBackend.apply always raises. There is no enable flag, production writer, startup
hook, daemon installation or hidden UI bypass. Read connected displays invokes only the
fixed read-only `hyprctl -j monitors all`. The preview process has no route to execute a
planned argv. Apply preview affects only a private temporary simulated backend directory.
A concise Preview only label and physical-authority text are visible in the page.

### Profiles and importer

Version1 profile files reside in XDG_STATE_HOME/magi/display-preview/profiles, outside
Stow and the main Settings blob. UUID filenames are generated internally and validated;
path traversal and symlink profiles are rejected. JSON is sorted/stable, private temp
writes are fsynced and atomically renamed with a directory fsync. Filename and internal
ID must agree. Corrupt/future/malformed/ambiguous profiles produce diagnostics rather
than disappearing silently. Save as, list, preview, rename and delete operate only in
that preview directory. Profiles exclude transient focus/discovery flags.

Exact, subset and manual matching are modeled; ties return Ask, never auto-apply.
Extra/missing displays or mode fallback may mark a preview degraded. Future recommendation:
Ask by default, optional exact-only auto-apply after explicit activation/physical acceptance.
No profile is applied automatically now.

Hyprmon import reads fixed user profile files without changing them. It returns converted
identity/enabled/mode/scale/position/transform/mirror fields plus unsupported values and
warnings; it does not save a MAGI profile automatically. Copies of both actual profiles
are test fixtures. The laptop profile converts cleanly. Docked selects 239.995 Hz while
its saved catalog says 240 Hz, so conversion is blocked for review rather than inventing
a mode. Advanced BitDepth/ColorMode/SDR/VRR values are retained in the report as unsupported
(the actual fixtures use defaults). UI drag offsets are intentionally not configuration.
[Conversion report](previews/phase10c2a/hyprmon-conversion.json).

Upstream hardware_id.go (main, inspected 2026-10-22):
https://raw.githubusercontent.com/erans/hyprmon/main/hardware_id.go
builds make/model/serial IDs (make/model without serial), disambiguates duplicate IDs
by sorted connector suffix, resolves profiles by hardware ID and falls back to name
for legacy profiles. Missing matches are skipped. This explains compatibility risks;
MAGI instead surfaces duplicate ambiguity. This moving source is not an installed
revision guarantee; pinned-source fetch was unavailable.

### Phase 10B and Settings boundaries

No production BarFleet, SurfaceOrigin, workspace backend or main-output rule changes.
The display preview never publishes synthetic outputs to the real bar. The isolated
integration harness projects enabled fixtures to Phase10B screen objects and exercises
external removal/recreation, popup cleanup, focused shortcut fallback, reservation and
monitor-local workspace highlight. Existing full Phase10B regression remains required.
Mirrored physical output visibility is a Phase10C.2B observation, not guessed here.
Main-bar output, focused output, internal panel and profile identity are separate concepts.

Main Settings stays schema15: no global display preferences need persistence yet.
The new singleton is lazy-started by visiting Displays; navigation is added without
reorganizing unrelated pages. Theme, Power & Idle, lock, profiles outside the preview
namespace, Hyprmon and all protected live state remain untouched.

## Phase 10C.2B physical acceptance ledger — all deferred

No hardware manipulation is needed to review or commit non-authoritative groundwork.
A later explicit activation gate must address the following before replacing Hyprmon:

| Gate | Required evidence | Status |
| --- | --- | --- |
| Discovery | Laptop, external and disabled outputs; actual JSON normalization and identity | Deferred |
| Modes | Resolution/refresh changes and effective readback; unavailable modes rejected | Deferred |
| Scale/rotation | Integer/fractional geometry, transform, windows and pointer usability | Deferred |
| Position | Left/right/above/below, negative offsets, multi-rule intermediate overlap | Deferred |
| Enable/disable | Last-root protection and safe workspace migration | Deferred |
| Mirror | Target removal, aspect ratios, root validation, bars and surface behavior | Deferred |
| Transaction | Keep, manual Revert, timeout, UI crash, guardian failure and readback mismatch | Deferred |
| Hotplug | Remove/reconnect during edits and confirmation, dock/two externals, changed connectors | Deferred |
| Profiles | Laptop/docked restore, ambiguous hardware, degraded modes, current advanced settings | Deferred |
| Startup | Fresh login, reboot if necessary, guardian journal recovery, one authority | Deferred |
| Retirement | Required parity, physical/hotplug/profile/safe-revert/startup passes; documented rollback | Deferred |

Hyprmon startup, generated include, profiles and boot restoration stay in place until
all required gates pass and the operator explicitly approves retirement. Preserve its
known-good fallback before installing any future production display service. Fingerprint,
visual/aesthetic work, application polish, lock customization and greeter are outside
this implementation.

## Initial-pass validation and delivery

The implementation remains in an isolated detached worktree at
`/tmp/magi10c2a-20261022-190952/worktree`, based on the verified committed baseline.
The watched main source has not been edited, and no operator-run status helper was
created. One attempted direct read-only monitors query failed at the sandbox IPC
boundary; physical discovery remains optional evidence for 10C.2B.

Passing coverage: 21 Python model/profile/planner/transaction cases; real Qt pointer
drag with exact coordinate conversion, selection, Cancel, profile and degraded UI,
confirmation/Keep; detached host-kill watchdog; simulated hotplug projected through
Phase10B bar/surface cleanup, shortcut fallback and workspace highlighting. Settings
schema/persistence and production page presentation, existing Phase10C.1 and full
Phase10B suites pass. Only known offscreen IPC/platform warnings are filtered; no
unrelated assertions were weakened. `git diff --check` passes.

Six production-component software previews are included:
[laptop](previews/phase10c2a/laptop.png),
[dual](previews/phase10c2a/dual.png),
[external controls](previews/phase10c2a/external.png),
[profiles](previews/phase10c2a/profiles.png),
[confirmation](previews/phase10c2a/confirmation.png),
[missing display](previews/phase10c2a/missing.png).
They are synthetic output representations using real Settings components, not
physical monitor acceptance. Some captures intentionally scroll to the lower controls.

Exact inventory: 38 paths, 7 modified, 31 added, zero deleted.
All 14 protected dirty file/symlink entries match the preflight snapshot.
No index changes, commit or push. Runtime preview profile/transaction files and test
logs live outside Git; only the deliberate fixtures, six PNGs and conversion report
are source artifacts.

```text
M linux/magi/.config/quickshell/magi/components/settings/SettingsContent.qml
M linux/magi/.config/quickshell/magi/services/qmldir
M linux/magi/README.md
M linux/magi/docs/README.md
M linux/magi/docs/architecture.md
M linux/magi/docs/decisions.md
M linux/magi/tests/settings/presentation.qml
A linux/magi/.config/quickshell/magi/components/settings/DisplayCanvas.qml
A linux/magi/.config/quickshell/magi/components/settings/pages/DisplaysPage.qml
A linux/magi/.config/quickshell/magi/displays/backend.py
A linux/magi/.config/quickshell/magi/displays/fixtures.json
A linux/magi/.config/quickshell/magi/displays/model.py
A linux/magi/.config/quickshell/magi/displays/planner.py
A linux/magi/.config/quickshell/magi/displays/profiles.py
A linux/magi/.config/quickshell/magi/displays/transaction.py
A linux/magi/.config/quickshell/magi/services/Displays.qml
A linux/magi/docs/design/phase10c2-display-manager.md
A linux/magi/docs/design/previews/phase10c2a/confirmation.png
A linux/magi/docs/design/previews/phase10c2a/dual.png
A linux/magi/docs/design/previews/phase10c2a/external.png
A linux/magi/docs/design/previews/phase10c2a/hyprmon-conversion.json
A linux/magi/docs/design/previews/phase10c2a/laptop.png
A linux/magi/docs/design/previews/phase10c2a/missing.png
A linux/magi/docs/design/previews/phase10c2a/profiles.png
A linux/magi/tests/displays/bar-interaction.qml
A linux/magi/tests/displays/fixtures/hotplug-unsaved.json
A linux/magi/tests/displays/fixtures/hyprmon-Home-Office-Docked.json
A linux/magi/tests/displays/fixtures/hyprmon-Norm-t15g-Screen.json
A linux/magi/tests/displays/fixtures/invalid-zero-enabled.json
A linux/magi/tests/displays/fixtures/layout-dual.json
A linux/magi/tests/displays/fixtures/layout-laptop.json
A linux/magi/tests/displays/fixtures/layout-mirror.json
A linux/magi/tests/displays/fixtures/layout-portrait.json
A linux/magi/tests/displays/fixtures/layout-three.json
A linux/magi/tests/displays/fixtures/missing-saved-monitor.json
A linux/magi/tests/displays/model.py
A linux/magi/tests/displays/presentation.qml
A linux/magi/tests/displays/run.py
```

Operator review decisions: accept the preview-only UI/model and conservative Ask
profile policy; later authorize watched-source integration separately. No choice
is needed to unblock synthetic work. Production guardian deployment, real command
application/readback, compositor-specific scale behavior and true fresh-session
ownership remain 10C.2B activation gates. Hyprmon stays authoritative.


## Controlled integration — 2026-10-22

The operator accepted the isolated architecture for integration. Exactly the 38
reviewed paths were copied into the main checkout after a fresh protected-state
snapshot and operator confirmation that Settings was saved. Automatic reload at
19:41:08 completed successfully; MAGI retained PID 1573, with no new QML warnings
or errors in the log segment after the snapshot. All 14 protected file/symlink
entries remain unchanged, including settings.json and Hyprmon startup/profiles.
The earlier isolated-only delivery notes above describe the initial pass.

Phase 10C.2A does NOT replace Hyprmon. Static execution-path review confirms that
HyprlandBackend.read invokes only `hyprctl -j monitors all`, the planner returns
an argv value without executing it, and HyprlandBackend.apply always refuses.
The only active mutation target is the file-backed synthetic transaction backend.
No production hotplug subscription or automatic profile application was added.
Hyprmon remains installed and its startup source remains byte-identical.

Runtime profiles remain under `$XDG_STATE_HOME/magi/display-preview/profiles`
(default `~/.local/state/magi/display-preview/profiles`), using version 1, validated
32-hex IDs, symlink rejection and atomic writes. They are not source artifacts.
The watchdog is not deployed as a compositor authority; real compositor rollback,
readback and physical acceptance remain Phase 10C.2B requirements.

The operator accepted the integrated framework/UI. This is visual and synthetic
acceptance only: Phase 10C.2B physical acceptance remains deferred. The exact
38-path source set is authorized for staging, commit and normal push.


Final integrated regression: 21 model/profile/planner/transaction tests, display
Qt presentation and pointer-drag tests, synthetic Phase 10B bar interaction,
Settings schema/persistence/presentation, Phase 10C.1 and full Phase 10B all pass.
`git diff --check` passes. Final source inventory remains 38 paths: 31 added,
7 modified, zero deleted. All 14 protected entries match the integration snapshot.
No production display operation or Hyprmon configuration change was performed.
