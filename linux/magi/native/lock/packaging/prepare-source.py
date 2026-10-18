"""Create a deterministic local source archive + checksummed PKGBUILD, never install.
Usage: python3 prepare-source.py /tmp/magi-lock-package
Cargo dependencies must already be cached; no network fetch is performed here.
"""
import gzip
import hashlib
import io
from pathlib import Path
import sys
import tarfile

source = Path(__file__).resolve().parents[1]
output = Path(sys.argv[1]).resolve()
if output == source or source in output.parents:
    raise SystemExit('Use an output directory outside the source tree')
output.mkdir(parents=True, exist_ok=True)
files = [source / 'CMakeLists.txt', source / 'auth/Cargo.toml', source / 'auth/Cargo.lock']
for directory in ['src', 'qml', 'integration', 'tests', 'auth/src', 'auth/tests', 'auth/examples']:
    files += [p for p in (source / directory).rglob('*') if p.is_file() and '__pycache__' not in p.parts and p.suffix != '.pyc']
archive = output / 'magi-lock-0.1.0.tar.gz'
with archive.open('xb') as raw, gzip.GzipFile(fileobj=raw, mode='wb', filename='', mtime=0) as zipped:
    with tarfile.open(fileobj=zipped, mode='w') as tar:
        for p in sorted(files):
            if p.is_symlink():
                raise SystemExit('Source symlinks are not permitted')
            data = p.read_bytes()
            entry = tarfile.TarInfo('magi-lock-0.1.0/' + str(p.relative_to(source)))
            entry.size = len(data)
            entry.mode = 0o755 if p.name == 'magi-lock-request' else 0o644
            entry.mtime = 0
            tar.addfile(entry, io.BytesIO(data))
digest = hashlib.sha256(archive.read_bytes()).hexdigest()
recipe = (source / 'packaging/PKGBUILD.in').read_text().replace('@SOURCE_SHA256@', digest)
(output / 'PKGBUILD').write_text(recipe)
print(f'{archive}: SHA256 {digest}; {len(files)} source files; local package only')
