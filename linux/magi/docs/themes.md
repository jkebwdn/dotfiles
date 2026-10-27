# Canonical MAGI themes

Settings → Appearance uses the shared visual gallery. Schema remains **22**; neither
saved IDs nor the default/current selection changes. No external theme packages are
required. The existing 18 entries remain in their original order; these follow them:

| Family | Theme ID / display name | Kind |
| --- | --- | --- |
| Gruvbox | `gruvbox-dark` / Gruvbox Dark | Dark |
| Gruvbox | `gruvbox-light` / Gruvbox Light | Light |
| Kanagawa | `kanagawa-wave` / Kanagawa Wave | Dark |
| Kanagawa | `kanagawa-dragon` / Kanagawa Dragon | Dark |
| Dracula | `dracula` / Dracula | Dark |
| One | `one-dark` / One Dark | Dark |
| One | `one-light` / One Light | Light |
| Ayu | `ayu-mirage` / Ayu Mirage | Dark |

The flat gallery already displays family-qualified labels in registry order. Family
metadata remains available; no separate picker or theme-specific runtime code is added.

## Sources and mapping

Inspected 2026-10-27. URLs below refer to the inspected upstream master sources,
not immutable commit pins (GitHub commit resolution was unavailable from this
sandbox). The exact RGB mapping is bundled in `theme/palettes/registry.json`; runtime
never downloads colours. Permission notices accompany the registry.

- [Gruvbox](https://github.com/morhetz/gruvbox/blob/master/colors/gruvbox.vim):
  upstream medium-contrast defaults, bright dark accents and faded light accents.
  Warm yellow is Dark's accent; Light uses faded orange. MIT/X11, morhetz.
- [Kanagawa colours](https://github.com/rebelot/kanagawa.nvim/blob/master/lua/kanagawa/colors.lua)
  and [theme assignments](https://github.com/rebelot/kanagawa.nvim/blob/master/lua/kanagawa/themes.lua):
  Wave uses sumiInk/fujiWhite and crystalBlue; Dragon uses dragonBlack/dragonWhite
  and dragonOrange. Dragon's ANSI magenta uses dragonPink. MIT, Tommaso Laurenzi.
- [Dracula Classic specification](https://draculatheme.com/spec): purple accent,
  purple blue/lavender roles, cyan teal and pink ANSI magenta; canonical neutral UI surfaces. MIT,
  Dracula Theme. No Pro/Alucard colours.
- [Atom One Dark](https://github.com/atom/one-dark-syntax/blob/master/styles/colors.less)
  and [One Light](https://github.com/atom/one-light-syntax/blob/master/styles/colors.less):
  exact HSL-to-RGB conversion, including distinct light syntax accents. Neutral
  steps use their corresponding One UI Less lightening/darkening formulas. Muted
  Light uses mono-2 for readability; Dark retains mono-3. MIT, GitHub Inc.
- [Ayu Mirage](https://github.com/ayu-theme/ayu-colors/blob/master/themes/mirage.yaml):
  literal palette anchors, base/lift/panel backgrounds, editor foreground and
  `common.accent.tint` amber. These are source anchors, not claimed copies of its
  newer computed OKLCH syntax/terminal ramps. MIT, Konstantin Pschera.

MAGI retains its existing 33 roles: neutral levels, text/subtext/muted, seven colour
roles, status/focus/slider roles and paired ink. Upstream colour values are preserved;
paired control ink prefers upstream endpoints, with the existing black/white fallback
when needed to meet the established 4.5:1 control-label gate. No semantic roles added.

## Generated applications and ANSI

All adapters consume the same snapshot: MAGI, Hyprland borders, Ghostty, GTK/Thunar,
Zen hybrid CSS, Yazi/yatline, Neovim, Starship, Fastfetch ANSI and btop. Hyprland
still owns only border integration; transparency remains separate background alpha.

The existing ANSI derivation is unchanged: elevated/red/green/yellow/blue/magenta/
teal/subtext, then overlay and repeated chromatic entries, ending in text. Magenta
uses `ansiMagenta` when supplied, otherwise lavender. This preserves named colour
identity but is **not** an exact upstream 16-colour terminal port: bright chromatic
slots repeat. Ghostty selection uses accent/onAccent; syntax and graphs retain the
existing role mappings. No adapter tests a theme name.

## Contrast and review

Existing checks require primary text/background and coloured-control ink ≥4.5:1,
and text on surface/elevated ≥3:1. No new threshold is imposed. Ratios below are
opaque RGB measurements; actual wallpaper/transparency needs native review.

| Theme | Text/background | Muted/background | Accent/background | Error/background | Selected ink/selection |
| --- | ---: | ---: | ---: | ---: | ---: |
| Gruvbox Dark | 10.75 | 5.30 | 8.69 | 4.29 | 8.69 |
| Gruvbox Light | 10.22 | 4.29 | 5.40 | 7.60 | 5.40 |
| Kanagawa Wave | 11.26 | 3.33 | 5.94 | 5.09 | 5.94 |
| Kanagawa Dragon | 10.76 | 4.17 | 6.34 | 5.21 | 6.34 |
| Dracula | 13.36 | 3.03 | 5.90 | 4.53 | 5.90 |
| One Dark | 6.57 | 2.32 | 5.92 | 4.38 | 5.92 |
| One Light | 10.86 | 5.01 | 3.88 | 3.51 | 5.19 |
| Ayu Mirage | 9.45 | 3.58 | 10.41 | 6.29 | 10.41 |

One Dark muted text is weakest. One Light's coloured text/selection boundary and
Gruvbox Light muted text deserve particular review; paired selected text is stronger.
The generated contrast report also records all accent/surface combinations. Passing
these gates does not claim universal WCAG compliance.

## Validation and acceptance

`tests/phase12b/palettes.py` covers registry/order/backwards compatibility, contrast,
all adapter rendering, parse checks, generation publication and return to the original
theme. `tests/theme-orchestrator/bootstrap.py` cycles all additions through stable
source hooks and checks byte equality. `tests/runtime-visual/palettes.qml` uses
production previews, gallery, Bar/Hub, menus and lock credential presentation in an
isolated home; captures go to `MAGI_PALETTE_PREVIEWS`, outside Git. The canonical
runner includes these checks. Software captures do not prove native blur or SVG quality.

Native acceptance passed on 2026-10-27 for all eight additions across MAGI, Ghostty,
GTK/Thunar, Neovim, Yazi and btop. The original theme was restored; Settings values
and tracked source remained unchanged throughout the round-trip. Existing activation
contracts remain in effect (including Zen restart and next-launch application targets).
The full regression run plus corrected harness reruns resolved to 83 PASS, 0 FAIL,
4 documented sandbox environment limitations and 0 SKIPPED. Schema remains 22.
