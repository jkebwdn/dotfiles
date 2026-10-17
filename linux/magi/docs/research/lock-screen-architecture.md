# MAGI Lock Screen — Phase 1 security and architecture audit

Date inspected: **2026-10-17**. Baseline: `fde3d241ae829dc3815158613dd3e1abf7ce138c`
(`magi: complete shell visual overhaul`). Status: **research complete; architecture
proposal pending operator review and native proof; no production acceptance**.

Evidence labels: **Local** means files/package metadata inspected on this machine;
**Source** means upstream code or specification inspected; **Proposal** means work
not implemented; **Gate** means evidence required before migration. References [R1–R16]
are linked in section X. No lock, PAM transaction, suspend, failure injection,
package change, service restart or compositor configuration change was performed.

## A. Executive recommendation

**Keep Hyprlock in production. Develop a separate, on-demand native MAGI locker
with Qt Quick/QML presentation, a native lock/input controller, and a small Rust
PAM worker.** This is option D below: a dedicated Qt host, not another surface in
the long-running MAGI Quickshell process. The native host owns
`ext-session-lock-v1`, every output surface, credential entry, and the canonical
lock state. QML receives sanitized presentation state, never raw credentials or
an unlock capability. The worker performs PAM conversations; only its successful
result for the current attempt can authorize the host to unlock.

This is a **provisional implementation direction**, not a claim that a suitable
MAGI native host already exists. The Qt Wayland integration and native input path
must first be demonstrated. Do not build production UI around an unproven bridge.
A hardened upstream Quickshell solution could reduce implementation cost and
should be reconsidered at Phase 2 if it meets the same invariants.

Why not simply use the installed Quickshell lock example?

- Quickshell **does** implement the real protocol, per-output surfaces and confirmed
  lock state. There is no justification for a fullscreen/layer-shell imitation.
- In v0.3.1, `WlSessionLock::updateSurfaces()` calls `unlock()` when the surface
  component does not instantiate the required type. `onScreensChanged()` calls
  this while locked. Source therefore contains a potential **fail-open error
  path**, distinct from the documented fail-secure process-crash behaviour.
  Reachability with a particular QML component must be tested; this audit did
  not reproduce it on the live session. Current upstream still has that branch.
- Its normal PAM interface accepts a `QString` from QML, and its lock object has
  a writable `locked` property. A separate PAM executable alone does not move
  either credential capture or unlock authority out of QML.
- Keeping the locker separate avoids shell reloads, service activation, Settings
  writes, clipboard models, notifications and general shell IPC in the lock's
  normal execution path. It does **not** sandbox mutually trusted code in the
  lock process or defeat arbitrary code already running as the session user.

**Rust is recommended narrowly for the PAM worker and bounded IPC parsing**, not
for replacing MAGI or its Qt rendering. It improves ownership and cleanup of
worker-owned secret buffers; it cannot erase Qt, kernel or PAM-module copies.
A carefully reviewed C++ worker remains viable if adding a Rust toolchain costs
more than these benefits. No Cargo project or dependency has been created.

**Decision record remains pending.** Native host feasibility, exact credential
capture and installed-compositor acceptance are material uncertainties; this
phase does not append a settled decision to `decisions.md`.

## B. Current local system audit

Read `AGENTS.md`, documentation index, MAGI README, architecture, decisions and
Quickshell reference, then the relevant current source. Historical documentation
contains earlier milestones; the accepted Phase 2E generation and current source
are authoritative. The user-authorized two-path write limit overrides broader
documentation-maintenance guidance. Only this research document is changed.

### Installed evidence and limits

| Component | Local result | Meaning / limitation |
| --- | --- | --- |
| Hyprland | `0.56.2-4` | Installed Arch package; tagged upstream v0.56.2 examined. Not a verified running-build hash. |
| Quickshell | `0.3.1-1`; CLI reports 0.3.1, empty revision, Arch distribution | Installed QML metadata confirms compiled lock and PAM interfaces. |
| Qt | base `6.11.2-3`, declarative `6.11.2-2`, Wayland `6.11.2-1` | Native integration must target this combination; private Qt Wayland APIs are an upgrade risk. |
| Hyprlock / Hypridle | `0.9.6-3` / `0.1.8-2` | Working operator baseline; source reviewed at matching upstream releases. |
| Wayland / protocols | `1.26.0-1` / `1.49-1` | Installed XML is staging `ext-session-lock-v1`, interface version 1. |
| Hyprland protocols | `0.7.0.r1.g3f3860b-1` | Lock-notify support is relevant to suspend integration. |
| PAM / pambase | `1.7.3-1` / `20260616-1` | Existing policy includes faillock; no authentication exercised. |
| fprintd | `1.94.5-2`; `pam_fprintd.so` exists | Availability is not proof of enrolled/working biometric authentication. |
| Tools | GCC 16.2.1, CMake 4.4.4, Ninja 1.13.2, pkgconf 3.0.7, libxkbcommon 1.13.2 | Rust/Cargo packages and commands were not found; wayland-info command absent. |

`hyprctl version` failed with `Couldn't set socket timeout (2)`. Consequently no
live registry, monitor inventory, effective compositor options or active process
version is certified here. Configuration observations below are read-only file
evidence, not a fresh native runtime test. No disruptive probe was used to fill
that gap. Local copies of all three Hyprland/Hypridle/Hyprlock files compare
byte-for-byte equal to the corresponding `~/.config/hypr/` files.

### Existing routing and behaviour

`linux/t15g/hypr/.config/hypr/hyprland.lua` starts hyprpolkitagent, hyprpaper,
hypridle, hyprmon and `quickshell -c magi`. It configures eDP-1 at 3840×2160,
scale 2, and HDMI-A-1 at 3840×2160, scale 1.5. These are configured outputs,
not a statement that both are connected. Keyboard layout is `gb`.

Current Hypridle configuration:

| Trigger | Exact current command |
| --- | --- |
| logind Lock event | `pidof hyprlock || hyprlock` |
| Before sleep | `loginctl lock-session` |
| After sleep | `hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'` |
| 300 seconds idle | `loginctl lock-session` |
| 600 seconds idle | `hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'` |
| Resume from that idle listener | `hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'` |

No `unlock_cmd` or explicit `inhibit_sleep` is configured. Source v0.1.8 defaults
to auto mode 2 and recognizes the current command strings as lock-notify mode
**if** the compositor advertises the notifier. This condition was not queried
live. See N for the migration trap.

Hyprlock configuration: grace 0, hidden cursor, immediate rendering, failure
feedback timeout 1500 ms; blurred screenshot background, clock/date, password
field and fingerprint prompt across unspecified/all monitors; fixed footer.
PAM service is `hyprlock`; direct fingerprint backend is enabled with a 250 ms
retry delay. That retry delay and visual failure timeout are not PAM rate limits.
Configured screenshot blur is not a strong privacy boundary.

`/etc/pam.d/hyprlock` contains only `auth include login`. The includes traverse
`login` → `system-local-login` → `system-login` → `system-auth`; auth includes
nologin/shell policy, pam_unix, optional systemd-home, pam_env and pam_faillock.
No fingerprint module was present in this inspected include chain: Hyprlock's
configured direct fprintd backend is separate. `faillock.conf` had no active
noncomment settings; effective module defaults and any other policy must be
verified before auth testing. No shadow, password hash or enrollment data read.

Manual routes: `modules/ControlCatalog.qml` reads the Settings schema catalogue;
system actions call `QuickActions.execute()`, whose Python `system_actions.py`
maps Lock to `loginctl lock-session`. Its availability check only finds loginctl;
it does not establish that a locker is working. Hibernate, shutdown and reboot
map to systemctl with capability/confirmation handling. There is no dedicated
manual lock binding in the inspected Hyprland Lua file. Super+L is layout
preselection, not Lock. Super+Shift+Q exits the compositor; launcher/Hub/CC binds
are ordinary binds. Volume/mute and display brightness explicitly have
`locked = true`. Their continued availability is existing compositor policy.

### MAGI presentation resources

