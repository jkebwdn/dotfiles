#!/usr/bin/env python3
"""MAGI settings I/O: one JSON request on stdin, one response on stdout.

No shell interpolation. Atomic replacement preserves a symlink's target.
The advisory lock coordinates MAGI writers; the content check detects stale
external edits, but cannot lock an unrelated editor's rename operation.
"""
import fcntl
import hashlib
import json
import os
from pathlib import Path
import stat
import sys
import tempfile

CURRENT_VERSION = 2


def perform(request):
    path = Path(request['path']).expanduser().resolve()
    if request['op'] == 'read':
        return {'ok': True, 'text': path.read_text() if path.exists() else None}
    if request['op'] != 'write':
        raise ValueError('Unknown settings operation')
    # Creating parents is appropriate only for an explicit save, never a read.
    path.parent.mkdir(parents=True, exist_ok=True)
    state = Path(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state')))
    locks = state / 'magi/settings-locks'
    locks.mkdir(parents=True, exist_ok=True, mode=0o700)
    lock_path = locks / hashlib.sha256(str(path).encode()).hexdigest()
    with lock_path.open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        before = path.read_text() if path.exists() else None
        if before != request['expected']:
            return {'ok': False, 'conflict': True, 'error': 'Settings changed on disk; reload before saving'}
        text = request['text']
        json.loads(text)
        try:
            prior_version = json.loads(before).get('schemaVersion', 0) if before else 0
        except (ValueError, AttributeError):
            prior_version = 0
        if before is not None and prior_version != CURRENT_VERSION:
            state = Path(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state')))
            backups = state / 'magi/settings-backups'
            backups.mkdir(parents=True, exist_ok=True, mode=0o700)
            name = hashlib.sha256((str(path) + '\0' + before).encode()).hexdigest() + '.json'
            backup = backups / name
            if not backup.exists():
                with backup.open('x') as output:
                    os.chmod(backup, 0o600)
                    output.write(before)
                    output.flush()
                    os.fsync(output.fileno())
        mode = stat.S_IMODE(path.stat().st_mode) if path.exists() else 0o600
        fd, temp = tempfile.mkstemp(prefix='.' + path.name + '-', dir=path.parent)
        try:
            with os.fdopen(fd, 'w') as output:
                os.fchmod(output.fileno(), mode)
                output.write(text)
                output.flush()
                os.fsync(output.fileno())
            # Recheck after backup/write work, immediately before replacing.
            if (path.read_text() if path.exists() else None) != before:
                return {'ok': False, 'conflict': True, 'error': 'Settings changed during save'}
            os.replace(temp, path)
            directory = os.open(path.parent, os.O_DIRECTORY)
            try:
                os.fsync(directory)
            finally:
                os.close(directory)
        finally:
            if os.path.exists(temp):
                os.unlink(temp)
        return {'ok': True, 'text': text}


if __name__ == '__main__':
    try:
        result = perform(json.loads(sys.stdin.readline()))
    except Exception as error:
        result = {'ok': False, 'error': str(error)}
    print(json.dumps(result), flush=True)
