# Settings architecture spike

Status: **approved; S1–S6 foundation implemented and validated 2026-09-27**. See the
[implementation record](../research/settings-foundation-checkpoint.md) for exact
scope, evidence and limitations. Stable module ownership from S4 was brought
forward to S1; descriptor-driven CC rendering and all Settings GUI work remain
future stages. The audit below records the pre-implementation baseline:
`5215bbef5fa3573295c1c1101059d62da502892c`. Installed packages rechecked with
`pacman -Q`: Quickshell 0.3.1-1, Hyprland 0.56.2-3, Qt base 6.11.2-3,
Qt declarative 6.11.2-2. These are package versions, not a new live-session test.

**Product constraints:** keep the accepted shared status surface, semantic
navigation, lifecycle/interruption model, one active view, consumed dismissal,
OnDemand focus, fullscreen behavior, sole 48px reservation and anchored fallback.
Settings is a separate normal application window. This proposal changes the
configuration and presentation inputs to those systems, not their architecture.
No morph refinement is included.

Catppuccin Mocha is the default/reference palette. The render remains the
composition/geometry reference; its sampled colors are historical evidence,
not canonical MAGI colors. S2 removed that bypass.

## S3 / CC / Settings implementation — 2026-09-27

Semantic icons, responsive configured Control Centre and the initial normal
Settings window are now implemented. The [checkpoint](../research/settings-application-checkpoint.md)
records the exact departures/limits and passed operator checklist. Stable keys
and explicit actions implement the contract below; user asset import and icon
override UI remain deferred. S2 retargeting permits live open-view layout updates;
password/pending sessions still defer them. The original audit remains historical.

## S1/S2 implementation delta — 2026-09-27

The audit and staged designs below retain their original baseline/context.
Implementation uses a small Python stdlib helper for atomic persistence, backup,
canonical symlink handling and stale-disk checks; FileView is the watcher only.
Stable nonvisual module sessions and hidden-detail fallback anchoring were brought
forward from S4. Same-view geometry retargeting is implemented/tested, so future
layout consumers need not close an open surface merely to change its size.
Ten palettes and semantic radius controls are live. CC ordered-layout consumption,
IconRegistry and the normal Settings window remain unimplemented. See the
[checkpoint](../research/settings-foundation-checkpoint.md) for the authoritative
current contract, validation and exact file inventory.

## 1. Verified configuration audit

Paths below are relative to [the live source](../../.config/quickshell/magi/).
Line numbers refer to the baseline above. These findings are source inspection,
not inferred runtime behavior.

