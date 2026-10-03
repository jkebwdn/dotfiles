# Permanent notification ownership migration

Baseline `f3bdd43`, inspected 2026-10-03. Operator review passed and commit/push
were authorized after final reproducibility validation. This is a
startup-ownership close-out only; notification visuals/model and Clipboard are out
of scope.

## Previous state

- Hyprland's live, tracked `hyprland.lua` started `quickshell -c magi`, then
  `swaync`, then `~/.config/swaync/scripts/swaync-greeting.sh` in one startup hook.
- Packaged `/usr/lib/systemd/user/swaync.service` is `Type=dbus`, owns
  `org.freedesktop.Notifications`, restarts on failure and is disabled as a unit,
  but packaged session-D-Bus service files can activate it.
- Enabled `swaync-greeting.timer` runs a linked tracked oneshot every30 minutes.
  The script edits preserved SwayNC greeting configuration, then calls
  `swaync-client -R` and `-rs`; those clients can D-Bus-activate SwayNC. During the
  accepted notification checkpoint this caused a competing start/retry limit.
- MAGI's accepted server required manual `notifications activate` IPC once per
  process. ShellRoot PersistentProperties retained that temporary approval across
  QML reload, but deliberately reset on process restart.
- `SUPER+N` called `swaync-client -t`, another possible activation path.
- `QuickActions` retained its pre-handoff SwayNC DND adapter and queried it before
  ShellRoot completion. A production reload at20:03 reproduced this hidden path:
  the query D-Bus-activated SwayNC and it retried/fell into start-limit failure.

## Intended migration

- Production `ShellRoot` calls the singleton's existing idempotent
  `activateServer()` on completion. No delayed shell/IPC command. Keeping the
  trigger in the owning shell avoids unrelated service/test imports taking D-Bus
  ownership as a side effect.
- Remove only the two SwayNC commands from Hyprland startup and repoint `SUPER+N`
  to MAGI's existing Notification Centre IPC.
- Disable/stop `swaync-greeting.timer`, stop its oneshot, and mask
  `swaync.service`. Masking is required because merely disabling this D-Bus unit
  does not prevent activation from the packaged bus service files.
- Keep SwayNC installed and preserve all SwayNC configuration/scripts/units.
- Remove the now-obsolete automatic SwayNC DND query/set adapter. The accepted
  MAGI Settings value remains the sole DND state; no startup import calls a
  `swaync-client`. This is migration cleanup, not a DND redesign.

## Status

| Phase | State | Evidence / exact resume point |
| --- | --- | --- |
| Inspect installed startup | complete | Paths and mechanisms above verified locally |
| MAGI automatic activation | complete | First singleton-owned attempt failed focused isolation because imports could claim the bus; corrected to ShellRoot ownership; focused suite passed |
| SwayNC/Hyprland migration | complete | Exact changes shown first and approved; Hyprland3-line change, timer disabled, service masked; package/config preserved |
| Declarative reproducibility | complete | Fresh empty-target Stow simulation resolves tracked mask to `/dev/null`, installs timer definition disabled, and creates no wants links; live restowed to match |
| Clean restart/live validation | complete | Final PID143717 started without activation IPC and immediately owned name under tracked mask; toast/history/Centre/DND/runtime checks passed earlier |
| Operator review | complete | `SUPER+N` operator check and final reproducibility review passed; checkpoint accepted |

## New state

- At login Hyprland starts only `quickshell -c magi` for notifications. ShellRoot
  constructs MAGI's accepted NotificationServer during startup, before any manual
  command is needed.
- `swaync.service` is masked/inactive, so installed D-Bus activation cannot create
  a competing owner. The greeting timer definition is linked but disabled/inactive;
  neither `timers.target.wants` nor `default.target.wants` contains it.
- `SUPER+N` opens MAGI's Notification Centre. QuickActions reads/writes MAGI's
  Settings DND value and never launches a SwayNC client.
- SwayNC remains installed with configuration, scripts and tracked units preserved.

## Applied reversible system changes

Tracked `../t15g/hypr/.config/hypr/hyprland.lua`: remove direct `swaync` and greeting
startup commands; change `SUPER+N` command to
`quickshell ipc -c magi call notifications toggle`. No other Hyprland setting.

The initial live handoff used:

```text
systemctl --user disable --now swaync-greeting.timer
systemctl --user stop swaync-greeting.service
systemctl --user mask swaync.service
systemctl --user reset-failed swaync.service
```

Because the timer was a linked unit, disablement removed its live unit symlink as
well as both enablement links. The reproducibility audit below restored that unit
link through Stow without enabling it. The greeting service's stale failed marker
was reset after stopping the hung old invocation.

## Reproducibility audit

The first live mask (`~/.config/systemd/user/swaync.service -> /dev/null`) was
machine-local and absent from Git. A fresh clone therefore would have removed the
Hyprland direct start but still exposed the packaged D-Bus activatable SwayNC unit.
That was insufficient.

GNU Stow2.4.1 rejects an absolute symlink directly inside a package. The final
portable representation uses a relative package-local indirection:

```text
systemd/.config/systemd/user/swaync.service
  -> ../../../mask-targets/swaync.service
systemd/mask-targets/swaync.service
  -> /dev/null
```

`systemd/.stow-local-ignore` excludes `mask-targets` from deployment. Stow links
the user unit to the tracked relative link, whose full chain resolves to `/dev/null`.
This is independent of repository clone depth. An isolated empty-target deployment
with the installed Stow created exactly the greeting service, greeting timer and
SwayNC mask links; `readlink -f` returned `/dev/null`; no `*.wants` link existed.

