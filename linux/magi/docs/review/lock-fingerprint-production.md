# Lock layout and fingerprint production integration

2026-10-30. Baseline `12827c6d9b856f3a0a129d9f1f9ac02d92aaf289` was synchronized
with origin/main (0/0), with clean tree and empty index. Worktree:
`/tmp/magi-lock-fingerprint-Kw6nCK`. Installed package: **magi-lock 0.1.0-10**.

## Current acceptance

**INTERNAL DISPLAY — ACCEPTED** for final composition, sharpness, Caps stability,
password mask, fingerprint match-to-unlock, password fallback, normal arrow cursor,
blur disabled and changing song title. The operator explicitly accepted the final
clock size and no-overlap result. The original right-index enrollment is preserved.
Mismatch/retry was observed during native review; wrong-finger trials were not a
controlled measurement of sensor reliability.

The operator also confirmed suspend/resume followed by fingerprint and password
unlock on the installed candidate. Service-loss, device-removal and reload paths
pass synthetic tests; they were not deliberately injected on the physical device. **PHYSICAL MULTI-OUTPUT — DEFERRED**, because no
external monitor is available. Do not infer physical acceptance from synthetic tests.
Repository closeout was explicitly approved after acceptance. Delivery is split
into layout/presentation and native fingerprint integration commits.

## Final composition

The sketch guides balance and hierarchy, not traced assets. Opt-in **Split Corners**
places a compact bordered avatar beside dominant time and subordinate date at top
left, with a right-aligned auth group at bottom right and large negative space.
Compact identity omits the username. Clock/date visible glyphs span the avatar height;
font ascent provides correct first-frame placement, and time numerals are reduced
10% from the first large-glyph candidate. A 12-logical-unit gutter separates avatar
and clock. A single supersampled avatar/frame image removes separate-node seams.

The auth group contains incremental marks, the prompt, then secondary REBOOT |
SUSPEND actions. Caps lock → fingerprint → ENTER PASSWORD have fixed icon slots;
mask, label and power actions share a right edge. Caps only changes opacity/state.
Biometric feedback is icon-only (waiting, retry, mismatch, timeout, unavailable,
matched), with accessible text retained. Native icons are synchronously rendered
from bounded paths at 96×96 into a 22-unit slot. Error/power feedback has a fixed
area above the mask. No state moves the auth block or steals keyboard focus.
The accepted count, 16-mark cap, overflow and Backspace behavior are preserved.

Lock Designer exposes the preset and editable alignment. Existing Centered default
and saved Custom layout are preserved. The operator selected Split Corners and tuned
it to Custom. At their explicit request only five saved offsets were later changed:
identity x=.03/y=.04, time y=.04, authentication x=-.03/y=-.05. All other values,
including module sizes, line mask, theme, Bar and application appearance, were preserved.
Settings remain schema **22**; optional blur appearance data defaults on for old data.

Lock Screen Settings offers Blur background; off retains a sharp wallpaper with
existing contrast tint. Title media style places the MAGI media icon and song title
under the adjacent profile/time block. It uses the existing bounded local snapshot;
a one-second metadata check refreshes changed tracks without reloading wallpaper or
avatar. Missing/stale data clears honestly. No media controls/network/auth capability
are exposed to presentation. Native waiting animation is not added.

## Native rendering and power safety

The internal panel is 3840×2160 at 2× scale. The old logical-resolution buffer caused
whole-screen pixelation. Buffers now use bounded integer output density with matching
QImage/QQuickRenderTarget DPR and wl_surface buffer scale. Logical geometry and power
hit regions are unchanged. Buffer count, memory limits and configure/lock authority
remain intact; density reduces if necessary to fit existing limits. NORMAL buffer
transform remains. Fractional outputs receive integer-density oversampling; physical
external acceptance remains deferred. Sharp wallpaper decode retains up to 3840×2160.
Native pointer enter explicitly selects a themed arrow via installed wayland-cursor;
media never owned a pointer handler.

Power labels are display-only. Native pointer hit regions require an owned lock
surface. Two clicks separated by at least 800 ms confirm; confirmation expires after
ten seconds. Typing, pointer leave, output reconfiguration/removal and sleep cancel.
No single key triggers reboot. Async systemctl uses --check-inhibitors=yes and
--no-ask-password with a five-second execution deadline; logind/system authorization
and inhibitors remain authoritative. No destructive reboot acceptance is requested.

## Hardware audit

Kernel: `7.2.11-arch1-1`. Installed: `fprintd 1.94.5-2`, `libfprint 1.94.100-1`.
Sysfs and the operator's host `lsusb` agree on `06cb:00bd`, **Synaptics Prometheus MIS
Touch Fingerprint Reader**. Host `fprintd-list` finds `/net/reactivated/Fprint/Device/0`,
press sensor, with **right-index-finger already enrolled**. No enrollment was replaced.
The static service was inactive before the query; D-Bus activation is expected.
Enrollment-stage count requires a claimed device and is read only when enrollment
is deliberately requested. No extra package installation is required on this host.

