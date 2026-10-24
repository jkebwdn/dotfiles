import re
from pathlib import Path
from .base import Adapter, block, change, command
from ..storage import Conflict


class Magi(Adapter):
    id, label, boundary = 'magi', 'MAGI', 'Applied — reactive palette'

    def detect(self, store):
        return dict(available=True, configured=True, reason='Canonical palette source')


class Hyprland(Adapter):
    id, label, executable = 'hyprland', 'Hyprland', 'hyprctl'
    config_path = 'hypr/hyprland.lua'
    boundary = 'Runtime update pending'

    def plan(self, store, options):
        path = str(store.current(self.id) / 'colors.lua')
        # Late colour-only application preserves every geometry/autostart setting.
        body = f'local magi_theme = {path!r}\nlocal magi_file = io.open(magi_theme, "r")\nif magi_file then magi_file:close(); dofile(magi_theme) end'
        return [change(self.path(store), lambda t: block(t, body, '--'))]

    def render(self, p, store):
        # Borders only: shadow RGB/alpha and all effect parameters stay user-owned.
        r = p['roles']
        rgba = lambda role, alpha: 'rgba(' + r[role][1:] + alpha + ')'
        return {'colors.lua': '-- MAGI generated theme v1\nhl.config({general={col={active_border={colors={"'
                + rgba('blue', 'ee') + '","' + rgba('focus', 'ee')
                + '"},angle=45},inactive_border="' + rgba('inactive', 'aa')
                + '"}}})\n'}

    def activate(self, store):
        # Installed 0.56 Lua API only; never reload the whole compositor config.
        version = command(['hyprctl', 'version'])
        if not re.search(r'\b0\.56\.', version):
            raise RuntimeError('Hyprland runtime adapter requires audited 0.56.x; generated include ready')
        response = command(['hyprctl', 'eval', 'dofile(' + repr(str(store.current(self.id) / 'colors.lua')) + ')'])
        if re.search(r'error|failed|exception', response, re.IGNORECASE):
            raise RuntimeError('Hyprland rejected colour update: ' + response[:500])
        errors = command(['hyprctl', 'configerrors'])
        if errors:
            raise RuntimeError('Hyprland configerrors: ' + errors[:500])
        return 'Runtime update accepted; configerrors clear (visual check required)'


class Ghostty(Adapter):
    id, label, executable = 'ghostty', 'Ghostty', 'ghostty'
    config_path = 'ghostty/config.ghostty'
    version = 3
    boundary = 'Reload required — Ghostty reload_config (Ctrl+Shift+,)'

    def plan(self, store, options):
        body = 'config-file = ?' + str(store.current(self.id) / 'colors.conf')
        return [change(self.path(store), lambda t: block(t, body))]

    def render(self, p, store, appearance=None):
        t = p['terminal']
        fields = {'background': t['background'], 'foreground': t['foreground'],
                  'cursor-color': t['cursor'], 'cursor-text': t['cursorText'],
                  'selection-background': t['selection'], 'selection-foreground': t['selectionText']}
        text = '# MAGI generated theme v1\n' + ''.join(f'{k} = {v}\n' for k, v in fields.items())
        text += ''.join(f'palette = {i}={color}\n' for i, color in enumerate(p['ansi']))
        from application_appearance.policy import normalize
        policy = normalize(appearance)
        files = {}
        if policy['managed']:
            text += 'background-opacity = ' + format(policy['backgroundOpacity'], '.6g') + '\n'
            text += 'background-opacity-cells = false\n'
            # GTK 4.24 advertises ext-background-effect even without a blur region.
            # Ghostty 1.3.1 needs an explicit backdrop request. This provider is
            # loaded only inside Ghostty; .window is its main-window CSS class.
            # GTK 4.24 gskblurutils.c requires radius >= 20 to emit a region.
            # Hyprland uses the requested region, not this CSS radius: strength
            # remains compositor-owned. Keep the request stable across toggles;
            # the immutable no-blur rule independently gates participation.
            css_path = (store.current(self.id) if store else Path('.')) / 'background-blur.css'
            text += 'gtk-custom-css = ' + str(css_path) + '\n'
            files['background-blur.css'] = '/* MAGI: Ghostty-only compositor blur request. */\nwindow.window { backdrop-filter: blur(20px); }\n'
        # Releasing ownership omits these keys, so the existing operator config wins.
        return {**files, 'colors.conf': text}


