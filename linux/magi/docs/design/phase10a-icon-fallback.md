# Phase 10A icon fallback correction — operator review pending

The initial Phase 10A icon fallback was rejected. No acceptance, staging, commit,
push, package installation or live reload is part of this correction.

## Root cause and corrected ownership

The first pass removed selected-pack → Legacy lookup while retaining the partial
default manifest. It replaced any missing mapping with `{kind:"glyph",text:"?"}`.
The shared Icon renderer also used question-mark Text on SVG load failure. Thus
removing inheritance exposed missing battery and Control Centre mappings directly.

The corrected resolver is selected pack → **same semantic ID** in built-in
`magi-default` → bundled `icons/packs/magi-default/missing.svg`. There is no arbitrary
parent graph. Parent metadata is ignored, and no override/module selection machinery
has been restored. Malformed/unknown alternate packs use the default. Image load
failure retries the same canonical ID, then the real placeholder, with deferred
state changes to avoid QML binding loops. The placeholder is a neutral outlined
rounded square/cross, with normal icon sizing, alignment, tint and opacity.

MAGI Default is now both the initial selection and canonical fallback authority.
Its 87 explicit mappings include the existing MAGI SVGs and the exact previously
inherited Nerd Font glyph descriptors, plus the existing reboot SVG. This preserves
the already-used glyph artwork for roles without first-party SVGs; it does not
select unrelated approximations. There is no font conversion or new font dependency.
Legacy is an optional selectable pack, not a runtime parent of Default.

## Battery audit

`IconState.batteryRole` is unchanged and requests these actual IDs:

| State | Semantic ID | Canonical mapping |
|---|---|---|
| Unavailable | `battery-unknown` | Existing U+F0091 battery-unknown glyph |
| Charging (all percentages) | `battery-charging` | Existing `battery-charging.svg` |
| Discharging ≥90% | `battery-full` | Existing `battery-full.svg` |
| Discharging 65–89% | `battery-high` | Existing U+F0080 battery-high glyph |
| Discharging 35–64% | `battery-medium` | Existing `battery-medium.svg` |
| Discharging <35% | `battery-low` | Existing `battery-low.svg` |

There are no separate AC/charging-percentage IDs in this runtime. The historical
`battery-0`, `battery-10` … `battery-90` vocabulary is also explicitly preserved
in the default manifest. Tests cover every boundary and both charging/unavailable
branches without collapsing them into a generic battery. The unavailable icon
contains its designed internal question symbol; it is a battery glyph, not a
literal question-mark Text fallback.

## Control Centre and static audit

ControlCatalogue actions (`vpn`, `dnd`, `caffeine`, `lock`, `hibernate`, `shutdown`,
`reboot`, Settings/Hub routes), network variants, Bluetooth variants, volume levels,
brightness and media controls all resolve to their same-ID Default mapping when
omitted by the selected pack. The production fixture checks the visible status
cluster and open Control Centre, with an alternate pack containing only `wifi`.

The role-by-role audit records selected and canonical descriptors in
`/tmp/magi-icon-fallback-role-audit.tsv`. All literal shell icon IDs are mapped;
`accent` found by the broad source scan is a palette selector value, not an icon ID.
Runtime icon-path searches found only a rejection guard for a question-mark glyph,
not a returned question-mark fallback. `LauncherIcons.qml` retains its independent
application-name initial fallback and system `Quickshell.iconPath` lookup unchanged.
Other question marks in these files are JavaScript ternary syntax.

## Tests and previews

- `tests/settings/icons.cjs`: explicit A–H cases; selected precedence, exact-ID
  default, real placeholder descriptor, every battery state, Control Centre roles,
  malformed/unknown pack, retired overrides, missing Icons page and app-icon isolation.
- `tests/settings/assets.py`: default and alternate manifest validation/load plus
  malformed manifest rejection. `catalogue.cjs` verifies every action has an icon.
- `tests/phase10a/icon-fallback.py`: real production Icon, bar and Control Centre,
  exact battery-high fallback, SVG failure recovery and no question-mark fallback.
  A real `calendar` role is deliberately removed from both fixture manifests;
  it resolves to the bundled placeholder.
- `tests/phase10a/run.py` and schema tests preserve the rest of Phase 10A, including
  schema 13, Settings layout, semantic colours, Emoji and Clipboard behaviour.

Focused previews are under `/tmp/magi-icon-fallback-previews/`:
`bar-battery-high.png`, `control-centre-incomplete-pack.png`, and
`semantic-fallback-gallery.png`.

The sandbox's Qt software backend cannot render MultiEffect. The test first runs
with the unchanged production renderer. For shape screenshots only, a disposable
copy exposes the resolved SVG Image directly in white (glyph colours remain exact).
This is an explicitly adapted offscreen preview, not a live/native GPU screenshot;
no production renderer styling is changed for the captures. Native tint quality
was subsequently accepted in the operator live review; no deliberate reload was
performed during that review.
