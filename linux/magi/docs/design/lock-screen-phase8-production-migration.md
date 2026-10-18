# MAGI Lock Screen — Phase 8A production packaging and migration preparation

2026-10-18. Baseline verified before work:
`0a0f2d7a64463078f138c74a3817e8692d44feae`,
`magi: harden suspend and resume locking`; HEAD/origin/main `0 0`.
**Non-migrating implementation. No production installation or activation.**
Earlier Phase 2–7 checkpoints remain historical and unchanged. Phase 7 acceptance
covers the development deployment, not the new MAGI-owned PAM service or installed
production paths. Those require separately approved Phase 8B acceptance.

## Scope and fixed security architecture

Native C++/Qt owns ext-session-lock-v1, wl_keyboard/xkbcommon, the bounded native
credential, per-output lifetimes and one global auth controller. Private inherited
AF_UNIX/SOCK_SEQPACKET IPC connects at most one Rust PAM worker. QML receives only
sanitized presentation state. Only valid current-generation Success plus the
accepted IPC/child-exit/reap contract authorizes normal global unlock. No public
unlock, stop or kill command is added.

The explicit Phase 7 modes remain:

- `magi-lock-request lock` (also default): native coordinator holds its delay
  before sleep, clears credential/cancels and reaps auth during preparation, and
  releases only when compositor Locked plus auth quiescence are established.
- `magi-lock-request sleep-coordinated`: trusted Hypridle mode-3 integration owns
  the pending sleep delay. MAGI does not attempt a late acquisition. Only actual
  ext_session_lock_v1.locked establishes secureLockReady; Hypridle's compositor
  notifier releases its inhibitor. On resume, or coordinated startup while
  already awake, native protection is acquired before fresh editable input.

No implicit fallback on inhibitor errors. The measured Phase 7 acquisition times
were 107.062 ms and 128.781 ms; the effective logind ceiling was 5000000 us. These
are dated observations, not an indefinite suspend veto or future latency promise.
The package does not change idle policy or implement another idle daemon.

## Deployment model and file ownership

Recommend a **local Arch package**, built using the CMake install rules. Compared
with raw sudo installation, pacman supplies one ownership database, dependency
checks, updates/removal and a backed-up PAM policy. There is no .install hook,
automatic enablement, daemon-reload, Hypridle edit, or Hyprlock conflict/replacement
in the package. Hyprlock stays installed throughout initial migration acceptance.

| Installed path | Mode | Owner after privileged/package install | Purpose |
| --- | --- | --- | --- |
| /usr/lib/magi/magi-lock | 0755 | root:root | Native session-lock owner |
| /usr/lib/magi/magi-lock-auth | 0755 | root:root | Private one-attempt Rust PAM worker |
| /usr/bin/magi-lock-request | 0755 | root:root | Narrow lock request wrapper |
| /usr/lib/systemd/user/magi-lock@.service | 0644 | root:root | On-demand user unit template |
| /etc/pam.d/magi-lock | 0644 | root:root | MAGI-owned authentication policy |

`/usr/lib/magi` holds private executables; only the request command is a public
PATH entry. Arch uses /usr/lib/systemd/user for vendor user units. /etc/pam.d is
chosen explicitly, matching this host's current PAM deployment and worker's
missing-policy guard. Although PAM also supports vendor /usr/lib/pam.d fallbacks,
this package deliberately requires the explicit /etc file and marks it a pacman
backup file. No setuid/setgid bits or file capabilities are assigned to MAGI.

Read-only `pacman -Qo` checks found all five destinations absent and unowned;
installation must repeat conflict checks in case another package appears later.
`/etc/pam.d/login` is owned by util-linux, existing hyprlock policy by hyprlock.
No existing package-owned file is replaced by the proposed package.

CMake `MAGI_LOCK_PRODUCTION_INSTALL=ON` requires Release, /usr prefix, development
unlock OFF, failure injection OFF and an empty MAGI_LOCK_AUTH_WORKER override.
It builds the owner as `magi-lock` and the worker with Cargo --release --locked
--offline, then installs exactly the five files above. Ordinary development builds
have no install rules. No harness, fixtures, test executables, sources, QML source
files, caches or build outputs are installed; QML is an embedded resource.

Source layout: `src/`, `auth/`, `qml/`; integration artifacts in `integration/`
(including `pam/magi-lock`); package recipe/source exporter in `packaging/`; tests
in `tests/`. Generated C/Cargo/protocol/binary files remain in out-of-source trees.

## Dependencies and inspected versions

Read-only pacman ownership and installed headers/plugins were checked on this
Arch host. Arch packages generally combine runtime files and development headers.

| Runtime package | Used for |
| --- | --- |
| glibc, gcc-libs | C/C++ runtime, Rust's native runtime dependencies |
| wayland | libwayland-client |
| qt6-base | Core/Gui, offscreen QPA plugin, painting/fonts |
| qt6-declarative | Quick/Qml and QtQuick QML plugin |
| libxkbcommon | Native keyboard and compose handling |
| pam | libpam and existing authentication modules/helpers |
| pambase | system-local-login/system-login/system-auth policy |
| util-linux | /etc/pam.d/login include target |
| systemd, systemd-libs | user manager, systemctl/loginctl/logind, libsystemd |
| hyprland, hypridle | Supported compositor and mode-3 sleep/idle coordinator |
| sh (provided by bash), grep | Request script and exact environment comparison |

Transitive libraries/plugins retain their package dependencies; no manual bundled
copy is made. QtWayland is not required by this native Wayland/offscreen Qt path.
Fonts remain the host's normal Qt/fontconfig fonts; native opaque fallback does
not depend on optional visual assets. Hypridle remains a **production dependency**.

Build/check packages: cmake, ninja, gcc, binutils (readelf/nm/strings), pkgconf,
wayland-protocols, Rust toolchain/Cargo and Python. wayland supplies wayland-scanner;
pam supplies security/pam_appl.h; Qt/xkb/systemd packages supply development
metadata. Python is test/package tooling, not an installed locker dependency.
Rust/rustc/Cargo/rustup are build-only, not runtime requirements. Current rustup
provides the installed toolchain; no compiler/package removal was performed.

Inspected versions: glibc 2.44, GCC/gcc-libs 16.2.1, Wayland 1.26.0, protocols 1.49,
Qt base/declarative 6.11.2, xkbcommon 1.13.2, PAM 1.7.3, pambase 20260616,
systemd 262, Hyprland 0.56.2, Hypridle 0.1.8, CMake 4.4.4, Ninja 1.13.2,
pkgconf 3.0.7, rustup 1.29.1, rustc/Cargo 1.99.1. Rebuild and revalidate after
relevant ABI/policy changes rather than treating these versions as permanent.

## PAM policy decision

The complete intended `/etc/pam.d/magi-lock` contents are:

```pam
#%PAM-1.0
auth include login
```

This preserves the reviewed local auth stack while eliminating dependency on
Hyprlock's service/file. The worker hardcodes **magi-lock**, checks that its policy
file exists before pam_start (no silent `other` fallback), uses the current real
UID's name, and rejects PAM_USER changes after success. No caller/environment/CLI
selects an arbitrary account or PAM service. The terminal proof harness's notice
is updated too, but that harness is not installed.

On the inspected machine, auth include traversal is:
`magi-lock → login → system-local-login → system-login → system-auth`.
It includes pam_nologin and pam_shells, optional pam_systemd_home, pam_unix,
pam_env and pam_faillock. The login auth policy has a nologin check also encountered
inside system-login; preserving that stack avoids silently weakening local policy.
Only **auth** entries are included by `auth include`, not account/session/password
entries in those files.

Alternatives considered:

