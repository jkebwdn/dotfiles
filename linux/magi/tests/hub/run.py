#!/usr/bin/env python3
"""Real Hub window/content/controller, native wrapper substituted only offscreen."""
from pathlib import Path
import os, shutil, subprocess, tempfile
root = Path(__file__).resolve().parents[2]
source = root / ".config/quickshell/magi"
assert (source / "shell.qml").read_text().count("HubUI.HubWindow {") == 1
for retired in ["launcher/LauncherWindow.qml", "emoji/EmojiWindow.qml", "clipboard/ClipboardWindow.qml", "notifications/NotificationCentre.qml"]:
    assert not (source / "components" / retired).exists(), retired
with tempfile.TemporaryDirectory(prefix="magi-hub-ui-") as tmp:
    stage = Path(tmp); config = stage / "config"
    shutil.copytree(root / ".config/quickshell/magi", config)
    (config / "settings.json").write_text('{"schemaVersion":9}')
    path = config / "components/hub/HubWindow.qml"
    text = path.read_text().replace("PanelWindow {", "FloatingWindow {\n    implicitWidth: 1280; implicitHeight: 900")
    text = "\n".join(line for line in text.splitlines() if not any(token in line for token in ["anchors { top: true;", "exclusionMode:", "WlrLayershell."]))
    path.write_text(text)
    runtime = stage / "runtime"; runtime.mkdir(mode=0o700)
    env = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software", XDG_RUNTIME_DIR=str(runtime), XDG_STATE_HOME=str(stage / "state"))
    env.pop("WAYLAND_DISPLAY", None); env.pop("DISPLAY", None)
    # Isolate desktop discovery and external copy/capture effects. Emoji uses its
    # real helper; only wl-copy is replaced. Clipboard transport is synthetic;
    # backend MIME/restore correctness remains in its existing focused suite.
    binary = stage / "bin"; binary.mkdir()
    copier = binary / "wl-copy"
    copier.write_text("#!/usr/bin/python3\nimport os,sys\nfrom pathlib import Path\nPath(os.environ['MAGI_COPY_LOG']).write_bytes(sys.stdin.buffer.read())\n")
    copier.chmod(0o755)
    env["PATH"] = str(binary) + os.pathsep + env["PATH"]
    env["MAGI_COPY_LOG"] = str(stage / "copy")
    env["MAGI_RESTORE_LOG"] = str(stage / "restore")
    applications = stage / "data/applications"; applications.mkdir(parents=True)
    (applications / "magi-hub-fixture.desktop").write_text("[Desktop Entry]\nType=Application\nName=MAGI Hub launch fixture\nExec=/usr/bin/true\n")
    env["XDG_DATA_HOME"] = str(applications.parent)
    env["XDG_DATA_DIRS"] = str(stage / "empty-data")
    service = config / "services/Clipboard.qml"
    service.write_text(service.read_text().replace('"clipboard_backend.py"', '"hub_clipboard_fixture.py"'))
    (config / "services/hub_clipboard_fixture.py").write_text('''import json,os,sys
from pathlib import Path
row = {"id":"hub-test", "category":"text", "preview":"hub sample", "timestamp":1, "pinned":False, "thumbnail":""}
query = ""
for line in sys.stdin:
    request = json.loads(line)
    if request.get("op") == "search": query = request["query"]
    restored = request.get("op") == "restore"
    if restored: Path(os.environ["MAGI_RESTORE_LOG"]).write_text(request["id"])
    print(json.dumps({"query":query,"rows":[row],"count":1,"monitoring":True,"restored":restored}),flush=True)
''')
    for fixture, marker in [("integration.qml", "Hub integration PASS"), ("pointer.qml", "Hub pointer selector"), ("actions.qml", "Hub actions PASS")]:
        (config / "test.qml").write_text(Path(__file__).with_name(fixture).read_text().replace("../../.config/quickshell/magi/", ""))
        result = subprocess.run(["quickshell", "-p", str(config / "test.qml"), "--no-color"], env=env, capture_output=True, text=True, timeout=15)
        output = result.stdout + result.stderr; print(output)
        checked = "\n".join(line for line in output.splitlines() if "Failed to start IPC server" not in line and "This plugin does not support setting window masks" not in line)
        assert result.returncode == 0 and marker in output and "ERROR" not in checked and "WARN" not in checked
    assert (stage / "copy").read_bytes() == "👩🏽‍💻".encode()
    assert (stage / "restore").read_text() == "hub-test"
    print("Hub exact UTF-8 copy and selected clipboard restore ID PASS")