| Existing source/resource | Reuse proposal and boundary |
| --- | --- |
| `shell.qml`, `components/bar/Bar.qml`, `HubWindow`, `ToastHost` | ShellRoot starts Notifications, Clipboard, ThemeOrchestrator, Wallpaper, Weather. Bar/Hub are ordinary shell surfaces, not lock surfaces. Do not import this root into the locker. |
| `theme/Theme.qml`, `ThemeRegistry.qml`, palette data, RenderTokens | Reuse semantic colours/radius calculations through a validated, read-only snapshot or pure module. Theme currently imports Settings; importing it wholesale can instantiate services. |
| `services/Settings.qml`, `settings/SettingsStore.qml` | Existing single writer, Python persistence, backups and schema 12 stay outside the locker. Locker reads only allowlisted presentation data; malformed data uses built-in defaults. |
| `ProfileHeader.qml`, `AssetManager.qml`, `assets.py` | Existing explicit display name/custom subtitle and managed avatar. Avatar ID resolves into `~/.local/share/magi/avatars/`; the configured PNG exists (225587 bytes). Do not treat display name as PAM identity. Do not copy operator identity/location into this report unnecessarily. |
| `services/Weather.qml` | Opt-in configured location, helper/cache, 30-minute refresh and three-hour stale cutoff. Reuse only sanitized cached summary if separately opted in; never make lock readiness depend on network. |
| `services/Media.qml`, `MediaController.qml` | MPRIS selection, capability checks and artwork cache exist; polling references MenuController. Reuse bounded adapters/data, not the whole service dependency graph. |
| ClockState, Battery, Wallpaper | Local time/date and coarse battery state are candidates. Wallpaper is a validated static asset, not a screenshot or live desktop dependency. |

## C. ext-session-lock-v1 findings

The installed wayland-protocols XML [R1], matched against upstream protocol
publication, remains the relevant protocol; no replacement was found. It is
staging version 1. “Privileged client” in the specification describes compositor
policy, not a requirement for a Unix-root locker.

1. A client binds `ext_session_lock_manager_v1` and issues `lock()`. The returned
   lock object receives `locked` or `finished`. Sending the request, having a PID,
   drawing a fullscreen window, or setting logind's LockedHint is not readiness.
2. `locked` is the security barrier: normal clients no longer receive protected
   input or have normal content visible; a protected frame must have appeared
   on every output. The compositor can show an opaque fallback while waiting
   for client graphics. Special privileged surfaces are compositor policy.
3. Create one role-specific `wl_surface` per output, including newly advertised
   outputs. The surface must have no previous role, committed content or buffer.
   A second lock surface for the same output is an error.
4. Wait for initial configure; acknowledge its serial before buffer commit. Meet
   exact surface-local dimensions, with scale/transform handled correctly. Newer
   configures can supersede older ones; never acknowledge an already-consumed
   serial or submit a null buffer. Reconfigure on output geometry changes.
5. After successful authentication the owner sends `unlock_and_destroy`, then
   destroys remaining surfaces. Before exiting, wait for a display sync so the
   compositor has processed the request. There is no separate protocol
   “authentication passed” event or “unlocked” acknowledgement.
6. Before `locked`, ordinary `destroy` disposes the object. After `locked`, that
   request is invalid; it is **not** a legitimate error-cleanup unlock. If the
   client dies, the compositor must remain locked. Losing/removing a lock surface
   on an active output must leave that output covered by compositor fallback.
7. `finished` can mean initial refusal or later compositor-directed retirement.
   Record whether `locked` was received and follow the corresponding destructor
   rules; never interpret `finished` as a successful PAM result.
8. Lock objects/surface references belong to their Wayland client connection.
   A helper cannot give an ordinary separate Quickshell connection the right to
   render onto its lock simply by passing an object ID over a socket. Sharing
   one connection between independent Qt and Rust dispatch loops is also not a
   supported composition design. A renderer bridge or an embedded QML engine is
   necessary for a native protocol owner.

The protocol delegates authentication entirely to the client. It neither checks
PAM nor prevents a compromised lock owner from unlocking. It permits compositor
recovery policy and does not mandate that only the original client can ever
unlock. Hyprland has native `forceUnlock()` and configurable restore behaviour;
these are part of the compositor trust boundary, not MAGI auth capabilities.

**Hyprland source** [R4]: `CSessionLockProtocol` retains `m_locked` when a client
resource dies; `CSessionLockManager` discards its client/surfaces but does not
clear that protocol flag. `IHyprRenderer::renderLockscreen()` supplies an opaque
primer/missing-lock presentation. The manager tracks rendered outputs and sends
`locked` when covered; it also has a five-second fallback timer and a no-active-
outputs path. Validate actual frame presentation, DPMS, hotplug and timer races
on the installed build rather than equating source inspection with certification.

`misc:session_lock_xray`, above-lock layer rules, privileged input methods,
restore policy and compositor control access affect the guarantee. None was
explicitly enabled in the inspected Lua file; effective settings are unverified.
Production acceptance requires xray off and no untrusted above-lock exceptions.

## D. Quickshell capability assessment

Installed metadata:

- `/usr/lib/qt6/qml/Quickshell/Wayland/quickshell-wayland.qmltypes` exports
  `WlSessionLock` and `WlSessionLockSurface` through `Quickshell.Wayland`.
- `WlSessionLock`: writable `locked`, read-only `secure`, component `surface`,
  lock/secure change signals. `secure` corresponds to compositor confirmation;
  `locked` alone must not authorize suspend.
- `WlSessionLockSurface`: native QQuickWindow-backed lock surface with read-only
  screen, size, visibility and contentItem, plus configurable colour/content.
- `Quickshell.Services.Pam` exports `PamContext`, `PamResult`, `PamError`.
  Context exposes start/abort/respond(QString), active, user, config/directory,
  message/error/response-required/response-visible and completion signals.

Tagged implementation [R2–R3] verifies native protocol use, QGuiApplication
screen-added/removed/primary-change handling, configure acknowledgement and exact
resizing. These are real per-output lock surfaces; PanelWindow keyboard grabs
and HyprlandFocusGrab are neither needed nor equivalent. Keyboard focus between
lock surfaces remains compositor-mediated. QML item focus, layout/Caps state,
touch and multi-seat delivery still require native tests.

Two critical distinctions:

- Process death after confirmation normally leaves a conformant compositor
  locked. However `updateSurfaces()` → invalid component → `unlock()` is a
  deliberate unlock path on a construction failure. A valid static component
  lowers its likelihood but is not a security proof. Reload transfers managers
  and windows; disable production hot reload and test reload attempts anyway.
- PamContext already uses a **forked PAM subprocess and pipes**, not merely a
  blocking QML call. It supports multiple conversation messages. Its frontend
  still converts QString responses to std::string and the subprocess duplicates
  strings for PAM; no end-to-end secret wiping guarantee follows. It invokes
  pam_authenticate, not an application-specific account policy.

The v0.3.1 native lock adapter uses private Qt Wayland integration, with explicit
version branches for Qt <6.9, 6.9 and >=6.10. Installed 6.11.2 uses the latter.
Current upstream changes some realization/reload bookkeeping but retains the
invalid-component unlock branch. It is not evidence that a package upgrade
alone fixes the issue. **Stock installed Quickshell is not accepted unchanged
for MAGI's requested failure and credential invariants.** No fake-lock fallback.

## E. Bounded implementation comparison

Source versions and exact paths are in X; no project code/assets were copied.
This is a pattern comparison, not a complete security audit of these projects.

