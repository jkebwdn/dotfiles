# MAGI visual / Settings overhaul — phase 1 audit and implementation plan

Date inspected: **2026-10-15**. Baseline verified locally:
`a6a2856aa849fdbc4b8cd7e26c12b58a5965720a` — `magi: add system theme orchestrator`.
Status: **read-only investigation with this report as the sole authorized output**.
No implementation, existing-document updates, application activation, test-suite
execution, system edits, staging, commits or pushes form part of this phase.

## Method and evidence boundaries

Repository QML, the schema/store, service interfaces, existing tests and project
instructions are the primary evidence. No web research or new framework dependency
was necessary. Source links below are relative to this report and refer to the
verified baseline; named components/functions identify the relevant implementation.
The audit inspected current code rather than inferring behaviour from filenames.
No code/assets from other projects were reused; no external licensing dependency
is introduced by this proposal.

Three evidence levels are used:

- **Observed in source:** explicit geometry, bindings, event handlers, data contracts
  or repeated declarations. These are not claims about live GPU rendering.
- **Calculated:** contrast from registry RGB and default Settings values, using
  sRGB relative luminance. Actual operator overrides and rendered image backgrounds
  can change results. These are not comprehensive accessibility certification.
- **Proposal / native check:** visual direction or likely narrow-window failure
  requiring later offscreen layout and native operator verification.

Operator acceptance of existing functional milestones, including the final Zen
hybrid sanity checks, is retained. This audit does not reopen that acceptance or
claim a new native screenshot review. No running shell was opened/restarted or
manipulated. Existing tests were inspected to plan regressions, not run here.
No live notification/clipboard/browser contents were read.

Initial Git status contains the protected Settings JSON, eight modified Stow
integration source files, two untracked Hypridle/Hyprlock files and the Yazi flavour
symlink. Their content hashes/symlink destinations were captured read-only for
end-of-pass comparison. None is a visual-overhaul source change.

## A. Current-state map

### Architecture to retain

The architecture is adequate for the overhaul; no replacement host system is
needed. Preserve the following contracts:

- [shell.qml](../../.config/quickshell/magi/shell.qml) activates first-party services
  and hosts the combined bar, one Hub, toasts, Settings and Wallpaper Manager.
- [Bar.qml](../../.config/quickshell/magi/components/bar/Bar.qml) owns the main
  layer, exactly **48 logical px** reservation in combined mode, input regions,
  dismissal catcher and OnDemand keyboard focus. Its compact strip is 48px high;
  it uses full-screen-height geometry for expanded content without reserving that
  height. Do not conflate panel height with exclusive zone.
- [SharedStatusSurface.qml](../../.config/quickshell/magi/components/bar/SharedStatusSurface.qml)
  owns staged expand/reveal/fade/retract, retained bodies and focus transfer.
  [CalendarSurface.qml](../../.config/quickshell/magi/components/calendar/CalendarSurface.qml)
  reuses that mechanism as a **separate anchored family**, with time/date absorption.
- [ModuleRegistry.qml](../../.config/quickshell/magi/modules/ModuleRegistry.qml)
  keeps independent Wi-Fi/Bluetooth/Volume/Control Centre objects. Its interaction
  guard defers presentation changes during Wi-Fi selection/connection.
- [Hub.qml](../../.config/quickshell/magi/services/Hub.qml) coordinates visibility,
  visited-mode preparation and handoffs; services keep their data/worker ownership.
  [HubContent.qml](../../.config/quickshell/magi/components/hub/HubContent.qml)
  retains four content instances, exactly one visible. Do not split modes into
  separate windows or replace persistent content with destructive loaders.
- [SettingsStore.qml](../../.config/quickshell/magi/settings/SettingsStore.qml)
  owns validated writes, conflicts, migration and ordering. Presentation must not
  become a second writer. [SettingsSchema.js](../../.config/quickshell/magi/settings/SettingsSchema.js)
  is schema 10; preserve unknown values and existing explicit preferences.

### Settings map

[SettingsWindow.qml](../../.config/quickshell/magi/components/settings/SettingsWindow.qml)
is a normal FloatingWindow: initial 940×720, minimum 720×500, 190px sidebar,
11 page destinations, Loader-selected page, persistent save/error footer. The
sidebar is a non-scrolling ColumnLayout. It establishes Noto Sans 14 and a partial
Qt Basic control palette. Page changes recreate the page; local draft/control
state can therefore be lost. This matters especially for unsaved Wallpaper roots.

All page links below are in `components/settings/pages`:

