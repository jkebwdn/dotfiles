# Post-0.57 consolidation review — 2026-11-05

Baseline: `e2514507cfff23324388ca05691ffdaad9d03e96`, synchronized with origin/main,
clean tree and empty index. One detached worktree was created for this review.
No product feature, visual redesign, schema/package bump, GPU change or authentication
change is included. This is a bounded source/ownership review, not a security proof.

Private evidence is retained under `$STATE/magi/audits/consolidation-5_kw58sg`:
`baseline.json`, `local-inventory.json`, `services.json`, `generated-inventory.json`,
`test-catalogue.json`, `host-session.json`, `renderer-log.json`,
`production-log-review.json`, `canonicalization-plan.json`, `integration-backup/result.json`,
`host-session-post.json` and regression logs.
These are evidence/plan paths, not production dependencies or instructions to rerun helpers.

## Classified findings and disposition

P0 means security/data loss/lockout; P1 correctness; P2 maintenance/performance risk;
P3 stale source/docs; P4 optional polish. No P0 was established by this review.
The first classification table was reported before source cleanup.

| Finding | Severity | Evidence / affected paths | Action | Risk / state |
| --- | --- | --- | --- | --- |
| Successful old receipt can mask current publication failure | P1 | `services/theme_orchestrator/coordinator.py::status`; prior native theme gate observed an old Live label beside a generation error | Current generation/publication/activation failure overrides label/detail; preserve receipts and publication barrier | Low, covered by existing transaction fixtures extended with status assertions |
| Live Hyprland directory resolves into a retained audit candidate | P2 | `~/.config/hypr` → `discrete-bringup…/monitor-trial/config`; all four files inventoried | Integrated byte-identical accepted Lua; repaired link/enrollment under journal lock after approval | Resolved; native monitor readback unchanged, no reload |
| Stow would expose development files at HOME root | P2 | MAGI simulation proposed `deployment`, `tools`, `.gitignore` | Add package-root exclusions; disposable-home integration tests | Low; normal runtime paths remain installed |
| Local magi-fetch absolute link is correct but Stow reports it unowned | P3 | Resolves to exact production file; native use already accepted | Installed relative canonical Stow link to identical file after approval | Resolved; Stow simulation passes, no fetch behavior change |
| Dead Ghostty CSS validation branch | P3 | Renderer v4 emits only colors/config metadata, native blur false; old CSS references appear only in historical snapshots | Remove obsolete temporary-CSS rewrite branch | Low; rollback still restores prior immutable snapshots through existing owner |
| Test-only exact 0.56.2 build hash in production executor | P3 | Only Phase12G fixture imports use BUILD; actual release gate is 0.56/0.57 | Move hash into fixture, preserve 0.56 and malformed/future tests | No gate weakening |
| Old compatibility labels | P3 | Hyprland 0.56-only, Ghostty 1.3.1, outdated Zen version text | Correct audited Hyprland range/Ghostty host and describe Zen's real partial contract | Text-only; Zen profile identity/confirmation guards remain |
| Canonical docs contain resolved/pending contradictions | P3 | README, architecture, testing, roadmap, generated state, debt | Reconcile current truth; move dated index intact to `history.md`; retain phase records | Documentation only |
| Historical Ghostty CSS generations | P3 | 26 Ghostty generations, eight CSS-bearing; current/previous clean; all inspected manifests match | Retain, inventory recovery references before any owner-prune | No generated deletion |
| Released whole-window-opacity journal | P3 | `window-appearance`: managed false, active/inactive 1, null ownership/transaction, released status | Retain as obsolete rollback evidence, no active consumer | No generated deletion |
| Known polling and hardware gaps | P2 | Source timers and accepted hardware limits below | Document concrete remaining debt | Deferred; no service/auth redesign |
| Rounded edges, depth import and other visual polish | P4 | Prior native reports; no new cause established | Do not change | Deferred |

No source files/components or tests were deleted. Removed production fragments are
only the three-line CSS rewrite and unused build-hash constant. Historical input
schemas, internal designer, lock layout engine and broker security checks remain.

## Repository and artifacts: KEEP / REMOVE / INVESTIGATE

- **KEEP:** main and this active consolidation worktree. At baseline there were no
  other branches, unmerged branches, stale worktrees or broken gitdir registrations.
- **REMOVE:** no pre-existing Git branch/worktree qualifies. Remove this new worktree
  only after approved commit/push, synchronization and content/reference reconciliation.
