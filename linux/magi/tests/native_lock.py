#!/usr/bin/env python3
"""Clean offline native build and synthetic tests. Never install, lock or invoke PAM.

Exit77 means an evidenced sandbox transport limitation, not a security-test pass.
All build roots are temporary and removed on exit. Full command output is retained
by run-all's log, including failures classified as environment-limited.
"""
from pathlib import Path
import errno
import hashlib
import json
import os
import re
import socket
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
NATIVE = ROOT / 'native/lock'
BASELINE = '4a26d6232c97266f011355b8fb932f8e0436c0e6'
# Phase 16B: the operator ran this exact presentation-only delta on the host:
# 21/21 CTest and 18/18 Rust tests pass (2026-10-28). Keep all other native
# files identical to BASELINE. Hashes prevent future presentation edits from
# silently inheriting this environment classification. See the Phase 16B review.
AUDITED_PRESENTATION = {
    'qml/LockCredential.qml': '667653887b956ad7960ec24ec799b9b8f779e52cf9da7385ab9223ed690b858f',
    'tests/auxiliary_test.cpp': 'e4f83f1cc14c9e9e1baf6272083531c4abba1a2c68d461adb35bd8230568a291',
}

CTEST_LIMITS = {
    'auth_production': 'Check failed at line 125',
    'auth_development': 'Check failed at line 125',
    'sleep_synthetic': 'after 23 scenarios: check failed: done()',
    'output_synthetic': 'line 28: done()',
    'presentation_offscreen': '',
}
RUST_LIMITS = {
    'framing_rejects_version_truncation_size_unknown_and_nul',
    'all_styles_batch_multiple_prompts_and_success',
    'cancellation_bad_order_oversize_disconnect_partial_batch_cleanup',
    'failed_backend_and_invalid_pam_style', 'prompt_limit_and_unsolicited_response',
    'wrong_handshake_never_calls_backend', 'startup_cancel_does_not_call_backend',
    'dropping_parent_worker_kills_and_reaps_stuck_child',
    'inherited_spawn_exit_and_secret_output_regression',
    'real_worker_cancelled_before_pam_start',
}


def run(command, env, timeout=300):
    print('COMMAND', json.dumps([str(x) for x in command]), flush=True)
    result = subprocess.run(command, cwd=ROOT, env=env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=timeout)
    print(result.stdout, flush=True)
    return result


def main():
    denied = False
    try:
        a, b = socket.socketpair(socket.AF_UNIX, socket.SOCK_SEQPACKET)
        try:
            a.send(b'fixture')
            assert b.recv(32) == b'fixture'
        finally:
            a.close(); b.close()
    except PermissionError as error:
        denied = error.errno == errno.EPERM
        print('SOCK_SEQPACKET probe:', repr(error), flush=True)
    unchanged = subprocess.run(['git', 'diff', '--quiet', BASELINE, '--',
        'linux/magi/native/lock'], cwd=ROOT.parents[1]).returncode == 0
    if not unchanged:
        exclusions = [':(exclude)linux/magi/native/lock/' + name for name in AUDITED_PRESENTATION]
        unchanged = all(hashlib.sha256((NATIVE/name).read_bytes()).hexdigest() == digest
                        for name, digest in AUDITED_PRESENTATION.items()) and subprocess.run(
            ['git', 'diff', '--quiet', BASELINE, '--', 'linux/magi/native/lock', *exclusions],
            cwd=ROOT.parents[1]).returncode == 0
    with tempfile.TemporaryDirectory(prefix='magi-native-regression-') as temporary:
        stage = Path(temporary); auth = stage/'auth'; build = stage/'build'
        runtime = stage/'runtime'; runtime.mkdir(mode=0o700)
        env = dict(os.environ, HOME=str(stage), XDG_RUNTIME_DIR=str(runtime),
                   XDG_CONFIG_HOME=str(stage/'config'), XDG_DATA_HOME=str(stage/'data'),
                   XDG_STATE_HOME=str(stage/'state'), XDG_CACHE_HOME=str(stage/'cache'),
                   QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software')
        # Cargo's preinstalled offline registry is read-only input, not runtime state.
        env['RUSTUP_HOME'] = os.environ.get('RUSTUP_HOME', str(Path.home()/'.rustup'))
        env['CARGO_HOME'] = os.environ.get('CARGO_HOME', str(Path.home()/'.cargo'))
        cargo = ['cargo', '--locked', '--offline', '--manifest-path', str(NATIVE/'auth/Cargo.toml'),
                 '--target-dir', str(auth), '--all-targets']
        commands = [[cargo[0], 'build', *cargo[1:]],
                    ['cmake', '-S', str(NATIVE), '-B', str(build), '-G', 'Ninja',
                     '-DCMAKE_BUILD_TYPE=Debug', '-DMAGI_LOCK_AUTH_WORKER='+str(auth/'debug/magi-lock-auth'),
                     '-DMAGI_LOCK_AUTH_FIXTURE='+str(auth/'debug/examples/protocol_fixture'),
                     '-DMAGI_LOCK_VISUAL_PREVIEW=ON'],
                    ['cmake', '--build', str(build), '-j3']]
        for command in commands:
            if run(command, env).returncode: return 1
        print('Native clean build PASS', flush=True)
        ctest = run(['ctest', '--test-dir', str(build), '--output-on-failure',
                     '--output-junit', str(stage/'ctest.xml')], env)
        rust = run([cargo[0], 'test', *cargo[1:]], env)
        cases = ET.parse(stage/'ctest.xml').getroot().findall('testcase')
        failed = {c.attrib['name']: c for c in cases if c.find('failure') is not None}
        skipped = [c.attrib['name'] for c in cases if c.find('skipped') is not None]
        rust_failed = set(re.findall(r'^test (\S+) \.\.\. FAILED$', rust.stdout, re.MULTILINE))
        rust_passed = re.findall(r'^test (\S+) \.\.\. ok$', rust.stdout, re.MULTILINE)
        summary = dict(build='PASS', ctest=dict(total=len(cases), passed=len(cases)-len(failed)-len(skipped),
                       failed=sorted(failed), skipped=skipped),
                       rust=dict(passed=len(rust_passed), failed=sorted(rust_failed)),
                       seqpacket_denied=denied, native_source_matches_audited_baseline=unchanged)
        print('NATIVE_RESULTS ' + json.dumps(summary), flush=True)
        if not ctest.returncode and not rust.returncode and not failed and not rust_failed:
            return 0
        known_ctest = bool(failed) and set(failed) == set(CTEST_LIMITS) and all(
            signature in ''.join(failed[name].itertext()) for name, signature in CTEST_LIMITS.items())
        known_rust = rust_failed == RUST_LIMITS and 'Err` value: Cancelled' in rust.stdout \
            and 'left: -1' in rust.stdout and 'right: 48' in rust.stdout
        if denied and unchanged and known_ctest and known_rust and ctest.returncode == 8 and rust.returncode == 101:
            print('MAGI_NATIVE_ENVIRONMENT: audited unchanged transport tests blocked by independently proven SOCK_SEQPACKET EPERM', flush=True)
            return 77
        return 1


if __name__ == '__main__':
    sys.exit(main())