| Page | Existing composition / behaviour | Reorganization opportunity |
| --- | --- | --- |
| [Appearance](../../.config/quickshell/magi/components/settings/pages/AppearancePage.qml) | Theme selector, eight swatches, 13 adapter/deferred rows, inline enrollment review, Zen colour/Copy, shell icon pack, roundness, many visual tuning sliders/selectors | Separate common theme choice, application following, and advanced shape/state tuning; avoid making adapter diagnostics the whole page |
| [Profile](../../.config/quickshell/magi/components/settings/pages/ProfilePage.qml) | Avatar import/clear, display name, greeting/custom subtitle, preview/reset | Strong preview, masked avatar and clear conditional custom subtitle field |
| [Bar](../../.config/quickshell/magi/components/settings/pages/BarPage.qml) | Module placement selector and up/down controls | Human-facing names, grouped regions, stable reorder rows; retain hidden-module behaviour |
| [Date & time](../../.config/quickshell/magi/components/settings/pages/CalendarPage.qml) | Locale/week start/density/time/date selectors, adjacent days, week numbers | Group bar formatting separately from calendar display; retain keyboard explanation in help |
| [Control Centre](../../.config/quickshell/magi/components/settings/pages/ControlCentrePage.qml) | Independent columns/actionColumns, section flags, module/accent selectors and order/remove buttons, add menus, sliders | Group layout, primary controls and secondary actions; progressive per-entry colour editing |
| [Notifications](../../.config/quickshell/magi/components/settings/pages/NotificationsPage.qml) | Enable/toasts/DND/body/critical policy, timeout/count/history fields | Everyday controls first; preserve policy semantics and units in advanced section |
| [Clipboard](../../.config/quickshell/magi/components/settings/pages/ClipboardPage.qml) | Collection/types/persistence, limit, privacy help, clear/armed erase/status | Separate capture, storage/privacy and destructive actions; do not hide persistence warning |
| [Launcher](../../.config/quickshell/magi/components/settings/pages/LauncherPage.qml) | List/grid/layout/size/icon/image options plus hidden-app restore list | Mode-relevant fields and advanced artwork/layout group; hidden apps as a compact list |
| [Emoji](../../.config/quickshell/magi/components/settings/pages/EmojiPage.qml) | Enable/categories/close-on-copy, columns/size/recents, clear/reset | Small grouped form; no new picker semantics |
| [Wallpaper](../../.config/quickshell/magi/components/settings/pages/WallpaperPage.qml) | Roots editor with explicit Save, manager link, thumbnail size, status and recents reset | Dedicated source-directory section; explicit draft/Save semantics, concise operational status |
| [Icons](../../.config/quickshell/magi/components/settings/pages/IconsPage.qml) | Existing MAGI internal pack/role overrides, four-role SVG import/reset | Label as shell icons to distinguish from system application icon themes; preserve import safety |

Repeated page skeleton: Flickable, `contentHeight = implicitHeight + 48`,
24px x/y padding, width minus 48, title 26 bold, vertical ScrollBar. Spacing varies
14/16/18/20px; scroll bounds are explicitly StopAtBounds on Appearance but not
uniformly on all pages. Label columns vary from fill-width to fixed 155/200px.
Most controls are unwrapped Qt Basic CheckBox/Slider/ComboBox/SpinBox; there is no
shared field-row or section contract. Actual card nesting is modest: do not solve
this by putting every field in another bordered card.

Existing reuse is narrow: [SettingsButton.qml](../../.config/quickshell/magi/components/settings/SettingsButton.qml)
styles backgrounds, and [VisualSettingsGroup.qml](../../.config/quickshell/magi/components/settings/VisualSettingsGroup.qml)
repeats numeric/role editors with fixed 200px labels. The latter is useful but
Appearance-specific, not yet a general form toolkit.

### Shell surface/component map

| Area | Current visual ownership | Keep / debt |
| --- | --- | --- |
| Bar/status cluster | Theme pill metrics, ModulePill adapter, MorphingPillContent, per-module icons | 28px pill height, 6px compact gaps, 14px outer inset; expanded status spacing interpolates to 12px; preserve live delegate continuity |
| Control Centre | RenderTokens, ControlTile, ActionButton, IconSlider, ProfileHeader, MediaSection | Independent grids; icon-only tiles and actions, coloured tile rims; duplicated height arithmetic |
| Hub | 48px selector band, 32px mode buttons, per-mode preferred dimensions | Host navigation already has focus rings/F6; child modes still have inconsistent headers/search/footer layouts |
| Notifications | Shared NotificationCard for toast/history, NotificationContent and ToastHost | Bounded plaintext, timestamps/actions, input-mask lifecycle; duplicated embedded title/close chrome |
| Wi-Fi | WifiMenuContent + WifiAuthentication + controller | Current-network card, nearby list, inline auth; compact status typography and pointer-only row controls |
| Calendar | CalendarContent + TimeDatePill + separate CalendarSurface | 344px nominal expansion, 32/38px day cells, numeric header offsets; keyboard date model already present |
| Wallpaper | WallpaperWindow/Content/Tile | Separate accepted manager, virtualized grid, filters/scope/fit; basic controls and image-edge inconsistencies |
| Artwork/icons | RoundedArtwork, Icon, IconRegistry, LauncherIcons | Mask implementation exists; semantic shell icon tint distinct from app icon lookup |

Theme roles are centralized in [registry.json](../../.config/quickshell/magi/theme/palettes/registry.json),
resolved by ThemeRegistry and [Theme.qml](../../.config/quickshell/magi/theme/Theme.qml).
Ten dark/light palettes, 33 semantic roles, paired on-colour roles, user roundness
and visual overrides already exist. [RenderTokens.qml](../../.config/quickshell/magi/theme/RenderTokens.qml)
is explicitly a scoped Control Centre reference set, not a global design system.

## B. Visual debt inventory

“Critical” below means a concrete interaction/legibility issue, not a preference
for a different desktop style. Native severity still needs checking where noted.

