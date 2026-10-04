#!/usr/bin/env python3
"""Production content in isolation; no clipboard or bus activation."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix="magi-calendar-ui-") as temporary:
    stage = Path(temporary)
    config = stage / "config"
    shutil.copytree(root / ".config/quickshell/magi", config)
    (config / "settings.json").write_text('{"schemaVersion":8}')
    runtime = stage / "runtime"
    runtime.mkdir(mode=0o700)
    env = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
               XDG_RUNTIME_DIR=str(runtime), XDG_STATE_HOME=str(stage / "state"))
    env.pop("WAYLAND_DISPLAY", None)
    env.pop("DISPLAY", None)
    for name in ("content.qml", "settings.qml"):
        (config / "test.qml").write_text(Path(__file__).with_name(name).read_text()
            .replace("../../.config/quickshell/magi/", ""))
        result = subprocess.run(["quickshell", "-p", str(config / "test.qml"), "--no-color"],
                                env=env, text=True, capture_output=True, timeout=10)
        output = result.stdout + result.stderr
        print(output)
        checked = "\n".join(line for line in output.splitlines()
                            if "Failed to start IPC server" not in line
                            and "This plugin does not support setting window masks" not in line)
        assert result.returncode == 0 and "PASS" in output and "ERROR" not in checked and "WARN" not in checked
