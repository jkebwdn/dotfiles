# Literal render specification — Control Centre reference

Prepared **2026-09-26 before QML changes**. The accepted shared status surface,
semantic navigation, animation sequence/timings, native geometry, input/focus,
fullscreen policy and 48px reservation are frozen for this milestone.

## Product color-policy clarification — 2026-09-26

The later Settings brief establishes **Catppuccin Mocha** as MAGI's default and
reference palette. This document's sampled colors record the render and the
completed reference pass; they are not canonical product colors. Geometry and
composition measurements remain useful. See [the Settings architecture](settings-architecture.md)
for semantic themes/roundness. S2 (2026-09-27) replaced sampled color bypasses
with the selected Theme while retaining the measured geometry. The historical
samples and screenshot comparisons below describe the earlier render pass. The adapted extra battery summary
is also marked for removal when CC composition becomes configurable.

## Evidence and measurement convention

Source: `/home/jkebwdn/Downloads/Magi Quickshell Render.png`, 6000×15000 PNG.
Measurements use original image pixels (**R**), not the downscaled conversation
preview. The main Control Centre is approximately x2074–2505, y575–1179.
Detail diagrams are below it; Wi-Fi begins near x2075,y1954. Inspected native
crops, not generated alternatives. Flat colors were counted from an RGB crop
with ImageMagick; antialiased edges introduce small coordinate uncertainty.

Comparison: current QML and operator screenshot
`/tmp/codex-clipboard-aBEE4S.png` (Control Centre), with
`/tmp/codex-clipboard-dkKpLU.png` (Wi-Fi). These are operator captures, not
pixel-perfect output calibration references. Runtime is 1920×1080 logical,
3840×2160 physical, scale 2. QML dimensions below are **L** logical pixels;
physical output pixels are 2×L. Do not halve the render simply because the
monitor uses scale 2: the design board has no output-scale metadata.

Labels: **O** observable/approximately measurable; **S** sampled flat RGB;
**E** visual estimate; **A** explicit runtime adaptation, not a render fact.
Adopt a reference width of **320L** for this pass: 320/432 ≈ 0.741 R→L.
Retain the real compact status group and its minimum-width constraint; a wide
connected Bluetooth name can make the surface wider than 320L.

## Geometry specification

| Feature | Source evidence | Runtime target / treatment |
| --- | --- | --- |
| Full CC silhouette | O ≈432R wide ×605R tall, H/W≈1.40 | A full composition ≈320×448L, only once all depicted modules exist |
| Outer radius | E ≈15R | A 11L for CC |
| Left/right interior inset | O ≈19–22R | A 14L |
| Header/status band | O ≈69R before profile area; status icons ≈28R with ≈9R gaps | A retain accepted 36L expanded header, 28L hit areas; 48L native reservation unchanged |
| Header right inset | O ≈15R | A retain 12L; no header architecture/scale changes in this pass |
| Profile area | O ≈394×97R, avatar ≈76R | A ≈292×72L; absent backend/presentation, omitted rather than blank space |
| Major vertical gaps | O ≈32R profile→tiles and tiles→sliders; ≈30R around action row | A 24L primary group gap, 20L before power summary |
| Four-tile row | O four ≈80×80R squares; ≈24–28R gaps over ≈397R | A 60×60L tiles; distribute three gaps over available 292L (≈17.3L each) |
| Tile radii/outlines | E radius≈13R, O colored rim≈4R | A radius10L, 3L lighter rim; this outline is specifically in the render |
| Tile glyphs | E ≈40–49R centered, no visible titles or subtitles | A 32L centered glyphs; text stays accessible metadata, not visible labels |
| Slider pair | O ≈184×64R each, ≈28R central gap | A two 136×48L tracks at 320L outer width, gap20L |
| Slider shape | E radius≈13R; O rim≈3–4R, muted dark fill, not saturated full-width pill | A radius10L, 2L rim; dark filled portion over muted track |
| Slider icon | O ≈36–42R, left≈13R, vertically centered over track | A 28L glyph at x10L; no heading, percentage, knob or separate icon card |
| Quick-action row | O four unboxed icons ≈45–52R tall, distributed under sliders | A ≈36L height; no new quick-action functionality in this pass |
| Battery/power summary | O no current-style labelled full-width battery card in source; leaf/battery tile and circular lightning action present | A preserve current read-only state/time in a quiet 36L unboxed row; explicitly an accommodation, not a literal source module |
| Media area | O ≈394×97R with ≈76R album image and transport glyphs | A ≈292×72L; omitted because media is outside current functionality |
| Bottom inset | O ≈20R | A 14L |
| List group radii | E ≈10–12R | Future A 8–9L; no list restyling now |
| Wi-Fi/BT row pitch | O ≈43R, single-line names within one grouped surface | Future A ≈32L; current two-line rows remain 44L this pass |
| Detail primary state | O ≈394×97R with ≈64–72R hero icon; BT real battery ring≈70R | Future A ≈292×72L, hero48L; preserve real-data-only battery |

