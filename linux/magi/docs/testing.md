# Testing MAGI

Run from `~/dotfiles`. Tests, source and fixtures are self-contained in this repository;
old home-directory development worktrees are not required. Schema 22 is current.

## Fast and affected-area checks

List the explicit offline matrix:

```sh
python3 linux/magi/tests/run-all.py --list
python3 linux/magi/tests/run-all.py --only settings/catalogue --only calendar/schema
python3 linux/magi/tests/run-all.py --only phase14b/run --only phase14a/fleet
```

Repeat `--only` for exact suite IDs. Run affected subsystem checks after a change,
then the complete matrix for phase closeout. Historical phase names identify
regression coverage, not frozen historical UI contracts. Preserve old-schema
migration inputs; current-output assertions use current defaults and the independent
`tests/settings/expected-current.cjs` expectation helper.

## Complete offline matrix

```sh
python3 linux/magi/tests/run-all.py
```

The explicit 98-command allowlist excludes live helpers. FAIL begins classified as UNKNOWN until evidence supports a narrower triage classification. Each existing harness owns
its fixtures. The runner uses offscreen software rendering, nonexistent compositor
and D-Bus endpoints, removes live display variables and capture overrides, and
records each command, exit, duration, log and classification in `results.json`.
`summary.json` is a compatibility copy. Use `--logs /tmp/magi-regression-<unique>`
to choose a **new** result directory. No logs are committed.

A harness success marker cannot override nonzero exit, assertions or Qt failure
markers. Launcher lifecycle has a 180-second allowance for its 127-second delayed
write. Other commands have a 600-second outer bound; individual harnesses may impose
shorter limits. A timeout terminates the process group. Exit 0 means all selected
commands pass; exit 1 means failure; exit 2 means only classified environment limits.
Filtered-out suites are not reported as passes.

## Native components and session acceptance

The default matrix includes `native_lock`: a clean temporary CMake/Cargo build,
all CTest cases and Rust tests. It never installs, acquires a lock or invokes real
PAM; its build root is removed automatically. Run just this entry with `--only native_lock`.
Its ENVIRONMENT classification requires the independently denied SOCK_SEQPACKET
probe, unchanged audited native source, exact known failed case sets and error
signatures; any discrepancy remains FAIL. Detailed internal counts stay in the log.
For lower-level commands, use
`native/lock/README.md` only for **offline builds/tests**, never interpret its
historical live-lock deployment instructions as authorization. Build outside the
repository; do not install/redeploy for a test-only change. Real lock/PAM tests
require a separate explicit operator gate.

Hardware/session acceptance remains distinct from offline fixtures: actual audio
routing, paired Bluetooth devices, authenticated pairing hardware, native tray
menus, physical displays and fingerprint devices. Never invoke live helper scripts
through discovery. A test/doc-only change does not require restarting production.

## Current environment limits

See [known environment limits](known-warnings.md). Never turn an unknown assertion
into an environment skip merely because it ran in a sandbox. The Phase 15
[reconciliation record](review/phase15-regression-reconciliation.md) documents
baseline reproduction and each corrected old assumption.


`theme-orchestrator/bootstrap` covers current static source fixtures independently
of the historical legacy enrollment fixtures. It asserts byte-identical source across
round trips, no-journal recognition, journal conversion/recovery, foreign-hook refusal,
and fresh/active/disabled parser or startup behavior. Native GTK theme selection and
full workstation/plugin behavior still require the operator smoke gate.

`runtime-visual/run:quality.qml` covers Phase 16 keyboard/focus rendering, Wi-Fi
accessible labels and notification idle/expiry lifecycle without a live notification bus.

`theme-orchestrator/visuals` covers optional CAVA/ascii-splash discovery, all 26
palette payloads, native parser/theme validation when installed, guarded launch
fallbacks and behavior/source preservation across enrollment round-trips.

`fetch/run` covers the read-only animated terminal fetch, deterministic geometry
snapshots and isolated PTY cleanup/input/resize behavior. It never enables startup.


`daily-polish/run`, `daily-polish/schema` and
`runtime-visual/run:daily-polish.qml` cover initial media progress and timer gating,
status role persistence/preview, connected Battery regions and production module
activation. Native limitations and optional preview generation are recorded in
[the candidate review](review/daily-use-polish.md).

## Lock/fingerprint candidate — 2026-10-30

The host offline candidate passes 23 CTest and 18 Rust checks, including an isolated
mock fprintd broker and power-intent confirmation. No actual sensor is used by these
checks. Native source hashes in native_lock.py bind sandbox exemptions to that exact
host audit; changed source cannot inherit it. Split Corners/Caps/error/biometric
geometry and production Settings controls are exercised in phase13a/presentation
and fingerprint/run. [Evidence and physical gates](review/lock-fingerprint-production.md).

Final lock validation: full 96-suite matrix plus focused final visual and audited
native reruns yields 92 PASS / 4 evidenced ENVIRONMENT / 0 unresolved FAIL or UNKNOWN.
The final installed source passes 23 host CTest and 18 Rust tests without skips.
Native pixel checks include actual 2× rendering and first-frame clock/date ink gap;
internal visual, fingerprint/password and suspend/resume acceptance are confirmed.
See [exact coverage and limits](review/lock-fingerprint-production.md).

`lock-themes/model` and `runtime-visual/run:lock-themes.qml` cover curated theme
metadata/migration, the normal gallery and responsive production presentation.
The Phase 13 designer fixtures continue exercising the preserved internal designer.
Native theme acceptance is separate; see [acceptance record](review/lock-screen-themes.md).
