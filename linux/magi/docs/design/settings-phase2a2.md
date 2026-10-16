# Settings Phase 2A.2 — interaction checkpoint

2026-10-16. Continues the uncommitted, operator-accepted Phase 2A/2A.1 work.
No commit, push, shell restart or Phase 2B work. Native interaction acceptance is pending.

## Interaction and ownership

Control Centre primary controls and secondary actions now have quiet drag handles instead of permanent ordering arrows. The existing enabled, identity, accent, remove/add and independent column controls remain. Bar Settings now derives three labelled lanes from the existing left/center/right arrays, plus an Available lane for hidden modules. At 720×500 the lanes stack; at 940×720 the three visible regions sit alongside one another. Sidebar, other pages, footer and accepted control styling are retained.

`SettingsReorderBoard` and `SettingsDragHandle` are Settings-only primitives. The board keeps delegates keyed by stable entry identity, so live rearrangement and crossing lanes retain the pointer grab, focused handle and loaded controls. Only the handle initiates a drag, after a 6px threshold. A transient visual order supplies live neighbouring-row rearrangement and a 2px insertion line. This is a cancellable preview, not a second persisted representation: canonical configuration changes on a valid drop, never on hover.

The page receives `moveRequested(key, lane, position)` and owns all mutations:

- Control Centre resolves the current key index and calls existing `moveControl` or `moveEntry`. Metadata stays with the original object; columns and actionColumns are independent.
- Bar uses existing `placeBar` for region changes/hiding and `moveBar` for the destination index or within-region moves. Cross-region placement can make two synchronous validated calls, with the existing debounced writer saving the final state. No schema, defaults, catalogue, service, runtime application timing or adapter changes.
- Hidden Bar modules are derived from IDs absent from the visible arrays. Available is alphabetically arranged and has no new stored ordering. Moving into Available hides a module; moving it out re-adds it.

Pointer coordinates are held in viewport space and remapped as the page scrolls. A 16ms timer moves the viewport 8px per tick in its 32px edge bands. Lane heights remain stable during the drag and may grow when needed. Leaving the viewport invalidates a drop. Escape, navigation away, window deactivation, board resizing, or external order/membership changes cancel without overwriting canonical state.

Neighbours reposition using 120ms OutCubic x/y animations. The dragged row follows the pointer with a semantic accent border and 0.92 opacity. There is no runtime-surface animation change or new theme system.

## Keyboard and focus

Tab to a handle, then use Alt+Up/Down for one position and Alt+Home/End for the ends. Bar additionally supports Alt+Left/Right between regions, including Available. Escape cancels pointer dragging. The focused delegate survives ordering and scrolls into view after moving. Shortcuts appear in a bounded, semantic tooltip and Accessible.description, without permanent instructional controls. Mouse and keyboard paths share the page mutation request, while keyboard moves do not depend on pointer state.

## Automated evidence

All of these runners passed against the working tree:

| Command (from linux/magi) | Result |
| --- | --- |
| `python tests/settings/reorder.py` | 0 failures: production pointer, keyboard, cancellation, scroll, metadata and persistence |
| `python tests/settings/presentation.py` | 0 failures: all pages, keyboard, palettes, reset and drafts |
| `python tests/settings/run.py` | 0 failures: existing persistence/schema coverage |
| `python tests/settings/appearance.py` | 0 failures: ten palettes and live appearance |
| `python tests/settings/modules.py window.qml` | 0 failures: Settings window integration |
| `python tests/theme-orchestrator/qml.py` | Theme pointer and exact hex-only Zen Copy PASS |
| `python tests/shared-status-surface/run.py` | 0 failures: 48 steps |
| `git diff --check` | clean |

The new fixture uses the real SettingsWindow, production pages/controls and a disposable HOME/config/data/state/runtime. It tests both actual backing-window sizes, 720×500 and 940×720: primary/secondary first-to-last, last-to-first and repeated ordering; enabled/identity/accent retention; both column values; production add/remove; all three Bar regions; cross-region moves; hide/re-add; uniqueness/validation; keyboard focus retention; scrolling; insertion bounds; cancellation; and disk save/reload. Stale-drop cancellation after an external order edit and page navigation are covered. Existing regressions were preserved.

Logs and software framebuffer captures are in `/tmp/magi-settings-phase2a2/`. The inherited presentation/palette coverage includes Catppuccin Mocha/Frappé and Everforest Dark/Light. Offscreen rendering and semantic assertions are evidence, not native appearance or compositor interaction acceptance.

## Protected operator state

Before implementation, `/tmp/magi-settings-phase2a2/protected.json` recorded file SHA-256 hashes, directory presence and symlink targets; `initial-status` captured Git status. Final `protected-after.json` and `protected-verification.txt` confirm all 13 records, flavors directory membership and protected Git statuses are unchanged. This includes live settings.json, all named t15g operator files, untracked hypridle/hyprlock and the magi.yazi symlink. No protected path was staged, normalized or rewritten. The initial Settings source snapshot is `settings-before`, allowing this phase to be distinguished from the earlier uncommitted work.

## Exact paths added or changed in this phase

Relative to `linux/magi/` (earlier uncommitted work remains in place):

- `.config/quickshell/magi/components/settings/SettingsDragHandle.qml` — new
- `.config/quickshell/magi/components/settings/SettingsReorderBoard.qml` — new
- `.config/quickshell/magi/components/settings/qmldir` — exports
- `.config/quickshell/magi/components/settings/pages/BarPage.qml`
- `.config/quickshell/magi/components/settings/pages/ControlCentrePage.qml`
- `tests/settings/reorder.py` — new isolated runner
- `tests/settings/reorder.qml` — new production interaction fixture
- `docs/design/settings-phase2a2.md` — this checkpoint
- `docs/README.md`
- `docs/architecture.md`
- `docs/decisions.md`
- `docs/quickshell-reference.md`

## Native operator checkpoint

Please inspect real pointer grab/threshold, insertion feel and neighbour motion; edge autoscroll at minimum/default sizes; cross-region and hidden-module drops; Escape/outside cancellation; keyboard focus and tooltip placement; and the four requested native palettes. Fractional scaling, compositor shortcut interception and window-focus transitions still need native validation. No claim of native acceptance is made from software captures.

Phase 2B runtime Control Centre, bar/status surfaces, profile header, Wi-Fi and Hub work remain deferred. Theme Orchestrator diagnostic compaction, all excluded integrations and whole-shell animation work remain outside this phase.
