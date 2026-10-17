# MAGI visual overhaul — Phase 2B operator checkpoint

2026-10-17. Based on `7afd1c6` (`magi: overhaul settings experience`) on `main`.
Native acceptance is complete. The current Bar / Control Centre / Profile / Network
implementation is the accepted Phase 2B baseline. Operator-tuned live Settings remain
local and excluded from the source checkpoint. The sections below retain the
implementation/review history; the exact 7afd1c6 colour restoration and final
typography/gap additions define the final behaviour.
The Phase 1 visual audit and final Phase 2A documentation were consulted. Phase 2A's
accepted Settings composition and drag system remain intact.

## Runtime changes

**Bar.** Defaults already excluded Notifications and Clipboard. The reported
Notifications bug was confirmed: schema accepted its placement, but `Bar.syncPlacement`
filtered it out and `pluginComponents` had no renderer. Both utilities now have an
optional `UtilityPill` using the existing `Hub.toggle(mode)` route. Settings Bar's
Available lane exposes both, and the existing schema accepts Clipboard placement.
Defaults remain unchanged; existing explicit Notifications placements now render.
No extra host, service, notification subscription or permanent icon was introduced.

**Workspaces.** Every active/hover cell inherits the surrounding pill's semantic
radius, replacing the unrelated action radius. First, middle, last and reverse
transitions retain the original colour animation and workspace model.

**Control Centre.** Primary tiles are 68px with 12px gaps; section spacing is 20px.
Profile is unboxed; media is a distinct, quieter 100px region with title above artist,
a useful empty state and 80px artwork. Minimum intended surface width is 300px,
clamped to available output width. Profile/media/slider height arithmetic uses the
same scoped RenderTokens as the child components. Existing scrolling handles tall
configurations. Surface anchors and staged animations are unchanged.

Primary tiles retain configured semantic accents and shade preferences in both
on and off states. Unavailable controls remain distinct.
Component ink uses actual shaded-fill contrast: retain the configured ink when it
has at least 3:1 contrast, otherwise choose the better of palette text/background.
Canonical palette values and saved appearance preferences are unchanged. This is
an icon contrast floor, not a blanket text-accessibility or native-render claim.
Slider icons are directly overlaid without a background chip. Actions have
hover/focus feedback and active toggle marks.
Tiles, actions, sliders, media controls and existing action chips gain local keyboard
activation/focus feedback. Menu key opens tile secondary actions; slider arrows and
Home/End adjust through the existing valueMoved callback.

**Action wrapping.** Saved primary and secondary columns remain independent.
Action columns additionally fit the body width with a 38px minimum cell target;
extra actions produce as many rows as needed. No single-row special case or new
ordering model. Configured data, disabled entries, confirmation and service routing
remain canonical.

**Profile.** The runtime avatar is 76px (previously 42px), using the existing avatar
roundness role with a 10px reference for a rounded square, and RoundedArtwork. Local-hour greeting plus configured display name
occupies line one: Good Morning (05–11), Good Afternoon (12–17), Good Evening
(18–22), Good Night (23–04). A minute timer refreshes local time. No Linux username
lookup. `weatherSummary` is an input boundary for a future verified provider; empty
means “Weather unavailable”, with no fabricated forecast, provider or location.
The existing custom subtitle becomes the optional third line. Empty/disabled text
leaves no hidden layout row. Long name/summary/subtitle text elides within bounds.
The existing opt-in profile availability and section visibility are preserved.

**Artwork.** RoundedArtwork already masked images with MultiEffect and a layered
rounded alpha mask. Its PreserveAspectCrop source now explicitly clips into a layer
before that mask samples it, bounding the source texture and avoiding uncropped
image texture coordinates. The source remains hidden; borders remain styling,
not a clipping workaround. This applies to runtime avatar/media, Settings avatar
preview and Clipboard thumbnails through the shared primitive; Clipboard itself
was not redesigned. Native edge quality is still an operator check, especially
with border width zero, non-square source images and fractional scaling.

**Wi-Fi/Bluetooth.** Both use the same compact semantic toggle, at top-left of the
body under the persistent compact-control header. Wi-Fi removes the repeated title.
Connected cards are 72px; nearby rows are 52px, with larger names and legible
security/state/signal metadata. Wi-Fi retains inline authentication, masked input,
Enter/Cancel/retry and pending-operation observation. Browser height accounts for
the larger rows/header. Empty/scanning states are explicit; scan status reads the
existing device scannerEnabled property. Bluetooth retains paired/bonded connection
semantics, scan action, battery availability and connected-only, 30px icon-only
Bar representation. No Network, Bluetooth or other backend service was changed.

**Dismissal and placement.** Existing Bar catcher and SharedStatusSurface Loader
Escape handler are retained. Native input regions, OnDemand focus, compact-to-open
relationship and exactly 48 logical px reservation are unchanged. First Escape in
password input cancels authentication; ordinary Escape closes the surface. Outside
click closes even during a pending operation, clears secret UI, and leaves the
controller observing its completion without reopening on late failure. Calendar
remains a separate surface family. Hub remains the shared utility host.

