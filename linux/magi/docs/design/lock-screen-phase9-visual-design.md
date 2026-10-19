# MAGI Lock Phase 9A — presentation foundation

2026-10-18. Implementation and offline visual-review checkpoint. **Not installed,
not live-tested, not visually accepted yet.** Baseline verified as
`c7c942656536028b5d775900be69b05ceee00eab` (`magi: retire hyprlock fallback`),
with HEAD/origin/main divergence `0 0` before work. Phase 2–8 security and production
acceptance remains authoritative. No Phase 9B work is included.

## Audit and design ownership

The old `Proof.qml` was a centred debug paragraph: native protocol state, up to
511 bullets, input diagnostics and a proof disclaimer. It contained no media,
weather, clock, avatar or wallpaper. Its native software-render-control path and
plain native fallback remain; the debug composition is replaced.

Sources inspected in the existing shell:

- `theme/Theme.qml` and `theme/palettes/registry.json`: semantic roles, JetBrainsMono
  Nerd Font, role-based roundness. The registry is the palette source of truth.
- `services/Settings.qml`, `AssetManager.qml`, and Control Centre `ProfileHeader.qml`:
  display name and content-addressed avatar assets; no separate profile lookup daemon.
- `services/Wallpaper.qml` and `wallpaper_state.py`: persisted shared assignment,
  with connector **and description** required for monitor-specific overrides.
- `ClockState.qml`, `TimeDatePill.qml`, Calendar styling: locale/12h/24h time,
  semantic ink and the same font family.
- Weather's opt-in configured location and Media's Quickshell MPRIS service:
  neither is suitable as a required independent locker dependency; both deferred.

The visual hierarchy is time/date → identity → authentication. No large card,
editable field, power actions, control panel or glass effect. A full-bleed wallpaper
uses a semantic background overlay (0.78 opacity), allowing both dark and light
palettes. This conservative treatment and the vertical spacing need operator review.

## Components

All components live in `native/lock/qml/` and are compiled resources:

| Component | Responsibility |
| --- | --- |
| `LockScreen.qml` | Responsive composition and safe display values |
| `LockTokens.qml` | Font, semantic colours and main geometry tokens |
| `LockBackground.qml` | Cover crop, semantic overlay and solid background |
| `LockClock.qml` | Large light-weight time and long date |
| `LockProfile.qml` | 96-logical-pixel avatar, initial fallback, display name |
| `LockCredential.qml` | 0–16 visible dots; overflow mark beyond 16 |
| `LockStatus.qml` | Ready/typing/verifying/failure/unavailable and Caps Lock |

Small layouts reduce the clock size and spacing while retaining readable status
text. Display names use plain text and elision. The proof disclaimer is removed
for authenticated normal builds; explicit unsafe development recovery still shows
its warning. Offline previews are visibly labelled.

The renderer creates/destroys a complete QML scene per frame. No QML animation or
Timer is introduced: restarting animations on each credential redraw would be
misleading. A native timer checks for a minute change once per second and refreshes
through `Controller::refresh`, retaining all output lifetime/backpressure checks.
Authentication redraws retain their existing 16ms coalescing. Clock data also updates
on each ordinary frame. Motion is deferred rather than changing renderer ownership.

## Independent, bounded display data

`VisualData` takes one immutable snapshot per locker process. No Quickshell IPC,
subprocess, network lookup, new settings writer or running-shell dependency exists.

- Settings: `$XDG_CONFIG_HOME/quickshell/magi/settings.json` (standard home fallback).
- Palette: sibling `theme/palettes/registry.json`, format version 1; selected theme's
  seven required display roles must all be six-digit RGB values. Unknown themes
  resolve to registry Mocha; malformed/unavailable data uses embedded Mocha roles.
  Catppuccin, Everforest and valid custom registry palettes use the same reader.
- Clock: `calendar.timeFormat` accepts `12h`, `24h`, otherwise system locale short
  time. Long date uses locale day/month names. No novel font or settings schema.
- Identity: `profile.displayName` is bounded to 64 characters; fallback “Welcome
  back”. Managed `avatar:<sha256>.<png|jpg|webp>` resolves under
  `$XDG_DATA_HOME/magi/avatars/`; missing/unsupported assets show an initial.
  Avatar roundness uses the existing avatar role/master multiplier.
- Wallpaper: `$XDG_STATE_HOME/magi/wallpaper/state.json`, version 1, **shared** saved
  assignment. It is cropped to each output's logical dimensions. Monitor-specific
  overrides are intentionally not guessed from connector names: matching the exact
  description is future work. An absent shared assignment yields semantic solid
  coverage even when the shell has a monitor override.
