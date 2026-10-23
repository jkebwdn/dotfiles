# Phase 12F — Settings product design

Status: integrated and natively accepted on 2026-10-23. The audit and isolated checkpoints below record the earlier design passes in `magi-phase12f-design`.
Baseline: `bea9cf99b7a6b9aae358c8b78bb2ff6945722e3d` (origin/main 0/0).
Roadmap amendment: this phase refines Settings; application opacity/blur is Phase 12G.
Native acceptance and final sidebar correction are explicitly confirmed; precise staging, commit and push are authorized.

## Formal first-pass audit — before implementation

Source audit covers all 14 active pages and shared Settings primitives. A complete
1080×780 production-component software gallery was rendered before edits (temporary
source captures in /tmp/magi12f-before). Findings below include the first-frame visual
review, not just a checklist of requested changes. Default window remains 1000×720
inside Hub; no enlargement is initially proposed. Schema remains 18.

### High-confidence cross-page findings (implement now)

| Issue | Why weak | Improvement / benefit | Risk |
|---|---|---|---|
| Page title x differs between centered form bodies and editor margins | Navigation changes make content jump | One page inset; bounded forms left anchored; same editor inset | Presentation only |
| Dropdown values centered, inputs left aligned, steppers centered | Fields lack a shared reading edge | Left-align selectors/input text with shared padding; keep numeric stepper centered | No value change |
| GridLayout infers each row's label/control ratio independently | Adjacent controls start at unrelated x positions | Shared row control column, right anchor and compact width; narrow fallback | Recheck bounds on every page |
| Long explanatory text occupies primary space | Looks like developer documentation | Short microcopy; contextual help and tooltips; retain consequential privacy/security warnings | No safety-relevant disclosure removed |
| Ordinary buttons blend into host surface, reset treatment varies | Interaction/hierarchy unclear | Secondary elevated fill, primary accent, quiet utility, destructive semantic role; consistent padding/states | No action semantics changed |
| Editor titles/subtitles and inspector titles duplicate hierarchy | More labels than content | One page title; selection name and concise shared/individual group hierarchy | Scope remains explicit |
| Persistent grips obscure tile icons; keyboard controls are always visible | Fallback mechanics dominate the canvas | Whole-item drag targets, focus/hover feedback, keyboard hint on focus; contextual menu | Pointer/keyboard regression required |
| CC structure vs control tools mutually exclusive | User must choose mechanism before arranging | Section headers drag structures; child tiles drag controls concurrently; one palette | Highest implementation risk; race/gesture tests required |
| Empty Behaviour pages and Expand preview are navigation overhead | Extra clicks without distinct task | CC/Hub two modes; Media behaviour stays contextual; Bar retains meaningful placement mode | All existing fields must remain reachable |
| Inspector numeric values use three visual rows per option | Hard to scan related settings | Label/value header + tight slider, aligned value edge; semantic colour rows | Must retain useful hit areas |
| Sidebar background competes with content | Navigation is the heaviest surface | Slightly lower elevation and tighter rhythm; keep 22 px icons | No radical grouping change |
| Action/focus styling inconsistently inherited | Keyboard interaction can be hard to follow | Shared focus treatment for inputs/buttons; retain semantic radii | Test both light and dark |

### Page archetypes and BEFORE → AFTER plan

| Page / archetype | Primary task; secondary tasks | Before → after (high confidence) |
|---|---|---|
| Appearance / structured | Choose theme/icons; application following, shared tokens | Theme/icons compete with infrastructure prose → hero choice block, master roundness visible, collapsed advanced shell styling; healthy application status quiet |
| Bar / horizontal visual editor | Arrange modules; pill/host style, placement | Grips, move buttons, repeated instructions and oversized empty canvas → whole-module drag, context/keyboard actions, smaller layout canvas and quiet reset; retain meaningful Behaviour geometry |
| Control Centre / visual editor | Compose sections/controls; style visible object | Arrange-components tool, Expand, move buttons and verbose scope prose → unified structure/tile drag, compact categorized palette, Layout/Appearance only, contextual media behaviour |
| Hub / visual editor | Place/style host and selector; independent toggle style | Three modes including prose-only Behaviour; many selector buttons → Layout/Appearance, compact preview-mode toolbar, direct selection with keyboard selectors; lifecycle help contextual |
| Profile / structured | Identity/avatar; optional detail and weather | Full-width fields and disabled weather form → Identity/Details/Weather, aligned fields, conditional optional line/weather controls, deliberate Choose/Clear/Save hierarchy |
| Date & time / structured | Time/date formats; calendar details | Long instructions and ambiguous format grouping → concise shortcut hint, aligned rows; keep all format/density options |
| Notifications / preview + controls | Notification behaviour; card styling | Two full-width cards precede behaviour → compact examples with adjacent appearance, concise shared-scope caption, behaviour in first viewport |
| Clipboard / preview + controls | Collection/history; card appearance | Card and multiple shared-token links dominate → compact appearance disclosure and collection first; keep persistence warning/actions explicit |
| Launcher / structured | Enable/layout; sizing, artwork, hidden apps | Dimensions/artwork dominate long page → common presentation first, dimensions/artwork disclosed, hidden-app restore retained |
| Emoji / structured | Enable/search presentation; recents | Explanatory paragraph and large row gaps → concise hint, aligned steppers/toggles, quiet reset; no new styling |
| Wallpaper / domain canvas | Choose wallpaper; sources | Purpose-built workflow valid; inherited control contrast weak → shared control polish only, sources remain disclosed; no backend changes |
| Power & Idle / structured | Set timers; apply/cancel | Good simple task but prose/Apply hierarchy weak → short useful warning, primary Apply, quiet Cancel; preserve draft validation |
| Displays / domain canvas | Preview topology; inspect settings | Technical state text is partly essential → shared alignment/control polish only; retain preview-only and recovery notices |
| Security / structured | Inspect fingerprint groundwork; synthetic demo | Synthetic enrollment demonstration dominates first frame → collapse demo, keep password-only/deferred warning explicit; no auth changes |

