# MAGI Lock Screen — Phase 5 failure-path and resilience hardening

2026-10-17; baseline `58c14da0dbbd25eda06c3152574aaaefc0e9cdd6`.
**Accepted: automated validation and three separately approved live failure tests.**
Tests A, B and C each ran once and passed containment; none may be repeated under
this checkpoint. The operator authorized final documentation, validation, commit
and push only. Phase 4 remains the accepted authenticated-success evidence.

## Invariant and audit findings

**Only valid current-generation PAM Success satisfying the complete accepted
worker/protocol lifecycle may authorize normal unlock. Everything else remains
locked.** Development recovery is not authentication: it is compiled out of default
builds, explicitly runtime-enabled in development, and logged distinctly as
UNSAFE DEVELOPMENT TIMER UNLOCK.

The native owner's Controller::authenticatedUnlock requires confirmed Locked,
no teardown, and AuthController::consumeSuccess for the current generation. That
private check now spells out the full existing contract: Succeeded, not consumed,
hello and credential response sent, reaped child, clean exit, closed IPC, EOF,
Success result, no cancellation/stop in progress, and empty owned credential.
Authorization is consumed once. No UI, signal, process exit alone, EOF alone,
error, fixture selection or log message supplies authorization.

Line-by-line inspection covered auth_controller.cpp/.hpp, controller.cpp,
wayland_owner.cpp, native_input.cpp, credential.cpp/.hpp, presentation.cpp, options
and main, and the accepted Rust protocol/process/PAM boundary. No unlock bypass
was found. Concrete gaps addressed:

- Failure diagnostics previously collapsed PAM/protocol/worker results, timeout
  and crash. Constant category logs now distinguish them without PAM text.
- Pending input survived first transition to native presentation fallback. The
  native owner now clears Editing input or cancels Authenticating on that first
  transition per output. This is native failure policy, not a QML-callable method.
  It never manufactures or consumes a completed Success receipt. Fallback remains
  usable after cleanup. A persistent fallback does not cancel every keystroke.
- Failure terminal paths explicitly invalidate authorization, and consumeSuccess
  explicitly requires all cleanup/conversation conditions rather than relying
  solely on the fact that finish() established them.
- Tests previously sometimes destroyed a failed controller before observing retry
  cleanup. Expanded tests wait for retry readiness and prove child already reaped,
  IPC closed and full owned credential storage zeroed.

No real Rust worker logic, PAM service, dependency or authentication policy changed.
Only its separate synthetic example changed. No cosmetic refactoring is included.

## Failure-path audit

All rows retain the compositor lock and have zero normal unlock authorization.
"Cleanup" means explicit native buffer erasure, one spawned child's completion/reap,
FD close, then 1500 ms retry delay (short injected delay in tests). While a child
exists or retry timer runs, append/submit are blocked. Error state may be shown
before cleanup finishes; that does not make input editable.

