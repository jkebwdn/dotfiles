# Phase 9B resume-input investigation — 2026-10-18

Rollout is paused. Installed `magi-lock 0.1.0-2` is unchanged. HEAD remains
`c7c942656536028b5d775900be69b05ceee00eab`. No lock, suspend, installation,
routing change, staging, commit or push was performed in this investigation.
Accepted Phase 9 visuals remain intact.

## Conclusion and limits

**D: insufficient event evidence; diagnostic instrumentation required.** A specific
focus/modifier-readiness failure is plausible and reproducible synthetically, but
is not established as the cause of this production failure. No input-acceptance
fix was made. Hardware input failure remains possible. A successful keymap only
proves delivery/configuration of keyboard mapping, not focus or physical input.

The USB error precedes completion of resume, not the later troubleshooting HDMI
unplug. It also occurs in successful runs. It cannot alone explain this failure.
The operator's chronology (input already broken, then unplug HDMI) is retained.

Evidence: `/tmp/magi-resume-input-investigation-mi8fhp4p/` contains original journal
JSON, successful-run extracts, build/test logs and baseline/comparison records.
Earlier recovery evidence remains at `/tmp/magi-phase9b-resume-audit-zj5vdlv8/`.
Earlier rollout build directories did not survive the reboot; none was cleaned here.
Failed boot: `9fe190683c8e4ab5a7f9e824a374bd2b`; locker PID 730132.

## Failed-run timeline

Times are 2026-10-18 BST. Monotonic values are journal receipt microseconds from
`__MONOTONIC_TIMESTAMP`, not elapsed wall time across sleep. Kernel messages can
be buffered: receipt timestamps do not measure exact hardware execution time.

| Wall time | Monotonic µs | Evidence |
|---|---:|---|
| 18:27:07.011426 | 110996921300 | logind suspend request, systemctl PID 730118 |
| 18:27:07.066810 | 110996976684 | MAGI starts |
| 18:27:07.069566 | 110996979440 | PreparingForSleep already true at startup |
| 18:27:07.069605 | 110996979479 | Input blocked, credential cleared, authentication cancelled |
| 18:27:07.069942 | 110996979816 | Output 72 surface lifetime 1 (eDP) |
| 18:27:07.070009 | 110996979883 | Output 88 surface lifetime 2 (HDMI) |
| 18:27:07.070153 | 110996980027 | eDP configure, 1920×1080 logical |
| 18:27:07.212389 | 110997122262 | eDP commit, native fallback false |
| 18:27:07.212433 | 110997122307 | HDMI configure, 2560×1440 logical |
| 18:27:07.230949 | 110997140823 | HDMI commit, native fallback false |
| 18:27:07.242468 | 110997152343 | Initial keymap initialized |
| 18:27:07.246797 | 110997156671 | Compositor Locked |
| 18:27:07.264773 | 110997174646 | systemd starts suspend |
| 18:27:07.286281 | 110997196155 | Hypridle coordination: secure/auth quiescent |
| 18:27:07.340185 | 110997250059 | systemd Performing suspend |
| 18:27:07.341157 | 110997251031 | Kernel deep-suspend entry |
| 18:27:20.161846 | 111000005813 | NVIDIA surface/synchronization error, resume batch |
| 18:27:20.162136 | 111000006103 | Low-level resume complete |
| 18:27:20.163441 | 111000007408 | xhci_hcd 0000:00:0d.0: xHC error in resume, USBSTS 0x401, reinit |
| 18:27:20.167293 | 111000011261 | USB 3-4 camera reset |
| 18:27:20.168019 | 111000011987 | USB 3-3 vendor device reset |
| 18:27:20.168369 | 111000012337 | USB 3-9 smartcard reset |
| 18:27:22.321046 | 111002165013 | Kernel suspend exit |
| 18:27:22.325440 | 111002169408 | systemd returned from sleep |
| 18:27:22.466059 | 111002310027 | MAGI PrepareForSleep(false) |
| 18:27:22.468625 | 111002312593 | Native delay inhibitor reacquired |
| 18:27:22.480477 | 111002324445 | eDP redraw |
| 18:27:22.496620 | 111002340588 | HDMI redraw |
| 18:27:22.496687 | 111002340655 | RESUME: still locked, fresh keyboard state required |
| 18:27:22.674718 | 111002518686 | Fresh keymap initialized |
| 18:28:00.170909 | — | Later redraws of both surfaces; logging is bounded |
| 18:30:36.136027 | 111195979994 | logind Power key pressed (short) |
| 18:30:36.162697 | 111196006665 | Powering off |
| 18:30:36.776196 | 111196620164 | Wayland disconnect 104 |
| 18:30:36.783651 | 111196627619 | Locker failure without authenticated unlock |
| 18:30:36.806183 | 111196650151 | Compositor lost |

No authentication attempt/PAM worker/unlock follows the fresh keymap. The old
journal does not log keyboard enter/leave/modifiers/repeat/key events, capability
changes or individual readiness predicates. Their absence from the log is not
proof their absence on the wire. Native input unblock/recreation follows from
`resumeSleep()` source plus the RESUME message, not an individually timestamped
unblock event. Hypridle's individual PrepareForSleep/inhibitor-release callbacks
are not independently timestamped here; MAGI's startup sleep-state observation,
Locked and system suspend establish the recorded sequence.

There is **no output-removal event in this locker instance** after resume. The
18:23 output 87→88 replacement belongs to an earlier lock, not this failure.
HDMI unplug has no recoverable exact timestamp. Operator chronology bounds it
after post-resume input failure and before poweroff (broadly 18:27:22–18:30:36).
The USB error is therefore category **A relative to the later observed failure**:
it predates userspace resume and the operator's post-resume observation, rather
than occurring during the later unplug. This does not establish causation or
an exact first-failed-key timestamp.

## Hardware and input-stack evidence

Current enumeration identifies the internal keyboard as `AT Translated Set 2
keyboard`, bus 0011, `isa0060/serio0/input0`, under `platform/i8042/serio0`.
It is not a USB keyboard. HDMI-A-1 is on NVIDIA PCI 0000:01:00.0 (RTX 3070);
eDP is on Intel 0000:00:02.0. The failing xHCI controller is Intel Thunderbolt
USB at 0000:00:0d.0, a different path. No USB display adapter, external USB
keyboard or dock is currently enumerated. This supports GPU-native HDMI, but
cannot prove historical physical cabling or exclude a separate USB upstream.

