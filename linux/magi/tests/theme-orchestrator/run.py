#!/usr/bin/env python3
"""Focused lifecycle/ownership fixtures; no operator configuration writes."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / '.config/quickshell/magi'
sys.path.insert(0, str(SOURCE / 'services'))
from theme_orchestrator.adapters import ADAPTERS
from theme_orchestrator.palette import resolve
from theme_orchestrator.storage import Store, Conflict
from theme_orchestrator.coordinator import Orchestrator

MOCHA, FOREST = 'catppuccin-mocha', 'everforest-dark-hard'


class FakeActivation:
    def activate(self, target, adapter, store):
        from theme_activation.capabilities import result, CAPABILITIES
        if target == 'hyprland': return result('applied',adapter.activate(store))
        if target == 'ghostty': return result('reload_requested','Fake accepted action')
        kind=CAPABILITIES[target].kind
        return result(kind, CAPABILITIES[target].detail)

class Lifecycle(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='magi-orchestrator-')
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.store = Store(self.home, self.home/'config', self.home/'data', self.home/'state')
        self.worker = Orchestrator(self.store, FakeActivation())
        self.theme = MOCHA
        env = patch.dict(os.environ, {'STARSHIP_CONFIG': ''})
        env.start(); self.addCleanup(env.stop)
        paths = {'ghostty': 'ghostty/config.ghostty', 'hypr': 'hypr/hyprland.lua',
                 'gtk3': 'gtk-3.0/gtk.css', 'yazi': 'yazi/theme.toml',
                 'nvim': 'nvim/init.lua', 'starship': 'starship.toml', 'fastfetch': 'fastfetch/config.jsonc'}
        def baseline(package, relative):
            # Historical legacy-enrollment fixture: explicitly pre-bootstrap source.
            # New bootstrap coverage separately reads current tracked templates.
            return subprocess.check_output(['git', 'show',
                '254d4ac9f4a34623397c12aeb96023bfe0c83190:linux/t15g/'+package+'/.config/'+relative], cwd=ROOT)
        for package, relative in paths.items():
            dst = self.store.config/relative
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.write_bytes(baseline(package, relative))
        for relative in ('yazi/init.lua', 'gtk-3.0/settings.ini'):
            package = 'gtk3' if relative.startswith('gtk') else 'yazi'
            (self.store.config/relative).write_bytes(baseline(package, relative))
        (self.home/'.bashrc').write_text('# user shell\neval "$(starship init bash)"\n')
        (self.store.config/'btop').mkdir()
        (self.store.config/'btop/btop.conf').write_text('color_theme = "t15g"\ntheme_background = false\n')
        zen = self.home/'.zen'
        profile = zen/'release'
        (profile/'chrome').mkdir(parents=True)
        (profile/'chrome/userChrome.css').write_text(':root { --ctp-base: #1e1e2e; }\n/* personal CSS */\n')
        (profile/'prefs.js').write_text('user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);\n')
        (zen/'profiles.ini').write_text('[Profile0]\nPath=other\nDefault=1\n[Profile1]\nPath=release\nIsRelative=1\n[Install15B76BAA26BA15E7]\nDefault=release\n')
        (zen/'installs.ini').write_text('[15B76BAA26BA15E7]\nDefault=release\n')
        self.gsettings = {'gtk-theme': "'catppuccin'", 'color-scheme': "'prefer-dark'"}
        def command(argv):
            if argv[0] == 'gsettings':
                if argv[1] == 'get': return self.gsettings[argv[3]]
                self.gsettings[argv[3]] = argv[4]; return ''
            if argv == ['hyprctl', 'version']: return 'Hyprland 0.56.2'
            return ''
        for name in ('theme_orchestrator.adapters.desktop.command', 'theme_orchestrator.coordinator.command'):
            p = patch(name, side_effect=command); p.start(); self.addCleanup(p.stop)
        p = patch('theme_orchestrator.adapters.base.shutil.which', return_value='/usr/bin/test')
        p.start(); self.addCleanup(p.stop)
        self.originals = {p: p.read_bytes() for p in [*self.store.config.rglob('*'), self.home/'.bashrc', profile/'chrome/userChrome.css'] if p.is_file()}

    def request(self, op, **args):
        return self.worker.perform(dict(op=op, theme=self.theme, **args))

    def enable(self, target):
        options = {'confirmedProfile': str(self.home/'.zen/release')} if target == 'zen' else {}
        plan = self.request('plan', target=target, options=options)['plan']
        result = self.request('enable', target=target, options=options, token=plan['token'])
        row = next(r for r in result['targets'] if r['id'] == target)
        self.assertFalse(row['error'], row)
        self.assertTrue(row['enabled'])
        return row

    def test_all_switch_idempotence_removal_persistence(self):
        for target in ADAPTERS:
            if target != 'magi': self.enable(target)
        for theme in (FOREST, MOCHA):
            self.theme = theme
            result = self.request('apply')
            self.assertFalse(any(r['error'] for r in result['targets']))
            for target in ADAPTERS:
                if target not in ('magi', 'fastfetch'):
                    p = self.store.current(target)/'palette.json'
                    self.assertEqual(json.loads(p.read_text())['id'], theme)
        outputs = {p: p.stat().st_mtime_ns for p in self.store.data.rglob('*') if p.is_file()}
        self.request('apply')
        self.assertEqual(outputs, {p: p.stat().st_mtime_ns for p in self.store.data.rglob('*') if p.is_file()})
        self.assertTrue(Orchestrator(self.store).perform({'op': 'status', 'theme': MOCHA})['targets'][1]['enabled'])
        for target in reversed(list(ADAPTERS)):
            if target != 'magi':
                result = self.request('disable', target=target)
                row = next(r for r in result['targets'] if r['id'] == target)
                self.assertFalse(row['enabled'])
                self.assertFalse(row['error'], row)
                self.request('disable', target=target)
        for path, original in self.originals.items():
            self.assertEqual(path.read_bytes(), original, str(path))
        self.theme = FOREST
        self.request('apply')
        self.assertEqual(outputs, {p: p.stat().st_mtime_ns for p in self.store.data.rglob('*') if p.is_file()})
        self.assertEqual(self.gsettings, {'gtk-theme': "'catppuccin'", 'color-scheme': "'prefer-dark'"})

    def test_later_user_edits_and_modified_hook(self):
        self.enable('ghostty')
        p = self.store.config/'ghostty/config.ghostty'
        p.write_text(p.read_text()+'\nfont-size = 14\n')
        self.request('disable', target='ghostty')
        self.assertTrue(p.read_text().endswith('font-size = 14\n'))
        self.enable('ghostty')
        p.write_text(p.read_text().replace('config-file = ?', 'config-file = /user/'))
        before = p.read_bytes()
        row = next(r for r in self.request('disable', target='ghostty')['targets'] if r['id']=='ghostty')
        self.assertFalse(row['enabled']); self.assertTrue(row['error'])
        self.assertEqual(p.read_bytes(), before)

    def test_generation_preflight_aborts_all_targets_and_missing(self):
        self.enable('ghostty'); self.enable('neovim')
        with patch.object(ADAPTERS['ghostty'], 'render', side_effect=ValueError('deliberate renderer failure')):
            self.theme = FOREST
            result = self.request('apply')
            rows = {r['id']: r for r in result['targets']}
            self.assertIn('deliberate', rows['ghostty']['error'])
            self.assertEqual(rows['neovim']['publishedPalette'], MOCHA)
            self.assertEqual(json.loads((self.store.current('ghostty')/'palette.json').read_text())['id'], MOCHA)
            self.assertIn('failure', result['summary'].lower())
            self.assertEqual(rows['neovim']['phase'], 'ready')
            self.assertEqual(self.worker.activation.snapshot('neovim')['files']['palette.json'], json.dumps(resolve(MOCHA),sort_keys=True,indent=2)+'\n')
        with patch('theme_orchestrator.adapters.base.shutil.which', return_value=None):
            self.assertFalse(self.request('status')['targets'][1]['available'])
            with self.assertRaises(RuntimeError): self.request('plan', target='btop')

    def test_plan_race_and_path_identity(self):
        plan = self.request('plan', target='ghostty')['plan']
        p = self.store.config/'ghostty/config.ghostty'
        p.write_text(p.read_text()+'# subsequent edit\n')
        self.request('enable', target='ghostty', token=plan['token'])
        self.assertNotIn('MAGI THEME BEGIN', p.read_text())
        self.enable('ghostty')
        replacement = self.home/'other'
        replacement.write_text(p.read_text())
        p.unlink(); p.symlink_to(replacement)
        self.assertIn('changed', next(r for r in self.request('apply')['targets'] if r['id']=='ghostty')['error'])

    def test_zen_registration_confirmation_and_preservation(self):
        with self.assertRaises(Conflict): self.request('plan', target='zen')
        self.assertEqual(ADAPTERS['zen'].profile(self.store), self.home/'.zen/release')
        self.enable('zen')
        css = self.home/'.zen/release/chrome/userChrome.css'
        self.assertIn('/* personal CSS */', css.read_text())
        self.assertTrue(css.read_text().startswith('/* MAGI THEME BEGIN */'))
        (self.home/'.zen/installs.ini').write_text('[15B76BAA26BA15E7]\nDefault=other\n')
        row = next(r for r in self.request('apply')['targets'] if r['id']=='zen')
        self.assertTrue(row['error'])

    def test_zen_minimal_css_and_private_state_boundary(self):
        profile = self.home/'.zen/release'
        private = [profile/name for name in ('zen-sessions.jsonlz4', 'places.sqlite',
                   'cookies.sqlite', 'logins.json', 'extensions.json', 'zen-themes.json')]
        for path in private: path.write_bytes(b'private sentinel: never open')
        original = (profile/'chrome/userChrome.css').read_bytes()
        real_open = Path.open
        def guarded_open(path, *args, **kwargs):
            self.assertNotIn(path, private, 'adapter accessed private browser state')
            return real_open(path, *args, **kwargs)
        with patch.object(Path, 'open', guarded_open):
            self.enable('zen')
            registry = json.loads((SOURCE/'theme/palettes/registry.json').read_text())
            for theme in registry['themes']:
                self.theme = theme['id']
                self.request('apply')
                css = (self.store.current('zen')/'chrome.css').read_text()
                declarations = [line.strip() for line in css.splitlines() if line.startswith('  ')]
                r = resolve(self.theme)['roles']
                self.assertEqual(declarations, [f'--ctp-base: {r["background"]} !important;',
                    f'--ctp-surface0: {r["surface"]} !important;', f'--ctp-text: {r["text"]} !important;'])
                self.assertEqual(css.count('{'), 1)
                self.assertIn(':root {', css)
                row = next(r for r in self.request('status')['targets'] if r['id']=='zen')
                self.assertIn('Manual workspace colour required', row['result'])
                self.assertIn('Restart Zen', row['result'])
            self.request('disable', target='zen')
            self.assertEqual((profile/'chrome/userChrome.css').read_bytes(), original)
            self.enable('zen')
            css = profile/'chrome/userChrome.css'
            css.write_text(css.read_text().replace('@import url(', '@import /* user changed */ url('))
            changed = css.read_bytes()
            row = next(r for r in self.request('disable', target='zen')['targets'] if r['id']=='zen')
            self.assertFalse(row['enabled']); self.assertTrue(row['error'])
            self.assertEqual(css.read_bytes(), changed)
        for path in private: self.assertEqual(path.read_bytes(), b'private sentinel: never open')

    def test_yazi_comment_whitespace(self):
        self.enable('yazi')
        text = (self.store.config/'yazi/theme.toml').read_text()
        self.assertTrue(all(line == line.rstrip() for line in text.splitlines()
                            if line.startswith('# MAGI flavour owns:')))
        self.request('disable', target='yazi')
        path = self.store.config/'yazi/theme.toml'
        self.assertEqual(path.read_bytes(), self.originals[path])

    def test_light_metadata_and_all_palettes(self):
        self.enable('gtk')
        registry = json.loads((SOURCE/'theme/palettes/registry.json').read_text())
        for theme in registry['themes']:
            p = resolve(theme['id'])
            self.assertEqual(p['dark'], theme['dark'])
            self.assertEqual(p, resolve(theme['id']))
            for adapter in ADAPTERS.values():
                files = adapter.render(p, self.store)
                self.assertEqual(files, adapter.render(p, self.store))
        self.theme = 'catppuccin-latte'
        self.request('apply')
        self.assertEqual(self.gsettings['color-scheme'], "'prefer-light'")
        self.gsettings['gtk-theme'] = "'HighContrast'"
        self.assertIn('changed', next(r for r in self.request('apply')['targets'] if r['id']=='gtk')['error'])

    def test_no_generated_writes_in_checkout_or_symlink(self):
        repo = self.home/'dotfiles'; (repo/'.git').mkdir(parents=True); (repo/'.git/HEAD').write_text('ref: refs/heads/main')
        with self.assertRaises(Conflict): Store(self.home, self.store.config, repo/'data', self.home/'state')
        with self.assertRaises(Conflict): Store(self.home, self.store.config, Path('relative-data'), self.home/'state')
        linked = self.home/'linked'; linked.symlink_to(repo, target_is_directory=True)
        with self.assertRaises(Conflict): Store(self.home, self.store.config, linked/'data', self.home/'state')
        # Legacy enrollment must no longer mutate stowed source. Canonical hooks
        # are read-only and can enroll without a source ownership journal.
        p = self.store.config/'ghostty/config.ghostty'; dest = repo/'ghostty'; p.rename(dest); p.symlink_to(dest)
        with self.assertRaisesRegex(Conflict, 'Tracked source'):
            self.request('plan', target='ghostty')
        self.assertEqual(dest.read_bytes(), self.originals[p])
        from theme_orchestrator.bootstrap import blocks
        dest.write_text(dest.read_text() + '\n' + blocks(self.store, 'ghostty')[p] + '\n')
        canonical = dest.read_bytes()
        self.enable('ghostty'); self.request('disable', target='ghostty')
        self.assertTrue(p.is_symlink())
        self.assertEqual(dest.read_bytes(), canonical)
        self.assertEqual(set(repo.iterdir()), {repo/'.git', dest})

    def test_interrupted_enrollment_recovery(self):
        import theme_orchestrator.coordinator as coordinator
        plan = self.request('plan', target='gtk')['plan']
        real_install = coordinator.install
        calls = []
        def fail_second(item):
            calls.append(item)
            if len(calls) == 2: raise OSError('simulated interrupted enrollment')
            real_install(item)
        with patch.object(coordinator, 'install', side_effect=fail_second):
            result = self.request('enable', target='gtk', token=plan['token'])
        row = next(r for r in result['targets'] if r['id'] == 'gtk')
        self.assertFalse(row['enabled']); self.assertIn('interrupted', row['error'])
        self.assertEqual(self.store.load()['targets']['gtk']['phase'], 'installing')
        self.request('disable', target='gtk')
        for path, original in self.originals.items():
            self.assertEqual(path.read_bytes(), original)

    def test_publication_retention_and_user_owned_output(self):
        self.enable('ghostty')
        first = self.store.current('ghostty').resolve()
        self.theme = FOREST; self.request('apply')
        self.theme = 'catppuccin-latte'; self.request('apply')
        self.assertFalse(first.exists())
        root = self.store.data/'ghostty'
        self.assertEqual(len(list((root/'generations').iterdir())), 2)
        output = self.store.current('ghostty')/'colors.conf'
        output.write_text(output.read_text()+'# user edit\n')
        row = next(r for r in self.request('apply')['targets'] if r['id'] == 'ghostty')
        self.assertIn('edited', row['error'])
        external = self.home/'unrelated'; external.mkdir()
        output.unlink(); output.symlink_to(external/'do-not-create')
        self.request('apply')
        self.assertFalse((external/'do-not-create').exists())

    def test_failed_first_activation_pauses_and_resumes_safely(self):
        plan = self.request('plan', target='ghostty')['plan']
        with patch.object(self.worker.activation.executor, 'activate', side_effect=RuntimeError('activation unavailable')):
            result = self.request('enable', target='ghostty', token=plan['token'])
        row = next(r for r in result['targets'] if r['id'] == 'ghostty')
        self.assertFalse(row['enabled'])
        self.assertTrue(row['installed'])
        self.assertIn('activation unavailable', row['error'])
        result = self.request('resume', target='ghostty')
        row = next(r for r in result['targets'] if r['id'] == 'ghostty')
        self.assertTrue(row['enabled']); self.assertFalse(row['error'])
        self.request('disable', target='ghostty')
        p = self.store.config/'ghostty/config.ghostty'
        self.assertEqual(p.read_bytes(), self.originals[p])

    def test_dynamic_base_and_narrow_journal(self):
        self.enable('starship')
        base = self.store.config/'starship.toml'
        base.write_text(base.read_text().replace('truncation_length = 4', 'truncation_length = 8'))
        self.request('apply')
        self.assertIn('truncation_length = 8', (self.store.current('starship')/'starship.toml').read_text())
        record = self.store.load()['targets']['starship']
        self.assertNotIn('before', record['edits'][0])
        self.assertIn('beforeHash', record['edits'][0])

    def test_hyprland_only_changes_border_colours(self):
        # Execute actual generated Lua against a config spy. Checking its full
        # write set protects both focused/unfocused shadows and all effects,
        # including future fields we have not explicitly enumerated here.
        themes = ('everforest-dark-soft', 'everforest-dark-hard',
                  'everforest-light-hard', 'catppuccin-frappe', 'catppuccin-mocha')
        harness = self.home/'check-hyprland.lua'
        harness.write_text("""