| Path / trigger | State and lifecycle | Diagnostics / retry |
|---|---|---|
| A AuthenticationFailed result | Failed after clean completion; erase and cleanup | AUTH FAILED; delayed retry |
| B PamError result | WorkerError after cleanup | PAM ERROR; delayed retry |
| C ProtocolError result | WorkerError after cleanup | PROTOCOL ERROR; delayed retry |
| D WorkerError result | WorkerError after cleanup | WORKER ERROR; delayed retry |
| E EchoOn or second hidden prompt | Unsupported; erase, best-effort Cancel, bounded reap | UNSUPPORTED CONVERSATION; delayed retry |
| F Cancellation | Cancelled; receipt invalidated immediately; erase, Cancel, reap | AUTH CANCELLED; delayed retry |
| G Missing/non-executable/exec failure | WorkerError; all partial spawn FDs closed; no child retained | WORKER ERROR: spawn failed; delayed retry |
| H Crash/nonzero exit | WorkerError; waitpid records abnormal completion; erase | WORKER CRASH/TERMINATED or abnormal-exit category; retry after reap |
| I EOF before complete contract | WorkerError; erase, reap; EOF alone is never Success | WORKER ERROR; delayed retry |
| J Malformed/oversize/version/order/trailing frame | WorkerError; erase, Cancel, reap | WORKER ERROR; delayed retry |
| K Deadline | WorkerError; erase and Cancel; after 2 s grace SIGKILL and reap | AUTH TIMEOUT; retry only after reap |
| L Stale generation | poll returns without touching current child; consume rejects | No repeated log; no state change |
| M Duplicate result | Trailing packet rejected even after first Success | WORKER ERROR; cleanup and retry |
| N QML/render failure | Native fallback; Editing/Authenticating abandoned on first transition; completed receipt unchanged | Existing bounded fallback log; cleanup before retry |
| O Escape/Ctrl+U/focus loss | Escape clears Editing or cancels active attempt; no unlock; Ctrl+U only when editable | Clear/cancel category; active cancellation cleanup before retry |
| P Owner teardown/destruction | Callbacks removed, cancel/erase; auth destructor closes FD, kills/reaps outstanding child | No unlock; no retry after destruction |

Owner protocol failure sets stopping/Failed and exits via ordinary teardown; it
does not call unlock. Fatal native process failure still depends on compositor
protection and is not made recoverable by the development timer.

## Attempt, cleanup and generation lifecycle

Idle/Editing → Authenticating → terminal Failed/WorkerError/Unsupported/Cancelled
(with possible cleanup pending) → reaped child + closed IPC + zeroed credential →
retry delay → Editing if focus active, otherwise Idle. Success has no retry path.
PID ownership, not state label alone, prevents concurrent workers. Repeated Enter
and text are ignored during authentication. Escape remains active to cancel.
Escape during the delay clears only; it neither shortens the delay nor unlocks.
There is no automatic resubmission and no real-password rate-limit experiment.

Each submit increments a monotonic generation (wrap refused). Poll callbacks carry
that generation; result callbacks carry it; native unlock checks it again. Retry
creates a fresh unnamed socketpair only after old child reap and FD close. An old
worker cannot survive into a new attempt through the supported lifecycle. A reused
PID is not an authorization identity: the current generation and private channel
remain necessary. Tests inject stale callbacks during a later child lifetime,
reject an old receipt before/during/after retry, and check cancellation/timeout
followed by delayed Success. No attempt to force kernel PID allocator reuse occurs.

Success then signal/nonzero exit, duplicate Success, malformed trailing bytes,
or Success without EOF/clean reap cannot unlock. Cancellation/timeout mark the
receipt consumed and stop receiving results, so late Success is ignored. Lock
teardown/Failed/Acquiring also rejects a current successful receipt. Cancellation
of a previously completed but unconsumed success remains an explicit native action.

## Credential lifetime and presentation boundary

The fixed 511-byte Credential remains noncopyable; native input and IPC scratch
are erased with explicit_bzero. Terminal outcomes, clear/cancel, spawn failure,
timeout, first fallback transition and destructor clear owned bytes. Tests inspect
zero/nonzero storage through a friend defined only in the test translation unit;
there is no runtime dump or QML secret accessor. Existing destructor storage tests
also remain. No QString conversion of credentials is introduced.

QML receives only the existing count/active/caps/status value object. Presentation
failure tests render invalid QML during actual Editing, Authenticating and Failed
controller stages, then exercise the same native fallback cancellation policy.
Fallback, success-looking QML and main-shell state cannot authorize unlock.
The locker has no communication dependency on quickshell -c magi: neither input,
auth state nor unlock routes through that process. The real shell is not killed.

Owned-memory erasure does not guarantee erasure of compiler spills, xkb internals,
kernel queues, or PAM module copies. SIGKILL cannot run a hung child's destructors.
Core dumps remain disabled. No operator memory inspection occurs. Automated tests use synthetic secrets only;
the approved Test A used one deliberately incorrect password through native input.

