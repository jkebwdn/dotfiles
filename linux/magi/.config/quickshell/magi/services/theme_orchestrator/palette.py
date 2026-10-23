"""Resolve the same bundled registry as ThemeRegistry.qml into immutable JSON data."""
import hashlib
import json
from pathlib import Path
import re

REGISTRY = Path(__file__).resolve().parents[2] / 'theme/palettes/registry.json'
ROLES = ('background surface elevated overlay text subtext muted inactive border rim '
         'accent blue lavender green yellow peach red teal success warning danger focus '
         'sliderFill sliderTrack sliderRim onAccent onBlue onLavender onGreen onYellow '
         'onPeach onRed onTeal').split()


def fingerprint(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def resolve(theme_id):
    registry = json.loads(REGISTRY.read_text())
    if registry['formatVersion'] != 1:
        raise ValueError('Unsupported palette registry')
    theme = next((t for t in registry['themes'] if t['id'] == theme_id), None)
    if not theme or type(theme['dark']) is not bool:
        raise ValueError('Unknown or invalid MAGI palette')
    r = theme['roles']
    if any(not re.fullmatch(r'#[0-9a-fA-F]{6}', r.get(k, '')) for k in ROLES):
        raise ValueError('Incomplete semantic palette')
    # Optional upstream ANSI accent belongs to the shared canonical registry.
    magenta = theme.get('ansiMagenta', r['lavender'])
    if not re.fullmatch(r'#[0-9a-fA-F]{6}', magenta):
        raise ValueError('Invalid ANSI magenta')
    ansi = [r['elevated'], r['red'], r['green'], r['yellow'], r['blue'], magenta,
            r['teal'], r['subtext'], r['overlay'], r['red'], r['green'], r['yellow'],
            r['blue'], magenta, r['teal'], r['text']]
    snapshot = dict(schemaVersion=1, id=theme_id, label=theme['label'], dark=theme['dark'],
                    roles=r, ansi=ansi,
                    terminal=dict(background=r['background'], foreground=r['text'],
                                  cursor=r['focus'], cursorText=r['onAccent'],
                                  selection=r['accent'], selectionText=r['onAccent']),
                    syntax=dict(comment=r['muted'], keyword=r['lavender'], string=r['green'],
                                function=r['blue'], number=r['peach'], type=r['yellow']),
                    diagnostics=dict(error=r['danger'], warning=r['warning'], info=r['blue'], hint=r['teal']),
                    graph=[r['blue'], r['yellow'], r['red']])
    snapshot['fingerprint'] = fingerprint(snapshot)
    return snapshot
