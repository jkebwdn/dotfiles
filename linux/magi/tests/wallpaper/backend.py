#!/usr/bin/env python3
"""Filesystem, persistence and renderer transaction tests; never contacts desktop."""
import copy
import json
from pathlib import Path
import sys
import tempfile
import subprocess
import unittest
from unittest.mock import patch
sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / '.config/quickshell/magi/services'))
import wallpaper_library as library
import wallpaper_backend as backend
import wallpaper_state as state


class WallpaperTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.library = self.base / 'images'; self.library.mkdir()
        self.image = self.library / 'one image.png'; self.image.write_bytes(b'\x89PNG\r\n\x1a\nheader')
        self.second = self.library / 'two.jpg'; self.second.write_bytes(b'\xff\xd8\xffheader')
        self.file = self.base / 'state.json'
        self.monitors = [{'name':'DP-3','description':'Display A'}, {'name':'eDP-2','description':'Display B'}]
        self.active = {m['name']:str(self.image) for m in self.monitors}
        self.calls = []
        def apply(monitor, path, mode):
            self.calls.append((monitor, path, mode)); self.active[monitor] = path
        self.addCleanup(patch.stopall)
        patch.object(backend, 'monitors', lambda: self.monitors).start()
        patch.object(backend, 'active', lambda: dict(self.active)).start()
        patch.object(backend, 'apply', apply).start()

    def test_library(self):
        (self.library / 'alias.png').symlink_to(self.image)
        (self.library / 'broken.jpg').symlink_to(self.base / 'gone')
        (self.library / 'text.png').write_text('not an image')
        (self.library / 'text.txt').write_text('not an image')
        (self.library / 'web.webp').write_bytes(b'RIFF0000WEBP')
        (self.library / 'sub').mkdir()
        (self.library / 'sub/cycle').symlink_to(self.library)
        (self.library / 'sub/deep.png').write_bytes(self.image.read_bytes())
        out = library.scan([str(self.library), str(self.library), str(self.base / 'missing')])
        self.assertEqual(len(out['entries']), 2)
        self.assertEqual(len(out['warnings']), 1)
        self.assertTrue(all(e['url'].startswith('file:///') for e in out['entries']))
        for value in [['relative'], ['/bad\npath'], ['/tmp'] * 17, 'not a list']:
            with self.assertRaises(ValueError): library.roots(value)
        self.assertEqual(library.roots([]), [])

    def test_command(self):
        self.assertEqual(backend.command('DP-3', '/a/a $(touch x).png', 'contain'),
            ['hyprctl','hyprpaper','wallpaper','DP-3,/a/a $(touch x).png,contain'])
        for path, mode in [('/a,b.png','cover'), ('/ok.png','invented'), ('relative','cover'), ('/trailing ','cover')]:
            with self.assertRaises(ValueError): backend.command('DP-3', path, mode)

    def test_transport_errors(self):
        for response in [subprocess.CompletedProcess([], 1, 'denied', ''),
                         subprocess.CompletedProcess([], 0, 'error: rejected', '')]:
            with patch.object(subprocess, 'run', return_value=response):
                with self.assertRaises(RuntimeError): backend.run(['hyprctl'])
        with patch.object(subprocess, 'run', side_effect=subprocess.TimeoutExpired('hyprctl', 5)):
            with self.assertRaises(RuntimeError): backend.run(['hyprctl'])

    def test_missing_override_falls_back(self):
        saved = state.empty()
        saved['shared'] = {'path': str(self.image), 'mode': 'contain'}
        saved['monitors']['DP-3'] = {'path': '/missing/image.png', 'mode': 'tile', 'description': 'Display A'}
        state.save(self.file, saved)
        result = state.perform({'op':'restore'}, self.file)
        self.assertTrue(result['ok']); self.assertTrue(result['warnings'])
        self.assertIn(('DP-3', str(self.image), 'contain'), self.calls)
        self.assertEqual(state.read(self.file)['monitors']['DP-3']['path'], '/missing/image.png')

    def test_apply_and_reload(self):
        out = state.perform({'op':'apply','path':str(self.second),'mode':'contain'}, self.file)
        self.assertTrue(out['ok']); self.assertEqual(len(self.calls), 2)
        loaded = state.perform({'op':'load'}, self.file)['state']
        self.assertEqual(loaded['shared'], {'path':str(self.second),'mode':'contain'})
        self.assertEqual(loaded['recents'], [str(self.second)])
        state.perform({'op':'apply','path':str(self.image),'monitor':'DP-3','mode':'tile'},self.file)
        saved = state.read(self.file)
        self.assertEqual(state.target_for(saved,self.monitors[0])['path'],str(self.image))
        self.assertEqual(state.target_for(saved,{'name':'DP-3','description':'Different display'})['path'],str(self.second))
        self.monitors = [self.monitors[1]]
        state.perform({'op':'restore'},self.file)
        self.assertIn('DP-3',state.read(self.file)['monitors'])
        self.monitors.append({'name':'DP-3','description':'Display A'})
        state.perform({'op':'restore'},self.file)
        self.assertEqual(self.active['DP-3'],str(self.image))

    def test_failure_rollback(self):
        state.save(self.file,state.empty()); original=self.file.read_bytes()
        def fail(monitor,path,mode):
            if monitor == 'eDP-2' and path == str(self.second): raise RuntimeError('renderer rejected')
            self.active[monitor]=path
        with patch.object(backend,'apply',fail):
            result=state.perform({'op':'apply','path':str(self.second),'mode':'cover'},self.file)
        self.assertFalse(result['ok']); self.assertIn('renderer rejected',result['error'])
        self.assertEqual(self.file.read_bytes(),original)
        self.assertTrue(all(p==str(self.image) for p in self.active.values()))

    def test_save_failure_rollback(self):
        with patch.object(state,'save',side_effect=OSError('disk full')):
            result=state.perform({'op':'apply','path':str(self.second),'mode':'cover'},self.file)
        self.assertFalse(result['ok']); self.assertFalse(self.file.exists())
        self.assertTrue(all(p==str(self.image) for p in self.active.values()))

    def test_favourites_recents_missing(self):
        item=str(self.second)
        state.perform({'op':'favourite','path':item},self.file)
        self.second.unlink()
        self.assertEqual(state.read(self.file)['favourites'],[item])
        state.perform({'op':'favourite','path':item},self.file)
        self.assertEqual(state.read(self.file)['favourites'],[])
        with self.assertRaises(ValueError): state.perform({'op':'apply','path':item},self.file)
        for _ in range(2): state.perform({'op':'apply','path':str(self.image)},self.file)
        self.assertEqual(state.read(self.file)['recents'],[str(self.image)])
        state.perform({'op':'clearRecents'},self.file)
        self.assertEqual(state.read(self.file)['recents'],[])

    def test_bounds_corruption(self):
        saved=state.empty(); saved['recents']=[f'/p/{i}.png' for i in range(24)]
        state.save(self.file,saved)
        state.perform({'op':'apply','path':str(self.image)},self.file)
        self.assertEqual(len(state.read(self.file)['recents']),24)
        self.file.write_text('{broken')
        with self.assertRaises(ValueError): state.perform({'op':'favourite','path':str(self.image)},self.file)
        self.assertEqual(self.file.read_text(),'{broken')


if __name__ == '__main__': unittest.main()
