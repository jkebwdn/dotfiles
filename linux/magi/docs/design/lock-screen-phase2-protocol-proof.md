# MAGI Lock Screen — Phase 2 native protocol proof checkpoint

Date: **2026-10-17**. Baseline: `317abcd001c2d90a43cec6a16132865f3b0c089e`
(`docs: research MAGI lock screen architecture`).

**Phase 2 single-output native acceptance passed on 2026-10-17.** Builds and
non-locking component tests pass. The native lock-owner direction is validated
sufficiently to proceed to Phase 3; the complete lock-screen architecture is not
production-complete. No PAM or production migration has occurred.

## Accepted native test evidence

Exactly one operator-approved invocation of the existing development build ran:

```bash
/tmp/magi-lock-dev-build/magi-lock-proof \
  --acquire-session-lock \
  --unsafe-development-unlock-after=60
```

Bounded user-journal diagnostics recorded manager version 1 binding, lock request,
one output (registry ID 72), one lock surface, and configure serial 0 with logical
size **1920×1080**. The connected display was **eDP-1** (3840×2160, scale 2).
`ext_session_lock_v1.locked` confirmed acquisition at 19:25:38.991437;
the explicit development release occurred at 19:26:39.001748, approximately
**60.010 seconds after confirmation**. Compositor sync completed at
19:26:39.002235 and the proof exited with status 0. No fallback or protocol error
was logged; Qt diagnostics went to the user journal rather than terminal output.

The operator confirmed full-display coverage throughout the lock and transitions,
no underlying desktop/window exposure, and containment while deliberately pressing
Escape, Super+Space, Super+E, Super+M, Super+Enter, Super+Q and other keys.
None escaped the lock or exposed underlying content. The desktop returned normally
without visible glitches after the timed release.

Post-test checks found the proof gone and Hyprland unlocked. MAGI Quickshell
(PID 1543) and Hypridle (PID 1541) remained running with their original PIDs.
All 488 snapshotted files matched immediately after the test, including protected
state; Hyprlock remained installed and production routing/PAM remained untouched.

**Proven now:** real single-output acquisition and compositor-confirmed native
state; secure visible coverage of that output; input/shortcut containment in the
observed use; clean explicit unlock; independent native lock ownership in a
separate process while the normal shell continued running. Shell-crash independence
is an architectural property, not a crash test result.

**Still unproven / future security acceptance:** monitor hotplug while locked,
multi-output native observation, locker crash/process-kill behaviour, compositor
failure/restart, suspend/resume, Hypridle production migration, PAM authentication,
credential input, and final lock-screen UI. No additional native tests are authorized
by this checkpoint. Phase 3 implementation has not begun.

The accepted direction remains a dedicated native Qt/Wayland lock owner and native
canonical state, presentation-only QML with no raw credentials, a separate narrow
native authentication-worker boundary, and Hyprlock as production/fallback.

## Architecture and bounded scope

Self-contained `linux/magi/native/lock/`, C++20, CMake, Qt Core/Gui/Quick/Qml and
libwayland-client. There was no existing MAGI native CMake convention; the existing
clipboard helper is a bounded C utility built on first use. The new proof has its
own explicit out-of-tree build instead of changing that helper or the main shell.

```text
magi-lock-proof (standalone ordinary-user process)
  Controller: canonical native state + output/configure bookkeeping
    Backend interface → WaylandOwner: one private wl_display connection
      registry / compositor / SHM / ext_session_lock_manager_v1
      ext_session_lock_v1 → one ext_session_lock_surface_v1 per wl_output
      native memfd SHM pixels → ack / attach / commit
    Presentation: embedded QML → public QQuickRenderControl → native pixels
      failure → native solid-colour pixels; no unlock capability
Main MAGI Quickshell remains independent and unchanged.
```

The proof uses public **offscreen** Qt Quick rendering rather than a private Qt
Wayland shell plugin. `QQuickRenderControl`/`QQuickRenderTarget::fromPaintDevice`
render directly into a QImage backed by the same pixels submitted through SHM.
Qt uses offscreen QPA/software Quick, owns no native display connection/window,
and never calls show(). Native code owns all Wayland surface roles and commits.
This is not an ordinary fullscreen window or layer-shell overlay. There is no
nested compositor or cross-process renderer/FD-sharing arrangement.

This refines the provisional Phase 1 Qt integration approach without rewriting
its historical report. Private Qt Wayland development headers exist locally but
are **not required by this implementation**. Software SHM is intentionally enough
for the static proof. It is not a decision about the final GPU renderer or input
path, and compiling it does not finalize the architecture decision.

