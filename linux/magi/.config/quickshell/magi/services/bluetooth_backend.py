#!/usr/bin/env python3
"""Private, application-scoped BlueZ Agent1 + asynchronous action transport.

JSON lines on stdin/stdout are ephemeral IPC, never logs or Settings. The agent
and Pair calls share one bus connection; MAGI never requests default-agent status.
"""
import json
import os
import signal
import sys

import gi
gi.require_version('Gio', '2.0')
from gi.repository import Gio, GLib
from bluetooth_actions import Actions

AGENT_PATH = '/org/magi/BluetoothAgent'
AGENT_XML = '''<node><interface name="org.bluez.Agent1">
<method name="Release"/>
<method name="RequestPinCode"><arg type="o" direction="in"/><arg type="s" direction="out"/></method>
<method name="DisplayPinCode"><arg type="o" direction="in"/><arg type="s" direction="in"/></method>
<method name="RequestPasskey"><arg type="o" direction="in"/><arg type="u" direction="out"/></method>
<method name="DisplayPasskey"><arg type="o" direction="in"/><arg type="u" direction="in"/><arg type="q" direction="in"/></method>
<method name="RequestConfirmation"><arg type="o" direction="in"/><arg type="u" direction="in"/></method>
<method name="RequestAuthorization"><arg type="o" direction="in"/></method>
<method name="AuthorizeService"><arg type="o" direction="in"/><arg type="s" direction="in"/></method>
<method name="Cancel"/>
</interface></node>'''


