# Settings Phase 2A — native operator checkpoint

2026-10-16. Implemented over the visual/Settings audit. No commit, staging, push,
Quickshell restart, Hyprland edit or live service activation was performed.
Automated acceptance is complete; native visual acceptance is pending.

## Visual foundations and reuse

`components/settings/SettingsMetrics.qml` owns only Settings geometry: 24px page
padding, 16px spacing, 8px compact spacing, 36px minimum controls, 26/18/14/13px
title/section/body/helper typography, 24px icons, 2px focus outlines and 0.7 disabled
opacity. No semantic palette, global Theme role, roundness default, schema or
RenderTokens value changed. No motion was added; unused timing abstractions were
avoided. Native control interaction remains Qt Basic's.

Shared SettingsPage owns scrolling, bounded content, headings and descriptions;
SettingsSection provides borderless grouping and optional disclosure; SettingsRow
stacks label/editor pairs below 540px content width. SettingsHelp wraps plain text.
SettingsToggle, SettingsSelector, SettingsNumber, SettingsSlider and SettingsTextField
extend native controls. SettingsFocus provides semantic focus outlines and scrolls
focused controls into view. Existing SettingsButton now explicitly pairs pressed/
selected accent fill with accentText, retains keyboard activation, and shows focus.
Existing VisualSettingsGroup uses sections and rows. Profile reuses RoundedArtwork
with the Theme avatar radius and the existing GPU mask; the artwork primitive itself
is unchanged. No second theme system or backend was introduced.

## Migrated pages and presentation

All eleven pages use the shared page/container and appropriate native control
subclasses: Appearance, Profile, Bar, Date & time, Control Centre, Notifications,
Clipboard, Launcher, Emoji, Wallpaper and Icons.

The normal movable FloatingWindow retains 940×720 initial and 720×500 minimum
sizing. Navigation scrolls independently, uses consistent selected/focus treatment,
and reveals focused entries. All page IDs remain unchanged. Page headings,
descriptions and margins are shared. Footer save/conflict handling is preserved; long diagnostics scroll within an 80px bound.

Appearance separates application themes and collapsed advanced appearance;
VisualSettingsGroup remains the editor for visual overrides. Target labels sit above
aligned enrollment/actions; error, retry, pending, deferred and unavailable states,
inline enrollment review and Zen workspace-colour/Copy remain present. Long status
text wraps. Qt, hyprtoolkit and Hyprlock remain deferred.

Control Centre groups primary controls and secondary actions. Primary entry rows
use two lines, retaining stable keys and existing keyboard move/remove buttons.
Both `controlCentre.columns` and `controlCentre.actionColumns` remain independent.
No drag-and-drop or actual Control Centre surface changes were made.

Notifications groups limits/timing; Launcher groups dimensions/artwork; Wallpaper
separates explicit-save library sources; Clipboard separates history actions while
retaining privacy text and armed erase. Bar uses readable module labels with original
IDs. Icons explicitly describes MAGI shell packs. Profile avatar clipping now follows
the existing mask approach; no weather or Control Centre profile-header changes.

## Behaviour boundary

No settings keys/options/defaults, persistence, migrations, adapters, models or
service implementations changed. All existing page service entry points are retained.
Visited pages now remain loaded for the lifetime of the Settings window, preserving
scroll position and unsaved Wallpaper drafts on navigation. Appearance and Launcher
still refresh on revisiting. Directory edits still require Save; merely navigating
never persists them. The new UI behaviours are disclosures, responsive rows and
focus-driven scrolling. Existing reset/clear/enrollment operations are unchanged.

The 48 logical px reservation, shared-status-surface lifecycle, separate Control
Centre/Calendar families, one Hub and all shortcuts remain untouched.

## Tests and results

New `tests/settings/presentation.py` / `presentation.qml` exercise production Settings
in disposable HOME, config, data and state roots. PASS:

- All eleven pages via keyboard navigation at 720×500 and 940×720, in Mocha,
  Latte and Everforest Light Hard; selected state and navigation viewport bounds.
- Advanced appearance slider keyboard write; independent Control Centre columns;
  Emoji toggle via Space, Tab advance and production reset.
