"""Canonical, read-only source integration. Markers alone confer no ownership."""
from pathlib import Path
import os
from .storage import Conflict, identity

TARGETS = {'starship', 'ghostty', 'gtk', 'hyprland', 'neovim', 'yazi'}
LUA_DATA = '(os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share"))'


def wrap(body, language='#'):
    if language == 'css':
        return '/* MAGI BOOTSTRAP v1 BEGIN */\n' + body + '\n/* MAGI BOOTSTRAP v1 END */'
    return language + ' MAGI BOOTSTRAP v1 BEGIN\n' + body + '\n' + language + ' MAGI BOOTSTRAP v1 END'


def blocks(store, target):
    c = store.config
    if target == 'starship':
        return {store.home/'.bashrc': wrap('magi_starship="${XDG_DATA_HOME:-$HOME/.local/share}/magi/theme-orchestrator/starship/current/starship.toml"\nif [[ -r "$magi_starship" ]]; then\n    export STARSHIP_CONFIG="$magi_starship"\nelif [[ "${STARSHIP_CONFIG:-}" == "$magi_starship" ]]; then\n    unset STARSHIP_CONFIG\nfi\nunset magi_starship')}
    if target == 'ghostty':
        # Ghostty expands ~ in optional config-file paths. Custom XDG stores
        # require an explicitly matching static path rather than guessing.
        path = str(store.current(target)/'colors.conf')
        default = store.home/'.local/share/magi/theme-orchestrator/ghostty/current/colors.conf'
        if Path(path) == default: path = '~/.local/share/magi/theme-orchestrator/ghostty/current/colors.conf'
        return {c/'ghostty/config.ghostty': wrap('config-file = ?' + path)}
    if target == 'hyprland':
        return {c/'hypr/hyprland.lua': wrap('do\n    local path = ' + LUA_DATA + ' .. "/magi/theme-orchestrator/hyprland/current/colors.lua"\n    local file = io.open(path, "r")\n    if file then file:close(); dofile(path) end\nend', '--')}
    if target == 'neovim':
        return {c/'nvim/init.lua': wrap('do\n    local path = ' + LUA_DATA + ' .. "/magi/theme-orchestrator/neovim/current"\n    if vim.fn.filereadable(path .. "/colors/magi.lua") == 1 then\n        vim.opt.runtimepath:prepend(path)\n        vim.cmd.colorscheme("magi")\n    end\nend', '--')}
    if target == 'gtk':
        return {c/'gtk-3.0/gtk.css': wrap('/* Theme colours come from the selected GTK theme; layout remains local. */', 'css'),
                c/'gtk-3.0/settings.ini': wrap('# Static fallback; MAGI selects its generated theme through GSettings.')}
    if target == 'yazi':
        return {c/'yazi/init.lua': wrap('local magi = {accent="#b4befe", background="#1e1e2e", muted="#9399b2", text="#cdd6f4", green="#a6e3a1", red="#f38ba8", teal="#89dceb"}\ndo\n    local path = ' + LUA_DATA + ' .. "/magi/theme-orchestrator/yazi/current/yatline.lua"\n    local file = io.open(path, "r")\n    if file then file:close(); magi = dofile(path) end\nend', '--'),
                c/'yazi/theme.toml': wrap('[flavor]\ndark = "magi"\nlight = "magi"')}
    return {}


def records(store, target):
    expected = blocks(store, target)
    texts = {path: path.read_text() if path.is_file() else '' for path in expected}
    if not any('MAGI BOOTSTRAP' in text for text in texts.values()): return None
    result = []
    for path, block in expected.items():
        text = texts[path]
        if text.count(block) != 1 or text.count('MAGI BOOTSTRAP v1 BEGIN') != 1 or 'MAGI THEME BEGIN' in text:
            raise Conflict('Canonical bootstrap missing or modified: ' + str(path))
        result.append(dict(kind='bootstrap', **identity(path), block=block))
    if target == 'yazi' and not (store.config/'yazi/magi-template.toml').is_file():
        raise Conflict('Yazi source colour template is missing')
    return result


def verify(item):
    path = Path(item['path'])
    if identity(path) != {k:item[k] for k in ('path', 'resolved', 'link')}:
        raise Conflict('Bootstrap path changed: ' + str(path))
    text = path.read_text()
    if text.count(item['block']) != 1 or text.count('MAGI BOOTSTRAP v1 BEGIN') != 1 or 'MAGI THEME BEGIN' in text:
        raise Conflict('Canonical bootstrap changed: ' + str(path))


def inside_git(path):
    resolved = Path(path).resolve()
    return any(((p/'.git/HEAD').is_file() or (p/'.git').is_file()) for p in (resolved.parent, *resolved.parents))


def runtime_plan(store, target, canonical, command):
    result = list(canonical)
    if target == 'gtk':
        before = command(['gsettings', 'get', 'org.gnome.desktop.interface', 'gtk-theme'])
        if 'highcontrast' in before.lower(): raise Conflict('Preserve active high contrast')
        result += [dict(kind='symlink', path=str(store.data.parents[1]/'themes/MAGI'), destination=str(store.current('gtk')/'theme')),
                   dict(kind='gsettings', schema='org.gnome.desktop.interface', key='gtk-theme', before=before, after="'MAGI'"),
                   dict(kind='gsettings', schema='org.gnome.desktop.interface', key='color-scheme', before=command(['gsettings','get','org.gnome.desktop.interface','color-scheme']), after="'prefer-dark'", dynamicScheme=True)]
    if target == 'yazi':
        result.append(dict(kind='symlink', path=str(store.config/'yazi/flavors/magi.yazi'), destination=str(store.current('yazi')/'flavor')))
    return result
