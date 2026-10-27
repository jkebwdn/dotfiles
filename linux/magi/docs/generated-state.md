# Generated state and retention

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
| Settings lock / backups | settings/persist.py | `$STATE/magi/settings-locks`, `$STATE/magi/settings-backups` | Preserve locks and backups during work. Current backup trigger still compares against schema 20; schema 22 saves create extra content-addressed backups (documented debt). No automatic deletion policy added. |
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
transparency is deferred. Yazi's operator-owned flavour symlink is preserved.

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