- JSON reads are capped at 1 MiB. Raster files must be absolute local regular files,
  at most 32 MiB, PNG/JPEG/WebP/BMP, at most 16384 on either axis and 64 million
  source pixels. Decode targets are bounded to 3840×2160 wallpaper and 192×192
  avatar. Unsupported/corrupt/missing images fall back. SVG and animated playback
  are not part of this first pass. No raw user path is passed to QML.
- A private image provider exposes only predecoded wallpaper/avatar images.
  Native rounded avatar masking avoids GPU effects. Changes to shell settings or
  assets during a lock take effect on the next locker launch.

Embedded palette/font defaults deliberately allow the installed locker to remain
usable if the MAGI configuration tree is missing. No extra package-owned asset or
new runtime daemon is required.

## Security boundary and multi-output

No authentication/input/authorization behaviour changes. `AuthState`, the existing
value-only `AuthPresentation`, and its unchanged name helper move to
`auth_presentation.hpp`. The renderer no longer includes or links the auth controller.
QML receives bounded count, state name, Caps/input flags, time/date and a whitelist
of visual metadata. It receives **no credential, auth controller, PAM response,
plaintext, worker handle, callback or unlock capability**. No TextInput/TextField,
keyboard handler, pointer handler, clipboard or action control exists in lock QML.

Native credential clearing, retry timing, cancellation, PAM generation validation,
worker reap and authenticated unlock are unchanged. Verifying/failure messages are
presentation only; no animation or UI acknowledgement gates a security transition.
Unsupported PAM details are reduced to “Authentication unavailable” in normal QML.

Phase 9A deliberately retains mirrored global auth presentation on both outputs.
These are passive views of one controller, not independently editable forms. Each
output still gets its own scene/surface/lifetime and compositor logical dimensions.
A focused-auth/quiet-secondary arrangement is a later visual decision requiring an
explicit safe focus-display contract; it is not inferred from registry ID/order.
Output add/remove/replacement and resume use the accepted Phase 6/7 machinery.

Missing assets retain the QML layout. QML creation or scenegraph failure instead
retains/repaints the opaque native semantic fallback with bounded auth/Caps state.
It neither cancels a valid global attempt nor authorizes unlock. All fallback and
stale-output regression tests remain enabled.

## Safe preview

Build the preview separately from production installation:

```sh
cmake -S linux/magi/native/lock -B /tmp/magi-lock-visual -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=OFF -DMAGI_LOCK_VISUAL_PREVIEW=ON
cmake --build /tmp/magi-lock-visual --target magi-lock-preview
/tmp/magi-lock-visual/magi-lock-preview /tmp/magi-lock-renders
```

The executable forcibly uses offscreen software rendering and emits six PNGs:
ready laptop, typing external, verifying, failure/Caps, missing-assets portrait,
and unavailable state. It accepts only an output directory, never credentials.
It contains no Wayland owner, auth controller/worker-spawn implementation or logind
adapter. Symbol inspection is an automated gate. Production-install configuration
rejects the preview option, and no preview is installed. A source archive may
contain its source for development; production execution cannot select it.

Current renders: `/tmp/magi-phase9-renders/`. Reviewed visually during implementation:
`ready-laptop.png`, `failed.png`, `missing-assets-portrait.png`. The last was adjusted
to retain legible status text at 360×640 instead of scaling the entire scene down.
These are synthetic offline renders, **not** evidence of a real lock.

## Validation

Final completed builds: `/tmp/magi-lock-phase9-dev` and
`/tmp/magi-lock-phase9-production`.

| Validation | Result |
| --- | --- |
| Development native CTest | 15/15 PASS, including offline preview capability/render gate |
| Production native CTest | 15/15 PASS, including five-artifact DESTDIR audit and binary gates |
| Native sleep matrix | Existing 39 scenarios PASS |
| Output/failure matrix | Existing 41 scenarios PASS |
| Handoff/request regressions | Existing 19 / 12 PASS |
| New visual tests | 16 size/state/recreation renders at each of Qt scale 1, 1.5 and 2; 48 per build |
| Additional visual checks | Missing/corrupt/network asset rejection, semantic/custom colour loading, malformed registry fallback, missing avatar, count -1/0/1/16/17/511/1000000, state messages, no secret properties |
| Existing presentation fallback | Invalid QML, wrong root, null/portrait buffers, opaque fallback, in-flight auth unaffected PASS |
| Rust | 18/18 PASS; Clippy all targets `-D warnings`; fmt PASS |
| Production controls | Development unlock/injection/worker override gates and install audit PASS |
| Protected snapshot | All 41 captured operator/config/PAM/installed-file hashes unchanged |

