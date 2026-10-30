#!/usr/bin/env python3
"""Private mock bus only; never contact host fprintd or modify enrollment."""
import socket
import subprocess
import sys
import tempfile
with tempfile.TemporaryDirectory(prefix='magi-fprint-bus-') as root:
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as probe:
            probe.bind(root + '/probe')
    except PermissionError:
        print('Private D-Bus socket bind denied; fingerprint broker integration requires host regression')
        sys.exit(77)
    sys.exit(subprocess.run(['dbus-run-session', '--', 'sh', '-c',
        'export DBUS_SYSTEM_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS"; exec "$1"',
        'fingerprint-private-bus', sys.argv[1]], timeout=30).returncode)