### Additional design recommendations — operator review first

| Issue / weakness | Proposal | Expected benefit | Risk / reason to defer |
|---|---|---|---|
| Theme selection is a name list, weak visual recognition | Small curated theme thumbnail chooser | Faster palette recognition; stronger first frame | Larger product choice and more artwork; do not impose |
| Settings sidebar is long and ungrouped | Optional subtle grouping of shell/features/system | Faster scanning | Operator muscle memory and order; retain current order now |
| Very compact CC has necessarily small production canvas | Optional focus-on-selection zoom, not an always-visible Expand button | Easier precise editing at small size | Zoom/drop coordinates and interaction model need separate review |
| Profile preview could show a live identity card | Larger identity composition using production header | Clearer effect of text/avatar choices | Can duplicate CC ownership; keep minimal avatar grouping now |
| Advanced shared fields accessed from features can lose context | Anchored cross-page navigation / return breadcrumb | Better round-trip editing | Routing change beyond simple visual pass; preserve existing links |

## Design-system plan

Page inset 24 px; spacing scale 4/8/12/20/24; body 14, helper 12, section 16,
page title 26. Controls retain ≥32 px height, 12 px horizontal padding; stepper
width 104, ordinary selector width 208, control column capped near 240. Visual
editors use full width; forms stay bounded and share the same left anchor.
Buttons share primary/secondary/quiet/destructive presentation; keyboard focus
remains visible. Radii/colours remain semantic. Layout-only state is not persisted.

Implementation will preserve every accepted setting and reset route. No schema,
policy, security, display apply, clipboard or production shell behavior changes.
Second-pass screenshots, capability checks, final inventory and recommendations
will be recorded below after implementation.


## Revised brief: product philosophy and visual-first audit

**Visual choices should be chosen visually whenever practical.** Commercial-product
restraint means clear hierarchy and direct manipulation, not imitation of macOS.
Linux-rice freedom means keeping semantic palettes, exact values and composable layouts.
There are no new Settings preferences or schema changes. Application visuals are 12G.

The interrupted `magi-phase12f` worktree was inspected: 38 modified tracked paths,
Settings-only presentation and test changes, plus its audit and initial test harness.
It contains no application opacity/blur implementation. It remains untouched. The
reviewed spacing, disclosure, direct-drag and mode simplifications may be carried
into this fresh baseline worktree; unfinished test scaffolding will be corrected.
The earlier theme-gallery recommendation is now explicitly authorized by this brief.

### Revised high-confidence work

| Finding | Proposed implementation | Benefit / risk |
|---|---|---|
| Theme and icon pack choice are name lists | Horizontal visual galleries backed by the real registries | Compare actual palettes/icons; keep all IDs, fallback and install capabilities |
| Master roundness is abstract | Three shape samples plus expandable exact slider | Immediate shape recognition; custom numeric values remain intact |
| Switch style is a dropdown | Production switch samples for Pill/Filled/Minimal | Preview shared presentation without activating anything |
| Semantic role controls already show swatches | Preserve swatch + name and refine alignment | Semantic choice stays accessible; no arbitrary colours |
| Default Flickable wheel movement relies on platform kinetics | Shared immediate wheel adapter, fractional deltas, bounded movement | No input threshold or queued animation; native touchpad still needs review |
| Nested previews and diagnostics need defined wheel ownership | Consume only if a region moves; otherwise pass to scrolling ancestor | Avoid traps; verify actual Qt event propagation |
| Horizontal galleries can steal vertical page input | Horizontal/Shift-wheel only; ordinary vertical wheel belongs to page | Predictable ownership; show subtle horizontal scrollbar |
| Precision fields should not accidentally change while scrolling | Explicit wheel-disabled selectors/sliders/steppers | Scroll is navigation, arrow keys/clicks still edit |
| Gallery cards need focus, names and visibility | Shared visual-choice card, keyboard arrows + Enter/Space; reveal focused/selected card | Accessible visual selection; no colour-only identity |

### Page-by-page visual and scroll audit supplement

| Page | Visual-picker opportunity | Scroll/container finding and proposed result |
|---|---|---|
| Appearance | Theme, Icon Pack, Master roundness | Vertical page + horizontal galleries + adapter diagnostics; galleries must pass vertical input; diagnostics consume until bound |
| Bar | Existing canvas is the visual choice | One page Flickable; canvas drag must not consume wheel; quiet Available palette |
| Control Centre | Existing production composition and contextual palette swatches | Fixed fit-to-height preview, separate inspector; no wheel capture in fitted preview; inspector immediate and bounded |
| Hub | Production Switch style samples | Fixed preview and inspector; remove prose-only Behaviour; mode dropdown remains synthetic selection |
| Profile | Avatar already visual; no duplicate CC profile editor | One bounded form; conditional weather/message should not leave stale scroll offset |
| Date & time | Text format names are meaningful; retain | Short conventional page; scroll should not change selector values |
| Notifications | Existing Toast/History examples | Keep first-frame behaviour reachable; compact shared card controls; limits disclosed |
| Clipboard | Compact card appearance disclosure | Behaviour first; no unnecessary nested scroller |
| Launcher | Existing layout choices; gallery not justified for two functional modes | Size/art controls disclosed; preserve hidden-app restore list |
| Emoji | Grid columns are precision, not a new gallery | One short form; no invented styling |
| Wallpaper | Existing image browser | Domain workflow retained; source lists and page wheel reviewed, no backend changes |
| Displays | Existing topology canvas | Preview-only architecture retained; no apply/hardware work; fields shouldn't eat wheel |
| Power & Idle | Timeouts are functional values | Short form, direct wheel and button hierarchy; draft/apply policy unchanged |
| Security | No visual picker appropriate | Collapse synthetic demo, preserve password-only/deferred warning; no PAM/hardware changes |

