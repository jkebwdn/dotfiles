# Hub focus, image picker and Settings cards — review candidate

Baseline verified after the separate decoration push: `771cf7c39664385a37ea656497ac39509609ab48`,
`HEAD == origin/main`, divergence 0/0, clean tree and empty index. The host push
also verified unchanged Settings and 701 protected entries. The completed decoration
worktree was reconciled against main and removed through Git; its stale derived
bytecode was retained in the new audit rather than mistaken for source.

One worktree: `/tmp/magi-focus-picker-settings-irfbn17q`. Private evidence and fresh
Settings snapshot: `$STATE/magi/audits/focus-picker-settings-a0aw8hmd`.
No live Settings were changed during the audit. Schema remains **22**. This phase
has no new persisted fields, importer, asset location, theme writer or output policy.
Native acceptance passed on 2026-11-10. The operator approved the three focused
commits; push still requires separate approval.

## Hub diagnosis and lifecycle

`hyprland.lua` maps Super+Space/C/E to `hub toggle apps/clipboard/emoji`.
`Hub.toggleFromShortcut` selects `SurfaceOrigin.shortcutTarget`; `Hub.open` chooses
the mode, retains the existing visited/query policy and publishes presentation.
`shell.qml` owns one retained `HubWindow`. Its surface and selector are QML items
inside the same full-output, pointer-masked layer-shell window. Popups use that
window's Qt overlay. There is no second search-window surface to register.

The previous fix bound `WlrKeyboardFocus.Exclusive` to visible searchable content.
External pointer clicks could pass through the input mask, but did not change
`Hub.opened`; Exclusive keyboard ownership therefore persisted and locked other
applications out. There was no HyprlandFocusGrab or outside-dismiss handler.
`forceActiveFocus()` in each content's `focusSearch` only selects the Qt item; it
cannot release compositor ownership. No `requestActivate()` is used.

The candidate uses OnDemand while mapped and None while hidden, with a single
`HyprlandFocusGrab` listing the Hub window. The grab is requested only while visible
in Apps, Clipboard or Emoji. Grab activation and existing visibility/mode callbacks
focus the current search field. A compositor `cleared` signal closes only an active
search Hub, unmaps it and releases keyboard ownership. Escape, close, suppression
and transition to Settings/Notifications release the grab; non-search modes retain
their existing on-demand policy. Selector/results/scroll areas share the registered
window and do not cause outside dismissal. No input-mask expansion was introduced.

`hub/run` exercises production controller/item routing and a protocol-object
substitution offscreen: immediate item typing, repeats, mode changes, query policy,
Escape, simulated cleared dismissal and non-search exclusions. This is **not**
proof of compositor first-key capture, click-through, or typing into another app.
The operator passed the real Hyprland gate on 2026-11-10: Zen, Ghostty and Thunar
in all three search modes, immediate typing, outside dismissal and typing back
into the previous app, reopening, mode switching and Escape. The response was
“All focus checks passed.” `hubWindow status` reports actual grab state.

## File-picker diagnosis and ownership

Both image controls already imported QtQuick.Dialogs, created FileDialog, called
`open()` and connected acceptance to AssetManager. Settings pages are retained after
visiting, so a missing import, disconnected button or unloaded page was not the
observed cause. An isolated reproduction of the original DecorationSettings showed
`parentWindow: null` before and after clicking while `visible` became true. Qt source
clarifies that its getter only returns the stored pointer: `windowForOpen()` may
resolve an implicit parent separately. Therefore null alone does **not** establish
that the dialog was unparented. The verified issue is in presentation ownership:
the button opens a page-local dialog with the default separate Popup.Window path
from an overlay-layer host, without an explicit in-window presentation contract.
The exact native stacking/activation failure is still an inference, not established
by offscreen visibility. Existing native text logs supplied no picker-specific
warning. The operator subsequently passed opening, Cancel, reopening and final-asset
import in the real Settings host. This accepts the repaired behavior without proving
the exact original compositor failure.

