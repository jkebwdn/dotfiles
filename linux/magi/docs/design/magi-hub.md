# MAGI Hub — implementation checkpoint

2026-10-06. Implemented and validated to the scope below; uncommitted operator review. Baseline verified locally:
`a007259a4f8e79cd8372d520ea2c9902cb2a3393` (First-Party Emoji Picker),
branch `main`, upstream `origin/main`, no divergence reported. Pre-existing
operator changes: `.config/quickshell/magi/settings.json` and sibling untracked
Hypridle/Hyprlock files. These are excluded from this milestone.

## Architecture and contract

`services/Hub.qml` owns open/closed state and mode. One `HubWindow` owns the
zero-reservation overlay and keyboard input. `HubContent` supplies the shared
background and upper-right icon selector, in order Apps → Notifications → Emoji
→ Clipboard. Four persistent content items retain their identities; only one is
visible. Notification Centre's existing UI is extracted into `NotificationContent`.
Launcher, Emoji and Clipboard reuse existing content. Backend/data ownership is
unchanged. ShellRoot still activates notification ownership and clipboard capture
independently of Hub; `ToastHost` remains separate.

Existing IPC targets/methods remain: launcher, notifications, emoji, clipboard.
Legacy writable `opened`/`centreOpen` properties are synchronized requests to Hub.
New `hub open MODE`, `hub toggle MODE`, `hub close`, `hub status` are additive.
`hubWindow status` reports visibility, geometry and focus without content/history.
Mode IDs: `apps`, `notifications`, `emoji`, `clipboard`. Additive `open` methods
also exist for Clipboard and Notifications.

Direct shortcuts (existing Hyprland configuration unchanged):

| Shortcut | IPC target | Hub mode |
| --- | --- | --- |
| SUPER+SPACE | launcher toggle | apps |
| SUPER+N | notifications toggle | notifications |
| SUPER+. | emoji toggle | emoji |
| SUPER+SHIFT+V | clipboard toggle | clipboard |
| SUPER+CTRL+SPACE | rofi -show drun | independent fallback |

Closed → open requested mode; different mode → switch without unmapping Hub;
same mode toggle → close. `open` and selector clicks are idempotent, not toggles.
Queries persist when switching within a Hub session; reopen resets them using
existing subsystem preparation. Emoji copy completion is invalidated when leaving
Emoji, so stale completion cannot dismiss another mode.

Search focus belongs to Apps/Emoji/Clipboard. Notifications focuses its content.
F6 reaches the mode selector, Tab/Shift+Tab navigate controls, Enter/Space activate
buttons. Escape and consuming outside-click close Hub. The input mask excludes
the 48px bar so Control Centre/Calendar stay pointer-accessible. Opening either
closes Hub; opening Hub closes the anchored menu and waits for `bar.settingsReady`
(existing collapse/interaction readiness). Fullscreen closes Hub and blocks open
requests; leaving fullscreen does not resurrect a closed menu. Native previous-app
focus follows the accepted exclusive-layer unmapping pattern and passed live tests
after both mode switches and per-mode Escape dismissal.

## Geometry, Settings and retirement

One full-output transparent native window, namespace `magi-hub`, keeps its identity
while inner preferred geometry varies. Existing widths: Launcher configured list
420/grid720 defaults; Emoji columns×(size+24)+32 (448 default); Clipboard540;
Notifications410. Existing preferred content heights are retained, plus48px for
the compact selector, clamped to output minus96px. Launcher top/center preference
is preserved; other modes centre. No Hub Settings or schema migration.

Bell renderer and Bar Settings placement choice are removed. Old saved
`notifications` placement IDs remain valid but are filtered from presentation;
new defaults omit the bell. Notification policy/state and DND are retained.
Two original geometric semantic icons (Apps, Emoji) extend MAGI's registry; no
external artwork/code was reused. Runtime settings are not edited.

Retired after native replacement validation: `LauncherWindow.qml`,
`EmojiWindow.qml`, `ClipboardWindow.qml`, `NotificationCentre.qml` and unused
`NotificationIndicator.qml`. Reusable content remains, including extracted
`NotificationContent`. The old Clipboard floating-window fixture is removed;
Hub integration replaces it. Notification presentation tests load extracted
content; the existing Emoji live fixture now checks the Hub namespace.

Clipboard now uses Hub's modal utility behaviour: outside-click dismisses it
instead of leaving a floating viewer behind another app. Its old narrow Hyprland
class/title rule is inert and deliberately untouched. Normal QML source reloads
reset session-only Clipboard history, as before: baseline count3 became0 during
implementation reloads. The clipboard backend and capture architecture were not
changed. No persisted history or clipboard payload was read/erased by live tests.

