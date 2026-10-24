# Phase 13A — Lock Screen Designer

Status: native acceptance complete, 24 October 2026. The reviewed source and
production package are integrated; the operator accepted the designer and real
Centered/custom locks. No Phase 13B or Greeter work is included. Baseline `19156074aea95f93c31521f22cd67fcd119b9c8c`
(`magi: coordinate application theme activation`); local origin/main comparison was
`0 0`. Development worktree: `/home/jkebwdn/magi-phase13a`.

[Open the synthetic preview gallery](phase13a-previews/index.html).

## Security and current production decomposition

The native owner still owns ext-session-lock-v1, credential input/buffer, PAM worker
communication, current-generation success validation, unlock authority, readiness,
and the sleep-coordinated contract. No changes to those implementations or interfaces.
`VisualData::current()` remains a bounded, immutable presentation snapshot for a
lock invocation. The only changed native C++ source is `visual_data.cpp`, which
passes the JSON layout object through the existing display-only `visual` map.
The renderer's existing root-property allowlist is unchanged.

The audited composition has Clock + Date, Avatar + Username, credential dots,
fingerprint guidance, status/error and Caps Lock. It has no power controls or
personal greeting. Identity and date/time continue to come from the existing native
visual/profile and locale paths. The footer and development notice remain fixed.
Wallpaper decoding, preprocessing, adaptive tint and fallback painter are unchanged.

The element registry deliberately has three groups:

| Group | Existing components | Why grouped |
| --- | --- | --- |
| Time | Clock and Date | Keeps the date attached while allowing an independently placed, aligned time block |
| Identity | Avatar and Username | Keeps identity coherent; no duplicate Profile ownership |
| Authentication | Dots, fingerprint guidance, status/error, Caps Lock | Feedback must remain coherent, visible and usable through conditional states |

The footer/development notice is not editable. There are no invented modules.
Separate movement of clock/date or avatar/name is not part of this first candidate.

## One responsive layout model

`LockLayout.js` owns presets, normalization, anchor resolution, placement and snaps.
The same `LockElementHost` renders each group for every preset. No preset-specific
QML themes or component branches exist.

Each group has a nine-way anchor, normalized `offsetX`/`offsetY` fractions, size,
alignment, visibility and bounded z-order. Fractions refer to the logical canvas,
not physical pixels. Existing native visual scaling is retained. Anchor positioning
subtracts the group's actual extent, so right/bottom anchors keep it inside the
canvas. Custom layouts have a 16-logical-unit margin and reserve 48 units below
content for the existing footer. The offsets are rounded to four decimal places
when dragged; the inspector exposes percentages, never implementation decimals.

The schema also records a coordinate space:

* `composition`: the original centered, scaled frame (maximum 600 × 650 logical
  units). Time sits at its top; Identity starts at 36% of its height; Authentication
  follows the measured Identity height with the original gap. This retains the
  existing content-dependent baseline instead of approximating it with offsets.
* `screen`: the common anchored coordinate model for movable layouts. The first
  positional/size/visibility edit materializes all current positions before
  detaching from the original flow, avoiding a jump in untouched groups.

Centered, Editorial, Corner, Split and Minimal initialize this same structure.
A manual change is labelled Custom. Reset replaces only `lockScreen` with Centered.
Minimal hides Identity, not authentication. There is one responsive definition for
all outputs; no per-output state is added.

## Editing and usability

Lock Screen is a first-class Settings section, separate from Security. Visual preset
cards precede the canvas. At wide widths the inspector sits alongside it; narrower
widths stack and scroll using the established SettingsPage primitives.

Selection has a restrained outline. Pointer drag is local until release, including
handling a final coalesced pointer event. Escape cancels without persisting. Arrows
move one logical unit; Shift moves ten. Alt bypasses snapping. Guides include margins,
centres, thirds, and other visible group edges/centres, with an eight-unit threshold.
Wheel input over the canvas does not move elements or unexpectedly scroll its parent.
A selector exposes overlapping/hidden groups and makes recovery keyboard-accessible.
Fine tune is disclosed; it contains anchor and percentage offsets. Time exposes
alignment. Group size choices avoid raw font-size controls.

Time and Identity can be hidden and exchanged in z-order. Authentication always
remains visible at z=2, in front, with size 1–1.25; other groups allow 0.75–1.25.
Long status text wraps within its group rather than overflowing a narrow output.
Overlap is permitted. Authentication grouping keeps error and Caps Lock feedback
attached. There is no general layers panel, undo framework, new effect, image layer,
weather, media, or arbitrary decorative text. Reset is the recovery path.

