# MAGI Lock Screen — Phase 7A suspend/readiness architecture

2026-10-18. Baseline verified first:
`9f9ab8618db09b9f1e6f7d15aea67e8662fb3254`,
`magi: harden multi-output session lock`, HEAD/origin/main `0 0`.
**Original Phase 7A checkpoint: non-disruptive implementation only.**
**Current acceptance: Phase 7 live acceptance is complete. Live Test 1, revised
dual-coordinator Live Test 2, and the final dual-output suspend/resume gate passed,
including operator visual acceptance. Test 3 is subsumed by revised Live Test 2;
no separate execution is required. Earlier failed/incomplete runs and corrections
remain recorded below. Production migration remains unproven and unauthorized.**
Hyprlock remains production/fallback. No live configuration, earlier checkpoint,
Rust PAM worker or production route is changed. Nothing is installed/enabled.

## Security boundary and guarantee limits

One native compositor lock, controller, credential buffer and at most one PAM
worker remain authoritative. QML remains presentation-only. Only current-generation
validated PAM Success can authorize normal unlock. The new sleep policy only
vetoes unlock; it cannot manufacture Success or send a Wayland unlock request.
Phase 6 output lifecycle remains the sole output architecture.

A process starting, a lock request, a surface, a rendered frame or logind LockedHint
is NOT secure readiness. `Controller::secureLockReady()` requires the actual
`ext_session_lock_v1.locked` transition, current Locked state and no teardown.
This is false during acquisition, failure, unlocking and cleanup. Zero outputs
does not negate a compositor-confirmed session lock.

**A finite delay inhibitor cannot meet an unconditional NEVER-suspend-unlocked
claim.** The intended normal path waits for compositor confirmation, not elapsed
time. Acquisition failure, a stalled/crashed locker or expired logind delay can
still permit sleep. No claim of permanent blocking is made. Production migration
remains blocked until live timing/ordering acceptance and explicit acceptance of
platform limits. Privileged direct sleep-target/kernel operations, missing/crashed
Hypridle, missing notifier and bypassing logind are outside this integration's
protection. Critical-power/firmware sleep is not made safe by a user daemon.

## Current live flow (read-only audit)

Installed `hypridle --version`: v0.1.8; package `hypridle 0.1.8-2`.
Installed systemd: `262-1`; libsystemd pkg-config 262. Qt 6.11.2.
Live `~/.config/hypr/hypridle.conf` resolves to the protected repository file.
Original processes: Hyprland PID 1492, Hypridle 1541, MAGI Quickshell 1543, all
retaining October 12 start times. Hyprland's registry advertises
`hyprland_lock_notifier_v1` v1 and `ext_session_lock_manager_v1` v1 (read-only
registry probe; no lock manager bound). `wayland-info` was unavailable.

| Trigger | Current action |
| --- | --- |
| Control Centre/system action Lock | `system_actions.py` → `loginctl lock-session` |
| logind Session.Lock received by Hypridle | `pidof hyprlock || hyprlock` |
| Idle 300 s | `loginctl lock-session` |
| Idle 600 s | `hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'` |
| Activity after DPMS listener | `hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'` |
| PrepareForSleep(true) | `loginctl lock-session` |
| PrepareForSleep(false) | `hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'` |

There is no idle-triggered suspend command in the live file. No explicit
inhibit_sleep/unlock_cmd is set. No dedicated Lock/suspend/lid keybind was found in
live Hyprland Lua; Super+L is layout preselection. MAGI's existing power helper has
hibernate/shutdown/reboot actions, not a newly introduced suspend action. Configured
Hyprlock uses `hyprlock` PAM plus its separate direct fingerprint backend; MAGI's
proof still uses only its accepted password/PAM policy.

`systemd-analyze cat-config systemd/logind.conf` showed no active overrides or
drop-ins. Live Manager properties: InhibitDelayMaxUSec **5000000**, PreparingForSleep
false, HandleLidSwitch `suspend`, HandleLidSwitchDocked `ignore`. Lid behaviour with
multiple displays is therefore not an unconditional suspend trigger. No low-level
lid inhibitor appeared in the inhibitor listing. Current sleep delay holders were
Hypridle, NetworkManager, UPower, realtime kit and fprintd. No MAGI inhibitor was
acquired. No user lock/sleep units were listed. Existing `/usr/lib/systemd/system-sleep`
hooks are nvidia and tlp; these manage device power, not MAGI readiness. The inspected
systemd-suspend service runs systemd-sleep after sleep.target. Hooks are not a place
to wait for frozen user-session services. Hibernation is untested/future, not added
here merely because the existing shell offers it.

## Authoritative source findings

Inspected 2026-10-18. No upstream implementation code was copied.