| Priority / ID | Evidence | Impact and proposed response |
| --- | --- | --- |
| Critical inconsistency C1 | ControlTile uses TapHandlers only; ActionButton, ActionChip, IconSlider and ValueSlider rely on pointer handlers; MediaButton has Accessible metadata but no keyboard activation. NotificationCard close/action Items similarly lack full keyboard paths | Some primary operations have no local Tab/Space/Enter/arrow equivalent. Build focusable control contracts with accessible actions; preserve existing global keys and alternate service paths |
| Critical inconsistency C2 | Theme.stateColor defaults primary ON ink to `text`; tinted tile backgrounds are not paired with on-colour ink. SettingsButton changes pressed background to accent without explicitly selecting accentText | Calculated low-contrast foreground/background pairings (section G). Correct component pairings and test rendered states; do not mutate canonical palettes to repair individual controls |
| High H1 | SettingsWindow sidebar has 11 navigation buttons, header/footer and gaps in an unscrolled column despite 500px minimum height | Narrow/short-window navigation overflow risk; test bounds, introduce independently scrolling navigation |
| High H2 | Fixed label/control combinations: VisualSettingsGroup 200+56px before slider; CC module + 118px accent + three buttons; Theme target name + full checkbox label + Retry | At 720px window width, sidebar leaves roughly 482px page content after padding. Layouts can compress labels/controls excessively; stack secondary lines at a content-width breakpoint |
| High H3 | ProfilePage rounded Rectangle uses `clip: true` with a full-size image; RoundedArtwork already uses MultiEffect mask | Rectangle clip is rectangular, not its painted rounded outline. Reuse mask for circular preview; do not claim all artwork masks are missing |
| High H4 | Appearance mixes palette, 13 target rows, detailed roundness/state controls; Launcher exposes both list/grid settings together | Poor hierarchy and long scans. Keep common choices first, advanced groups collapsed by default without losing explicit settings |
| High H5 | Hub selector band plus Notifications title/close and Clipboard title/close; search heights 46 vs 42 and padding 16 vs 18 | Repeated chrome and inconsistent mode rhythm. One host-level header/navigation contract plus mode-specific actions |
| High H6 | CC naturalHeight embeds profile 58, media 86, sliders 48 and section gap18; Wi-Fi subtracts hard-coded row/header heights | Larger text/avatar designs can clip or produce empty space if only child styling changes. Introduce measured section metrics without disturbing lifecycle phases |
| High H7 | Persistent theme results concatenate backend status and palette ID; all enabled targets display Retry; Zen adds another line and Copy; deferred targets mix with daily-use targets | Keep status truthful but scan-friendly. Distinguish result, required action, error and details; preserve inline enrollment confirmation and visible failures |
| Medium M1 | Noto Sans Settings vs JetBrainsMono body across utility modes; sizes9–26; individual widgets omit font.family | Deliberate font roles rather than accidental inheritance; preserve monospace compact bar identity and data text |
| Medium M2 | Custom buttons have different hover/focus/pressed/disabled treatment; .4/.45/.55/.6 opacity conventions | Define state pairs and focus indicator, avoiding colour/opacity alone as state evidence |
| Medium M3 | Media shows artist 13 bold above title10; controls32×28; empty mode keeps “—” title | Stronger title/artist hierarchy, clearer inactive state and larger hit areas within explicit geometry budget |
| Medium M4 | Wallpaper outer radius10, unmasked crop image, fixed dark caption scrim; native Basic buttons alongside bespoke shell controls | Reuse artwork/image-caption treatment and state badges; distinguish focus, current wallpaper and favourite |
| Medium M5 | Shared host, anchored host and ExpandablePlugin repeat 180/140/90/70/120/160 timings; toast/workspace transitions use other local values | Centralize categories while retaining phase ordering; no gratuitous new animations |
| Medium M6 | Network duplicates Wi-Fi title inside a titled expanded surface, uses 9/10px metadata; connected card64 vs nearby rows44 | More compact connected summary and aligned status roles; preserve error/auth space and security text |
| Optional/later O1 | No weather summary exists | Reserve a header data slot; no provider, location, network access or placeholder feature now |
| Optional/later O2 | CC ordering is up/down with stable entry keys | Plan drag handles and a single commit-on-drop adapter; retain keyboard move controls |
| Optional/later O3 | Launcher already has list/grid and system icon resolver | Defer dedicated Rofi-like/Launchpad-like visual evolution and Fraud O.G artwork/port |

## C. Concrete reusable component opportunities

Use a small layered set. Adapt proven components rather than creating parallel
frameworks or one generic component with dozens of flags.

| Candidate | Existing consumers | Contract / reuse strategy |
| --- | --- | --- |
| SettingsPage + SettingsSection | All 11 pages | Scroll/padding/title/help/error rhythm; section slots; optional disclosure, accessible headings; UI-only scroll state |
| SettingsRow with toggle/select/numeric wrappers | Notifications, Calendar, Emoji, Launcher, Appearance, Wallpaper | Label, short description, control slot, validation and responsive stacking; signals call existing Settings APIs; no persistence inside row |
| IconButton / button state foundation | ClipboardIconButton, Hub modes, notification dismiss/actions, calendar arrows, media/actions | Build on the existing Button-based clipboard control; accessible name, focus, tooltip, disabled/pressed ink, keyboard activation |
| SearchField | Launcher, Emoji, Clipboard | Shared size/padding/palette; preserve per-mode key interception and query/selection model; never own service search logic |
| SurfaceHeader + CompactStatusRow | Hub content actions, Wi-Fi summary, notifications, profile-adjacent status | Slots and optional title/actions; avoid forcing one title on every embedded mode |
| InlineStatus / StatusBadge / EmptyState | Theme targets, network errors, wallpaper status, Hub modes | Text plus semantic severity/action, wrapping and optional retry; no inferred success from colour alone |
| Avatar + existing RoundedArtwork | Profile header/Settings preview; media/clipboard/wallpaper images | Avatar enforces circular geometry; generic artwork retains rounded mode/progress. Audit GPU masking before rewriting it |
| ReorderRow | CC controls/actions and optionally Bar placement | Stable key, enable state, edit affordance, keyboard moves; later drag handle. Data mutation remains in SettingsStore |
| ActionTile / SliderTile refinements | Existing ControlTile, ActionButton, IconSlider, ValueSlider | Evolve existing files/behaviour; focusable Base Control wrappers rather than new service-aware tiles |

Do not abstract the calendar cell model, notification records, clipboard privacy
policy or adapter state machine into visual controls. Reuse typography/state
primitives within their existing content components. Use section backgrounds only
where grouping needs one; separators or whitespace usually suffice.

