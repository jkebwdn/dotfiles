# Phase 2E.2 — final native feedback checkpoint

> Native acceptance is complete for the cumulative Phase 2E milestone, including
> live weather, all eight shortcuts and Everforest Light Hard. The finalization
> [checkpoint and exact allowlist](runtime-phase2e-finalization.md) supersede pending
> review/uncommitted wording retained below as implementation history. Rofi is absent;
> no package removal remains outstanding.

2026-10-17. Continues the current uncommitted Phase 2E/2E.1 tree over `b77e449f52603e74c1b9e1c1c3260cf4a251dc3b`. No commit, push, staging, shell restart or compositor mutation. Phase 2E.1 is broadly accepted; this is the next native-review checkpoint, not a new roadmap milestone.

## Changes and settings

Schema remains **12**, with one existing 11→12 migration. Missing fields receive validated defaults; existing values and unknown compatible fields remain preserved. SettingsStore supports weather persistence/reset. No implementation manually writes the live settings file.

| Key | Default / bounds | Settings location |
| --- | --- | --- |
| `appearance.navigationAccent` | `accent`; existing semantic palette roles | Appearance → Surfaces |
| `appearance.toggleStyle` | `pill`; `pill`, `filled`, `minimal` | Appearance → Surfaces |
| `profile.greetingStyle` | `compact`; `compact`, `friendly` | Profile |
| `appearance.visual.profileGreetingWeight` | 700 (Bold); 400/700 only | Appearance → Control Centre → Appearance → Profile typography |
| `appearance.visual.profileWeatherWeight` | 400 (Normal); 400/700 only | same |
| `appearance.visual.profileThirdLineWeight` | 400 (Normal); 400/700 only | same |
| `weather.enabled` | false | Profile → Weather |
| `weather.location` | empty; explicit query, maximum 160 characters | same; draft then Save location |
| `weather.units` | `metric`; `metric` / `imperial` | same |
| `appearance.visual.mediaTitleSize` | 13; integer 10–24px | Appearance → Control Centre → Appearance → Media typography |
| `appearance.visual.mediaArtistSize` | 11; integer 10–20px | same |
| `appearance.visual.mediaTitleWeight` | 700 (Bold); 400/700 only | same |
| `appearance.visual.mediaArtistWeight` | 400 (Normal); 400/700 only | same |
| `appearance.visual.mediaProgressBorderWidth` | 2; 0–5px | Appearance → Control Centre → Appearance → Profile and media |
| `appearance.visual.avatarBorderWidth` | existing 2; existing 0–5px, reused | same; label Profile image border width |

Navigation accent resolves through Theme once and drives only selected primary Settings icon/text and Hub icon. Appearance subsection pills retain their existing treatment; inactive icons, hover and focus remain separate. No selected dots or fills were reintroduced.

SettingsToggle now specializes the production CompactToggle Switch instead of duplicating a CheckBox/indicator. Pill preserves the accepted 32×18 track/12px knob. Filled uses a smaller indicator and more exposed accent body; Minimal reduces track height to 6px. State, pointer/keyboard operation, accessibility, hover, focus and disabled handling remain one implementation. Settings and Wi-Fi/Bluetooth use it; no remaining standalone Switch/CheckBox implementation exists. Runtime action tiles remain action tiles rather than being converted to switches.

Primary-control rows no longer render the redundant 10px colour circle. The existing accent selector retains its live role swatch, followed by remove and the existing drag handle; runtime colour semantics are unchanged.

Profile and media retain their measured `max(artwork, natural text stack) + balanced padding` geometry and vertical centring. Weight bindings use native Qt values, with only Normal/Bold exposed. Media title/artist remain left-aligned and elided. Profile greeting uses exact display-name case. Local buckets remain 05:00–11:59 Morning, 12:00–17:59 Afternoon, 18:00–22:59 Evening, otherwise Night. Compact emits `Afternoon, jkebwdn`; Friendly emits `Good Afternoon jkebwdn`.

The media border uses the existing RoundedArtwork `borderWidth`, concentric mask and perimeter renderer. Playback position, duration, normalized progress and direction are untouched. Avatar border already existed and is not duplicated or coupled.

Notifications Hub no longer exposes its master enabled switch. DND is left-aligned and Clear All right-aligned in the compact top row. `notifications.enabled` predates Phase 2E and remains backward-compatible in schema/service/Settings. No daemon, DBus, toast, action, replacement, DND or retention changes.

## Weather investigation and implementation

