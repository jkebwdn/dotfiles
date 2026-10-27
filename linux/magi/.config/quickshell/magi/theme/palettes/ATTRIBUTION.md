# Palette attribution

Rosé Pine by mvllow and contributors: MIT, LICENSE-RosePine.
Nord by Sven Greb: MIT, LICENSE-Nord.
Tokyo Night from folke/tokyonight.nvim by Folke Lemaitre and contributors:
Apache-2.0, LICENSE-TokyoNight. The project credits enkia/tokyo-night-vscode-theme.

MAGI maps these upstream colours into its own semantic roles. Registry entries
are modified representations, not upstream files; paired ink is selected by
contrast, with black/white fallback where upstream endpoints are insufficient.
Upstream base/accent RGB values are retained. Sources and inspection date accompany each
entry; detailed mappings and source discrepancies are in
`docs/design/phase12b-theme-library.md`. No fonts or editor plugins are bundled.

## Palette expansion — inspected 2026-10-27

- Gruvbox: morhetz, MIT/X11 as declared in the upstream README; medium-contrast
  dark/light defaults from `morhetz/gruvbox/colors/gruvbox.vim` (12 Aug 2017 header).
- Kanagawa: Tommaso Laurenzi, MIT, LICENSE-Kanagawa; `rebelot/kanagawa.nvim`
  `lua/kanagawa/colors.lua` and `themes.lua`, Wave and Dragon mappings.
- Dracula Classic: Dracula Theme, MIT, LICENSE-Dracula; official
  https://draculatheme.com/spec (not Dracula Pro or Alucard).
- One: GitHub Inc., MIT, LICENSE-One; Atom `one-dark-syntax` / `one-light-syntax`
  `styles/colors.less` and corresponding One UI Less neutral-level formulas.
- Ayu Mirage: Konstantin Pschera, MIT, LICENSE-Ayu; `ayu-theme/ayu-colors`
  `themes/mirage.yaml`, literal palette anchors, UI surfaces and accent tint.

Registry URLs identify the inspected upstream master files. Network restrictions
prevented resolving commit SHAs; these are dated source observations, not claims
of immutable upstream revisions. RGB values are bundled locally and never fetched
at runtime. See `docs/themes.md` for mapping decisions and validation.