| Source | Current behavior / constraint |
| --- | --- |
| [settings.json](../../.config/quickshell/magi/settings.json):1 | Only `palette` and three bar placement arrays are stored. Current center is `["workspaces"]`. No version. |
| [services/Settings.qml](../../.config/quickshell/magi/services/Settings.qml):11–35 | Aliases a JsonAdapter, watches/reloads the file; no validation, migration, save call, reset or error interface. Adapter center default is `[]`, unlike the checked-in file. GUI property changes would not automatically persist. |
| [theme/Theme.qml](../../.config/quickshell/magi/theme/Theme.qml):10–42 | Two explicit palette instances; exactly `everforest` selects Dark Hard, everything else selects Mocha. Semantic colors already exist and should be extended. The persistence comment overstates current behavior. Two-way palette assignment should become one-way consumption of Settings. |
| [Theme.qml](../../.config/quickshell/magi/theme/Theme.qml):44–64 | Hard-coded font, radii, 28px pill height, spacing and insets. These mix user personality choices with internal geometry. |
| [RenderTokens.qml](../../.config/quickshell/magi/theme/RenderTokens.qml):7–40 | CC width320/body208, tile60, slider48, geometry/typography and literal sampled colors. Colors bypass Theme. Radius roles partly duplicate Theme; CC-specific spacing is intentional, not automatically redundant. |
| [theme/qmldir](../../.config/quickshell/magi/theme/qmldir), [services/qmldir](../../.config/quickshell/magi/services/qmldir) | Explicit singleton registration; no theme/icon registry or media service. Keep this simple import model. |
| [Bar.qml](../../.config/quickshell/magi/components/bar/Bar.qml):26–63,109–200,248 onward | Explicit component dictionary, Settings-driven rows and live pill registry keyed by menu ID. No placement validation; duplicate IDs can compete in the registry. Plugin lifetime depends on placement Loaders. |
| [SharedStatusSurface.qml](../../.config/quickshell/magi/components/bar/SharedStatusSurface.qml):23–35,87–130,235–257 | Selected plugin supplies size; actual status Row supplies compact width. Body Loaders remain alive while registered. Selection and compact-width updates use settled bindings. No general handler currently retargets a same-view `menuHeight` change. |
| [ControlCentre.qml](../../.config/quickshell/magi/plugins/bar/controlcentre/ControlCentre.qml):56–182 | Four fixed tiles (Wi-Fi, read-only Power, Sound, Bluetooth), two sliders, then duplicated battery state/time. Primary/secondary actions already separate; Wi-Fi/BT secondary calls navigate by ID. |
| [ControlTile.qml](../../.config/quickshell/magi/plugins/bar/controlcentre/ControlTile.qml) | Reusable presentation/action signals and accessible labels already exist. Retain them. |
| [Volume.qml](../../.config/quickshell/magi/plugins/bar/volume/Volume.qml), [ControlCentre.qml](../../.config/quickshell/magi/plugins/bar/controlcentre/ControlCentre.qml):27 | Duplicate volume glyph selection. [Network.qml](../../.config/quickshell/magi/services/Network.qml):41, [Battery.qml](../../.config/quickshell/magi/services/Battery.qml):65 and [Wifi.qml](../../.config/quickshell/magi/plugins/bar/wifi/Wifi.qml):31 also encode glyphs. No semantic icon resolver. |
| [Wifi.qml](../../.config/quickshell/magi/plugins/bar/wifi/Wifi.qml):15–19,45–145,178 | Password candidate, pending connection and result/error state are plugin-owned. Destroying this instance during placement edits risks breaking an accepted flow. Preserve its password window and Network calls. |

Two integration risks follow from that source:

1. Removing a bar plugin also removes its registration/body; CC detail navigation
   cannot depend on that pill being visible. Separate module availability from
   placement before advertising unrestricted Bar configuration.
2. Content-driven layouts need a safe geometry-update checkpoint. Current
   navigation changes target height, but editing the active view's layout is a
   different case. Initially defer structural settings until the surface is
   closed; do not quietly rewrite the state machine to make every edit immediate.

## 2. Proposed schema and boundaries

The original foundation used one MAGI-specific JSON document with integer
`schemaVersion: 1`; production now chains that migration to schema v2 for
profile/media/optional-region settings. Keep its
existing location, `.config/quickshell/magi/settings.json`, for the first
implementation. Avoid a simultaneous path migration or multiple override files.
The [example document](settings-schema-v1.example.json) is a proposed default,
not an installed configuration or an implemented validator.

| Section | Fields / meaning |
| --- | --- |
| `appearance` | Stable `theme` ID; `roundness.master` and nullable `roundness.roles` overrides. |
| `icons` | Global `pack`, module-ID → pack map, optional global/module role → asset overrides. Missing entries mean Default/inherit. |
| `bar` | Ordered `left`, `center`, `right` ID arrays. Omission hides a bar item, not its service/detail capability. |
| `controlCentre` | Requested `columns`; ordered `controls` and `sliders` entries with stable instance `key`, module ID, `enabled` and supported `presentation`. |
| Later `profile`, `media` | Add in their own migration when implemented; do not publish ineffective GUI settings now. Proposed shapes in section 8. |

Do not persist live volume, Wi-Fi radio state, device lists, passwords, current
menu/view/history, animation phases or QML references. Services own system state;
MenuController owns navigation. This file is user preference, not a session dump.

### Defaults, validation and publication

Use small pure JS functions in `settings/SettingsSchema.js` and
`settings/SettingsMigrations.js`; no generic plugin framework or schema engine.
One `defaults()` factory returns a fresh document, including center workspaces
and the existing production right order. Runtime consumers, resets and tests
all use it; do not repeat defaults in three QML adapters.

Proposed validation rules:

- Root is an object; version is a supported nonnegative integer. Validate types
  and finite numbers, not truthiness (zero/false/empty arrays can be intentional).
