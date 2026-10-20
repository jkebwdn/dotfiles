# MAGI icon-pack contract

Current Phase 10A contract (schema 13). Icon packs are the sole configurable
source of MAGI shell control/status icons. Application icons continue through
LauncherIcons/system icon-theme lookup. Select or install a pack in
Settings → Appearance → Theme, beside the theme selector. There is no Icons page.

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

Resolution is selected pack's requested semantic ID → built-in `magi-default`
for the **same ID** → `magi-default/missing.svg`. Unknown/malformed alternate packs
use the default mapping. A malformed descriptor is treated as absent. An unreadable
selected SVG retries the same default ID; an unreadable default asset terminates at
the bundled placeholder. There is no normal question-mark text fallback.

No arbitrary parent graph, module pack or individual override is consulted.
Legacy `parent` fields are ignored on normalization. The `roles` keys are the
supported-icon inventory; no duplicate list is needed. The generic placeholder is
a 24×24 rounded square/cross SVG using the same semantic tint/opacity/alignment as
other SVG icons. It remains available before the asynchronous pack inventory loads.

The optional `{ "text": "…", "font": "…" }` descriptor supports glyph packs
(including MAGI Legacy) under the same contract. Text must be nonempty and at
most eight characters; font names are bounded to 100 characters. No executable
QML is accepted. Glyph rendering requires the named font; SVG packs are preferred.

## Built-in packs

`icons/packs/registry.json` lists manifest paths. Both bundled packs and installed
packs pass `assets.py:pack_manifest` and produce the same normalized role map
and directory base URL. IconRegistry loads that inventory; IconResolver has no
built-in-pack branch. Existing `formatVersion: 1` remains sufficient.

`magi-default` (MAGI Default) is the default first-party SVG pack. Its existing
SVG artwork is unchanged. Previously inherited same-ID glyph descriptors (for
example `battery-high`, `battery-unknown`, `settings`, `dnd`, `caffeine` and `lock`)
are now explicit mappings in the default manifest. Thus the default itself is the
fallback authority, with no runtime dependency on Legacy. These are the exact
previously used glyphs, not newly chosen similar icons; no font outlines are copied.
`reboot` explicitly maps to the existing bundled reboot SVG.
`magi-legacy` remains an explicitly selectable glyph pack, never an implicit
fallback. Built-in IDs cannot be shadowed by imported packs.

Schema 12→13 retires `icons.overrides` and `icons.modulePacks` while preserving
`icons.pack` and unrelated fields. The loader migrates in memory; loading alone
never rewrites settings. The next normal save writes the migrated document.
There is no individual SVG import/persistence API or override editor. Existing
operator-managed old assets are not deleted from disk.
