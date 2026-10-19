# MAGI native authenticated-lock proof

**Phase 4 accepted: one real single-output authenticated unlock passed.**
Hyprlock remains production. Do not acquire a session lock or use a real password
without explicit approval for that specific run. No live installation or routing change has been made.

[Phase 2](../../docs/design/lock-screen-phase2-protocol-proof.md) accepted the native
Wayland owner. [Phase 3](../../docs/design/lock-screen-phase3-pam-proof.md) accepted
one independent ordinary-user PAM success. The
[Phase 4 checkpoint](../../docs/design/lock-screen-phase4-authenticated-unlock.md)
records their integration, accepted live result, synthetic evidence and remaining gates.

The C++20 owner binds ext-session-lock-v1 and wl_seat/wl_keyboard on one native
Wayland connection. xkbcommon translates keys directly into a bounded native
credential buffer. QML renders offscreen and receives only presentation values.
On submission, a single ordinary-user Rust child uses private inherited
AF_UNIX/SOCK_SEQPACKET IPC and the MAGI-owned `magi-lock` PAM service.
Earlier accepted live proofs used `hyprlock`; the new policy is a deployment
template only until separately approved Phase 8B installation. Only the C++
lock controller may authorize unlock for a current, validated successful attempt.

## Offline builds and non-locking tests

Dependencies: C++20, CMake >=3.25, Ninja, pkg-config, Qt >=6.8 Core/Gui/Quick/Qml,
wayland-client >=1.20, wayland-scanner/protocols >=1.25, xkbcommon >=1.0, Linux/glibc
with closefrom spawn actions and explicit_bzero, PAM development library, Rust.
Verified here: Qt 6.11.2, Wayland 1.26.0, xkbcommon 1.13.2, PAM 1.7.3,
Rust/Cargo 1.99.1. Vulkan headers are optional and unused. Install nothing
implicitly. The only Cargo dependency remains pinned libc 0.2.179.

From the repository root (these commands neither authenticate nor lock):

```bash
cargo build --locked --offline --manifest-path linux/magi/native/lock/auth/Cargo.toml --target-dir /tmp/magi-auth-build
cargo build --locked --offline --manifest-path linux/magi/native/lock/auth/Cargo.toml --target-dir /tmp/magi-auth-phase4 --example protocol_fixture

cmake -S linux/magi/native/lock -B /tmp/magi-lock-phase4-build -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug \
  -DMAGI_LOCK_AUTH_WORKER=/tmp/magi-auth-build/debug/magi-lock-auth \
  -DMAGI_LOCK_AUTH_FIXTURE=/tmp/magi-auth-phase4/debug/examples/protocol_fixture
cmake --build /tmp/magi-lock-phase4-build
ctest --test-dir /tmp/magi-lock-phase4-build --output-on-failure

cmake -S linux/magi/native/lock -B /tmp/magi-lock-phase4-dev-build -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug -DMAGI_LOCK_DEVELOPMENT_UNLOCK=ON \
  -DMAGI_LOCK_AUTH_WORKER=/tmp/magi-auth-build/debug/magi-lock-auth \
  -DMAGI_LOCK_AUTH_FIXTURE=/tmp/magi-auth-phase4/debug/examples/protocol_fixture
cmake --build /tmp/magi-lock-phase4-dev-build
ctest --test-dir /tmp/magi-lock-phase4-dev-build --output-on-failure

cargo test --locked --offline --manifest-path linux/magi/native/lock/auth/Cargo.toml --target-dir /tmp/magi-auth-phase4
cargo clippy --locked --offline --manifest-path linux/magi/native/lock/auth/Cargo.toml --target-dir /tmp/magi-auth-phase4 --all-targets -- -D warnings
cargo fmt --manifest-path linux/magi/native/lock/auth/Cargo.toml --check
```

Tests require socketpair traffic and a pseudo-terminal; the agent sandbox blocks
socket sends, so automated tests were permitted outside it. They use synthetic
credentials only. No C++ test calls WaylandOwner::start(). The Rust startup gate
test cancels before HelloAck, so it never enters PAM. The test fixture is a separate
Cargo example using the real IPC library, not a fake mode in magi-lock-auth.

CMake does not invoke Cargo or access the network. BUILD_TESTING requires the
explicit prebuilt fixture path. The worker path is a build option, not a runtime
socket/worker selector; empty means the packaged sibling `magi-lock-auth` next to
the owner. A future package should install these in a trusted directory and exclude
test fixtures. No machine-specific /tmp path is hardcoded into source defaults.
Generated protocols and binaries remain in /tmp; native/ remains Stow-excluded.

