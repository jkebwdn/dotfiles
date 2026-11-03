"""Audited Lua border contract for Hyprland 0.56–0.57; unknown APIs fail closed."""
import json
import re


class ActivationUnavailable(RuntimeError):
    def __init__(self, reason, detail):
        super().__init__(detail)
        self.reason = reason


class VerificationFailed(RuntimeError):
    pass


def parse_version(output):
    # Read the release token, never a dependency version, tag or commit message.
    match = re.match(r'\A(?:Hyprland\s+v?|v)(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?=\s|$)', output.strip())
    return tuple(map(int, match.groups())) if match else None


def expected_borders(payload):
    # The generated v1 contract is intentionally fixed, and owns only these keys.
    match = re.fullmatch(
        r'-- MAGI generated theme v1\nhl\.config\(\{general=\{col=\{active_border=\{colors=\{"rgba\(([0-9a-fA-F]{8})\)","rgba\(([0-9a-fA-F]{8})\)"\},angle=45\},inactive_border="rgba\(([0-9a-fA-F]{8})\)"\}\}\}\)\n', payload)
    if not match:
        raise VerificationFailed('Generated border payload does not match the audited Lua contract')
    # Hyprland serializes colours as ARGB hex, not Lua's RGBA input.
    a, b, inactive = (int(c[-2:] + c[:-2], 16) for c in match.groups())
    return {'general.col.active_border': ((a, b), 45),
            'general.col.inactive_border': ((inactive,), 0)}


def read_border(command, option):
    reply = json.loads(command(['hyprctl', '-j', 'getoption', option]))
    if not isinstance(reply, dict) or reply.get('option') != option:
        raise ValueError('Unexpected option reply')
    value = reply.get('gradient', reply.get('custom'))
    if not isinstance(value, str) or not re.fullmatch(r'(?:[0-9a-fA-F]{1,8}\s+)+-?\d+deg', value):
        raise ValueError('Unexpected gradient reply')
    *colors, angle = value.split()
    return tuple(int(c, 16) for c in colors), int(angle[:-3]) % 360


def activate(store, command):
    def run(argv):
        try:
            return command(argv)
        except FileNotFoundError as error:
            raise ActivationUnavailable('missing_hyprctl', 'hyprctl is unavailable; generated Lua is ready.') from error
        except Exception as error:
            raise ActivationUnavailable('runtime_command_failed', 'Hyprland runtime command failed: ' + str(error)[:500]) from error

    version = parse_version(run(['hyprctl', 'version']))
    if version is None:
        raise ActivationUnavailable('malformed_version', 'Cannot identify Hyprland release; live activation withheld. Generated Lua is ready.')
    if not (version[0] == 0 and 56 <= version[1] <= 57):
        raise ActivationUnavailable('unsupported_version', 'Hyprland ' + '.'.join(map(str, version)) +
                                    ' is outside the audited 0.56–0.57 Lua API range; live activation withheld. Generated Lua is ready.')
    path = store.current('hyprland') / 'colors.lua'
    expected = expected_borders(path.read_text())
    # A read-only API probe before mutation. Unsupported providers cannot receive writes.
    try:
        for option in expected:
            read_border(run, option)
    except ActivationUnavailable:
        raise
    except Exception as error:
        raise ActivationUnavailable('unsupported_readback', 'Border introspection unavailable; live activation withheld: ' + str(error)[:300]) from error
    response = run(['hyprctl', 'eval', 'dofile(' + repr(str(path)) + ')'])
    if response != 'ok':
        raise ActivationUnavailable('runtime_rejected', 'Hyprland did not accept the Lua colour update: ' + response[:500])
    errors = run(['hyprctl', 'configerrors'])
    if errors:
        raise VerificationFailed('Hyprland configerrors after colour update: ' + errors[:500])
    try:
        for option, value in expected.items():
            actual = read_border(run, option)
            if actual != value:
                raise ValueError(f'{option}: expected {value}, got {actual}')
    except Exception as error:
        raise VerificationFailed('Border verification failed: ' + str(error)[:500]) from error
    return 'Active/inactive border colours verified; no compositor reload.'