## Settings and catalogue audit

No new profile key, schema version, migration or aesthetic setting was needed.
Existing displayName and subtitle/subtitleMode are reused; Profile labels now explain
the optional third line. Bar adds the two optional utility choices. Existing user
values, unknown data and single-writer migration/persistence remain intact.

The existing catalogue has 19 definitions: Wi-Fi, Bluetooth, Low Power, Airplane,
Battery status, Settings, Volume, Brightness, VPN, Do Not Disturb, Caffeine, Lock,
Hibernate, Shutdown, Reboot, Applications, Notifications, Emoji and Clipboard.
Eligibility still distinguishes tiles, sliders, actions and detail views. Apps,
Notifications, Emoji, Clipboard and confirmed Reboot were already implemented.
No genuinely absent action was identified within this bounded phase; no duplicate
catalogue entry or backend action was added.

## Automated validation and limits

Logs: `/tmp/magi-phase2b/`. All listed checks pass:

- `python tests/runtime-visual/run.py`: real Bar/component pointer interactions;
  optional utility defaults/render/toggle/hide through actual Hub routes; workspace
  first/middle/last and reverse transitions at roundness 0/.5/1/2; long profile text,
  greeting cases, third-line visibility and weather fallback; primary columns
  1/4/5/8/16 with independent action columns and width fitting; icon contrast in
  Catppuccin Mocha/Frappé and Everforest Dark Hard/Light Hard; actual outside clicks,
  Escape, password Escape and pending-operation dismissal/late failure.
- `python tests/settings/modules.py control-layout.qml`, `action-layout.qml`,
  `wifi-inline.qml`, `anchored-layout.qml`, `catalogue-layout.qml`, `catalogue`, and
  the default modules fixture: variable composition, retained ownership, Bluetooth
  connected-only behaviour, authentication, Hub routes and persistence.
- `python tests/shared-status-surface/run.py`: unchanged 48-step lifecycle regression.
- `python tests/settings/run.py`: schema/migrations/persistence, including optional
  Notifications/Clipboard placement and absent defaults.
- `python tests/settings/appearance.py`: all ten palettes, semantic shades and live
  preferences. Active-shade assertions now explicitly set active state; off-state
  coverage asserts retained configured accents. Geometry asserts the intended 68px tile.
- `python tests/settings/presentation.py`: existing production Settings pages and
  keyboard interactions across five palettes and both supported window sizes.
- `python tests/settings/media.py` and `node tests/visual/state.cjs`: MPRIS ownership,
  metadata/transport, exact greeting boundaries, workspace model and progress math.
- `git diff --check`: clean.

The new runtime runner stages all files in a temporary directory, isolates HOME/XDG,
reuses existing hardware adapters, and replaces only the native layer wrapper and
Hyprland workspace inputs. It asserts the original reservation expression before
adapting the window. Qt software rendering cannot establish GPU mask quality,
compositor focus restoration, actual radio/auth success or optical alignment.
No automated check is presented as native visual acceptance.

## Protected state

`protected.json` and `protected-after.json` under `/tmp/magi-phase2b/` compare 359
records: live settings.json; all initially dirty/untracked operator t15g integration
records; symlink targets and directory membership; generated Theme Orchestrator
files; and MAGI XDG state. All match. Initial Git status is retained alongside the
snapshot. No generated assets, enrollment, preferences, wallpaper/runtime selection,
notification/clipboard contents or unrelated dotfiles were edited or normalized.

## Native operator review — stop here

Review Catppuccin Mocha, Frappé, Everforest Dark Hard and Everforest Light Hard:

- Closed/open/switch/reverse CC, Wi-Fi and Bluetooth; right-cluster anchoring,
  optical spacing, hover/focus/disabled/active states and exactly 48px reservation.
- Workspace first/middle/last at square/default/rounder settings and live transitions.
- Avatar and album art with portrait/landscape sources, border zero and normal border,
  normal/2×/fractional scale where available; also Settings preview and existing
  Clipboard thumbnails using the same primitive. Look for edge pixels without
  relying on the frame. No Clipboard composition work is authorized here.
- Long display name; absent/present third line; time greeting; honest weather slot;
  long track/artist, playing/paused/unavailable capabilities and media empty state.
- Independent primary/action columns and multiple action rows, including scrolling.
- Wi-Fi toggle, connected header, scan/empty states, known/open/secured network,
  password typing/Enter/cancel/retry and outside/Escape during a pending request.
- Bluetooth enabled/disconnected/connected, scan and known-device actions; no
  persistent device name or disconnected icon in the compact Bar.
- Optional Notifications and Clipboard placement/open/toggle/hide, direct shortcuts,
  normal outside-click consumption and focus recovery to the prior application.

Stop for screenshots and feedback. No Hub, Notification Centre, Launcher, Wallpaper
integration, lock-screen or other later-phase overhaul has begun.

## Exact changed paths

Relative to `linux/magi/`; protected pre-existing changes are excluded.