`SettingsImagePicker` is one retained Settings-module singleton. Callers pass their
actual `Window.window`; FileDialog binds that explicit parent. Qt 6.12's native
QtQuick dialog fallback is deliberately used as `Popup.Item` with
`DontUseNativeDialog`, so it appears in the retained host's existing overlay/input
region instead of an unrelated top-level behind the layer surface. This remains
QtQuick.Dialogs.FileDialog, with no external file-picker process or shell script.

The owner serializes dialog/import requests, dispatches to the unchanged
AssetManager Bar/decoration operations, reports errors to the relevant page and
merges only the successful asset descriptor into the latest preferences. Requests
finish if a page unloads; hiding the parent or leaving Settings for another Hub mode cancels an open chooser. Cancel changes
nothing. PNG/GIF decoration filters and broader Bar filters remain distinct; the
same existing validation/storage/alpha measurement handles both. Originals are
never converted or deleted.

`settings/image-picker` clicks the production choose button, checks a non-null exact
parent, selects PNG/GIF through the real Qt file-list delegates, cancels/reopens,
unloads/reloads the caller during import, cancels on leaving Settings with the host
still mapped, verifies Bar reuse and checks unsupported
and missing-file failures preserve the previous selection. Managed bytes and saved
GIF descriptors are verified in isolated XDG directories. Synthetic tests do not establish native layer-shell behavior. The separate operator
response “Picker checks passed” establishes that acceptance.

## API evidence (2026-11-10)

Installed: Quickshell 0.3.2-1, Qt base 6.12.0-3 / declarative 6.12.0-4,
Hyprland 0.57.1-1. Installed QML type metadata confirms FocusGrab and dialog APIs.

- [Quickshell 0.3 FocusGrab](https://quickshell.org/docs/v0.3.0/types/Quickshell.Hyprland/HyprlandFocusGrab/)
  documents window registration, activation and compositor-cleared dismissal.
  [0.3 source](https://raw.githubusercontent.com/quickshell-mirror/quickshell/v0.3.0/src/wayland/hyprland/focus_grab/qml.cpp)
  shows deferred activation on mapping and release. Applied only to Hub search modes.
- [WlrKeyboardFocus](https://quickshell.org/docs/v0.3.0/types/Quickshell.Wayland/WlrKeyboardFocus/)
  documents Exclusive locking other windows out and None disabling keyboard input.
- [Hyprland 0.57.0 FocusGrab source](https://raw.githubusercontent.com/hyprwm/Hyprland/v0.57.0/src/protocols/FocusGrab.cpp)
  demonstrates initial keyboard refocus to a committed surface and clearing the seat
  grab. This is version-family evidence, not a claim to have inspected 0.57.1's exact
  implementation; the 0.57.1 raw source was unavailable and native checks remain required.
- [Qt 6.12 Dialog](https://doc.qt.io/qt-6/qml-qtquick-dialogs-dialog.html) documents
  explicit parentWindow and Popup.Item (since Qt 6.10); [FileDialog](https://doc.qt.io/qt-6/qml-qtquick-dialogs-filedialog.html)
  documents filters, acceptance and the QtQuick fallback. The candidate requires the
  already installed Qt 6.12 API; older Qt compatibility is not claimed.
  [Qt 6.12 dialog implementation](https://raw.githubusercontent.com/qt/qtdeclarative/6.12/src/quickdialogs/quickdialogs/qquickabstractdialog.cpp)
  distinguishes the stored parentWindow getter from implicit `windowForOpen()`
  resolution, and establishes Popup.Window as the default reset behavior. This
  prevents interpreting the null getter as conclusive missing-parent evidence.


## Focus and picker validation

Hub and picker component checks passed. Native focus and chooser acceptance passed
separately as recorded above. Shared Settings cards and final matrix evidence are
allocated to the following commit.
