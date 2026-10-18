# MAGI Lock Screen — Phase 6 accepted multi-output checkpoint

2026-10-18. Baseline `1f2d181ef13bf5c06b7b17e1b5f29305e7558e50`,
`magi: harden lock authentication failures`; HEAD/origin/main comparison was `0 0`.
**Phase 6 accepted on 2026-10-18:** synthetic architecture validation, the second
pre-armed headless integration and Physical Tests 1–4 passed, including operator
visual acceptance. The first headless attempt remains recorded as incomplete.
The operator has authorized finalization, commit and push of Phase 6 only.
Hyprlock remains production/fallback. Earlier pending-acceptance/no-commit language
below records the historical state of each test, not the current disposition.

There is one compositor session lock, canonical native lock state, auth controller
and credential buffer, with at most one PAM worker. Each output owns a separate
surface/presentation lifetime. Output events never authorize unlock. Connector
names are metadata; registry identity plus lifetime protects replacements. QML is
presentation-only and receives no raw credentials. Only valid current-generation
PAM Success authorizes normal global unlock.

## Remaining gates — not yet proven / future work

- Suspend, resume and lock-before-suspend integration.
- Hypridle production migration and compositor restart/failure recovery.
- Broader keyboard layouts and real MFA/fingerprint flows.
- Production PAM/account-policy decisions and packaged/install paths.
- Production routing, Hyprlock retirement and final MAGI lock-screen visual design.

None of these gates is started or authorized by this checkpoint. Phase 7 remains
out of scope. Physical acceptance applies to the tested hardware/compositor;
forced stale-callback rejection and zero-output behaviour retain synthetic coverage.

## Architecture and audit

One native owner, one Wayland connection, one ext_session_lock_v1, one Controller,
one AuthController, one NativeInput, one Credential, and at most one Rust worker.
QML receives only count/input-active/Caps/status and output/lock/proof labels.
Only current-generation Success satisfying the existing complete IPC/child-reap
contract can authorize one global unlock. Output callbacks have no auth authority.
The Rust worker, IPC semantics, PAM policy and production routes are unchanged.

The Phase 2–5 implementation already keyed outputs by registry global, created
surfaces during Acquiring and Locked, handled multiple/repeated configures,
coalesced busy-buffer work, supported zero outputs, and failed secure on allocation
failure. It did not depend on array order, first output, connector name or 16:9.
Concrete gaps fixed:

- Keyboard leave and removal of the focused surface called the generic input-loss
  path, cancelling global auth and clearing editing input. Ordinary output focus
  loss now disables native input and resets held-key/compose/modifier state while
  preserving the global credential/attempt/retry policy. Enter requires valid
  native focus and fresh modifiers before key processing resumes.
- A first QML fallback on *any* output cancelled global auth. Removed the
  presentation-to-auth cancellation API. A failed output now renders native
  fallback with the same safe global status, independently of healthy outputs.
- Deferred buffer-release work carried only a registry ID. A queued old release
  could retry drawing a new instance after ID reuse. Controller lifetimes now
  monotonically identify instances; native configure/release callbacks carry the
  lifetime. Old callbacks cannot affect a replacement instance.
- Lifecycle was implicit in booleans. Explicit lifecycle states now expose the
  per-output transition, separately from global lock/auth state.

These deliberately supersede Phase 1's proposed focus-transfer cancellation and
Phase 4/5's blanket focus/fallback cancellation policy. Earlier checkpoints remain
historical and unchanged. Security guarantees remain: no secret in QML; only valid
Success unlocks; actual auth failures clear secrets, invalidate authorization,
reap the worker and enforce retry delay. Explicit Escape/cancel, keyboard/seat loss,
keymap replacement and global teardown still cancel. A repeated cancelling input
loss also works after an output transition already suspended input.

Ordinary wl_keyboard leave cannot reliably distinguish monitor transfer from all
other compositor focus changes. All such leaves preserve auth while blocking keys;
seat/keymap invalidation uses the separate cancelling path. With zero outputs,
editing bytes remain in the one native buffer until explicit cancellation,
auth submission/completion or teardown. No extra inactivity policy is introduced.
This is a deliberate Phase 6 policy change, not a claim that old focus-loss tests
proved preservation.

## Output ownership and lifecycle

| Record | Owner / meaning |
| --- | --- |
| Registry numeric global and wl_output proxy | NativeOutput; authoritative connection-local identity |
| Lifetime | Controller monotonically allocated u64, copied into native surface/buffer records; never an auth generation |
| Connector label, scale, transform | NativeOutput metadata only; connector name is not an identity or authorization input |
| wl_surface and ext_session_lock_surface_v1 | NativeOutput; unique role per active output, assigned before attach/commit |
| Configure serial, logical width/height | Controller pending/committed Configure; serials opaque, including zero/wrap |
| Lifecycle, failure, fallback, dirty | Controller Output; independent of global session/auth state |
| QML presentation | Ephemeral per frame; offscreen scene destroyed before committing native pixels |
| Fallback | Native opaque QPainter status in that output's pixels; compositor fallback if no usable buffer/surface |
| Buffers/callbacks | Native owner; per-output ID + lifetime; busy buffers never repainted |

`Discovered → SurfaceRequested → AwaitingConfigure → Configured → Presented`.
SurfaceRequested is synchronous. Configured means newest configure awaiting a
successful submission; Deferred stays there. Reconfigure returns Presented to
Configured. Presented includes native fallback, distinguished by its fallback
flag; it means client commit, **not proof of hardware scanout**. Unrecoverable
creation/geometry/buffer failure enters PresentationFailed. Removal enters Removed
and erases the record immediately; no growing tombstone registry exists.

Add while Acquiring/Locked binds wl_output, registers a fresh instance, creates
wl_surface and the lock role immediately, waits for configure, prepares pixels,
acks the selected serial, attaches a non-null buffer and commits. No new lock,
auth generation, worker or unlock/relock cycle occurs. Lock confirmation may precede
or follow output configures. Adds during Unlocking do not create roles; late
configure/release/refresh work cannot commit or authorize another unlock.

Removal destroys only the output's lock role, wl_surface, buffers/mappings and
wl_output proxy. A pending callback carries a stale lifetime and is ignored;
libwayland proxy destruction suppresses delivery to destroyed protocol objects.
Qt presentation objects already died at frame completion. The focused surface
pointer is cleared and input suspended; other output records remain usable.
Zero outputs retains Locked/auth state, and a later output starts a fresh lifetime.
An actual current Success can still authorize the one session unlock at zero outputs.

Policy A: every output displays identical safe auth presentation. There is no
preferred/full-auth owner to reassign and no per-output keyboard handler or password
buffer. Hyprland chooses keyboard focus; no focus IPC is added. Native fallback
continues displaying status even if every QML scene fails. Failed/WorkerError/
Unsupported/Cancelled and retry delay remain global; topology cannot reset them.

## Protocol and installed compositor evidence

Inspected 2026-10-18: installed wayland-protocols **1.49**, Wayland **1.26.0**,
Hyprland package **0.56.2-4**, Qt base **6.11.2-3** / declarative **6.11.2-2**.
Sources were inspected for semantics, with no upstream implementation copied.
The installed XML retains its permissive copyright in generated build output.
The package version is not a fresh verification of the running compositor hash.

