# Phase 10C.1 — Power & Idle

## Audit before implementation (2026-10-21)

Baseline 0db5535264da073984687f4d6ceda8ee4ff1b78a, divergence 0 0.
Implementation uses an isolated detached worktree; the watched main tree and
operator settings remain unchanged. Production activation is prohibited in this pass.

Installed Hypridle 0.1.8-2 / binary v0.1.8, MAGI Lock 0.1.0-3. Canonical
`linux/t15g/hypr/.config/hypr/hypridle.conf` is the stowed default input.
Hyprland's `hyprland.start` callback runs `hl.exec_cmd("hypridle")`. Historical
native audit confirms direct process ownership, not the vendor user unit. The
current user bus is inaccessible to this environment; current ownership must be
reconfirmed at the live gate. The vendor unit is Type=simple, Restart=on-failure,
PartOf graphical-session.target. No config reload/check option is advertised.

Canonical policy: 300-second loginctl lock-session, 600-second DPMS disable and
resume enable, no idle suspend. DPMS uses the host's Lua `hl.dsp.dpms` dispatcher,
not legacy `dpms off/on`. General always contains sleep-coordinated request,
inhibit_sleep=3, before-sleep loginctl lock-session and after-sleep DPMS enable.
Existing manual power actions use systemctl/logind; idle suspend will use explicit
`/usr/bin/systemctl suspend`, as the installed Hypridle example does. No lock code,
PAM, keybindings, lid policy or Hyprmon changes are required.

SettingsStore has a validated JS document/effective model, 250ms debounce,
optimistic conflict checks, atomic Python persistence, unknown-field preservation
and future-schema read-only behavior. Settings does not rewrite on initial read.
Power & Idle will extend this transaction boundary rather than write config in QML.
Caffeine is one shared requested flag plus the fleet's one Wayland IdleInhibitor;
no D-Bus or sleep inhibitor is created by Caffeine. Fullscreen itself is not a new
policy input; client/protocol inhibitors keep their current effect.

## Ownership decision

A: rewriting the stowed canonical config would dirty source on each selection and
mix source with user policy: rejected. B: generated full runtime config selected
with --config gives deterministic complete ownership: chosen. C: static include
is supported, but still needs daemon restart and creates missing-include/bootstrap
risk without avoiding startup ownership migration: rejected. A parallel second
daemon is forbidden. The canonical config remains unchanged as rollback source.

Tracked Python renderer/policy and a deployment-only user service define behavior.
Generated `~/.local/state/magi/power-idle/active.conf` (or XDG_STATE_HOME equivalent)
is private runtime data. A one-time approved direct-process → user-service handoff
is necessary; this pass supplies preparation/enrollment and service files without
installing, enabling, stopping or restarting anything. Not enrolled means policy
changes fail with a useful diagnostic; migration/default reads never activate.

## Sources inspected

Local: /usr/share/hypr/hypridle.conf, /usr/lib/systemd/user/hypridle.service,
installed --help/--version, canonical config, SettingsStore/persist.py,
Caffeine.qml/BarFleet.qml, MAGI Lock Phase 7/8/9 accepted checkpoints.
Official sources inspected 2026-10-21, Hypridle tag v0.1.8:
- https://github.com/hyprwm/hypridle/blob/v0.1.8/src/main.cpp — parses config before
  compositor connection; no reload/check CLI.
- https://github.com/hyprwm/hypridle/blob/v0.1.8/src/config/ConfigManager.cpp —
  listener/source syntax, inhibitor defaults, errors can be logged then ignored.
  Zero listeners logs No rules configured; it does not disable general commands.
- https://github.com/hyprwm/hypridle/blob/v0.1.8/src/core/Hypridle.cpp — constructor
  exits before D-Bus/events if Wayland unavailable; mode 3 lock-notify and sleep
  inhibitor behavior; no signal reload hook. Startup health must prove readiness,
  not merely a live PID. No upstream implementation code copied.
