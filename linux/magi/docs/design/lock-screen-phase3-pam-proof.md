# MAGI Lock Screen — Phase 3 PAM worker proof

Date: 2026-10-17. Baseline: `24ebcee1c6dba70baadc0fa01cdad53b5281c8f7`.
**Operator accepted: implementation, automated validation and one real ordinary-user
non-locking PAM success. Not a production locker. Phase 4 has not begun.**

This checkpoint adds an isolated Rust worker and a non-locking native terminal
harness. The Phase 2 C++/Wayland owner, QML, production routes, Hyprlock, Hypridle
and system PAM configuration are unchanged. Authentication success is a result
for the private parent, never a compositor operation. No unlock message exists.

## Local preflight and policy decision

Read the Phase 1 architecture audit, Phase 2 checkpoint, native README and native
source, plus MAGI instructions and documentation index. Earlier checkpoints are
not rewritten. The user-requested narrow scope takes precedence over broad
repository documentation-maintenance guidance.

Verified locally:

- `rustc 1.99.1 (58cf8f9c3 2026-10-13)`;
  `cargo 1.99.1 (5f94df478 2026-08-27)`;
  `stable-x86_64-unknown-linux-gnu (default)`.
- Linux-PAM `1.7.3` via pkg-config; installed `security/pam_appl.h` and
  `_pam_types.h`; `/usr/lib/libpam.so` → `libpam.so.0.85.1`.
- Current UID/GID 1000, account `jkebwdn`; no shadow/password hashes read.
- Installed manual pages for `pam_start`, `pam_authenticate`, `pam_acct_mgmt`,
  `pam_conv`, `pam_end` inspected read-only. No packages installed by this work.
- Hyprlock config enables PAM and selects `hyprlock`. `/etc/pam.d/hyprlock`
  contains `auth include login`, with no account/session/password entries.
- Auth includes traverse login → system-local-login → system-login → system-auth.
  Inspected auth modules include nologin, shells, faillock, optional systemd-home,
  pam_unix and pam_env. No pam_fprintd in this chain. Hyprlock's configured direct
  fingerprint backend is separate.

**Proof service: existing `hyprlock`, hardcoded; no service/username argument.**
It is appropriate as the existing lock authentication policy. There is no fallback
to `su`, `login` or `other`; the worker checks that the service file exists before
starting. Config change races remain in the trusted administrator boundary.

Sequence: `pam_start("hyprlock", current_uid_name, conversation)` →
`pam_authenticate(PAM_DISALLOW_NULL_AUTHTOK)` → on success `pam_get_item(PAM_USER)`
and exact identity check → `pam_end(last_status)`. Result is sent after pam_end.
Failed starts do not use the undefined handle. A guard ends an active transaction
on normal Rust unwinding. No setcred, chauthtok or open/close-session calls exist.
The null-token flag deliberately rejects passwordless-token authentication even
though the included local pam_unix policy has `nullok`; it is stricter than the
examined Hyprlock call's flags=0.

**Do not call pam_acct_mgmt for this proof.** It checks account/access/token
expiry rather than merely verifying identity, and this service has no account
stack. Including it blindly could deny access to an already logged-in session
without providing a password-change path. This is an explicit proof policy,
not a claim that account checks are universally wrong for lockers. A future
administrator-reviewed `magi-lock` service is preferable for independent policy;
that milestone must decide whether expired/disabled accounts may recover an
existing session, including how PAM_NEW_AUTHTOK_REQD is handled. Never treat
that result as authentication success or silently change the password here.

PAM modules and the existing distro helper remain the authority. Ordinary-user
operation is intended, matching the current locker model; the worker rejects root,
setuid and setgid execution. Installed unix_chkpwd has privilege bits; this work
adds no helper or privilege. The single approved live test authenticated UID 1000
successfully with this stack. No sudo, polkit, setuid worker or root service was added.

## Dependency and upstream review

Sources below were inspected 2026-10-17. Latest-page results are snapshots, not
claims of a complete security audit or guaranteed future maintenance. Installed
headers are the ABI reference; no upstream implementation code was copied.