- Installed `/usr/share/wayland-protocols/staging/ext-session-lock/ext-session-lock-v1.xml`
  and [upstream protocol](https://gitlab.freedesktop.org/wayland/wayland-protocols/-/blob/1.49/staging/ext-session-lock/ext-session-lock-v1.xml):
  get_lock_surface expects surfaces for existing and newly advertised outputs.
  No numeric hotplug deadline is specified; create immediately. Before client
  rendering, compositor lock protection remains responsible for opaque coverage.
  Initial configure must be acked before first commit; null buffers are forbidden.
  Configure dimensions are exact surface-local dimensions. Latest pending configure
  may supersede earlier ones; never ack a consumed serial. Remove the lock surface
  when its wl_output disappears. Destroying a surface on an active locked output
  requires compositor solid coverage, not session unlock. Client death cannot unlock.
- [Hyprland v0.56.2 protocol implementation](https://github.com/hyprwm/Hyprland/blob/v0.56.2/src/protocols/SessionLock.cpp),
  CSessionLockSurface constructor/sendConfigure/onGetLockSurface: initial configure
  and monitor mode-change configure use monitor logical size; removed monitor
  references are checked. A racing request for an already-gone output may not yield
  a surface/configure. Client removal still cleans its resources without unlocking.
  The implementation checks first ack and null buffers but is less strict than XML
  about serial/dimension validation. MAGI follows the XML rather than relying on
  this leniency.
- [Hyprland v0.56.2 manager](https://github.com/hyprwm/Hyprland/blob/v0.56.2/src/managers/SessionLockManager.cpp),
  onNewSessionLock/onLockscreenRenderedOnMonitor/removeSessionLockSurface: one lock,
  per-monitor surfaces, first-lock rendered-monitor tracking, a five-second fallback
  timer, immediate confirmation with no active monitors, and focus transfer to a
  remaining mapped surface on removal. These explain the focus-loss interaction;
  there is no need for a second client/auth controller.
- [Hyprland v0.56.2 renderer](https://github.com/hyprwm/Hyprland/blob/v0.56.2/src/render/Renderer.cpp),
  renderAllClientsForWorkspace/renderLockscreen/renderSessionLockPrimer: after
  clientLocked, workspace rendering is suppressed and an opaque primer covers
  monitors without client graphics. This applies to new monitors via the global
  lock condition. **Exception:** session_lock_xray bypasses those protections;
  above-lock layers are also compositor policy. Effective policy must be checked
  before native acceptance. Source does not prove absence of physical scanout flashes.

Factual refinement: protocol timing means “as advertised”, not “after locked”.
Scale/rotation do not authorize guessing physical dimensions. “Presented” is a
client commit marker; only compositor confirmation establishes initial lock readiness.
Compositor fallback after a surface failure is a requirement, not a guarantee MAGI
can enforce against a compositor/driver defect.

## Configure, scale and resource policy

Continue exact compositor-provided logical width/height, QImage DPR 1, XRGB8888,
wl_surface buffer scale 1 and NORMAL buffer transform. The compositor maps these
onto each output independently. The known 3840×2160 scale-2 laptop remains a
1920×1080 logical buffer; another output can have a different scale/rotation.
wl_output scale/transform are diagnostic metadata, not rendering dimensions.
Fractional-scale sharpness/native-resolution buffers are deferred, not coverage.
Portrait, wide, 1×1, resizing and repeated same-size configures are tested.

Keep 64-output, 16384-per-axis, 64 MiB/frame and 256 MiB outstanding-buffer limits;
Qt temporary allocations are additional. Two busy buffers/output coalesce pending
configures until release. Invalid geometry or allocation failure destroys stale
client surface content and relies on compositor coverage; no null commit, duplicate
role recreation, automatic worker restart or unauthenticated unlock occurs.
Per-output QML failure first tries native opaque status rendering. If allocation
or the native process itself fails, availability relies on compositor/TTY recovery.

## Automated evidence and limits

New `output_synthetic` runs **41 scenarios** with the production Controller,
AuthController, NativeInput, real offscreen QML/QPainter and the existing Rust
protocol fixture; Wayland operations are a fake Backend. Both builds run it.

| Group | Scenarios / checks |
| --- | --- |
| Lifecycle (6) | Discovery/configure before confirmation; one/remove/re-add; two/three outputs and reordered IDs; duplicate/unknown add/remove/configure; old lifetime configure/release rejection; last removal/re-add; fresh global for same connector concept |
| Geometry/failures (11) | Six logical geometries including initial 1920×1080, resize/same-size, portrait, ultrawide and 1×1; fallback/deferred/buffer failure isolated to B; surface creation failure; invalid and post-failure configure |
| Real presentation (9) | Healthy A + invalid-QML B during Editing, Authenticating, Failed, WorkerError, Unsupported, Cancelled; opaque fallback and no global state/credential mutation; three simultaneous synthetic scale-1/2/3 and rotated logical outputs |
| Native input (2) | Editing survives focus/output removal; no keys while unfocused or without fresh modifiers; active worker survives 2→0→1; explicit seat/keymap-style cancellation still clears after suspension |
| Success orderings (5) | Add just before Success; remove just before Success; configure on completion; deferred presentation released after Success; QML failure during attempt; all require exactly one unlock, same generation/PID, no second submit |
| Failures (8) | Failed, WorkerError, Unsupported, timeout, crash, malformed IPC, Cancelled result, explicit cancellation with delayed Success; hotplug during active/terminal/retry states; zero unlock and unchanged generation |

Existing controller suites retain serial wrap/coalescing, duplicate ack rejection,
zero-output and global failure/gating checks. Auth suites retain stale-result,
24 failure modes, cleanup/retry, synthetic secret leakage, xkb and one-worker
serialization. Old fallback-cancels-auth tests now test explicit cancellation;
real fallback preservation is covered above. Presentation boundary and binary
symbol/flag gates remain. No security-result acceptance condition was relaxed.

Default and development builds: **8/8 CTest tests each**. Rust unchanged:
**18/18 tests**, locked/offline all-target Clippy (`-D warnings`), fmt check pass.
Sandbox private socket sends initially failed; the synthetic suites were rerun
with execution permission outside the sandbox. No real PAM entry point was called;
one Rust regression starts the real worker and cancels before HelloAck/backend.
No test invokes WaylandOwner::start or acquires any compositor lock.

Mocks do not prove libwayland wire ordering, real proxy release/scanout, actual
focus reassignment or physical leakage. Mixed-scale cases synthesize compositor
logical dimensions; they do not emulate a fractional-scale compositor. QML
renders synchronously; “completes after Success” tests deferred frame delivery,
not concurrent rendering threads (none exist). These are explicit native gates.

## Headless assessment — recommended next, approval required

[Hyprland v0.56.2 HyprCtl.cpp](https://github.com/hyprwm/Hyprland/blob/v0.56.2/src/debug/HyprCtl.cpp),
`dispatchOutput`, supports `output create headless NAME` through an available
Aquamarine headless backend. It rejects an existing name, and `output remove NAME`
only removes a user-created output. Backend availability must be verified at runtime;
“no backend replied” is failure, not permission to alter configuration.

**A HEADLESS-OUTPUT TEST IS RECOMMENDED FIRST. Do not move yet.** It adds useful
registry/role/configure/ack/buffer-release evidence on the installed compositor,
which mocks cannot supply, but cannot replace physical connector/scanout acceptance.
No headless output was created or removed during Phase 6A.

Proposed intermediate procedure, **not executed and not authorized by this document**:

1. Obtain explicit approval for this one live headless-output lock test and fresh
   authenticated TTY recovery confirmation. Save work, check current monitor list,
   absence of name MAGI-6A, reviewed hashes/worker paths/build-info, xray off and no
   untrusted above-lock rules. Record protected hashes and original shell/idle PIDs.
   Do not overlap production lock/idle triggers or change their routing.
2. Start on laptop only, without authentication/PAM:

   ```bash
   /tmp/magi-lock-phase6-dev-build/magi-lock-proof --acquire-session-lock --unsafe-development-unlock-after=90
   ```

3. After COMPOSITOR CONFIRMED LOCKED, from the approved authenticated recovery TTY
   targeting the original graphical instance, run these separately and inspect
   output/configure logs before proceeding (preserve the graphical instance's
   HYPRLAND_INSTANCE_SIGNATURE/XDG_RUNTIME_DIR; do not guess another session):

   ```bash
   hyprctl output create headless MAGI-6A
   hyprctl -j monitors all
   hyprctl locked
   hyprctl output remove MAGI-6A
   hyprctl -j monitors all
   hyprctl locked
   ```

   Require one new registry lifetime/role/configure with no protocol failure,
   continued laptop coverage and locked=true before and after removal. Return to
   the graphical VT for observation; do not type an account credential.
4. Wait for the 90-second development timer, verify sync/exit; `hyprctl locked` must report **false** after recovery.
   Require zero AUTHENTICATED UNLOCK, no worker, no residual MAGI-6A, original process
   PIDs and matching protected hashes. Timer recovery is not auth acceptance.
   If creation fails, stop; no alternative backend/config changes are authorized.

The development timer cannot recover a dead/frozen owner. Use the agreed TTY
recovery plan; killing the locker does not unlock, and ending the graphical session
is a last-resort operator action with possible data loss, never automatic.

## Phase 6B — exact physical acceptance plan, not started

After the intermediate result is reviewed, explicitly request the physical milestone:
**PHYSICAL MULTI-OUTPUT ACCEPTANCE IS NOW REQUIRED. Move the laptop to the external
monitor before continuing.** That is a future gate, not today's instruction.

Before **each** test: fresh explicit individual approval and fresh confirmation
of an accessible authenticated recovery TTY; save work; check effective compositor
policy, monitor inventory, reviewed build hashes and real worker path; confirm
`--build-info` gates; record MAGI/Hypridle PIDs and protected/PAM hashes. Ensure no
other locker or idle trigger overlaps. Never change routing or disable protection.
Keep development emergency timer recovery available. No wrong-password or retry
experiment is included. If a test fails, stop and review before the next test.

For each separately approved test, use the same explicit real-PAM command, without
any failure-injection selector:

```bash
/tmp/magi-lock-phase6-dev-build/magi-lock-proof \
  --acquire-session-lock --authenticate --unsafe-development-unlock-after=90
```

1. **Two outputs before lock.** Connect external display while unlocked. Verify
   Hyprland lists internal and external outputs; record connector, mode, scale,
   transform and logical sizes. Acquire development lock. Both displays must be
   fully covered, with no desktop leakage and matching safe global auth state.
   Enter the real password once, Enter once. Require one attempt/worker, one
   AUTHENTICATED UNLOCK, sync/exit, and clean return on both outputs before timer.
2. **Connect while locked.** Start laptop-only; acquire and wait for locked event.
   Physically connect external display once. Watch the external display from its
   first visible frame: no unlocked desktop content is acceptable, including before
   MAGI presentation appears. Require new registry/role/configure, continuous laptop
   coverage and unchanged global auth state. Authenticate once; both unlock together.
3. **Remove while locked.** Start with both outputs present and locked. Type a
   short non-secret editing marker without submitting; disconnect external once.
   Internal display stays locked and retains the same masked edit count. Clear the
   marker explicitly, enter the real password once and authenticate. Require one
   worker/generation and one global unlock; no reconnect in this test.
4. **Reconnect/reconfigure.** Lock with both outputs. Disconnect/reconnect external
   once; require old output resources removed, fresh instance even if connector
   name repeats, exact new logical configure, no stale-sized content/desktop flash
   and unchanged global auth policy. Authenticate once; both return cleanly.
   Record actual reconfigure events; do not claim a resolution change if none occurs.

After **each**: review bounded PID/type/status logs only, verify exactly one
normal unlock, timer did not fire, worker/owner exited, compositor unlocked,
original MAGI/Hypridle processes retained and protected/PAM hashes match. Ask the
operator about both displays and transitions. Timer recovery marks authenticated
acceptance failed. Do not capture real passwords, raw PAM text or private desktop
screenshots. Do not combine worker failure, suspend, rotation or compositor restart.

Optional later individually approved tests: mixed resolution/scale and portrait;
active-auth physical removal if deterministic observation is practical. Synthetic
coverage already exercises active-auth hotplug; no fast manual race is required
in the first four physical runs. Zero-physical-output behaviour is synthetic-only
until a separately safe test setup is approved. Suspend/resume, Hypridle readiness,
compositor restart, packaging/account policy, broader input/MFA and production
migration remain separate gates. No visual polish or phase checkpoint commit yet.

## Phase 6A implementation-pass preservation and scope (historical)

Pre-edit SHA-256 snapshot `/tmp/magi-phase6-protected.json` contains 33 protected
operator-local/PAM files, including recursive Yazi flavor contents. All 33 match
at final comparison. Initial Git status is `/tmp/magi-phase6-status.txt`.
All earlier checkpoint documents and all real Rust worker/fixture/dependency files
remain unchanged. New work is confined to these 14 paths:

```text
linux/magi/docs/design/lock-screen-phase6-multi-output.md
linux/magi/native/lock/CMakeLists.txt
linux/magi/native/lock/README.md
linux/magi/native/lock/src/auth_controller.cpp
linux/magi/native/lock/src/auth_controller.hpp
linux/magi/native/lock/src/controller.cpp
linux/magi/native/lock/src/controller.hpp
linux/magi/native/lock/src/native_input.cpp
linux/magi/native/lock/src/native_input.hpp
linux/magi/native/lock/src/wayland_owner.cpp
linux/magi/native/lock/src/wayland_owner.hpp
linux/magi/native/lock/tests/auth_test.cpp
linux/magi/native/lock/tests/output_test.cpp
linux/magi/native/lock/tests/presentation_test.cpp
```

All build products are under /tmp. `git diff --check` and new-file whitespace
checks pass. No real session lock, real PAM, physical monitor, live headless output,
production routing change, package install, compositor restart, suspend, staging,
commit or push occurred during this phase. Implementation is awaiting operator
review and separately approved native acceptance.

## Approved headless integration attempt — 2026-10-18, incomplete

This later entry supersedes the implementation-pass statement that no live lock
has run. The operator approved exactly one non-PAM development lock, one manual
headless add/remove from an authenticated TTY, and timer recovery. Fresh authenticated
TTY availability was explicitly confirmed before acquisition. **Only the single
physical-output lock/timer portion ran. Headless integration is NOT accepted.**

Preflight verified running Hyprland v0.56.2 commit
`efb50993780079460b0cbed1363e2166a2de1d9f`, PID 1492, instance
`efb50993780079460b0cbed1363e2166a2de1d9f_1791834132_983040737`,
XDG_RUNTIME_DIR `/run/user/1000`, Wayland socket `wayland-1`, xray false,
locked=false and only eDP-1 (3840×2160, scale 2, transform 0). MAGI PID 1543 and
Hypridle PID 1541 were running; Hyprlock was installed. No existing proof, auth
worker or MAGI-6A output was present. Production routing was unchanged.

Before the run, bounded native lifecycle diagnostics were added to wayland_owner.cpp
and .hpp: surface lifetime/auth generation, first eight frame commits/ack/fallback,
resource removal and ignored stale releases. No secret or input count is logged.
Both native builds and four relevant controller/boundary/binary-gate tests per
build passed after this logging-only addition. The prior complete 8/8 suites and
41-scenario results remain the functional regression evidence; those unchanged
synthetic suites were not repeated for these diagnostics.

Reviewed development SHA-256:
`adbdb3692bcfbf5a21c239cf343b76ce642ed903ea772976311bd4dbad463489`.
Default SHA-256:
`5e8e1e7a4691179e1e6b469fec42f3dd3557b5865eb4caa4434fc5e380e992cd`.
Build-info and binary tests confirmed development unlock enabled only in the
explicit development binary; authentication still required --authenticate.

Exactly one invocation ran, PID **541905**:

```bash
/tmp/magi-lock-phase6-dev-build/magi-lock-proof \
  --acquire-session-lock --unsafe-development-unlock-after=90
```

No --authenticate or injection selector was supplied. An independent observer
recorded 88 compositor/process samples, including 86 locked=true samples. Only
eDP-1 appeared, and no magi-lock-auth process was observed. Native auth generation
was 0 with authentication enabled=false; no input/worker path was enabled.

Journal times (local Europe/London):

| Time | Evidence |
| --- | --- |
| 09:36:21.148745 | eDP-1 registry 72, lifetime 1: lock surface created; auth generation 0, authentication disabled |
| 09:36:21.149848 | Configure serial 0, 1920×1080 logical |
| 09:36:21.190805 | Serial 0 acked and frame committed, native fallback false |
| 09:36:21.208335 | COMPOSITOR CONFIRMED LOCKED |
| 09:36:21.221398 | Existing frame repainted without re-ack; global state Locked (2), auth generation 0 |
| 09:37:51.224111 | UNSAFE DEVELOPMENT TIMER UNLOCK: authenticated acceptance FAILED |
| 09:37:51.224801 | Explicit unlock processed by compositor; exiting |

Timer recovery occurred **90.015776 seconds** after compositor confirmation.
The legacy “authenticated acceptance FAILED” suffix is expected in this non-PAM
run; it is not an authenticated unlock or evidence of PAM failure. Proof exit was 0.

The agent requested a separate privileged diagnostic read after launch. Its tool
approval delay consumed the observation window before the agent could deliver the
instruction to switch TTYs. The operator did not switch TTYs. The provided commands
`hyprctl output create headless MAGI-6A` and `hyprctl output remove MAGI-6A` were
**not executed**. There is no MAGI-6A registry/lifetime, configure, commit, removal
or stale-release evidence from this run. No headless-output creation/removal
security assertion can be accepted. No second instance or lock run was attempted.

Postflight: locked=false; proof and worker absent; MAGI-6A absent with no cleanup
needed; eDP-1 unchanged; Hyprland/MAGI/Hypridle original PIDs and start times retained;
Hyprlock installed. `/tmp/magi-phase6-headless/before.json` snapshotted 513 files;
all 511 outside the two intentional source logging edits matched before updating
this report, including protected operator files, live Hypr configuration and PAM.
Evidence resides in that /tmp directory: launched.json, proof.pid, samples.jsonl,
result.json, proof-journal.json, proof-output.txt and processes-before.json.
No real password, PAM call, physical hotplug, suspend, process kill, compositor
restart, production routing change, staging, commit or push occurred.

Operator confirmation: **coverage and timer return were clean; no TTY switch**.
Thus full laptop coverage/no desktop leakage and clean timer-only desktop return
are accepted for this run. TTY-return and headless transitions remain untested.
No remaining visual questions apply to the completed single-output run.

**Additional non-physical evidence is still warranted. Do not move to an external
monitor yet.** This one-run authorization is consumed. Any repeat needs new
operator approval and fresh TTY confirmation. A future attempt must prepare and
validate the entire observer before acquisition and use its already-running
read-only state stream to deliver confirmation without a new mid-test tool approval.
It still must perform only one approved headless add/remove cycle. Phase 6B has
not begun and is not yet the next acceptance action.

## Second headless integration attempt — 2026-10-18, accepted

**PASS: real headless add/remove while locked, automated evidence and operator
visual confirmation.** The first attempt above remains incomplete due to
orchestration timing, not a locker failure. No accepted architecture or native
source changed for this second attempt. The operator separately authorized one
pre-armed run and freshly confirmed accessible authenticated TTY recovery after
preparation/preflight, immediately before acquisition. No TTY switch was needed.

### Pre-armed automation and preflight

Temporary helper/runner, mock checks and evidence live exclusively under
`/tmp/magi-phase6-headless-attempt2/`. `run.py` SHA-256:
`b17297b850d068c46c8348cc3629a0acdf8ed5a57c8acc29f8a9b488ed161d4f`.
Six helper-only mock cases passed: normal add/remove, create failure, removal
failure with cleanup, no-lock timeout, early unlock, pre-existing name refusal.
A preparation-only error-reporting bug (empty assertion text misclassified as
success) was caught and corrected in this temporary helper before the live run.
This did not affect the locker or its architecture.

The runner verifies the same binary hashes recorded for attempt one, default/dev
build-info gates, no existing proof/PAM worker, unlocked compositor, xray false,
only eDP-1, Hyprlock installed, and original process lifecycles. Default/development
binary-gate tests passed again. It targets the verified existing instance using:

```bash
export XDG_RUNTIME_DIR=/run/user/1000
export HYPRLAND_INSTANCE_SIGNATURE=efb50993780079460b0cbed1363e2166a2de1d9f_1791834132_983040737
```

Wayland socket remains `wayland-1`; Hyprland PID 1492, version/commit unchanged.
MAGI PID 1543 and Hypridle PID 1541 retained their recorded October 12 start times.
Preflight output was eDP-1 only: 3840×2160, scale 2, transform 0. MAGI-6A absent;
Hyprland locked=false. A fresh 513-file repository/live-Hypr/PAM snapshot was saved
and rechecked immediately before launching. A single-use O_EXCL marker prevents
accidental repeat acquisition by the runner.

The helper starts **before** the proof, verifies unlocked state/name absence,
and publishes its PID/waiting marker. Only after verifying that marker and a live
helper does the runner acquire one lock. Helper behaviour:

1. Poll `hyprctl locked` for true with a 20-second waiting deadline.
2. Settle four seconds; require still locked and MAGI-6A absent.
3. Execute `hyprctl output create headless MAGI-6A` exactly once.
4. Allow at most three seconds for output advertisement; record
   `hyprctl -j monitors all`, `hyprctl locked`, and auth-worker absence.
5. Wait five seconds; require still locked; execute
   `hyprctl output remove MAGI-6A` exactly once.
6. Allow at most three seconds for disappearance; record outputs/locked/workers;
   verify only eDP-1 remains and exit. On command/error paths, record the error
   and attempt bounded cleanup of the test output if creation was attempted.

Every external command has a two-second timeout. The read-only observer has a
115-second observation bound and never kills/unlocks the proof. It records
compositor outputs/locked state, worker absence, both process exits, bounded
PID-specific locker journal events, and postflight automatically. No new tool
approval or operator command was required during the locked interval.

### Actual live sequence

Helper PID **545784** published waiting-for-locked at **09:48:12.043786** (local
Europe/London), before proof PID **545789** started. The exact proof command was:

```bash
/tmp/magi-lock-phase6-dev-build/magi-lock-proof \
  --acquire-session-lock --unsafe-development-unlock-after=90
```

No authentication flag, failure selector, password input or PAM transaction.
The helper observed locked=true at 09:48:12.265116. Creation completed about
4.139 seconds later; removal completed about 5.065 seconds after creation.
Both exact Hyprland output commands returned exit 0 and `ok`.

| Local time | Actual evidence |
| --- | --- |
| 09:48:12.121612 | eDP-1 lock surface: registry 72, lifetime 1, auth generation 0, authentication disabled |
| 09:48:12.166769 | eDP-1 serial 0 acknowledged; 1920×1080 logical frame committed without fallback |
| 09:48:12.175507 | COMPOSITOR CONFIRMED LOCKED |
| 09:48:12.189177 | eDP-1 repaint, global state Locked (2), auth generation 0 |
| 09:48:16.403483 | New wl_output registry 73 discovered |
| 09:48:16.403510 | Registry 73 lock surface created, lifetime 2, auth generation 0, authentication disabled |
| 09:48:16.404503 | Registry 73 configure serial 0, exact logical dimensions 960×540 |
| 09:48:16.410528 | Serial 0 acknowledged and frame committed; native fallback false; global Locked (2), auth generation 0 |
| 09:48:16.428852 | Helper snapshot: eDP-1 + MAGI-6A, locked=true, zero auth workers |
| 09:48:21.468980 | Registry 73/lifetime 2 surface/buffer resources removed; global Locked (2), auth generation 0 |
| 09:48:21.469012 | Registry 73 removed |
| 09:48:21.520648 | Helper snapshot: eDP-1 only, locked=true, zero auth workers |
| 09:48:21.562892 | Helper completed successfully, exit 0 |
| 09:49:42.220752 | UNSAFE DEVELOPMENT TIMER UNLOCK: authenticated acceptance FAILED |
| 09:49:42.221266 | Compositor unlock sync processed; proof exits 0 |

MAGI-6A was compositor monitor ID **1**, 1920×1080 mode, scale **2**, normal
transform. The corresponding native registry ID **73** and lifetime **2** are
separate identity namespaces. Its 960×540 configure was followed exactly; no
physical-mode sizing assumption was used. eDP-1 retained registry 72/lifetime 1.
There was one session-lock acquisition, not a separate lock for the new output.

There were **87** automatic state samples, **85** continuously locked samples
between initial acquisition and final timer release, and no auth worker in any
sample. Native generation remained **0** before/during creation and after removal;
no auth input path was enabled, so no attempt or credential mutation occurred.
No authenticated-unlock or worker-spawn log appeared. eDP-1 was not removed or
recreated. The session remained locked for roughly another 80.75 seconds after
headless removal, until timer recovery **90.045245 seconds** after lock confirmation.

No stale-release diagnostic occurred and no old lifetime affected eDP-1 or any
other output. This run did **not** force a stale callback or replacement-ID race;
it does not independently prove that rejection branch executed. The synthetic
lifetime-reuse/release rejection tests remain the positive branch-coverage evidence.
No second headless instance was created merely to force such a race.

### Postflight, visual confirmation and disposition

Proof **545789 exited 0**, helper **545784 exited 0**, runner exited 0. Hyprland
reported unlocked; MAGI-6A was absent, with no error cleanup or extra removal
needed. eDP-1 retained its original mode, scale, transform and enabled/DPMS state.
Original Hyprland/MAGI/Hypridle PIDs and start times matched preflight. Hyprlock
remained installed, zero auth workers existed, and production routing was untouched.
All **513/513** snapshotted files matched immediately after the test, before this
authorized documentation update. No implementation files changed in this attempt.

The operator confirmed **all four visual checks passed**: full laptop-panel
coverage throughout, no underlying desktop exposure, continued lock through the
automatic headless add/remove period, and visually clean final timer recovery.
No visual confirmation remains pending. The legacy timer log's “authenticated
acceptance FAILED” suffix means only that this was intentionally unauthenticated
recovery; the **headless integration test passed**.

Evidence files: preflight.json, protected-before.json, run-consumed.json,
helper-ready.json, launched.json, helper-events.jsonl, helper-result.json,
helper-output.txt, samples.jsonl, proof-journal.json, proof-output.txt,
postflight.json. No credentials, raw PAM traffic or desktop screenshots were
collected. No physical hotplug, suspend/resume, compositor restart, process kill,
configuration/routing edit, staging, commit or push occurred.

**PHYSICAL MULTI-OUTPUT ACCEPTANCE IS NOW REQUIRED.** This is the next evidence
gate; the existing four-test Phase 6B plan above still requires individual approval
and fresh authenticated TTY recovery confirmation before each real lock. This
statement does not start Phase 6B or authorize any further lock. Headless evidence
cannot certify physical HDMI/DisplayPort scanout or absence of connector-transition
flashes. No additional non-physical issue was found in this run. Suspend/Hypridle,
production migration and visual polish remain out of scope.

## Phase 6B — Physical Test 1 (2026-10-18): PASSED

Scope: two physical outputs already present before one authenticated development
lock. The operator freshly confirmed authenticated TTY recovery immediately before
acquisition. No physical hotplug or Tests 2–4 were performed. The earlier headless
attempt records above remain unchanged.

### Preflight and invocation

Development/default binary gates passed: development emergency unlock enabled;
default unauthenticated development unlock and failure injection disabled. The
accepted unchanged Rust worker `/tmp/magi-auth-phase6/debug/magi-lock-auth` was
selected, using the existing `hyprlock` PAM service. No failure fixture was used.
Hyprlock remained installed; production loginctl/Hyprlock/Hypridle routing was
unchanged. Initially Hyprland was unlocked, with no proof/auth worker or MAGI-6A.

| Output | Physical mode | Logical size | Scale | Transform | Position | State |
| --- | --- | --- | --- | --- | --- | --- |
| eDP-1 | 3840×2160 @ 60 Hz | 1920×1080 | 2 | normal (0) | 0,0 | enabled, DPMS on |
| HDMI-A-1 | 3840×2160 @ 239.995 Hz | 2560×1440 | 1.5 | normal (0) | 1920,32 | enabled, DPMS on |

Both were independent extended displays, not mirrored. Original processes were
Hyprland PID 1492, MAGI PID 1543 and Hypridle PID 1541. Fresh snapshot covered
517 repository/system files, including PAM and live Hyprland configuration.
The pre-armed read-only observer collected bounded process, compositor and
allowlisted native journal evidence automatically under `/tmp/magi-phase6b-test1`.
It issued no output changes, retries, credential input or process kills.

Exactly one invocation (proof PID **556872**):

```bash
/tmp/magi-lock-phase6-dev-build/magi-lock-proof \
  --acquire-session-lock \
  --authenticate \
  --unsafe-development-unlock-after=180
```

### Surface and authentication evidence

| Output correspondence by unique logical dimensions | Registry global | Lifetime | Configure serial | Configure/commit |
| --- | --- | --- | --- | --- |
| eDP-1 | 72 | 1 | 190463 | 1920×1080, acknowledged, committed, no native fallback |
| HDMI-A-1 | 75 | 2 | 190464 | 2560×1440, acknowledged, committed, no native fallback |

Both native lock surfaces existed before compositor confirmation. Subsequent
repaints recorded global Locked (2), auth generation 0 on both outputs. Repaint
logs with `acknowledged false` reflect no new configure to acknowledge; the initial
configure for each output was acknowledged successfully.

Local Europe/London event sequence:

- **10:21:16.526163:** COMPOSITOR CONFIRMED LOCKED.
- Exactly one worker spawned, PID **556983**, and one authentication attempt
  started at **generation 1**. Output setup had retained generation 0.
- PAM PromptEchoOff; native credential cleared; worker reaped with
  `Authentication succeeded`.
- **10:21:25.515429:** exactly one `AUTHENTICATED UNLOCK: current PAM Success`.
- **10:21:25.520774:** compositor unlock sync processed; proof exited **0**.

The authenticated path stops the development timer before issuing the global
unlock. No `UNSAFE DEVELOPMENT TIMER UNLOCK` occurred; authenticated unlock was
8.989266 seconds after compositor lock confirmation. There was one global
controller/input/credential buffer, one worker and one consumed Success, not an
attempt per display. The short worker lifetime was captured by native spawn/reap
events, not by the one-second process polling samples. Teardown `AUTH CANCELLED`
messages came after successful compositor unlock sync; they do not indicate a
failed PAM attempt or another unlock cause.

Credential isolation remains the accepted native/QML boundary; this run collected
no credential content or raw PAM traffic. Visual confirmation below establishes
that password characters were not displayed literally.

### Postflight and operator acceptance

Proof and observer exited **0**. Hyprland reported unlocked, no auth worker
remained, and both physical outputs retained their modes, scale, transform,
positions and enabled/DPMS state. MAGI-6A was absent throughout. Original MAGI,
Hypridle and Hyprland PIDs/start times matched preflight; Hyprlock remained
installed. All **517/517** snapshotted files matched immediately after the run,
before this documentation update. PAM/configuration/production routing were
untouched. No implementation change was needed.

The operator confirmed **all six visual checks passed**: laptop fully covered,
external display fully covered, neither exposed the desktop even briefly,
password characters never displayed literally, both displays returned together,
and both returned cleanly. **Physical Test 1 PASSED**, including real authenticated
unlock acceptance with different physical-output scales.

Evidence: `/tmp/magi-phase6b-test1/{preflight.json,protected-before.json,consumed.json,
launched.json,samples.jsonl,proof-output.txt,journal.json,postflight.json}`.
This acceptance covers only two displays present before lock. Physical Tests 2–4
remain unperformed and require separate approval and fresh TTY confirmation.
No staging, commit, push, suspend/Hypridle work, production migration or visual
polish was performed. Stop for operator review; do not start another test.

## Phase 6B — Physical Test 2 (2026-10-18): PASSED

Scope: one physical external-display connection while the session was already
locked on eDP-1, followed by one real PAM authentication. Test 1 was not repeated.
The operator confirmed readiness in response to the fresh authenticated-TTY
recovery question before acquisition. All observation was prepared beforehand;
automation performed no compositor output changes. The operator connected the
cable physically and left both displays connected after return.

### Preflight and invocation

Only eDP-1 existed: compositor monitor ID 0, 3840×2160 @ 60 Hz, logical
1920×1080, scale 2, normal transform (0), position 0,0, enabled and DPMS on.
Hyprland was unlocked, with no HDMI-A-1, MAGI-6A, other virtual output, existing
proof or auth worker. Original MAGI PID 1543 and Hypridle PID 1541 were running.

Development/default binary security gates passed. Reviewed binary hashes matched
Test 1: development `adbdb3692bcfbf5a21c239cf343b76ce642ed903ea772976311bd4dbad463489`,
default `5e8e1e7a4691179e1e6b469fec42f3dd3557b5865eb4caa4434fc5e380e992cd`,
Rust worker `3cd88d189993a7e85ed1019d0e20e1b497d9725cea4988c43d102f2c6d0c56b7`.
The accepted worker `/tmp/magi-auth-phase6/debug/magi-lock-auth` and existing
`hyprlock` PAM service were selected. Development timer enabled; default build
had no unauthenticated development unlock. No failure fixture selected.
Hyprlock remained installed, production routing unchanged, and 517 files were
snapshotted before launch.

The single-use observer `/tmp/magi-phase6b-test2/run.py` bounded observation to
205 seconds, individual commands to three seconds, and polled roughly once per
second. It collected allowlisted native journal events and automatic postflight;
no mid-lock instruction or approval was needed. Exactly one invocation, PID
**559899**, used:

```bash
/tmp/magi-lock-phase6-dev-build/magi-lock-proof \
  --acquire-session-lock \
  --authenticate \
  --unsafe-development-unlock-after=180
```

### Actual hotplug and authentication evidence

Times below are local Europe/London on 2026-10-18.

| Time | Evidence |
| --- | --- |
| 10:31:23.679320 | eDP-1 lock surface created: registry 72, lifetime 1, auth generation 0 |
| 10:31:23.719602 | eDP-1 serial 190747 acknowledged; 1920×1080 committed without fallback |
| 10:31:23.726025 | COMPOSITOR CONFIRMED LOCKED |
| 10:31:37.171310 | New external output registry 76 discovered, after lock confirmation |
| 10:31:37.171648 | Registry 76 native lock surface created, new lifetime 2, auth generation 0 |
| 10:31:37.403262 | External configure serial 190753, logical 2560×1440 |
| 10:31:37.418805 | Configure acknowledged and presentation committed; fallback false, global Locked (2), auth generation 0 |
| 10:31:49.539573 | One auth worker spawned, PID 560192, after external presentation |
| 10:31:49.540109 | One auth attempt started, generation 1 |
| 10:31:49.604515 | Worker reaped; Authentication succeeded |
| 10:31:49.604650 | Exactly one AUTHENTICATED UNLOCK: current PAM Success |
| 10:31:49.634129 | Explicit unlock processed by compositor; proof exits 0 |

The new physical output was HDMI-A-1, compositor monitor ID 1, 3840×2160 @
239.995 Hz, logical 2560×1440, scale 1.5, normal transform (0), position 1920,32.
Its registry/lifetime correspondence follows the new output event and unique
logical dimensions. Registry ID, compositor monitor ID and lifetime token are
separate identity namespaces.

Auth generation stayed 0 before, during and after hotplug until the operator's
later submission started generation 1. No worker spawned because of hotplug;
there was one later spawn/reap pair and one PAM Success. The accepted global
controller/native input/credential buffer architecture was unchanged. Native
PromptEchoOff and credential-cleared events were recorded; no raw credential or
PAM payload was collected. Raw credentials remain outside QML by the accepted
native presentation boundary.

All 24 locked samples among 26 observer samples were contiguous, spanning
physical output addition and the later authentication. There was one lock
acquisition, no unlock/relock cycle, and one authenticated unlock. The
successful native unlock path stopped the emergency timer before issuing the
unlock. No emergency timer unlock occurred; authenticated unlock was 25.878625
seconds after lock confirmation. Teardown cancellation logs followed successful
unlock sync and do not represent a failed authentication or another unlock.

### Postflight and visual acceptance

Proof and observer exited 0; the worker was reaped, with no worker remaining.
Hyprland reported unlocked. Both physical displays remained connected, enabled,
DPMS on and in the expected extended configuration. No headless output existed.
Original Hyprland/MAGI/Hypridle PIDs and start times matched preflight. Hyprlock
remained installed. All **517/517** snapshotted files matched immediately after
the test, before this documentation update; PAM, Hyprlock, Hypridle and production
routing were untouched.

The operator confirmed all eight visual checks passed: laptop continuously
covered; no desktop content on external connection even briefly; any black/blank
transition contained no unlocked content; external MAGI lock presentation
appeared; both screens stayed locked together; password characters never appeared
literally; both screens unlocked together; and both returned cleanly. This visual
confirmation supplies the first-visible-content evidence that protocol logs alone
cannot establish. **Physical Test 2 PASSED.** No visual questions remain pending.

Evidence is under `/tmp/magi-phase6b-test2`: preflight.json,
protected-before.json, consumed.json, launched.json, samples.jsonl,
proof-output.txt, journal.json and postflight.json. No implementation changes,
physical disconnection after the test, Test 3/4, suspend/resume, compositor restart,
production migration, Hypridle changes, visual polish, staging, commit or push
were performed. Stop for operator review with the dual-display setup intact.

## Phase 6B — Physical Test 3 (2026-10-18): PASSED

Scope: one physical external-display removal while the session was locked across
two displays, then one real PAM authentication on the remaining laptop panel.
Tests 1 and 2 were not repeated. Fresh authenticated-TTY recovery confirmation
was received immediately before the single invocation. The operator physically
unplugged HDMI and left it disconnected; automation performed no output changes.

### Preflight and invocation

Exactly eDP-1 and HDMI-A-1 were active, extended, enabled and DPMS on:

| Output | Physical mode | Logical size | Scale | Transform | Position |
| --- | --- | --- | --- | --- | --- |
| eDP-1 | 3840×2160 @ 60 Hz | 1920×1080 | 2 | normal (0) | 0,0 |
| HDMI-A-1 | 3840×2160 @ 239.995 Hz | 2560×1440 | 1.5 | normal (0) | 1920,32 |

Hyprland was unlocked; no temporary/headless output, proof or auth worker existed.
Original MAGI PID 1543 and Hypridle PID 1541 were running. Reviewed development,
default and worker hashes matched Test 2. Both binary security gates passed:
development timer enabled, default unauthenticated development unlock disabled.
No failure fixture selected. The accepted real Rust worker and existing `hyprlock`
PAM service were selected; Hyprlock installed and production routing unchanged.
Fresh protected-state snapshot covered 517 files.

The read-only observer `/tmp/magi-phase6b-test3/run.py` was prepared before lock,
with a 205-second observation bound, three-second individual command deadlines,
automatic journal/postflight collection and a single-use invocation guard. It
performed no input, retries, output changes, unlock requests or process kills.
Exactly one invocation, proof PID **562979**:

```bash
/tmp/magi-lock-phase6-dev-build/magi-lock-proof \
  --acquire-session-lock \
  --authenticate \
  --unsafe-development-unlock-after=180
```

### Actual removal and authentication evidence

Local Europe/London times on 2026-10-18:

| Time | Evidence |
| --- | --- |
| 10:41:49.004596 | eDP-1 lock surface: registry 72, lifetime 1, auth generation 0 |
| 10:41:49.004643 | HDMI-A-1 lock surface: registry 76, lifetime 2, auth generation 0 |
| 10:41:49.009871 | eDP-1 configure 191002 acknowledged, 1920×1080 committed without fallback |
| 10:41:49.019027 | HDMI configure 191003 acknowledged, 2560×1440 committed without fallback |
| 10:41:49.029811 | COMPOSITOR CONFIRMED LOCKED |
| 10:41:58.074449 | Output resources removed: registry 76, lifetime 2, global Locked (2), auth generation 0 |
| 10:41:58.074759 | Wayland registry output 76 removed |
| 10:42:09.792110 | eDP-1 repaint retains registry 72/lifetime 1, global Locked (2), auth generation 0 |
| 10:42:17.745596 | One auth worker spawned, PID 563291 |
| 10:42:17.746014 | One auth attempt started, generation 1 |
| 10:42:17.790582 | Worker reaped; Authentication succeeded |
| 10:42:17.790702 | Exactly one AUTHENTICATED UNLOCK: current PAM Success |
| 10:42:17.799301 | Explicit compositor unlock processed; proof exits 0 |

Output correspondence follows the unique configure dimensions and monitor-list
transition. Removal occurred approximately 9.045 seconds after lock confirmation.
The per-output teardown path destroys that output's ext-session-lock surface and
wl_surface, releases its buffers and presentation/controller state, releases
wl_output and erases its native registry entry. The resource-removal log and
subsequent registry-removal log confirm this path ran for 76/lifetime 2. No
eDP-1 removal/recreation occurred; its existing lifetime continued to repaint.
No global auth cancellation occurred during removal, generation stayed 0, and no
worker started until the later submission. Global input remained usable.

Deferred buffer callbacks retain registry ID plus lifetime and validate that pair
before acting. No stale-release diagnostic or cross-output effect was observed.
This physical run did not force a stale callback or replacement lifetime, so it
does not independently prove execution of the rejection branch; accepted
synthetic tests remain the positive coverage for that branch. No reconnect was
performed to manufacture such a race.

All 27 locked samples among 29 observer samples were contiguous, including the
transition to eDP-1 only. There was one lock acquisition, no unlock/relock cycle,
one worker, one generation-1 PAM Success and one global authenticated unlock.
The native authenticated-unlock path cancelled the emergency timer; no timer
unlock occurred. Authenticated unlock was 28.760891 seconds after lock
confirmation. Teardown cancellation messages occurred after successful unlock
sync, not during physical removal or the PAM attempt. No raw credentials or PAM
payloads were collected; the accepted native/QML credential boundary is unchanged.

### Postflight and operator acceptance

Proof and observer exited 0; the worker was reaped and none remained. Hyprland
reported unlocked. Only eDP-1 remained, active at its original mode, scale,
transform and position. HDMI-A-1 remained absent and no MAGI-6A existed. Original
Hyprland/MAGI/Hypridle PIDs and start times matched preflight; Hyprlock remained
installed. All **517/517** snapshotted files matched immediately after testing,
before this documentation update. PAM, Hyprlock, Hypridle and production routing
were unchanged.

The operator confirmed all seven visual checks: both displays initially covered;
laptop fully covered during disconnection; no desktop exposure even briefly;
lock presentation usable after removal; no literal password display;
authentication worked on the laptop; and clean desktop return. **Physical Test 3
PASSED.** No visual questions remain pending.

Evidence under `/tmp/magi-phase6b-test3`: preflight.json, protected-before.json,
consumed.json, launched.json, samples.jsonl, proof-output.txt, journal.json and
postflight.json. Only this documentation was updated; no implementation changes
were needed. External monitor remains disconnected. Test 4, suspend/resume,
compositor restart, production migration, Hypridle changes, visual polish,
staging, commit and push were not performed. Stop for operator review.

## Phase 6B — Physical Test 4 (2026-10-18): PASSED

Scope: one physical disconnect/reconnect of the same external monitor within one
continuous session lock, then one real PAM authentication. Tests 1–3 were not
repeated. The operator responded to the fresh authenticated-TTY recovery question
with permission to proceed before acquisition. All observation was prepared before
locking. Only the operator changed physical connections; automation never changed
outputs or monitor configuration. Both displays remain connected after the test.

### Preflight and invocation

Exactly eDP-1 and HDMI-A-1 were active, extended, enabled and DPMS on:

| Output | Physical mode | Logical size | Scale | Transform | Position |
| --- | --- | --- | --- | --- | --- |
| eDP-1 | 3840×2160 @ 60 Hz | 1920×1080 | 2 | normal (0) | 0,0 |
| HDMI-A-1 | 3840×2160 @ 239.995 Hz | 2560×1440 | 1.5 | normal (0) | 1920,32 |

No headless/virtual output, existing proof or auth worker was present. Hyprland
was unlocked. Original MAGI PID 1543 and Hypridle PID 1541 were running. Reviewed
development/default/worker hashes matched the previous accepted tests; both
binary security gates passed. Development timer enabled, default unauthenticated
development unlock disabled, no failure fixture selected. The accepted Rust worker
and existing `hyprlock` PAM service were selected; Hyprlock remained installed,
production routing unchanged, and 517 files were freshly snapshotted.

Read-only observer `/tmp/magi-phase6b-test4/run.py` had a 205-second observation
bound, three-second individual command deadlines, automatic journal/postflight
collection and a single-use guard. No mid-lock approval or tool action was needed.
Exactly one invocation, proof PID **565974**:

```bash
/tmp/magi-lock-phase6-dev-build/magi-lock-proof \
  --acquire-session-lock \
  --authenticate \
  --unsafe-development-unlock-after=180
```

### Old/new lifetime and real compositor evidence

Times are local Europe/London on 2026-10-18.

| Time | Evidence |
| --- | --- |
| 10:51:16.604933 | eDP-1 native lock surface: registry 72, lifetime 1, auth generation 0 |
| 10:51:16.604944 | Initial HDMI lock surface: registry 77, lifetime 2, auth generation 0 |
| 10:51:16.631895 | eDP-1 configure 191250 acknowledged; 1920×1080 committed without fallback |
| 10:51:16.642114 | Initial HDMI configure 191251 acknowledged; 2560×1440 committed without fallback |
| 10:51:16.660857 | COMPOSITOR CONFIRMED LOCKED |
| 10:51:26.751301 | Old HDMI resources removed: registry 77/lifetime 2, global Locked (2), auth generation 0 |
| 10:51:26.751592 | Old Wayland registry output 77 removed |
| 10:51:44.987581 | Reconnected output discovered: new registry 78 |
| 10:51:44.988088 | Fresh native lock surface created: registry 78, new lifetime 3, auth generation 0 |
| 10:51:45.229576 | Fresh configure 191262, logical 2560×1440 |
| 10:51:45.249210 | Fresh configure acknowledged and presentation committed; fallback false, global Locked (2), auth generation 0 |
| 10:52:06.884313 | One auth worker spawned, PID 566524 |
| 10:52:06.884869 | One auth attempt started, generation 1 |
| 10:52:06.973250 | Worker reaped; Authentication succeeded |
| 10:52:06.973324 | Exactly one AUTHENTICATED UNLOCK: current PAM Success |
| 10:52:06.977835 | Explicit compositor unlock processed; proof exits 0 |

The connector name remained HDMI-A-1, but **old registry 77/lifetime 2 became new
registry 78/lifetime 3**. The fresh output did not reuse the old per-output
lifetime. Monitor-list transitions and the unique 2560×1440 configure dimensions
establish the connector correspondence. eDP-1 retained registry 72/lifetime 1 and
continued repainting after reconnection. The compositor monitor ID reused for
HDMI-A-1 is distinct from Wayland global and native lifetime identity.

The old output traversed the accepted resource teardown path: its lock surface,
wl_surface, buffers, presentation/controller state and native wl_output registry
entry were released. No eDP-1 removal or recreation occurred. Deferred buffer
callbacks retain registry plus lifetime identity and validate it before acting.
No `Stale output release ignored` diagnostic or old-lifetime effect on eDP-1 or
new HDMI was observed. This run did not force a delayed callback; synthetic tests
remain the positive rejection-branch evidence, rather than claiming that branch
executed here.

All 47 locked samples among 49 observer samples were contiguous across the
2→1→2 output sequence. Auth generation stayed 0 before/during/after removal and
reconnection until the later manual submission created generation 1. No PAM
worker launched because of either output event. One global lock/controller/native
credential buffer remained authoritative; no unlock/relock cycle occurred.
The single later PAM attempt succeeded and the worker was reaped. No credentials
or raw PAM payloads were collected; the native/QML credential boundary is unchanged.

The authenticated native path stopped the emergency timer before issuing exactly
one global unlock, 50.312467 seconds after lock confirmation. No emergency timer
unlock occurred. Teardown cancellation logs followed successful compositor unlock
sync; they do not indicate lifecycle-triggered cancellation or another unlock.

### Postflight, visual acceptance and Phase 6 disposition

Proof and observer exited 0; no worker remained; Hyprland reported unlocked.
Both displays remained connected, enabled and DPMS on with the preflight modes,
scales, transforms and positions. HDMI-A-1 was the reconnected lifetime. No
headless output existed. Original Hyprland/MAGI/Hypridle PIDs and start times
matched preflight; Hyprlock remained installed. All **517/517** snapshotted files
matched immediately after testing, before this documentation update. PAM,
Hyprlock, Hypridle and production routing were unchanged.

The operator explicitly confirmed all ten visual checks passed: both initially
covered; laptop covered after removal; no laptop desktop leakage; no unlocked
external desktop during reconnection; black/blank transition contained no unlocked
content; external MAGI lock returned; both remained locked together; no literal
password display; both unlocked together; and visually clean return on both.
This supplies the physical first-visible-content evidence beyond protocol logs.
**Physical Test 4 PASSED.** No visual questions remain pending.

Evidence under `/tmp/magi-phase6b-test4`: preflight.json, protected-before.json,
consumed.json, launched.json, samples.jsonl, proof-output.txt, journal.json and
postflight.json. No implementation changes were needed.

**All four Phase 6B physical acceptance tests are now accepted. Phase 6 physical
acceptance is complete for this tested hardware/compositor configuration.**
Earlier pending-physical statements above describe their historical checkpoints.
This result does not authorize Phase 7, suspend/resume, Hypridle production
integration, compositor restart testing, production migration, visual polish,
staging, commit or push. None were performed. Stop for operator review with both
displays connected and Hyprlock still production/fallback.

## Final Phase 6 checkpoint validation (2026-10-18)

The operator accepted the implementation and all synthetic/headless/physical gates
and explicitly authorized committing and pushing Phase 6 only. Finalization ran
no real session lock, password submission, PAM transaction or output hotplug.

Both existing /tmp native build configurations built successfully. Complete CTest
passed **8/8 default and 8/8 development**, including the **41-scenario** synthetic
multi-output matrix in each, Phase 5 containment/stale-result regressions,
credential/presentation boundary and synthetic-secret leakage checks. Build-info
and binary gates confirm default `development-unlock=0; failure-injection=0`.
Development retains explicit opt-in timer/failure-fixture support.

Rust `cargo test --locked --offline` passed **18/18** (two unit tests and 16
integration tests); Clippy `--locked --offline --all-targets -- -D warnings` and
`cargo fmt --check` passed. The initial sandboxed Rust run failed socket-based
fixtures; rerunning unchanged outside the IPC-restricting sandbox passed. Native
IPC suites also ran outside that sandbox, using only synthetic workers/offscreen
rendering. The real Rust worker, fixtures, dependencies and PAM semantics remain
unchanged by Phase 6.

The final working-tree audit independently derived **14 intended paths**, still
matching the explicit implementation-pass list above: **12 modifications and two
additions** (this checkpoint and `tests/output_test.cpp`). Lifecycle logging and
all acceptance records are contained in those paths; no extra source scope was
added. No /tmp logs, binaries, build directories, production configuration or
operator-local paths belong to the allowlist. No build products are tracked.
The fresh finalization snapshot covers **503 files outside the allowlist**,
including operator-local/runtime state and PAM/live Hyprland configuration; hashes
match before staging. Earlier per-test 517-file snapshots are preserved above.

Only the exact 14-path allowlist is authorized for staging and the checkpoint
subject is `magi: harden multi-output session lock`. Repository whitespace checks
pass. Hyprlock remains production/fallback; remaining future gates are listed at
the top of this document. Commit/push authorization does not start any next phase.