- Depending on hyprlock: rejected as production dependency/ownership coupling.
- `auth include system-auth`: shorter, but bypasses the current shell/nologin
  layers and changes accepted behavior; not selected.
- `auth include system-local-login`: bypasses login's top-level policy; no concrete
  need to diverge from the already accepted stack.
- Copying individual pam_unix/faillock rules: duplicates distribution policy and
  risks missing updates; not selected.

The call remains `pam_authenticate(..., PAM_DISALLOW_NULL_AUTHTOK)` followed by
pam_end; no pam_acct_mgmt, pam_setcred, pam_chauthtok or session-open call is added.
This is reauthentication of an existing graphical session, not a new login.
Account-expiry/time/access rules that require pam_acct_mgmt are **not enforced as
an additional unlock policy**. Conversely, auth-stack nologin/shell/faillock rules
can prevent unlocking; retained authenticated recovery is necessary. Password
expiry/change workflows are not implemented. This is an explicit policy decision,
not a claim that all login policy is evaluated. Local `pam_unix nullok` does not
remove the worker's null-token prohibition; native empty Enter also cannot submit.

No fingerprint module is configured in the inspected auth chain. Hyprlock's direct
fprintd feature is separate. Standard PAM modules can be configured by an admin
later, but the native owner currently supports one hidden password response and
bounded info/error acknowledgements; EchoOn/second prompt and success without its
expected response fail closed. Do not claim live MFA/fingerprint compatibility or
install a biometric policy here. Real acceptance of the new service is Phase 8B.

Policy file ownership is root:root 0644, backup-managed by pacman. Recommended
install/uninstall is the package operation below. If a separately approved,
unmanaged installation is ever chosen, its exact PAM-only commands are:

```sh
sudo install -D -o root -g root -m 0644 \
  /tmp/magi-lock-install-root/etc/pam.d/magi-lock /etc/pam.d/magi-lock
# Only for an unmanaged file, after fallback restored and no active MAGI owner:
sudo rm -- /etc/pam.d/magi-lock
```

Do not use the rm command against a pacman-owned file; uninstall the package.
No such command ran in Phase 8A.

## Service, environment and request contract

The single `magi-lock@.service` template uses:

```ini
[Unit]
Description=MAGI native session lock
After=graphical-session.target
PartOf=graphical-session.target
RefuseManualStop=yes

[Service]
Type=notify
NotifyAccess=main
ExecStart=/usr/lib/magi/magi-lock --acquire-session-lock --authenticate --sleep-integration --sleep-coordinator=%i --notify-ready
Restart=no
TimeoutStartSec=20
LimitCORE=0
SyslogIdentifier=magi-lock
```

No [Install] section: do not enable this service. `%i` is validated by native CLI
as native or hypridle before runtime work; the public wrapper only selects those
units. READY=1 is sent from the compositor-locked callback, never process launch.
Hypridle consumes its own compositor notifier, not systemd READY. Startup timeout
is not secure readiness and is not a suspend veto; a failed/killed owner remains
subject to compositor fail-secure behavior. Restart=no avoids a replacement-owner
fiction. No Conflicts or ExecStop/unlock action is supplied.

Do not add NoNewPrivileges, setuid restrictions, PrivateUsers or an unreviewed
syscall filter: pam_unix can need its packaged privileged unix_chkpwd helper.
MAGI runs as the ordinary session user, rejects root/setuid execution, clears the
worker environment to PATH=/usr/bin and LANG=C, and disables core dumps. These
are not isolation from malicious same-UID code or compromised system libraries.

Read-only user-manager audit found WAYLAND_DISPLAY=wayland-1, the current
HYPRLAND_INSTANCE_SIGNATURE, XDG_RUNTIME_DIR=/run/user/1000 and user D-Bus address.
DISPLAY=:0 was present but is not used by the native/offscreen locker.
XDG_SESSION_ID was absent from the manager and is not needed by the locker;
production Hypridle runs inside the graphical session and has its session context.

Hyprland v0.56.2 `CCompositor::startCompositor` imports graphical variables into
systemd and D-Bus activation for a real backend session unless HYPRLAND_NO_SD_VARS
is enabled. No additional import was found in protected Hyprland Lua/MAGI scripts.
The actual manager matches the running shell. Do not assume this for nested or
multiple concurrent graphical sessions: one graphical session per user manager
is the supported initial deployment.

The request wrapper accepts only zero arguments/default lock, `lock`, or
`sleep-coordinated`; extra args, arbitrary units/paths/services and unlock/stop/kill
are rejected with status 64 before bus access. It checks caller WAYLAND_DISPLAY
and XDG_RUNTIME_DIR against the manager without eval or importing the environment.
Missing/mismatched values return 78 with a diagnostic; manager errors or unsafe
service states return 69. A valid systemctl start error propagates. Existing
active/activating native or hypridle units are reused; inactive/failed may start.
Deactivating/reloading/unknown state is not guessed into a new activation.

Future recovery from missing manager display environment, from the verified
current graphical terminal only, before locking and with no competing session:

```sh
systemctl --user import-environment WAYLAND_DISPLAY
```

No broad environment import; no import per lock request. XDG_RUNTIME_DIR and the
bus are supplied by the user session. HYPRLAND_INSTANCE_SIGNATURE is useful for
operator hyprctl recovery but unnecessary to native Wayland acquisition. The
wrapper does not promise arbitrary multi-session routing or protection against
another same-UID process changing the manager environment.

## Instance guard and production defaults

The existing guard is retained at
`$XDG_RUNTIME_DIR/magi-lock-$WAYLAND_DISPLAY.lock`. It requires an owned runtime
directory with no group/other access, O_NOFOLLOW on directory/file, an owned
regular 0600 file with one link, and nonblocking exclusive flock. Display identity
is bounded and restricted to safe basename characters. FD is CLOEXEC. A stale
file alone is harmless; kernel flock is released on owner exit/crash. Never
unlink the file during cleanup: that would permit competing locked inodes.
Requests to the same service coalesce; simultaneous cold cross-mode starts may
launch a losing process, but the native guard admits only one lock owner. No
loser may stop the winner. Crash recovery remains a separate compositor gate.

Defaults retained: 511-byte native credential cap; 120-second attempt deadline;
2-second cancellation grace before forced worker reap; 1500 ms retry delay;
worker 125-second last-resort alarm; native coordinator by default; explicit
Hypridle selection for its lock command. Opaque native rendering/compositor
fallback remains fail-secure. Logs use bounded event categories and never raw
credential/PAM text or credential length. Service notify is explicitly selected
by the unit. Worker resolves the installed trusted sibling; production builds
reject external worker overrides. Production PAM service is now magi-lock.

## Build hardening and checks

Production CMake adds PIE, stack protector strong, stack-clash protection,
FORTIFY_SOURCE=3 with optimized Release compilation, full RELRO, immediate binding
and non-executable stack. Existing -Wall/-Wextra/-Wpedantic/-Werror remain on
security-sensitive native targets. Rust preserves Cargo.lock, only direct libc
0.2.179 dependency, panic=abort, checked overflow, thin LTO, one codegen unit and
symbol stripping; explicit linker hardening/pic flags are supplied by CMake.
Rust does not claim the C stack-protector instrumentation; inspect its ELF too.

The staged owner and worker are inspected using readelf/ldd/strings, including
PIE, GNU_RELRO, BIND_NOW, non-executable GNU_STACK, resolved dependencies, absent
dev/injection markers and absent hyprlock policy strings. C++ stack-check symbols
are verified. Invalid CLI flags are tested without acquiring a lock. Package audit
checks the five file modes and exact PAM contents. Native regression tests cover
actual offscreen Qt presentation and inherited IPC with fake authentication.