| Project / pattern | Benefit | Downside / MAGI disposition |
| --- | --- | --- |
| Hyprlock: native protocol owner, output objects, configure/scale handling; `acquireSessionLock`, `releaseSessionLock`, `onLockLocked` | Established compositor-targeted lifecycle; waits for lock event before ordinary release; roundtrip after unlock | **Adapt** lifecycle and native output test cases, not its renderer/dependency stack. |
| Hyprlock: CPam thread and condition-variable prompt exchange | Rendering stays responsive; repeated prompt requests possible | Native std::string copies and shared address space; blocking module/thread termination concerns. **Adapt** conversation semantics into a killable process. |
| Hyprlock: separate fprintd backend and suspend tracking | Independent biometric UX alongside password | Additional authorization route/DBus lifecycle; not equivalent to PAM stack fingerprint. **Defer**, prefer PAM extensibility first. |
| Hyprlock: SIGUSR1 enqueues unlock; optional grace | Convenient operator control | **Reject** both for MAGI. Grace is locally zero but SIGUSR1 exists in examined code. Same-user malware is outside its strong guarantees. |
| swaylock: native ext lock, per-output surfaces, `--ready-fd` after `locked` | Small core, useful explicit readiness contract | Minimal graphics compared with MAGI. **Adopt** readiness semantics and output lifetime discipline. |
| swaylock: unprivileged PAM subprocess, private pipes, bounded/locked password buffer, explicit clearing | Auth crash isolated; parent detects pipe failure; reduces secret lifetime | PAM conversation supplies a submitted password once and aborts further prompt requests; unsuitable as MAGI's general multi-prompt design. **Adapt** process/buffer pattern; **reject** one-password assumption. |
| swaylock: single validation in flight, XKB modifiers/layout and Caps feedback | Deterministic input and no overlapping password checks | Visual timers are not canonical account rate limits. **Adopt** native gating and indicators; retain PAM policy. |
| swaylock: backend failure exits without ordinary release; SIGUSR1 exits display loop into unlock | Fail-secure backend crash; convenient remote control | **Adopt** crash semantics; **reject** signal-to-unlock route. Audit all normal-exit paths in MAGI. |
| gtklock: gtk-session-lock abstraction and per-window presentation; PAM fork and message pipes | Demonstrates toolkit presentation can use real protocol; separates blocking auth | Adds GTK stack, module hooks and password-string frontend; callback reuses supplied password across prompts. **Adapt** toolkit separation idea; **reject** plugin loading and generic password forwarding in locker. |
| gtklock: shutdown calls unlock; SIGUSR1 quits application | Convenient lifecycle | **Reject** generic quit/shutdown authorizing unlock. MAGI must distinguish authenticated release from failure/termination. |
| Quickshell: per-output QML template and forked PAM conversation | Existing local dependencies and flexible UI | Construction-failure unlock and QString input route require native hardening. **Reject as-is**, retain as potential upstream-backed alternative. |

All use compositor protection for lock-client death; none can preserve a vanished
compositor's security state. Hotplug, resume and keyboard handling are not proven
for MAGI by their existence upstream. Hyprlock's installed release and current
PAM source differ in cancellation/allocation cleanup; do not transplant older
code. Privilege-free PAM builds use system helpers where required, not a new
custom root authenticator.

## F. Threat model and trust assumptions

Assets: desktop confidentiality, protected input, authentication responses,
correct unlock authorization, availability of a recoverable locked session.
Trusted base: kernel, compositor and its configuration/control channels, Qt/native
locker code, packaged QML, PAM libraries/modules and policy, auth worker and its
launch path. QML is trusted in-process code; reducing its API is defence against
mistakes, **not a sandbox against hostile JavaScript/native plugins**.

| Threat | Required defence / residual limit |
| --- | --- |
| Ordinary Wayland client overlays, focus/workspace changes or steals keyboard/pointer | Compositor session lock, no privileged above-lock rules; native tests of shortcuts, Xwayland, touch and focus. Layer-shell opacity is not a defence. |
| UI error/crash; renderer/GPU failure | Native opaque fallback or process disconnect retaining compositor lock; never cleanup by unlock. Availability may require TTY intervention. |
| PAM worker crash/kill/hang | Invalidate attempt, wipe input, remain locked; bounded restart with a new private channel. No exit-code-only authentication. |
| Main MAGI crash/reload | Separate lock process and immutable presentation snapshot; no ownership in ShellRoot or main service cgroup. |
| Compositor restart/crash | Protocol cannot survive it. Session startup/greeter/VT policy must prevent returning to an unprotected desktop; audit separately. Never describe this as guaranteed fail-secure. |
| Output add/remove/primary change, all outputs off | Compositor coverage first; native surface registry independent of auth; no unlock transitions from topology. |
| Suspend/resume race | Confirmed lock plus lock-notify integration; test deadline exhaustion. DPMS is not a lock. Cancel stale auth across sleep. |
| VT switching | Outside Wayland lock control; another logged-in VT may already expose the account. Require operator session/TTY policy. Never disable VT recovery casually. |
| Malicious same-UID code, compositor IPC, modified config/binary, ptrace, injected libraries | Session lock is not a security boundary against arbitrary code with the user's ambient authority. Fixed executable/config paths, non-dumpability and private FDs reduce attack surface; no absolute claim. Root/kernel compromise is out of scope. |
| Untrusted MPRIS/notification/artwork payload | Off by default; bounded plain text, no markup/actions/URLs in privileged paths, validated assets only. |
| Credential memory/logs/QML inspection | Native entry, no raw QML properties/signals, short-lived buffers, no logging/persistence, core-dump controls; Qt/PAM/kernel residuals remain. |
| Shell IPC or remote controls request unlock | No unlock verb, signal or DBus action. Lock request/status only. Compositor administration remains separate trusted authority. |
| Replay/stale result, cancelled result, repeated/concurrent auth | Attempt generation + lock generation + prompt sequence on private IPC, one in flight, consume success once and only in current locked state. |
| Brute force / retry storms | Native cooldown plus PAM policy; do not restart workers to bypass PAM_MAXTRIES or faillock. Local same-user code may invoke PAM separately. |
| Multi-message PAM, timeout/cancel | Full conversation array handling and bounded resources; cancel cannot unlock; kill hung worker after grace, invalidate results first. |
| Screencopy/remote desktop/virtual input | Protocol is not a universal capture or remote-access policy. Audit compositor capture, portals, privileged input and control interfaces separately under lock. |

The physical unattended-console adversary and ordinary unprivileged Wayland
clients are the main protection target. An attacker can still cause denial of
service. Enabling compositor lock restoration can allow a replacement client to
become the trusted owner; do not turn it on automatically for convenience.

## G. PAM authentication architecture

**Proposal:** use a future dedicated, administrator-owned `/etc/pam.d/magi-lock`
policy, reviewed for this Arch installation. Do not install it through Stow or
write it in Phase 1. Pin the service name and `/etc/pam.d`; never accept a service,
config directory, username or PAM module path from QML, Settings or public IPC.
Resolve the real current UID via the system account database; after successful
PAM, ensure any canonicalized PAM_USER still maps to the intended UID.

For a deliberate Phase 3 compatibility experiment, existing `hyprlock` auth
policy can be reused unchanged. This is a temporary dependency, not permission
to modify it or assume every machine has it. Missing policy is a fatal auth
configuration error; **no fallback to login, su, pam_permit or a user-writable
PAM file**. Current Quickshell defaults to login and Hyprlock has a missing-service
fallback; neither is the desired MAGI policy.

Production proposal is `pam_start` → `pam_authenticate` → reviewed
`pam_acct_mgmt` → `pam_end`. Dedicated policy should include appropriate existing
auth/account stacks rather than duplicating password validation. Account expiry,
access restrictions and `PAM_NEW_AUTHTOK_REQD` require deliberate policy: fail
closed with recovery guidance, no password-changing wizard in initial locker.
This differs from the examined lockers' auth-only behaviour and can prevent
unlocking an expired account; test it explicitly before adopting the template.
Do not call pam_open_session/pam_close_session: this is an existing login session.
Credential refresh via pam_setcred is module/policy-dependent, not an unconditional
new login or privilege acquisition. Reject empty-token authentication using the
appropriate PAM flag and tested local policy, rather than relying on UI checks.

Conversation requirements [R8]: handle an array of messages and repeated callbacks,
not one fixed “Password” string. Support ECHO_OFF, ECHO_ON, TEXT_INFO and ERROR_MSG;
responses preserve order with zero resp_retcode and correct C allocation/free
ownership. A prompt ID is answered once. Display bounded sanitized text; never
parse English prompt text to choose an authentication algorithm. Unknown styles,
invalid sizes, allocation failures and malformed IPC abort the transaction.
Do not send the same saved password into subsequent OTP or username prompts.

Use a fresh worker transaction for each deliberate attempt; one attempt at a time.
PAM's response allocations may be retained/copied by modules and are not fully
controlled by Rust. Clean up our allocations on every partial-error path. A
worker normally calls pam_end; forced cancellation of a wedged module cannot
promise module cleanup. Close the channel and invalidate authorization before
terminating/reaping it. No asynchronous thread cancellation inside PAM.

Failure policy: native monotonic cooldown of at least two seconds after a failed
attempt (proposal), without shortening any PAM delay. Fixed delay is predictable;
unbounded exponential backoff adds avoidable denial of service. PAM faillock/
MAXTRIES remains canonical; MAXTRIES enters a blocked-auth state without an
automatic retry loop. A new manual attempt must respect policy recovery and not
reset counters. Distinguish unavailable auth from a wrong response without
printing raw PAM conversations in logs. Cancel/timeout may still affect PAM
failure accounting; never promise that cancellation is consequence-free.