| Candidate | Evidence, safety and conversation control | Decision |
| --- | --- | --- |
| pam-client 0.5.0 | Published 2022-07-30; safe application API and custom ConversationHandler, Linux-tested. Covers account/session/credential operations beyond this proof. Lists bitflags, enum-repr, libc, pam-sys alpha and rustversion; optional CLI/serde. Ownership through wrapper must be audited for credential copies. Recent maintenance was not established by this older release. | Viable broader abstraction, not selected for this small boundary. |
| pam-sys 0.5.6 / alpha series | Published stable documentation exposes raw and wrapped libpam functions/types; libc dependency. Upstream tree also has build.rs and wrapper.h; pam-client depends on the 1.0 alpha line. Low-level access supports arbitrary conversations but does not solve callback lifetime/cleanup. Maintenance/version split requires care. | Does not materially remove the unsafe ownership code needed here. |
| Direct minimal Linux-PAM FFI | Four application symbols, three repr(C) structs; matches local 1.7.3 declarations. Full control over conversation responses and partial allocation cleanup. No safety abstraction beyond our reviewed wrapper; ABI and unsafe-code maintenance belong to MAGI. Linux/glibc only. | Selected; smallest explicit scope, not a claim of inherently safer FFI. |
| zeroize 1.9.1 | RustCrypto, no mandatory dependencies, Rust 1.85 minimum; volatile/fence erasure, optional derive. Good maintained portable erasure option with documented copy limitations. | Appropriate future portable alternative; unnecessary extra dependency for this glibc-only proof. |
| secrecy 0.10.3 | Explicit secret exposure and zeroize-on-drop; no mlock guarantee. Useful general wrapper, with broader API than the single fixed buffer needed here. | No extra wrapper crate. Our buffer deliberately has no Clone/Debug/Display. |
| glibc explicit_bzero | Documented non-elidable memory erasure; already supplied by target libc. Does not erase invisible register/stack copies. | Selected erasure primitive via libc. |

**Only direct Rust dependency: `libc = "=0.2.179"`**, default std feature,
MIT OR Apache-2.0. No transitive Cargo dependencies, proc macros, async runtime,
serde, JSON or build-time binding generator. This already cached release supplies
target-specific POSIX/Linux ABI declarations (socketpair, poll, termios, passwd,
allocation, close_range, erasure); avoiding hand-maintained libc layouts reduces
ABI risk. This is a pinned known build input, not a claim it is the latest release
or has received a full vulnerability audit. Rust-lang maintains the libc project;
future dependency changes need review and the full test suite. `Cargo.lock` is
included in the operator-approved Phase 3 commit allowlist.

Sources and what they establish:

- [Linux-PAM pam_start](https://raw.githubusercontent.com/linux-pam/linux-pam/master/doc/man/pam_start.3.xml),
  [pam_authenticate](https://raw.githubusercontent.com/linux-pam/linux-pam/master/doc/man/pam_authenticate.3.xml),
  [pam_acct_mgmt](https://raw.githubusercontent.com/linux-pam/linux-pam/master/doc/man/pam_acct_mgmt.3.xml),
  [pam_conv](https://raw.githubusercontent.com/linux-pam/linux-pam/master/doc/man/pam_conv.3.xml):
  upstream master documentation inspected alongside local 1.7.3 manuals. Establishes
  transaction initialization, returned PAM_USER, account-policy distinction,
  Linux pointer-array semantics, four styles and caller-owned response freeing.
  Master is not a pinned source revision; compatibility was checked locally.
- [Hyprlock v0.9.6 Pam.cpp](https://raw.githubusercontent.com/hyprwm/hyprlock/v0.9.6/src/auth/Pam.cpp):
  CPam::auth uses start/authenticate/end, without account/session operations;
  CPam constructor selects configured service and UID-derived username. Its fallback,
  prompt logging and unlock logic are not copied.
- [pam-client 0.5.0 package](https://docs.rs/crate/pam-client/0.5.0)
  and [API](https://docs.rs/pam-client/latest/pam_client/): release/dependency/feature
  evidence and custom conversation support; Linux compatibility, not a local test.
- [pam-sys API](https://docs.rs/pam-sys/latest/pam_sys/)
  and [upstream repository](https://github.com/1wilkens/pam-sys): raw/wrapped scope,
  version split and repository build surface. Not a claim of current security review.
- [zeroize](https://docs.rs/zeroize/latest/zeroize/),
  [secrecy](https://docs.rs/secrecy/latest/secrecy/),
  [glibc erasure documentation](https://sourceware.org/glibc/manual/latest/html_node/Erasing-Sensitive-Data.html):
  erasure mechanisms and explicit limits. libc's installed cached 0.2.179 source
  confirms the explicit_bzero declaration; [libc upstream API](https://docs.rs/libc/latest/libc/)
  supplies the maintained target ABI project reference.

## Process, identity and private channel

`magi-auth-harness` is a separate native Rust executable; using Rust for this tiny
parent avoids premature CMake/language bridging. It is not a replacement for the
C++ owner. The documented byte contract is language-neutral and can be implemented
with socketpair/posix_spawn or fork+exec in the future owner.

1. Parent creates AF_UNIX/SOCK_SEQPACKET | SOCK_CLOEXEC socketpair (no bind/path).
2. Command spawn maps child endpoint to FD 3. Parent endpoint and unrelated FDs
   close on exec; child stdin/stdout are /dev/null and stderr is a private pipe.
   The Rust exec-error pipe stays CLOEXEC to preserve spawn failure reporting.
3. Parent closes its copy of the child's endpoint. Worker validates unnamed local
   and peer AF_UNIX addresses, SOCK_SEQPACKET type, and SO_PEERCRED UID/PID equal
   to its UID/current parent. No pathname/env-selected socket is accepted.
4. Worker restores FD_CLOEXEC on 3, closes FDs >=4, and sets its lifetime alarm.
   FD 3 therefore does not leak through PAM helper exec. Standard FDs remain.
5. Worker resolves getuid through bounded getpwuid_r storage; neither IPC nor env
   chooses the account. It rejects PAM_USER changes after success, including aliases.
6. One handshake, one transaction, one bounded result, process exit. Parent waits
   and reaps; transport exit code alone is never authentication success.

The launcher clears the environment and supplies only PATH=/usr/bin, LANG=C;
worker startup enforces that exact allowlist and exact arguments
`--ipc-fd=3 --one-attempt`. Dynamic loader injection happens before main, so this
check is not a defence against an already-compromised launcher. Production must
execute an installed trusted binary by absolute path and preserve this clean spawn
contract, preferably from its dedicated native spawn component. Current sibling
binary resolution is only a development harness convention.

Inherited descriptors are capabilities, not a barrier against arbitrary malicious
same-UID code. Another process can launch its own worker, but cannot select another
user/service or unlock a compositor. There is no filesystem socket, public listener,
D-Bus endpoint, daemon, Wayland dependency or generic unlock service.

## Wire format and state

Each seqpacket record is exactly a 12-byte header plus 0..512 payload bytes.
SOCK_SEQPACKET preserves boundaries; recv with MSG_TRUNC detects oversize records
without allocating their advertised size. SOCK_STREAM is unnecessary on Linux.

| Offset | Meaning |
| --- | --- |
| 0..3 | ASCII `MAG3` |
| 4 | Version 1; other versions rejected |
| 5 | Mandatory message type |
| 6..7 | Big-endian u16 message ID |
| 8..11 | Big-endian u32 payload byte length |

| Value / message | Direction and payload |
| --- | --- |
| 1 Hello | worker → parent, ID 0, empty |
| 2 HelloAck | parent → worker, ID 0, empty; only this enters backend |
| 3 PromptEchoOff / 4 PromptEchoOn | worker → parent, sequential ID, bounded PAM text |
| 5 Info / 6 Error | worker → parent, sequential ID, bounded PAM text |
| 7 Response | parent → worker, matching prompt ID, 0..511 bytes, no interior NUL |
| 8 AuthenticationResult | worker → parent, ID 0, one result byte |
| 9 Cancel | parent → worker, ID 0, empty |
| 10 Ack | parent → worker, matching Info/Error ID, empty |

Result codes: 0 Success; 1 AuthenticationFailed; 2 Cancelled; 3 PamError;
4 ProtocolError; 5 WorkerError. All other values fail closed. These are future
presentation categories, not permission to unlock. Safe user text is generic
failure/cancel/unavailable; internal stack details and arbitrary PAM text should
not be passed directly into QML or diagnostic logs.

Worker states: validate → Hello/await HelloAck → backend → sequential exchanges
→ end transaction → result → exit. IDs begin at 1; at most 64 conversation messages
per transaction, 32 per PAM callback. Each prompt waits for a matching Response;
each Info/Error waits for Ack. No speculative/reused credential reply. Queued input
before a prompt, wrong IDs/types/directions, extra handshakes, unknown types,
truncation, oversized records and NUL-containing replies are errors. A parent
cancelling its attempt must disregard any late success, even if cancellation
crosses a result in transit.

All four standard PAM styles work, including multiple messages in one C callback
and multiple callbacks. Linux's array of message pointers becomes an equally sized
calloc response array; Info/Error entries have null response and all retcodes are
zero. Failure frees/erases partially built responses and returns PAM_CONV_ERR.
The fake backend exercises this exact callback, not a parallel reimplementation.

## Secrets, cancellation and crash limits

No QML sees raw credentials. No Settings, clipboard, argv/env passwords, file
persistence, tracing or debug formatting of sensitive payloads exists. Buffer is a
fixed-size boxed byte slice without Clone/Debug/Display. glibc explicit_bzero
clears its entire storage on drop and explicit clear. Parsing errors also drop and
wipe received buffers. The TTY parent reads directly into bounded mutable bytes;
it clears the response immediately after send (including a send error).

Unavoidable copies: parent input → temporary framed send buffer → kernel socket
queue → worker frame → calloc C string transferred to PAM. Each owned Rust buffer
is erased; partial C allocations are erased before free. On successful callback,
PAM/modules own the C strings and their internal copies; the worker cannot safely
erase those pointers afterward. PAM messages may themselves contain sensitive
text, so all received frames are treated as sensitive and raw text is not logged.
No credential contents or lengths appear in application logs.

Neither Rust nor explicit_bzero guarantees removal from registers, compiler spills,
allocator internals, kernel TTY/socket buffers, swap, hibernation or module memory.
No mlock guarantee is claimed. RLIMIT_CORE=0 disables ordinary process core dumps;
this is not protection from a privileged debugger/system capture configuration.
SIGKILL, OOM, release panic-abort or a corrupt native module can skip destructors.
Panic hooks omit payload/location; the callback catches unwinding in development
and never unwinds across C. Release aborts instead of unwinding.

Poll waits are bounded to 30 seconds each, with a total channel deadline of 120
seconds. Callback Cancel or socket loss returns conversation error, erases owned
responses and normally reaches pam_end. Info messages also permit cancellation
through their Ack step. PAM itself may block without calling back; the harness
restores the TTY, allows 2 seconds for child exit, then kills/reaps it. Worker
SIGALRM at 125 seconds is a final bound if its parent vanishes or a module hangs.
Forced termination cannot safely execute pam_end or guarantee erasure. A future
owner must stay locked on every such path, clear pending input, and never reuse
an attempt's result. These bounds are proof limits, not final MFA/fingerprint UX.

PAM failure delays and faillock policy are not overridden. The harness requires
an actual controlling terminal and explicit CLI gates, waits three seconds and
runs once, with no automated retries. This prevents accidental scripted retry
loops, not a malicious user spawning many processes. Production needs one active
worker per lock owner and UI retry serialization/backoff in addition to PAM policy;
never substitute custom password verification or skip module delays.

## Harness and historical real test procedure

The terminal harness supports every conversation type but deliberately displays
only message types. Even EchoOn responses are hidden as a conservative proof
presentation policy; the protocol retains the distinction for future UX. Arbitrary
multi-factor prompts cannot yet be explained usefully by this deliberately generic
TTY display. No fingerprint-specific logic is implemented. Sequential PAM/fprintd
conversations fit the protocol, but enrolled devices, async status, timeout policy
and real module combinations still require separate validation.

Tests and ordinary no-argument invocation do **not** authenticate. Before the real
run, obtain explicit operator approval for this specific one-attempt test and
review the selected system policy. Wrong credentials may update PAM's failure
counters or trigger its lockout policy. Do not intentionally test repeated failures.
No system configuration change is part of the procedure.

The following command was executed exactly once with explicit operator approval,
from a separate ordinary-user terminal. It is retained as historical evidence,
not authorization for another run:

```bash
/tmp/magi-auth-build/debug/magi-auth-harness --real-pam --operator-approved
```

The already-built sibling `magi-lock-auth` must be present. This command does not
connect to Wayland or lock anything. It opens /dev/tty, saves termios, disables echo,
creates the private child channel, waits for a PAM prompt, and accepts the current
account response without printing it. Enter submits; Backspace removes one byte
(not a Unicode grapheme); Ctrl-C, Ctrl-D or Escape cancels. Credential buffers are
cleared and the child returns a bounded result and exits. Terminal settings restore
before the final result is printed. Both success and failure finish the process;
there is no retry prompt. Report the result without sending any password to chat.

SIGINT/TERM/HUP/TSTP request cancellation (TSTP cancels rather than suspends).
While waiting on IPC rather than TTY, signal handling may take up to the poll bound.
Forced death of the harness cannot run its termios guard; if externally killed,
the operator may need `stty sane` in that terminal. This limitation is not a reason
to run any kill/fault test on real credentials. Synthetic PTY tests verify normal
submission/cancellation restore the saved flags and emit no input echo.

**The one approved real command succeeded and is operator accepted. No retry
occurred.** Automated tests remain separate: one starts the real worker and sends
Cancel before HelloAck, so its backend is unreachable. Other automated backend
tests use fake messages and responses. No real authentication is repeated during
checkpoint finalization.

## Build, validation and future boundary

See the native README for build commands; keep targets under /tmp. The new
Cargo.lock pins the binary dependency. Release uses panic=abort, checked overflow,
thin LTO, one codegen unit and symbol stripping; development retains diagnostics.
Inspected release worker: PIE, GNU_RELRO, BIND_NOW, non-executable GNU_STACK;
dynamic dependencies libpam, libc and libgcc_s. No special Rust compiler or package
installation, sudo, build script or automatic CMake integration is required.
Future packaging can build the two native components separately, install the
worker next to a trusted owner under an administrator-owned path, and version the
IPC contract together. The proof harness need not be installed in production.

Validation includes buffer erasure; real callback batches/all four styles; multiple
prompts; success/failure; invalid style; cancellation; malformed/oversize/NUL reply;
disconnection; version/truncation/unknown type; wrong state/ID; message count bound;
private FD spawn, CLOEXEC and child reaping; synthetic-secret stderr/panic-hook
regression; binary startup gates; and native pseudo-terminal input/restore/no-echo.
No real PAM calls are made by these automated tests. Partial allocation cleanup is
exercised, but no allocator sanitizer or proof of PAM-internal erasure is claimed.

The sandbox initially returned EPERM for private socket sends. The same mock-only
suite passed outside that sandbox after approval; it did not require network access
or elevated application privileges. Clippy with warnings denied passed. Both
unchanged C++ CTest configurations passed 4/4 tests without acquiring any lock.
Final exact Rust test totals and preservation results are recorded below.

Phase 4 proposal only: the dedicated native C++ owner consumes keyboard text events
before QML delivery, maintains bounded mutable credential bytes, and exposes only
count/input-active/Caps-Lock presentation to QML. Key events, QString conversion,
input-method/preedit state, paste and focus routing all need explicit review so
raw text cannot leak via QML signals or Qt input-method machinery. Native code
sends responses through this FD contract and immediately clears its own buffer.
QML cannot send success, select an account, launch workers or unlock. Only the
owner can associate one current attempt with its locked state and decide whether
a verified result authorizes protocol release. Do not connect these components
until input ownership, lifecycle races and cancellation are accepted for the
combined locker. Independent real PAM success is now accepted.

Remaining uncertainties: failed real password behaviour and local faillock effects;
account-expiry production policy; actual module delays and cancellation; final
native input isolation; MFA/fprintd presentation and timing; parent/child crash
recovery; packaging trust; and the outstanding Phase 2 multi-output/hotplug gates.
No Phase 4 implementation is included.

### Final validation record

- Debug worker/harness and release worker/harness build successfully, using locked
  offline dependencies and /tmp targets.
- `cargo test`: **18 passed** (1 buffer unit test, 1 native TTY test, 16 integration
  tests). Three integration entries are child fixtures that return immediately
  under the ordinary runner and are exercised by subprocess tests. No ignored or
  failed tests. Synthetic normal/error/panic-output regression passes.
- `cargo clippy --all-targets -- -D warnings`, `cargo fmt --check` and
  `git diff --check` pass. New source/docs were also checked for trailing whitespace.
- Existing production/development C++ CTest trees: **4/4 each**, unchanged sources.
- Pre-edit snapshot covered 487 existing tracked/untracked nonignored repository
  files plus PAM/live Hypr files. Only native/lock/README.md changed among those
  pre-existing files. All protected runtime/local files and /etc/pam.d match their
  starting SHA-256 content hashes. New files are confined to auth/ and this document.
- No compiled output in the new source tree; no generated binaries are tracked.
  Initial implementation validation performed no actual PAM transaction. The
  separately approved single real success is recorded below. No package installation,
  sudo, PAM configuration change, production routing change or session lock occurred.
  The operator subsequently authorized staging, commit and push of only this allowlist.

Exact changed paths (relative to repository root):

```text
linux/magi/docs/design/lock-screen-phase3-pam-proof.md
linux/magi/native/lock/README.md
linux/magi/native/lock/auth/.gitignore
linux/magi/native/lock/auth/Cargo.toml
linux/magi/native/lock/auth/Cargo.lock
linux/magi/native/lock/auth/src/lib.rs
linux/magi/native/lock/auth/src/main.rs
linux/magi/native/lock/auth/src/pam.rs
linux/magi/native/lock/auth/src/process.rs
linux/magi/native/lock/auth/src/protocol.rs
linux/magi/native/lock/auth/src/secret.rs
linux/magi/native/lock/auth/src/bin/magi-auth-harness.rs
linux/magi/native/lock/auth/tests/proof.rs
```

## Operator acceptance — real ordinary-user PAM success

The operator explicitly accepted Phase 3 after exactly one approved non-locking
real PAM attempt. The existing `hyprlock` service authenticated logged-in UID 1000
using the reviewed debug worker and native harness. The result was `Success`;
harness PID 494530 exited with status 0 and worker PID 494535 exited cleanly.
The observer verified both processes absent afterward. No retry occurred.

The observer confirmed echo suppression and equality of the complete saved termios
state before/after the run, including restored echo. The operator entered the
credential directly into the terminal; no response content, credential length,
PAM_AUTHTOK or raw PAM text was captured or logged. The observer intentionally did
not capture PAM message types. **No claim is made about which conversation styles
the live stack exercised**, nor that it exercised all styles.

No authentication error was reported. Ghostty emitted unrelated GUI/theme and
shell-integration warnings. No session lock or Phase 2 binary was invoked. All
499 snapshotted files matched after the test, including PAM configuration,
Hyprlock, Hypridle, production routing and protected operator-local state.

### Proven by implementation and live success

- The Rust worker builds and runs as an ordinary user; direct libpam FFI works on
  this machine and the existing `hyprlock` service authenticates the logged-in user.
- Private inherited AF_UNIX/SOCK_SEQPACKET IPC works across parent/child processes.
- Credential entry remains outside QML; hidden terminal input and full terminal
  state restoration work. QML receives no raw credentials.
- Worker and parent cleanup succeed. The bounded authentication-result boundary
  returns real success; failure categories are covered by automated tests, not a
  live wrong-password attempt.
- This PAM proof requires no compositor/session-lock dependency.

### Proven by automated tests

- PAM_PROMPT_ECHO_OFF, PAM_PROMPT_ECHO_ON, PAM_TEXT_INFO and PAM_ERROR_MSG;
  multiple prompts and batches through the actual callback with a fake backend.
- Success/failure categories, malformed/oversized IPC, cancellation, disconnects,
  worker cleanup and synthetic-secret non-leakage.
- Native TTY echo suppression/restoration and owned-buffer cleanup within the
  explicitly documented Rust/FFI ownership limits. No PAM-internal erasure claim.

### Still unproven / future gates

- Combined session-lock + PAM lifecycle, including worker failure while locked.
- Native lock-screen keyboard credential capture and production QML integration.
- Failed real password path, live MFA/fingerprint and broader PAM module stacks.
- Production account policy and retry/rate-limit UX.
- Earlier Phase 2 multi-output/hotplug, recovery and packaging trust gates.

Phase 2 independently proved the native session-lock owner; Phase 3 independently
proved the Rust PAM worker. The architecture is ready for a later integration
milestone: native Qt/Wayland locker → private inherited IPC → Rust worker → PAM.
QML remains presentation-only, raw credentials must never pass through it, and
successful authentication remains a result only. The worker must never directly
unlock the compositor. No components are integrated by this checkpoint.

The final allowlist was derived again from the working tree and matches the
13 paths above. Acceptance documentation adds no path. Finalization reruns only
the locked/offline automated Rust tests, Clippy, formatting and whitespace checks;
unchanged C++ sources retain their previously passing 4/4 tests in both builds.
No real authentication or session-lock test is repeated. Phase 4 has not begun.