- [Hypridle v0.1.8 core](https://github.com/hyprwm/hypridle/blob/v0.1.8/src/core/Hypridle.cpp),
  `run`, `handleDbusSleep`, `onLocked/onUnlocked`, `inhibitSleep`:
  auto mode 2 selects notifier mode when before_sleep contains `hyprlock`, or when
  lock_cmd contains `hyprlock` and before_sleep contains `lock-session`, with the
  notifier available. Explicit mode 3 selects compositor notification directly.
  Normal mode launches before_sleep asynchronously then releases its delay; it
  does not wait for that command's exit/readiness. Notifier mode releases on
  compositor locked and reacquires on unlocked. Thus merely replacing the command
  loses the safe readiness wait. [Config source](https://github.com/hyprwm/hypridle/blob/v0.1.8/src/config/ConfigManager.cpp)
  defaults inhibit_sleep to 2. [Current main core](https://github.com/hyprwm/hypridle/blob/main/src/core/Hypridle.cpp)
  inspected the same day retains these relevant branches; this is a dated source
  comparison, not a claim of a pinned installed executable/source reproducibility.
  [Current Hypridle docs](https://wiki.hypr.land/Hypr-Ecosystem/hypridle/) describe
  explicit mode 3. Compatibility: live notifier availability was verified.
- [systemd v262 inhibitor design](https://github.com/systemd/systemd/blob/v262/docs/INHIBITOR_LOCKS.md):
  acquire the delay FD before sleep intent. Subscribe-only or acquisition after
  the signal is racy. Close all FD copies after preparation; crash also closes
  them. Delay expires at the configured maximum. False means completion or failure,
  normally resume; reacquire for the next cycle. Signals cover logind-mediated
  sleep, not every kernel sleep path. These facts prohibit an absolute veto claim.
- [login1 API](https://www.freedesktop.org/software/systemd/man/latest/org.freedesktop.login1.html):
  `Inhibit("sleep", who, why, "delay")` returns a Unix FD;
  PreparingForSleep can reconcile startup with an already-pending signal.
  [logind.conf](https://www.freedesktop.org/software/systemd/man/latest/logind.conf.html)
  defines the finite delay and lid/docked policy. Live D-Bus properties above,
  rather than commented defaults, establish the relevant running settings.
- [systemd v262 polkit policy](https://github.com/systemd/systemd/blob/v262/src/login/org.freedesktop.login1.policy),
  inhibit-delay-sleep: default allow_any/inactive/active are yes. Ordinary-user
  delay acquisition is supported, subject to administrator overrides; denial is
  still handled. No privilege escalation or policy modification is implemented.
- [systemd service semantics](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html):
  Type=notify stays activating until READY=1; NotifyAccess=main restricts attribution.
  Repeated starts of the same service use one activation/job. Restart=no avoids
  pretending a replacement process can inherit the dead owner's compositor lock.
  The native guard additionally rejects independent duplicate launches.

## Options and selected integration

| Option | Security/races and crash behaviour | Cost, privileges, testability | Manual/idle/direct suspend |
| --- | --- | --- | --- |
| A: Hypridle waits for a ready child | Before-sleep command completion is not mode-1 readiness in this version; name heuristic is unsafe for MAGI | Requires patch or mode 3; no new privilege; fakeable | Manual/idle okay; direct sleep needs preheld inhibitor |
| B: native locker alone owns delay | Handles auth cleanup while alive; cannot catch sleep when no locker exists | Small libsystemd adapter, ordinary user; fake backend | Insufficient alone for unlocked direct suspend |
| C: persistent companion | Can hold inhibitor and supervise an on-demand owner; still finite/crash-sensitive | New daemon, IPC, lifecycle and handoff complexity | Covers logind paths while healthy; unnecessary duplication here |
| D: existing Hypridle mode 3 plus native cleanup inhibitor | Compositor-based readiness while unlocked; native preheld FD handles secrets/worker while locked | No new daemon; libsystemd dependency and on-demand user unit; fake policy tests | Selected for normal manual/idle/logind-mediated suspend |

Hypridle holds its existing cheap persistent delay while unlocked. It receives
logind sleep intent irrespective of whether a lid, systemctl or another logind
client initiated it, requests lock, and waits for compositor notification. MAGI
acquires its own delay **before** Wayland lock acquisition and holds it while
awake/locked: this is needed because Hypridle releases its own when lock is already
established. Both FD holders must release for sleep to proceed before the maximum.
No bespoke suspend daemon, sleep invocation, DPMS replacement or arbitrary sleep
as a security barrier is added.

Manual lock uses the same short-lived owner and cheap native delay; it does not
block normal sleep indefinitely. The native owner exits after authenticated unlock.
The main Quickshell shell is not a dependency. No automatic Hyprlock fallback is
launched over an uncertain lock owner; production remains routed to Hyprlock until
migration. Native integration startup failure returns nonzero without readiness.

## Implemented native contracts

`--sleep-integration` and `--notify-ready` require explicit acquisition plus
`--authenticate`. Informational/invalid invocations cannot arm sleep integration.
Without the sleep flag there is no logind connection. No suspend method or public
unlock endpoint exists. No QML properties were added.

`--notify-ready` sends systemd READY=1 only from the native locked callback, after
Controller accepts the compositor event. Failed delivery logs a constant diagnostic
and retains the lock. This reports acquisition, not a promise that a later sleep
or arbitrary future instant remains locked. No raw secrets/worker data cross it.

The on-demand `integration/magi-lock.service` is **uninstalled template only**:
Type=notify, NotifyAccess=main, Restart=no, RefuseManualStop=yes, core dumps disabled,
20-second startup bound, no enable/install section. Startup timeout/death never
sends unlock; compositor fail-secure/recovery remains authoritative. A service
start is a readiness wait, not process-start success. `magi-lock-request` accepts
no arguments and only executes `systemctl --user start magi-lock.service`; it
cannot stop/restart/unlock. Concurrent manual/idle/sleep service requests coalesce.
Independent owner invocations use a nonblocking per-WAYLAND_DISPLAY flock in the
validated private XDG_RUNTIME_DIR, held until exit, CLOEXEC, no unlink/symlink or
world-accessible file. A duplicate returns 73 without claiming readiness. This is
single graphical session per user, not a multi-session service design; same-UID
malicious filesystem/environment manipulation is outside the existing trust model.

Proposed package paths, not installed:

- `/usr/bin/magi-lock-request` — safe request/wait wrapper.
- `/usr/lib/magi/magi-lock` — reviewed default owner (packaged name of proof target).
- `/usr/lib/magi/magi-lock-auth` — trusted sibling worker; build with empty
  MAGI_LOCK_AUTH_WORKER to use this sibling, never a /tmp path.
- `/usr/lib/systemd/user/magi-lock.service` — on-demand template.

The compositor session must import its verified WAYLAND_DISPLAY/XDG_RUNTIME_DIR
into the user manager before requests. No stale hardcoded instance signature in
production commands. No broad systemd sandbox options that break PAM helpers
(e.g. NoNewPrivileges) were blindly added. Packaging and session startup wiring
remain a separate gate.

## Sleep state machine, credentials and resume

`Unarmed → Awake → Preparing → SecureForSleep → Awake` on successful resume.
Error is latched and blocks normal authentication; recovery requires operator
assessment, not a silent unlock/restart. SecureForSleep means permission released,
not proof that the kernel actually slept. False after failed suspend follows the
same resume path. Duplicate true/false signals are idempotent.

The adapter subscribes to the system-bus signal, acquires/duplicates the inhibitor
FD with CLOEXEC, reads the running maximum and PreparingForSleep property, then
begins bounded event-loop processing. An already-pending true property enters
preparation. D-Bus calls have a one-second bound; processing drains at most 32
messages per 10 ms tick. Polling cadence is event delivery, not readiness authority.
This adapter is only activated by explicit opt-in, never by the synthetic suite.

On true: block normal unlock first; block native keys/focus; erase partial input;
cancel the current auth attempt and invalidate its Success receipt. Cancellation
uses accepted bounded worker cancellation, two-second kill/reap backstop and retry
policy. Progress releases delay only when **secureLockReady AND auth.quiescent**
(no child, no IPC FD, empty native credential). Output events cannot release it.
The native generation does not reset; a fresh submission later increments it.
No password is intentionally carried through sleep. Worker/PAM-internal erasure
cannot be guaranteed under forced termination or catastrophic process failure.

Preparation deadline is min(4 s, observed maximum minus 250 ms); this is a failure
budget, never permission to sleep. Timeout, bus loss/name-owner replacement or
inhibitor reacquisition failure enters Error, cancels input/auth, reports
SLEEP SAFETY UNPROVEN, and retains any held FD. logind can still expire the delay.
A crash closes it. No normal unlock is authorized by these errors.

On false: reacquire native delay before enabling fresh input; recreate wl_keyboard
only if the seat still has keyboard capability. Clear focus, held keys, compose and
modifier readiness. Fresh keymap/enter/modifiers must arrive before processing
keys. A held/stale key cannot submit a restored password. Presentation refresh uses
Phase 6 records and supports zero outputs, one/two returning outputs, changed IDs,
old lifetime callbacks and native fallback. No pre-sleep credential or Success is
restored; a new PAM attempt is required.

Before consuming a successful receipt, opt-in integration additionally queries
PreparingForSleep and vetoes unlock on true/error. It does not create authorization.
**This query is not atomic with a future sleep request.** An authenticated-unlock
versus new sleep-intent/handoff race remains a live integration gate: Hypridle
must observe unlock/reacquire and request lock again as applicable. There is no
claim of an atomic transaction across Wayland and logind. The same finite-delay
limits apply. Do not promote this prototype to production based only on mocks.
The development emergency timer remains an explicit unsafe recovery bypass,
compiled out of the default build; a timer firing fails live authenticated acceptance.

## Proposed Hypridle migration — DO NOT APPLY

Current protected general block:

```ini
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'
}
```

Proposed after packaging, environment setup and live acceptance:

```diff
 general {
-    lock_cmd = pidof hyprlock || hyprlock
+    lock_cmd = /usr/bin/magi-lock-request
+    inhibit_sleep = 3
     before_sleep_cmd = loginctl lock-session
     after_sleep_cmd = hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'
 }
```

The launcher gives one native owner/readiness job. Explicit 3 removes the
Hyprlock-substring dependency. Before-sleep still requests the current graphical
session lock; compositor notification is the authoritative Hypridle wait, not the
exit of loginctl. Both DPMS listener commands and 300-second lock remain unchanged.
Control Centre/system_actions can retain loginctl and reach the same launcher via
Hypridle. No new keybind is required. Resolve/verify graphical logind session
selection during live preflight; never let a TTY caller accidentally target its
own session for an intended graphical lock.

## Non-disruptive tests and limits

`sleep_synthetic` uses the production Controller/AuthController/NativeInput with a
fake SleepBackend/Wayland backend and accepted synthetic Rust fixture. It covers
acquire-once, unlocked preparation, already locked, no readiness from frames,
duplicate signals, secure confirmation, timeout/acquisition failure, inhibitor
failure, resume reacquire failure, partial input erasure, active and hung worker
reap, completed-but-unconsumed Success cancellation, no stale-generation unlock,
resume with no outputs/one/two returning outputs, fallback, old callback rejection,
stale keys/modifiers, fresh post-resume auth, competing native processes and CLI
gates. It checks secret non-leakage. The initial new test used the wrong synthetic
fixture secret and failed; correcting the fixture input made it pass without
changing real PAM code. This was a test setup error, not live acceptance.

Real logind transport timing, systemd activation, keyboard reacquisition on this
compositor, user-session freeze behaviour, physical frames and suspend recovery
are NOT established by fake backends. No private fake claims a real sleep occurred.
No public Unlock API, production routing edit or PAM configuration is introduced.

## Phase 7B plan — no live step executed or authorized here

Every test is separately approved with saved work, AC/battery check, short planned
sleep, fresh authenticated TTY/recovery assessment and an understanding that a
TTY is unavailable during sleep itself. Confirm lid/recovery access; do not rely
solely on a timer if the process/compositor freezes. Pre-arm bounded observation
and postflight before locking so tool approvals cannot consume the recovery window.
Do not repeat accepted Phase 6 tests or combine failures. Use only one real password
submission after resume, no retry; emergency timer recovery means acceptance failed.

1. **Already locked:** temporary reviewed development owner with
   `--acquire-session-lock --authenticate --sleep-integration
   --unsafe-development-unlock-after=180`; confirm compositor lock, native armed FD,
   and saved work. Only after individual approval request one `systemctl suspend`.
   Wake promptly. Verify true → credential clear/worker absent → SECURE FOR SLEEP
   before sleep, false → reacquire → fresh keyboard, continuous physical coverage,
   then one authenticated unlock and timer cancellation. No partial real password
   should be entered before sleep. Verify original MAGI/Hypridle and protected hashes.
2. **Unlocked suspend request:** separately approved temporary integration setup
   exercising Hypridle mode 3 and the native service. Live production Hypridle must
   not be left competing for Session.Lock. Exact temporary handoff/restore procedure
   must be reviewed at that time; do not silently stop or reconfigure it in Phase 7A.
   With both inhibitors armed as appropriate, request one logind-mediated suspend.
   Record acquisition/confirmation preceding release and system sleep. Resume
   locked; authenticate once. If startup/ready exceeds the effective five-second
   delay, fail the gate, not silently increase the timeout or accept unlocked sleep.
3. **Hypridle-equivalent flow:** separate temporary configuration/unit with verified
   graphical environment and reviewed build paths. Exercise loginctl → Session.Lock
   → request unit → READY → compositor notifier; preserve DPMS policy. Verify the
   full actual future command chain on one approved suspend/resume. A mock command
   run is not a substitute. Restore production Hyprlock routing afterward.
4. **Output topology across sleep, if practical:** individually approve a dual-output
   run with scales 2/1.5; one planned topology condition across sleep. Verify Phase 6
   lifetimes, no desktop exposure, and one global authenticated unlock after resume.

Additional gate before production: deliberately bounded non-sleep integration of
inhibitor startup/denial/deadline/error and simultaneous lock requests, plus review
of suspend racing authenticated unlock. Do not inject a real unlocked-suspend
failure on this workstation. Use a disposable environment for deadline exhaustion.
No compositor restart, hibernate, production migration or visual work in these tests.

Remaining: live Phase 7B acceptance, atomicity/finite-delay risk decision, packaging
and trusted service paths, session environment wiring, production PAM/account
policy, broader keyboard layouts/MFA/fingerprint, compositor restart/failure,
Hyprlock retirement and final visual design. Hibernation remains optional future work.

## Exact Phase 7A path scope

22 paths: 12 existing files modified and 10 new files. Protected operator changes
are excluded; earlier checkpoints and all Rust worker/fixture sources are unchanged.

```text
linux/magi/docs/design/lock-screen-phase7-suspend-resume.md
linux/magi/native/lock/CMakeLists.txt
linux/magi/native/lock/README.md
linux/magi/native/lock/integration/magi-lock-request
linux/magi/native/lock/integration/magi-lock.service
linux/magi/native/lock/src/auth_controller.hpp
linux/magi/native/lock/src/controller.cpp
linux/magi/native/lock/src/controller.hpp
linux/magi/native/lock/src/instance_guard.cpp
linux/magi/native/lock/src/instance_guard.hpp
linux/magi/native/lock/src/logind_sleep.cpp
linux/magi/native/lock/src/logind_sleep.hpp
linux/magi/native/lock/src/main.cpp
linux/magi/native/lock/src/native_input.cpp
linux/magi/native/lock/src/native_input.hpp
linux/magi/native/lock/src/options.cpp
linux/magi/native/lock/src/options.hpp
linux/magi/native/lock/src/sleep_policy.cpp
linux/magi/native/lock/src/sleep_policy.hpp
linux/magi/native/lock/src/wayland_owner.cpp
linux/magi/native/lock/src/wayland_owner.hpp
linux/magi/native/lock/tests/sleep_test.cpp
```

## Final non-disruptive results

- Default and development builds pass in `/tmp/magi-lock-phase7-{build,dev-build}`.
- Complete CTest: **9/9 default, 9/9 development**; each includes **25** new
  sleep/readiness/fake-inhibitor/input/instance scenarios and **41** Phase 6 output
  scenarios, plus Phase 5 auth containment, stale-result, presentation boundary,
  secret leakage and binary security regressions.
- Rust locked/offline: **18/18**; Clippy all-targets with warnings denied and
  formatting pass. Rust source/fixtures unchanged. Fixture execution used an
  environment permitting inherited Unix IPC, not real PAM.
- Default build-info: development-unlock=0, failure-injection=0. Development flags
  remain explicit and compiled out of default. No real integration flags invoked.
- Request wrapper shell syntax passes. Unit structure checked with systemd-analyze
  on a /tmp copy substituting `/usr/bin/true` for the uninstalled future executable;
  no unit was started. Sandbox socket-option warnings are not a live unit test.
- Fresh snapshot: **505/517 pre-existing files unchanged**, with all 12 changed
  existing files confined to the intended native-locker scope. All protected
  operator/runtime/PAM files and prior checkpoints match. New paths are listed
  above. No build outputs are tracked; `git diff --check` passes; index empty.
- No real suspend, session lock, real PAM transaction, password entry, headless or
  physical hotplug, compositor restart, live Hypridle/PAM/routing edit, service
  install/enable, staging, commit or push occurred.

**Stop for operator review. Phase 7B is not started.** Live logind transport,
service activation and suspend/resume acceptance require explicit separate
approval; passing synthetic tests does not authorize them or production migration.

## Phase 7B Live Test 1 — first attempt incomplete before suspend

2026-10-18. Individually approved already-locked suspend/resume test, following
fresh saved-work/authenticated-recovery confirmation. This entry supersedes the
Phase 7A-only statement above that no live lock/PAM had run; the earlier validation
record remains unchanged.

Preflight: AC connected, battery charging at 44%; only eDP-1 active, physical
3840x2160@60, logical 1920x1080, scale 2, normal transform, position 0,0.
Hyprland initially unlocked; Hyprland/MAGI/Hypridle PIDs 1492/1543/1541 retained
original lifecycles; Hyprlock installed. Default and development CTest reruns both
passed 9/9 with inherited IPC available (sandbox-restricted runs could not execute
the IPC fixtures). Default development-unlock/failure-injection gates remained 0.

Development binary SHA256:
`fb4f970c9207b8bf0a725bcebd7518f5699caff2115faafffd83ddba6818b583`.
Exact single invocation:

```sh
/tmp/magi-lock-phase7-dev-build/magi-lock-proof \
  --acquire-session-lock --authenticate --sleep-integration \
  --unsafe-development-unlock-after=300
```

Timer decision: installed Qt 6.11.2 offscreen probe uses
QPAEventDispatcherGlib; Qt's Unix timer list uses steady_clock. Installed
libstdc++ steady_clock::now disassembly calls clock_gettime(CLOCK_MONOTONIC).
Linux excludes suspended time from this clock. Therefore the emergency interval
is 300 seconds of awake time after compositor confirmation, not wall time across
sleep. Timer recovery would not count as authenticated acceptance.
References: [Qt timer implementation](https://raw.githubusercontent.com/qt/qtbase/v6.11.2/src/corelib/kernel/qtimerinfo_unix.cpp),
[Linux clock semantics](https://man7.org/linux/man-pages/man2/clock_gettime.2.html).

Proof PID 581995 armed sleep integration, obtained eDP-1 registry 72/lifetime 1,
acknowledged configure serial 192530 at 1920x1080 and committed without fallback.
The compositor confirmed ext_session_lock_v1.locked; Hyprland reported locked,
generation 0 and no worker. Suspend remained behind an explicit operator visual
confirmation gate plus fresh software checks.

The operator reported accidentally pressing Enter before suspend. Diagnostics
recorded exactly one generation-1 worker (PID 582107), PAM Success, worker reap,
and exactly one `AUTHENTICATED UNLOCK: current PAM Success`. The timer was stopped
by the authenticated-unlock path. No input content or length was collected or
inferred. The proof exited 0 approximately 10.39 seconds after launch.

**No suspend command was issued. No resume or sleep credential-clear acceptance
was exercised. Test 1 is INCOMPLETE, not an observed suspend/resume failure.**
No retry or second lock was performed. A fresh individual approval/recovery
confirmation is required for another attempt. The pending stable-lock question
from this attempt must not authorize a later invocation.

Postflight: Hyprland unlocked; no worker; eDP-1 normal; original MAGI/Hypridle
lifecycles intact; Hyprlock installed; all 527 snapshot files matched before this
documentation update, including protected runtime files and PAM/live Hypridle
configuration. Evidence is local under `/tmp/magi-phase7b-test1/` and is not tracked.
No routing change, staging, commit or push. All actual suspend/resume gates remain
unproven; Test 2 and later work remain unauthorized.

## Phase 7B Live Test 1 — second attempt incomplete at visual gate

2026-10-18. A separately approved second invocation used the same reviewed binary
and command, following renewed recovery confirmation. AC connected, battery
charging at 57%; eDP-1 only. Proof PID 583217 acquired compositor-confirmed lock;
registry 72/lifetime 1, configure serial 192735 at 1920x1080 acknowledged and
presentation committed without fallback. Authentication generation remained 0;
no PAM worker launched.

The operator entered partial input without Enter and waited for sleep. The runner
was still waiting for a separate in-chat stable-lock/partial-input confirmation;
that confirmation never arrived during the run. This was a coordination problem:
the extra confirmation step was not made sufficiently clear before locking.
No suspend approval gate file was created and **no suspend command was issued**.
The operator reported MAGI remained visible throughout the 300-second interval.

Recovery was `UNSAFE DEVELOPMENT TIMER UNLOCK: authenticated acceptance FAILED`.
The native credential-clear event occurred during timer cleanup, not sleep
preparation. The proof exited 0 at approximately 300.23 seconds. No authenticated
unlock or resume occurred. **Suspend/resume Test 1 remains INCOMPLETE and cannot
be accepted; this run supplies no evidence of suspend/resume failure or success.**

Postflight: Hyprland unlocked, eDP-1 normal, no worker, original MAGI/Hypridle
lifecycles intact, Hyprlock installed. All 527 snapshot files matched before this
documentation addition. Evidence: `/tmp/magi-phase7b-test1-attempt2/` (untracked
outside repository). No production/configuration changes, staging, commit or push.
No third invocation is authorized. Before any separately approved retry, agree
on a usable means of supplying the required visual confirmation while locked;
do not silently substitute an elapsed-time delay for that gate.

## Phase 7B Live Test 1 — third, pre-armed attempt PASSED

2026-10-18, individually approved with fresh saved-work/authenticated-recovery
confirmation. The operator explicitly replaced the mid-lock chat confirmation
model with a fully pre-armed sequence. The two incomplete attempts above remain
part of the record; neither exercised suspend/resume.

Preflight: AC connected, battery charging at 94%; eDP-1 only, physical
3840x2160@60, logical 1920x1080, scale 2, normal transform at 0,0, active/DPMS on.
Hyprland unlocked; no proof or PAM worker. Original Hyprland/MAGI/Hypridle PIDs
1492/1543/1541 and start times intact; Hyprlock installed. Logind CanSuspend=yes.
Reviewed development/default/worker hashes and default security gates matched the
prior preflight. Accepted Rust worker and existing hyprlock PAM service selected;
no failure fixture. The exact command was unchanged from the first attempt.

Temporary runner `/tmp/magi-phase7b-test1-attempt3/run.py`, SHA256
`62c3c48b7dbf1e2e95ab1eea559c303cf28b4c739da4fb11bd55d0633d1e4c57`,
passed 14 offline decision checks. It permits one invocation and one suspend,
requires observed compositor lock, waits 15 seconds, then reads fresh lock/output,
worker and bounded journal evidence. Generation must remain 0, the output must
have an acknowledged secure commit, and any observed auth attempt or observation
failure vetoes suspend. No mid-lock chat/file approval is required. The 15 seconds
is the operator's partial-input interval, not a substitute for compositor readiness.
Failure withholds suspend and leaves the development recovery timer active.

Observed sequence (Europe/London, BST):

- **12:17:55**: proof PID **596876** armed sleep integration and acquired real
  ext-session-lock-v1. eDP-1 registry **72**, lifetime **1**, configure serial
  **193945**, logical **1920x1080**, acknowledged/committed with **no fallback**.
  Actual compositor `locked` received; Hyprland subsequently reported true.
- Operator entered harmless partial native input without Enter. No input contents
  or lengths were logged. Global auth generation remained **0**, with no worker.
- **12:18:11**: after **15.53 seconds from observed lock confirmation**, fresh
  automated checks passed. Runner issued exactly one `/usr/bin/systemctl suspend`,
  PID **597038**, later exit **0**. No additional tool/chat interaction gated it.
- PrepareForSleep(true) handling emitted `CREDENTIAL CLEARED`, `AUTH CANCELLED`,
  `SLEEP PREPARATION: input blocked, credential cleared, auth cancelled`, then
  `SECURE FOR SLEEP: compositor locked, auth reaped, delay released`. No worker
  existed to cancel; no Success or unlock occurred during sleep preparation.
- System journal confirms systemd-sleep performed **suspend** and returned from
  **suspend** at **12:18:32**; logind completed the operation at **12:18:33**.
  Observer boottime-minus-monotonic change was approximately **17.80 seconds**.
  This run genuinely slept, unlike the two earlier attempts.
- **12:18:33**: PrepareForSleep(false) handling emitted
  `RESUME: still locked; fresh keyboard state required`, followed by
  `Native keyboard keymap initialized`. eDP-1 retained registry/lifetime 72/1;
  no output removal/replacement, fallback or stale-lifetime effect was observed.
  Hyprland samples remained locked through resume until authenticated return.
  This single-output run does not prove topology-change-across-suspend acceptance.
- **12:18:38–39**, after resume settling and manual submission: exactly one
  generation-**1** Rust PAM worker, PID **597565**, launched; PAM succeeded and
  the worker was reaped. Exactly one
  `AUTHENTICATED UNLOCK: current PAM Success` occurred. The authenticated path
  stopped the emergency timer; no development timer unlock occurred.
- Proof exited **0** after approximately **26.56 awake seconds** (about 44.36 wall
  seconds). No automatic authentication or unlock occurred on resume.

The system sleep journal reports the existing
`SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=0` environment: user sessions remained unfrozen
on explicit platform configuration. No change to this setting was made. Acceptance
is for this installed machine/configuration; it does not establish behaviour under
a different user-session freeze policy.

Postflight: Hyprland unlocked, proof and worker exited, eDP-1 normal at original
mode/scale/topology, original MAGI/Hypridle lifecycles intact, Hyprlock installed.
All **527** pre-test snapshot files matched before this documentation update,
including protected runtime files, live Hypridle/Hyprlock configuration and PAM.
No observation errors in 25 bounded samples. Local evidence remains under
`/tmp/magi-phase7b-test1-attempt3/`; no artifacts are added to the repository.

**Operator accepted all seven visual checks:** full coverage before sleep; no
underlying desktop during resume; MAGI visible after wake; pre-suspend bullets
cleared; keyboard usable; no literal password characters; clean authenticated
return. Combined software and visual evidence accepts **Live Test 1 only**.

No production routing/Hypridle/PAM change, staging, commit or push. Stop here.
Initially-unlocked readiness ordering (Test 2), temporary Hypridle-equivalent
integration (Test 3), topology across suspend (Test 4), production migration and
all other deferred gates remain unproven and require separate authorization.

## Phase 7B Live Test 2 — FAILED: late inhibitor acquisition and premature cleanup

2026-10-18. One separately approved temporary runtime Hypridle handoff and one
suspend request from an initially unlocked desktop. **This is a failed security
acceptance test, not an incomplete coordination attempt. Test 1 remains accepted.**
No retry or Test 3 is authorized/performed.

### Preparation and actual temporary integration

Production Hypridle PID 1541 was audited as directly launched by Hyprland PID 1492
via `hl.exec_cmd("hypridle")`, not its disabled systemd user unit. Executable
`/usr/bin/hypridle`, argv `hypridle`, cwd `/home/jkebwdn`, original session environment
preserved privately under `/tmp`. Default config resolves to the protected file.
Installed v0.1.8-2 `--help` and
[v0.1.8 main.cpp](https://github.com/hyprwm/hypridle/blob/v0.1.8/src/main.cpp)
verify `--config <path>` (inspected 2026-10-18). An orphan Hyprlock PID 597052 from
Test 1 was separately authorized for SIGTERM cleanup before the fresh preflight;
it exited. This was not a PAM/configuration change.

Temporary config `/tmp/magi-phase7b-test2/hypridle.conf` copied the current live
file with exactly this diff:

```diff
-    lock_cmd = pidof hyprlock || hyprlock
+    lock_cmd = /tmp/magi-phase7b-test2/magi-lock-request
+    inhibit_sleep = 3
```

Before/after-sleep commands, idle timings and DPMS policy remained identical.
Request script was a byte-for-byte copy of the accepted no-argument launcher.
Accepted Type=notify service template was linked only under the user runtime
unit directory, with explicit graphical environment and this development command:

```sh
/tmp/magi-lock-phase7-dev-build/magi-lock-proof \
  --acquire-session-lock --authenticate --sleep-integration \
  --notify-ready --unsafe-development-unlock-after=300
```

No unit was permanently installed/enabled. Service starts coalesce; native flock
remains the independent guard. Three constant non-secret diagnostics were added to
`logind_sleep.cpp` for acquired inhibitor, pending-sleep startup and signal receipt;
no policy change. Rebuilt development SHA256
`6bc642a01e88272c1fb500050775eb447be75b46b5856ab3af3e83a737e36979`.
Both complete native suites passed **9/9** before this run. Synthetic passing does
not supersede the following real transport failure.

Preflight: AC, battery full, eDP-1 only at 3840x2160@60/scale 2/logical 1920x1080;
unlocked, no native locker/PAM worker/Hyprlock process; MAGI PID 1543 and Hyprland
1492 intact. Five-second effective logind limit verified. Normal delay holders:
NetworkManager, rtkit, UPower, fprintd, Hypridle. Saved-work/authenticated recovery
and runtime handoff received fresh final approval.

Execution command: `python /tmp/magi-phase7b-test2/run.py --run-once`.
It stopped production Hypridle, launched temporary PID **609004**, verified its
mode-3 inhibitor and unlocked state, then issued exactly one `systemctl suspend`
(PID **609019**). It did not manually start MAGI.

### Recorded failure ordering

Times below are BST, from bounded journal/source timestamps and runner records:

| Time | Evidence |
| --- | --- |
| 12:55:42.814187 | Temporary Hypridle logged acquired sleep inhibitor FD 10; pre-request listing confirmed holder |
| 12:55:43.067249 | Runner recorded Hyprland unlocked and native service inactive |
| 12:55:43.078838 | Runner recorded its one suspend invocation |
| 12:55:43.085476 | logind received suspend request from PID 609019 |
| 12:55:43.092807 | Hypridle journal receipt: PrepareForSleep(true), loginctl lock-session, Session.Lock and request script (batched messages; their individual micro-order is not inferred from identical timestamps) |
| 12:55:43.095818 | User manager started MAGI service |
| 12:55:43.123057 | Native PID **609031** logged startup |
| 12:55:43.125172 | `Cannot arm sleep integration; no readiness claimed` |
| 12:55:43.133386 | Native process exited **2**; service failed |
| About 12:55:43.409 | Runner began premature restoration and stopped temporary Hypridle |
| 12:55:43.411563 | systemd-suspend.service started |
| 12:55:43.485222 | systemd-sleep began actual suspend operation |
| 12:56:17.892025 | systemd-sleep returned from suspend |
| 12:56:18.031407 | logind completed suspend operation |

There was **no native inhibitor-acquired event, no Wayland lock request, no
compositor locked event, no secureLockReady, no native secure inhibitor release,
no PAM worker, and no authenticated unlock**. The initial banner “REAL SESSION
LOCK REQUESTED” is process intent, not a Wayland request or readiness. The timer
never armed because it starts only after compositor confirmation. There is no
successful acquisition time or margin to report against the five-second limit.
Actual sleep operation began roughly **392 ms** after the observed sleep signal,
without MAGI coverage; this was not observed five-second expiration.

### Architecture finding and runner error — separate causes

Native `SleepPolicy::arm()` tries to acquire its own inhibitor when the on-demand
locker starts. On failure it quiesces input and startup exits before Wayland.
The observed diagnostic path identifies failure to acquire that native inhibitor.
[systemd v262 method_inhibit](https://github.com/systemd/systemd/blob/v262/src/login/logind-dbus.c)
rejects an inhibitor matching an already-pending delayed action with
`OperationInProgress`. The restored Hypridle explicitly logged this same error
when started during the pending operation. Thus a pre-existing Hypridle inhibitor
does not permit a newly launched native locker to acquire another inhibitor after
sleep intent. The proposed Phase 7A handoff assumption is not valid on this system.
The native error name was not logged, so its diagnosis combines the observed
acquisition-failure path with authoritative source, rather than claiming a
captured native D-Bus error string.

**The test runner also had an independent safety defect:** it interpreted native
service exit as completion of the entire sleep transaction and immediately ran
restoration. Stopping temporary Hypridle then closed the still-needed original
delay FD before logind's maximum. The first production restart occurred while
sleep was pending and could not reacquire an inhibitor. Its verification hit a
JSON parse error; the runner incorrectly treated process/config restoration alone
as complete. This orchestration fault accelerated loss of the remaining delay
protection and must not be attributed solely to logind timeout or native code.

The first `postflight.json` was collected before actual sleep and is **not valid
post-resume acceptance evidence**. Both native pending-sleep acquisition and
transaction-aware cleanup require non-disruptive correction/review before any
separately approved retry. No bypass, architecture fix or live retry was introduced
in this test turn.

### Completed recovery/restoration

After the actual resume, PreparingForSleep=false was verified. The incomplete
replacement Hypridle PID 609122 was stopped as part of the authorized restoration.
Production was relaunched using its audited argv, executable, cwd and environment:
**PID 610203**, exactly one Hypridle, using the original config and **verified to
hold its normal sleep-delay inhibitor**. New PID/start time is expected after the
explicitly authorized runtime handoff; the original process lifecycle is not
claimed preserved. MAGI shell PID 1543 and Hyprland PID 1492 remain original.

Final software state: unlocked, eDP-1 normal, no native locker/PAM worker,
Hyprlock installed, runtime MAGI unit link absent and LoadState=not-found. All
**527** protected snapshot entries matched before this documentation update.
Live hypridle.conf SHA256 remains
`eb6fa3c034957abaf48de818e690429c4a1c8b4815e72ead5e19d90a30cc17fb`.
PAM/Hyprlock/Hyprland configuration unchanged. Temporary evidence/configs retained
only under `/tmp/magi-phase7b-test2/`, not active. Final restoration evidence is
`restored-after-resume.json`, superseding the premature first restoration report.

Operator visual account remains pending; no visual pass is claimed. Software
already establishes Test 2 failure. No Test 3, permanent migration, staging,
commit or push. Stop for review.

## Non-disruptive correction after failed Test 2 — dual ownership

2026-10-18. The operator accepted the failed run's evidence, including suspend
without MAGI coverage and unlocked resume. The record above is preserved. This
correction supersedes the initial Phase 7A integration proposal; it does not
reclassify the failure as a PAM, credential-boundary or multi-output regression.
**No live retry is authorized or performed by this correction.**

### Reverified source and ownership

Re-read Hypridle **v0.1.8** `run`, `handleDbusSleep`, `handleDbusLogin`,
`onLocked`, `inhibitSleep/uninhibitSleep` in
[Hypridle.cpp](https://github.com/hyprwm/hypridle/blob/v0.1.8/src/core/Hypridle.cpp),
and systemd **v262** `method_inhibit` in
[logind-dbus.c](https://github.com/systemd/systemd/blob/v262/src/login/logind-dbus.c).
Inspected 2026-10-18; versions match the audited installed packages.

Hypridle mode 3 holds a delay before sleep intent. PrepareForSleep(true) launches
before_sleep_cmd; loginctl emits Session.Lock; lock_cmd starts the locker.
Command exit is not its sleep gate. Compositor lock notification releases the
Hypridle-owned FD. Native READY=1 is not consumed by Hypridle. systemd rejects new
matching inhibitor acquisition once the operation is pending. The five-second
ceiling still applies to the original holder. These semantics explain both the
late-acquisition failure and why removing that holder prematurely was unsafe.

### Explicit native modes

`--sleep-integration --sleep-coordinator=native` is the normal/manual mode and the
backward-compatible default for `--sleep-integration`. It acquires native delay
before lock acquisition, retains it while awake, and on sleep blocks input,
clears credentials, cancels/reaps any worker, then releases only when compositor
Locked AND auth quiescent. Errors never switch implicitly to delegation. This
preserves Live Test 1's architecture.

`--sleep-integration --sleep-coordinator=hypridle` explicitly selects a trusted
Hypridle-coordinated startup. During already-pending sleep:

1. Subscribe to sleep/resume signals and reconcile PreparingForSleep.
2. Arm policy without calling native Inhibit. This is explicit ownership selection,
   not an inference from a failed Inhibit call.
3. Quiesce input/auth before requesting the Wayland session lock. A fresh process
   has no prior credential or worker; native input remains blocked through sleep.
4. Only actual ext_session_lock_v1.locked establishes secureLockReady. Surface
   creation, configure, rendering and process startup are insufficient.
5. Hypridle releases its own pre-existing FD on the compositor notifier. Native
   `HYPRIDLE COORDINATED` diagnostics report local Locked+quiescent state and do
   not close or manufacture an external inhibitor.
6. On PrepareForSleep(false), acquire native protection before rebuilding/enabling
   input, then change policy ownership to Native. Subsequent sleep while the same
   owner is still locked therefore retains credential/worker cleanup protection.

If the explicit Hypridle request arrives while sleep is already over, startup
observes false and changes to native protection before editing/lock acquisition.
The same behaviour supports ordinary idle/manual requests delivered by Hypridle's
single lock_cmd. Acquisition failure in that awake transition remains an error;
it never falls back to unprotected editing. This transition is necessary because
Hypridle releases its own FD on lock even outside a sleep operation.

The coordinated flag assumes a trusted mode-3 Hypridle integration. It does not
prove some arbitrary caller has an external inhibitor. Same-UID malicious caller
behaviour is outside the accepted trust model. No new unlock endpoint, fake
readiness, PAM bypass, raw-QML credential path or per-output auth domain exists.
Five-second expiration, failed/crashed Hypridle, failed lock acquisition and
concurrent external sleep triggers remain finite-delay limits, not an indefinite
veto. Subscription/property reconciliation is not a new atomic transaction with
future sleep intent; late native acquisition still fails honestly in a race.

### Request/service selection and readiness

The single implementation is now the **uninstalled** template
`integration/magi-lock@.service`, replacing the earlier uninstalled non-template
file. It retains Type=notify, NotifyAccess=main, Restart=no, RefuseManualStop=yes,
core limits and the startup timeout; `%i` selects only the validated native or
hypridle coordinator argument. Unknown coordinator values are rejected by native
CLI parsing before any lock/bus action. No Conflicts relationship or automatic
restart may stop another lock owner.

| Request | Cold-start unit | Use |
| --- | --- | --- |
| `magi-lock-request` or `magi-lock-request lock` | `magi-lock@native.service` | Normal/manual lock |
| `magi-lock-request sleep-coordinated` | `magi-lock@hypridle.service` | Trusted Hypridle lock_cmd, including pending sleep |

The request script reuses either existing active/activating instance and waits on
its start job. Same-instance simultaneous starts coalesce in systemd. A cold
cross-mode race may launch two processes, but the per-display native flock admits
only one owner; the loser exits without claiming readiness or stopping the winner.
That is safe rejection, not a guarantee every racing caller succeeds. A native
mode request raced against pending sleep may still fail acquisition; no automatic
fallback to the other mode is added.

READY=1 remains solely a projection of the same native compositor-locked callback,
useful to callers/tests. It is not a second readiness authority or Hypridle's gate.
The compositor delivers events to two processes: native callback receipt and
Hypridle notifier receipt may be scheduled in either order. Future evidence must
separate server event causality from cross-process log receipt timestamps; do not
invent micro-order from batched journal messages. Hypridle must log its compositor
notification before its own FD release, with actual sleep service following.

Proposed future paths remain `/usr/bin/magi-lock-request`, sibling binaries
`/usr/lib/magi/{magi-lock,magi-lock-auth}`, and now
`/usr/lib/systemd/user/magi-lock@.service`. None is installed/enabled here.

Refined proposed live config diff — **NOT APPLIED**:

```diff
 general {
-    lock_cmd = pidof hyprlock || hyprlock
+    lock_cmd = /usr/bin/magi-lock-request sleep-coordinated
+    inhibit_sleep = 3
     before_sleep_cmd = loginctl lock-session
     after_sleep_cmd = hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'
 }
```

All idle listeners and DPMS policy remain unchanged. `handoff_config.py` renders
only these two settings into a caller-provided temporary config; it cannot write
or activate the live file.

### Corrected temporary restoration lifecycle

`integration/handoff_policy.py` is a pure, tested harness policy, not a production
sleep daemon. Normal phases are:

`ProductionActive → ProductionStopped → TemporaryStarting → TemporaryActive →
SleepRequested → SleepPending → Sleeping → Resumed → TemporaryStopping →
ProductionRestoring → ProductionVerified`.

LockFailed, TemporaryFailed, ObservationFailed and Deadline are recorded alongside
the phase; they do not jump to teardown. SleepFailed can permit restoration only
with a definitive rejected request and independently verified non-pending state.
Generic command nonzero, transport error or timeout is not a definitive rejection.

For an issued sleep request, normal restoration requires **all** of:

- observed PrepareForSleep true then false for this transaction;
- fresh PreparingForSleep=false;
- systemd-suspend.service terminal (inactive/failed);
- native locker exited, so normal restoration follows authenticated/timer return.

The gate is rechecked inside restoration, including the independent watchdog.
`systemctl suspend` returning 0 is only request acceptance. Native service failure
is only lock failure. Neither closes temporary Hypridle's FD. Unknown bus/journal
state, pending sleep, or a bounded observation deadline leaves temporary Hypridle
alive and emits an operator-recovery requirement. It never guesses completion or
claims production restored. Setup failure before any request can restore after
fresh non-pending/service/locker checks, including interruption before a phase
write. No temporary/production overlap is allowed during normal restoration.

After the gate: stop only the identified temporary Hypridle, verify it is gone,
remove the runtime unit link, restore audited production argv/cwd/environment,
and require one process **plus its delay inhibitor**, matching config hash and
absent runtime unit before ProductionVerified. JSON/observation errors are not
success. The revised runner does not generically treat systemctl errors as
cancellation; ambiguous failures remain blocked for explicit recovery.

### Synthetic validation and revised Test 2 preparation

Default and development native builds pass. Complete CTest **11/11 each** includes:

- **39** sleep/readiness/inhibitor/input/instance scenarios (the accepted 25 plus
  explicit coordinated path, no native acquisition while pending, real Controller
  readiness gate, failed lock, duplicate events, native ownership after resume,
  second sleep, awake-transition failure, blocked pre-resume submission and CLI
  validation). The fake external notifier responds only to the simulated
  compositor event, never process/render readiness.
- **19** temporary-handoff state tests, including failed service during pending
  sleep, early systemctl success, false-before-true, stale false vs fresh true,
  unknown property, timeout, safe failure completion, failed restoration verification
  and prevention of overlapping Hypridle instances.
- **8** request/config tests execute the actual script with only systemctl replaced
  by an offline fake: native/coordinated selection, reuse, invalid/unlock rejection,
  exact before_sleep/lock_cmd/mode-3 config chain, and one service implementation.
- **41** accepted multi-output scenarios plus all existing Phase 5 auth/failure,
  stale-result, presentation-boundary/leakage and binary-gate regressions.
- Rust **18/18**, locked/offline; Clippy all-targets `-D warnings` and fmt pass.
  Rust source unchanged. Sandbox IPC restrictions prevented the initial Rust fake
  socket run; rerunning with inherited IPC permitted passed. No real PAM ran.
- Default build: development-unlock=0, failure-injection=0. No public unlock added.
  Shell syntax, temporary unit structural verification and git diff whitespace pass.

Prepared, **not executed**: `/tmp/magi-phase7b-test2-revised/` contains the revised
runner, copied request script, mode-3 temporary config and development template.
The runner imports the tested repository handoff policy and gates both normal and
watchdog restoration through it. Files remain outside Git. Temporary unit syntax
was checked without activation; no user-manager units were linked/reloaded.

Revised live sequence, requiring separate approval:

1. Audit current production Hypridle PID/environment/config and current outputs;
   reject active lockers/workers, verify unlocked, power, current five-second limit,
   builds, notifier availability, protected hashes and no temporary units. Refresh
   the preflight snapshot and audited restoration environment; do not reuse stale
   process identities. Obtain one final saved-work/authenticated-recovery approval.
2. Pre-arm bounded observation and guarded watchdog. Link only the temporary unit
   template; hand off Hypridle using the reviewed two-setting config diff. Verify
   exactly one temporary instance with its pre-existing inhibitor; remain unlocked.
3. Issue exactly one `systemctl suspend`; do not start MAGI first. Session.Lock
   invokes `magi-lock-request sleep-coordinated`, selecting the explicit coordinator.
   Expect no native inhibitor request before first resume. Observe real compositor
   lock/notifier → Hypridle release → sleep service; measure elapsed time and the
   remaining five-second margin. No arbitrary timing delay supplies readiness.
4. On resume, observe false, native inhibitor acquisition, keyboard rebuild, still
   Locked, empty credential and no automatic PAM. Operator waits about five seconds
   then submits once. Exactly one PAM Success/global authenticated unlock required;
   the 300-awake-second recovery timer must be cancelled. No mid-test chat gate.
5. Only after transaction completion and locker exit, restore production and verify
   its actual inhibitor. A service failure during pending sleep retains temporary
   Hypridle through the operation and records failure; delay expiry is an external
   platform limit. If completion cannot be established, retain temporary protection
   and request operator recovery rather than run unsafe cleanup.
6. Collect postflight/visual evidence and stop. No Test 3 or additional suspend.

No live lock, real PAM, suspend, Hypridle handoff, production config change,
staging, commit or push occurred during this correction. Protected-state comparison
and exact correction path list follow below. **Live Test 2 remains failed until a
separately approved corrected run passes; synthetic validation is not live acceptance.**

### Correction path audit and protected state

Compared with the pre-correction snapshot: **514/527 existing files unchanged**;
all 13 changed/removed existing paths are in the authorized scope, with five new
paths. The 18 path entries below count the old service removal and new template
separately. All protected operator/live/PAM files match; no generated artifacts
are present under the native tree, and the index is empty.

```text
linux/magi/docs/design/lock-screen-phase7-suspend-resume.md
linux/magi/native/lock/CMakeLists.txt
linux/magi/native/lock/README.md
linux/magi/native/lock/integration/handoff_config.py
linux/magi/native/lock/integration/handoff_policy.py
linux/magi/native/lock/integration/magi-lock-request
linux/magi/native/lock/integration/magi-lock.service (removed; replaced by template)
linux/magi/native/lock/integration/magi-lock@.service
linux/magi/native/lock/src/logind_sleep.cpp
linux/magi/native/lock/src/logind_sleep.hpp
linux/magi/native/lock/src/main.cpp
linux/magi/native/lock/src/options.cpp
linux/magi/native/lock/src/options.hpp
linux/magi/native/lock/src/sleep_policy.cpp
linux/magi/native/lock/src/sleep_policy.hpp
linux/magi/native/lock/tests/handoff_test.py
linux/magi/native/lock/tests/request_test.py
linux/magi/native/lock/tests/sleep_test.cpp
```


## Revised Phase 7B Live Test 2 — accepted, 2026-10-18

One separately approved retry used the corrected dual-coordinator architecture.
The operator subsequently confirmed **all nine visual checks passed**. This is a
new successful run; the earlier failed Test 2 and root-cause record are preserved.
No Test 3 or further suspend was performed.

### Preflight and temporary integration

The session began unlocked with no MAGI locker, PAM worker or active Hyprlock.
MAGI PID 1543 and Hyprland PID 1492 remained running. Production Hypridle PID
610203 held its normal sleep delay inhibitor. Battery was 84%, discharging;
CanSuspend was yes. Only eDP-1 was active: 3840×2160 at 60 Hz, scale 2, logical
1920×1080, normal transform, position 0,0. No headless output was present.

The runner under `/tmp/magi-phase7b-test2-revised/` was re-inspected. Before live
execution, an erroneous runtime-link argument list was corrected to link only
the unit template, excluding three non-unit evidence/policy files. The 19 handoff
and 8 request tests passed again. Fresh production argv, cwd and full environment
were captured privately, protected state was snapshotted, and fresh saved-work /
authenticated-recovery approval was obtained before the handoff.

Only the temporary config changed:

```diff
-    lock_cmd = pidof hyprlock || hyprlock
+    lock_cmd = /tmp/magi-phase7b-test2-revised/magi-lock-request sleep-coordinated
+    inhibit_sleep = 3
```

`before_sleep_cmd = loginctl lock-session`, after-sleep DPMS enable, idle timings
and all listeners remained unchanged. The live file was not edited. The runtime
unit selected the reviewed development command:

```sh
/tmp/magi-lock-phase7-dev-build/magi-lock-proof \
  --acquire-session-lock --authenticate --sleep-integration \
  --sleep-coordinator=hypridle --notify-ready \
  --unsafe-development-unlock-after=300
```

Development binary SHA-256:
`58cd5c8f38ffce3295a781b9437adaf5aad480766c85b18deb2bd37556ee28cf`.
The 300-second awake-time timer remained emergency recovery only. The runner
issued exactly one `systemctl suspend` from unlocked, without manually launching
MAGI first and without any mid-lock chat confirmation.

### Recorded ordering and timing

Evidence is retained under `/tmp/magi-phase7b-test2-revised/`: preflight,
before-suspend, journal, samples, handoff, restored and verified-postflight JSON.
Times below are UTC on 2026-10-18; journal times are receipt timestamps.

| Event | Time |
| --- | --- |
| Temporary Hypridle PID 620125 holds inhibitor FD 10 | 12:27:00.137327 |
| Runner records suspend request | 12:27:00.229158 |
| Hypridle PrepareForSleep(true), Session.Lock / sleep-coordinated request | 12:27:00.242895 |
| MAGI PID 620153 requests ext-session-lock | 12:27:00.298398 |
| eDP-1 configure, 1920×1080 | 12:27:00.298479 |
| Configure acknowledged and presentation committed, no fallback | 12:27:00.323252 |
| Hypridle receives compositor locked notification | 12:27:00.349852 |
| Hypridle logs release of its inhibitor | 12:27:00.349928 |
| MAGI logs ext_session_lock_v1.locked; native readiness callback | 12:27:00.349957 |
| Native coordinated Locked + auth-quiescent diagnostic | 12:27:00.357458 |
| systemd-sleep begins suspend operation | 12:27:00.580423 |
| systemd-sleep returns from suspend | 12:27:35.922625 |
| Hypridle receives PrepareForSleep(false) | 12:27:36.055109 |
| MAGI receives PrepareForSleep(false) | 12:27:36.061069 |
| MAGI acquires native inhibitor | 12:27:36.064428 |
| MAGI resumes still locked, reconstructing input | 12:27:36.071296 |
| Native keyboard keymap initialized | 12:27:36.074654 |
| Single PAM worker PID 620995 spawned | 12:27:46.319531 |
| Authentication attempt generation 1 | 12:27:46.319733 |
| Worker reaped, authentication succeeded | 12:27:46.365023 |
| AUTHENTICATED UNLOCK: current PAM Success | 12:27:46.365209 |
| Compositor processed unlock; locker exits | 12:27:46.367658 |
| Production Hypridle restoration verified | 12:27:46.997316 |

PrepareForSleep/Hypridle request to native compositor confirmation was
**107.062 ms**, leaving **4892.938 ms** against the effective 5000 ms limit.
Hypridle release to systemd-sleep operation start was **230.495 ms**.

The two compositor clients' log receipt order must not be conflated with server
causality: MAGI's callback log appears 29 microseconds after Hypridle's release
log. This does not demonstrate native secureLockReady executing before the other
process releases its FD. It demonstrates the accepted mode-3 gate: Hypridle's
actual compositor lock notification precedes its release, and both clients'
confirmation precedes suspend. Native readiness still derives exclusively from
ext_session_lock_v1.locked. No process-start shortcut or fabricated readiness was
used. The early logind message “The system will suspend now!” is intent, not the
actual systemd-sleep entry recorded above. Finite-delay limitations remain.

### Resume, authentication and restoration

There was no native inhibitor acquisition before suspend. Coordinated startup
observed already-pending sleep, blocked input and cleared credential state before
lock acquisition. Auth generation stayed 0 and no worker existed before manual
submission. eDP-1 retained registry 72 / lifetime 1 with no fallback; resume used
the accepted output machinery and committed the still-Locked state. Thirty-two
post-resume, pre-unlock samples reported locked. Native inhibitor acquisition
preceded input reconstruction; no credential or Success was restored by resume.

Exactly one generation-1 PAM attempt succeeded, its worker was reaped, and exactly
one global **AUTHENTICATED UNLOCK** occurred. No emergency timer unlock occurred.
The service ended inactive/dead with Result=success and ExecMainStatus=0.

Restoration followed observed true→false sleep completion, fresh non-pending
logind state, terminal suspend-service state and locker exit. The handoff reached
ProductionVerified with no recorded failures. Temporary Hypridle was removed;
production PID **621026** runs `/usr/bin/hypridle` with argv `hypridle`, cwd
`/home/jkebwdn`, and the exact audited environment. Its normal delay inhibitor was
verified both by the runner and independent read-only postflight. Runtime unit,
runner/watchdog, MAGI locker and PAM worker were absent afterward.

All **531 snapshotted files** matched before documentation was updated, including
protected operator state and PAM configuration. Protected live Hypridle SHA-256:
`eb6fa3c034957abaf48de818e690429c4a1c8b4815e72ead5e19d90a30cc17fb`.
MAGI PID 1543 remained running, Hyprlock remained installed, and eDP-1 was active
and normal with the same topology. No permanent unit installation, production
routing change, live config change, staging, commit or push occurred.

### Operator visual acceptance and remaining gates

The operator confirmed: initial desktop unlocked; visible transition to MAGI lock
before sleep; no unlocked desktop between lock transition and suspend; genuine
suspend; MAGI visible after wake; no desktop leakage during wake; usable keyboard;
no literal password characters; and clean authenticated desktop return.

**Revised Live Test 2 is accepted.** Live Test 1 remains accepted. Tests 3–4,
production integration/migration and the other previously documented future gates
remain outstanding and require separate authorization. No additional live test
is authorized by this acceptance record.

## Final live gate selection — 2026-10-18

By explicit operator direction, Test 3 is **SUBSUMED BY REVISED LIVE TEST 2 —
no separate execution required.** The successful revised Test 2 exercised the
real temporary Hypridle → lock request → compositor notifier → suspend-readiness
chain that Test 3 originally intended to prove. Historical plans above are
preserved; their references to outstanding Test 3 are superseded here.

The remaining final Phase 7 live acceptance gate is one dual-output suspend/resume
cycle with eDP-1 and HDMI-A-1 already active, no physical hotplug, and the corrected
temporary Hypridle coordination and guarded restoration. This gate is not yet
executed or accepted. Display verification and a fresh saved-work / authenticated
recovery confirmation must precede the runtime handoff. Production migration,
Hyprlock retirement, staging, commit and push remain outside authorization.


## Final dual-output suspend/resume — accepted, 2026-10-18

The operator approved one cycle, freshly confirmed saved-work/authenticated
recovery readiness, and subsequently confirmed **all ten visual checks passed**.
This completes the selected Phase 7 live acceptance gates. Test 3 remains
**SUBSUMED BY REVISED LIVE TEST 2 — no separate execution required.** Earlier
failed and incomplete runs remain preserved; the preceding gate-selection entry
records the plan before this execution.

### Starting state and execution

Hyprland was unlocked. MAGI PID 1543, Hyprland PID 1492 and production Hypridle
PID 621026 were present; Hypridle held its normal delay inhibitor. No MAGI locker,
PAM worker, active Hyprlock or temporary MAGI unit existed. Battery was 63%,
discharging; suspend was supported. Both physical outputs were enabled with DPMS
on, normal transform, and extended rather than mirrored layout:

| Output | Physical mode | Logical dimensions | Scale | Position |
| --- | --- | --- | --- | --- |
| eDP-1 | 3840×2160 @ 60 Hz | 1920×1080 | 2 | 0,0 |
| HDMI-A-1 | 3840×2160 @ 239.995 Hz | 2560×1440 | 1.5 | 1920,32 |

No scale/layout normalization or physical hotplug was performed. The fresh
one-shot runner and evidence reside under `/tmp/magi-phase7b-dual-output/`.
It reused the successful revised Test 2 runner, adding exact two-output checks
at preflight and immediately before suspend, a separate evidence directory and
journal identifier, and the freshly captured production environment for all
read-only observations. Handoff/request regressions passed 19/19 and 8/8.
Binaries matched the accepted revised Test 2 hashes.

Temporary Hypridle PID 629129 used only these config changes:

```diff
-    lock_cmd = pidof hyprlock || hyprlock
+    lock_cmd = /tmp/magi-phase7b-dual-output/magi-lock-request sleep-coordinated
+    inhibit_sleep = 3
```

Before/after-sleep commands, idle listeners and DPMS policy were unchanged. The
runtime-only service used the same development command as revised Test 2:
`--acquire-session-lock --authenticate --sleep-integration
--sleep-coordinator=hypridle --notify-ready --unsafe-development-unlock-after=300`.
No failure fixture was selected. One `systemctl suspend` was issued from unlocked;
MAGI was launched by Hypridle, not manually. No mid-lock chat response was needed.

### Lock-before-suspend evidence

Times are UTC on 2026-10-18, from the bounded journal/runner evidence:

| Event | Time |
| --- | --- |
| Temporary Hypridle holds sleep inhibitor FD 10 | 12:55:14.393346 |
| Runner records suspend request | 12:55:14.547614 |
| PrepareForSleep(true) | 12:55:14.558023 |
| Hypridle invokes sleep-coordinated request | 12:55:14.561067 |
| MAGI PID 629157 requests session lock | 12:55:14.619259 |
| eDP-1 commit, configure acknowledged, no fallback | 12:55:14.644908 |
| HDMI-A-1 commit, configure acknowledged, no fallback | 12:55:14.655148 |
| Native ext_session_lock_v1.locked / secureLockReady callback | 12:55:14.686804 |
| Hypridle compositor lock notification, then inhibitor release | 12:55:14.687039 |
| Native coordinated Locked/auth-quiescent diagnostic | 12:55:14.704624 |
| systemd-sleep starts suspend operation | 12:55:14.889144 |
| systemd-sleep returns from suspend | 12:55:33.290338 |
| MAGI receives PrepareForSleep(false) | 12:55:33.428326 |
| MAGI acquires native inhibitor | 12:55:33.431787 |
| MAGI resumes still locked; input reconstruction | 12:55:33.444932 |
| Keyboard keymap initialized | 12:55:33.620457 |
| Single worker PID 630159 spawned | 12:55:45.250047 |
| Generation-1 attempt started | 12:55:45.250534 |
| Worker reaped; authentication succeeded | 12:55:45.314649 |
| AUTHENTICATED UNLOCK: current PAM Success | 12:55:45.314934 |
| Compositor processes unlock; locker exits | 12:55:45.320703 |
| Production Hypridle restoration verified | 12:55:45.738995 |

Both outputs had acknowledged/committed surfaces before compositor confirmation
and sleep. PrepareForSleep to confirmation was **128.781 ms**; Hypridle request
to confirmation was **125.737 ms**. Remaining margin against the effective
5000 ms delay was **4871.219 ms**. Release preceded sleep by **202.105 ms**.
Hypridle notification and release share a journal timestamp; their source/event
order is notification then release, not a separately measurable microsecond gap.
Native compositor confirmation also precedes both in this run. No native inhibitor
acquisition occurred during pending pre-suspend coordination. Finite logind delay
limits remain unchanged; this acceptance does not establish an indefinite veto.

### Real resume output-lifetime transition

Before suspend:

- eDP-1: registry **72**, lifetime **1**, configure serial 196524, 1920×1080.
- HDMI-A-1: registry **79**, lifetime **2**, configure serial 196525, 2560×1440.

Both initially recommitted after resume with global state Locked and auth
generation 0. The external display then naturally re-enumerated without operator
hotplug:

| HDMI lifecycle event | UTC time |
| --- | --- |
| Old registry 79 / lifetime 2 resources removed, still Locked, generation 0 | 12:55:34.326499 |
| Old registry removal observed | 12:55:34.326732 |
| New registry 80 discovered | 12:55:36.822155 |
| Fresh lock surface, lifetime 3, generation 0 | 12:55:36.822649 |
| Fresh configure serial 196539, 2560×1440 | 12:55:37.050064 |
| Configure acknowledged; secure commit, no fallback, still Locked | 12:55:37.065388 |

Final output identities were eDP-1 **72 / 1** and HDMI-A-1 **80 / 3**. The internal
lifetime remained valid. No stale-callback diagnostic or cross-output effect was
observed; forced stale-callback rejection remains covered by synthetic tests.
This run directly exercised the accepted Phase 6 replacement-output machinery
across resume, rather than assuming retained identities.

### Authentication, restoration and visual acceptance

Thirty-six post-resume, pre-unlock samples reported Locked. Native inhibitor
protection preceded input reconstruction. Auth generation remained 0 through the
output transition; no automatic worker launched. Exactly one manually initiated
generation-1 PAM attempt succeeded, its worker was reaped, and exactly one global
**AUTHENTICATED UNLOCK** occurred. The emergency timer did not unlock the session.

The guarded restoration policy observed sleep completion and locker exit before
restoring production. It reached ProductionVerified with no failures. Production
Hypridle PID **630192** was independently verified with original argv `hypridle`,
executable `/usr/bin/hypridle`, cwd `/home/jkebwdn`, exact audited environment and
its normal delay inhibitor. Temporary Hypridle, runtime unit, runner/watchdog,
locker and PAM worker were absent. Hyprland was unlocked; MAGI PID 1543 remained
running; Hyprlock remained installed. Both outputs returned to the original
mode/scale/layout with DPMS enabled.

All **531 snapshotted files** matched before this documentation update, including
protected operator state, live configuration and PAM files. Live Hypridle SHA-256
remained `eb6fa3c034957abaf48de818e690429c4a1c8b4815e72ead5e19d90a30cc17fb`.

The operator confirmed all ten visual requirements: both displays initially
unlocked; both showed MAGI before sleep; no unlocked content between lock and
suspend; genuine suspend; secure MAGI coverage on both after resume; no desktop
leakage during wake/reconfiguration; working keyboard; no literal password;
both displays unlocked together; and clean final return on both.

**Final dual-output live gate accepted; Phase 7 live acceptance complete.**
Production integration/migration, Hyprlock retirement, compositor restart/failure
recovery, broader layouts/authentication methods, packaging/PAM policy and final
visual design remain separate future work. No additional test, production change,
staging, commit or push was performed or authorized by this acceptance.


## Phase 7 finalization audit — 2026-10-18

The operator accepted the implementation and authorized a Phase 7-only commit
and push. No additional live lock, PAM authentication, suspend, hotplug or Hypridle
handoff was performed during finalization. Production migration is not included.

Final default/development builds pass; complete CTest is **11/11 in each**
(31.16 s / 30.95 s), including 39 sleep scenarios, 41 output scenarios, 19 handoff
and 8 request/configuration tests, plus the Phase 5 authentication/failure,
presentation-boundary and binary security gates. Rust is **18/18**; locked/offline
Clippy all-targets with warnings denied and cargo fmt check pass. The initial
sandbox runs could not exercise synthetic inherited-socket IPC; complete suites
passed after permitting that IPC. No real PAM transaction was invoked.

Default build reports development-unlock=0 and failure-injection=0. Reviewed
development options remain explicitly enabled only in the development build.
Rust source is unchanged. All build outputs remain under /tmp.

Read-only final runtime verification found production Hypridle PID 630192 with
its normal delay inhibitor and original argv/cwd/environment. Hyprlock remains
installed. Live Hypridle and protected/PAM hashes match the fresh finalization
snapshot; live Hypridle also matches the accepted test hash. Operator-local dirty
paths are excluded from staging. README acceptance status is now current.

The exact final Phase 7 allowlist is **26 files: 14 additions, 12 modifications,
zero deletions**. The original non-template magi-lock.service existed only in the
uncommitted Phase 7 work; therefore Git records the accepted template as an
addition, with no tracked old-service deletion. No /tmp runner, binary, build
artifact or protected production configuration is included.

```text
linux/magi/docs/design/lock-screen-phase7-suspend-resume.md
linux/magi/native/lock/CMakeLists.txt
linux/magi/native/lock/README.md
linux/magi/native/lock/integration/handoff_config.py
linux/magi/native/lock/integration/handoff_policy.py
linux/magi/native/lock/integration/magi-lock-request
linux/magi/native/lock/integration/magi-lock@.service
linux/magi/native/lock/src/auth_controller.hpp
linux/magi/native/lock/src/controller.cpp
linux/magi/native/lock/src/controller.hpp
linux/magi/native/lock/src/instance_guard.cpp
linux/magi/native/lock/src/instance_guard.hpp
linux/magi/native/lock/src/logind_sleep.cpp
linux/magi/native/lock/src/logind_sleep.hpp
linux/magi/native/lock/src/main.cpp
linux/magi/native/lock/src/native_input.cpp
linux/magi/native/lock/src/native_input.hpp
linux/magi/native/lock/src/options.cpp
linux/magi/native/lock/src/options.hpp
linux/magi/native/lock/src/sleep_policy.cpp
linux/magi/native/lock/src/sleep_policy.hpp
linux/magi/native/lock/src/wayland_owner.cpp
linux/magi/native/lock/src/wayland_owner.hpp
linux/magi/native/lock/tests/handoff_test.py
linux/magi/native/lock/tests/request_test.py
linux/magi/native/lock/tests/sleep_test.cpp
```

The finite five-second delay ceiling, explicit coordinator selection, real
compositor readiness, global auth/single-instance invariants and guarded runtime
restoration remain unchanged. Hypridle stays in the intended future design; its
proposed lock_cmd/inhibit_sleep migration is not applied. Packaging/install paths,
production PAM/routing decisions, Hyprlock retirement, compositor restart/failure
recovery, broader keyboard layouts and MFA/fingerprint flows, hibernation and
final visual design remain separate gates.