Initial prompt inactivity timeout proposal: 60 seconds, plus a bounded overall
transaction timeout appropriate to the reviewed modules (initially 120 seconds).
A blocked module is terminated after a short cleanup grace. These are engineering
limits to test, not PAM defaults; biometric/network stacks may require revision.

Future fingerprint support should follow PAM conversation semantics and module
policy, including informational prompts and asynchronous device waits. Installed
fprintd does not mean the current auth stack includes pam_fprintd. Sequential PAM
password/fingerprint flows do not automatically provide simultaneous OR races.
No direct fprintd success bypass in MAGI Phase 1–initial production.

## H. Credential-handling rules

1. No secrets in Settings, JSON state, backups, environment, command arguments,
   logs, journal messages, crash reports, clipboard, files, screenshot fixtures,
   generic Qt debug output, accessibility text or QML/JS properties/signals.
2. Native entry consumes key events before QML event handlers. QML sees only
   prompt type, fixed/bounded masking feedback, busy/cooldown and sanitized status.
   No TextInput/TextField `text` bridge, `Keys.onPressed` forwarding raw text, or
   generic `respond(password)` invokable. Disable paste, primary selection,
   drag/drop, undo history, external input methods and password reveal initially.
3. Native entry stores bounded bytes in a dedicated buffer; reject embedded NUL,
   invalid encodings and overlength input explicitly, never silently truncate.
   Installed PAM headers define PAM_MAX_RESP_SIZE=512; initial maximum is
   **511 UTF-8 bytes plus terminator**, validated against the selected modules.
   Limits must apply in both host and worker, not only in the visual component.
4. Wipe used and spare buffer capacity on submission, cancel, failure, inactivity,
   output-focus transfer, sleep, auth completion and normal shutdown. Avoid
   reallocations, clones, formatting and secret-bearing exceptions. Use explicit
   clearing in C++ and `Zeroizing`/zeroize in Rust-owned storage.
5. Use non-dumpable processes, disable core dumps, and dedicated mlock-backed
   secret storage where supported. Missing memory-lock protection must be visible
   as a deployment issue; do not silently claim protected memory. Avoid a blanket
   privilege or sandbox setting that breaks standard PAM helpers.
6. Private IPC still copies bytes into kernel buffers and the worker. PAM expects
   C response allocations; cleanup/zeroization guarantees end where ownership is
   transferred to PAM. Do not promise overwriting all RAM, swap or hibernation
   images. These require system-level policy beyond this locker.
7. Qt keyboard events can transiently contain QString data before native capture.
   QString implicit sharing, conversions and QML garbage collection do not offer
   reliable whole-history zeroization. “QML never sees raw password” means no
   raw secret reaches the QML API, not that Qt never sees individual characters.
   Native event capture/filtering is a required proof, not yet implemented.
8. Python immutable strings and JSON/stdout adapters cannot meet this credential
   boundary; retain Python for unrelated MAGI services only. Rust also cannot
   guarantee wiping on SIGKILL, abort or power loss, nor erase library copies.

## I. QML versus native responsibility boundary

| Layer | Responsibilities | Prohibited capabilities |
| --- | --- | --- |
| Main MAGI Quickshell | Request lock through existing routing; optional read-only status; continue normal shell services behind compositor protection | Own lock, relay credentials, receive auth success tokens, unlock or change PAM policy |
| Locker QML | Theme/layout, clock, safe profile assets, plain prompt/status, request focus/submit/cancel intents | Raw credentials, writable security state, session-lock object, arbitrary commands, generic DBus/IPC unlock, loading shell plugins |
| Native Qt locker controller | ext lock connection/objects, per-output surface roles, input capture, secret entry buffer, canonical state, attempt validation, readiness, authenticated unlock and sync | Unlock on visual destruction, user cancel, signal, timeout, missing UI, worker failure or shell exit |
| Rust PAM worker | Real-UID identity, fixed PAM service, conversation, bounded secret response handling, auth/account result | Wayland connection, output control, executing UI commands, deciding compositor unlock itself |

Native host embeds QML rather than trying to put independent Quickshell windows
above native lock surfaces. A Qt Wayland adapter on the host's **same** display
connection must establish the correct surface role before Qt commits. Prototype
its configure, resize and null-buffer behaviour first. Reusing audited upstream
ideas is sensible; linking undocumented Quickshell private classes as a stable
SDK is not assumed to work. No native Qt host is present in MAGI today.

The native controller retains opaque fallback surfaces if a QML component fails.
It can replace presentation while preserving lock ownership; if that cannot be
done safely it disconnects/exits without unlock. Presentation errors cannot call
the authenticated release function. No live-reload or arbitrary plugin import
path in production. Build a small static QML bundle with a narrow native facade.
This reduces accidental authority but same-process QML/native code remains TCB.

## J. Architecture options and Rust assessment

| Option | Boundary / crash behaviour | IPC / multi-output / flexibility | Cost and judgement |
| --- | --- | --- | --- |
| A: Quickshell owns lock, native PAM helper | Separate dedicated QS process preferable to main shell; compositor protects process death. Stock construction-failure unlock and QML credential entry remain | Private pipes feasible, native secret input plugin additionally needed; QS handles screens; full QML flexibility | Lowest protocol cost but requires audited upstream hardening and native auth/input gate. **Reject stock A; reconsider hardened A at Phase 2.** Rust helper alone does not fix it. |
| B: Rust native helper owns protocol and PAM; separate QS presents | Owner can survive renderer death, but renderer cannot attach ordinary windows to another client's lock objects | Needs offscreen frames/dmabuf bridge, native input routing or nested compositor; all outputs handled natively | High attack surface, dependencies and test burden. **Reject** cross-process Quickshell renderer for first implementation; not a “small helper”. |
| C: Quickshell lock + PamContext | Native PAM subprocess already exists, but QML controls release and handles QString responses; same lock error path | Minimal extra IPC code/dependencies; rich QML; screens built in | Best convenience, insufficient requested credential/failure separation unchanged. **Reject for production**, not a claim PamContext is fake PAM. |
| D: dedicated native Qt Quick host + private PAM worker | Native state and secret input outside QML; host crash stays compositor-locked; PAM crash leaves host alive | Embed QML in owner; one connection/surface per output; narrow private worker channel; preserve MAGI appearance through data | More native Qt work and testing than A, far less bridging than B. **Recommended provisional direction** with feasibility gate before UI work. |
| Established locker retained/themed | Already operational | Existing multi-output/auth paths; limited first-party integration | **Production choice now and fallback throughout.** Does not satisfy eventual first-party ownership by itself. |

Rust adds memory-safe protocol parsing, explicit ownership and useful secret
cleanup helpers to a small auth process. It does not make PAM modules memory-safe,
provide OS privilege separation from same-UID code, or solve native Qt input.
Keep FFI small, pin/review dependencies and handle panic/EOF as failure. Candidate
`pam-client` offers a conversation interface; audit allocation and copying before
selection. Avoid a convenience API that holds reusable username/password strings.
A small reviewed libpam FFI is an alternative, with a larger explicit unsafe-code
review burden. `zeroize` helps owned buffers, not all historic copies.

Rust Wayland crates are credible if a native non-Qt locker is later selected,
but implementing protocol, renderer, text input and QML transport together would
violate the intended small-helper scope. No Rust rewrite of MAGI is proposed.

## K. Process, IPC, authorization and privilege model

Proposed process tree (names are placeholders, not commands installed now):

```text
Hypridle / deliberate test launcher
  └─ magi-lock (ordinary session UID; native Qt host; owns Wayland lock)
       └─ magi-lock-auth (same UID; exec-created worker; fixed PAM service)
Main MAGI Quickshell remains a separate process.
```

Prefer on-demand host and per-attempt exec-created worker. Exec avoids running
complex PAM code in a forked multithreaded Qt image. No always-running root daemon,
setuid MAGI binary, or PAM session creation. System PAM may invoke its existing
privileged helper; do not replace it or assume all policies work unprivileged.
Local unix_chkpwd exists with special mode bits; ownership shown inside this
execution environment is not a host privilege audit. Native acceptance must
verify standard PAM helper operation under the actual login UID.

