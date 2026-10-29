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
| Ghostty background/transparency | ApplicationAppearanceCoordinator composes through the same Theme Orchestrator store | Ghostty generation above; shared journal | No second writer for generated Ghostty files. Disable through the owner before removing output. |
| Global blur | GlobalBlurService / global_blur.py | `$STATE/magi/global-blur` | Keep captured baseline and pending restoration state; generation identity prevents restoring into another compositor session. |
| Power/idle policy | Settings power_idle.py | `$STATE/magi/power-idle` | Active config, previous config and pending transaction are recovery state; never clean while a service uses them. |
| Settings lock / backups | settings/persist.py | `$STATE/magi/settings-locks`, `$STATE/magi/settings-backups` | Preserve locks and backups during work. Back up original content when its schema is older than the outgoing Schema-analyzed document, or when recovering malformed content. Current-schema saves do not create migration backups; retries deduplicate by original content/path. No automatic deletion policy added. |
| Imported wallpaper/avatar/header/icon assets | AssetManager / assets.py | `$DATA/magi` managed asset subdirectories | User imports are persistent data; retain referenced assets. Staged imports use temporary siblings and validate ownership before publication. |
| Thumbnails and weather | Assets / Wallpaper / Weather owners | `$CACHE/magi` | Disposable cache only after proving no active reader/write or rollback dependency. Owners regenerate on demand; do not delete user originals. |
| Clipboard | Clipboard backend | Session runtime/cache; opt-in XDG data history | User history is not disposable build output. Default is session-only; explicit persistence is unencrypted. |
| Lock auxiliary display snapshots | LockAuxiliary / lock_auxiliary.py | `$STATE/magi/lock-auxiliary`, `$CACHE/magi` prepared artwork | No credentials. Retain current snapshots while lock may consume them. Prepared artwork is bounded to 16 files by its owner. |
| Display/fingerprint state | Respective Settings/backend/native owners | Owner-specific XDG state / external service | Physical production acceptance remains deferred. Preserve profiles and pending transaction state; do not repurpose test output as live state. |
| Test/build output | Test harness / build invocation | `mkdtemp` roots under `/tmp` | Disposable only after jobs end and useful evidence is summarized in docs. TemporaryDirectory harnesses clean automatically. No persistent source dependencies on phase folders. |

## Single-writer conclusions

Theme Orchestrator renders Ghostty, GTK, Zen, Yazi, Neovim, btop and Hyprland border
artifacts. Application Appearance composes policy through that publisher rather than
writing competing output. Global blur manages a separate compositor property.
Zen workspace colour still requires a manual application step; GTK/Thunar background
transparency is deferred. Yazi's runtime-owned flavour symlink remains local and exact-ignored.

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
| Ghostty | config.ghostty optional include | Theme Orchestrator current/colors.conf, background fragments | Read-only hook; absent include preserves static preferences |
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
reload/restart boundary. Ghostty disable still requires release of managed application
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