## Accepted real test — historical procedure, not authorization to repeat

First complete the checkpoint's save-work, authenticated TTY recovery, current
output/process, worker-hash and build-gate preflight. After explicit approval only:

```bash
/tmp/magi-lock-phase4-dev-build/magi-lock-proof \
  --acquire-session-lock --authenticate --unsafe-development-unlock-after=180
```

This **really locks the session and enables real PAM**. Type the current account
password once and press Enter. QML shows only bullets. Successful authentication
must log `AUTHENTICATED UNLOCK`, cancel the emergency timer, and return to the desktop
well before 180 seconds. No real wrong-password test or second attempt is included.

If authentication fails, do not retry; wait for the development emergency timer.
`UNSAFE DEVELOPMENT TIMER UNLOCK` means authenticated-unlock acceptance **failed**.
The timer starts only on compositor confirmation, is explicitly runtime-gated,
and is entirely absent from default builds. It is not a crash/hang watchdog;
process death can leave the compositor locked. Keep the checkpoint's TTY recovery
route available. Signals never authorize unlock. Do not run a destructive recovery
test, change compositor restore policy, or assume Hyprlock can take over a dead owner.

No-argument and informational invocations never connect to Wayland. `--authenticate`
alone is rejected. Without it, legacy explicit protocol-proof acquisition remains
possible but has no keyboard/PAM path. Default builds now include authenticated
unlock, **not** the old Phase 2 no-unlock implementation; they still contain no
unauthenticated timer. Do not use a default build for the first combined real test.

Production lock actions, Hypridle/loginctl routing, PAM files, broad MAGI services,
clipboard, Settings and final visual design remain outside this proof.

## Phase 5 non-locking failure validation

[Phase 5 checkpoint](../../docs/design/lock-screen-phase5-failure-resilience.md)
records the failure audit and accepted live Tests A/B/C. They must not be repeated
under this checkpoint; these build instructions authorize no live run. The real PAM
worker remains unchanged.

```bash
cargo build --locked --offline --manifest-path linux/magi/native/lock/auth/Cargo.toml --target-dir /tmp/magi-auth-phase5 --example protocol_fixture
cmake -S linux/magi/native/lock -B /tmp/magi-lock-phase5-build -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug \
  -DMAGI_LOCK_AUTH_WORKER=/tmp/magi-auth-build/debug/magi-lock-auth \
  -DMAGI_LOCK_AUTH_FIXTURE=/tmp/magi-auth-phase5/debug/examples/protocol_fixture
cmake --build /tmp/magi-lock-phase5-build
ctest --test-dir /tmp/magi-lock-phase5-build --output-on-failure
cmake -S linux/magi/native/lock -B /tmp/magi-lock-phase5-dev-build -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug -DMAGI_LOCK_DEVELOPMENT_UNLOCK=ON \
  -DMAGI_LOCK_FAILURE_INJECTION=ON \
  -DMAGI_LOCK_AUTH_WORKER=/tmp/magi-auth-build/debug/magi-lock-auth \
  -DMAGI_LOCK_AUTH_FIXTURE=/tmp/magi-auth-phase5/debug/examples/protocol_fixture
cmake --build /tmp/magi-lock-phase5-dev-build
ctest --test-dir /tmp/magi-lock-phase5-dev-build --output-on-failure
cargo test --locked --offline --manifest-path linux/magi/native/lock/auth/Cargo.toml --target-dir /tmp/magi-auth-phase5
cargo clippy --locked --offline --manifest-path linux/magi/native/lock/auth/Cargo.toml --target-dir /tmp/magi-auth-phase5 --all-targets -- -D warnings
cargo fmt --manifest-path linux/magi/native/lock/auth/Cargo.toml --check
```

Failure injection additionally requires runtime `--development-auth-failure=crash`
or `=hang`, authentication, acquisition and explicit emergency timer flags. The
fixture never calls PAM; use only fake input. Injection is absent from default
binaries. A hang selection uses a fixed five-second timeout, plus two-second
cancellation grace; normal PAM retains 120 seconds. Future live failure tests use
90-second emergency recovery and need separate approval and fresh TTY readiness.

## Phase 6 accepted multi-output validation

[Phase 6 checkpoint](../../docs/design/lock-screen-phase6-multi-output.md) records
architecture, protocol evidence, the passing synthetic matrix, the incomplete first
headless attempt, successful second headless attempt, and accepted Physical Tests
1–4 with operator visual confirmation. No further live run is authorized here.