- Theme/pack/module/action IDs are data, never QML paths or commands. Known
  actions come from registries. Unknown IDs remain in the stored document with
  diagnostics and an explicit effective fallback/dormant state.
- Bar IDs must be unique across sections. Duplicate placements from an external
  file use the first occurrence in the effective model and produce a warning;
  the GUI rejects creating duplicates. Unknown entries remain editable/dormant.
- CC instance keys are unique. Reject unsupported module/presentation pairs in
  the GUI. Singleton controls cannot be duplicated within the same presentation
  list; a volume tile and volume slider are intentionally allowed.
- Roundness multipliers are finite 0–2, default 1; role overrides also accept null.
  Columns are integers 1–16 as an initial protective bound, with responsive
  effective columns (section 6). This supports 4–8 and more, not a fixed four.
- Partial documents merge defaults by **field**, replacing arrays as whole
  ordered lists. Empty arrays stay empty. Unknown keys survive round trips;
  unsupported content never executes. Reject prototype-related keys in maps.
- Malformed JSON retains the last valid effective snapshot. On first startup,
  use defaults in memory with a visible diagnostic; never overwrite the bad file.
  Invalid individual fields can use defaults in the effective snapshot while
  retaining their raw value. Block saving until diagnosed fields are repaired
  or explicitly reset, so changing a theme cannot silently erase other data.

Settings exposes a read-only effective snapshot, revision, diagnostics and
save state (`saved`, `pending`, `error`, `conflict`, `readOnly`). Commands are
specific operations such as `setTheme`, `setRoundness`, `setBarPlacement`,
`setControlLayout`, `resetSection` and `resetAll`. Apply a validated transaction
by replacing objects/arrays, not mutating nested `property var` values in place.
This gives QML bindings an explicit notification boundary. Keep old placement
aliases/read accessors temporarily while consumers migrate.

### Persistence and external edits

Settings remains the **only writer**, also when its desktop window is closed.
Use FileView text + JSON parse/serialize for this versioned nested document;
replace the flat adapter only after migration/save tests pass. The proposed
sequence is validate → publish safe live values → debounce save (about 250ms) →
serialize latest revision → atomic write → acknowledge that revision. If another
edit arrives in flight, save the newer snapshot next. Expose unsaved status on
failure; do not falsely roll back live values or show Saved.

FileView's documented atomic write and watcher behavior support this approach,
but do not provide a transactional multi-writer store. Reload external changes
after load completion; identify self-write notifications by content, not by
ignoring the next event. With pending edits and external changes, stop automatic
writing and offer Reload external / Keep my changes after review. Re-read the
baseline before writing; a concurrent editor race remains possible without a
file-lock/CAS helper. Do not claim lossless simultaneous editing. If stronger
guarantees become necessary, add that small persistence helper separately.

Before the first migrated save, keep an exact original backup under
`$XDG_STATE_HOME/magi/settings-backups/` (fallback `~/.local/state`), not among
QML sources; report backup failure and leave disk unchanged. Resolve/check the
settings target before atomic replacement: the audited project file is regular,
but a deployed file may be a symlink. Never replace a symlink unexpectedly or
silently redirect a read-only configuration elsewhere. Persist through a known
writable canonical target, or expose read-only mode. Test both arrangements.

See the [version-specific evidence](../research/settings-spike-references.md).
Write failure, symlink handling and watcher ordering are **required future tests**.

### Migration, reset and rollback

Treat the current unversioned document as v0. Pure `v0ToV1` maps:

| Old value | Proposed mapping |
| --- | --- |
| `palette: "catppuccin"` | `appearance.theme: "catppuccin-mocha"` |
| `palette: "everforest"` | `appearance.theme: "everforest-dark-hard"` |
| Three `bar*Plugins` arrays | Copy into `bar.left/center/right`, preserving explicit empty lists and order. |
| Missing center list | Preserve old v0 effective default `[]`; new v1 installations default to `["workspaces"]`. |
| Unknown palette | Preserve unresolved ID and report Mocha effective fallback; never silently reinterpret as Everforest. |
| Other keys | Preserve unknown fields without conflicting with canonical keys; ambiguous mixed old/new fields require repair, not guessed precedence. |