## Evidence and validation so far

Installed Quickshell0.3.1-1 and Hyprland0.56.2-4 verified with pacman.
API sources inspected2026-10-06, documentation versionv0.3.1:
[WlrKeyboardFocus](https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/WlrKeyboardFocus/)
and [ExclusionMode](https://quickshell.org/docs/v0.3.1/types/Quickshell/ExclusionMode/).
Exclusive gives exclusive keyboard input; Ignore cannot reserve an exclusion zone.
`HubWindow` reuses these installed APIs from the accepted Launcher/Emoji hosts.
These docs establish API meaning, not compositor focus restoration or multi-output
correctness. No repository revision inferred; native tests remain necessary.

Additional sources inspected2026-10-06:
[Qt6.11.2 TestCase](https://doc.qt.io/qt-6.11/qml-qttest-testcase.html) documents
item-targeted mouse events, focus-targeted keyboard events and eventual assertions.
`tests/hub/pointer.qml` and `actions.qml` exercise actual QML handlers using these
APIs on installed Qt6.11; the native wrapper is substituted offscreen, so they do
not establish compositor pointer routing. No sample code/artwork was copied.
[Hyprland dispatchers](https://wiki.hypr.land/Configuring/Basics/Dispatchers/)
(current unversioned Lua docs, inspected against installed0.56.2) document
`send_shortcut` and `window.fullscreen`. `tests/hub/live.py` sends guarded keys;
`fullscreen.py` fullscreens only its disposable client. Local execution, not the
unversioned documentation alone, establishes compatibility. Broader output/focus
policies remain operator tests.

### Automated checks passed

- `python3 tests/hub/run.py`: retired-host/source ownership assertions; real Hub
  controller/window/content with only the native wrapper substituted offscreen;
  direct modes, selector, retained content identity/queries, focus, toggles, legacy
  property writes, Escape, anchored readiness/handoff, fullscreen state, Settings
  handoff. QtTest covers selector clicks, consumed interior clicks and outside
  dismissal. Representative selection tests launch a disposable desktop entry via
  real GIO, copy exact `👩🏽‍💻` bytes through Emoji's real helper into a fake wl-copy,
  render notification history/invoke a controlled default action/dismiss, and
  search/restore a synthetic Clipboard row through real service/content with a
  fixture transport. Exact selected restore ID and UTF-8 bytes are asserted.
- Launcher `presentation.py`: content, settings, service desktop discovery/launch,
  disable/reset, hidden app/context action/restore; staged identical implementation.
- Emoji `presentation.py`: content/settings, exact copy bytes, reopen race and
  failure behaviour; staged identical implementation.
- Clipboard `presentation.py`: content and service isolation/search/fullscreen;
  `model.py`: all10 tests passed outside sandbox. The two image tests initially
  failed inside sandbox; no backend edit was needed. Existing GLib deprecation
  warning remains unrelated.
- Notifications `presentation.py`, `policy.cjs`, and private-bus `run.py`: history/
  toast geometry, policy and complete existing protocol/ownership/reload checks.
  Private D-Bus sockets require execution outside this sandbox. No desktop bus
  ownership replacement was attempted by the fixture.
- Calendar `presentation.py` and `bar.py`; the latter was rerun after final bar
  placement filtering. Shared Control Centre/status lifecycle `run.py`:48 steps,
  zero failures. No Wi-Fi/backend/network commands were exercised.
- Settings `run.py`: schema/atomic store/migration/persistence/reset checks; only
  the obsolete default-six-items assertion changed to five after bell retirement.
  Icon resolver regression passed with `.config/quickshell/magi/icons` as argument.
- `git diff --check`: clean.

The existing offscreen runners filter known IPC-socket and window-mask platform
messages. This is not a claim of warning-free native support for the offscreen
plugin. Focused suites were used; backend search/data edge cases were not broadly
re-proven when unchanged.

### Native runtime checks passed

- `python3 tests/hub/live.py`: same native layer address through all four modes;
  correct content focus, Apps/Emoji typing, F6/Shift+Tab/Space selector activation;
  toggles, Escape, previous-app focus after mode switching and each mode's close;
  Hub↔Control Centre and Hub↔Calendar handoffs; no old utility layers or Clipboard
  desktop client; notification/capture continuity; exactly48px reservation.
- `python3 tests/hub/fullscreen.py`: disposable native test client becomes
  fullscreen while Hub is open; Hub closes, all four shortcuts' IPC paths remain
  suppressed; exit does not reopen it; explicit open restores search focus.
  Disposable client/process is terminated in `finally`.
- Final inspection: same production PID1572 / instanceo71yp2imt as baseline;
  exactly one MAGI instance, one child clipboard backend. Notification D-Bus owner
  is PID1572. Capture ready/monitoring true; Hub closed after tests.
- eDP-1 scale2 remains `[0,48,0,0]`; `hyprctl configerrors` empty. Recent reload
  log tail is INFO-only. First promotion had a new-type discovery error, fixed by
  explicit Hub `qmldir`/local import and normal source reload. No explicit process
  restart or Hyprland config change.
- Live Emoji Hub screenshot inspected:448×456 inner geometry at(736,312), with
  shared selector and existing content. New semantic SVG masks use white source
  pixels, matching MAGI's existing tint pipeline; default-black currentColor was
  corrected during review. Fresh resource paths cleared the retained native image
  cache; the final screenshot confirms semantic tint on all four icons. Hub uses
  the accepted Launcher/Emoji opaque background to prevent underlying text showing
  through. Visual acceptance remains the operator's decision.
- Runtime settings SHA-256 remains
  `d84e2ac05c341eb08a7268b560209aaf7c457c71111659ba0818d8c6cc9a2796`.

### Review / resume

Implementation and automated validation are complete to the stated scope. Stop
for operator review; no commit or push. Please review physical shortcut switching,
mouse selector/outside dismissal/bar handoff, Launcher list/grid sizing, actual
app launch/paste, Emoji exact paste and Clipboard restoration with normal content.
Native live tests deliberately did not write clipboard data or Emoji Recents;
external copy/restore integration was isolated, with live paste left to review.
Notification protocol actions were private-bus tested; Hub card actions were
fixture tested. No claim of new live notification-action pointer acceptance.

If further work is requested, use repository source and this ledger, not the
initial staging copy. `/tmp/magi-hub-work/*.log` contains run logs and screenshots;
those temporary artifacts are not required to reproduce tests. No known failing
check remains; no whole-suite rerun is necessary without a relevant change.

## Deferred / operator review

Visual approval, physical shortcuts, multi-output/fractional scale, whole-shell
visual overhaul and Control Centre catalogue are not claimed by automation.
No omnibox, provider framework, backend replacement or new subsystem features.

## Exact intended Git path allowlist

Paths relative to `linux/magi/`; includes the explicit deletions above. This is a
review/staging allowlist only, not permission to commit. Exclude runtime
`settings.json`, sibling Hypridle/Hyprlock files and all `/tmp` artifacts.

```text
.config/quickshell/magi/components/bar/Bar.qml
.config/quickshell/magi/components/clipboard/ClipboardContent.qml
.config/quickshell/magi/components/clipboard/ClipboardWindow.qml
.config/quickshell/magi/components/emoji/EmojiContent.qml
.config/quickshell/magi/components/emoji/EmojiWindow.qml
.config/quickshell/magi/components/hub/HubContent.qml
.config/quickshell/magi/components/hub/HubWindow.qml
.config/quickshell/magi/components/hub/qmldir
.config/quickshell/magi/components/launcher/LauncherContent.qml
.config/quickshell/magi/components/launcher/LauncherWindow.qml
.config/quickshell/magi/components/notifications/NotificationCentre.qml
.config/quickshell/magi/components/notifications/NotificationContent.qml
.config/quickshell/magi/components/notifications/NotificationIndicator.qml
.config/quickshell/magi/components/settings/pages/BarPage.qml
.config/quickshell/magi/icons/packs/magi-default/hub-apps.svg
.config/quickshell/magi/icons/packs/magi-default/hub-emoji.svg
.config/quickshell/magi/icons/packs/registry.json
.config/quickshell/magi/services/Clipboard.qml
.config/quickshell/magi/services/Emoji.qml
.config/quickshell/magi/services/Hub.qml
.config/quickshell/magi/services/Launcher.qml
.config/quickshell/magi/services/Notifications.qml
.config/quickshell/magi/services/qmldir
.config/quickshell/magi/settings/SettingsSchema.js
.config/quickshell/magi/shell.qml
README.md
docs/README.md
docs/architecture.md
docs/decisions.md
docs/design/magi-hub.md
docs/quickshell-reference.md
tests/clipboard/presentation.py
tests/clipboard/window.qml
tests/emoji/live.py
tests/hub/actions.qml
tests/hub/fullscreen.py
tests/hub/integration.qml
tests/hub/live.py
tests/hub/pointer.qml
tests/hub/run.py
tests/notifications/presentation.py
tests/notifications/presentation.qml
tests/settings/store.qml
```