Create a Unix `socketpair` (or two anonymous pipes) before exec; only intended
ends survive exec. Use a private inherited descriptor, no filesystem listener,
no D-Bus authentication service and no stdout JSON. The host launches a fixed
worker executable with a constrained environment, verifies the intended child
and uses its private channel. Same UID from SO_PEERCRED alone is not proof of an
authorized peer: arbitrary user-session clients share that UID. FD inheritance
and trusted launch are the capability; optional peer credentials/PID checks are
additional checks, not the sole authorization mechanism. Close unrelated FDs;
do not leak the Wayland connection into the auth worker.

Versioned bounded binary messages: Begin(lock-generation, attempt-id), Prompt
(prompt-id, style, bounded sanitized text), native Response(prompt-id, length,
bytes), Cancel, Result(attempt-id, success/failure/error). Include lock generation
in result validation. Bound message sizes, prompt counts, total traffic and time;
handle short reads/writes, EINTR, EOF, unknown types and duplicates. No generic
object serialization or client-supplied command/service strings. Results are
accepted only from the current child/channel while the host remains securely
locked in that uncancelled attempt. A fresh lock invalidates all old results.

Only native code calls protocol unlock after matching success, identity/account
checks and one-time consumption. Exit status 0, worker startup, displayed success,
DBus Unlock, SIGUSR1 and QML completion signals are never authorization.
Signals terminate without release; do not inherit Hyprlock/swaylock convenience
unlock signals. Drop results received after cancel/suspend/topology invalidation.

Duplicate lock requests must be idempotent. A future request/status endpoint,
if needed for readiness, has a private XDG_RUNTIME_DIR directory (0700) and socket
(0600), checks peer credentials and exposes **request-lock/status only**. A forged
status response must not authorize suspend: readiness comes from the owner or
trusted compositor lock notification, tied to the exact live attempt. No generic
`unlock()` endpoint, even for same-user callers. No remote automation exemption.

Worker failure: close/reap, invalidate generation, preserve host lock and retry
cooldown; restart only on deliberate retry. Host failure: no automatic claim
that a new process owns the old lock; compositor recovery policy governs it.
Shell restart has no auth/lock effect. Optional future systemd --user unit can
supervise a per-lock host, with readiness tied to compositor confirmation, but
must not bind its lifetime to MAGI ShellRoot or auto-restart into an unlock path.
Do not use ExecStop to unlock. Avoid hardening settings such as NoNewPrivileges
without checking compatibility with the selected standard PAM helper stack.

## L. Multi-monitor design and input requirements

One lock surface per advertised output, opaque from its first valid buffer.
Native registry owns these independent of QML and the authentication attempt.
Every output remains secured even if it has no UI, is waking or is newly attached;
compositor blanking supplies protection before the client draws. MAGI cannot
repair a compositor that exposes desktop frames during hotplug: that is a release
blocker. Never create an ordinary-window placeholder.

Initial auth UI: focused output if identifiable, otherwise configured preferred
output, then deterministic available output. Secondary outputs show opaque
background and optional clock/coarse locked status. One active credential entry
and one PAM attempt globally. Clicking/touching another lock output may transfer
the auth UI; clear entry and cancel the attempt before transfer. Output removal
moves idle auth to a surviving screen after invalidating input; removal of the
last screen keeps the lock and clears credentials. Primary changes do not unlock
or duplicate authentication. A later alternative may keep auth status on all
outputs but must not create concurrent password buffers.

Requirements for native entry:

- Layout and Caps Lock from the actual seat/XKB state; configured `gb` alone is
  insufficient. Num Lock indication when relevant to keypad use. Test multiple
  layouts, compose/dead keys and UTF-8 byte limits; do not normalize passwords.
- Enter submits the current prompt once; repeats while pending are ignored.
  Escape clears/cancels auth and returns to LockedIdle, never Unlocked.
- No reveal, paste, clipboard selection, context menu, undo or external IME in v1.
  Native input must preserve ordinary physical keyboard layouts; accessibility
  and on-screen keyboard support need a separately reviewed secure design.
- Pointer/touch can focus/submit/cancel but not bypass the native gate. Focus loss
  clears input; window focus changes cannot release the lock.
- Consume the wake-only key/touch when waking a powered-off display, then accept
  deliberate input; test timing so it cannot submit stale credentials. There is
  no grace-to-unlock window. Auth remains bound to its seat/output generation.
- Test modifier release across lock acquisition, keyboard unplug/replug, output
  scale 2 and 1.5, rotation and seat changes. Do not promise multi-seat support
  until it is implemented and accepted.

## M. Canonical lock/auth state machine

The native owner holds canonical state. QML is a read-only projection. Separate
lock ownership from auth substate so auth failure never implies unlocked state.

| State / event | Native transition and invariant |
| --- | --- |
| Unlocked + request | AcquiringLock; establish native protocol objects and opaque surfaces. No readiness yet. |
| AcquiringLock + `locked` | LockedIdle; publish readiness exactly once for this generation. |
| AcquiringLock + `finished` / unsupported / timeout | AcquisitionFailed; never report success. Pre-acquisition fallback only after establishing there is no owned lock. Unknown ownership stays conservative. |
| LockedIdle + deliberate auth input | Authenticating with new worker/attempt. Prompt substates allow multiple sequential responses. |
| Authenticating + failure | AuthFailed/Cooldown within Locked; wipe entry, retain protocol ownership, enforce delay. |
| Cooldown elapsed + deliberate retry | New Authenticating attempt; no automatic loop. MAXTRIES remains blocked by PAM policy. |
| Any auth + Escape / timeout | Cancelled → LockedIdle after invalidating attempt and cleanup; no unlock. |
| Authenticating + validated success | Unlocking; wipe secrets, consume authorization, send unlock_and_destroy, wait display sync. |
| Unlocking + sync completed | Unlocked; destroy surfaces/process. No fade exposing desktop before authorization. |
| Any locked state + worker EOF/crash/malformed frame | HelperFailed (still Locked); invalidate result and offer deliberate retry if policy allows. |
| Any locked state + QML/render failure | Native fallback (still Locked), or disconnect without release. |
| Any state + compositor disconnect | CompositorDisconnected; clear credentials and stop. Do not label the new session locked or unlocked based on the dead connection. |
| OutputAdded/Removed/primary change | Topology side transition; create/remove only lock surfaces, cancel affected auth, stay Locked. |
| Suspend | Clear input/cancel auth, retain lock; permit app-initiated suspend only after confirmed lock. |
| Resume | Stay Locked, refresh seat/output state, require a fresh deliberate attempt. |
| `finished` after `locked` | CompositorRetired; invalidate auth and use protocol-required disposal. This is not PAM success. Investigate external recovery/unlock policy. |

Do not send unlock while merely AcquiringLock. For cancellation after a request
but before the outcome, resolve protocol state rather than racing a destroy
against a queued `locked`. Error handling must never share a generic destructor
that performs authenticated release. A transport failure after sending unlock
has an uncertain final state; do not replay a saved success into a new connection.

## N. Hypridle, suspend and manual routing migration boundary

Keep all current routes and files unchanged now. Future production boundary:
**change the locker launched by Hypridle, explicitly preserve lock-notify sleep
inhibition, and verify native readiness before relying on suspend**.

Proposed future edits, not performed:

- `general.lock_cmd`: replace the Hyprlock command with an idempotent MAGI locker
  launcher once accepted; exact installed path decided during packaging.
- Set `general.inhibit_sleep = 3` explicitly on this supported Hyprland/Hypridle
  combination. Auto mode 2 checks for the substring `hyprlock`; replacing only
  the command can fall back to waiting for command execution rather than lock.
- Keep `before_sleep_cmd = loginctl lock-session`, existing DPMS enable/disable
  commands, 300/600-second idle timing and an empty `unlock_cmd`.
- Keep CC/catalogue/Python Lock → loginctl routing: it will reach the new owner
  through Hypridle. Any future manual keybind should use the same route. Update
  availability/status so command submission is not displayed as secure lock.
- App-initiated suspend/hibernate must explicitly await confirmed lock before
  requesting sleep; never rely on a fixed delay or `pidof`.

Hypridle source `onLocked()` releases its delay inhibitor after compositor
lock-notify. This avoids assuming a locker-specific ready signal, but **delay
inhibitors expire** at logind's deadline [R12]. They are not an absolute veto.
Slow/missing locker, compositor five-second fallback and logind timeout can race.
Before migration, verify lid switch, power key, external loginctl/systemctl sleep,
no outputs/DPMS off and induced acquisition delay. If lock-before-suspend cannot
be demonstrated within effective deadlines, do not migrate; resolve the session
sleep policy separately. An on-demand locker alone cannot guarantee blocking
arbitrary privileged or forced suspend. No logind changes are authorized here.

