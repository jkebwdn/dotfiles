"""Private generation store and compare-before-write integration journal."""
import contextlib
import difflib
import fcntl
import json
import os
from pathlib import Path
import tempfile
import stat
import hashlib
import re


class Conflict(RuntimeError):
    pass


def sync_directory(path):
    fd = os.open(path, os.O_DIRECTORY)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def atomic(path, text):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, temporary = tempfile.mkstemp(prefix='.magi-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        if path.exists():
            os.chmod(temporary, stat.S_IMODE(path.stat().st_mode))
        os.replace(temporary, path)
        sync_directory(path.parent)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def identity(path):
    path = Path(path)
    return {'path': str(path.absolute()), 'resolved': str(path.resolve()),
            'link': os.readlink(path) if path.is_symlink() else None}


def text_hash(text):
    return hashlib.sha256(text.encode()).hexdigest()


def edit(path, before, after):
    left, right = before.splitlines(True), after.splitlines(True)
    groups = difflib.SequenceMatcher(None, left, right, autojunk=False).get_grouped_opcodes(3)
    chunks = [dict(old=''.join(left[g[0][1]:g[-1][2]]), new=''.join(right[g[0][3]:g[-1][4]]),
                   oldStart=g[0][1], oldEnd=g[-1][2], newStart=g[0][3], newEnd=g[-1][4]) for g in groups]
    # Keep only narrow changed spans/context and hashes, never a complete copy
    # of shell/application configuration merely to remember an import.
    return dict(identity(path), beforeHash=text_hash(before), afterHash=text_hash(after), chunks=chunks,
                existed=path.exists(), diff=''.join(difflib.unified_diff(
                    before.splitlines(True), after.splitlines(True),
                    fromfile=str(path), tofile=str(path))))


def verify(item, expected_hash):
    path = Path(item['path'])
    if identity(path) != {k: item[k] for k in ('path', 'resolved', 'link')}:
        raise Conflict('Configuration path or symlink changed: ' + str(path))
    current = path.read_text() if path.exists() else ''
    if text_hash(current) != expected_hash:
        raise Conflict('Configuration changed since preview: ' + str(path))
    return current


def install(item):
    current = verify(item, item['beforeHash']).splitlines(True)
    for chunk in reversed(item['chunks']):
        current[chunk['oldStart']:chunk['oldEnd']] = chunk['new'].splitlines(True)
    text = ''.join(current)
    if text_hash(text) != item['afterHash']:
        raise Conflict('Invalid integration patch')
    atomic(Path(item['resolved']), text)


def removal(item):
    """Undo only exact inserted spans; preserve unrelated subsequent edits."""
    path = Path(item['path'])
    if identity(path) != {k: item[k] for k in ('path', 'resolved', 'link')}:
        raise Conflict('Configuration path changed: ' + str(path))
    current = path.read_text() if path.exists() else ''
    if text_hash(current) == item['beforeHash']:
        return current
    if text_hash(current) == item['afterHash']:
        lines = current.splitlines(True)
        for chunk in reversed(item['chunks']):
            lines[chunk['newStart']:chunk['newEnd']] = chunk['old'].splitlines(True)
        return ''.join(lines)
    # Context makes repeated style declarations unambiguous. A later edit in a
    # hook's context conservatively conflicts instead of guessing a location.
    for chunk in reversed(item['chunks']):
        old, new = chunk['old'], chunk['new']
        if not new or current.count(new) != 1:
            raise Conflict('MAGI hook edited or ambiguous; remove manually: ' + str(path))
        current = current.replace(new, old, 1)
    return current


class Store:
    def __init__(self, home=None, config=None, data=None, state=None):
        self.home = Path(home or Path.home())
        self.config = Path(config or os.environ.get('XDG_CONFIG_HOME', self.home / '.config'))
        self.data = Path(data or os.environ.get('XDG_DATA_HOME', self.home / '.local/share')) / 'magi/theme-orchestrator'
        self.state = Path(state or os.environ.get('XDG_STATE_HOME', self.home / '.local/state')) / 'magi/theme-orchestrator'
        if not all(p.is_absolute() for p in (self.home, self.config, self.data, self.state)):
            raise Conflict('HOME and XDG roots must be absolute paths')
        for root in (self.data, self.state):
            # Reject symlinked roots and any Git/Stow source location, including XDG overrides.
            if root.absolute() != root.resolve():
                raise Conflict('MAGI storage must not traverse symlinks: ' + str(root))
            if any((p / '.git/HEAD').exists() or (p / '.git').is_file() for p in [root, *root.parents]):
                raise Conflict('MAGI generated/state storage cannot be inside a Git checkout')
        self.journal = self.state / 'state.json'

    @contextlib.contextmanager
    def locked(self):
        if self.state.absolute() != self.state.resolve() or (self.state / 'lock').is_symlink():
            raise Conflict('Ownership state/lock path changed')
        self.state.mkdir(parents=True, exist_ok=True, mode=0o700)
        with (self.state / 'lock').open('a') as stream:
            fcntl.flock(stream, fcntl.LOCK_EX)
            yield

    def load(self):
        if self.journal.is_symlink():
            raise Conflict('Ownership journal was redirected')
        if not self.journal.exists():
            return {'schemaVersion': 1, 'targets': {}}
        result = json.loads(self.journal.read_text())
        if result.get('schemaVersion') != 1:
            raise Conflict('Unsupported ownership journal; refusing to reset it')
        return result

    def save(self, state):
        if self.journal.is_symlink():
            raise Conflict('Ownership journal was redirected')
        atomic(self.journal, json.dumps(state, indent=2, sort_keys=True) + '\n')

    def current(self, target):
        return self.data / target / 'current'

    def publish(self, target, files, digest):
        root = self.data / target
        if root.absolute() != root.resolve():
            raise Conflict('Generated target root traverses a symlink')
        marker = root / '.magi-owner'
        if root.exists() and (not marker.is_file() or marker.is_symlink() or marker.read_text() != 'MAGI theme store v1\n'):
            raise Conflict('Existing target directory is not owned by MAGI')
        if not root.exists():
            atomic(marker, 'MAGI theme store v1\n')
        if not re.fullmatch('[0-9a-f]{64}', digest):
            raise ValueError('Invalid generation identity')
        generation = root / 'generations' / digest
        for name, content in files.items():
            if Path(name).is_absolute() or '..' in Path(name).parts:
                raise ValueError('Invalid generated artifact')
            path = generation / name
            if path.absolute() != path.resolve():
                raise Conflict('Generated artifact traverses a symlink: ' + str(path))
            if path.exists() and path.read_text() != content:
                raise Conflict('Generated artifact was edited: ' + str(path))
            if not path.exists():
                atomic(path, content)
        manifest = {'owner': 'MAGI theme store v1', 'files': {name: hashlib.sha256(content.encode()).hexdigest() for name, content in files.items()}}
        manifest_path = generation / '.manifest.json'
        expected = json.dumps(manifest, sort_keys=True) + '\n'
        if manifest_path.is_symlink() or (manifest_path.exists() and manifest_path.read_text() != expected):
            raise Conflict('Generated ownership manifest changed')
        if not manifest_path.exists():
            atomic(manifest_path, expected)
        pointer = root / 'current'
        if pointer.exists() and not pointer.is_symlink():
            raise Conflict('MAGI current pointer replaced by user')
        if pointer.is_symlink() and not re.fullmatch(r'generations/[0-9a-f]{64}', os.readlink(pointer)):
            raise Conflict('MAGI current pointer was redirected')
        if pointer.is_symlink() and pointer.resolve() == generation:
            return False
        if pointer.is_symlink():
            previous = root / 'previous'
            if (previous.exists() and not previous.is_symlink()) or (previous.is_symlink() and not re.fullmatch(r'generations/[0-9a-f]{64}', os.readlink(previous))):
                raise Conflict('MAGI previous pointer replaced by user')
            previous.unlink(missing_ok=True)
            previous.symlink_to(os.readlink(pointer))
        temporary = root / '.current-next'
        if temporary.exists() or temporary.is_symlink():
            if not temporary.is_symlink() or not re.fullmatch(r'generations/[0-9a-f]{64}', os.readlink(temporary)):
                raise Conflict('Unrecognized pending publication artifact')
            temporary.unlink()
        temporary.symlink_to(Path('generations') / digest)
        os.replace(temporary, pointer)
        sync_directory(root)
        return True

    def prune(self, target, digest):
        """Delete only a journal-listed obsolete generation with intact artifacts."""
        root = self.data / target / 'generations' / digest
        if root.absolute() != root.resolve() or not root.is_dir():
            return False
        manifest_path = root / '.manifest.json'
        if manifest_path.is_symlink() or not manifest_path.is_file():
            return False
        manifest = json.loads(manifest_path.read_text())
        if manifest.get('owner') != 'MAGI theme store v1':
            return False
        expected = {root / name for name in manifest['files']} | {manifest_path}
        actual = {p for p in root.rglob('*') if not p.is_dir()}
        if actual != expected or any(p.is_symlink() for p in root.rglob('*')):
            return False
        for name, checksum in manifest['files'].items():
            path = root / name
            if path.absolute() != path.resolve() or not path.is_relative_to(root):
                return False
            if hashlib.sha256(path.read_bytes()).hexdigest() != checksum:
                return False
        for path in expected:
            path.unlink()
        for path in sorted(root.rglob('*'), key=lambda p: len(p.parts), reverse=True):
            path.rmdir()
        root.rmdir()
        return True