- https://wiki.hypr.land/Hypr-Ecosystem/hypridle/ — current documentation agrees on
  three inhibitor classes, opt-out defaults and user-service startup alternatives.

## Implemented model and UI

Schema advances once, 14→15. `powerIdle` stores integer seconds:
`lockAfter:300`, `displayOffAfter:600`, `suspendAfter:0`. Zero means Never and omits
only that idle listener. General sleep/lock/wake commands always remain. Unknown
fields are retained; schema 16+ remains read-only. Initial reads do not persist
migration or activate a daemon. Actual policy changes pass through the same
Python writer used for Settings, so generic set/reset/all paths cannot bypass it.
No idle-suspend listener appears in defaults.

Lock/display choices: 0, 60, 120, 300, 600, 900, 1800, 3600. Suspend choices:
0, 300, 600, 900, 1800, 3600, 7200. Enabled values, in lock/display/suspend order,
must be nondecreasing; Never values are skipped. Thus lock 5/display Never/
suspend 30 is valid, as is lock Never/display Never/suspend 5 because sleep locking
is mandatory independently of idle locking. Equal timers are accepted; before-
sleep coordination remains the security barrier if idle callbacks race.

The production Settings page uses existing page/row/selector/button/theme
components. Three selectors edit a local draft; Apply submits the whole policy,
which avoids intermediate invalid combinations. Invalid order disables Apply and
has a short explanation. Cancel discards the draft. Normal shared pending/saved/
error feedback handles persistence and activation failure; Reload from disk
restores last saved values after failure. No raw logs or debug card is shown.

## Generation, validation and activation

The first-party renderer emits stable UTF-8 bytes with no timestamps or shell
interpolation from values. A strict reverse structural check requires exactly
the renderer's output, preventing unknown or duplicate commands/listeners.
Explicit paths retain the accepted request helper and host Lua DPMS commands.
All required binaries are checked before activation. The audited native parser
runs in a new private directory with a minimal environment, no inherited file
descriptors, an absent Wayland socket and absent session/system D-Bus sockets.
It parses then exits before compositor/D-Bus initialization or any command can
execute. This is not a successful daemon-start test. Version mismatch fails closed
for compatibility review. Other parse errors fail even though Hypridle itself
would ignore faulty entries. All-Never permits only the precise zero-rules notice.

The adapter atomically writes mode-0600 sibling temporaries, fsyncs file and
parent directory, and renames. A writer flock serializes policy transactions;
the existing Settings lock and stale-content checks serialize Settings saves.
The activation sequence is:

1. Validate new values/render/native parse and required commands.
2. Require explicit enrollment, no interrupted journal, and active config matching
   the prior saved policy; verify one healthy managed instance.
3. Refuse known active D-Bus/logind idle inhibitors or sleep preparation.
4. Save previous.conf and pending.json; atomically replace active.conf.
5. Restart only magi-hypridle.service. Verify stable MainPID, exact config argv,
   exactly one same-user Hypridle, and current-invocation journal evidence of
   mode-3 inhibition and a sleep inhibitor FD. Type=simple alone is insufficient.
6. Persist Settings with a second conflict check, then clear the transaction marker.

Failure before replacement leaves the old policy untouched. Restart/health/save
failure restores the old config and restarts/verifies it. A failed Settings
replacement durability step also restores the previous settings bytes. Rollback
failure has a distinct diagnostic and keeps pending.json. Abrupt writer death
requires explicit `recover` of last saved Settings; the adapter blocks subsequent
edits rather than silently assuming the pending policy is committed. A power loss
may leave a pending marker after a successful save; recover converges to the saved
policy. See deployment/README-power-idle.md for the non-executed handoff/recovery.

## Suspend and inhibitor boundaries

No MAGI Lock/authentication/PAM code, native action route or coordinator contract
changes. Every generated policy retains sleep-coordinated request, mode 3,
before-sleep loginctl lock-session and after-sleep DPMS enable. Idle suspend calls
systemctl suspend, which enters the existing logind/Hypridle path. No second
competing sleep inhibitor is added. Manual locking and hibernate are unchanged.
The accepted logind delay/inhibitor limitations still apply; this is not a new
security proof of suspend readiness. Native live acceptance remains required.

