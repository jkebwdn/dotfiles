#!/usr/bin/env python3
"""Generate MAGI metadata from the pinned, official Unicode emoji-test file.
Download SOURCE manually, then run: python3 tools/generate_emoji.py SOURCE_FILE OUTPUT
No network access or third-party modules required by the generator.
"""
import hashlib
import json
from pathlib import Path
import re
import sys

SOURCE = 'https://www.unicode.org/Public/17.0.0/emoji/emoji-test.txt'
SHA256 = '1d8a944f88d7952f7ef7c5167fef3c67995bcae24543949710231b03a201acda'
VERSION = '17.0'


def parse(text):
    group = subgroup = None
    entries, seen = [], set()
    for line in text.splitlines():
        if line.startswith('# group: '):
            group = line.removeprefix('# group: ')
        elif line.startswith('# subgroup: '):
            subgroup = line.removeprefix('# subgroup: ')
        elif line.strip() and not line.startswith('#'):
            match = re.fullmatch(r'([0-9A-F ]+)\s*;\s*([\w-]+)\s*#\s*(\S+)\s+E([\d.]+)\s+(.+)', line)
            if not match:
                raise ValueError('Malformed emoji row')
            points, status, display, version, name = match.groups()
            if status != 'fully-qualified':
                continue
            sequence = ''.join(chr(int(p, 16)) for p in points.split())
            if not group or not subgroup or sequence != display or sequence in seen:
                raise ValueError('Invalid, ungrouped or duplicate emoji')
            seen.add(sequence)
            entries.append(dict(id='-'.join(points.split()), emoji=sequence, name=name,
                                group=group, subgroup=subgroup, version=version))
    if not entries:
        raise ValueError('Empty dataset')
    return entries


def generate(raw):
    if hashlib.sha256(raw).hexdigest() != SHA256:
        raise ValueError('Source checksum mismatch: review version and source before updating')
    return dict(unicodeVersion=VERSION, source=SOURCE, sourceSha256=SHA256,
                entries=parse(raw.decode('utf-8')))


if __name__ == '__main__':
    result = generate(Path(sys.argv[1]).read_bytes())
    Path(sys.argv[2]).write_text(json.dumps(result, ensure_ascii=False, separators=(',', ':')) + '\n', encoding='utf-8')
    print(f"Generated {len(result['entries'])} fully-qualified emoji (Unicode {VERSION})")
