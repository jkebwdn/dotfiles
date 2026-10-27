"""Bluetooth user-intent coordinator. No bus/UI dependencies or persisted state."""
import re

DEVICE_PATH = re.compile(r'^/org/bluez/hci[0-9]+/dev_(?:[0-9A-Fa-f]{2}_){5}[0-9A-Fa-f]{2}$')


class Actions:
    def __init__(self, transport, emit):
        self.transport = transport
        self.emit = emit
        self.operation = None
        self.serial = 0
        self.prompt_serial = 0
        self.prompt = None

    def publish(self, state, error=''):
        op = self.operation
        self.emit({'event': 'state', 'path': op['path'] if op else '',
                   'state': state, 'error': error})

    def active(self, op):
        return self.operation is op

    def start(self, path):
        if self.operation:
            return  # One deliberate transaction, no repeated or competing requests.
        if not isinstance(path, str) or not DEVICE_PATH.fullmatch(path):
            return
        self.serial += 1
        op = self.operation = {'path': path, 'serial': self.serial, 'stage': 'checking'}
        self.publish('Checking…')
        self.transport.read(path, lambda props, error: self.checked(op, props, error))

    def checked(self, op, props, error):
        if not self.active(op):
            return
        if error or not props or not props.get('Powered'):
            self.finish('Device or adapter unavailable')
            return
        if props.get('Connected'):
            self.run(op, 'Disconnect', 'Disconnecting…', self.disconnected)
        elif props.get('Paired') or props.get('Bonded'):
            self.run(op, 'Connect', 'Connecting…', self.connected)
        else:
            op['stage'] = 'registering'
            self.publish('Pairing…')
            self.transport.register(lambda error: self.registered(op, error))

    def registered(self, op, error):
        if not self.active(op):
            return
        if error:
            self.finish('Pairing agent unavailable')
            return
        self.run(op, 'Pair', 'Pairing…', self.paired)

    def run(self, op, method, label, callback):
        op['stage'] = method
        self.publish(label)
        self.transport.call(op['path'], method, lambda error: callback(op, error))

    def paired(self, op, error):
        if not self.active(op):
            return
        self.clear_prompt()
        if error:
            self.finish(self.failure('Pairing', error))
            return
        # Pair's asynchronous reply, not the initial low-level Connected signal,
        # is the completion boundary. Never trust merely discovered devices.
        op['stage'] = 'trust'
        self.transport.trust(op['path'], lambda error: self.trusted(op, error))

    def trusted(self, op, error):
        if not self.active(op):
            return
        if error:
            self.finish('Paired; could not enable automatic reconnection. Retry connection.')
            return
        self.transport.read(op['path'], lambda props, error: self.after_pair(op, props, error))

    def after_pair(self, op, props, error):
        if not self.active(op):
            return
        if error or not props or not props.get('Powered'):
            self.finish('Device or adapter unavailable')
        elif props.get('Connected'):
            self.finish()
        else:
            self.run(op, 'Connect', 'Connecting…', self.connected)

    def connected(self, op, error):
        if self.active(op):
            # Keep paired/trusted state on connection failure. Never RemoveDevice.
            self.finish(self.failure('Connection', error) if error else '')

    def disconnected(self, op, error):
        if self.active(op):
            self.finish(self.failure('Disconnection', error) if error else '')

    @staticmethod
    def failure(kind, error):
        code = str(error).rsplit('.', 1)[-1]
        if code == 'InProgress':
            return 'Another Bluetooth operation is in progress. Try again.'
        if code in ('AuthenticationRejected', 'Rejected'):
            return 'Pairing rejected'
        if code in ('AuthenticationCanceled', 'Canceled'):
            return 'Pairing cancelled'
        if code in ('AuthenticationTimeout', 'Timeout', 'NoReply'):
            return kind + ' timed out. Try again.'
        if code in ('UnknownObject', 'NotReady', 'DoesNotExist'):
            return 'Device or adapter unavailable'
        return kind + ' failed. Check the device and try again.'

    def cancel(self, message='Pairing cancelled'):
        op = self.operation
        if not op:
            return
        if op['stage'] == 'Pair':
            self.transport.cancel_pair(op['path'])
        elif op['stage'] == 'Connect':
            self.transport.cancel_connect(op['path'])
            if message == 'Pairing cancelled':
                message = 'Connection cancelled'
        self.finish(message)

    def unavailable(self, path):
        op = self.operation
        if op and (op['path'] == path or op['path'].startswith(path + '/')):
            self.cancel('Device or adapter unavailable')

    def finish(self, error=''):
        self.clear_prompt()
        self.publish('', error)
        self.operation = None

    def clear_prompt(self):
        if self.prompt:
            reply = self.prompt.get('reply')
            self.prompt = None
            if reply:
                reply(None, 'org.bluez.Error.Canceled')
            self.emit({'event': 'prompt', 'prompt': None})

    def challenge(self, path, kind, value, reply=None):
        op = self.operation
        if not op or op['path'] != path or op['stage'] not in ('Pair', 'Connect'):
            if reply:
                reply(None, 'org.bluez.Error.Rejected')
            return False
        self.clear_prompt()
        self.prompt_serial += 1
        self.prompt = {'id': self.prompt_serial, 'kind': kind, 'reply': reply}
        self.emit({'event': 'prompt', 'prompt': {'id': self.prompt_serial,
                   'path': path, 'kind': kind, 'value': value}})
        return True

    def answer(self, identifier, accepted, value=''):
        prompt = self.prompt
        if not prompt or prompt['id'] != identifier:
            return
        kind = prompt['kind']
        if accepted and kind == 'pin' and not (isinstance(value, str) and 1 <= len(value) <= 16):
            return
        if accepted and kind == 'passkey' and not (isinstance(value, str) and re.fullmatch(r'[0-9]{1,6}', value)):
            return
        if accepted and kind in ('displayPin', 'displayPasskey'):
            return  # Display-only requests complete on BlueZ's side.
        reply = prompt.get('reply')
        self.prompt = None
        if reply:
            reply(int(value) if kind == 'passkey' and accepted else value,
                  None if accepted else 'org.bluez.Error.Rejected')
        self.emit({'event': 'prompt', 'prompt': None})
        if not accepted:
            self.cancel('Pairing rejected')
