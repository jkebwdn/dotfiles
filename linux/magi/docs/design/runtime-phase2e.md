# MAGI visual overhaul — Phase 2E native review checkpoint

> Native acceptance is complete for the cumulative Phase 2E milestone, including
> live weather, all eight shortcuts and Everforest Light Hard. The finalization
> [checkpoint and exact allowlist](runtime-phase2e-finalization.md) supersede pending
> review/uncommitted wording retained below as implementation history. Rofi is absent;
> no package removal remains outstanding.

> Final Phase 2E.1 feedback supersedes the lifecycle, dots, card geometry and legacy-tool decisions below. Use [the 2E.1 checkpoint and cumulative path list](runtime-phase2e1.md) for the current uncommitted implementation.

> Phase 2E.1 supersedes legacy-tool references below: MFTrunk and Rofi are retired; MAGI Apps is the sole launcher route. Earlier references record historical state.

2026-10-17. Accepted baseline: `b77e449f52603e74c1b9e1c1c3260cf4a251dc3b`
(`magi: refine calendar wallpaper and media surfaces`). Phase 2D native acceptance
is complete. Phase 2E is **uncommitted, not pushed, and pending broad native review**.
Earlier checkpoint pending-review language describes those phases at implementation time.

## Architecture and shared styling

The full-output bar retains exactly 48 logical px of reservation; Hub remains floating
and non-reserving. The shared status surface, separate Calendar family, five retained
Hub modes, Settings-in-Hub, Settings-wide real Control Centre preview, Wallpaper-in-Settings,
and independent service/backend owners are unchanged. No additional normal window or mode.

`SurfaceBorder.qml` is the single transparent, non-interactive border overlay. Both
expanded surfaces and notification cards bind it to canonical Appearance preferences.
Width is 0 when disabled; there is no invisible retained border or layout inset.
Expanded flags cover Control Centre, Wi-Fi, Bluetooth, Hub content and selector.
Notification flags independently cover toast/history cards. Width is bounded 0–5;
colour is a validated semantic palette role. Calendar keeps its accepted family.

Appearance → Surfaces holds both shared border groups, existing global roundness
and status-icon size. Hub selector uses a new `hubSelector` roundness role following
Master by default. All compatible outer surfaces keep their existing semantic roles;
artwork keeps its purpose-specific independent radius and the shared masked primitive.

## Hub and Clipboard

Appearance → Hub exposes Below/Above, vertical position (10–90%), selector roundness
and resets. Selector Y derives from logical output height, with a 64px upper boundary,
16px bottom content boundary and a minimum content allowance near extreme anchors.
Below grows upward; Above grows downward. Clamping depends on output/placement, never
active mode size. The selector stays centred even while Settings makes room for preview.
Per-mode preferred widths and limits remain; Clipboard now measures its content up to
660px, Notifications remains measured up to 640px. Available space can impose a lower cap.
A short history may already fill that cap near extreme anchor positions.

The selector now uses a small accent dot under the active icon. Only hover/press creates
background fill; keyboard focus has its own outline. Pointer, arrows/activation and
stable direct mode IDs are preserved. No additional content animation was introduced:
anchored resizing remains direct, avoiding a second conflicting geometry controller.

Clipboard has compact top actions/status, bounded history, then the shared bottom
search. Empty/short history measures actual content; longer history scrolls. Direct
opening still focuses search and existing Up/Down/Enter/Ctrl+P/Ctrl+Delete behaviour
is intact. Permanent privacy footer was removed; its session/sensitive-hint limitation
is explained in Clipboard Settings. No clipboard persistence/privacy/backend changes.

## Settings and application themes

The persistent Settings Close button is removed. Sidebar selection is an accent dot,
without selected fill/line; focus remains separate. Appearance has internal Theme,
Surfaces, Bar, Control Centre and Hub navigation. Existing BarPage and ControlCentrePage
remain the only canonical implementations, with retained page instances and scroll state.
Legacy `Bar`, `Control Centre` and `Appearance` routes still resolve; internal subsection
IDs are stable (`bar`, `controlcentre`, `theme`, `surfaces`, `hub`). Profile stays separate.
No empty Motion tab or new motion sliders: these are internal design tokens.

