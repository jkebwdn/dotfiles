# MAGI documentation

Current source of truth: `~/dotfiles/linux/magi`. Settings schema **22**.
Post-0.57 consolidation reviews the accepted `e251450` baseline; it adds no feature.
Current capabilities include Audio routing, inline Tray toggling, authenticated
Bluetooth pairing support, the curated lock themes and internal designer, and the evolved Bar/Hub/Settings.

## Current canonical documents

- [Appearance simplification and complete roundness audit — review only](review/appearance-roundness.md)

- [Hub focus, image picker and grouped Settings cards candidate](review/focus-picker-settings.md)

- [Control Centre decorative image acceptance](review/controlcentre-image.md)

- [Custom Image Bar item and deployment](review/bar-custom-image.md)

- [Thunar backgrounds and Hub focus acceptance](review/thunar-hub-focus.md)
- [tfm-tui research only](research/tfm-tui.md)

- [Post-0.57 consolidation findings](review/post-057-consolidation.md)
- [Historical acceptance index](history.md)
- [Current architecture and service ownership](architecture/current-system.md)
- [Canonical theme library and mapping](themes.md)
- [Curated lock screen themes](review/lock-screen-themes.md)
- [CAVA/ascii-splash support and ownership](review/terminal-visuals.md)
- [Animated terminal fetch](terminal-fetch.md)
- [Keybindings and IPC](keybindings.md)
- [Testing](testing.md) and [current environment limits](known-warnings.md)
- [Generated state and retention](generated-state.md)
- [Security boundaries](security.md)
- [Technical debt](technical-debt.md) and [current roadmap](current-roadmap.md)
- [Development/phase closeout policy](phase-closeout.md)
- [Phase 15 worktree reconciliation](review/phase15-worktree-reconciliation.md)
- [Regression reconciliation](review/phase15-regression-reconciliation.md)
- [Profile layout cause and minimal correction](review/phase15-profile-layout.md)
- [Phase 15 consolidation review](review/phase15-closeout.md)

`architecture.md` and `decisions.md` are chronological journals. `design/phase12*`,
`phase13*`, `phase14*` and their acceptance galleries are historical phase evidence;
old schema numbers, candidate paths and pending instructions describe their dates,
not current deployment directions. Research documents preserve investigations and
rejected alternatives. Do not execute old helpers or restore old architecture from
those records. Current canonical documents above take precedence.

## Phase 16 quality audit

[Intel blur architecture investigation](research/intel-blur-architecture.md)
records the historical-config limits, GTK protocol distinction and accepted
compositor-only Ghostty integration. GPU-routing experiments are cancelled; native
performance, normal-launch and theme-switch/restore acceptance passed. The
integration is committed and synchronized at `e251450`.

[UX, accessibility and performance findings](review/phase16-ux-quality-audit.md)
records the bounded fixes, deferred work and validation limits.

## Phase 16B review candidate

[Lock mask feedback, Settings toggle and product-finish review](review/phase16b-settings-product-review.md)
records the corrected diagnosis, bounded candidates and larger recommendations
awaiting operator review. The lock-mask and Settings-toggle fixes passed native acceptance.

## Settings product finish

[Visual theme gallery and product proposals](review/settings-product-finish.md)
records the accepted collapsible gallery and the subsequent grouped-navigation,
Lock composition, Bar guidance and feedback implementation. All passed native
interaction acceptance and source-cleanliness checks; Settings schema remains 22.

## Repository ownership maintenance

Stable workstation bootstraps are separated from generated theme payloads; live
Settings is untracked. See [bootstrap ownership and validation](review/bootstrap-ownership.md).

## Daily-use media and status styling

[Media diagnosis, per-item status backgrounds and split Battery](review/daily-use-polish.md)
records integrated per-item colours, palette-relative shade refinement, centered
Battery regions and immediate media refresh. Schema remains 22. The review records
native acceptance separately from the unresolved Zen missing-duration limitation.

## Historical checkpoints

Earlier phase records and the original dated documentation index are preserved in
[history.md](history.md). They do not override current architecture or native acceptance.
