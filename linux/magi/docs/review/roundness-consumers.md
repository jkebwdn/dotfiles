# Roundness consumer and geometry map

Source baseline: `eb19df4`; audit date 2026-11-10. Paths are MAGI-relative.

Numeric fields are listed in [the complete control inventory](roundness-controls.csv). Direct role calls, exported aliases and native avatar bridges are enumerated below. Component-level propagation follows the graph after the lists; an inspector writing a value is not itself a painted consumer.

## barPill

- [.config/quickshell/magi/components/bar/Bar.qml:138](../../.config/quickshell/magi/components/bar/Bar.qml#L138) — `cornerRadius: MagiTheme.Theme.barPillRadius`
- [.config/quickshell/magi/components/bar/Bar.qml:322](../../.config/quickshell/magi/components/bar/Bar.qml#L322) — `pillRadius: MagiTheme.Theme.barPillRadius,`
- [.config/quickshell/magi/components/bar/ExpandablePlugin.qml:98](../../.config/quickshell/magi/components/bar/ExpandablePlugin.qml#L98) — `radius: MagiTheme.Theme.barPillRadius`
- [.config/quickshell/magi/components/bar/ExpandablePlugin.qml:102](../../.config/quickshell/magi/components/bar/ExpandablePlugin.qml#L102) — `: MagiTheme.Theme.barPillRadius`
- [.config/quickshell/magi/components/bar/ExpandablePlugin.qml:105](../../.config/quickshell/magi/components/bar/ExpandablePlugin.qml#L105) — `: MagiTheme.Theme.barPillRadius`
- [.config/quickshell/magi/components/bar/SharedStatusSurface.qml:230](../../.config/quickshell/magi/components/bar/SharedStatusSurface.qml#L230) — `radius: MagiTheme.Theme.barPillRadius + root.expansion *`
- [.config/quickshell/magi/components/bar/SharedStatusSurface.qml:231](../../.config/quickshell/magi/components/bar/SharedStatusSurface.qml#L231) — `(root.presentation(root.displayedModule, "viewRadius", MagiTheme.Theme.radiusMedium) - MagiTheme.Theme.barPillRadius)`
- [.config/quickshell/magi/components/bar/StatusPill.qml:9](../../.config/quickshell/magi/components/bar/StatusPill.qml#L9) — `radius: Theme.Theme.barPillRadius`
- [.config/quickshell/magi/components/bar/UtilityPill.qml:18](../../.config/quickshell/magi/components/bar/UtilityPill.qml#L18) — `radius: Theme.Theme.barPillRadius`
- [.config/quickshell/magi/components/calendar/TimeDatePill.qml:17](../../.config/quickshell/magi/components/calendar/TimeDatePill.qml#L17) — `radius: Theme.Theme.barPillRadius`
- [.config/quickshell/magi/components/tray/TrayGroup.qml:44](../../.config/quickshell/magi/components/tray/TrayGroup.qml#L44) — `background: Rectangle { radius: Theme.Theme.barPillRadius; color: parent.hovered || parent.activeFocus ? Theme.Theme.overlay : "transparent" }`
- [.config/quickshell/magi/theme/Theme.qml:123](../../.config/quickshell/magi/theme/Theme.qml#L123) — `? barPillRadius : Math.min(14, 8 * barVisual.workspacePills.roundness)`
- [.config/quickshell/magi/theme/Theme.qml:164](../../.config/quickshell/magi/theme/Theme.qml#L164) — `readonly property real barPillRadius: radius("barPill", 8, 28, 28)`

## surface

- [.config/quickshell/magi/components/bar/ExpandableModule.qml:52](../../.config/quickshell/magi/components/bar/ExpandableModule.qml#L52) — `property real viewRadius: MagiTheme.Theme.radiusMedium`
- [.config/quickshell/magi/components/bar/ExpandablePlugin.qml:42](../../.config/quickshell/magi/components/bar/ExpandablePlugin.qml#L42) — `property real viewRadius: MagiTheme.Theme.radiusMedium`
- [.config/quickshell/magi/components/bar/SharedStatusSurface.qml:231](../../.config/quickshell/magi/components/bar/SharedStatusSurface.qml#L231) — `(root.presentation(root.displayedModule, "viewRadius", MagiTheme.Theme.radiusMedium) - MagiTheme.Theme.barPillRadius)`
- [.config/quickshell/magi/components/bar/menu/AnchoredPopupHost.qml:75](../../.config/quickshell/magi/components/bar/menu/AnchoredPopupHost.qml#L75) — `bottomLeftRadius: Math.min(MagiTheme.Theme.radiusMedium, height / 2)`
- [.config/quickshell/magi/components/bar/menu/AnchoredPopupHost.qml:89](../../.config/quickshell/magi/components/bar/menu/AnchoredPopupHost.qml#L89) — `MagiTheme.Theme.radiusMedium, height / 2`
- [.config/quickshell/magi/components/bar/menu/AnchoredPopupHost.qml:92](../../.config/quickshell/magi/components/bar/menu/AnchoredPopupHost.qml#L92) — `MagiTheme.Theme.radiusMedium, height / 2`
- [.config/quickshell/magi/components/bar/menu/CombinedMenuHost.qml:54](../../.config/quickshell/magi/components/bar/menu/CombinedMenuHost.qml#L54) — `MagiTheme.Theme.radiusMedium, height / 2`
- [.config/quickshell/magi/components/bar/menu/CombinedMenuHost.qml:57](../../.config/quickshell/magi/components/bar/menu/CombinedMenuHost.qml#L57) — `MagiTheme.Theme.radiusMedium, height / 2`
- [.config/quickshell/magi/components/calendar/CalendarSurface.qml:43](../../.config/quickshell/magi/components/calendar/CalendarSurface.qml#L43) — `property real viewRadius: Theme.Theme.radius("surface", 11, expandedWidth, menuHeight)`
- [.config/quickshell/magi/components/clipboard/ClipboardCardFrame.qml:7](../../.config/quickshell/magi/components/clipboard/ClipboardCardFrame.qml#L7) — `radius: Theme.Theme.radius("surface", 11, width, height)`
- [.config/quickshell/magi/components/clipboard/ClipboardContent.qml:29](../../.config/quickshell/magi/components/clipboard/ClipboardContent.qml#L29) — `radius: Theme.Theme.radius("surface", 18, width, height)`
- [.config/quickshell/magi/components/emoji/EmojiContent.qml:35](../../.config/quickshell/magi/components/emoji/EmojiContent.qml#L35) — `radius: Theme.Theme.radius("surface", 22, width, height)`
- [.config/quickshell/magi/components/hub/HubSurface.qml:7](../../.config/quickshell/magi/components/hub/HubSurface.qml#L7) — `radius: Theme.Theme.radius("surface", 11, width, height)`
- [.config/quickshell/magi/components/launcher/LauncherContent.qml:68](../../.config/quickshell/magi/components/launcher/LauncherContent.qml#L68) — `radius: Theme.Theme.radius("surface", 22, width, height)`
- [.config/quickshell/magi/components/notifications/NotificationCard.qml:21](../../.config/quickshell/magi/components/notifications/NotificationCard.qml#L21) — `radius: Theme.Theme.radius("surface", 12, width, height)`
- [.config/quickshell/magi/components/notifications/NotificationContent.qml:26](../../.config/quickshell/magi/components/notifications/NotificationContent.qml#L26) — `radius: Theme.Theme.radius("surface", 11, width, height)`
- [.config/quickshell/magi/components/settings/ApplicationAppearancePreview.qml:12](../../.config/quickshell/magi/components/settings/ApplicationAppearancePreview.qml#L12) — `radius: Theme.Theme.radius("surface", 12, width, height)`
- [.config/quickshell/magi/components/settings/BarCanvas.qml:63](../../.config/quickshell/magi/components/settings/BarCanvas.qml#L63) — `radius: Theme.Theme.radius("surface", 10, width, height)`
- [.config/quickshell/magi/components/settings/ControlCentrePreview.qml:242](../../.config/quickshell/magi/components/settings/ControlCentrePreview.qml#L242) — `radius: Theme.RenderTokens.outerRadius`
- [.config/quickshell/magi/components/settings/SettingsContent.qml:77](../../.config/quickshell/magi/components/settings/SettingsContent.qml#L77) — `radius: Theme.Theme.radius("surface", 11, width, height)`
- [.config/quickshell/magi/components/settings/SettingsReorderBoard.qml:247](../../.config/quickshell/magi/components/settings/SettingsReorderBoard.qml#L247) — `radius: Theme.Theme.radius("surface", 10, width, height)`
- [.config/quickshell/magi/components/settings/SettingsSection.qml:25](../../.config/quickshell/magi/components/settings/SettingsSection.qml#L25) — `radius: Theme.Theme.radius("surface", 12, width, height)`
- [.config/quickshell/magi/components/settings/SettingsSelector.qml:98](../../.config/quickshell/magi/components/settings/SettingsSelector.qml#L98) — `radius: Theme.Theme.radius("surface", 10, width, height)`
- [.config/quickshell/magi/components/tray/TrayItem.qml:95](../../.config/quickshell/magi/components/tray/TrayItem.qml#L95) — `background: Rectangle { radius: Theme.Theme.radiusMedium; color: Theme.Theme.surfaceBackground(Theme.Theme.elevated); border.color: Theme.Theme.border; border.width: 1 }`
- [.config/quickshell/magi/components/tray/TrayOverflow.qml:25](../../.config/quickshell/magi/components/tray/TrayOverflow.qml#L25) — `radius: Theme.Theme.radiusMedium`
- [.config/quickshell/magi/components/wallpaper/WallpaperWindow.qml:28](../../.config/quickshell/magi/components/wallpaper/WallpaperWindow.qml#L28) — `background: Rectangle { color: Theme.Theme.surface; radius: Theme.Theme.radius("surface", 11, width, height) }`
- [.config/quickshell/magi/plugins/bar/bluetooth/Bluetooth.qml:128](../../.config/quickshell/magi/plugins/bar/bluetooth/Bluetooth.qml#L128) — `radius: MagiTheme.Theme.radiusMedium`
- [.config/quickshell/magi/plugins/bar/controlcentre/ControlCentre.qml:65](../../.config/quickshell/magi/plugins/bar/controlcentre/ControlCentre.qml#L65) — `viewRadius: Theme.RenderTokens.outerRadius`
- [.config/quickshell/magi/plugins/bar/wifi/WifiMenuContent.qml:43](../../.config/quickshell/magi/plugins/bar/wifi/WifiMenuContent.qml#L43) — `radius: Theme.Theme.radiusMedium; color: Theme.Theme.elevated`
- [.config/quickshell/magi/plugins/bar/wifi/WifiPasswordWindow.qml:53](../../.config/quickshell/magi/plugins/bar/wifi/WifiPasswordWindow.qml#L53) — `radius: MagiTheme.Theme.radiusMedium`
- [.config/quickshell/magi/theme/RenderTokens.qml:11](../../.config/quickshell/magi/theme/RenderTokens.qml#L11) — `readonly property real outerRadius: Theme.radius("surface", 11, controlWidth, controlBodyHeight)`
- [.config/quickshell/magi/theme/Theme.qml:112](../../.config/quickshell/magi/theme/Theme.qml#L112) — `readonly property real radiusMedium: radius("surface", 10, 1000, 1000)`
- [.config/quickshell/magi/theme/Theme.qml:113](../../.config/quickshell/magi/theme/Theme.qml#L113) — `readonly property real radiusLarge: radius("surface", 14, 1000, 1000)`

## controlTile

- [.config/quickshell/magi/plugins/bar/controlcentre/ControlTile.qml:24](../../.config/quickshell/magi/plugins/bar/controlcentre/ControlTile.qml#L24) — `radius: MagiTheme.RenderTokens.tileRadius`
- [.config/quickshell/magi/plugins/bar/controlcentre/MediaSection.qml:14](../../.config/quickshell/magi/plugins/bar/controlcentre/MediaSection.qml#L14) — `radius: Theme.Theme.radius("controlTile", 10, width, height)`
- [.config/quickshell/magi/plugins/bar/controlcentre/ProfileHeader.qml:11](../../.config/quickshell/magi/plugins/bar/controlcentre/ProfileHeader.qml#L11) — `radius: Theme.Theme.radius("controlTile", 10, width, height)`
- [.config/quickshell/magi/theme/RenderTokens.qml:17](../../.config/quickshell/magi/theme/RenderTokens.qml#L17) — `readonly property real tileRadius: Theme.radius("controlTile", 10, tileSize, tileSize)`

## slider

- [.config/quickshell/magi/components/controls/IconSlider.qml:32](../../.config/quickshell/magi/components/controls/IconSlider.qml#L32) — `radius: MagiTheme.RenderTokens.sliderRadius`
- [.config/quickshell/magi/components/controls/IconSlider.qml:41](../../.config/quickshell/magi/components/controls/IconSlider.qml#L41) — `radius: Math.min(width / 2, Math.max(0, MagiTheme.RenderTokens.sliderRadius`
- [.config/quickshell/magi/components/controls/ValueSlider.qml:28](../../.config/quickshell/magi/components/controls/ValueSlider.qml#L28) — `radius: MagiTheme.Theme.radius("slider", height / 2, width, height)`
- [.config/quickshell/magi/components/controls/ValueSlider.qml:44](../../.config/quickshell/magi/components/controls/ValueSlider.qml#L44) — `radius: MagiTheme.Theme.radius("slider", width / 2, width, height)`
- [.config/quickshell/magi/theme/RenderTokens.qml:25](../../.config/quickshell/magi/theme/RenderTokens.qml#L25) — `readonly property real sliderRadius: Theme.radius("slider", 10, 1000, sliderHeight)`

## action

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
- [.config/quickshell/magi/components/settings/CCInspector.qml:422](../../.config/quickshell/magi/components/settings/CCInspector.qml#L422) — `radius: Theme.Theme.radiusSmall`
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
- [.config/quickshell/magi/components/settings/ThemeGallery.qml:183](../../.config/quickshell/magi/components/settings/ThemeGallery.qml#L183) — `radius: Theme.Theme.radius("action", 6, width, height)`
- [.config/quickshell/magi/components/settings/ThemeGallery.qml:187](../../.config/quickshell/magi/components/settings/ThemeGallery.qml#L187) — `radius: Theme.Theme.radius("action", 5, width, height)`
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

## avatar

- [.config/quickshell/magi/components/settings/CCInspector.qml:90](../../.config/quickshell/magi/components/settings/CCInspector.qml#L90) — `value: Services.Settings.data.appearance.roundness.roles.avatar ?? Services.Settings.data.appearance.roundness.master`
- [.config/quickshell/magi/components/settings/LockLayoutCanvas.qml:15](../../.config/quickshell/magi/components/settings/LockLayoutCanvas.qml#L15) — `property real avatarRadius: 12`
- [.config/quickshell/magi/components/settings/LockLayoutCanvas.qml:80](../../.config/quickshell/magi/components/settings/LockLayoutCanvas.qml#L80) — `visual: Object.assign({},root.palette,{displayName:"Alex Morgan",avatarRadius:root.avatarRadius,background:previewBackground.ready ? "#00000000" : (root.palette.background || "#1e1e2e"),lockScreen:root.depthPreview ? Object.assign({},root.presented,{effects:Object.assign({},root.presented.effects,{depth:true})}) : root.presented,depthAvailable:root.depthPreview,weather:{available:true,temperature:"12°",condition:"Partly cloudy",location:"Sample city"},media:{available:true,title:"Morning light",artist:"Sample artist",playing:true,artwork:true}})`
- [.config/quickshell/magi/components/settings/LockThemePreview.qml:13](../../.config/quickshell/magi/components/settings/LockThemePreview.qml#L13) — `property real avatarRadius: 12`
- [.config/quickshell/magi/components/settings/LockThemePreview.qml:35](../../.config/quickshell/magi/components/settings/LockThemePreview.qml#L35) — `Rectangle {visible:module.modelData==="identity";objectName:"lockThemeAvatar";width:124;height:124;radius:root.layout.effects.avatar==="frame" ? 4 : root.avatarRadius;antialiasing:true;anchors.horizontalCenter:parent.horizontalCenter;color:Theme.Theme.elevated;border.color:Theme.Theme.accent;border.width:4}`
- [.config/quickshell/magi/components/settings/pages/LockScreenPage.qml:25](../../.config/quickshell/magi/components/settings/pages/LockScreenPage.qml#L25) — `readonly property real avatarRadius: {`
- [.config/quickshell/magi/components/settings/pages/LockScreenPage.qml:27](../../.config/quickshell/magi/components/settings/pages/LockScreenPage.qml#L27) — `const override=rounding.roles.avatar`
- [.config/quickshell/magi/components/settings/pages/LockScreenPage.qml:51](../../.config/quickshell/magi/components/settings/pages/LockScreenPage.qml#L51) — `UI.LockThemePreview {Layout.fillWidth:true;Layout.preferredHeight:width*9/16;Layout.minimumHeight:width*9/16;Layout.maximumHeight:width*9/16;themeId:card.modelData.id;wallpaperSource:root.wallpaperSource;backgroundBlur:root.layout.effects.blur;avatarRadius:root.avatarRadius;selectedLayout:card.selected ? root.layout : null}`
- [.config/quickshell/magi/components/settings/pages/LockScreenPage.qml:65](../../.config/quickshell/magi/components/settings/pages/LockScreenPage.qml#L65) — `aspect:Math.max(.5,Screen.width/Math.max(1,Screen.height));layout:root.layout;palette:root.colors;interactive:false;wallpaperSource:root.wallpaperSource;avatarRadius:root.avatarRadius`
- [.config/quickshell/magi/components/settings/pages/ProfilePage.qml:26](../../.config/quickshell/magi/components/settings/pages/ProfilePage.qml#L26) — `radius: Theme.Theme.radius("avatar", 10, width, height)`
- [.config/quickshell/magi/plugins/bar/controlcentre/ProfileHeader.qml:29](../../.config/quickshell/magi/plugins/bar/controlcentre/ProfileHeader.qml#L29) — `radius: Theme.Theme.radius("avatar", 10, width, height)`
- [native/lock/qml/LockProfile.qml:16](../../native/lock/qml/LockProfile.qml#L16) — `radius: root.treatment === "frame" ? 4 : tokens.avatarRadius; color: root.compact && root.nativeArtwork && root.artworkAvailable ? "transparent" : tokens.surface`
- [native/lock/qml/LockTokens.qml:27](../../native/lock/qml/LockTokens.qml#L27) — `readonly property real avatarRadius: palette.avatarRadius === undefined ? 12 : palette.avatarRadius`
- [native/lock/src/presentation.cpp:31](../../native/lock/src/presentation.cpp#L31) — `const double outerRadius=effects.value("avatar").toString()=="frame" ? 4.0 : data.values.value("avatarRadius",12).toDouble();`
- [native/lock/src/visual_data.cpp:54](../../native/lock/src/visual_data.cpp#L54) — `{"wallpaperTint",wallpaperTint},{"fontFamily","JetBrainsMono Nerd Font"},{"displayName",identity},{"avatarRadius",12.0}};`
- [native/lock/src/visual_data.cpp:82](../../native/lock/src/visual_data.cpp#L82) — `result.values["avatarRadius"]=qBound(0.0,12.0*radius.toDouble(roundness["master"].toDouble(1.0)),48.0);`

## albumArt

- [.config/quickshell/magi/plugins/bar/controlcentre/MediaSection.qml:25](../../.config/quickshell/magi/plugins/bar/controlcentre/MediaSection.qml#L25) — `radius: Theme.Theme.radius("albumArt", 10, width, height)`

## hubSelector

- [.config/quickshell/magi/components/hub/HubSelector.qml:18](../../.config/quickshell/magi/components/hub/HubSelector.qml#L18) — `radius: Theme.Theme.radius("hubSelector", 22, width, height)`

## secondaryControl

- [.config/quickshell/magi/plugins/bar/controlcentre/ActionButton.qml:25](../../.config/quickshell/magi/plugins/bar/controlcentre/ActionButton.qml#L25) — `radius: Theme.Theme.radius("secondaryControl", 10, width, height)`
- [.config/quickshell/magi/plugins/bar/controlcentre/ActionButton.qml:47](../../.config/quickshell/magi/plugins/bar/controlcentre/ActionButton.qml#L47) — `radius: Theme.Theme.radius("secondaryControl", 1, width, height)`

## workspace

- [.config/quickshell/magi/plugins/bar/workspaces/Workspaces.qml:16](../../.config/quickshell/magi/plugins/bar/workspaces/Workspaces.qml#L16) — `radius: MagiTheme.Theme.workspacePillRadius`
- [.config/quickshell/magi/settings/SettingsSchema.js:210](../../.config/quickshell/magi/settings/SettingsSchema.js#L210) — `const workspaceRadius = effective.bar.visual.workspacePills.roundness`
- [.config/quickshell/magi/settings/SettingsSchema.js:212](../../.config/quickshell/magi/settings/SettingsSchema.js#L212) — `errors.push("bar.visual.workspacePills.roundness: invalid value")`
- [.config/quickshell/magi/settings/SettingsSchema.js:213](../../.config/quickshell/magi/settings/SettingsSchema.js#L213) — `effective.bar.visual.workspacePills.roundness = null`
- [.config/quickshell/magi/theme/Theme.qml:122](../../.config/quickshell/magi/theme/Theme.qml#L122) — `readonly property real workspacePillRadius: barVisual.workspacePills.roundness === null`
- [.config/quickshell/magi/theme/Theme.qml:123](../../.config/quickshell/magi/theme/Theme.qml#L123) — `? barPillRadius : Math.min(14, 8 * barVisual.workspacePills.roundness)`

## header

- [.config/quickshell/magi/components/launcher/LauncherContent.qml:81](../../.config/quickshell/magi/components/launcher/LauncherContent.qml#L81) — `radius: root.preferences.headerRadius`
- [.config/quickshell/magi/components/settings/pages/LauncherPage.qml:101](../../.config/quickshell/magi/components/settings/pages/LauncherPage.qml#L101) — `model: [{key:"headerRadius",label:"Header corner roundness",max:75}, {key:"headerBorderWidth",label:"Header border width",max:8}]`
- [.config/quickshell/magi/settings/SettingsSchema.js:87](../../.config/quickshell/magi/settings/SettingsSchema.js#L87) — `headerPosition: "top", headerFit: "cover", headerRadius: 12, headerBorderWidth: 1, headerBorderRole: "border"},`
- [.config/quickshell/magi/settings/SettingsSchema.js:368](../../.config/quickshell/magi/settings/SettingsSchema.js#L368) — `iconSize:[20,64], visibleRows:[3,12], gridColumns:[3,8], headerRadius:[0,75], headerBorderWidth:[0,8]}`

## master

- [.config/quickshell/magi/theme/Theme.qml:44](../../.config/quickshell/magi/theme/Theme.qml#L44) — `radius(): nullable role -> master -> reference * multiplier -> geometry clamp`
- [native/lock/src/visual_data.cpp:80](../../native/lock/src/visual_data.cpp#L80) — `native avatar override -> master -> 12px reference`

## Propagation beyond direct reads

- `Theme.radius` → `RenderTokens.outerRadius` → ControlCentre and ControlCentrePreview → ExpandablePlugin/SharedStatusSurface/CombinedMenuHost paint and PaintedBlurRegion. Expanded Bar bottom corners become zero at the join; menu lower corners remain surface-derived.
- `Theme.barPillRadius` → Bar, ExpandablePlugin, StatusPill, TimeDatePill, UtilityPill and TrayGroup → BatteryPillContent regions and shared collapsed/expanded transition. Inner focus rims subtract inset. Workspace override → Workspaces root and each active segment.
- `Theme.radius("surface", …)` → HubSurface/HubWindow, NotificationCard/ToastHost input regions, clipboard/emoji/launcher/Settings backgrounds and menus. SurfaceBorder follows the painted parent radius; no independent border-radius preference.
- `RenderTokens.tileRadius` → ControlTile outer frame; inner focus rim subtracts 2. The same controlTile role also rounds ProfileHeader and MediaSection backgrounds, so its primary-controls label understates the scope.
- `RenderTokens.sliderRadius` → IconSlider track/frame; fill radius subtracts sliderBorder and clamps to half current fill width. ValueSlider uses the slider role for track and handle; **SettingsSlider uses fixed 2px tracks and 7px handle**, with action-derived focus styling.
- Avatar/album/header radius → RoundedArtwork.outerRadius → background, inner alpha mask, painted border and VisualState.perimeter progress path. The same component clamps to half size and subtracts actual frameWidth.
- Avatar role/master → native visual_data.cpp avatarRadius → LockTokens/LockProfile and presentation.cpp native premultiplied-alpha mask. Frame treatment forces 4px in both QML and C++; plain uses the shared avatar multiplier. Lock previews duplicate the same 12px reference/clamp, while CC uses a 10px reference.
- Native lock credential marks and profile style are presentation-only; their controls do not affect PAM, fprintd, authentication authority or input routing.

## Fixed/internal radius sites

48 definition sites: 39 literal QML assignments/defaults, seven conditional fixed branches and two native defaults/branches. These are not 48 separate controls or distinct numeric values.

- [.config/quickshell/magi/components/bar/PaintedBlurRegion.qml:11](../../.config/quickshell/magi/components/bar/PaintedBlurRegion.qml#L11) — `cornerRadius: 0`
- [.config/quickshell/magi/components/bar/menu/AnchoredPopupHost.qml:74](../../.config/quickshell/magi/components/bar/menu/AnchoredPopupHost.qml#L74) — `topLeftRadius: 0`
- [.config/quickshell/magi/components/bar/menu/AnchoredPopupHost.qml:74](../../.config/quickshell/magi/components/bar/menu/AnchoredPopupHost.qml#L74) — `topRightRadius: 0`
- [.config/quickshell/magi/components/bar/menu/AnchoredPopupHost.qml:85](../../.config/quickshell/magi/components/bar/menu/AnchoredPopupHost.qml#L85) — `topLeftRadius: 0`
- [.config/quickshell/magi/components/bar/menu/AnchoredPopupHost.qml:86](../../.config/quickshell/magi/components/bar/menu/AnchoredPopupHost.qml#L86) — `topRightRadius: 0`
- [.config/quickshell/magi/components/bar/menu/CombinedMenuHost.qml:50](../../.config/quickshell/magi/components/bar/menu/CombinedMenuHost.qml#L50) — `topLeftRadius: 0`
- [.config/quickshell/magi/components/bar/menu/CombinedMenuHost.qml:51](../../.config/quickshell/magi/components/bar/menu/CombinedMenuHost.qml#L51) — `topRightRadius: 0`
- [.config/quickshell/magi/components/controls/IconSlider.qml:85](../../.config/quickshell/magi/components/controls/IconSlider.qml#L85) — `radius: 8`
- [.config/quickshell/magi/components/controls/RoundedArtwork.qml:13](../../.config/quickshell/magi/components/controls/RoundedArtwork.qml#L13) — `radius: 10`
- [.config/quickshell/magi/components/emoji/EmojiContent.qml:61](../../.config/quickshell/magi/components/emoji/EmojiContent.qml#L61) — `radius: 8`
- [.config/quickshell/magi/components/emoji/EmojiContent.qml:82](../../.config/quickshell/magi/components/emoji/EmojiContent.qml#L82) — `radius: 8`
- [.config/quickshell/magi/components/hub/HubSearchField.qml:27](../../.config/quickshell/magi/components/hub/HubSearchField.qml#L27) — `radius: 6`
- [.config/quickshell/magi/components/hub/HubSelector.qml:91](../../.config/quickshell/magi/components/hub/HubSelector.qml#L91) — `radius: 8`
- [.config/quickshell/magi/components/launcher/LauncherContent.qml:59](../../.config/quickshell/magi/components/launcher/LauncherContent.qml#L59) — `radius: 10`
- [.config/quickshell/magi/components/settings/ApplicationAppearancePreview.qml:42](../../.config/quickshell/magi/components/settings/ApplicationAppearancePreview.qml#L42) — `radius: 10`
- [.config/quickshell/magi/components/settings/ApplicationAppearancePreview.qml:48](../../.config/quickshell/magi/components/settings/ApplicationAppearancePreview.qml#L48) — `radius: 6`
- [.config/quickshell/magi/components/settings/ApplicationAppearancePreview.qml:53](../../.config/quickshell/magi/components/settings/ApplicationAppearancePreview.qml#L53) — `radius: 6`
- [.config/quickshell/magi/components/settings/ApplicationAppearancePreview.qml:54](../../.config/quickshell/magi/components/settings/ApplicationAppearancePreview.qml#L54) — `radius: 9`
- [.config/quickshell/magi/components/settings/ApplicationAppearancePreview.qml:59](../../.config/quickshell/magi/components/settings/ApplicationAppearancePreview.qml#L59) — `radius: 2`
- [.config/quickshell/magi/components/settings/ApplicationAppearancePreview.qml:61](../../.config/quickshell/magi/components/settings/ApplicationAppearancePreview.qml#L61) — `radius: 6`
- [.config/quickshell/magi/components/settings/DisplayCanvas.qml:28](../../.config/quickshell/magi/components/settings/DisplayCanvas.qml#L28) — `radius: 10`
- [.config/quickshell/magi/components/settings/DisplayCanvas.qml:48](../../.config/quickshell/magi/components/settings/DisplayCanvas.qml#L48) — `radius: 6`
- [.config/quickshell/magi/components/settings/LockLayoutCanvas.qml:15](../../.config/quickshell/magi/components/settings/LockLayoutCanvas.qml#L15) — `avatarRadius: 12`
- [.config/quickshell/magi/components/settings/LockLayoutCanvas.qml:102](../../.config/quickshell/magi/components/settings/LockLayoutCanvas.qml#L102) — `radius: 6`
- [.config/quickshell/magi/components/settings/LockThemePreview.qml:13](../../.config/quickshell/magi/components/settings/LockThemePreview.qml#L13) — `avatarRadius: 12`
- [.config/quickshell/magi/components/settings/LockThemePreview.qml:49](../../.config/quickshell/magi/components/settings/LockThemePreview.qml#L49) — `radius: 12`
- [.config/quickshell/magi/components/settings/SettingsReorderBoard.qml:359](../../.config/quickshell/magi/components/settings/SettingsReorderBoard.qml#L359) — `radius: 1`
- [.config/quickshell/magi/components/settings/SettingsSelector.qml:38](../../.config/quickshell/magi/components/settings/SettingsSelector.qml#L38) — `radius: 3`
- [.config/quickshell/magi/components/settings/SettingsSlider.qml:10](../../.config/quickshell/magi/components/settings/SettingsSlider.qml#L10) — `radius: 2`
- [.config/quickshell/magi/components/settings/SettingsSlider.qml:12](../../.config/quickshell/magi/components/settings/SettingsSlider.qml#L12) — `radius: 2`
- [.config/quickshell/magi/components/settings/SettingsSlider.qml:17](../../.config/quickshell/magi/components/settings/SettingsSlider.qml#L17) — `radius: 7`
- [.config/quickshell/magi/components/settings/ThemeGallery.qml:194](../../.config/quickshell/magi/components/settings/ThemeGallery.qml#L194) — `radius: 5`
- [.config/quickshell/magi/components/settings/ThemeGallery.qml:196](../../.config/quickshell/magi/components/settings/ThemeGallery.qml#L196) — `radius: 3`
- [.config/quickshell/magi/components/settings/ThemeGallery.qml:205](../../.config/quickshell/magi/components/settings/ThemeGallery.qml#L205) — `radius: 3`
- [.config/quickshell/magi/components/settings/ThemeGallery.qml:215](../../.config/quickshell/magi/components/settings/ThemeGallery.qml#L215) — `radius: 9`
- [.config/quickshell/magi/components/tray/TrayItem.qml:79](../../.config/quickshell/magi/components/tray/TrayItem.qml#L79) — `radius: 4`
- [.config/quickshell/magi/components/tray/TrayItem.qml:84](../../.config/quickshell/magi/components/tray/TrayItem.qml#L84) — `radius: 3`
- [.config/quickshell/magi/components/wallpaper/WallpaperTile.qml:57](../../.config/quickshell/magi/components/wallpaper/WallpaperTile.qml#L57) — `radius: 8`
- [native/lock/qml/LockScreen.qml:91](../../native/lock/qml/LockScreen.qml#L91) — `radius: 12`
- [.config/quickshell/magi/components/bar/ExpandablePlugin.qml:100](../../.config/quickshell/magi/components/bar/ExpandablePlugin.qml#L100) — conditional/default branch; see source for fixed and inherited cases.
- [.config/quickshell/magi/components/bar/ExpandablePlugin.qml:103](../../.config/quickshell/magi/components/bar/ExpandablePlugin.qml#L103) — conditional/default branch; see source for fixed and inherited cases.
- [.config/quickshell/magi/components/notifications/ToastHost.qml:46](../../.config/quickshell/magi/components/notifications/ToastHost.qml#L46) — conditional/default branch; see source for fixed and inherited cases.
- [.config/quickshell/magi/components/settings/LockThemePreview.qml:35](../../.config/quickshell/magi/components/settings/LockThemePreview.qml#L35) — conditional/default branch; see source for fixed and inherited cases.
- [native/lock/qml/LockCredential.qml:25](../../native/lock/qml/LockCredential.qml#L25) — conditional/default branch; see source for fixed and inherited cases.
- [native/lock/qml/LockProfile.qml:16](../../native/lock/qml/LockProfile.qml#L16) — conditional/default branch; see source for fixed and inherited cases.
- [native/lock/qml/LockTokens.qml:27](../../native/lock/qml/LockTokens.qml#L27) — conditional/default branch; see source for fixed and inherited cases.
- [native/lock/src/visual_data.cpp:54](../../native/lock/src/visual_data.cpp#L54) — conditional/default branch; see source for fixed and inherited cases.
- [native/lock/src/presentation.cpp:31](../../native/lock/src/presentation.cpp#L31) — conditional/default branch; see source for fixed and inherited cases.

## Derived exports and dead data

Nine named QML geometry exports: Theme.radiusSmall, radiusMedium, radiusLarge, barPillRadius, workspacePillRadius; RenderTokens.outerRadius, tileRadius, sliderRadius; LockTokens.avatarRadius. **radiusLarge has no consumer**; it is a dead token, not a persisted field. All twelve numeric persisted fields have consumers. Native avatarRadius publication is the bridge for the same avatar token, not a thirteenth preference.

Historical migrations preserve albumArt from action when upgrading schema 10→11, and secondaryControl from action when upgrading 17→18. They explain current independence; neither is a dead legacy field. Experimental bar-surface fixed radii are not loaded production components. Generated application-theme code has no matching radius/roundness writer; palette generation and adapters do not consume these MAGI UI values.
