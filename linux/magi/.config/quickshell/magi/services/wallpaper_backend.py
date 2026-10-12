"""hyprpaper 0.8.4 adapter. Runtime IPC only; never writes compositor config."""
import json
from pathlib import Path
import subprocess
import time

MODES = ('cover', 'contain', 'stretch', 'tile')


def run(args):
    try:
        result = subprocess.run(args, capture_output=True, text=True, timeout=5)
    except (OSError, subprocess.TimeoutExpired) as error:
        raise RuntimeError(f'Wallpaper backend unavailable: {error}') from error
    if result.returncode or result.stdout.strip().lower().startswith('error:'):
        raise RuntimeError((result.stderr.strip() or result.stdout.strip() or 'hyprctl failed')[:1000])
    return result.stdout


def command(monitor, path, mode):
    if mode not in MODES or not isinstance(monitor, str) or not isinstance(path, str) or not path.startswith('/'):
        raise ValueError('Invalid wallpaper target, path or fit mode.')
    # hyprctl parses comma-separated fields and trims whitespace; it has no escaping.
    if ',' in monitor + path or any(ord(c) < 32 or ord(c) == 127 for c in monitor + path) or path != path.strip() or monitor != monitor.strip():
        raise ValueError('hyprpaper cannot address paths/monitors with commas, newlines or outer whitespace.')
    return ['hyprctl', 'hyprpaper', 'wallpaper', f'{monitor},{path},{mode}']


def monitors():
    data = json.loads(run(['hyprctl', '-j', 'monitors']))
    return [{'name': m['name'], 'description': m.get('description', '')} for m in data if m.get('name')]


def active():
    result = {}
    for line in run(['hyprctl', 'hyprpaper', 'listactive']).splitlines():
        name, separator, path = line.partition(': ')
        if separator and path.startswith('/'):
            result[name] = str(Path(path).resolve())
    return result


def apply(monitor, path, mode):
    run(command(monitor, path, mode))
    # An IPC acknowledgement precedes async image loading. Confirm actual active path.
    for _ in range(15):
        if active().get(monitor) == path:
            return
        time.sleep(0.1)
    raise RuntimeError(f'hyprpaper did not confirm the wallpaper on {monitor}.')
