# Security boundaries

This is a bounded source review and regression summary, not a formal security proof.
No new authentication, lock or pairing feature is introduced by Phase 15.

| Boundary | Authority and reviewed invariant | Evidence / remaining limit |
| --- | --- | --- |
| Session lock | Native controller owns acquisition, surfaces, input, sleep gating and unlock. Unlock consumes a current successful auth generation only when secure lock is ready. Failure/timeout/disconnect do not authorize unlock. | `native/lock/src/controller.cpp`, `wayland_owner.cpp`; controller/input/sleep tests. Synthetic transport tests need permitted SOCK_SEQPACKET. |
| Credentials / PAM | Isolated Rust worker owns PAM conversation; bounded native credential storage is wiped. QML receives presentation state, never credentials or unlock authority. | Credential/auth source and boundary fixtures; native protocol tests remain strict. No live lock or PAM invocation during consolidation. |
| Development lock build | Unsafe timer unlock is explicitly gated to development builds and rejected by production boundary checks. | Options/binary/install tests. Do not deploy test binaries. |
| Bluetooth Agent1 | Pair and registered agent share one bus connection. Only the recorded unique BlueZ owner may call Agent1; MAGI does not become the global default agent. Pending requests cancel on owner/device loss. | `bluetooth_backend.py`, coordinator/private-bus tests. Native PIN/passkey hardware acceptance remains deferred. Pairing values belong to transient protocol/UI state, not logs or Settings. |
| Desktop launching | GIO desktop-entry semantics with independent standard streams; shell lifetime does not own application output pipes. | Backend and 127-second delayed-write no-EPIPE regression. No application is launched merely by shell reload. |
| Tray | Built-in Quickshell StatusNotifier model; application menus stay native. Removal closes invalid menu state. | Tray fixtures and accepted Mullvad/Steam native tests. Application icons remain application-owned. No VPN-specific control path. |
| Generated config | Owned roots/manifests, expected-content checks, safe paths and atomic publication; conflicts preserve operator edits. | Theme, appearance, blur and Settings tests; see generated-state policy. Per-target compensation is not global atomicity. |
| IPC and status | User-session endpoints route deliberate commands to service owners. Status may contain personal device/application data. | Canonical IPC inventory. Do not publish raw operator snapshots or treat session IPC as a remote authorization boundary. |

Weather/Media lock auxiliaries are display-only snapshots with bounded preparation;
they cannot dispatch media actions, acquire credentials or authorize unlock.
Fingerprint and display physical completion remain separate hardware gates.

Logging review found structured lifecycle/status messages and transient pairing
transport, not intentional credential logging. Keep private pairing/credential
payloads out of diagnostics. Test logs use synthetic data. No security assertions
were removed to accommodate the sandbox. [Environment limits](known-warnings.md)
are not passes for the blocked transport cases.

## Fingerprint production boundary

The [accepted internal-device integration](review/lock-fingerprint-production.md)
uses unique-owner/path-pinned fprintd verification and Controller consumption of a
current, one-shot binding. Password fallback and session-lock ownership remain
independent and authoritative. Settings enroll/remove/test uses a system-authorized
helper with no unlock channel. Host tests and normal/resumed fingerprint/password
acceptance passed. Service-loss/removal/reload have synthetic coverage; physical
external-monitor testing is deferred. No biometric templates/images enter MAGI.