Hypridle defaults continue respecting Wayland, D-Bus and systemd idle inhibitors;
no ignore flags or per-listener overrides are emitted. Existing Caffeine holds
one Wayland inhibitor on the fleet's main bar. Neither policy writer nor service
controller changes Caffeine.requested, creates a new inhibitor, or reloads MAGI.
Synthetic tests prove requested/bound/active behavior and preservation through a
policy failure and output changes, not physical playback inhibition.

Restart has unavoidable effects: timers restart, Wayland notifications rebind,
and Hypridle-owned D-Bus ScreenSaver cookies cannot be transferred. The adapter
checks the pinned daemon's latest logged inhibitor count and logind sleep state,
refusing updates with known active inhibitors. This is conservative operational
protection, not an atomic protocol barrier: a new inhibitor or sleep request can
race the final check and restart; journals may lag. This limitation requires
operator review and native testing with playback/presentation/Caffeine before
production handoff. A fully seamless D-Bus transfer would require upstream reload
support or a persistent proxy/coordinator, outside this narrow milestone. No
claim is made that restarting recreates a previous client's cookie.

Lid-close/logind policy, docked behavior, AC/battery profiles, idle hibernate,
monitor policy/Hyprmon and Phase 10C.2 remain untouched. A future AC/battery model
can resolve a selected profile into this same three-field validated effective
policy and reuse rendering/transactions; no profile UI or selection exists now.

## Automated validation and preview

Tests use fake service controllers or disconnected native parsing; none stops,
restarts, locks, DPMS-disables or suspends the production desktop. Coverage:
defaults/all Never/lock only/display Never/suspend enabled, deterministic listener
sets, immutable suspend commands, invalid durations/order, unknown/future schema,
lossless v14 migration, validation failure, restart failure, unhealthy/duplicate/
missing service, save failure, rollback failure/recovery, enrollment and inhibitor
guards, success ordering, real-controller readiness parsing, Settings UI/error
feedback, and Caffeine state lifetime.

[Production-component preview](previews/phase10c1/power-idle.png) shows defaults:
5 minutes, 10 minutes, Never. It is a direct Qt offscreen software capture, not
an invented mockup; it does not claim native GPU or compositor acceptance.

## Later live acceptance — NOT EXECUTED

Approve the service ownership migration and restart/inhibitor limitations first.
The proposed startup change is documented, not applied. Capture live process,
settings/log offsets and saved state, confirm the original policy and one daemon,
then perform the reviewed handoff/enrollment with rollback ready.

A. Verify 300/600/0 and mandatory mode-3/lock/wake contract after enrollment.
B. Temporarily select a short supported lock timeout; allow natural idle, verify
   MAGI Lock, explicit lock independence and one clean unlock.
C. Test a short display timeout with valid ordering; verify DPMS disable/input
   enable and resume display recovery on the host Lua path.
D. Keep suspend Never initially. Check real Caffeine on/off, playback and
   presentation inhibitors, refusal while known D-Bus inhibition is active, no
   duplicate daemon, and saved/error feedback after each change.
E. Only with separate explicit approval, enable short idle suspend; verify actual
   compositor lock readiness before sleep, safe resume input, DPMS recovery and
   one clean unlock. Do not substitute an explicit lock for this integration test.
F. Restore 300/600/0 (or explicitly chosen preferences), verify one healthy
   service, no pending transaction, preserved unrelated Settings and startup
   ownership across a later session. Do not run the native lock torture suite.

## Implementation location and review gate

The implementation is uncommitted in the isolated worktree recorded in the final
report. Main/watched sources, live settings, canonical hypridle.conf and production
processes were not changed. No service has been installed, enabled or enrolled.
No native policy activation is authorized by this implementation pass. Applying
the runtime source to the watched tree is itself a later reviewed step. The
startup handoff and inhibitor-transfer limitation are explicit review decisions,
not silently assumed approvals.


