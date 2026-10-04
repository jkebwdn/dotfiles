#!/usr/bin/env python3
"""MAGI clipboard model and JSON-lines worker. Never log sender data."""
import hashlib
import html.parser
import json
import os
from pathlib import Path
import queue
import signal
import sqlite3
import subprocess
import sys
import tempfile
import threading
import time
import uuid
import fcntl

MAX_ITEM = 8 * 1024 * 1024
MAX_TEXT = 256 * 1024
MAX_TOTAL = 64 * 1024 * 1024
DEFAULTS = dict(enabled=True, historyLimit=100, persistHistory=False,
                includeImages=True, includeFiles=True)


def preferences(raw):
    result = dict(DEFAULTS)
    for key, default in DEFAULTS.items():
        value = raw.get(key, default)
        if key == "historyLimit":
            if type(value) is int and 10 <= value <= 200:
                result[key] = value
        elif type(value) is bool:
            result[key] = value
    return result


class PlainHTML(html.parser.HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.parts = []
        self.hidden = 0

    def handle_starttag(self, tag, attrs):
        if tag in ("script", "style", "template"):
            self.hidden += 1
        if tag in ("br", "p", "div", "li", "tr") and not self.hidden:
            self.parts.append("\n")

    def handle_endtag(self, tag):
        if tag in ("script", "style", "template") and self.hidden:
            self.hidden -= 1

    def handle_data(self, data):
        if not self.hidden:
            self.parts.append(data)


def image_preview(payload, mime, target):
    import gi
    gi.require_version("GdkPixbuf", "2.0")
    from gi.repository import GdkPixbuf
    loader = GdkPixbuf.PixbufLoader.new_with_mime_type(mime)
    dimensions = []

    def size_prepared(source, width, height):
        dimensions.extend([width, height])
        # Bound decode size even for a rejected decompression bomb.
        scale = min(1.0, 280 / max(width, height))
        source.set_size(max(1, int(width * scale)), max(1, int(height * scale)))

    loader.connect("size-prepared", size_prepared)
    try:
        loader.write(payload)
        loader.close()
        if len(dimensions) != 2 or not 0 < dimensions[0] * dimensions[1] <= 16000000:
            raise ValueError("Image dimensions exceed limit")
        pixbuf = loader.get_pixbuf()
        if pixbuf is None:
            raise ValueError("Invalid image")
        pixbuf.savev(str(target), "png", [], [])
        os.chmod(target, 0o600)
        return dimensions
    except Exception:
        target.unlink(missing_ok=True)
        raise ValueError("Image unavailable or exceeds limits") from None


class History:
    def __init__(self, runtime, storage, config=None):
        self.runtime, self.storage = Path(runtime), Path(storage)
        self.runtime.mkdir(mode=0o700, parents=True, exist_ok=True)
        self.entries = []
        self.config = preferences(config or {})
        self.db = None
        if self.config["persistHistory"]:
            self.load()
        else:
            self.erase_disk()

    def database(self):
        if self.storage.is_symlink():
            raise ValueError("Unsafe history directory")
        self.storage.mkdir(mode=0o700, parents=True, exist_ok=True)
        os.chmod(self.storage, 0o700)
        path = self.storage / "history.sqlite3"
        if path.is_symlink():
            raise ValueError("Unsafe history path")
        connection = sqlite3.connect(path)
        os.chmod(path, 0o600)
        connection.execute("PRAGMA secure_delete=ON")
        version = connection.execute("PRAGMA user_version").fetchone()[0]
        if version not in (0, 1):
            connection.close()
            raise ValueError("History version unsupported")
        connection.execute("CREATE TABLE IF NOT EXISTS entries (id TEXT PRIMARY KEY, mime TEXT, stamp REAL, pinned INTEGER, payload BLOB)")
        connection.execute("PRAGMA user_version=1")
        return connection

    def load(self):
        self.db = self.database()
        # Never allocate an unbounded corrupted/foreign database payload.
        rows = self.db.execute("SELECT id,mime,stamp,pinned,payload FROM entries WHERE length(payload)<=? ORDER BY pinned DESC,stamp DESC LIMIT 200", (MAX_ITEM,))
        for ident, mime, stamp, pinned, payload in rows:
            if not isinstance(ident, str) or len(ident) != 32 or any(c not in "0123456789abcdef" for c in ident):
                continue
            if not isinstance(stamp, (float, int)) or not 0 < stamp < 1e12:
                continue
            try:
                entry = self.prepare(mime, payload)
                if entry and not any(e["hash"] == entry["hash"] for e in self.entries):
                    entry.update(id=ident, timestamp=stamp, pinned=bool(pinned))
                    self.entries.append(entry)
            except (ValueError, TypeError, UnicodeError):
                continue
            if sum(len(e["payload"]) for e in self.entries) >= MAX_TOTAL:
                break
        self.trim()
        self.save()

    def save(self):
        if not self.config["persistHistory"]:
            return
        if self.db is None:
            self.db = self.database()
        with self.db:
            self.db.execute("DELETE FROM entries")
            self.db.executemany("INSERT INTO entries VALUES (?,?,?,?,?)", [
                (e["id"], e["mime"], e["timestamp"], int(e["pinned"]), e["payload"]) for e in self.entries])

    def erase_disk(self):
        if self.db is not None:
            self.db.close()
            self.db = None
        # Exact MAGI-owned files only, never traverse arbitrary paths.
        for name in ("history.sqlite3", "history.sqlite3-journal", "history.sqlite3-wal", "history.sqlite3-shm"):
            (self.storage / name).unlink(missing_ok=True)

    def configure(self, raw):
        old = self.config
        self.config = preferences(raw)
        if old["persistHistory"] and not self.config["persistHistory"]:
            self.erase_disk()
        self.trim()
        self.save()

    def prepare(self, mime, payload):
        if not isinstance(payload, bytes) or not 0 < len(payload) <= MAX_ITEM:
            return None
        text, thumb, dimensions = "", "", []
        if mime in ("text/plain", "text/plain;charset=utf-8", "UTF8_STRING", "text/html", "text/uri-list"):
            if len(payload) > MAX_TEXT:
                return None
            text = payload.decode("utf-8")
            if "\x00" in text:
                return None
            category = "files" if mime == "text/uri-list" else "text"
            if category == "files" and not self.config["includeFiles"]:
                return None
            if mime == "text/html":
                parser = PlainHTML()
                parser.feed(text)
                text = "".join(parser.parts).strip()
                payload = text.encode("utf-8")
            if category == "text":
                mime = "text/plain;charset=utf-8"
            if not text.strip():
                return None
        elif mime in ("image/png", "image/jpeg") and self.config["includeImages"]:
            category = "image"
        else:
            return None
        digest = hashlib.sha256(mime.encode() + b"\0" + payload).hexdigest()
        if category == "image":
            path = self.runtime / (digest + ".png")
            dimensions = image_preview(payload, mime, path)
            thumb = path.as_uri()
            text = f"{dimensions[0]} × {dimensions[1]} · {mime.removeprefix('image/').upper()}"
        return dict(id=uuid.uuid4().hex, mime=mime, category=category,
                    timestamp=time.time(), preview=text[:600], text=text,
                    thumbnail=thumb, dimensions=dimensions, hash=digest,
                    payload=payload, pinned=False, size=len(payload))

    def trim(self):
        # Pinning cannot bypass the configured count or global byte budget.
        ordered = sorted(self.entries, key=lambda e: e["timestamp"], reverse=True)
        for e in [x for x in ordered if x["pinned"]][min(50, self.config["historyLimit"]):]:
            e["pinned"] = False
        while len(self.entries) > self.config["historyLimit"] or sum(e["size"] for e in self.entries) > MAX_TOTAL:
            candidates = [e for e in self.entries if not e["pinned"]]
            if not candidates:
                candidates = self.entries
            self.remove(min(candidates, key=lambda e: e["timestamp"])["id"], save=False)

    def ingest(self, mime, payload):
        if not self.config["enabled"]:
            return None
        entry = self.prepare(mime, payload)
        if not entry:
            return None
        previous = next((e for e in self.entries if e["hash"] == entry["hash"]), None)
        if previous:
            previous["timestamp"] = time.time()
            entry = previous
        else:
            self.entries.append(entry)
        self.trim()
        self.save()
        return entry["id"] if entry in self.entries else None

    def get(self, ident):
        return next((e for e in self.entries if e["id"] == ident), None)

    def pin(self, ident):
        entry = self.get(ident)
        if entry:
            if not entry["pinned"] and sum(e["pinned"] for e in self.entries) >= min(50, self.config["historyLimit"]):
                raise ValueError("Pin limit reached")
            entry["pinned"] = not entry["pinned"]
            self.save()

    def remove(self, ident, save=True):
        entry = self.get(ident)
        if entry:
            self.entries.remove(entry)
            if entry["thumbnail"]:
                (self.runtime / (entry["hash"] + ".png")).unlink(missing_ok=True)
            if save:
                self.save()

    def clear(self, all_entries=False):
        for entry in self.entries[:]:
            if all_entries or not entry["pinned"]:
                self.remove(entry["id"], save=False)
        self.save()

    def rows(self, query=""):
        terms = query.casefold().split()
        entries = sorted(self.entries, key=lambda e: (e["pinned"], e["timestamp"]), reverse=True)
        return [{k: v for k, v in e.items() if k not in ("payload", "text", "hash")}
                for e in entries if all(t in e["text"].casefold() for t in terms)]

    def close(self):
        if self.db:
            self.db.close()
        for path in self.runtime.glob("*.png"):
            path.unlink()


def build_capture(cache):
    source = Path(__file__).with_name("clipboard_capture.c")
    xml = Path("/usr/share/wayland-protocols/staging/ext-data-control/ext-data-control-v1.xml")
    digest = hashlib.sha256(source.read_bytes() + xml.read_bytes()).hexdigest()[:20]
    cache.mkdir(mode=0o700, parents=True, exist_ok=True)
    executable = cache / ("capture-" + digest)
    if not executable.exists():
        with tempfile.TemporaryDirectory(dir=cache) as directory:
            directory = Path(directory)
            subprocess.run(["wayland-scanner", "client-header", str(xml), str(directory / "data-control.h")], check=True, capture_output=True)
            subprocess.run(["wayland-scanner", "private-code", str(xml), str(directory / "data-control.c")], check=True, capture_output=True)
            subprocess.run(["cc", "-O2", "-Wall", "-Wextra", "-Werror", "-I" + str(directory), str(source), str(directory / "data-control.c"), "-lwayland-client", "-o", str(directory / "capture")], check=True, capture_output=True)
            os.replace(directory / "capture", executable)
    return executable


class Worker:
    def __init__(self, history, capture):
        self.history, self.capture = history, capture
        self.events = queue.Queue(maxsize=4)
        self.reader = None
        self.generation = 0
        self.query = ""
        self.monitoring = False

    def emit(self, **extra):
        print(json.dumps(dict(type="state", query=self.query, rows=self.history.rows(self.query),
                              count=len(self.history.entries), monitoring=self.monitoring, **extra)), flush=True)

    def watch(self):
        self.generation += 1
        generation = self.generation
        if self.reader:
            self.reader.terminate()
            self.reader.wait(timeout=3)
            self.reader = None
        self.monitoring = False
        if not self.history.config["enabled"]:
            return
        args = [str(self.capture)]
        if self.history.config["includeImages"]:
            args.append("--images")
        if self.history.config["includeFiles"]:
            args.append("--files")
        self.reader = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        process = self.reader

        def read():
            try:
                while True:
                    mime = process.stdout.readline(128).decode("ascii").strip()
                    if not mime:
                        break
                    size = int(process.stdout.readline(32))
                    if not 0 <= size <= MAX_ITEM:
                        break
                    payload = process.stdout.read(size)
                    if len(payload) != size:
                        break
                    self.events.put((generation, mime, payload))
            finally:
                process.stdout.close()
                self.events.put((generation, "stopped", b""))

        threading.Thread(target=read, daemon=True).start()

    def command(self, command):
        op = command.get("op")
        if op == "configure":
            old = self.history.config
            self.history.configure(command.get("preferences", {}))
            if any(old[k] != self.history.config[k] for k in ("enabled", "includeImages", "includeFiles")):
                self.watch()
        elif op == "search":
            self.query = str(command.get("query", ""))[:512]
        elif op == "pin":
            self.history.pin(command.get("id"))
        elif op == "delete":
            self.history.remove(command.get("id"))
        elif op == "clear":
            self.history.clear()
        elif op == "erase":
            self.history.clear(all_entries=True)
        elif op == "restore":
            entry = self.history.get(command.get("id"))
            if not entry:
                raise ValueError("Entry no longer available")
            subprocess.run(["wl-copy", "--type", entry["mime"]], input=entry["payload"],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=3, check=True)
            entry["timestamp"] = time.time()
            self.history.save()
            self.emit(restored=True)
            return
        self.emit()

    def run(self):
        commands = queue.Queue(maxsize=16)

        def read_commands():
            for line in sys.stdin:
                if len(line) > 16384:
                    continue
                try:
                    commands.put(json.loads(line))
                except ValueError:
                    pass
            commands.put(None)

        threading.Thread(target=read_commands, daemon=True).start()
        self.watch()
        self.emit()
        try:
            while True:
                try:
                    command = commands.get(timeout=0.03)
                    if command is None:
                        break
                    try:
                        self.command(command)
                    except Exception:
                        self.emit(error="Clipboard operation failed; check storage or entry limits.")
                except queue.Empty:
                    pass
                try:
                    generation, mime, payload = self.events.get_nowait()
                    if generation != self.generation:
                        continue
                    if mime == "ready":
                        self.monitoring = True
                        self.emit()
                    elif mime == "stopped":
                        self.monitoring = False
                        self.emit(error="Clipboard capture stopped. Re-enable history to retry.")
                    else:
                        try:
                            self.history.ingest(mime, payload)
                            self.emit()
                        except Exception:
                            # Invalid/unreasonably large offers are ignored, without data/error logging.
                            pass
                except queue.Empty:
                    pass
        finally:
            if self.reader:
                self.reader.terminate()
                self.reader.wait(timeout=3)
            self.history.close()


def main():
    os.umask(0o077)
    runtime = Path(os.environ["XDG_RUNTIME_DIR"]) / "magi-clipboard"
    runtime.mkdir(mode=0o700, exist_ok=True)
    if runtime.is_symlink() or runtime.stat().st_uid != os.getuid():
        raise ValueError("Unsafe runtime directory")
    os.chmod(runtime, 0o700)
    lock = (runtime / "lock").open("a")
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    for path in runtime.glob("*.png"):
        path.unlink()
    config = json.loads(sys.stdin.readline(16384)).get("preferences", {})
    cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "magi/clipboard"
    storage = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "magi/clipboard"
    capture = build_capture(cache)
    history = History(runtime, storage, config)
    def stop(_signum, _frame):
        raise SystemExit(0)
    signal.signal(signal.SIGTERM, stop)
    Worker(history, capture).run()


if __name__ == "__main__":
    try:
        main()
    except Exception:
        print(json.dumps(dict(type="state", rows=[], count=0, monitoring=False,
                              error="Clipboard backend unavailable (dependencies, permissions or storage).")), flush=True)
        sys.exit(1)
