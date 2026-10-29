#!/usr/bin/env python3
"""Guarded launch consumers; never edit user config or published generations."""
import configparser
import json
import os
from pathlib import Path
import re
import shutil
import sys

sys.dont_write_bytecode = True
SPLASH_THEMES = ('ocean', 'matrix', 'starlight', 'fire', 'monochrome')


def validate_payload(target, text):
    if '\0' in text:
        raise ValueError('NUL in colour payload')
    if target == 'ascii-splash':
        value = json.loads(text)
        if not isinstance(value, dict) or set(value) != {'theme'} or value['theme'] not in SPLASH_THEMES:
            raise ValueError('Unsupported ascii-splash theme payload')
        return value['theme']
    parser = configparser.ConfigParser(interpolation=None, inline_comment_prefixes=(';',))
    parser.read_string(text)
    keys = {'background', 'foreground', 'gradient', 'gradient_count'} | {f'gradient_color_{n}' for n in range(1, 7)}
    if parser.sections() != ['color'] or parser.defaults() or set(parser['color']) != keys:
        raise ValueError('Invalid CAVA colour keys')
    colors = {k: v.strip("'\"") for k, v in parser['color'].items()}
    if colors['background'] != 'default' or colors['gradient'] != '1' or colors['gradient_count'] != '6':
        raise ValueError('Invalid CAVA background/gradient')
    if any(not re.fullmatch(r'#[0-9a-fA-F]{6}', colors[k]) for k in keys-{'background','gradient','gradient_count'}):
        raise ValueError('Invalid CAVA colour')
    return colors


def cava_config(original, colors):
    """Replace only the colour section; retain all other source lines verbatim."""
    output, in_color = [], False
    for line in original.splitlines(keepends=True):
        section = re.match(r'^\s*\[([^]]+)\]', line)
        if section:
            in_color = section[1].strip().lower() == 'color'
        if not in_color:
            output.append(line)
    return ''.join(output).rstrip('\n')+'\n\n'+colors


def explicit_override(target, args):
    if target == 'cava':
        return bool(args)  # Custom -p, help and version retain unmodified native semantics.
    # Shared presets contain their own theme. Informational/subcommands are untouched.
    return any(a in ('play','share','watch','--help','-h','--version','-V','--theme','-t') or
               a.startswith('--theme=') or (a.startswith('-t') and len(a)>2) for a in args)


def main(argv):
    target, *args = argv
    if target not in ('cava','ascii-splash'):
        raise ValueError('Unknown terminal visual target')
    binary = shutil.which('cava') if target == 'cava' else (shutil.which('splash') or shutil.which('ascii-splash'))
    if not binary:
        print('MAGI: application not installed: '+target, file=sys.stderr)
        return 127
    config = Path(os.environ.get('XDG_CONFIG_HOME', Path.home()/'.config'))
    data = Path(os.environ.get('XDG_DATA_HOME', Path.home()/'.local/share'))
    name = 'colors.ini' if target == 'cava' else 'theme.json'
    payload = data/'magi/theme-orchestrator'/target/'current'/name
    if not explicit_override(target, args) and payload.is_file():
        fd = None
        try:
            text = payload.read_text()
            value = validate_payload(target, text)
            if target == 'ascii-splash':
                args += ['--theme', value]
            else:
                source = config/'cava/config'
                original = source.read_text() if source.exists() else ''
                merged = cava_config(original, text).encode()
                # Anonymous launch-only snapshot: no persistent generated config,
                # cleanup worker, polling, subprocess supervisor or second writer.
                fd = os.memfd_create('magi-cava-config', os.MFD_CLOEXEC)
                with os.fdopen(os.dup(fd), 'wb') as stream:
                    stream.write(merged)
                os.set_inheritable(fd, True)
                args = ['-p', f'/proc/self/fd/{fd}']
        except (OSError, ValueError, configparser.Error):
            if fd is not None:
                os.close(fd)
            print('MAGI: colour payload unavailable or invalid; using application defaults.', file=sys.stderr)
    os.execv(binary, [binary, *args])


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