## Authentication boundary

`fingerprint/broker.*` implements the existing direct-fprintd design beside the
independent PAM password worker. All D-Bus method calls are asynchronous with bounded
method timeouts and an overall 30-second attempt deadline. A private connection owns
one claim; discovery pins the daemon's unique name and device path. VerifyStatus
sender/path/state are validated. Only a recognized terminal match followed by
successful VerifyStop and Release can produce a consumable current model binding.
The native Controller separately requires a secure current lock and an unblocked
sleep gate. Password success and fingerprint success converge on the existing native
unlock/sync path. QML remains incapable of authorizing success.

Cancel, sleep and teardown invalidate model state and close the private connection;
fprintd owns disconnected-client claim cleanup. Retry starts a fresh connection and
attempt binding. Owner loss, removal, no enrollment, timeout, cleanup error and
mismatch never authorize unlock or clear a typed password. Fingerprint work does not
own keyboard focus. Existing instance guard prevents duplicate lock owners. Reload
of Settings cannot create a lock verifier. A shell reload terminates managed Settings
helpers; the system service continues to own the native lock independently.

Security Settings invokes a bounded separate Gio helper for status, enrollment,
selected-print deletion and test verification. It uses the caller's own identity,
refuses enrollment over an existing selected finger, and requires explicit selected
print removal confirmation. fprintd/polkit owns authorization and storage. Only generic
state, finger names and progress counts cross into Settings. No templates, images or
passwords are logged, received or persisted by these changes. Settings verification
cannot unlock. Competing Settings activity is refused by fprintd claim ownership;
password remains available in the lock.

## Validation and preservation

- Final installed source archive matches all 86 native source files. Host clean build,
  **23/23 CTest and 18/18 Rust tests pass, no skips**, and package install audit passes.
- Canonical 96-suite matrix plus focused corrections/audited native rerun yields
  **92 PASS, 4 ENVIRONMENT, 0 unresolved FAIL/UNKNOWN**. Environment cases are the
  evidenced Bluetooth/private-bus, clipboard model, notifications/private-bus and
  native socket/D-Bus sandbox restrictions. Host native tests cover those native cases.
- Phase13A/B model/designer, fingerprint Settings, Phase11/native fingerprint and
  runtime palette/visual checks pass. Four required palettes are covered.
- Synthetic compact, normal, wide, portrait and output-topology coverage passes.
  Caps off/on/off and all feedback states preserve auth geometry. Native pixel tests
  cover frame/biometric antialiasing, 2× rasterization, unchanged power hit regions,
  and actual white-time/red-date glyph separation at DPR 1/2 and module size .75/1.
  Qt scale-factor runs 1/1.5/2 pass. Media tests cover change/removal/reappearance.
- Private mock fprintd tests validate sender/path/unique-owner and old-daemon rejection,
  one-shot match consumption, mismatch/retry, no enrollment, unavailable/busy device,
  timeout, cleanup errors, cancel/sleep gates, daemon loss and replacement.
- Final visual tweak passes focused native pixel and Phase13A/B presentation checks.
  git diff --check is clean. Live Settings are ignored/untracked and never staged.
- Runtime integration used exact paths and before/after Settings comparisons. Settings
  changed only through operator UI choices and the five explicitly requested offsets.
  Protected config snapshots, integration backups and rollback package evidence remain
  in /tmp until successful closeout. No permanent home worktree was created.

## Repository delivery

Required internal-device and visual acceptance are complete. The operator explicitly
approved committing, synchronizing, pushing and removing the temporary worktree.
Delivery uses two reviewed commits: `magi: refine lock screen layout and caps
indicator`, then `magi: enable fingerprint unlock`. Exact source/test/documentation
paths are staged; live Settings and unrelated operator files are excluded. The
worktree is removed only after merged/pushed ancestry, clean trees and protected
state are verified. No next feature is started.

## Verified references

Inspected 2026-10-30:

- [libfprint supported devices](https://fprint.freedesktop.org/supported-devices.html):
  development support table includes 06cb:00bd. Host fprintd discovery independently
  confirms compatibility of installed packages; a table alone is not native proof.
- [fprintd Device API](https://fprint.freedesktop.org/fprintd-dev/Device.html): Claim with
  empty username addresses the caller; VerifyStart/VerifyStatus/VerifyStop/Release,
  polkit checks, selected-print deletion and claimed-device enrollment-stage property.
  Relevant implementation: broker reply/signal/consume and Settings helper main.
- [Quickshell 0.3.1 Process](https://quickshell.org/docs/v0.3.1/types/Quickshell.Io/Process/):
  argv commands, managed process lifetime, signal cancellation and configuration reload
  behavior. Relevant component: SecurityPage's managed Process, never startDetached.
- Installed Wayland headers expose the pointer listener used with seat version 7;
  newer events are not bound. Existing installed Qt software-render control and shared
  QML presentation remain the renderer; no compositor/lock protocol replacement.