- `.config/quickshell/magi/components/bar/Bar.qml`
- `.config/quickshell/magi/components/bar/UtilityPill.qml`
- `.config/quickshell/magi/components/controls/ActionChip.qml`
- `.config/quickshell/magi/components/controls/CompactToggle.qml`
- `.config/quickshell/magi/components/controls/IconSlider.qml`
- `.config/quickshell/magi/components/controls/MediaButton.qml`
- `.config/quickshell/magi/components/controls/RoundedArtwork.qml`
- `.config/quickshell/magi/components/controls/VisualState.js`
- `.config/quickshell/magi/components/settings/pages/BarPage.qml`
- `.config/quickshell/magi/components/settings/pages/ProfilePage.qml`
- `.config/quickshell/magi/plugins/bar/bluetooth/Bluetooth.qml`
- `.config/quickshell/magi/plugins/bar/controlcentre/ActionButton.qml`
- `.config/quickshell/magi/plugins/bar/controlcentre/ControlCentre.qml`
- `.config/quickshell/magi/plugins/bar/controlcentre/ControlTile.qml`
- `.config/quickshell/magi/plugins/bar/controlcentre/MediaSection.qml`
- `.config/quickshell/magi/plugins/bar/controlcentre/ProfileHeader.qml`
- `.config/quickshell/magi/plugins/bar/wifi/Wifi.qml`
- `.config/quickshell/magi/plugins/bar/wifi/WifiMenuContent.qml`
- `.config/quickshell/magi/plugins/bar/workspaces/Workspaces.qml`
- `.config/quickshell/magi/settings/SettingsSchema.js`
- `.config/quickshell/magi/theme/RenderTokens.qml`
- `.config/quickshell/magi/theme/Theme.qml`
- `docs/README.md`
- `docs/architecture.md`
- `docs/decisions.md`
- `docs/design/runtime-phase2b.md`
- `docs/quickshell-reference.md`
- `tests/runtime-visual/run.py`
- `tests/runtime-visual/runtime.qml`
- `tests/settings/appearance.qml`
- `tests/settings/modules.py`
- `tests/settings/schema.cjs`
- `tests/visual/state.cjs`


## Native-feedback corrective pass — 2026-10-17

Continues the existing uncommitted Phase 2B tree. Restored the configured accent
fill and rim on every primary tile, including off toggles; focus and availability
feedback, dimensions and settings semantics remain. Runtime avatar and Settings
preview now use the avatar role with a 10px rounded-square reference instead of
half-width circular references. The slider icon backing rectangle is removed;
its existing ink, key handling and value callbacks remain.

RoundedArtwork remains the shared mask primitive. Image/effect/mask now occupy an
inner viewport inset by the clamped frame width; inner radius is outer radius minus
that inset. Thus image pixels do not lie behind the frame's antialiased outer edge.
Border zero still uses an actual rounded mask. The mask now uses threshold 0.5 and
spread 1, smoothing across its full alpha range instead of promoting faint edge
coverage to opaque source pixels. Image source stays hidden, cropped and layered;
frame and progress use the same clamped outer contour. No covering border workaround
or backend/render dependency was added. Native screenshot review remains necessary.

Validation: runtime visual (including new loaded-image contour/source isolation
checks at radii 0/10/20 and frame widths 0/2/6), ten-palette appearance, Settings
presentation, schema/persistence, reorder, dynamic Control Centre, inline Wi-Fi and
48-step shared-surface checks pass. The software fixture verifies mask geometry and
configuration, not native GPU edge quality. Logs and fresh protected/source/status
snapshots are in `/tmp/magi-phase2b-corrective/`.

The fresh baseline preserves native-review changes to settings.json and Settings
backup directory membership since the original Phase 2B snapshot. During this pass the operator confirmed further live Settings edits: settings.json
and backup directory membership changed and were left untouched. The other 357
of 359 snapshot records and all initial Git status entries are unchanged.
No commit, push, staging, shell restart, Hub/Notification Centre redesign, Settings
architecture, drag/reorder, keyboard or networking changes.

Corrective-pass exact paths (relative to `linux/magi/`):

- `.config/quickshell/magi/components/controls/IconSlider.qml`
- `.config/quickshell/magi/components/controls/RoundedArtwork.qml`
- `.config/quickshell/magi/components/settings/pages/ProfilePage.qml`
- `.config/quickshell/magi/plugins/bar/controlcentre/ControlTile.qml`
- `.config/quickshell/magi/plugins/bar/controlcentre/ProfileHeader.qml`
- `tests/runtime-visual/run.py`
- `tests/runtime-visual/runtime.qml`
- `tests/settings/appearance.qml`
- `docs/README.md`
- `docs/architecture.md`
- `docs/decisions.md`
- `docs/quickshell-reference.md`
- `docs/design/runtime-phase2b.md`

Native follow-up: verify configured accents, rounded-square avatar, bare slider
icons, and bright portrait/landscape artwork edges at border zero/default and
normal/fractional scale. Stop for screenshots and operator review.


## Control Centre appearance and pinned preview — 2026-10-17