## Synthetic fixtures and build gates

The separate Rust protocol_fixture example never calls PAM. Crash aborts after
inherited-FD validation; hang waits without completing and ignores Cancel. Tests
also cover all bounded result categories, unsupported prompts, version/truncation/
oversize/unknown/order errors, EOF after handshake/prompt/response, duplicate
Success, delayed Success, Success followed by crash/nonzero exit/trailing frame,
and Success followed by a hang. Real worker code has no fixture switch.

MAGI_LOCK_FAILURE_INJECTION defaults OFF and CMake rejects ON unless
MAGI_LOCK_DEVELOPMENT_UNLOCK is also ON. The development owner accepts only
--development-auth-failure=crash|hang, and only with explicit authentication,
acquisition and emergency timer flags. Fixed build-directory symlinks select the
prebuilt example; no arbitrary runtime executable path or public socket exists.
Selection logs SYNTHETIC FAILURE INJECTION and uses a fixed five-second attempt
timeout plus existing two-second cleanup grace. Without selection, the accepted
real worker and 120-second timeout remain in use.

Default binary tests inspect flags, strings and symbols: no development timer,
crash/hang selection, fixture paths or synthetic-success mode. The unit test
executables can of course use fixtures even in a default build tree; they are
separate binaries and are not installed. No new install rule exists. Selecting a
malicious worker at build time or replacing executables as the same UID remains
outside this proof; trusted packaging is still a gate.

## Automated matrix and commands

See native README for exact Phase 5 build commands. Both CTest configurations
retain seven aggregate tests: controller_production, auth_production,
controller_development, auth_development, presentation_offscreen,
presentation_boundary and binary_gate. Each aggregate covers multiple cases.

Expanded auth tests require zero unlock requests for 24 failure modes and one
consumable request for valid synthetic Success. They cover full-storage clearing,
100-submit bursts, blocked input, child reap before retry, missing/non-executable/
invalid executable, delayed result after cancel/timeout, stale callback during a
later attempt, lock teardown, active auth destruction, and presentation fallback.
Existing editing, bounds, xkb, caps, paste rejection and native input tests remain.
Native captured diagnostics must exclude the distinctive synthetic secret and
contain the required bounded failure categories. Rust's stdout/stderr/panic
non-leakage regression is retained; no raw IPC debugging is enabled.

Validation results are recorded after the final run below. These are synthetic
non-locking tests, not claims about live wrong-password or live crash containment.

## Accepted live procedures — historical record; do not repeat

Before **each** test: save work, obtain fresh explicit confirmation of an
accessible authenticated TTY, verify reviewed binary hashes and compile gates,
confirm one output and original MAGI/Hypridle PIDs, snapshot protected/PAM/config
state, and confirm production Hyprlock remains installed and unchanged. Use
bounded PID-specific journal diagnostics, never raw PAM text or input capture.
Do not kill the locker or compositor. A timer cannot recover a dead/frozen owner.

Use **90 seconds after compositor confirmation** via the existing 10..300-second
runtime timer. It permits observation of failure plus cleanup without the former
180-second wait. Timer recovery is never authentication success. If a PAM module
is still blocked at recovery, cancellation/destruction reaps the child; that run
does not prove a completed AuthenticationFailed result.

### A — one wrong password, real PAM; accepted

```bash
/tmp/magi-lock-phase5-dev-build/magi-lock-proof \
  --acquire-session-lock --authenticate --unsafe-development-unlock-after=90
```

Enter one deliberately incorrect password; Enter once. Require AUTH FAILED,
worker reap, CREDENTIAL CLEARED, locked coverage and bounded failure presentation;
retry availability only after cleanup/delay. **Do not retry.** Wait for the timer.
Expected outcome: failure containment PASS; unlock cause UNSAFE DEVELOPMENT TIMER
UNLOCK. It is not authenticated-unlock acceptance. A real failed password can
increment PAM/faillock counters; never automate repeated failures or reset counters.

