# MAGI Phase 2E.1 — final native-feedback checkpoint

> Native acceptance is complete for the cumulative Phase 2E milestone, including
> live weather, all eight shortcuts and Everforest Light Hard. The finalization
> [checkpoint and exact allowlist](runtime-phase2e-finalization.md) supersede pending
> review/uncommitted wording retained below as implementation history. Rofi is absent;
> no package removal remains outstanding.

2026-10-17. This pass continues the **uncommitted Phase 2E tree**, based on
`b77e449f52603e74c1b9e1c1c3260cf4a251dc3b`. No reset/restart from HEAD, commit,
push or next roadmap milestone. This checkpoint supersedes Phase 2E's selected dots,
Hub outside-dismissal, fixed card floors and legacy-tool retention decisions.

## Hub lifecycle and selector

Hub has no desktop click catcher. Its input mask is the union of active content and
selector, so normal desktop/application clicks pass through without dismissing it.
A child popup temporarily owns its normal overlay, including areas beyond the content;
outside clicks dismiss the popup, not Hub. Pinned Control Centre remains separately
reachable. OnDemand layer keyboard eligibility allows ordinary applications to take
focus; no focus-loss handler closes Hub. Escape still bubbles after child popup,
dialog, text edit and drag handling. Explicit same-mode toggle/close, incompatible
MAGI ownership and teardown remain close paths. No special Super+Q handling exists.
The ordinary Hyprland application window-close binding is unchanged.

Fullscreen temporarily suppresses presentation while retaining the open session, rather
than losing it on application focus/fullscreen changes. Explicit toggle can still close
that retained session. Existing notification-toast and anchored Calendar suppression
remain independent. Direct-launch keyboard eligibility is compositor-mediated and needs
native confirmation; offscreen item focus alone cannot certify it.

Hub selection is now icon accent only: no dot and no persistent selected background.
Inactive icons use subtext; temporary hover/press and keyboard outline stay independent.
Above/below, percentage anchor, semantic selector radius, retained modes, measured
Clipboard/Notifications, and 48px shell reservation remain unchanged.

## Settings composition and controls

The left sidebar is an inset rounded `elevated` panel inside the main `surface`.
Every top-level entry has an existing MAGI icon role; profile/calendar fallbacks were
added to the canonical Legacy registry (default pack can inherit them). Selected icon
and label use accent, with no dot/fill. Appearance's Theme/Surfaces/Bar/Control Centre/Hub
level instead uses a compact selected `elevated` pill and accent text. Legacy routes
still select the retained canonical pages; Bar/CC pages were not copied.

SettingsSelector now has an elevated background, quiet outline, hover surface and focus
state. Selected value plus optional swatch is centred in the available text area;
the chevron stays right-aligned. An explicit leftAligned opt-out is available for future
path-based selectors; current path inputs are text fields, not centred dropdowns.
Palette-role lists automatically show a current-theme swatch and semantic role name.
The swatch updates with Theme roles, not stored hex values. SettingsNumber remains a
single background with integrated minus/value/plus hit areas, now visibly outlined.
Disabled state, editing and keyboard input retain existing semantics.

Save status moved from the full-width main footer into a compact rounded surface at
the sidebar bottom. Saved is quiet; pending writes read “Saving…”; actual errors are
red, bounded to three lines with full tooltip text and the existing reload action.
Navigation scrolls independently above it. The Settings-global real CC preview close
control remains in this sidebar area, not a redundant Settings close button.

All collapsible Settings headers now put the chevron after the title. Substantial CC
sections use the same keyboard-accessible disclosure: Appearance, Profile and playback,
Layout, Visible sections, Primary controls, Sliders, Secondary actions. Existing
Appearance disclosure remains initially collapsed; other major groups initially open.
These transient UI states do not write runtime section visibility or persisted collapse
keys. The responsive horizontal role groups and Track/Progress/Outline labels remain.

## Profile, Media and Clipboard cards

Profile height is `max(avatarSize, naturalTextStackHeight) + 2 * contentPadding`.
The background uses 10px balanced padding when enabled; otherwise no background inset.
Greeting/weather/optional third line form one natural-height stack, vertically centred
against the avatar. The avatar centres when the text stack is taller. No fixed 84px
floor is used by ProfileHeader. Operator font sizes, avatar radius and section gaps stay.