## D. Proposed token/system contract

Retain ThemeRegistry as semantic colour authority. Add one small geometry/type/state
layer (working name `VisualTokens.qml`) and a motion layer if needed. Existing
Theme.radius and explicit Settings overrides remain authoritative. RenderTokens
may delegate to the new layer gradually; do not delete the reference facade until
all consumers/tests migrate. No second palette registry or new theme dependency.

| Category | Proposed starting values / rules | Rationale / caveat |
| --- | --- | --- |
| Spacing | Base 4; supported2/4/6/8/12/16/20/24/32; named bar inset14 and established CC gap18 exceptions | Preserve compact6/12 rhythm and accepted14/18 geometry initially; no mass replacement of meaningful offsets |
| Typography | UI family Noto Sans; compact/data family existing JetBrainsMono; emoji Noto Color Emoji. Caption11–12, body13–14, section16–18, page24–26 | Existing identity, improved small metadata; 9px reserved for nonessential compact indicators only. Font role, not a per-component arbitrary choice |
| Radius | Action6–8, row/tile10–12, surface14–22 through existing role multipliers | Keep square/reference/rounder overrides; circle is an explicit Avatar shape contract, not master roundness accidentally making a rounded square |
| Icon size | 16 inline, 18 compact bar default (respect saved setting), 20–24 standard, 28–32 primary tiles | Separate image size from hit target; preserve mixed fixed-art/semantic icon colour modes |
| Row/control size | Standard control36, compact32, form row minimum44, two-line row56–64, search44–46; keep bar28 within48 strip and CC tile60 initially | Starting design budget, not a global fixed-height mandate; rows grow for wrapped text, errors and zoom |
| Stroke | Default1, focus2; preserve configured tile4/slider2/avatar2 as explicit reference defaults until operator-approved change | Avoid triple borders (surface + section + each field); do not silently reset saved rim settings |
| Surfaces | Opaque semantic background/surface/elevated for forms and panels; selected/hover pairs specify both fill and ink | Existing Hub is opaque. Do not add global transparency/blur or palette-coloured glows |
| Image captions | Named imageScrim + imageOnScrim pair, contrast validated over imagery | Wallpaper's fixed dark scrim/white is image-legibility policy, not automatically a light-theme bug. Make intention explicit rather than changing to unreadable light text surfaces |
| Disabled | Semantic disabled ink plus disabled interaction, optional opacity only when tested on composed background | Avoid repeatedly dimming already-muted colours; visually separate OFF-but-interactive from unavailable |
| Focus | Consistent2px semantic focus ring/outline and keyboard focus path | Selected, focused, hovered and current/applied are different states |
| Shadows | No new shadow by default; if later approved, a restrained neutral paired dark/light surface treatment | Never touch Hyprland shadows/effect strengths; Theme Orchestrator still owns only borders there |

Motion proposal uses existing OutCubic identity: micro/hover80–120ms; control-state
120–150ms; position reflow140–180ms; surface expand180/reveal140 and close retract120/
contract160, content fade-in90/out70. Keep these phase-specific values initially,
centralize their names, then review perceived rhythm. Current workspace colour
animation defaults to linear150; consciously choose whether colour state should
remain linear rather than forcing geometry easing everywhere.

Hub currently changes mode-dependent dimensions without explicit animated geometry.
A restrained size transition is optional after focus/input-region tests; no fade
that hides typed text or recreates content. Reduced-motion support is a potential
later preference: do not simply set phase-driven animations to zero without
verifying completion/focus/catcher transitions. Avoid animating live numerical
values, long lists or whole pages on every setting change.

## E. Settings redesign proposal

Retain the normal window, SettingsWindowState entry points, schema and auto-save
contract. Replace the unscrolled navigation column with a bounded list and a stable
registry of existing page IDs/labels/components. Existing service links such as
`page = "Wallpaper"` must continue working through aliases if labels later change.
No data migration is needed solely for visual grouping.

Proposed navigation groups: **Appearance** (Theme & shape, Profile, shell Icons),
**Shell** (Bar, Control Centre, Date & time), **Utilities** (Notifications,
Clipboard, Launcher, Emoji, Wallpaper). These are presentation groupings, not a
new service hierarchy. Keep destinations discoverable; a navigation search is
optional later, not necessary to ship the overhaul.

Use one outer page scrolling context, shared title/help spacing, section headers
and right-aligned controls with a stacked layout below an available-content-width
threshold (start around520px and validate). Sidebar may narrow from190 to160 at
minimum window width; prioritize text-labelled navigation rather than icon-only
ambiguity. At short heights, both navigation and page must remain reachable.
Maintain footer conflict/error visibility; move schema version to technical details
rather than primary user feedback. Preserve actionable “Discard edits and reload”.

```text
MAGI Settings              Appearance
Appearance                Theme                        [Catppuccin Mocha v]
  Theme & shape           [small semantic palette preview]
  Profile
  Shell icons             Applications following MAGI                 [details]
Shell                     Hyprland     Runtime update               [Follow]
  Bar                     Ghostty      Reload configuration         [Follow]
  Control Centre          Zen          CSS generated                [Follow]
  Date & time                          Workspace base #1e1e2e        [Copy]
Utilities                              Manual selection · Restart CSS
  ...                     [Deferred targets (3) >]
                          Shape                         [Master roundness]
                          [Advanced colour/state tuning >]
                          [Reset Appearance…]
                          Saved / actionable error
```

“Runtime update” must be qualified by actual backend result; this wireframe is
hierarchy, not a new claim of successful activation. Errors expand visibly and
must not disappear into a closed details group. Integration review remains next
to the initiating row with exact diff, enable and cancel; no hidden enrollment step.