## Schema 20 and failure behaviour

Migration 19 → 20 adds only:

```json
"lockScreen": {"layoutVersion": 1, "preset": "centered", "elements": {}}
```

This compact neutral form resolves to the unchanged original composition. The first
edit/preset selection stores the expanded model. Migration is idempotent, does not
rewrite unknown pre-existing fields, and preserves the copied operator schema-19
fixture exactly apart from schemaVersion and the new section. No live settings were
migrated. Phase 12G appearance/global blur and Phase 12H runtime status remain separate.

Settings validates the object, exact element IDs, version, anchor/alignment enums,
finite offsets, bounds, size, booleans, unique z-order and authentication floor.
The shared production normalizer independently sanitizes a fixed data shape and
falls back to Centered for invalid or missing configuration. Unknown layout data
never becomes QML source, a URL, an expression or an executable component.
The native reader retains its 1 MiB JSON cap. No additional last-known-good store
is needed: the known default is built in, and the pre-existing native solid fallback
still covers a presentation loading failure. Security ownership does not depend on
layout validation or QML success.

## Shared production and synthetic presentation

Native `qml/` remains the canonical source, embedded in the native package. Settings
imports the same directory through `components/lockPresentation`, a repository-relative
symlink. Stow must preserve that link; standalone shell distributions must include
its native presentation source target. The native archive itself contains regular
QML/JS files and has no symlink dependency. Its packaging check succeeded.

All editor handlers/selection/guides live in `LockLayoutCanvas.qml`, outside native
presentation. The native boundary test now scans both QML and JS. No input handler,
credential object, shell service or public unlock capability was introduced there.
The synthetic canvas uses a fixed sample identity/time and six fake dots only in
Typing state. Idle, Typing, Authenticating, Wrong password and Caps Lock are explicit
preview states. It never reads live credentials or acquires a session lock. The
fallback preview background is the deterministic semantic plain background; native
wallpaper effects remain unchanged.

Each native output continues receiving a scene at its surface-local logical size,
using the same immutable layout snapshot and existing native input presentation.
No focus, output ownership, scaling protocol, buffer lifecycle or readiness changes.
Layout changes affect a subsequent lock invocation, not an already acquired lock.

## Verification

Development environment: Qt 6.12.0, Quickshell 0.3.2 (Arch package). All rendering was
software/offscreen with isolated Settings, state and generated-output roots.

* Model/migration: five presets; nine anchors; snapping/bypass; four aspect ratios;
  unknown anchor/ID, NaN, huge offset, negative size, missing element, duplicate z;
  mandatory auth visibility/size; exact copied-operator migration and idempotence.
* UI: pointer release commits without intermediate Settings mutation; keyboard
  movement, Escape cancellation, reset, visibility geometry, all five synthetic
  states, full Settings navigation, actual compact-width capture and ultrawide.
* Six theme captures: Catppuccin Mocha, Everforest Dark Hard, Rosé Pine, Nord,
  Tokyo Night Moon, Rosé Pine Dawn. Dawn retains its light palette and readable
  editor controls/outlines; it is not forced dark.
* Native before/after render comparison: all eleven 1920×1080/portrait cases are
  pixel-identical. Two 2560×1440 cases differ in only two colour channels by one
  8-bit step, consistent with transform rounding, with unchanged placement.
* Native suite: **14 passed, 5 baseline-identical failures, 1 skipped**. Both the
  unchanged baseline and candidate fail auth_production/auth_development (success
  fixture assertion), sleep_synthetic, output_synthetic and presentation_offscreen
  (fixture completion). These are not counted as passing. fingerprint_transport
  skips in this environment. Visual scales 1/1.5/2, presentation/preview boundaries,
  production/development controllers, input ownership/resume ordering, handoff,
  request, binary gate and fingerprint synthetic/session tests pass.
* Settings persistence/schema, presentation and appearance; Phase 12F; runtime
  visuals; Phase 12H coordinator and presentation; Theme Orchestrator; Phase 12G
  model, global blur, lifecycle and presentation runners pass. Existing migration
  assertions were extended to schema 20, not removed.

Evidence and copied private operator fixture are outside Git in `/tmp/magi-13a-audit`.
No raw operator settings are included in the gallery or candidate.

## Sources audited

