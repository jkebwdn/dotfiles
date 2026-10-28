#!/usr/bin/env python3
"""Offline regression entry point. Live acceptance scripts are never discovered/run.

Each existing harness owns its fixtures. This runner adds a disconnected outer
environment, deterministic ordering and durable logs; it does not replace tests.
Exit: 0 all pass, 1 failures, 2 environment-limited/incomplete.
"""
import argparse
import json
import os
import re
import signal
from pathlib import Path
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]


def suites():
    result = []

    def py(path, *args):
        result.append((path.removesuffix('.py') + (':' + ','.join(args) if args else ''),
                       [sys.executable, 'tests/' + path, *args]))

    def js(path, *args):
        result.append((path.removesuffix('.cjs'), ['node', 'tests/' + path, *args]))

    for path in ('settings/run', 'settings/presentation', 'settings/appearance',
                 'settings/reorder', 'settings/assets', 'settings/actions',
                 'settings/media'):
        py(path + '.py')
    py('settings/reorder.py', '--hub')
    for fixture in ('modules.qml', 'control-layout.qml', 'action-layout.qml',
                    'catalogue-layout.qml', 'anchored-layout.qml', 'wifi-inline.qml',
                    'window.qml', 'catalogue'):
        py('settings/modules.py', fixture)
    js('settings/catalogue.cjs')
    js('settings/icons.cjs', '.config/quickshell/magi/icons')
    js('visual/state.cjs')
    for phase in ('phase10a', 'phase10b', 'phase10c1', 'phase12a', 'phase12c',
                  'phase12d', 'phase12e', 'phase12f', 'phase12g', 'phase12h',
                  'phase13a', 'phase13b', 'phase14a', 'phase14b'):
        py(phase + '/run.py')
    py('phase10a/icon-fallback.py')
    py('phase12b/palettes.py')
    for phase in ('phase12g', 'phase12h', 'phase13a', 'phase13b'):
        py(phase + '/presentation.py')
    py('phase14a/fleet.py')
    for path in ('displays/run', 'fingerprint/run', 'hub/run', 'shared-status-surface/run',
                 'bluetooth/run', 'bluetooth/bus', 'calendar/presentation', 'calendar/bar',
                 'clipboard/model', 'clipboard/presentation', 'emoji/backend',
                 'emoji/presentation', 'launcher/backend', 'launcher/presentation',
                 'launcher/lifecycle', 'notifications/run', 'notifications/presentation',
                 'wallpaper/backend', 'wallpaper/presentation', 'weather/backend',
                 'theme-orchestrator/run', 'theme-orchestrator/bootstrap', 'theme-orchestrator/qml',
                 'theme-orchestrator/native', 'phase2e/keybindings'):
        py(path + '.py')
    for path in ('calendar/math', 'calendar/schema', 'clipboard/schema',
                 'emoji/model', 'emoji/schema', 'launcher/schema', 'launcher/search',
                 'notifications/policy', 'wallpaper/schema'):
        js(path + '.cjs')
    py('runtime-visual/run.py')
    for fixture in ('theme-gallery.qml', 'settings-product.qml', 'quality.qml', 'palettes.qml', 'profile.qml', 'appearance.qml', 'colours.qml', 'feedback.qml',
                    'polish.qml', 'secondary.qml', 'typography.qml', 'weather.qml',
                    '../phase12b/surfaces.qml', '../phase12d/runtime.qml'):
        py('runtime-visual/run.py', fixture)
    py('native_lock.py')
    return result


