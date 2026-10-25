# Phase 13B — Rich lock modules and effects

Native acceptance completed, 2026-10-25. The operator explicitly accepted final
Phase 13B after the backdrop correction and a subsequent normal cursor appearance.
The production package is installed and byte-verified. Greeter is out of scope.

## Baseline and protected state

Verified baseline: `9843edd9e99759d824c5d20dd10af5a8f176ba22`,
`magi: update default icon mappings`, `HEAD...origin/main = 0 0`.
The supplied `9843edde…` spelling was a typo; the verified accepted commit was
used to create `/home/jkebwdn/magi-phase13b` on branch `phase13b`.
Main checkout was read-only during isolated development; the approved exact
allowlist was subsequently integrated for controlled native acceptance. A private `/tmp/magi-phase13b-audit`
snapshot covers all 17 dirty/untracked paths, including settings, the custom
layout, icon artwork and the Yazi symlink. No operator settings fixture is shipped.

## Presentation and security boundary

The existing native owner, credential buffer, PAM worker/protocol, unlock authority,
input handling, readiness and lock/sleep request contracts are unchanged.
Changes to native C++ are limited to `VisualData`, its image provider in
`presentation.cpp`, and tests/build resource declarations. QML receives display
values and decoded images, never service objects or control capabilities.
Production QML has no pointer handlers, keyboard handlers, process execution,
network request or authentication methods. Existing structural security tests
remain intact.

Native scenes are one-shot renders. `VisualData::current()` remains an immutable
snapshot for the locker process. Weather/media therefore reflect prepared state
at acquisition, not a live player subscription. There is no new owner refresh
mechanism or timer. Existing multi-output replication remains unchanged.

## Registry, geometry and layering

`LockLayout.js` extends the existing Time / Identity / Authentication registry with
Weather and Media. Both optional groups use the same anchors, normalized offsets,
size, alignment, visibility, editor selection, snapping and keyboard movement.
No second positioning engine exists. Legacy three-group records normalize by
adding dormant module geometry without moving any existing group.

All five presets retain their original composition. Dormant Weather geometry is
upper-right; Media is lower-left. Selecting a preset initializes the same data
schema, with both optional modules off. Reset lock screen restores Centered,
modules off, Dots, Plain avatar and depth off; Profile and media preferences stay
untouched.

Decorative z slots are -2 through 1. Authentication retains z=2, cannot hide or
shrink below size 1, and remains constrained on screen. Prepared depth occupies
z=1.5. Authentication additionally gets an opaque semantic background when media
or depth is present, protecting contrast under overlap. Ordinary decorative
layers can exchange their z slots; Authentication cannot join that exchange.

## Weather

Weather reuses `Weather.qml` / `weather.py` and the existing explicit-location
Profile configuration. Existing background cadence is 30 minutes. The native
reader only consumes the existing cached observation; it never starts the helper,
performs geolocation or makes a network request.

An observation must match the configured location hash, have a valid temperature
and supported condition, and be at most three hours old. Bad/missing/stale data
is hidden. Styles are Compact (single line), Standard and Minimal. Weather is
opt-in; city-label disclosure is separately off by default. Only the cached city
name is displayable, never coordinates, queries or diagnostics. Preview uses
12°, Partly cloudy, Sample city.

**Capability gap for review:** the canonical icon registry has no weather-condition
roles and the existing Weather service is text-only. This candidate keeps weather
text-only rather than introducing emoji, a separate pack or invented fallback.
Weather-condition semantic icon registration/artwork needs a separate explicit
choice; it is not falsely reported as implemented.

## Media and prepared assets

Media is opt-in and read-only. `LockAuxiliary.qml` observes the existing `Media`
selection and artwork cache; it does not discover players or expose transport
controls. A 300 ms coalesced publisher writes display-only metadata atomically to
`$XDG_STATE_HOME/magi/lock-auxiliary/media.json`. There is no second MPRIS service.
Disabling the module clears the export and the native reader independently checks
visibility before using it. Empty, invalid or older-than-three-hour data is hidden.

