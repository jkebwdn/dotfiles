# MAGI Lock Screen — Phase 4 authenticated-unlock integration

Date: 2026-10-17. Baseline: `9d5a866384fd3a4b0a5630a36793180b57d6c171`
(`magi: prove PAM authentication worker`). **Accepted: implementation, automated tests and one operator-approved live
authenticated-unlock test.** The live test is complete; no further real lock or
password test is authorized by this checkpoint.

## Evidence boundary and architecture

Phase 2 independently accepted real ext-session-lock ownership on one eDP-1 output.
Phase 3 independently accepted exactly one ordinary-user PAM success with the existing
hyprlock service. That live observer did not capture PAM message styles. The accepted Phase 4 run below additionally proves the combined success lifecycle
and native keyboard capture on the current single output. A wrong password while
locked and multi-monitor/hotplug behaviour remain unproven. Earlier checkpoints
remain unchanged.

```text
wl_keyboard on the owner's Wayland connection
    → native xkb translation → Credential → AuthController
    → private inherited socketpair → one Rust worker → Linux-PAM
    → bounded result + checked child exit + attempt generation
    → native LockController authorization → Wayland unlock_and_destroy + sync

AuthPresentation (count, active, caps, status) → offscreen QML → native SHM pixels
```

The native C++ owner remains authoritative. No keyboard event, text character,
response, credential object or auth-controller QObject is exposed to QML. The
Rust worker never owns Wayland or sends an Unlock command. Hyprlock remains the
production locker; no routing, keybind, Hypridle, loginctl, Settings or PAM-policy
changes are made.

## Input research and local verification

Installed libxkbcommon **1.13.2** and Wayland client **1.26.0** have working
pkg-config metadata and `/usr/include/xkbcommon/xkbcommon.h` /
`/usr/include/wayland-client-protocol.h`. CMake links xkbcommon explicitly; compose
is part of the same library. No new package is required. Qt remains offscreen,
using the existing software RenderControl and SHM path; no QtWayland input path
or hidden ordinary window is introduced.

Sources inspected 2026-10-17:

