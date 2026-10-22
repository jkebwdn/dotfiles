# Phase 11A — fingerprint authentication groundwork

Status: **Phase 11A complete and operator-accepted; production password-only**.
Audit date: 2026-10-22. Baseline `da48096e37b1ebbd56721d97c59ef4c1384a76e1`
(`magi: add display management framework`), `HEAD...origin/main = 0 0`.
Implementation was reviewed in `/home/jkebwdn/magi-phase11a` and the exact
allowlist integrated into `/home/jkebwdn/dotfiles` during finalization.
Initial pass performed no staging, commit or push. Finalization authorizes those
Git operations only after explicit visual/framework acceptance. No production
installation, PAM modification, daemon restart, sensor verification, enrollment,
deletion or suspend test is part of either pass.

## Scope and implemented boundary

Production remains password-only. Native C++20/Qt/Wayland owner holds
ext-session-lock-v1; `Controller::authenticatedUnlock` consumes a single verified
`AuthController` success, requires secure lock readiness and rejects sleep-blocked
release. The Rust `magi-lock-auth` worker uses PAM via an inherited unnamed
AF_UNIX/SOCK_SEQPACKET channel. Its startup checks the FD type, unnamed endpoints,
creating parent PID and UID. Protocol MAG3 v1 bounds frames, prompts and responses;
credential buffers are wiped. Native success additionally requires orderly worker
exit/reaping, EOF, current generation and an unconsumed result. QML receives a
presentation value, never credentials or an owner/controller object.

Phase 11A implements a **test-only native fingerprint model**, strict packet codec,
deterministic backend and narrow device lifecycle adapter. These are linked only
into test executables. The production binary symbol gate rejects their presence.
There is deliberately no live D-Bus adapter, spawned fingerprint executable,
production fingerprint opt-in, or fingerprint-to-Wayland authorization route.
The test owner exercises consumption and the real password controller's cancel /
scrub API, but does not claim a real compositor lock. Its unlock counter is a
synthetic decision, not proof of production fingerprint unlock.

The production renderer gains only an optional text value/component, hidden by
default. The separate offline preview executable supplies synthetic text. Settings
adds a non-authoritative Security page and in-memory enrollment preview.

## Read-only host audit and enrollment preservation

| Item | Observation |
|---|---|
| fprintd | Installed `1.94.5-2` |
| libfprint | Installed `1.94.100-1` |
| PAM | `1.7.3-1`; `/usr/lib/security/pam_fprintd.so` supplied by fprintd |
| MAGI Lock | Installed `0.1.0-3`; unchanged |
| Quickshell / Qt | `0.3.2-1`; Qt base `6.12.0-3`, declarative `6.12.0-2` |
| System service | Installed `Type=dbus`, bus name `net.reactivated.Fprint`, `/usr/lib/fprintd` |
| D-Bus activation | System service file specifies root and `fprintd.service` |
| Runtime daemon owner | Unknown: system bus connection denied by environment |
| USB | `lsusb` libusb initialization denied; sysfs lists `06cb:00bd` |
| Likely fingerprint reader | Synaptics; upstream development supported-device list includes this ID |
| Other USB | Intel `8087:0032`, camera `13d3:56fb`, smartcard `058f:9540`, root hubs |
| PCI | Tiger Lake-H / WM590; Intel USB controllers; PCI Realtek RTS525A is a card reader, not fingerprint evidence |
| Existing enrollment | **Unknown, protected**: `fprintd-list "$USER"` failed connecting to bus (`Operation not permitted`) |
| Fingerprint PAM rules | Read-only `rg fprint /etc/pam.d` returned no matches |

Installed service confines storage to StateDirectory `fprint`, mode 0700, with
ProtectSystem/ProtectHome and USB/SPI/hidraw allowances. Storage was not opened,
copied, hashed, modified or reinitialized. No claim or scan API was called.
The listing failure is not evidence of zero enrollment. Operator's previously
enrolled Hyprlock finger remains the first Phase 11B verification candidate.
Reader hardware identification/support confirmation is pending Phase 11B; the
USB ID and upstream list alone are not hardware acceptance.