def clipboard_decoder_limit(env):
    """Independent valid-PNG probe; only a specific transport denial is an ENV limit."""
    probe = """import runpy, gi
from pathlib import Path
gi.require_version('GdkPixbuf', '2.0')
from gi.repository import GdkPixbuf
fixture = runpy.run_path('tests/clipboard/model.py')
try:
    loader = GdkPixbuf.PixbufLoader.new_with_type('png')
    loader.write(fixture['PNG'])
    loader.close()
    assert loader.get_pixbuf().get_width() == 1
except Exception as error:
    print(type(error).__name__ + ': ' + str(error))
"""
    result = subprocess.run([sys.executable, '-c', probe], cwd=ROOT, env=env,
                            capture_output=True, text=True, timeout=20)
    text = result.stdout + result.stderr
    return 'D-Bus error' in text and 'Operation not permitted' in text, text


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--list', action='store_true')
    parser.add_argument('--only', action='append', default=[], help='Exact suite ID; repeatable')
    parser.add_argument('--logs', type=Path, help='New output directory (default: mkdtemp)')
    args = parser.parse_args()
    matrix = suites()
    unknown = set(args.only) - {name for name, _ in matrix}
    if unknown:
        parser.error('Unknown suites: ' + ', '.join(sorted(unknown)))
    if args.only:
        matrix = [(name, command) for name, command in matrix if name in args.only]
    if args.list:
        for name, command in matrix:
            print(name, ':', ' '.join(command))
        return 0
    logs = args.logs.resolve() if args.logs else Path(tempfile.mkdtemp(prefix='magi-regression-'))
    if args.logs:
        logs.mkdir(parents=True, exist_ok=False)
    print('Logs:', logs, flush=True)
    env = dict(os.environ, PYTHONDONTWRITEBYTECODE='1', QT_QPA_PLATFORM='offscreen',
               QT_QUICK_BACKEND='software', MAGI_TEST_QPA='offscreen',
               MAGI_TEST_RENDERER='software',
               HYPRLAND_INSTANCE_SIGNATURE='magi-offline-regression-no-compositor',
               DBUS_SESSION_BUS_ADDRESS='unix:path=' + str(logs / 'no-session-bus'),
               DBUS_SYSTEM_BUS_ADDRESS='unix:path=' + str(logs / 'no-system-bus'))
    for key in ('DISPLAY', 'WAYLAND_DISPLAY'):
        env.pop(key, None)
    # User capture/fixture overrides must not make the default matrix write elsewhere.
    for key in list(env):
        if key.startswith('MAGI_') and key not in ('MAGI_TEST_QPA', 'MAGI_TEST_RENDERER'):
            env.pop(key)
    results = []
    for number, (name, command) in enumerate(matrix, 1):
        start = time.monotonic()
        path = logs / (f'{number:03d}-' + name.replace('/', '-').replace(':', '-') + '.log')
        status = 'FAIL'
        reason = 'Nonzero harness exit'
        classification = 'UNKNOWN'
        timeout = 180 if name == 'launcher/lifecycle' else 600
        with path.open('w') as output:
            try:
                run = subprocess.Popen(command, cwd=ROOT, env=env, stdout=output,
                                       stderr=subprocess.STDOUT, start_new_session=True)
                try:
                    code = run.wait(timeout=timeout)
                except subprocess.TimeoutExpired:
                    os.killpg(run.pid, signal.SIGTERM)
                    try:
                        run.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        os.killpg(run.pid, signal.SIGKILL)
                        run.wait()
                    raise
                if code == 0:
                    status = 'PASS'
                    reason = 'Harness completed without failure signatures'
                    classification = 'PASS'
            except (subprocess.TimeoutExpired, OSError) as error:
                output.write(str(error) + '\n')
                code = None
                reason = str(error)
        evidence = path.read_text(errors='replace')
        failure = re.search(r'(?m)^\s*(?:FAIL!?:|(?:ERROR|WARN).*\bFAIL\b|AssertionError|Traceback \(most recent call last\))', evidence)
        if status == 'PASS' and failure:
            status = 'FAIL'
            classification = 'UNKNOWN'
            reason = 'Failure signature despite zero exit: ' + failure.group(0).strip()
        # Narrow classification: private-bus setup failure is not a protocol pass.
        if status == 'FAIL' and name in ('bluetooth/bus', 'notifications/run'):
            if 'Failed to start message bus' in evidence and 'Operation not permitted' in evidence:
                status = 'ENVIRONMENT'
                classification = 'ENVIRONMENT LIMIT'
                reason = 'Private D-Bus creation denied with Operation not permitted'
        if status == 'FAIL' and name == 'clipboard/model':
            errors = re.findall(r'^ERROR: (\w+) ', evidence, re.MULTILINE)
            expected_errors = {'test_image_cleanup_and_limits', 'test_image_eviction_and_persisted_cleanup'}
            if set(errors) == expected_errors and len(errors) == 2 and 'FAILED (errors=2)' in evidence:
                denied, probe = clipboard_decoder_limit(env)
                (logs / 'clipboard-decoder-probe.log').write_text(probe)
                if denied:
                    status = 'ENVIRONMENT'
                    classification = 'ENVIRONMENT LIMIT'
                    reason = 'Independent valid PNG decode reports D-Bus Operation not permitted; only the two image tests failed'
        if status == 'FAIL' and name == 'native_lock' and code == 77:
            marker = 'MAGI_NATIVE_ENVIRONMENT: audited unchanged transport tests blocked by independently proven SOCK_SEQPACKET EPERM'
            if marker in evidence:
                native = next((json.loads(line.removeprefix('NATIVE_RESULTS ')) for line in evidence.splitlines()
                               if line.startswith('NATIVE_RESULTS ')), {})
                if native.get('seqpacket_denied') and native.get('native_source_matches_audited_baseline') and native.get('build') == 'PASS':
                    status = 'ENVIRONMENT'
                    classification = 'ENVIRONMENT LIMIT'
                    reason = 'Clean native build passed; unchanged audited transport failures plus independent SOCK_SEQPACKET EPERM (internal case counts in log)'
        row = dict(suite=name, command=command, status=status, exit=code,
                   classification=classification, reason=reason,
                   seconds=round(time.monotonic()-start, 1), log=path.name)
        results.append(row)
        for filename in ('results.json', 'summary.json'):
            (logs / filename).write_text(json.dumps(results, indent=2) + '\n')
        print(f'{number}/{len(matrix)} {status} {name} ({row["seconds"]}s)', flush=True)
    counts = {status: sum(row['status'] == status for row in results)
              for status in ('PASS', 'FAIL', 'ENVIRONMENT', 'SKIPPED')}
    print('MAGI regression summary\n-----------------------', flush=True)
    for status, count in counts.items():
        print(f'{status:<12} {count:3}', flush=True)
    print('Logs:', logs, flush=True)
    return 1 if counts['FAIL'] else 2 if counts['ENVIRONMENT'] else 0


if __name__ == '__main__':
    sys.exit(main())
