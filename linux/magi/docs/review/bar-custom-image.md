# Custom Image Bar item

Native visual acceptance passed on 2026-11-09. The operator authorized one focused
commit, `magi: add custom animated bar image`, and explicitly withheld push approval.
The reviewed source is deployed in `~/dotfiles`; no further reload is needed for
commit closeout. Schema remains **22**.

Current operator configuration is **20px high**, trim enabled, ordered
**Time → Date → Custom Image** in the left region. Centre Workspaces and the right
region `[bluetooth,wifi,volume,controlcentre,battery]` are unchanged. Live Settings
is local, ignored and untracked. Its current bytes are preserved exactly during
commit closeout; neither the Settings file nor the operator's artwork enters Git.

Baseline before development was `53adb11d866da6a5f55440c036027b9257502db1`, with
main/origin/main synchronized, divergence 0/0 and clean working tree/empty index.
One ephemeral worktree, `/tmp/magi-bar-image-VCzYlv`, holds the development source
and is retained until separately approved push/synchronization closeout.

## Architecture audit and decision

- `SettingsSchema.barIds` is the placement catalogue; `bar.left/center/right` own
  ordering and `bar.modules` owns sparse per-item options. Schema remains 22;
  defaults/migrations do not insert the item or alter existing placements.
- `SettingsStore.placeBar` and `BarCanvas` retain drag/drop, keyboard/context placement
  and persistence. `BarPage`/`BarInspector` select the new artwork family, distinct
  from status/workspace pill families. Import/height/trim controls appear in Layout
  and Appearance; background, icon tint, shade and roundness controls do not apply.
- `Bar.pluginComponents` instantiates the same `CustomImage` presenter in any region.
  Rows retain 6px normal spacing and 28px pill alignment inside the 48px reservation.
  Image content is centered, 32px high by default (16–40px), with a 240px width cap
  and preserved aspect ratio. Settings previews use that same presenter.
- `BarFleet` continues owning enabled outputs. Each Bar consumes the shared Settings
  asset; Custom Image appears on every enabled output, unlike main-only Tray.
  Output removal destroys its local player. Hidden presenters pause native playback.
- `CustomImage` contains an unpainted Item and a clipped image viewport. GIF uses
  QtQuick `AnimatedImage`; PNG/JPEG/static WebP use `Image`. No background, border,
  mask, semantic icon resolver, shader tint or input handler. The Bar's pill blur
  collector explicitly excludes this item. A user-enabled whole-Bar background
  remains the existing environment behind all items.
- `AssetManager` queues the existing one-shot Python helper. Its `bar-image` import
  uses Qt `QImageReader` via installed `python-pyqt6` to decode all composited frames,
  including disposal and later-frame content, and calculate the union of alpha > 0.
  It stores the original bytes under `$XDG_DATA_HOME/magi/bar-images/<sha256>.<ext>`.
  Settings stores `{asset:{id,width,height,bounds},height,trim}` in `bar.modules.customImage`.
  Bounds are `[x,y,width,height]` in source pixels; disabling trim fits the full canvas.
  There is no frame extraction, re-encoding or per-frame external process.
- Imports accept only local files, GIF/PNG/JPEG/static WebP, up to 20MiB, 4096px per
  dimension, 500 frames and 100 million decoded pixels; the decode loop also checks
  a ten-second budget between frames. Invalid/empty imports leave the prior selection.
  Missing/failed runtime images collapse without a placeholder pill.

## Supplied asset and rendering evidence

`~/Downloads/Animated AE86 Drift Smoke Loop.gif` is user-supplied personal artwork;
no redistribution licence was supplied. It is not bundled or committed. Original
SHA-256: `bac2b6043a2a1b505dbd04f48ff34c969a58d7e6029af32aeec4a0534afca40c`.

Qt decodes 8 frames at 443×443, 130ms per frame, 1040ms per loop, infinite looping.
First-frame bounds are `[15,168,414,146]`; the all-frame union is `[3,167,427,147]`.
A first-frame-only crop would clip later smoke. At the currently saved 20px height,
the union occupies approximately 58.10px width. Imported bytes preserve the original
palette, alpha, disposal, timing and loop metadata.

Native Qt offscreen tests verify original colours, GIF alpha, partial PNG alpha,
background composition through transparent pixels, native looping, later-frame
content, replacement/clear, region ordering, multiple Bar presenters and reload.
Settings interaction checks cover slider mouse input, 1px keyboard/stepper changes,
synchronized controls, immediate preview/runtime size and persisted height after
reload. Size controls are available in both Layout and Appearance.