## Final isolated results

- `python tests/phase10c1/run.py`: PASS — 17 adapter/transaction/static-contract
  tests, disconnected native parser, schema migration, production page and Caffeine.
- `python tests/settings/run.py`: PASS — schema, atomic persistence, five fixtures.
- `python tests/settings/presentation.py`: PASS — all pages including Power & Idle,
  keyboard/palettes, responsive bounds, reset and drafts.
- `python tests/settings/actions.py`: PASS — power/VPN and dry-run action boundary.
- `python tests/phase10a/run.py`: PASS.
- `python tests/phase10b/run.py`: PASS — output, geometry, surface/shortcut routing.
- Separate v14 fixture copied from the real operator snapshot: lossless migration
  PASS; live settings were read/snapshotted, never written.
- `git diff --check`: PASS. No security/native lock torture suite was run.

All protected hashes (including canonical hypridle.conf) and the flavor symlink
match the initial snapshot. The main worktree retains only its original 14 dirty
operator paths. The live MAGI log gained zero bytes during implementation. Both
indexes remain empty; no staging, commit or push occurred. Runtime candidate/
state files were confined to disposable test directories, not Git.

Exact Phase 10C.1 path inventory: **30** (19 modified, 11 added, 0 deleted).
The preview PNG is an intentional review artifact; no active.conf, pending journal,
service enrollment or bytecode cache is included.

### Modified

```text
linux/magi/.config/quickshell/magi/components/settings/SettingsContent.qml
linux/magi/.config/quickshell/magi/settings/SettingsMigrations.js
linux/magi/.config/quickshell/magi/settings/SettingsSchema.js
linux/magi/.config/quickshell/magi/settings/SettingsStore.qml
linux/magi/.config/quickshell/magi/settings/persist.py
linux/magi/README.md
linux/magi/docs/README.md
linux/magi/docs/architecture.md
linux/magi/docs/decisions.md
linux/magi/tests/calendar/schema.cjs
linux/magi/tests/clipboard/schema.cjs
linux/magi/tests/emoji/schema.cjs
linux/magi/tests/launcher/schema.cjs
linux/magi/tests/phase10b/policy.cjs
linux/magi/tests/settings/presentation.qml
linux/magi/tests/settings/run.py
linux/magi/tests/settings/schema.cjs
linux/magi/tests/settings/store.qml
linux/magi/tests/wallpaper/schema.cjs
```

### Added

```text
linux/magi/.config/quickshell/magi/components/settings/pages/PowerIdlePage.qml
linux/magi/.config/quickshell/magi/settings/power_idle.py
linux/magi/deployment/README-power-idle.md
linux/magi/deployment/systemd/magi-hypridle.service
linux/magi/docs/design/phase10c1-power-idle.md
linux/magi/docs/design/previews/phase10c1/power-idle.png
linux/magi/tests/phase10c1/caffeine.qml
linux/magi/tests/phase10c1/policy.py
linux/magi/tests/phase10c1/presentation.qml
linux/magi/tests/phase10c1/run.py
linux/magi/tests/phase10c1/schema.cjs
```

## Controlled integration preflight — 2026-10-21

The operator's desktop audit reports saved schema 14 Settings, legacy Hypridle
PID 32456 (`/usr/bin/hypridle`, argv `hypridle`), inactive/disabled vendor unit,
and no installed MAGI unit. Logind is not preparing sleep; its reported inhibitors
are sleep-delay coordinators, with no idle inhibitor. All three reported Hyprland
client `inhibitingIdle` fields are false. This is preflight evidence, not managed
service or live lock/DPMS acceptance.