### Exact path scope

Added:

```text
linux/magi/native/lock/
  CMakeLists.txt
  README.md
  qml/Proof.qml
  src/controller.hpp
  src/controller.cpp
  src/options.hpp
  src/options.cpp
  src/presentation.hpp
  src/presentation.cpp
  src/wayland_owner.hpp
  src/wayland_owner.cpp
  src/main.cpp
  tests/controller_test.cpp
  tests/presentation_test.cpp
  tests/binary_gate.cmake
linux/magi/docs/design/lock-screen-phase2-protocol-proof.md
```

One existing file changed: `linux/magi/.stow-local-ignore`, adding only `native`
to the package-root development exclusion so source cannot accidentally be
stowed into `$HOME/native`. No Git ignore change needed: builds are under `/tmp`.
No decision entry, Phase 1 rewrite or shell/service/config changes.

## Reverified local capabilities

| Item | Inspected result / use |
| --- | --- |
| Wayland | Package `1.26.0-1`; pkg-config wayland-client and wayland-scanner 1.26.0 |
| Protocols | Package `1.49-1`; pkg-config 1.49; pkgdatadir `/usr/share/wayland-protocols` |
| XML | `/usr/share/wayland-protocols/staging/ext-session-lock/ext-session-lock-v1.xml`; interface version 1 |
| Generator | `/usr/bin/wayland-scanner`, client-header/private-code modes |
| Qt | base `6.11.2-3`, declarative `6.11.2-2`, Wayland `6.11.2-1`; pkg-config Core/Gui/Quick/WaylandClient 6.11.2 |
| Qt native interfaces | Public RenderControl/RenderTarget and private Wayland integration/window/shellsurface headers inspected; public offscreen route selected |
| Compiler/build | GCC 16.2.1, CMake 4.4.4, Ninja 1.13.2, pkgconf 3.0.7 |
| Optional dependency | CMake reports missing Vulkan headers; software rendering does not use them. No installation required. |
| Hyprlock | `/usr/bin/hyprlock` still available; routing/config files unchanged |

CMake finds explicit required dependencies and generates glue at build time from
installed XML (not handwritten opcodes, not checked-in generated code). It binds
ext-session-lock manager **version 1**, wl_shm version 1, wl_compositor version 4,
and wl_output up to version 4. wl_compositor <4 or missing required globals abort
before requesting lock. Higher advertised versions are capped, not assumed.
This proof is Linux-specific (memfd). No Rust or PAM library dependency.

## Native state and acquisition

The pure C++ `Controller` is tested through a fake `Backend`. It contains the
state, outputs, pending/committed configure and failure markers. There is no
QML controller object, writable security property, IPC, or unlock invokable.

| Native state/event | Behaviour |
| --- | --- |
| Idle → explicit acquisition | Acquiring; one lock generation per process. Duplicate requests rejected. |
| Initial registry sync | Required globals checked, native `lock()` requested, surfaces created immediately for known outputs. Do not wait for locked before providing frames. |
| `ext_session_lock_v1.locked` | Acquiring → Locked. This is the only confirmation; log `COMPOSITOR CONFIRMED LOCKED`. |
| Initial `finished` | Failed, exit/disconnect; never report locked. |
| `finished` after locked | Failed, compositor-directed retirement; exit/disconnect without treating it as authorization. |
| Surface/QML/buffer failure | Retain native lock state; native fallback or compositor fallback for that output. |
| Explicit development timer, compiled and enabled | Locked → Unlocking, exactly one unlock request plus wl_display.sync. |
| Unlock sync completion | Idle, quit; no reacquisition in the same owner lifetime. |
| Unexpected events, transport errors/deadlines | Failed; stop event processing and exit without an unlock request. |
| Cleanup | Idempotent local proxy disposal + connection close. No generic protocol unlock or lock.destroy request. |

Discovery timeout is 5 seconds; acquisition timeout is 15 seconds. Either timeout
exits without unlock. A compositor may already have accepted an acquisition even
if confirmation has not reached the client, so timeout can leave a dead-client
locked screen. There is no automatic fallback launch or retry on another display.
A sync timeout after a development release means final state is uncertain.

The protocol recommends destructor selection for `finished` depending on whether
locked was received. This proof instead abandons the entire connection in both
cases: it never issues an unauthenticated unlock as generic retirement cleanup.
This conservative client-death route does not claim the compositor is still
locked if it had already performed its own authorized retirement.

The native Qt event loop uses read/write QSocketNotifiers. Only this owner reads
its libwayland connection; Qt's offscreen backend does not share it. Incoming
callbacks run serially, no nested display roundtrip/event loop is used, outgoing
EAGAIN is retried on write readiness. Discovery/release use asynchronous sync.