One lock/auth/input/credential controller serves all outputs with identical safe
presentation. Output lifecycle and instance tokens are independent of auth
generations. Output focus loss suspends keys without cancelling editing or an
active attempt; output removal and per-output QML fallback no longer reset global
authentication. Seat/keymap loss, explicit cancellation and teardown still clear
credentials/cancel. This supersedes the earlier blanket focus/fallback policy.
Zero outputs remains locked. Rendering uses each configure's logical size with
scale-1/NORMAL buffers, independently of output scale/transform metadata.

Non-locking build/test commands from the repository root:

```bash
cargo build --locked --offline --manifest-path linux/magi/native/lock/auth/Cargo.toml --target-dir /tmp/magi-auth-phase6 --bins --example protocol_fixture
cmake -S linux/magi/native/lock -B /tmp/magi-lock-phase6-build -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug \
  -DMAGI_LOCK_AUTH_WORKER=/tmp/magi-auth-phase6/debug/magi-lock-auth \
  -DMAGI_LOCK_AUTH_FIXTURE=/tmp/magi-auth-phase6/debug/examples/protocol_fixture
cmake --build /tmp/magi-lock-phase6-build
ctest --test-dir /tmp/magi-lock-phase6-build --output-on-failure
cmake -S linux/magi/native/lock -B /tmp/magi-lock-phase6-dev-build -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug -DMAGI_LOCK_DEVELOPMENT_UNLOCK=ON \
  -DMAGI_LOCK_FAILURE_INJECTION=ON \
  -DMAGI_LOCK_AUTH_WORKER=/tmp/magi-auth-phase6/debug/magi-lock-auth \
  -DMAGI_LOCK_AUTH_FIXTURE=/tmp/magi-auth-phase6/debug/examples/protocol_fixture
cmake --build /tmp/magi-lock-phase6-dev-build
ctest --test-dir /tmp/magi-lock-phase6-dev-build --output-on-failure
cargo test --locked --offline --manifest-path linux/magi/native/lock/auth/Cargo.toml --target-dir /tmp/magi-auth-phase6
cargo clippy --locked --offline --manifest-path linux/magi/native/lock/auth/Cargo.toml --target-dir /tmp/magi-auth-phase6 --all-targets -- -D warnings
cargo fmt --manifest-path linux/magi/native/lock/auth/Cargo.toml --check
```

Each CTest tree has eight aggregate tests, including 41 new multi-output scenarios
in `output_synthetic`. It uses a fake Wayland Backend, actual offscreen Qt rendering
and synthetic Rust IPC. It cannot certify live wire traffic or physical scanout.
No Rust source or fixture changed for Phase 6A. The real worker path above does not authorize another authentication run.

## Phase 7 sleep/readiness (live acceptance complete; not production migrated)

[Phase 7 checkpoint](../../docs/design/lock-screen-phase7-suspend-resume.md) defines
explicit sleep ownership. Native mode holds a delay before sleep for credential
clearing/worker reap. `--sleep-coordinator=hypridle` delegates an already-pending
sleep to Hypridle mode 3's pre-existing inhibitor; it does not attempt a late
native acquisition. On resume (or startup with sleep already finished), it acquires
native protection before permitting input, protecting subsequent sleep cycles.
Already-locked Test 1, corrected initially-unlocked Test 2 and the final
dual-output suspend/resume test passed with operator visual acceptance. The
original Test 2 failure remains documented. Test 3 is subsumed by corrected
Test 2; no redundant execution is required. Resume exercised HDMI replacement
from registry/lifetime 79/2 to 80/3 while the global session remained locked.
Delay is finite, not an absolute suspend veto. Production
continues using Hyprlock; no unit/config below is installed or enabled.

New dependency: libsystemd >=252 (plus Python 3 for tests). `--sleep-integration` subscribes only
with explicit acquisition/authentication. `--notify-ready` sends READY=1 only from
the compositor-confirmed native callback. Neither exposes unlock. A native runtime
flock rejects duplicate owners without claiming ready. Ordinary help/build-info
and automated tests never acquire a real lock or sleep inhibitor.