Resume wakes displays but does not authenticate. Main MAGI overlays/toasts should
remain excluded by compositor policy even if shell IPC requests them. Lock-aware
shell suppression later improves UX/privacy but cannot substitute for protocol
input/render exclusion.

## O. Hyprlock fallback, parallel development and rollback

Production fallback remains exactly **`pidof hyprlock || hyprlock`**, normally
reached through `loginctl lock-session`. Keep binaries, PAM service and protected
configuration. An isolated named test executable/config must not replace
`quickshell -c magi` or Hypridle. Start protocol experiments in a disposable nested
compositor/VM first, then deliberately operator-controlled native tests with TTY
recovery available. Never start two competing lockers on the real session.

Fallback is not a post-crash unlock recipe. If MAGI fails before acquisition and
there is definitely no lock owner, a future launcher may start Hyprlock and await
its actual readiness. If MAGI acquired the lock and died, Hyprlock may be denied:
default restore policy is false. Do not clear the lock to make fallback work or
automatically enable restore. If acquisition status is ambiguous, report failure
and preserve safety; avoid silently treating fallback process launch as success.

Rollback after an ordinary authenticated unlock: restore the exact previous
Hypridle lock command and reviewed sleep-inhibition setting, stop only inactive
test processes, and return manual requests to the existing path. A frozen lock
requires authenticated TTY/remote operator recovery, potentially terminating the
graphical session and losing unsaved work. Secure compositor-specific restoration
is a separately reviewed operator action, not an exposed MAGI control.

Retire Hyprlock only after full Phase 6 acceptance, operator daily-use soak and
Phase 7 explicit approval. Retirement is optional even after migration; keeping
a known-working package/config is useful. No removal is part of this report.

## P. Locked-screen information policy

**Proposal defaults:** opaque theme background; local clock/date; coarse battery
charge and keyboard-layout/Caps indicators. Generic account label/avatar unless
the operator explicitly opts into the configured display name/avatar. Display
name never selects the authentication identity.

| Data | Default policy |
| --- | --- |
| Notifications, history, OTPs, application titles | No content/previews/actions while locked; optional count only after separate design review. |
| Media title, artist, album art, player identity | Hidden; independently opt in, not inherited from CC preference. |
| Weather | Off; optional coarse cached summary without precise location text, coordinates or network refresh dependency. |
| Username/display name/custom subtitle/avatar | Separate lock-specific opt-in; generic fallback. No automatic GECOS/account discovery for presentation. |
| Battery/network | Coarse battery okay; network status at most generic connectivity, no SSID, IP, VPN name or Bluetooth device names. |
| Wallpaper | Static validated local image optional; no desktop screenshot by default, including blurred screenshots. |

Read a bounded immutable presentation snapshot before acquisition; missing assets
or invalid Settings must still produce an opaque usable lock. Avoid arbitrary
external image URLs, theme scripts, live application-theme adapters and writing
Settings during lock. Snapshot age/failure never changes authorization.

## Q. Media and power actions while locked

Media controls are **off by default**. Optional future play/pause, next/previous
and bounded volume can be permitted without unlock as deliberate privacy/availability
policy, with capability checks and a selected player. No seeking/open URI, launch,
raise-window, arbitrary MPRIS methods or following metadata links. Treat all
metadata as untrusted bounded plain text; no live remote artwork fetch in the
lock process. A malicious MPRIS player can react to control messages; capability
flags are not a security endorsement. Default require unlock for media interaction;
an explicit opt-in may relax only the enumerated controls. Existing compositor
volume keys already work while locked and are a separate policy to acknowledge.

Power policy: optional confirmed Suspend after secure lock, through existing
logind authorization with no privilege bypass. Denied authorization stays locked;
never show a generic polkit agent/password flow inside the locker. Shutdown and
reboot off by default (data loss/denial of service), possibly future explicit
operator opt-in with confirmation and ordinary logind policy. Logout is excluded:
it destroys the session and can complicate greeter/startup safety. Switch-user
is deferred until a known display-manager flow preserving the old locked session
is audited. Do not import Control Centre's entire action catalogue into lock UI.

## R. Crash, failure and recovery analysis

| Failure | Expected/proposed result | Required native evidence |
| --- | --- | --- |
| Main MAGI exits/restarts | Dedicated locker remains active | Separate process/cgroup lifetime; no inherited parent-death termination from MAGI. |
| QML component fails, including on hotplug | Native owner keeps opaque surface/fallback; no release | Fault injection must prove no unlock request. This is where stock QS is not accepted. |
| Entire locker killed or Wayland connection lost while compositor survives | Hyprland remains locked, missing-client screen/blank output | SIGKILL, SIGTERM, abort and disconnect tests on disposable session first. |
| Worker exits, is killed, hangs or writes malformed result | Host stays locked, cancels attempt, bounded deliberate restart | No success from EOF/exit code; stale success rejected. |
| Host is killed before `locked` | No confirmed-lock claim; compositor may still have accepted request | Test acquisition races and launcher conservative fallback; do not promise prior protection. |
| Worker says success during suspend/cancel | Result invalidated | Generation and cancellation race tests. |
| Output hotplug/removal while UI broken | Compositor prevents desktop exposure; native fallback | Frame-level observation on all displays, including wake. |
| Compositor dies/restarts | No surviving session-lock guarantee | Greeter/session startup review; no automatic unlocked desktop restoration. |
| PAM policy unavailable/account expired | Stay locked; actionable generic error and operator recovery | Deliberate auth tests under actual deployment policy. |
| Generic termination / service stop | Disconnect without unlock | Audit destructors, signals, errors and systemd stop paths. |

Hyprland's restore option is not a general authenticated restart protocol. With
restore disabled, recovery may require ending the session from an authenticated
TTY. With it enabled, a new client can acquire the role according to compositor
policy, which increases trust in other same-user clients. The protocol has no
built-in password or cryptographic identity for a replacement owner. Do not
promise seamless secure recovery from every lock-client crash.

## S. Dependency and deployment audit

| Dependency | Installed? | Required/optional and security implications |
| --- | --- | --- |
| Hyprland + ext-session-lock-v1 | Package/source yes; live registry unqueried | Required trust boundary; native gate verifies effective policy and failures. |
| Qt6 Core/Gui/Quick/QML/Wayland | Yes | Required for recommended host. Native Wayland role adapter may depend on private ABI; rebuild/retest on Qt upgrades. No stable built-in Qt lock API assumed. |
| libwayland-client + wayland-protocols | Yes | Required protocol transport/generated definitions; avoid custom protocol redesign. |
| libxkbcommon | Yes | Required if native seat/input adapter uses XKB; keymap/state must match compositor seat. |
| Linux-PAM / pambase / existing system helper | Yes | Required; module policy is administrator-owned. No custom shadow reading or root daemon. |
| Rust compiler/Cargo | Not found | Build dependency if recommended worker selected, not permission to install. New language/toolchain maintenance cost. |
| `pam-client` (0.5.0 docs examined) or audited libpam FFI | Not established locally | Candidate required binding, not selected/pinned yet. Review conversation allocations, unsafe code, errors and license. |
| `zeroize` | Not established locally | Recommended worker buffer cleanup; does not eliminate historical copies or lock memory. |
| Rust standard Unix APIs; `rustix` or `nix` if needed | Not established locally | Optional narrow FD/process/memory APIs; avoid overlapping crates/async runtime without need. |
| `wayland-client`, `wayland-protocols` Rust crates | Not established locally | Optional alternative-B/non-Qt proof only; not needed for PAM-only Rust worker. ext lock is behind staging feature. |
| CMake/Ninja/GCC/pkgconf | Yes | Native host build tools; no package operations performed. |
| systemd/logind, Hypridle | Present | Required future session integration; user unit optional. Delay inhibition is finite. |
| fprintd/pam_fprintd | Yes | Future optional auth policy; direct fingerprint backend not proposed now. |
| GTK/gtk-session-lock, Python auth, additional renderer/compositor | Not selected | No need to add these for recommended architecture. |

No code/assets reused in this milestone. Upstream downloads are research material
under `/tmp/magi-lock-audit`, not vendored source. Before copying/adapting any code,
review the exact revision's LICENSE/SPDX and attribution obligations; protocol XML
contains its permissive notice. Do not assume licenses transfer across projects
or that reading source authorizes uncredited incorporation. Dependency review,
version pinning and build reproducibility are Phase 2 gates.