Titles/artists are bounded plain text. Artwork must originate in the existing
local MAGI artwork cache. A bounded, time-limited ImageMagick conversion prepares
a maximum 256×256 PNG outside the lock process. Thumbnails are content-addressed,
private and capped at 16 files; no duplicate download occurs. The native reader
accepts only bounded PNGs in that prepared directory. Broken artwork leaves the
text intact and uses the prepared semantic media icon when available.

That fallback is resolved by the existing `IconRegistry.resolve("media-play")`.
The publisher validates the resolved SVG with the existing asset validator and
rasterizes it outside locking using installed `rsvg-convert`; glyph descriptors
also have a bounded preparation path. The native image provider tints its alpha
with the current semantic text colour. No icon-resolver architecture is changed.
Missing preparation tools/assets degrade quietly. ImageMagick and librsvg are
existing host tools, not newly installed dependencies.

Media styles are Compact, Artwork and Minimal, with an artwork switch. Editor
metadata and artwork are deterministic synthetic fixtures, never listening history.

## Credential and avatar styles

Credential choices: Dots, Line, Segments, Ring, Minimal. Existing Dots retains its
accepted cap of 16 and overflow ellipsis. The existing native count property is
unchanged; this phase does not create additional length exposure. Every new style
uses only empty/nonempty state. Native pixel comparisons prove identical output
for counts 1 and 100. Error, authenticating and Caps Lock remain the unchanged
status presenter inside the protected Authentication group.

Avatar choices: Plain, Ring, Glow and Frame. All use semantic colours. Glow is a
bounded translucent border treatment, not a blur shader or global compositor
change. Identity source and avatar preparation remain unchanged. Visual cards
reuse the production presenters; precision/layout controls remain contextual.

## Depth: prepared capability, import deferred

Depth defaults off. The Settings inspector offers an inert synthetic preview and
an unavailable production toggle. **Mask import/selection UI is deliberately
not implemented in this pass**, as permitted by the phase scope. It must be
reviewed before claiming a complete end-user depth workflow.

The native prepared-asset contract is:

- `$XDG_DATA_HOME/magi/lock-depth/subject.png`: decoded PNG with alpha, maximum
  960×960, maximum 4 MiB, matching the current wallpaper aspect ratio.
- `current.json` beside it: exact `wallpaper` path, source file `size` and
  `modified` timestamp (seconds). A mismatched or unavailable source disables it.
- Desired `lockScreen.effects.depth` opt-in, default false.

This is a prepared RGBA subject cutout, not a grayscale mask needing compositing
or segmentation during lock. No ML, resize pipeline, synchronous segmentation or
network work occurs at acquisition. Only bounded local decode/compositing occurs.
Existing 960-pixel wallpaper blur/dim preprocessing is unchanged. Subject depth
can cover Time/Identity but never Authentication. Synthetic preview uses a fixed
vector silhouette through the same production image layer; no real credentials
or private artwork enter it.

## Schema 21 and migration

Schema advances once, 20→21. Migration adds only `lockScreen.effects` defaults
and schemaVersion. Existing custom geometry, preset label, space, other settings
and preferences survive byte-for-value in the parsed document. Optional geometry
is supplied during normalization and saved through the existing layout writer
only after editing. The copied operator Editorial-derived Custom layout passes
exact semantic preservation and idempotence tests. Effects and optional geometry
are validated; malformed layout falls back to Centered, malformed styles use
safe defaults. Settings is desired state, never auxiliary runtime metadata.

## Evidence and limitations

[Gallery](phase13b-previews/index.html): module compositions, artwork, all credential
and avatar styles, depth, error, Caps Lock, compact, ultrawide and all six requested
themes, including Rosé Pine Dawn. These are synthetic software captures.

Passed:

- Phase 13B model, copied-operator migration, cache/privacy, prepared icon/artwork,
  production/editor boundary and unchanged security-source assertions;
- Phase 13A model and full presentation interaction suite;
- Settings schema/persistence, presentation and Appearance;
- Phase 12F; Phase 12G model, global blur, lifecycle and presentation;
- Phase 12H coordinator and presentation; runtime visuals; Theme Orchestrator;
- native auxiliary snapshot/decoder and real software presenter tests, including
  wrong-aspect/broken depth, unavailable data and credential count invariance;