This pass retains the uncommitted Phase 2B implementation. ControlTile now passes
its configured semantic accent to Theme.primaryIconInk. The icon registry forwards
that colour to semantic SVG tint or fallback glyph; explicitly fixed-colour user
assets retain their existing semantics. Primary on/off role settings now supply
lightness references, rather than replacing the accent hue. A bounded HSL search
keeps the accent hue and finds contrasting ink against the actual shaded tile
(target 3:1); off shade and colour strength alter tone/saturation. Palette role
strings are converted to Qt colours before reading lightness. No palette hex
values change. Tile fill/rim still derive independently from the same accent.

All Control Centre appearance controls have one UI home: **Control Centre →
Appearance**, grouped into Primary tiles, Secondary actions, Sliders, and Profile
and media. Existing CC visual controls moved here from Advanced Appearance, so
they can be tuned beside the preview. Global status-icon and general roundness
controls remain in Appearance. The primary container setting sizes the existing
tile, without adding an icon chip. Slider icons remain bare.

Schema 11 adds validated defaults and preserves existing values/unknown keys:

| Key (under appearance) | Default | Bounds |
| --- | --- | --- |
| visual.primaryIconSize | 32 px | 16–48 |
| visual.primaryContainerSize | 68 px | 60–96 |
| visual.secondaryIconSize | 32 px | 16–36 |
| visual.avatarSize | 76 px | 48–112 |
| roundness.roles.avatar (existing) | null / Master | 0–2 multiplier |
| visual.mediaArtworkSize | 80 px | 48–112 |
| roundness.roles.albumArt | null / Master | 0–2 multiplier |

Artwork uses independent semantic roles at reference radius 10: multiplier 0 is
square, 1 rounded square, 2 rounder, with the usual half-size safety clamp. Even
the smallest supported artwork does not become circular at multiplier 2. The
v10 migration seeds albumArt from an existing action-roundness override to retain
the prior media contour; other new values come from validated defaults. Normal
store auto-save, reload, section reset and migration paths remain canonical.
The local live settings file is never edited as source.

RenderTokens drives tile size, glyphs, secondary cell height, avatar/profile
height and media height. Column fitting and secondary row height adapt to these
values independently. Text remains elided within available layout width. The
existing shared RoundedArtwork correction remains the single masking primitive:
image viewport inset by frame width, hidden/clipped/layered source, inner radius
outer-minus-frame, smooth alpha mask, separate outer frame. This pass exercises
that primitive at variable runtime sizes/roundness and border widths; it does
not claim native pixel-edge quality from software tests.

The existing Preview button opens the actual retained Control Centre through
MenuController. SettingsWindowState owns a temporary preview flag, not a stored
preference. While pinned, Bar removes the full-screen outside-click catcher
from its input region and SharedStatusSurface does not steal Settings focus.
The same production surface keeps its normal anchor, live services and 48px
reservation. The button reads Close preview. Closing it, leaving the CC page,
closing Settings, Escape in the CC, or another menu taking ownership ends the
pin. Normal key/toggle handlers are unchanged. Normal outside dismissal returns
when preview ends. Native compositor focus/input-region behaviour still needs
operator verification.

Validation (all passed):

- `node tests/settings/schema.cjs .config/quickshell/magi/settings` — v0–11 migration, bounds/defaults, preservation and independent artwork roles.
- `python tests/runtime-visual/run.py appearance.qml` — real Settings preview interaction, four accent colours in on/off states across Mocha/Everforest Dark/Light, size extremes, three secondary rows, mask bounds, reset/reload and preview lifecycle.
- `python tests/runtime-visual/run.py` — runtime visual/profile/workspace/optional Bar modules, artwork geometry and transient dismissal.
- `python tests/settings/appearance.py` — all ten palettes and live appearance.
- `python tests/settings/presentation.py` — all Settings pages, keyboard/Escape precedence, reset and drafts.
- `python tests/settings/run.py` — schema/store persistence, migrations and fallback scenarios.
- `python tests/shared-status-surface/run.py` — 48 lifecycle steps.
- `python tests/settings/reorder.py` — production drag/keyboard/cancel/scroll/metadata/persistence.
- `python tests/settings/modules.py control-layout.qml` — dynamic primary layout.
- `python tests/settings/modules.py action-layout.qml` — secondary layout.
- `python tests/settings/modules.py wifi-inline.qml` — authentication, retry, secret clearing, late callbacks and geometry.
- `python tests/settings/media.py` — MPRIS metadata/selection/actions.
- `git diff --check` — clean.

Fresh snapshots/logs are in `/tmp/magi-phase2b-appearance/`. All **378 protected
records** match the beginning of this pass, including live settings, Settings
backup files/membership, Theme Orchestrator state/integrations, Hypridle/Hyprlock
and Yazi. All initial Git status entries are retained unchanged. Previous
operator edits are preserved as the baseline, not restored to older snapshots.

Exact paths changed in this appearance pass, relative to `linux/magi/` (earlier
Phase 2B changes remain in the working tree):