The integration review added a live Caffeine guard at the Settings boundary and
a Hyprland-client inhibitor query in the adapter, supplementing the Hypridle
D-Bus/logind count. Apply refuses known active inhibition with concise feedback.
The check-to-restart race remains; these checks do not eliminate it. Explicit
unchanged Apply now performs the same validated transaction, enabling the
behaviour-neutral first acceptance. Invalid daemon configuration exits 78; the
unit excludes this exit from restart and limits other restarts to two per minute.

The updated 19-case adapter suite, schema/UI/Caffeine suite and Settings suite
pass in isolation. The source set is now 31 paths (20 modified, 11 added).
Integration stopped before any source copy because the desktop shell PID was
not visible in the agent process namespace; a fresh desktop shell check is
pending. No production policy, daemon ownership or startup source changed.

### Watched-source integration

After the operator confirmed one Quickshell instance (PID 1573), saved schema-14
Settings and Caffeine off, the reviewed 31 paths were integrated. A fresh settings
copy and log offset were captured beforehand. The automatic reload logged
“Configuration Loaded” without warnings; disk settings remained byte-identical.
Desktop-side effective-schema, persistence and visual confirmation are pending.
No Hypridle service installation, activation or startup retirement has occurred.

The desktop migration helper subsequently stopped on Settings state `error`:
`Power & Idle setup is not active yet; previous policy is unchanged.` Effective
in-memory policy was 600/900/1800, while disk settings remained byte-identical to
the schema-14 snapshot. This confirms the unenrolled adapter refused the request;
it is not a successful apply or suspend acceptance. The origin of the unsaved
selection is awaiting operator confirmation before discard/reload. No daemon
handoff or live timer test has run.

The operator confirmed these were manual UI test selections and authorized
discarding them. The desktop helper now reloads the untouched saved policy
before persisting schema 15; no timer activation is part of this operation.

### Live schema migration confirmed

The operator ran the integrated check successfully: saved schema 15, effective
policy 300/600/0, Caffeine false, one MAGI instance PID 1573. Semantic comparison
shows only the persisted schemaVersion changed; powerIdle currently uses schema
defaults until explicitly saved through its page. Every other protected file
matches the preflight snapshot. The earlier 600/900/1800 UI selections were
discarded with operator authorization and never activated.

Integrated regression results: Phase 10C.1 adapter/schema/presentation/Caffeine,
Settings persistence, Settings presentation, system actions, Phase 10A and
Phase 10B pass. Hypridle ownership migration remains pending.

### Managed ownership proven; live timer acceptance pending

The operator executed the reviewed handoff: legacy PID 32456 stopped; exactly
one managed PID 536438 became healthy and enrolled. The active file is
`/home/jkebwdn/.local/state/magi/power-idle/active.conf`, policy 300/600/0.
The user service is active but disabled: graphical-session.target is inactive.
The existing Hyprland session-start callback now imports the named compositor
and session environment variables and starts magi-hypridle.service explicitly.
Only the legacy Hypridle line was replaced, after managed health was proven.
Reversing that one replacement reproduces the protected file exactly; a
startup-only patch against HEAD is retained outside Git for later hunk isolation.
No staging was performed. Fresh-login startup has not yet been tested.

The original tracked hypridle.conf is retained unchanged as a documented emergency
fallback, not a second live authority. No real lock, DPMS or suspend acceptance
has run in this gate yet. Default UI Apply and visual confirmation are next.

### Default Apply, idle lock and DPMS accepted

The unchanged default UI Apply succeeded: saved schema 15, one managed PID
537032, 300/600/0, and verified mode-3 sleep coordination. The one-minute lock
policy 60/600/0 then ran under PID 537496. The operator confirmed timed lock,
password input and clean unlock, and restored defaults.

The subsequent 60/120/0 DPMS policy ran under PID 538707 (desktop health output
shown in the operator screenshot). The operator confirmed all instructed checks:
idle lock, display off, input-driven display wake with lock retained, clean unlock,
and restoration to 300/600/0. This is lock/DPMS acceptance, not suspend acceptance.
Caffeine refusal, invalid-order UI feedback, representative manual lock and final
health evidence remain pending. No real suspend has been requested in this gate.

