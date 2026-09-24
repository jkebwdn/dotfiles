# MAGI — Research and Development

MAGI is a modular Quickshell environment for Arch Linux and Hyprland.
This directory records implementation evidence, decisions and proposed research.

## Audited development checkpoint

Read-only source audit: **2026-09-24**, repository HEAD
`e375e5ee95e82f5609c2aeb4b880b21eb38b1086`. Source references below describe
that snapshot; no interactive UI or connection tests were performed.

- `shell.qml:6` creates one bar. `components/bar/Bar.qml:15` defines a
  top-layer, top/left/right-anchored PanelWindow with a 48px implicit height
  and automatic exclusion. Expanded menus use separate windows.
- `Bar.qml:47` explicitly registers clock, date, workspaces, Wi-Fi, volume
  and battery. Repeaters/Loaders instantiate configured left/centre/right
  lists; there is no filesystem plugin discovery.
- `settings.json:3` selects Catppuccin, clock/date left, workspaces centre,
  and Wi-Fi/volume/battery right. `services/Settings.qml:17` watches and
  reloads JSON; it has no explicit save path or plugin-ID validation.
- Settings and Controls are unconditional inline test menus in
  `Bar.qml:162` and `Bar.qml:203`, outside the configurable registry.
- `ExpandablePlugin.qml` supplies staged width/reveal/fade animations,
  window-relative popup positioning, and Component/Loader content hosting.
  `services/MenuController.qml:10` stores the requested menu ID, not the
  completion state of animations or the Wi-Fi menu state.
- Wi-Fi retains its own selector, scanning and connection flow, plus a
  separate password PanelWindow. Volume and battery retain their tooltips.
  None has migrated to the shared expandable content interface.
- Earlier sessions reported working Wi-Fi and stress-tested two-menu
  positioning. These are historical reports, not new audit test results.

All QML paths above are relative to `.config/quickshell/magi/`; bar component
names without a directory are under `components/bar/`. See the
[source-referenced audit](research/local-audit.md) for details and risks.

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
- `design/`: intended location for annotated renders and specifications.
- `tasks/`: intended location for bounded research and implementation tasks.

## Research checkpoint and next steps

As of **2026-09-24**, phase 1 (official Quickshell windows/lifecycle) and
phase 2A (K4 and Serpantinum source investigations) are documented. Phase 2A
used MAGI HEAD `04b5e4b9556624f7a365524bebc8869d05f6cc21` as its local
comparison point. No runtime experiments or live implementation changes
were made during these research phases.

1. Review the lifecycle proposal and the
   [A/B/C technical comparison](research/serpantinum.md#technical-comparison-for-magi).
   Agree on focus, dismissal, content retention and screen ownership.
2. If approved, run bounded isolated tests with MAGI's current animation and
   positioning as the control; compare alternative hosts using identical
   content. Preserve the working shell and Wi-Fi flow.
3. Continue Noctalia **v4**, Lucid and Caelestia investigations after approval.
4. Research networking object lifetime, scanning ownership and failure
   handling before any Wi-Fi migration; review its acceptance tests first.
5. Implement only the separately approved contract/design increments.

Further research and implementation require the user's next approval.
Record URLs, inspection dates, pinned versions/commits, source
components, demonstrated behavior, compatibility and outstanding tests.
Check licenses before reusing code or assets. Keep proposals separate from
verified implementation and historical user reports.

Supplementary references retained for later evaluation:
[Quickshell Book](https://github.com/programmersd21/the_quickshell_book) and
[Tony's tutorial](https://tonybtw.com/tutorial/quickshell/).