`integration/magi-lock@.service` and `magi-lock-request` are future packaging
artifacts, not commands to deploy now. Intended paths are `/usr/bin/magi-lock-request`
and sibling owner/worker `/usr/lib/magi/{magi-lock,magi-lock-auth}`. Packaged builds
must leave MAGI_LOCK_AUTH_WORKER empty; /tmp overrides are development only.
`magi-lock-request lock` (also the no-argument default) selects the native instance;
`magi-lock-request sleep-coordinated` selects the hypridle instance. Existing
activations are reused across modes. Same-instance requests coalesce in systemd;
a simultaneous cold-start cross-mode race fails safely at the native flock rather
than stopping another owner. No Conflicts/restart/unlock endpoint is added.
Type=notify reports the same compositor confirmation to waiting callers;
Hypridle does not consume READY=1 and gates sleep on its compositor notifier.
The explicit coordinated request assumes the trusted caller has configured mode 3;
it is not a claim that arbitrary callers have an external inhibitor.

`integration/handoff_policy.py` is the pure acceptance-harness state model.
Service/locker exit, systemctl success and deadlines never establish completed
sleep. Restoration requires observed true→false, fresh PreparingForSleep=false,
terminal sleep service and an exited locker (or a definitive rejected request).
Unknown/pending state retains temporary Hypridle and requires operator recovery.
Production verification requires its inhibitor, not merely a PID.
`handoff_config.py` renders only the two temporary integration changes; it never
writes or activates live configuration. Neither module is a production daemon.

Non-disruptive validation from repository root (no real lock/PAM/suspend):

```bash
cargo build --locked --offline --manifest-path linux/magi/native/lock/auth/Cargo.toml --target-dir /tmp/magi-auth-phase7 --bins --example protocol_fixture
cmake -S linux/magi/native/lock -B /tmp/magi-lock-phase7-build -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug \
  -DMAGI_LOCK_AUTH_WORKER=/tmp/magi-auth-phase7/debug/magi-lock-auth \
  -DMAGI_LOCK_AUTH_FIXTURE=/tmp/magi-auth-phase7/debug/examples/protocol_fixture
cmake --build /tmp/magi-lock-phase7-build
ctest --test-dir /tmp/magi-lock-phase7-build --output-on-failure
cmake -S linux/magi/native/lock -B /tmp/magi-lock-phase7-dev-build -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug -DMAGI_LOCK_DEVELOPMENT_UNLOCK=ON \
  -DMAGI_LOCK_FAILURE_INJECTION=ON \
  -DMAGI_LOCK_AUTH_WORKER=/tmp/magi-auth-phase7/debug/magi-lock-auth \
  -DMAGI_LOCK_AUTH_FIXTURE=/tmp/magi-auth-phase7/debug/examples/protocol_fixture
cmake --build /tmp/magi-lock-phase7-dev-build
ctest --test-dir /tmp/magi-lock-phase7-dev-build --output-on-failure
cargo test --locked --offline --manifest-path linux/magi/native/lock/auth/Cargo.toml --target-dir /tmp/magi-auth-phase7
cargo clippy --locked --offline --manifest-path linux/magi/native/lock/auth/Cargo.toml --target-dir /tmp/magi-auth-phase7 --all-targets -- -D warnings
cargo fmt --manifest-path linux/magi/native/lock/auth/Cargo.toml --check
```

`sleep_synthetic` adds fake inhibitor/readiness/resume cases, real native input and
synthetic worker cancellation/reap, output replacement, and competing-process
instance-guard tests. Existing Phase 5/6 suites remain required. Any further live
test requires separate approval and fresh recovery planning. Phase 7 acceptance
does not authorize installation, production routing/PAM migration or Hyprlock
retirement. Hypridle remains the intended production idle/sleep coordinator.


## Phase 8A production packaging (not installed)

[Production deployment checkpoint](../../docs/design/lock-screen-phase8-production-migration.md)
contains the PAM review, dependencies, exact migration/rollback commands and
remaining live gates. Hyprlock remains the active fallback; Hypridle remains a
production dependency. No live configuration changes are included.

A production build uses Release, prefix `/usr`, and
`MAGI_LOCK_PRODUCTION_INSTALL=ON`. That configuration rejects development unlock,
failure injection and external worker overrides, builds Cargo release with
`--locked --offline`, and installs exactly five artifacts. Proof builds have no
install rules. Rust/Cargo are build dependencies, not runtime requirements.