### Scroll diagnosis before implementation

Verified source: SettingsPage uses a plain Flickable with StopAtBounds and no
central wheel handler. CC has a fitted preview Flickable; navigation and adapter
diagnostics use ScrollView. No Settings scroll handler performs synchronous IO.
There is no evidence yet of a render bottleneck: software snapshots do not measure
native frame pacing. Suspected causes are platform wheel kinetics and nested input
ownership; these are hypotheses, not a measured diagnosis of the operator's device.
We will avoid speed multiplication or changing touch-flick physics blindly. Pixel
input should be used directly; angle input should have one consistent modest scale.
Native Wayland touchpad momentum/frame pacing remains an acceptance gate.

Qt API references inspected 2026-10-23: WheelHandler supports Mouse/TouchPad devices,
blocking and wheel callbacks; WheelEvent exposes pixelDelta and angleDelta;
Flickable exposes bounds/kinetics separately. See [WheelHandler](https://doc.qt.io/qt-6/qml-qtquick-wheelhandler.html),
[WheelEvent](https://doc.qt.io/qt-6/qml-qtquick-wheelevent.html),
[Flickable](https://doc.qt.io/qt-6/qml-qtquick-flickable.html).
Implementation will be verified against the locally installed Qt version and
isolated event tests before claiming input propagation works.

## Implemented visual system

- Four archetypes retained: full-width editor, preview-with-controls, bounded structured
  page, domain canvas. Default window size is unchanged; content uses one 24 px left
  anchor. Forms cap at 760 px rather than stretching into every available pixel.
- Spacing is 4/8/12/20/24 px; controls are 34 px high. Shared metrics define 12 px
  input padding, 104 px steppers, 208 px ordinary selectors and a 240 px row column.
  Narrow rows stack at 420 px and align their controls with their labels. Wider rows
  share a trailing control anchor. Multi-cell slider rows explicitly opt out.
- Titles use 26 px, sections 16 px, body 14 px, secondary text 12 px. Dropdowns and
  inputs read left-to-right; numeric steppers remain centered. Inspector values sit
  beside their label, above the slider, instead of becoming a third vertical block.
- Primary actions use accent fill; ordinary secondary actions use elevated surfaces;
  resets/Clear/Cancel are deliberately quiet; erase-history uses destructive ink.
  Common padding, focus outlines, disabled opacity and hover/pressed states replace
  inconsistent inherited treatment. Choose avatar, Install icon pack and Save
  location now have intentional button surfaces.
- Semantic palette/radius authorities remain intact. The new card examples use the
  existing values; there are no new persisted visual settings. Schema is still 18.

## Visual picker architecture

`SettingsChoiceCard` supplies the selected/focus/hover/pressed language and text
accessibility. `SettingsGallery` supplies horizontal layout, reveal-current and
keyboard focus navigation. Theme and Icon Pack galleries use the real registries;
there is no duplicate theme list. Arrow keys move focus; Enter/Space select. Focused
and selected cards are brought into view. Theme samples use each definition's real
background, surface, text and accent roles, including light palettes.

Icon pack samples use the production `Icon` with a narrow `previewPack` adapter;
`IconRegistry.resolvePack` delegates to the existing resolver. It cannot change the
selected pack or application icon theme. Asset recovery/default fallback is shared.
The Install manifest dialog remains available.

Master roundness offers Sharp=0, Balanced=1 and Rounded=2 using the existing master
multiplier. A custom value selects no misleading preset; Fine tune exposes the
unchanged 0–2 / .05 precision slider. Component overrides are not reset by presets.
Switch samples are actual `CompactToggle` presenters with a preview style binding;
production callers still bind style to Settings. The enclosing card owns interaction.
Hub/Settings, Wi-Fi and Bluetooth retain the same shared style; their colours do not
become one setting. Semantic-role fields keep a swatch and readable role name.

## Direct manipulation and contextual editing

CC now has one Layout experience. Section headings and the Profile/Media blocks
move structure; child controls move between Primary, Secondary and Available.
Both existing drag boards operate together, with typed target validation and one
canonical composition. Structural Available space appears when needed, including
while dragging. The palette is narrower and uses quiet category labels.

Bar and CC items themselves are the drag targets. No permanent grip glyph remains.
Alt+arrows/Home/End still reorder; Shift+F10/right-click exposes move/remove actions.
Selection/focus does not persist a value. Pointer motion remains temporary, a drop
publishes once, Escape cancels, and canonical changes invalidate stale drags.
A passive hint overlay replaces Popup tooltips: review/testing found that a Popup
could cover an Available item and intercept the next drag after a keyboard move.

CC and Hub use Layout/Appearance. CC Media behaviour remains in Media's inspector;
Hub's removed Behaviour mode contained lifecycle prose, not an independent setting.
Hub lifecycle guidance remains accessible on the inert preview. Bar retains Behaviour
because position, inset, edge offset and external-display presentation are a distinct
useful task. Expand preview, Arrange components, permanent move-button rows and
repeated autosave/footer instructions are removed. Reset remains reachable.

Inspectors follow preview selection scope: families expose shared styling, while
individual items show identity with shared styling collapsed. Singleton components
stay direct; no instance geometry was introduced. CC's
preview stays left and inspector right at 720 px; fitted content never forces
whole-page horizontal scrolling. Hub uses a compact sample-mode toolbar.

## Conventional pages and progressive disclosure

Appearance leads with theme, icon pack and roundness. Application integration
status/details and advanced shared shell styling remain reachable below them.
Profile starts with the avatar and deliberate Choose/Clear actions, then aligned
identity fields. Personal message and Weather children disappear while disabled
without clearing their saved content. Weather still requires explicit Save location.

Notifications uses compact Toast/History examples beside the shared border controls;
behaviour follows immediately and limits/timing are disclosed. Clipboard prioritizes
collection/privacy/history; card appearance is a disclosure. Date & time and Emoji
keep their functional choices with shorter copy. Launcher dimensions/artwork are
collapsed, with common presentation choices first. Security's synthetic demo is
collapsed while password-only/deferred notices remain visible. Power & Idle retains
its draft/apply contract with a stronger Apply action and a quiet Cancel. Wallpaper
and Displays keep their existing domain workflows and safety notices.

## Scroll architecture and evidence

`SettingsScroll.js` is the only wheel-distance policy: pixel deltas are used directly,
including fractions; angle deltas map to 48 px per conventional 120-unit detent.
There is no threshold, animation queue, speed preference or touch-flick retuning.
`ScrollInput` is installed on shared Settings pages, navigation, adapter diff review,
and galleries. It cancels residual flicking when new wheel input arrives and clamps
to content bounds. Native touch drag physics remain Qt defaults.

Wheel ownership is explicit: the innermost scrollable region consumes movement;
at a bound it forwards to a scrollable ancestor. The fitted CC preview is inert and
has no scrollable overflow. Horizontal gallery gestures and Shift+wheel move the
gallery; ordinary vertical wheel moves the page. Initial tests exposed double
handling with nonblocking WheelHandlers; blocking handlers plus explicit ancestor
handoff fixed this and are covered by exact-distance assertions. Selectors, steppers
and sliders do not change values from navigation wheel input.

Verified isolated inputs: one angle unit moves .4 px immediately, one normal detent
moves 48 px, repeated detents clamp without overshoot, vertical input over a gallery
moves only the page, horizontal/Shift input moves only the gallery, nested input
moves only the inner region until its bound, then only the outer region. Fractional
pixel-delta conversion is tested separately. This does **not** prove native touchpad
momentum, natural-scroll preferences or compositor frame pacing; those require native
review. No synchronous work was added to scroll handlers. The 18 static theme cards
and small installed pack inventory are not virtualized; no measured frame-time claim
is made from software captures.

## Second design pass — deliberate gallery review

Implementation was paused after the complete first gallery. All 14 pages and the
editor/visual-picker views were inspected together, then critical normal/compact/light
frames were inspected at full size. This was a design review, not just a test pass.

| Finding | Classification | Result |
|---|---|---|
| Narrow shared-border row squeezes colour into an almost empty dropdown | High confidence | Separate aligned Colour/Width rows; full-width feature toggles |
| Standalone selectors drift right of their preceding label | High confidence | Left anchor outside rows; explicit trailing anchor in wide two-field rows |
| CC host title still all-caps, scope paragraph still technical | High confidence | Natural title and one short honest shared-effect sentence |
| Notification sample repeats implementation explanation | High confidence | Natural sample notification; shared effect stays in its small settings caption |
| Appearance retains an old 10 px extra top margin | High confidence | Remove route-specific margin; all form title anchors asserted equal |
| Hero gallery headings weaker than secondary disclosure headings | High confidence | Theme/Icon Pack/Roundness use shared section size |
| Short pages can retain an invalid scroll offset after disclosure | High confidence | Shared clamp on content/viewport size changes |
| Tooltip can intercept re-drag after keyboard movement | High confidence | Passive overlay and explicit pointer/keyboard regression |
| Power Apply/Cancel accidentally treated as a label/field grid | High confidence | Action row uses button layout, not the field-column rule |
| Compact switch cards split names across lines | High confidence | Stack samples inside the narrow inspector; preview remains left |
| Software renderer omits shader-tinted SVG icons | Environment limitation | Record honestly; production SVG/fallback logic unchanged, native icon review required |
| Sparse short pages still have substantial lower blank space | Design recommendation | Do not fill with decoration; consider future window/content sizing only after native review |

The normal first frame now gives primary choices priority. Compact CC remains legible
as a whole composition but individual targets necessarily become small. This and
native optical alignment/scroll feel remain review decisions, not claims of final
product acceptance.

## Additional design recommendations — operator review first

| Problem | Proposed change | Benefit | Risk / scope | Recommendation |
|---|---|---|---|---|
| Eighteen themes require lateral exploration and many adjacent variants look similar | Optional All / Dark / Light filter inside the gallery, preserving selected-card reveal | Faster comparison across light/dark families | New navigation layer; small UI task, no schema | Review first |
| Shared-style links take users away from their selection | Anchor the destination group and offer a lightweight return path | Better round-trip editing | Routing/focus-state change across editors | Review first |
| Very compact CC target sizes limit precise pointer work | Selection-focused zoom or a temporary magnifier | Precision without permanent Expand chrome | Drop-coordinate and zoom interaction risk | Review first |
| A long list of externally installed icon packs could become costly | Virtualize the pack gallery if measured inventories justify it | Bounded render cost | Delegate focus/reveal lifetimes; optimize from evidence | Review first |
| Profile's display name feels detached from its avatar at wide sizes | A compact identity composition with fields beside the avatar | Stronger identity first frame | Could compete with CC Profile Header ownership | Review first |
| Sidebar is still one long undifferentiated list | Very subtle Shell / Features / System grouping, keeping current order | Better scanning | Muscle memory and extra labels; not automatically better | Review first |

## Native review checklist

Judge calmness, first-party polish and MAGI personality; visual Theme/Icon Pack/
Roundness/Switch choices; heading/field/internal-text alignment; intentional button
surfaces; unified CC Layout without grips/move rows/Expand; discoverable keyboard
fallbacks; inspector clarity; Profile, Appearance, Notifications and Clipboard;
immediate scrolling and predictable nested/horizontal input; compact usability;
weakest remaining page; and which recommendations above deserve another pass.
No live integration, stage, commit or push is part of this checkpoint.

## Final verification and limitations

27 of 30 existing suite entrypoints pass after updating obsolete UI assertions;
all retained capabilities remain tested. Passing coverage includes Settings schema,
persistence, presentation/navigation/reset/drafts, modules, appearance and reorder;
10A/10B/10C.1; Displays and Fingerprint; 12A/12B/12C/12D/12E; Hub; shared-surface
lifecycle; Calendar/Bar; runtime visual; Notifications presentation; Clipboard
presentation; Emoji backend/presentation; Wallpaper backend/presentation; and
Theme Orchestrator backend plus QML enrollment/confirmation/changed-hook protection.

The new Phase12F suite passes with both default and legacy icon selections. It covers
all 14 pages, equal title anchors, 18 theme choices, click/keyboard/current visibility,
icon-pack identity/fallback/application-icon independence, exact roundness preservation,
switch samples, progressive disclosure, whole-item pointer drag, Escape, keyboard and
context-menu removal, nested/gallery/sidebar wheel input, compact/large layouts, six
palettes, schema18 and persistence/reload. The semantic icon resolver CJS suite passes.

Three existing-suite limitations remain unweakened:

1. `notifications/run.py`: private D-Bus creation is denied by this sandbox (exit127).
2. `clipboard/model.py`: 9/11 pass; the two known PNG image-decoding cases raise
   `Image unavailable or exceeds limits`. Backend code is unchanged.
3. `phase10a/icon-fallback.py`: the old fixture fails at its CC-opening phase wait
   (`presentation.qml` equivalent `icon-fallback.qml:106`) and reports an incomplete
   synthetic Hyprland replacement. The **same failure was reproduced on accepted
   `bea9cf9` in the main checkout** using its isolated runner. This was not weakened
   or relabelled a pass. Core resolver tests and new gallery fallback checks pass.

Offscreen OpenGL/EGL attempts could not create a usable graphics context. Final
review captures therefore use Qt software. No production renderer was changed to
hide that limitation. The supplementary SVG-shapes capture is clearly marked.
Native touchpad phases, GPU tint/contrast and visual comfort still need acceptance.

## Final inventory / protection boundary

**130 intended paths: 77 added, 53 modified, 0 deleted.**

| Category | Paths |
|---|---:|
| Settings design system / navigation | 13 |
| Visual pickers / narrow presenter adapters | 9 |
| Editor refinements | 11 |
| Conventional pages / previews | 12 |
| Scroll/input | 2 |
| Tests | 11 |
| Documentation (including exact inventory and action audit) | 8 |
| Preview assets | 64 |

The gallery contains 62 PNGs (including the all-pages sheet, one baseline Profile
comparison and one labelled SVG-shape capture), an HTML index and capture notes.
Every active page and remaining editor mode is represented; default, compact, large
and six representative palettes are covered. See [gallery](previews/phase12f/index.html)
and [exact A/M/D path inventory](phase12f-paths.tsv). `git diff --stat` covers the
53 tracked modifications; the inventory additionally accounts for all untracked adds.
No logs, caches, temporary renders or generated runtime state are in the allowlist.

The main checkout remains on accepted `bea9cf9`, synchronized 0/0 with origin/main.
Both indexes are empty. `git diff --check` passes. No live source integration,
staging, commit, push, hardware activation or application-opacity/blur work occurred.
The interrupted `magi-phase12f` worktree remains untouched.

The 14 protected paths were snapshotted before work. Thirteen remain byte/link-identical.
Live settings.json changed during the pass: the operator explicitly confirmed these
were their own Mocha→Frappé and CC styling/accent edits. They were left untouched;
we did **not** restore the snapshot or stage the file. Main dirty-path status is unchanged.
Schema remains 18. Test Settings paths resolve only inside disposable source copies.

## Final refinement pass — common intent first, precision second

The existing candidate is retained. This round changes presentation within the
accepted page/ownership architecture; it introduces no schema or runtime model.
Appearance remains the benchmark and its galleries, presets, fine precision and
advanced disclosures are preserved. Scroll physics/input code is unchanged.

### Action and heading audit

[Complete action inventory](phase12f-actions.tsv) covers 88 action declarations or
interaction families, including dynamic editor tabs, disclosures, cards, context
menus and domain-canvas actions. Classifications: 3 Primary, 29 Secondary,
16 Tertiary/quiet, 6 Destructive, 22 Reset, 12 Navigation. Dynamic declarations
represent all their rendered items rather than pretending each item is a new control.

`SettingsButton.actionKind` now provides the shared reset/navigation treatment:
a quiet semantic surface and thin border, consistent padding/height, hover/pressed
feedback, disabled opacity and keyboard-focus outline. Reset text stays neutral;
navigation uses the semantic accent. These are ordinary focusable buttons, not
unadorned text. Reset/default/restore/follow-master operations retain their exact
handlers. Data-erasing actions keep destructive colour, including Emoji history,
Clipboard history, Wallpaper recents and display-profile deletion. Power Apply/Cancel
remains transactional. Choose avatar is secondary, Clear avatar intentionally quiet,
Open Control Centre a navigation action and Reset profile a quiet reset.

Hub's active Layout tab no longer repeats a large Layout heading. Appearance has one
context heading (Hub content, Selector or Switches), at the same section hierarchy as
CC. The repeated Content/Hub selector subheadings are gone; the toggle simply says
Border. Blank sections no longer reserve a heading or heading margin. Clipboard's
nested Card border heading is also gone. All other page titles/section names were
reviewed: remaining headings distinguish actual groups or selected objects rather
than repeating the active tab. No sidebar grouping was introduced.

### Control Centre first-frame composition

| Selection | Common first layer | Disclosed precision retained |
|---|---|---|
| Wi-Fi / other primary module | Module accent; Primary controls shared shape; columns | Icon/container size, background/border/off shades, border width, off strength, ON/OFF references |
| Secondary module | Module accent; Secondary controls shared shape; columns | Icon/container size, background opacity, border width/colour, ON/OFF references and strength/shade |
| Profile Header | Avatar shape; background enable/colour; greeting style | Avatar size/border, greeting/weather/detail sizes and weights |
| Media Player | Artwork shape; progress colour; playback controls; preferred player | Artwork size, artwork/progress border, title/artist sizes and weights |
| Sliders | Track, progress, outline, border width and shape | Section spacing remains a separate quiet disclosure |
| Host | Shape, background and border | Short shared-menu scope note; no additional precision layer needed |

All 36 literal visual-setting keys from the accepted CC inspector remain present.
Fine tune is UI-only state; opening it does not change Settings. Shape controls now
use a label above a slider and adjacent Default action, avoiding an orphaned Default
row or a tiny slider pushed against the right edge. Columns stay inline at compact
width. Section spacing remains available. No control was given per-instance geometry.
The selected module's accent still precedes its shared family settings.

### Remaining page refinements

- **Hub:** removed only the decorative editor scene rectangle. Production Hub host,
  selector surface and selected outlines remain, so the object sits on the canvas
  without another frame. Mode/selection safety and production behaviour are unchanged.
- **Profile:** bounded the content to 520 px, bringing the name field closer to its
  label and the avatar/actions. Optional message and Weather controls retain their
  conditional visibility and saved values. Compact width uses the existing row rules.
- **Clipboard:** the first frame explicitly says session-only by default and that
  saved history is unencrypted. About Clipboard history discloses sensitive-hint
  limitations, pins, persistence/removal, backups, pausing and possible unpinning when
  reducing the limit. No security detail was deleted. Card preview and shared-style
  navigation remain available.
- **Notifications:** aligned the card-border group with the preview column rather
  than adding an extra section top margin. The compact Toast/History examples and
  independent flags remain; the Clipboard-sharing note stays quiet.
- **Conventional pages:** reset and history actions now follow the same treatment.
  Date/time, Launcher, Emoji, Power and Security keep their structured layouts.
  Wallpaper and Displays receive action styling only; domain workflows are untouched.
- **Appearance/sidebar:** no new cards, filters, groups or elevation changes. The
  accepted benchmark did not need another redesign.

### Final optical review

Reviewed all page first frames, CC selected contexts, Hub contexts, compact layouts
and Dawn captures again. High-confidence follow-ups from that review: tightened
Profile from an initially tried 600 px to 520 px; gave CC shape/Default rows deliberate
geometry; reduced Hub inspector heading size to section size. Intentional empty space
on short pages and unavailable Wallpaper/Security fixtures is retained. No decorative
content was added just to occupy it. Compact CC and Hub remain side by side; the
small CC canvas still needs native pointer-comfort judgement, not a new zoom feature.

The gallery retains useful baseline references and adds an expanded CC Fine tune
view and the complete Clipboard history explanation for review. Software rendering
cannot establish native icon tint, touchpad feel, physical wheel momentum or frame
pacing; those acceptance items remain pending.

### Deferred recommendations — operator decisions honoured

| Recommendation | Decision in this pass |
|---|---|
| Dark/Light theme filter | Deferred; preserve lateral gallery and partial-card affordance |
| Shared-style return navigation | Standardize existing navigation actions only; no return-state system |
| Temporary compact CC selection zoom | Deferred |
| Stronger avatar/name composition | Only the bounded-width optical refinement applied; no new identity model |
| Sidebar grouping | Deferred; no grouping labels or navigation changes |
| Icon-pack gallery virtualization | Remains evidence-dependent future work; no speculative rewrite |

No additional subjective redesign is being imposed. The remaining review questions
are whether the quieter reset actions, CC disclosure depth, Profile width and
unframed Hub canvas feel right natively. Keep precise tuning one disclosure away.

### Final-refinement verification

The 30-entrypoint regression set was rerun: 27 pass, with the same three documented
baseline/environment limits above. Following the optical adjustments, Settings
presentation/reorder, 12C, 12D, 12E and runtime visuals were rerun and all six pass.
Phase 12F passes with default and legacy icon packs; the final legacy gallery includes
keyboard-operated precision/privacy disclosures and invariant settings assertions.
The semantic icon resolver passes independently. No existing failure was weakened.

A fresh snapshot for this refinement includes the operator-confirmed Frappé and CC
edits from the earlier pass. All 14 protected paths remain byte/link-identical to
that fresh snapshot. Both indexes are empty, main and isolated HEAD remain on
`bea9cf99b7a6b9aae358c8b78bb2ff6945722e3d`, and origin comparison remains 0/0.
Schema is 18. `ScrollInput.qml` and `SettingsScroll.js` are byte-identical to their
pre-refinement fingerprints; fractional/normal/repeated wheel, nested-bound handoff
and gallery/page ownership checks still pass. Native gesture feel is not claimed.
Temporary logs, audit scripts and montage intermediates remain under `/tmp`.
No live integration, staging, commit or push occurred. Operator review is the next step.

## Final interaction-scope pass — family selection versus item selection

**Permanent MAGI editor rule:** group/family selection edits shared presentation;
item selection edits only that item's identity/options. Shared family controls remain
available through contextual disclosure but do not dominate individual-item editing.
Apply this only where the product has a real shared family, never by inventing
per-instance preferences. Selection and disclosure are transient editor state.

### Scope and applicability decisions

| Target | Family selection | Item selection |
|---|---|---|
| CC Primary | Primary region opens shape, columns and existing Fine tune | Wi-Fi/Bluetooth/etc. show Accent; Primary controls is collapsed |
| CC Secondary | Secondary region opens its own shared shape, columns and Fine tune | DND/Caffeine/etc. show their semantic accent; Secondary controls is collapsed |
| CC Sliders | Sliders region opens Track, Progress, Outline, border width and shape | Volume/Brightness have no unique visual setting: name plus collapsed Sliders, no invented option |
| CC Profile / Media | Existing singleton inspectors | No artificial family/instance distinction |
| CC / Bar host | Existing host inspector | No extra level |
| Bar Status pills | Heading selects all status/utility pills and opens shared style | Wi-Fi/Bluetooth show Accent, collapsed Status pills and their existing menu disclosure; other modules show only actual options |
| Bar Workspace pills | Heading or any numbered pill selects the Workspace family | No per-workspace styling was invented |
| Hub selector / switches | Mode icons select Selector; sample switches select Switches | No per-mode or per-switch identity state; the family is the meaningful target |
| Notifications | Retain the existing compact shared card style with separate Toast/History flags | No additional selection layer: the existing preview-plus-controls presentation is clearer |
| Clipboard | Retain its streamlined single card presentation | No artificial split |

`EditorSelection.familyKeys` classifies existing transient selection IDs. CC uses its
existing section IDs; Bar uses Status pills plus the existing Workspaces module key.
No persisted object or placement model changed. An instance's family disclosure resets
closed when its identity or family changes, including a CC presentation-family move.
Opening the disclosure keeps the selected item. Fine tune remains inside that family
view, preserving all precision controls. Global reset utilities remain reachable from
family/host views and deliberately expanded family disclosures; Layout reset stays put.

### Preview and keyboard language

CC headings and region empty space are broad appearance targets, with accessible
names such as Primary Controls appearance. The region uses a quiet accent heading,
a thin translucent boundary and a faint semantic tint. Individual items use a stronger
outline. Bar's two small family headings occupy the existing preview label strip in
Appearance; status family selection coordinates subtle boundaries across its members,
while Workspace selection highlights the whole workspace module. Layout retains its
existing labels, drag targets and drag outline; Behaviour gains no family toolbar.

Both family and item selection support Tab, Space/Return and accessible press actions.
Pointer selection moves focus to the new target so a stale item ring cannot imply a
second scope. Returning to Layout transfers a focused preview item to its existing
drag handle when necessary. Alt-arrow/Home/End and context-menu operations are retained.
Bar inspector rows now honour the existing compact row layout, avoiding overlapping
labels when the shared family view is open in a narrow inspector.

Empty CC families retain editor-only Appearance headings so their saved style remains
editable. Production empty-region rendering is unchanged. Removing a selected module
clears selection safely; an empty family itself remains a valid editor target.
Microcopy such as Shared appearance, Only this control and All workspaces is removed
where the selection/disclosure already communicates scope. Semantic scope notes for
truly cross-feature menu tokens remain honest.

### Verification and review evidence

Phase 12F covers actual pointer and keyboard family/item selection, collapsed defaults,
explicit disclosure, unchanged Settings/revision during selection, independent Primary
and Secondary accents, family geometry propagation, Bar icon-size propagation, no fake
workspace identity, singleton continuity, empty-family targets, selected-item removal,
Hub family-only applicability and compact scope visibility. The existing wheel/input
assertions are unchanged; disclosure collapse also verifies bounded inspector scroll.

The requested regression set passes: Settings schema/persistence, presentation,
appearance and reorder; retained 12A, full 12C/12D/12E; Hub; Notifications presentation;
runtime visuals, production CC composition and shared-surface lifecycle. The previous
D-Bus protocol, Clipboard decoding and old icon-fallback fixture limitations remain
as documented; those unrelated failing entrypoints were not relabelled or weakened.

The gallery keeps existing pages and adds explicit CC Primary/Wi-Fi,
Secondary/DND, Sliders/Volume and Bar Status/Wi-Fi/Bluetooth/Workspace comparisons,
plus compact family/item views. Native acceptance should judge family target discovery,
the quieter region versus stronger item highlight, and family-disclosure discoverability.
The intentionally sparse Volume and non-customizable Bar item views should be reviewed
for clarity, not filled with fabricated controls. No further subjective design change
is imposed in this pass.

Final scope-pass inventory is **130 paths (77 A / 53 M / 0 D)**. The action inventory
now covers 89 declarations/families, including the Bar family-target declaration.
All 14 operator-state paths match the fresh pre-pass fingerprint, including confirmed
live preferences. Both indexes remain empty. Scroll implementation fingerprints match;
schema stays 18. No live source, stage, commit, push or Phase 12G work was performed.

Native review questions:

- Is family selection obvious in both CC and Bar?
- Do individual-item views feel substantially cleaner?
- Is the quiet family boundary versus stronger item outline understandable?
- Is collapsed access to shared styling discoverable enough?
- Does CC feel less like a property inspector?
- Does Bar follow the same mental model naturally?
- Does any distinction feel forced, particularly the intentionally minimal Volume view?

## Final pre-integration correction — horizontal Bar archetype

Composition follows the aspect ratio of the edited object:

- **Vertical visual editors (Control Centre, Hub):** preview left, inspector right
  wherever space permits.
- **Horizontal Bar editor:** full-width preview at the top, inspector or relevant
  controls below, in Layout, Appearance and Behaviour, including compact windows.

The Bar page's existing editor frame now uses one column in every mode. Its inspector
no longer requests the former side-column width. Layout and Behaviour retain their
existing composition; Appearance follows them. Family/item selection, disclosure,
workspace-family behaviour, keyboard editing, Available modules and quiet actions are
unchanged. No shared editor primitive, scroll implementation, schema or CC/Hub layout
was modified for this correction.

Phase 12F now checks canvas width against the page's usable body width, common left
anchors and preview-above-controls geometry across all three modes at normal and
compact widths. Existing family/item and scroll checks still run. The capture filter
allows this review to refresh only the nine requested Bar images; unrelated gallery
images remain intact. Native review should use those updated full-width Bar captures.

Pre-integration correction verification: Phase 12F, full Phase 12C, Settings
presentation, Settings reorder and runtime visuals all pass. The nine requested Bar
captures were regenerated and reviewed at normal and compact widths; no unrelated
capture was replaced. `git diff --check` passes. All 14 protected operator paths,
CC/Hub page layouts, Bar inspector, selection model and scroll implementation match
the pre-correction fingerprints. Entire candidate inventory remains 130 paths
(77 A / 53 M / 0 D), with both indexes empty. Phase 12F is ready for live integration;
this checkpoint itself performs no integration, staging, commit or push.

## Live integration — pre-acceptance evidence

The exact reviewed 130-path set (77 added, 53 modified, no deletions) was copied
from the isolated worktree after the operator confirmed All changes saved. The
same single MAGI instance `y610sddnt` (PID 1546) reported Configuration Loaded.
Schema remained 18 and settings.json was byte-identical immediately after reload;
all 14 protected operator-local entries matched the fresh preflight snapshot.
Preflight preferences were Catppuccin Frappé and MAGI Default.

The reload emitted one undefined-to-int warning from unchanged Network.qml
signal-strength binding and familiar Wayland text-input focus warnings. No Settings
component load error or reload loop was observed. IPC is sandbox-blocked, so native
page opening, wheel/touchpad feel, actual SVG tint and visual acceptance require
the operator's review. No staging has occurred.

## Native acceptance and final operator preference

The operator accepted the native review gate, including overall composition, Theme
gallery and precision disclosures, Icon Pack rendering/tint, Roundness interaction,
mouse-wheel/touchpad response, horizontal galleries and nested scroll behavior.
CC Layout, family/item selection and deliberately minimal item inspectors were accepted.
Bar retains full-width preview above controls in every mode and at compact width;
family/item editing remains intact. Hub hierarchy, Profile composition, Notifications
and Clipboard presentation, conventional pages and Rosé Pine Dawn were accepted.
These are operator-reported native results; software tests remain complementary.

One final preference was requested: restore the background behind the left main
Settings menu. `SettingsContent` again uses the original semantic `elevated` sidebar
background. The operator explicitly confirmed “Yes — sidebar is correct; finalize.”
No navigation grouping, geometry, scroll logic, data model or unrelated runtime
behavior was changed. Settings presentation passed after the correction.

The final regression found two stale fixture assumptions, both corrected without
weakening capability checks: an absent optional capture-filter variable now means
all captures; the old Phase 10A fixture now checks status-icon controls are hidden
for an individual Wi-Fi selection and visible for the Status pills family. Both
fixtures pass after those corrections.

Deferred recommendations remain unchanged: optional Dark/Light gallery filtering,
return-navigation state for shared-style links, compact CC selection zoom and sidebar
grouping. No Phase 12G implementation is included.

### Final regression and inventory

After native acceptance and the sidebar correction, **31 of 34 regression suites
passed**. This includes Phase 12F, Settings schema/persistence/presentation/appearance/
navigation/reorder, Phases 10A/10B/10C.1 and 12A–12E, Hub, shared surfaces, Calendar,
Notifications presentation, Clipboard presentation, Emoji, Launcher, Wallpaper,
Displays, Fingerprint, runtime visuals and Theme Orchestrator. Additional CC runtime
composition and semantic icon-resolver checks pass. The Phase 12F default-pack and
Legacy gallery runs pass with all existing scroll/input assertions unchanged.

The three existing limitations remain unweakened:

- Notifications protocol cannot start a private D-Bus inside the sandbox.
- Clipboard model passes 9/11 checks; the two baseline image-decoding cases report
  “Image unavailable or exceeds limits.”
- The baseline icon-fallback fixture still times out opening CC with its incomplete
  compositor fixture. Dedicated icon resolution and current CC runtime checks pass.

The Launcher backend fixture initially ran from the repository root, but requires
`linux/magi` as its working directory; it passes there without source changes.
Earlier failed fixture attempts and corrected-run logs are retained in the temporary
finalization evidence. No test expectation was weakened.

Current after-captures, the shape-only supplementary image and the contact sheet
were refreshed to show the restored sidebar. Historical Before Profile stays intact.
The exact final allowlist remains **130 paths: 77 A, 53 M, 0 D**, including 64 gallery
assets (62 PNG images plus index and README). No runtime state, logs, temporary
captures or Phase 12G implementation are included. `git diff --check` passes.
All 14 protected local files/symlinks, including settings.json, match the preflight
snapshot byte-for-byte/target-for-target after native review. Schema remains 18,
with Catppuccin Frappé and MAGI Default retained.
