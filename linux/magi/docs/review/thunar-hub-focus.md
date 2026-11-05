# Thunar backgrounds and Hub search focus

Baseline `26be1be9166fdf88f8cbf1db93046b0867ccca2e`, inspected 2026-11-05.
Native acceptance passed; the temporary deployment has been restored to the original
production baseline before integration. The operator approved integration and both
reviewed commits; pushing remains subject to separate approval.

## Installed stack and ownership

Host inventory reports Thunar 4.20.10-1, GTK3 3.24.52-2, no xfce4-settings package,
GSettings theme `MAGI`, dark scheme, and native Wayland app ID `thunar`.
Active/inactive/fullscreen compositor opacity are all 1.0. Blur is enabled, size 4,
four passes, optimizations enabled. No Thunar opaque/RGBX/no-blur rule existed.
Hybrid graphics and the Intel compositor remain unchanged.

Theme Orchestrator owns the named MAGI GTK3 theme, semantic colours, runtime theme
link and GSettings selection. Generated CSS lives below
`$DATA/magi/theme-orchestrator/gtk/generations`, with current/previous pointers.
The static gtk.css bootstrap owns layout only. Existing Thunar palette rules used
opaque colours over Adwaita; there was no application-background policy input.
GTK activation remains next process launch. No unrelated GTK application is restarted.

## Verified GTK hierarchy

