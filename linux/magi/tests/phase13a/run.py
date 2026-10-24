#!/usr/bin/env python3
"""Offline designer contracts. Never acquire a session lock or invoke PAM."""
from pathlib import Path
import os
import subprocess

root = Path(__file__).resolve().parents[2]
fixture = os.environ.get('MAGI_PHASE13A_FIXTURE')
subprocess.run(['node', str(Path(__file__).with_name('model.cjs')), str(root)] + ([fixture] if fixture else []), check=True)
subprocess.run(['cmake', '-DSOURCE=' + str(root/'native/lock'), '-P', str(root/'native/lock/tests/presentation_boundary.cmake')], check=True)
shared = root/'.config/quickshell/magi/components/lockPresentation'
assert shared.is_symlink() and shared.resolve() == root/'native/lock/qml'
canvas = (root/'.config/quickshell/magi/components/settings/LockLayoutCanvas.qml').read_text()
assert 'characterCount: root.stateIndex===1 ? 6 : 0' in canvas
assert all(word not in canvas for word in ['LockService', 'AuthController', 'Process {', 'IpcHandler', 'unlockAndDestroy'])
assert 'onReleased:' in canvas and 'preventStealing:true' in canvas
assert 'Qt.Key_Escape' in canvas and 'Qt.ShiftModifier' in canvas and 'Qt.AltModifier' in canvas
screen = (root/'native/lock/qml/LockScreen.qml').read_text()
assert 'Layout.normalize(visual.lockScreen)' in screen
assert all(word not in screen for word in ['MouseArea', 'Keys.', 'selected', 'guideX', 'Settings.'])
print('Phase13A shared-source, inert preview and production/editor boundary PASS')