Appearance grouping: theme/preview first; System Theme section with status/action
hierarchy; shape next; advanced per-role roundness, primary/secondary icon states,
slider colours/rims and profile border tuning last. Preserve all existing palettes.
Avoid showing “Follow MAGI Theme” in full on every row if the column heading and
accessible control name communicate it, but keep the control as primary opt-in.

Control Centre grouping: independent primary/secondary columns, sections, primary
control list, slider list, secondary action list. A row shows module name, enabled,
colour swatch and reorder/edit affordance; expanded editor hosts module/accent
selectors. Do not hide removal or keyboard order behind drag-only gestures.

Wallpaper roots are a draft with explicit Save, unlike ordinary auto-save fields.
Make dirty state visible and preserve it during navigation or ask before discarding
in the later implementation; do not silently save roots on every keystroke.
Launcher controls disclose list/grid-relevant sizing without deleting the inactive
mode's saved values. Profile shows greeting preview; custom subtitle editing is
conditional. Clipboard persistence/erase warnings remain adjacent to risky actions,
not buried inside generic advanced disclosure. Avoid converting all resets to one
new confirmation policy without reviewing their existing semantics.

## F. Whole-shell visual plan

### Bar and anchored surfaces

Keep compact pills and continuous workspace chip; tune optical icon weight and
text baseline alignment using existing IconRegistry rather than replacing icons
wholesale. Keep the 28px visual pill and48px reserved strip initially. Align expanded
surface edge, header inset and icon anchors with compact positions. Preserve
right-cluster interpolation6→12px and time/date family anchoring. Long clock/date
formats and left/centre/right collisions on narrow outputs need explicit tests;
there is no demonstrated collision policy in the three independently anchored rows.
Permanent Notification/Clipboard icons remain absent. Schema's legacy notification
bar ID is compatibility data, not an invitation to reintroduce the icon.

### Control Centre, ordering and profile

Keep independent `controlCentre.columns` and `actionColumns` (both1–16) and
ordered entry keys. Primary controls clamp to available output width; action
columns currently clamp to action count, not a minimum touch width. At narrow CC
width and many action columns, cells can become too narrow. Add presentation-only
fit logic for secondary actions while retaining the saved column preference and
independence; do not force actions to match the primary grid.

Preserve distinct primary coloured tiles, secondary actions and two service-driven
sliders. Improve focus/hover and state clarity before adding labels everywhere.
Icon-only primary controls need discoverable tooltips and keyboard-accessible
secondary/detail actions (currently often right-click). Keep unavailable distinct
from OFF, and armed destructive actions distinguishable beyond red alone.

For later drag/drop, render Settings reorder lists from stable `key`, never index
identity. Use a local preview order during drag, insertion indicator and edge
scroll; commit one reordered array through `setEntries(group, entries)` on drop.
Cancel on Escape, lost pointer/session or model-version conflict. Keep explicit
up/down keyboard operations via `moveEntry`. Do not write on every pointer movement,
rebuild the live module registry, reuse one combined list for controls/actions, or
bypass Wi-Fi layout deferral. Drag/drop itself is not part of this audit; the
component boundaries make it a separate reviewable later change.

[ProfileHeader.qml](../../.config/quickshell/magi/plugins/bar/controlcentre/ProfileHeader.qml)
already supports displayName, avatar and time-of-day greeting via
[VisualState.js](../../.config/quickshell/magi/components/controls/VisualState.js).
Greeting ranges are05–12 morning,12–18 afternoon,18–23 evening, otherwise night;
current wording uses sentence case. Desired title-case “Good Morning/Afternoon/
Evening/Night” is a presentation choice, not a new clock service.

Propose a64px circular avatar (72 only if available width permits), name and
stronger greeting, optional third line. Replace fixed58px height with measured
content. Decouple the header view into inputs (`avatarSource`, `displayName`,
`greeting`, optional `secondarySummary`) and signals; a container binds Settings,
AssetManager and a local greeting presenter. Weather later supplies a formatted
summary through that boundary, with availability/error policy outside layout.
No weather service/location/configuration now. Existing `profileAvailable` checks
only configured name/subtitle/avatar, so greeting-only profiles can remain hidden:
make any future change to that visibility an explicit product decision, not an
accidental consequence of larger header styling. Preserve optional section hiding.

### Notifications and network

[NotificationContent.qml](../../.config/quickshell/magi/components/notifications/NotificationContent.qml)
currently adds a22px icon,17px title and close item beneath the Hub selector.
Remove redundant embedded chrome in favour of host-level accessible mode identity;
retain DND and Clear All as concise actions. A compact switch may replace the DND
button visually, but it must use the same QuickActions/server activation contract.
Use app/timestamp metadata together, summary primary, bounded body secondary,
actions tertiary. Grouping can be a presentation proxy keyed by stable record IDs;
do not change server ownership, dismiss semantics, action liveness, unread or expiry.
Empty and server-unavailable states are distinct.

[ToastHost.qml](../../.config/quickshell/magi/components/notifications/ToastHost.qml)
is already top-right at top62/right14 and no reservation. Keep this relationship
to the status strip. If operator chooses a right-aligned Notifications Hub view,
implement a position policy in the **same Hub host**, not a new Notification Centre
window. Clamp to the same output margins and test mode-switch geometry/focus;
current Hub Notifications is centred. This is a proposal requiring visual review.

Toast cards own entry/exit/reflow regions individually. Preserve hover-paused
expiry, exiting cards losing input, union-of-cards mask and fullscreen suppression.
Height changes require checking the outputToastLimit estimate in shell.qml; do not
change notification policy just to fit a new card size.