class Backend:
    def __init__(self, address=None):
        # A private connection ties registration lifetime to this helper, including
        # hard shell exit. Optional address is only used by the private-bus tests.
        address = address or Gio.dbus_address_get_for_bus_sync(Gio.BusType.SYSTEM, None)
        self.bus = Gio.DBusConnection.new_for_address_sync(address,
            Gio.DBusConnectionFlags.AUTHENTICATION_CLIENT | Gio.DBusConnectionFlags.MESSAGE_BUS_CONNECTION,
            None, None)
        self.owner = self.bus.call_sync('org.freedesktop.DBus', '/org/freedesktop/DBus',
            'org.freedesktop.DBus', 'GetNameOwner', GLib.Variant('(s)', ('org.bluez',)),
            GLib.VariantType.new('(s)'), Gio.DBusCallFlags.NONE, 5000, None).unpack()[0]
        self.registered = False
        self.closed = False
        self.actions = Actions(self, self.emit)
        self.loop = GLib.MainLoop()
        self.bus.register_object(AGENT_PATH, Gio.DBusNodeInfo.new_for_xml(AGENT_XML).interfaces[0], self.agent, None, None)
        self.bus.signal_subscribe('org.bluez', 'org.freedesktop.DBus.ObjectManager',
            'InterfacesRemoved', '/', None, Gio.DBusSignalFlags.NONE, self.removed)
        self.bus.signal_subscribe('org.bluez', 'org.freedesktop.DBus.Properties',
            'PropertiesChanged', None, None, Gio.DBusSignalFlags.NONE, self.changed)
        self.bus.signal_subscribe('org.freedesktop.DBus', 'org.freedesktop.DBus',
            'NameOwnerChanged', '/org/freedesktop/DBus', 'org.bluez', Gio.DBusSignalFlags.NONE, self.owner_changed)
        self.bus.connect('closed', lambda *_: self.shutdown())

    def emit(self, event):
        try:
            print(json.dumps(event, separators=(',', ':')), flush=True)
        except (BrokenPipeError, OSError):
            self.shutdown()

    def request(self, path, interface, method, parameters, callback, timeout=15000):
        def done(bus, result):
            try:
                reply = bus.call_finish(result)
            except GLib.Error as error:
                callback(None, Gio.DBusError.get_remote_error(error) or 'org.bluez.Error.Timeout')
            else:
                callback(reply.unpack() if reply else (), None)
        self.bus.call('org.bluez', path, interface, method, parameters,
                      None, Gio.DBusCallFlags.NONE, timeout, None, done)

    def register(self, callback):
        if self.registered:
            callback(None)
            return
        def registered(_result, error):
            self.registered = not error
            callback(error)
        self.request('/org/bluez', 'org.bluez.AgentManager1', 'RegisterAgent',
                     GLib.Variant('(os)', (AGENT_PATH, 'KeyboardDisplay')), registered)

    def read(self, path, callback):
        def device(result, error):
            if error:
                callback(None, error)
                return
            props = result[0]
            def adapter(result, error):
                props['Powered'] = bool(result and result[0].get('Powered'))
                callback(props, error)
            self.request(props.get('Adapter', path.rsplit('/', 1)[0]),
                         'org.freedesktop.DBus.Properties', 'GetAll',
                         GLib.Variant('(s)', ('org.bluez.Adapter1',)), adapter)
        self.request(path, 'org.freedesktop.DBus.Properties', 'GetAll',
                     GLib.Variant('(s)', ('org.bluez.Device1',)), device)

    def call(self, path, method, callback):
        def finished(_result, error):
            if method == 'Pair' and error and error.endswith(('Timeout', 'NoReply')):
                self.cancel_pair(path)
            callback(error)
        self.request(path, 'org.bluez.Device1', method, None, finished,
                     120000 if method == 'Pair' else 45000)

    def trust(self, path, callback):
        self.request(path, 'org.freedesktop.DBus.Properties', 'Set',
                     GLib.Variant('(ssv)', ('org.bluez.Device1', 'Trusted', GLib.Variant('b', True))),
                     lambda _result, error: callback(error))

    def cancel_connect(self, path):
        self.request(path, 'org.bluez.Device1', 'Disconnect', None, lambda *_: None)

    def cancel_pair(self, path):
        self.request(path, 'org.bluez.Device1', 'CancelPairing', None, lambda *_: None)

    def removed(self, _bus, _sender, _path, _iface, _signal, parameters):
        path, interfaces = parameters.unpack()
        if 'org.bluez.Device1' in interfaces or 'org.bluez.Adapter1' in interfaces:
            self.actions.unavailable(path)

    def changed(self, _bus, _sender, path, _iface, _signal, parameters):
        interface, changed, _invalidated = parameters.unpack()
        if interface == 'org.bluez.Adapter1' and changed.get('Powered') is False:
            self.actions.unavailable(path)

    def owner_changed(self, *_args):
        self.actions.cancel('Bluetooth service unavailable')
        self.shutdown()

    def agent(self, _bus, sender, _path, _interface, method, parameters, invocation):
        if sender != self.owner:
            invocation.return_dbus_error('org.bluez.Error.Rejected', 'Not the Bluetooth service')
            return
        args = parameters.unpack()
        if method in ('Cancel', 'Release'):
            invocation.return_value(None)
            if method == 'Release':
                self.registered = False
                self.actions.cancel('Pairing agent released')
            else:
                self.actions.clear_prompt()
            return
        kinds = {'RequestPinCode': 'pin', 'RequestPasskey': 'passkey',
                 'DisplayPinCode': 'displayPin', 'DisplayPasskey': 'displayPasskey',
                 'RequestConfirmation': 'confirm', 'RequestAuthorization': 'authorize',
                 'AuthorizeService': 'service'}
        kind = kinds.get(method)
        if not kind:
            invocation.return_dbus_error('org.bluez.Error.Rejected', 'Unsupported request')
            return
        def reply(value, error):
            if error:
                invocation.return_dbus_error(error, 'Pairing request declined')
            elif kind == 'pin':
                invocation.return_value(GLib.Variant('(s)', (value,)))
            elif kind == 'passkey':
                invocation.return_value(GLib.Variant('(u)', (value,)))
            else:
                invocation.return_value(None)
        value = ''
        if kind in ('confirm', 'displayPasskey'):
            value = f'{args[1]:06d}'
            if kind == 'displayPasskey':
                value += f' · {args[2]} digits entered'
        elif kind in ('displayPin', 'service'):
            value = args[1]
        if kind.startswith('display'):
            allowed = self.actions.challenge(args[0], kind, value)
            reply('', None if allowed else 'org.bluez.Error.Rejected')
        else:
            self.actions.challenge(args[0], kind, value, reply)

    def command(self, data):
        if data.get('action') == 'select':
            self.actions.start(data.get('path'))
        elif data.get('action') == 'cancel':
            self.actions.cancel()
        elif data.get('action') == 'answer':
            self.actions.answer(data.get('id'), data.get('accepted') is True, data.get('value', ''))

    def shutdown(self):
        if self.closed:
            return
        self.closed = True
        self.actions.cancel('Pairing cancelled')
        if not self.bus.is_closed():
            self.bus.close_sync(None)
        self.loop.quit()

    def run(self):
        buffer = bytearray()
        def incoming(_fd, condition):
            try:
                chunk = os.read(0, 8192)
                if not chunk:
                    self.shutdown()
                    return False
                buffer.extend(chunk)
                if len(buffer) > 65536:
                    self.shutdown()
                    return False
                while b'\n' in buffer:
                    line, _, rest = buffer.partition(b'\n')
                    buffer[:] = rest
                    try:
                        data = json.loads(line)
                        if isinstance(data, dict):
                            self.command(data)
                    except (ValueError, TypeError):
                        pass
            except OSError:
                self.shutdown()
                return False
            return True
        GLib.io_add_watch(0, GLib.IO_IN | GLib.IO_HUP | GLib.IO_ERR, incoming)
        GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, lambda: (self.shutdown(), False)[1])
        self.emit({'event': 'ready'})
        self.loop.run()


if __name__ == '__main__':
    try:
        Backend().run()
    except GLib.Error:
        print(json.dumps({'event': 'unavailable'}), flush=True)
        sys.exit(1)