## Output, configure and buffer lifecycle

Native registry keyed by wl_registry numeric name; no fixed output count, primary
monitor dependency, output-order assumption or hardcoded resolution. Both native
protocol handles and controller records are explicit. wl_output scale/transform
are recorded; configure width/height remain authoritative for surface-local size.

- Startup outputs and outputs added during Acquiring/Locked receive a fresh
  role-specific wl_surface, before any buffer attachment/commit. No duplicate
  lock role is created for a repeated registry ID.
- Configure serial/width/height are recorded. Prepare the complete pixels first;
  acknowledge that serial immediately before non-null attach/damage/commit.
  Do not ack on rendering/allocation failure. Never commit a null buffer.
- Serial values are opaque uint32 values, including zero/wraparound. Pending
  configures are coalesced in delivery order; duplicate current/pending serials
  are ignored, not acknowledged twice. The compositor is trusted to supply a
  valid serial stream; hostile arbitrary old-serial replay detection is not a
  separate client security boundary.
- Never repaint a busy buffer. At most two in-flight buffers per output; wait for
  release and use the newest pending configure if busy. Released buffers are
  reclaimed before new allocation. Callback retries are queued, not reentrant.
- Limits: up to 64 registry outputs, 16384 per dimension, 64 MiB per frame and
  256 MiB total outstanding pixel allocations. These are resource limits, not
  assumptions about monitor count. Exceeding them fails secure, possibly without
  a visible MAGI scene. Native Qt/QML temporary allocations add overhead.
- Removal destroys only that output's role/surface/buffers and releases its output
  proxy; remaining outputs and the lock stay owned. Late queued buffer notifications
  after removal are harmless. Numeric names may be reused with fresh records.
- Invalid/oversize geometry or unrecoverable buffer allocation removes stale-sized
  client content and relies on compositor fallback; it does not recreate a second
  role for the same output or release the session lock.

Buffers use XRGB8888, scale 1 and normal buffer transform; buffer dimensions equal
configured logical dimensions. The compositor maps them onto scaled/transformed
outputs. This permits secure coverage without native-resolution/fractional quality,
which is deferred. Rotation/HiDPI/hotplug still require actual compositor observation.
Output metadata is never used to guess a physical-size fullscreen window.

## Presentation and fallback

One embedded static Rectangle/Text scene, plain text, dark opaque background,
registry output ID and obvious proof/development notice. No imported MAGI root,
Settings, profile, wallpaper, weather, media, notifications, animation or assets.
The scene renders only on configure; it labels the native state **at frame creation**.
An initial frame can continue saying Acquiring after confirmation: authoritative
readiness is the native compositor event/log, not a periodically refreshed label.

A fresh scene is rendered offscreen for each submitted configure frame and then
destroyed. This is deliberately simple, not the final interactive renderer.
Native memory starts opaque; QML parse/creation/wrong-root/render errors leave or
restore native solid colour. The fallback needs no QML/Text/font assets. A signal
from QML destruction cannot release the protocol lock because no such API exists.

If the pixel buffer itself cannot be created, the compositor must cover the output.
If Qt/renderer crashes or hangs, the fallback code may not run: process death leaves
protection to the compositor, and a hung process may require TTY recovery. No claim
of surviving arbitrary native corruption in-process. Static QML is trusted code,
not sandboxed hostile code. No runtime file/URL selector, reload or QML debug flag.

**No seat/keyboard/pointer/touch listeners are bound in Phase 2.** There is no
password input, paste, input forwarding to QML, or key-based release. Compositor
input exclusion passed the observed single-output test; future native credential input remains
unproven and is a separate prerequisite, not implied by offscreen rendering.

## Development unlock and process death

Only one development mechanism: a compile-time-gated native **one-shot timer**,
started after confirmed lock, which sends unlock_and_destroy then waits for sync.

- CMake `MAGI_LOCK_DEVELOPMENT_UNLOCK` defaults OFF. Default binary has no native
  development-unlock method or generated unlock call. It has no authentication
  and is therefore not safe to deploy as a finished locker.
- In an explicitly ON build, acquisition also requires
  `--unsafe-development-unlock-after=N`, N=10..300. Flag omitted/invalid/duplicated
  is an error. It does nothing without `--acquire-session-lock`.
- Build and startup emit explicit unsafe-development warnings. No escape key,
  signal handler, D-Bus/socket, main MAGI IPC, or QML method can release it.