Initial sandboxed socket tests failed because required synthetic IPC was blocked;
reruns with host socket access passed. A new JSON temporary-reference bug was found
by the offline preview and fixed before final validation. An explicit test include
was added after separating the safe presentation header. These were implementation
failures, not live acceptance runs. No real lock, PAM authentication, suspend,
Hypridle handoff/restart or installation occurred.

Qt scale tests validate rendering in those environments and logical sizes; they do
not replace future physical mixed-scale acceptance. A 16-render synthetic batch
completed in roughly half a second locally; this is not a live lock acquisition
latency claim. Real presentation/acquisition timing remains a rollout gate.

## Review decisions and rollout

Operator review needed: clock/profile spacing and size, wallpaper visibility,
avatar shape/size, dot/status treatment, and whether mirrored presentation should
remain for the first visual rollout. Current scope intentionally omits motion,
per-monitor wallpaper override matching, weather, media, battery and power actions.

After visual review and any corrections: repeat affected offline gates; separately
approve a rebuilt production package and installation; verify installed hashes and
feature gates; obtain fresh authenticated TTY recovery approval for a real visual
lock test, including mixed-scale coverage. No development timer may be introduced
into production. Live acceptance must check that added image work remains within
the logind delay allowance. Never depend on killing the lock client to unlock.

No staging/commit/push or Phase 9B progression is authorized by this checkpoint.
Power & Idle Settings (5m lock, 10m DPMS, no idle suspend; Hypridle backend), possible
AC/battery policy, and the normal-shell external-display top-bar option remain
later refinement work. They are not lock surfaces and are not implemented here.

## Phase 9A source inventory

25 paths; all unstaged. `qml/Proof.qml` is removed, replaced by the modular resources.

- `linux/magi/native/lock/CMakeLists.txt`
- `linux/magi/native/lock/README.md`
- `linux/magi/native/lock/qml/Proof.qml`
- `linux/magi/native/lock/src/auth_controller.cpp`
- `linux/magi/native/lock/src/auth_controller.hpp`
- `linux/magi/native/lock/src/presentation.cpp`
- `linux/magi/native/lock/src/presentation.hpp`
- `linux/magi/native/lock/src/wayland_owner.cpp`
- `linux/magi/native/lock/src/wayland_owner.hpp`
- `linux/magi/native/lock/tests/presentation_boundary.cmake`
- `linux/magi/native/lock/tests/presentation_test.cpp`
- `linux/magi/docs/design/lock-screen-phase9-visual-design.md`
- `linux/magi/native/lock/qml/LockBackground.qml`
- `linux/magi/native/lock/qml/LockClock.qml`
- `linux/magi/native/lock/qml/LockCredential.qml`
- `linux/magi/native/lock/qml/LockProfile.qml`
- `linux/magi/native/lock/qml/LockScreen.qml`
- `linux/magi/native/lock/qml/LockStatus.qml`
- `linux/magi/native/lock/qml/LockTokens.qml`
- `linux/magi/native/lock/src/auth_presentation.hpp`
- `linux/magi/native/lock/src/visual_data.cpp`
- `linux/magi/native/lock/src/visual_data.hpp`
- `linux/magi/native/lock/src/visual_preview.cpp`
- `linux/magi/native/lock/tests/preview_boundary.cmake`
- `linux/magi/native/lock/tests/visual_test.cpp`

## Phase 9A.1 — blurred wallpaper and stronger auth composition

The operator accepted the Phase 9A architecture, but not its initial visual
appearance. This section supersedes the initial background opacity, geometry and
preview inventory above. Visual acceptance remains pending; nothing is installed.

**MAGI Lock intentionally uses a strongly blurred copy of the current wallpaper,
NOT a blurred screenshot of the live desktop.** The input is exclusively the saved
shared Wallpaper Manager asset already audited in Phase 9A. There is no screen,
window, framebuffer or compositor capture. Sensitive application content cannot
enter this processing path. No Hyprlock runtime dependency is reintroduced.

### Background processing and cache

`wallpaper_blur.hpp/.cpp` owns the strong default: a maximum 640×640 working extent,
12-working-pixel radius and three horizontal/vertical box-blur pairs approximating
a Gaussian. Sliding sums make each pass linear in pixel count. At 16:9 the cached
image is 640×360 (roughly 0.9 MiB ARGB), independent of output resolution. Decode is
bounded as before, now targeting at most 1920×1080 before the working downsample.
Fine detail disappears while broad colours and shapes remain.

