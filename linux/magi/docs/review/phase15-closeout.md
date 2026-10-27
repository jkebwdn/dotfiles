# Phase 15 consolidation review

Reviewed 2026-10-27. Settings schema remains **22**. No new feature was added.

## Environment cleanup

The [file-level reconciliation](phase15-worktree-reconciliation.md) records all
124 unique versions: 62 superseded, 62 historical-only, no missing accepted behavior
and no recovered production code. All 16 obsolete home worktrees were removed after
individual reconciliation; three absent registrations were pruned. Merged development
branches `fix/launcher-lifecycle` and `phase13b` were deleted; no remote branch was
deleted. Only `~/dotfiles` remains registered. No home archive or permanent Phase 15
worktree was created.

The temporary baseline reproduction worktree was also removed. The earlier audit native build and four disposable Profile probe/location helpers
were removed after their source and purpose were verified. New native builds use
TemporaryDirectory and remove themselves. Protected snapshots, regression
logs and focused visual evidence remain under `/tmp` for review. Older ambiguous
display-preview/test roots are retained: naming alone does not prove ownership or
that their state is disposable. XDG runtime, current/previous theme generations,
rollback journals, lock state and user assets were deliberately retained.

## Source and architecture review

The only runtime correction is the authorized shared SettingsRow parent-width sizing
fix. Its baseline cause, negative control and visual/native acceptance are documented
in [the Profile review](phase15-profile-layout.md). No speculative dead-code removal
was made. TrayOverflow has live consumers; migrations remain compatibility code;
retired tray visibility is only scrubbed during normalization; no abandoned Audio
auto-switch implementation remains.

[Current architecture](../architecture/current-system.md) inventories services and
state owners. Theme Orchestrator publishes application artifacts; appearance composes
through it and global blur owns separate compositor properties. Audio expresses
intent through PipeWire while WirePlumber owns routing. Bluetooth has one pairing
coordinator and an application-scoped Agent1. Native lock/PAM retains security
authority; QML remains presentation. No competing writer was established.

The keybind and IPC review found no duplicate MAGI shortcut or stale target requiring
removal. Canonical [bindings](../keybindings.md) include Super+A Audio and Super+T
inline Tray toggling. Schema 22 and historical migrations remain intact. A stale
schema-20 backup trigger is documented as deferred reliability debt; no operator
Settings normalization or backup deletion was performed.

Performance debt includes existing bounded status polling and duplicated test setup.
No new polling or startup/reload actions were introduced. The bounded security review
established no critical vulnerability; native transport limitations are not a security
pass. Logs and tests keep credentials out of diagnostic output. See [security](../security.md),
[generated-state ownership](../generated-state.md) and [technical debt](../technical-debt.md)
for evidence and limits.

Legacy shell package queries found Waybar, swaync/swaync-git, Noctalia, Hyprpanel,
Matugen, awww and cliphist absent. No system uninstall is proposed. Historical
references remain historical. No icon artwork was changed; application icons retain
system ownership. Python bytecode is now ignored locally within MAGI.

## Documentation and verification

Canonical architecture, testing, known warnings, generated state, security, keybinds,
roadmap and closeout documents now take precedence over chronological phase records.
Useful historical records and galleries are retained. Greeter is not active roadmap
work; TTY login is accepted. AGENTS.md requires removal of completed worktrees after
accepted, committed, pushed, synchronized and protected-state-verified work.

The operator confirmed Profile with long identity text and a pinned preview, plus
Bar, Apps, Audio, Bluetooth, Tray and Settings smoke checks. The shell reloaded cleanly.
Final canonical matrix: **85 commands, 81 PASS, 0 FAIL, 4 ENVIRONMENT, 0 SKIPPED**.
The clean native build succeeds; transport limitations remain explicit, not security
passes. Launcher delayed-write/no-EPIPE passes. See the regression record for internal
native counts and the machine-readable log index.

Final source inventory: **47 paths: 18 added, 28 modified, 1 deleted** (rename detection
disabled; the historical expected18 helper is replaced by expected-current). This
includes the one minimal runtime fix, test/tooling reconciliation and canonical docs.
All 21 protected entries remain unchanged; Settings, local dotfiles, icon artwork and
Yazi symlinks are excluded from staging. Index and synchronization are checked during
Git closeout. No subsequent phase is started.