Migration runs in memory on read and is idempotent. Do not rewrite settings on
startup merely to stamp a version; write v1 only after an intentional save/reset
and successful backup. Future migrations chain v1→v2→v3 and validate the result.
A newer unsupported version is read-only: show the last valid snapshot or safe
defaults and explain the mismatch; never downgrade or save over it.

Reset one control deletes its override; radius null means inherit master.
Reset section replaces only that section with defaults (including its overrides).
Reset All resets known preferences after confirmation; unrelated unknown keys
are retained unless the user explicitly chooses a clean-document reset. Neither
reset changes system volume/radios, deletes imported assets, closes a password
dialog or clears live connection state. Save through the same pipeline.

Rollback old code together with its exact pre-migration settings backup. Old
Settings.qml cannot read v1; switching code alone is not a supported rollback.
No automatic downgrade or dual-writing flat and nested schemas.

## 3. Theme registry and semantic appearance

Retain `Theme.qml` as the stable consumer facade. Add `ThemeRegistry.qml` loading
a bundled manifest and validated JSON palette definitions; no component checks
for theme names. A definition has formatVersion, ID, label, family, light/dark,
source/license metadata and a complete semantic color map. The manifest gives
ordering and paths. No runtime fetching, dynamic QML imports or color-generation
dependency is needed. Adding a palette means one data definition + manifest
entry and role/contrast checks.

Initial IDs: `catppuccin-mocha`, `catppuccin-macchiato`, `catppuccin-frappe`,
`catppuccin-latte`; retain `everforest-dark-hard` and add dark medium/soft, then
light hard/medium/soft as their role mappings are checked. All are the same
contract. Missing required colors reject a definition as a unit, using Mocha
as effective fallback rather than creating a mixed light/dark palette.

| Semantic role set | Meaning / initial mapping policy |
| --- | --- |
| `background`, `surface`, `elevated`, `overlay` | Base and grouped/elevated surfaces; retain existing Mocha roles initially. |
| `text`, `subtext`, `muted`, `inactive`, `onAccent` | Readable foreground and inactive treatment, explicitly mapped for light palettes. |
| `accent`, `blue`, `lavender`, `green`, `yellow`, `peach`, `red`, `teal` | Semantic accent channels; Mocha accent remains lavender. Everforest lavender can map to its purple, peach to orange, teal to aqua, explicitly in its data. |
| `border`, `rim`, `focus`, `success`, `warning`, `danger` | Interaction/status colors; aliases can retain existing Theme API. |
| Control fills/foregrounds | Theme-derived active/inactive tile and slider roles with contrasting foregrounds; avoid unconditional white or naive lightening in Latte. |

Raw palette names/hex values belong only in palette data. Central semantic
control styles choose roles (e.g. network teal, Bluetooth blue); module bodies
consume styles, not theme IDs. Live theme preview changes colors without
reconstructing plugins or changing geometry. Test the entire shell, including
password UI, for readable contrast; this is not permission to redesign it.

`RenderTokens.qml` initially keeps geometry but forwards colors to Theme; then
rename/extract `DesignTokens.qml` when consumers are ready. Historical sampled
hex values stay in the render document, not a secret alternative default theme.
Palette sources and license obligations are in the reference ledger; pin their
exact versions before bundling new data. No palette assets copied in this spike.

### User settings versus internal tokens

| User-facing preference | Internal implementation value |
| --- | --- |
| Theme and icon pack | Color-role mapping and icon baseline metrics |
| Master roundness, Advanced per-role overrides: `barPill`, `surface`, `controlTile`, `slider`, `action` | Reference radii and geometric clamping; phase-dependent interpolation between pill/header/surface |
| Bar visibility/section/order | 48px reservation, native origin, hit areas, Row spacing and edge margins |
| CC module order/assignment/enabled and requested columns | Minimum tile size, responsive limits, gaps, padding, body height calculation |
| Explicit profile name/avatar/subtitle later | Text elision, avatar layout and typography hierarchy |
| Preferred media player later | Player capability handling and artwork loading |