- `.config/quickshell/magi/components/bar/Bar.qml`
- `.config/quickshell/magi/components/bar/SharedStatusSurface.qml`
- `.config/quickshell/magi/components/settings/pages/AppearancePage.qml`
- `.config/quickshell/magi/components/settings/pages/ControlCentrePage.qml`
- `.config/quickshell/magi/plugins/bar/controlcentre/ActionButton.qml`
- `.config/quickshell/magi/plugins/bar/controlcentre/ControlCentre.qml`
- `.config/quickshell/magi/plugins/bar/controlcentre/ControlTile.qml`
- `.config/quickshell/magi/plugins/bar/controlcentre/MediaSection.qml`
- `.config/quickshell/magi/plugins/bar/controlcentre/ProfileHeader.qml`
- `.config/quickshell/magi/services/SettingsWindowState.qml`
- `.config/quickshell/magi/settings/SettingsMigrations.js`
- `.config/quickshell/magi/settings/SettingsSchema.js`
- `.config/quickshell/magi/theme/RenderTokens.qml`
- `.config/quickshell/magi/theme/Theme.qml`
- `docs/README.md`
- `docs/architecture.md`
- `docs/decisions.md`
- `docs/design/runtime-phase2b.md`
- `docs/quickshell-reference.md`
- `tests/runtime-visual/appearance.qml`
- `tests/runtime-visual/run.py`
- `tests/settings/run.py`
- `tests/settings/schema.cjs`
- `tests/settings/store.qml`

Native checkpoint: review Mocha plus another Catppuccin variant, Everforest Dark
and Everforest Light; verify accent recognition, Settings preview pointer/focus
behaviour and unchanged anchoring; inspect avatar/album-art edges with bright
portrait/landscape images at minimum/default/maximum sizes, roundness and borders,
including fractional scale. Confirm long text, nothing-playing layout and bare
slider icons. No shell restart, commit, push, staging or subsequent roadmap work.
Stop here for screenshots and operator feedback.


## Settings-session live tuning correction — 2026-10-17

This supersedes the contrast-search and page-scoped preview behaviour above.
No accepted size, roundness, mask, tile or slider controls were removed.

Production colour path: configured control accent → ControlTile.activeColor →
Theme.primaryIconInk → Icon.color → semantic SVG tint / glyph ink. Explicitly
fixed-colour custom assets retain their established asset semantics. The previous
3:1 contrast search preserved hue but snapped different tone/shade settings to
the same lightness boundary. It is removed only from primary icon tuning.
Generic legibleInk and other component colour paths remain untouched.

The retained transformation uses the configured accent hue, saturation scaled by
`0.5 + 0.5 * strength` (on strength 1; off strength controlOffOpacity), and
lightness `0.65 * accent lightness + 0.35 * reference lightness`, minus
`0.35 * controlOffShade` for off state. Lightness is bounded to 0.08–0.92.
Thus shade/tone/strength tune the same accent; tile fill/rim settings cannot
override icon ink. Manual choices are not forced through a contrast fallback.
Native contrast/appearance is intentionally operator-tuned in the live preview.

History inspected: `7afd1c6`, committed pre-Phase-2B Theme.qml stateColor/stateInk
and ControlTile. Those implementations selected generic role ink, not an
accent-preserving transform. No historical accent algorithm is claimed recovered.
This correction preserves the existing uncommitted tone/shade/strength model and
fixes its contrast-search interference. No new On/Off colour selector model.

Schema 11 remains unchanged: no experimental keys were found to remove. Final
CC appearance keys and defaults (under `appearance.visual`) are:

| Key | Default | Validation |
| --- | --- | --- |
| primaryIconSize | 32 | 16–48 px |
| primaryContainerSize | 68 | 60–96 px |
| tileBackgroundShade | 0.28 | −1–1 |
| tileBorderShade | 0.48 | −1–1 |
| tileBorderWidth | 4 | 0–6 px |
| controlOffShade | 0 | −1–1 |
| controlOffOpacity (Off colour strength) | 0.28 | 0–1 |
| controlOn (On tone reference) | text | semantic role |
| controlOff (Off tone reference) | background | semantic role |
| secondaryIconSize | 32 | 16–36 px |
| secondaryOn / secondaryOff | text / overlay | semantic role |
| secondaryOffShade / secondaryOffOpacity | 0 / 0.6 | −1–1 / 0–1 |
| avatarSize / mediaArtworkSize | 76 / 80 | 48–112 px |
| avatarBorderWidth | 2 | 0–5 px |
| sliderTrack / sliderFill / sliderBorder | elevated / overlay / lavender | semantic role |
| sliderBorderWidth | 2 | 0–5 px |

`appearance.roundness.roles.avatar` and `.albumArt` remain independent null
(Master) or 0–2 semantic multipliers; reference radius 10 gives rounded-square
defaults. All these controls retain one canonical UI home in Control Centre →
Appearance. Global statusIconSize remains in Appearance. The v10→11 migration,
validation, reset and auto-save architecture are unchanged. No live settings
file was manually rewritten.