This is **CPU preprocessing**, not a QML/GPU live effect. `VisualData::load` calls
`prepareWallpaper` once when constructing the immutable per-process snapshot.
Only the blurred representation remains in that snapshot; decode/working temporaries
are released. Short-lived QML scenes receive implicitly shared QImage references
through the existing private provider. They cover/crop each output independently.
No blur is run on clock, count, Caps, auth-state, output addition or output-recreation
redraws. No full-resolution processed-image cache is allocated per monitor.

Cache lifetime/invalidation is deliberately the accepted Phase 9A snapshot model:

- Locker process exit discards the cache; the next launch reloads settings, selected
  wallpaper path/file bytes, palette and identity and regenerates it.
- Path changes, same-path file modification, theme changes and changed compiled
  treatment therefore take effect on the next launch. There is **no mid-lock file
  watcher**, timestamp polling or incremental cache-key invalidation.
- Geometry/aspect changes only change the cover crop. They do not invalidate the
  shared blurred image. Authentication and time never invalidate it.
- Preview/test code may explicitly construct another snapshot or call
  `prepareWallpaper` with a synthetic image; production rendering does neither.

The global semantic background tint is **42%**, owned by the native presentation
constant and passed as display metadata. Light themes use their semantic background
as the tint rather than introducing arbitrary black. The first bright test showed
that pale ink over a moderately tinted white image was not sufficiently separated.
Instead of crushing the wallpaper or adding a panel, preprocessing compares the
worst sampled contrast across the central UI area using the semantic text and
background colours. It chooses background-colour ink where that is more legible.
Secondary text follows that choice; accent/warning/danger colours are shaded toward
that semantic ink when necessary. Dark wallpapers retain normal palette ink.
This selection is also cached. It is a practical contrast heuristic, not a claim of
universal WCAG compliance for every possible wallpaper/crop. The bright preview is
part of operator review. No halo, opaque panel, glass rectangle or text outline is
used in the final direction.

### Refined composition

Clock weight/style and open date presentation are retained. The profile begins at
36% of the composition height (previously 41.5%), bringing the two visual anchors
closer. Baseline avatar size is 112 logical pixels, username 25, status 16, credential
dots 9 with 10-pixel gaps. Sixteen dots remain the maximum; overflow stays bounded.
The Caps warning is a secondary 13px `⇧ Caps Lock`, under the one main status line.
Ready, typing, verifying, failed and unavailable messages retain their native-safe
state mapping. No retry/clearing/auth policy changes.

One composition scale applies to clock, avatar, spacing, dots and status:

```text
visualScale = clamp(pow(min(logicalWidth / 1920, logicalHeight / 1080), 0.45), 0.8, 1.15)
1920×1080 → 1.0
2560×1440 → approximately 1.138
360×640   → 0.8, with additional available-width clock fitting
```

This affects QML composition only. Native buffer size, compositor scale and output
lifetimes are unchanged. Authentication remains global and mirrored. Shared
wallpaper is independently cover-cropped; monitor-specific assignment support is
still deferred.

Missing avatars now preserve the configured display name and its initial. If
configuration itself is missing, the native account name is resolved with
`getpwuid_r(getuid())`, with numeric UID as the final nonempty fallback. It never
becomes a generic “W / Welcome back” identity. The missing-assets preview removes
only image assets from the normal snapshot, preserving identity and palette.

### Preview and regression record

All ten requested PNGs are generated by the same offline preview:
`/tmp/magi-phase9a1-renders/`:

- `ready-laptop.png`
- `ready-external.png`
- `typing-external.png`
- `failed.png`
- `unavailable.png`
- `verifying.png`
- `missing-assets-portrait.png`
- `bright-wallpaper.png`
- `max-credential-count.png`
- `long-username.png`

The bright input is a synthetic white/yellow/cyan image with fine high-contrast
checker detail, created in memory; it is not a screenshot or a changed live wallpaper.
Both its blur and its legibility are inspected. No animation has been added.

New automated assertions cover null blur fallback, bounded 640×360 output, uniform
white preservation, suppression of 2px black/white detail, bright semantic-ink
selection, unchanged cached image identity over size/auth redraws, persistent
snapshot identity, and responsive scale values. Existing missing/corrupt image,
QML failure, credential boundaries, scale 1/1.5/2, scene recreation and security
regressions remain enabled without weakened expectations.