- Ordinary CLI arguments are parsed before Qt or a display connection exists;
  unknown arguments, Qt plugin/debug arguments and accidental no-argument launch
  are rejected. Informational flags cannot be combined with acquisition.
- SIGINT/SIGTERM/SIGUSR1 retain default process-termination behaviour, never unlock.
  SIGPIPE is ignored so write errors can be handled. SIGKILL/abort likewise do not
  authorize unlock. Cleanup disposes lock proxies locally, not via protocol
  `destroy` after confirmation and not via `unlock_and_destroy`.

The unsafe timer is not failover or authentication. Process death/event-loop hang,
compositor loss or transport failure can prevent it firing. Protocol client-death
semantics say a surviving conformant compositor stays locked; this is source-defined
behaviour, **not observed on this build/session yet**. A compositor crash/restart
has no surviving session-lock guarantee. Hyprland restore policy may deny a new
locker after a crash; do not silently enable restore or force-clear the lock.

## Build and automated verification

Commands run without acquiring a lock (from repository root):

```bash
cmake -S linux/magi/native/lock -B /tmp/magi-lock-build -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build /tmp/magi-lock-build
ctest --test-dir /tmp/magi-lock-build --output-on-failure

cmake -S linux/magi/native/lock -B /tmp/magi-lock-dev-build -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug -DMAGI_LOCK_DEVELOPMENT_UNLOCK=ON
cmake --build /tmp/magi-lock-dev-build
ctest --test-dir /tmp/magi-lock-dev-build --output-on-failure
```

Both builds succeed. **4/4 CTest tests pass in each build**:

| Test | What it actually establishes |
| --- | --- |
| controller_production | State transitions/rejection, output add/remove/reuse, zero outputs, configure geometry/serial wrap/coalescing, failed allocation/surface/fallback paths, cleanup idempotence, production CLI gate through fake backend |
| controller_development | Same cases plus exactly one gated release only after Locked, no release on failed state, and sync transition; fake backend only |
| presentation_offscreen | Real embedded QML renders text into caller-owned 800×600 pixels with opaque coverage; invalid QML/wrong root yields uniform native fallback; portrait and null-image cases. Offscreen only, no Wayland socket/window |
| binary_gate | Executes only help/build-info/rejected flags, inspects native symbols with nm; default binary lacks development unlock implementation, development binary identifies/contains it |

Fake backend tests do not certify the real adapter's wire traffic, compositor
buffer release or physical display frames. Automated tests acquired no real or
nested compositor lock and did not execute the adapter start method. The separately
approved native run is recorded above; no crash/suspend test was run. All generated code, executables and CMake caches stay under `/tmp`.

## First native run procedure — retained for reference

**Executed once and accepted as recorded above. Do not rerun without fresh explicit
operator approval.** This procedure is historical test guidance, not authorization
for additional tests. A disposable graphical session may offer stronger isolation.

### Preflight

1. Save work. Confirm an authenticated TTY recovery route that works on this
   machine; do not discover its availability after the lock is stuck.
2. Confirm `command -v hyprlock` returns the existing binary and inspect the
   unchanged Hypridle `lock_cmd = pidof hyprlock || hyprlock`. Do not invoke two
   lockers or change production routes. Avoid the normal idle/suspend trigger
   during the short test; do not change Hypridle to accomplish this.
3. Confirm the development build's `--build-info` reports `development-unlock=1`.
   Never substitute `/tmp/magi-lock-build/` (the default no-release binary).
4. Record active outputs and the graphical logind session ID using read-only
   `hyprctl monitors` and `loginctl list-sessions`. Identify the graphical session
   separately from a recovery TTY. Do not terminate anything in preflight.
5. Understand recovery: startup prints the proof PID. In a recovery TTY,
   `kill -TERM <printed-proof-pid>` stops a hung proof **without unlocking**.
   If no secure recovery is available, `loginctl terminate-session <graphical-session-id>`
   can end that graphical session, losing unsaved work. This is a last-resort
   operator action, not part of the first test. Do not run broad pkill, assume
   Hyprlock can take over, enable restore, or clear lock state automatically.

### Approved command

Run from a terminal in the target graphical session **only after approval**:

```bash
/tmp/magi-lock-dev-build/magi-lock-proof \
  --acquire-session-lock --unsafe-development-unlock-after=60
```

The 60-second countdown starts on the compositor's locked event, not process
startup. Wait for the automatic development release; there is no unlock key.
No destructive kill/crash tests, suspend tests or main-shell restarts in this run.

### Observe