SettingsWindowState remains the narrow session owner. Page changes no longer
clear the pin; opening/focusing an already active Settings session preserves it.
A compact footer button, “CC preview active · Close”, appears across all pages.
The original Control Centre Preview button still opens/toggles the real surface.
Closing either preview affordance, closing Settings, Escape/toggle closing the
CC, incompatible MenuController ownership, or process/session end clears it.
No page, dropdown, edit, or Settings focus event clears it. Bar anchoring, input
region handling, 48px reservation and normal transient dismissal are unchanged.
Shared RoundedArtwork, direct slider icons, networking and drag/reorder code
are untouched in this pass.

Validation: all passed.

- `python tests/runtime-visual/run.py appearance.qml`: actual production icons retain four hues on/off in Mocha, Everforest Dark and Everforest Light; each tone/shade/strength control changes ink; tile/icon independence; geometry extremes and masking bounds; every Settings page visited with preview pinned; live profile typing; global close; Settings close; Escape; incompatible ownership and normal dismissal restored.
- `python tests/runtime-visual/run.py`: runtime visual, masks, workspace/profile, optional utilities and transient dismissal.
- `python tests/settings/appearance.py`: ten palettes/live settings; obsolete generic-primary-ink expectations replaced with accent expectations.
- `python tests/settings/presentation.py`: Settings pages, dropdown/dialog/Escape precedence, reset/drafts.
- `node tests/settings/schema.cjs .config/quickshell/magi/settings` and `python tests/settings/run.py`: schema/migration/bounds/reset/store/persistence.
- `python tests/settings/modules.py control-layout.qml` and `action-layout.qml`: independent columns/wrapping.
- `python tests/settings/media.py`: MPRIS.
- `python tests/shared-status-surface/run.py`: 48 steps.
- `python tests/settings/modules.py wifi-inline.qml`: inline authentication and pending operations.
- `python tests/settings/reorder.py`: existing drag/reorder/cancel behaviour.
- `git diff --check`: clean.

The runtime fixture allows only the established offscreen missing-Hyprland-socket
warning additionally encountered when visiting all Settings pages, matching the
existing Settings presentation harness. All other unexpected warnings/errors fail.

All **389 protected records** match the fresh start-of-pass snapshot, including
current operator settings and backup history, orchestration integrations/state,
Hypridle/Hyprlock and Yazi. All initial Git status entries remain unchanged.
Snapshots, exact path list and test logs: `/tmp/magi-phase2b-live-tuning/`.

Exact paths changed in this pass, relative to `linux/magi/`:

- `.config/quickshell/magi/components/settings/SettingsWindow.qml`
- `.config/quickshell/magi/plugins/bar/controlcentre/ControlTile.qml`
- `.config/quickshell/magi/services/SettingsWindowState.qml`
- `.config/quickshell/magi/theme/Theme.qml`
- `docs/README.md`
- `docs/architecture.md`
- `docs/decisions.md`
- `docs/design/runtime-phase2b.md`
- `docs/quickshell-reference.md`
- `tests/runtime-visual/appearance.qml`
- `tests/runtime-visual/run.py`
- `tests/runtime-visual/runtime.qml`
- `tests/settings/appearance.qml`

Native review still required: tune the four accents and on/off references/shade/
strength across Mocha, another Catppuccin variant, Everforest Dark/Light; confirm
preview remains anchored and interactive alongside Settings across pages,
dropdowns and focus changes; inspect unchanged artwork edges at multiple sizes/
roundness/borders and fractional scale; confirm bare slider icons. Automated
geometry/colour tests do not establish native clipping quality or visual contrast.
No commit, push, staging, restart or next-phase work. Stop for operator review.


## Exact 7afd1c6 colour restoration — 2026-10-17

This supersedes every earlier Phase 2B primary-colour interpretation above.
The operator selected committed `7afd1c6` as the canonical rendering function,
not an accent-derived approximation. No default values were changed.

Exact reference files were read using `git show 7afd1c6:linux/magi/<path>` and
directly diffed: ControlTile.qml, Theme.qml, RenderTokens.qml, VisualState.js,
AppearancePage.qml, SettingsSchema.js, SettingsStore.qml, Icon.qml, IconRegistry.qml
and ThemeRegistry.qml. Reference copies/diffs are retained in
`/tmp/magi-phase2b-colour-restore/`. No web research.

Source-level findings and restoration:

- Tile fill/rim already matched the reference: `primaryTileColor(activeColor)`
  and `primaryTileRim(activeColor)` use the configured accent and signed palette
  shade. Their settings and defaults were unchanged. Phase 2B's focus-coloured
  rim and whole-tile unavailable opacity were additional colour differences;
  restore the canonical rim and default whole-tile opacity. Keyboard handling,
  accessibility and tooltips remain.
- Primary icon rendering had changed from `controlInk(toggle, active, available,
  false)` to `primaryIconInk(activeColor, active)` with HSL processing. That changed
  reference roles into lightness-only inputs, Off shade into a lightness offset,
  and Off strength from alpha into saturation. It also lost the old unavailable
  state selection. Earlier contrast search/fallback experiments compounded the
  mismatch; none remain in the primary tile path.
