# Visual composition, state correctness and shared morph — sprint ledger

Started 2026-10-02. Source baseline: accepted icon-pack checkpoint, clean MAGI
working tree (unrelated sibling dotfile changes pre-exist). No commit/push.
The original 6000×15000 render was inspected, including a native Control Centre
crop. Reference: 4 colored tiles with prominent rims, icon-on-slider controls,
unboxed actions, rounded profile/media artwork, persistent status header.
Colors remain semantic selected-theme roles; the raster colors are historical.

## Resume and acceptance rules

Continue from the first unfinished phase; preserve completed edits. Each phase
records its files, decisions and validation below. No destructive action tests.
Phase 8 and inline Wi-Fi authentication require operator acceptance; unit tests
cannot establish visual motion, real password authentication or compositor focus.
Multi-output and fractional scaling remain unverified.

| Phase | Status | Files / decisions | Tests / operator checks / deviations |
| --- | --- | --- | --- |
| 1 — state/icon correctness | complete; operator checks passed | Workspace filtering/sorting and semantic icon state | Prior automated/runtime checks plus operator functional confirmation |
| 2 — bar/control scale | complete; bounded shade review pending | Status default now18px; primary shades added below | Prior functional checks passed; new appearance review pending |
| 3 — sliders | complete; operator checks passed | Semantic rounded track/fill/rim | Live slider/appearance checks passed |
| 4 — profile | complete; operator checks passed | Rounded mask, greeting, saved subtitle compatibility | Operator confirmation |
| 5 — media | complete; operator checks passed | Persistent empty state, real metadata/actions | Operator confirmation; no fabricated progress |
| 6 — compact Volume | complete; operator checks passed | Click mute/wheel volume | Operator confirmation |
| 7 — inline Wi-Fi auth | complete; operator checks passed | Inline authentication with existing backend | Requested functional review passed; separate native anchored focus remains unverified |
| 8 — cluster morph | complete; operator checks passed | Persistent Row and interruption-safe lifecycle | Requested open/close/switch/interruption review passed |
| 9 — Appearance controls | complete; bounded shade review pending | Existing controls retained, two palette shade controls added | Previous functional review passed; new controls require operator review |

## Current next step

The 2026-10-03 acceptance/follow-up entry below supersedes earlier pending-review notes.
Next: operator review of primary tile shades; no further refinement authorized.
No production edits preceded creation of this ledger.

## Phase 1 — complete (automated/runtime), operator checks pending

Changed `icons/IconState.js`, `icons/IconRegistry.qml`, `icons/packs/registry.json`,
`plugins/bar/workspaces/{WorkspaceModel.js,Workspaces.qml}`, `tests/visual/state.cjs`.
Normal positive-ID numeric workspaces are sorted using reactive ObjectModel.values;
removed stale `lastIpcObject.windows` filtering. Boundary tests include one/two
workspaces, negative/special/named entries, addition/removal/rename and sorting.
Battery: 90/65/35 boundaries; zero is low; charging wins over level. Volume:
0/muted, 1–33 low, 34–66 medium, 67+ high. Wi-Fi 0–49 low, 50–74 medium, 75+ high;
connected hero and every list row already consume the same semantic helper.
`battery-high.svg` is absent from supplied/bundled artwork; high uses the registered
Legacy 70% glyph. No invented or modified SVG. Other named levels use custom assets.
Tests: state.cjs and icons.cjs pass; qmllint exits 0 (existing QProcess metadata
warning); diff check passes. Restarted named MAGI: PID433086, one 1920×1080 layer
at (0,0), reservation [0,48,0,0], scale2. Clean configuration log; compositor has
workspaces1 and2. Operator still to check live workspace creation/deletion and
visual icon changes; no synthetic battery/network state claimed.

Official API evidence, inspected 2026-10-02, Quickshell0.3.1:
- https://quickshell.org/docs/v0.3.1/types/Quickshell/ObjectModel/ — `.values` is reactive.
- https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/HyprlandWorkspace/ — raw
  `lastIpcObject` does not refresh automatically; native id/name properties are used.

## Phases 2, 3, 9 — implementation decisions

26px icon fits the 28px-high compact pill; intrinsic content centering replaces
an 8px minimum inset that would overflow a 30px icon-only pill. CC primary tiles
retain semantic accent backgrounds/rims in every state. Equal 32px secondary
icons have no individual background. On/off/unavailable/armed colors are explicit.
Slider track=elevated, fill=overlay, rim=lavender are initial Mocha semantic-role
choices (theme live); both fill ends rounded. Appearance settings use bounded
sizes/widths and palette-role selections, retaining internal spacing/baselines.
Existing schema3 files get effective defaults without discarding unknown/user fields.

