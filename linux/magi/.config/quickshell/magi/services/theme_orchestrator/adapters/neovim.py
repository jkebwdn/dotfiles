import json
import os
from .base import Adapter, block, change


class Neovim(Adapter):
    id, label, executable = 'neovim', 'Neovim', 'nvim'
    config_path = 'nvim/init.lua'
    boundary = 'Reload required — :colorscheme magi; otherwise next launch'

    def detect(self, store):
        result = super().detect(store)
        if os.environ.get('NVIM_APPNAME', 'nvim') != 'nvim':
            result.update(configured=False, reason='NVIM_APPNAME selects an unaudited configuration')
        return result

    def plan(self, store, options):
        path = str(store.current(self.id))
        body = 'vim.opt.runtimepath:prepend(' + repr(path) + ')\nvim.cmd.colorscheme("magi")'
        return [change(self.path(store), lambda t: block(t, body, '--'))]

    def render(self, p, store):
        r = p['roles']
        # Transparency is intentional in the audited config. Plugin groups use
        # the same semantic source but explicit UI/syntax mappings.
        groups = {
            'Normal': ('text', None), 'NormalNC': ('subtext', None), 'NormalFloat': ('text', 'surface'),
            'FloatBorder': ('border', 'surface'), 'SignColumn': ('text', None),
            'LineNr': ('inactive', None), 'CursorLineNr': ('accent', None),
            'CursorLine': (None, 'surface'), 'Visual': ('text', 'elevated'),
            'Search': ('onYellow', 'yellow'), 'IncSearch': ('onAccent', 'accent'),
            'Comment': ('muted', None), 'Constant': ('peach', None), 'String': ('green', None),
            'Character': ('green', None), 'Number': ('peach', None), 'Boolean': ('peach', None),
            'Identifier': ('text', None), 'Function': ('blue', None), 'Statement': ('lavender', None),
            'PreProc': ('peach', None), 'Type': ('yellow', None), 'Special': ('teal', None),
            'Underlined': ('blue', None), 'Error': ('danger', None), 'Todo': ('onYellow', 'yellow'),
            'Pmenu': ('text', 'surface'), 'PmenuSel': ('onAccent', 'accent'),
            'StatusLine': ('text', 'surface'), 'StatusLineNC': ('muted', 'surface'),
            'TabLine': ('muted', 'surface'), 'TabLineSel': ('accent', 'elevated'),
            'WinSeparator': ('border', None), 'Directory': ('blue', None),
            'DiffAdd': ('green', 'surface'), 'DiffChange': ('yellow', 'surface'),
            'DiffDelete': ('red', 'surface'), 'DiffText': ('onAccent', 'accent'),
            'NeoTreeNormal': ('text', None), 'NeoTreeNormalNC': ('subtext', None),
            'NeoTreeDirectoryName': ('blue', None), 'NeoTreeDirectoryIcon': ('blue', None),
            'NeoTreeRootName': ('accent', None), 'NeoTreeFloatBorder': ('border', 'surface'),
            'NeoTreeCursorLine': ('accent', 'surface'),
            'TelescopeNormal': ('text', 'surface'), 'TelescopeBorder': ('border', 'surface'),
            'TelescopeSelection': ('accent', 'elevated'), 'TelescopeMatching': ('yellow', None),
            'WhichKey': ('accent', None), 'WhichKeyGroup': ('blue', None),
            'WhichKeyNormal': ('text', 'surface'), 'WhichKeyDesc': ('text', None),
            'IblIndent': ('border', None), 'IblScope': ('accent', None),
            'BufferLineFill': ('muted', None), 'BufferLineBackground': ('muted', None),
            'BufferLineBufferSelected': ('accent', None), 'BufferLineSeparator': ('border', None),
            'AlphaHeader': ('blue', None), 'AlphaButtons': ('accent', None), 'AlphaFooter': ('muted', None),
        }
        for name, role in [('Error', 'danger'), ('Warn', 'warning'), ('Info', 'blue'), ('Hint', 'teal'), ('Ok', 'success')]:
            groups['Diagnostic' + name] = (role, None)
            groups['DiagnosticVirtualText' + name] = (role, None)
            groups['DiagnosticSign' + name] = (role, None)
        for name, role in [('Add', 'green'), ('Change', 'yellow'), ('Delete', 'red')]:
            groups['GitSigns' + name] = (role, None)
        text = '-- MAGI generated colorscheme v1\nvim.cmd("highlight clear")\n'
        text += 'vim.o.background = ' + json.dumps('dark' if p['dark'] else 'light') + '\nvim.g.colors_name = "magi"\n'
        for group, (fg, bg) in groups.items():
            text += 'vim.api.nvim_set_hl(0, ' + json.dumps(group) + ', {fg=' + json.dumps(r[fg] if fg else 'NONE') + ', bg=' + json.dumps(r[bg] if bg else 'NONE') + '})\n'
        links = {'@comment': 'Comment', '@string': 'String', '@number': 'Number', '@boolean': 'Boolean',
                 '@function': 'Function', '@function.call': 'Function', '@keyword': 'Statement',
                 '@type': 'Type', '@variable': 'Identifier', '@constant': 'Constant', '@operator': 'Special'}
        for group, link in links.items():
            text += 'vim.api.nvim_set_hl(0, ' + json.dumps(group) + ', {link=' + json.dumps(link) + '})\n'
        for i, color in enumerate(p['ansi']):
            text += f'vim.g.terminal_color_{i} = "{color}"\n'
        # lualine's auto theme observes ColorScheme. Do not replace plugin options.
        return {'colors/magi.lua': text}