- Restore `ControlTile → controlInk → stateInk → stateColor → Icon.color` exactly.
  Available on/non-toggle controls use the selected ON semantic role. Off or
  unavailable controls use the OFF semantic role, signed `shadeAccent`, then
  `Qt.alpha(..., controlOffOpacity)`. The configured accent owns the tile fill/rim;
  the icon uses the selected semantic role exactly as the old implementation did.
- Remove the experimental `primaryIconInk` helper entirely. Keep `legibleInk`
  and contrast utilities used by other components. Icon.qml and its registry/data
  are byte-identical to the reference: glyph colour and semantic SVG tint/alpha
  therefore receive the same resolved values.

The existing UI labels remain unchanged, including On/Off tone reference and Off
colour strength; their underlying `controlOn`, `controlOff`, `controlOffShade`,
`controlOffOpacity` keys now execute the old semantics. The helper description
now states role selection, shade and opacity accurately. No schema/store keys,
migration, validation, defaults or operator values changed. Schema 11 retains all
accepted sizes and independent artwork roundness. There were no experimental
colour-only keys to delete.

All accepted non-colour work remains: geometry, layout, profile greeting/weather/
optional line, inset artwork masking, bare sliders, columns/wrapping, utility Bar
modules, workspace geometry and network presentation. SettingsWindowState still
owns the session-wide preview with the global close affordance; no preview
lifecycle or dismissal code changed.

`tests/runtime-visual/colours.qml` compares current production ControlTile with
the exact old tile and Theme/RenderTokens/ThemeRegistry/palette sources loaded
from Git into the isolated test directory. Only reference import locations are
relocated to share identical current Settings inputs. The test asserts that the
shared Icon/registry source is byte-identical to the old implementation. No
expected colour algorithm is reimplemented by the test. Exact channel-by-channel
RGBA, rim, fill, border width, opacity and icon resolution match in **600 pairs**:
four requested accents × three palettes × two icon packs × five setting sets ×
five active/toggle/availability states. Focus-rim equivalence and independent new
size controls also pass. Rejected hue-preservation assertions were removed from
the runtime/preview suite, and reference state-role/alpha assertions restored in
the palette suite.

Validation, all passed:

- `python tests/runtime-visual/run.py colours.qml` — exact 7afd1c6 equivalence, 600 production pairs.
- `python tests/runtime-visual/run.py` — runtime visual/profile/workspace/artwork/dismissal.
- `python tests/runtime-visual/run.py appearance.qml` — accepted geometry and Settings-wide production preview, live updates and cleanup.
- `python tests/settings/appearance.py` — ten palettes and restored state-role/alpha semantics.
- `python tests/shared-status-surface/run.py` — 48 steps.
- `git diff --check` — clean.

Schema/store files and keys were not changed, so their suites were not rerun.
No unrelated broad suites were run. Logs and start-of-pass snapshots are in
`/tmp/magi-phase2b-colour-restore/`.

Protected comparison: 424 records snapshotted; 422 unchanged. Live settings.json
and Settings backup-directory membership changed concurrently and were left
untouched; operator attribution was requested. Existing backup file hashes,
Theme Orchestrator integrations/state, Hypridle/Hyprlock, Yazi and all initial Git
status entries match. No earlier state was restored.

Exact agent-changed paths for this restoration (relative to `linux/magi/`):

- `.config/quickshell/magi/components/settings/pages/ControlCentrePage.qml`
- `.config/quickshell/magi/plugins/bar/controlcentre/ControlTile.qml`
- `.config/quickshell/magi/theme/Theme.qml`
- `docs/README.md`
- `docs/architecture.md`
- `docs/decisions.md`
- `docs/design/runtime-phase2b.md`
- `docs/quickshell-reference.md`
- `tests/runtime-visual/appearance.qml`
- `tests/runtime-visual/colours.qml`
- `tests/runtime-visual/run.py`
- `tests/runtime-visual/runtime.qml`
- `tests/settings/appearance.qml`

Native checkpoint: use current live values with the familiar controls and pinned
preview to compare the restored result; inspect artwork edges, geometry and
compositor focus as before. Exact resolved-colour equivalence does not claim
native screenshot/pixel-edge equivalence across different geometry or GPU paths.
No commit, push, staging, shell restart or other feature work.


## Final profile typography and section-gap tuning — 2026-10-17

Additions stay within Schema 11 and Control Centre → Appearance. No colour,
preview lifecycle, backend or unrelated roadmap changes. Defaults reproduce the
pre-addition runtime geometry and typography. New integer settings under
`appearance.visual`:

| Key | Default | Range | Production target |
| --- | --- | --- | --- |
| profileGreetingSize | 16 | 12–24 px | profileGreeting.font.pixelSize |
| profileWeatherSize | 12 | 10–20 px | profileWeather.font.pixelSize |
| profileThirdLineSize | 11 | 10–20 px | profileThirdLine.font.pixelSize |
| profileControlsGap | 20 | 0–48 px | gap after visible Profile |
| controlsSlidersGap | 20 | 0–48 px | gap after visible Primary controls |
| slidersActionsGap | 20 | 0–48 px | gap after visible Sliders |
| actionsMediaGap | 20 | 0–48 px | gap after visible Secondary actions |