Media height is `max(artworkSize, naturalMetadataAndTransportHeight) + 20`.
The right stack is natural-height, vertically centred and horizontally left-aligned;
there is no expanding spacer. Hidden/empty transport reduces measured height naturally.
ControlCentre now observes both production card implicit heights for its section layout,
so its scroll/outer geometry follows the same measurements. MPRIS actions, availability,
Always/active/Hidden semantics, artwork masking and truncation remain unchanged.

Clipboard delegates use the existing SurfaceBorder primitive with the shared card style.
Appearance → Surfaces exposes Clipboard card borders alongside toast/history enables.
The single additional Schema 12 key is `appearance.notificationBorders.clipboard`,
boolean, default true; it shares existing role/width. Disabling gives actual width zero
without moving content. Selection stays visible through the existing row surface state;
image masking remains independent. No new schema bump or unused experimental setting.

## Final binding audit

Super+S had no active conflict in the represented Hyprland/MAGI/utility bindings before
mutation. The static test checks each desired chord is unique, including non-exec bind
owners, and validates Lua syntax. No compositor reload or native dispatch was performed.

| Chord | Route |
| --- | --- |
| Super+Space | `hub toggle apps` |
| Super+N | `hub toggle notifications` |
| Super+C | `hub toggle clipboard` |
| Super+E | `hub toggle emoji` |
| Super+M | `magi toggle controlcentre` |
| Super+W | `magi toggle wifi` |
| Super+B | `magi toggle bluetooth` |
| Super+S | `hub open settings` |

Super+S opens/switches directly to the same Settings instance and keeps the selected page.
It intentionally does not toggle Settings closed. MFTrunk's Super+Ctrl+C and Rofi's
Super+Ctrl+Space are removed. No obsolete Super+Period/Super+Shift+V MAGI mappings remain.
The existing Theme Orchestrator integration suffix is byte-for-byte preserved.
`phase2e-keybindings.patch` now records the cumulative intended patch from the original
Phase 2E snapshot. Never stage the whole dirty Hyprland file.

## MFTrunk and Rofi retirement

Ownership audit: MFTrunk was only the repository-stowed script/assets, with no owning
pacman package. Removed 44 tracked files: the script and frame-0000.txt through
frame-0042.txt. No other active config/autostart references were found. Its two exact
verified symlinks were unlinked:

- `/home/jkebwdn/.local/bin/mftrunk`
- `/home/jkebwdn/.local/bin/mftrunk-assets`

Rofi config ownership was repository-stowed. Removed its two tracked files:
`linux/t15g/rofi/.config/rofi/config.rasi` and `themes/S14T15G.rasi` beneath that directory.
The exact `/home/jkebwdn/.config/rofi` symlink was unlinked. The theme's sole dedicated
header `/home/jkebwdn/Theme Resources/S14T15G/WofiHeader-rofi.png` had no remaining active
config reference; it was archived then removed. No MAGI/shared artwork was deleted.
All retired tracked files and deployed-link metadata/header backup are under
`/tmp/magi-phase2e1/retired` and `/tmp/magi-phase2e1/deployed` respectively.

Package audit: exact installed package **rofi 2.0.0-1**, explicitly installed;
Required By: None, Optional For: None; no running rofi process found. Approved attempt
`sudo -n pacman -R --noconfirm rofi` stopped because sudo requires a password.
**The package remains installed.** The only outstanding operator command is:

```sh
sudo pacman -R rofi
```

This removes only the exact package, without dependency/orphan cleanup or `-Rdd`.
No MFTrunk package command is needed. Repository-wide case-insensitive searches now
find only historical retirement/research notes, the removal patch and negative tests;
there are no active runtime/config invocations. Current READMEs describe MAGI Apps.
Earlier research/checkpoints explicitly mark legacy-tool references as historical.

## Focused verification

Passing production/isolated checks:

- Settings schema/store, migration/persistence/reset; Clipboard border boolean validation.
- Settings presentation across themes/minimum/default sizes; keyboard selectors and steps.
- New feedback fixture: semantic sidebar/selected navigation, submenu pills, swatches on
  theme changes, balanced values/fixed chevrons, saved/pending/error display, independent
  sidebar status geometry, disclosure keyboard state without runtime-section mutation.
