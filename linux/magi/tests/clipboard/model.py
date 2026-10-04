#!/usr/bin/env python3
"""Synthetic tests only. Never touches the session clipboard or user store."""
import struct
import zlib
import importlib.util
from pathlib import Path
import tempfile
import unittest
import sys
import contextlib
import io
import json
from unittest.mock import patch
sys.dont_write_bytecode = True

SOURCE = Path(__file__).resolve().parents[2] / ".config/quickshell/magi/services/clipboard_backend.py"
spec = importlib.util.spec_from_file_location("clipboard_backend", SOURCE)
backend = importlib.util.module_from_spec(spec)
spec.loader.exec_module(backend)
def png_chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))


PNG = (b"\x89PNG\r\n\x1a\n" + png_chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0))
       + png_chunk(b"IDAT", zlib.compress(b"\x00\x80\xa0\xff")) + png_chunk(b"IEND", b""))


class Model(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.history = backend.History(self.root / "runtime", self.root / "data", {"historyLimit": 10})

    def tearDown(self):
        self.history.close()
        self.temp.cleanup()

    def add(self, text):
        return self.history.ingest("text/plain", text.encode())

    def test_text_identity_search_delete(self):
        first = self.add("safe alpha\nBeta")
        self.add("second")
        self.assertEqual(self.add("safe alpha\nBeta"), first)
        self.assertEqual(len(self.history.entries), 2)
        self.assertEqual(self.history.rows()[0]["id"], first)
        self.assertEqual(len(self.history.rows("ALPHA beta")), 1)
        self.assertEqual(self.history.rows("missing"), [])
        self.assertNotIn("payload", self.history.rows()[0])
        self.assertNotIn("hash", self.history.rows()[0])
        self.history.remove(first)
        self.assertIsNone(self.history.get(first))

    def test_bounded_pins_and_clear(self):
        pinned = self.add("pinned")
        self.history.pin(pinned)
        for i in range(20):
            self.add(f"sample {i}")
        self.assertEqual(len(self.history.entries), 10)
        self.assertTrue(self.history.get(pinned)["pinned"])
        self.history.clear()
        self.assertEqual(len(self.history.entries), 1)
        self.history.pin(pinned)
        self.history.clear()
        self.assertFalse(self.history.entries)

    def test_full_pinned_history_rejects_new(self):
        for i in range(10):
            self.history.pin(self.add(f"pin {i}"))
        self.assertIsNone(self.add("unretainable"))
        self.assertEqual(len(self.history.entries), 10)
        self.history.clear(all_entries=True)
        self.assertFalse(self.history.entries)

    def test_html_plain_and_uri_not_opened(self):
        ident = self.history.ingest("text/html", b"<p>Harmless &amp; plain</p><script>hidden()</script>")
        entry = self.history.get(ident)
        self.assertEqual(entry["payload"], b"Harmless & plain")
        self.assertEqual(entry["mime"], "text/plain;charset=utf-8")
        ident = self.history.ingest("text/uri-list", b"file:///not/a/real/file\r\nhttps://example.invalid/\r\n")
        self.assertEqual(self.history.get(ident)["category"], "files")
        self.history.configure({"includeFiles": False})
        self.assertIsNone(self.history.ingest("text/uri-list", b"file:///ignored"))

    def test_invalid_and_disabled(self):
        self.assertIsNone(self.history.ingest("application/octet-stream", b"stuff"))
        with self.assertRaises(UnicodeError):
            self.history.ingest("text/plain", b"\xff\x00")
        self.assertIsNone(self.history.ingest("text/plain", b"a\x00b"))
        self.assertIsNone(self.history.ingest("text/plain", b"a" * (backend.MAX_TEXT + 1)))
        self.history.configure({"enabled": False})
        self.assertIsNone(self.add("ignored"))

    def test_image_cleanup_and_limits(self):
        ident = self.history.ingest("image/png", PNG)
        entry = self.history.get(ident)
        self.assertEqual(entry["dimensions"], [1, 1])
        path = self.history.runtime / (entry["hash"] + ".png")
        self.assertTrue(path.exists())
        self.history.remove(ident)
        self.assertFalse(path.exists())
        with self.assertRaises(ValueError):
            self.history.ingest("image/png", b"not an image")
        self.assertFalse(list(self.history.runtime.glob("*.png")))

    def test_image_eviction_and_persisted_cleanup(self):
        ident = self.history.ingest("image/png", PNG)
        self.history.configure({"persistHistory": True, "historyLimit": 10})
        for i in range(12):
            self.add(f"eviction fixture {i}")
        self.assertIsNone(self.history.get(ident))
        self.assertFalse(list(self.history.runtime.glob("*.png")))
        self.history.clear(all_entries=True)
        other = backend.History(self.root / "restored", self.root / "data", {"persistHistory": True})
        self.assertFalse(other.entries)
        other.close()

    def test_persistence_opt_in_and_off_cleanup(self):
        ident = self.add("deliberately persisted fixture")
        self.history.pin(ident)
        self.assertFalse((self.root / "data/history.sqlite3").exists())
        self.history.configure({"persistHistory": True})
        database = self.root / "data/history.sqlite3"
        self.assertEqual(database.stat().st_mode & 0o777, 0o600)
        other = backend.History(self.root / "runtime2", self.root / "data", {"persistHistory": True})
        self.assertEqual(other.rows()[0]["id"], ident)
        self.assertTrue(other.rows()[0]["pinned"])
        other.close()
        self.history.configure({"persistHistory": False})
        self.assertFalse(database.exists())
        other = backend.History(self.root / "runtime3", self.root / "data")
        self.assertEqual(other.rows(), [])
        other.close()

    def test_settings_and_bytes(self):
        self.assertEqual(backend.preferences({"historyLimit": 100000, "enabled": "yes"}), backend.DEFAULTS)
        ident = self.add("first")
        self.history.pin(ident)
        previous = backend.MAX_TOTAL
        try:
            backend.MAX_TOTAL = 10
            self.add("second")
            self.add("third")
            self.assertLessEqual(sum(e["size"] for e in self.history.entries), 10)
            self.assertIsNotNone(self.history.get(ident))
        finally:
            backend.MAX_TOTAL = previous

    def test_worker_search_and_restore_boundary(self):
        ident = self.add("safe literal $(not-a-command)")
        worker = backend.Worker(self.history, None)
        with contextlib.redirect_stdout(io.StringIO()) as output:
            worker.command({"op": "search", "query": "literal"})
        response = json.loads(output.getvalue())
        self.assertEqual(response["query"], "literal")
        self.assertEqual(response["rows"][0]["id"], ident)
        with patch.object(backend.subprocess, "run") as run:
            with contextlib.redirect_stdout(io.StringIO()):
                worker.command({"op": "restore", "id": ident})
            args, kwargs = run.call_args
            self.assertEqual(args[0], ["wl-copy", "--type", "text/plain;charset=utf-8"])
            self.assertEqual(kwargs["input"], b"safe literal $(not-a-command)")
            self.assertNotIn("shell", kwargs)


if __name__ == "__main__":
    unittest.main()
