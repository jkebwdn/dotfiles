# Settings Phase 2A.3 native feedback checkpoint

> Phase 2E.1: Hub uses Escape after child interactions; Super+Q is only an ordinary compositor application binding, not a Hub close requirement.

2026-10-16. The accepted uncommitted Phase 2A, 2A.1 and 2A.2 work remains in place. This pass refines Settings selection, configured-item presentation, application-theme status and Escape handling. Native operator review remains the final checkpoint. Nothing is committed or pushed, and Phase 2B has not begun.

## Sidebar and configured controls

Sidebar selection now uses the existing semantic accent marker and demi-bold text, without a selected background fill. Hover/pressed surfaces remain temporary; the existing keyboard-focus outline remains independent of selection.

Primary and secondary configured lists now show only enabled entries, matching the existing runtime filters in `plugins/bar/controlcentre/ControlCentre.qml`. Separate enabled switches are removed. The underlying format has a useful distinction: disabled records retain their stable key, accent and position. They therefore remain stored and appear in Available, rather than being deleted during a migration or on page entry.

Remove calls existing `editControl`/`editEntry` with enabled=false. Add re-enables an existing disabled record through `editEntry`, retaining its preferences and previous position, or uses `addEntry` for an identity not already stored. The catalogue-derived Available selector includes both cases and excludes configured identities. No schema/default migration, automatic file rewrite or runtime Control Centre code change is needed. This deliberately changes the Settings remove interaction from deleting a record to making it available while preserving metadata.

Each primary row is now 50px high: identity selector, accent swatch/selector, remove and drag handle. Secondary rows use identity, remove and handle. Visible reorder destinations are mapped back to canonical array indices before invoking existing moveControl/moveEntry APIs, so disabled records do not break visible ordering. Independent columns/actionColumns remain unchanged.

The accepted Bar arranger is unchanged. The shared drag board has only an Escape-ownership binding added to its handle; live preview, stable delegates, insertion line, edge scrolling, 120ms OutCubic movement and cancellation remain. Alt+Up/Down and Alt+Home/End still order controls/actions; Bar retains Alt+Left/Right for region changes.

## Application themes

Each target now presents its name, Follow MAGI switch, concise state and detail disclosure in one row. Healthy reload/restart paragraphs and palette details are collapsed by default. Full status text remains available through the disclosure; errors, setup requirements, integration confirmation and manual-action requirements are visible automatically. Retry is available in expanded enabled rows and immediately for enabled error rows; Remove hooks retains its existing conditions and handler.

Zen retains the visible manual workspace-colour instruction, dynamically derived exact hex, Copy and restart requirement. Qt, hyprtoolkit and Hyprlock remain compact deferred rows with disabled enrollment and expandable reasons. Enrollment, confirmation, disable, retry, adapter and Copy implementations are unchanged. Rows still come from ThemeOrchestrator.targets; themes still come from ThemeRegistry, with no new fixed target/theme list in presentation.

## Closing Settings

SettingsWindow handles Escape on its outer Pane with Keys.AfterItem. Child controls and popups consume the key first. An active drag handle consumes Escape to cancel; an idle handle lets it propagate. The inline integration confirmation also consumes Escape to cancel its pending plan. Otherwise the window updates the existing SettingsWindowState.shown property to close.

The operator's Hyprland configuration already binds `SUPER + Q` to `hl.dsp.window.close()` at `linux/t15g/hypr/.config/hypr/hyprland.lua:187`. `SUPER + SHIFT + Q` exits the session. No competing application shortcut or compositor edit was added. Super+Q continues through the existing compositor close route and still needs native confirmation; offscreen QtTest cannot dispatch a Hyprland shortcut.

## Validation

All focused runners pass:

- `python tests/settings/reorder.py`: production pointer/keyboard ordering at 720×500 and 940×720; hidden legacy entries in Available; remove/re-add retaining keys/accent; uniqueness; canonical persistence; Bar placement/availability; drag cancellation and stale-drop protection. Escape ownership covers drag, Dialog, consuming text editor, idle handle and ordinary navigation.
- `python tests/settings/presentation.py`: every page, marker-only selection, independent keyboard focus, popup Escape ownership, reset/drafts and bounds at both sizes across Catppuccin Mocha, Frappé, Latte, Everforest Dark Hard and Light Hard.
- `python tests/settings/run.py`: persistence/schema/migrations pass without modification.
- `python tests/settings/appearance.py`: ten palettes and live appearance pass.
- `python tests/theme-orchestrator/qml.py`: existing integration and window checks, production enrollment/confirmation/cancel/disable/error/changed-hook protection, compact/detail status assertions, bounds at content widths 530/750, and exact hex-only Zen Copy across all current palettes.
- `python tests/shared-status-surface/run.py`: all 48 steps pass; test unchanged.
- `git diff --check`: clean.

Software captures and logs are under `/tmp/magi-settings-phase2a3/`. The theme pointer fixture now supplies the same semantic text/background context as the production Settings Pane for meaningful dark/light captures. Software rendering does not replace native acceptance of focus, typography, drag feel or compositor close behavior.

## Protected state

Before editing, `protected.json`, `initial-status` and `settings-before` in `/tmp/magi-settings-phase2a3/` recorded the current operator state and accepted Settings source. Final `protected-after.json` and `protected-verification.txt` confirm all 13 protected records, flavors directory membership, symlink targets and protected Git statuses are unchanged. This includes live settings.json and all named t15g files. No stage, clean, reset or normalization occurred.

## Exact changed paths

Relative to `linux/magi/`, changes made in this pass are:

- `.config/quickshell/magi/components/settings/SettingsNavigationItem.qml`
- `.config/quickshell/magi/components/settings/SettingsWindow.qml`
- `.config/quickshell/magi/components/settings/SettingsDragHandle.qml`
- `.config/quickshell/magi/components/settings/SettingsReorderBoard.qml`
- `.config/quickshell/magi/components/settings/pages/ControlCentrePage.qml`
- `.config/quickshell/magi/components/settings/pages/AppearancePage.qml`
- `tests/settings/reorder.qml`
- `tests/settings/presentation.qml`
- `tests/theme-orchestrator/pointer.qml`
- `docs/design/settings-phase2a3.md`
- `docs/README.md`
- `docs/architecture.md`
- `docs/decisions.md`
- `docs/quickshell-reference.md`

Earlier uncommitted files are retained; this list is relative to the phase-start snapshot, not Git HEAD.

## Accepted future direction

The operator prefers integrating the actual Wallpaper Manager into Wallpaper Settings, rather than a Settings page that only launches another manager. A future Hub mode remains an alternative if later Hub composition favours it. The planned five-item Hub selector is Apps, Clipboard, Notifications, Emoji and Settings. Neither the integration nor that future selector is implemented here.

Wallpaper-derived palettes and automatic wallpaper-driven theme changes remain future work. Theme selection remains separated from target enrollment: a future palette source can feed the existing theme/orchestration boundary without embedding extraction logic or fixed theme/target lists in Settings rows. No extraction, automatic switching or backend changes are part of this pass.

Native review should confirm the marker-only sidebar, compact primary/secondary rows, remove/Available/re-add interaction, theme disclosure and important status visibility, Escape precedence and existing Super+Q. All runtime Control Centre, bar, profile, Hub, Calendar, Notifications and Wallpaper Manager work remains outside Phase 2A.3.


## Final native status refinement

The operator accepted Phase 2A.3 except for wrapping adapter prose in collapsed target rows. Application Themes now maps result text to short user-facing labels and keeps the status column on one line. Complete messages remain in expandable details; errors/setup failures and Zen manual colour/Copy stay visible. Unknown future adapter wording uses Details. This follow-up changes only AppearancePage.qml, tests/theme-orchestrator/pointer.qml and the existing documentation records. No architecture, enrollment, backend, drag, sidebar or key-handling changes. Relevant Settings presentation and Theme Orchestrator checks are the validation scope; final operator review remains pending.

Validation: Settings presentation (pages, keyboard, reset/drafts, five palettes and both sizes) and Theme Orchestrator QML (enrollment, status disclosure, one-line labels and exact Zen Copy) pass. All 13 protected records match the follow-up snapshot in `/tmp/magi-settings-status-final/`. `git diff --check` is clean. Nothing committed or pushed.