## Phases 2–6 and 9 — implemented, final validation / operator review pending

- `Theme.qml`, `RenderTokens.qml`, `SettingsSchema.js`, `SettingsStore.qml`,
  `AppearancePage.qml`, `VisualSettingsGroup.qml`: 26px status size, tile rim4px,
  on=text / off=background at28% alpha, slider semantic roles and widths, avatar
  radius/border. Roundness still follows master/per-role overrides. Values are
  validated; no second writer. Theme-selected role names, no sampled colors.
- `ControlTile.qml`, `ActionButton.qml`, `ControlCentre.qml`, `ControlCatalog.qml`:
  persistent tile colors, catalogue toggle distinction, unboxed32px secondary icons.
  Armed power actions alone use danger. Availability stays honest.
- `MorphingPillContent.qml`, `Battery.qml`: actual26px icons within compact28px
  height, centered with no overflowing fixed inset. Battery percentage retained.
- `IconSlider.qml`: both fill endcaps rounded; track/fill/rim separated.
- `RoundedArtwork.qml`, `VisualState.js`, `ProfileHeader.qml`, `ProfilePage.qml`:
  real rounded alpha mask and border, local greeting (05–12 morning,12–18 afternoon,
  18–23 evening,otherwise night). New subtitleMode defaults to greeting; persisted
  custom subtitle remains selectable. No account information inferred.
- `MediaController.qml`, `MediaSection.qml`, `MediaButton.qml`: media no longer
  collapses merely because a player disappears. Artist first, title second;
  truthful empty text, unboxed transports. Artwork border progress reads only
  supported position+length;1s monitoring only while CC selected and playing.
  Explicit section/media disable settings remain respected. Existing322px default
  CC width retained:70px art leaves sufficient text/transport width; avoids changing
  accepted60px tile geometry merely to inflate media.
- `Volume.qml`, `Expandable{Module,Plugin}.qml`, `ModulePill.qml`, `Bar.qml`:
  left-click mute,5% wheel steps via existing Audio; no redundant Volume view.
  Catalogue now advertises Volume slider only; IPC rejects non-expanding modules.
  No audio backend rewrite. Future mixer needs an explicit real detail component.
- `IconRegistry` maps connected Bluetooth to supplied `bluetooth-on.svg` through
  manifest/registry alias; no SVG bytes changed. Removed unused Battery.icon
  threshold/glyph duplicate; battery state service otherwise unchanged.

Focused evidence so far: appearance10-palette tests, schema tests, media-selection
and dynamic CC-layout tests pass. Phases2–6 restart loaded cleanly. Pure state tests
also cover greetings and bounded rounded progress geometry. Runtime image masking,
real media progress and control optical size still need visual review.

## Phase 7 — implemented; real authentication acceptance pending

`Wifi.qml`, `WifiMenuContent.qml`, new `WifiAuthentication.qml`, `ModuleRegistry.qml`:
selected row expands inline; no PasswordWindow instance. Old file remains unused
for review/rollback only. Secrets stay solely in masked TextInput; cleared on
submission/cancel/navigation. Enter submits, Escape cancels authentication before
closing browser. Late backend callbacks observed by session owner rather than a
row delegate; never reopen a view. Pending operation survives navigation; Cancel
is disabled during submission (does not falsely promise NetworkManager cancellation).
Known/open/PSK calls unchanged in Network.qml. Scanning while browser or pending
request exists. Bounded list scrolls selected form into view; view height retargets.
`tests/settings/wifi-inline.qml` passes real-component/stub-backend regression for
masking, submission, secret clearing, inline failure/retry/success, cancellation,
known/open calls, late failure and height retarget. Updated module ownership test.
A list-vs-ObjectModel `.values` ambiguity found by the test was fixed before launch.
Live read-only Wi-Fi opening: clean logs,PID437904,one1920×1080 layer(0,0),48px.
Real PSK, incorrect password, retry, Escape/keyboard and fallback focus unverified.

## Phase 8 — implemented; NOT operator-accepted