An existing destructor-erasure test needed its observation changed to initialized
backing storage with volatile reads: Release optimization diagnosed the former
post-lifetime pointer inspection. This changes test observation only, not the
credential class or erasure semantics. No warning was suppressed.

## Reproducible build and staging commands (non-live)

Run from repository root, with already-cached Cargo dependencies:

```sh
cargo build --locked --offline --manifest-path linux/magi/native/lock/auth/Cargo.toml \
  --target-dir /tmp/magi-auth-phase8 --bins --example protocol_fixture
cmake -S linux/magi/native/lock -B /tmp/magi-lock-phase8-production -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
  -DMAGI_LOCK_PRODUCTION_INSTALL=ON \
  -DMAGI_LOCK_AUTH_FIXTURE=/tmp/magi-auth-phase8/debug/examples/protocol_fixture
cmake --build /tmp/magi-lock-phase8-production -j 4
ctest --test-dir /tmp/magi-lock-phase8-production --output-on-failure
DESTDIR=/tmp/magi-lock-install-root cmake --install /tmp/magi-lock-phase8-production
python3 -B linux/magi/native/lock/tests/install_test.py --audit /tmp/magi-lock-install-root
```

The Cargo worker is built automatically by CMake; the first explicit Cargo command
above builds the separate test fixture/debug test tools, not an installed fixture.
For a packaging-only build, use BUILD_TESTING=OFF and omit the fixture path.
Staging is unprivileged, so files are owned by the invoking user there. Modes
match final installation; pacman/fakeroot metadata supplies final root ownership.
No real filesystem installation under /usr or /etc occurs with DESTDIR set.

For the local package, choose a fresh output directory:

```sh
python3 -B linux/magi/native/lock/packaging/prepare-source.py /tmp/magi-lock-package
cd /tmp/magi-lock-package
makepkg --verifysource
makepkg --cleanbuild
```

Do not add -i/--install or -s/--syncdeps in Phase 8A. The exporter creates a sorted,
normalized source archive with fixed gzip/tar times, no .git or build output, plus
PKGBUILD with a real SHA-256 rather than SKIP. Cargo remains --locked --offline.
Two exports of the same inputs are byte-identical. Full binary reproducibility
also depends on pinned toolchain/system dependencies and Arch build environment;
no cross-machine bit-for-bit claim is made. `.BUILDINFO` records the local package
build. Package version/release must be advanced for future releases.

No repository distribution license was found. The local-only recipe records
LicenseRef-Local-Unlicensed; this is not a license grant or public-distribution
approval. Resolve licensing before publishing outside the operator's machine.
No new runtime dependency on Rust, Python, development fixtures or Hyprlock exists.

## Routing decision and exact future Hypridle diff

Keep existing Control Centre/system routes:
`ControlCatalog → QuickActions → system_actions.py → loginctl lock-session`.
The availability check currently proves loginctl exists, not locker readiness;
production acceptance must verify the complete route. No dedicated lock keybind
was found; Super+L is a layout operation. No broad shell code changes are needed.

Any application issuing loginctl lock-session continues to produce Session.Lock,
which the running Hypridle receives and maps to its single lock_cmd. This keeps
manual, idle and external/system requests consistent. With no pending sleep,
explicit coordinated startup acquires native protection before editing. Direct
`magi-lock-request lock` remains useful for controlled manual/service acceptance
and callers needing Type=notify start completion. loginctl success alone means
request delivery, not compositor readiness; suspend relies on mode 3's notifier.

Proposed change to protected `linux/t15g/hypr/.config/hypr/hypridle.conf` —
**not applied**:

```diff
 general {
-    lock_cmd = pidof hyprlock || hyprlock
+    lock_cmd = /usr/bin/magi-lock-request sleep-coordinated
+    inhibit_sleep = 3
     before_sleep_cmd = loginctl lock-session
     after_sleep_cmd = hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'
 }
```

The 300-second loginctl idle listener and 600-second DPMS listener/resume command
stay byte-for-byte unchanged. loginctl remains the session-level trigger and
Hypridle stays responsible for idle/DPMS and lock-before-suspend coordination.
The old command-name-based auto heuristic must not be relied upon after replacing
Hyprlock; explicit inhibit_sleep=3 is required.

## Phase 8B sequence and privileged commands — proposed only

Every live test needs separate approval, saved work and fresh authenticated TTY
recovery. Production has **no development timer**. Before the first production
lock, agree on recovery if UI/auth fails: do not kill/restart the owner to pretend
unlock succeeded. Authenticated recovery may require ending the graphical session
and losing unsaved state; config/package rollback cannot unlock an existing
fail-secure compositor lock. Hyprlock is fallback for subsequent locks, not a way
to steal the current lock. No live test or such recovery is authorized here.

1. Review this checkpoint, account-policy choice and five-second platform limit.
   Repeat destination ownership/conflict and active-lock/sleep checks; build/audit
   the production package. Keep known-good Hyprlock installed and operational.
2. Install all five artifacts atomically through the local package. This is the
   principal proposed sudo operation (replace path only with the reviewed artifact):

   ```sh
   sudo pacman -U /tmp/magi-lock-package/magi-lock-0.1.0-1-x86_64.pkg.tar.zst
   systemctl --user daemon-reload
   pacman -Qkk magi-lock
   /usr/lib/magi/magi-lock --build-info
   systemd-analyze --user verify /usr/lib/systemd/user/magi-lock@.service
   ```

   No sudo for user daemon-reload; never run the locker as root. Do not enable
   the on-demand unit. Review any .pacnew rather than silently replacing policy.
3. Verify installed hashes/modes, service/unit path, actual PAM content, worker
   sibling, manager environment and absent development features. Repeat wrapper
   mock tests as needed. If necessary, explicitly import WAYLAND_DISPLAY from the
   verified graphical terminal; do not alter global manager variables from a TTY.
4. With production Hypridle still using Hyprlock, approve **one** installed manual
   lock via `/usr/bin/magi-lock-request lock` and one real password submission.
   This proves the MAGI PAM name and installed native path. No automatic retry.
   Require compositor lock, worker reap, one authenticated global unlock and clean
   return. No migration on failure.
5. Back up the resolved live Hypridle file before changing it, record its hash and
   exact running Hypridle argv/cwd/environment. Preserve the backup outside the
   package and retain it until rollback acceptance. Proposed commands from the
   graphical terminal (not executed here):

   ```sh
   mkdir -p "$HOME/.local/state/magi-lock"
   chmod 700 "$HOME/.local/state/magi-lock"
   cp -p -- "$HOME/.config/hypr/hypridle.conf" \
     "$HOME/.local/state/magi-lock/hypridle.before-magi.conf"
   ```

   Do not overwrite an earlier rollback backup during a retry. Apply only the
   displayed two-setting diff after separate approval. No manual shell/button
   route changes are necessary because they already use loginctl.
6. While unlocked and logind PreparingForSleep=false, hand off/restart Hypridle
   with audited argv/cwd/environment and verify exactly one process plus its
   delay inhibitor. Do not restart during pending sleep or an active lock; reuse
   Phase 7's guarded procedure. Do not restart Hyprland.
7. Individually approve production Session.Lock/Control Centre/manual route,
   idle-lock/DPMS behavior, initially-unlocked suspend/resume, already-locked sleep
   cleanup, and dual-output locking/resume. Do not combine all tests into one run.
   Require one global PAM/unlock flow and no desktop leakage. No assumed acceptance
   from development-only tests; the new installed PAM service must pass live.
8. Perform the rollback drill below while safely unlocked; verify restored
   Hyprlock route and normal inhibitor. Reapply MAGI only after separate approval
   and verify the final intended routes. Keep Hyprlock installed through review.