No internal-keyboard/i8042/HID/libinput failure or re-enumeration is recorded in
the failed window. Power-button delivery proves that input device worked, not
that the keyboard did. No raw kernel/libinput input trace or old compositor
keyboard trace survives. Hardware input recovery is therefore **not proven**.

## Successful-run comparison

Same previous-boot journal; wall timestamps below are journal event displays.

| Run | USB resume error | MAGI resume | Fresh keymap | Later output churn | PAM start / authenticated unlock |
|---|---|---|---|---|---|
| Phase 7, PID 629157 | 13:55:31.129502 | 13:55:33.444932 | 13:55:33.620457 | 79 removed 13:55:34.326732; 80 added 13:55:36.822155 | 13:55:45.250534 / 45.314934 |
| Phase 8B, PID 674616 | 16:37:49.113381 | 16:37:50.053677 | 16:37:50.058105 | See preserved extract; not required to explain success | 16:37:55.773765 / 55.836665 |
| Phase 8C, PID 685102 | 17:06:12.108450 | 17:06:14.414932 | 17:06:14.580794 | 84 removed 17:06:15.284626; 85 added 17:06:17.709552 | 17:06:25.203828 / 25.278773 |
| Failed Phase 9 | 18:27:20.163441 | 18:27:22.496687 | 18:27:22.674718 | None logged | None |

An earlier single-output Phase 7 run also unlocked. None of these historical
runs logs enter/modifiers/first key, so the earliest **input** divergence cannot
be reconstructed. The first observable downstream difference is no PAM attempt.
Automatic output churn differs in two successful dual-output runs; it could
refresh focus, but that explanation is not proven. Keymap latency in the failed
run (~178 ms) resembles successful Phase 8C (~166 ms).

## Native state-machine audit

`wayland_owner.cpp`, `native_input.cpp/.hpp`, `auth_controller.cpp`, controller
output lifetimes and sleep policy were inspected against the committed baseline.
Phase 9 did not change native keyboard acceptance or resume reconstruction.

1. Seat keyboard capability creates one wl_keyboard; loss releases it and clears
   focus. Keymap creates XKB state and resets native focus/modifier readiness.
2. Enter accepts only a currently owned lock surface; held keys are suppressed.
   Enter resets modifier readiness. Modifiers initializes XKB state/readiness.
3. Owner routes keys only while not stopping, Controller Locked and focused surface
   belongs to a current native output. NativeInput also requires sleep unblocked,
   valid keymap, focus, fresh modifiers, valid/nonrepeated pressed key, permitted
   modifier combination and editable authentication state. Capacity/retry/worker
   gates remain. Enter submits only a nonempty native credential.
4. Sleep blocks input, clears credential/focus and cancels authentication. Resume
   unblocks/reset-focus, clears owner modifiers/focus, releases the old keyboard,
   requests a fresh keyboard, unblocks controller sleep state and redraws.
5. Surface removal clears its focus. Output configure/buffer work uses numeric
   lifetime tokens. Keyboard focus instead uses current wl_surface membership;
   callbacks previously ignore the keyboard parameter and rely on libwayland
   resource destruction. There is no separate existing keyboard-generation
   acceptance predicate. Diagnostics expose an epoch, without adding acceptance.
6. Authentication generation remains separate and authoritative for stale worker
   results. No stale output, fake focus or missing modifiers is accepted by this
   investigation's changes.

A fresh keymap can coexist with missing focus or missing modifiers indefinitely.
The synthetic tests demonstrate this state, but cannot say which state existed
in the failed process. No duplicate keyboard or stale-focus event is proven.

## Protocol guarantees and compositor hypothesis

Inspected 2026-10-18: installed Wayland 1.26.0 `/usr/share/wayland/wayland.xml`,
wl_keyboard v11. Enter establishes focus; leave clears it. Modifiers must follow
enter. Modifiers may also arrive without focus. Keys require an active surface;
repeat-info precedes the first key. `get_keyboard` does not promise unconditional
re-entry of an already focused surface after client-side recreation.