Before modification, ProfileHeader defined `weatherSummary: ""` as an intentionally deferred provider slot. There was no weather service, network fetch or location setting. The fallback was expected, not a provider failure.

A first-party `Weather.qml` singleton owns lifecycle, configuration, summary and concise diagnostics. Shell startup activates it independently of Control Centre. `weather.py` uses Python stdlib HTTPS/JSON only. No daemon, package or API key is added. The UI sends no request itself.

Verified official sources on 2026-10-17:

- [Open-Meteo forecast API](https://open-meteo.com/en/docs): `/v1/forecast`, current temperature/weather code, Celsius units and Unix observation time; documented WMO code mapping. MAGI requests only those current fields. No HTML scraping.
- [Open-Meteo geocoding API](https://open-meteo.com/en/docs/geocoding-api): explicit name/postcode query, bounded result count, optional geographic qualifiers, latitude/longitude and resolved name. MAGI uses one best match and shows its resolved place in Settings; refine an ambiguous query with country/region. Location data attribution is GeoNames; weather attribution Open-Meteo.

Weather is disabled and unconfigured by default. Save location is deliberate, so typing does not trigger searches. No IP/system geolocation exists. Only the explicitly configured query is geocoded. A single process is active; a changed configuration coalesces and stale replies are discarded. Configuration changes are debounced 750ms. Refresh is internally fixed at 30 minutes, not tied to CC opening. Each HTTP read has an 8-second timeout and 128KiB limit; the process has a 20-second watchdog. Failures retry on the normal interval, not rapidly.

The cache at `$XDG_CACHE_HOME/magi/weather/current.json` holds only the latest query hash, resolved place/coordinates and successful Celsius observation/timestamps (0600 file). It is reused across unit changes/restarts; coordinates are reused for an unchanged query. A failed refresh may retain an observation at most three hours old. A different location never borrows the previous location's weather. Units are formatted locally from Celsius. Errors expose neither query URLs nor provider payloads. The profile fallback remains Weather unavailable when disabled, unconfigured or without usable data. Provider errors/unknown codes/malformed data fail honestly.

## Preserved architecture and retirement

Five-mode single Hub, persistent outside-click behavior, child-first Escape, Settings-in-Hub, real pinned CC preview, Wallpaper-in-Settings, Schema 12 retention/borders and exactly 48px reservation remain. No accepted layout redesign.

Eight unique routes pass static validation: Super+Space Apps; N Notifications; C Clipboard; E Emoji; M Control Centre; W Wi-Fi; B Bluetooth; S Hub Settings. No Hyprland edits in this pass. Existing isolated Phase 2E binding patch and dirty Theme Orchestrator hunks remain intact. Native compositor IPC is not claimed.

MFTrunk retirement remains intact; no files/routes restored. Rofi active config/assets/routes remain retired. `pacman -Q rofi` reports package not found after the operator's removal. No package removal or orphan cleanup was run. Active source/config whole-word references to either retired tool remain zero; historical retirement notes and negative tests remain.

## Validation

Focused production regressions (isolated configurations; no weather Internet dependency):

- Settings schema/store: new enum/role/integer/range validation, 11→12 preservation, save/reload/reset, atomic persistence and conflict handling.
- Settings presentation at 720×500 and 940×720 across five palettes; sidebar/save chip/selectors/swatches and existing controls.
- Hub modes/routing/pointer/keyboard, persistent outside click, Escape, compact notifications with DND/Clear/actions/dismiss, measured heights/anchor and no reservation.
- New typography/navigation/toggle production fixture across Mocha, Everforest Dark Hard and Everforest Light Hard: live selected roles/inactive/subnav separation; all three styles on/off/disabled/hover/focus, pointer and Space; min/max Profile/Media natural layout, independent weights, long metadata, artwork sizes, all transport modes, border widths 0/2/5, progress 0/.43/.99, playing/paused, corner extremes.
- Weather helper: eight offline fixture tests covering no location/disabled, geocoding, units, cache/refresh/location isolation, bounded request/timeout, stale failure, malformed data and condition codes. Real QML service + mocked network worker verifies initial state, location/unit refresh, in-flight replacement, diagnostics, Profile binding and natural height.
- Real pinned CC preview: typography/size/weight/border live updates, existing 96 hidden-section/gap combinations, navigation/session ownership and close cleanup.
- Notifications presentation/retention and private DBus protocol suite; protocol test runs outside sandbox solely because the private bus socket is blocked inside it, never on the operator notification bus.
- MPRIS service; Launcher UI and XDG/GIO/Ghostty adapter; Theme Orchestrator confirmation/pointer and exact Zen Copy; Settings Bar/CC reorder; static keybindings/Lua syntax.
- Runtime artwork/layout and Phase 2E.1 feedback fixtures; exact **600** old-reference Control Centre RGBA comparisons; shared-status-surface **48-step** lifecycle/reservation regression; controlled greeting boundaries; `git diff --check`.

Logs/snapshots: `/tmp/magi-phase2e2/`. Offscreen geometry does not establish GPU mask edges or native visual/animation quality.

## Protected state

627 snapshot entries captured before this pass at `/tmp/magi-phase2e2/snapshot.json`, with file copies. Comparison retains existing Settings backups, Theme Orchestrator integration files, Hypridle/Hyprlock, Yazi flavour and all dirty Hyprland hunks. No clean/reset/restore/stage operation occurred.

Observed concurrent runtime changes: live settings gained the new appearance defaults; the backup directory gained entries. Existing values were preserved; existing backup contents and all other protected files/links compare unchanged. These live/runtime paths are excluded from the intended source lists below. The final comparison must be refreshed if operator edits continue.

## Native review still required

Review navigation accent prominence and independent focus; all three switch styles in dark/light themes; primary row balance/drag; Profile Normal/Bold, both greetings and long names; explicit weather configuration/resolved place/live provider result and failure recovery; Media typography/centering/transport modes and 0–5px progress edge quality; compact Notifications DND/Clear row. Confirm pinned preview updates and existing Hub lifecycle. Provider integration is fixture-verified; actual location/network and GPU rendering remain native checks.

No next milestone started. No commit or push.

## Exact paths changed during Phase 2E.2

<!-- phase2e2-paths -->

```text
linux/magi/.config/quickshell/magi/components/controls/CompactToggle.qml
linux/magi/.config/quickshell/magi/components/controls/VisualState.js
linux/magi/.config/quickshell/magi/components/hub/HubContent.qml
linux/magi/.config/quickshell/magi/components/notifications/NotificationContent.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsNavigationItem.qml
linux/magi/.config/quickshell/magi/components/settings/SettingsToggle.qml
linux/magi/.config/quickshell/magi/components/settings/VisualSettingsGroup.qml
linux/magi/.config/quickshell/magi/components/settings/pages/ControlCentrePage.qml
linux/magi/.config/quickshell/magi/components/settings/pages/ProfilePage.qml
linux/magi/.config/quickshell/magi/components/settings/pages/SurfacesPage.qml
linux/magi/.config/quickshell/magi/plugins/bar/controlcentre/MediaSection.qml
linux/magi/.config/quickshell/magi/plugins/bar/controlcentre/ProfileHeader.qml
linux/magi/.config/quickshell/magi/services/Weather.qml
linux/magi/.config/quickshell/magi/services/qmldir
linux/magi/.config/quickshell/magi/services/weather.py
linux/magi/.config/quickshell/magi/settings/SettingsSchema.js
linux/magi/.config/quickshell/magi/settings/SettingsStore.qml
linux/magi/.config/quickshell/magi/shell.qml
linux/magi/.config/quickshell/magi/theme/Theme.qml
linux/magi/docs/README.md
linux/magi/docs/architecture.md
linux/magi/docs/decisions.md
linux/magi/docs/design/runtime-phase2e2.md
linux/magi/docs/quickshell-reference.md
linux/magi/tests/hub/actions.qml
linux/magi/tests/hub/notifications.qml
linux/magi/tests/runtime-visual/appearance.qml
linux/magi/tests/runtime-visual/run.py
linux/magi/tests/runtime-visual/runtime.qml
linux/magi/tests/runtime-visual/typography.qml
linux/magi/tests/runtime-visual/weather.qml
linux/magi/tests/settings/schema.cjs
linux/magi/tests/settings/store.qml
linux/magi/tests/visual/state.cjs
linux/magi/tests/weather/backend.py
linux/magi/tests/weather/fixture.py
```

36 changed paths in this feedback pass.

## Cumulative intended Phase 2E / 2E.1 / 2E.2 paths

```text
README.md
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
linux/magi/docs/design/runtime-phase2e.md
linux/magi/docs/design/runtime-phase2e1.md
linux/magi/docs/design/runtime-phase2e2.md
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

149 cumulative intended paths; Hyprland remains a partial-file change from earlier work. Protected/operator-local state is excluded.