- [Wayland wl_keyboard specification](https://wayland.freedesktop.org/docs/html/apa.html#protocol-spec-wl_keyboard),
  checked against installed 1.26.0 generated declarations: keyboard capability
  lifecycle, enter/leave, serialized modifiers, keymap FD, evdev keycodes and repeat
  events. The owner binds seat version 7 and uses MAP_PRIVATE for keymap mapping.
  Runtime key delivery passed in the accepted single-output live test.
- [xkbcommon 1.13.2 keyboard state](https://xkbcommon.org/doc/current/group__state.html):
  clients consume server modifier masks using update_mask; they should not maintain
  a competing server state using update_key. The implementation uses evdev+8,
  key_get_utf8 and the locked Caps modifier. It keeps translation in native bytes.
- [xkbcommon compose](https://xkbcommon.org/doc/current/group__compose.html):
  feed/status/get_utf8/reset supports native compose/dead-key handling. The proof
  creates a C.UTF-8 compose table, clears composition at editing controls/focus
  boundaries, and makes no claim of testing every locale or input method.
- [glibc explicit erasure](https://sourceware.org/glibc/manual/latest/html_node/Erasing-Sensitive-Data.html):
  explicit_bzero resists dead-store removal but cannot erase invisible copies.
  This is the same platform primitive used by Phase 3; no erasure library is added.

No upstream implementation code or assets are copied. These are API/semantic
references, not blanket upstream/security certification.

## Keyboard ownership and credential lifetime

`NativeInput` uses one selected wl_seat and its wl_keyboard. Pointer/touch/data-device
interfaces are not bound. Input is accepted only after compositor-confirmed Locked,
with keyboard focus on a surface owned by this lock instance and a valid keymap
and modifier state. The key array on enter never becomes typed text. Keymap size
is capped at 1 MiB; unsupported/invalid maps disable input while keeping the lock.
The keymap FD closes on all paths. Keyboard capability removal, seat removal,
focus loss and keymap replacement clear input/cancel the current attempt. The
first seat is selected; multi-seat switching is a later gate. Output handling
remains one surface per output and retains the existing registry/hotplug structure.

The owner retains non-secret modifier masks so a modifier event arriving before
lock confirmation does not strand the first typed character. xkb logs are suppressed.
No raw key event or keysym is logged. Repeat_info is deliberately ignored and duplicate
key-down events are suppressed: this proof has no autorepeat, including Backspace.
Qt never receives these events. Input-method/preedit, paste and on-screen keyboard
support are not implemented.

`Credential` is a noncopyable/nonmovable native object containing a fixed
`std::array<char, 511>`, used-byte count and scalar count. UTF-8 append rejects
invalid/overlong sequences, surrogates, out-of-range scalars, NUL/control characters
and capacity overflow without partial append. Backspace removes one Unicode scalar
safely, not a full grapheme cluster. xkb translation uses a bounded temporary
64-byte native array, erased on scope exit; no QString conversion of credentials.

Enter with non-empty input submits once; empty Enter does nothing. Escape and
Ctrl+U clear, and cancel an active attempt without unlocking. Ctrl+V and all other
Ctrl shortcuts are ignored; Insert (including Shift+Insert), Alt and Super input
are ignored. Shift and ordinary AltGr/level modifiers remain xkb-driven; exotic
Ctrl/Alt-based layout variants require later testing. Caps Lock is presentation-only.
A layout label is deliberately omitted rather than exposing arbitrary keymap text.

The auth controller owns the buffer from editing through spawn/first prompt. It
clears immediately after the response send, and on spawn failure, PAM result,
malformed IPC, cancellation, focus loss, timeout and destruction. Backspace erases
removed bytes. Packet send/receive scratch arrays also erase on scope exit with
explicit_bzero. No credential byte/length appears in application diagnostics.

Limits: the count intentionally crosses the presentation boundary for bullets,
but is not logged. Kernel events/socket queues, xkb compose internals, register or
stack spills, PAM/module allocations and privileged capture remain outside native
owned-buffer guarantees. No mlock or whole-system zeroization is claimed. Core
dump limits are set to zero before acquisition. Fatal signals/OOM/native corruption
can skip destructors; process isolation is not protection from hostile same-UID code.

## Presentation and frame updates

Only `AuthPresentation {count, active, caps, state}` reaches the renderer. Additional
existing inputs are output ID label, native lock state and the development notice.
The fixed QML root has only corresponding scalar/string presentation properties;
there are no TextField/TextInput/Keys handlers, clipboard access, context security
objects or callable unlock methods. Bullets are generated from a clamped scalar
count. Status text is selected from native constants, never PAM prompt contents.

The UI is intentionally basic: lock label, bullets, input status, Caps Lock and
emergency notice. Native QPainter fallback gives opaque coverage with lock/auth
status and Caps Lock, without secret text. QML failure cannot authorize unlock or
change native input ownership. Even a success-looking presentation is not an
authentication result. Unrecoverable buffer/surface failure preserves the earlier
compositor-fallback/fail-secure behaviour.

Input/status changes coalesce over 16 ms before a redraw. Controller tracks dirty
content separately from pending configure: repainting an existing-sized frame does
not acknowledge the same configure serial again. At most two in-flight buffers per
output and the existing global memory cap remain. Busy buffers are never repainted;
release retries a deferred refresh. This preserves Phase 2 configure ordering and
output registry architecture. Physical output hotplug testing is not expanded here.

## Authentication attempt and IPC

States: Idle, Editing, Authenticating, Failed, WorkerError, Unsupported, Cancelled,
Succeeded. A monotonic u64 generation identifies each attempt; wrap is rejected.
Only one worker can exist. Input is frozen during auth, and repeated Enter cannot
spawn another child. Failure/error/cancel allows editing only after the child is
reaped and a 1500 ms retry delay completes. No custom password verification, retry
loop or replacement for PAM's own delays/faillock policy exists.

C++ uses socketpair(AF_UNIX, SOCK_SEQPACKET | SOCK_CLOEXEC), then posix_spawn with
explicit file actions: child endpoint → FD 3, stdio → /dev/null, close FDs >=4.
The parent closes its child endpoint; child FD 3 survives only its initial exec.
The unchanged Rust worker validates socket type, unnamed endpoints, creator parent
PID/UID, makes FD 3 CLOEXEC and rejects root/setuid/setgid execution. Parent also
rejects elevated/mismatched identity. Environment is only PATH=/usr/bin and LANG=C;
signal mask/defaults are reset for the worker. No filesystem/public socket exists.

The parent does not use a shell, service, arbitrary username or request-selected
worker. CMake's explicit absolute prebuilt-worker option is a development build
input; the empty default resolves an installed sibling. Selecting the correct
trusted worker binary is part of build/package review. Same-UID executable replacement
and dynamic loader compromise are outside this proof. The Rust service remains
hardcoded `hyprlock`, authentication-only, with no account/session/credential-policy
changes. The dedicated-service/pam_acct_mgmt production decision remains open.

C++ implements the existing `MAG3` version 1 wire contract: 12-byte header,
big-endian IDs/lengths, payload <=512, response <=511, no JSON. Every frame has exact
length/version/type/state checks. Prompt IDs are sequential with a maximum of 64.
MSG_TRUNC detects oversized records; all sends/receives are nonblocking. The event
loop polls at 10 ms with at most eight packets per drain, without nested event loops.
PAM remains isolated from the Qt/Wayland event loop.

Conversation policy is deliberately narrower than the protocol:

- Hello is required before HelloAck. No response can precede the matching prompt.
- Info and Error are acknowledged; only their type is logged, not their text.
- The first PromptEchoOff receives the submitted buffer, then that buffer is erased.
- A further hidden prompt returns Unsupported and sends Cancel. Credentials are
  never cached/replayed or guessed for another prompt.
- PromptEchoOn also returns Unsupported. PAM_USER is already fixed by UID in the
  worker. Arbitrary echo-on text cannot reliably establish that it asks for a
  username, so this proof does not guess a username or offer QML editing.
- No-prompt Success is rejected by this password-proof policy. Future zero-prompt
  fingerprint/MFA acceptance needs explicit policy/UI review; the Phase 3 protocol
  and worker still support general conversations. No fprintd code is introduced.

On rejection, cancellation is best effort; cleanup and absence of unlock do not
depend on a cooperative peer. Unsupported conversation is a locked error state,
not a fallback verifier or an alternate success path.

## Unlock authorization and failure handling

AuthController privately holds the result and its generation. A success callback
is emitted only after a well-formed Success, credential submission, EOF without
extra packets, and waitpid confirmation that this exact spawned child exited with
status 0. Rust sends the result after pam_end and its PAM_USER check. Exit status
alone, EOF alone, success-looking QML state and synthetic keyboard shortcuts never
create success. A Success followed by extra data or abnormal child exit is rejected.

Controller::authenticatedUnlock requires canonical confirmed Locked state and
consumes the AuthController's current successful generation exactly once. Old,
cancelled, mismatched or consumed generations cannot unlock. This native interface
is not exposed to QML, shell IPC or other processes. Only the owner's backend then
marshals unlock_and_destroy, waits for display sync, and exits. Sync timeout or
compositor loss cannot establish a successful return; recovery is not inferred.

AuthenticationFailed, PamError, ProtocolError, WorkerError, crash, disconnect,
spawn failure, unsupported prompt and timeout clear credentials and remain locked.
After bounded cleanup/delay a deliberate new submit is possible. A 120-second
attempt timeout plus two-second cancellation grace bounds a stuck worker; SIGKILL
and waitpid complete cleanup. Rust's existing 125-second alarm is a final backstop.
Cancellation never accepts a late success. Forced worker termination cannot guarantee
PAM-internal cleanup. Destructor kills/reaps an outstanding child without unlocking.

SIGINT/SIGTERM/SIGUSR1 retain process-termination semantics, not authenticated unlock.
Client death relies on compositor protection as in Phase 2; this milestone does not
claim live crash/recovery acceptance. Neither a native crash nor a frozen event
loop can rely on the development timer running.

## Development emergency recovery

MAGI_LOCK_DEVELOPMENT_UNLOCK remains OFF by default. Its QTimer, backend method and
CLI flag support are compiled only in the development build. That build still
requires an explicit --unsafe-development-unlock-after=N (10..300) with acquisition.
The first proposed integrated run uses **180 seconds after compositor lock confirmation**.

Validated PAM success stops the timer before native unlock and logs
`AUTHENTICATED UNLOCK: current PAM Success`. If the timer instead fires, it cancels
the attempt and logs `UNSAFE DEVELOPMENT TIMER UNLOCK: authenticated acceptance FAILED`.
This recovery path is unauthenticated, unsafe for deployment and never acceptance
of the integrated proof. There are no Escape/signal/public IPC emergency unlocks.

Unlike the Phase 2 default binary, the Phase 4 default binary necessarily contains
authenticated unlock and sync code. Binary tests now exclude development methods
and timer symbols rather than incorrectly requiring all unlock code to be absent.

## Automated acceptance and build commands

The [native README](../../native/lock/README.md) contains exact locked/offline Cargo
and CMake commands for `/tmp/magi-lock-phase4-build` and
`/tmp/magi-lock-phase4-dev-build`. CMake never downloads or builds Rust implicitly;
BUILD_TESTING requires an explicit prebuilt `protocol_fixture` example. Neither
the fixture nor tests should be installed as a production worker.

The test-only Rust example uses the actual Phase 3 protocol/inherited-FD library
but never calls PAM. CMake creates test-local mode symlinks in its build directory;
mode selection exists only in this example, not in magi-lock-auth. C++ tests drive
native buffer → controller → real private socketpair/posix_spawn → Rust → fake lock
controller. A second scenario types the synthetic input through xkb before submission.

C++ tests cover:

- Existing lock-state/output/configure/failure cases and CLI gates in both builds.
- UTF-8 append, capacity rejection, scalar Backspace, erasure/clear/destruction;
  no-focus input, empty Enter, duplicate key-down, Escape, Ctrl+U, Caps Lock,
  paste rejection and spawn-error clearing.
- Synthetic keyboard-to-Rust success; Info/Error/hidden prompt; safe rejection of
  echo-on and repeated prompts; failed result, PamError, crash, exit-only, timeout,
  version mismatch, truncated/oversized/unknown frames, wrong prompt ID, zero-prompt
  success, success followed by abnormal exit, and extra frame after success.
- Concurrent-submit blocking, retry after failure, cancelled prior success,
  stale generation before/during/after another attempt, one-shot success consumption,
  no unlock before Locked, cancellation/timeout kill-and-reap, and repaint without
  duplicate configure acknowledgement.
- Development authorization requiring both compile-time and explicit enablement;
  default binary lacks development-unlock symbols and rejects its CLI flag.
- Real offscreen QML and native fallback rendering for every auth presentation
  state; invalid QML and success-looking presentation leave the fake lock locked.
  Structural QML property allowlist/input-boundary checks.
- Captured native diagnostics exclude the known synthetic secret. Raw prompt text,
  payloads and input counts are not logged. Rust's independent secret-output tests
  and TTY cleanup regression remain intact.

This is deterministic synthetic evidence, not certification of live input focus,
compositor wire timing, every Unicode layout, or a real failed password. No worker
PAM source or Cargo dependency changed. Final test results are recorded below.

## Accepted first real combined test — historical procedure; do not repeat

The operator explicitly approved and accepted exactly one combined real lock/PAM
success attempt. This historical procedure does not authorize another run. Do not repeat Phase 3 real authentication
while unlocked and do not run a real wrong-password test.

Preflight after approval:

1. Save work; confirm an already authenticated TTY recovery route. If the owner
   crashes/hangs, killing it does not unlock. Session termination from that TTY
   may be last-resort recovery with loss of unsaved work; do not discover this
   route while stranded. Do not force-unlock or alter restore policy.
2. Confirm Hyprlock installed and normal MAGI/Hypridle processes running; record
   their PIDs without restarting them. Confirm current outputs (one eDP-1 expected
   from accepted Phase 2, but recheck rather than assume). If different, review scope.
3. Compare hashes of the reviewed default/dev binaries and real Rust worker,
   recheck the dev CMake worker path (never the fixture), and inspect --build-info
   on both binaries. Default must say development-unlock=0; dev must say =1.
4. Confirm the runtime command enables authentication and the 180-second emergency
   timer, which starts on the compositor's locked event. Keep production routing
   untouched; avoid triggering an overlapping ordinary locker during this manual run.

Exact command used for the accepted single run:

```bash
/tmp/magi-lock-phase4-dev-build/magi-lock-proof \
  --acquire-session-lock --authenticate --unsafe-development-unlock-after=180
```

Wait for compositor confirmation and the minimal lock UI. Type the account password
once; literal characters must not appear, only count-derived bullets. Enter starts
one PAM attempt. Acceptance requires `AUTHENTICATED UNLOCK`, timer cancellation,
compositor sync and immediate desktop return well before 180 seconds.

If PAM fails or does not unlock, **do not retry**. Wait for the emergency timer and
record authenticated-unlock acceptance as FAILED if it fires. The timer cannot
rescue a dead/frozen owner; use the prearranged TTY recovery if necessary. Do not
add a wrong-password, kill, hotplug or suspend experiment to this first run.

Postflight: verify both proof and worker exited, return cause was PAM Success,
original MAGI/Hypridle processes remain, and production routing/PAM/protected-file
hashes match. Collect bounded types/results/PIDs only, never credential text/length,
raw PAM text, IPC dumps or memory dumps. Report before any additional attempt.

## Still unproven — future security gates

Separately approved real wrong-password/worker-failure behaviour while locked;
crash/recovery; additional layouts, Unicode/compose/input methods and multi-seat
policy; multiple outputs/hotplug/DPMS; live MFA/fingerprint/module combinations;
production account management/dedicated PAM service; retry UX and abuse policy;
trusted packaging and upgrade compatibility; final input/presentation review;
Hypridle lock-before-suspend/readiness integration. No visual polish, production
migration, suspend changes or next-phase work is included here.

## Final non-disruptive validation and preservation

- Default and development C++ builds succeed. Each CTest configuration passes
  **7/7** tests: controller_production, auth_production, controller_development,
  auth_development, presentation_offscreen, presentation_boundary, binary_gate.
  These aggregate the cases above; they never acquire a real lock.
- Rust locked/offline tests: **18 passed**, including three subprocess fixture
  entries as described in Phase 3. Clippy all-targets with warnings denied and
  cargo fmt --check pass, including the new test-only example.
- Native captured-log synthetic-secret check, Rust leakage tests, native input/IPC
  integration and fallback/QML boundary checks pass. No real password is used.
- git diff --check and a scan of all changed/new text files pass. No compiled
  binaries/build outputs are in the change set; all build trees are under /tmp.
- The 499-file starting snapshot covers tracked/untracked nonignored repository
  files plus /etc/pam.d and live Hypr configurations. Every pre-existing file
  outside native/lock matches its starting SHA-256. Protected local/runtime state,
  earlier checkpoints, PAM, Hyprlock, Hypridle and production routing are unchanged.
- The index is empty. No install or service restart occurred. Implementation and automated checks
  used no real PAM or lock; the separately approved live run is recorded below.

Build identity for the proposed review (recheck immediately before any approved run):

```text
default: 9e9f4148be28da1c7f70f3a270bfbfae8f3a6415c8b99742d106d54179fd43fc
development: 304ba087200ca739da4c7dc3d0e3ead14e31cb8fd62f0a65a6b4177f6e7a544e
Rust worker: 3cd88d189993a7e85ed1019d0e20e1b497d9725cea4988c43d102f2c6d0c56b7
```

Both CMake trees point MAGI_LOCK_AUTH_WORKER to the reviewed
/tmp/magi-auth-build/debug/magi-lock-auth; their fixtures point separately to the
/tmp/magi-auth-phase4/debug/examples/protocol_fixture test executable. Informational
--build-info calls report development-unlock=0 and =1 respectively, native auth
available and explicit --authenticate required. These calls make no display connection.

Exact changed paths: **25**, derived from tracked diffs and new files rather than
including pre-existing operator changes:

```text
linux/magi/docs/design/lock-screen-phase4-authenticated-unlock.md
linux/magi/native/lock/CMakeLists.txt
linux/magi/native/lock/README.md
linux/magi/native/lock/auth/examples/protocol_fixture.rs
linux/magi/native/lock/qml/Proof.qml
linux/magi/native/lock/src/auth_controller.cpp
linux/magi/native/lock/src/auth_controller.hpp
linux/magi/native/lock/src/controller.cpp
linux/magi/native/lock/src/controller.hpp
linux/magi/native/lock/src/credential.cpp
linux/magi/native/lock/src/credential.hpp
linux/magi/native/lock/src/main.cpp
linux/magi/native/lock/src/native_input.cpp
linux/magi/native/lock/src/native_input.hpp
linux/magi/native/lock/src/options.cpp
linux/magi/native/lock/src/options.hpp
linux/magi/native/lock/src/presentation.cpp
linux/magi/native/lock/src/presentation.hpp
linux/magi/native/lock/src/wayland_owner.cpp
linux/magi/native/lock/src/wayland_owner.hpp
linux/magi/native/lock/tests/auth_test.cpp
linux/magi/native/lock/tests/binary_gate.cmake
linux/magi/native/lock/tests/controller_test.cpp
linux/magi/native/lock/tests/presentation_boundary.cmake
linux/magi/native/lock/tests/presentation_test.cpp
```

The operator accepted Phase 4 and authorized this checkpoint commit/push. No further
real test, visual polish, production migration or later-phase implementation is included.

## Accepted live evidence — 2026-10-17

**PROVEN LIVE:** the single approved run acquired a compositor-confirmed
ext-session-lock-v1 lock on eDP-1, with a 1920×1080 logical surface (3840×2160,
scale 2). The operator confirmed complete visible coverage, no underlying desktop
exposure, native credential entry with bullets only, and a visually clean return.
QML remained presentation-only; raw credential bytes stayed in native code.

Native wl_keyboard initialization succeeded. Exactly one attempt (generation 1)
used the existing hyprlock PAM service as ordinary UID 1000 over the private
inherited AF_UNIX/SOCK_SEQPACKET channel. The only observed live conversation
style was PromptEchoOff. Worker PID 506281 returned Success and was reaped cleanly.
The current-generation success authorized the native owner, PID 506214, to request
explicit compositor unlock. Its journal recorded AUTHENTICATED UNLOCK about
11.05 seconds after lock confirmation, followed by compositor sync completion;
the proof exited with status 0. The emergency timer did not fire.

Credential erasure and timer cancellation are established by the reviewed success
path, not separate runtime log events. Generation 1 follows from the first and
only attempt; the log does not separately print its numeric generation. No password,
response content or credential length was captured. Qt events were recovered from
the proof PID's journal through a bounded allowlist; no PAM text was collected.

Hyprland reported unlocked afterward. Original MAGI PID 1543 and Hypridle PID 1541
and their start times remained unchanged; Hyprlock remained installed. All **509**
pre-test file hashes matched afterward, including protected state, PAM files,
Hyprlock/Hypridle configuration and production routing. No retry occurred.

**PROVEN BY AUTOMATED TESTS:** credential editing, explicit owned-buffer clearing
and bounds; synthetic xkb input; private C++↔Rust IPC; stale-generation rejection;
malformed IPC; worker crash/error handling; timeout; cancellation; retry cleanup;
QML failure remaining fail-secure; presentation-only credential boundary; synthetic
secret non-leakage; and default-build absence of development unlock. These tests
do not constitute live acceptance of failure paths while locked.

**STILL UNPROVEN:** real wrong-password, worker-failure and timeout/recovery paths
while locked; multi-output and physical hotplug; suspend/resume and production
Hypridle integration; compositor failure/restart; broader keyboard layouts; live
MFA/fingerprint; production PAM/account policy; packaging/install paths; production
migration; and final visual design.

The core native Qt/Wayland → native credential buffer → private IPC → Rust/PAM →
bounded Success → native-owner unlock architecture is accepted for this current
single-output environment. PAM never calls Wayland or sends an Unlock command.
Only current-generation validated Success authorizes production unlock; errors
remain locked. Default builds have no unauthenticated development unlock path.
