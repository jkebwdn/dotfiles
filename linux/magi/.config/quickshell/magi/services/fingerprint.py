#!/usr/bin/env python3
"""Bounded Settings-only fprintd management. Never an unlock authority.

System fprintd/polkit owns enrollment, verification and deletion. Only names,
stages and generic progress leave this process; no biometric storage API exists.
"""
import argparse
import json
import signal
from gi.repository import Gio, GLib

SERVICE = 'net.reactivated.Fprint'
DEVICE = SERVICE + '.Device'
FINGERS = [side + '-' + finger for side in ('left', 'right')
           for finger in ('thumb', 'index-finger', 'middle-finger', 'ring-finger', 'little-finger')]


def emit(**state):
    print(json.dumps(state), flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['status', 'enroll', 'remove', 'verify'])
    parser.add_argument('--finger', choices=FINGERS)
    args = parser.parse_args()
    if args.action in ('enroll', 'remove') and not args.finger:
        parser.error('--finger required')
    bus = None
    owner = path = None
    claimed = False
    operation = None
    subscriptions = []
    loop = GLib.MainLoop()
    result = {'state': 'unavailable', 'message': 'Fingerprint unavailable · password remains available'}

    def call(destination, object_path, interface, method, signature=None, values=()):
        return bus.call_sync(destination, object_path, interface, method,
                             GLib.Variant(signature, values) if signature else None,
                             None, Gio.DBusCallFlags.NONE, 3000, None).unpack()

    def device(method, signature=None, values=()):
        return call(owner, path, DEVICE, method, signature, values)

    def finish(state, message):
        nonlocal result
        result = {'state': state, 'message': message}
        loop.quit()

    def cancelled(*_):
        finish('cancelled', 'Cancelled')
        return GLib.SOURCE_REMOVE

    def timeout():
        finish('timeout', 'Timed out · try again')
        return GLib.SOURCE_REMOVE

    try:
        # Private connection: exit/cancel cannot leave a persistent shell claim.
        address = Gio.dbus_address_get_for_bus_sync(Gio.BusType.SYSTEM, None)
        bus = Gio.DBusConnection.new_for_address_sync(address,
            Gio.DBusConnectionFlags.AUTHENTICATION_CLIENT | Gio.DBusConnectionFlags.MESSAGE_BUS_CONNECTION,
            None, None)
        try:
            owner = call('org.freedesktop.DBus', '/org/freedesktop/DBus', 'org.freedesktop.DBus',
                         'GetNameOwner', '(s)', (SERVICE,))[0]
        except GLib.Error as error:
            if Gio.DBusError.get_remote_error(error) != 'org.freedesktop.DBus.Error.NameHasNoOwner':
                raise
            call('org.freedesktop.DBus', '/org/freedesktop/DBus', 'org.freedesktop.DBus',
                 'StartServiceByName', '(su)', (SERVICE, 0))
            owner = call('org.freedesktop.DBus', '/org/freedesktop/DBus', 'org.freedesktop.DBus',
                         'GetNameOwner', '(s)', (SERVICE,))[0]
        path = call(owner, '/net/reactivated/Fprint/Manager', SERVICE + '.Manager', 'GetDefaultDevice')[0]
        try:
            fingers = list(device('ListEnrolledFingers', '(s)', ('',))[0])
        except GLib.Error as error:
            if Gio.DBusError.get_remote_error(error) != SERVICE + '.Error.NoEnrolledPrints':
                raise
            fingers = []
        fingers = [finger for finger in fingers if finger in FINGERS]
        emit(state='available', fingers=fingers,
             message='Fingerprint available' if fingers else 'No fingerprints enrolled')
        if args.action == 'status':
            result = {'state': 'available', 'fingers': fingers,
                      'message': str(len(fingers)) + ' fingerprint(s) enrolled'}
            return
        if args.action == 'enroll' and args.finger in fingers:
            result = {'state': 'error', 'message': 'That finger is already enrolled; choose another finger'}
            return
        device('Claim', '(s)', ('',)); claimed = True
        if args.action == 'remove':
            device('DeleteEnrolledFinger', '(s)', (args.finger,))
            result = {'state': 'complete', 'message': 'Fingerprint removed',
                      'fingers': [f for f in fingers if f != args.finger]}
            return
        enrolling = args.action == 'enroll'
        operation = 'Enroll' if enrolling else 'Verify'
        stages = 0
        if enrolling:
            value = call(owner, path, 'org.freedesktop.DBus.Properties', 'Get',
                         '(ss)', (DEVICE, 'num-enroll-stages'))[0]
            stages = int(value.unpack() if hasattr(value, 'unpack') else value)
        progress = 0

        def status(connection, sender, object_path, interface, name, parameters, data):
            nonlocal progress, claimed, operation
            if sender != owner or object_path != path:
                return
            code, done = parameters.unpack()
            if code.endswith('-disconnected'):
                claimed = False; operation = None
                finish('unavailable', 'Fingerprint reader disconnected')
            elif code == 'enroll-stage-passed' and not done:
                progress += 1
                emit(state='reading', stages=stages, progress=progress, message=f'Reading… {progress} of {stages} stages')
            elif done:
                success = code in ('enroll-completed', 'verify-match')
                finish('complete' if success else 'retry',
                       ('Fingerprint enrolled' if enrolling else 'Fingerprint matched') if success else 'Try again')
            else:
                emit(state='reading', stages=stages, progress=progress, message='Touch fingerprint sensor' if code == 'verify-finger-selected' else 'Try again')

        def owner_changed(connection, sender, object_path, interface, name, parameters, data):
            nonlocal claimed, operation
            service, old, new = parameters.unpack()
            if service == SERVICE and old == owner:
                claimed = False; operation = None
                finish('unavailable', 'Fingerprint service unavailable')

        subscriptions.append(bus.signal_subscribe(owner, DEVICE, operation + 'Status', path,
                             None, Gio.DBusSignalFlags.NONE, status, None))
        subscriptions.append(bus.signal_subscribe('org.freedesktop.DBus', 'org.freedesktop.DBus',
            'NameOwnerChanged', '/org/freedesktop/DBus', SERVICE, Gio.DBusSignalFlags.NONE, owner_changed, None))
        GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, cancelled)
        GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGINT, cancelled)
        device(operation + 'Start', '(s)', (args.finger if enrolling else 'any',))
        emit(state='waiting', stages=stages, progress=0, message='Touch fingerprint sensor')
        GLib.timeout_add_seconds(120 if enrolling else 30, timeout)
        loop.run()
    except GLib.Error:
        result = {'state': 'unavailable', 'message': 'Fingerprint unavailable or permission denied · try again'}
    finally:
        if bus:
            for subscription in subscriptions:
                bus.signal_unsubscribe(subscription)
            if args.action == 'enroll' and result['state'] == 'complete':
                try:
                    result['fingers'] = [f for f in device('ListEnrolledFingers', '(s)', ('',))[0] if f in FINGERS]
                except GLib.Error:
                    result = {'state': 'unavailable', 'message': 'Enrollment finished; refresh to confirm status'}
            clean = True
            for method in ([operation + 'Stop'] if operation else []) + (['Release'] if claimed else []):
                try:
                    device(method)
                except GLib.Error:
                    clean = False
            if not clean and result['state'] == 'complete':
                result = {'state': 'unavailable', 'message': 'Could not confirm reader cleanup · refresh status'}
            try:
                bus.close_sync(None)
            except GLib.Error:
                pass
        emit(**result)


if __name__ == '__main__':
    main()
