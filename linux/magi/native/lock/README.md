# MAGI native authenticated-lock proof

**Phase 4 accepted: one real single-output authenticated unlock passed.**
Hyprlock remains production. Do not acquire a session lock or use a real password
without explicit approval for that specific run. No install/routing change exists.

[Phase 2](../../docs/design/lock-screen-phase2-protocol-proof.md) accepted the native
Wayland owner. [Phase 3](../../docs/design/lock-screen-phase3-pam-proof.md) accepted
one independent ordinary-user PAM success. The
[Phase 4 checkpoint](../../docs/design/lock-screen-phase4-authenticated-unlock.md)
records their integration, accepted live result, synthetic evidence and remaining gates.

The C++20 owner binds ext-session-lock-v1 and wl_seat/wl_keyboard on one native
Wayland connection. xkbcommon translates keys directly into a bounded native
credential buffer. QML renders offscreen and receives only presentation values.
On submission, a single ordinary-user Rust child uses private inherited
AF_UNIX/SOCK_SEQPACKET IPC and the existing `hyprlock` PAM service. Only the C++
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