`SharedStatusSurface.qml`, `Bar.qml`, lifecycle regression:
- Status Row and its delegates stay owned by the same Loader throughout.
- Compact spacing6px grows to12px; inset grows0→12px and y0→8px.
- Header height28→44px. Compact metrics are computed independently of animated
  spacing; expanded-header target accommodates the real status contents plus Back.
- Header progress is independent of body target width; a different view cannot
  recalculate/jump icon positions. Radius interpolates from compact to surface.
- Widen180 → reveal140/fade90; fade70 → retract120 → narrow160 unchanged.
  Header travels with widening/narrowing; open-view switches keep it expanded.
- Only existing persistent row click targets, one selected interactive body;
  Region/catcher/focus still belong to Bar, no extra native window or handover.
48-step lifecycle passes including interruption/retargeting, exact compact settle
and one header construction. Must still review CC/Wi-Fi/Bluetooth, close, sibling
switching and rapid interruption visually. Do not call this accepted from tests.

## Historical resume point — before 2026-10-03 operator confirmation

Implementation phases1–9 and automated/runtime checkpoint complete. **Next task is
operator visual and real inline-password review**, not another implementation pass
or full-suite run. Native anchored inline keyboard/focus is separately unverified.
No subsequent polishing before that review. No commit/push. Source palette/icon
selection remains user's Mocha/MAGI; live status icon size is now18px, changed via
Settings during this sprint and preserved. New default remains26px.

Final review correction: `Icon.qml` now separates RGB colorization from overall
semantic state alpha (`MultiEffect.opacity`). Thus the new translucent OFF token
multiplies, rather than replacing, artwork's internal alpha. Fixed-color assets
are unchanged. This matters beyond the prior all-opaque tint fixture.


## Final validation reconciliation — 2026-10-02

The full accepted suite was run once after the main implementation. Settings
fixtures (missing/legacy/valid/partial/invalid), appearance10 palettes/live changes,
module ownership, CC dynamic layout, Settings window, icons/managed assets,
media selection/actions, safe backend actions, state helpers, inline Wi-Fi and
48-step shared lifecycle passed. Action-layout alone initially failed because
its copied operator configuration has five secondary actions (VPN removed),
while the test assumes six defaults. Its isolated copy now explicitly resets
CC, and the focused rerun passes. Real settings were not reset.
The additional catalogue/action-state QML fixture passes too. No destructive
session actions or actual radio/connection toggles were automated.

After resume, the concrete fallback clipping risk was addressed in
`ExpandablePlugin.qml` and `menu/AnchoredDetailHost.qml`: open target-size changes
retarget existing geometry animations without restarting lifecycle/fade.
`tests/settings/anchored-layout.qml` uses actual animation/session owners with
only the native PopupWindow stubbed. Inline auth grow/cancel/shrink, close and
hidden-module fallback resize/close all pass. Non-expanding Volume does not
instantiate a fallback adapter. The focused tests and lint pass after these edits.
This establishes geometry, **not native popup keyboard focus**.

Whole-production qmllint exits0. Existing metadata/unqualified warnings remain;
two additional static dynamic-delegate warnings concern `itemAt()` custom members
in WifiMenuContent (runtime verified, no corresponding runtime errors). The
isolated offscreen harness reports its known sandbox IPC-socket warning, and the
Settings-window harness its documented offscreen mask warning; production logs
contain neither. Final diff whitespace check passes. No full-suite rerun on resume.

Live: PID441199, combined host, one MAGI layer1920×1080 at(0,0), scale2,
reservation[0,48,0,0]. Captured CC open322×426 and fully closed175.78125×28,
phase0/catcher=false/keyboard=false. CC/Wi-Fi/Bluetooth screenshots were inspected:
actual persistent status row, rounded avatar border and local greeting, unboxed
actions, permanent media empty state, bounded Wi-Fi list. Bluetooth was off;
connected-state visuals and real playback/progress not exercised. Final read-only
compositor check after resume agrees; clean reload log. Left Control Centre open.

Temporary review captures (not committed assets):
- `/tmp/magi-visual-cc.png`
- `/tmp/magi-visual-wifi.png`
- `/tmp/magi-visual-bluetooth.png`
- `/tmp/magi-visual-closed.png`
Full initial suite output: `/tmp/magi-final-validation.log` (contains the initial
fixture failure; corrected action-layout and catalogue/fallback PASS results are
recorded above). Lint output: `/tmp/magi-qmllint.log`.

### Required operator review / known deviations

