# MAGI icon-pack contract

Status: production contract introduced with settings schema v3 on 2026-09-28.
MAGI Legacy remains the complete built-in fallback. This contract describes
local installable packs; it is not an online package or trust system.

## UI asset contract

Normal semantic UI glyphs are local SVG files with:

- a transparent canvas and canonical `viewBox="0 0 24 24"`;
- lowercase kebab-case filenames such as `airplane-mode.svg`;
- intentional padding retained inside the 24×24 canvas—MAGI never crops a
  glyph to its path bounds;
- no scripts, event handlers, entities, external URLs or external resources;
- at most 256 KiB and 512 SVG elements;
- monochrome structure suitable for semantic recoloring where the SVG itself
  permits it.

First-party semantic glyphs use neutral white geometry and may use object or
fill opacity for hierarchy. The production renderer treats their rendered alpha
as a mask and applies the caller's semantic foreground color, preserving those
opacity differences. Fixed-color artwork is explicit; the renderer never tries
to infer mode from SVG colors.

The validator checks the canvas and bounded safe SVG subset. It does not reject
art simply because paths occupy less than 24×24. Future logos, illustrations
and artwork need an explicit non-UI asset type rather than weakening this rule.

## Manifest

A pack is installed from a local JSON manifest next to its SVG files:

```json
{
  "formatVersion": 1,
  "id": "example-pack",
  "displayName": "Example Pack",
  "version": "1.0",
  "author": "Example",
  "description": "Optional metadata",
  "parent": "magi-legacy",
  "roles": {
    "wifi": "wifi.svg",
    "profile-logo": {
      "asset": "profile-logo.svg",
      "colorMode": "fixed"
    }
  }
}
```

A filename is shorthand for `{ "asset": filename, "colorMode": "semantic" }`.
`colorMode` is either `semantic` or `fixed`. Semantic mode preserves the SVG's
alpha while replacing RGB with the requested theme role; fixed mode preserves
the SVG's own colors for future logos and multicolor assets.

`id`, role names and filenames use lowercase kebab-case. The manifest is
limited to 64 KiB and 256 role mappings. Every mapped asset must be a regular
file in the manifest directory. Installation validates and copies a pack into
`$XDG_DATA_HOME/magi/icon-packs/<id>/` (normally
`~/.local/share/magi/icon-packs/`); QML never loads the original source path.
An existing ID is not overwritten implicitly.

Resolution remains:

1. individual module/role override, then global role override;
2. selected module pack, when configured;
3. selected global pack;
4. the selected pack's declared parent;
5. MAGI Legacy and its neutral missing glyph.

An incomplete pack is therefore valid. Adding a future first-party MAGI SVG
pack requires a manifest and assets, not edits to consuming controls.

## Built-in packs

`magi-default` is MAGI's partial first-party SVG pack. Its bundled manifest and
registry descriptors use semantic color mode and inherit missing roles from
`magi-legacy`. `magi-legacy` remains the complete Nerd Font fallback. Bundled
SVG files retain their exported 24×24 canvases byte-for-byte; MAGI does not trim
them to visible path bounds.

## Current semantic action roles

The production vocabulary includes `power-saver`, `airplane-mode`, `vpn`,
`dnd`, `caffeine`, `lock`, `hibernate` and `shutdown`, alongside the
existing network, Bluetooth, volume, brightness, battery, settings, navigation
and media roles. Until first-party SVG artwork exists, MAGI Legacy supplies
Nerd Font fallback glyphs.