Inspected 2026-10-24 at accepted commit `19156074…`: native
`qml/LockScreen.qml`, `LockTokens.qml`, `LockClock.qml`, `LockProfile.qml`,
`LockCredential.qml`, `LockStatus.qml`, `LockFingerprint.qml`,
`src/visual_data.cpp`, `src/presentation.cpp`, and `src/wayland_owner.cpp`.
These establish the actual composition, immutable display data, existing native
property boundary and per-output rendering. Existing SettingsSchema/Store,
SettingsContent and SettingsPage establish migration, navigation and scrolling.
No third-party artwork/code was copied; existing repository components are reused.
Qt interaction behaviour was exercised on the installed Qt/Quickshell versions;
real compositor pointer/scale behaviour remains part of the native gate.

## Protected state and separate operator requests

All 14 protected entries match the preflight snapshot, including settings.json and
the Yazi flavour link. Main's tracked diff is byte-identical and its index is empty.
The operator separately requested a normal live MAGI reload for newly added icons:
the normal watched-source mechanism logged Configuration Loaded in the existing
instance; the temporary comment was removed and original source bytes restored.
No designer code was integrated. The four operator-added SVGs remain untouched.
Inspection found their manifest mappings were still glyphs (or absent for unlock),
so a reload alone could not select them. Icon registration is outside this candidate.

## Architecture decisions and native gate (now completed below)

Review the three-group choice, composition-to-screen transition, authentication
constraints, shared-source deployment link and preset gallery. These choices were accepted for controlled integration; native results are recorded below.

After explicit approval: integrate only the reviewed source, validate the synthetic
Settings experience on the normal display, then separately deploy the reviewed native
presentation build through the existing safe mechanism. Compare default lock appearance
first; test custom layouts on laptop/external outputs, real keyboard entry/error/Caps
feedback, and the existing suspend/resume lock path without changing its contract.
Restore the preferred layout and retain the baseline native binary for rollback.
Do not use the synthetic preview as proof of real authentication or lock coverage.

Future 13B artwork/depth/modules can use registry entries, the same anchors and bounded
z-order, below mandatory authentication. Per-output overrides and optional finer group
decomposition require their own review. None are implemented here; Greeter remains separate.

## Final first-pass inventory

54 paths: **29 added, 25 modified, 0 deleted**. Nothing staged.

| Category | Added | Modified | Total |
| --- | ---: | ---: | ---: |
| Settings UI/navigation and shared-source link | 3 | 3 | 6 |
| Schema/migration/store | 0 | 4 | 4 |
| Native presentation/model/resource list | 2 | 5 | 7 |
| New tests and existing regression updates | 4 | 9 | 13 |
| Design/architecture/reference documentation | 1 | 4 | 5 |
| Intentional synthetic PNGs and HTML gallery | 19 | 0 | 19 |

The native security implementation, settings.json, live generated output, operator
SVG additions and all protected t15g files are excluded. The exact path list was
recalculated with `git status --short --untracked-files=all`; tracked diff whitespace
validation passed. Baseline and origin/main still compare `0 0`; both indexes are empty.

## Controlled native integration — 2026-10-24 (in progress)

Operator approved architecture and confirmed Settings showed All changes saved.
Fresh snapshot: `/tmp/magi-13a-native-lf5s7k27`, 21 protected/local entries including
all seven current icon additions/edits. Both indexes were empty; baseline remained
`19156074…`, divergence `0 0`.

Integrated the reviewed source allowlist without installing a locker binary. The
first watched reload was rejected: shared-directory discovery reported LockBackground
is not a type. The existing shell remained alive. Fixed only component discovery
with an explicit shared `qml/qmldir`, included in native resources. The synthetic
presentation regression now preserves the actual repository-relative symlink and
directory structure instead of flattening it. Model/boundary and presentation tests
pass. The follow-up live reload logged Configuration Loaded at 19:57:59 in the same
shell instance, without QML errors.

Current candidate inventory: **55 paths, 30 added, 25 modified, 0 deleted**. The only
new path since architecture review is `native/lock/qml/qmldir`. Installed native
owner, worker, request wrapper, unit and PAM file hashes remain unchanged. All 21
protected/local entries still match. Disk Settings remain schema 19 until a normal
Settings save; neutral schema-20 persistence and operator designer review are next.
No real lock has been requested. Native/default/custom acceptance is pending.

Operator accepted the native Settings designer after the requested preset/state,
drag/snapping, keyboard/cancel, layering/visibility, responsive/compact and Dawn
review, then restored Centered and saved. Readback exactly equals the neutral
schema-20 snapshot, including the original Frappé theme and all unrelated state.

