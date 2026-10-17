# MAGI visual overhaul — Phase 2C native review checkpoint

> Phase 2E.1 supersedes legacy-tool references below: MFTrunk and Rofi are retired; MAGI Apps is the sole launcher route. Earlier references record historical state.

2026-10-17. Baseline: `398fe6c0c0240fa204f9cba3c29f2b323dc4539a`,
`magi: overhaul bar and control centre surfaces`, on `main`.
Implementation is uncommitted; native operator acceptance is pending.

## Architecture and composition

One production `HubWindow` retains the independent Apps, Clipboard, Notifications
and Emoji contents/services. Settings is the fifth stable mode ID, `settings`.
Selector order is `apps`, `clipboard`, `notifications`, `emoji`, `settings`.
Labels are presentation only; no mode persistence or display-string routing was added.

`HubContent` is now a transparent FocusScope containing two separate surfaces:
the active content rectangle and a 212×44 logical-pixel selector pill. The internal
`contentSelectorGap` is 12px. Every content surface uses semantic `surface`, `border`
and `Theme.radius("surface", 11, width, height)`, matching the expanded-surface
reference. Controls keep their own radii. Selector fill/active/focus use surface,
overlay, border and focus roles; icons use palette text. Tooltips and accessible
names provide labels without a permanent text tab bar.

The selector's **top** is anchored at two-thirds of the logical output height,
clamped between 120px and output-height minus 60px. Content bottom is always 12px
above it; content top is constrained to at least 64px. Output dimensions, rather
than physical monitor pixels, drive this calculation. Switching modes changes
content size upward without moving the selector. There is no additional animation
or spring; existing control motion remains. No new user-facing composition setting.

| Mode | Preferred content surface width | Preferred content surface height |
| --- | --- | --- |
| Apps | Existing list/grid preferences; defaults 420 / 720 | 88 + enabled header height (150) + visible row heights; default list 424, grid 376 |
| Clipboard | 540 | 660 |
| Notifications | 430 | Measured content, capped at 640 |
| Emoji | columns × (emoji size + 24) + 32; default 448 | 148 + 5 × (emoji size + 24); default 408 |
| Settings | 1000 | 720 |

Heights exclude the 12px gap and 44px selector. All modes fit the available space
above the anchor; e.g. at logical 1920×1080, content height is capped at 644px.
Settings retains independent navigation/page scrolling rather than forcing its
preferred dimensions into another utility's size. At short outputs the same cap
applies; native usability at unusual scales/output dimensions remains a review item.
Legacy Launcher whole-panel position data remains preserved but no longer determines
Hub placement; its obsolete editor was removed. Header top/bottom position still works.

F6 reaches the selected mode button; Left/Right moves selector focus, and
Enter/Space activates. Content arrows retain their existing search/grid/selection
meaning. Child controls get Escape first; otherwise Hub closes. Mode buttons and
content consume interior input; the transparent gap/outside region dismisses Hub.
Direct shortcuts and existing catalogue actions retain their stable routes.
Control Centre/Calendar are still separate incompatible surfaces, except for the
explicit Settings-owned Control Centre preview. No global binding remap was made.

## Canonical Settings and preview

`SettingsContent.qml` extracts the existing Settings UI. No page implementations,
store, schema writer, migrations, arranger or orchestrator backend were copied.
The Hub lazily creates this one content instance on first visit and retains it,
including visited page Loaders, drafts and scroll state. All 11 existing pages,
controls, reset/persistence paths, Control Centre ordering and Bar arranger remain.

`SettingsWindowState.open()` routes to `Hub.open("settings")`. Existing buttons,
Control Centre actions and `settingsWindow` IPC use that route. `SettingsApplication`
is now an IPC adapter and creates no window or Loader. The small **internal**
`SettingsWindow.qml` FloatingWindow wrapper remains for isolated presentation tests;
it wraps the same SettingsContent and is not instantiated by the production shell.
Thus there is no second normal user-facing Settings experience or hidden old host.
The old compositor title rule was left untouched with the operator's Hyprland state.

The real production Control Centre preview remains pinned across Settings pages.
Hub ownership allows only this pinned exception. Its overlay input region subtracts
the actual preview rectangle, tracked using TransformWatcher and scene coordinates,
so pointer input can reach the underlying bar surface. Settings content fits to the
left of the preview when necessary; the selector remains centred on the output.
The initial collapse/interaction readiness gate still applies. Once presented, Hub
stays mapped while preview opens/retracts. Closing Hub, leaving Settings or opening
an incompatible menu clears the pin and restores normal Control Centre dismissal.
There is no fake preview or persisted preview state.

