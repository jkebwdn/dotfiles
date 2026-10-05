"""No session clipboard access: generator and shared handoff tests."""
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch
sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
def module(name, path):
    spec = importlib.util.spec_from_file_location(name, ROOT / path)
    result = importlib.util.module_from_spec(spec); spec.loader.exec_module(result)
    return result
backend = module('clipboard', '.config/quickshell/magi/services/clipboard_backend.py')
generator = module('generator', 'tools/generate_emoji.py')
class Emoji(unittest.TestCase):
    def test_parser(self):
        source = '# group: Smileys & Emotion\n# subgroup: face-smiling\n263A FE0F ; fully-qualified # ☺️ E0.6 smiling face\n263A ; unqualified # ☺ E0.6 smiling face\n'
        rows = generator.parse(source)
        self.assertEqual(len(rows), 1); self.assertEqual(rows[0]['emoji'], '☺️')
        self.assertEqual(rows[0]['id'], '263A-FE0F')
        for bad in ['', 'bad', source + source, source.replace('☺️','x')]:
            with self.assertRaises(ValueError): generator.parse(bad)
        with self.assertRaises(ValueError): generator.generate(b'not pinned data')
    def test_exact_copy(self):
        for text in ['🔥','❤️','👍🏽','👩🏽‍💻','👨‍👩‍👧‍👦','🇬🇧']:
            with patch.object(backend.subprocess, 'run') as copy:
                backend.copy_text_request(io.StringIO(json.dumps({'text':text})+'\n'))
                args, kwargs = copy.call_args
                self.assertEqual(args[0], ['wl-copy','--type','text/plain;charset=utf-8'])
                self.assertEqual(kwargs['input'], text.encode('utf-8'))
                self.assertEqual(kwargs['timeout'],3); self.assertTrue(kwargs['check'])
    def test_failure(self):
        with patch.object(backend.subprocess,'run', side_effect=subprocess.TimeoutExpired('wl-copy',3)):
            with self.assertRaises(subprocess.TimeoutExpired): backend.copy_text_request(io.StringIO('{"text":"🔥"}'))
        for value in ['', None, 1, 'a'*9000, '\0']:
            with self.assertRaises(ValueError): backend.copy_text_request(io.StringIO(json.dumps({'text':value})))
if __name__ == '__main__': unittest.main()