Synthetic `tests/bar-image/alpha.gif` is original fixture artwork: a red rectangle
plus a larger blue second-frame rectangle on alpha, 24×24, two 130ms frames,
infinite loop and disposal Background. It covers later-frame bounds without
redistributing the operator's artwork.

An early decode-size binding loop was corrected before deployment: sourceSize now
comes from validated metadata/display scale and is capped by original dimensions,
not the image's provisional implicit width. No failing test was exempted.

## API evidence (inspected 2026-11-09)

Installed target: Quickshell 0.3.2; Qt base 6.12.0-3, Qt declarative 6.12.0-4,
python-pyqt6 6.12.0-2. No package install is needed on this host. On other hosts,
`python-pyqt6` is required for this import operation; playback remains native QML.

- [Qt 6.12 AnimatedImage](https://doc.qt.io/qt-6/qml-qtquick-animatedimage.html):
  native frame playback, frameCount/currentFrame, pause, cache and sourceSize.
  The presenter uses these existing APIs; no Quickshell extension was added.
  A separate static Image avoids the documented static-to-animation playing-state
  caveat. Scaled decode size follows output pixel ratio; frame caching is disabled.
- [Qt 6.12 QImageReader](https://doc.qt.io/qt-6/qimagereader.html): sequential read,
  image count/size/format and animation handling. Import reads from the same bounded
  in-memory bytes later persisted, so the measurement and stored source cannot race.
- [Qt 6.12 Image](https://doc.qt.io/qt-6/qml-qtquick-image.html): native image scaling
  and sourceSize. The viewport offsets the full image against the alpha union;
  it does not depend on animated sourceClipRect support.

The documented [Quickshell 0.3 file watcher](https://quickshell.org/docs/v0.3.0/types/Quickshell/Quickshell/)
was checked against installed metadata on 2026-11-09. Its default file watching
reloads changed configuration; normal reloads retained the existing shell process.
No temporary executable hook, alternative layout or external animation player exists.

## Deployment, acceptance and protected state

The original GIF was imported into `$DATA/magi/bar-images`. Initial placement used
the existing Settings writer with expected-content checking. Subsequent size choices
were made through Settings; commit closeout leaves the currently saved 20px value
and every other preference unchanged.

The existing Quickshell session (PID 1594, instance `a81iy68ot`) logged successful
source loading at 09:26:05.747 UTC and successful size-control reload at
09:39:33.177 UTC. No QML/image errors followed those reloads. Existing Wi-Fi null-device
and Wayland text-input focus warnings predate this feature. Direct IPC readback was
sandbox-denied, so runtime-load evidence comes from session logs and the normal
file watcher. The operator separately confirmed native visual acceptance after
reviewing the size controls. Physical mixed-DPI/multi-output acceptance is not
inferred from that confirmation.

Private evidence and rollback bytes are retained in
`$STATE/magi/audits/bar-image-9e533xur`, including deployment manifests, Settings
snapshots, source inventory, reload logs, protected file/link hashes and commit
preflight records. Initial deployment protected 720 entries. During application,
only the ignored assets.py bytecode cache refreshed to match the changed source;
unrelated config, icon, theme-generation and journal bytes were preserved. Commit
preflight captures 693 non-source entries and the exact current Settings bytes.

Review captures and all-frame alpha measurements are in
`/tmp/magi-bar-image-review-gbbkos_m`. These offscreen captures support the rendering
checks; the operator's live acceptance is separate evidence.

## Regression and commit gate

The earlier complete 103-suite matrix passed **99 PASS / 4 ENVIRONMENT / 0 FAIL /
0 UNKNOWN / 0 SKIPPED** (`/tmp/magi-regression-u7ubcz1g`). The final size-control
interaction suite passed separately (`/tmp/magi-regression-o1ejqjqs`).

The final complete matrix, including the finished size controls, passed **99 PASS / 4 ENVIRONMENT / 0 FAIL / 0 UNKNOWN / 0 SKIPPED** (`/tmp/magi-regression-3mb5bbpe`).

The four established environment limits are `bluetooth/bus`, `clipboard/model`,
`notifications/run` and `native_lock`. Native lock builds successfully; unchanged
source hashes and independent SOCK_SEQPACKET/private D-Bus denial probes bind its
existing exemption. No exemption is broadened by this feature.

The commit inventory is 21 modified and 6 added source/test/documentation files,
with no deletions. Settings, managed originals, audit state and generated files are
excluded. Push requires separate operator approval; retain the worktree until the
approved commit has been pushed and synchronized.