- Wallpaper draft retention without implicit save, followed by production Save.
- Profile masked-artwork instance; long unbroken helper wrapping; pressed ink pairing,
  focus and disabled opacity in light and dark states; bounded scrollable diagnostics.

Existing suites preserved and passed:

- `python tests/settings/run.py`: schema, atomic persistence, migration backups,
  conflicts, symlinks and five real-store fixtures.
- `python tests/settings/appearance.py`: ten palettes and live appearance.
- `python tests/settings/modules.py window.qml`: normal window, persistence/reopen,
  deferred opening.
- `python tests/settings/modules.py control-layout.qml` and `action-layout.qml`:
  dynamic primary and secondary layouts.
- `python tests/theme-orchestrator/qml.py`: real bridge, Settings window and production
  pointer enrollment/cancel/removal/failure/changed-hook tests; exact hex-only Zen
  clipboard payload for all ten palettes.
- `python tests/shared-status-surface/run.py`: all 48 lifecycle steps; suite unchanged.
- `node tests/visual/state.cjs`, `node tests/settings/catalogue.cjs`,
  `node tests/settings/icons.cjs .config/quickshell/magi/icons`: PASS.
- `git diff --check`: PASS.

The first direct icon-test invocation omitted its required path argument; rerunning
with the documented command above passed. QML fixture warnings found during work
were fixed. The new runner allows only named offscreen window-mask and absent
IPC/DBus/Hyprland environment diagnostics; other QML warnings/errors fail it.
No native compositor, real service action or GPU-mask rendering equivalence is
claimed by these software/offscreen checks. No existing regression test was rewritten.

## Protected operator state

Initial snapshot: `/tmp/magi-settings-phase2a/protected.json` and `initial-status`,
recorded before source edits. Final comparison: all 13 entries match in content hash,
file type or symlink destination; every initial Git status entry is unchanged.
The protected files were never staged, reset, normalized or written by this work.
The initial snapshot follows (SHA-256 for regular files):

- `linux/magi/.config/quickshell/magi/settings.json`: `3939ceb512dd3fc8e82e3aef78cfe22cec44670c78c26187d5f216866f373980`
- `linux/t15g/bash/.bashrc`: `9d6973a7f9706eaaea5b2673f5833da2d27ff9abd49323ca990eb4fc2e8f70b7`
- `linux/t15g/ghostty/.config/ghostty/config.ghostty`: `e7e2dfb6b7a2a0f5b02dc325856206036a08a95e7ee35cda7fb1121d22430eaf`
- `linux/t15g/gtk3/.config/gtk-3.0/gtk.css`: `1b4f0b6bade6690c04f590a19520a9400051dc59036f6d2a25d11b065cce815d`
- `linux/t15g/gtk3/.config/gtk-3.0/settings.ini`: `4ebc4bf83a77f430233b23f2c3cd4f5bc5ee46cc2d19264d654d2bbfd2976d94`
- `linux/t15g/hypr/.config/hypr/hyprland.lua`: `c2c56f9e27af073d5eef64764ee016a22c84bf94cc07734c6ed8640dd5556826`
- `linux/t15g/nvim/.config/nvim/init.lua`: `ea4cd972accd26fc4d5d94c2b18fea6d8a923ceca5aec30c05f82e1e4fd6a514`
- `linux/t15g/yazi/.config/yazi/init.lua`: `77da8c5318d44f75e60f06b22b45b785fc4042545fa6b5067d3c9f1a078d1bce`
- `linux/t15g/yazi/.config/yazi/theme.toml`: `5b24520ea21fd545994c0ac0ea6b80980de1bc68d5e7e006dd456d5ef27cd56e`
- `linux/t15g/hypr/.config/hypr/hypridle.conf`: `eb6fa3c034957abaf48de818e690429c4a1c8b4815e72ead5e19d90a30cc17fb`
- `linux/t15g/hypr/.config/hypr/hyprlock.conf`: `4093a0fec9821d286c47b53916057b8231ce792c71ce404fa940d72d3861262d`
- `linux/t15g/yazi/.config/yazi/flavors`: `directory`
- `linux/t15g/yazi/.config/yazi/flavors/magi.yazi`: `/home/jkebwdn/.local/share/magi/theme-orchestrator/yazi/current/flavor`