- **RESOLVED:** the monitor-audit and absolute magi-fetch links were canonicalized
  after approval, preserving effective bytes. Their prior targets remain retained.
- **KEEP:** all earlier audit stores. `blur-architecture-nl2uk5ig` (~21.7 MiB) preserves
  accepted architecture/regression/native evidence; `hybrid-gpu-bpeta0pr` (~0.7 MiB)
  preserves rejected cross-GPU evidence; `discrete-bringup-b3cyx63n` (~1.5 MiB) holds
  monitor acceptance/recovery **with its live dependency now removed**; `hyprland-blur-reboot-bugurw53`
  preserves a summary of evidence lost across reboot. All contain potentially redundant
  helpers/backups, but no operator evidence deletion is authorized.

Tracked runtime code has no dependency on a `/tmp/magi-*` worktree. Temporary paths
in native lock proof/build documentation and historical investigations are examples
or dated evidence. Runtime directories, test roots and recovery backups are distinct
owners. Native lock README remains a historical proof/deployment journal; current
architecture/testing/security docs supersede its early password-only/Hyprlock statements.
No old install helper was run and no package was rebuilt/installed for cleanup.

## Live session, monitor and GPU evidence

Read-only native inventory found one registered production MAGI instance, one Hyprland,
one Ghostty, hyprpaper, Hypridle, three expected portal processes (core/GTK/Hyprland)
and fprintd. A second Quickshell process appeared during the offline matrix but was
not registered as another MAGI desktop instance; process presence alone is not a
reason to kill it. Portals and managed Hypridle report active/running.

Hyprland reports 0.57.0/Lua, no nonblank configuration errors, eDP-1 at 3840×2160/60 Hz,
scale 2, position 0×0 and transform 0. Current Aquamarine log explicitly identifies
`Mesa Intel(R) UHD Graphics (TGL GT1)` and card2/renderD129. Desktop process environments
contain no speculative GPU overrides. Ghostty alone carries the accepted
`GDK_WAYLAND_DISABLE=ext_background_effect_manager_v1`. Hybrid/Intel with application
PRIME offload remains the accepted policy; no NVIDIA-first trial was repeated.

The accepted panel rule matches `desc:California Institute of Technology 0x1500`,
mode `3840x2160@60.00`, position `0x0`, numeric scale 2. Canonical source differed only
by connector matching and string scale syntax. The isolated canonical candidate now
matches live Lua byte-for-byte. `hyprmon.lua`, `hypridle.conf` and `hyprpaper.conf` are
already identical between the live audit directory and canonical local files.
HyprMon retains its exact-ignored generated profile and normal startup authority.

Approved deployment completed: protected hashes and all four effective files matched,
reviewed source was integrated, and the directory link was switched to canonical source.
The journal-locked transaction backed up links/enrollment and changed only the Hyprland
bootstrap/probe resolved identities; all other targets, receipts and generation records
were preserved. The transaction included link/journal/source rollback on failure.
Native post-deployment readback confirms identical monitor geometry, 1920×1080 logical
size, zero config errors and Hyprland Live at the canonical path. No reload, monitor
setter, shell restart or GPU change occurred. Both MAGI and Hyprland Stow simulations
now pass. The magi-fetch relative link resolves to the same executable bytes.

A separate symlink scan found Sidra/Chromium singleton locks and its temporary socket.
Those are application runtime artifacts, not broken MAGI bootstraps; retain them.

## Hyprland / appearance / target contracts

Both release gates accept stable 0.56.x and 0.57.x, fail closed on unknown/malformed
versions, and keep config-generation/readback guards. The Displays planner still
mentions its 0.56 audit intentionally: it has no production apply authority and must
not be silently promoted to a new hardware claim. No `hyprctl keyword` or legacy
Hyprland `.conf` publisher was found. Hypridle's `.conf` is its own valid configuration,
not a superseded Hyprland provider. Historical fixtures are retained.

Ghostty wrapper execs the fixed binary (no recursion), preserves argv/environment
except its scoped GTK opt-out, and leaves PRIME variables intact. MAGI/desktop-entry
normal launch and CLI wrapper behavior have dedicated tests; native normal launch
was accepted in the preceding phase. Ghostty provides alpha, compositor provides blur;
MAGI retains precise BackgroundEffect regions. No production Lua layer replacement or
whole-client opacity rule was added. Static blur remains four passes, optimizations on;
GlobalBlur owns opted-in size only. Palette semantics are unchanged.