- native visual scales, presentation boundary, binary gate and other passing
  existing native tests; `git diff --check`.

Native CTest accounting in this build: **14 passed, 5 failed, 1 skipped**.
An independently built accepted baseline produces the same five failures:
`auth_production`, `auth_development`, `sleep_synthetic`, `output_synthetic`,
`presentation_offscreen`. Baseline has 13 passing tests plus the same skip; the
candidate adds the passing auxiliary test. No failing assertion was weakened.
`fingerprint_transport` remains environment-skipped.

Warm software 1920×1080 sampling measured 33 ms for five plain frames and 52 ms
for five enriched frames (about 6.6 vs 10.4 ms/frame). This is a small synthetic
sample, not a native latency or hardware guarantee. New prepared textures are
bounded (256×256 media, 96×96 icon, 960×960 depth), with no per-frame processing
pipeline or new polling.

Offline native and production package compilation completed. Packaging stops in
its existing install audit at `systemd-analyze --user verify`: SO_PASSRIGHTS /
SO_PASSCRED socket operations are denied by this environment. The initial sandbox audit was not
bypassed. The operator subsequently completed the normal checked host package
build/install and real-lock acceptance, as recorded below. Build logs/artifacts remain under `/tmp/magi-phase13b-*`, outside Git.

## Original review decisions and native gate plan (completed below)

Review snapshot-at-lock media semantics, text-only weather, the subtle border-based
Glow, and prepared-only depth before live integration. Weather icon roles/artwork
and a user-facing depth import workflow remain explicit capability gaps.

After architecture approval: snapshot/save operator state, integrate the reviewed
allowlist and neutrally migrate to 21; build and pass the package audit on the
host before installation. Confirm original custom geometry first. Review optional
modules and privacy opt-ins, every style, keyboard movement, overlap and Dawn.
Only then test normal real lock/unlock, wrong-password/Caps, unavailable services,
and a prepared depth cutout; verify auth contrast and prompt acquisition. Never
use a debug unlock path. External-monitor acceptance remains deferred until
hardware is attached. No Greeter work is included.

## Exact Phase 13B inventory

65 paths: 37 added, 28 modified, 0 deleted.

