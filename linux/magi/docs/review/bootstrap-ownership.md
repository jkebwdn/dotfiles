# Tracked bootstrap and runtime ownership

Audit/design, 2026-10-27. Schema remains 22. Source configuration must not be an
enrollment payload. Canonical versioned bootstrap blocks are recognized by exact
content; a marker alone never authorizes adoption of foreign source.

| Adapter | Tracked bootstrap | Runtime payload | Absent payload |
| --- | --- | --- | --- |
| Bash/Starship | Readable-file check before exporting STARSHIP_CONFIG | XDG data Starship current/starship.toml | Existing Starship default config |
| Ghostty | Optional config-file include | XDG data Ghostty current/colors.conf | Existing static colours/preferences |
| GTK | Static layout CSS without overriding theme colours; baseline settings.ini | Named MAGI theme, generated definitions, GSettings selection | Baseline theme; no missing CSS import |
| Hyprland | File-existence guard around border-only Lua include | XDG data Hyprland current/colors.lua | Existing border settings |
| Neovim | Readable generated colourscheme guard | XDG data Neovim current/colors/magi.lua | Existing plugin/default colourscheme |
| Yazi | Semantic Lua fallback, static flavour selection, tracked colour template | Generated flavour and yatline.lua; local runtime symlink | Yazi built-in theme plus fallback yatline roles |

Installed Yazi was tested in a disposable PTY without the selected flavour: startup
continues without a missing-flavour error. Full fresh/active tests must also cover
the canonical configuration. GTK activation must be checked natively: GSettings owns
selection, while the INI fallback remains static. No GTK-generated CSS import is
needed in tracked gtk.css.

HyprMon help advertises -cfg for profile storage, not an alternate generated monitor
output. Keep its generated hyprmon.lua local and exact-ignored; conditionally load it
from the actual config directory. Never suppress errors inside an existing file.
Yazi's absolute XDG-target link is runtime-owned and exact-ignored, not portable source.

Canonical bootstrap records validate blocks without claiming write/removal ownership.
Legacy journals are reconciled explicitly under the existing lock only after exact
source/bootstrap validation and verification that non-hook user content is preserved.
Retired source-edit entries are replaced by read-only bootstrap records; runtime links
and GSettings rollback records remain owned. Disable restores runtime selection/links
and detaches the owned current generation, retaining generations for rollback. It never
removes canonical tracked hooks. Unrecognized or modified source remains a conflict.
Legacy enrollment for non-bootstrap configurations must not write into Git checkouts.

Hard gates: fresh no-journal startup, enable/apply/switch/disable/re-enable with identical
source bytes, legacy-journal reconciliation, foreign modification rejection, full matrix,
and native theme-switch/source-cleanliness acceptance. Do not infer native success from
synthetic parser checks.


## Implemented safety and fixture results

- All six adapters recognize exact canonical blocks without pre-existing journal state.
  A marker with altered content, redirected paths, or a missing Yazi template is refused.
- Legacy source enrollment and legacy disable refuse Git-backed paths. Non-Git legacy
  fixtures remain supported; they are explicitly pinned to pre-bootstrap source history.
- Migration validates old source edits and runtime ownership before saving any intent.
  Each resumed write must match its exact before/after content and path identity. User
  edits outside legacy blocks survive. Completion drops writable source records;
  generated current pointers and their contents are not changed by migration.
- Disable validates generated output before cleanup, restores owned runtime selection,
  removes runtime links, and detaches current pointers with directory synchronization.
  Read-only hooks remain byte-identical. Existing Ghostty appearance release guard stays.
- Seven focused tests cover every adapter round trip, no-journal checkout, old journal
  conversion, crash recovery/intervening edits, foreign blocks, Git-backed source,
  syntax/config parsing and fresh/active/disabled Yazi, Neovim and Bash bootstrap startup.
  Neovim plugin modules are stubbed in the synthetic startup check to avoid downloads;
  the full installed plugin setup remains part of native smoke acceptance.
- Optional Ghostty tilde include validates with absent output. A non-default XDG data
  store requires a corresponding literal Ghostty hook; unknown paths are not adopted.
- The Settings test and Phase 10B/10C.1 migration fixtures previously read or assumed
  a copied live settings.json. They now use absent-file handling and explicit synthetic
  historical inputs. The standalone Phase 12G schema fixture also no longer defaults to
  operator state. Current defaults remain in schema code, not a new example JSON file.

## Repository actions

The accepted three battery SVGs are copied byte-for-byte; saved HyprMon profile updates
change metadata/schema spelling only, not geometry. Live Settings is removed from tracking with `git rm --cached` after hash verification;
its on-disk bytes stay intact.
Exact ignore rules cover settings.json, the HyprMon generated Lua file/backup convention,
and Yazi's runtime flavour link. The proven redundant Hyprland backup is removable.
No index-hiding flags or broad config reformat are used.

Native migration passed on the operator host: GTK3 effective theme is MAGI,
Hyprland configerrors is empty, generated pointers and Settings bytes are unchanged.
The repeated migration invocation stopped before mutation as designed. The operator confirmed the theme-switch/source-cleanliness check and full application
smoke acceptance: MAGI/Bar/Settings, Ghostty, Neovim, Yazi and GTK/Thunar all pass.


HyprMon v0.0.17 (installed build 3131caff) was also tested with a disposable HOME,
profile and fake hyprctl. Its documented HYPRLAND_CONFIG redirects the main config,
not a separately documented sidecar output setting. A guarded `require("hyprmon")`
is recognized and remains byte-identical after profile application. Missing sidecar
startup succeeds; errors in an existing sidecar propagate. Installed reference:
`/usr/share/doc/hyprmon/README.md`, Configuration and Backup Files sections.


## Final offline validation

Canonical `python3 linux/magi/tests/run-all.py` completed all 86 commands:
**82 PASS, 0 FAIL, 4 ENVIRONMENT, 0 SKIPPED; UNKNOWN=0**.
Logs/results: `/tmp/magi-hygiene-d7pvz4e7/final-matrix/results.json`.
The four environment entries are the previously evidenced private-bus tests,
Clipboard image-decoder transport and native lock SOCK_SEQPACKET restrictions.
Native lock builds; no security assertion is weakened. The delayed-write launcher
regression passes. Icon resolver/fallback, Theme Orchestrator, application appearance,
Settings and bootstrap round-trip/startup coverage all pass.

The earlier broad run exposed three fixtures depending on the removed live Settings
file (Settings missing-file setup and Phase 10B/10C.1 input reads). Their corrected
focused checks and the entire subsequent matrix pass. No runtime regression was
hidden by those fixture updates. The reviewed candidate has 35 paths: 7 added,
27 modified and 1 removed-from-tracking Settings path. Native acceptance is recorded. The Settings index deletion retains the live file
locally, with an exact ignore rule; no operator preference values are committed.