Debug-build observations on this machine: initial settings/avatar/wallpaper decode
plus blur about **121–123ms**; a synthetic 1920×1080 bright image downsample/blur about
**50–52ms**. These are one-time offline measurements, not a live acquisition deadline
proof. Cached redraws do not perform these operations. A 16-render size/state batch
completed in about 437ms locally. Production acquisition timing remains a separately
approved rollout gate; no live lock or suspend was performed here.

Scope since the Phase 9A foundation: native visual-data preprocessing and two new
blur source/header files; visual QML tokens/composition; preview cases and visual
tests; documentation. Total Phase 9 source inventory is now 27 paths, still entirely
unstaged. Security/input/PAM/session-lock/sleep/service architecture is unchanged.

Deferred: animation, user-facing blur/darkness controls, Power & Idle Settings,
fingerprint, weather, media, power actions, external-display top-bar option and
monitor-specific wallpaper selection. No package installation, live routing change,
staging, commit or push is part of Phase 9A.1.

Final Phase 9A.1 validation: production CTest **15/15**, development CTest **15/15**;
Rust **18/18**, Clippy all targets with warnings denied, cargo fmt and git diff
checks pass. The 39 sleep, 41 output, 19 handoff and 12 request scenarios remain
passing. Preview symbol/capability gate, all three scale environments, blur/bright
checks, native fallback and production install/security gates pass. Ten preview
files were verified. All 41 protected snapshot hashes match; Git index is empty.
The final debug preview run measured 124ms initial assets/blur and 53ms synthetic
bright blur, consistent with the earlier observations. No live security test,
production installation, configuration change, staging, commit or push occurred.

## Phase 9A.2 — final tuning, pending visual review

The accepted composition is unchanged: clock/date, vertical anchors, 112px avatar,
username size, 9px dots/10px gaps, external visual scale, semantic failure colour,
compact Caps warning, identity fallback and 16-dot cap. This section supersedes
9A.1's blur parameters and wallpaper-dependent foreground reversal only.

Final preprocessing uses a **960px maximum working extent** (960×540 at 16:9),
**radius 9** and **three separable box-blur pairs**. Bounded decode remains at most
1920×1080. At baseline laptop geometry this is approximately half the previous
9A.1 effective spatial blur spread. Inspection against
`/tmp/magi-phase9a1-renders/ready-laptop.png` shows the new image retains the car body,
roof and wheel silhouettes and broader scene shapes more distinctly, while fine
wallpaper detail remains heavily suppressed. It is still exclusively a processed
saved wallpaper asset, never desktop capture. No full-resolution live blur is added.

Foreground roles now remain the selected MAGI theme's normal text/subtext/accent/
danger/warning colours regardless of wallpaper brightness. For the current dark
MAGI palette this keeps the same light foreground in both real and bright synthetic
previews. No outlines, panel, local halo or foreground inversion is used.

Adaptive dimming is computed once with the cached wallpaper:

```text
B = mean of a fixed 16×16 whole-image sample grid
    using 0.2126 R + 0.7152 G + 0.0722 B on normalized RGB
    (transparent samples composited against semantic background)
tint = 0.42 + 0.20 × clamp((B - 0.30) / (0.75 - 0.30), 0, 1)
```

The range is **42–62%**. This deliberately simple perceptual brightness metric is
not physical linear-light luminance. Dark imagery stays at 42%; very bright imagery
reaches 62%. The final bright synthetic preview keeps its bright-derived broad
white/yellow/cyan composition with normal light UI above it. The slightly higher
62% ceiling was chosen through preview for readable separation without making the
wallpaper disappear. This remains a visual heuristic, not a universal contrast
certification for arbitrary images.

The existing per-locker snapshot/cache lifetime remains unchanged: tint and blur
are computed on snapshot creation; path/file/theme changes are picked up next
launch. Credential, time, Caps, PAM-state and normal output redraws do not recompute
either. New tests assert cached image identity **and tint** remain unchanged across
render/state/geometry changes, plus black/mid-grey/white and missing-image dimming.

At zero count, the credential row is invisible and the old dash is removed. Its
26px allocated area remains in place. The test covers both invisibility and constant
height across negative/zero/positive/bounded/overflow synthetic counts. The typing
hint is now **“Press Enter to unlock”**; it remains secondary and is explicitly
excluded from verifying, failure and unavailable states. No authentication policy
changes accompany this wording.

All ten requested previews were regenerated under `/tmp/magi-phase9a2-renders/`
with the same filenames as 9A.1. The real laptop and bright-wallpaper renders were
inspected directly. Debug-build one-time measurements were **197ms** for current
asset loading plus preprocessing and **120ms** for synthetic bright preprocessing.
The cached image is approximately 2 MiB at 16:9. This remains comfortably sub-second
offline; it is not a live lock/acquisition timing proof.