All twelve expected targets appear in live status without errors: MAGI, Hyprland,
Ghostty, GTK, Zen, Yazi, Neovim, Starship, Fastfetch, btop, CAVA, ascii-splash. Hyprland
is Live, Ghostty Reload requested, and each remaining target retains its documented
launch/restart/prompt boundary. Adapter payload versions are unchanged because no
renderer output changed. The ordinary barrier, compensation and per-target activation
isolation remain intact. There is no duplicated launch/reload implementation to remove.

## Lock, fingerprint, Settings, UI and icons

The six unique curated theme IDs are `split-corners`, `centered`, `minimal`, `editorial`,
`media`, `compact`. LockScreenPage uses current shared wallpaper; Legacy Custom survives.
SettingsContent exposes LockDesignerPage only for `MAGI_LOCK_DESIGNER=1`. The underlying
layout presets and Phase13 fixtures remain required for internal editing and migration.
No component was removed merely because a textual reference count was low; dynamic QML
loading, qmldir registration and harness use were considered. No newly orphaned registered
service/model type was found.

Production native fingerprint broker and Settings management are separate authority
paths. Device discovery is through fprintd, not a hard-coded Synaptics ID. The accepted
Synaptics/internal password/fingerprint and suspend/resume evidence remains valid;
physical external-monitor acceptance remains incomplete. Installed magi-lock is 0.1.0-11,
matching pkgrel 11. Native source/package/test hashes and all auth boundaries are untouched.
No enrollment operation was invoked; protected system template contents were not read.

Settings schema stays 22. Migration inputs 0–21 remain necessary historical support;
current expectations use defaults through `expected-current.cjs`. Persistence compares
the actual outgoing schema and preserves original recovery/migration backups. No new
schema constant, migration or backup writer was added. Semantic MAGI icons remain separate
from application/tray identity; no icon artwork/hard-coded application overrides changed.

## Services and polling

All 38 registered singleton/model types have consumers (see appendix and private
`services.json`). Existing ownership remains in [current architecture](../architecture/current-system.md).
Theme, appearance and global-blur 450 ms timers are one-shot reconciliation debounce,
not idle polling. LockAuxiliary's 300 ms timer is coalescing; Wallpaper topology/retry
is bounded. Bluetooth/audio timers bound explicit operations. Media progress runs only
with a playing/valid player and visible Control Centre. Notification expiry work is
conditioned on live/expiring records; the slower retention prune remains separate.

Known QuickActions/Brightness intervals remain unchanged. Weather refresh stays opt-in.
The native fingerprint broker dispatches bounded batches on a 10 ms timer during an
active attempt, with a 30 s deadline and 5 s enabled retry; cancel/close stops dispatch.
This is concrete future event-loop debt, not an always-on shell fingerprint poll and
not authorization to refactor authentication during hygiene work.

## Packages, logs and generated ownership

Read-only installed versions: Hyprland 0.57.0-1, Aquamarine 0.15.1-1, Quickshell 0.3.2-1,
Ghostty 1.4.0-1, magi-lock 0.1.0-11, fprintd 1.94.5-2, libfprint 1.94.100-1,
hyprpaper 0.8.4-9, hypridle 0.1.8-2 and Hyprland portal 1.4.1-2. Zen is 1.24b-1;
its old version-only label is replaced with its actual partial CSS/restart contract,
without weakening exact profile confirmation. ascii-splash is not a pacman package
under that name; executable discovery/live target status are separate evidence.

`pacman -Qdtq` reports cmake, csakura-debug, electron39, ffmpeg4.4, go,
hyprland-protocols-git, hyprwayland-scanner, lib32-libcap, libliftoff, libxnvctrl,
meson, opencl-headers, python-mako, python-pkg_resources, svt-hevc, xcb-imdkit, yay-debug.
These are review candidates only: several are useful build tools. Nothing was uninstalled.

112 user-journal lines since the accepted production MAGI restart were inspected;
none matched repeated binding-loop/ReferenceError/TypeError/deprecation/EGL/theme-retry
patterns searched. Normal suspend/resume/password success appears. This bounded window
is not proof that no warning ever occurs; old failed GPU/sandbox trial logs were excluded.

Generated data/state owners were inventoried: theme generations/receipts, global blur,
wallpaper, lock auxiliary, power idle, Settings locks/backups, imported avatar/icons,
audits and the released old window-appearance journal. All inspected theme manifests
validated. No source hook, user asset, theme pointer, wallpaper assignment, Settings,
biometric enrollment or runtime state was deleted or rewritten during source audit.