Offline production build completed with development-unlock=0 and failure-injection=0.
The packaging audit passed its artifact, mode, ELF-hardening, dependency and policy
checks up to `systemd-analyze --user verify`, which exits 1 here with SO_PASSRIGHTS /
SO_PASSCRED Operation not permitted. No tests were disabled. Host-side completion
of the package check is required before installation. The request wrapper, unit and
PAM file are byte-identical to installed versions; the worker is rebuilt from
unchanged source (its binary is not byte-identical). No authentication source or
protocol change is included. Installed artifacts remain unchanged at this checkpoint.

Operator completed host-side checked package build and installation. All five
installed artifacts exactly match the package files; production build-info confirms
development-unlock=0 and failure-injection=0. Request wrapper, systemd unit and PAM
file also remain byte-identical to pre-integration versions. Settings readback is
still exactly the neutral schema-20 snapshot (Centered, Frappé, all other preferences
unchanged). Real Centered lock acceptance is the next gate. Package ownership checks
inside the sandbox report UID/GID namespace mismatches, including standard system
directories; this is not treated as a verified host ownership change.

## Final native acceptance

The operator accepted the designer, reported the default real-lock checks “all
working”, and then reported the custom real-lock checks “all working, no external
displays were attached”. These are operator observations, not synthetic-test claims.

| Gate | Result |
| --- | --- |
| Schema 20 | Exact neutral migration; every pre-existing preference preserved |
| Designer | Canvas/inspector, five presets, five simulated states, compact scrolling and Dawn accepted |
| Interaction | Time/Identity drag, snapping, arrows/Shift, Escape, visibility recovery and z-order accepted |
| Time | Native default preserved; Editorial-derived custom placement matches preview |
| Identity | Manually repositioned in custom layout; native placement accepted |
| Authentication | Visible/foremost, usable dots/status/error/Caps, normal password unlock accepted |
| Real Centered lock | Normal acquisition; wallpaper/blur/dim/composition unchanged; first character, wrong password, Caps Lock and normal unlock passed |
| Real Custom lock | Editorial-derived Custom layout saved and rendered correctly; background unchanged; normal unlock passed |
| Editor separation | No handles, outlines, guides, inspector/debug artifacts or observed jitter on real locks |
| Outputs | Built-in display accepted; no external displays attached; physical multi-output acceptance deferred, synthetic aspect evidence retained |
| Request contract | Both real tests used the normal production request path; no test/debug unlock path |
| Suspend/resume | No new physical cycle: scene/output recreation and sleep coordination were not changed; existing synthetic lifecycle accounting retained |
| Fallback | Malformed-layout coverage remained offline; live settings were never deliberately corrupted |

Final operator preference is Frappé with an Editorial-derived Custom layout. Identity
has normalized vertical offset 0.27; Time and Authentication retain the Editorial
positions. Readback matches the neutral schema-20 snapshot in every section except
the intentionally edited lockScreen. That preference remains local/unstaged.

No credential contents were inspected. Native owner, input, credential buffer, PAM
protocol, unlock authority, request/sleep contract and readiness implementation are
unchanged. Physical multi-output and a new suspend cycle are not claimed as tested.

Final inventory: **55 paths — 30 added, 25 modified, 0 deleted**. This adds the
explicit native `qml/qmldir` to the 54-path first-pass inventory above. Native
presentation/resource category is now 3 added + 5 modified = 8; all other category
counts remain as listed. All icon files/mappings and settings.json are excluded.
The 20 protected non-Settings entries match the native preflight snapshot exactly;
Settings differs only by the accepted schema/layout. Yazi's flavour link is intact.
Phase 13B, Greeter, icon registration and physical external-output acceptance remain
separate work; none is started by this finalization.

Final post-native regression: all 14 runner entrypoints passed (Phase 13A model/UI;
Settings persistence/schema/presentation/appearance; Phase 12F; Phase 12G model/global
blur/lifecycle/presentation; Phase 12H coordinator/UI; runtime visuals; Theme
Orchestrator). The rebuilt native suite retained the same 14-pass / 5-baseline-failure /
1-skip outcome. The package's full host-side check succeeded before the operator
installed it. Preview captures were regenerated after the component-discovery fix.
`git diff --check` passed. Native acceptance authorizes precise finalization only;
Phase 13B and separate icon registration remain unstarted.