Source changes in this refinement are confined to `wallpaper_blur.hpp`,
`visual_data.cpp`, `LockTokens.qml`, `LockCredential.qml`, `LockStatus.qml`,
`visual_test.cpp` and this checkpoint. No layout redesign, animation, production
installation or live security test is included.

Validation note: the first full native runs each passed 14/15 and rejected the word
“unlock” in the newly requested display hint. The structural test now exempts only
the exact quoted `"Press Enter to unlock"` literal in `LockStatus.qml`; it still
rejects unlock identifiers/functions/handlers and every other unlock reference.
Behavioural tests assert the exact hint and its absence during verification/failure/
unavailable states. No public API exception was introduced. The refinement also
updates `tests/presentation_boundary.cmake` for this explicit copy allowance.

Protected-state audit: 40 of the 41 earlier captured hashes match. The operator-local
`settings.json` hash differs, with observed mtime 2026-10-18 17:46:49 BST during this
pass. No assistant operation wrote that file; its current theme remains Catppuccin
Mocha and display identity remains jkebwdn. The change is preserved without restore,
normalization or staging. Installed binaries, PAM and production Hypridle hashes
still match. Do not describe all 41 hashes as unchanged for Phase 9A.2.

Final complete reruns: development CTest **15/15 PASS** (37.40s), production CTest
**15/15 PASS** (34.52s). Rust **18/18**, Clippy all targets with `-D warnings`, cargo
fmt and git diff checks pass. Preview capability, native fallback, three scale
configurations, logical scene recreation, output lifetimes, sleep, missing assets,
bright treatment, credential bounds/empty-height and production feature/install
gates all pass. Ten PNGs are available for final operator review. Git index is
empty; no production files, PAM or Hypridle were altered and no live lock/suspend,
package installation, staging, commit or push was performed.


## Phase 9B — reviewed package, awaiting manual installation

The operator accepted Phase 9A.2 and authorized production rollout without further
offline aesthetic iteration. Baseline remains
`c7c942656536028b5d775900be69b05ceee00eab`, synchronized with origin/main (0/0).
Only the Arch release was bumped: `pkgver=0.1.0`, `pkgrel=2`.

Fresh build evidence is under `/tmp/magi-phase9b-dz0b1ckq/`. Two independently
generated 63-file source archives have identical SHA-256:
`cc7545a654473ab83287e2150bb56c8da01fb81643e9951a9f81a1fe436dc879`.
The clean offline production build and makepkg checks passed. Initial sandboxed
systemd unit verification was blocked; repeating with host access passed without
changing source or bypassing checks. The Rust worker has no debugging symbols;
makepkg's optional debug-index notice did not prevent successful packaging.

Reviewed installation artifact:
`/tmp/magi-phase9b-dz0b1ckq/package/magi-lock-0.1.0-2-x86_64.pkg.tar.zst`

SHA-256:
`e10789763c5e980f4b0c7aabcad4254b122d804eeb83e321db18cdd28be058f4`

The runtime package still owns exactly five regular files (root:root):

| Path | Mode | Content compared with installed 0.1.0-1 |
| --- | --- | --- |
| `/usr/lib/magi/magi-lock` | 0755 | Updated; QML compiled into binary |
| `/usr/lib/magi/magi-lock-auth` | 0755 | Identical |
| `/usr/bin/magi-lock-request` | 0755 | Identical |
| `/usr/lib/systemd/user/magi-lock@.service` | 0644 | Identical |
| `/etc/pam.d/magi-lock` | 0644 | Identical |

Per-file hashes are saved in `package-manifest.json` in the evidence directory.
No preview executable, external QML/source/test assets, PNGs or installation hooks
are shipped. The separate generated debug package is not part of the installation
request. DESTDIR and extracted-package audits passed: exact paths/modes, PAM,
request validation, unit verification, ELF hardening and production feature gates.
The production build reports development-unlock=0 and failure-injection=0.

Final Phase 9A.2 production/development CTest results remain 15/15 each; rebuilding
both trees reports no work to do. Rust 18/18, Clippy and formatting results remain
valid because their sources were unchanged. Package release metadata is the only
production-source change in this rollout so far. No authentication/session-lock/
sleep policy changes were introduced; safe display state was separated from the
auth controller, while credentials and unlock authority remain native.

The fresh pre-rollout protected snapshot matches all 41 files, including the
operator's current settings.json, live Hypridle, installed binaries and PAM.
Installation, real-output visual acceptance and the separately approved
suspend/resume presentation check are **pending**. No live test, install, staging,
commit or push has occurred during this preparation. Manual package installation
is the next explicit operator gate.