9. Only after all production gates and rollback pass, consider a later Hyprlock
   retirement decision. No removal is part of Phase 8A or automatic Phase 8B.

Raw CMake installation is possible but not recommended alongside pacman ownership.
Its alternative privileged command would be `sudo cmake --install BUILD_DIR`
with the reviewed /usr-prefix build and no DESTDIR; it touches the same five files
including PAM. Never mix this with the package installation. Prefer pacman because
it supplies transparent ownership and removal.

## Rollback / uninstall, prepared before migration

Rollback changes future routing, not an existing lock's authorization. Run only
when unlocked, no MAGI owner, and no pending sleep. If those conditions cannot be
established, retain existing protection and use the individually approved recovery
plan. Never release a pending Hypridle inhibitor just because the locker failed.

For this audited deployment, production Hypridle is an ordinary `hypridle` process
started from the graphical session, cwd $HOME; no managed user Hypridle service.
Future migration must record this again. A small-command rollback from the same
verified graphical terminal, with the pre-migration backup present:

```bash
# Phase 8B ONLY. Guards must all pass; no command in this block ran in Phase 8A.
test "$(hyprctl locked)" = false || exit 1
test "$(busctl get-property org.freedesktop.login1 /org/freedesktop/login1 \
  org.freedesktop.login1.Manager PreparingForSleep)" = 'b false' || exit 1
if pgrep -x magi-lock >/dev/null || pgrep -x magi-lock-proof >/dev/null; then exit 1; fi
mapfile -t magi_idle_pids < <(pgrep -x hypridle)
test "${#magi_idle_pids[@]}" = 1 || exit 1
# Follow the existing config symlink, preserving its destination and mode.
cat "$HOME/.local/state/magi-lock/hypridle.before-magi.conf" > "$HOME/.config/hypr/hypridle.conf" || exit 1
kill -TERM "${magi_idle_pids[0]}"
for magi_wait in {1..50}; do
  kill -0 "${magi_idle_pids[0]}" 2>/dev/null || break
  sleep 0.1
done
kill -0 "${magi_idle_pids[0]}" 2>/dev/null && exit 1
(cd "$HOME" && nohup /usr/bin/hypridle > "$HOME/.local/state/magi-lock/hypridle-rollback.log" 2>&1 < /dev/null &)
systemd-inhibit --list
```

Use the exact saved environment/launch mechanism if it differs; do not restart
with an unverified TTY environment. Verification after launch is mandatory: one
Hypridle, protected backup content restored (including original implicit mode-2
behavior), normal delay inhibitor, no temporary config/units, and Hyprlock still
installed. If startup/inhibitor verification fails, rollback is not complete.
Do not invoke another lock until corrected. This narrow recipe does not pretend
its shell guards atomically exclude an unrelated concurrent system sleep request;
perform the controlled change with sleep triggers quiescent and use the tested
handoff supervisor for any sleep test.

Because Control Centre/loginctl routes were not changed, restoring this file
restores their Hyprlock destination too. The package can remain inert during the
rollback drill. Optional later uninstall, only after fallback verified and no
active MAGI service:

```sh
sudo pacman -R magi-lock
systemctl --user daemon-reload
```

Pacman may retain a modified PAM backup as .pacsave. Review it explicitly; do not
use broad rm globs. There is no enabled unit to disable and no package hook stops
an active lock. Removing binaries or PAM while a locker is active is prohibited.

Hyprlock removal is **last**, only after installed binaries/PAM, manual and
Session.Lock routing, Hypridle idle and suspend, dual outputs, and rollback are
accepted, with no live Hyprlock routing or PAM dependency. Only then may a
separately approved `sudo pacman -R hyprlock` be considered. Hypridle stays.

## Sources and evidence limits

Inspected 2026-10-18; local versions above. No upstream implementation was copied.

