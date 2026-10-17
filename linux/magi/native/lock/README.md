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