## Controlled gate final result — 2026-10-22

Caffeine refusal passed against PID 540397: unchanged PID and identical active
policy bytes, with the concise inhibition diagnostic. Invalid 10-minute lock /
5-minute display ordering showed feedback and disabled Apply in the supplied
production screenshot. The operator used Reload from disk to discard the draft;
this was safe and did not change active policy. That first “final” check still
showed Caffeine true and did not prove recovery. After correction, the operator
reported saved schema 15, Caffeine false, one managed PID 547695 and 300/600/0.
The changed PID proves successful activation after disabling inhibition. The
operator also explicitly confirmed manual lock/unlock passed after the changes.
One MAGI shell and managed mode-3 sleep coordination were verified by the desktop
helper. No real suspend test was performed.

The live Power & Idle controls were exercised successfully; the supplied screen
capture documents the invalid-order presentation. The original production
component preview remains under previews/phase10c1/power-idle.png.

All 19 adapter/native-parser/transaction tests passed, including all-Never's
precisely accepted Hypridle 0.1.8 notice, failed validation, activation rollback,
duplicate/missing daemon and interrupted recovery. Schema, production Power &
Idle presentation/Caffeine, Settings persistence/presentation/actions, Phase 10A
and Phase 10B regressions passed after integration. Generated-config assertions
retain lock_cmd sleep-coordinated, inhibit_sleep=3, before-sleep locking and
DPMS recovery for every policy. No destructive native suspend suite ran.

Protected-state verification: the only settings semantic changes from the gate
snapshot are schemaVersion 14→15 and powerIdle 300/600/0. Reversing the one
intentional Hyprland startup replacement reproduces its snapshot exactly. All
other protected file hashes and the Yazi flavor symlink match; canonical
hypridle.conf is unchanged. No Lock, PAM, Hyprmon or lid-policy source was edited.

Remaining limits: real suspend acceptance is a separate explicit gate;
fresh-login startup is not yet tested; known inhibitor check-to-restart race is
not eliminated. The daemon configuration/version validation and saved recovery
artifacts remain available. Do not stage or commit until the later gate.

### Exact source inventory at this gate

32 source paths: 21 modified (including only one intentional hunk in the
operator-dirty Hyprland file), 11 added, 0 deleted. settings.json is excluded.
The startup-only patch against HEAD is outside Git; never stage the whole dirty
Hyprland file blindly. All paths below are repository-relative:

```text
linux/magi/.config/quickshell/magi/components/settings/SettingsContent.qml
linux/magi/.config/quickshell/magi/components/settings/pages/PowerIdlePage.qml
linux/magi/.config/quickshell/magi/services/Settings.qml
linux/magi/.config/quickshell/magi/settings/SettingsMigrations.js
linux/magi/.config/quickshell/magi/settings/SettingsSchema.js
linux/magi/.config/quickshell/magi/settings/SettingsStore.qml
linux/magi/.config/quickshell/magi/settings/persist.py
linux/magi/.config/quickshell/magi/settings/power_idle.py
linux/magi/README.md
linux/magi/deployment/README-power-idle.md
linux/magi/deployment/systemd/magi-hypridle.service
linux/magi/docs/README.md
linux/magi/docs/architecture.md
linux/magi/docs/decisions.md
linux/magi/docs/design/phase10c1-power-idle.md
linux/magi/docs/design/previews/phase10c1/power-idle.png
linux/magi/tests/calendar/schema.cjs
linux/magi/tests/clipboard/schema.cjs
linux/magi/tests/emoji/schema.cjs
linux/magi/tests/launcher/schema.cjs
linux/magi/tests/phase10b/policy.cjs
linux/magi/tests/phase10c1/caffeine.qml
linux/magi/tests/phase10c1/policy.py
linux/magi/tests/phase10c1/presentation.qml
linux/magi/tests/phase10c1/run.py
linux/magi/tests/phase10c1/schema.cjs
linux/magi/tests/settings/presentation.qml
linux/magi/tests/settings/run.py
linux/magi/tests/settings/schema.cjs
linux/magi/tests/settings/store.qml
linux/magi/tests/wallpaper/schema.cjs
linux/t15g/hypr/.config/hypr/hyprland.lua
```

