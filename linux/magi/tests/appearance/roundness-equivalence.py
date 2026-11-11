#!/usr/bin/env python3
"""Compare unchanged consumers against the accepted source, in private XDG homes.

Software captures prove deterministic geometry; native GPU alpha/lock acceptance
remains a separate operator gate. No operator file is ever written.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
from PyQt6.QtGui import QImage

ROOT = Path(__file__).resolve().parents[2]
BASELINE = '5e00c381f76830ba2a75e952e6f723efe2604ea1'
parser = argparse.ArgumentParser()
parser.add_argument('--settings', type=Path)
parser.add_argument('--output', type=Path)
args = parser.parse_args()
raw = json.loads(args.settings.read_bytes()) if args.settings else {
    'appearance': {'roundness': {'master': 1, 'roles': {'surface': None,
        'barPill': 1, 'action': 1.2, 'controlTile': 1.25, 'secondaryControl': 1.2,
        'slider': 1.2, 'avatar': 1.2, 'albumArt': 1.2, 'hubSelector': .4}}},
    'bar': {'visual': {'workspacePills': {'roundness': None}}}, 'launcher': {}}
seed = {'roundness': raw['appearance']['roundness'],
        'workspace': raw['bar']['visual']['workspacePills']['roundness'],
        'header_present': 'headerRadius' in raw['launcher'],
        'header': raw['launcher'].get('headerRadius', 12)}
# Exact refinement allocation: geometry changes are also checked against independent
# runtime coordinates in settings/refinement; defaults/migrations remain protected.
allowed = {
    'components/settings/' + name for name in [
        'BarCanvas.qml', 'BarInspector.qml', 'CCSectionPreview.qml', 'ControlCentrePreview.qml',
        'CustomImageSettings.qml', 'RoundnessPicker.qml', 'RoundnessValue.qml',
        'SettingsReorderBoard.qml', 'qmldir', 'pages/BarPage.qml',
        'pages/ControlCentrePage.qml', 'pages/WallpaperPage.qml']
} | {'components/wallpaper/WallpaperContent.qml', 'components/wallpaper/WallpaperTile.qml',
     'plugins/bar/controlcentre/ControlCentre.qml', 'plugins/bar/controlcentre/SectionLayout.js',
     'services/QuickActions.qml', 'services/Wallpaper.qml', 'services/system_actions.py',
     'settings/SettingsSchema.js'}
with tempfile.TemporaryDirectory(prefix='magi-roundness-equivalence-') as temporary:
    stage = Path(temporary)
    archive = subprocess.check_output(['git', 'archive', BASELINE, 'linux/magi'], cwd=ROOT.parents[1])
    subprocess.run(['tar', '-xf', '-', '-C', str(stage)], input=archive, check=True)
    baseline = stage/'linux/magi'
    checked = 0
    for area in ['.config/quickshell/magi', 'native']:
        for before in (baseline/area).rglob('*'):
            if not before.is_file() and not before.is_symlink(): continue
            rel = before.relative_to(baseline)
            prefix = '.config/quickshell/magi/'
            if str(rel).startswith(prefix) and str(rel)[len(prefix):] in allowed: continue
            after = ROOT/rel
            assert after.exists(), f'Missing preserved source: {rel}'
            if before.is_symlink(): assert os.readlink(before) == os.readlink(after), rel
            else: assert before.read_bytes() == after.read_bytes(), f'Runtime/schema changed: {rel}'
            checked += 1
    # Use the identical capture harness on both production revisions.
    for name in ['run.py', 'roundness.qml']:
        shutil.copyfile(ROOT/'tests/runtime-visual'/name, baseline/'tests/runtime-visual'/name)
    output = args.output or stage/'captures'
    results = []
    for theme in ['nord', 'one-light']:
        folders = []
        for label, source in [('before', baseline), ('after', ROOT)]:
            folder = output/theme/label
            folder.mkdir(parents=True, exist_ok=True); folders.append(folder)
            env = dict(os.environ, MAGI_ROUNDNESS_EQUIVALENCE='1',
                MAGI_ROUNDNESS_SEED=json.dumps(seed), MAGI_ROUNDNESS_THEME=theme,
                MAGI_ROUNDNESS_CAPTURES=str(folder))
            run = subprocess.run(['python3', str(source/'tests/runtime-visual/run.py'), 'roundness.qml'],
                env=env, text=True, capture_output=True)
            (folder/'run.log').write_text(run.stdout+run.stderr)
            assert run.returncode == 0, run.stdout+run.stderr
        names = sorted(p.name for p in folders[0].glob('*.png'))
        assert len(names) == 14, names
        for name in names:
            a, b = (QImage(str(folder/name)) for folder in folders)
            assert not a.isNull() and not b.isNull() and a == b, f'Pixel difference: {theme}/{name}'
            results.append({'theme': theme, 'consumer': name, 'pixel_identical': True})
    result = {'baseline': BASELINE, 'unchanged_source_files': checked, 'comparisons': results,
              'settings_writes': 0, 'renderer': 'Qt software; native GPU/lock acceptance separate'}
    (output/'result.json').write_text(json.dumps(result, indent=2)+'\n')
    print(f'Roundness equivalence PASS: {checked} unchanged runtime/schema/native files; 28 pixel-identical pairs; no Settings writes')
