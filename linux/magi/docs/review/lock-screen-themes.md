# Curated Lock Screen Themes

Implementation based on `4871ad7378f3c42e5be08c980bc02c9e1b25edbc`, 2026-10-30.
Package 0.1.0-11 is installed and accepted on the T15G internal display. Matching runtime/Settings files
were integrated into the live source after verifying the clean baseline and protected
state. Saved Settings stayed byte-identical through integration; the index is empty.
The operator reported the requested native review working, then accepted the
wallpaper/rounded-avatar preview refinement with “excellent pass”. The operator explicitly approved the two planned commits and normal push after
native acceptance. Synchronization and cleanup are verified during Git closeout.

## Product and ownership

Normal Lock Screen Settings opens with six lightweight visual cards: Split Corners,
Centered, Minimal, Editorial, Media and Compact. A single read-only production
presentation preview follows the selected card. The gallery uses responsive columns,
keyboard focus and the current semantic palette. Relevant appearance/module controls
follow the preview; blur and password mark style are shared choices and survive theme
switches. Enrollment, removal and device verification remain in Security.

`native/lock/qml/LockThemes.js` owns catalogue metadata, supported controls, module
policies, defaults and selection/migration. Themes use the existing layout elements
and bounded hosts. Curated flows in `LockLayout.js` use measured content sizes;
Split Corners retains the accepted anchored composition. Media optionally uses the
existing bounded artwork/title path, without playback controls or network activity.

The previous builder is preserved as `LockDesignerPage.qml`. Set
`MAGI_LOCK_DESIGNER=1` in an isolated development Quickshell process to use it through
the existing Lock Screen destination. Normal Settings has no designer button, drag
handles, coordinates, anchors or z-order controls. Internal edits become Custom;
the anchor, snapping, validation and placement machinery remains available.

Gallery cards are primitive diagrams derived from the shared theme model.
After the operator reported the gallery working, previews were enlarged to a true
widescreen aspect and avatar placeholders adopted native rounding (including Frame).
Cards and the single full preview read the existing Wallpaper service shared
assignment, matching native wallpaper selection. Images use a common URL and fixed
960×540 source size for Qt pixmap-cache reuse, plus semantic contrast shading.
Blur is a bounded preview effect when enabled; it approximates the native CPU blur.
No native package change is required for this Settings-only refinement. Cards do
not instantiate lock scenes, MPRIS observers, media pipelines or timers; wallpaper
Image items share the bounded Qt decode cache. Exactly one
full preview exists on the normal page. Runtime service ownership and polling are
unchanged; there are no new authentication or media service owners.

## Compatibility and schema

Schema stays **22**. The existing `lockScreen.preset` identifies the theme; optional
appearance fields `effects.curated` and `effects.date` select measured curated flows
and date visibility. Missing fields retain the accepted legacy rendering defaults.
No new top-level preference or replacement layout format is needed.

The accepted saved Custom layout is recognized by its corner anchors/alignment,
bounded offsets, adjacent time/profile, title media style and disabled weather.
Custom layouts with weather enabled remain legacy, preserving their placement. Recognition changes
only preset metadata to `split-corners`; coordinates, visibility, styles and extra
fields are preserved. Settings recognizes this on load without writing the file;
the normal next explicit save persists metadata. Opening the page never selects a
new layout. A theme click intentionally applies that theme's defaults, preserving
shared blur/mask choices. Reset selects the defined Centered curated default.

Other Custom, Corner and Split compositions remain **Custom (legacy)** and keep
rendering. They can be edited in the internal designer. Unknown theme IDs remain in
the stored document; presentation uses safe Centered geometry and the normal page
explains that selecting a theme will replace the unavailable layout. Malformed
geometry retains the existing safe fallback. Old valid Centered/Minimal/Editorial
layouts retain their geometry until the user selects a curated card.

## Security invariants

No PAM, fingerprint broker, auth controller, credential owner, Wayland lock owner,
input routing, power authority or media service implementation is changed. Themes
only provide presentation geometry. Authentication is always visible, bounded and
in front. Caps/fingerprint/status slots retain fixed geometry; password fallback
and existing confirmation/inhibitor handling remain independent of theme selection.

## Verification and acceptance

New model coverage checks catalogue metadata, unique IDs, defaults, supported
controls, deterministic accepted-layout recognition, arbitrary Custom preservation,
old defaults, malformed input, unknown IDs and absent optional appearance fields.
The production QML fixture covers gallery selection/relevant controls at compact,
normal and wide Settings widths; six themes at compact, normal, wide and portrait
sizes; optional module and size variants; bounds/overlap; stable Caps/fingerprint
slots; and simultaneous synthetic outputs. Four palettes are Catppuccin Mocha,
Everforest, Kanagawa and One Light. Existing designer tests retain their assertions
through the internal page. Security tests are not weakened.

Focused model, Settings and production-render checks pass. The final host build
passed 23/23 CTest and 18/18 Rust cases plus the package installation audit.
Evidence: `/tmp/magi-lock-themes-host-final.log` and
`/tmp/magi-lock-themes-package-final.log`; source hashes were verified against the
prepared final archive before updating the existing sandbox audit allowlist.
Full 98-suite matrix plus affected-suite reruns reconciles to **94 PASS, 4 ENVIRONMENT,
0 FAIL, 0 UNKNOWN**. The known limits are Bluetooth private bus, clipboard decoder,
notification socket and native transport/private bus. The first native sandbox run
correctly refused the old source audit; after the final host pass and exact source
hash verification, its rerun classified the same proven sandbox denials as ENVIRONMENT.
Original logs remain unchanged. Evidence is `/tmp/magi-lock-themes-full-1`,
`/tmp/magi-lock-themes-final-targeted`, `/tmp/magi-lock-themes-candidate-check`,
`/tmp/magi-lock-themes-native-reconcile` and `/tmp/magi-lock-themes-reconciled.json`.
`git diff --check` passes. Settings and protected operator state are unchanged before
native integration; no authentication implementation files differ from the baseline.
Native internal-display review: **ACCEPTED** by the operator following the requested
gallery/theme/lock/auth checks. The final wallpaper, proportions and avatar-corner
refinement also passed native review. Physical checks are operator-reported;
synthetic geometry assertions and host test counts are recorded independently.

Final preview-focused regression: all five selected suites passed in
`/tmp/magi-lock-themes-preview-refinement`; final widescreen/source/radius assertions
passed in `/tmp/magi-lock-themes-wallpaper-final.log`. No native source changed after
the host audit. All 15 integrated runtime files match the candidate. Only
`lockScreen` differs in operator Settings following explicit theme selections;
all other Settings sections and recorded protected configuration/symlinks remain
unchanged. Schema is 22. Installed package is 0.1.0-11.
Physical external-monitor acceptance: **DEFERRED**, no external monitor available.
