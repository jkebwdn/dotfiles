# Phase 12F review gallery

[Open the gallery](index.html) · [All pages](all-pages.png) · [Design audit](../../phase12f-settings-product-design.md)

Production components rendered in a disposable HOME/XDG environment with Qt 6.12.0,
offscreen/software. Most captures are 1080×780; compact is 720×650, large CC is
1400×900. No live settings or services were used for editor state.

**Rendering limit:** ordinary captures select the production MAGI Legacy pack.
Qt software cannot render MultiEffect-tinted SVGs, including the MAGI Default card.
[Icon pack shapes](icon-pack-shapes-only.png) is a supplementary **shape-only** capture:
the disposable renderer shows the actual resolved SVG Image without the tint effect.
It is not evidence of native tint/contrast. Normal renderer tests run independently.
Wallpaper correctly shows an empty library/unavailable compositor; Displays is synthetic;
Security remains deferred/password-only. Application adapter counts belong to the fixture.

| Page/task | Capture |
|---|---|
| Appearance / Theme and Icon Pack galleries / roundness samples | [Appearance](appearance.png) |
| Roundness precision remains available | [Fine tune](roundness-fine-tune.png) |
| Switch styles | [Pill, Filled, Minimal](switch-style-picker.png) |
| Bar | [Layout](bar-layout.png), [Appearance](bar-appearance.png), [Behaviour](bar-behaviour.png) |
| Control Centre | [Unified Layout](control-centre.png), [Wi-Fi](cc-wifi.png), [Profile](cc-profile.png), [Volume](cc-volume.png), [Media](cc-media.png), [Host](cc-host.png), [Fine tune expanded](cc-fine-tune.png) |
| Hub | [Layout/Apps](hub.png), [Host](hub-host.png), [Selector](hub-selector.png), [Switches](switch-style-picker.png) |
| Other synthetic Hub modes | [Clipboard](hub-clipboard.png), [Notifications](hub-notifications.png), [Emoji](hub-emoji.png), [Settings](hub-settings.png) |
| Profile | [Identity / Weather disabled](profile.png) |
| Date & time | [Page](date-time.png) |
| Notifications | [Toast / History](notifications.png) |
| Clipboard | [Behaviour](clipboard.png), [Card appearance](clipboard-appearance.png), [History privacy details](clipboard-history-details.png) |
| Launcher | [Page](launcher.png) |
| Emoji | [Page](emoji.png) |
| Wallpaper | [Page](wallpaper.png) |
| Power & Idle | [Page](power-idle.png) |
| Displays | [Page](displays.png) |
| Security | [Page](security.png) |
| Compact | [Appearance](compact-appearance.png), [CC](compact-control-centre.png), [Hub](compact-hub.png), [Profile](compact-profile.png) |
| Large | [CC](large-control-centre.png) |
| Light / Rosé Pine Dawn | [Appearance](palette-rose-pine-dawn.png), [CC](light-control-centre.png), [Hub](light-hub.png), [Profile](light-profile.png), [Notifications](light-notifications.png) |

Additional palette captures: [Everforest Dark Hard](palette-everforest-dark-hard.png),
[Rosé Pine](palette-rose-pine.png), [Nord](palette-nord.png),
[Tokyo Night Moon](palette-tokyo-night-moon.png). Default Appearance shows Catppuccin Mocha.

## Before / after

- Appearance: [12E](../phase12e/appearance.png) → [12F](appearance.png).
- Bar: [12C](../phase12c/layout.png) → [12F](bar-layout.png).
- CC: accepted 12D gallery remains under [phase12d](../phase12d/); compare [12F](control-centre.png).
- Profile: [accepted-baseline capture](before-profile.png) → [12F](profile.png).
- Notifications: [12E](../phase12e/notifications.png) → [12F](notifications.png).

## Reproduce in isolation

From the reviewed worktree:

```sh
MAGI_PHASE12F_ICON_PACK=magi-legacy MAGI_PHASE12F_PREVIEWS=/tmp/magi12f-review python linux/magi/tests/phase12f/run.py
```

Default renderer/resolver regression: run the same test without the icon-pack override.
Optional supplementary shape-only run uses `MAGI_PHASE12F_RAW_SVG=1` and a separate
capture directory. The runner edits only its temporary copy. Generated logs and
intermediate captures stay outside the repository.

## Family versus item scope

| Family view | Individual view |
|---|---|
| [CC Primary](cc-family-primary.png) | [Wi-Fi](cc-item-wifi.png) |
| [CC Secondary](cc-family-secondary.png) | [DND](cc-item-dnd.png) |
| [CC Sliders](cc-family-sliders.png) | [Volume](cc-item-volume.png) |
| [Bar Status pills](bar-family-status.png) | [Wi-Fi](bar-item-wifi.png), [Bluetooth](bar-item-bluetooth.png) |
| [Bar Workspace pills](bar-family-workspace.png) | Numbered workspaces select this same family |
| [Compact CC family](compact-cc-family-primary.png) | [Compact Wi-Fi](compact-control-centre.png) |
| [Compact Bar family](compact-bar-family-status.png) | [Compact Bar Wi-Fi](compact-bar-item-wifi.png) |

Family boundaries are intentionally subtle; an individual has the stronger outline.
Items start with family styling collapsed. Profile, Media, host surfaces and the
existing streamlined Notifications/Clipboard pages retain their direct editing model.

Bar captures use the horizontal-editor archetype: full-width preview above controls
in every mode, including compact views. CC and Hub retain vertical preview-left /
inspector-right composition.

Final native-review preference: the original elevated sidebar background is restored.
Current after-captures and contact sheet were refreshed after that change; the historical
Before Profile image remains unchanged. The operator separately accepted native tint,
wheel/touchpad and gallery interaction; these software captures do not establish those results.