Current `/etc/pam.d/magi-lock`, also the packaged fixture, is exactly:

```pam
#%PAM-1.0
auth include login
```

SHA-256: `7c0ddfcdcf0beaef0146aa289a95f1eb482e5529bfaf5216e70d23ce8680e5e4`.
`login` includes its existing stack; `system-auth` uses pam_faillock,
pam_systemd_home, pam_unix and standard environment/account/session modules.
No changes to login, sudo, su, polkit, greetd or other PAM roles are proposed here.

## Upstream evidence and compatibility

Inspected 2026-10-22; web pages are rolling documentation, **not pinned source
commits**. Installed XML/manual/package metadata pins the host API to fprintd
1.94.5-2. No upstream implementation code was copied; therefore no borrowed-code
license is introduced. The fprintd package identifies GPL-2.0-or-later.

| Source / version | What was verified | MAGI consequence / outstanding check |
|---|---|---|
| [Device API](https://fprint.freedesktop.org/fprintd-dev/Device.html); installed `/usr/share/dbus-1/interfaces/net.reactivated.Fprint.Device.xml` | Claim/Release, ListEnrolledFingers, VerifyStart/Stop, VerifyStatus(result,done), EnrollStart/Stop/Status, delete methods and properties | Adapter contract and exact status mapping; live D-Bus implementation and permission acceptance deferred |
| [Manager API](https://fprint.freedesktop.org/fprintd-dev/Manager.html); installed Manager XML | GetDevices enumerates; GetDefaultDevice may fail with NoSuchDevice | Discover all readers; select one enrolled reader explicitly, never one attempt per monitor |
| [pam_fprintd manual](https://man.archlinux.org/man/pam_fprintd.8.en), installed 1.94.5-2 manual | Serialized PAM; concurrency requires separate application-owned transactions. Default three tries / 30 seconds | Single sequential stack does not meet immediate password UX; separate PAM remains a viable alternative |
| [libfprint API](https://fprint.freedesktop.org/libfprint-dev/) | FpContext discovery, FpDevice operations, FpPrint/FpImage abstraction | MAGI stays above fprintd; no image/template APIs or storage ownership |
| [Supported devices](https://fprint.freedesktop.org/supported-devices.html) | `06cb:00bd` is Synaptics in development support list; list warns about release differences | Likely reader identity only; installed driver/hardware confirmation deferred |
| [Arch fprintd](https://archlinux.org/packages/extra/x86_64/fprintd/), [libfprint](https://archlinux.org/packages/extra/x86_64/libfprint/) and local pacman metadata | Current package versions match installed versions | Standard packages are available; no unofficial module required |
| [ArchWiki fprint](https://wiki.archlinux.org/title/Fprint) | Full-page fetch blocked by Anubis | Not used as evidence for deployment instructions; official manual and installed files used instead |
| [fprintd v1.94.5 PAM source](https://gitlab.freedesktop.org/libfprint/fprintd/-/blob/v1.94.5/pam/pam_fprintd.c) | Fetch unavailable | No claim of source-level cancellation/resume guarantees; resolve before live adapter acceptance |

Further installed-XML findings: Claim is exclusive and can return AlreadyInUse;
ListEnrolledFingers distinguishes NoEnrolledPrints from permission failures and
requires no Claim. Verification uses existing storage. Match/no-match are terminal;
scan-quality retries remain within the operation. `done` must agree with the
recognized status. Disconnection means stop using that device object. An unknown
error is terminal. The adapter must stop/release on ordinary completion/cancel;
unavailability is never success. Finger-present/needed and finger-selected are
presentation hints only. The model does not infer Match from these hints.

Installed PolicyKit policy mediates verify, enroll and setusername separately.
A future unprivileged lock child must use its actual UID, never an arbitrary
QML username, never request interactive authorization while locked and never
broaden system policy to make tests pass. Denial falls back to password. Live
session-active/inactive policy behaviour remains an explicit acceptance item.

## Architecture decision: first-party broker

| Criterion | Single PAM stack | Separate fingerprint PAM worker | Direct narrow broker (selected) |
|---|---|---|---|
| Immediate password | Sequential fingerprint module can delay password | Yes, independent password transaction | Yes, existing password worker remains independent |
| Conversation | Existing Rust worker allows one password echo-off response; fingerprint info is not password input | Separate service + message policy required | Typed scan state; no PAM prompt translation |
| Cancellation | Cannot safely cancel arbitrary PAM inside owner | Terminate/reap child; daemon cleanup must be verified | Explicit VerifyStop/Release plus bounded child teardown |
| Device/enrollment status | PAM outcome is insufficient for Settings | Extra discovery path still required | Read-only discovery uses same API vocabulary |
| Scope | Editing login include risks scope expansion | Dedicated fingerprint-only PAM service avoids shared-stack edits | No fingerprint PAM edits at all |
| Cost | Small patch, wrong interaction | Reuses PAM isolation, but two service stacks and conversation policy | More adapter/security review, precise lifecycle and daemon identity |

Selection is based on independent password availability, typed fprintd semantics
and explicit lifetime control, not code size. Separate standard PAM services are
a legitimate alternative if review favours PAM policy centralization. No hack
PAM module is justified. Existing Rust PAM implementation/tests remain unchanged;
no new fingerprint PAM fixture is needed for the selected direct architecture.
This phase does not claim to have run real PAM transactions in its tests.

Future owner launches one fixed root-owned `/usr/lib/magi/magi-lock-fingerprint`
child with a private inherited SOCK_SEQPACKET FD. Child has no Wayland socket,
compositor API, filesystem control socket, shell execution, templates or authority
to kill/unlock the owner. Validate inherited peer/type/UID as with the password
worker, close unrelated FDs, sanitize environment, disable cores, bound deadlines,
check child exit and reap. No configurable executable path in production.
A new child/connection per attempt avoids reusing a D-Bus signal subscription
across attempts. Match remains a candidate until cleanup and orderly child
completion; EOF/crash or extra protocol data must invalidate it.

## Protocol and owner state

Implemented broker-to-owner packet: exactly 32 bytes, `MFP`, version 1, event byte,
zero reserved fields; little-endian lock generation (64), attempt (64), UID (32).
No strings, biometric bytes or credential payloads. Known events: Ready, Scan,
Retry, Match, NoMatch, Timeout, DeviceLost, DaemonLost, Busy, Error. Wrong size,
version, type, reserved fields and zero generation/attempt are rejected. Wrong
binding cannot advance state. An invalid packet terminates the attempt. The codec
is a draft ABI; production transport framing still needs full child/parent tests.

Owner-to-broker design: `Start(binding, selected device)`, `Cancel(binding)`,
`Shutdown`; these are native adapter calls in 11A, not a deployed wire protocol.
Start follows owner secure readiness, policy opt-in, discovery and enrollment.
Device selection is owner-controlled, bounded and never supplied by QML.
The production transport must reject truncation using recvmsg/MSG_TRUNC, reject
ancillary FDs, cap packet count/rate, and bind completion to its tracked child PID.

Capability: unavailable, reader-present, no-enrollment, enrolled, busy, daemon-error.
Attempt: idle, waiting, scanning, retry, matched, failed, cancelled, device-lost,
daemon-lost. Enrollment metadata can change capability only, never authorize.
Waiting requires an enrolled capability; Ready requires successful claim/start.
A Match before Ready is rejected. Terminal results stop accepting further events.
Consumption is single-use and requires matching binding and current secure lock.

One global model belongs to one native owner, independent of output count. Outputs
receive snapshots only. Native future integration must invalidate on topology
change, lock teardown, cancellation, sleep transition, daemon owner change and
unlock beginning. A new monotonically increasing attempt follows recovery;
wraparound fails closed. Callback closures carry their original binding in
addition to pinned daemon unique name and object path, so queued callbacks cannot
be relabelled as a new attempt. A fresh process/connection per attempt is required
because fprintd signals themselves do not contain MAGI attempt IDs.

Password success invalidates fingerprint first and proceeds through the existing
native authorization route. Fingerprint success must invalidate pending password
success, call native cancel (scrubs full credential storage and pending input),
wait for worker cleanup without accepting further credentials, then release once.
The synthetic owner tests the decision and partial-buffer scrubbing; actual
concurrent child teardown/reap and compositor release are **not implemented or
validated for fingerprint** in this pass. They remain prerequisites before 11B
deployment, not grounds to enable the feature now.

## Failure, retries and resume

The narrow Device interface has claim/start/stop/release operations, implemented
only by deterministic tests. Session validates callback binding, daemon and path,
cleans up before delivering Match, rejects failed cleanup, models daemon/device
loss without further calls to a vanished object, and exposes an explicit clock
for timeout/backoff tests. No D-Bus is contacted by these fixtures.

Scan-quality retry statuses continue the same operation. True no-match ends it;
MAGI policy proposes a 1.5-second minimum before another attempt, a 30-second
verification deadline, bounded IPC/method timeouts and no unbounded claim loop.
These are MAGI policy choices, not promises from libfprint. Busy requires capability
refresh; no force-release of another application's device. Unknown messages/errors,
timeout, broker death, daemon death, disconnect and missing enrollment fail closed.
Neither fingerprint timeout nor backoff changes password editability or retries.

Before sleep, invalidate attempt and cancel/close the fingerprint channel without
holding up existing lock readiness. Resume begins password-ready with fingerprint
unavailable. Later bounded read-only rediscovery may establish a new daemon/device
and new attempt; no old Match is accepted. No automatic enrollment repair or
re-enrollment. Real first-scan latency and resume behaviour are unverified; the
upstream API documentation does not establish a universal resume guarantee.

## Settings and enrollment

Security → Fingerprint unlock is disabled and explicitly describes password-only
production. Host reader/enrollment status is unknown/not queried; fixture selection
is labelled synthetic. Existing enrolled metadata is not feature opt-in.
No persisted preference: **schema stays 15**. Capability, count, preview stages and
fake enrollments are session-local. No Settings JSON change.

Synthetic UI supports available + existing finger, available + no enrollment,
unavailable, waiting, staged progress, completion, duplicate and cancellation.
It previews left-index enrollment only; this is not a complete enrollment manager.
All mutations affect a disposable QML array. Real list/enroll/delete-one/delete-all
remain future operations, with explicit confirmations and authorization separate
from the lock process. UI has no unlock or authentication channel.

Future flow: list → choose finger → obtain approval → Claim → EnrollStart → stage /
retry feedback → terminal completion/failure/duplicate/cancel → EnrollStop/Release
→ relist. `num-enroll-stages` is available only when claimed (otherwise -1); never
hard-code five scans. UI currently shows stages received without inventing a total.
Existing enrollment must never be overwritten implicitly. Deletion needs explicit
selected-finger/all-fingers confirmation and is not a rollback mechanism. No images,
minutiae, templates, raw scans or copies of fprintd storage belong in MAGI.

## Lock presentation and previews

Current credential dots, clock, profile and existing status stay intact. A small
subordinate text component appears only for nonempty native presentation text.
Production passes empty text. It has no handlers, input widgets, APIs or IPC.
Preview strings use UTF-8 and render through the production QML/theme renderer.

[Waiting](previews/phase11a/fingerprint-waiting.png),
[retry/no-match](previews/phase11a/fingerprint-retry.png),
[unavailable/password fallback](previews/phase11a/fingerprint-unavailable.png).
Settings: [host unknown](previews/phase11a/host-unknown.png),
[existing enrollment](previews/phase11a/existing-enrollment.png),
[no enrollment](previews/phase11a/no-enrollment.png),
[unavailable](previews/phase11a/unavailable.png),
[synthetic enrollment](previews/phase11a/enrollment.png).
These are offline software renders, not hardware acceptance or live lock captures.

## Packaging and rollback design

Current Arch recipe is `native/lock/packaging/PKGBUILD.in`, package 0.1.0-3.
Production CMake installs owner/worker under `/usr/lib/magi`, request wrapper under
`/usr/bin`, user unit and backed-up `/etc/pam.d/magi-lock`. No install hooks.
This pass changes no package recipe, dependency, service or PAM fixture.
Fingerprint model/adapter test targets are never installed. No package was deployed.

Future package can add the fixed broker and `optdepends=('fprintd: optional
fingerprint unlock')`; fprintd already brings libfprint/PAM module. No direct
libfprint linkage/storage access is needed. If broker startup linking requires a
new library, make that an explicit dependency rather than breaking password-only
startup. Standard system D-Bus authorization, no custom broad polkit rule or daemon
service. Opt-in must follow reader support, enrollment and acceptance, never merely
hardware/enrollment discovery. Review the compiled gate and full child teardown
before any package can expose the opt-in.

Rollback: disable fingerprint opt-in, install the retained password-only
`magi-lock-0.1.0-3-x86_64.pkg.tar.zst` (verify/cache this artifact before deployment),
confirm the above exact PAM file and existing unit/wrapper. Preserve enrollment.
A direct-broker deployment should never have altered PAM; if a separately reviewed
future PAM experiment did, restore only the saved MAGI PAM service, not shared
login/system-auth. Keep an authenticated recovery terminal available for the
future deployment transaction. Broken fprintd alone needs no PAM rollback: password
worker remains independent. No enrollment deletion, fprintd storage restoration,
login/greeter/keyring integration or sudo/polkit fingerprint enablement is involved.

## Validation and limits

- Native build succeeds with C++20 warnings-as-errors for new model/tests.
- `fingerprint_synthetic` passes: missing capability/enrollment, all failure events,
  partial password scrub, password-wins/late Match, fingerprint-wins/one consumption,
  wrong UID/lock/attempt, cancelled/stale/duplicate Match, quality retries, resume,
  malformed/truncated/unknown packets, EOF/death invalidation and shared snapshots.
- `fingerprint_session` passes: exact fprintd semantic events, pinned sender/path,
  stale subscription, claim/start/stop/release, failed cleanup, timeout, backoff,
  busy, daemon loss and reappearance. No real bus/sensor involved.
- `fingerprint_transport` **skipped**, explicitly reports EPERM on private socket
  send in this environment. It must pass outside this restriction before deployment.
- CTest full run: **14 passed, 5 failed, 1 skipped** (20 total). Failures:
  auth_production, auth_development, sleep_synthetic, output_synthetic,
  presentation_offscreen. All five reproduce on the unchanged accepted baseline
  with the same fixtures/environment. Do not interpret this as a full regression pass.
- Rust: two unit tests pass; proof integration suite 6 pass / 10 fail. The same ten
  failures reproduce on baseline; private IPC send returns Operation not permitted.
  No weakening or skipping was added to existing password tests.
- Passing native checks include controller production/development, input-owner
  lifetime, resume-input ordering, visual scales 1/1.5/2, presentation boundary,
  binary gate and preview boundary. Preview binary has no auth/Wayland capability.
- Settings schema/persistence and presentation pass. Fingerprint Settings fixture
  passes and confirms disabled enablement, state changes, duplicate/cancel semantics,
  preview files and byte-identical disposable schema15 Settings file.
- Phase 10A and Phase 10B policy/lifecycle pass. Schema was not touched. Finalization also reruns Phase 10C.1
  policy/schema/UI/Caffeine regressions. No suspend/display physical acceptance.
- QML boundary scans reject unlock/input/process capabilities and renderer security
  objects. Binary inspection rejects synthetic fingerprint symbols in owner.

Commands: build the Rust `protocol_fixture` with `cargo build --locked --offline
--example protocol_fixture`; configure native CMake with its absolute path as
`MAGI_LOCK_AUTH_FIXTURE`, `MAGI_LOCK_VISUAL_PREVIEW=ON`; build and run CTest.
Run `tests/fingerprint/run.py` with `MAGI_FINGERPRINT_PREVIEWS` for Settings captures.
Builds/logs and extra legacy lock previews live in `/tmp/magi11a-*`, outside Git.
Only the eight selected preview assets are part of this change.

## Review decisions and Phase 11B ledger (not executed)

The operator accepted the direct broker architecture and non-authoritative scope.
The 30-second/1.5-second proposed policy, per-attempt process/connection and future
opt-in/deployment criteria remain recorded for production implementation review.
Full live adapter and native production wiring remain absent. Baseline-reproduced
IPC failures are explicitly accepted as a non-blocking Phase 11A limitation, not
passing tests. A capable environment may rerun them later without sensor interaction;
production transport still requires validation before deployment.

Deferred acceptance, batched when convenient:

- Confirm T15g `06cb:00bd` identity and installed libfprint support.
- Read existing enrollment; **first verify the existing enrolled finger**.
- Only consider re-enrollment if missing/unusable, and only with explicit approval.
- Complete/review live broker, bounded asynchronous transport, peer validation,
  native global authorization, cancellation/reap and compile/deployment gate.
- Verify default-off package and explicit operator opt-in; deploy only at that gate.
- Immediate password entry during verification, timeout, busy and daemon recovery.
- Lock → valid fingerprint; mismatch → password; repeated mismatch/backoff.
- Reader missing/disconnected/busy, fprintd restart, sender/path replacement.
- Sleep/resume recovery; first scan after resume; password during recovery.
- Both racing successes with pending password child, full secret scrub, one unlock.
- Multi-output global state, topology invalidation, no per-monitor claims.
- Production package rollback and password-only recovery with enrollment preserved.
- Preserve test enrollment; delete it only if explicitly requested.

Display hardware milestone 10C.2B is separately deferred. Next roadmap after 11B:
Visual/Aesthetic Pass, theme/application polish, lock customisation, MAGI Greeter,
then deferred hardware batches. None begins here.

## Exact Phase 11A path inventory

32 reviewed files: 20 added, 12 modified, 0 deleted (relative to the accepted baseline). No package/deployment fixture,
protected-state or generated build artifact paths are included. New files are
untracked: plain `git diff --stat` lists only the modified tracked subset.

### Implementation (12)

```text
linux/magi/.config/quickshell/magi/components/settings/SettingsContent.qml
linux/magi/.config/quickshell/magi/components/settings/pages/SecurityPage.qml
linux/magi/native/lock/CMakeLists.txt
linux/magi/native/lock/fingerprint/model.cpp
linux/magi/native/lock/fingerprint/model.hpp
linux/magi/native/lock/fingerprint/session.cpp
linux/magi/native/lock/fingerprint/session.hpp
linux/magi/native/lock/qml/LockFingerprint.qml
linux/magi/native/lock/qml/LockScreen.qml
linux/magi/native/lock/src/auth_presentation.hpp
linux/magi/native/lock/src/presentation.cpp
linux/magi/native/lock/src/visual_preview.cpp
```

### Tests (7)

```text
linux/magi/native/lock/tests/binary_gate.cmake
linux/magi/native/lock/tests/fingerprint_session_test.cpp
linux/magi/native/lock/tests/fingerprint_test.cpp
linux/magi/native/lock/tests/fingerprint_transport_test.cpp
linux/magi/native/lock/tests/presentation_boundary.cmake
linux/magi/tests/fingerprint/presentation.qml
linux/magi/tests/fingerprint/run.py
```

### Docs (5)

```text
linux/magi/README.md
linux/magi/docs/README.md
linux/magi/docs/architecture.md
linux/magi/docs/decisions.md
linux/magi/docs/design/phase11a-fingerprint-groundwork.md
```

### Preview assets (8)

```text
linux/magi/docs/design/previews/phase11a/enrollment.png
linux/magi/docs/design/previews/phase11a/existing-enrollment.png
linux/magi/docs/design/previews/phase11a/fingerprint-retry.png
linux/magi/docs/design/previews/phase11a/fingerprint-unavailable.png
linux/magi/docs/design/previews/phase11a/fingerprint-waiting.png
linux/magi/docs/design/previews/phase11a/host-unknown.png
linux/magi/docs/design/previews/phase11a/no-enrollment.png
linux/magi/docs/design/previews/phase11a/unavailable.png
```

### Package/deployment fixtures (0)

None.

### Protected state (0)

None.

### Generated artifacts (0)

None.

Original worktree tracked diff was compared byte-for-byte with the initial
snapshot; protected untracked regular-file hashes also match. The initial and pre-acceptance indexes were empty; final staging is restricted
to this exact allowlist. Existing enrollment was never accessed for mutation or scanning.

## Finalization checkpoint — 2026-10-22

The operator confirmed Settings showed all changes saved before watched QML was
copied. One registered MAGI shell, `d817zobnt`, PID 1597, was recorded before and
after integration. Automatic reload logged `Reloading configuration...` at
20:26:34.350 and `Configuration Loaded` at 20:26:34.540 (host local time).
There were no new QML errors; existing Wayland text-input warnings recurred.
IPC status/open calls were denied with SocketAccessError; the operator subsequently
accepted the integrated UI/framework after the visual-review request. Bar/Hub/Control
Centre automated regressions passed; IPC health queries remain unavailable.
No shell restart or extra live shell was launched.

Final hardware-free reruns: fingerprint model/lifecycle, Settings fingerprint UI,
Settings schema/persistence/presentation, Phase 10A, Phase 10B, and Phase 10C.1
policy/schema/UI/Caffeine all passed. Lock preview/presentation/binary boundary
checks passed. Native suite remains 14 passed / 5 failed / 1 skipped; Rust proof
integration remains 6 passed / 10 failed, plus two passing unit tests. Failure
name sets were compared to untouched-baseline logs and matched exactly.
The fingerprint race test explicitly enters scanning before password wins;
malformed-result fallback also exercises immediate native password editing.

The ten baseline-reproduced Rust failures are:

```text
all_styles_batch_multiple_prompts_and_success
cancellation_bad_order_oversize_disconnect_partial_batch_cleanup
dropping_parent_worker_kills_and_reaps_stuck_child
failed_backend_and_invalid_pam_style
framing_rejects_version_truncation_size_unknown_and_nul
inherited_spawn_exit_and_secret_output_regression
prompt_limit_and_unsolicited_response
real_worker_cancelled_before_pam_start
startup_cancel_does_not_call_backend
wrong_handshake_never_calls_backend
```

Installed owner, password worker and PAM file hashes match the pre-integration
snapshot. Protected tracked/untracked file hashes match. Schema remains 15;
settings.json is excluded. Recalculated inventory: 32 paths, 20 added / 12 modified /
0 deleted, retaining the category totals above. Test logs/builds remain outside Git.
The accepted sandbox limitation does not block non-authoritative 11A finalization.
The operator explicitly accepted the UI/framework and authorized commit/push.
Phase 11A is complete. Phase 11B hardware acceptance remains deferred; no reader
verification or Visual/Aesthetic Pass was started.