Fresh deployment semantics, now documented in the repository root README:

```text
cd ~/dotfiles/linux
stow magi
cd ~/dotfiles/linux/t15g
stow hypr
stow systemd
systemctl --user daemon-reload
```

`stow magi` installs the production ShellRoot which auto-activates notifications.
`stow hypr` installs the MAGI-only notification startup and MAGI `SUPER+N` binding.
`stow systemd` installs the persistent SwayNC mask plus the optional greeting unit
definitions. It creates no enablement links, so the timer stays disabled after a
fresh clone. On a new login, MAGI is the only daemon able and configured to claim
`org.freedesktop.Notifications`.

## Files and live state changed

- MAGI: `shell.qml`, `services/Notifications.qml`, `services/QuickActions.qml`,
  `services/system_actions.py`; focused notification activation and quick-action
  tests; architecture/decision/index documentation.
- Relevant startup only: `../t15g/hypr/.config/hypr/hyprland.lua` removes two
  SwayNC startup calls and points `SUPER+N` to MAGI. No other t15g/Hyprland setting.
- Declarative systemd: new `../t15g/systemd/.config/systemd/user/swaync.service`
  relative mask link, `../t15g/systemd/mask-targets/swaync.service` `/dev/null`
  target and `../t15g/systemd/.stow-local-ignore`. Root `../../README.md` documents
  the MAGI/Hyprland/systemd Stow sequence.
- Live systemd user state now mirrors Stow: `swaync.service` masked/inactive;
  `swaync-greeting.timer` linked but disabled/inactive; greeting service inactive;
  no SwayNC wants links.
- Untouched: SwayNC package, `~/.config/swaync` contents, tracked greeting script,
  tracked timer/service sources and unrelated dirty sibling files.

## Validation results

- `python3 tests/notifications/run.py`: PASS on private session bus, including
  automatic production ownership, creation/replacement/actions/DND/fullscreen,
  QML reload and receipt after reload. No manual activation call.
- `python3 tests/settings/actions.py`: PASS after removing obsolete SwayNC adapter.
- Scoped qmllint exits0; only existing Qt `Process.exited` metadata warning remains.
- `luac -p` and live `hyprctl reload`; `hyprctl configerrors` empty.
- Clean production restart: old PID1548 killed; `quickshell -d -c magi` PID136463
  loaded with INFO-only log and immediately owned `org.freedesktop.Notifications`
  as unique name `:1.635`, before any test notification.
- Live notification ID1 produced one toast and history entry. Centre opened from
  IPC, displayed history and marked it read. Live DND ID3 was retained unread with
  zero toasts and no toast layer; preference restored to off.
- SwayNC is masked/inactive, no process exists, timer absent from timer list, and
  its journal has no entries after migration time20:08:45.
- Compositor: one main1920×1080 MAGI layer at(0,0), plus only the expected transient
  toast/Centre layer while shown; eDP-1 scale2; reservation `[0,48,0,0]`.
- Fresh PID136463 Quickshell log contains launch/config-loaded INFO only.
- Final `git diff --check` passes. Scoped qmllint exits0 with the one documented
  Qt process-signal metadata warning and no notification ownership warning/error.
- Reproducibility recheck: the live package was restowed after the empty-target
  simulation. Final clean restart produced PID143717 / unique name`:1.643`, with
  automatic activation, SwayNC still masked and timer still disabled. One main
  layer and `[0,48,0,0]` reservation remain; fresh process log is INFO-only.
- Operator confirmed `SUPER+N` opens MAGI Notification Centre before this audit;
  tracked/live binding still points to MAGI and Hyprland config errors remain empty.

## Exact intended Git paths

Only these paths belong to this checkpoint (paths from repository root):

```text
README.md
linux/magi/.config/quickshell/magi/services/Notifications.qml
linux/magi/.config/quickshell/magi/services/QuickActions.qml
linux/magi/.config/quickshell/magi/services/system_actions.py
linux/magi/.config/quickshell/magi/shell.qml
linux/magi/docs/README.md
linux/magi/docs/architecture.md
linux/magi/docs/decisions.md
linux/magi/docs/design/notifications-toasts.md
linux/magi/docs/quickshell-reference.md
linux/magi/docs/research/README.md
linux/magi/docs/research/notifications-toasts-checkpoint.md
linux/magi/docs/research/permanent-notification-ownership-checkpoint.md
linux/magi/tests/notifications/activation.qml
linux/magi/tests/notifications/run.py
linux/magi/tests/settings/actions.py
linux/t15g/hypr/.config/hypr/hyprland.lua
linux/t15g/systemd/.config/systemd/user/swaync.service
linux/t15g/systemd/.stow-local-ignore
linux/t15g/systemd/mask-targets/swaync.service
```

Explicitly exclude the pre-existing dirty
`linux/t15g/swaync/.config/swaync/config.json`, untracked Hypridle/Hyprlock files
and unrelated stray file from any future staging/commit. They were not modified by
this milestone.

## Rollback

For a persistent rollback, revert the MAGI/Hyprland changes and the three tracked
systemd-mask paths above. Restow the packages, restart MAGI so it no longer claims
the name, then restore SwayNC with:

```text
systemctl --user unmask swaync.service
systemctl --user enable --now swaync-greeting.timer
systemctl --user reset-failed swaync.service swaync-greeting.service
systemctl --user start swaync.service
```

Verify `busctl --user status org.freedesktop.Notifications` reports `swaync`.
For a temporary runtime fallback, `systemctl --user unmask swaync.service` removes
the deployed mask link, but a later `stow systemd` restores it while the tracked
mask exists. No package reinstall or SwayNC configuration restoration is necessary.
