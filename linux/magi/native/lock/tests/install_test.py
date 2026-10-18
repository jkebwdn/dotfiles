"""Non-live production deployment audit; never request lock, PAM or sleep."""
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile


def run(*args, **kwargs):
    return subprocess.run(args, check=True, capture_output=True, text=True, **kwargs).stdout


def audit(root):
    expected = {
        'usr/lib/magi/magi-lock': 0o755,
        'usr/lib/magi/magi-lock-auth': 0o755,
        'usr/bin/magi-lock-request': 0o755,
        'usr/lib/systemd/user/magi-lock@.service': 0o644,
        'etc/pam.d/magi-lock': 0o644,
    }
    files = {str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() or p.is_symlink()}
    assert files == set(expected), files
    for name, mode in expected.items():
        p = root / name
        assert not p.is_symlink() and stat.S_IMODE(p.stat().st_mode) == mode, name
    owner = root / 'usr/lib/magi/magi-lock'
    worker = root / 'usr/lib/magi/magi-lock-auth'
    info = run(str(owner), '--build-info')
    assert 'development-unlock=0; failure-injection=0' in info
    assert 'magi-lock' in run(str(owner), '--help')
    for flag in ['--unsafe-development-unlock-after=30', '--development-auth-failure=crash', '--authenticate']:
        assert subprocess.run([str(owner), flag], capture_output=True).returncode == 64
    for binary in [owner, worker]:
        header = run('readelf', '-hW', str(binary))
        dynamic = run('readelf', '-dW', str(binary))
        segments = run('readelf', '-lW', str(binary))
        assert 'DYN (Position-Independent Executable file)' in header
        assert 'GNU_RELRO' in segments and 'BIND_NOW' in dynamic
        stack = next(line for line in segments.splitlines() if 'GNU_STACK' in line)
        assert ' E ' not in stack and 'RWE' not in stack
        assert 'not found' not in run('ldd', str(binary))
        strings = run('strings', str(binary))
        assert not any(s in strings for s in ['UNSAFE DEVELOPMENT TIMER UNLOCK', '--development-auth-failure', 'fixture-success', 'fixture-crash'])
        assert 'hyprlock' not in strings
    assert '/etc/pam.d/magi-lock' in run('strings', str(worker))
    assert '__stack_chk_fail' in run('readelf', '-sW', str(owner))
    assert 'developmentUnlock' not in run('nm', '-C', str(owner))
    pam = (root / 'etc/pam.d/magi-lock').read_text()
    assert pam == '#%PAM-1.0\nauth include login\n'
    for relative in ['usr/bin/magi-lock-request', 'usr/lib/systemd/user/magi-lock@.service', 'etc/pam.d/magi-lock']:
        assert '/tmp/' not in (root / relative).read_text()
    unit = (root / 'usr/lib/systemd/user/magi-lock@.service').read_text()
    assert 'Type=notify' in unit and 'Restart=no' in unit
    assert '--sleep-coordinator=%i' in unit and 'NoNewPrivileges=yes' not in unit
    with tempfile.TemporaryDirectory(prefix='magi-unit-', dir='/tmp') as temp:
        check = Path(temp) / 'magi-lock@.service'
        check.write_text(unit.replace('/usr/lib/magi/magi-lock', str(owner)))
        run('systemd-analyze', '--user', 'verify', str(check))
    # Invalid requests reject before systemctl/bus contact; no live service call.
    for operation in ['unlock', 'stop', 'kill', '/tmp/worker', 'arbitrary.service']:
        assert subprocess.run([str(root / 'usr/bin/magi-lock-request'), operation], capture_output=True).returncode == 64
    print('5-artifact install audit passed: modes, PAM policy, no dev features, ELF hardening, unit, offline CLI')


if __name__ == '__main__':
    if len(sys.argv) == 3 and sys.argv[1] == '--audit':
        audit(Path(sys.argv[2]).resolve())
    else:
        build = Path(sys.argv[1]).resolve()
        with tempfile.TemporaryDirectory(prefix='magi-install-', dir='/tmp') as temp:
            run('cmake', '--install', str(build), env=dict(os.environ, DESTDIR=temp))
            audit(Path(temp))
        source = Path(__file__).resolve().parents[1]
        for forbidden in ['MAGI_LOCK_DEVELOPMENT_UNLOCK=ON', 'MAGI_LOCK_FAILURE_INJECTION=ON', 'MAGI_LOCK_AUTH_WORKER=/tmp/untrusted']:
            with tempfile.TemporaryDirectory(prefix='magi-reject-', dir='/tmp') as temp:
                p = subprocess.run(['cmake', '-S', str(source), '-B', temp,
                                    '-DMAGI_LOCK_PRODUCTION_INSTALL=ON', '-DCMAKE_BUILD_TYPE=Release',
                                    '-DCMAKE_INSTALL_PREFIX=/usr', '-D' + forbidden], capture_output=True, text=True)
                assert p.returncode and any(message in p.stderr for message in
                    ['Production install forbids', 'Failure injection requires development']), p.stderr
        print('3 unsafe production configuration combinations rejected')