[WifiMenuContent.qml](../../.config/quickshell/magi/plugins/bar/wifi/WifiMenuContent.qml)
can reduce its repeated title and64px connected card to a compact network summary
with actual hardware-aware toggle. Nearby rows should align signal, SSID, Saved/
Open/Secured/Connecting and errors; avoid colour as the sole connection indicator.
Keep inline [WifiAuthentication.qml](../../.config/quickshell/magi/plugins/bar/wifi/WifiAuthentication.qml)
password masking, sensitive input hints, Enter/Cancel, focus and error space.
Don't simplify layout by dropping auth state or rewriting Network/controller code.

### Hub and launcher boundary

Keep one selector/header family, consistent search inset/height, focus rings,
selection and empty/error messages. Apps and Emoji already share nearly identical
46px search fields; Clipboard has42px and additional header/actions. Preserve
Clipboard stable-ID selection reconciliation, search shortcuts, pins and privacy
copy. Preserve Emoji categories/recent ordering/async copy session invalidation.
Notification mode has no search; do not force a blank search field for symmetry.

Hub F6 selector focus, Tab/Shift+Tab, mode-specific arrows, Escape/outside dismissal,
exclusive focus and bar-reachable input mask remain contracts. Mode size variation
is legitimate; centralize bounds/padding instead of forcing identical content size.
All mode styles should have loading, unavailable and empty-state treatments.

Launcher work now: shared host/search/row states, readable hierarchy, clipping and
system-icon fallback consistency. Preserve list/grid dimensions, existing artwork
options, hidden-app menu/keyboard paths and search/launch semantics. Full compact
Rofi-like vs expanded Launchpad-like art direction belongs to the later dedicated
Launcher/Fraud O.G milestone. [LauncherIcons.qml](../../.config/quickshell/magi/services/LauncherIcons.qml)
already uses `Quickshell.iconPath`; keep it as a system-icon presentation boundary.
No Fraud O.G-specific rendering, icon-theme manager or bespoke lookup layer.

### Calendar, wallpaper and media

[CalendarContent.qml](../../.config/quickshell/magi/components/calendar/CalendarContent.qml)
has selected weekday/date, month navigation, weekday headings, optional ISO week
numbers and six rows. Today gets accent text/outline; selection uses elevated fill;
adjacent dates use muted. Distinguish today, selected and keyboard focus rather than
merging them. Replace y56/94/116 arithmetic with measured header/nav/grid spacing
while preserving32/38 density choices and local date math. CalendarSurface also
has a matching menu-height formula: update the contract together. Keep arrow keys,
PageUp/Down/Home, locale first day, week-year boundaries and absorption of time/date.
No events/providers, schedules or agenda features.

Wallpaper manager retains virtualized GridView, bounded sourceSize/asynchronous
thumbnails, favourites/recents, explicit scope and fit-for-next-selection semantics.
Group library filters separately from monitor/fit controls; current/all-monitor or
mixed-monitor state must remain explicit. Distinguish selected keyboard tile from
currently applied image and favourite. Use consistent masked crop and inset border;
current image is rectangular inside rounded card and caption edges are square.
Offer neutral loading/error placeholder and concise empty action linking Settings;
do not change scanning or random-selection policy. Existing caption scrim is
intentional image legibility, not an excuse for blanket dark-surface conversion.

[MediaSection.qml](../../.config/quickshell/magi/plugins/bar/controlcentre/MediaSection.qml)
already uses RoundedArtwork70px and progress around the border. Inspect native
mask edges at1×/2×/fractional scale before claiming its masking is broken; the
Settings avatar preview is the clear divergent path. Prefer title primary, artist
secondary, capability-disabled playback controls with tooltips/focus and a clean
Nothing playing state. Long metadata should elide with optional tooltip, not force
width growth or continuous marquee. No seek feature is currently implied by the
progress border; do not add it in visual work. Preserve player selection/capability
logic and explicit media section visibility, including accepted stable empty height.

## G. Dark/light theme risk matrix

Most shell colours are already semantic. The main risks are **pairing**, alpha
composition and inherited control palettes, not a broad hard-coded-colour purge.

Calculated examples (opaque registry values; default teal tile uses72% teal +28%
shadeDark, matching default tileBackgroundShade0.28):

| Pair | Mocha | Everforest Dark Hard | Everforest Light Hard | Latte |
| --- | ---: | ---: | ---: | ---: |
| text / background | 11.34 | 8.15 | 5.40 | 7.06 |
| text / accent | 1.24 | 1.18 | 1.92 | 2.51 |
| muted / surface | 5.65 | 3.70 | 2.52 | 3.20 |
| text / default tinted teal tile | 1.79 | 1.97 | 1.56 | 1.71 |

Ratios are diagnostic evidence, not actual operator-setting measurements. Target
normal readable text at4.5:1 and essential control graphics/focus at3:1 where
applicable; large text has different thresholds. Disabled/decorative content must
be assessed separately. Existing palette contrast tests cover text/background and
onColour/raw-accent, not every composed surface/state.

