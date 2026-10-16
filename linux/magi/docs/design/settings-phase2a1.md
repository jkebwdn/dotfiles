# Settings Phase 2A.1 — composition checkpoint

2026-10-16. Phase 2A is accepted as the structural foundation. This pass refines
Settings presentation only and stops for native operator screenshots. No staging,
commit, push, shell restart or live service activation was performed.

## Visible changes

- Sidebar: 190px, flat 34px navigation rows with 2px gaps, a small accent active
  marker, aligned left text and a subtle selected surface. Keyboard focus and
  independent scrolling remain. No decorative or mismatched navigation icons added.
- Controls: shared native Qt Basic primitives retain their handlers and keyboard
  behaviour but use MAGI semantic rounded surfaces. Selectors have a bounded 208px
  preferred / 260px maximum width, single chevron and styled popup list. Steppers
  are a unified 118×34px surface with integrated minus/value/plus. Toggle tracks
  use semantic accent/on-accent pairs and a positional knob. Text fields and
  sliders share the quiet treatment.
- Buttons: borderless secondary fills, flat reset/order/remove actions, semantic
  primary confirmation/Save buttons and accessible-name tooltips for symbolic
  actions. Focus is a single inset 1px accent outline for keyboard focus; mouse
  clicks no longer leave a doubled outer outline. Focus-driven scrolling remains.
- Pages: bounded 760px content, more deliberate section spacing, 16px section
  headings, compact 10px section rows and aligned label/control columns down to
  420px content width. Advanced disclosure headings align left and stay quiet.
- Control Centre Settings: aligned independent column steppers; section switches
  in two columns; one soft surface per configured primary entry, with a bold
  name/enable line and a secondary accent/order/remove line. Existing stable keys,
  move buttons, add/remove functions and separate action columns are preserved.
  Preview remains available near the page's reset action. No drag-and-drop.
- Icons: current shell-pack overview and explanatory copy, followed by aligned
  60px override rows with small icon wells, status and import/default actions.
  Imports, validation and pack behaviour are unchanged.
- Launcher: Presentation, Dimensions, Artwork and Hidden applications sections.
  Image enable flags/header position now sit with the image paths. All options
  remain visible; no setting key, default or handler semantics changed.
- Appearance: small palette swatches, aligned target-name/enrollment rows and
  quieter status hierarchy. Ordinary target status now uses semantic text rather
  than low-contrast accent text on light backgrounds. Errors retain their danger
  role. Enrollment/review/Retry/Copy behaviour remains unchanged.
- Footer: quiet “All changes saved” at the lower right. Schema version is removed
  from routine UI; errors/conflicts remain visible and long diagnostics remain
  scrollable within the existing 80px bound.

The semantic palettes, Theme/roundness backend, settings persistence/migrations,
services, shared-surface architecture, runtime Control Centre, Hub, Calendar,
Notifications, Wallpaper Manager and launcher surfaces were not edited.

## Evidence and validation

The installed environment remains Quickshell 0.3.1-1 / Qt declarative 6.11.2-2.
Customization points were checked against the installed Qt Basic SpinBox.qml and
ComboBox.qml under `/usr/lib/qt6/qml/QtQuick/Controls/Basic/` and QtTest TestCase.qml,
on 2026-10-16. No third-party assets or new dependencies were introduced.

`tests/settings/presentation.qml` retains Phase 2A coverage and adds:

- Catppuccin Mocha, Frappé, Everforest Dark Hard, Everforest Light Hard and Latte.
- Actual backing-window resizing and explicit 720×500 / 940×720 size assertions.
  The previous fixture changed only preferred implicit dimensions, which did not
  resize an already mapped FloatingWindow. This gap is now fixed.
- Horizontal bounds checks for visible production buttons, switches and selectors;
  aligned column steppers; native pointer increment/decrement; selector popup
  activation and Escape dismissal without an unintended settings write.
- Optional QtTest framebuffer captures, with pixel-dimension assertions, enabled by
  `MAGI_SETTINGS_CAPTURES=/path`. No capture is required for the normal test run.

PASS (exit 0):

