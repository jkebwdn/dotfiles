# Generated state and retention

Tracked bootstrap hooks are source; generated payloads and enrollment state are not.
Live `.config/quickshell/magi/settings.json` is local, untracked and exact-ignored;
`SettingsSchema.defaults()` remains authoritative. No sample duplicates the schema.

Source, tests, fixtures and documentation belong in `~/dotfiles/linux/magi`.
Generated output is **not source** and remains in its XDG location. This table uses
`$DATA`, `$STATE`, `$CACHE` for the corresponding XDG homes (with normal home defaults).
None of these runtime stores should be staged.

| Thing | Source / runtime owner | Location | Retention and safe removal / recreation |
| --- | --- | --- | --- |
| Application theme artifacts | Theme Orchestrator storage + activation coordinator | `$DATA/magi/theme-orchestrator/<target>/generations/<digest>`, `current`, `previous` | Keep active and previous generations. Publisher retains the last two journal entries and refuses pruning of edited/unowned artifacts. Use enrollment/disable transactions, not directory deletion. |
| Theme ownership and receipts | Theme Orchestrator; ThemeActivationCoordinator | `$STATE/magi/theme-orchestrator`, `$STATE/magi/theme-activation/status.json` | Keep ownership, rollback and activation evidence. Reconciliation uses these to avoid duplicate activation and overwriting user edits. |
| Ghostty / Thunar background transparency | ApplicationAppearanceCoordinator composes through the same Theme Orchestrator store | Ghostty and enrolled GTK generations above; shared journal | Validate both before publication; retain rollback intent and release shared appearance before removing either integration. |
| Global blur | GlobalBlurService / global_blur.py | `$STATE/magi/global-blur` | Keep captured baseline and pending restoration state; generation identity prevents restoring into another compositor session. |
| Power/idle policy | Settings power_idle.py | `$STATE/magi/power-idle` | Active config, previous config and pending transaction are recovery state; never clean while a service uses them. |
| Settings lock / backups | settings/persist.py | `$STATE/magi/settings-locks`, `$STATE/magi/settings-backups` | Preserve locks and backups during work. Back up original content when its schema is older than the outgoing Schema-analyzed document, or when recovering malformed content. Current-schema saves do not create migration backups; retries deduplicate by original content/path. No automatic deletion policy added. |
| Imported wallpaper/avatar/header/icon assets | AssetManager / assets.py | `$DATA/magi` managed asset subdirectories | User imports are persistent data; retain referenced assets. Staged imports use temporary siblings and validate ownership before publication. |
| Thumbnails and weather | Assets / Wallpaper / Weather owners | `$CACHE/magi` | Disposable cache only after proving no active reader/write or rollback dependency. Owners regenerate on demand; do not delete user originals. |
| Clipboard | Clipboard backend | Session runtime/cache; opt-in XDG data history | User history is not disposable build output. Default is session-only; explicit persistence is unencrypted. |
| Lock auxiliary display snapshots | LockAuxiliary / lock_auxiliary.py | `$STATE/magi/lock-auxiliary`, `$CACHE/magi` prepared artwork | No credentials. Retain current snapshots while lock may consume them. Prepared artwork is bounded to 16 files by its owner. |
| Display profiles/transactions | Displays / HyprMon | Owner-specific XDG state and local monitor profile | Displays 10C.2B remains deferred; preserve profiles and transactions. |
| Fingerprint enrollment | fprintd / system policy | External system service storage | Production internal unlock is accepted. No MAGI biometric store; preserve enrollment and never treat fixtures as live state. |
| Test/build output | Test harness / build invocation | `mkdtemp` roots under `/tmp` | Disposable only after jobs end and useful evidence is summarized in docs. TemporaryDirectory harnesses clean automatically. No persistent source dependencies on phase folders. |

## Single-writer conclusions

Theme Orchestrator renders Ghostty, GTK, Zen, Yazi, Neovim, btop and Hyprland border
artifacts. Application Appearance composes policy through that publisher rather than
writing competing output. Global blur manages a separate compositor property.
Zen workspace colour still requires a manual application step. Thunar background
alpha composes through its existing GTK theme adapter and applies on relaunch;
menus/dialogs and foregrounds retain opaque surfaces. See the
[Thunar/Hub candidate and native evidence](review/thunar-hub-focus.md). Yazi's runtime-owned flavour symlink remains local and exact-ignored.

Lock presentation comes from shared source under `native/lock/qml`, not a second
generated authorizer. Bar layout is Settings-owned; active Tray items and Super+T
presentation override are session-only. Audio route/volume state remains external.

## Write and temporary-file contracts

Theme storage checks ownership markers, manifests, hashes and symlink boundaries,
publishes the current pointer atomically, and fsyncs its directory. Settings writes
resolve the explicitly selected symlink target, use an advisory lock and expected
content check, then atomic replacement. An unrelated editor's rename cannot be
locked by MAGI; conflicts remain possible and are reported. Theme publication is
per-target atomic, not one globally atomic filesystem transaction.

Validators use `TemporaryDirectory` (for example Ghostty configuration validation).
Clipboard conversions use bounded cache-local temporary directories. Atomic writers
create sibling temporary files and remove them after replacement/failure. Future
development helpers should use one `mktemp` root, never permanent home archives.
Keep current, last-known-good, pending and modified/conflicted generations; directory
age alone never proves a generation disposable.


## Workstation bootstrap ownership