```text
M linux/magi/.config/quickshell/magi/components/settings/LockLayoutCanvas.qml
A linux/magi/.config/quickshell/magi/components/settings/LockStylePreview.qml
A linux/magi/.config/quickshell/magi/components/settings/lock-depth-fixture.svg
M linux/magi/.config/quickshell/magi/components/settings/pages/LockScreenPage.qml
A linux/magi/.config/quickshell/magi/services/LockAuxiliary.qml
A linux/magi/.config/quickshell/magi/services/lock_auxiliary.py
M linux/magi/.config/quickshell/magi/services/qmldir
M linux/magi/.config/quickshell/magi/settings/SettingsMigrations.js
M linux/magi/.config/quickshell/magi/settings/SettingsSchema.js
M linux/magi/.config/quickshell/magi/shell.qml
M linux/magi/docs/README.md
M linux/magi/docs/architecture.md
M linux/magi/docs/decisions.md
A linux/magi/docs/design/phase13b-lock-modules-effects.md
A linux/magi/docs/design/phase13b-previews/avatar-frame.png
A linux/magi/docs/design/phase13b-previews/avatar-glow.png
A linux/magi/docs/design/phase13b-previews/avatar-plain.png
A linux/magi/docs/design/phase13b-previews/avatar-ring.png
A linux/magi/docs/design/phase13b-previews/credential-dots.png
A linux/magi/docs/design/phase13b-previews/credential-line.png
A linux/magi/docs/design/phase13b-previews/credential-minimal.png
A linux/magi/docs/design/phase13b-previews/credential-ring.png
A linux/magi/docs/design/phase13b-previews/credential-segments.png
A linux/magi/docs/design/phase13b-previews/depth-synthetic.png
A linux/magi/docs/design/phase13b-previews/index.html
A linux/magi/docs/design/phase13b-previews/media-artwork.png
A linux/magi/docs/design/phase13b-previews/modules-caps.png
A linux/magi/docs/design/phase13b-previews/modules-catppuccin-mocha.png
A linux/magi/docs/design/phase13b-previews/modules-centered.png
A linux/magi/docs/design/phase13b-previews/modules-compact.png
A linux/magi/docs/design/phase13b-previews/modules-editorial.png
A linux/magi/docs/design/phase13b-previews/modules-error.png
A linux/magi/docs/design/phase13b-previews/modules-everforest-dark-hard.png
A linux/magi/docs/design/phase13b-previews/modules-nord.png
A linux/magi/docs/design/phase13b-previews/modules-rose-pine-dawn.png
A linux/magi/docs/design/phase13b-previews/modules-rose-pine.png
A linux/magi/docs/design/phase13b-previews/modules-split.png
A linux/magi/docs/design/phase13b-previews/modules-tokyo-night-moon.png
A linux/magi/docs/design/phase13b-previews/modules-ultrawide.png
M linux/magi/native/lock/CMakeLists.txt
A linux/magi/native/lock/qml/LockAuxiliary.qml
M linux/magi/native/lock/qml/LockCredential.qml
M linux/magi/native/lock/qml/LockLayout.js
M linux/magi/native/lock/qml/LockProfile.qml
M linux/magi/native/lock/qml/LockScreen.qml
M linux/magi/native/lock/qml/qmldir
M linux/magi/native/lock/src/presentation.cpp
M linux/magi/native/lock/src/visual_data.cpp
M linux/magi/native/lock/src/visual_data.hpp
A linux/magi/native/lock/tests/auxiliary_test.cpp
M linux/magi/tests/phase12f/presentation.qml
M linux/magi/tests/phase12g/presentation.qml
M linux/magi/tests/phase12g/schema.cjs
M linux/magi/tests/phase12h/presentation.qml
M linux/magi/tests/phase13a/model.cjs
M linux/magi/tests/phase13a/presentation.qml
A linux/magi/tests/phase13b/custom-layout.json
A linux/magi/tests/phase13b/model.cjs
A linux/magi/tests/phase13b/presentation.py
A linux/magi/tests/phase13b/presentation.qml
A linux/magi/tests/phase13b/run.py
M linux/magi/tests/settings/expected18.cjs
M linux/magi/tests/settings/run.py
M linux/magi/tests/settings/schema.cjs
M linux/magi/tests/settings/store.qml
```

## Controlled native gate — in progress

The operator approved snapshot-at-acquisition Media, text-only cached Weather and
prepared-only Depth as Phase 13B limits. Host build/install was run using the
normal checked package recipe. All five installed artifacts match final package
bytes, including the owner binary's embedded QML resources. Build-info reports
`development-unlock=0; failure-injection=0; native-authentication=1`.

Pre-integration snapshot: `/tmp/magi-13b-native-5v4g0c9b`, 21 protected/local
entries and 645 runtime files. Both indexes were empty. The operator confirmed
All changes saved. The exact 65-path allowlist was integrated; the same shell
identity reloaded. Settings remained schema 20 on disk with unchanged values
until a normal UI save; the in-memory migration is schema 21.

The first reload exposed an undefined-to-bool binding for legacy layouts missing
Media geometry. The enabled expression now explicitly yields false, with a
regression assertion. Reload after correction was clean. Media export is empty.
Preview-only Weather, Media and combined states were added so module review does
not opt in to production disclosure. Synthetic interaction tests prove preview
visibility and keyboard movement do not enable the persisted modules.

Neutral UI migration, designer acceptance and real locks remain pending. No lock
was requested by the agent. No lifecycle/security source changed; a new suspend
cycle is not required on this diff. Final operator preferences are not yet known.

### Neutral schema-21 save verified

The operator completed the normal Identity → Plain save. Disk schema is now 21.
Time, Identity and Authentication retain every prior geometry value; layoutVersion,
Custom preset label and screen space are identical. Every unrelated preference is
unchanged. Weather/Media were added with dormant geometry and visibility false;
Dots, Plain, Standard weather, Compact media, city disclosure off and depth off
are neutral defaults. Media export remains `{}`. Both indexes remain empty.
Designer acceptance and all Phase 13B real-lock checks are still pending.

