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

## Focus validation

Hub component tests cover item typing, reopening, mode switching and simulated
grab clearing. The separate native Zen/Ghostty/Thunar gate passed as recorded above.
Picker and card implementation are allocated to the following commits.