### B — synthetic worker crash; accepted

```bash
/tmp/magi-lock-phase5-dev-build/magi-lock-proof \
  --acquire-session-lock --authenticate --unsafe-development-unlock-after=90 \
  --development-auth-failure=crash
```

Type a non-secret test word, Enter once (never an account password). Require
synthetic-injection marker, worker crash/error, clear and reap, zero authenticated
unlock, and continued lock coverage. Do not retry. Wait for timer recovery.

### C — synthetic worker timeout; accepted

```bash
/tmp/magi-lock-phase5-dev-build/magi-lock-proof \
  --acquire-session-lock --authenticate --unsafe-development-unlock-after=90 \
  --development-auth-failure=hang
```

Type a non-secret test word and Enter once. Expect AUTH TIMEOUT at roughly five
seconds, Cancel grace up to two seconds, termination/reap, cleared buffer, no
normal unlock, and continued coverage. Wait for timer recovery; do not retry.

For all three: verify exact unlock cause, proof/worker exit, unlocked compositor,
unchanged original MAGI/Hypridle processes, and matching protected/PAM/routing
hashes. Ask operator about coverage, no literal input and clean graphical return.
Do not combine tests into a single session or treat this plan as approval.

## Remaining gates

Live A/B/C containment is accepted for the current single eDP-1 output.
Multiple physical outputs, output hotplug/removal while locked, suspend/resume,
Hypridle migration, compositor failure/restart, broader layouts and input methods,
live MFA/fingerprint, production PAM/account policy, packaging, production migration
production routing, final MAGI UI and eventual Hyprlock retirement remain separate
gates. No such work is performed here.

## Final non-disruptive validation

Default and development builds pass **7/7 CTest tests each**, including the expanded
native auth/IPC suite and real offscreen rendering during controller failures.
Rust **18/18** regressions, locked/offline all-target Clippy with warnings denied,
and cargo fmt --check pass. Native captured-log and Rust stdout/stderr/panic
synthetic-secret regression checks pass. No real worker source/dependency changed.
The default binary reports development-unlock=0 and failure-injection=0; the
explicit development build reports both 1. Invalid injection-without-recovery
CMake configuration is rejected as intended. No missing dependency was installed;
optional unused Vulkan headers remain absent.

The initial snapshot contains **509** files. All pre-existing files outside the
Phase 5 allowlist retain their hashes, including earlier checkpoints, protected
operator state, PAM and production routing/configuration. git diff --check passes;
the index is empty. All generated objects/binaries remain under /tmp, and the
16 changed/new Phase 5 paths are text files. Implementation/automated validation
used no real lock or password. The separately approved live runs are recorded below;
no production process restart occurred. Final commit/push was separately authorized.

Reviewed build SHA-256 values (reverify before any individually approved live run):

```text
default: 7c8de2a3597ff3043544988140f1b0c6c02fccad218036712f58ac07b316c448
development: 481e725cedada9cb2a1a17c21bd69ac199b57c8b7773c1c7954e9bb1b3533c50
fixture: 7420c78c9661d07253963d09bb56d7e2db4057e63839a3ffb7b54815888e8296
accepted real worker: 3cd88d189993a7e85ed1019d0e20e1b497d9725cea4988c43d102f2c6d0c56b7
```

Exact Phase 5 path audit:

```text
linux/magi/docs/design/lock-screen-phase5-failure-resilience.md
linux/magi/native/lock/CMakeLists.txt
linux/magi/native/lock/README.md
linux/magi/native/lock/auth/examples/protocol_fixture.rs
linux/magi/native/lock/src/auth_controller.cpp
linux/magi/native/lock/src/auth_controller.hpp
linux/magi/native/lock/src/credential.hpp
linux/magi/native/lock/src/main.cpp
linux/magi/native/lock/src/options.cpp
linux/magi/native/lock/src/options.hpp
linux/magi/native/lock/src/wayland_owner.cpp
linux/magi/native/lock/src/wayland_owner.hpp
linux/magi/native/lock/tests/auth_test.cpp
linux/magi/native/lock/tests/binary_gate.cmake
linux/magi/native/lock/tests/controller_test.cpp
linux/magi/native/lock/tests/presentation_test.cpp
```

