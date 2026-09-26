# MAGI — Research and Development

MAGI is a modular Quickshell environment for Arch Linux and Hyprland.
This directory records implementation evidence, decisions and proposed research.

## Literal-render reference checkpoint — 2026-09-26

The accepted shared-surface architecture is frozen. The
[measured visual specification](design/render-visual-specification.md) records
source-image dimensions/colors, explicit logical-pixel adaptations and exact
pre-pass mismatches. Control Centre now implements the supported reference
subset using scoped RenderTokens, icon-only colored tiles, dark icon-on-slider
controls and an unboxed power summary. Other detail views retain their styling.

Static checks and the expanded 44-step lifecycle/geometry regression pass;
startup retains one layer and 48px reservation with clean logs. The supplied
CC screenshot shows the reference tile/slider treatment, and the operator
confirmed compact-height restoration after Wi-Fi/Bluetooth detail navigation.
This is bounded geometry confirmation, not blanket visual approval. Missing custom icon assets and
unimplemented profile/media/action modules prevent full literal reproduction;
no empty placeholders or new services were added.

## Shared composition review — 2026-09-26

The right status cluster now expands as one `SharedStatusSurface`, with
persistent plugin-owned status visuals and body Components. Internal view
navigation replaces per-plugin collapse/reopen in combined mode. Volume is
icon-only; Battery carries percentage; Control Centre sliders place icons over
the tracks. The anchored fallback remains selectable.

The operator confirmed the shared-cluster visual model, then reported a
collapse/reopen stall. Its binding-order fix passes a 41-step offscreen
real-component regression. The operator subsequently passed full collapse,
repeated/rapid Control Centre reopening, and Control Centre → Bluetooth detail
→ Back without surface collapse. This **bounded structural checkpoint is accepted**;
full focus/fullscreen/password-flow regression remains separate.
Startup, logs and the one-layer/48px compositor baseline passed; those checks
are not proof of transition, focus or network-flow equivalence. See
[the design correction and checkpoint](design/shared-status-surface.md).

## Prior accepted production checkpoint

Updated **2026-09-26** from repository HEAD
`35c282012f2d749081a3f8b1821f01bf0b8aa6ea` plus the current uncommitted
integration work.

- The combined same-surface host is selected in `shell.qml`. MAGI owns one
  output-local full-height top-layer surface and reserves exactly 48 logical
  pixels. Bar, selected menu and consuming dismissal catcher share one native
  input Region.
- The anchored PopupWindow/TransformWatcher implementation remains selectable
  as rollback. It is not the design target for new plugins.
- Volume, Wi-Fi, Bluetooth and Control Centre are real configurable
  ExpandablePlugin entries. The former inline Settings/Controls demonstrations
  are removed from production placement.
- The right-side order is Volume, Wi-Fi, conditional Bluetooth, Battery and
  Control Centre. Bluetooth hides while disconnected but remains reachable
  through Control Centre.
- Shared services now cover Network, PipeWire audio, BlueZ Bluetooth,
  brightnessctl-backed brightness, UPower battery, Settings and semantic menu
  selection.
- Wi-Fi browsing uses the combined host while password entry remains a
  separate OnDemand PanelWindow. The operator passed scanning, radio,
  known/open/PSK connections, masked entry, Enter/Connect/Cancel, error/retry,
  successful connection and scanning handoff.
- On the tested eDP-1 scale-2 session, every checkpoint retained one
  1920x1080 combined MAGI layer at `(0,0)` and reservation
  `[0,48,0,0]`. Multi-output and fractional-scale behavior remain untested.

See [Architecture](architecture.md) for current ownership and
[the migration record](research/combined-surface-migration-plan.md) for
checkpoint evidence.

## Verified installed environment

Verified locally on 2026-09-24 with `pacman -Q`, `quickshell --version` and
`Hyprland --version`:

| Component | Installed version |
| --- | --- |
| Quickshell | 0.3.1; Arch package 0.3.1-1; binary revision blank |
| Hyprland | 0.56.2; Arch package 0.56.2-3 |
| Hyprland commit | `efb50993780079460b0cbed1363e2166a2de1d9f` |
| Qt base | 6.11.2-3 |
| Qt declarative | 6.11.2-2 |

These identify installed software, not the binaries loaded by an existing
session. API research must target Quickshell 0.3.1 and account for this Qt
and Hyprland environment.

## Documentation

- [Architecture](architecture.md): current structure and proposed concerns.
- [Quickshell reference](quickshell-reference.md): version-specific evidence.
- [Decisions](decisions.md): implementation history and preservation rules.
- [Local audit](research/local-audit.md): findings and unanswered questions.
- [Research index](research/README.md): completed and planned investigations.
- [Quickshell windows/lifecycle](research/quickshell-windows-and-lifecycle.md):
  phase-1 API research, proposed lifecycle and pending tests.
- [K4](research/k4.md) and [Serpantinum](research/serpantinum.md): phase-2A
  pinned source investigations, including a neutral surface comparison.
- [Combined-surface experiment](research/architecture-experiment.md): isolated
  fixture design, measurements and completed host-validation results.
- [Render architecture requirements](design/render-architecture-requirements.md):
  architecture-relevant visual and interaction direction from the current
  MAGI render; it is not a styling specification.
- [Combined-surface migration plan](research/combined-surface-migration-plan.md):
  production invariants, ownership, staged checkpoints and rollback paths.
- `tasks/`: intended location for bounded research and implementation tasks.

## Next steps

1. Refine render-driven production presentation, especially connected
   Bluetooth name/header continuity, tile styling and menu spacing.
2. Validate multi-output association, hotplug and fractional scaling.
3. Add explicit Bluetooth pairing-agent UX only after its prompt/security
   lifecycle is designed.
4. Consider Wi-Fi timeout, enterprise-security and adapter-failover work as
   separate Network-service changes with real connection tests.
5. Continue Noctalia **v4**, Lucid and Caelestia investigations when external
   research resumes.

The initial audit and external-project reports remain historical evidence.
Record new source/API findings, runtime measurements and compatibility limits
without rewriting historical results.

Supplementary references retained for later evaluation:
[Quickshell Book](https://github.com/programmersd21/the_quickshell_book) and
[Tony's tutorial](https://tonybtw.com/tutorial/quickshell/).
