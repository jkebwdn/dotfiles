# Phase 12B exact path inventory

Reviewed source: `/home/jkebwdn/magi-phase12b`; integrated into `/home/jkebwdn/dotfiles`. This is the exact reviewed Phase12B allowlist; protected local state is excluded.

**33 paths: 23 added, 10 modified, 0 deleted.**

## Canonical palette definitions — 1

- M `linux/magi/.config/quickshell/magi/theme/palettes/registry.json`

## Documentation — 7

- M `linux/magi/README.md`
- M `linux/magi/docs/README.md`
- M `linux/magi/docs/architecture.md`
- M `linux/magi/docs/decisions.md`
- M `linux/magi/docs/quickshell-reference.md`
- A `linux/magi/docs/design/phase12b-paths.md`
- A `linux/magi/docs/design/phase12b-theme-library.md`

## Intentional preview assets — 10

- A `linux/magi/docs/design/previews/phase12b/contrast.json`
- A `linux/magi/docs/design/previews/phase12b/index.html`
- A `linux/magi/docs/design/previews/phase12b/nord.png`
- A `linux/magi/docs/design/previews/phase12b/rose-pine-dawn.png`
- A `linux/magi/docs/design/previews/phase12b/rose-pine-moon.png`
- A `linux/magi/docs/design/previews/phase12b/rose-pine.png`
- A `linux/magi/docs/design/previews/phase12b/tokyo-night-day.png`
- A `linux/magi/docs/design/previews/phase12b/tokyo-night-moon.png`
- A `linux/magi/docs/design/previews/phase12b/tokyo-night-storm.png`
- A `linux/magi/docs/design/previews/phase12b/tokyo-night.png`

## Orchestrator canonical metadata — 1

- M `linux/magi/.config/quickshell/magi/services/theme_orchestrator/palette.py`

## Registry validation — 1

- M `linux/magi/.config/quickshell/magi/theme/ThemeRegistry.qml`

## Source attribution and licenses — 4

- A `linux/magi/.config/quickshell/magi/theme/palettes/ATTRIBUTION.md`
- A `linux/magi/.config/quickshell/magi/theme/palettes/LICENSE-Nord`
- A `linux/magi/.config/quickshell/magi/theme/palettes/LICENSE-RosePine`
- A `linux/magi/.config/quickshell/magi/theme/palettes/LICENSE-TokyoNight`

## Tests — 9

- M `linux/magi/tests/runtime-visual/run.py`
- M `linux/magi/tests/theme-orchestrator/integration.qml`
- A `linux/magi/tests/phase12b/gallery.py`
- A `linux/magi/tests/phase12b/palettes.py`
- A `linux/magi/tests/phase12b/presentation.qml`
- A `linux/magi/tests/phase12b/run.py`
- A `linux/magi/tests/phase12b/schema.cjs`
- A `linux/magi/tests/phase12b/surfaces.qml`
- A `linux/magi/tests/phase12b/switching.qml`

## Excluded state and artifacts

- Main-checkout `settings.json`, all protected `linux/t15g` modifications and
  untracked operator files: excluded; all protected bytes match preflight after restoring Catppuccin Mocha.
- `/tmp/magi12b/output`: 198 isolated adapter render files + contrast report.
- `/tmp/magi12b-final`: finalization logs, protection snapshots and test captures.
- No `__pycache__`, Cargo/build output, runtime state or logs in this allowlist.
- No changes to application adapters, production lock, PAM, enrollment,
  Hyprland configuration. Live adapters followed ordinary user theme selection
  and returned to Mocha; their runtime output is excluded. No Phase12C/D work.