class Gtk(Adapter):
    id, label, executable = 'gtk', 'GTK / Thunar', 'thunar'
    config_path = 'gtk-3.0/gtk.css'
    boundary = 'Relaunch Thunar required; system scheme requested; GTK4 full palette deferred'

    def plan(self, store, options):
        # One named GTK3 theme plus matching GSettings owner. GTK4's local
        # settings/CSS, icons and cursors remain outside palette ownership.
        schema = 'org.gnome.desktop.interface'
        current = command(['gsettings', 'get', schema, 'gtk-theme'])
        if 'highcontrast' in current.lower():
            raise Conflict('High contrast is active; preserve accessibility policy')
        names = {'#1e1e2e': 'background', '#181825': 'background',
                 '#cdd6f4': 'text', '#313244': 'surface', '#45475a': 'elevated'}
        def transform(text):
            # Move colour declarations only in audited Thunar selectors, never
            # unrelated application's CSS that happens to use a Mocha colour.
            def declaration(match):
                line = match.group(0)
                return '/* MAGI named theme owns: ' + line.strip() + ' */'
            colors = '|'.join(re.escape(c) for c in names)
            pattern = r'(?m)^[ \t]*(?:background-color|color)\s*:\s*(?:' + colors + r')\s*;[ \t]*$'
            def rule(match):
                selector, body = match.group(1), match.group(2)
                if '.thunar' in selector:
                    body = re.sub(pattern, declaration, body)
                return selector + '{' + body + '}'
            text = re.sub(r'([^{}]+)\{([^{}]*)\}', rule, text)
            text = re.sub(r'(?m)^@define-color theme_selected_(?:bg|fg)_color (?:' + colors + r');$', declaration, text)
            return block(text, '@import url("' + (store.current(self.id) / 'gtk.css').as_uri() + '");', 'css', True)
        settings = store.config / 'gtk-3.0/settings.ini'
        def select(text):
            pattern = r'(?m)^gtk-theme-name=.*$'
            if len(re.findall(pattern, text)) != 1 or 'HighContrast' in text:
                raise Conflict('GTK3 theme selector is missing/ambiguous or high contrast')
            return re.sub(pattern, '# MAGI THEME BEGIN\ngtk-theme-name=MAGI\n# MAGI THEME END', text)
        link = store.data.parents[1] / 'themes/MAGI'
        if link.exists() or link.is_symlink():
            raise Conflict('Unowned MAGI GTK theme exists')
        return [change(self.path(store), transform), change(settings, select),
                {'kind': 'symlink', 'path': str(link), 'destination': str(store.current(self.id) / 'theme')},
                {'kind': 'gsettings', 'schema': schema, 'key': 'gtk-theme',
                 'before': current, 'after': "'MAGI'"},
                {'kind': 'gsettings', 'schema': schema, 'key': 'color-scheme',
                 'before': command(['gsettings', 'get', schema, 'color-scheme']),
                 'after': "'prefer-dark'", 'dynamicScheme': True}]

    def render(self, p, store):
        r = p['roles']
        text = '/* MAGI generated GTK3/Thunar palette v1 */\n'
        text += ''.join(f'@define-color magi_{k} {v};\n' for k, v in r.items())
        definitions = text
        rules = {
            '.thunar, .thunar window, .thunar dialog, .thunar toolbar, .thunar menubar': ('surface', 'text'),
            '.thunar .view, .thunar entry': ('background', 'text'),
            '.thunar menu, .thunar menuitem, .thunar popover': ('surface', 'text'),
            '.thunar .view:selected, .thunar menuitem:hover, .thunar button:checked': ('accent', 'onAccent'),
        }
        for selector, (bg, fg) in rules.items():
            text += f'{selector} {{ background-color: {r[bg]}; color: {r[fg]}; border-color: {r["border"]}; }}\n'
        text += f'.thunar *:disabled {{ color: {r["muted"]}; }}\n'
        base = 'gtk-contained-dark.css' if p['dark'] else 'gtk-contained.css'
        theme = '/* MAGI generated named GTK3 theme v1 */\n@import url("resource:///org/gtk/libgtk/theme/Adwaita/' + base + '");\n' + text
        return {'gtk.css': definitions, 'theme/gtk-3.0/gtk.css': theme}