## Exact changed paths

Paths below are relative to the dotfiles repository. Protected pre-existing changes
listed above are excluded. These are the complete implementation/test/documentation
changes for this phase:

- `linux/magi/.config/quickshell/magi/components/settings/SettingsButton.qml`
- `linux/magi/.config/quickshell/magi/components/settings/SettingsFocus.qml`
- `linux/magi/.config/quickshell/magi/components/settings/SettingsHelp.qml`
- `linux/magi/.config/quickshell/magi/components/settings/SettingsMetrics.qml`
- `linux/magi/.config/quickshell/magi/components/settings/SettingsNumber.qml`
- `linux/magi/.config/quickshell/magi/components/settings/SettingsPage.qml`
- `linux/magi/.config/quickshell/magi/components/settings/SettingsRow.qml`
- `linux/magi/.config/quickshell/magi/components/settings/SettingsSection.qml`
- `linux/magi/.config/quickshell/magi/components/settings/SettingsSelector.qml`
- `linux/magi/.config/quickshell/magi/components/settings/SettingsSlider.qml`
- `linux/magi/.config/quickshell/magi/components/settings/SettingsTextField.qml`
- `linux/magi/.config/quickshell/magi/components/settings/SettingsToggle.qml`
- `linux/magi/.config/quickshell/magi/components/settings/SettingsWindow.qml`
- `linux/magi/.config/quickshell/magi/components/settings/VisualSettingsGroup.qml`
- `linux/magi/.config/quickshell/magi/components/settings/pages/AppearancePage.qml`
- `linux/magi/.config/quickshell/magi/components/settings/pages/BarPage.qml`
- `linux/magi/.config/quickshell/magi/components/settings/pages/CalendarPage.qml`
- `linux/magi/.config/quickshell/magi/components/settings/pages/ClipboardPage.qml`
- `linux/magi/.config/quickshell/magi/components/settings/pages/ControlCentrePage.qml`
- `linux/magi/.config/quickshell/magi/components/settings/pages/EmojiPage.qml`
- `linux/magi/.config/quickshell/magi/components/settings/pages/IconsPage.qml`
- `linux/magi/.config/quickshell/magi/components/settings/pages/LauncherPage.qml`
- `linux/magi/.config/quickshell/magi/components/settings/pages/NotificationsPage.qml`
- `linux/magi/.config/quickshell/magi/components/settings/pages/ProfilePage.qml`
- `linux/magi/.config/quickshell/magi/components/settings/pages/WallpaperPage.qml`
- `linux/magi/.config/quickshell/magi/components/settings/qmldir`
- `linux/magi/docs/README.md`
- `linux/magi/docs/architecture.md`
- `linux/magi/docs/decisions.md`
- `linux/magi/docs/design/settings-phase2a.md`
- `linux/magi/docs/quickshell-reference.md`
- `linux/magi/tests/settings/presentation.py`
- `linux/magi/tests/settings/presentation.qml`

## Native review and Phase 2B

Review all pages live at minimum/default size, dark/light palettes, keyboard-only
navigation, open selector popups, disabled/error states, long target messages and
roundness 0/1/2. Inspect avatar edges at 1×/2×/fractional scaling with a real image;
software rendering cannot accept the GPU mask. Confirm visual contrast and focus
visibility on the operator's actual palettes and display. Validate draft navigation,
explicit Save, reset, Zen Copy and target review placement live as appropriate.

Phase 2B deliberately retains Control Centre/status-bar/Hub visual implementation,
profile-header work, whole-shell motion, drag-and-drop ordering and broader surface
accessibility/contrast work. All user exclusions remain deferred, including weather,
application-icon/theme switching, lock/greeter, Calendar providers, wallpaper-derived
palettes and Qt/hyprtoolkit/Hyprlock adapters. Stop here for operator screenshots and
feedback; do not extend this work into shell surfaces or commit without approval.
