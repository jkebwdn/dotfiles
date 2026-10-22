#!/usr/bin/env python3
"""Narrow Hypridle policy renderer and opt-in managed-service transaction.

No startup activation from Settings, no arbitrary command/config inputs, and no
PID killing. CLI prepare is offline; enroll/recover require the reviewed live gate.
"""
from pathlib import Path
import contextlib
import fcntl
import json
import os
import re
import subprocess
import sys
import tempfile
import time

DEFAULT = dict(lockAfter=300, displayOffAfter=600, suspendAfter=0)
DURATIONS = (0, 60, 120, 300, 600, 900, 1800, 3600)
SUSPEND = (0, 300, 600, 900, 1800, 3600, 7200)
UNIT = 'magi-hypridle.service'
LOCK = '/usr/bin/loginctl lock-session'
WAKE = '/usr/bin/hyprctl dispatch \'hl.dsp.dpms({ action = "enable" })\''
OFF = '/usr/bin/hyprctl dispatch \'hl.dsp.dpms({ action = "disable" })\''
GENERAL = ('general {\n'
           '    lock_cmd = /usr/bin/magi-lock-request sleep-coordinated\n'
           '    inhibit_sleep = 3\n'
           f'    before_sleep_cmd = {LOCK}\n'
           f'    after_sleep_cmd = {WAKE}\n'
           '}\n')

class PolicyError(Exception):
    pass


def policy(document):
    value = document.get('powerIdle', DEFAULT)
    if not isinstance(value, dict):
        raise PolicyError('Power & Idle must be an object.')
    result = {k: value.get(k, default) for k, default in DEFAULT.items()}
    for key, seconds in result.items():
        if type(seconds) is not int or seconds not in (SUSPEND if key == 'suspendAfter' else DURATIONS):
            raise PolicyError('Choose a supported Power & Idle duration.')
    enabled = [result[k] for k in DEFAULT if result[k]]
    if enabled != sorted(enabled):
        raise PolicyError('Enabled timers must run in order: lock, display off, then suspend.')
    return result


def render(value):
    value = policy({'powerIdle': value})
    text = GENERAL
    for key, command in [('lockAfter', LOCK), ('displayOffAfter', OFF),
                         ('suspendAfter', '/usr/bin/systemctl suspend')]:
        if not value[key]:
            continue
        text += f'\nlistener {{\n    timeout = {value[key]}\n    on-timeout = {command}\n'
        if key == 'displayOffAfter':
            text += f'    on-resume = {WAKE}\n'
        text += '}\n'
    return text


