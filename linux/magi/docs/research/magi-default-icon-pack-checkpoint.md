# First-party MAGI icon-pack checkpoint

Status: implemented and operator-accepted on 2026-10-01. This checkpoint adds
the partial built-in `magi-default` pack and semantic SVG tinting. It does not
change shell composition or the shared-status-surface lifecycle.

## Export audit

Source inspected: `/home/jkebwdn/Downloads/magi-icons/` on 2026-10-01.
All 47 SVG files:

- parse successfully and use `viewBox="0 0 24 24"`;
- contain visible geometry, including all four re-exported chevrons;
- pass MAGI's production SVG validator;
- contain no raster images, `data:image` data, scripts, event handlers,
  entities, external references or unsupported elements;
- use `width="100%"` and `height="100%"` with the canonical viewBox;
- rasterize with transparent margin inside the 24×24 canvas, so no artwork
  touches or appears cropped to a canvas edge.

The exports contain no transforms. `wifi-high.svg` is fully opaque. The other
46 files contain at least one intentional partial-opacity element. Files with
more than one explicit partial level are `brightness`, `copy`, `earbuds`,
`ethernet`, `home`, `media-next`, `media-previous`, `more`, `package`, `paste`,
`profile`, `save`, `screen-record`, `volume-muted`, `vpn` and `warning`.

All visible RGB fills are neutral white except `power-saver.svg`, which also
contains `#fbfbfb`. That near-white value remains byte-for-byte unchanged and
is the only source item to review in a future Affinity cleanup. `package.svg`
also uses the expected `fill:none`. No source artwork was rewritten, cropped or
normalized during integration.

## Production integration

The built-in pack lives in
`.config/quickshell/magi/icons/packs/magi-default/`. Its manifest identifies it
as `magi-default`, display name `MAGI`, with `magi-legacy` as parent. All 47
source SVGs were copied byte-for-byte. Forty-eight semantic mappings are
registered because `chevron-left.svg` supplies both `chevron-left` and the
existing `back` role.

Each filename also has its same-name semantic role. This records useful future
roles such as `bluetooth-on`, `battery-low`, `volume-high` and `wifi-on` without
guessing that they mean an existing but different state such as
`bluetooth-connected`. There are no unmapped filenames. Roles for which the
first-party library has no artwork continue through the parent, including
`settings`, `dnd`, `caffeine`, `lock`, `hibernate`, `shutdown`, scan/connect
actions, disconnected/off Wi-Fi, connected Bluetooth, unknown/numeric battery
states and the missing glyph.

`components/controls/Icon.qml` now uses `QtQuick.Effects.MultiEffect` for assets
whose resolver descriptor has `colorMode: semantic`. The source SVG's rendered
alpha becomes the mask while `colorizationColor` receives the normal component
foreground. Internal opacity is therefore retained for default, accent and
muted colors across dark and light themes. `colorMode: fixed` bypasses the
effect and renders original colors for future logos or multicolor assets.

Bundled, managed-pack and individual-override descriptors use the same resolver
path. Manifest filename shorthand means semantic mode; an object descriptor can
request fixed mode explicitly. Resolution remains individual override, module
or global selected pack, declared parent, then MAGI Legacy.

## Validation

- The production validator accepts all 47 exports and the bundled manifest.
- Byte comparison confirms all bundled SVGs match their exported sources.
- Resolver tests pass first-party selection, semantic/fixed modes, override
  precedence, parent fallback and path guards.
- Managed-asset tests pass semantic shorthand and explicit fixed-color mode.
- Full settings tests and all 48 shared-surface lifecycle steps pass.
- Whole-production `qmllint` exits successfully with only the existing
  Network/Quickshell metadata warnings; `git diff --check` passes.
- The fixture under `experiments/icon-pack/` renders the production Icon
  component at 12, 16, 20 and 24 logical pixels. Captured output retains
  negative space, partial alpha, optical scale and semantic state colors; the
  Settings role demonstrates legacy fallback.
- Production was checked with Catppuccin Mocha, Macchiato and Latte, then
  restored to Mocha. Custom icons remained visible and readable.
- Runtime logs contain no QML, Image or SVG errors. Hyprland reports one MAGI
  1920×1080 layer at output-local `(0,0)` and reservation `[0,48,0,0]`.
- The operator accepted fixture scale/opacity and bar, Control Centre, slider,
  media, detail/navigation and fallback rendering.

No commit or push was performed.