- Profile min/max avatar and typography, third line on/off, background on/off; Media
  min/max artwork, empty/active, all transport modes and long metadata; natural heights,
  balanced insets and vertical centring in three palettes.
- Hub routing, retained instances, selector input/anchor, outside persistence, application
  focus transfer, explicit Escape, child Escape, temporary popup input region and pinned
  preview. Settings direct open/switch uses the same host/page state.
- Clipboard presentation/backend isolation, measured heights/bottom search, shared border
  enable/width/role/geometry in dark/light; thumbnail mask checks retained.
- Notification toast/history presentation and retained controlled retention checks.
- MPRIS service/actions; runtime artwork/secondary surfaces; CC preview and 96 gap/hidden
  section combinations; Bar/CC drag/reorder/cancel/persistence.
- Theme Orchestrator pointer confirmation/cancel/error/ownership safety and exact Zen Copy.
- Launcher discovery/search/list/grid/hidden/restore and real GIO Ghostty adapter preserving
  arguments, field codes and working directory, without Rofi executable/assets.
- Shared-status 48-step lifecycle and exact primary-colour oracle (600 RGBA pairs).
- Icon registry fallback/tint/precedence; eight binding routes/absence of retired commands;
  `luac -p`; `git diff --check`.

Logs: `/tmp/magi-phase2e1/*.log`. Offscreen tests do not establish native Wayland focus,
GPU mask edges, compositor dispatch or physical animation quality. Live network auth
and anchored-surface dismissal retain their existing ownership; native review remains.

## Protected-state comparison

Start snapshot: `/tmp/magi-phase2e1/snapshot.json` and `files/`, 594 records including
all current dirty source and protected machine/runtime state. Retired files were separately
archived before deletion. Current live settings were never manually rewritten or staged.
Protected comparison shows only the intended Hyprland keybind hunks and a concurrent
addition of the Calendar settings group, concurrent profile-font/controls-to-sliders-gap
tuning, and backup-directory membership changes. Existing backup files and the current
operator visual values are preserved; Theme Orchestrator integrations,
Hypridle, Hyprlock and Yazi flavour match.
No staged paths, commits or pushes. Runtime settings remain excluded from source allowlists.

## Native review still required

Confirm that desktop/other-app clicks pass through while every Hub mode stays open;
first keyboard focus after a direct shortcut and focus return after using another app;
Escape versus child dropdown/dialog/drag; extended popup input; pinned CC usability;
Super+S switching and all eight native shortcuts; sidebar distinction and compact status;
role swatches/selector balance/steppers; internal Appearance pills and disclosure layout;
Profile/Media natural heights/centres at operator tuning; Clipboard border states and
image edges; light/dark contrast; unchanged anchored outside dismissal and 48px reservation.
Package removal above is the only outstanding system cleanup. Stop for screenshots and
operator feedback; do not begin another milestone.

## Exact Phase 2E.1 changed paths

Paths below are changes since the uncommitted Phase 2E snapshot, including the 46 tracked
legacy-file deletions. Protected `settings.json` and unrelated local changes are excluded.
The Hyprland path means only the isolated keybind hunks. A separate cumulative list follows
for eventual finalization; neither list is an instruction to stage protected whole files.

<!-- feedback-paths -->