| Component / risk | Severity and future semantic fix | Verification |
| --- | --- | --- |
| ControlTile ON/OFF ink on shaded accent | High, all palettes; pair ink with **actual tinted fill**, not blindly text or onAccent from an untinted colour. Preserve overrides and make default policy changes explicit | All accent roles × all palettes × ON/OFF/unavailable, including operator custom shades |
| SettingsButton pressed fill | High; background becomes accent while inherited button text may remain text. Explicit pressed foreground pair | Pointer-held and keyboard activation in both palette families |
| Tiny muted network/calendar/notification metadata | High in light and some dark themes; essential text should use readable secondary ink rather than muted+opacity | Timestamp/security/adjacent-date contrast at actual sizes |
| IconSlider over both fill and track | Medium/high; one text ink overlays changing surfaces, configurable fill/track may conflict | Min/mid/max values and disabled, all palette families |
| Settings Basic switches/combo popup/spin controls | Medium; parent palette is partial and individual shell consumers override subsets | Popups, selections, disabled labels and keyboard focus in native Qt style |
| Hub selection/focus and thin accent border | Medium on light palettes; use visible selected fill plus independent focus outline | Apps/Emoji/Clipboard with long names, empty results and tab focus |
| Wallpaper caption / Launcher background image | Context-dependent; scrim/onScrim pair for images, no automatic recolouring of artwork. Launcher opacity0.16 still changes effective contrast | Bright/dark/busy images and light palettes |
| RoundedArtwork white mask | Not a palette bug: white is mask alpha, not visible UI ink | Check antialias/alpha edges without replacing mask colour with semantic surface |
| Disabled glyph alpha .4/.45/.55 and secondaryOff .6 | Medium; avoid stacked dimming and OFF/unavailable ambiguity | Composited contrast, fixed-colour SVGs, glyphs and semantic SVGs |
| Hover/pressed/elevated differences | Medium; relative roles differ by palette, no guarantee a small step is perceptible | Everforest Light Hard/Soft and Latte, grayscale/state identification |

Do not add theme-name conditionals, globally darken light themes, recolour artwork,
change icon/cursor themes or restore palette glows. Hyprland border-only ownership
is a permanent regression invariant.

## H. Refactor risk assessment

| Risk class | Examples | Guardrail |
| --- | --- | --- |
| Pure QML styling, low | Text hierarchy, spacing inside existing bounds, semantic labels, section help | Before/after images; wrapping and contrast checks; no service changes |
| Shared component, medium | SettingsRow/SearchField/IconButton, Avatar, token indirection | Preserve signals/properties and explicit preferences; migrate a few consumers first; test pointer + keyboard |
| State/model-sensitive, medium/high | Page registry/disclosure drafts, reorder preview, grouped notifications, adapter row presenter | Stable IDs; single source writer; no stale-index actions; errors/conflicts remain visible |
| High regression | SharedStatusSurface/Calendar geometry and phases, masks, Hub placement/focus, Wi-Fi auth resizing, toast reflow | Native+isolated lifecycle/input tests, unchanged ownership and reservation; one family per commit |
| Out of scope backend | Network, DBus notifications, clipboard capture, wallpaper scanner, theme adapter storage/reload | Do not modify unless separately authorized concrete defect demands it |

The hierarchy is not “all QML is safe”: QML includes focus, IPC, process activation,
password state and output/input-region logic. Review changes by behavioural scope.
No blanket component replacement, regex-driven token rewrite or global schema reset.

## I. Proposed implementation phases and commit boundaries

Recommend **nine implementation/acceptance phases**, after review of this audit.
Most phases can be one bounded commit; a large page conversion may require two.
Expected scale is approximately8–12 commits, not one whole-shell rewrite. Each
phase should remain usable and independently reviewable. Do not implement these
steps in the present read-only phase.

### 1. Visual foundations and reusable primitives

Areas: Theme/RenderTokens facade, proposed VisualTokens/motion constants,
SettingsButton, ClipboardIconButton-derived shared button, SearchField, row/section
scaffolds, RoundedArtwork/Avatar. Preserve existing defaults first; explicitly
separate later default contrast-policy changes from simple token extraction.
Risk: global state colours/radii and focus changes affect many surfaces.
Checks: settings appearance/icons/schema and `tests/visual/state.cjs`; new direct
primitive pointer/keyboard/contrast tests and native artwork-mask snapshots at
multiple scales. Natural commit: **visual tokens and shared control foundations**.

### 2. Settings shell/navigation

Areas: SettingsWindow, SettingsApplication and SettingsWindowState presentation
interface; reusable page container, scrolling grouped navigation, responsive
content widths, consistent save/error footer. Preserve page IDs/deep links.
Risk: focus destruction, lost drafts, blocked navigation at minimum size.
Checks: `tests/settings/window.qml` through its existing runner, store/persistence
checks when touched;720×500,940×720, wide/tall and enlarged-font navigation; all
11 pages reachable, no clipped footer. Natural commit: **Settings shell and navigation**.

### 3. Settings pages and theme target presentation

Areas: all current pages, VisualSettingsGroup; targeted theme target row component,
inline review/details, Zen Copy; CC reorder-row groundwork and conditional fields.
Risk: toggles writing on binding changes, orphaned async confirmations, reset/privacy
semantics, environment-dependent availability. No Theme Orchestrator backend rewrite.
Checks: focused Settings appearance/modules/actions/calendar/launcher/emoji/wallpaper
schema/page tests selected by changed pages; production Theme Orchestrator pointer
and Copy regression; enrollment failures/changed hooks in disposable roots.
Check wallpaper draft navigation and long CC/target rows at narrow width.
Natural commit(s): **Settings page composition**, optionally separate **system theme rows**.

### 4. Bar and shared surface visual integration

Areas: Bar, SharedStatusSurface, ExpandablePlugin/anchored adapters,
MorphingPillContent, TimeDatePill; consume tokens without replacing lifecycle.
Risk: exclusive zone, click-through, close reversal, anchor positions, bar collisions.
Checks: `tests/shared-status-surface/run.py`, calendar bar tests and Settings anchored
layout fixtures; native open/close/reopen/switch/rapid reversal, output changes,
48px reservation and input regions. Ensure no permanent notification/clipboard icon.
Natural commit: **bar and anchored surface visual consistency**.

### 5. Control Centre/profile/network

