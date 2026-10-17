#!/usr/bin/env python3
"""Real Hub window/content/controller, native wrapper substituted only offscreen."""
from pathlib import Path
import os, shutil, subprocess, tempfile
root = Path(__file__).resolve().parents[2]
source = root / ".config/quickshell/magi"
assert (source / "shell.qml").read_text().count("HubUI.HubWindow {") == 1
assert "SettingsWindow {" not in (source / "components/settings/SettingsApplication.qml").read_text()
assert "Loader {" not in (source / "components/settings/SettingsApplication.qml").read_text()
assert "exclusionMode: ExclusionMode.Ignore" in (source / "components/hub/HubWindow.qml").read_text()
assert "exclusiveZone:" not in (source / "components/hub/HubWindow.qml").read_text()
assert "exclusiveZone: fullSurface ? 48 : 0" in (source / "components/bar/Bar.qml").read_text()
launcher = (source / "components/launcher/LauncherContent.qml").read_text()
assert not any(value in launcher for value in ("backgroundEnabled", "backgroundImage", "Esc to close", "Enter to open", " applications  "))
for retired in ["launcher/LauncherWindow.qml", "emoji/EmojiWindow.qml", "clipboard/ClipboardWindow.qml", "notifications/NotificationCentre.qml"]:
    assert not (source / "components" / retired).exists(), retired
with tempfile.TemporaryDirectory(prefix="magi-hub-ui-") as tmp:
    stage = Path(tmp); config = stage / "config"
    shutil.copytree(root / ".config/quickshell/magi", config)
    (config / "test-artwork.ppm").write_bytes(b"P6\n120 40\n255\n" + bytes([0,255,255]) * 120 * 40)
    (config / "settings.json").write_text('{"schemaVersion":9}')
    path = config / "components/hub/HubWindow.qml"
    text = path.read_text().replace("PanelWindow {", "FloatingWindow {\n    implicitWidth: 1280; implicitHeight: 900")
    text = "\n".join(line for line in text.splitlines() if not any(token in line for token in ["anchors { top: true;", "exclusionMode:", "WlrLayershell."]))
    path.write_text(text)
    runtime = stage / "runtime"; runtime.mkdir(mode=0o700)
    env = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software", XDG_RUNTIME_DIR=str(runtime), XDG_STATE_HOME=str(stage / "state"), HOME=str(stage), XDG_CONFIG_HOME=str(stage / "xdg-config"), XDG_CACHE_HOME=str(stage / "cache"))
    env.pop("WAYLAND_DISPLAY", None); env.pop("DISPLAY", None)
    if env.get("MAGI_HUB_CAPTURES"):
        Path(env["MAGI_HUB_CAPTURES"]).mkdir(parents=True, exist_ok=True)
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
rows = [row, dict(row,id="hub-image",category="image",preview="picture",thumbnail=str(Path(__file__).parents[1]/"test-artwork.ppm")), dict(row,id="hub-files",category="files",preview="file:///harmless")]
query = ""
for line in sys.stdin:
    request = json.loads(line)
    if request.get("op") == "search": query = request["query"]
    if request.get("op") == "pin":
        for entry in rows:
            if entry["id"] == request["id"]: entry["pinned"] = not entry["pinned"]
    if request.get("op") == "delete": rows = [entry for entry in rows if entry["id"] != request["id"]]
    if request.get("op") == "clear": rows = [entry for entry in rows if entry["pinned"]]
    restored = request.get("op") == "restore"
    if restored: Path(os.environ["MAGI_RESTORE_LOG"]).write_text(request["id"])
    print(json.dumps({"query":query,"rows":[entry for entry in rows if query.lower() in entry["preview"].lower()],"count":len(rows),"monitoring":True,"restored":restored}),flush=True)
''')
    for fixture, marker in [("integration.qml", "Hub integration PASS"), ("pointer.qml", "Hub pointer selector"), ("actions.qml", "Hub actions PASS"), ("composition.qml", "Hub composition PASS"), ("notifications.qml", "Hub notification height PASS"), ("polish.qml", "Hub polish PASS")]:
        (config / "test.qml").write_text(Path(__file__).with_name(fixture).read_text().replace("../../.config/quickshell/magi/", ""))
        try:
            result = subprocess.run(["quickshell", "-p", str(config / "test.qml"), "--no-color"], env=env, capture_output=True, text=True, timeout=25)
        except subprocess.TimeoutExpired as error:
            print(error.stdout.decode() if isinstance(error.stdout, bytes) else error.stdout, flush=True)
            raise
        output = result.stdout + result.stderr; print(output)
        checked = "\n".join(line for line in output.splitlines() if "Failed to start IPC server" not in line and "This plugin does not support setting window masks" not in line and "Unable to find hyprland socket" not in line
            and "Could not connect to DBus. NetworkManager backend will not work." not in line
            and "Network will not work. Could not find an available backend." not in line
            and "Could not connect to DBus. Bluetooth integration is not available." not in line)
        assert result.returncode == 0 and marker in output and "ERROR" not in checked and "WARN" not in checked and "FAIL!" not in checked
    assert (stage / "copy").read_bytes() == "👩🏽‍💻".encode()
    assert (stage / "restore").read_text() == "hub-test"
    print("Hub exact UTF-8 copy and selected clipboard restore ID PASS")
