#!/usr/bin/env python3
"""Run the production Icon component in an isolated temporary config."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


root = Path(__file__).resolve().parents[2]
source = root / ".config/quickshell/magi"
fixture = Path(__file__).with_name("shell.qml").read_text()
fixture = fixture.replace(
    'import "../../.config/quickshell/magi/components/controls" as Controls',
    'import "components/controls" as Controls',
).replace(
    'import "../../.config/quickshell/magi/icons" as Icons',
    'import "icons" as Icons',
).replace(
    'import "../../.config/quickshell/magi/theme" as Theme',
    'import "theme" as Theme',
)

with tempfile.TemporaryDirectory(prefix="magi-icon-fixture-") as temporary:
    config = Path(temporary) / "config"
    shutil.copytree(source, config)
    settings_path = config / "settings.json"
    settings = json.loads(settings_path.read_text())
    settings["appearance"]["theme"] = "catppuccin-mocha"
    settings["icons"]["pack"] = "magi-default"
    settings_path.write_text(json.dumps(settings, indent=2) + "\n")
    (config / "shell.qml").write_text(fixture)
    environment = dict(os.environ)
    subprocess.run(["quickshell", "-p", str(config / "shell.qml")],
                   env=environment, check=False)