Native layer-shell focus, pointer routing through the subtracted region, narrow-output
side-by-side usability, and transient file chooser focus still require operator checks.
Offscreen tests verify geometry, actual production content and ownership, not compositor dispatch.

## Utility presentation

**Apps:** common semantic surface/search; custom background image renderer and
Settings controls removed. Old raw background keys are preserved as unknown data
instead of rewriting operator preferences. Persistent application-count/Enter/Escape
footer hints are removed; actionable launch errors and temporary busy status remain.
Discovery, ranking, list/grid, hidden IDs/restoration and GIO terminal launch are unchanged.

Header artwork uses the existing `RoundedArtwork` mask and inset frame. Schema 11
additively defaults/validates `headerFit` (cover/contain), `headerRadius` (0–75),
`headerBorderWidth` (0–8) and `headerBorderRole` (border/rim/accent/subtext).
`headerEnabled`, image path and top/bottom position remain canonical. Cover maps to
PreserveAspectCrop, contain to PreserveAspectFit; both use the same clipped source,
rounded alpha mask and independent border. RoundedArtwork's new fillMode input
defaults to its existing crop behaviour for all other consumers.

**Notifications:** redundant large title/close removed. The compact notification
enable switch uses the established Settings toggle, with DND and Clear All icon
actions and tooltips. History cards use elevated surface, app/time metadata together,
primary summary, bounded secondary body and keyboard-capable dismiss/action buttons.
Empty history now has a semantic icon, stronger title and secondary help, including a paused state; service-unavailable feedback remains distinct. Notification model/DBus
ownership, replacement, actions and toast positioning/policy are unchanged.

**Clipboard:** removes duplicate title/close/settings chrome in favour of Hub
navigation; shares search, padding and surface family. History selection uses overlay,
rows use elevated, timestamp ink uses subtext, and pin/delete retain accessible
buttons. Existing RoundedArtwork thumbnails, a clearer icon/title/help empty state, privacy/storage note,
pause/clear actions, exact payload restoration and stable-ID keyboard selection remain.

**Emoji:** shares search and surface family while retaining category selector,
selection/hover styling, empty/no-result feedback, Unicode data, Recents and exact
multi-codepoint copy semantics. No emoji data or clipboard service redesign.

Shared components: `HubSearchField` is a native TextField with icon, clear action,
semantic styling and mode-owned handlers; `controls/IconButton` promotes the existing
Clipboard button, with a compatibility wrapper; `RoundedArtwork` supplies image masking;
`SettingsContent` owns the single Settings UI. Legacy's missing search glyph was added
through the existing registry; first-party SVGs and all existing role mappings remain.

## Automated verification

All commands below run from `linux/magi`. Tests use synthetic fixtures and disposable
configuration/state. Logs: `/tmp/magi-phase2c-1792226529/`.
Software captures cover all five modes in Catppuccin Mocha/Frappé, Everforest Dark Hard
and Everforest Light Hard. They establish layout/semantic-role behaviour, not native
GPU mask quality or comprehensive contrast certification.

- `python3 tests/hub/run.py`: real host/content/controller; five mode IDs, retained
  content/state, pointer and keyboard selection, fixed selector coordinates at logical
  1024×768, 1280×900, 1920×1080 and 3840×2160; mode dimensions, direct routes,
  Escape/outside close, ownership/fullscreen guards; actual launch/emoji copy,
  notification default/explicit actions, dismiss/update, DND, enable/Clear All;
  clipboard search/text/image/URI presentation, pin/unpin/delete/clear and restore ID;
  all Settings pages, retained instance, header mask/fit/border, save/reload/reset and palettes.
- `python3 tests/runtime-visual/run.py hub.qml`: real Bar + Hub + pinned Control Centre;
  cross-page preview, live size changes, subtracted mask geometry, fixed selector,
  preview close, Hub close, outside close, mode exit, Calendar handoff, normal catcher
  restoration, and production 48px reservation expression.
- `python3 tests/runtime-visual/run.py appearance.qml`: existing live appearance,
  typography and 96 section-gap combinations now exercised with Settings **inside Hub**;
  production preview, live controls and cleanup pass.
- `python3 tests/settings/reorder.py --hub`: existing production Control Centre and
  Bar drag/keyboard ordering, scroll, cancellation, popup/dialog/editor Escape,
  metadata and persistence checks inside Hub at minimum/default content sizes.