### Native designer accepted

Operator: “designer passes, no issue.” Saved schema 21 retains the exact original
three-group Custom geometry and all unrelated preferences, including restored
Catppuccin Frappé. Weather and Media remain off; Dots, Plain and depth off are
selected. Weather's preferred style is now Compact following deliberate designer
review. Installed package bytes and production flags were reverified unchanged.
The neutral real-lock test is ready but has not yet been reported as passed.

### Neutral real lock accepted

Operator: “everything passed,” in response to the normal `magi-lock-request lock`
gate covering unchanged custom composition, first character, Caps Lock, incorrect
password feedback, successful unlock, no editor chrome and no noticeable delay.
Weather/Media/depth were off, with Dots and Plain. This is native evidence for
neutral migration and the normal request path, not yet auxiliary-module acceptance.

Weather is configured and a recent cached observation is available without forcing
a refresh. No prepared production depth asset exists; accepted synthetic/native
renderer evidence remains the depth gate. Auxiliary/style tests remain pending.

### Native media backdrop correction

The operator confirmed normal password entry/unlock with an active media player,
but reported a shallow rectangle wider than the authentication text. The renderer
previously enabled its contrast backdrop for any available media, regardless of
position. It now checks scaled host intersection (including backdrop padding);
separated media no longer adds a panel, while overlapping media and prepared depth
retain authentication contrast protection. Synthetic QML tests cover separation,
intersection, absent media and depth. Model tests cover scaled geometry and edges.
The five targeted native visual/boundary/auxiliary tests pass. The updated embedded
QML requires host package installation and a focused native visual check.

The reported persistent cursor shape remains unconfirmed. Native pointer/input
handling is unchanged; no cursor workaround or input handler was added to QML.
This observation is not recorded as resolved. Nothing is staged.

The operator installed the backdrop correction package. All five installed
artifacts match the final package bytes; build-info confirms development unlock
and failure injection disabled, native authentication enabled. Focused native
backdrop verification remains pending. The cursor was clarified as a pointing
hand (link cursor). Production lock QML has no cursor handlers, and the unchanged
native seat listener handles keyboard capability only, with no pointer cursor
assignment. A retained pre-lock cursor is a hypothesis, not a verified cause;
no security/input code was changed to address it.

Focused native backdrop retest: the operator reports the wide rectangle is gone
and normal unlock succeeds. Starting with a normal arrow over empty wallpaper
still produces a pointing-hand cursor on the lock. Thus a simple retained
pre-lock cursor explanation is insufficient. The cursor issue remains unresolved;
it is not counted as fixed or as an authentication failure. No native owner/input
changes have been made. Any fix requiring that protected boundary needs a separate
explicit architecture decision.

### Cursor investigation history (2026-10-25; proposal not implemented)

During investigation Phase 13B was held at the operator's request. The wide
backdrop fix was accepted; the pointing-hand cursor still occurred at that point.

Verified local evidence:
- Installed Hyprland is 0.56.2-4; session build identity is
  `efb50993780079460b0cbed1363e2166a2de1d9f`.
- `main.cpp` forces Qt offscreen rendering. Presentation QML cannot assign the
  compositor cursor; no pointer/control capability is provided to it.
- `WaylandOwner::seatListener` subscribes only to keyboard capability. There is
  no `wl_pointer` listener or cursor request. Owner .cpp/.hpp, native_input.cpp,
  credential.hpp and auth_controller.cpp are byte-identical to production baseline.
- Installed `/usr/share/wayland/wayland.xml`, `wl_pointer.enter` and `set_cursor`,
  specify that the pointer image is undefined on surface entry until the client
  sets it. A null cursor surface hides it, using the current enter serial.

