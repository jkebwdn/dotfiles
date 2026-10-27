# Current test environment limits

Verified during Phase15 on 2026-10-27. These are not blanket warning suppressions.

| Evidence | Classification / handling |
| --- | --- |
| Private D-Bus daemon reports `Failed to start message bus` and `Operation not permitted` in Bluetooth transport / Notifications protocol harnesses | ENVIRONMENT. Keep tests intact and run on a host permitting private buses. No real session service is needed. |
| GdkPixbuf valid PNG decode reports `D-Bus error` and `Operation not permitted` | ENVIRONMENT only when Clipboard has exactly the two known image errors and an independent valid-PNG probe confirms the transport denial. Other failures remain FAIL. |
| Native lock SOCK_SEQPACKET send returns EPERM; transport-dependent CTest/Rust proofs fail | Host transport verification required. Build succeeds; this is not a security pass. Do not weaken authentication or frame validation assertions. |
| Offscreen window masks / nonexistent Hyprland socket / Quickshell IPC server unavailable | Harness-specific expected platform limitations. The runner supplies a synthetic nonexistent compositor signature; no live compositor needed. Unexpected QML warnings/errors still fail. |
| Host SSH configuration unavailable inside sandbox | Git transport limitation, not a test failure. One guarded host helper at most when a push is authorized. |

The old icon-fallback Control Centre opening failure was repaired in the fixture;
it is no longer an accepted warning. Old schema, catalogue and theme-label failures
are test debt addressed in Phase15, not permanent known failures. A Wayland text-input
warning recorded in historical native logs was not reproduced by this offscreen
matrix; do not use it to excuse unrelated errors.
