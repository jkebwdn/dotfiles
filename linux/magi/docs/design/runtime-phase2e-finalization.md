# Phase 2E — native acceptance and final source checkpoint

2026-10-17. The operator accepted the cumulative Phase 2E, 2E.1 and 2E.2
implementation over `b77e449f52603e74c1b9e1c1c3260cf4a251dc3b` and authorized one
commit: `magi: complete shell visual overhaul`. No next milestone is included.

## Acceptance

Accepted: shared borders, navigation accent, toggle styles, Settings composition,
persistent five-mode Hub and explicit Escape, Profile/Media natural geometry and
independent typography, compact/friendly greetings, live explicit-location
Open-Meteo weather and Metric/Imperial switching, artwork progress width without
progress changes, notification presentation/DND/Clear/retention, light-theme
presentation, all eight shortcuts, and MFTrunk/Rofi retirement. Schema remains 12.

The earlier [2E](runtime-phase2e.md), [2E.1](runtime-phase2e1.md) and
[2E.2](runtime-phase2e2.md) checkpoints retain dated implementation history and
focused-test evidence. Their pending-review wording is superseded by acceptance.
The operator removed Rofi; `pacman -Q rofi` confirms it is absent. No package or
runtime implementation changes were made during finalization.

## Public documentation reconciliation

Reviewed all nine tracked README files and the platform layout. Updated:

- Root `README.md`: concise cross-platform landing page, Linux guide, active stack,
  existing practical Stow workflow and platform links.
- New `linux/README.md`: Arch/Hyprland/MAGI stack, application packages, Stow,
  Wallpaper/Theme Orchestrator, local-state restoration and shortcut link.
- `linux/magi/README.md`: current product/setup landing page, retained Hub versus
  anchored surface families, 48px reservation, Settings, weather, Theme Orchestrator,
  final shortcuts and a clearly future roadmap. No invented screenshot assets.
- `Windows/Dell-Inspiron-7501/README.md`: corrected repository filename case and
  documented its existing PowerShell/Starship/Fastfetch/Windows Terminal paths.
- MAGI docs/research README indexes: accepted current state separated from dated history.
- Shared-status-surface test README: corrected 44 to 48 lifecycle steps.

No macOS README exists. Tracked macOS configuration is Yabai/skhd, SketchyBar,
JankyBorders, Ghostty, Neovim and Fastfetch; no Aerospace/Starship implementation
was inferred. Root's separate macOS description and its files remain intact.
Emoji data provenance, icon-pack fixture and vendored yatline READMEs remain valid
and unchanged. Existing historical research references to retired tools remain.
No obsolete shell screenshot was retained as a current MAGI screenshot.

Relative Markdown destinations and referenced repository paths were checked.
Final static keybind/Lua validation passes; active source/config has no whole-word
Rofi/MFTrunk dependency. No full test matrix was rerun: accepted focused evidence
includes Settings, Hub, Notifications, Clipboard, Launcher, MPRIS, offline Weather,
Theme Orchestrator pointer, pinned preview, 600 exact colour comparisons and
48-step lifecycle checks. Finalization checks are documentation/link accuracy,
working/index whitespace, exact staged paths and keybind-only index content.

## Staging ownership

The final allowlist below has **154 paths**: the verified 149 cumulative checkpoint
paths plus five documentation additions/modifications. The count includes 46 retired
tracked files (44 MFTrunk script/frame files, two Rofi config/theme files).

Only the accepted keybind patch is included for
`linux/t15g/hypr/.config/hypr/hyprland.lua`. Its unrelated local Theme Orchestrator
hook is excluded. The patch is [recorded separately](phase2e-keybindings.patch).
All other allowed files are staged by exact path, never broad directory staging.

Live `settings.json`, Settings backups/runtime state, application theme integrations,
local shell/editor/terminal/GTK/Yazi files, Hypridle/Hyprlock and the Yazi flavour are
excluded. Finalization snapshot: `/tmp/magi-phase2e-final/snapshot.json`; source and
protected-state comparisons are recorded alongside it. Concurrent live Settings edits
and new backup entries were detected and preserved; all other protected records and
implementation files remained unchanged during this documentation pass. Commit/push validation must
confirm an empty index afterward and only these preserved local changes remaining.