- `python3 tests/settings/presentation.py`: all canonical Settings pages, navigation,
  controls, reset, drafts, keyboard and five palettes in the internal test wrapper.
- `python3 tests/settings/run.py`: store/schema/migration/persistence/reset.
- `node tests/settings/schema.cjs .config/quickshell/magi/settings`: new header ranges,
  enums/defaults and raw retired-key preservation, plus existing schema checks.
- `python3 tests/theme-orchestrator/qml.py`: real Settings bridge, Hub routing,
  orchestrator pointer/confirmation/error paths and exact Zen Copy in all ten palettes.
- `python3 tests/settings/modules.py catalogue`: all five Control Centre routes,
  real collapse gate, focus, optional entries, independent columns and unavailable handling.
- `python3 tests/shared-status-surface/run.py`: 48 lifecycle steps.
- `python3 tests/launcher/presentation.py` and `python3 tests/launcher/backend.py`:
  production search/list/grid/hidden/restore and isolated XDG/GIO/terminal execution.
- `python3 tests/notifications/presentation.py` and `python3 tests/notifications/run.py`:
  existing toast/history presentation and private-bus notification protocol/activation,
  including replacement/action/dismiss semantics. Backend tests were not rewritten.
- `python3 tests/clipboard/presentation.py` and `python3 tests/clipboard/model.py`:
  existing selection/service/privacy/MIME/restore paths; all 10 model tests pass.
- `python3 tests/emoji/presentation.py`: category/recents/search/copy, stale completion,
  failure handling and exact UTF-8 handoff.
- `python3 tests/runtime-visual/run.py`: runtime artwork, utilities, profile, palette,
  outside/Escape and pending-authentication regression.
- `python3 tests/runtime-visual/run.py colours.qml`: all 600 exact Phase 2B colour pairs.
  Oracle permits only the added Legacy search role; existing mappings/renderers still match.
- `node tests/settings/icons.cjs .config/quickshell/magi/icons`: registry/fallback checks.
- `git diff --check`: clean.

Initial Clipboard image decoding and private notification-bus startup were blocked
by sandbox D-Bus/socket permissions. Their isolated reruns outside the sandbox passed;
neither test used the desktop clipboard/history or desktop notification bus.
Known offscreen missing-mask/platform/backend warnings are filtered by the existing
bounded harness patterns. No native visual acceptance is claimed.

## Protected operator state

Before edits, the initial dirty/untracked paths and repository Settings backups were
copied to `/tmp/magi-phase2c-1792226529/files/` with hashes/symlink targets. A second
manifest covers Settings backup/runtime membership and generated Theme Orchestrator
state. Final comparison: **16 initial source/backup records and 420 runtime records
unchanged**, with no runtime membership additions/removals. These counts can overlap
through deployment symlinks; they are not 436 unique physical files.

Protected settings.json, backups, integration files, Hypridle, Hyprlock, Yazi flavour
and all pre-existing local changes remain untouched and unstaged. No live configuration
normalization, shell restart, Hyprland edit, commit, push or staging was performed.

## Native operator checkpoint

Stop here for screenshots and feedback. Check:

1. All five modes and direct shortcuts; selector stability on the actual scaled output,
   short/tall mode transitions, outside/gap dismissal and previous-application focus.
2. Settings navigation, scrolling, file choosers, dropdown/dialog/editor Escape and drag
   cancellation; one Hub layer and no standalone Settings desktop client.
3. Real pinned Control Centre pointer interaction, live profile/appearance updates,
   Settings usability beside it, page navigation, close/reopen and pin cleanup.
4. Header top/bottom, portrait/landscape, cover/contain, zero/max border and radius;
   inspect GPU masking at normal/2×/fractional scale. Check Clipboard image edges too.
5. Populated notification history/actions/DND/Clear All, clipboard payloads and Emoji
   selection/recents in Mocha, Frappé, Everforest Dark and Everforest Light.
6. Exactly 48 logical px reserved by the main bar; Hub reserves nothing. Normal
   Control Centre/Calendar ownership and independent toast positioning still hold.

Deferred only: notification history ageing (possible 2h/6h/24h/until-cleared policy
and critical urgency treatment), full global keybind conflict audit/remap, mftrunk
redundancy audit, and future Wallpaper Manager integration under Settings → Wallpaper.
No Wallpaper Hub mode, ageing policy, mftrunk removal or next roadmap phase was implemented.