## T. Future repository placement (proposal only)

Preserve the existing Stow package. Source/build files must not become executable
configuration accidentally via directory stowing.

| Proposed path under `linux/magi/` | Purpose |
| --- | --- |
| `native/lock/` | Native Qt owner, protocol adapter, native input and immutable QML facade; build definition. |
| `native/lock-auth/` | Small Rust PAM worker, manifest/lockfile only in a later authorized phase. |
| `.config/quickshell/magi/components/lock/` or `native/lock/qml/` | Presentation sources; prefer bundled `native/lock/qml/` for dedicated host so shell auto-reload/import graph cannot affect it. Final placement depends on proof. |
| `packaging/pam/magi-lock` | Administrator-reviewed template, never automatically stowed to /etc. |
| `packaging/systemd/magi-lock.service` | Optional on-demand user-unit template; no enablement link now. |
| `tests/lock/` | State/IPC/conversation tests, disposable-compositor harness and manual native checklist. |
| `docs/research/lock-screen-architecture.md` | This evidence/proposal. Future accepted decision appended to existing decisions.md. |

Build outside deployed config; choose a reviewed executable installation path in
packaging phase. Production QML/worker must come from a known matching build, not
an arbitrary file selected by Settings. User-writable dotfiles/binaries remain
part of the same-user trust limitation. No new source, QML, template, unit, build
file or test file is created in Phase 1.

## U. Future security/native test matrix

**None of these tests ran in Phase 1.** Start with mock PAM and disposable nested
compositor/VM; reserve actual credentials, sleep and failure recovery for an
explicit operator-controlled native checkpoint. Offscreen QML screenshots cannot
certify input isolation or physical-output frame security.

| Group | Cases | Required evidence / pass condition |
| --- | --- | --- |
| Protocol | Missing global; denied/duplicate lock; acquire timeout; early cancel; locked/finished ordering; malformed configure; sync on release | No fake lock, no false readiness, no unauthenticated release; protocol trace with synthetic data only. |
| Functional auth | Manual lock; correct/wrong password; repeated failure; clear/cancel/retry; empty/overlength/Unicode; expired account; unavailable service | Only current PAM success + approved account policy releases; errors remain locked; no truncation. |
| Conversations | Multiple messages in one call, repeated prompts, OTP-like flow, ECHO_ON/OFF, info/error, unknown style, allocation failure | Correct ordered independent responses, bounded data, cleanup; no saved-password replay. |
| IPC/races | Forged result; wrong UID/child; stale generation; EOF; short reads/writes; malformed size; concurrent submissions; cancel/suspend versus success | One attempt, private-channel authority, no unlock from malformed/replayed messages or exit 0. |
| Session security | Open normal/layer/Xwayland windows; focus/workspace changes; Apps/Hub/CC/Settings shortcuts; notifications/toasts; shell IPC; locked binds | No protected input to underlying apps, no desktop/unauthorized overlay visible; permitted brightness/volume behaves as documented. |
| Multi-monitor | One/two displays; eDP+external; scales 2/1.5; hotplug/unplug; primary change; rotated output; all outputs removed; sleeping output wakes | Every output continuously opaque; no flash; usable single auth route, topology never releases. |
| Input | Caps/Num; layout switch; compose/dead keys; modifier held over acquisition; keyboard reconnect; pointer/touch; focus transfer; wake event; paste attempts | Native capture before QML, no clipboard exposure, predictable Enter/Escape; correct seat indicators. |
| Suspend | Manual/idle lock, app sleep, external sleep, lid/power key; DPMS before lock; slow owner; logind deadline exhausted; resume | Protected frame before sleep/resume; no stale auth, no timing reliance on PID/command return. Failures block migration. |
| Failure | Kill QML host; component creation failure on new output; kill/hang auth worker; restart MAGI; SIGTERM/SIGUSR1; compositor disconnect/restart | Owner failures remain compositor-locked; signal never unlocks; restart limitations documented. Compositor restart only in disposable session with recovery. |
| Privacy | Synthetic secret marker in logs/core policies/process args/state/backups; native/QML introspection; notification redaction; media/asset payload abuse | No application-owned persistent/logged secret; QML facade has no secret field; bounded static assets. Memory scan is evidence, not universal erasure proof. |
| Capture/control | Screenshot key, screencopy, portal screencast, active remote desktop, virtual-input and compositor control interfaces | Document actual allowed privileged access; no ordinary capture of unlocked content. Privileged exceptions are explicit deployment policy. |
| Resource/upgrade | Missing avatar/theme, corrupt Settings, no network, CPU/GPU pressure, renderer loss, memory allocation failure; Qt/QS/Hyprland updates | Native fallback remains locked, bounded work; re-run affected acceptance after security-stack upgrades. |
| Recovery/rollback | Locked host crash with restore off; authenticated TTY recovery; return to Hyprlock after normal unlock | Honest recovery path demonstrated without a public unlock endpoint; protected configurations recover exactly. |

Acceptance records should retain versions, effective compositor policy, output
inventory, pass/fail observations and operator sign-off. Avoid recording real
credentials or screenshots of private desktop content. No automated test can
prove absence of all compositor, driver or PAM vulnerabilities.

## V. Bounded implementation roadmap

Every phase stops at its stated checkpoint; none is started by this audit.

| Phase | Boundary and likely files | Tests / operator-native acceptance | Rollback |
| --- | --- | --- | --- |
| 2: native protocol/input feasibility | `native/lock/`, isolated `tests/lock/`; opaque native surfaces, state machine, secret input proof; no real PAM or production UI | Disposable compositor first: confirmed readiness, every output, component failure, no generic release, native keys never reach QML. Review hardened upstream QS alternative before committing to custom adapter. Deliberate native proof only with operator recovery plan. | Stop isolated experiment; Hyprlock untouched. If native Qt role/input bridge cannot be made safe, stop and retain Hyprlock. |
| 3: PAM and private-channel proof | `native/lock-auth/`, IPC adapter/tests; proposed PAM template reviewed but not installed automatically | Mock full conversations/races first; deliberate actual-UID auth with existing service, then separately approved dedicated policy/account semantics; inspect synthetic-secret logs and failure cleanup | Remove test activation; retain existing PAM files/Hyprlock. Never “test” by replacing production policy. |
| 4: presentation and multi-output composition | Bundled locker QML and minimal pure theme/asset reader; preserve native controller | Fault-inject QML/asset errors and hotplug; native layouts/Caps/input, mixed scaling, all-screen coverage; no network or shell-root dependencies | Native opaque test UI or stop test after authorized unlock; production unchanged. |
| 5: opt-in integration | Test launcher/readiness; optional unit template; reviewed future Hypridle/manual routing diff | Verify lock-notify mode 3 and sleep deadlines in disposable setup, then deliberate opt-in native checks. Present exact protected-config migration diff for operator approval | Restore preserved Hyprlock route and prior inhibition setting after ordinary authenticated unlock; no forced release. |
| 6: security acceptance | Tests/checklists/docs and targeted fixes only | Full U matrix, crash/TTY recovery, capture/control, hotplug/DPMS/suspend/resume, repeated daily-use soak; operator and native acceptance required | Hyprlock remains production or immediate route rollback after safe unlock; unresolved failure is a release blocker. |
| 7: production migration | Explicitly approved Hypridle/manual integration, deployment artifacts, final decision/docs | Recheck actual installed builds and effective policy, acceptance evidence and recovery; monitor normal use | Preserve exact old command/config/package. Retire Hyprlock only after separate explicit acceptance, never automatically. |

Phase 2 must resolve the largest design uncertainty **before** production UI:
maintainable native Qt lock integration versus a properly hardened supported
Quickshell abstraction. If neither meets the invariants, the conclusion is to
retain Hyprlock, not relax the requirements into a fullscreen window.

## W. Explicit exclusions and Phase 1 validation

No lock implementation, production UI, native helper, Cargo project, PAM template,
unit file or new settings. No Hyprland/Hypridle/Hyprlock/PAM/system configuration
changes; no lock/unlock/suspend commands; no running shell restart; no installs or
removals; no stage, commit or push. No fingerprint implementation, final pixel
layout, greeter, arbitrary privileged daemon or claim of resistance to root or
fully compromised user-session code.

