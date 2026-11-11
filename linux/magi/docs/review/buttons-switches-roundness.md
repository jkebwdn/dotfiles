# Buttons and switches: focused roundness audit

Historical audit retained. The operator subsequently approved the
[Pass 2 default UI roundness model](controlcentre-settings-pass2.md): generic action
consumers follow Appearance/surface; the old field stays compatibility-only and
its normal editor is removed. The findings below describe the prior review.

2026-11-10; runtime reference `fa40a70`, with only uncommitted editor redistribution.
Classification: **INVESTIGATE FURTHER** for permanent UI ownership. Keep the field
and editor for this review, temporarily under Control Centre → Roundness →
Shared buttons & switches · review. This is a MAGI-wide role, not a Control Centre
role; no merge or removal is proposed for this commit. Appearance remains limited
to the shared-shell slider as requested.

Field: `appearance.roundness.roles.action`. Stored/effective current value:
`1.2000000000000002` (displayed 1.20×). Default `null`; multiplier 0–2, step 0.05.
Null follows `appearance.roundness.master` (currently 1), **not** Shell surfaces,
Primary controls or Secondary controls. Checking inheritance discards the custom
number; unchecking starts at the current saved base. There is no persisted old
custom-value slot to restore. No passive page visit creates an override.

## What changes

| Surface/control | Effect of action roundness |
| --- | --- |
| Buttons / icon buttons | ActionChip, IconButton, MediaButton hover/focus; Settings buttons, navigation, disclosure and focus outlines |
| Switch tracks | CompactToggle track radius in pill, filled and minimal styles |
| Toggle handles | CompactToggle knob radius and focus ring; style/size/position remain owned by the separate style selector |
| Settings controls | Button, text input, number stepper, selector field/delegates, drag handles, choice/gallery/result cards and focus outlines |
| Settings sliders | Focus outline only; their track/knob use fixed internal radii, not this field |
| Bar controls | Tray item hover; battery submenu surface; Wi-Fi/Bluetooth menu rows, authentication fields/buttons, shared action chips |
| Bar pill contours/joins | **No**; barPill and inherited workspace own those |
| Hub controls | Search field and clipboard/emoji/launcher result cards; not Hub selector or outer Hub content |
| Control Centre | Shared UI primitives/previews/media transport controls; **not** primary tile or secondary ActionButton contours |
| Lock controls | No native lock credential or avatar contour change. Settings controls on the Lock Screen page use normal shared UI styling |
| Artwork | Notification thumbnail/action backgrounds and wallpaper tiles use action; CC media crop uses albumArt and identity uses avatar |
| Other surfaces | Calendar day cells, notification action buttons and various selection previews |

`Theme.radiusSmall` is an action-derived 6px-reference alias, consumed by media
buttons and Bar popup controls. There are **45 direct binding/alias sites in 34
files**, listed below: 44 consumer bindings plus the Theme alias export.
The new generic RoundnessValue preview adds one dynamically selected binding
for action (46 sites in 35 files when that editor preview is included). These
are source locations, not independent preferences or a count of on-screen instances.
Generic Settings primitives naturally propagate to all pages using them.

## Distinct from Primary and Secondary controls

Primary controls read `controlTile` (10px base), including profile/media container
backgrounds. Secondary ActionButton reads `secondaryControl` (10px outer base,
1px inner glyph treatment). Neither reads action. Historical migrations copied
old action values into albumArt/secondaryControl when those roles were introduced;
that is migration history, not a current live inheritance relationship.

Focused Qt tests hold Primary at 1.25, Secondary at 1.2 and avatar at 1.2 while
changing action through 0 / 1.2000000000000002 / 2. Their radii remain identical.
Buttons, search/results and number/selector controls visibly change.

At multiplier **1 or above**, several controls are already geometrically saturated:
CompactToggle uses half-height/half-width references, and ActionChip is a pill.
Consequently 1.2 → 2 does not round those tracks/handles/chips further. It can still
change a Settings button (8px reference: 9.6 → 16px), Hub search (10px reference:
12 → 20px) and other controls with room before their half-size clamp. This explains
why moving the slider can appear ineffective on switches while changing other UI.
No new clamping was added.

