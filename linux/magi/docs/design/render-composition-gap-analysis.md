# MAGI render composition gap analysis

**Superseded product interpretation:** the operator clarified on 2026-09-26
that the entire status cluster becomes one surface with internal module views.
The per-pill morph proposed below was insufficient. Retain this analysis as
history; [shared-status-surface.md](shared-status-surface.md) defines the current
structural checkpoint.

Status: **implementation input**, recorded 2026-09-26 before the dedicated
composition pass. The comparison uses the original user-supplied render at
`/home/jkebwdn/Downloads/Magi Quickshell Render.png`, a live screenshot of
the current combined shell, and the production QML listed below. The render
defines visual relationships rather than exact pixel values or finished
assets.

## Compared implementation

- `components/bar/ExpandablePlugin.qml`: the pill owns horizontal animation
  and the selected host owns vertical reveal.
- `components/bar/menu/CombinedMenuHost.qml`: the menu is already an Item
  directly below the pill on the same native surface, but currently inserts
  12px of empty top padding before plugin content.
- `plugins/bar/bluetooth/Bluetooth.qml`: the pill and menu instantiate two
  different connected-device compositions.
- `plugins/bar/volume/Volume.qml`: the pill changes from percentage to a
  generic title while the menu creates a separate output card.
- `plugins/bar/wifi/Wifi.qml` and `WifiMenuContent.qml`: the pill changes to a
  generic Wi-Fi title while the menu repeats connection identity in two
  separate header/status blocks.
- `plugins/bar/controlcentre/ControlCentre.qml` and `ControlTile.qml`: the pill
  becomes a generic title and the content starts again with a section label,
  two large tiles and three outlined rows.

The accepted animation order, input Region, focus, dismissal, reservation and
fallback geometry are not gaps and must remain unchanged.

## Major gaps

### Pill to menu continuity

The render treats the clicked status pill as the top edge and persistent hero
of the expanded module. Its icon and state move within the widening shape,
then the rest of the module reveals below. Current production pill content
switches abruptly from compact status to a generic centred title. A second
icon/title/status composition then fades in below it. This creates the visual
sequence “pill, then dropdown” even though both are already on one surface.

The first composition pass should use one plugin-owned pill header whose icon
moves from the compact centre/group position to the expanded leading position
as `animatedWidth` changes. Compact status should fade or reposition into an
expanded title and trailing live state. Menu content must begin with supporting
content rather than duplicate that header.

### Header composition

The render gives the top status area the strongest weight: connected device or
network identity, a large recognisable icon, live state and only the essential
action. Current menus use conventional title/subtitle/button rows followed by
another bordered status card. Bluetooth and Wi-Fi therefore repeat the same
identity, while Volume replaces its compact percentage with an unrelated
“Default output” form header.

For the first pass:

- Bluetooth's connected name remains visible while the pill widens; the menu
  continues with connection state, optional real battery and disconnect action.
- Wi-Fi's icon and SSID become the widened header, with signal/radio state
  continuing immediately below.
- Volume's icon and percentage survive the widening transition and become the
  expanded header rather than being replaced by a second output card.
- Control Centre's compact icon becomes the leading icon in its expanded title.

### Menu silhouette

The current host technically forms one silhouette, but 12px of blank content
padding directly under the 28px pill and the immediate appearance of nested
cards make the lower area read as a separate panel. The render has a continuous
outer silhouette with the header flush to its content hierarchy.

The pass should retain the zero-radius join between pill and revealed body,
reduce the empty top inset, and keep one uninterrupted outer surface. Menu
height remains plugin-owned and the exclusive zone remains exactly 48 logical
pixels.

### Spacing and typography

Current layouts use uniform 8–10px gaps and repeated small uppercase labels.
That makes every block equally important. The render uses larger gaps between
major groups, compact gaps within groups, and a clearer progression from hero
state to controls to secondary lists. Current type is mostly 9–12px with bold
labels applied broadly; the render reserves emphasis for device/network names,
primary state and large icons.

The pass should reduce labels that merely describe obvious content, keep one
quiet section caption for secondary lists, enlarge hero icons/status values,
and use whitespace rather than dividers to separate primary and secondary
content.

### Icons

The render relies on large, intentional icons as the visual anchor of each
module. Current bar icons are appropriately compact, but expanded menus create
unrelated icon wells or small generic icons. The shared pill header should
retain the exact plugin icon through widening. Supporting hero icons may grow,
but should not compete with a duplicate title icon.

The supplied custom icon set is not yet in the repository, so this pass keeps
the existing Nerd Font glyphs. Asset replacement remains separate work.

### Surface hierarchy and outlines

Current production uses borders on connected cards, known network/device rows,
Control Centre tiles, slider cards and the battery row. The accumulated outlines
produce a settings-page appearance. The render uses a dark outer module, a few
soft grouped surfaces and selective colour blocks; most list rows are separated
by spacing or subtle tonal changes.

The pass should remove routine borders and full-width dividers, use soft tonal
groups for primary state, and reserve accent colour for active state or the
selected hero. Hover feedback remains tonal.

### Module proportions

Bluetooth and Wi-Fi currently devote similar visual weight to primary state
and each secondary row. The render makes the connected state broad and dominant
and keeps the bounded list visually subordinate. Volume currently contains two
stacked settings cards, while the render uses a compact status/slider module.

The first pass should use shorter secondary rows, a stronger upper status area,
and fewer nested containers. Bounded scrolling and all backend-derived state
remain unchanged.

### Control Centre composition

The render's Control Centre is a compact vertical dashboard: a strong top
identity area, four similarly sized coloured control tiles, two concise slider
modules, a lighter row of small status/actions, and a wide media/status module.
Current production has only two wide tiles followed by three outlined settings
rows. Its proportions and rhythm therefore remain a prototype even though the
services are functional.

Within the available production services, the first pass can form a four-tile
grid from Wi-Fi, Bluetooth, mute/audio and battery/power state, followed by
paired Volume and Brightness controls and a quiet battery summary. It must not
invent media, notification or device capabilities that do not yet exist.
Secondary/right-click detail routing remains available for Wi-Fi and Bluetooth.

## First-pass implementation boundaries

The composition pass will add a shared morphing pill header driven by the
existing `animatedWidth`; simplify the four plugin bodies around that header;
and adjust host content insets only as presentation. It will not change phase
transitions, durations, MenuController ownership, native surfaces, input Region,
focus policy, dismissal, exclusive zone, services or password-window lifecycle.

The first substantial runtime result requires direct screenshot comparison
with the original render before further detail tuning.

## First-pass screenshot comparison

Operator screenshots captured on 2026-09-26 confirm that the continuous outer
silhouette, softer grouping and Control Centre proportions are substantially
closer to the render. Volume now reads as one compact slider module, Bluetooth
gives the active connection priority over its bounded secondary list, and the
Control Centre presents four coloured controls above paired sliders.

The screenshots also exposed one shared implementation defect: the Loader for
plugin-owned pill content retained only its loaded item's implicit size instead
of the pill's animated bounds. The morphing header therefore laid itself out in
an undersized coordinate space. In every expanded plugin, the trailing state
appeared before the icon while the intended leading title was clipped. This was
not a desired visual result or a host-animation limitation. The correction is
to size the existing pill-content Loader to the animated pill, preserving the
same component instance and animation lifecycle while giving its icon, title
and trailing state the correct coordinate space.

The supplied screenshots did not include an open Wi-Fi state, so Wi-Fi's
primary connected-network composition still requires direct visual comparison
after the shared header correction.
