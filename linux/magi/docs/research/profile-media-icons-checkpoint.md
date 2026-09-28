# Profile, media and managed-icon checkpoint

Implementation and acceptance checkpoint **2026-09-27**, based on commit
`0155364246cd5b6f6d234cbf46f4f6bde0e8fe8d`. Installed runtime: Quickshell
0.3.1-1, Hyprland 0.56.2-3, Qt 6.11.2. No commit or push was made for this
work. Multi-output and fractional scaling were not tested.

## Implemented production contracts

Settings schema v2 adds opt-in `profile`, `media`, and independently enabled
Control Centre section data. The pure v1→v2 migration retains all existing
appearance, icon, bar and Control Centre values. The running SettingsStore is
still the only writer; its explicit migration save created the existing backup
through the same atomic persistence helper. Profile name/subtitle updates are
live and the section reset uses the normal SettingsStore transaction.

`services/AssetManager.qml` serializes asset work through the bounded standard-
library helper `services/assets.py`. Avatar and SVG imports accept local regular
files, validate content, content-address the result, and atomically copy it under
`$XDG_DATA_HOME/magi/`. Settings stores managed IDs rather than arbitrary paths.
Avatars support PNG, JPEG and WebP up to 5 MiB. SVGs are limited to 256 KiB,
4096×4096 and 512 allowlisted elements; event handlers, script/foreign content,
entities and external references are rejected. The exact standard W3C SVG 1.1
doctype emitted by common design tools is stripped before parsing; arbitrary
DTDs remain rejected. `IconResolver.js` implements the existing precedence:
individual override → pack/module default → selected global pack → legacy
fallback. The Icons Settings page demonstrates global overrides for four roles
and clearing back to Default.

`services/Media.qml` wraps Quickshell's MPRIS model through testable
`MediaController.qml`. Selection is deterministic: explicit preferred identity,
then a retained playing player, then the first playing player sorted by stable
DBus/desktop identity, then a retained suitable player, then the first suitable
player. No transient selection is persisted automatically. Title, artist,
identity, artwork, playback state and capabilities remain live. Previous,
play/pause and next are guarded by the active player's advertised capabilities.
Local or HTTP(S) artwork is limited to 4 MiB and cached by content under
`$XDG_CACHE_HOME/magi/artwork`; the cache is capped at 64 files/32 MiB and stale
request results cannot replace the current track.

`ProfileHeader.qml` and `MediaSection.qml` are optional regions of the existing
Control Centre body. They do not create windows or host state. Empty profile
data and absent MPRIS players consume no height. Appearance/disappearance uses
the accepted same-view geometry retarget path, retaining one open surface.
Quick controls and sliders remain data-driven; the removed battery summary has
not returned. The normal shared-surface lifecycle, Wi-Fi password window,
Bluetooth/Audio/Brightness services and anchored fallback are unchanged.

MAGI Settings retains the stable title `MAGI Settings` and Quickshell's process-
wide class `org.quickshell`. A narrow Hyprland rule matches both, floats and
centres it at initial 940×720 size, and does not pin it, make it topmost, or
affect layer surfaces. It remains normally movable, resizable and focusable.

## Validation evidence

Automated suites pass for settings migration/persistence/reset, ten theme
definitions, module ownership, icon resolution, dynamic Control Centre layout,
Settings-window lifecycle, managed assets, MPRIS selection/metadata/actions and
all 48 shared-surface lifecycle steps. The dynamic layout fixture verifies
profile and media appearance/disappearance resize the already-open Control
Centre in both directions without collapse. Whole-production qmllint exits 0
with the documented Quickshell metadata warnings; `git diff --check` passes.
Offscreen test processes in the managed sandbox report a known failure to create
their disposable IPC socket; harnesses ignore only that exact infrastructure
line after successful configuration load and assertions.

Production PID **295263** initially validated the implementation. After the two
operator-found asset fixes, final instance **09d6gw91mt**, PID **297108**, launched cleanly. The
compositor reported one Quickshell layer at output-local `(0,0)`, 1920×1080,
and eDP-1 reservation `[0,48,0,0]` at scale 2. Schema v2 was saved with the
user's prior theme, radius, bar order and Control Centre layout intact. Settings
mapped as floating `org.quickshell` / `MAGI Settings`, 940×720 at `(490,204)`.

Operator-observed passes:

- Settings move, resize, close and reopen;
- live and persistent display name/subtitle, managed avatar, and Control Centre
  profile update;
- real MPRIS title, artist and artwork, previous/play-pause/next, player removal,
  and live Control Centre shrink;
- importing `bluetoothUI.svg`, live semantic override, and Default fallback;
- Wi-Fi, Bluetooth, Volume and consumed outside-click dismissal.

The first asset review found two bounded defects. `StandardPaths` already
returned a file URL, so prefixing another `file://` produced
`file://file///…`; the URL construction is corrected and the persisted avatar
then rendered. The SVG validator initially rejected the standard SVG 1.1
doctype; its safe exact-prolog allowance is described above. Both corrections
passed targeted tests and operator recheck.

## Remaining limits

Only the MAGI Legacy pack ships. Override UI is intentionally limited to four
global semantic roles; module-specific UI, asset browsing/deletion and SVG tint
policy remain future work. Profile layout has no crop editor. MPRIS preference
has no Settings control, and automated two-player selection has not received a
real multi-player operator test. Quickshell emitted transient DBus
`ServiceUnknown` warnings while Firefox's MPRIS endpoint disappeared, but MAGI
cleared the player and resized correctly; the fresh post-fix runtime log is
clean. No media progress/seek/volume UI is implemented.