Installed Hyprland is 0.56.2-4. Upstream tag v0.56.2
[Seat.cpp](https://raw.githubusercontent.com/hyprwm/Hyprland/v0.56.2/src/protocols/core/Seat.cpp)
shows keyboard-resource construction sends keymap/repeat information and may send
enter for the focused client, without a corresponding modifiers call on that
constructor path. Its `sendEnter` does not supply modifiers.
[SeatManager.cpp](https://raw.githubusercontent.com/hyprwm/Hyprland/v0.56.2/src/managers/SeatManager.cpp)
shows normal focus changes send enter and modifiers, while unchanged focus returns
early. These are upstream source observations, not a trace of this installed
binary; distro patches and other event paths remain possible.

**Hypothesis:** retained lock focus + recreated keyboard + constructor enter with
no fresh modifiers leaves MAGI safely rejecting keys. A modifier change or later
focus transfer might restore readiness. That fits an omission on this compositor
path, but production logs cannot confirm it. Do not remove the modifier gate or
invent focus as a workaround. No upstream code was copied.

## Phase 9 timing

Wallpaper preparation is lazy, process-cached and synchronous on the GUI/Wayland
thread during first presentation. The first keyboard request precedes rendering;
queued keyboard callbacks can wait for that render. Failed-run first configure
to commit is ~142 ms, including all rendering, not an isolated blur measurement.
Resume redraws use the cached wallpaper; no repeated blur is required. Two resume
redraws take about 30 ms before the RESUME log. Output scene creation is synchronous.
There is no evidence that new wallpaper preprocessing blocked the resume window
for 200 ms or caused the failure. Visual code is unchanged in this investigation.

## Instrumentation and tests added

`MAGI_LOCK_INPUT_DIAGNOSTICS` defaults OFF and is rejected for production install.
Diagnostic builds emit at most 256 lifecycle events with CLOCK_MONOTONIC µs,
keyboard epoch/current-resource status, seat/capability, owned surface's output
and lifetime, auth generation, readiness flags and routing-gate reason. Events
cover sleep block/unblock, reconstruction, keyboard create/release, keymap,
enter/leave, modifiers, repeat-info, key press/release and surface removal.
Existing surface creation/removal and sleep logs remain.

No translated text, credentials, keymap contents, modifier values or PAM secrets
are logged. Raw keycodes are deliberately omitted too: they can reconstruct a
password. Event presence and readiness are sufficient to distinguish delivery
from rejection. Routing-ready does not promise append: held/repeated keys,
modifier combinations and auth retry/capacity rules still apply.

Nine production NativeInput characterizations cover normal ordering, enter before
keymap with owner focus reapplication, pre-enter modifiers, missing fresh
modifiers, retained output without enter, removed/fresh focus, replaced/lost
keymap and held resume keys. All reject while sleep-blocked and never submit or
start PAM. They are not a mock compositor and do not claim wl_surface/resource
lifetime coverage; the existing output/auth suites cover those boundaries.

## Validation and deployment gate

Both fresh native builds compile. New ordering tests (9 cases) and binary gate
pass in production and development (2/2 focused CTests in each). Diagnostic marker
is absent from production binary and present in diagnostic development binary;
production-install + diagnostics configuration is rejected as intended.

Full suites were run once: initial production 9/16, development 10/16. One new test
needed to wait for the real auth retry timer; corrected and rerun successfully.
Combined latest results are production 10/16, development 11/16, **not full passes**.
Remaining failures: auth production/development, sleep, output and presentation
IPC tests; production additionally fails systemd user-unit verification. Unix
socket sends return EPERM in this execution environment, including an independent
socketpair probe. These tests need a normal host run; no checks were weakened.
Rust: 8/18 pass, 10 IPC-dependent failures. Clippy and cargo fmt pass. Visual scale
1/1.5/2, presentation/preview boundaries and binary gates pass. Diff whitespace
check passes. No live or package approval can be inferred from partial validation.

Non-disruptive host validation commands (no lock/suspend/install):

```sh
ctest --test-dir /tmp/magi-resume-input-investigation-mi8fhp4p/production --output-on-failure
ctest --test-dir /tmp/magi-resume-input-investigation-mi8fhp4p/development --output-on-failure
cd /home/jkebwdn/dotfiles/linux/magi/native/lock/auth
CARGO_TARGET_DIR=/tmp/magi-resume-auth cargo test --locked --offline
```

**Do not launch the development locker live:** that test build contains the
existing unsafe timed-unlock/failure-injection test features. Diagnostics are not
installed. There is no package release bump or new package. A later reviewed
production binary change requires 0.1.0-3, package audit and the manual sudo gate.

## Proposed next test — not authorized or initiated

First review this report and complete host validation. Agree a narrowly scoped,
nonsecret diagnostic deployment with development unlock/failure injection OFF;
the current diagnostic install guard deliberately prevents accidental deployment.
Then verify saved work, both outputs, installed hashes, normal Hypridle inhibitor,
no existing locker/worker, and an authenticated recovery TTY. Record the original
VT before testing; do not assume its number. Keep that TTY available.

Pre-arm journal capture and timestamp markers before one separately approved
suspend. `/tmp/magi-resume-input-investigation-mi8fhp4p/capture.py` is a read-only
snapshot helper (only writes evidence files); it does not lock or suspend.

On resume, first try normal input; if it works, authenticate once. If not:

1. Do not unplug HDMI. Note wall time and whether Caps Lock LED/state responds.
   A modifier change could itself restore readiness; record that explicitly.
2. Try Ctrl+Alt+F3 to the already prepared recovery TTY. This distinguishes VT
   input handling, without terminating the graphical session.
3. Run `python3 /tmp/magi-resume-input-investigation-mi8fhp4p/capture.py failed-before-hotplug`.
   Inspect the captured MAGI/Hyprland/kernel journal; do not type a password into
   diagnostic commands. Do not kill the locker, compositor or restart Hypridle.
4. Return to the recorded graphical VT only if safe. After evidence is captured,
   HDMI removal may be a separately timestamped diagnostic: run the helper with
   `before-hdmi-unplug`, unplug, then `after-hdmi-unplug` from the TTY.
5. If VT switching is unavailable, record that fact; do not claim that it proves
   hardware failure. Recovery limitations must be agreed before the live test.

No automatic retest follows this report. Stop for operator review.

## Exact investigation changes and protected state

- `native/lock/CMakeLists.txt`
- `native/lock/src/native_input.hpp`
- `native/lock/src/wayland_owner.hpp`
- `native/lock/src/wayland_owner.cpp`
- `native/lock/tests/resume_input_test.cpp`
- `docs/design/lock-screen-phase9-resume-input-investigation.md`
- `docs/design/lock-screen-phase9-visual-design.md` (pause/link only)
- `docs/README.md`, `docs/architecture.md`, `docs/decisions.md` (investigation links)

The 629-record start snapshot covers dirty/untracked source, operator settings and
backup history, Theme Orchestrator runtime state and the five installed lock files.
Comparison changes only intended pre-existing source records; operator/protected
records match. Additional previously clean/new investigation files are listed
above. Hypridle/Hyprlock configuration was not touched; the existing package/routing
and other operator-local dirty paths remain. No index entries were added.

## Accepted checkpoint: host-validation gate

The operator accepted the investigation checkpoint and requested one instrumented
reproduction after host validation. A fresh AF_UNIX socketpair probe still fails
with EPERM for both stream and seqpacket sends in the tool environment. Sandbox
escalation is unavailable under this session's permission policy. No additional
live preparation or handoff has therefore begun.

Prepared and syntax-checked:
`/tmp/magi-resume-input-investigation-mi8fhp4p/host-validate.sh`.
Run as the normal graphical-session user, without sudo:

```sh
bash /tmp/magi-resume-input-investigation-mi8fhp4p/host-validate.sh
```

The script checks IPC, refreshes the existing temporary test builds, runs both
complete CTest suites, Rust tests, Clippy, format checking, installed user-unit
verification and diff checking. Complete command/output logs, per-command exit
codes and final status go to a unique `host-validation-*` directory inside the
investigation directory. Build/preflight failure stops immediately; suite failures
are collected and produce a nonzero final exit. The existing production-install
CTest stages an artifact audit exclusively under a temporary DESTDIR; it never
replaces installed files. No live lock, suspend, configuration edit or package
installation is performed. Existing test builds remain offline-only.

Host results are **pending operator execution and independent log review**.
No diagnostic binary/service deployment, temporary Hypridle handoff or suspend
approval request is appropriate until this gate passes. Installed 0.1.0-2,
production acceptance rules, Phase 9 visuals and protected operator state remain
unchanged. No staging, commit, push or cleanup.

## Host validation passed; inactive diagnostic preparation

Independently inspected `host-validation-4XAjs6kr/results.tsv`, exit status and
saved suite logs after operator execution at 19:19 BST. All commands returned 0:
production CTest **16/16**, development CTest **16/16**, Rust **18/18**, Clippy,
formatting, installed user-unit verification and diff check. Socket preflight
passed on the host. The previous IPC failures were execution-environment dependent.
The QML invalid-provider line in visual tests comes from standalone root inspection
without the render engine's provider; the actual render assertions passed.

Built an inactive Release diagnostic owner:
`/tmp/magi-resume-input-investigation-mi8fhp4p/diagnostic-runtime/magi-lock-proof`.
`MAGI_LOCK_INPUT_DIAGNOSTICS=ON`; development unlock, failure injection, preview,
tests and production install are OFF. Auth-worker override and fixture paths are
empty. Its sibling `magi-lock-auth` symlinks to `/usr/lib/magi/magi-lock-auth`.
The current reviewed source is unchanged: diagnostic-only logging, no change to
input readiness/acceptance or visuals. Release hardening flags mirror production;
the build intentionally uses the non-install target, so it is not a package byte
comparison. Binary security gate passed; diagnostic marker present; installed-file
hashes unchanged. No binary was executed with acquisition/authentication flags.

Inactive drafts under `handoff-draft/`:

- `magi-lock-resume-diag@.service`: copies installed notify/refuse-stop/no-restart
  semantics; changes executable, description and journal identifier only.
  Eventual runtime location would be
  `/run/user/1000/systemd/user/magi-lock-resume-diag@.service`; **not placed there**.
- `magi-lock-request`: installed request wrapper with only target unit family
  renamed. Native per-display instance guard remains; no unlock endpoint.
- `hypridle.conf`: only `lock_cmd` routes to the temporary wrapper. Existing
  inhibit_sleep=3, 300/600-second listeners, before/after sleep commands unchanged.
  Exact diff is `handoff-draft/hypridle.diff`.

`capture-failure.sh` is executable and delegates to reviewed `capture-host.py`.
It writes a unique private snapshot under the investigation directory: wall and
monotonic markers, lock/Hypridle/Hyprland/kernel journals, read-only compositor
status/topology/devices, process names, unit state, inhibitors, sleep state, power,
input enumeration and each actual login session's type/VT/identity. It captures
Hypridle argv/cwd/executable and allowlisted graphical environment only. No raw
input recorder, keycode, keysym, translated text, input injection, process control,
configuration write, lock, suspend or restart is used. From TTY it recovers the
compositor environment from the still-running Hypridle process. Draft unit
verification runs only in `preflight` mode. Syntax checks pass.

Next required read-only host snapshot:

```sh
bash /tmp/magi-resume-input-investigation-mi8fhp4p/capture-failure.sh preflight
```

The tool environment sees isolated processes and cannot query the host socket/bus.
Current power, outputs, production Hypridle PID/argv/cwd, inhibitor and graphical
session therefore await this snapshot. Authenticated Ctrl+Alt+F3 recovery also
requires operator confirmation. No handoff or suspend approval is requested yet.

Restoration design remains gated by the proven Phase 7 policy: a separate host
supervisor must observe PrepareForSleep true→false, fresh false, terminal sleep
service and exited diagnostic owner before stopping temporary Hypridle and
restoring the exact captured production invocation/environment. Unknown/pending
state retains the temporary coordinator; no timer unlock or forced locker stop.
The independent TTY recovery path must use the same verified restoration gates;
if secure graphical recovery fails, determine the actual Wayland session before
any explicitly approved termination. Finalize and audit these scripts only after
current host identity/lifetime evidence is available. **Automatic restoration is
not yet prepared or claimed guaranteed; activation remains prohibited.**

No source acceptance change, package change, live handoff/test, staging, commit,
push or cleanup occurred. All Phase 9 visuals remain frozen.

## Host preflight and guarded handoff preparation (inactive)

Reviewed `20261018-200632-082742-preflight` independently. Every capture command
returned 0; draft user-unit verification passed. Production Hypridle PID 1571,
executable `/usr/bin/hypridle`, argv `hypridle`, cwd `/home/jkebwdn`, holds its
sleep-delay inhibitor. User-manager and Hypridle graphical identities match:
wayland-1, runtime /run/user/1000, Hyprland instance
`efb50993780079460b0cbed1363e2166a2de1d9f_1792344695_1252034819`.
Actual graphical session **1**, Type=wayland, Active=yes, **VT1**, LockedHint=no;
manager session 2 is not the graphical session. All production/diagnostic locker
units inactive. PreparingForSleep=false. `hyprctl status` reports backend/config
provider only: do not mistake that response for compositor lock-state proof.

Both outputs are active/DPMS on: eDP-1 3840×2160 scale 2 at 0,0; HDMI-A-1
3840×2160 scale 1.5 at 1920,32. Power snapshot: AC online, battery **3% charging**.
Keep AC connected and allow at least 10% before this experiment; launcher rechecks.
TTY3 authentication has not yet been confirmed by the operator. Return to the
verified graphical VT with Ctrl+Alt+F1, rather than assuming a VT number.

Prepared under the investigation directory, **not run/activated**:

- `handoff.py`: imports the existing Phase 7 pure handoff policy. Fresh checks
  enforce reviewed file hashes, exact PID/start-time/argv/cwd, one Hypridle,
  manager environment, active graphical session, both outputs, sufficient power,
  no locker, compositor unlocked and inhibitor. The exact original environment
  is captured only at activation in a private mode-0600 file, never printed or
  included in failure snapshots. A logind signal subscription precedes routing
  changes. Temporary Hypridle is launched with the exact original environment.
- `start-approved-test.sh`: inert without `--one-suspend-approved`. Detaches a
  one-shot supervisor so terminal disconnect does not abandon restoration.
  The supervisor issues exactly one systemctl suspend; existing state prevents
  repeating it. This is an action script, **not another preflight command**.
- `restore-if-safe.sh`: independent TTY recovery entry. It rejects concurrent
  supervisor operation, another boot, unknown/pending sleep, live owner or locked
  compositor. It never signals a locker. Stale/unrecognized Hypridle identities
  are rejected; pidfd-based SIGTERM applies only to the verified idle process.
- `lock-state`: small read-only Wayland notifier client using the installed
  hyprland-lock-notify-v1 XML. It never binds keyboard/seat or creates a lock.
  A roundtrip bounds the protocol's immediate already-locked notification.
  Failure is unknown, never interpreted as unlocked. Its generated protocol
  sources retain the system XML's license. No new production source dependency.
- `capture-failure.sh`: now includes the notifier result and copies supervisor,
  temporary Hypridle and policy-state logs, in addition to the reviewed read-only
  snapshot. It never copies the private original environment.

Automatic restoration requires observed PrepareForSleep true→false, fresh false,
terminal suspend service, exited owners and fresh compositor-unlocked evidence.
It stops only the exact temporary Hypridle, restores original argv/executable/cwd
and full environment, verifies exactly one production Hypridle with inhibitor,
then removes only the matching runtime diagnostic unit and reloads the user
manager. The unit is never stopped to unlock. A timeout/command exit never grants
restoration. Unknown state deliberately retains the temporary coordinator;
independent recovery refuses to guess. This is fail-secure restoration, not a
promise that arbitrary process/kernel failure can be recovered automatically.

Twelve offline mock guard tests pass: pending sleep, active sleep service, live
owner, locked compositor, missing true/false, unknown idle process, changed PID
identity, one-shot enforcement, original-already-running path, safe restoration,
and a gate changing immediately before stop. Python/Bash syntax checks pass.
Existing host suites remain passed; no input-acceptance source changed afterwards.
Exact artifact hashes are recorded in `handoff-artifact-hashes.json` and checked
before action. Installed/runtime config hashes still match preparation.

### Pending operator gate and one-test procedure

Do not run the action script until fresh explicit approval after TTY verification.
Operator must save work, leave both displays connected, confirm AC/battery and
verify authenticated Ctrl+Alt+F3 recovery. Current TTY verification is pending.

After approval only: activate the reviewed one-shot supervisor. It performs the
handoff and one suspend. Wake normally, wait five seconds, try normal input. If
it works, authenticate once with one Enter; no repeated suspend tests.

If input fails, keep HDMI connected. Press Caps Lock once, record physical LED
response (and whether that action restores input), then Ctrl+Alt+F3. From the
prepared TTY, if needed set:

```sh
export XDG_RUNTIME_DIR=/run/user/1000
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
bash /tmp/magi-resume-input-investigation-mi8fhp4p/capture-failure.sh failed-before-hotplug
```

Report the evidence directory without terminating the session. The capture uses
running Hypridle's graphical environment. Do not enter a password in diagnostic
commands. Independent restoration is only for a stopped supervisor and only if
its strict guards pass; it cannot unlock a failed live owner. If graphical
termination ultimately becomes necessary, re-query actual session identity and
obtain approval before `loginctl terminate-session <verified-id>`. Do not hardcode
session 1 merely because it was verified in this snapshot. HDMI removal remains
a separately approved, timestamped experiment after original-state capture.

No test result, event-case classification, Caps Lock or TTY outcome is claimed.
No handoff, suspend, runtime-unit installation, production package write, source
acceptance change, staging, commit, push or cleanup occurred in preparation.

## Operator accepts reboot recovery instead of TTY

The operator reports Ctrl+Alt+F3 does not switch to a terminal and explicitly
permits the one test without TTY, accepting reboot if necessary. This supersedes
the earlier TTY prerequisite for this one experiment; it does not demonstrate
kernel input failure and does not authorize any acceptance-rule change. Fresh
sysfs power check: AC online, battery 36%, charging.

Because reboot can erase /tmp, added a **read-only** detached evidence collector
before handoff. It follows diagnostic unit journal events with fsync and snapshots
at 5/20 seconds after observed resume, with a 60-second fallback and a post-restore
snapshot. Collection lasts at most ten minutes; expiry never unlocks, stops a
locker or grants restoration. Supervisor event/state records are also persisted.
Durable evidence directory:
`/home/jkebwdn/.local/state/magi-resume-input-evidence/mi8fhp4p/`.
No original full environment or credential data is copied there. Both physical
outputs stay connected. The collector does not read raw input or log keycodes.

The modified temporary harness passes syntax checks and all 12 offline restoration
guard tests again. Reviewed artifact hashes were refreshed. No production/native
source, acceptance semantics, installed files, PAM or canonical Hypridle config
changed. No handoff or live suspend was executed by the assistant.

Operator action for the single approved test (not a repeatable loop): save work,
keep AC/both outputs connected, launch `start-approved-test.sh` with
`--one-suspend-approved`. On resume wait five seconds, try normal input once. If
it fails, keep HDMI connected, press Caps Lock once and note LED/input response.
Allow at least 60 seconds for automatic evidence capture before the accepted
reboot fallback if feasible. Return with observed input/Caps Lock outcome; the
next step is trace classification, not a guessed source fix or rollout.

## One live diagnostic result — Case 2 recovered, 2026-10-18 20:29 BST

Operator reports normal password entry and return to the desktop. Exactly one
suspend request was issued. No repeat test, source fix, package installation or
rollout finalization follows. **The trace nevertheless demonstrates Case 2:** a
fresh keyboard enter had no following modifiers event until after the first key
press, and that first key reached MAGI with modifier readiness false.

Authoritative preserved source:
`/home/jkebwdn/.local/state/magi-resume-input-evidence/mi8fhp4p/20261018-202954-664960-auto-restored/early-lock-journal.log`.
Locker PID 31523, resumed keyboard epoch 2. Below, wall time is journal receipt
(BST); monotonic values for INPUT_DIAG are its own `mono_us` field, not journal
receipt. Other rows use journal receipt monotonic µs.

| Wall time | Monotonic µs | Event and predicates |
|---|---:|---|
| 20:29:23.752188 | 4875003086 | Supervisor issues its one suspend request |
| 20:29:24.258188 | 4875509054 | Keyboard capability false before sleep |
| 20:29:24.258197 | 4875509073 | Epoch 1 keyboard released on capability loss |
| 20:29:41.631567 | 4878553527 | Same xHCI resume error, USBSTS 0x401 |
| 20:29:42.684749 | 4879606710 | MAGI PrepareForSleep(false) |
| 20:29:42.687819 | 4879609757 | resume-begin: no keyboard, capability false, sleep blocked |
| 20:29:42.687834 | 4879609776 | Sleep unblocked; no owned focus |
| 20:29:42.716218 | 4879638144 | Resume reconstruction completes; keyboard still absent |
| 20:29:43.541715 | 4880463638 | Keyboard capability returns |
| 20:29:43.541771 | 4880463670 | Fresh keyboard created, epoch 2 |
| 20:29:43.562180 | 4880483957 | Fresh keymap received |
| 20:29:43.562995 | 4880484918 | Keymap applied; no focus/modifiers |
| 20:29:43.563008 | 4880484928 | Repeat-info received |
| 20:29:43.563019 | 4880484938 | Enter: output 77/lifetime 2, owned focus true, focused true, modifiers false, gate=no-modifiers |
| 20:29:49.606354 | 4886528231 | First pressed key event: current epoch/resource, valid owned focus, sleep unblocked, modifiers false; gate=no-modifiers |
| 20:29:49.606838 | 4886528305 | First fresh modifiers event: modifiers true, gate=routing-ready |
| 20:29:50.452903 | 4887374775 | First later pressed event with gate=routing-ready |
| 20:29:53.606232 | 4890528193 | One PAM worker spawned, PID 32413 |
| 20:29:53.606346 | 4890528307 | One authentication attempt, generation 1 |
| 20:29:53.695380 | 4890617340 | Worker reaped, authentication succeeded |
| 20:29:53.695392 | 4890617353 | One AUTHENTICATED UNLOCK |
| 20:29:53.701417 | 4890623209 | Keyboard leave following unlock |
| 20:29:53.701430 | 4890623217 | Focus cleared |
| 20:29:53.701441 | 4890623402 | Compositor processed unlock; locker exits |
| 20:29:54.297152 | 4891219128 | Production Hypridle restoration/inhibitor verified |

The enter→first-key gap is **6.043293 seconds** by native monotonic timestamps.
The modifiers callback follows that first key callback by **74 microseconds**.
NativeInput's unchanged `!focused_ || !haveModifiers_ || !state_` gate discards
that initial pressed event before translation. The next modifiers event opens
readiness, allowing later input. The trace does not log or identify the key and
must not be used to infer any password character. Routing-ready alone does not
prove a particular event appended text; operator success and the later successful
PAM exchange establish that authentication input ultimately worked.

No output removal/recreation occurred: eDP registry 72/lifetime 1 and HDMI registry
77/lifetime 2 persisted. Fresh keyboard focus remained on the valid HDMI surface.
All logged keyboard callbacks identify the current resource. No stale lifetime
rejection is shown. Both outputs were still active/DPMS on after unlock; no HDMI
troubleshooting was reported or logged. No internal-keyboard/i8042/HID failure
was recorded. The same USB error again accompanied a successful unlock.

**Classification: Case 2, followed by modifier-event recovery and successful
unlock.** This is stronger than a generic successful-run comparison: it proves
the missing-modifier gate can reject a real key on this installed compositor.
It does not retrospectively prove that the original failed run had exactly this
state, since that run lacked callback diagnostics. This run recreated its keyboard
on a later capability-return event, not directly inside resumeSleep while already
capable; the failed run's capability sequence remains unknown. The compatibility
hypothesis is now supported enough to justify investigating a narrow protocol-
correct fix. No neutral-modifier synthesis, fake focus, global gate removal or
input-rule modification is made here. Stop for review before any fix work.

### Recovery and instrumentation qualifications

TTY3 was unavailable before the test and deliberately waived by the operator.
No failed-resume TTY attempt or Caps Lock LED observation was needed/reported.
Do not infer which key caused the observed modifiers event.

The original continuous journal follower failed at startup with `Failed to add
filter for units: No data available`: the globbed diagnostic unit family did not
yet exist in the journal. Its `live-lock-journal.jsonl` is empty. **The automatic
5-second and post-restoration journal snapshots recovered the complete trace**
and saved it durably. This collection defect must be corrected before reusing the
harness; no further live run is authorized by this result.

The supervisor also logged `STOP: Hypridle overlap refused` after its restoration
success message. The source permits an initial restoration exception to be
re-raised after the finally-block restoration succeeds. A process-exit/reaping
race is plausible, but not separately instrumented, so do not claim a proven
harness root cause. Independent post-restoration snapshot verifies exactly one
production Hypridle **PID 32456**, original argv `hypridle`, executable/cwd and
allowlisted graphical environment, plus its sleep-delay inhibitor. Compositor
notifier reports UNLOCKED. All locker units are inactive; the matching runtime
unit file is absent. This is verified restoration despite the harness exit error,
not a clean-harness-exit claim. No recovery action is currently required by those
observations. Review the harness guard/reaping behavior before reuse.

Installed package/config/build hashes match `diagnostic-preparation-hashes.json`;
installed magi-lock remains 0.1.0-2. No production source change was made after
host validation. This result updates documentation only. Diff check passes;
index remains empty. Phase 9B finalization remains paused; no commit/push/cleanup.

## Compatibility fix implementation — awaiting host validation

**Confirmed classification: Hyprland / MAGI keyboard-state compatibility defect.**
The live trace proves MAGI rejected a real, correctly focused event while waiting
for initial modifiers. It does not prove every detail of the earlier unrecovered
failure. Installed versions rechecked: Wayland 1.26.0-1, Hyprland 0.56.2-4.
Local `/usr/share/wayland/wayland.xml`, wl_keyboard interface version 11, enter:
“The compositor must send the wl_keyboard.modifiers event after this event.”
Its enter description also forbids using the unordered held-key list to emulate
press events. The key description places modifier-change notification after the
key that changes it. A later mask therefore cannot necessarily reconstruct an
arbitrary sequence of preceding keys. No web-only assumption is used here.

### Narrow native implementation

NativeInput retains **one press and optionally its matching release**, fixed
capacity **two raw metadata records**. No translation, credential mutation or
logging of key identity occurs while deferring. The corresponding real modifiers
update first applies the authoritative depressed/latched/locked/group values;
then the detached pending pair goes through normal NativeInput dispatch exactly
once. The native slot and temporary replay copy are explicitly scrubbed. Held
enter keys remain suppression data and are never replayed as credential presses.
A held key's release before initial modifiers still updates suppression correctly.

The maximum wait is **100 ms from the first deferred press**, using a precise Qt
timer plus an elapsed-time check in modifiers/key callbacks (so a delayed timer
cannot permit late replay). This is a bounded retention/retry policy, not a
claim about compositor latency or a source of modifier truth. The live 74 µs gap
fits comfortably; no sleeping or busy waiting blocks the Wayland dispatcher.

Another press or unrelated event before authoritative state is an overflow/ambiguous
sequence, not permission to reinterpret several keys under a later mask. On
overflow or expiry the pair is scrubbed, any partial credential is cleared and
the existing status slot displays `Keyboard state unavailable: press and release
Shift`. Further unknown-state events cannot grow a queue. A real modifier event
restores readiness; no neutral mask is synthesized. If even a physical modifier
press/release produces no authoritative notification, remain locked and stop for
further evidence as required by the operator's never-modifiers stop condition.

Caps Lock is explicitly **unknown** until authoritative state arrives. Native
presentation exports only `capsKnown` alongside the existing derived Caps value;
QML shows `Caps Lock state pending` while unknown. Existing font, layout, avatar,
blur/dimming, scale, dots and ordinary status copy remain unchanged. The native
fallback also uses the exceptional recovery instruction and never asserts a stale
Caps value as current. These are exceptional-state correctness changes, not a
visual redesign.

### Missing-modifiers recovery alternatives

| Option | Decision |
|---|---|
| A: bounded deferred dispatch | Chosen for the proven key→modifiers gap. One logical keystroke only, 100 ms ceiling, no guessed mask. |
| B: reconstruct from enter.keys | Rejected as a complete state source: held keys do not determine latched/locked modifiers or group. Continue suppression only. |
| C: provisional neutral/guessed state | Rejected: can corrupt password interpretation or submit before reconciliation; no safe general rollback. |
| D: keyboard rebinding | Not selected as automatic recovery: the observed/upstream recreation path is itself incomplete; another rebind cannot guarantee modifiers and may lose valid focus. |
| E: obtain a genuine modifier transition | Exceptional hint asks for Shift press/release; only compositor-supplied modifiers become authoritative. No input injection, public endpoint or bypass. If no state arrives, fail secure and investigate. |

### Invalidation/security boundaries

Focus leave/change, keymap replacement, keyboard destruction/replacement, output
removal/replacement, sleep blocking, unlock and disconnect scrub pending state.
Native auth clear/cancel/submit hooks scrub it immediately; a captured auth
creation generation is also checked before replay. No buffered event migrates
onto a new focus. Owner callbacks reject non-current keyboard resources; keymap
FDs from stale callbacks are closed. Focus now explicitly records output registry
ID and lifetime in addition to wl_surface identity, and dispatch/replay requires
that association to remain current while Controller is Locked. Invalid routing
clears native focus/pending input. No focus or modifier requirement is bypassed.

Development INPUT_DIAG remains opt-in and prohibited for production installation.
Three exceptional production messages describe defer, authoritative replay or
expiry/overflow; they contain no keycode, keysym, text or credential. Messages
are bounded per focus/state episode rather than emitted per ordinary key.

### Tests and validation gate

Resume coverage compares the actual normal/deferred credential result for
printable, Shift, Ctrl, Alt, Super, Caps Lock, Backspace, Enter and Escape, across
neutral, depressed, locked, latched and layout-group settings. US/GB shifted
symbol expectations additionally verify group interpretation. Coverage includes
the exact live event order, one press/release replay, no duplicate replay,
leave/refocus, sleep, keymap loss/replacement, auth cancellation/clear/submission,
overflow, timer expiry, late modifiers, held-key suppression and Enter submission
without any real PAM worker. Production owner tests exercise current versus stale
keyboard identity and output registry/lifetime replacement/removal. Existing auth,
sleep, output and presentation/security suites remain enabled, not weakened.
The presentation boundary allows only the added safe `capsKnown` boolean.

Focused production/development checks pass; final expanded input checks are
recorded under `/tmp/magi-resume-fix-xgs8mwux/`. Full IPC suites must run on host:
AF_UNIX send is again denied in the tool sandbox. Prepared reviewed script:

```sh
bash /tmp/magi-resume-fix-xgs8mwux/host-validate.sh
```

This uses existing temporary build caches and writes fresh full logs in a unique
host-validation directory under the fix evidence directory. Both CTest suites now
contain **17 tests**. It performs no live lock, suspend, configuration change or
production installation. **Do not package until every host check passes.**
The recipe is prepared with pkgver 0.1.0/pkgrel 3; no 0.1.0-3 artifact is built or
installed yet. Installed 0.1.0-2 is unchanged.

### Host validation follow-up — 2026-10-18 21:12 BST

Independently inspected `host-validation-pb6uixh4/results.tsv`: both native builds
passed 16/17 tests, with only `sleep_synthetic` failing after 27 scenarios. Rust
18/18, Clippy, formatting, installed unit verification and diff checks passed.
This was a stale expectation in `tests/sleep_test.cpp::keyboard`: it sends a fresh
press/release before modifiers and a separate press/release afterward, but still
expects only one character, relying on the old first-key discard.

Updated that scenario to assert zero credential mutation while the two event
records are pending, one character after authoritative modifiers, no duplicate
on a repeated modifiers event, and two characters after the second physical
press. Existing sleep-blocked, authentication-generation and authenticated-unlock
assertions remain. No production input code changed in this follow-up.
Both builds compile; focused production input and owner tests pass locally.
AF_UNIX sends remain blocked in the tool sandbox, so full sleep completion is
still a host gate. Run the bounded follow-up (both builds, sleep/input/owner tests):

```sh
bash /tmp/magi-resume-fix-xgs8mwux/host-revalidate-sleep.sh
```

The script writes fresh logs, changes no source/configuration, and performs no
installation, lock or suspend. Other successful full-host checks remain valid;
packaging remains blocked until this follow-up passes.

### Separate temporary harness corrections

Preserved before copies in `harness-before/`. Journal follower now names both
concrete diagnostic unit instances instead of using a glob that cannot expand
before the first journal entry; an unknown exact unit read succeeds with no
entries. Hypridle process enumeration excludes exited/zombie states, and repeat
restoration recognizes the recorded restored process rather than treating it as
an unrelated overlap. Fourteen offline harness guard cases pass, including zombie
classification and idempotent restored-process handling. These changes are in
the temporary harness, not production package files, and do not authorize reuse
of the completed one-shot experiment. Its archived evidence is unchanged.

### Source paths for this fix

- `native/lock/src/native_input.hpp`, `native_input.cpp`
- `native/lock/src/auth_controller.hpp`, `auth_controller.cpp`
- `native/lock/src/auth_presentation.hpp`
- `native/lock/src/wayland_owner.hpp`, `wayland_owner.cpp`
- `native/lock/src/presentation.cpp`
- `native/lock/qml/LockScreen.qml`, `LockStatus.qml` (safe exceptional state only)
- `native/lock/tests/resume_input_test.cpp`, `input_owner_test.cpp`
- `native/lock/tests/sleep_test.cpp` (explicit deferred replay expectation)
- `native/lock/tests/visual_test.cpp`, `presentation_boundary.cmake`
- `native/lock/CMakeLists.txt`, `packaging/PKGBUILD.in`
- This investigation and the Phase 9 visual checkpoint documentation.

No staging/commit/push, runtime handoff, package replacement, live lock/suspend or
cleanup. Normal production lock and one suspend remain later, separate approval
gates after manual installation of an audited 0.1.0-3 package.

### Host revalidation and package preparation — 2026-10-19

Independently inspected `host-sleep-revalidation-ny2VuVJ8/results.tsv`: all
commands passed, with sleep/input/owner 3/3 in both builds (88 input cases and
39 sleep scenarios). Together with the unaffected successful tests in
`host-validation-pb6uixh4`, all 17 native tests per configuration now have passing
host results; Rust 18/18, Clippy, format and unit verification remain passed.

Fresh package preparation: `/tmp/magi-lock-0.1.0-3-8ers_vad`. Two deterministic
65-file source exports match SHA-256
`4790e743e81bf49fcc97eb25c09631806b6aa45b59cd6070ebf99d2eef763676`.
The release build compiled, but makepkg check() stopped at sandbox-restricted
`systemd-analyze --user verify`. No check was skipped and no package was installed.
Reviewed host-only build script `host-build.sh` in that directory verifies the
source/recipe hashes, copies them into a new unique build directory, runs normal
makepkg including check(), and records checksum/inventory. It performs no install,
lock, suspend or production configuration changes. Final artifact audit and the
manual installation gate remain pending. Installed version remains 0.1.0-2.

### Audited 0.1.0-3 artifact — manual installation pending

Host makepkg including mandatory check() passed at 19:24 BST on October 19.
Artifact: `/tmp/magi-lock-0.1.0-3-8ers_vad/host-build-gl9OEgBl/magi-lock-0.1.0-3-x86_64.pkg.tar.zst`.
SHA-256: `7fcc34e9e711c23c43bbcb377bf3a769c91de578020ba794a2320f2d0a185812`.
Independent final archive extraction confirms exactly five runtime files: locker,
PAM worker, request helper, user service and PAM policy. Policy, helper and unit
are byte-identical to installed files. Development unlock, failure injection and
input diagnostics are OFF; final executable strings contain no /tmp paths or
diagnostic/test feature markers. QML is embedded; no preview, harness or fixtures
are installed. The separate makepkg debug archive is not part of the installation.
Its Rust debug-index warning did not fail the main package build or audit.

Protected-state comparison against the fix baseline found no protected changes.
Installed 0.1.0-2 remains untouched. Await manual installation; no live test,
staging, commit or push has occurred.

### Installed 0.1.0-3 verified — 2026-10-19 19:47 BST

Operator installed the audited main package through pacman. Independent byte
comparison of all five runtime files matches the reviewed archive. Host evidence
`/tmp/magi-resume-fix-xgs8mwux/post-install-f8pzxs66` confirms package integrity
(13 entries, zero altered), root ownership, valid user unit and Hyprlock absent.
Graphical session 1 is active Wayland on VT1, LockedHint=no; Hyprland locked=false.
Both outputs are active: eDP-1 3840x2160 scale 2 and HDMI-A-1 3840x2160 scale 1.5.
Both production lock units are inactive/dead with Result=success, no locker
process was found, and existing Hypridle PID 32456 retains its delay inhibitor.
No Hypridle restart or configuration edit was performed.

Next gate is explicit operator approval for ONE normal production lock via
`loginctl lock-session`, followed by one password submission, visual confirmation
and journal review for one PAM attempt/success/unlock. Save work and retain both
outputs. TTY recovery is unavailable on this setup; reboot remains the previously
accepted last recovery. Suspend is not part of this approval and remains gated
after normal lock acceptance. No live test has been triggered in this step.

### Normal production lock acceptance — 2026-10-19 19:49 BST

Operator approved and ran one normal lock with installed 0.1.0-3, entered the
password successfully, returned to the desktop and confirmed all visual checks.
The initial helper attempt stopped before lock because terminal `self` had no
logind session; discovery was corrected to require one active local Wayland
session owned by the operator. No lock was issued in the failed helper attempt.

Saved `normal-lock-journal.log` under the fix evidence directory records exactly
one worker (419343), one auth attempt (generation 1), one PAM success and one
authenticated unlock. Locker PID 419271 created output 72/lifetime 1 and
80/lifetime 2, rendered both without fallback, and exited after compositor unlock.
Lock confirmed monotonic 88895.386162; authenticated unlock 88902.312405; explicit
compositor unlock processed 88902.317447. Accepted visuals remain unchanged.

Single suspend script `suspend-once.sh` is prepared but NOT run: it requires
0.1.0-3, unlocked compositor, both active outputs, AC, Hypridle delay inhibitor,
both inactive successful production units and exactly one active local Wayland
session. It records preflight state and an exclusive start marker before one
`systemctl suspend`. No runtime handoff or configuration edits are involved.
Explicit suspend approval remains pending.

### Production suspend acceptance — 2026-10-19 19:52 BST

The operator explicitly approved and ran ONE suspend with installed 0.1.0-3,
then confirmed input worked without missing characters, neither input failure
nor manual HDMI troubleshooting occurred, and both displays returned cleanly.
Saved `suspend-fix-journal.log` records locker PID 419977 and this monotonic order:

- 89017.800076 compositor confirmed locked; coordinated readiness followed.
- 89022.801155 PrepareForSleep(false); 89022.833741 resume remained locked.
- 89023.419746 output 80/lifetime 2 removed during resume topology churn.
- 89023.444763 fresh keyboard keymap initialized.
- 89026.129749 output 81/lifetime 3 created; 89026.379663 rendered without fallback.
- 89034.906151 one worker PID 420586, one authentication generation 1.
- 89035.023947 authentication success; 89035.024209 authenticated unlock.
- 89035.039084 compositor processed unlock and locker exited.

No early-input deferral or expiry messages appeared in this run. It validates
normal production resume and output recreation but does NOT prove the buffering
branch was exercised live; that branch remains covered by deterministic tests
against the previously observed compatibility ordering. Original unrecovered
failure causality remains less certain than the confirmed first-key-loss defect.
No further live cycles are needed or authorized. Final post-run host health and
upstream fetch are pending because sandbox bus/SSH ownership restrictions prevent
those checks here. The 37-path Phase 9 allowlist is in the visual checkpoint.

### Final host health gate passed — 2026-10-19 19:58 BST

`post-install-phuzivj0` confirms installed integrity, healthy outputs, unlocked
Wayland session, inactive successful locker services and original Hypridle PID
32456 with delay inhibitor. Fresh host fetch has HEAD...origin/main = 0 0.
All acceptance gates are complete. Proceed only with the reviewed Phase 9
allowlist and normal commit/push. No additional lock, suspend or cleanup.