Exact release source: [Thunar 4.20.10 archive](https://archive.xfce.org/src/xfce/thunar/4.20/thunar-4.20.10.tar.bz2),
SHA256 `a5a32b51028dc821155e44cdec025fe70398bae193c619ae6ba8b1babf6f49f1`.
The upstream GPL source was inspected, not copied into MAGI implementation.
`thunar-window.c` adds `.thunar` to the main window and requests an RGBA visual;
it constructs the menubar, toolbar, paned widgets, notebooks and preview pane.
`thunar-standard-view.c` adds `.standard-view`; `thunar-shortcuts-pane.c` adds
`.shortcuts-pane`; the window adds `.sidebar` to its active side pane. Location
entry/buttons remain normal GTK controls; status uses GtkStatusbar.

A test-only GTK module inspected the installed binary and captured its widget drawing
into ARGB images. Actual paths include `window.thunar.background`, `toolbar`,
`scrolledwindow.sidebar.shortcuts-pane > treeview.view`,
`notebook > scrolledwindow.standard-view > widget.view`, `statusbar`,
`scrolledwindow.preview-pane > viewport`, and the location `entry`.
List view uses GtkTreeView. Tabs use notebook header; menus/popovers and separate
dialogs retain solid semantic/base-theme surfaces. No global transparent wildcard.

Background alpha is applied once to `.standard-view`, `.sidebar`, toolbar, menubar,
statusbar, notebook header and preview pane. The root and intervening containers are
transparent; inner file/sidebar views are transparent. This is necessary because
GtkTreeView paints its own background more than once: painting 0.8 there produced
about 0.96 rendered alpha. Painting its enclosing container instead produces 0.8.
Explicit `:backdrop` variants prevent Adwaita from restoring opaque inactive surfaces.
Foregrounds, icons, thumbnails, controls and selected rows receive no opacity multiplier.

## Candidate integration

The existing shared `applicationAppearance` policy supplies background opacity;
no new control or persisted field is introduced. Unmanaged mode emits the original
opaque palette rules. GTK is included only when its existing theme target is enrolled.
Application Appearance validates both affected outputs before publishing, records
rollback intent under the existing shared journal lock, verifies publication and
restores both targets after a publication/runtime failure. Old Ghostty-only pending
journals remain recoverable. Normal theme switches compose the same stored policy.

The static Lua integration adds one disabled-by-default, exact Thunar-class no-blur
rule alongside the existing Ghostty rule. Each handle is independent; runtime toggles
create no rules and never change window opacity, blur size or passes. Managing enrolled
Thunar fails before publication if its handle is missing. The global blur engine is
still Hyprland's sole background blur implementation; no GTK CSS backdrop filter or
background-effect protocol request is added. Ghostty's accepted path is unchanged.

## Hub diagnosis and candidate

Shortcut → shared Hub controller → retained HubWindow → HubContent → search field.
All three searchable components already call forceActiveFocus. The window requested
`WlrKeyboardFocus.OnDemand`, which does not require the compositor to transfer input
from the previous application. Offscreen item-focus tests therefore passed while
real typing leaked into that application.

The shared window now requests Exclusive keyboard access while a searchable mode
(Apps, Clipboard, Emoji) is visible, and releases that policy on hide/suppression.
Settings and Notifications retain OnDemand behavior and their existing content focus.
Existing readiness and mode-change callbacks select the relevant retained search
field; no recurring focus timer, external activation command or synthetic input is used.
Queries retain their existing prepare/entered/reset policy. Deliberately selected
controls are not refocused when models update. Escape still closes the shared host.

[Quickshell 0.3 WlrKeyboardFocus](https://quickshell.org/docs/v0.3.0/types/Quickshell.Wayland/WlrKeyboardFocus/)
was checked on 2026-11-05 against installed QML metadata. Exclusive supplies layer-shell
keyboard ownership; it is not an authentication/lock mechanism. Native first-character
routing and focus return were verified in the normal-session operator acceptance gate.
Mouse/result interactions were included in the reopen/navigation check.

## Evidence and acceptance

Private evidence is under `$STATE/magi/audits/thunar-focus-413vpnwz`; it is not a runtime
dependency. Source/Settings/config-link snapshots and the read-only host inventory are
retained. Isolated Thunar tests used a private bus/config and disposable sample files.
Normal Thunar and saved operator settings were not modified.

- Initial Nord opaque control was opaque as expected. All four alpha palettes exposed
  the inactive Adwaita background defect; no premature pass was claimed.
- Explicit backdrop rules passed active/inactive transparency and blur in Nord,
  One Light, Catppuccin Mocha and Everforest Dark Hard.
- Final single-paint canvas passed the Nord/One Light visual recheck. Captures contain
  748,929 pixels at alpha 204/255 in the active reference images; the former large
  alpha-245 sidebar region is gone. Solid foreground pixels remain present.
- Operator reports clear foregrounds and working transparency/blur; selected-document
  colour polish was explicitly deferred. No visual redesign is included.
- Focus tests exercise production components: actual Qt key events for typing,
  navigation/activation and Escape, reopen/mode changes, query retention, and deliberate
  selector focus. Offscreen tests do not certify compositor routing to another app.
- Transaction tests cover GTK validation before either publication, partial GTK
  publication and blur-toggle rollback, missing handle refusal and next-launch
  activation alongside Ghostty. Schema remains 22.

Full regression: **97 PASS, 4 ENVIRONMENT, 0 FAIL, 0 UNKNOWN, 0 SKIPPED** across
101 suites. Limits remain bluetooth/bus, clipboard/model, notifications/run and
native_lock. Final appearance/activation/Thunar targeted rerun: 3 PASS. Diff checks
pass; schema 22 and protected production state are unchanged.

Normal-session evidence: `native-gate-2_zcl2n5/report.json`. All six immediate-typing
cases passed (Apps, Clipboard and Emoji from Ghostty and the second-app test labelled
Thunar or Zen), with sampled visible/focused/Exclusive state and operator confirmation
of zero first-key leakage and Escape returning focus. Reopen, mode changes, keyboard
navigation/activation and mouse interaction passed. Nord → One Light → Nord passed
through normal Thunar relaunches, including active/inactive transparency, blur,
foreground/menu clarity, scrolling/navigation/thumbnails and workspace responsiveness.
The test used temporary application alpha 0.8, preserving saved alpha 0.7 and the
existing global blur size 4/four passes. Independent blur-exclusion handles were
verified off/on. Theme targets had no activation errors; GTK correctly reported next
launch and Ghostty reload requested, rather than claiming loaded-generation readback.

The acceptance checks passed before cleanup encountered two test-helper defects:
an exited child shell was mistaken for a running process, then Quickshell's textual
no-instance result was incorrectly parsed as JSON. Both were repaired and tested;
the original failure report remains retained. Recovery subsequently verified source,
Settings bytes, original appearance/palette, canonical links, monitor geometry and
runtime effects, with clean production Git. Final evidence records both native
acceptance and restoration as passed. Neither failure required product-source changes.

Approved commit split: `magi: add translucent Thunar appearance` and
`magi: focus hub search on open`. No push without explicit approval.
