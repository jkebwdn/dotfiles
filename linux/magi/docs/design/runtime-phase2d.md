# MAGI visual overhaul — Phase 2D native review checkpoint

2026-10-17. Baseline: `5c86ea90de8105a49abccf6b6f2d9241a57e1270`,
`magi: overhaul hub and utility surfaces`. Phase 2C native acceptance is complete;
its older pending-review wording records that milestone's implementation history.
Phase 2D is uncommitted and awaits native operator review.

## Calendar

The existing CalendarContent now measures a compact month/navigation row, secondary
selected-date summary, weekday headings and the six-row date grid. CalendarSurface
uses the production content's implicit height plus existing surface insets, replacing
the duplicated fixed header offset. Width remains 344 logical px; density retains
32/38px cells. The outer radius uses the expanded `surface` role with reference 11.
There is no new animation or host. Time/date absorption, anchoring, clock formatting,
shared lifecycle, outside dismissal and the bar's 48px reservation are unchanged.

Today keeps accent text/outline; selected dates use overlay fill; the keyboard-focused
selected date gets a focus outline. Adjacent dates and ISO week numbers use readable
subtext rather than muted ink. Local date math, week start, adjacent-day visibility,
month navigation, Today and arrow/PageUp/PageDown/Home behaviour remain canonical.
No events or providers were added.

## Wallpaper architecture and presentation

Settings → Wallpaper now embeds the actual WallpaperContent. One virtualized grid
and one WallpaperTile implementation serve the manager; no second implementation
or Hub mode was introduced. The page uses Settings selectors/buttons, responsive
monitor/fit controls, collection filter, Random/Refresh, current selection and status,
followed by a bounded scrolling grid. Library sources are a collapsed Settings section
below the manager, with explicit Save directories and quiet unsaved-draft feedback.
Enable, thumbnail size, clear recents and preference reset remain available.

The manager's preferred height is max(360, page height minus 150). Its grid uses the
remaining space with a 140px minimum; the Settings page scrolls at short heights.
Monitor/fit controls stack below 520px content width. Columns derive from available
width and the existing thumbnail-size preference, allowing one column at narrow sizes.
Tiles keep image aspect through PreserveAspectCrop; captions sit on semantic surfaces
outside the image rather than a hard-coded dark overlay. Current, keyboard selection,
favourite, loading, unavailable and empty-library states remain distinct.

Wallpaper.open/IPC now select the Wallpaper Settings page and route through Hub Settings.
Wallpaper.opened reflects that visible page, and close closes that Settings Hub session.
Disabling wallpaper leaves Settings usable. Page navigation retains content, grid state,
filter, fit choice and unsaved directories; revisiting refreshes backend status.
The shell explicitly initializes Wallpaper so startup restore/topology handling does
not depend on opening Settings after removal of the window instance.

WallpaperWindow is retained only as an internal fallback wrapper over the same content;
**shell.qml no longer instantiates it**. It is not a normal production route. No hidden
standalone manager remains. The scanner, Python backend/state workers, confirmed
selectionChanged extension point, apply/rollback, source immutability, favourites,
bounded recents, random eligibility and monitor mapping are unchanged. No Theme
Orchestrator coupling, derived palette, scheduling or directory auto-save was added.

## Media and shared artwork

MediaSection retains its size/roundness controls and permanent Control Centre card.
Title is primary, artist/identity secondary, both bounded/plaintext; truncated title
has a tooltip. Transports align under metadata, preserve capability checks and gain
readable action names/tooltips. Missing media retains artwork fallback and quiet copy,
while hiding transport controls. Playing/paused controls and the existing artwork
progress frame remain service-driven; no seek/new player behaviour was added.

Wallpaper thumbnails now use the same inset source, layered alpha mask and MultiEffect
as avatar, album art, Launcher header and Clipboard thumbnails. RoundedArtwork exposes
source status, asynchronous/cache and sourceSize inputs with unchanged defaults.
Wallpaper opts into asynchronous, uncached 320×200 decode bounds and cacheBuffer 0;
virtualized offscreen delegates are still released. Media retains independently tuned
album-art size/radius. No palette definitions or existing artwork shape settings changed.

The bounded secondary-surface audit found no reason to expand scope beyond Calendar,
Wallpaper and Media. Network/detail surfaces already use the accepted shared family
and Phase 2B presentation. Toasts and accepted Hub utility surfaces were left alone.
No final whole-shell polish, global bindings, mftrunk work or excluded roadmap feature.
Settings schema remains **11**, with no new persisted keys or migration.

## Verification

Commands run from `linux/magi`, with disposable configuration/state and existing
isolated service adapters. Logs, protected-state snapshot and optional software captures:
`/tmp/magi-phase2d/`. All listed checks pass:

- `node tests/calendar/math.cjs`, `node tests/calendar/schema.cjs`:
  civil date/month/week math and current-schema preference validation.
- `python3 tests/calendar/presentation.py`, `python3 tests/calendar/bar.py`:
  local grid, locale/week start, density, adjacent days, Today, navigation/keyboard,
  clock/date formats, real bar anchoring/absorption, dismissal and reservation.