Roundness proposal: master multiplier default 1; nullable per-role multiplier
overrides it. Radius = reference role radius × effective multiplier, clamped
to half the smaller dimension. Zero is square. Distinct default role radii
preserve proportions; a global raw pixel radius would not. The GUI labels
Square–Reference–Rounder, with live sample controls and Default per role.
Internal padding, baseline offsets, tiny gaps, font hierarchy, animation timings,
exclusive zone and host mode are not first-release appearance controls.

## 4. Semantic icons

Add `IconRegistry.qml` plus `components/controls/Icon.qml`. Callers request a
role and optional module ID, size and semantic tint; the resolver returns a
descriptor, not a QML component path. The existing font glyphs become the first
`magi-legacy` pack to avoid replacing artwork and APIs at once. Descriptors can
be `{kind: "glyph", font, text}` or `{kind: "svg", assetId, tintable}` with
consistent view-box/baseline metadata. No arbitrary SVG strings in module QML.

Initial role vocabulary includes `wifi`, `wifi-low`, `wifi-off`,
`bluetooth`, `bluetooth-connected`, `bluetooth-off`, `volume`, `volume-low`,
`volume-muted`, `brightness`, `battery`, `battery-charging`, `settings`,
`night-light`, `dnd`, `power-profile`, `media-play`, `media-pause`, `media-next`,
`media-previous`, plus navigation roles. Roles reserve vocabulary, not unsupported
features. Service presentation adapters choose state roles from existing state;
do not rewrite Network operations to remove its legacy glyph accessor.

Resolution, highest priority first:

1. Individual module+role override, then global role override.
2. Explicit module pack selection, if supplied by the user.
3. Selected global pack's role.
4. Module/core bundled default role, then a neutral missing-icon fallback.

Thus global selection establishes the look, component choices refine it and
individual overrides win. Missing variants may use a declared neutral base-role
fallback, never imply a connected/full-battery state incorrectly. Unknown pack
or missing asset yields a diagnostic and fallback, not a blank essential control.
Default removes the relevant override and reveals inherited selection.

Settings initially needs a pack selector and compact component/role override
editor, not a gallery/browser. Bundled replacement choices use registry asset
IDs. Override-map values are tagged descriptors: for example
`{source:"bundled", pack:"magi-legacy", icon:"wifi"}` or
`{source:"user", assetId:"user:sha256:<digest>"}`. Global overrides are keyed by
role; module overrides are keyed first by module ID, then role. No override is
represented by deleting the entry. Imported SVG uses the stable asset reference;
do not serialize arbitrary executable paths.

Proposed import boundary (a small tested helper when imports are implemented):
local regular SVG only, explicit file selection, maximum 256KiB and bounded
dimensions/element count; reject DTD/entities, scripts, foreignObject, external
links/resources and animation. Permit a documented static shape/path/gradient
subset, with only checked internal fragment references. Copy validated bytes to
`$XDG_DATA_HOME/magi/icons/` (fallback `~/.local/share`), content-addressed and
immutable; settings references that copy, not a moving source file. Never
interpolate filenames into shell commands. Invalid/missing assets keep the last
valid selection. Preserve supplied colors unless tintability is declared.
Qt SVG rendering is not a general security sandbox: validator limits and rendering
must be tested before exposing import. Assets are not deleted by Reset.
Pack manifests carry attribution/license; do not redistribute existing font or
third-party SVG assets without checking their individual license.

## 5. Proposed production structure and ownership

Only create files as their stage needs them; names below are a plan, not a
requirement for a large directory reshuffle.