1. CC/Wi-Fi/Bluetooth open states and close animation; sibling selection,
   CC→Bluetooth→Back and rapid interruptions. Confirm the cluster itself appears
   to expand, with no duplicated/jumping icons; screenshots plus motion feedback.
2. Inline secured-network focus, masked input, Enter/Connect, Cancel/Escape,
   failure/retry/success, navigation away and normal scan/scroll. No native password
   window should appear. Pending connection cancellation/timeouts remain backend
   follow-up; enterprise networks still follow the pre-existing PSK limitation.
3. Volume left-click mute/wheel, live slider/appearance changes; avatar greeting,
   real artist/title/actions and progress only when available, empty-media state.
4. Workspace creation/removal/active state with one/two/three normal workspaces;
   fullscreen hide/recovery and consumed dismissal must be reconfirmed for this pass.

No battery-high SVG was supplied; its registered Legacy fallback remains intentional.
Current18px icon selection and existing radius overrides differ from reference
26px defaults. Five secondary actions reflect operator configuration. Bluetooth's
fixed off-state height remains a known presentation gap; cross-section status
migration, multiple outputs and fractional scaling are not validated. Native
anchored inline keyboard behavior needs a bounded operator fallback check.

### Exact working-tree scope at review

All implementation/docs/test edits are under MAGI. Existing sibling t15g changes
and the unrelated untracked filename remain untouched. `settings.json` contains
the live Appearance update (18px) and was not manually replaced with test data.

```text
.config/quickshell/magi/components/bar/Bar.qml
.config/quickshell/magi/components/bar/ExpandableModule.qml
.config/quickshell/magi/components/bar/ExpandablePlugin.qml
.config/quickshell/magi/components/bar/ModulePill.qml
.config/quickshell/magi/components/bar/SharedStatusSurface.qml
.config/quickshell/magi/components/bar/menu/AnchoredDetailHost.qml
.config/quickshell/magi/components/controls/Icon.qml
.config/quickshell/magi/components/controls/IconSlider.qml
.config/quickshell/magi/components/controls/MediaButton.qml
.config/quickshell/magi/components/controls/MorphingPillContent.qml
.config/quickshell/magi/components/controls/RoundedArtwork.qml
.config/quickshell/magi/components/controls/VisualState.js
.config/quickshell/magi/components/settings/VisualSettingsGroup.qml
.config/quickshell/magi/components/settings/pages/AppearancePage.qml
.config/quickshell/magi/components/settings/pages/ProfilePage.qml
.config/quickshell/magi/icons/IconRegistry.qml
.config/quickshell/magi/icons/IconState.js
.config/quickshell/magi/icons/packs/magi-default/manifest.json
.config/quickshell/magi/icons/packs/registry.json
.config/quickshell/magi/modules/ControlCatalog.qml
.config/quickshell/magi/modules/ModuleRegistry.qml
.config/quickshell/magi/plugins/bar/battery/Battery.qml
.config/quickshell/magi/plugins/bar/controlcentre/ActionButton.qml
.config/quickshell/magi/plugins/bar/controlcentre/ControlCentre.qml
.config/quickshell/magi/plugins/bar/controlcentre/ControlTile.qml
.config/quickshell/magi/plugins/bar/controlcentre/MediaSection.qml
.config/quickshell/magi/plugins/bar/controlcentre/ProfileHeader.qml
.config/quickshell/magi/plugins/bar/volume/Volume.qml
.config/quickshell/magi/plugins/bar/wifi/Wifi.qml
.config/quickshell/magi/plugins/bar/wifi/WifiAuthentication.qml
.config/quickshell/magi/plugins/bar/wifi/WifiMenuContent.qml
.config/quickshell/magi/plugins/bar/workspaces/WorkspaceModel.js
.config/quickshell/magi/plugins/bar/workspaces/Workspaces.qml
.config/quickshell/magi/services/Battery.qml
.config/quickshell/magi/services/MediaController.qml
.config/quickshell/magi/settings.json
.config/quickshell/magi/settings/SettingsSchema.js
.config/quickshell/magi/settings/SettingsStore.qml
.config/quickshell/magi/theme/RenderTokens.qml
.config/quickshell/magi/theme/Theme.qml
docs/README.md
docs/architecture.md
docs/decisions.md
docs/design/shared-status-surface.md
docs/design/visual-refinement-checkpoint.md
docs/quickshell-reference.md
tests/settings/action-layout.qml
tests/settings/anchored-layout.qml
tests/settings/appearance.qml
tests/settings/control-layout.qml
tests/settings/media.qml
tests/settings/modules.py
tests/settings/modules.qml
tests/settings/store.qml
tests/settings/wifi-inline.qml
tests/shared-status-surface/lifecycle.qml
tests/visual/state.cjs
```

