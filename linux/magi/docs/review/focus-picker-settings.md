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

## Shared card composition

`SettingsSection` remains the one grouping abstraction. Its non-focusable outer
Item owns a semantic elevated background, a subtle border-role outline and the
existing surface roundness policy. Internal layouts provide 12px inset, shared
spacing, heading, description and the existing optional disclosure. Controls keep
their own focus/hover semantics. The page owns width; Profile's responsive identity
rows use the page's available width minus card padding, avoiding provisional-width
feedback during first creation with long text and a pinned preview.

`carded: false` removes the surface and inset for structural groups and already
painted previews. CC family containers, nested Fine tune/border groups, Hub's nested
border controls, application error details and Lock Screen's live preview opt out.
Theme, palette, icon, lock-theme and wallpaper galleries are not wrapped again.

Reviewed coverage:

| Page | Treatment |
| --- | --- |
| Appearance / application themes | Existing conceptual sections receive shared cards; galleries remain independent. |
| Wallpaper | Existing Library sources card; Library preferences added; gallery retained. |
| Transparency | Shared backgrounds, Global blur, Application support and Details cards; preview separate. |
| Profile | Identity and Weather; long-text responsive rows retain alignment. |
| Bar | Existing identity, family, refinement and Custom Image sections share cards; visual layout editor retained. |
| Control Centre | Decorative Image and contextual appearance sections share cards; preview/layout unchanged; nested groups opt out. |
| Hub | Layout, Selector appearance and Switch appearance grouped; existing surface controls share cards. |
| Date & time | Formats and spacing; Calendar details. |
| Launcher | Existing Behaviour, Layout, result-limit and hidden-app sections share cards. |
| Notifications | Card borders; Behaviour and history; Limits and timing. |
| Clipboard | Collection and limits; existing privacy, borders and history-action sections. |
| Emoji | Behaviour; Layout and history. |
| Lock Screen | Selected-theme appearance/authentication options receive cards; gallery and live preview kept separate. |
| Security | Existing fingerprint status/enrollment groups receive cards. |
| Power & Idle | One coherent Idle timers card, preserving apply/cancel semantics. |

`settings/cards` checks semantic surfaces, roundness, no extra focus targets,
no nested card regression and horizontal control bounds on Appearance, Bar,
Control Centre, Lock Screen and Power & Idle at 720×560, 1000×760 and 1400×900
in One Light and Nord. It resizes the actual backing QWindow and can save 30
captures with `python3 linux/magi/tests/settings/cards.py <capture-directory>`.
Existing presentation tests exercise the remaining pages and keyboard controls.
Captures are private evidence at `/tmp/magi-settings-cards-preview`. The operator
accepted the representative pages in light/dark palettes and compact/normal windows
on 2026-11-10 (“Cards accepted”). Wide-window coverage is automated.

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

## Validation and commit gate

The targeted Hub, existing Settings presentation/palettes and importer checks passed
4/4 (`/tmp/magi-regression-ugylmpsa`). The next 15 checks passed 14 and exposed a
Profile recursive-layout warning; this was treated as a failure despite its PASS
marker. The final width/layout correction passes the Profile and cards checks
(`/tmp/magi-regression-g272keg1`). Separate picker/cards checks passed 2/2
(`/tmp/magi-regression-c81ir0ct`). The broader phase12f disclosure test was updated
to use the section’s stable disclosureButton instead of a child index after the
wrapper change; all five sites still send real keyboard events. It and the chooser
mode-exit case pass (`/tmp/magi-regression-7ft0n9bj`). No warning exemption was expanded.

The first full run exposed an additional offscreen catalogue harness still creating
a real compositor grab. It was stopped; existing native-window substitutions now
substitute the protocol object too. No warnings are exempted. The subsequent broad run identified the old disclosure
index assumption; the final complete matrix is rerun after that correction and the
chooser mode-exit guard. The broad run completed 101 PASS / 2 FAIL / 4 ENVIRONMENT. Its second failure was
an appearance fixture that left personal-message mode off after visibility
permutations, then clicked hidden Message and Weather fields by maximumLength.
The test now enables Personal message through its real toggle and edits exactly
the two visible identity fields; the preview-text assertions remain intact.
The corrected complete appearance/preview fixture passes
(`/tmp/magi-regression-53u2cosf`), including all 96 visibility/gap combinations and
real identity-field editing. The final complete matrix at
`/tmp/magi-regression-t5i49jcv` finishes **103 PASS / 0 FAIL / 0 UNKNOWN /
4 ENVIRONMENT / 0 SKIPPED** across 107 commands. Its exit 2 represents the four
established environment limits: Bluetooth private D-Bus, Clipboard image decode
requiring denied D-Bus, Notifications private D-Bus, and native-lock
SOCK_SEQPACKET/private-bus denial after a clean native build and exact host audit.
No exemption was widened. Results are retained as `final-regression.json` in the
audit; individual logs remain in the matrix directory. Native focus, picker and
card acceptance all passed separately. No schema change or new default asset.

The review candidate was copied to the persistent source with per-file preconditions
and rollback bytes, then loaded by the normal watcher at 09:05:25 on 2026-11-10.
No Quickshell restart or Settings write was performed. The native log records
`Configuration Loaded`; the subsequent Wi-Fi null-device warning also existed
before this phase. Native input, picker and card review were requested separately. All three gates are
operator-accepted; responses are recorded in `native-acceptance.json`. The native
Wayland text-input `disableSurface` mismatch warnings still appear during focus
changes and were present before this phase. They are recorded, not suppressed;
the operator passed actual keyboard delivery and release despite those warnings.

The post-deployment check verifies all 42 candidate paths match the worktree,
all 32 frozen runtime/test hashes match the full-run input, and both indexes are
empty. `git diff --check` passes in both locations. Main remains at the baseline
commit with divergence 0/0; its working tree intentionally holds the review changes.
Of 701 protected snapshot entries, 687 are identical and 14 are intended source
file/directory changes. There are no unexpected changes; Settings is byte-identical,
and existing artwork, managed assets and generated theme state are unchanged.
Evidence is in `protected-deploy-result.json` and `deployment.json` under the audit.
After native acceptance, the only additional protected change is Settings
`emoji.recents`, reflecting recent-item activity during the focus check. All other
Settings values remain identical; that operator history is preserved. Assets and
all other protected configuration remain unchanged. The later snapshot is
`protected-after-native.json`.

Three focused commits approved by the operator:

1. `magi: release hub focus on external interaction` — HubWindow, Hub focus tests
   and focus-specific documentation.
2. `magi: repair control centre image picker` — retained SettingsImagePicker,
   decoration/Bar callers, registration, picker tests and picker documentation.
3. `magi: group settings options into cards` — shared section, page grouping and
   nested opt-outs, responsive Profile rows, card tests and presentation documentation.

Shared matrix/document files must be staged by relevant hunks. Exclude live Settings,
user artwork, managed imports, private audit/capture state and all unrelated files.
Native review and commit approval are complete. Stop after the three commits for
separate push approval.