```text
.config/quickshell/magi/
  settings.json                         # existing path, future v1 data
  settings/SettingsSchema.js            # defaults + validation + normalization
  settings/SettingsMigrations.js        # pure sequential migrations
  services/Settings.qml                # sole persistence/live snapshot owner
  services/Media.qml                    # later: MPRIS selection/capabilities
  theme/Theme.qml                      # existing semantic facade
  theme/ThemeRegistry.qml               # data registry; add to theme/qmldir
  theme/DesignTokens.qml                # geometry/typography only, staged extraction
  theme/palettes/manifest.json, *.json   # complete validated palette definitions
  icons/IconRegistry.qml, qmldir
  icons/packs/manifest.json, *.json      # glyph/SVG role data + attribution
  components/controls/Icon.qml          # shared rendering, accessible caller labels
  components/bar/Bar.qml                # unchanged native/input/focus ownership
  components/bar/SharedStatusSurface.qml # unchanged lifecycle/navigation host
  modules/ModuleRegistry.qml            # explicit built-ins, action/state adapters
  modules/ModuleInstances.qml           # stable per-Bar view/session instances
  plugins/bar/...                       # current status/body implementations retained
  plugins/bar/controlcentre/ControlCentre.qml # ordered descriptor rendering
  plugins/bar/controlcentre/ProfileHeader.qml # later, explicit user content
  plugins/bar/controlcentre/MediaControls.qml # later, real player only
  components/settings/SettingsWindow.qml # one lazy FloatingWindow
  components/settings/SettingsPages.qml  # minimal explicit page registry
  components/settings/pages/{Appearance,Bar,ControlCentre}Page.qml
tests/settings/                        # pure migration/save-contract tests
tests/shared-status-surface/            # existing lifecycle tests, extended as needed
```

Keep singleton dependencies acyclic: Settings/schema → data registries/Theme →
views; Settings never imports Bar or Theme for its defaults. Explicit validated
ID catalogues can be shared as data. Registries describe capabilities; they do
not own another Network/Audio/Bluetooth service. Register new singletons through
the existing qmldir pattern. No user settings can import third-party QML.

ModuleInstances must retain the existing plugin/session objects independently
of bar delegates. Extract a compact status delegate only where necessary;
settings reorder/hide that delegate without destroying Wi-Fi's result listeners
or creating a second session. In combined mode those same body Components still
feed the one SharedStatusSurface. Bar retains the actual Item lookup and Region;
MenuController keeps only IDs/history. This separation is a checkpoint, not an
unreviewed host replacement.

Anchored rollback still loads only its existing adapter. A detail with no visible
pill needs a deliberate fallback anchor: use the invoking visible Control Centre
pill for CC navigation; leave existing visible-pill TransformWatcher geometry
untouched. If neither trigger exists, decline that navigation with a diagnostic.
Do not instantiate an invisible native host to solve lookup. This new hidden-view
case requires a bounded fallback test before hiding detail pills is exposed.

## 6. Control Centre module contract and layout

Settings entries identify **instances/order**, not runtime code. For example:

```text
{ key: "network", module: "wifi", enabled: true, presentation: "tile" }
```

Registry definition contract:

| Field | Owner / behavior |
| --- | --- |
| `id`, label, supported presentations | Static built-in definition; e.g. tile, slider, status. |
| `available`, `active`, status text, numeric value | Live bindings to existing service adapters; hardware absence is not user-disabled. |
| `iconRole`, `accentRole` | Semantic presentation, no palette-specific hex/glyph. |
| `primaryAction`, `secondaryAction`, `detailViewId` | Registered capability IDs mapped to code callbacks. No arbitrary commands in JSON. |
| Minimum/preferred size, singleton rules | Layout metadata; actual geometry derives from available logical width. |
| `bodyComponent`, keyboard eligibility | For detail views, existing plugin contract, not stored configuration. |

Primary Wi-Fi/Bluetooth toggles stay as now; Sound toggles mute; Power remains
read-only until a real power-profile backend exists. Sliders call current Audio
and Brightness APIs. Secondary/right-click invokes navigate(detailViewId) inside
the open shared surface; the same method can later serve long-press. Hide/disable
secondary affordances where no detail exists. Assignment chooses a registered
module and its supported actions; v1 need not be a general action editor.

Render ordered enabled entries using delegates; reorder by stable `key`, including
future drag/drop, and replace `module` without changing the slot key. Keep view
instances outside delegates so reordering cannot duplicate services or reset a
network session. Retain unavailable controls with disabled state and explanation
unless a definition explicitly declares conditional visibility. Brightness must
not appear operative when its backend is unavailable.

Requested columns are not a promise to fit eight 60px tiles into 320px. Compute
preferred width from columns × reference tile size + internal gaps/insets; cap
it to the output's available logical width while respecting the existing compact
cluster width floor. Effective columns are the greatest fit up to the request;
wrap remaining controls, maintain useful hit sizes, and bound/scroll body height
if needed. Show the effective count in Settings. A fitting eight-column row is
valid on a wide output; a narrow output wraps it. All geometry changes remain
presentation targets and never alter the 48px exclusive zone.

