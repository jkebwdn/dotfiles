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
# Host audit 2026-10-30: exact candidate source passed 23/23 CTest and
# 18/18 Rust tests, including the private mock fprintd broker. Package build and
# installation audit also passed. See docs/review/lock-fingerprint-production.md.
# Any subsequent native source change must earn a new host audit.
AUDITED_NATIVE = {
    'CMakeLists.txt': '4d881da889e94d9329fc574c98d5b45c6a81e5f18e0a5a11c1dc9f7889f49345',
    'fingerprint/broker.cpp': 'b4c93a698143a3f44a471534db741ec67461b9a2700262b4987f4ba84e8dc3c8',
    'fingerprint/broker.hpp': '97722860983b092ad7ba6a72c47fce96123a80bcc5de14db04dd0565ad7baee8',
    'fingerprint/model.hpp': 'ed4c2c88dcff01c5133d1f82cdfbb1f23a941187011590902a82ea4152b91399',
    'packaging/PKGBUILD.in': '8bd48f642cad500f9b700e29f7b1315ba654400c8f86fa0f069a716a52955585',
    'packaging/prepare-source.py': '307465f3af3cccc8264655a93655fd083063322b1695b5a7d9f06dfa09e41440',
    'qml/LockAuxiliary.qml': 'e2e68555a3f0a0d28d6a71fb5866d91241d6b33566eaa3c488aca26831a98b8b',
    'qml/LockCapsIcon.qml': '9ea9e23436b0fbdcee463cc6ed6d4da494b44822290602ff391f8f988fb31fe9',
    'qml/LockClock.qml': '3a3831bf9172f11fd4772b4823ba442a84da8e5fef5e453b7ecfacafbf357ade',
    'qml/LockCredential.qml': 'b06b884a1df082faff37aaa1ca6ba480bd32f9974aac7018eda87d553cc9cd4e',
    'qml/LockFingerprint.qml': '511279dea2e97a6df681f0c9ee2409cee49e9edd8b75b5f8a84967322c62237f',
    'qml/LockLayout.js': '8812aa1f0bbb49829f29ec59a0f36d14c312536d53666eecbfca2423da759eb8',
    'qml/LockMediaIcon.qml': '7ea05261d9eeb514e5fe8d1a148b6f1af4dbb42c63b686788d0bc0908c9b00b3',
    'qml/LockProfile.qml': '09812c715cf52f8910c2149c3b493d7682cb98ce17a781342fd8601a43559466',
    'qml/LockScreen.qml': 'e37d0d20ddf7853d4fdd33d09580d6bf5791d7c761c5e3bdaa5a32475d8ffe27',
    'qml/LockStatus.qml': '8b7c1354b11cb4fe8c693bb74745c23a53194bb70292ff028f7df0a464373a65',
    'qml/LockTokens.qml': '499a792ef843aa9f10aa03c365b9485643c14b1e86ebb3bd535b92d4b5603776',
    'qml/qmldir': '5ec0e7a8782d9d65e811b92963e5ef4ec1a81899896b1b91fbfa7360f6488acc',
    'src/auth_presentation.hpp': 'e677e30d107416bc97a9b55def37083648cd58638c43e2519495d1228e5167f4',
    'src/controller.cpp': '27ed80a5d190ae25e8b6ff74fcb3a68cae12b5cc3a35f93989c7cb8af41fc9bd',
    'src/controller.hpp': 'c3616a32dbc9e207a2bd4998e152fa7d9fc518bff4c0ad25edc1afedac3e375c',
    'src/power_intent.hpp': 'fbf10d0f42c2d94f37e1007106e1e8c14b4ec2841b8947168b71e2424d29b3f2',
    'src/presentation.cpp': '79f809d6e30b19f749a949ae5b653d8124f0329588a4fc136e481eea6ea7cd89',
    'src/presentation.hpp': 'f3315be52d5b9254ac50f3c0f73dff46490c984abfdfe3ac41e13178fd8bb655',
    'src/visual_data.cpp': '3598cbb19d124ccb0a4ac4b58ed6e4d089e49bca7dd06e1325d31b20e20a0b14',
    'src/visual_data.hpp': '78d7c42c899f4f51c34791ed52584cbecbcdcdbbdac473e5a70c7d14f61abad5',
    'src/wayland_owner.cpp': '5f446bea8520b1590fe468812ae61d3774d8450966e2a5771d3b0a611ca65bc2',
    'src/wayland_owner.hpp': 'e7b1a4cff9c92fb928a7926b29376c5348db487840f8163749aae1345c3f9ec2',
    'tests/auxiliary_test.cpp': '4804b2e189aa7ca1b9be9d85f15638fa1333a39ccab356413377dd9b00882e8a',
    'tests/binary_gate.cmake': '91e961d8fb95daedf55783507d67a49a36c6693ba8f28326d663f855d9c4d71f',
    'tests/fingerprint_broker_test.cpp': 'd5f91d68bd1471ad92385d76585e48421a2d5530ca41d2fcebcee35052de2c50',
    'tests/fingerprint_broker_test.py': 'd2e58d1ae1c20325fde4173b0da3ba1e1e80aa3aa191ef5e5afb6c26b973ad1f',
    'tests/power_intent_test.cpp': '927b0abef209103f7726ea5e0e28d23a60ee258bf8b26bb4107a8f6799281f92',
    'tests/presentation_boundary.cmake': '1086ce5a5cdf7637993e2902b204a3109f2d8433e304230810cf0bb03530ada5',
    'tests/visual_test.cpp': 'fa2d5a7c208785808d4b84b9c6ef5eae878b8588c07ad08e98554f85e130376b',
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
        exclusions = [':(exclude)linux/magi/native/lock/' + name for name in AUDITED_NATIVE]
        unchanged = all(hashlib.sha256((NATIVE/name).read_bytes()).hexdigest() == digest
                        for name, digest in AUDITED_NATIVE.items()) and subprocess.run(
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
        if not ctest.returncode and not rust.returncode and not failed and not rust_failed and not skipped:
            return 0
        known_ctest = bool(failed) and set(failed) == set(CTEST_LIMITS) and all(
            signature in ''.join(failed[name].itertext()) for name, signature in CTEST_LIMITS.items())
        known_rust = rust_failed == RUST_LIMITS and 'Err` value: Cancelled' in rust.stdout \
            and 'left: -1' in rust.stdout and 'right: 48' in rust.stdout
        known_skips = set(skipped) == {'fingerprint_transport', 'fingerprint_broker'} and any(
            c.attrib['name'] == 'fingerprint_broker' and 'Private D-Bus socket bind denied' in ''.join(c.itertext()) for c in cases)
        if denied and unchanged and known_ctest and known_rust and known_skips and ctest.returncode == 8 and rust.returncode == 101:
            print('MAGI_NATIVE_ENVIRONMENT: host-audited native source blocked by independently proven SOCK_SEQPACKET EPERM and private D-Bus bind denial', flush=True)
            return 77
        return 1


if __name__ == '__main__':
    sys.exit(main())
