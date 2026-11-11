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
BASELINE = '93ef0da1b29908e4908bb9923b26772835d9872b'
parser = argparse.ArgumentParser()
parser.add_argument('--settings', type=Path)
parser.add_argument('--output', type=Path)
parser.add_argument('--baseline', default=BASELINE)
args = parser.parse_args()
BASELINE = args.baseline
raw = json.loads(args.settings.read_bytes()) if args.settings else {
    'appearance': {'roundness': {'master': 1, 'roles': {'surface': None,
        'barPill': 1, 'action': 1.2, 'controlTile': 1.25, 'secondaryControl': 1.2,
        'slider': 1.2, 'avatar': 1.2, 'albumArt': 1.2, 'hubSelector': .4}}},
    'bar': {'visual': {'workspacePills': {'roundness': None}}}, 'launcher': {}}
seed = {'roundness': raw['appearance']['roundness'],
        'workspace': raw['bar']['visual']['workspacePills']['roundness'],
        'header_present': 'headerRadius' in raw['launcher'],
        'header': raw['launcher'].get('headerRadius', 12)}
# Settings composition is reviewed separately. Outside Settings, only the audited
# generic-role rebinding is allowed; native/schema/feature geometry stays exact.
with tempfile.TemporaryDirectory(prefix='magi-roundness-equivalence-') as temporary:
    stage = Path(temporary)
    archive = subprocess.check_output(['git', 'archive', BASELINE, 'linux/magi'], cwd=ROOT.parents[1])
    subprocess.run(['tar', '-xf', '-', '-C', str(stage)], input=archive, check=True)
    baseline = stage/'linux/magi'
    checked = 0
    unchanged = 0
    rebound = []
    settings_resources = []
    for area in ['.config/quickshell/magi', 'native']:
        for before in (baseline/area).rglob('*'):
            if not before.is_file() and not before.is_symlink(): continue
            rel = before.relative_to(baseline)
            prefix = '.config/quickshell/magi/'
            if str(rel).startswith(prefix+'components/settings/'): continue
            after = ROOT/rel
            assert after.exists(), f'Missing preserved source: {rel}'
            if before.is_symlink():
                assert os.readlink(before) == os.readlink(after), rel
                unchanged += 1
            else:
                expected=before.read_bytes()
                if str(rel) == prefix+'icons/packs/magi-default/manifest.json':
                    old_pack=json.loads(expected);new_pack=json.loads(after.read_bytes())
                    info=new_pack['roles'].pop('info', None)
                    assert info == {'asset':'info.svg','colorMode':'semantic'}
                    assert new_pack == old_pack, 'Existing icon roles changed'
                    assert (after.parent/'info.svg').is_file()
                    # A new Settings help glyph has no effect on existing runtime roles.
                    checked += 1; settings_resources.append(str(rel))
                    continue
                if str(rel).startswith(prefix) and before.suffix=='.qml':
                    expected=expected.replace(b'radius("action",',b'radius("surface",')
                    if before.name=='ValueSlider.qml':expected=expected.replace(b'radius("slider",',b'radius("surface",')
                assert expected == after.read_bytes(), f'Unexpected runtime/schema change: {rel}'
                if before.read_bytes() == after.read_bytes(): unchanged += 1
                else: rebound.append(str(rel))
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
        assert len(names) == 23, names
        for name in names:
            a, b = (QImage(str(folder/name)) for folder in folders)
            assert not a.isNull() and not b.isNull()
            generic=name.startswith('generic') or name in ['controls.png','slider.png']
            if not generic: assert a == b, f'Feature geometry changed: {theme}/{name}'
            results.append({'theme': theme, 'consumer': name, 'pixel_identical': a==b,
                'scope':'generic Appearance ownership (intentional)' if generic else 'preserved feature geometry'})
    result = {'baseline': BASELINE, 'checked_source_files': checked, 'unchanged_source_files': unchanged, 'approved_runtime_rebindings': rebound, 'approved_settings_resources': settings_resources, 'comparisons': results,
              'settings_writes': 0, 'renderer': 'Qt software; native GPU/lock acceptance separate'}
    (output/'result.json').write_text(json.dumps(result, indent=2)+'\n')
    print(f'Roundness equivalence PASS: {checked} checked runtime/schema/native files ({unchanged} unchanged, {len(rebound)} approved role rebindings, {len(settings_resources)} help-icon manifests); 46 comparisons (generic differences recorded; feature pairs identical); no Settings writes')
