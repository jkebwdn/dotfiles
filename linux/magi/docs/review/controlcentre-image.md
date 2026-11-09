# Control Centre decorative image — accepted

Baseline: `ca87b81f65d143a1c6ef007e27fe79117bbfa9b3`, synchronized main,
0/0 divergence, clean tree and empty index verified before development.
One isolated worktree: `/tmp/magi-controlcentre-image-5qy159st`.
The operator confirmed “tests passed and accepted” on 2026-11-09 after reviewing
PNG, GIF playback, slower reveal and the revised artwork. This acceptance supersedes
the pending native-review notes in the chronological evidence below. The focused
commit is `magi: add control centre image decoration`; push requires separate approval.

Accepted local selection: **Windblown Red-Haired Anime Peek.gif**, height **340px**,
overlap **19px**, vertical offset **−20px**, reveal **320ms**, no flip. The operator
adjusted overlap after the asset replacement; closeout preserves these current
Settings bytes exactly. Schema remains **22**. No operator artwork or Settings enters
Git. Tested source hashes still match the completed **101 PASS / 4 ENVIRONMENT /
0 FAIL / 0 UNKNOWN** regression, and all **689 protected entries** match the original
snapshot. Physical multi-output acceptance and native CPU measurement remain
unverified; operator acceptance does not turn synthetic checks into hardware evidence.

## Composition and ownership

Production `BarFleet` selects `Bar.expandableHostMode: "combined"`. Each enabled
output already has an output-sized transparent `PanelWindow`, anchored to the
configured Bar edge with a 48px reservation. `SharedStatusSurface` expands inside
that window, keeping its right edge at the existing inset. Its painted background
owns radius, background alpha and `SurfaceBorder`; its body alone is clipped.
The alternate anchored PopupWindow path remains intact and has no decoration.

`ControlCentreDecoration` is a sibling of `SharedStatusSurface` in that same
window, at z=11 versus panel z=10. Neither the panel coordinates, window bounds,
reservation nor output selection change. It is not placed in the clipped body.
Only the image's own viewport trims measured transparent source margins. All
nonzero alpha pixels remain within that viewport. It has no background, border,
shadow, tint, semantic icon resolver, input handler or keyboard focus.

The existing precise `PaintedBlurRegion` continues targeting the panel background.
There is no image blur region and no whole-window blur expansion. Panel background
opacity does not affect the sibling artwork. The existing outside-click dismissal
catcher remains in force: image-only areas behave as ordinary outside-panel space,
not image buttons. Full click-through to the underlying app is not claimed while
the existing modal dismissal catcher is active. Hands overlapping real panel controls
are input-transparent QML artwork; they do not consume panel input.

## Asset and Settings model

Settings → Control Centre → Appearance contains a collapsible **Decorative Image**
section. Controls: enable, choose/clear PNG or GIF, height, border overlap, vertical position,
reveal duration and horizontal flip. Each numeric control has a slider and precise
stepper. Existing static composition preview shows the same presenter in Appearance;
it does not create another live Control Centre. Layout editing is unchanged.

Schema remains **22**. Additive `controlCentre.decoration` defaults are filled into
the effective preferences without rewriting an older current-schema document.
Defaults: disabled, no asset, height 340, overlap 8, verticalOffset 0, duration 180,
flip false. Height range 120–600px, overlap 0–24px, vertical offset −300–300px from panel
centre, reveal 120–500ms. These are general product defaults, not accepted artwork
placement values.

`AssetManager` adds a `decoration-image` request to the same serialized worker queue.
The Bar importer delegates to shared `import_measured_image`; validation, all-frame
alpha measurement and atomic content-addressed persistence are shared. Decorations
accept PNG and GIF and retain original bytes in `$DATA/magi/images/<sha256>.<png|gif>`.
The Settings descriptor stores `id`, dimensions and alpha-union bounds. Existing
`bar-image` IDs, URLs, storage and GIF behavior are unchanged. No asset migration,
second importer, conversion process or runtime animation worker was added.

Missing/unreadable assets hide the artwork with no placeholder; the panel opens
normally. Settings reports an unavailable image. Replacing or clearing artwork does
not delete managed originals. Operator artwork is not bundled in Git.

## Animation, geometry and outputs