Areas: ControlCentre naturalHeight/metrics, ProfileHeader, ControlTile/ActionButton,
IconSlider/ValueSlider, WifiMenuContent/Authentication presentation; profile preview.
Risk: variable columns, squeezed actions, auth focus and presentation deferral,
profile/media section height contracts, capability states.
Checks: Settings control/action/catalogue/anchored/Wi-Fi-inline layout fixtures,
media tests and visual-state tests; independent columns1/4/5/8/16 where valid,
empty/enabled sections, long profile name and SSID, unavailable hardware, secure
connection Enter/Cancel/error flow on operator-approved test network. No backend edits.
Natural commit(s): **Control Centre composition**, **profile/network polish** if needed.
Drag/drop may follow as its own small implementation after stable rows; retain
keyboard ordering and review single-write/drop cancellation separately.

### 6. Hub and Notifications

Areas: HubContent/Window positioning policy, mode headers/search/empty states,
NotificationContent/Card/ToastHost; Clipboard/Emoji/Launcher consume shared visuals.
Risk: focus handoffs, persistent content, notification record identity, toast mask
geometry/expiry and embedded close behaviour.
Checks: `tests/hub/run.py` and pointer/fullscreen fixtures as appropriate; focused
notification/clipboard/emoji/launcher presentation tests; app launch context menu,
F6/Tab/search/arrows/Escape, all mode handoffs, DND/Clear All and stale actions.
Native toasts: gaps click through, exiting cards noninteractive, hover pause,
fullscreen suppression; one Hub window. Natural commit: **Hub and notification composition**.

### 7. Calendar, Wallpaper and media finishing

Areas: CalendarContent/Surface measured geometry, WallpaperContent/Tile,
MediaSection and artwork usage. Do not duplicate prior phase's profile refactor.
Risk: grid arithmetic/locale, thumbnail resource usage, scope/current-vs-selected
semantics, progress masks, stable inactive media height.
Checks: calendar math/presentation/bar; wallpaper backend tests only if affected,
otherwise presentation/schema tests; media/asset tests; native leap/year/week cases,
long locale labels, all/per-monitor/mixed wallpaper, favourites/recents/random,
missing image, long artist/title, paused/no-player, fractional-scale artwork.
Natural commit: **calendar wallpaper and media visual consistency**.

### 8. Cross-palette, motion and accessibility regression

Areas: composed state pairs, focus/error rings, text overflow, token consumers and
motion constants; targeted refinements, not another redesign.
Risk: changing shared constants can invalidate lifecycle tests and light-theme ink.
Checks: representative Mocha/Frappé, Everforest Dark Hard/Soft, Everforest Light Hard
and Latte; all ten palettes for numeric contrast; keyboard-only path inventory;
minimum Settings size, long labels, roundness0/1/2, user visual overrides, both icon
rendering kinds. Verify reduced-motion handling only if explicitly included later.
Retest only affected shared-surface/mode tests after fixes; no repeated exhaustive
suite when code has not changed. Natural commit: **visual accessibility and palette regression fixes**.

### 9. Final operator visual acceptance and release checkpoint

Freeze visual scope. Review native screenshots/behaviour per family with a small
state matrix: closed/open/switching, normal/hover/focus/disabled/error, dark/light,
minimum/default width. Verify exactly48px, CC/Calendar separate, one Hub, Wallpaper,
Notifications and Clipboard still work; preserve existing shortcuts and services.
Theme switching must retain accepted borders-only Hyprland and truthful Zen manual
colour guidance. Do not repeat the entire accepted external-app audit unless a
concrete defect appears. Final Git allowlist/diff checks and documentation update
belong to that future authorized implementation, not this report-only phase.
Natural commit: **reviewed visual overhaul acceptance checkpoint** (if docs change).

### Test strategy boundaries

Existing tests provide a strong base but are not visual acceptance by themselves.
Shared-surface tests cover44 lifecycle steps, not real compositor hit-testing.
Settings appearance tests currently assert some exact ink/default metrics; changing
those expectations requires a reviewed visual specification, not weakening tests
to make a redesign pass. Notification tests explicitly check gap masks, exiting
input removal and reflow; preserve them. Hub pointer tests must remain actual
production-component interactions, not service-only calls. Add rendered clipping,
focus and long-label checks where source assertions cannot prove the result.

## J. Scope exclusions and completion criteria

Do not drag these into the visual overhaul:

- Fraud O.G port, icon artwork production or bespoke launcher rendering;
- system icon-theme or cursor-theme management, icon/palette presets;
- lock screen, greeter/display manager, substantial Hyprlock theming;
- Qt/hyprtoolkit integration or changes to deferred adapter scope;
- calendar providers/events, wallpaper-derived palettes or automatic theme schedules;
- weather service/backend/location acquisition (header slot only in this plan);
- network, DBus notification, clipboard capture/history, application search/launch,
  wallpaper scanning, Theme Orchestrator ownership/reload backend rewrites;
- compositor shadow/blur/intensity changes, theme-specific hard-coded fixes;
- permanent notification/clipboard bar icons, separate utility windows, merger of
  Calendar and Control Centre families, reservation or shortcut changes;
- cleanup of operator-local settings, hooks, generated files, unknown prefs or assets.

The future implementation is complete when the shared design vocabulary is used
consistently, Settings is navigable at supported sizes, meaningful actions are
keyboard-accessible with visible focus, dark/light composed states are readable,
artwork respects its actual mask geometry, and the operator accepts each family
without regressions to the protected architecture. No claim that these changes
have been implemented is made by this audit.

## Audit finalization

Only `docs/research/visual-settings-overhaul-audit.md` is created by this phase.
Run final `git status --short` and the requested path-scoped `git diff --check`.
Because Git does not include an untracked file in an ordinary diff, also inspect
this report's trailing whitespace directly. Compare the initial protected-file
hashes/symlink destinations and path set; report any discrepancy rather than
repairing operator state. No staging/commit/push or existing-document edits.