```text
README.md
linux/magi/.config/quickshell/magi/components/clipboard/ClipboardContent.qml
linux/magi/.config/quickshell/magi/components/hub/HubContent.qml
linux/magi/.config/quickshell/magi/components/hub/HubWindow.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsContent.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsNavigationItem.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsNumber.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsSection.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsSelector.qml
linux/magi/.config/quickshell/magi/components/settings/pages/AppearancePage.qml
linux/magi/.config/quickshell/magi/components/settings/pages/ControlCentrePage.qml
linux/magi/.config/quickshell/magi/components/settings/pages/SurfacesPage.qml
linux/magi/.config/quickshell/magi/icons/packs/registry.json
linux/magi/.config/quickshell/magi/plugins/bar/controlcentre/ControlCentre.qml
linux/magi/.config/quickshell/magi/plugins/bar/controlcentre/MediaSection.qml
linux/magi/.config/quickshell/magi/plugins/bar/controlcentre/ProfileHeader.qml
linux/magi/.config/quickshell/magi/services/Clipboard.qml
linux/magi/.config/quickshell/magi/services/Hub.qml
linux/magi/.config/quickshell/magi/settings/SettingsSchema.js
linux/magi/README.md
linux/magi/docs/README.md
linux/magi/docs/architecture.md
linux/magi/docs/decisions.md
linux/magi/docs/design/application-launcher.md
linux/magi/docs/design/calendar-date-surface.md
linux/magi/docs/design/magi-hub.md
linux/magi/docs/design/phase2e-keybindings.patch
linux/magi/docs/design/runtime-phase2c.md
linux/magi/docs/design/runtime-phase2d.md
linux/magi/docs/design/runtime-phase2e.md
linux/magi/docs/design/runtime-phase2e1.md
linux/magi/docs/design/settings-phase2a3.md
linux/magi/docs/design/theme-orchestrator.md
linux/magi/docs/design/wallpaper-manager.md
linux/magi/docs/quickshell-reference.md
linux/magi/docs/research/legacy-shell-retirement-checkpoint.md
linux/magi/docs/research/theme-orchestrator-coverage.md
linux/magi/docs/research/visual-settings-overhaul-audit.md
linux/magi/tests/clipboard/service.qml
linux/magi/tests/hub/composition.qml
linux/magi/tests/hub/integration.qml
linux/magi/tests/hub/pointer.qml
linux/magi/tests/hub/polish.qml
linux/magi/tests/phase2e/keybindings.py
linux/magi/tests/runtime-visual/appearance.qml
linux/magi/tests/runtime-visual/feedback.qml
linux/magi/tests/runtime-visual/hub.qml
linux/magi/tests/runtime-visual/run.py
linux/magi/tests/settings/presentation.qml
linux/magi/tests/settings/schema.cjs
linux/magi/tests/settings/store.qml
linux/magi/tests/wallpaper/presentation.py
linux/magi/tests/wallpaper/reload.qml
linux/t15g/hypr/.config/hypr/hyprland.lua
linux/t15g/mftrunk/.local/bin/mftrunk
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0000.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0001.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0002.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0003.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0004.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0005.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0006.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0007.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0008.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0009.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0010.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0011.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0012.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0013.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0014.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0015.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0016.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0017.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0018.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0019.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0020.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0021.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0022.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0023.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0024.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0025.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0026.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0027.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0028.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0029.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0030.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0031.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0032.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0033.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0034.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0035.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0036.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0037.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0038.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0039.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0040.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0041.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0042.txt
linux/t15g/rofi/.config/rofi/config.rasi
linux/t15g/rofi/.config/rofi/themes/S14T15G.rasi
```

100 changed paths in this feedback pass.

## Cumulative intended Phase 2E / 2E.1 paths