Runtime artifacts excluded from Git: user unit
`~/.config/systemd/user/magi-hypridle.service`; generated active.conf,
previous.conf, managed.json and writer.lock under
`~/.local/state/magi/power-idle/`; acceptance helpers/evidence and process
environment snapshots under /tmp. No pending transaction is present in the
reported final health. The unit is active but disabled, started explicitly by
the Hyprland session callback because graphical-session.target is inactive.

## Final suspend and startup gate — 2026-10-22

Preflight verified saved schema 15, 300/600/0, Caffeine off, unlocked active
Wayland session, no known idle inhibition and no sleep preparation. Executing
the exact Hyprland startup command against the running unit retained Hypridle
PID 547695, MAGI PID 1573, settings hash and active-config hash. The deployed
unit matched repository source. This proves idempotent startup invocation, not
a fresh login; no logout/reboot was performed and fresh login remains a
post-commit observation. The unit remains explicitly started by the Hyprland
callback because this host's graphical-session.target is inactive.

The operator explicitly confirmed readiness and invoked `systemctl suspend`
once with Suspend-after still Never. Captured journals show PrepareForSleep(true),
sleep-coordinated lock request, Wayland locked notification and inhibitor release
before kernel suspend entry. On resume they show PrepareForSleep(false), the
accepted DPMS-on command, still-locked resume state, early input deferred pending
initial modifiers then replayed exactly once, and one authenticated unlock.
The operator confirmed lock immediately visible, no desktop exposure, immediate
keyboard input with no first-character loss, password/unlock and normal shell
return. Post-resume checks retained PID 547695, unchanged policy/settings hashes,
one MAGI shell and eDP-1 DPMS on. No coordinator failure, restart loop or failed
lock handoff appears in the captured sequence.

System journals also contain an xHCI resume reinitialization message, a BlueZ
AlreadyExists message and NetworkManager forwarding warnings; these are recorded
without claiming the whole system journal is warning-free. The operator observed
no resulting display/input issue. Existing SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=0
was reported by systemd; this gate did not change it or other lock/sleep policy.

Temporary 300/600/1800 Apply succeeded under PID 558610 with exactly one listener
calling `/usr/bin/systemctl suspend`. It was immediately restored without waiting
for the timer. Final saved 300/600/0 under PID 558813 has zero suspend listeners,
Caffeine false, healthy mode-3 coordination and one MAGI instance. This validates
listener generation/activation; actual idle-triggered suspend was not exercised.

Final focused regressions all passed: 19 adapter/renderer/native-parser/
transaction/rollback/ownership/inhibitor/contract cases, schema 15 migration,
Power & Idle presentation/Caffeine, Settings persistence/presentation/actions,
Phase 10A and Phase 10B. No unrelated destructive lock suite was run.

Temporary desktop helper issues (loginctl self-session resolution, property
argument syntax, changing Quickshell uptime text and journal cursor headers)
were corrected without relaxing health requirements. The successful reruns
provided the evidence above; the earlier failed helper runs did not request
suspend or alter policy.

The exact source inventory remains 32 paths (21 modified, 11 added, zero deleted).
The known inhibitor check-to-restart race remains documented, not eliminated.
Final operator acceptance is required before staging or commit.

### Final operator acceptance

The operator explicitly accepted Phase 10C.1 and authorized precise staging,
commit and normal push with subject `magi: add power and idle settings`. All
listed live results and final 300/600/0 state were confirmed, with fresh-login
observation pending and the inhibitor race accepted. settings.json and unrelated
local changes are excluded; only the startup ownership hunk is eligible in
hyprland.lua. Phase 10C.2 is not authorized by this finalization.
