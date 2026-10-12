"""Read-only, nonrecursive wallpaper discovery. No image processing dependencies."""
import os
from pathlib import Path

MAX_ROOTS = 16
MAX_ENTRIES = 10000
MAX_VISITED = 50000


def valid_path(value):
    return (isinstance(value, str) and 0 < len(value) <= 4096
            and (value.startswith('/') or value.startswith('~/'))
            and not any(ord(c) < 32 or ord(c) == 127 for c in value))


def roots(values):
    if not isinstance(values, list) or len(values) > MAX_ROOTS or not all(map(valid_path, values)):
        raise ValueError('Use up to 16 absolute directories or ~/ paths, one per line.')
    return list(dict.fromkeys(str(Path(p).expanduser().resolve()) for p in values))


def image_file(path):
    """Gate by extension and magic; Qt handles actual decoding at display/apply time."""
    if path.suffix.lower() not in ('.png', '.jpg', '.jpeg') or not path.is_file():
        return False
    with path.open('rb') as stream:
        header = stream.read(12)
    return (path.suffix.lower() == '.png' and header.startswith(b'\x89PNG\r\n\x1a\n')
            or path.suffix.lower() in ('.jpg', '.jpeg') and header.startswith(b'\xff\xd8\xff'))


def scan(values):
    entries, warnings, seen = [], [], set()
    visited = 0
    for directory in roots(values):
        try:
            with os.scandir(directory) as children:
                for child in children:
                    visited += 1
                    if visited > MAX_VISITED or len(entries) >= MAX_ENTRIES:
                        return {'entries': entries, 'warnings': warnings + ['Library scan limit reached (10,000 images / 50,000 entries).']}
                    try:
                        path = Path(child.path).resolve()
                        if not image_file(path):
                            continue
                        stat = path.stat()
                        identity = (stat.st_dev, stat.st_ino)
                        if identity in seen:
                            continue
                        seen.add(identity)
                        entries.append({'path': str(path), 'url': path.as_uri(), 'name': path.name})
                    except (OSError, ValueError, RuntimeError):
                        continue
        except OSError as error:
            warnings.append(f'{directory}: {error.strerror}')
    entries.sort(key=lambda entry: (entry['name'].casefold(), entry['path']))
    return {'entries': entries, 'warnings': warnings}