## Exact agent-changed paths

Paths below are relative to `linux/magi`; protected local changes are excluded.

- `.config/quickshell/magi/components/clipboard/ClipboardContent.qml`
- `.config/quickshell/magi/components/clipboard/ClipboardIconButton.qml`
- `.config/quickshell/magi/components/controls/IconButton.qml`
- `.config/quickshell/magi/components/controls/RoundedArtwork.qml`
- `.config/quickshell/magi/components/emoji/EmojiContent.qml`
- `.config/quickshell/magi/components/hub/HubContent.qml`
- `.config/quickshell/magi/components/hub/HubSearchField.qml`
- `.config/quickshell/magi/components/hub/HubWindow.qml`
- `.config/quickshell/magi/components/hub/qmldir`
- `.config/quickshell/magi/components/launcher/LauncherContent.qml`
- `.config/quickshell/magi/components/notifications/NotificationCard.qml`
- `.config/quickshell/magi/components/notifications/NotificationContent.qml`
- `.config/quickshell/magi/components/settings/SettingsApplication.qml`
- `.config/quickshell/magi/components/settings/SettingsContent.qml`
- `.config/quickshell/magi/components/settings/SettingsWindow.qml`
- `.config/quickshell/magi/components/settings/pages/LauncherPage.qml`
- `.config/quickshell/magi/components/settings/qmldir`
- `.config/quickshell/magi/icons/packs/registry.json`
- `.config/quickshell/magi/services/Hub.qml`
- `.config/quickshell/magi/services/SettingsWindowState.qml`
- `.config/quickshell/magi/settings/SettingsSchema.js`
- `.config/quickshell/magi/shell.qml`
- `docs/README.md`
- `docs/architecture.md`
- `docs/decisions.md`
- `docs/design/runtime-phase2c.md`
- `docs/quickshell-reference.md`
- `tests/hub/actions.qml`
- `tests/hub/catalogue.qml`
- `tests/hub/composition.qml`
- `tests/hub/integration.qml`
- `tests/hub/pointer.qml`
- `tests/hub/run.py`
- `tests/runtime-visual/appearance.qml`
- `tests/runtime-visual/hub.qml`
- `tests/runtime-visual/run.py`
- `tests/settings/icons.cjs`
- `tests/settings/modules.py`
- `tests/settings/reorder.py`
- `tests/settings/schema.cjs`
- `tests/settings/window.qml`
- `tests/theme-orchestrator/qml.py`


## Native Notifications refinement — 2026-10-17

The operator accepts the Hub composition, separate selector, stable anchor, Settings
integration, Apps cleanup and Clipboard/Emoji direction. Only Notifications is refined:
remove the enabled toggle's visible title while keeping its accessible name and
state-specific tooltip; retain the toggle at left and DND/Clear All at right.

NotificationContent now exposes implicitHeight from its production header, ListView
contentHeight (real NotificationCard delegates) or the measured empty-state column.
Existing 14px content insets and 10px section spacing are named local tokens. Hub adds
the existing 8px inset on both edges and caps this mode at 640px. The existing logical
output clamp may reduce that cap further. Width remains 430px. The selector anchor,
12px composition gap, scroll view, cards/actions, backend and toast host are unchanged.
No additional measurement cards, model/service or reservation were added.

Focused verification: `python3 tests/hub/run.py`,
`python3 tests/notifications/presentation.py` and `git diff --check`.
The new Hub fixture checks empty, one/two-card, replacement-text and full histories
at three logical output sizes; exact selector coordinates, upward growth, the 640px/
output cap, scroll-to-last-card and Clear All shrinkage. Existing Hub action coverage
checks enable, DND, Clear All, dismiss and default/explicit actions.

Stop for one native Notifications screenshot. No commit, push or other redesign.

Exact paths changed in this follow-up (relative to `linux/magi`):

- `.config/quickshell/magi/components/hub/HubContent.qml`
- `.config/quickshell/magi/components/notifications/NotificationContent.qml`
- `docs/README.md`
- `docs/architecture.md`
- `docs/decisions.md`
- `docs/design/runtime-phase2c.md`
- `docs/quickshell-reference.md`
- `tests/hub/notifications.qml`
- `tests/hub/run.py`

Validation passed: Hub runner (including the new height fixture), Notifications
presentation and `git diff --check`. Protected snapshot comparison retains all
472 records outside the eight intentionally edited existing source/test/doc files;
the new test is additional. No protected operator-state file changed.
