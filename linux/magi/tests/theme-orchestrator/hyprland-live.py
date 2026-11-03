#!/usr/bin/env python3
"""Opt-in read-only native border check; never switches palettes or writes state.

Run in the desktop session with --theme matching the selected MAGI palette.
Excluded from run-all.py: synthetic tests must never query the operator compositor.
"""
import argparse
import json
from pathlib import Path
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[2]/'.config/quickshell/magi/services'))
from theme_orchestrator.adapters import ADAPTERS
from theme_orchestrator.adapters.base import command
from theme_orchestrator.adapters.hyprland_runtime import expected_borders, parse_version, read_border
from theme_orchestrator.palette import resolve

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--theme', required=True)
args = parser.parse_args()
version_text = command(['hyprctl', 'version'])
version = parse_version(version_text)
if version is None or version[0] != 0 or not 56 <= version[1] <= 57:
    raise SystemExit('Unaudited or unrecognized compositor version: ' + version_text)
expected = expected_borders(ADAPTERS['hyprland'].render(resolve(args.theme), None)['colors.lua'])
actual = {option:read_border(command, option) for option in expected}
print(json.dumps({'version':version_text,'theme':args.theme,'expected':expected,'actual':actual,
                  'match':actual == expected}, indent=2))
if actual != expected:
    raise SystemExit('Border verification failed')
if command(['hyprctl', 'configerrors']):
    raise SystemExit('Compositor reports config errors')
print('PASS: selected palette agrees with both running border values')
