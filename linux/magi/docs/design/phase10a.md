# Phase 10A — Settings, Hub and icon refinement

Accepted and complete on 2026-10-20 over
`649326c77022bd400bf241336894102d50ff0616`. Operator live review passed,
including the accepted Clipboard option B. No package installation or deliberate
live shell reload was required. MAGI Lock security/authentication is unchanged.

## Ownership audit and changes

- SettingsStore remains the single persistence owner. Schema 12→13 is one deliberate
  migration: remove `icons.overrides`/`modulePacks`, keep pack/theme/status size,
  preserve unrelated values and history, default `appearance.mediaProgressRole`
  and `appearance.hubToggleRole` to `accent`. Reading migrates in memory only;
  a normal save later persists retirement. Invalid colour roles resolve to accent
  with a diagnostic, without a malformed-settings failure.
- Individual icon controls, setter, standalone SVG import operation and resolver
  precedence are removed. Built-in and installed manifests share `pack_manifest`
  validation and one resolver. Following the rejected initial fallback regression,
  the chain is selected pack → same-ID MAGI Default → `missing.svg`. The canonical
  default now explicitly declares the previously inherited same-ID glyphs, and
  existing SVG artwork/application icon lookup remain unchanged. See the
  [fallback correction audit](phase10a-icon-fallback.md).
- Appearance → Theme has responsive Theme/Icon Pack columns, local pack installation,
  and two semantic palette selectors. The small shared selector reuses SettingsSelector's
  existing swatches and ThemeRegistry's approved accent roles, plus `accent`.
  Theme resolves colour on palette changes, falling back to accent when necessary.
  MPRIS artwork-progress geometry/behaviour is unchanged. Hub selector and Settings
  switches use the Hub role; external Wi-Fi/Bluetooth switches retain their accent.
  Pill/Filled/Minimal styling remains independent.
- Icons page/registration/navigation are removed. MAGI branding remains without
  the redundant Settings subtitle. Existing sidebar save/error/conflict/reload
  behaviour remains; the footer is quiet, transparent and horizontally centred.
  Appearance tab composition uses the same top-inset token as the sidebar.
  Other pages do not receive that inset. Status icon size moves from Surfaces
  to Bar, keeping `appearance.visual.statusIconSize`, range 16–28 and default 18.
- Emoji category state was never persisted. `All` remains the useful initial
  category, followed by the nine normal categories. Removed/unknown category
  requests fall back to All. History stays in `emoji.recents`; a one-line row
  shows at most ten entries and no more than the available columns, newest first.
  Empty history or search collapses the row. Recent buttons use the same copy,
  session/race/failure and history-promotion transaction as category selections.

## Clipboard lifecycle and root cause

Hub retains ClipboardContent, but previously never called its `begin()` reset.
`reconcile()` also scrolled the selected row on every model update, while the
backend sorted pins ahead of newer copies. Those combined behaviours explain the
operator's observation; no native screenshot of the original failure was required
to establish these source paths.

Every fresh entry from another mode or a closed Hub emits `Clipboard.entered`:
clear search and request the newest timestamp (which can follow older pinned rows).
Repeated open while already in Clipboard and temporary
fullscreen suppression do not reset browsing. Query changes request the first match;
the reset waits for matching asynchronous results and stays pending across an empty
model. Manual scrolling cancels a pending empty-result reset.

Ordinary backend updates preserve the visible entry by ID and its pixel offset,
including new entries inserted ahead of it. If that entry disappears, clamp the
previous offset into the remaining list. Keyboard selection alone scrolls its target
into view. Deferred restoration avoids fighting an active scroll gesture.

Operator accepted option B: backend order remains pinned-first, then newest timestamp
within each group. Pins retain protection from eviction and Clear unpinned. Fresh entry
selects and scrolls to the globally newest timestamp; older pins remain above it and
can be reached by scrolling up. Search resets to the first matching row in pinned-first
order. Ordinary updates preserve browsing rather than following the newest copy.

## Validation and visual review

`tests/phase10a/run.py` uses production presenters with synthetic media/clipboard
inputs in disposable HOME/XDG roots. It checks responsive columns, tab/sidebar
alignment, page removal, Bar ownership, pack selection, all ten palettes and three
switch styles, fallback, recent-row visibility/search and asynchronous Clipboard
entry/search/browsing/insertion/re-entry. Set `MAGI_10A_CAPTURES` to export previews.
Existing Settings store/UI/assets/icons, Emoji and Hub suites cover migration,
normal save/error states, navigation, exact UTF-8 copy/history/races and mode lifecycle.

Software offscreen previews are useful for layout and colour, but do not establish
native GPU SVG mask quality or compositor focus behaviour. The operator confirmed
the live review passed. Runtime logs confirmed automatic configuration reloads;
no deliberate restart was performed during review. Protected settings were not
rewritten by implementation, tests or finalization.

## Deferred — not implemented

- Phase 10B: external-display bar show/hide, hotplug bars, left/right insets,
  screen-edge distance, Top/Bottom placement, research vertical Left/Right bars,
  and surfaces on the originating monitor.
- Phase 10C: Lock/Display off/Suspend after, Never, possible AC/Battery policies,
  Hypridle backend retention, and MAGI Display Manager replacing Hyprmon only
  after research/proof.
- Later: fingerprint unlock, btop semantic-theme overhaul, MAGI Greeter and
  Theme Orchestrator v2. Lock weather/media additions remain deferred.

## Results from this implementation pass

- PASS: migration/default/schema tests, five isolated store/I/O fixtures,
  manifest/import/asset validation, icon resolver and control catalogue tests.
- PASS: full Settings presentation, reorder/keyboard/persistence, ten-theme
  appearance tests, typography/toggle tests and 600 reference colour comparisons.
- PASS: Emoji model/schema and four production fixtures (copy, history, settings,
  race and failure handling); Clipboard UI/service/schema and Hub's six fixtures.
- PASS: Launcher content/application-icon presentation, Settings, discovery and
  hidden-application persistence. Its reset fixture now awaits asynchronous save
  completion instead of assuming a fixed delay.
- PASS: new Phase 10A offscreen layout/palette/Emoji/Clipboard lifecycle tests.
- Clipboard backend model: 9/11 pass, including pinned-first ordering. The two image
  decode/cleanup failures reproduce unchanged against accepted HEAD (8/10 there).
  Finalization reproduced both again on the accepted baseline and current tree:
  `test_image_cleanup_and_limits` and `test_image_eviction_and_persisted_cleanup`,
  each raising `ValueError: Image unavailable or exceeds limits`. These are
  pre-existing baseline failures, not introduced by Phase 10A; tests were not weakened.
- GPU preview attempt: OpenGL context creation failed in this sandbox. Software
  previews were generated and inspected; shader-tinted SVGs are not a native-quality
  rendering oracle in those images. No live session was touched.

Preview artifacts: `/tmp/magi-10a-previews/{theme-wide,theme-narrow,bar,media-and-toggles,emoji-recents,clipboard-fresh}.png`.
The wide/narrow Settings views include branding, navigation, tabs and save footer.
The media fixture uses synthetic progress and a teal Hub switch, not live playback.

The initial literal-question-mark fallback was rejected and corrected separately;
its original preview artifacts above are historical. Use the focused fallback
correction previews for icons. The operator confirmed all live checks passed and chose
pinned-first ordering (option B) on 2026-10-20. The subsequent ordering adjustment is
covered by isolated async entry, search, browsing and re-entry tests; no deliberate
live reload was performed. The operator accepted finalization with commit subject
`magi: refine settings hub and icon packs`. Phase 10B has not begun.
