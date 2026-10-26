# Launcher API evidence — inspected 2026-10-04

Verified installed packages: Quickshell0.3.1 (Arch0.3.1-1), Hyprland0.56.2-3,
GLib2.88.3-1, python-gobject3.56.3-1. No third-party implementation or artwork was
copied. Quickshell/GIO APIs are consumed as installed dependencies. GLib source
has its LGPL license header; the private adapter is original MAGI code.

## Desktop entries

Sources: Quickshell **v0.3.1**
[DesktopEntries](https://quickshell.org/docs/v0.3.1/types/Quickshell/DesktopEntries/)
and [DesktopEntry](https://quickshell.org/docs/v0.3.1/types/Quickshell/DesktopEntry/).
Inspected 2026-10-04; documentation version, not an inferred repository revision.

`DesktopEntries.applications` excludes Hidden/NoDisplay. `DesktopEntry` exposes
name, icon, genericName, comment, keywords and categories. Its `execute()`
documentation explicitly says terminal requirements and field codes are ignored.
This rules out blindly delegating production launch to it on the installed
version. MAGI uses one GIO-backed model for consistent discovery and launch.
Tests cover metadata and execution; future Quickshell versions can be reassessed.

## Desktop-aware launching

Sources: [GioUnix.DesktopAppInfo.new](https://docs.gtk.org/gio-unix/ctor.DesktopAppInfo.new.html),
[Gio.AppInfo.launch](https://docs.gtk.org/gio/method.AppInfo.launch.html), inspected
2026-10-04. Current documentation reports API2.0/library2.90.0; this differs from
installed2.88.3, so behavior is additionally verified against the pinned source
and installed-library fixture tests below.

`DesktopAppInfo.new(id)` resolves XDG desktop IDs. `AppInfo.launch([], context)`
launches without file arguments and can report dispatch errors. Success cannot
prove the app completes startup. These are the calls in `launcher_backend.launch`;
MAGI never executes a search string. Isolated tests verify ID lookup, overrides,
field expansion, cwd, missing/hidden entries and failures. D-Bus-only applications
and stricter Wayland activation policies need broader acceptance testing.

## Installed GLib behavior and Ghostty compatibility

Source: [GLib tag2.88.3, gio/gdesktopappinfo.c](https://github.com/GNOME/glib/blob/2.88.3/gio/gdesktopappinfo.c),
[raw inspected file](https://raw.githubusercontent.com/GNOME/glib/2.88.3/gio/gdesktopappinfo.c),
inspected 2026-10-04. Relevant functions: `expand_macro`,
`expand_application_parameters`, `prepend_terminal_to_vector`,
`g_desktop_app_info_launch_uris_with_spawn`; visibility uses `g_app_info_should_show`.

The source expands desktop-entry fields before building terminal argv. Terminal
lookup includes xdg-terminal-exec and a legacy fallback list, but not Ghostty.
Local Ghostty metadata uses `X-TerminalArgExec=-e`; no xdg-terminal-exec is
installed. MAGI's private adapter supplies that missing integration only for
terminal entries, unless the system already supplies xdg-terminal-exec. It restores
the original PATH before exec. Synthetic terminal tests confirm argument/cwd and
environment preservation. The operator subsequently accepted live Neovim launching in Ghostty.

## Surface choice

Sources: Quickshell **v0.3.1**
[WlrKeyboardFocus](https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/WlrKeyboardFocus/)
and [ExclusionMode](https://quickshell.org/docs/v0.3.1/types/Quickshell/ExclusionMode/),
inspected 2026-10-04. Components: `LauncherWindow`, attached `WlrLayershell`.

Exclusive takes keyboard focus; Ignore prevents an exclusion zone. MAGI combines
these on a temporary overlay with explicit close routes. This is a design choice,
not a claim that all compositors focus identically. Local compositor inspection
confirmed the layer/reservation; injected typing/Escape and operator outside-click
checks confirmed focus/dismissal. Multi-output and fractional scale remain untested.

## Hyprland integration

Source: [current dispatcher documentation](https://wiki.hypr.land/Configuring/Basics/Dispatchers/),
inspected 2026-10-04, unversioned current Lua docs; installed0.56.2.
`hl.dsp.send_shortcut` accepts mods/key for synthetic input. The live test used
`hyprctl dispatch 'hl.dsp.send_shortcut({mods = "", key = "z"})'` and Escape.
The legacy dispatch spelling failed before sending input; the Lua call passed.
Existing `hl.bind`/`hl.dsp.exec_cmd` patterns were retained for the two shortcuts.
Physical shortcut behavior was separately confirmed by the operator.

## Contextual Hide menu (2026-10-04)

Sources: [Qt6.11 Menu](https://doc.qt.io/qt-6.11/qml-qtquick-controls-menu.html)
and [Qt6.11 Popup](https://doc.qt.io/qt-6.11/qml-qtquick-controls-popup.html),
inspected2026-10-04; docs6.11.2 match installed qt6-declarative6.11.2-2.
`Menu.popup(x,y)` supports positioned context menus, and explicit `Popup.Item`
keeps the popup in the containing window rather than a native popup window.
`LauncherContent` uses these APIs for one shared Hide menu, capturing a desktop
ID before mutation; `LauncherItem` supplies right-click coordinates. This avoids
coupling menu lifetime to a delegate that hiding removes. The fixture verifies
popup focus, the action, subsequent search focus, both layout filters and Restore.
Live pointer Hide/Restore acceptance remains part of final operator review. This
is original composition using Qt APIs; no sample implementation or assets copied.

## Long-running application stream lifetime — 2026-10-26

Installed Quickshell 0.3.2-1 and GLib 2.90.1-1 were inspected and tested.
MAGI's `Launcher.launch()` starts a tracked `Process` for the Python GIO helper;
only discovery has a `StdioCollector`. No shell pipeline or GUI-process tracker
is involved. The helper returns after dispatch, closes Hub and updates history.

Source: [Quickshell v0.3.2 process.cpp](https://raw.githubusercontent.com/quickshell-mirror/quickshell/v0.3.2/src/io/process.cpp),
`startProcessIfReady` and `onFinished`, inspected 2026-10-26. A normal Process uses
QProcess channels (closing read channels without parsers), and deletes its QProcess
when the helper exits. A child inheriting those output descriptors outlives their
reader. The standalone baseline fixture confirms successful GIO launch followed by
errno 32 on delayed output after pipe-reader closure. This reproduces the generic
failure mechanism, not a claim to have traced the original Mullvad process.

Source: [GIO explicit-fd launch API](https://docs.gtk.org/gio-unix/method.DesktopAppInfo.launch_uris_as_manager_with_fds.html),
inspected 2026-10-26 (API since 2.58; documentation library 2.91.0, installed binding
2.90.1 verified). The replacement supplies open `/dev/null` descriptors for all
three standard streams. GIO retains XDG resolution, terminal wrapping, field codes,
cwd and activation; D-Bus activation ignores these descriptors because the bus owns
that process. No shell interpolation, polling service or Mullvad exception is added.
The helper still reports launch failure normally; application console output is
intentionally discarded rather than attached to a short-lived shell pipe.

Source: [Quickshell v0.3.2 desktopentry.hpp](https://raw.githubusercontent.com/quickshell-mirror/quickshell/v0.3.2/src/core/desktopentry.hpp),
`DesktopEntry::execute`, inspected 2026-10-26. It still documents ignoring terminal
requirements and field codes. Replacing GIO would regress accepted launch semantics.
[Quickshell v0.3.2 qmlglobal.cpp](https://raw.githubusercontent.com/quickshell-mirror/quickshell/v0.3.2/src/core/qmlglobal.cpp),
`execDetached`, uses QProcess startDetached with optional unbound output. Detaching
only the helper would also remove the dispatch-result channel used by Launcher.
GIO's explicit stream ownership is the smaller compatible fix.

Regression: `python tests/launcher/lifecycle.py` from `linux/magi` uses synthetic
XDG entries and the production Launcher/Hub/content in an isolated shell. It closes
Hub, destroys content, invokes Quickshell.reload(true), exits the shell, then tests
stdout/stderr writes over two minutes later. Child fd targets must be `/dev/null`.
`--delay 2` is a development shortcut; the default delayed run is the acceptance
check. No live shell reload, real application start, or VPN operation is required.
Existing backend tests retain terminal argv, field-code, cwd and error coverage.
Existing running applications cannot have their inherited descriptors repaired by
this change; the new launch policy applies to subsequently spawned processes.

Validation result: the full default lifecycle run passed, including healthy output
at 127.2 seconds after launch following Hub/content teardown, hard reload and shell
exit. Launcher backend, UI/service/hidden-entry, search and schema checks pass.
The schema fixture's stale version-16 expectation was changed to the current
schema default; no persisted schema or preferences changed. The negative control
reproduces EPIPE using GIO's old inherited-stream launch path. Native Mullvad was
not started, stopped or otherwise manipulated by these tests.