**Remove the duplicated battery state/time row during this stage.** Keep Battery
in the status header and an optional Power control. Recompute body height; do not
leave its former 36px plus gap as empty space. Profile/media later add only their
real content height. No final comprehensive module list is required now.

For the first release, structural configuration applies when the shared surface
reaches phase 0 and no password/pending connection interaction is busy. Show
“Layout will update when the menu closes”; saving the desired value need not wait.
Color/radius/icon previews remain immediate. A later small, explicitly tested
same-view geometry retarget can remove this deferral without changing phases or
timings; it is not part of this spike. Do not rebuild the live bar per slider tick.

## 7. Dedicated Settings window and UX

Use Quickshell 0.3.1 `FloatingWindow`, lazy-created by shell-level window management,
without a layer-shell role, exclusive zone, parent menu or shared-surface Region.
It uses the existing Settings singleton in the same process. A future launcher/IPC
command requests that one window; it does not spawn a second settings writer.
“FloatingWindow” means a normal top-level client, not a guarantee that Hyprland
automatically floats it. Normal compositor move/resize/tiling policy applies;
do not inject Hyprland rules. Verify decoration/title, minimum size, scaling and
keyboard accessibility locally before advertising the window as finished.

Opening Settings from a transient surface first closes that surface and waits
for its focus eligibility to clear, then shows/activates Settings. Do not add
another global focus grab. Opening during the Wi-Fi password flow must not
destroy/steal that dialog; defer the request or leave it user-activated. Closing
Settings closes its window, not MAGI, and pending saves remain service-owned.

Initial pages only:

1. **Appearance:** theme list, live swatch/control preview, global icon pack,
   master roundness and collapsed Advanced role controls; per-control and section
   reset. Compact icon override editor may be a subpage once imports are tested.
2. **Bar:** three ordered groups, enable/disable/move controls, available modules;
   initially buttons/selectors, drag/drop later. Explain that hiding a status item
   does not disable its device or remove its CC detail view.
3. **Control Centre:** requested/effective columns, ordered control/slider slots,
   enable/disable/replace and preview. Reuse the same module metadata.

Expose save/error/conflict state quietly but persistently, and a config location/
schema version readout. No global Apply button. Future Menus/Surfaces, Notifications,
Icons and Advanced/About become pages only when they contain implemented controls;
surface radius belongs in Appearance now. A dedicated Settings styling pass can
follow; do not copy the compared shells' visual layouts.

Bounded reference takeaways: make override/reset precedence visible (Noctalia),
use semantic theme data with live preview (DMS), and keep bar placement as ordered
data (Serpantinum). These are design inferences from documentation, not claims
that MAGI has tested or adopted their implementations. See the
[evidence and version limits](../research/settings-spike-references.md).

## 8. Implemented Control Centre milestone: profile and real MPRIS

Profile's implemented settings shape is
`{displayName:"", subtitle:"", avatar:null}`; Control Centre section visibility
is stored separately. Configure deliberately;
no automatic username, hostname, account photograph or other identity. Store an
imported local avatar asset reference, validate/decode/copy separately from SVG
icons, and allow deletion/reset of the reference. An enabled empty name/avatar
does not fabricate a profile; omit unavailable fields and collapse an empty area.

Implemented media shape:
`{enabled:true, preferredPlayer:null, emptyState:"collapse"}`. `Media.qml` wraps
Quickshell.Services.Mpris, not an independent polling playerctl state store.
Select explicit user choice if present; otherwise retain a still-playing current
player, then another playing player, then a stable available player. Persist a
stable preference only where an identity is suitable; do not persist a transient
DBus instance suffix as an everlasting device identity.

Bind artwork/title/artist and playback live. Previous, play/pause and next must
respect player capabilities. A player that disappears invalidates references
and chooses another or collapses. Paused players may remain visible; no player
means no fake artwork/track or decorative media placeholder. Missing artwork
uses an intentional neutral icon without inventing metadata. Decode/cache only
the selected player's artwork with stale-load protection; allow validated local
or HTTP(S) artwork URLs, reject other schemes, bound downloads/decode sizes and
handle failure. Remote artwork policy must be explicit in that milestone.

