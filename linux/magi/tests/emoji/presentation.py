#!/usr/bin/env python3
"""Production content in isolation; no clipboard or bus activation."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix="magi-emoji-ui-") as temporary:
    stage = Path(temporary)
    config = stage / "config"
    shutil.copytree(root / ".config/quickshell/magi", config)
    (config / "settings.json").write_text('{"schemaVersion":9}')
    runtime = stage / "runtime"
    runtime.mkdir(mode=0o700)
    env = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
               XDG_RUNTIME_DIR=str(runtime), XDG_STATE_HOME=str(stage / "state"))
    env.pop("WAYLAND_DISPLAY", None)
    env.pop("DISPLAY", None)
    binary = stage / "bin"
    binary.mkdir()
    copier = binary / "wl-copy"
    copier.write_text("#!/usr/bin/python3\nimport os,sys\nfrom pathlib import Path\npayload=sys.stdin.buffer.read()\nif os.environ.get('MAGI_COPY_FAIL'): sys.exit(1)\nwith Path(os.environ['MAGI_COPY_LOG']).open('ab') as f: f.write(payload+b'\\n')\n")
    copier.chmod(0o755)
    env["PATH"] = str(binary) + os.pathsep + env["PATH"]
    env["MAGI_COPY_LOG"] = str(stage / "copies")
    for name in ("content.qml", "settings.qml", "race.qml", "failure.qml"):
        (config / "settings.json").write_text('{"schemaVersion":9}')
        if name == "failure.qml": env["MAGI_COPY_FAIL"] = "1"
        (config / "test.qml").write_text(Path(__file__).with_name(name).read_text()
            .replace("../../.config/quickshell/magi/", ""))
        try:
            result = subprocess.run(["quickshell", "-p", str(config / "test.qml"), "--no-color"],
                                env=env, text=True, capture_output=True, timeout=10)
        except subprocess.TimeoutExpired as error:
            print(error.stdout, error.stderr)
            raise
        output = result.stdout + result.stderr
        print(output)
        checked = "\n".join(line for line in output.splitlines()
                            if "Failed to start IPC server" not in line
                            and "This plugin does not support setting window masks" not in line)
        assert result.returncode == 0 and "PASS" in output and "ERROR" not in checked and "WARN" not in checked
    assert (stage / "copies").read_bytes().splitlines() == ["👩🏽‍💻".encode(), "🔥".encode(), "🔥".encode(), "🔥".encode()]
    print("Exact UTF-8 process stdin handoff PASS")
