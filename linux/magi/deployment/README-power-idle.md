# Power & Idle deployment gate

These files are **not** installed or enabled by Stow. The controlled handoff
has now been performed on the operator host; repeat installation only as an
explicit deployment or recovery operation. The design checkpoint contains the audit
and acceptance plan. The existing canonical hypridle.conf stays unchanged.

## Required reviewed handoff

1. Snapshot saved Settings, the canonical config, the one current Hypridle PID,
   executable, arguments, session environment and startup configuration. Confirm
   no sleep preparation and no active D-Bus/logind idle inhibition. Confirm the
   supported Hypridle 0.1.8 / MAGI Lock 0.1.0-3 contract. Take separate approval
   before stopping that identified production process.
2. Apply the reviewed MAGI source/schema changes from the isolated worktree after
   a Quickshell log/settings preflight. Source may auto-reload. Default migration
   remains 300/600/0 and does not activate or rewrite Hypridle.
3. Run the adapter's `prepare` operation with the normal desktop environment. It
   reads only the usual MAGI settings path and generates/validates active.conf
   under XDG_STATE_HOME/magi/power-idle. It refuses to overwrite existing state.
   It starts no service. The Python entry point is
   `~/.config/quickshell/magi/settings/power_idle.py`.
4. Install `deployment/systemd/magi-hypridle.service` into the user unit directory.
   Import the current graphical environment (WAYLAND_DISPLAY,
   HYPRLAND_INSTANCE_SIGNATURE, XDG_CURRENT_DESKTOP, XDG_SESSION_ID, XDG_SESSION_TYPE, DISPLAY where present,
   XDG_STATE_HOME when customized) into the user manager. Reload its unit files.
5. Stop only the previously verified direct process; start the named user service
   once. No broad pkill/killall or PID guessing. The daemon wrapper refuses
   startup when another same-user Hypridle exists. If managed startup fails,
   stop the managed unit, restore the exact previous executable/arguments/session
   environment, and verify one daemon plus mode-3 sleep-inhibition readiness.
6. Run `enroll`. It verifies one stable managed PID, exact config argv and
   current-invocation mode-3 sleep inhibition before writing the enrollment marker.
7. Only after that success, replace the one legacy `hl.exec_cmd("hypridle")`
   line in the existing Hyprland start callback with the managed startup line:

   ```lua
   hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_STATE_HOME XDG_SESSION_ID XDG_SESSION_TYPE XDG_CURRENT_DESKTOP DISPLAY && systemctl --user start magi-hypridle.service")
   ```

   This host's graphical-session.target is inactive, so the unit stays disabled
   and the existing session-start callback starts it explicitly. Importing the
   session environment precedes service startup. Keep the vendor unit disabled.
   Preserve every unrelated local Hyprland hunk. A login/startup acceptance remains
   separate from proof that the current managed daemon runs correctly.
8. Perform the ordered live acceptance in the design document. Do not test idle
   suspend until separate explicit authorization. Keep rollback files until done.

The user-service restart is deliberately scoped to `magi-hypridle.service`.
No other service name, command, arbitrary output path or PID is accepted from QML.
No root service, PAM change, logind lid change or extra sleep inhibitor is created.

## Recovery

Each change keeps previous.conf and a pending.json journal. Settings is written
only after successful activation/health checks. Restart/save failures restore the
old config and restart/verify it. If that recovery fails, the UI says so explicitly
and retains pending.json; it does not falsely claim protection is restored.

An interrupted transaction blocks later edits. At a reviewed live recovery gate,
run `recover`: it reads the last saved Settings policy, validates/regenerates it,
restarts only the enrolled unit, verifies health and clears the pending journal.
Do not simply delete pending.json. A service or machine restart alone is not a
transaction recovery operation; if the writer died between activation and save,
the preserved candidate may be running until explicit recovery.

Managed state is not a privileged boundary: the session user can edit their own
files. The adapter validates exact generated structure and fixed command strings;
it is intentionally not a general Hyprland configuration editor.

## Production authority and fallback

MAGI Settings is the policy authority. The managed service uses only
`$XDG_STATE_HOME/magi/power-idle/active.conf` (default
`~/.local/state/magi/power-idle/active.conf`). The tracked
`linux/t15g/hypr/.config/hypr/hypridle.conf` remains unchanged solely as the
300/600/0 emergency fallback; it is no longer read by the managed service.
Do not edit it expecting Settings policy changes.

To return to that fallback at an explicit recovery gate: stop
`magi-hypridle.service`, verify no Hypridle remains, and start `/usr/bin/hypridle`
with the recorded desktop environment and original config path. Verify one
healthy daemon and sleep coordination before restoring the legacy startup line.
Do not start both routes. The controlled migration snapshot and original
process environment are outside Git under `/tmp/magi10c1-integration-20261021-210050`;
retain them until acceptance is complete.

## Final live evidence (2026-10-22)

The exact startup command above was invoked against the active service and
preserved its PID, MAGI identity and config/settings hashes. A true fresh login
was not forced; observe it after commit. Normal `systemctl suspend` passed the
managed lock/sleep handoff and resume, including first password input. A temporary
30-minute suspend listener activated successfully and was immediately removed;
final policy is 300/600/0 with Caffeine off. The known inhibitor check-to-restart
race remains; no second sleep cycle was required for listener activation.