- `python3 tests/wallpaper/backend.py`: nine existing discovery/deduplication,
  transaction/rollback, persistence, monitor and source-safety tests.
- `node tests/wallpaper/schema.cjs`: existing preference validation. This and the
  Calendar schema test now expect the already accepted schema 11, not obsolete 10.
- `python3 tests/wallpaper/presentation.py`: real manager inside real Hub Settings,
  discovery/apply/failure/reload/reset, favourites/recents, Random/per-monitor apply,
  retained drafts/fit/instance, thumbnail decode/mask/bounds and offscreen delegate
  release, arrow/Enter, Escape/outside dismissal. Checks 752×768, 1280×900 and
  3840×2160 logical outputs in Mocha, Frappé, Everforest Dark Hard and Light Hard.
  Only the native Hub window wrapper is adapted for the offscreen platform.
- `python3 tests/settings/presentation.py`, `python3 tests/settings/run.py`:
  all canonical pages, keyboard/palettes, explicit directory save, reset/store/migrations.
- `python3 tests/settings/media.py`: existing MPRIS selection/metadata/actions.
- `python3 tests/hub/run.py`: accepted five modes, selector anchor, Settings retention,
  routing, child Escape, utility actions and content-aware Notifications height.
- `python3 tests/runtime-visual/run.py appearance.qml`: existing live artwork extrema,
  avatar/media mask geometry and Settings-wide preview controls.
- `python3 tests/runtime-visual/run.py hub.qml`: real Settings-wide pinned CC preview,
  page navigation, live controls, ownership, cleanup and unchanged 48px reservation.
- `python3 tests/runtime-visual/run.py secondary.qml`: production Calendar/media across
  four palettes; Today vs focused selection; measured grid; min/default/max media art,
  square/portrait/landscape/no-art, radii 0/1/2, metadata/control bounds, keyboard and
  unavailable actions, playing/paused/nothing-playing.
- `python3 tests/runtime-visual/run.py`: shared artwork contour/source/mask geometry,
  runtime avatar and accepted surface/dismissal regression. Hub coverage also checks
  Launcher header and Clipboard thumbnail consumers.
- `python3 tests/shared-status-surface/run.py`: 48 lifecycle steps.
- `git diff --check`: clean.

Known offscreen window-mask and absent-system-backend messages remain bounded by the
existing harnesses; the Wallpaper missing-image warning is an intentional error fixture.
Software rendering does not render the GPU artwork mask faithfully. Geometry assertions
and software captures do **not** establish native image edges or compositor focus.

## Protected state and native checkpoint

All **483 protected records** match the pre-edit snapshot: operator settings, backups,
Theme Orchestrator state/integrations, Hypridle, Hyprlock, Yazi flavour and all initial
local changes. No protected file was restored, staged or normalized. No commit, push,
shell restart, native wallpaper apply or Hyprland configuration change was performed.

Native review required:

1. Calendar month/date hierarchy, Today/focus/adjacent contrast, both densities and
   week-number options; clock/date anchoring, Escape/outside click and 48px reservation.
2. Settings → Wallpaper on the actual scaled output, including page/grid scrolling,
   library disclosure and deliberate Save, favourites/recents/Random, shared/per-monitor
   apply and errors. Verify direct wallpaper IPC opens this page, with no second window.
3. Bright/dark portrait/landscape thumbnails, album art, avatar, header and Clipboard
   artwork edges at native/fractional scale; media minimum/maximum size and roundness,
   no-art/nothing-playing, long metadata and keyboard transport controls.
4. Mocha, another Catppuccin, Everforest Dark and Light; Settings-wide pinned CC preview
   and normal Calendar/Hub ownership remain usable.

Stop for screenshots and operator feedback. Do not begin whole-shell polish.

## Exact changed paths

Paths relative to `linux/magi`; protected operator state is excluded.

- `.config/quickshell/magi/components/calendar/CalendarContent.qml`
- `.config/quickshell/magi/components/calendar/CalendarSurface.qml`
- `.config/quickshell/magi/components/controls/MediaButton.qml`
- `.config/quickshell/magi/components/controls/RoundedArtwork.qml`
- `.config/quickshell/magi/components/settings/pages/WallpaperPage.qml`
- `.config/quickshell/magi/components/wallpaper/WallpaperContent.qml`
- `.config/quickshell/magi/components/wallpaper/WallpaperTile.qml`
- `.config/quickshell/magi/components/wallpaper/WallpaperWindow.qml`
- `.config/quickshell/magi/plugins/bar/controlcentre/MediaSection.qml`
- `.config/quickshell/magi/services/Wallpaper.qml`
- `.config/quickshell/magi/shell.qml`
- `docs/README.md`
- `docs/architecture.md`
- `docs/decisions.md`
- `docs/design/runtime-phase2d.md`
- `docs/quickshell-reference.md`
- `tests/calendar/schema.cjs`
- `tests/hub/actions.qml`
- `tests/runtime-visual/run.py`
- `tests/runtime-visual/secondary.qml`
- `tests/settings/presentation.qml`
- `tests/wallpaper/integration.qml`
- `tests/wallpaper/presentation.py`
- `tests/wallpaper/reload.qml`
- `tests/wallpaper/schema.cjs`
