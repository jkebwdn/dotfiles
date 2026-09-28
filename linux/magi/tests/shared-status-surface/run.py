#!/usr/bin/env python3
"""Run the real QML in an offscreen, disposable Quickshell config root."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix="magi-lifecycle-") as directory:
    stage = Path(directory)
    config = stage / "config"
    shutil.copytree(root / ".config/quickshell/magi", config)
    harness = Path(__file__).with_name("lifecycle.qml").read_text()
    harness = harness.replace('../../.config/quickshell/magi/', '')
    (config / "lifecycle.qml").write_text(harness)
    runtime = stage / "runtime"
    runtime.mkdir(mode=0o700)
    env = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
               XDG_RUNTIME_DIR=str(runtime))
    env.pop("WAYLAND_DISPLAY", None)
    env.pop("DISPLAY", None)
    result = subprocess.run(["quickshell", "-p", str(config / "lifecycle.qml"), "--no-color"],
                            env=env, text=True, capture_output=True, timeout=30)
    output = result.stdout + result.stderr
    print(output, end="")
    checked = "\n".join(line for line in output.splitlines()
                         if "ERROR quickshell.ipc: Failed to start IPC server" not in line)
    raise SystemExit(0 if result.returncode == 0 and "RESULT: 0 failures" in output
                     and "FAIL:" not in checked and "ERROR" not in checked else 1)