```bash
cargo build --locked --offline --manifest-path linux/magi/native/lock/auth/Cargo.toml \
  --target-dir /tmp/magi-auth-production-tests --example protocol_fixture
cmake -S linux/magi/native/lock -B /tmp/magi-lock-production -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
  -DMAGI_LOCK_PRODUCTION_INSTALL=ON \
  -DMAGI_LOCK_AUTH_FIXTURE=/tmp/magi-auth-production-tests/debug/examples/protocol_fixture
cmake --build /tmp/magi-lock-production
ctest --test-dir /tmp/magi-lock-production --output-on-failure
DESTDIR=/tmp/magi-lock-install-root cmake --install /tmp/magi-lock-production
python3 linux/magi/native/lock/tests/install_test.py --audit /tmp/magi-lock-install-root
```

This stages `/usr/lib/magi/{magi-lock,magi-lock-auth}`,
`/usr/bin/magi-lock-request`, `/usr/lib/systemd/user/magi-lock@.service`, and
`/etc/pam.d/magi-lock` beneath `/tmp` only. The PAM template is `auth include login`;
the worker retains authentication-only semantics, without account/session calls.
No production password test is authorized by these build commands.

Prefer the prepared local Arch package over unmanaged root installation:

```bash
python3 linux/magi/native/lock/packaging/prepare-source.py /tmp/magi-lock-package
cd /tmp/magi-lock-package
makepkg --cleanbuild --noconfirm
```

Use a fresh export directory. This builds a package without installing it and
without dependency downloads; required build packages and the locked Cargo crate
must already be present. No install hook changes routing or activates services.
Do not use `makepkg -i` or `pacman -U` until Phase 8B approval.

The request wrapper validates `lock`/`sleep-coordinated` and checks that the user
manager's Wayland/runtime environment matches its graphical caller. It never
imports environment silently. Type=notify still means compositor-confirmed Locked.
Instance guard and both explicit sleep coordinators remain the accepted Phase 7
implementation. No public unlock action is added.

Phase 8A validation: production CTest 12/12, development 11/11, Rust 18/18,
Clippy and formatting passed. Request tests now contain 12 cases. Staged install,
unit verification and package checks are non-activating; no real lock/PAM/suspend
was performed.

## Phase 9A visual preview (not installed)

The modular `qml/LockScreen.qml` replaces the proof paragraph. It consumes only
safe display values and an immutable native snapshot of MAGI's semantic palette,
shared saved wallpaper and managed avatar. Native input/auth/sleep/output ownership
is unchanged. See [the design and validation checkpoint](../../docs/design/lock-screen-phase9-visual-design.md).

Render synthetic PNGs without a session lock, worker or PAM:

```sh
cmake -S linux/magi/native/lock -B /tmp/magi-lock-visual -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=OFF -DMAGI_LOCK_VISUAL_PREVIEW=ON
cmake --build /tmp/magi-lock-visual --target magi-lock-preview
/tmp/magi-lock-visual/magi-lock-preview /tmp/magi-lock-renders
```

This executable forces Qt offscreen software rendering. It cannot accept secret
input, acquire a lock or authenticate. Production installation rejects the preview
build option and still installs exactly five artifacts. Phase 9A is pending visual
review; these source changes have not replaced the installed production locker.

Phase 9A.1 previews use a cached CPU-blurred copy of the saved shared wallpaper,
never a desktop capture. The snapshot is rebuilt on each locker launch, not on
credential/clock redraws. The preview emits ten states, including bright synthetic
wallpaper, missing artwork, long identity and maximum-count cases. See the Phase
9A.1 section of the design checkpoint for processing limits and cache semantics.

### Resume input compatibility (uncommitted, host validation pending)

A focused early press and its matching release can be held for at most 100 ms
until the first authoritative wl_keyboard.modifiers notification. The fixed
metadata slot is scrubbed on expiry, overflow, auth cancellation and focus/keyboard/
output/sleep lifetime changes. Replay uses normal NativeInput handling; no guessed
mask or held-enter-key replay is allowed. Unknown Caps state and an exceptional
Shift press/release recovery hint are safe display values only. Missing state
never permits authentication with guessed modifiers. See
`docs/design/lock-screen-phase9-resume-input-investigation.md` for evidence,
limits and required host validation before release 0.1.0-3 packaging.

### Phase 9 production acceptance (2026-10-19)

Installed magi-lock 0.1.0-3 passed operator-approved normal dual-output lock and
single suspend/resume acceptance, including correct input and clean display return.
Accepted visuals and native security boundaries remain intact. The bounded
early-key compatibility fix and 37-path final allowlist are documented in the
Phase 9 visual and resume-input checkpoints. Host offline validation is complete;
final post-suspend host health verification passed; repository finalization is authorized.