## Tests and review gate

The catalogue has 100 unique suite IDs and 100 unique commands; no duplicate suite was
removed. One new disposable-home Stow suite was registered. Existing failure-path tests
now assert truthful status text. The exact build hash moved to its historical fixture;
all 0.56 and 0.57 coverage remains. Runner timeout, nonzero exit, failure-signature and
specific ENVIRONMENT classification rules are unchanged.

Focused appearance/activation/bootstrap/launch suites and Stow checks passed. The full
100-suite matrix completed: **96 PASS, 4 ENVIRONMENT, 0 FAIL, 0 UNKNOWN, 0 SKIPPED**.
The four evidenced limits are bluetooth/bus, clipboard/model, notifications/run and
native_lock; native source hashes and independent transport-denial probes match.
`git diff --check` and local documentation-link checks pass. After approved production
integration, all six focused appearance/activation/bootstrap/launch/Stow suites passed
again. No runtime source bytes differ from the full-matrix candidate. Documentation
was updated to record deployment results. Protected file bytes, Settings schema 22,
wallpaper, GPU policy and biometric enrollment remain unchanged; only the approved
link representations and two Hyprland enrollment identity fields changed.

The native collector's initial summary assumed every catalogue row had a status label;
Qt and Hyprtoolkit are deliberately deferred placeholders. Its corrected validation of
the same saved host results passed: all 12 enabled targets have no error, Hyprland is
Live, Ghostty retains Reload requested, and the remaining activation boundaries match
the baseline. No repeated theme activation was issued.

Approved single commit: `magi: consolidate post-0.57 architecture`. Push requires
separate operator approval; retain the worktree and evidence until synchronized closeout.

## Registered service/model inventory

Source paths are under `.config/quickshell/magi/services`. Consumer counts exclude
the defining file and include QML/JS references; they are navigation evidence, not
a proof that every dynamic use can be discovered textually. Process commands/IPC
and persistence references are retained in `services.json`.

| Type / owner | Source consumers | Timer intervals (ms; not necessarily polling) | Explicit IPC target |
| --- | ---: | --- | --- |
| `Network` | 3 | none | none |
| `Settings` | 71 | none | settings |
| `Audio` | 6 | none | none |
| `Battery` | 8 | none | none |
| `Bluetooth` | 9 | 30000, 10000 | none |
| `Brightness` | 3 | 60, 2000 | none |
| `MenuController` | 14 | none | none |
| `SettingsWindowState` | 14 | none | none |
| `AssetManager` | 5 | none | none |
| `Media` | 6 | none | none |
| `QuickActions` | 2 | 5000 | none |
| `Notifications` | 18 | none | notifications |
| `Clipboard` | 15 | 70 | clipboard |
| `AirplaneMode` | 1 | none | none |
| `Caffeine` | 4 | none | none |
| `ActionConfirmation` | 2 | 5000 | none |
| `MediaController` | 1 | 1000 | none |
| `NotificationModel` | 1 | 60000, 50 | none |
| `NotificationBackend` | 1 | none | none |
| `NotificationRecord` | 1 | none | none |
| `Launcher` | 5 | none | launcher |
| `LauncherIcons` | 1 | none | none |
| `ClockState` | 2 | none | none |
| `Calendar` | 5 | none | none |
| `CalendarModel` | 1 | none | none |
| `Emoji` | 12 | none | emoji |
| `Hub` | 21 | none | hub |
| `Wallpaper` | 8 | 700, 3000 | wallpaper |
| `ThemeOrchestrator` | 4 | 450 | systemTheme |
| `Weather` | 6 | 750, 30 * 60 * 1000, 20000 | none |
| `SurfaceOrigin` | 10 | none | none |
| `Displays` | 2 | none | none |
| `ApplicationAppearanceService` | 2 | 450 | none |
| `GlobalBlurService` | 2 | 450 | none |
| `LockAuxiliary` | 2 | 300 | none |
| `TrayModel` | 1 | none | none |
| `TrayService` | 1 | none | none |
| `AudioModel` | 1 | 5000, 5000 | none |


Final protected-state verification matches the starting hashes for Settings, all four
Hyprland files, Ghostty config, Bash login/hooks, GTK and Yazi; monitored config/launch
links are unchanged. No biometric/system package operation was invoked. The current
monitor-audit dependency is deliberately retained until the reviewed placement gate;
it is not represented as already fixed. One commit is proposed, with no removals of
operator audit data, generated generations, package installs or unrelated state.