- [Linux-PAM pam.d](https://man.archlinux.org/man/pam.d.5.en): include selects the
  specified management type; per-service file lookup and vendor fallback semantics.
- [pam_authenticate](https://man.archlinux.org/man/pam_authenticate.3.en),
  [pam_acct_mgmt](https://man.archlinux.org/man/pam_acct_mgmt.3.en),
  [pam_unix](https://man.archlinux.org/man/pam_unix.8.en): authentication is distinct
  from account checks; null-token flag and privileged helper considerations.
- [Swaylock upstream PAM file](https://github.com/swaywm/swaylock/blob/master/pam/swaylock):
  established locker include pattern; comparison only, not a substitute for local
  policy review. Local /etc/pam.d/hyprlock and Arch include files are primary
  evidence for the selected exact policy; no credential database was read.
- [Hyprland v0.56.2 Compositor.cpp](https://github.com/hyprwm/Hyprland/blob/v0.56.2/src/Compositor.cpp):
  startCompositor imports graphical activation environment conditionally; local
  manager inspection confirms current variables, not all future sessions.
- [systemd.exec](https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html)
  and [systemd.service](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html):
  user service environment and notification/start semantics; no activation during
  unit verification. Phase 7 records the tested mode-3/logind ownership semantics.
- [Arch PKGBUILD manual](https://man.archlinux.org/man/PKGBUILD.5.en): package
  dependency/build/check/package roles and configuration backup ownership.

PAM lint here is exact-content/include review, not a real PAM transaction or
universal policy validator. No real biometric, expired-account, password-change,
compositor crash or broader keyboard acceptance is implied. Existing proof UI
is deliberately retained without visual polish. Production service failure
recovery and the changed wrapper/environment path need Phase 8B live acceptance.


## Phase 8A final validation record — 2026-10-18

- Clean Release production build passed; complete CTest **12/12**.
- Clean development build passed; complete CTest **11/11**. These retain Phase 5
  failure containment, Phase 6's 41 output scenarios, Phase 7's 39 sleep scenarios,
  19 handoff cases, credential/QML and binary gates. Request contract now has
  **12 cases**, including missing/mismatched environment, bus failure and stopping
  instance rejection.
- Rust **18/18**, `cargo clippy --locked --offline --all-targets -- -D warnings`
  and `cargo fmt --check` passed. No real PAM call occurred.
- `/tmp/magi-lock-install-root` contains exactly the five specified deployment
  files. Install audit passed modes, exact PAM template, safe CLI rejection,
  ELF hardening/dependencies, absence of development features/Hyprlock dependency,
  and staged-path `systemd-analyze --user verify`. Verification activates nothing.
- Production-install configurations reject development unlock, failure injection
  and external worker override. No test sources/fixtures are installed.
- Local `makepkg --cleanbuild --noconfirm` completed without installation in
  `/tmp/magi-lock-package-phase8-final`. The resulting artifact is
  `magi-lock-0.1.0-1-x86_64.pkg.tar.zst`. Main package contents are the same five
  files plus normal pacman metadata/directories, owned root:root in the archive.
  Extracted, stripped package contents passed the same install audit. Local
  makepkg defaults also produced a separate debug package; it is not required
  or installed. Its Rust debug-index warning reflected absent release debugging
  symbols, not a build/check failure.
- Two source exports were identical: SHA-256
  `7ff661a567502054288fdc7365a959d20ed0ca49d24116485cf50f67539f7239`.
  Missing cached dependencies are an offline build error, not permission to fetch.
- Existing final destination paths were absent/unowned; no pacman file conflict.
- Snapshot compared 525 existing paths. Only the nine authorized existing native
  source/documentation paths changed; all other snapshot entries, including PAM
  and protected operator/runtime files, matched. Live Hypridle hash remains
  `eb6fa3c034957abaf48de818e690429c4a1c8b4815e72ead5e19d90a30cc17fb`.
- Production Hypridle PID 630192 remains running with its normal logind delay
  inhibitor; Hyprlock 0.9.6-3 remains installed. No runtime handoff occurred.
- No real lock, authentication, suspend, live install, PAM configuration write,
  production route change, staging, commit or push occurred. Index remains empty.

Exact Phase 8A changes (14 paths: nine modified, five new):

```text
M linux/magi/native/lock/CMakeLists.txt
M linux/magi/native/lock/README.md
M linux/magi/native/lock/auth/src/bin/magi-auth-harness.rs
M linux/magi/native/lock/auth/src/pam.rs
M linux/magi/native/lock/integration/magi-lock-request
M linux/magi/native/lock/integration/magi-lock@.service
M linux/magi/native/lock/src/main.cpp
M linux/magi/native/lock/tests/auth_test.cpp
M linux/magi/native/lock/tests/request_test.py
A linux/magi/docs/design/lock-screen-phase8-production-migration.md
A linux/magi/native/lock/integration/pam/magi-lock
A linux/magi/native/lock/packaging/PKGBUILD.in
A linux/magi/native/lock/packaging/prepare-source.py
A linux/magi/native/lock/tests/install_test.py
```

These are working-tree changes, not staged additions. Earlier Phase 2–7 records
and all pre-existing operator changes are preserved. Phase 8B remains unstarted.


## Accepted Phase 8A checkpoint finalization

The operator accepted Phase 8A and authorized committing/pushing its source only.
Final audit reconfirmed 14 paths (nine modifications, five additions), with no
package archives or build output. All 49 exported build/test inputs still match
the successfully validated package source; subsequent edits are documentation
only, so the recorded native/Rust/package validation remains applicable.

Hyprlock remains installed and is still the current production locker/fallback.
MAGI has not been installed at the five production destinations. Hypridle remains
the production idle, DPMS, Session.Lock and sleep-coordination dependency. No live
Hypridle/PAM/routing change accompanies this source checkpoint. Phase 8B is not
started; Hyprlock removal remains last, after production acceptance and rollback
proof. Earlier statements that the index was empty describe the Phase 8A
implementation audit before this separately authorized checkpoint finalization.


## Phase 8B — installation verified; direct lock approval pending

2026-10-18. Baseline `6d6973e6c0a74159d05e129af60d48580f9173a7`,
HEAD/origin/main `0 0`. Fresh committed-source rebuild in
`/tmp/magi-phase8b-hev2uoup/package` passed package and extracted-artifact audits.
The operator manually installed `magi-lock-0.1.0-1-x86_64.pkg.tar.zst` with
`sudo pacman -U`; reported successful completion was independently checked using
pacman and installed files. Package SHA-256:
`0a2ecd84b46ba51e4cd686e75ffbd0e8e7d9d9f8d54f13e1497847f5bcc6045b`.

`pacman -Q` reports magi-lock 0.1.0-1; `pacman -Qkk` reports 13 entries,
zero altered files (five regular artifacts plus parent directories). Exactly the
five intended regular files are owned by this package, with no symlinks, root:root
ownership and matching reviewed hashes/modes:

| File | Mode | SHA-256 |
| --- | --- | --- |
| `/etc/pam.d/magi-lock` | `0644` | `7c0ddfcdcf0beaef0146aa289a95f1eb482e5529bfaf5216e70d23ce8680e5e4` |
| `/usr/bin/magi-lock-request` | `0755` | `949057877040a503cf75469094016bdec4f43c0d498d3fab655e3eeeaa70f8bc` |
| `/usr/lib/magi/magi-lock-auth` | `0755` | `b64613639a3c602a3f4f7dda4515e2b624c176dc9a662847b4611226eb7572a9` |
| `/usr/lib/magi/magi-lock` | `0755` | `080485c39c21686bed1ba120017f8712f7b5fcd0c206e01b74e07a444d4fabf9` |
| `/usr/lib/systemd/user/magi-lock@.service` | `0644` | `20957a3e49e1ce9c508175e848a4376965b1fa21c967548bea9e85ed12dffdf8` |

Ownership was verified outside the tool sandbox: its UID namespace represents
host root as nobody, producing misleading initial ownership warnings; host
stat/pacman verification confirmed root:root and zero alterations. No corrective
ownership operation was needed or performed.

Installed PAM contents are exactly `#%PAM-1.0` followed by `auth include login`.
The verified worker contains `/etc/pam.d/magi-lock` and no Hyprlock service
reference. No PAM transaction was performed. Installed build-info reports
development-unlock=0, failure-injection=0 and native authentication enabled.
The production build uses the installed sibling worker with no override. ELF
checks confirm PIE, RELRO, immediate binding and non-executable stacks; C++ stack
protection is present, with fortification inherited from the verified Release
build. Seven unsupported wrapper invocations rejected with status 64 without
calling a valid lock operation. Configuration contains no /tmp path/fixture.

`systemctl --user daemon-reload` and non-activating unit verification passed.
No template was enabled; no MAGI units or owner/worker processes are active.
Type=notify, Restart=no, installed executable and validated native/hypridle
instance selection remain unchanged. Only compositor-confirmed readiness sends
READY=1. Clarification: `/usr/bin/magi-lock-request lock` selects
**magi-lock@native.service**, not magi-lock@lock.service.

The manager matches graphical MAGI PID 1543 and Hypridle PID 630192:
WAYLAND_DISPLAY=wayland-1, XDG_RUNTIME_DIR=/run/user/1000, the current Hyprland
signature and unix:path=/run/user/1000/bus. Hyprland PID 1492's initial /proc
environment lacks the display/signature it establishes during startup; its
running children and manager match. No environment import/retarget was performed.
Graphical session 1 is active Wayland on tty1. Hyprland reports unlocked.

Hyprlock 0.9.6-3 remains installed. Production Hypridle PID 630192 retains
`pidof hyprlock || hyprlock` and its normal delay inhibitor. All 533 pre-install
snapshot file hashes match, including existing PAM files and operator configs.
The new MAGI PAM file is the intended package addition; pacman database changes
are expected installation metadata. Snapshot is not an audit of every system
file or arbitrary third-party package hook. No Hypridle restart/handoff, routing
change, real lock/PAM, suspend, staging, commit or push was performed here.

### Pending direct test and recovery gate

Proposed command, **not executed**: `/usr/bin/magi-lock-request lock`.
One submission, no automatic retry; observer must be ready before execution.
Production has no development timer. Obtain fresh saved-work and authenticated
TTY confirmation plus explicit approval before acquisition. Use Ctrl+Alt+F3 to
reach an authenticated recovery TTY and Ctrl+Alt+F1 to return to the current
graphical VT. Verify the TTY is accessible before the test.

From the same user's recovery TTY, safe inspection is:

```sh
export XDG_RUNTIME_DIR=/run/user/1000
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
systemctl --user status magi-lock@native.service --no-pager
journalctl --user -u magi-lock@native.service -n 80 --no-pager
loginctl show-session 1 -p Name -p Type -p State -p VTNr
```

If securely stuck, do not kill/restart the locker or assume Hyprlock can take over.
A last-resort recovery is ending the confirmed graphical session from the separate
TTY: `loginctl terminate-session 1`. This closes that desktop and can lose unsaved
work; it does not authenticate/unlock the existing session. Confirm the session
is still the original graphical session before doing so, and never terminate the
recovery TTY. If logind denies permission, use the operator's administrative
recovery (`sudo loginctl terminate-session 1`) rather than weakening the locker.
Then log in afresh using the machine's normal graphical login/start procedure.
The production Hyprlock route remains unchanged. No termination is authorized or
executed as part of preparation; it is the explicit emergency plan to review.

Production direct-lock acceptance and all subsequent migration gates remain
**pending**. No live migration success is claimed.

### Deferred post-lock-screen Settings/refinement requirements

After lock-screen work, MAGI should expose **Power & Idle** Settings backed by
Hypridle: **Lock after**, **Turn displays off after**, and **Suspend after**.
Each needs Enabled/Never semantics and sensible bounded time choices; custom
values can follow where appropriate. Separate AC/battery policies are a potential
future enhancement, not an architecture commitment. MAGI Settings is the eventual
user-facing control surface; Hypridle remains the idle/DPMS/suspend policy engine.
Do not change current idle timings during Phase 8B.

Also retain **optional MAGI top bar on external displays** for the later
consolidated MAGI refinement pass. Neither Settings nor external-bar work is
implemented by this milestone.


### Direct installed-production test — software passed, visual confirmation pending

2026-10-18. Explicit operator approval preceded exactly one
`/usr/bin/magi-lock-request lock`. The pre-armed observer ran without mid-lock
chat interaction or automatic retries. No development timer exists or was added.
Evidence: `/tmp/magi-phase8b-hev2uoup/direct-test/`.

At invocation only eDP-1 was present (the earlier installation preflight had two
outputs). This test therefore establishes single-output software evidence only;
production dual-output acceptance remains a later separate gate.

Installed owner PID 671894 under magi-lock@native.service acquired native sleep
protection at 16:29:28.780245. Output registry 72/lifetime 1 received configure
1920x1080, acknowledged/committed without fallback. Compositor confirmed Locked
at 16:29:28.823996; systemd reported Started afterward at 16:29:28.831203.
One worker PID 671984 and generation-1 attempt began at 16:29:37.341205/341236.
Worker was reaped with Authentication succeeded at 16:29:37.397917; exactly one
AUTHENTICATED UNLOCK: current PAM Success followed at 16:29:37.398096.
Compositor processed explicit unlock and the owner exited. Final service state
inactive/dead, Result=success, ExecMainStatus=0; wrapper exit 0. No worker remains.
The verified installed owner uses its installed sibling worker and hardcoded
magi-lock PAM service; no development binaries or service override were selected.
No password content was captured. Cleanup cancellation diagnostics occur after
authenticated unlock and do not represent additional attempts.

Hyprland returned unlocked, eDP-1 active; production Hypridle PID 630192 retained
its normal inhibitor. All pre-install hashes except this intentionally updated
checkpoint match; installed package hashes also match. Hyprlock routing remains
unchanged. Operator visual acceptance is still pending; no later migration gate
has started. No suspend, Hypridle restart, staging, commit or push occurred.


Operator confirmed all direct-production visual checks: complete laptop coverage,
no desktop leakage, no literal password display, successful authentication and
clean desktop return. **Direct installed-production test accepted.**

Next gate prepared, not applied: exact live Hypridle rollback copy at
`/tmp/magi-phase8b-hev2uoup/hypridle.before-migration.conf` (mode 0600), SHA-256
`eb6fa3c034957abaf48de818e690429c4a1c8b4815e72ead5e19d90a30cc17fb`.
Proposed change replaces only lock_cmd and adds inhibit_sleep=3, preserving all
other bytes. Await separate approval before configuration edit/runtime restart.


### Live Hypridle routing migration — applied, Session.Lock test pending

Operator explicitly approved the exact two-setting diff and runtime restart.
Before mutation Hyprland was unlocked, logind PreparingForSleep=false, and no
locker/worker existed. Original PID 630192 argv/cwd/environment/start identity
matched the saved snapshot. Exact original backup remains preserved.

Applied only lock_cmd=/usr/bin/magi-lock-request sleep-coordinated and
inhibit_sleep=3. All other bytes remain unchanged. Original process received TERM;
no forced kill. Replacement PID 672803 uses /usr/bin/hypridle with original argv
`hypridle`, cwd /home/jkebwdn and byte-matched saved graphical environment.
Exactly one Hypridle and its normal sleep-delay inhibitor were verified.
Migrated config SHA-256:
`2e4480b4517bca59a84aaf8ff0801a464720454d3417c55d207f674e79f4b3c5`.
Rollback was pre-armed but not needed. Other protected hashes match; Hyprlock
remains installed. No explicit lock, suspend, staging, commit or push was run
in this migration step. Existing 300-second idle policy is now active with MAGI
routing; Session.Lock, Control Centre, suspend, dual-output and rollback-drill
acceptance remain pending and require their separate operator gates.


### Production Session.Lock test — software passed, visual confirmation pending

2026-10-18. Fresh operator approval preceded exactly one `loginctl lock-session`;
pre-armed diagnostics at `/tmp/magi-phase8b-hev2uoup/session-lock-test/` captured
the installed magi-lock@hypridle.service route. Owner PID 673042 configured
registry 72/lifetime 1 at 1920x1080 without fallback. Because no sleep was pending,
coordinated startup acquired native delay protection at 16:32:59.666784 as designed.
Compositor confirmed Locked at 16:32:59.704826, before systemd Started.
One generation-1 worker PID 673094 spawned at 16:33:04.497133, reaped with
Authentication succeeded at 16:33:04.560606. Exactly one AUTHENTICATED UNLOCK
at 16:33:04.560748; owner exited normally, service Result=success/ExecMainStatus=0,
Hyprland unlocked, no worker remained. eDP-1 only; no dual-output claim.
Hypridle PID 672803 and its inhibitor remain intact; migrated configuration and
all other protected baseline files match expected hashes. No retry or suspend.
Visual confirmation remains pending before acceptance/next test.


Operator confirmed all production Session.Lock visual checks: full coverage, no
desktop leakage, no literal password display, successful authentication and clean
return. **Production loginctl/Session.Lock test accepted.** The next gate is one
operator-triggered Control Centre Lock action with pre-armed observation; approval
and fresh saved-work/authenticated recovery confirmation are pending. No Control
Centre code changes are required or made.


### Control Centre test — software passed, operator confirmation pending

2026-10-18. Operator approved one UI-triggered test. Read-only observer was armed
before inviting the Control Centre Lock click; it issued no lock command. Evidence
is under `/tmp/magi-phase8b-hev2uoup/control-centre-test/`. Existing UI/source was
unchanged. Installed magi-lock@hypridle.service owner PID 673754 acquired native
sleep protection while awake and configured eDP-1 registry 72/lifetime 1 at
1920x1080 without fallback. Compositor Locked: 16:35:04.124303, before service
Started. One generation-1 worker PID 673835 spawned at 16:35:11.363022 and reaped
with authentication success at 16:35:11.414431. Exactly one AUTHENTICATED UNLOCK
at 16:35:11.414553. Service exited successfully; desktop unlocked; no worker
remains. Hypridle PID 672803 and its normal inhibitor remain. Protected hashes
match except approved config/checkpoint changes. Operator confirmation of UI
trigger and visual result is pending. No suspend or further gate executed.


Operator confirmed the Control Centre Lock trigger and all visual checks:
complete coverage, no desktop leakage, hidden password characters and clean
return. **Production Control Centre Lock test accepted.** No UI rewrite required.

Idle decision: retain the actual 300-second idle listener unchanged and defer
observing its elapsed-time firing to post-migration daily use. The exact listener
command (`loginctl lock-session`) and production destination have already passed
explicit Session.Lock and Control Centre tests; another deliberate five-minute
wait adds timer evidence only. This is not a claim of actual idle-timer acceptance.
Do not shorten timings. Record this pending observation in the final report and
resolve before declaring all Hyprlock-removal gates satisfied.

Next planned gate: one separately approved production suspend/resume from an
unlocked desktop using the actual migrated Hypridle, with no temporary handoff.
Fresh power/recovery approval and complete observation preparation are required.
No suspend has occurred during Phase 8B yet.


### Production suspend/resume — software passed, visual confirmation pending

2026-10-18. Operator approved one cycle with saved-work/recovery gate. AC connected,
battery charging at 66%; eDP-1 only. Actual migrated Hypridle PID 672803 remained
running throughout; no temporary handoff/config. Pre-armed observer confirmed
Unlocked, no locker/worker, PreparingForSleep=false, installed hashes, supported
suspend and pre-existing Hypridle inhibitor before issuing exactly one systemctl
suspend. Evidence: `/tmp/magi-phase8b-hev2uoup/production-suspend/`.

Epoch timestamps (seconds, realtime):

- Request issued: 1792337856.441641; logind request: 1792337856.453276.
- Hypridle PrepareForSleep(true) observed: 1792337856.455024, with inhibitor FD10
  still `/run/systemd/inhibit/135.ref`; Session.Lock/request observed .457220.
- MAGI pending-sleep startup: 1792337856.496103; input blocked/credential cleared.
- Compositor Locked: 1792337856.524803. eDP-1 registry 72/lifetime 1 configured
  1920x1080, acknowledged/committed without fallback before confirmation.
- Hypridle notifier/release log and absent FD10 observed: 1792337856.526353.
- MAGI auth-quiescent/coordinated diagnostic: 1792337856.531044; zero late native
  inhibitor acquisitions before suspend. Hypridle gates on compositor notifier,
  not the later diagnostic or Type=notify delivery.
- systemd Performing sleep operation suspend: 1792337856.673545.
- Returned from suspend: 1792337869.905161.
- MAGI PrepareForSleep(false): 1792337870.043779; native inhibitor acquired
  .047270, before RESUME/input reconstruction .053677/.058105.
- One worker PID 675206, generation 1: 1792337875.773264/.773765.
- Worker reaped/Authentication succeeded: 1792337875.836567; exactly one
  AUTHENTICATED UNLOCK at 1792337875.836665. No timer or retry.

Hypridle timestamps are bounded userspace observations (2 ms polling target),
not syscall instrumentation. Its notifier/release ordering plus observed FD closure
precedes actual systemd suspend. Lock confirmation was about 71.527 ms after
logind's recorded request (about 69.779 ms after observing PrepareForSleep), leaving
about 4.928 s against the effective 5-second delay allowance using request time.
No indefinite-veto claim. Logind's earlier 'will suspend now' announcement is
sleep intent, not the actual systemd Performing sleep operation timestamp.

Output identity retained across sleep, remained globally Locked with generation 0
until manual submission. Native protection preceded input rebuild; no automatic
PAM. Final state Unlocked, PreparingForSleep=false, suspend command exit 0; no
locker/worker remains. MAGI PID1543/Hyprland PID1492 and Hypridle PID672803 remain;
Hypridle reacquired inhibitor `/run/systemd/inhibit/141.ref`. Protected hashes
match except approved Hypridle/checkpoint edits; installed hashes match.
Systemd logged existing SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=0 policy; no system
sleep configuration was changed. Visual suspend/wake/coverage acceptance pending.


Operator confirmed all production suspend visual checks: MAGI before sleep,
genuine suspend, no desktop leakage during wake, locked presentation on resume,
working input, hidden password characters and clean authenticated return.
**Production suspend/resume accepted.** No second suspend was performed.

The operator subsequently connected the external monitor normally while unlocked.
The separate production dual-output lock gate is being prepared; no lock command
has been issued and fresh saved-work/recovery approval remains required.


### Production dual-output lock — software passed, visual confirmation pending

2026-10-18. Fresh operator approval preceded one `loginctl lock-session` with
both displays active. Pre-armed observer: `/tmp/magi-phase8b-hev2uoup/dual-output-test/`.
Installed owner PID 676384 used magi-lock@hypridle.service. eDP-1 registry 72,
lifetime 1 configured 1920x1080 (scale 2); HDMI-A-1 registry 84, lifetime 2
configured 2560x1440 (scale 1.5). Both surfaces acknowledged/committed without
fallback; one global lock/auth state remained generation 0 until submission.
One generation-1 worker PID 676464 spawned at 16:41:54.239024, reaped with success
at 16:41:54.317419; exactly one AUTHENTICATED UNLOCK at 16:41:54.317682.
Service exited successfully; no locker/worker remains. Both outputs remain active
and normal, Hyprland unlocked, Hypridle PID672803 inhibitor intact. Protected hashes
match except approved config/checkpoint changes. No hotplug or suspend in this
run. Operator visual acceptance pending; rollback drill has not started.


Operator confirmed all dual-output visual checks: both displays fully covered,
no desktop leakage, password hidden, both unlocked together and both returned
cleanly. **Production dual-output lock accepted.**

Next required gate is the controlled routing rollback drill. Original backup hash
reverified; proposed procedure restores only the exact original Hypridle bytes,
restarts with audited invocation/environment, verifies one process and its normal
inhibitor, then performs one separately approved Hyprlock test via Session.Lock.
MAGI package stays installed. No rollback action has run yet; fresh approval and
saved-work/authenticated TTY recovery confirmation are pending. MAGI reapplication
will follow only after successful rollback acceptance and its own approval gate.


### Required rollback drill — software passed, visual confirmation pending

2026-10-18. Operator approved restoring original routing and one Hyprlock test.
Preconditions verified unlocked/no pending sleep/no locker. Restored exact backup
SHA-256 eb6fa3c034957abaf48de818e690429c4a1c8b4815e72ead5e19d90a30cc17fb,
including original lock_cmd and implicit original sleep-inhibition mode. Hypridle
PID672803 terminated normally; replacement PID677006 uses audited original
argv/cwd/environment. Exactly one process and normal delay inhibitor verified
before issuing exactly one loginctl lock-session. MAGI package was not removed.

Evidence `/tmp/magi-phase8b-hev2uoup/rollback-drill/`: Hypridle launched Hyprlock;
Hyprlock configured both outputs at 1920x1080 and 2560x1440, compositor confirmed
locked, and Hyprlock logged authentication success, unlocking, and clean exit.
No MAGI owner/worker launched. Observer saw locked then unlocked, Hyprlock exited,
both outputs stayed active, and Hypridle reacquired its normal delay inhibitor.
No claim is made about MAGI PAM semantics from the fallback's authentication.
Original config/all protected hashes (except checkpoint) now match pre-install
baseline; installed MAGI hashes unchanged. Hyprlock routing remains active pending
operator visual acceptance and separate MAGI-reapplication approval. No automatic
reapplication, suspend, staging, commit or push occurred.


Operator confirmed Hyprlock worked as expected. **Required rollback drill
accepted:** original routing, functional fallback lock/authentication and clean
return are proven without uninstalling MAGI. Final reapplication is pending
explicit approval: restore only the previously reviewed MAGI lock_cmd/inhibit_sleep
hunk, restart Hypridle using audited runtime parameters, verify inhibitor, then
one final loginctl Session.Lock check. No full acceptance suite will be repeated.


### Final MAGI reapplication — software passed, visual confirmation pending

Operator approved reapplication and one final Session.Lock check. Reapplied only
the identical reviewed two-setting hunk, replacing rollback Hypridle PID677006
with PID677552 using original audited argv/cwd/environment. One instance and its
normal inhibitor verified before exactly one loginctl lock-session. Evidence:
`/tmp/magi-phase8b-hev2uoup/final-magi-test/`.

Installed magi-lock@hypridle.service received both physical outputs. One
generation-1 worker was spawned/reaped successfully; exactly one AUTHENTICATED
UNLOCK. Final state unlocked, no MAGI owner/worker or Hyprlock process remains;
both outputs active, Hypridle PID677552 inhibitor verified. Package hashes match;
all other protected baseline hashes match except approved Hypridle/checkpoint.
MAGI routing is active; Hyprlock remains installed as unused fallback. Final
operator visual confirmation is pending. No full suite repeated or additional
suspend performed. No staging, commit or push.


Operator confirmed the final MAGI visual checks: both outputs fully covered,
no desktop leakage, hidden password, simultaneous unlock and clean return.
**Final MAGI reapplication accepted. Phase 8B controlled migration complete,
with actual 300-second idle-timer observation explicitly deferred to daily use.**

Final acceptance summary: installed package/PAM verified; direct production lock,
Session.Lock, Control Centre, production suspend/resume, production dual-output
lock, actual Hyprlock rollback drill, and final MAGI reapplication all accepted.
Every MAGI test used one generation-1 worker and exactly one authenticated unlock.
No production timer/failure fixture, automatic retry, package removal or broad
cleanup was used. The operator accepted coverage/clean return for every live gate.

Final active Hypridle configuration uses /usr/bin/magi-lock-request
sleep-coordinated and inhibit_sleep=3, retaining before_sleep loginctl,
after_sleep DPMS enable, 300-second lock and 600-second DPMS listeners unchanged.
Hypridle remains the production idle/DPMS/Session.Lock/sleep coordinator.
Hyprlock 0.9.6-3 remains installed as an unused tested fallback. Active config,
manual-routing source, installed service/request and MAGI PAM have no Hyprlock
launch/PAM dependency. Theme orchestrator adapters/__init__.py retains a protected
Hyprlock-configuration metadata entry; it is not a lock route. Historical docs,
rollback copies and hyprlock.conf remain deliberately preserved.

No native source correction was needed in Phase 8B. Repository changes comprise
this checkpoint and the authorized operator-local live hypridle.conf migration;
all pre-existing operator changes are preserved. Nothing was staged/committed or
pushed. Original exact backup and evidence remain in /tmp/magi-phase8b-hev2uoup;
that directory is temporary and is not package/repository content.

**Not all Hyprlock-removal gates are closed:** actual idle timer firing remains a
daily-use observation, and removal requires a separate explicit operator decision.
No Hyprlock removal is performed or authorized by this completion record. Deferred
Power & Idle Settings/external top-bar refinement remains documentation only.


### Actual 300-second production idle observation — software passed, visuals pending

2026-10-18. Fresh operator saved-work/recovery confirmation preceded a bounded
read-only observer. No input was synthesized, no lock command was issued by the
observer, no timeout changed, and no suspend/topology change occurred. Evidence:
`/tmp/magi-idle-acceptance-8b0z4ge9/observation/`.

Observation armed at epoch 1792338578.974564; Hypridle's actual `Idled` event was
observed at 1792338879.262151: **300.288 seconds** elapsed. This is observer elapsed
time, not a direct timestamp of the final physical input; approximately one-second
sampling bounds apply. Hypridle's log explicitly records the idle rule firing,
Running/Executing loginctl lock-session, Session.Lock delivery, and launching
/usr/bin/magi-lock-request sleep-coordinated. No manual trigger was substituted.
The 600-second DPMS listener remained unchanged and its firing was not observed.

Installed owner PID681327 configured eDP-1 registry72/lifetime1 at 1920x1080 and
HDMI-A-1 registry84/lifetime2 at 2560x1440. Compositor confirmed Locked at
16:54:39.105949. One generation-1 worker PID681470 spawned at 16:54:52.393219;
clean reap/Authentication succeeded at 16:54:52.468725; exactly one AUTHENTICATED
UNLOCK at 16:54:52.468833. Service ended inactive/dead, Result=success,
ExecMainStatus=0; no locker/worker remains. Hypridle PID677552 healthy, normal
inhibitor restored/present. All idle-test snapshot hashes matched before this
checkpoint update, including live configuration and installed package files.
Operator confirmation of no manual trigger, natural appearance after five minutes,
coverage/no leakage/hidden password/successful authentication/clean return is
pending. Hyprlock remains installed; no removal, staging, commit or push performed.


Operator confirmed no manual lock trigger, natural MAGI appearance after roughly
five minutes, complete coverage, no desktop leakage, hidden password characters,
successful authentication and clean return. **Actual production 300-second idle
lock observation accepted.** This closes the idle-observation deferral recorded
earlier; those entries remain as chronological history. The 600-second DPMS
listener was not awaited or claimed tested.

**All agreed Phase 8B production acceptance gates required before considering
Hyprlock removal are now satisfied:** installed package/MAGI PAM, direct lock,
Session.Lock, Control Centre, actual idle lock, production suspend/resume,
dual-output coverage, proven Hyprlock routing rollback, and successful MAGI
reapplication. No active routing/PAM dependency on Hyprlock remains. Its protected
theme metadata/historical configuration is not an active lock dependency.

This is acceptance evidence, not removal authorization. **Hyprlock remains
installed as unused fallback.** Any removal requires a separate explicit operator
decision. MAGI routing and Hypridle remain active. No further live test, config
change, package removal, staging, commit or push was performed. All idle-test
snapshot hashes other than this intentionally updated checkpoint still match.


## Final Phase 8B production acceptance

| Gate | Result |
| --- | --- |
| Package/PAM verification | PASS |
| Direct installed production lock | PASS |
| Session.Lock | PASS |
| Control Centre Lock | PASS |
| Suspend/resume | PASS |
| Dual-output | PASS |
| Hyprlock rollback | PASS |
| MAGI reapplication | PASS |
| Genuine 300s idle lock | PASS |
| 600s DPMS firing | NOT TESTED |

**Actual idle lock firing observed at 300.288 seconds.**
**600-second DPMS-off timer was NOT observed during Phase 8B.** Its unchanged
policy/command makes this informational, not a blocker to accepted MAGI locking
or the separate Hyprlock-removal decision. All applicable operator visual checks
passed. All agreed security/production gates for later removal are satisfied;
Hyprlock removal is explicitly outside Phase 8B and requires separate approval.

Current effective idle policy: Lock after 5 minutes; displays off after 10 minutes;
Suspend after Never (no idle-suspend listener). Other explicit/lid system suspend
policy is not disabled by that statement. Future Power & Idle Settings will expose
these controls through Hypridle, with Enabled/Never and bounded choices, possible
later custom values/AC-battery profiles. Future external-display MAGI top-bar
Settings remains deferred. Neither feature is implemented here.

Hypridle remains a permanent production dependency for idle timers, Session.Lock,
DPMS, suspend and lock-before-suspend coordination. MAGI replaces Hyprlock's locker
role, not Hypridle. Final read-only audit found magi-lock 0.1.0-1 and Hyprlock
0.9.6-3 installed, exactly one Hypridle PID677552 with normal delay inhibitor,
Hyprland unlocked and no locker/worker. Accepted live settings unchanged.

Canonical configuration audit: ~/.config/hypr is a symlink to
../dotfiles/linux/t15g/hypr/.config/hypr. Thus the requested hypridle.conf is the
canonical Stow-deployed file. Its bytes differ from the exact pre-migration backup
only in the accepted lock_cmd replacement and added inhibit_sleep=3. However,
HEAD/index have never tracked that file: Git sees it as a new 17-line file, not a
two-setting modification. Tracking it would necessarily add the preserved
before/after-sleep and listener baseline too. No partial two-line file may replace
the deployable config. This staging distinction is recorded for operator review
before committing; no other protected path belongs in the Phase 8B allowlist.


The operator explicitly approved tracking the complete canonical 17-line
hypridle.conf alongside this finalized checkpoint. The preserved baseline
before/after-sleep and listener settings are included because the file was
previously untracked; the only change from the pre-migration configuration is
the accepted two-setting MAGI routing hunk. Phase 8B commit allowlist is exactly
these two paths. No unrelated protected configuration is included.