Tests A, B and C were each individually approved with fresh TTY confirmation.
No further live test is authorized. The legacy timer diagnostic suffix says authenticated
acceptance FAILED: this is correct for an unauthenticated recovery, even when a
Phase 5 failure-containment test passes.

## Accepted live evidence — 2026-10-17

**PROVEN LIVE:** all three tests acquired a real compositor-confirmed session lock
on eDP-1 (1920×1080 logical, 3840×2160 scale 2). Each had exactly one generation-1
attempt and no retry or second worker. All logged CREDENTIAL CLEARED and worker
reap. Failure invalidated authorization through the reviewed native path; no
AUTHENTICATED UNLOCK appeared. The operator confirmed full coverage after failure,
no desktop leakage, no literal input, bounded failure/error presentation, and a
clean return only at emergency recovery.

| Test | Observed failure and cleanup | Recovery after lock confirmation |
|---|---|---|
| A: real wrong password | Existing hyprlock service, ordinary UID 1000; PromptEchoOff; AUTH FAILED / AuthenticationFailed; worker 515762 reaped; proof 515731 exited 0 | UNSAFE DEVELOPMENT TIMER UNLOCK, approximately 90.04 s |
| B: synthetic crash | Validated crash fixture; no PAM call; WORKER ERROR and WORKER CRASH/TERMINATED; worker 517447 reaped; proof 517388 exited 0 | UNSAFE DEVELOPMENT TIMER UNLOCK, approximately 90.01 s |
| C: synthetic hang | Validated hang fixture; no PAM call; AUTH TIMEOUT at approximately 5.00 s after attempt start; signal termination/reap approximately 2.02 s later; worker 519242 reaped; proof 519213 exited 0 | UNSAFE DEVELOPMENT TIMER UNLOCK, approximately 90.00 s |

B and C each had read-only Hyprland observations of locked=true at approximately
20/40/60/80 seconds. A's status query completed after recovery; its post-failure
coverage is supported by operator observation and the logged lifecycle, not an
intermediate compositor-status sample. All three ended with compositor sync and
Hyprland unlocked. C's termination timing and signal-exit log match the reviewed
Cancel → two-second grace → SIGKILL policy; the exact signal number was not separately
logged. The emergency timer is distinct from auth timeout and is never authentication.

All three post-test snapshots matched **510/510 files**, including PAM, protected
operator state and production routing/configuration. Original MAGI PID 1543 and
Hypridle PID 1541 and their start times remained unchanged. Hyprlock stayed installed;
proof/worker processes were gone after recovery. No input content or length was
captured. Tests B/C required no real password and never called PAM. Test A is the
only real PAM attempt in Phase 5; it was not repeated.

**PROVEN BY AUTOMATED TESTS:** complete current-generation Success authorization;
stale/duplicate/delayed result rejection; malformed/oversized/version/order IPC;
cancellation and EOF; spawn failure; retry gating until cleanup; QML/presentation
failure; owned-buffer clearing; synthetic-secret non-leakage; default-build absence
of emergency unlock and failure injection. These tests remain distinct from live
coverage and do not imply live testing of every protocol/PAM failure combination.

**STILL UNPROVEN:** multiple physical outputs and hotplug/removal while locked;
broader keyboard layouts; suspend/resume; Hypridle production migration; compositor
failure/restart; real MFA/fingerprint; production PAM/account policy; packaging and
install paths; production routing; final MAGI UI; eventual Hyprlock retirement.
No Phase 6 implementation or production migration is included in this checkpoint.