### Content-supported Control Centre height

Do not set the live CC to the full 448L target while omitting profile/media/actions.
The supported reference subset is: 36L accepted shared header + 6L body top
inset + 60L tiles + 24L gap + 48L sliders + 20L gap + 36L power summary + 14L
bottom inset = **244L total** (body target **208L**).
The profile and media gaps must not be left as empty placeholders.

### View-specific geometry, without changing lifecycle

The existing `expandedWidth` and `menuHeight` already belong to each module and
are consumed by the shared surface. Keep that contract; expose optional
presentation insets/radius/color on the same module rather than add a second
host or another navigation state. CC gets measured tokens; other modules retain
their current styling/dimensions in this pass. Load each body using its own
insets/target height while the shared animated silhouette moves toward the
selected module's target. Keep the compact-cluster width floor (content may
need more width than the nominal design).

| View | Source target evidence | This pass / later target |
| --- | --- | --- |
| Control Centre | O full432×605R | A supported subset320×244L; nominal body208L |
| Wi-Fi | O same≈432R width; short≈352R tall, long≈605R depending row count | Current328L width +36L header +390L body; future ≈320×261–448L bounded/content-sensitive |
| Bluetooth | O same≈432R width; short≈352R tall, additional modes≈436R, long list taller | Current326L width +36L header +350L body; future ≈320×261L short, bounded growth for real content; do not fabricate listening modes |
| Volume | No dedicated volume-detail drawing discernible in supplied sheet | Current280L width +36L header +100L body; no claimed source dimensions |

A view switch must animate directly to its own width/height, including shrinking
from Wi-Fi to CC or Volume. Do not retain the maximum visited height. The
existing animation already does this; regression coverage will verify it with
actual target sizes. No transition timing/state rewrite is authorized here.

## Typography and icon assets

Source text looks proportional and relatively condensed (E); exact family and
font weights cannot be recovered from raster output. List names occupy roughly
24–27R height, supporting copy 16–18R, media text20R. Approximate future mapping:
primary16–18L, secondary12–13L, quiet11L, normal/medium rather than monospaced bold
throughout. CC tiles/sliders have **no text labels** in the source. Power summary
uses available Noto Sans at12L normal for this adapted row. Existing compact
header font is retained; other views are not restyled.

The render uses custom illustrated glyphs (dish, leaf/battery, UFO, streaked
Bluetooth, musical speaker, bulb). No clean icon asset set or font identification
has been supplied. Keep functional Nerd Font glyphs at matched scale/placement;
this is an explicit asset-fidelity gap. Do not invent unrelated artwork or crop
annotation-covered icons into production assets.

## Sampled color roles

These are **S** flat RGB values from the main CC region, not inferred palette
names. White arrows/annotations were excluded from role assignment.

| Role | Render value | Current mismatch / intended use |
| --- | --- | --- |
| Outer surface | #423d55 | Current #313244; CC-only outer override |
| Grouped surface | #514b69 | Current nested near-black #1e1e2e cards; use for appropriate reference groups |
| Slider fill | #413d50 | Current bright lavender/yellow; use muted dark fill |
| Slider track | #4d485e | Use under dark fill |
| Slider rim | #655e82 | Restore the reference's selective outline |
| Tile1 teal | #4f9192, rim#69a1a2 | Wi-Fi; currently lavender |
| Tile2 rose | #9b4e63, rim#aa687a | Read-only power/battery leaf interpretation; currently no equivalent color |
| Tile3 warm brown | #9b7668, rim#aa8a7e | Retain existing Sound function here; UFO's intended action is not established |
| Tile4 blue | #6c92c5, rim#81a2cd | Bluetooth; currently green |
| Main icon/text | White/light grey, many custom icon shades | Adapt #f7f5fb icons, #c8c3d5 secondary; avoid dark icons on active tiles |

Inactive controls lose the colored fill and use the grouped purple surface;
disabled hardware is dimmed. Those inactive/hover details are **A**, because the
static render does not fully establish every interactive state. Connected Wi-Fi
and Bluetooth use a prominent grouped status region; the available list is a
single quieter group, not separate outlined cards. Future list treatment only.

## Exact current mismatches before implementation

Source paths relative to `.config/quickshell/magi/`:

1. `plugins/bar/controlcentre/ControlCentre.qml`: width360 versus320L target;
   supported body192 versus measured subset208L. Full render has additional
   profile/media/action regions absent from current functionality; do not fake them.
2. Same file / `ControlTile.qml`: tiles78L tall with tiny 9/7px labels and21px
   icons. Target60L, no visible labels,32px icons. Current gap8L versus≈17L.
3. Current order Wi-Fi/Bluetooth/Sound/Power diverges from dish/leaf/UFO/BT.
   Map existing functions to Wi-Fi/Power/Sound/Bluetooth; preserve all handlers.
4. Current colors lavender/green/yellow/grey differ from measured muted
   teal/rose/brown/blue, and active icons are dark instead of light.
5. `IconSlider.qml`:32L height, semicircular ends, no rim and vivid fills;
   target48L,10L radius,2L rim, muted dark fill,28L icons at10L inset.
6. CC spacing uniformly10L; reference separates groups by24/20L. Current
   power summary is a42L near-black rounded card with9/8px bold/mono copy;
   adapt to36L unboxed status row and12L proportional normal text.
7. `SharedStatusSurface.qml`: global12L body side/bottom insets and global
   palette/radius prevent CC-only faithful tokens. Add per-view presentation
   values with existing defaults so other views keep their appearance.
8. Current status band36L differs from scaled reference≈51L. Keep its accepted
   geometry this pass; changing it is not necessary to correct body composition.
9. Wi-Fi/BT:44L two-line rows, per-row treatment, type and source-icon differences
   remain recorded gaps. Volume detail source absent; password window not compared
   or changed by this scope.

## Acceptance gate

Run static checks and the existing lifecycle regression, extended only to cover
CC→tall detail→short view geometry. Launch MAGI; confirm one combined layer and
48L reservation, inspect log. Request CC screenshot plus CC→BT/Wi-Fi→CC visual
comparison, including a partly filled volume/brightness slider if convenient.
Do not mark literal reproduction complete while custom assets or absent source
modules remain unresolved. Stop for direct operator comparison before extending
these tokens to the other views.


## Implemented checkpoint / measured startup

Control Centre now uses `theme/RenderTokens.qml` for the scoped reference values.
`ControlTile.qml` renders centered icons without visible text, in the reference
Wi-Fi/Power/Sound/Bluetooth order. `IconSlider.qml` supplies the measured muted
track/fill/rim treatment; it is used only by CC, leaving dedicated Volume's
ValueSlider unchanged. The power summary is unboxed. Optional `viewPadding`,
`viewTopPadding`, `viewBottomPadding`, `viewRadius` and `viewSurfaceColor` retain
old defaults for other modules. Existing module widths/heights still drive the
same animation. No phase, timing, navigation or service change was made.

Validation on 2026-09-26: changed QML passes qmllint with no emitted warnings;
`git diff --check` passes; the expanded lifecycle regression passes **44 steps**,
including CC total height244L after Wi-Fi and Volume136L after Bluetooth.
This is windowless geometry/lifecycle evidence, not operator visual acceptance.

Launched instance `xyw3334zlt`, PID 182697. Fresh log is clean; Hyprland reports
one MAGI 1920×1080 layer at (0,0) and reservation [0,48,0,0], scale 2. Operator
screenshots/direct render comparison were pending at launch; see the follow-up below. Custom illustrated glyphs,
profile/media/quick actions, full render height and exact source typography
remain explicit deviations; no unsupported capability was simulated.


## Operator screenshot comparison — 2026-09-26

Received `/tmp/codex-clipboard-NnLGfT.png` with partly filled sliders and the
operator confirmation that returning from Wi-Fi and Bluetooth restores compact
height. Record **detail-return geometry PASS (operator-observed)**. This is not
an additional full service/focus/fullscreen test or blanket visual approval.

Compared directly with the original Control Centre crop: the supported subset
now visibly has four square icon-only tiles with muted teal/rose/brown/blue fills
and lighter rims, paired outlined tracks with dark partial fill and icons on
the controls, purple outer surface, and an unboxed power summary. No leftover
blank area from the taller detail views is visible in the supplied CC frame.
This screenshot supports the intended reference treatment; exact logical pixel
dimensions come from source/test evidence, not measurement of a resized capture.

Remaining literal-render differences are visible and explicit: generic font
glyphs instead of illustrated source icons; no profile/media/quick-action rows;
therefore a much shorter total silhouette; a text power summary not present in
that form in the render; retained 36L status band rather than the estimated
51L scaled source band. No further QML refinement or feature work was performed
in response to this confirmation. Architecture remains frozen.