### Phase 9B installation verification

The operator installed the reviewed 0.1.0-2 package manually. Independent checks
confirm `pacman -Q magi-lock` reports 0.1.0-2; host-side `pacman -Qkk` reports
13 entries (five files plus directories), **zero altered files**. All five regular
files match the reviewed package hashes/modes and are root:root, with pacman
ownership assigned to magi-lock. Sandbox-only UID/GID warnings were an identity
mapping artefact; host verification resolved them without changing files.

Only `/usr/lib/magi/magi-lock` changed against the 41-file pre-install snapshot;
all other protected files, including settings.json, PAM and Hypridle, match.
The installed unit verifies successfully, with no loaded MAGI lock instance.
Hypridle PID 677552 remains running with its sleep delay inhibitor; no restart
was performed. Hyprlock remains absent. Installed build-info confirms development
unlock and failure injection disabled. No preview tool is package-owned.

Pre-test compositor inspection reports unlocked and only eDP-1 active at
3840×2160, scale 2. HDMI-A-1 is currently absent. Dual-output visual acceptance
therefore remains pending external-display connection and fresh operator approval.
No live lock or suspend has been initiated during these post-install checks.

### Phase 9B first production dual-output lock — software result

After fresh saved-work/recovery approval, exactly one `loginctl lock-session` was
issued at 2026-10-18 18:04:12 BST. Both physical outputs were active: eDP-1
3840×2160/scale 2 (1920×1080 logical), HDMI-A-1 3840×2160/scale 1.5
(2560×1440 logical). Native owner PID 723122 created registry 72/lifetime 1 and
registry 87/lifetime 2 surfaces, configured and committed both with native fallback
false. Compositor `locked` was recorded at 18:04:13.010528. No QML render error was
reported. The journal does not separately instrument wallpaper-cache success;
wallpaper appearance requires operator visual confirmation rather than inference
from native-fallback=false alone.

One generation-1 attempt spawned worker 723287 at 18:04:26.849948; it was reaped
with authentication success. Exactly one AUTHENTICATED UNLOCK occurred at
18:04:27.037907, authorized by current PAM Success. The compositor processed unlock
and the service exited with Result=success/ExecMainStatus=0. Postflight is unlocked,
with no locker/worker remaining; Hypridle PID 677552 retains its delay inhibitor.
Protected hashes match except the expected installed locker update. Evidence:
`/tmp/magi-phase9b-dz0b1ckq/live-lock/`. Operator visual acceptance and the separately
approved suspend/resume presentation check remain pending. No suspend was issued.

### Phase 9B paused after failed resume input

The production suspend/resume acceptance failed: the lock remained secure and
visible, but the operator could not enter a password. HDMI was unplugged only
after input was already broken. No visual rollback or acceptance claim follows.
See the [resume-input investigation](lock-screen-phase9-resume-input-investigation.md)
for journal ordering, the provisional modifier-readiness hypothesis, diagnostic-only
changes, validation limitations and the required review before any further live test.
Installed package remains 0.1.0-2.

### Resume compatibility fix pending validation/package 0.1.0-3