def atomic(path, text):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, name = tempfile.mkstemp(prefix='.' + path.name, dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            os.fchmod(stream.fileno(), 0o600)
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(name, path)
        directory = os.open(path.parent, os.O_DIRECTORY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def state_dir():
    return Path(os.environ.get('XDG_STATE_HOME', str(Path.home()/'.local/state'))) / 'magi/power-idle'


def parse_generated(text):
    value = dict.fromkeys(DEFAULT, 0)
    commands = {LOCK:'lockAfter', OFF:'displayOffAfter', '/usr/bin/systemctl suspend':'suspendAfter'}
    for seconds, command in re.findall(r'    timeout = ([0-9]+)\n    on-timeout = ([^\n]+)', text):
        if command not in commands or value[commands[command]]:
            raise PolicyError('Unrecognized or duplicate idle listener.')
        value[commands[command]] = int(seconds)
    if render(value) != text:
        raise PolicyError('Idle policy does not match the mandatory managed configuration.')
    return value


def validate_native(text):
    """Parse with audited 0.1.8 before failing at an unreachable Wayland socket.

    A fresh private runtime dir plus a minimal environment and close_fds prevent
    connection to production Wayland/D-Bus. No event loop or command can execute.
    """
    parse_generated(text)
    for binary in ['hypridle', 'magi-lock-request', 'loginctl', 'hyprctl', 'systemctl', 'pgrep', 'journalctl', 'busctl']:
        if not os.access('/usr/bin/' + binary, os.X_OK):
            raise PolicyError('Required idle or lock helper is unavailable.')
    version = subprocess.run(['/usr/bin/hypridle', '--version'], capture_output=True, text=True, timeout=5)
    if version.stdout.strip() != 'hypridle v0.1.8':
        raise PolicyError('This Hypridle version needs a policy-adapter compatibility review.')
    with tempfile.TemporaryDirectory(prefix='magi-idle-validate-') as tmp:
        config = Path(tmp)/'candidate.conf'
        config.write_text(text)
        env = dict(PATH='/usr/bin', HOME=tmp, XDG_RUNTIME_DIR=tmp, WAYLAND_DISPLAY='absent',
                   DBUS_SESSION_BUS_ADDRESS='unix:path='+tmp+'/absent',
                   DBUS_SYSTEM_BUS_ADDRESS='unix:path='+tmp+'/absent', LC_ALL='C')
        result = subprocess.run(['/usr/bin/hypridle', '--config', str(config)], env=env,
                                capture_output=True, text=True, timeout=5, close_fds=True)
    output = re.sub(r'\x1b\[[0-9;]*m', '', result.stdout + result.stderr)
    # This version warns on a valid zero-listener policy, then continues general
    # sleep/lock coordination. Accept only that exact diagnostic for this case.
    if 'listener {' not in text:
        output = output.replace('Config has errors:\nNo rules configured\nProceeding ignoring faulty entries', '')
    if (result.returncode != 1 or "Couldn't connect to a wayland compositor" not in output
            or 'Config has errors' in output):
        raise PolicyError('Generated idle policy failed Hypridle validation.')


class ServiceController:
    def __init__(self, config):
        self.config = Path(config)

    def command(self, *args):
        try:
            return subprocess.run(args, capture_output=True, text=True, timeout=15, check=True).stdout
        except (OSError, subprocess.SubprocessError) as error:
            raise PolicyError('Could not contact managed Hypridle.') from error

    def safe_to_restart(self):
        # Restart cannot transfer old org.freedesktop.ScreenSaver cookies. Refuse
        # while the audited daemon reports an active D-Bus/logind idle inhibitor.
        invocation = self.command('/usr/bin/systemctl', '--user', 'show', UNIT,
                                  '--property=InvocationID', '--value').strip()
        if not re.fullmatch('[0-9a-f]{32}', invocation):
            raise PolicyError('Could not check idle inhibitors.')
        output = self.command('/usr/bin/journalctl', '--user', '--no-pager', '-o', 'cat',
                              '_SYSTEMD_INVOCATION_ID=' + invocation)
        counts = re.findall(r'Inhibit locks: ([0-9]+)', output)
        if counts and int(counts[-1]):
            raise PolicyError("Power policy can't be changed while idle inhibition is active.")
        # Hyprland exposes active client Wayland inhibitors separately from
        # Hypridle's D-Bus/logind count. MAGI's own layer inhibitor is checked
        # by SettingsStore immediately before submitting the transaction.
        try:
            clients = json.loads(self.command('/usr/bin/hyprctl', '-j', 'clients'))
            if not isinstance(clients, list) or any(type(c.get('inhibitingIdle')) is not bool for c in clients):
                raise ValueError('Unknown inhibitor response')
        except (ValueError, AttributeError) as error:
            raise PolicyError('Could not check idle inhibitors.') from error
        if any(c['inhibitingIdle'] for c in clients):
            raise PolicyError("Power policy can't be changed while idle inhibition is active.")
        sleeping = self.command('/usr/bin/busctl', '--system', 'get-property',
                                'org.freedesktop.login1', '/org/freedesktop/login1',
                                'org.freedesktop.login1.Manager', 'PreparingForSleep').strip()
        if sleeping != 'b false':
            raise PolicyError('Wait until sleep or resume has finished before changing idle policy.')

    def restart(self):
        self.command('/usr/bin/systemctl', '--user', 'restart', UNIT)

    def verify(self):
        deadline = time.monotonic() + 3
        while True:
            try:
                return self.verify_ready()
            except (PolicyError, OSError) as error:
                if time.monotonic() >= deadline:
                    raise PolicyError('Managed Hypridle readiness could not be verified.') from error
                time.sleep(0.1)

    def verify_ready(self):
        # Require one exact managed PID, stable across two samples, and readiness
        # evidence from this invocation (not a successful Type=simple spawn alone).
        previous = None
        for _ in range(2):
            raw = self.command('/usr/bin/systemctl', '--user', 'show', UNIT,
                               '--property=ActiveState,SubState,MainPID,InvocationID')
            fields = dict(line.split('=', 1) for line in raw.splitlines() if '=' in line)
            pid = fields.get('MainPID', '0')
            if fields.get('ActiveState') != 'active' or fields.get('SubState') != 'running' or pid == '0':
                raise PolicyError('Managed Hypridle is not running.')
            pids = self.command('/usr/bin/pgrep', '-u', str(os.getuid()), '-x', 'hypridle').split()
            if pids != [pid]:
                raise PolicyError('Expected exactly one managed Hypridle process.')
            args = Path('/proc', pid, 'cmdline').read_bytes().split(b'\0')
            if args[:3] != [b'/usr/bin/hypridle', b'--config', os.fsencode(self.config)]:
                raise PolicyError('Hypridle is not using the managed policy.')
            if previous is not None and previous != pid:
                raise PolicyError('Hypridle did not remain healthy.')
            previous = pid
            invocation = fields.get('InvocationID', '')
            if not re.fullmatch('[0-9a-f]{32}', invocation):
                raise PolicyError('Hypridle readiness could not be verified.')
            output = self.command('/usr/bin/journalctl', '--user', '--no-pager', '-o', 'cat',
                                  '_SYSTEMD_INVOCATION_ID=' + invocation)
            # Do not mistake the supported zero-listener notice for a failed start.
            output = re.sub(r'\x1b\[[0-9;]*m', '', output)
            if 'listener {' not in self.config.read_text():
                output = re.sub(r'(?m)^.*Config has errors:\nNo rules configured\nProceeding ignoring faulty entries\n?', '', output)
            if ('Inhibited sleep with fd ' not in output
                    or 'inhibiting until the wayland session gets locked' not in output
                    or any(word in output for word in ['[ERR]', '[CRIT]', 'Config has errors', 'missing hyprland-lock-notify'])):
                raise PolicyError('Hypridle sleep coordination is not ready.')
            time.sleep(0.3)


class Manager:
    def __init__(self, directory=None, controller=None, validator=validate_native):
        self.directory = Path(directory) if directory is not None else state_dir()
        self.active = self.directory/'active.conf'
        self.marker = self.directory/'managed.json'
        self.pending = self.directory/'pending.json'
        self.validator = validator
        self.controller = controller if controller is not None else ServiceController(self.active)

    @contextlib.contextmanager
    def locked(self):
        self.directory.mkdir(parents=True, exist_ok=True, mode=0o700)
        with (self.directory/'writer.lock').open('a') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            yield

    def prepare(self, value):
        """Offline bootstrap only; cannot overwrite an enrolled/existing policy."""
        text = render(value)
        self.validator(text)
        with self.locked():
            if self.active.exists() or self.marker.exists():
                raise PolicyError('Idle policy already prepared; refusing to overwrite it.')
            atomic(self.active, text)

    def enroll(self, value):
        with self.locked():
            if not self.active.exists() or self.active.read_text() != render(value):
                raise PolicyError('Prepared policy differs from Settings.')
            self.controller.verify()
            atomic(self.marker, '{"version":1}\n')

    def change(self, before, after, save, force=False):
        old, new = policy(before), policy(after)
        if old == new and not force:
            return save()
        text = render(new)
        self.validator(text)
        with self.locked():
            if not self.marker.exists():
                raise PolicyError('Power & Idle setup is not active yet; previous policy is unchanged.')
            if self.pending.exists():
                raise PolicyError('An idle update was interrupted; recover the saved policy before applying changes.')
            if not self.active.exists() or self.active.read_text() != render(old):
                raise PolicyError('Active idle policy differs from Settings; recover the saved policy first.')
            self.controller.verify()
            self.controller.safe_to_restart()
            previous = self.active.read_text()
            atomic(self.directory/'previous.conf', previous)
            atomic(self.pending, json.dumps({'before':old, 'after':new}, sort_keys=True)+'\n')
            try:
                atomic(self.active, text)
                self.controller.restart()
                self.controller.verify()
                save()
            except Exception as error:
                try:
                    atomic(self.active, previous)
                    self.controller.restart()
                    self.controller.verify()
                    self.pending.unlink()
                except Exception as rollback:
                    raise PolicyError('Could not apply idle policy; recovery failed. Check idle protection before continuing.') from rollback
                raise PolicyError('Could not apply idle policy; previous policy remains active.') from error
            self.pending.unlink()

    def recover(self, value):
        """Explicit recovery after an interrupted writer; never run on Settings read."""
        text = render(value)
        self.validator(text)
        with self.locked():
            if not self.marker.exists():
                raise PolicyError('Power & Idle setup is not active yet.')
            atomic(self.active, text)
            self.controller.restart()
            self.controller.verify()
            self.pending.unlink(missing_ok=True)


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ['prepare', 'enroll', 'recover', 'daemon']:
        raise PolicyError('Use prepare, enroll, or recover at the reviewed deployment gate.')
    if sys.argv[1] == 'daemon':
        manager = Manager()
        # No PID guessing or killing: refuse a duplicate coordinator at startup.
        existing = subprocess.run(['/usr/bin/pgrep', '-u', str(os.getuid()), '-x', 'hypridle'], capture_output=True)
        if existing.returncode != 1:
            raise PolicyError('Another Hypridle may already be running; refusing duplicate startup.')
        text = manager.active.read_text()
        manager.validator(text)
        os.execv('/usr/bin/hypridle', ['/usr/bin/hypridle', '--config', str(manager.active)])
    config = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home()/'.config')))
    settings = json.loads((config/'quickshell/magi/settings.json').read_text())
    if settings.get('schemaVersion', 0) > 15:
        raise PolicyError('Settings schema is newer than this policy adapter.')
    getattr(Manager(), sys.argv[1])(policy(settings))

if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(78 if sys.argv[1:] == ["daemon"] else 1)