## Operator acceptance and bounded default/shade correction — 2026-10-03

**Operator evidence:** the user reports that the requested functional checks passed.
Record the four review groups above (morph/navigation/interruption; inline Wi-Fi;
Volume/profile/media/appearance; workspaces/fullscreen/dismissal) as passed on that
basis. Earlier pending-review statements are historical. This does not establish
new multi-output/fractional-scale or native anchored-inline-focus validation.

**Bounded implementation:** architecture, geometry/motion, services, artwork and
secondary action presentation are unchanged.

- Fresh/reset `appearance.visual.statusIconSize` is **18 logical pixels**; existing
  16–28px slider remains. The operator's saved18px is preserved, as are their saved
  border5px and Off-state overlay/40% preferences. SVG canvases remain24×24.
- New `tileBackgroundShade = 0.28`, `tileBorderShade = 0.48`, validated −1…+1.
  Settings displays signed percentages: negative lighter, zero untouched accent,
  positive darker. Each is blended directly from the tile's assigned palette accent;
  the border is not blended from the already-shaded background.
- Palette dark anchor = Background for dark themes, Text for light themes;
  light anchor = Text for dark themes, Background for light themes. `Theme.shadeAccent`
  uses the palette's `dark` metadata, no theme-name/RGB special cases. At ±100% the
  selected anchor is reached. No raw-color picker or additional color source.
- Background stays colored regardless of toggle state. Active/non-toggle icons
  retain the configured On/Text foreground. Off-state color/opacity remain intact.
  Borders no longer brighten on hover; the selected shade stays consistent.
  Border width remains configurable with its existing default4px.
- Two controls join Appearance → Status and controls, with signed percentage labels
  and a concise direction legend. Existing state color semantics remain available.
  No Settings redesign. Additive effective schema3 defaults preserve existing files;
  all writes still use SettingsStore.

Changed for this follow-up: `settings/SettingsSchema.js`, `theme/Theme.qml`,
`plugins/bar/controlcentre/{ControlCentre,ControlTile}.qml`,
`components/settings/VisualSettingsGroup.qml`,
`components/settings/pages/AppearancePage.qml`, `tests/settings/{appearance.qml,schema.cjs}`,
this ledger and concise status/decision documentation. The existing broader sprint
working tree is preserved; no changes to `ActionButton.qml` in this follow-up.

Focused validation: schema defaults, existing custom-size preservation, signed-shade
bounds/invalid fallback; production QML appearance fixture across all10 palettes,
zero/negative/positive blends for Teal/Blue/Green/Lavender, Text foreground, live
shade/size/border updates, disk save/reload of shades/custom size all PASS.
Fixture uses an isolated temporary configuration; no real settings reset.
Known offscreen sandbox IPC warning only. Scoped `/usr/lib/qt6/bin/qmllint` exits0
with no output. Full unrelated suites were not rerun.

Runtime/capture evidence and pending operator review are recorded below after
palette inspection. No commit or push.

### Bounded follow-up runtime result / stop point

Production auto-reloaded the bounded changes successfully; existing healthy MAGI
PID441199 retained. Inspected actual Control Centre captures in Mocha, Macchiato
and Latte through the existing settings IPC (sole SettingsStore writer):

- `/tmp/magi-shade-mocha.png`
- `/tmp/magi-shade-macchiato.png`
- `/tmp/magi-shade-latte.png`

Mocha/Macchiato: colored backgrounds retained, light Text icons separated more
clearly from Teal/Blue, edges distinctly darker derivatives. Secondary actions
remain directly on the surface. Latte: accents and both anchors update from its
own palette; Text is Latte's existing dark foreground, not force-replaced with
white. Its dark Text against saturated tiles has less separation than Mocha;
negative/lightening shade values are available for tuning. This is an observed
contrast trade-off, not a claim of universal contrast compliance or final acceptance.
No automatic theme-specific overrides were introduced.

Restored and left **Catppuccin Mocha, Control Centre open**, phase3, interactive,
322×426 view. One MAGI1920×1080 layer at output-local(0,0), scale2, compositor
reservation `[0,48,0,0]`; clean production log (configuration/reload INFO only).
Scoped lint and final `git diff --check` pass. Existing broader working-tree edits
and unrelated sibling changes remain untouched. No commit/push.