```text
README.md
linux/magi/.config/quickshell/magi/components/bar/Bar.qml
linux/magi/.config/quickshell/magi/components/bar/SharedStatusSurface.qml
linux/magi/.config/quickshell/magi/components/clipboard/ClipboardContent.qml
linux/magi/.config/quickshell/magi/components/controls/IconButton.qml
linux/magi/.config/quickshell/magi/components/controls/MediaButton.qml
linux/magi/.config/quickshell/magi/components/controls/SurfaceBorder.qml
linux/magi/.config/quickshell/magi/components/hub/HubContent.qml
linux/magi/.config/quickshell/magi/components/hub/HubWindow.qml
linux/magi/.config/quickshell/magi/components/notifications/NotificationCard.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsApplication.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsContent.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsNavigationItem.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsNumber.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsSection.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsSelector.qml
linux/magi/.config/quickshell/magi/components/settings/SurfaceStyleSettings.qml
linux/magi/.config/quickshell/magi/components/settings/VisualSettingsGroup.qml
linux/magi/.config/quickshell/magi/components/settings/pages/AppearancePage.qml
linux/magi/.config/quickshell/magi/components/settings/pages/ClipboardPage.qml
linux/magi/.config/quickshell/magi/components/settings/pages/ControlCentrePage.qml
linux/magi/.config/quickshell/magi/components/settings/pages/EmojiPage.qml
linux/magi/.config/quickshell/magi/components/settings/pages/HubPage.qml
linux/magi/.config/quickshell/magi/components/settings/pages/NotificationsPage.qml
linux/magi/.config/quickshell/magi/components/settings/pages/SurfacesPage.qml
linux/magi/.config/quickshell/magi/components/settings/qmldir
linux/magi/.config/quickshell/magi/components/wallpaper/WallpaperContent.qml
linux/magi/.config/quickshell/magi/components/wallpaper/WallpaperTile.qml
linux/magi/.config/quickshell/magi/icons/packs/registry.json
linux/magi/.config/quickshell/magi/plugins/bar/controlcentre/ControlCentre.qml
linux/magi/.config/quickshell/magi/plugins/bar/controlcentre/MediaSection.qml
linux/magi/.config/quickshell/magi/plugins/bar/controlcentre/ProfileHeader.qml
linux/magi/.config/quickshell/magi/services/Clipboard.qml
linux/magi/.config/quickshell/magi/services/Hub.qml
linux/magi/.config/quickshell/magi/services/NotificationModel.qml
linux/magi/.config/quickshell/magi/services/SettingsWindowState.qml
linux/magi/.config/quickshell/magi/settings/SettingsMigrations.js
linux/magi/.config/quickshell/magi/settings/SettingsSchema.js
linux/magi/.config/quickshell/magi/settings/SettingsStore.qml
linux/magi/.config/quickshell/magi/theme/Motion.qml
linux/magi/.config/quickshell/magi/theme/qmldir
linux/magi/README.md
linux/magi/docs/README.md
linux/magi/docs/architecture.md
linux/magi/docs/decisions.md
linux/magi/docs/design/application-launcher.md
linux/magi/docs/design/calendar-date-surface.md
linux/magi/docs/design/magi-hub.md
linux/magi/docs/design/phase2e-keybindings.patch
linux/magi/docs/design/runtime-phase2c.md
linux/magi/docs/design/runtime-phase2d.md
linux/magi/docs/design/runtime-phase2e.md
linux/magi/docs/design/runtime-phase2e1.md
linux/magi/docs/design/settings-phase2a3.md
linux/magi/docs/design/theme-orchestrator.md
linux/magi/docs/design/wallpaper-manager.md
linux/magi/docs/quickshell-reference.md
linux/magi/docs/research/legacy-shell-retirement-checkpoint.md
linux/magi/docs/research/theme-orchestrator-coverage.md
linux/magi/docs/research/visual-settings-overhaul-audit.md
linux/magi/tests/calendar/schema.cjs
linux/magi/tests/clipboard/schema.cjs
linux/magi/tests/clipboard/service.qml
linux/magi/tests/hub/composition.qml
linux/magi/tests/hub/integration.qml
linux/magi/tests/hub/notifications.qml
linux/magi/tests/hub/pointer.qml
linux/magi/tests/hub/polish.qml
linux/magi/tests/hub/run.py
linux/magi/tests/notifications/presentation.qml
linux/magi/tests/phase2e/keybindings.py
linux/magi/tests/runtime-visual/appearance.qml
linux/magi/tests/runtime-visual/feedback.qml
linux/magi/tests/runtime-visual/hub.qml
linux/magi/tests/runtime-visual/polish.qml
linux/magi/tests/runtime-visual/run.py
linux/magi/tests/settings/presentation.qml
linux/magi/tests/settings/run.py
linux/magi/tests/settings/schema.cjs
linux/magi/tests/settings/store.qml
linux/magi/tests/theme-orchestrator/pointer.qml
linux/magi/tests/wallpaper/presentation.py
linux/magi/tests/wallpaper/reload.qml
linux/magi/tests/wallpaper/schema.cjs
linux/t15g/hypr/.config/hypr/hyprland.lua
linux/t15g/mftrunk/.local/bin/mftrunk
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0000.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0001.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0002.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0003.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0004.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0005.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0006.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0007.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0008.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0009.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0010.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0011.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0012.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0013.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0014.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0015.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0016.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0017.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0018.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0019.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0020.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0021.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0022.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0023.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0024.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0025.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0026.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0027.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0028.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0029.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0030.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0031.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0032.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0033.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0034.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0035.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0036.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0037.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0038.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0039.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0040.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0041.txt
linux/t15g/mftrunk/.local/bin/mftrunk-assets/frame-0042.txt
linux/t15g/rofi/.config/rofi/config.rasi
linux/t15g/rofi/.config/rofi/themes/S14T15G.rasi
```

131 cumulative intended paths. The Hyprland entry is a partial-file change.