ProfileHeader and MediaControls are body sections in the existing CC surface,
not new windows. Their presence affects content height. Before enabling dynamic
player appearance while CC is open, validate a bounded geometry-target update
or use the documented closed-surface deferral. This is a real integration test,
not evidence that the current height animation already handles it.

## 9. Staged implementation and review gates

Every implementation stage should be independently reviewable/rollbackable.
Do not combine settings migration, service ownership extraction and GUI launch
into one change. S1/S2 authorization followed this spike; later stages remain proposed.

| Stage | Smallest useful change | Checkpoint / rollback |
| --- | --- | --- |
| S1 Configuration core | Pure v0→v1 migration/default/validation functions, sole writer and compatibility accessors; no GUI or palette change. | Test both old palettes, missing/empty arrays, unknown keys, malformed/newer versions, reset, failed writes, watcher loops, rapid edits and external conflict using temp paths. Confirm backup/restore. Roll back code + original JSON. |
| S2 Theme/appearance | Data registry, Mocha default and Catppuccin variants, Everforest mappings, semantic radius facade. Route sampled CC colors through Theme; keep geometry. | Validate complete role maps and contrast including Latte, live edits while opening/closing, reset/restart persistence; original lifecycle 44-step test plus 48px/log check. Screenshot review. Roll back facade/registry consumption; retain v1 core. |
| S3 Icons | Registry + legacy glyph pack, incremental role consumption; then guarded SVG import/overrides. | Confirm identical initial glyphs, state semantics, missing font/pack/asset fallback, inheritance/reset and malformed asset rejection. No service-operation changes. Roll back Icon consumers independently. |
| S4 Module configuration | Stable view/session instances independent of bar placement; descriptor-driven CC and ordered controls; remove duplicated battery row. | Hide Wi-Fi/BT pills yet open their CC details; reorder across sections, columns 4/5/6/7/8+, narrow screen and empty lists. Test password/pending deferral, no duplicate owners, navigation/back, interruption, consumed dismissal, fullscreen and 48px. Bounded anchored fallback including hidden-detail anchor. Stop on lifetime/geometry blocker. Roll back this stage's registry/placement consumers to last accepted data. |
| S5 Minimum Settings window | One normal desktop window, Appearance/Bar/CC pages, live changes and reset/save diagnostics. | Move/resize/close/reopen; only one window; normal desktop focus; no extra reservation; close window mid-save; external-file conflict; menu→Settings and password coexistence. Manual operator check. Window rollback does not remove configuration core. |
| S6 Profile/media | Explicit user profile plus real MPRIS adapter/body section. Add schema migration only now. | Test no player, paused/multiple/disappearing players, missing capabilities/artwork, open-view height changes, no identity defaults. Real-player and geometry acceptance required. Roll back media/profile consumers + corresponding version backup if reverting schema code. |

At QML stages run qmllint and git diff --check, existing relevant regressions,
then an authorized runtime check for clean logs, one native host and 48px.
Operator tests remain necessary for visuals, keyboard/pointer/fullscreen,
password connections and real Bluetooth/media capabilities. Do not claim
multi-output or fractional-scale validation from the existing scale-2 session.

## 10. Review decisions and remaining uncertainty

Original spike recommendation was S1 only. The user subsequently approved S1 + S2;
both are now implemented. The remaining stages still require review.
The architecture is small enough to implement without a framework, but the
implemented choices are multiplier-based roundness, the existing settings path,
column cap 16 in the schema, legacy glyph pack identifier, idle deferral for bar
placement and the real Control Centre pill as hidden-view fallback anchor.
CC layout consumption, bounded SVG override assets, explicit profile and real
MPRIS media are implemented. See the latest
[checkpoint](../research/profile-media-icons-checkpoint.md). Module-specific icon
override UI, real multi-player operator coverage and final morph work remain.

Required future investigation is implementation-bounded: FileView failure/
watcher/symlink tests, Qt SVG subset support, normal-window focus behavior,
light-theme contrast, hidden plugin lifetime, responsive same-view height and
MPRIS artwork/capabilities. No broad external-shell research is prerequisite.