Related colour selectors use responsive columns, stacking at narrow widths. Slider
labels are Track / Progress / Outline; persisted keys are unchanged. Existing Bar arranger,
CC ordering, visual tuning, reset/persistence and Settings-session preview remain intact.

Application themes starts collapsed. Its summary counts available external applications
actually enrolled to follow MAGI (excluding MAGI itself), with errors/manual attention
visible outside the disclosure. Expanded rows still own Follow, confirmation, Retry,
unavailable/deferred, reload/restart details, and Zen manual colour Copy. No enrollment,
file ownership or backend safety semantics changed; no bulk enrollment action was added.

## Media, profile and status continuity

Media title/artist and transports remain aligned together on the left beside the artwork.
Playback controls offers Always / Only while playing / Hidden. Stable `active` means
playable media exists, including paused media, preserving the Phase 2D resume affordance.
Always keeps unavailable actions visible but inert and non-tabbable. The card remains
present when empty. Size, roundness, progress and action/service semantics are unchanged.

Optional profile background uses a semantic role, `controlTile` radius and 10px internal
padding only when enabled. The existing avatar, typography and operator section gaps
remain canonical; the real pinned preview updates immediately.

Expanded status icons form a right-aligned cluster with 4px spacing and existing 12px
surface inset. The same live delegates remain throughout; the surface reveals behind
them while their header position interpolates over 200ms OutCubic. The lifecycle retains
interruption/reversal phases and existing close ordering. `Motion.qml` centralizes
90ms micro, 140ms control, 180ms surface, 200ms shared-element and short exit timings.
Calendar shares lifecycle timing without changing its composition or ownership.
There is no duplicate icon handoff, bounce, spring or native-quality claim from tests.

## Notifications and retention

Toast and history use the same canonical NotificationCard hierarchy: one bounded 64px
leading image, otherwise application icon, otherwise semantic fallback; primary summary,
body, quiet history timestamp and real actions. App identity remains accessible/tooltip
metadata instead of repeated visible headers. Useful image data replaces the icon and
uses RoundedArtwork (bounded asynchronous decode, rounded mask, no masking border).
Dismiss/default/action behaviour, replacement, DND, fullscreen suppression and ownership
remain unchanged. History remains title-free and content-measured.

History retention is 2h / 6h / 24h / Until cleared, default 6h. NotificationModel owns a
minute timer independent of opening Hub and also prunes when preferences/state reconcile.
Age uses the record's `updatedAt` timestamp, refreshed by the existing replacement path.
Freedesktop urgency 2 is reliable in the current production snapshot and is exempt from
age pruning. Critical notifications can still be explicitly dismissed/cleared and remain
subject to the existing global capacity policy; no pin or on-disk history was invented.
Active/exiting toasts retain their independent timeout/hover lifecycle; overdue retained
history is pruned after that toast leaves. Until cleared disables age pruning, not the
existing bounded history capacity. DND-captured history follows the same age policy.

## Whole-shell reconciliation and native limits

Wallpaper keeps a persistent 3px accent current-frame and “Current” caption. Keyboard
focus is a separate inset outline; moving focus does not remove the applied-state frame.
Hover uses a quieter border and favourites retain semantic backing over artwork.

Light-theme review retains canonical palette values and exact restored primary CC colour
semantics. Disabled secondary icon actions now use solid semantic subtext rather than
low-opacity text; unavailable media uses subtext. Calendar adjacent days, notification
metadata, Clipboard/Emoji search, Settings help, and wallpaper captions already use
readable semantic roles. Shared border roles are operator-selectable. No automatic
primary-icon contrast search or palette hex edits were introduced.

Typography/spacing changes are limited to notification hierarchy, compact Settings colour
rows, selector dots, status-cluster spacing and optional profile inset. Existing Profile
font tuning and CC inter-section gaps are not overridden. Existing Apps/Emoji, network
authentication, Calendar and wallpaper composition were inspected and retained.

Outside-click and Escape retain owning-surface precedence. Tests cover Hub routing,
Settings dropdown/dialog/text-edit/drag cancellation, pinned preview, status handoff and
Calendar dismissal. Existing network authentication/dialog ownership is preserved. Native
Wi-Fi password/authentication, Bluetooth pairing and live compositor dispatch still need
operator review; automated service fixtures are not live-device certification.