- Native diagnostic must report `COMPOSITOR CONFIRMED LOCKED`, not merely requested.
  Review the terminal log after returning; a separate already-authorized observer
  may query `hyprctl locked` read-only. Postflight reported unlocked; the journal supplied lock confirmation.
- Every connected output must be covered, including the laptop and external
  display. Record any blank fallback, missing text, desktop flash or size error.
- Try ordinary workspace/window/Apps/Hub/Control Centre shortcuts. They must not
  reveal the desktop or deliver input into underlying applications. Existing
  locked brightness/volume bindings are expected to remain compositor policy.
- Hotplug was excluded from this run and remains a separate approval gate.
  Do not conflate startup coverage with hotplug acceptance.
- Timer release should log the explicit unsafe-development unlock and subsequent
  compositor sync. Normal desktop resumes, process exits, terminal returns.

### Postflight

Verify the printed proof PID no longer exists (`ps -p <printed-proof-pid>`), inspect
its exit status/log, and recheck the unchanged Hypridle/Hyprlock/MAGI routing files.
Normal user-facing lock still routes through Hyprlock. No migration or rollback
is needed because the production path never changed. Report observations before
any second run or more disruptive failure test.

## Remaining gates and Phase 3 prerequisites

- Real Hyprland 0.56.2 acquisition, configured single-output coverage and sync exit
  passed this run. Mixed-scale/rotation, multiple outputs, output wake/removal/addition
  and broader driver behaviour remain unverified.
- Native fail-secure crash behaviour, presentation fault under hotplug, compositor
  retirement/disconnect and recovery require separately approved tests after the
  successful first run. Unit tests are not substitutes.
- Native seat/XKB/input ownership and a credential path that never forwards raw
  input into QML must be designed/proven before authentication UI. None exists now.
- Select and review the later PAM worker/IPC boundary and policy separately; no
  Rust, PAM calls, password buffer or auth template was introduced here.
- Software snapshot rendering may be sufficient for basic future UI but retained
  scenes/GPU/fractional polish and responsive input need a later measured design.
- Effective compositor privilege/xray/above-lock/restore/capture policy and the
  limits on malicious same-UID code from Phase 1 still apply.
- Hypridle mode-3 readiness/suspend deadline integration remains a later milestone;
  no lock-before-suspend guarantee is added by this isolated proof.

The native owner portion has passed operator acceptance. This does not finalize
the entire architecture or remaining security gates in `decisions.md`. Phase 3 has
not begun.

## Preservation and evidence

Before editing, `git status --short` was captured and content hashes recorded for
all tracked/untracked nonignored repository files, protected live Hypr files and
`/etc/pam.d`. The only intentional pre-existing file edit is the narrow Stow ignore
rule. The Phase 1 report and decisions remain unchanged. Protected Settings,
application-theme integration, Hyprland/Hypridle/Hyprlock, shell/nvim/Yazi runtime
state are outside the edit scope. No package install/removal, sudo, service restart,
PAM call or production command rerouting occurred. One real lock test was separately
approved and accepted; the operator subsequently authorized this Phase 2 checkpoint
commit and push, limited to the exact implementation/documentation allowlist.

Final validation: both configure/build variants and all 4 tests per variant
passed. `git diff --check` passed; a separate scan covered the untracked source
and checkpoint for trailing whitespace. Before/after hashes found no changes to
any pre-existing file except the allowlisted `.stow-local-ignore`; live Hypr and
PAM files also matched. The only new paths are the native proof files listed above and this checkpoint.
No generated build artifacts exist in the source tree. The single approved native
test is recorded above; no additional lock test is part of checkpoint finalization.

Sources inspected 2026-10-17:

- Accepted [Phase 1 audit](../research/lock-screen-architecture.md), including its
  pinned Hyprland/Quickshell source findings and protocol requirements.
- Installed wayland-protocols 1.49 XML and generated-client API; inspected upstream
  [ext-session-lock specification](https://gitlab.freedesktop.org/wayland/wayland-protocols/-/blob/main/staging/ext-session-lock/ext-session-lock-v1.xml)
  in Phase 1. The same installed XML was re-read for this implementation.
- Installed Qt 6.11.2 public RenderControl/RenderTarget and private Wayland headers;
  [Qt 6.11 RenderControl](https://doc.qt.io/qt-6.11/qquickrendercontrol.html) documents
  offscreen ownership and the software-specific frame sequence; [RenderTarget](https://doc.qt.io/qt-6.11/qquickrendertarget.html#fromPaintDevice)
  provides the public paint-device target. Verified with the real offscreen test.
  No upstream implementation source was copied; generated protocol notices remain
  in build output. Software rendering avoids the private ABI considered in Phase 1.