Settings groups: **Profile typography** and **Section spacing**. Existing groups,
labels and all accepted controls stay intact. Existing schema default-fill handles
both committed v10→v11 migration and missing keys in uncommitted v11 settings.
Validation rejects fractions and out-of-range values for these seven keys.
Existing appearance/page reset and SettingsStore persistence paths apply.

SectionLayout.js owns a single arrangement rule: consecutive visible sections
receive the outgoing gap of the preceding visible section. A hidden section
contributes neither height nor gap. There is no leading/trailing gap and skipped
sections never sum gaps. For example, Primary→Secondary with Sliders hidden uses
controlsSlidersGap once; Sliders→Media with Secondary hidden uses slidersActionsGap
once. With Profile hidden, profileControlsGap contributes nothing. The final
visible section contributes no outgoing gap.

The production content Item uses the helper's section positions and total height,
so surface height and actual content share one calculation. Grid/slider/media
internal padding and outer surface margins are unchanged. ProfileHeader measures
its text-column implicit height and uses the larger of that or the existing
profile/avatar minimum. ControlCentre follows the measured profile height. Text
remains vertically centred, single-line/elided, and the optional third line
collapses when absent. The existing MAGI font family is unchanged.

Production preview coverage exercises the seven actual Settings sliders, three
independent font properties, font extrema, 96 gap/section visibility combinations
(all 32 masks at zero/max/distinct gaps), variable columns and secondary rows,
profile bounds and third-line visibility, actual content/surface height, and
existing cross-page pin/close/ownership behaviour. Schema and store coverage
adds integer rejection, migration defaults, persistence/reload and reset.

Validation, all passed:

- `node tests/settings/schema.cjs .config/quickshell/magi/settings` — migration defaults and validated integer ranges.
- `python tests/runtime-visual/run.py appearance.qml` — new live typography/gaps, 96 visibility combinations, profile bounds and existing pinned-preview lifecycle.
- `python tests/runtime-visual/run.py colours.qml` — 600 exact old/current colour pairs; restored architecture unchanged.
- `python tests/runtime-visual/run.py` — runtime visual/profile/artwork/dismissal.
- `python tests/settings/appearance.py` — ten palettes and live appearance.
- `python tests/settings/presentation.py` — Settings presentation/keyboard/reset.
- `python tests/settings/run.py` — store/schema/persistence/reset.
- `python tests/settings/modules.py control-layout.qml` — dynamic Control Centre geometry.
- `python tests/settings/media.py` — MPRIS metadata/selection/actions; media layout is also exercised in production preview.
- `python tests/shared-status-surface/run.py` — 48 lifecycle steps.
- `git diff --check` — clean.

Protected state: all **473 records** match the fresh start-of-pass snapshot.
Operator-tuned live settings, backup history/membership, Theme Orchestrator,
Hypridle/Hyprlock and Yazi remain intact. All initial Git status entries remain
unchanged. Logs/snapshots: `/tmp/magi-phase2b-type-spacing/`.

Exact paths changed in this addition, relative to `linux/magi/`:

- `.config/quickshell/magi/components/settings/pages/ControlCentrePage.qml`
- `.config/quickshell/magi/plugins/bar/controlcentre/ControlCentre.qml`
- `.config/quickshell/magi/plugins/bar/controlcentre/ProfileHeader.qml`
- `.config/quickshell/magi/plugins/bar/controlcentre/SectionLayout.js`
- `.config/quickshell/magi/settings/SettingsSchema.js`
- `.config/quickshell/magi/theme/RenderTokens.qml`
- `docs/README.md`
- `docs/architecture.md`
- `docs/decisions.md`
- `docs/design/runtime-phase2b.md`
- `docs/quickshell-reference.md`
- `tests/runtime-visual/appearance.qml`
- `tests/settings/schema.cjs`
- `tests/settings/store.qml`

Stopped for native typography/spacing review: tune the seven controls in the
pinned surface, check long names and optional-line collapse at narrow width, and
confirm the hidden-section gap rule feels appropriate. Native screenshots remain
the authority for visual alignment/font appearance. No commit, push, staging,
shell restart or MAGI Hub work.


## Native acceptance and source checkpoint

The operator accepted Phase 2B and authorized finalization with commit subject
`magi: overhaul bar and control centre surfaces`. The complete source allowlist is
the union of the explicit changed-path lists above: 44 paths. Live settings.json,
application integrations, Hypridle/Hyprlock, Yazi flavour and all backup/runtime
state are excluded and remain unstaged. No additional runtime or schema changes
were made during finalization. Restored pre-Phase-2B colours, Settings-session
preview, Schema 11 and profile typography/section-gap controls are included.
MAGI Hub and other roadmap work have not begun.