## Keybind conflict audit and MFTrunk

The audit was completed before changing the dirty Hyprland file:

| Desired chord | Previous owner | Decision |
| --- | --- | --- |
| Super+Space | MAGI launcher | Keep chord, route `hub toggle apps` |
| Super+N | MAGI notifications | Keep chord, route `hub toggle notifications` |
| Super+C | MFTrunk | Move MFTrunk to unused Super+Ctrl+C; use Hub Clipboard |
| Super+E | None | Move Emoji from Super+Period |
| Super+M | None | Actual Control Centre via `magi toggle controlcentre` |
| Super+W | None | Actual Wi-Fi via `magi toggle wifi` |
| Super+B | None | Actual Bluetooth via `magi toggle bluetooth` |

Old Super+Shift+V clipboard and Super+Period emoji bindings are removed. Super+V floating
and Super+Ctrl+Space Rofi fallback remain. The new `magi toggle` IPC delegates to existing
open/close routes; Hub uses its stable mode IDs. Lua syntax and exact routes pass static
verification. No compositor reload or `hyprctl configerrors` was run here.

MFTrunk is a repository-managed/stowed script under `linux/t15g/mftrunk`, not proven
redundant: it still supplies diagnostics, IP copy, nmtui/VPN utilities, audio sink-input
migration and service restarts. Keep its script/assets and alternative binding. No package
removal is recommended, no package command is appropriate, and no autostart was removed.

`phase2e-keybindings.patch` is the exact diff from the protected initial Hyprland snapshot,
excluding its already-dirty Theme Orchestrator integration. The final comparison confirms
that applying those intentional hunks accounts for the whole change since the snapshot.
Never stage the entire dirty Hyprland file at finalization: isolate these hunks explicitly.

## Schema 12

One v11 → v12 migration, preserving existing values and unknown raw keys; defaults are
filled by the existing validator. New persisted keys:

- `appearance.surfaceBorders.{role,width,controlcentre,wifi,bluetooth,hubContent,hubSelector}`
- `appearance.notificationBorders.{role,width,toasts,history}`
- `appearance.profileBackground.{enabled,role}`
- `appearance.roundness.roles.hubSelector` (null follows Master, otherwise 0–2)
- `hub.selectorPosition` (`below`/`above`), `hub.verticalPosition` (0.1–0.9)
- `media.controlsVisibility` (`always`/`active`/`hidden`)
- `notifications.retentionHours` (0/2/6/24)

All numeric/enumeration/boolean/palette-role values validate, persist and reset via the
existing store. No manual settings.json rewrite. Live runtime migration and concurrent
operator settings edits are preserved rather than restored to the initial snapshot.

## Focused verification

Tests run against copied production QML with offscreen native wrappers and isolated
service inputs where appropriate. The notification protocol suite uses a private bus,
never the desktop notification bus. The image model suite uses synthetic payloads.

- Settings/schema/store, new-key persistence/reset, presentation at minimum/default sizes.
- Hub routing/input/composition, five modes, title-free Notifications measured height,
  Clipboard empty/short/full height, bottom search, 1024×640/1280×900/3840×2160 placement,
  both selector sides and vertical extremes, roundness, scroll and stable anchors.
- Production drag/reorder in Hub: keyboard, pointer, cancellation, scrolling and persistence.
- Theme Orchestrator pointer: collapsed accurate summary, confirmation/cancel, errors,
  unavailable targets, changed-hook protection and exact Zen Copy.
- Notification real toast/history geometry and controlled retention timestamps for all four
  policies, fresh/replacement/critical/DND records, unopened Hub and toast-independent expiry.
- Private notification bus: actions, replacement, timeout, DND, critical, fullscreen,
  read/clear, transient/resident, hover, bounds and reload.
- Runtime visual/artwork, actual borders for all targets, profile background, transport
  modes, image/icon replacement, Wallpaper current/focus distinction, pinned CC preview.