The instrumented run authenticated successfully but proved the first key can
precede initial modifiers and be dropped. A bounded native early-event fix is
implemented; host validation and package audit remain pending. Accepted visual
geometry, wallpaper processing, scale and credential dots remain frozen. Only
unknown Caps state and an exceptional modifier-recovery instruction are exposed
through the existing status presentation. See the [compatibility implementation
and validation gate](lock-screen-phase9-resume-input-investigation.md#compatibility-fix-implementation--awaiting-host-validation).
Installed production remains 0.1.0-2; Phase 9B finalization is still paused.

## Final Phase 9 production acceptance — 2026-10-19

This section supersedes earlier pending-rollout entries, which remain historical.
Installed production is **magi-lock 0.1.0-3**. Host offline validation is complete:
all 17 native tests in each configuration have passing results across the full
run and the corrected sleep-test recheck; Rust 18/18, Clippy, formatting, unit
verification, security gates and package check() passed.

The operator accepted one normal dual-output lock and one suspend/resume on
0.1.0-3. Both runs produced exactly one authentication attempt and authenticated
unlock. No first-character loss was observed. Both 4K displays returned cleanly
(eDP-1 scale 2, HDMI-A-1 scale 1.5); automatic external-output recreation during
resume remained secure and rendered without native fallback. Detailed evidence
and limitations are in the resume-input investigation checkpoint.

Accepted appearance remains: current saved wallpaper only, cached CPU processing
at 960px extent, radius 9, three blur passes, adaptive 42–62% dimming, 112px
baseline avatar, bounded 16-dot credential presentation and accepted logical
responsive scaling. No desktop capture. Prior measured asset+blur preprocessing
was about 181–195 ms; no new performance claim is inferred from journal spacing.
Native code retains credentials, keyboard handling and unlock authority; QML
receives safe presentation state only and the Rust worker remains auth-only.
The compatibility fix defers one early press/release until authoritative modifiers,
with bounded storage/time and strict focus/lifetime invalidation.

Package artifact:
`/tmp/magi-lock-0.1.0-3-8ers_vad/host-build-gl9OEgBl/magi-lock-0.1.0-3-x86_64.pkg.tar.zst`

SHA-256: `7fcc34e9e711c23c43bbcb377bf3a769c91de578020ba794a2320f2d0a185812`.
Five runtime files, unchanged PAM policy/service/request helper; no diagnostic
build, preview, harness or fixtures installed. Post-suspend host health verification passed; repository finalization is authorized.

Fingerprint, weather, media, power actions, persistent-scene animation and
configurable blur/dim remain deferred. Power & Idle Settings and the external
normal-shell top-bar option are separate later work. No further visual iteration
is needed for this milestone. /tmp evidence must remain until dedicated cleanup.

### Final exact Phase 9 allowlist (37 paths)

No settings.json, operator-local integration/runtime state or generated artifacts
belong in this set. `Proof.qml` is a deletion; the remaining new QML is embedded
in the production binary.

- `linux/magi/docs/README.md`
- `linux/magi/docs/architecture.md`
- `linux/magi/docs/decisions.md`
- `linux/magi/docs/design/lock-screen-phase9-resume-input-investigation.md`
- `linux/magi/docs/design/lock-screen-phase9-visual-design.md`
- `linux/magi/native/lock/CMakeLists.txt`
- `linux/magi/native/lock/README.md`
- `linux/magi/native/lock/packaging/PKGBUILD.in`
- `linux/magi/native/lock/qml/LockBackground.qml`
- `linux/magi/native/lock/qml/LockClock.qml`
- `linux/magi/native/lock/qml/LockCredential.qml`
- `linux/magi/native/lock/qml/LockProfile.qml`
- `linux/magi/native/lock/qml/LockScreen.qml`
- `linux/magi/native/lock/qml/LockStatus.qml`
- `linux/magi/native/lock/qml/LockTokens.qml`
- `linux/magi/native/lock/qml/Proof.qml`
- `linux/magi/native/lock/src/auth_controller.cpp`
- `linux/magi/native/lock/src/auth_controller.hpp`
- `linux/magi/native/lock/src/auth_presentation.hpp`
- `linux/magi/native/lock/src/native_input.cpp`
- `linux/magi/native/lock/src/native_input.hpp`
- `linux/magi/native/lock/src/presentation.cpp`
- `linux/magi/native/lock/src/presentation.hpp`
- `linux/magi/native/lock/src/visual_data.cpp`
- `linux/magi/native/lock/src/visual_data.hpp`
- `linux/magi/native/lock/src/visual_preview.cpp`
- `linux/magi/native/lock/src/wallpaper_blur.cpp`
- `linux/magi/native/lock/src/wallpaper_blur.hpp`
- `linux/magi/native/lock/src/wayland_owner.cpp`
- `linux/magi/native/lock/src/wayland_owner.hpp`
- `linux/magi/native/lock/tests/input_owner_test.cpp`
- `linux/magi/native/lock/tests/presentation_boundary.cmake`
- `linux/magi/native/lock/tests/presentation_test.cpp`
- `linux/magi/native/lock/tests/preview_boundary.cmake`
- `linux/magi/native/lock/tests/resume_input_test.cpp`
- `linux/magi/native/lock/tests/sleep_test.cpp`
- `linux/magi/native/lock/tests/visual_test.cpp`

### Final host health and repository gate

At 19:58 BST, `post-install-phuzivj0` confirmed 0.1.0-3 with zero altered
package entries, both lock units inactive/successful, no locker processes, both
outputs healthy, unlocked active Wayland session, and original Hypridle PID 32456
still holding its delay inhibitor. Hyprlock remains absent. Fresh host fetch
reported HEAD/origin/main divergence 0 0 at baseline c7c9426. The approved
37-path allowlist is ready for precise staging and normal commit/push; protected
settings/integrations/runtime paths are excluded. All earlier pending health
entries are historical. No more live tests are required.