## Exact final allowlist

```text
README.md
Windows/Dell-Inspiron-7501/README.md
linux/README.md
linux/magi/.config/quickshell/magi/components/bar/Bar.qml
linux/magi/.config/quickshell/magi/components/bar/SharedStatusSurface.qml
linux/magi/.config/quickshell/magi/components/clipboard/ClipboardContent.qml
linux/magi/.config/quickshell/magi/components/controls/CompactToggle.qml
linux/magi/.config/quickshell/magi/components/controls/IconButton.qml
linux/magi/.config/quickshell/magi/components/controls/MediaButton.qml
linux/magi/.config/quickshell/magi/components/controls/SurfaceBorder.qml
linux/magi/.config/quickshell/magi/components/controls/VisualState.js
linux/magi/.config/quickshell/magi/components/hub/HubContent.qml
linux/magi/.config/quickshell/magi/components/hub/HubWindow.qml
linux/magi/.config/quickshell/magi/components/notifications/NotificationCard.qml
linux/magi/.config/quickshell/magi/components/notifications/NotificationContent.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsApplication.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsContent.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsNavigationItem.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsNumber.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsSection.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsSelector.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsToggle.qml
linux/magi/.config/quickshell/magi/components/settings/SurfaceStyleSettings.qml
linux/magi/.config/quickshell/magi/components/settings/VisualSettingsGroup.qml
linux/magi/.config/quickshell/magi/components/settings/pages/AppearancePage.qml
linux/magi/.config/quickshell/magi/components/settings/pages/ClipboardPage.qml
linux/magi/.config/quickshell/magi/components/settings/pages/ControlCentrePage.qml
linux/magi/.config/quickshell/magi/components/settings/pages/EmojiPage.qml
linux/magi/.config/quickshell/magi/components/settings/pages/HubPage.qml
linux/magi/.config/quickshell/magi/components/settings/pages/NotificationsPage.qml
linux/magi/.config/quickshell/magi/components/settings/pages/ProfilePage.qml
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
linux/magi/.config/quickshell/magi/services/Weather.qml
linux/magi/.config/quickshell/magi/services/qmldir
linux/magi/.config/quickshell/magi/services/weather.py
linux/magi/.config/quickshell/magi/settings/SettingsMigrations.js
linux/magi/.config/quickshell/magi/settings/SettingsSchema.js
linux/magi/.config/quickshell/magi/settings/SettingsStore.qml
linux/magi/.config/quickshell/magi/shell.qml
linux/magi/.config/quickshell/magi/theme/Motion.qml
linux/magi/.config/quickshell/magi/theme/Theme.qml
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
linux/magi/docs/design/runtime-phase2e-finalization.md
linux/magi/docs/design/runtime-phase2e.md
linux/magi/docs/design/runtime-phase2e1.md
linux/magi/docs/design/runtime-phase2e2.md
linux/magi/docs/design/settings-phase2a3.md
linux/magi/docs/design/theme-orchestrator.md
linux/magi/docs/design/wallpaper-manager.md
linux/magi/docs/quickshell-reference.md
linux/magi/docs/research/README.md
linux/magi/docs/research/legacy-shell-retirement-checkpoint.md
linux/magi/docs/research/theme-orchestrator-coverage.md
linux/magi/docs/research/visual-settings-overhaul-audit.md
linux/magi/tests/calendar/schema.cjs
linux/magi/tests/clipboard/schema.cjs
linux/magi/tests/clipboard/service.qml
linux/magi/tests/hub/actions.qml
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
linux/magi/tests/runtime-visual/runtime.qml
linux/magi/tests/runtime-visual/typography.qml
linux/magi/tests/runtime-visual/weather.qml
linux/magi/tests/settings/presentation.qml
linux/magi/tests/settings/run.py
linux/magi/tests/settings/schema.cjs
linux/magi/tests/settings/store.qml
linux/magi/tests/shared-status-surface/README.md
linux/magi/tests/theme-orchestrator/pointer.qml
linux/magi/tests/visual/state.cjs
linux/magi/tests/wallpaper/presentation.py
linux/magi/tests/wallpaper/reload.qml
linux/magi/tests/wallpaper/schema.cjs
linux/magi/tests/weather/backend.py
linux/magi/tests/weather/fixture.py
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