Reveal follows `SharedStatusSurface.interactive`: the selected Control Centre must
reach phase 3 after its existing horizontal/body animations. This completion-based
trigger uses no timer. The normal path takes approximately 200ms shared expansion
plus 140ms reveal, then the decoration's configurable 120–500ms opacity/12px slide with a gentle InOutCubic opening curve.
On close or navigation to another module the decoration fades for 60ms, before the
panel's existing 70ms fade, 120ms retract and160ms contract finish. Loss of output
ownership hides it immediately. Source readiness, valid geometry, enabled state
and panel identity all gate visibility. Repeated/reversed transitions use one
bounded progress property, not incremental offsets.

The alpha union's right edge is panelLeft+overlap; height preserves aspect ratio.
Vertical positioning is relative to the panel and clamped inside its height and
the output. Horizontal room is measured to the output's left edge with an 8px
margin. The image shrinks to fit; below 96px visible height it hides. The panel is
never moved to make room. Per-output Bar ownership and SurfaceOrigin route the
image with Control Centre, including hotplug. Physical mixed-output acceptance
remains separate from synthetic routing coverage.

Closed state has no running reveal once faded. GIF uses native AnimatedImage with
cache disabled and paused playback whenever hidden or before panel readiness.
The non-owning outputs and static Settings preview pause too. No custom frame
timer or animation worker exists; frame advancement stops while closed. Native CPU/workspace/open-close responsiveness remains an acceptance
check, not an inference from offscreen rendering.

## API evidence

Inspected 2026-11-09 against installed Quickshell 0.3.2-1, Qt 6.12.0 and
python-pyqt6 6.12.0-2:

- [Quickshell PanelWindow](https://quickshell.org/docs/v0.3.0/types/Quickshell/PanelWindow/)
  documents the anchored window and reservation contract. Existing Bar uses it;
  no second Wayland surface is needed. Native compositor behavior is a separate gate.
- [Quickshell Region](https://quickshell.org/docs/v0.3.0/types/Quickshell/Region/)
  documents item/geometry regions. Existing precise panel regions are preserved,
  not replaced with the expanded artwork rectangle.
- [Qt Image](https://doc.qt.io/qt-6/qml-qtquick-image.html) documents readiness,
  asynchronous decoding, source size and smooth rendering. The PNG presenter gates
  on Ready, derives bounded decode size independently of panel animation and uses
  native image alpha. Scaling and composition have pixel assertions.
- [Qt Item](https://doc.qt.io/qt-6/qml-qtquick-item.html) documents sibling stacking,
  clipping and transforms. The sibling z-order bypasses the panel body clip;
  only the measured artwork union is clipped. No effect alters source colour.

## Confirmed artwork and initial tuning

The operator confirmed the final PNG at
`~/Downloads/Anime Woman Peeking with Red Bead Necklace.png` is 1024×1536, with
alpha-union bounds `[102,71,883,1455]` and SHA-256
`520121d459da53d94bd90a0e25e93ae3c30e76dc9282c9986105d998baa0ebe0`.
An isolated XDG render uses a read-only copy of current Settings and managed Bar/avatar
assets. That preview did not write live state. After confirmation and the full regression,
the production asset worker imported the same byte-identical PNG into live storage
and the existing expected-content Settings writer enabled only the decoration entry.
The source PNG is not altered or redistributed.

At initial height **340px**, overlap **18px**, vertical offset **−20px**, reveal
**180ms**, and no flip, the alpha union renders at **206.34×340px**. In the 1920×1080
fixture the panel stays at `[1597,10,304,468]`; artwork is at approximately `[1408.66,54]`.
The hands visibly overlap the real panel border and the body extends left.
These are the initial preview values, not hardcoded product defaults. The operator
approved the native appearance and requested a slower reveal; height/overlap/position
are retained, with the reveal adjusted to 320ms as described below.

Captures and the final warning-free render log are retained in
`/tmp/magi-controlcentre-image-preview-mvf74z2f` (`controlcentre.png`, `settings.png`).
The preview uses isolated service fixtures and is not native compositor acceptance.
No licence to redistribute the operator's artwork is assumed.

## Validation and outstanding acceptance

All **14 affected suites passed**, no failures, warnings or environment exceptions
(`/tmp/magi-regression-7spje9ck`). The complete **105-suite matrix** finished with
**101 PASS / 4 ENVIRONMENT / 0 FAIL / 0 UNKNOWN / 0 SKIPPED**
(`/tmp/magi-regression-qoeishms`). `git diff --check` passes. That full run precedes the timing refinement below; affected tests are rerun for
the refinement, with separate source hashes retained.
The four established environment limits are `bluetooth/bus`, `clipboard/model`,
`notifications/run` and `native_lock`: independently evidenced sandbox bus/socket
denials, with the existing native-source audit still intact. No exemption broadened.
Early harness corrections concern resizing the underlying offscreen QWindow and
opening Appearance after the page's ordinary Layout initialization; warnings and
failed assertions are not exempted as environment limits.

The final operator PNG is confirmed. The operator described the native appearance
as very good and requested slower animation. Acceptance of the revised timing,
explicit input/workspace responsiveness checks and commit approval remain pending.
Do not treat synthetic fixtures as native acceptance or commit authorization.

Protected-state snapshot and rollback bytes are retained at
`$STATE/magi/audits/controlcentre-image-rat0di58`. Current Bar/GIF, themes,
wallpaper, application appearance, lock/fingerprint and monitor/GPU state are
protected. Deployment changed only decoration preferences; all other Settings
values match the fresh pre-deploy snapshot. Of the original 693 snapshot entries,
two are now intended source changes. Of the 691 non-source entries, 689 are
unchanged, Settings differs only by the decoration entry, and the ignored assets.py
bytecode cache refreshed (its compiled code matches the new source exactly).
The newly imported PNG remains byte-identical to the source.

The existing shell instance `a81iy68ot` logged **Configuration Loaded at
2026-11-09 13:28:31**, with no new QML/image errors. Pre-existing Wi-Fi null-device
and Wayland text-input warnings are not introduced by this change. Direct IPC
returned SocketAccessError; no alternative host hook or restart was used. The
host process is outside the sandbox's process namespace, so native CPU measurement
is unavailable here. The initial native appearance is accepted; revised open/close timing, explicit
workspace responsiveness and input acceptance remain pending. No offscreen test is
described as native acceptance.

Proposed commit after review/acceptance approval: **magi: add control centre image decoration**.
Stage exact source/test/documentation paths only. Settings, supplied artwork, managed
assets, generated state and audit files stay out of Git. Push requires explicit
approval and normal synchronization; retain the worktree until then.

## Native timing refinement

The initial dynamic Behavior could begin opening with its previous 60ms closing
duration: the new elapsed-time assertion observed completion before 80ms despite
requesting 320ms. Opening now sets from/to, duration and easing explicitly before
starting the same native NumberAnimation. Panel phase still owns the trigger;
there is no timer. The operator's reveal is 320ms with InOutCubic easing, close
remains 60ms with OutCubic, and the Settings range is 120–500ms. Existing 180ms
product defaults remain compatible. Size, position, artwork and other Settings
are preserved.

Focused validation: **3 PASS / 0 FAIL / 0 UNKNOWN**, including schema, shared panel lifecycle and decoration runtime (`/tmp/magi-regression-sbbq2evx`). The test checks intermediate opening
opacity after 80ms, panel-first ordering, early closing, repeat/reversal, and the
expanded Settings duration control and persistence.

## Requested GIF extension

The user requested GIF support and supplied
`~/Downloads/Playful Red-Haired Peek Animation.gif`. Qt reads **512×512**, **6 frames**,
**180ms per frame**, **1080ms per loop**, infinite looping. Every frame has transparent
pixels. First-frame bounds are `[65,5,355,505]`; the all-frame union is
`[14,5,407,506]`, so later hair movement extends substantially farther left.
The source SHA-256 is
`b8703aaebef20f2718093bf9efa1a85fc1add2fde128a552157195e23db1e9fb`.
Original bytes, frame delays, disposal and alpha are retained. The PNG import is
kept for rollback; neither artwork file is bundled in Git.

The existing importer, descriptor and Settings fields now accept `.gif` alongside
`.png`, with schema 22 unchanged. The presenter selects Image or AnimatedImage via
a Loader; this avoids static-image replacement leaving animation stopped. Decode
resolution follows configured size/output DPI, not panel motion. GIF playback
pauses before panel readiness, on close, while hidden and on other outputs. The
Settings composition stays a still preview. The original 320ms panel-first reveal
and placement controls are independent of GIF frame timing.

Coverage adds byte-identical GIF import and all-frame bounds, native loop advance,
closed-frame stability/reopen, paused preview/non-owning output, PNG↔GIF replacement,
alpha/colour and later-frame pixels. Only the existing deliberately missing fixture's
warning attribution was adapted for Loader. No new environment exemption exists.
Affected importer/schema/Bar checks passed; final GIF runtime passed in
`/tmp/magi-regression-vx1rend0`. The final complete GIF matrix passed **101 PASS / 4 ENVIRONMENT / 0 FAIL /
0 UNKNOWN / 0 SKIPPED** across 105 suites (`/tmp/magi-regression-h912wlzu`).
This includes the timing refinement and GIF support. The four established
environment limits are unchanged. The GIF is deployed with existing placement and
320ms reveal preserved; native GIF acceptance remains pending.

The actual operator GIF also passed native Qt offscreen loop/frame checks; all six
rendered captures and the warning-free log are at
`/tmp/magi-controlcentre-image-preview-mvf74z2f/gif`. At saved height 340, overlap 18,
vertical offset −20, it renders **273.48×340px** from the all-frame union. The live
shell logged Configuration Loaded at **2026-11-09 13:48:24**, without new image/QML
errors. Only the asset preference changed for the GIF switch; source originals and
the existing PNG import remain byte-identical and retained. Source/test hashes in
`gif-tested-source-sha256.json` match both worktrees. Both indexes remain empty.

## Revised artwork selection

The operator accepted the GIF appearance and supplied a revised artwork to avoid
an arm cut off in the original asset: `~/Downloads/Windblown Red-Haired Anime Peek.gif`.
The replacement is **561×466**, **6 frames**, with all-frame alpha-union bounds
`[79,10,353,452]`. Its SHA-256 is
`8d9c04a25c9dc5ee0ad1b6999477524e0a8e6ee05a37dac4486bd3e9b5bd9d6c`.
The shared importer retained original bytes and transparency in the managed image
store. Only the asset descriptor changed; the operator's latest height **340px**,
overlap **23px**, vertical offset **−20px**, reveal **320ms**, and no flip were
preserved. The visible alpha union renders at approximately **265.53×340px** before
compact-output constraints. Earlier managed originals remain available.

All six composited frames decoded successfully; their union matches the imported
descriptor. Settings schema validation passed and every other preference matches
the fresh pre-replacement snapshot. This asset-only replacement changes no runtime
or test code; the complete GIF regression above remains applicable. The revised
artwork is ready for native review. No commit or push is authorized by this swap.
Evidence: `windblown-deployment.json`, `windblown-source-audit.json`, and
`settings-pre-windblown.json` in the existing private audit directory.

## Exact commit inventory

After native acceptance and explicit commit approval, stage only these **24 paths**
(19 modified, 5 added), with no deletions. No staging has occurred at this gate.
The approved title should be `magi: add control centre image decoration`.

- `linux/magi/.config/quickshell/magi/components/bar/Bar.qml`
- `linux/magi/.config/quickshell/magi/components/bar/ControlCentreDecoration.qml`
- `linux/magi/.config/quickshell/magi/components/settings/ControlCentrePreview.qml`
- `linux/magi/.config/quickshell/magi/components/settings/DecorationSettings.qml`
- `linux/magi/.config/quickshell/magi/components/settings/pages/ControlCentrePage.qml`
- `linux/magi/.config/quickshell/magi/components/settings/qmldir`
- `linux/magi/.config/quickshell/magi/services/AssetManager.qml`
- `linux/magi/.config/quickshell/magi/services/assets.py`
- `linux/magi/.config/quickshell/magi/settings/SettingsSchema.js`
- `linux/magi/docs/README.md`
- `linux/magi/docs/architecture.md`
- `linux/magi/docs/architecture/current-system.md`
- `linux/magi/docs/current-roadmap.md`
- `linux/magi/docs/decisions.md`
- `linux/magi/docs/generated-state.md`
- `linux/magi/docs/quickshell-reference.md`
- `linux/magi/docs/review/controlcentre-image.md`
- `linux/magi/docs/technical-debt.md`
- `linux/magi/docs/testing.md`
- `linux/magi/tests/controlcentre-image/schema.cjs`
- `linux/magi/tests/run-all.py`
- `linux/magi/tests/runtime-visual/controlcentre-image.qml`
- `linux/magi/tests/runtime-visual/run.py`
- `linux/magi/tests/settings/assets.py`
