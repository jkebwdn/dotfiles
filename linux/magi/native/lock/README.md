# MAGI native session-lock protocol proof

**Phase 2, not a production locker. No authentication. No production routing.**
The native compositor test has **not** run. Do not invoke acquisition without
explicit operator approval for that specific run.

This standalone C++20/Qt application owns `ext-session-lock-v1` through libwayland.
Qt Quick renders an embedded, inert proof scene offscreen into native-owned SHM
pixels; it never creates an ordinary Wayland window. Native solid colour remains
available without QML. See the [checkpoint](../../docs/design/lock-screen-phase2-protocol-proof.md)
for ownership, failure limitations, source evidence and the manual test procedure.

## Build and automated tests (do not acquire a lock)

From the repository root, using installed development libraries:

```bash
cmake -S linux/magi/native/lock -B /tmp/magi-lock-build -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build /tmp/magi-lock-build
ctest --test-dir /tmp/magi-lock-build --output-on-failure
/tmp/magi-lock-build/magi-lock-proof --build-info
```

The default binary has **no unlock implementation**, so it is not suitable for
an ordinary live test or deployment. Running it without arguments fails without
connecting to Wayland. Help/build information also run without Qt initialization
or a display connection. No test calls `WaylandOwner::start()`.

To build the separate, explicitly unsafe development variant (still no lock):

```bash
cmake -S linux/magi/native/lock -B /tmp/magi-lock-dev-build -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug -DMAGI_LOCK_DEVELOPMENT_UNLOCK=ON
cmake --build /tmp/magi-lock-dev-build
ctest --test-dir /tmp/magi-lock-dev-build --output-on-failure
```

Dependencies: C++20 compiler, CMake >=3.25, Ninja (or another CMake generator),
pkg-config, wayland-client >=1.20, wayland-scanner, wayland-protocols >=1.25 with
`staging/ext-session-lock/ext-session-lock-v1.xml`, Qt >=6.8 Core/Gui/Quick/Qml,
Linux memfd/mmap, Qt offscreen platform and software Quick renderer. Tested with
Qt 6.11.2 and Wayland 1.26.0. Vulkan headers are optional and unused. Nothing needs
to be installed on the audited machine. Missing required dependencies must be
reported, not installed automatically.

CMake generates `session-lock.h` and `session-lock.c` using the installed XML,
inside the build directory. Generated protocol glue and binaries are not tracked.
There is no install target. `native/` is excluded from the MAGI Stow package.

## Proposed live command — APPROVAL REQUIRED, not executed

First complete the checkpoint's save-work, TTY, Hyprlock and recovery preflight.
Only the separate development binary is intended for this first test:

```bash
/tmp/magi-lock-dev-build/magi-lock-proof \
  --acquire-session-lock --unsafe-development-unlock-after=60
```

This really locks the session. It prints its PID and protocol diagnostics. Its
only development release is an **automatic timer 60 seconds after the compositor
confirms `locked`**. No key, mouse action, signal, socket or QML method unlocks.
The timer is explicitly unauthenticated; it is compiled out by default and must
never be deployed. It is not a watchdog: a crashed/hung process cannot guarantee
release. Do not attempt crash/signal tests in the first live run.

SIGINT, SIGTERM, SIGUSR1, SIGKILL or a fatal error may leave the graphical session
locked and unusable. From an authenticated TTY, `kill -TERM <printed-proof-pid>`
terminates a wedged proof **without unlocking**. Ending the graphical session may
be required; Hyprlock cannot necessarily take over a dead client's lock. Never
turn on lock restoration or clear compositor lock state automatically.

Hyprlock remains the production route through Hypridle/loginctl. This program
has no PAM, credentials, Rust, keyboard listeners, main-shell IPC, DBus service,
Settings access, final UI or system-service integration.
