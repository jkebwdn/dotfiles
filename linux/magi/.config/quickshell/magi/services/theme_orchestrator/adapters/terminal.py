import json
import os
from pathlib import Path
import re
import shlex
import tomllib
from .base import Adapter, block, change
from ..storage import Conflict, removal

# Audited Mocha literals -> semantic roles. Artwork is never processed.
LEGACY = {'#1e1e2e': 'background', '#181825': 'background', '#11111b': 'background',
          '#313244': 'surface', '#45475a': 'elevated', '#585b70': 'overlay',
          '#6c7086': 'inactive', '#7f849c': 'inactive', '#9399b2': 'muted',
          '#a6adc8': 'muted', '#bac2de': 'subtext', '#cdd6f4': 'text',
          '#b4befe': 'accent', '#cba6f7': 'lavender', '#f5c2e7': 'lavender',
          '#f38ba8': 'red', '#eba0ac': 'red', '#fab387': 'peach', '#f9e2af': 'yellow',
          '#a6e3a1': 'green', '#94e2d5': 'teal', '#89dceb': 'teal', '#74c7ec': 'blue',
          '#89b4fa': 'blue', '#f5e0dc': 'subtext', '#f2cdcd': 'subtext'}


def original(store, target, path):
    record = store.load()['targets'].get(target, {})
    for item in record.get('edits', []):
        if item.get('path') == str(path.absolute()):
            return removal(item)
    return path.read_text()


def recolor(text, p):
    def color(match):
        value = match.group(0).lower()
        if value not in LEGACY:
            raise Conflict('Unmapped source colour: ' + value)
        return p['roles'][LEGACY[value]]
    return re.sub(r'#[0-9a-fA-F]{6}\b', color, text)


class Yazi(Adapter):
    id, label, executable = 'yazi', 'Yazi + yatline', 'yazi'
    config_path = 'yazi/theme.toml'
    boundary = 'Next launch — Yazi and yatline'

    def detect(self, store):
        result = super().detect(store)
        override = os.environ.get('YAZI_CONFIG_HOME')
        if override and Path(override).resolve() != (store.config / 'yazi').resolve():
            result.update(configured=False, reason='YAZI_CONFIG_HOME overrides the audited configuration')
        return result

    def split(self, text):
        # Keep layout-only sections in the user's file. Move colour style objects
        # as a unit (including bold/reset) so user overrides cannot mask flavour.
        if '[flavor]' in text:
            raise Conflict('Existing Yazi flavour requires explicit migration')
        generated, retained, section = [], [], ''
        in_files = False
        for line in text.splitlines(True):
            if line.startswith('['):
                section = line
                in_files = line.strip() == '[filetype]'
                generated.append(line)
                retained.append('# MAGI filetype rules in flavour\n' if in_files else line)
            elif in_files or re.search(r'#[0-9a-fA-F]{6}', line):
                generated.append(line)
                retained.append(('# MAGI flavour owns: ' + line.rstrip()).rstrip() + '\n')
            else:
                retained.append(line)
        return ''.join(retained), ''.join(generated)

    def plan(self, store, options):
        flavor = store.config / 'yazi/flavors/magi.yazi'
        if flavor.exists() or flavor.is_symlink():
            raise Conflict('Yazi magi.yazi entry already exists and is not owned')
        body = '[flavor]\ndark = "magi"\nlight = "magi"'
        theme = change(self.path(store), lambda t: block(self.split(t)[0], body))
        path = store.config / 'yazi/init.lua'
        def init(text):
            for color, role in LEGACY.items():
                text = text.replace('"' + color + '"', 'magi.' + role)
            return block(text, 'local magi = dofile(' + repr(str(store.current(self.id) / 'yatline.lua')) + ')', '--', True)
        return [theme, change(path, init), {'kind': 'symlink', 'path': str(flavor),
                                          'destination': str(store.current(self.id) / 'flavor')}]

    def render(self, p, store):
        from ..bootstrap import records
        source = (store.config/'yazi/magi-template.toml').read_text() if records(store, self.id) else original(store, self.id, self.path(store))
        _, template = self.split(source)
        text = recolor(template, p)
        tomllib.loads(text)
        colors = ','.join(k + '=' + json.dumps(v) for k, v in p['roles'].items())
        return {'flavor/flavor.toml': '# MAGI generated Yazi flavour v1\n' + text,
                'yatline.lua': '-- MAGI generated yatline semantic data v1\nreturn {' + colors + '}\n'}


