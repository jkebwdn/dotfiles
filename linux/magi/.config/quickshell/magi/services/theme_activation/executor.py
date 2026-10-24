"""Read-only process discovery and non-starting GApplication action dispatch.

No signals, keyboard injection, process termination or application launch.
"""
import os
from pathlib import Path
import shutil

class SessionBus:
    def __init__(self):
        from gi.repository import Gio, GLib
        self.Gio, self.GLib = Gio, GLib
        self.bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)

    def call(self, destination, path, interface, method, signature, args, reply):
        G = self.GLib
        return self.bus.call_sync(destination, path, interface, method,
            G.Variant(signature, args), G.VariantType(reply),
            self.Gio.DBusCallFlags.NO_AUTO_START, 3000, None).unpack()

    def daemon(self, method, name, reply):
        return self.call('org.freedesktop.DBus','/org/freedesktop/DBus',
            'org.freedesktop.DBus',method,'(s)',(name,),reply)[0]

    def owner(self, name):
        if not self.daemon('NameHasOwner', name, '(b)'): return None
        return self.daemon('GetNameOwner', name, '(s)')

    def identity(self, owner):
        return (self.daemon('GetConnectionUnixUser', owner, '(u)'),
                self.daemon('GetConnectionUnixProcessID', owner, '(u)'))

    def describe(self, owner):
        return self.call(owner, '/com/mitchellh/ghostty', 'org.gtk.Actions',
                         'Describe', '(s)', ('reload-config',), '((bgav))')[0]

    def reload(self, owner):
        self.call(owner, '/com/mitchellh/ghostty', 'org.gtk.Actions',
                  'Activate', '(sava{sv})', ('reload-config', [], {}), '()')

class Executor:
    def __init__(self, bus_factory=SessionBus, proc=Path('/proc')):
        self.bus_factory, self.proc = bus_factory, proc

    def processes(self, executable):
        found=[]
        for directory in self.proc.iterdir():
            if not directory.name.isdigit(): continue
            try:
                if directory.stat().st_uid != os.getuid(): continue
                if (directory/'exe').resolve(strict=True) == executable:
                    found.append(int(directory.name))
            except (OSError, RuntimeError): continue
        return found

    def running(self, target):
        name = 'zen-browser' if target == 'zen' else target
        executable=shutil.which(name) or (shutil.which('zen') if target == 'zen' else None)
        # Audited Arch zen-browser launcher execs this ELF, not the shell wrapper.
        if target == 'zen' and Path('/opt/zen-browser-bin/zen-bin').is_file():
            executable = '/opt/zen-browser-bin/zen-bin'
        return bool(executable and self.processes(Path(executable).resolve()))

    def ghostty(self):
        from .capabilities import result
        executable=shutil.which('ghostty')
        if not executable: return result('next_launch', 'Ghostty is not installed/running.')
        executable=Path(executable).resolve()
        processes=self.processes(executable)
        if not processes: return result('next_launch', 'Ready for the next Ghostty launch.')
        bus=self.bus_factory();owner=bus.owner('com.mitchellh.ghostty')
        if not owner:
            return result('reload_required', 'Independent Ghostty instance: use Reload Configuration; sessions remain untouched.')
        uid,pid=bus.identity(owner)
        if uid != os.getuid() or pid not in processes:
            raise RuntimeError('Ghostty bus owner does not match the current user/executable')
        enabled,parameter,_=bus.describe(owner)
        if not enabled or parameter: raise RuntimeError('Ghostty reload-config action unavailable or incompatible')
        # Unique owner prevents a new process receiving a stale request. Recheck identity.
        if bus.owner('com.mitchellh.ghostty') != owner or bus.identity(owner)!=(uid,pid):
            raise RuntimeError('Ghostty owner changed before reload')
        bus.reload(owner)
        others=len(processes)-1
        return result('reload_requested', 'Reload accepted by Ghostty; no loaded-generation readback.' +
                      (' Other independent instances need manual reload.' if others else ''),
                      coveredProcesses=1, otherProcesses=others)

    def activate(self, target, adapter, store):
        from .capabilities import CAPABILITIES, result
        cap=CAPABILITIES[target]
        if target=='ghostty': return self.ghostty()
        if target=='hyprland': return result('applied', adapter.activate(store))
        if cap.kind=='restart_required':
            return result('restart_required' if self.running(target) else 'next_launch', cap.detail)
        return result(cap.kind if cap.kind in ('live','next_launch','unsupported') else 'unsupported',cap.detail)