| Application | Tracked source / bootstrap | Generated payload / runtime owner | Journal and absent-state behavior |
| --- | --- | --- | --- |
| Bash/Starship | .bashrc guarded STARSHIP_CONFIG export | Theme Orchestrator Starship current/starship.toml | Read-only hook record; absent file keeps normal Starship config |
| Ghostty | config.ghostty optional include | Theme Orchestrator current/colors.conf and palette metadata | Read-only hook; absent include preserves static preferences |
| GTK | gtk.css layout; settings.ini fallback | Generated named MAGI theme and runtime GSettings selection | Journal owns runtime theme link/GSettings rollback; absent state uses static theme |
| Hyprland | hyprland.lua guarded border hook | Theme Orchestrator current/colors.lua | Read-only hook; absent file preserves baseline borders |
| Neovim | init.lua guarded runtimepath/colourscheme | Theme Orchestrator current/colors/magi.lua | Read-only hook; absent file leaves plugin/default colourscheme |
| Yazi | init.lua semantic fallback, theme.toml selector, magi-template.toml source colours | Generated current/flavor and yatline.lua; exact-ignored magi.yazi link | Journal owns runtime link only; absent flavour uses Yazi defaults and Lua fallback |
| CAVA | `.bashrc` guarded source + canonical `services/terminal_visuals.sh` | Theme Orchestrator `cava/current/colors.ini`; launch-only anonymous memfd config | Read-only bootstrap record; disable detaches current, absent/invalid payload uses original config; no user config writes |
| ascii-splash | Same guarded shell bootstrap | Theme Orchestrator `ascii-splash/current/theme.json` | Read-only bootstrap record; optional next-launch built-in override; absent/disabled uses application config |
| HyprMon | conditional Hyprland loader; saved profile JSON | Local exact-ignored hyprmon.lua, owned by HyprMon | No MAGI journal ownership; absent file does not break compositor startup |

Normal enable/switch/disable never rewrites these canonical source hooks. Disable
restores runtime selection/removes owned links and detaches validated current pointers;
generations remain for recovery. Loaded application colours can remain until its normal
reload/restart boundary. Ghostty/GTK disable requires release of managed application
appearance first; the background-only transparency architecture is unchanged.

An explicit `migrate-bootstrap` operation under the existing journal lock converts old
source-edit ownership. It validates old ownership and all planned writes, saves resumable
intent, replaces only integration blocks, then replaces writable journal entries with
read-only records. Pending intent temporarily contains source replacement text in the
private state journal; it is removed after success, never logged. Intervening edits or
path changes stop migration. Startup/apply refuse a pending migration, never guess.
Legacy non-bootstrap adapters can still enroll non-Git external configurations, but
writes into a checkout (including Stow-resolved paths) are rejected. See
[ownership audit and acceptance](review/bootstrap-ownership.md).

Terminal visual generations follow the same current/previous retention rules above.
Use target disable before cleanup; re-enable/apply recreates generated colours.
See [terminal visuals audit](review/terminal-visuals.md) for fallback and next-launch limits.

`magi-fetch` is a read-only consumer of the saved theme, existing palette resolver
and matching published snapshot. It creates no persistent generated state, cache or
activation receipt. Its frames and captured Fastfetch text live only in process memory.


## Accepted Hyprland 0.57 compatibility

The [adapter audit and native acceptance gate](review/hyprland-057.md) records the bounded
0.56–0.57 Lua border API policy, verified runtime readback, generated-state status
and unchanged XDG/bootstrap ownership. Native host acceptance passed with exact border readback and Nord restoration;
The operator approved closeout. Settings schema stays 22.


## Audit evidence and superseded generations

`$STATE/magi/audits` is retained operator evidence, not a disposable cache. The 2026-11-05
inventory retains four earlier audit stores: blur architecture acceptance, Hybrid GPU
rejection, Discrete/monitor recovery, and a reboot-era evidence summary. Approved
canonicalization removed the monitor store's live Hyprland dependency while preserving
all effective config bytes and monitor readback. Retain its recovery/acceptance evidence;
source/doc references do not authorize deletion or running historical helpers.

Current and previous Ghostty generations use the accepted alpha-only/native-blur-off
payload. Eight older CSS-bearing generations remain among 26 owned, hash-valid
historical generations. Appearance publications and retained audit snapshots can leave
more history than the ordinary two-entry theme journal. Unreferenced is not equivalent
to disposable: protect current/previous, pending transactions, journal-listed generations,
and audit recovery references before using the owner-validated pruning routine.
No generations or evidence were deleted during this audit.

The retired `$STATE/magi/window-appearance` journal is released/unmanaged with null
ownership and transaction. It has no production consumer; retain it as rollback evidence
until separately approved cleanup. The active `applicationAppearance` policy and
`global-blur` journal are different owners and must remain intact.

Custom Image imports use `$DATA/magi/bar-images/<sha256>.<gif|png|jpg|webp>` through
AssetManager. Original bytes are retained; alpha bounds and display preferences
live in untracked Settings. Clearing/removing an item does not delete its imported
asset. Preserve referenced imports; no automatic garbage collector is introduced.

Control Centre decorations reuse the measured image importer and store
byte-identical PNG/GIF originals at `$DATA/magi/images/<sha256>.<png|gif>`, with
`decoration-image:` descriptors in local Settings. Existing Bar asset IDs/storage
remain valid. Clearing a selection does not delete originals; no automatic pruning
is added. See the [acceptance review](review/controlcentre-image.md).

The Settings image-picker candidate changes only dialog ownership; AssetManager and
its content-addressed Bar/decoration stores remain the sole import path. Picker
requests/errors and card disclosure are transient state, not new Settings fields.
Private phase evidence and rollback snapshots remain in `$STATE/magi/audits`.
