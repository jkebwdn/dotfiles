#!/usr/bin/env python3
"""One-shot JSON worker: serialized by QML and a cross-process state lock."""
import copy
import fcntl
import json
import os
from pathlib import Path
import sys
import tempfile

import wallpaper_backend as backend
from wallpaper_library import scan, valid_path, image_file


def empty():
    return {'version': 1, 'shared': None, 'monitors': {}, 'favourites': [], 'recents': []}


def assignment(value):
    return (isinstance(value, dict) and valid_path(value.get('path'))
            and value['path'].startswith('/') and value.get('mode') in backend.MODES)


def validate(state):
    if not isinstance(state, dict) or state.get('version') != 1:
        raise ValueError('Unsupported wallpaper state. Preserve the file and repair it before making changes.')
    if state.get('shared') is not None and not assignment(state['shared']):
        raise ValueError('Invalid shared wallpaper state.')
    mappings = state.get('monitors')
    if not isinstance(mappings, dict) or len(mappings) > 32 or not all(
            isinstance(k, str) and 0 < len(k) <= 256 and assignment(v) and isinstance(v.get('description', ''), str)
            for k, v in mappings.items()):
        raise ValueError('Invalid monitor wallpaper state.')
    for key, limit in [('favourites', 512), ('recents', 24)]:
        items = state.get(key)
        if not isinstance(items, list) or len(items) > limit or not all(valid_path(p) and p.startswith('/') for p in items) or len(set(items)) != len(items):
            raise ValueError(f'Invalid wallpaper {key}.')
    return state


def read(path):
    if not path.exists():
        return empty()
    if path.stat().st_size > 1024 * 1024:
        raise ValueError('Wallpaper state exceeds 1 MiB; refusing to overwrite it.')
    return validate(json.loads(path.read_text()))


def save(path, state):
    validate(state)
    fd, name = tempfile.mkstemp(prefix='.wallpaper-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            json.dump(state, stream, ensure_ascii=False)
            stream.write('\n'); stream.flush(); os.fsync(stream.fileno())
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def target_for(state, monitor):
    saved = state['monitors'].get(monitor['name'])
    # Connector plus exact description; don't assign a different display's override.
    if saved and saved.get('description', '') == monitor['description']:
        return saved
    return state['shared']


def perform(request, path):
    state = read(path)
    result = {'ok': True, 'state': state}
    op = request.get('op')
    if op == 'load':
        return result
    if op == 'scan':
        return dict(result, **scan(request.get('directories', [])))
    if op == 'favourite':
        item = request.get('path')
        if not valid_path(item) or not item.startswith('/'):
            raise ValueError('Invalid favourite path.')
        items = state['favourites']
        if item in items:
            items.remove(item)
        elif len(items) < 512:
            items.append(item)
        else:
            raise ValueError('Favourites limit is 512.')
        save(path, state)
        return result
    if op == 'clearRecents':
        state['recents'] = []; save(path, state)
        return result
    connected = backend.monitors()
    before = backend.active()
    result.update(monitors=connected, current=before)
    if op == 'status':
        return result
    if op not in ('apply', 'restore'):
        raise ValueError('Unknown wallpaper operation.')
    if not connected:
        raise RuntimeError('No connected monitors reported by Hyprland.')
    desired = []
    next_state = copy.deepcopy(state)
    if op == 'apply':
        source = Path(request.get('path', '')).resolve()
        mode = request.get('mode', 'cover')
        scope = request.get('monitor', '')
        if not image_file(source):
            raise ValueError('Wallpaper is missing, unreadable or unsupported.')
        selected = [m for m in connected if not scope or m['name'] == scope]
        if not selected:
            raise ValueError('Selected monitor is no longer connected.')
        value = {'path': str(source), 'mode': mode}
        for monitor in selected:
            backend.command(monitor['name'], str(source), mode)  # Validate all before mutation.
            desired.append((monitor, value))
        if not scope:
            next_state['shared'] = value
            next_state['monitors'] = {}
        else:
            if len(next_state['monitors']) >= 32 and scope not in next_state['monitors']:
                raise ValueError('Monitor mapping limit reached (32).')
            next_state['monitors'][scope] = dict(value, description=selected[0]['description'])
        next_state['recents'] = [str(source)] + [p for p in state['recents'] if p != str(source)][:23]
    else:
        for monitor in connected:
            value = target_for(state, monitor)
            if value:
                source = Path(value['path'])
                try:
                    available = image_file(source)
                except OSError:
                    available = False
                if not available:
                    result.setdefault('warnings', []).append(f'Saved wallpaper unavailable: {source}')
                    fallback = state['shared']
                    try:
                        if not fallback or not image_file(Path(fallback['path'])):
                            continue
                    except OSError:
                        continue
                    value = fallback
                desired.append((monitor, value))
    changed = []
    try:
        for monitor, value in desired:
            changed.append(monitor)
            backend.apply(monitor['name'], value['path'], value['mode'])
        if op == 'apply':
            save(path, next_state)
            result['state'] = next_state
    except (OSError, ValueError, RuntimeError) as error:
        rollback_errors = []
        for monitor in reversed(changed):
            old = before.get(monitor['name'])
            if not old:
                rollback_errors.append(f"No previous wallpaper known for {monitor['name']}")
                continue
            previous = target_for(state, monitor)
            old_mode = previous['mode'] if previous and previous['path'] == old else 'cover'
            try:
                backend.apply(monitor['name'], old, old_mode)
            except (OSError, ValueError, RuntimeError) as rollback:
                rollback_errors.append(str(rollback))
        result.update(ok=False, error=str(error) + ('; rollback: ' + '; '.join(rollback_errors) if rollback_errors else ''))
    try:
        result['current'] = backend.active()
    except RuntimeError:
        result['current'] = before
        result['currentUnknown'] = True
    return result


def main():
    try:
        request = json.loads(sys.stdin.readline(1024 * 1024))
        base = Path(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state'))) / 'magi/wallpaper'
        base.mkdir(parents=True, exist_ok=True, mode=0o700)
        with (base / 'state.lock').open('a') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            response = perform(request, base / 'state.json')
    except (OSError, ValueError, RuntimeError) as error:
        response = {'ok': False, 'error': str(error)}
    print(json.dumps(response, ensure_ascii=False), flush=True)


if __name__ == '__main__':
    main()
