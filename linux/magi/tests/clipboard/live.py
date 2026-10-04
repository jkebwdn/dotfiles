#!/usr/bin/env python3
"""Explicit live protocol test; replaces clipboard with synthetic samples only.

Never reads the initial clipboard. Uses disposable MAGI history/runtime storage.
Run only during an approved live checkpoint, before production capture activation.
"""
import argparse
import json
import os
from pathlib import Path
import queue
import runpy
import subprocess
import tempfile
import threading
import time

parser = argparse.ArgumentParser()
parser.add_argument("--replace-clipboard", action="store_true", required=True)
parser.parse_args()
root = Path(__file__).resolve().parents[2]
fixture = runpy.run_path(str(Path(__file__).with_name("model.py")))
with tempfile.TemporaryDirectory(prefix="magi-clipboard-live-") as temp:
    stage = Path(temp)
    runtime = stage / "runtime"
    runtime.mkdir(mode=0o700)
    display = str(Path(os.environ["XDG_RUNTIME_DIR"]) / os.environ["WAYLAND_DISPLAY"])
    env = dict(os.environ, XDG_RUNTIME_DIR=str(runtime), WAYLAND_DISPLAY=display,
               XDG_DATA_HOME=str(stage / "data"), XDG_CACHE_HOME=str(stage / "cache"))
    worker = subprocess.Popen(["python3", str(root / ".config/quickshell/magi/services/clipboard_backend.py")],
                              stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                              text=True, env=env)
    messages = queue.Queue()

    def reader():
        for line in worker.stdout:
            messages.put(json.loads(line))

    threading.Thread(target=reader, daemon=True).start()

    def send(**command):
        worker.stdin.write(json.dumps(command) + "\n")
        worker.stdin.flush()

    def wait(predicate, timeout=5):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            try:
                state = messages.get(timeout=deadline - time.monotonic())
            except queue.Empty:
                break
            if state.get("error"):
                raise AssertionError(state["error"])
            if predicate(state):
                return state
        raise AssertionError("Clipboard checkpoint timeout (payload omitted)")

    def copy(mime, data, sensitive=False):
        command = ["wl-copy", "--type", mime] + (["--sensitive"] if sensitive else [])
        subprocess.run(command, input=data, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True, timeout=4)

    try:
        send(preferences={})
        state = wait(lambda s: s["monitoring"])
        assert state["count"] == 0, "Initial offer must not be captured"
        copy("text/plain", b"MAGI harmless alpha")
        state = wait(lambda s: s["count"] == 1)
        first = state["rows"][0]["id"]
        copy("text/plain", b"MAGI harmless beta")
        wait(lambda s: s["count"] == 2)
        copy("text/plain", b"MAGI harmless alpha")
        state = wait(lambda s: s["rows"][0]["id"] == first)
        assert state["count"] == 2
        copy("text/plain", b"MAGI synthetic sensitive sample", sensitive=True)
        time.sleep(.25)
        send(op="search", query="")
        assert wait(lambda s: True)["count"] == 2
        copy("text/html", b"<b>MAGI HTML sample</b>")
        state = wait(lambda s: s["count"] == 3)
        # wl-copy may advertise a plain-text alias for its HTML bytes. Prefer an
        # actual offered plain representation; HTML-only conversion is model-tested.
        assert state["rows"][0]["preview"] in ("MAGI HTML sample", "<b>MAGI HTML sample</b>")
        assert state["rows"][0]["mime"] == "text/plain;charset=utf-8"
        copy("image/png", fixture["PNG"])
        state = wait(lambda s: s["count"] == 4)
        assert state["rows"][0]["dimensions"] == [1, 1]
        copy("text/uri-list", b"file:///tmp/MAGI-deliberately-nonexistent.txt\r\n")
        state = wait(lambda s: s["count"] == 5)
        assert state["rows"][0]["category"] == "files"
        send(op="pin", id=first)
        wait(lambda s: s["rows"][0]["pinned"])
        send(op="clear")
        state = wait(lambda s: s["count"] == 1)
        assert state["rows"][0]["id"] == first
        send(op="restore", id=first)
        wait(lambda s: s.get("restored"))
        # This reads only the deliberately restored harmless test entry.
        pasted = subprocess.check_output(["wl-paste", "--no-newline", "--type", "text/plain;charset=utf-8"], timeout=3)
        assert pasted == b"MAGI harmless alpha", "Restore mismatch (payload omitted)"
        send(op="configure", preferences={"enabled": False})
        wait(lambda s: not s["monitoring"])
        copy("text/plain", b"MAGI paused harmless sample")
        send(op="configure", preferences={"enabled": True})
        state = wait(lambda s: s["monitoring"])
        assert state["count"] == 1, "Re-enable must skip existing selection"
        send(op="erase")
        wait(lambda s: s["count"] == 0)
        print("Live clipboard: initial skip, text, promotion, sensitive hint, HTML, PNG, URI, pin/clear, restore, pause/re-enable PASS")
    finally:
        worker.stdin.close()
        worker.wait(timeout=5)
    assert not list(runtime.rglob("*.png")), "Runtime image cleanup"
    assert not list(stage.rglob("history.sqlite3")), "Memory-only capture must not persist"
    print("Live clipboard: no history database; runtime thumbnails cleaned PASS")