local calls = 0
local function keys(value, expected)
    for key in pairs(value) do assert(expected[key], 'Unexpected config write: ' .. key) end
    for key in pairs(expected) do assert(value[key] ~= nil, 'Missing key: ' .. key) end
end
hl = {config = function(config)
    calls = calls + 1
    keys(config, {general=true})
    keys(config.general, {col=true})
    keys(config.general.col, {active_border=true, inactive_border=true})
    local active = config.general.col.active_border
    keys(active, {colors=true, angle=true})
    assert(#active.colors == 2 and active.angle == 45)
    assert(active.colors[1] == arg[2] and active.colors[2] == arg[3])
    assert(config.general.col.inactive_border == arg[4])
end}
dofile(arg[1])
assert(calls == 1)
""")
        self.enable('hyprland')
        config = self.store.config/'hypr/hyprland.lua'
        before = config.read_bytes()
        for theme in themes + tuple(reversed(themes)):
            with self.subTest(theme=theme):
                self.theme = theme
                self.request('apply')
                r = resolve(theme)['roles']
                output = self.store.current('hyprland')/'colors.lua'
                result = subprocess.run(['lua', str(harness), str(output),
                    'rgba('+r['blue'][1:]+'ee)', 'rgba('+r['focus'][1:]+'ee)',
                    'rgba('+r['inactive'][1:]+'aa)'], capture_output=True, text=True, timeout=5)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(config.read_bytes(), before)

    def test_native_parsers(self):
        p = resolve(FOREST)
        files = ADAPTERS['neovim'].render(p, self.store)
        lua = self.home/'magi.lua'; lua.write_text(files['colors/magi.lua'])
        result = subprocess.run(['nvim', '--headless', '-u', 'NONE', '-i', 'NONE',
            '-c', 'luafile '+str(lua), '-c', 'lua assert(vim.g.colors_name == "magi"); assert(vim.api.nvim_get_hl(0, {name="Normal"}).fg == 0xd3c6aa)', '-c', 'qa!'], capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn('Error', result.stderr)
        ghost = self.home/'ghostty.conf'; ghost.write_text(ADAPTERS['ghostty'].render(p, self.store)['colors.conf'])
        result = subprocess.run(['ghostty', '+validate-config', '--config-file='+str(ghost)], capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == '__main__':
    unittest.main(verbosity=2)
