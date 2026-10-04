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