Existing operator-local modified/untracked files are intentional and preserved.
A before/after content-hash inventory of repository files is used in addition to
Git status; untracked research files require a direct whitespace scan because
ordinary `git diff --check` does not inspect untracked contents. Final checks: `git status --short` shows only this new research path in addition
to the original operator-local entries; `git diff --check --
linux/magi/docs/research/lock-screen-architecture.md` passes. A direct scan of
the untracked document finds no trailing whitespace. The before/after inventory
finds zero content changes to pre-existing repository files, and the index has
no staged changes. No decision entry is added because the
native implementation boundary still requires a feasibility checkpoint.

## X. Source/reference ledger

All inspected **2026-10-17**. Local package versions are in B. Release tags below
identify upstream source, not an assertion that Arch's installed binary is
byte-identical. Current-branch hashes pin the bounded comparison; they are not
new dependencies or recommended upgrades. Source material is evidence for the
specified functions only, not certification of whole projects.

| ID | Source/version and inspected components | Demonstrates / relevance / remaining gate |
| --- | --- | --- |
| R1 | [wayland-protocols ext-session-lock XML](https://gitlab.freedesktop.org/wayland/wayland-protocols/-/blob/main/staging/ext-session-lock/ext-session-lock-v1.xml); installed 1.49 XML at `/usr/share/wayland-protocols/staging/ext-session-lock/ext-session-lock-v1.xml`; [rendered protocol](https://wayland.app/protocols/ext-session-lock-v1) | Lock/locked/finished, configure, unlock, output and client-death contract. Local XML is primary evidence; live conformance untested. |
| R2 | [WlSessionLock v0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/WlSessionLock/); [native implementation](https://github.com/quickshell-mirror/quickshell/blob/1a4716cde794a59928d9d9fc15f2afc7a95de360/src/wayland/session_lock.cpp); `session_lock/{lock,surface,session_lock,manager}.cpp` at that commit | Supported per-output API, confirmed secure state, reload and invalid-component unlock path. Installed qmltypes corroborate API; live failure reachability still a test. |
| R3 | [PamContext v0.3.1](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Pam/PamContext/); [subprocess source](https://github.com/quickshell-mirror/quickshell/blob/1a4716cde794a59928d9d9fc15f2afc7a95de360/src/services/pam/subprocess.cpp), adjacent conversation/ipc/qml sources | Fork/pipes, prompt relay, QString conversion, authenticate-only flow. This is native PAM, but not the proposed no-QML-secret boundary. |
| R4 | Hyprland v0.56.2 `efb50993780079460b0cbed1363e2166a2de1d9f`: [manager](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/managers/SessionLockManager.cpp), [protocol](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/protocols/SessionLock.cpp), [renderer](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/render/Renderer.cpp), desktop/view/SessionLock and HyprCtl | Lock flag surviving destruction, readiness timer/rendered-monitor tracking, fallback, restore/force-unlock and xray/above-lock exceptions. Actual frame/input/capture policy needs native acceptance. |
| R5 | Hyprlock v0.9.6 `b222d9b1f87e980cac379371df57913a53b99d7f`: [core](https://github.com/hyprwm/hyprlock/blob/b222d9b1f87e980cac379371df57913a53b99d7f/src/core/hyprlock.cpp), core/LockSurface.cpp, [PAM](https://github.com/hyprwm/hyprlock/blob/b222d9b1f87e980cac379371df57913a53b99d7f/src/auth/Pam.cpp), auth/Auth.cpp and Fingerprint.cpp | Protocol lifecycle, output registry, scaling, auth thread/conversation, direct fprintd, SIGUSR1 release. Adopt bounded patterns only; not a copy or blanket security endorsement. |
| R6 | swaylock current inspected `44b82de635c3bc66b0093abd1cf8cc1c8b1b9c0f`: [main](https://github.com/swaywm/swaylock/blob/44b82de635c3bc66b0093abd1cf8cc1c8b1b9c0f/main.c), [pam.c](https://github.com/swaywm/swaylock/blob/44b82de635c3bc66b0093abd1cf8cc1c8b1b9c0f/pam.c), comm.c, password.c, password-buffer.c, seat.c | Ready FD, native lock, private child/pipes, mlock/clearing, one-shot prompt limitations, XKB and signal behaviour. No installation/runtime test. |
| R7 | gtklock current `3ba3671f15c4cc06468a7c017a861be80e8ef53e`: [gtklock.c](https://github.com/jovanlanik/gtklock/blob/3ba3671f15c4cc06468a7c017a861be80e8ef53e/src/gtklock.c), [auth.c](https://github.com/jovanlanik/gtklock/blob/3ba3671f15c4cc06468a7c017a861be80e8ef53e/src/auth.c), [project documentation](https://github.com/jovanlanik/gtklock) | gtk-session-lock integration, focused window, PAM fork/messages and quit-to-unlock pattern. Bounded comparison only; GTK dependency not proposed. |
| R8 | Linux-PAM upstream manuals rendered by man7: [pam_conv](https://man7.org/linux/man-pages/man3/pam_conv.3.html), [pam_authenticate](https://man7.org/linux/man-pages/man3/pam_authenticate.3.html), [pam_acct_mgmt](https://man7.org/linux/man-pages/man3/pam_acct_mgmt.3.html); local PAM 1.7.3 headers/policy | Four message classes, array response ownership, authentication versus account checks. Actual module conversations and cancellation remain Phase 3 tests. linux-pam.org guide fetch failed; not used as evidence. |
| R9 | Hypridle v0.1.8 `e5c01af0842bd66617f7004568df9406111d6e80`: [core](https://github.com/hyprwm/hypridle/blob/e5c01af0842bd66617f7004568df9406111d6e80/src/core/Hypridle.cpp), config/ConfigManager.cpp; [current docs](https://wiki.hypr.land/Hypr-Ecosystem/hypridle/) | Auto-mode command-name heuristic, notifier, onLocked/uninhibitSleep and DBus sleep handling. Explicit mode and timing acceptance needed. |
| R10 | [Hyprland current configuration options](https://wiki.hypr.land/configuring/core/config-options/) and [variables](https://wiki.hypr.land/Configuring/Basics/Variables/) | Documents restore/xray default false. Effective runtime values not queried; do not mistake defaults for verified deployment. |
| R11 | Current upstream sampled: QS [2b4501a282689792b62e94f3fb30d8f512324fe6](https://github.com/quickshell-mirror/quickshell/blob/2b4501a282689792b62e94f3fb30d8f512324fe6/src/wayland/session_lock.cpp); Hyprland [8010b4e5c66f97aa82cd5b3332b4ec613779b9a7](https://github.com/hyprwm/Hyprland/blob/8010b4e5c66f97aa82cd5b3332b4ec613779b9a7/src/managers/SessionLockManager.cpp); Hyprlock [0332e40b8e56404f11cd79f859f208a4b9de8714](https://github.com/hyprwm/hyprlock/blob/0332e40b8e56404f11cd79f859f208a4b9de8714/src/auth/Pam.cpp); Hypridle [aa958ed7ad4863860b93ecd7189419e193bfae2c](https://github.com/hyprwm/hypridle/blob/aa958ed7ad4863860b93ecd7189419e193bfae2c/src/core/Hypridle.cpp) | Current versus installed-release comparison limited to linked files: QS error branch persists; Hyprlock PAM cleanup evolves. No claim every current source file was audited. |
| R12 | [systemd inhibitor design](https://github.com/systemd/systemd/blob/main/docs/INHIBITOR_LOCKS.md), current documentation inspected | Delay timeout prevents an unlimited lock-before-suspend guarantee. Effective logind deadline/drop-ins require native deployment audit. Direct freedesktop login1 manual fetch returned 403 and was not relied on. |
| R13 | [pam-client 0.5.0](https://docs.rs/pam-client/latest/pam_client/) | Conversation-capable Rust API candidate; dependency/source/license audit required before adoption. |
| R14 | [zeroize](https://docs.rs/zeroize/latest/zeroize/) | Owned-buffer clearing primitive and limitations; not a promise to erase all copies. Pin a reviewed version later. |
| R15 | [wayland-protocols Rust 0.32.13 ext/session_lock](https://docs.rs/wayland-protocols/latest/wayland_protocols/ext/session_lock/v1/index.html) | Staging client/server bindings exist; does not supply a Qt/Quickshell renderer bridge. Not selected for PAM worker. |
| R16 | Repository files listed in B; installed Qt QML metadata, package inventory, protected config and PAM include files | Local compatibility/routing/asset evidence. Baseline and content preservation checked separately from upstream research. |