**Pending operator visual review only for this correction:**
1. Mocha primary tile readability, recognizable accent backgrounds, same-accent
   darker borders; active icons stay light. Secondary action appearance unchanged.
2. Appearance → Status and controls: move background/border shade through zero,
   lighter and darker; verify live preview and border-width adjustment. Retain or
   return to the desired saved values. Status icon size remains adjustable at18px.
3. Optional light-theme contrast tuning; finish on Mocha.

Resume from that feedback, not from another full-suite run or architecture pass.

## Close-out: semantic primary accents and compact Bluetooth — 2026-10-03

The operator accepted the preceding functional and bounded shade checks. This
close-out does not reopen the visual architecture. It makes two product changes:

- Palette registry `accentRoles` is the source for the compact selector embedded in
  each Settings → Control Centre primary row. Current common roles are Red, Peach,
  Yellow, Green, Teal, Blue and Lavender. Settings schema v4 persists the semantic
  role on the existing entry. The pure v3→v4 migration assigns Wi-Fi Teal,
  Bluetooth Blue, Low Power Green and Airplane Lavender while preserving existing
  ordering, enablement and unrelated preferences. New/replaced controls use their
  catalogue default. Unsupported roles render through the module default and then
  theme Accent; they cannot produce an invalid color.
- `ControlCentre.qml` resolves that role from the live palette, then applies the
  accepted global background and border shades independently to the same base.
  Theme switching therefore changes RGB while retaining the semantic selection.
  Active/off ink and all secondary-action styling are unchanged.
- Bluetooth's compact module is always30px and icon-only when configured. Off,
  enabled and connected use their existing semantic icons. Connected name/battery
  remain in the detail header/card; adapter, scanning and connection logic are
  untouched.

Focused automated evidence: schema v0→v4, v3 default/custom accent migration,
validation/fallback, persistence/reset; all10 palettes and both shade layers;
dynamic Control Centre layout; real Bluetooth module with a stub connected AirPods
and retained detail name; module ownership/inline Wi-Fi; 48-step shared lifecycle.
All pass. Whole-production qmllint exits0 with the previously documented warnings;
`git diff --check` passes. No destructive/radio actions were automated.

Production demonstration uses the authoritative SettingsStore: Wi-Fi changed from
Teal to Red, captured as distinct palette-native Reds in Mocha and Latte, then
returned to Mocha. The selected semantic Red persisted in schema v4. Captures:
`/tmp/magi-closeout-red-mocha.png`, `/tmp/magi-closeout-red-latte.png`,
`/tmp/magi-closeout-final-mocha.png`. The current Bluetooth detail capture
`/tmp/magi-closeout-bluetooth.png` shows real known devices but none connected, so
connected-device runtime confirmation remains an operator check rather than an
invented result.

Final operator review **passed**: per-primary-control selection correctly updates
the live palette-derived background and same-accent border shade, and Bluetooth's
connected-device name is absent from the compact bar. This supersedes the pending
review paragraph in the initial stop point. Multi-output/fractional scaling and
native anchored inline focus remain separately unverified.

Final clean production restart: PID680993, one1920×1080 MAGI layer at output-local
`(0,0)`, scale2, reservation `[0,48,0,0]`. Saved schema v4 has no diagnostics,
Catppuccin Mocha is restored, Wi-Fi retains semantic Red, and the startup/runtime
log contains Configuration Loaded only. Control Centre is open for review at
322×426, phase3, with its existing catcher/focus ownership. No commit or push.

### Sprint closure and explicitly deferred work

Status: **accepted and ready to checkpoint**. No further production changes were
made after operator acceptance. Final documentation consistency and `git diff
--check` pass; the healthy live compositor baseline above remains authoritative.

Two product decisions belong to the next milestone and are not implemented here:

1. Show the compact Bluetooth bar indicator only while at least one Bluetooth
   device is connected. Module/service availability remains separate: Bluetooth's
   service, Control Centre tile and detail/navigation entry must remain available
   with no compact delegate.
2. Build one reusable inherited icon-state style for primary and secondary controls:
   semantic ON/OFF palette roles, signed palette-derived shade adjustment, and
   state strength/opacity. Group-level defaults should flow to controls, with narrow
   overrides rather than duplicated settings for every button.

Notifications, Clipboard and both deferred changes were not started. No commit or
push was performed.