- Exact old primary-colour oracle: 600 production RGBA pairs unchanged.
- MPRIS service/actions and media geometry/artwork sizes/roundness/no-art.
- Clipboard model/presentation and exact UTF-8 Emoji / Clipboard restore route through Hub.
- Wallpaper backend transactions (9 tests), presentation/reload/lifecycle/thumbnail release,
  directory drafts/reset and source immutability. Runner now isolates HOME as well as state
  and restores its own library after testing Reset, avoiding an accidental real-home scan.
- Calendar content/settings and real Bar navigation/ownership; shared-status 48-step lifecycle.
- Seven desired keybind routes, retained MFTrunk fallback and `luac -p` syntax.
- `git diff --check`; nothing staged, committed or pushed.

GdkPixbuf image decoding and private D-Bus binding required approved execution outside the
sandbox; both still use disposable fixtures. Offscreen checks cannot certify GPU edges,
physical monitor output, live device auth, native motion quality or compositor key dispatch.

## Protected operator state

Initial snapshot: `/tmp/magi-phase2e/protected.json` plus copied files under
`/tmp/magi-phase2e/files` (485 file/link/directory records). Logs are alongside them.
All Theme Orchestrator application integrations, Hypridle, Hyprlock and Yazi flavour
remain untouched. Comparison detected changes only to the intended Hyprland keybind file,
live settings.json, and settings-backup directory membership. Existing snapshot backup
files are unchanged. Current settings reflect runtime schema migration and concurrent
avatar/artwork-size/action-column tuning; these are retained, never manually rewritten.
The Hyprland integration suffix matches the snapshot; only the documented keybind patch
is new. Protected state is excluded from the Phase 2E source path list below.

## Native operator checklist

Review the whole shell in Everforest Light Hard, Catppuccin Mocha and another dark palette:
shared borders on/off/zero and roles; Hub above/below at high/low anchors and all five modes;
Clipboard short/full search/history; Appearance navigation and narrow colour rows;
Theme summary expansion/errors/Zen; real CC preview while tuning; profile inset/background;
playing/paused/empty transports; status-cluster open/close continuity and rapid reversal;
notification screenshot image versus app icon, actions/DND/Clear; Wallpaper applied versus
focused/hovered/favourite state; GPU artwork edges; focus and outside/Escape ownership;
Wi-Fi authentication/Bluetooth pairing; actual seven shortcut routes and 48px reservation.
Native screenshots and operator feedback are required before acceptance. No next milestone.

## Exact Phase 2E paths

The list below contains intended source/test/documentation changes only. The Hyprland
entry means **only the isolated keybind patch**, not its existing local integration hunk.
`settings.json`, backup/runtime state and other protected dotfiles are excluded.

<!-- phase2e-paths -->

```text
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
linux/magi/.config/quickshell/magi/plugins/bar/controlcentre/MediaSection.qml
linux/magi/.config/quickshell/magi/plugins/bar/controlcentre/ProfileHeader.qml
linux/magi/.config/quickshell/magi/services/NotificationModel.qml
linux/magi/.config/quickshell/magi/services/SettingsWindowState.qml
linux/magi/.config/quickshell/magi/settings/SettingsMigrations.js
linux/magi/.config/quickshell/magi/settings/SettingsSchema.js
linux/magi/.config/quickshell/magi/settings/SettingsStore.qml
linux/magi/.config/quickshell/magi/theme/Motion.qml
linux/magi/.config/quickshell/magi/theme/qmldir
linux/magi/docs/README.md
linux/magi/docs/architecture.md
linux/magi/docs/decisions.md
linux/magi/docs/design/phase2e-keybindings.patch
linux/magi/docs/design/runtime-phase2e.md
linux/magi/docs/quickshell-reference.md
linux/magi/tests/calendar/schema.cjs
linux/magi/tests/clipboard/schema.cjs
linux/magi/tests/hub/composition.qml
linux/magi/tests/hub/notifications.qml
linux/magi/tests/hub/polish.qml
linux/magi/tests/hub/run.py
linux/magi/tests/notifications/presentation.qml
linux/magi/tests/phase2e/keybindings.py
linux/magi/tests/runtime-visual/appearance.qml
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
```

60 intended paths; Hyprland is a partial-file change only.