## Focused evidence

`$STATE/magi/audits/roundness-centralization-oj03ofrt/feature-ownership/impact/`:

- `nord-action-{min,current,max}.png`
- `one-light-action-{min,current,max}.png`
- `{nord,one-light}-media-button-{min,current,max}.png` (focused MediaButton)

These render the actual SettingsButton, SettingsTextField, SettingsNumber,
SettingsSelector, HubSearchField, LauncherItem, ActionChip, IconButton, CompactToggle
(all three styles), ControlTile, ActionButton and RoundedArtwork components.
Software captures demonstrate contours; some semantic icon/artwork shaders are
not painted by the software backend. Native visual review remains separate.
The fixture uses private Settings and restores its original roundness/theme values.
The broad baseline/candidate comparison has zero Settings writes and pixel-identical
results with unchanged values. Production renderers, schema and migrations remain
byte-identical.

## Direct binding map

Paths below are relative to MAGI. The same unchanged runtime files are present in
`fa40a70`; the CC inspector's line number reflects removal of old numeric editors.

- [.config/quickshell/magi/components/calendar/CalendarContent.qml:101](../../.config/quickshell/magi/components/calendar/CalendarContent.qml#L101) — `radius: Theme.Theme.radius("action", 8, width, height)`

- [.config/quickshell/magi/components/clipboard/ClipboardContent.qml:176](../../.config/quickshell/magi/components/clipboard/ClipboardContent.qml#L176) — `radius: Theme.Theme.radius("action", 9, width, height)`

- [.config/quickshell/magi/components/controls/ActionChip.qml:19](../../.config/quickshell/magi/components/controls/ActionChip.qml#L19) — `radius: MagiTheme.Theme.radius("action", 13, width, height)`

- [.config/quickshell/magi/components/controls/CompactToggle.qml:26](../../.config/quickshell/magi/components/controls/CompactToggle.qml#L26) — `radius: Theme.Theme.radius("action", height / 2, width, height)`

- [.config/quickshell/magi/components/controls/CompactToggle.qml:37](../../.config/quickshell/magi/components/controls/CompactToggle.qml#L37) — `radius: Theme.Theme.radius("action", width / 2, width, height)`

- [.config/quickshell/magi/components/controls/CompactToggle.qml:44](../../.config/quickshell/magi/components/controls/CompactToggle.qml#L44) — `radius: Theme.Theme.radius("action", 11, width, height)`

- [.config/quickshell/magi/components/controls/IconButton.qml:16](../../.config/quickshell/magi/components/controls/IconButton.qml#L16) — `radius: Theme.Theme.radius("action", 7, width, height)`

- [.config/quickshell/magi/components/controls/MediaButton.qml:16](../../.config/quickshell/magi/components/controls/MediaButton.qml#L16) — `Rectangle { anchors.fill: parent; radius: Theme.Theme.radiusSmall; color: root.available && hover.hovered ? Theme.Theme.overlay : "transparent"; border.width: root.activeFocus ? 1 : 0; border.color: Theme.Theme.focus }`

- [.config/quickshell/magi/components/emoji/EmojiContent.qml:109](../../.config/quickshell/magi/components/emoji/EmojiContent.qml#L109) — `radius: Theme.Theme.radius("action", 10, width, height)`

- [.config/quickshell/magi/components/hub/HubSearchField.qml:16](../../.config/quickshell/magi/components/hub/HubSearchField.qml#L16) — `radius: Theme.Theme.radius("action", 10, width, height)`

- [.config/quickshell/magi/components/launcher/LauncherItem.qml:15](../../.config/quickshell/magi/components/launcher/LauncherItem.qml#L15) — `radius: Theme.Theme.radius("action", 12, width, height)`

- [.config/quickshell/magi/components/notifications/NotificationCard.qml:44](../../.config/quickshell/magi/components/notifications/NotificationCard.qml#L44) — `radius: Theme.Theme.radius("action", 8, width, height)`

- [.config/quickshell/magi/components/notifications/NotificationCard.qml:110](../../.config/quickshell/magi/components/notifications/NotificationCard.qml#L110) — `radius: Theme.Theme.radius("action", 6, width, height)`

- [.config/quickshell/magi/components/settings/CCInspector.qml:338](../../.config/quickshell/magi/components/settings/CCInspector.qml#L338) — `radius: Theme.Theme.radiusSmall`

- [.config/quickshell/magi/components/settings/ControlCentrePreview.qml:297](../../.config/quickshell/magi/components/settings/ControlCentrePreview.qml#L297) — `radius: Theme.Theme.radius("action", 8, width, height)`

- [.config/quickshell/magi/components/settings/PreviewControlGrid.qml:116](../../.config/quickshell/magi/components/settings/PreviewControlGrid.qml#L116) — `radius: Theme.Theme.radius("action", 8, width, height)`

- [.config/quickshell/magi/components/settings/SettingsButton.qml:31](../../.config/quickshell/magi/components/settings/SettingsButton.qml#L31) — `radius: Theme.Theme.radius("action", 8, width, height)`

- [.config/quickshell/magi/components/settings/SettingsChoiceCard.qml:24](../../.config/quickshell/magi/components/settings/SettingsChoiceCard.qml#L24) — `radius: Theme.Theme.radius("action", 12, width, height)`

- [.config/quickshell/magi/components/settings/SettingsContent.qml:145](../../.config/quickshell/magi/components/settings/SettingsContent.qml#L145) — `radius: Theme.Theme.radius("action", 8, width, height)`

- [.config/quickshell/magi/components/settings/SettingsDragHandle.qml:25](../../.config/quickshell/magi/components/settings/SettingsDragHandle.qml#L25) — `radius: Theme.Theme.radius("action", 8, width, height)`

- [.config/quickshell/magi/components/settings/SettingsDragHandle.qml:59](../../.config/quickshell/magi/components/settings/SettingsDragHandle.qml#L59) — `radius: Theme.Theme.radius("action", 8, width, height)`

- [.config/quickshell/magi/components/settings/SettingsFocus.qml:9](../../.config/quickshell/magi/components/settings/SettingsFocus.qml#L9) — `radius: Theme.Theme.radius("action", 8, width, height)`

- [.config/quickshell/magi/components/settings/SettingsNavigationItem.qml:31](../../.config/quickshell/magi/components/settings/SettingsNavigationItem.qml#L31) — `radius: Theme.Theme.radius("action", 7, width, height)`

- [.config/quickshell/magi/components/settings/SettingsNumber.qml:30](../../.config/quickshell/magi/components/settings/SettingsNumber.qml#L30) — `radius: Theme.Theme.radius("action", 5, width, height)`

- [.config/quickshell/magi/components/settings/SettingsNumber.qml:37](../../.config/quickshell/magi/components/settings/SettingsNumber.qml#L37) — `radius: Theme.Theme.radius("action", 5, width, height)`

- [.config/quickshell/magi/components/settings/SettingsNumber.qml:42](../../.config/quickshell/magi/components/settings/SettingsNumber.qml#L42) — `radius: Theme.Theme.radius("action", 8, width, height)`

- [.config/quickshell/magi/components/settings/SettingsReorderBoard.qml:292](../../.config/quickshell/magi/components/settings/SettingsReorderBoard.qml#L292) — `radius: Theme.Theme.radius("action", 8, width, height)`

- [.config/quickshell/magi/components/settings/SettingsSection.qml:63](../../.config/quickshell/magi/components/settings/SettingsSection.qml#L63) — `radius: Theme.Theme.radius("action", 8, width, height)`

- [.config/quickshell/magi/components/settings/SettingsSelector.qml:59](../../.config/quickshell/magi/components/settings/SettingsSelector.qml#L59) — `radius: Theme.Theme.radius("action", 8, width, height)`

- [.config/quickshell/magi/components/settings/SettingsSelector.qml:77](../../.config/quickshell/magi/components/settings/SettingsSelector.qml#L77) — `radius: Theme.Theme.radius("action", 6, width, height)`

- [.config/quickshell/magi/components/settings/SettingsTextField.qml:15](../../.config/quickshell/magi/components/settings/SettingsTextField.qml#L15) — `radius: Theme.Theme.radius("action", 8, width, height)`

- [.config/quickshell/magi/components/settings/ThemeGallery.qml:185](../../.config/quickshell/magi/components/settings/ThemeGallery.qml#L185) — `radius: Theme.Theme.radius("action", 6, width, height)`

- [.config/quickshell/magi/components/settings/ThemeGallery.qml:189](../../.config/quickshell/magi/components/settings/ThemeGallery.qml#L189) — `radius: Theme.Theme.radius("action", 5, width, height)`

- [.config/quickshell/magi/components/tray/TrayItem.qml:49](../../.config/quickshell/magi/components/tray/TrayItem.qml#L49) — `radius: Theme.Theme.radius("action", 7, width, height)`

- [.config/quickshell/magi/components/wallpaper/WallpaperTile.qml:20](../../.config/quickshell/magi/components/wallpaper/WallpaperTile.qml#L20) — `radius: Theme.Theme.radius("action", 8, width, height)`

- [.config/quickshell/magi/components/wallpaper/WallpaperTile.qml:33](../../.config/quickshell/magi/components/wallpaper/WallpaperTile.qml#L33) — `radius: Theme.Theme.radius("action", 6, width, height)`

- [.config/quickshell/magi/plugins/bar/battery/Battery.qml:38](../../.config/quickshell/magi/plugins/bar/battery/Battery.qml#L38) — `radius: MagiTheme.Theme.radiusSmall`

- [.config/quickshell/magi/plugins/bar/bluetooth/Bluetooth.qml:293](../../.config/quickshell/magi/plugins/bar/bluetooth/Bluetooth.qml#L293) — `radius: MagiTheme.Theme.radiusSmall`

- [.config/quickshell/magi/plugins/bar/bluetooth/BluetoothAuthentication.qml:55](../../.config/quickshell/magi/plugins/bar/bluetooth/BluetoothAuthentication.qml#L55) — `radius: MagiTheme.Theme.radiusSmall`

- [.config/quickshell/magi/plugins/bar/wifi/WifiAuthentication.qml:21](../../.config/quickshell/magi/plugins/bar/wifi/WifiAuthentication.qml#L21) — `radius: Theme.Theme.radiusSmall`

- [.config/quickshell/magi/plugins/bar/wifi/WifiMenuContent.qml:99](../../.config/quickshell/magi/plugins/bar/wifi/WifiMenuContent.qml#L99) — `radius: Theme.Theme.radiusSmall`

- [.config/quickshell/magi/plugins/bar/wifi/WifiPasswordWindow.qml:76](../../.config/quickshell/magi/plugins/bar/wifi/WifiPasswordWindow.qml#L76) — `radius: MagiTheme.Theme.radiusSmall`

- [.config/quickshell/magi/plugins/bar/wifi/WifiPasswordWindow.qml:112](../../.config/quickshell/magi/plugins/bar/wifi/WifiPasswordWindow.qml#L112) — `radius: MagiTheme.Theme.radiusSmall`

- [.config/quickshell/magi/plugins/bar/wifi/WifiPasswordWindow.qml:142](../../.config/quickshell/magi/plugins/bar/wifi/WifiPasswordWindow.qml#L142) — `radius: MagiTheme.Theme.radiusSmall`

- [.config/quickshell/magi/theme/Theme.qml:111](../../.config/quickshell/magi/theme/Theme.qml#L111) — `readonly property real radiusSmall: radius("action", 6, 1000, 1000)`

- [components/settings/RoundnessValue.qml:61](../../.config/quickshell/magi/components/settings/RoundnessValue.qml#L61) — `Theme.Theme.radius(root.fieldKey, root.reference, width, height)` with `fieldKey: "action"` in the CC shared-controls editor. This is a lightweight numeric preview, not a new runtime role.