- `python tests/settings/presentation.py` (also run with captures enabled).
- `python tests/settings/run.py` — schema, migration, atomic persistence and fixtures.
- `python tests/settings/appearance.py` — all ten canonical palettes/live settings.
- `python tests/settings/modules.py window.qml` — window/deferred-open/persistence.
- `python tests/theme-orchestrator/qml.py` — real bridge, production enrollment,
  cancellation, failures, hook protection and exact Zen Copy in all ten palettes.
- `python tests/shared-status-surface/run.py` — unchanged 48-step lifecycle safety check.
- `git diff --check`, plus whitespace checks of new files.

Software framebuffer renders were inspected for the requested dark/light families,
including the narrow window. Final captures are in
`/tmp/magi-settings-phase2a1/captures/<palette>-<page>-<width>.png` (40 images covering
Appearance, Control Centre, Icons and Launcher at both sizes). Earlier exploratory
captures without a width suffix are superseded. These are disposable-root software
renders, not native compositor/GPU acceptance. The test runner only allows the
existing explicitly named offscreen/absent-system-service diagnostics.

## Protected state

A fresh pre-edit snapshot lives in `/tmp/magi-settings-phase2a1/protected.json` and
`initial-status`; the complete pre-pass Settings sources are in `settings-before/`.
All 13 protected entries match their initial SHA-256 hashes or directory/symlink
records, and their Git status entries are unchanged. No operator configuration was
normalized or reset. The initial records are retained below for reproducibility.

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

## Exact paths changed in this pass

Relative to `linux/magi/`; previous Phase 2A changes remain in the working tree.

- `.config/quickshell/magi/components/settings/SettingsButton.qml`
- `.config/quickshell/magi/components/settings/SettingsFocus.qml`
- `.config/quickshell/magi/components/settings/SettingsMetrics.qml`
- `.config/quickshell/magi/components/settings/SettingsNavigationItem.qml`
- `.config/quickshell/magi/components/settings/SettingsNumber.qml`
- `.config/quickshell/magi/components/settings/SettingsPage.qml`
- `.config/quickshell/magi/components/settings/SettingsRow.qml`
- `.config/quickshell/magi/components/settings/SettingsSection.qml`
- `.config/quickshell/magi/components/settings/SettingsSelector.qml`
- `.config/quickshell/magi/components/settings/SettingsSlider.qml`
- `.config/quickshell/magi/components/settings/SettingsTextField.qml`
- `.config/quickshell/magi/components/settings/SettingsToggle.qml`
- `.config/quickshell/magi/components/settings/SettingsWindow.qml`
- `.config/quickshell/magi/components/settings/pages/AppearancePage.qml`
- `.config/quickshell/magi/components/settings/pages/BarPage.qml`
- `.config/quickshell/magi/components/settings/pages/CalendarPage.qml`
- `.config/quickshell/magi/components/settings/pages/ClipboardPage.qml`
- `.config/quickshell/magi/components/settings/pages/ControlCentrePage.qml`
- `.config/quickshell/magi/components/settings/pages/EmojiPage.qml`
- `.config/quickshell/magi/components/settings/pages/IconsPage.qml`
- `.config/quickshell/magi/components/settings/pages/LauncherPage.qml`
- `.config/quickshell/magi/components/settings/pages/NotificationsPage.qml`
- `.config/quickshell/magi/components/settings/pages/ProfilePage.qml`
- `.config/quickshell/magi/components/settings/pages/WallpaperPage.qml`
- `.config/quickshell/magi/components/settings/qmldir`
- `docs/README.md`
- `docs/architecture.md`
- `docs/decisions.md`
- `docs/design/settings-phase2a1.md`
- `docs/quickshell-reference.md`
- `tests/settings/presentation.qml`

## Native checkpoint and deferred work

Stop for operator screenshots of Settings in the requested palettes. Inspect
normal/hover/keyboard-focus/disabled states, popup positioning, minimum-size
scrolling, long target errors, edited profile artwork and fractional scaling.
The renderer evidence shows an intentional composition change; the operator must
still accept its native appearance and density.

Control Centre/status bar/Hub implementation, runtime launcher and Wallpaper
Manager visuals, whole-shell motion and drag-and-drop remain deferred. No weather,
application icon/theme switching, lock/greeter, Calendar providers, palette or
Theme Orchestrator adapter work is included. No commit or push until requested.