Upstream source inspected on 2026-10-25 at the exact session revision:
[InputManager.cpp](https://raw.githubusercontent.com/hyprwm/Hyprland/efb50993780079460b0cbed1363e2166a2de1d9f/src/managers/input/InputManager.cpp),
`mouseMoveUnified`, lines 335–362, transfers pointer focus to an above-lock layer
or lock surface and returns without selecting a cursor.
[SeatManager.cpp](https://raw.githubusercontent.com/hyprwm/Hyprland/efb50993780079460b0cbed1363e2166a2de1d9f/src/managers/SeatManager.cpp),
`setPointerFocus`, sends enter events; `onSetCursor` checks the requesting client
against pointer focus. These findings establish a missing client cursor policy;
they do not identify the exact earlier source of the observed hand. Compositor
logs contain no relevant cursor events, and sandbox IPC prevents live layer
inspection. No MAGI above-lock QML configuration was found.

Proposed bounded exception, NOT implemented: acquire a native pointer when the
seat offers pointer capability; on enter into an owned lock surface, request a
null cursor using that event's serial. Ignore motion, button and axis events;
never forward them into QML or authentication. Release pointer resources on
capability removal, seat removal and teardown. No cursor theme/texture dependency,
keyboard changes, credential changes, PAM changes, lock readiness changes or
unlock-authority changes. No global compositor cursor setting or wrapper workaround.

Required verification if approved: fake pointer-event tests for owned versus
foreign surfaces, enter serial, ignored button/motion events and resource cleanup;
existing owner/security/request regressions; normal checked production package
installation; native cursor disappearance, normal unlock and desktop cursor
restoration. This is a concrete cursor-only native-owner proposal, requiring an
explicit exception to the Phase 13B hard boundary before code edits.

## Final operator acceptance — 2026-10-25

The operator reported a subsequent normal lock with the pointer appearing correctly,
explicitly requested no cursor fix, then stated “yes final phase 13b natice acceptance
accepted.” The hold is lifted. The cursor proposal above was not implemented; its
transient cause remains unknown and is not represented as a code fix.

- Designer accepted without issues, including optional modules and visual pickers.
- Schema 21 migration preserved the original three-group Editorial-derived custom
  layout exactly. Normal lock, first-character input, wrong-password/Caps feedback
  and successful unlock were accepted. No editor chrome or visible delay reported.
- Weather and Media were deliberately enabled for native review. Existing cached
  weather and active-player metadata/artwork preparation were used; no forced
  weather refresh or media controls were introduced. Final overall acceptance
  covers these modules; unavailable/opt-out paths additionally have offline evidence.
- The media-induced wide authentication panel was corrected and explicitly verified
  gone. Real unlock passed after that correction. Overlap/depth protection remains.
- All credential and avatar styles passed designer/synthetic review. Saved final
  preferences remain Dots and Plain; no separate non-default real-lock style result
  is claimed. New indicators' one-versus-100-character invariance is automated.
- Final local preference: original Custom geometry, Weather Compact (city hidden),
  Media Artwork at scale 0.75, artwork enabled, depth off. Settings remains local.
- Depth uses synthetic/native-render evidence: no prepared production cutout existed.
  Import UI and semantic weather condition icons remain deferred; Weather is text-only.
- Media is a snapshot at acquisition, not live playback. Auxiliary failures cannot
  affect authentication. Authentication remains foremost and contrast protected.
- Physical external-display acceptance remains deferred. Responsive synthetic
  outputs and six themes including Dawn pass. No new suspend cycle was needed:
  lifecycle, owner, keyboard, credentials, PAM and request contracts are unchanged.
- The checked host package's five installed artifacts match final archive bytes;
  production flags disable development unlock/failure injection and enable native auth.

Final regressions passed: Phase 13B model/cache/privacy and presentation, Phase 13A
model/presentation, Settings schema/persistence/presentation/Appearance, Phase 12F,
Phase 12G model/global blur/lifecycle/presentation, Phase 12H model/presentation,
runtime visuals and Theme Orchestrator. Native CTest remains 14 passed, five
baseline-identical failures and one fingerprint-transport skip. Diff checks pass.
The exact allowlist is 65 paths (37 added, 28 modified, zero deleted).
No Greeter work or cursor-owner change is included.

Final protected-state comparison: original lock geometry remains exact. Current
local Settings also differs from the pre-integration snapshot in global blur
management (off), application blur (off) and application background opacity (1).
These current local preferences are preserved without rewriting Settings; neutral
schema migration was separately verified before native review. Other protected
repository files, icon artwork and the Yazi symlink match their snapshots.
