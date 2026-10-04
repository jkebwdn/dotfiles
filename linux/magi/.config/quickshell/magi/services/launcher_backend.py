#!/usr/bin/env python3
"""Desktop applications only. GIO owns XDG precedence, visibility and execution."""
import json
import os
from pathlib import Path
import shutil
import sys
import gi
gi.require_version("GioUnix", "2.0")
from gi.repository import Gio, GioUnix


def applications():
    result = []
    for app in Gio.AppInfo.get_all():
        if not isinstance(app, GioUnix.DesktopAppInfo) or not app.should_show():
            continue
        result.append(dict(id=app.get_id(), name=app.get_display_name(),
            genericName=app.get_generic_name() or "", comment=app.get_description() or "",
            keywords=list(app.get_keywords() or []), categories=app.get_categories() or "",
            icon=app.get_string("Icon") or ""))
    return result


def launch(desktop_id):
    app = GioUnix.DesktopAppInfo.new(desktop_id)
    if app is None or not app.should_show():
        raise ValueError("Application is no longer available")
    context = Gio.AppLaunchContext()
    # GLib 2.88 knows xdg-terminal-exec but not Ghostty. Preserve GIO's field
    # expansion and working-directory handling through a private argv adapter.
    ghostty = shutil.which("ghostty")
    if app.get_boolean("Terminal") and not shutil.which("xdg-terminal-exec") and ghostty:
        original_path = os.environ.get("PATH", os.defpath)
        context.setenv("MAGI_LAUNCHER_TERMINAL", ghostty)
        context.setenv("MAGI_LAUNCHER_PATH", original_path)
        context.setenv("PATH", str(Path(__file__).resolve().parent / "launcher-terminal") + os.pathsep + original_path)
    if not app.launch([], context):
        raise RuntimeError("Application could not be started")


if __name__ == "__main__":
    try:
        if sys.argv[1:] == ["--list"]:
            print(json.dumps(applications()))
        elif len(sys.argv) == 3 and sys.argv[1] == "--launch":
            launch(sys.argv[2])
        else:
            raise ValueError("Expected --list or --launch desktop-id")
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