class Starship(Adapter):
    id, label, executable = 'starship', 'Starship', 'starship'
    config_path = 'starship.toml'
    boundary = 'Next prompt in shells with MAGI environment; existing shells need a new shell'

    def detect(self, store):
        result = super().detect(store)
        override = os.environ.get('STARSHIP_CONFIG')
        allowed = (self.path(store).resolve(), (store.current(self.id) / 'starship.toml').resolve())
        if override and Path(override).resolve() not in allowed:
            result.update(configured=False, reason='STARSHIP_CONFIG overrides the audited configuration')
        return result

    def plan(self, store, options):
        path = str(store.current(self.id) / 'starship.toml')
        return [change(store.home / '.bashrc', lambda t: block(t,
            'export STARSHIP_CONFIG=' + shlex.quote(path), prepend=True))]

    def render(self, p, store):
        # Read the current user base every time: layout/plugin edits are never frozen.
        source = self.path(store).read_text()
        parsed = tomllib.loads(source)
        name = parsed.get('palette')
        if name != 'catppuccin_mocha':
            raise Conflict('Starship base palette changed; review semantic mapping')
        old = parsed['palettes'][name]
        entries = []
        for key, color in old.items():
            if color.lower() not in LEGACY:
                raise Conflict('Unmapped Starship palette role: ' + key)
            entries.append(key + ' = ' + json.dumps(p['roles'][LEGACY[color.lower()]]))
        source = re.sub(r'(?m)^palette\s*=\s*[\'\"]catppuccin_mocha[\'\"]', 'palette = "magi"', source, count=1)
        source += '\n# MAGI generated palette v1\n[palettes.magi]\n' + '\n'.join(entries) + '\n'
        tomllib.loads(source)
        return {'starship.toml': source}


class Btop(Adapter):
    id, label, executable = 'btop', 'btop', 'btop'
    version = 2
    config_path = 'btop/btop.conf'
    boundary = 'Reload/restart required — reselect theme in btop or reopen'

    def plan(self, store, options):
        # btop resolves only entries enumerated in its theme directories; an
        # arbitrary generated-file path silently falls back to Default (1.4.7).
        link = store.config / 'btop/themes/magi.theme'
        if link.exists() or link.is_symlink():
            raise Conflict('Existing btop magi.theme entry requires explicit migration')
        path = str(link)
        def transform(t):
            pattern = r'(?m)^color_theme\s*=.*$'
            if len(re.findall(pattern, t)) != 1:
                raise Conflict('btop color_theme is missing or ambiguous')
            return re.sub(pattern, '# MAGI THEME BEGIN\ncolor_theme = ' + json.dumps(path) + '\n# MAGI THEME END', t)
        return [change(self.path(store), transform),
                {'kind': 'symlink', 'path': str(link),
                 'destination': str(store.current(self.id) / 'magi.theme')}]

    def render(self, p, store):
        r = p['roles']
        fields = dict(main_bg='background', main_fg='text', title='text', hi_fg='focus',
                      selected_bg='accent', selected_fg='onAccent', inactive_fg='muted',
                      graph_text='subtext', meter_bg='surface', proc_misc='lavender',
                      cpu_box='blue', mem_box='lavender', net_box='teal', proc_box='accent', div_line='border')
        text = '# MAGI generated btop theme v2 — semantic resources; host background policy unchanged\n'
        text += ''.join(f'theme[{k}]="{r[v]}"\n' for k, v in fields.items())
        gradients = {
            'temp': ('success','warning','danger'),
            'cpu': ('blue','warning','danger'),
            'free': ('teal','green','success'),
            'cached': ('blue','teal','green'),
            'available': ('teal','green','success'),
            'used': ('lavender','warning','danger'),
            'download': ('teal','teal','teal'),
            'upload': ('peach','peach','peach'),
            'process': ('blue','lavender','focus'),
        }
        for name, roles in gradients.items():
            text += ''.join(f'theme[{name}_{step}]="{r[role]}"\n' for step, role in zip(('start','mid','end'), roles))
        return {'magi.theme': text}


class Fastfetch(Adapter):
    id, label, executable = 'fastfetch', 'Fastfetch (terminal ANSI)', 'fastfetch'
    config_path = 'fastfetch/config.jsonc'
    boundary = 'Next launch after terminal palette reload; inherits Ghostty ANSI'
