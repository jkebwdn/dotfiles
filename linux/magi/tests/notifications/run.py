#!/usr/bin/env python3
"""Real Quickshell notification protocol on a PRIVATE D-Bus; never the desktop bus."""
from pathlib import Path
import json, os, re, shutil, subprocess, tempfile, time, sys

if os.environ.get('MAGI_PRIVATE_NOTIFICATION_TEST') != '1':
    result = subprocess.run(['dbus-run-session', '--', sys.executable, __file__],
                            env=dict(os.environ, MAGI_PRIVATE_NOTIFICATION_TEST='1'))
    raise SystemExit(result.returncode)

root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='magi-notifications-') as temporary:
    stage = Path(temporary)
    config = stage/'config'
    shutil.copytree(root/'.config/quickshell/magi', config)
    (config/'test.qml').write_text(Path(__file__).with_name('integration.qml').read_text()
        .replace('../../.config/quickshell/magi/', ''))
    runtime = stage/'runtime'; runtime.mkdir(mode=0o700)
    env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software', QS_NO_RELOAD_POPUP='1',
               XDG_RUNTIME_DIR=str(runtime), XDG_STATE_HOME=str(stage/'state'))
    env.pop('WAYLAND_DISPLAY', None); env.pop('DISPLAY', None)
    log = open(stage/'shell.log', 'w+')
    signals = open(stage/'signals.log', 'w+')
    monitor = subprocess.Popen(['dbus-monitor','--session',"type='signal',interface='org.freedesktop.Notifications'"],
                               env=env,stdout=signals,stderr=signals)
    shell = subprocess.Popen(['quickshell','-p',str(config/'test.qml'),'--no-color'], env=env, stdout=log, stderr=log)
    def command(args):
        return subprocess.check_output(args, env=env, text=True, stderr=subprocess.STDOUT).strip()
    def ipc(method, *args):
        return command(['quickshell','ipc','-p',str(config/'test.qml'),'call','test',method,*map(str,args)])
    def state(): return json.loads(ipc('state'))
    def send(title, replace=0, timeout=0, urgency=1, actions=(), transient=False, resident=False):
        pairs = [v for a in actions for v in a]
        args = ['busctl','--user','call','org.freedesktop.Notifications','/org/freedesktop/Notifications',
                'org.freedesktop.Notifications','Notify','susssasa{sv}i','MAGI test',str(replace),'',title,'Safe test body',
                str(len(pairs)),*pairs,'3','urgency','y',str(urgency),'transient','b',str(transient).lower(),
                'resident','b',str(resident).lower(),str(timeout)]
        return int(command(args).split()[1])
    def settle(): time.sleep(.25)
    try:
        for _ in range(60):
            if shell.poll() is not None: raise AssertionError('shell failed to start')
            try:
                state(); break
            except subprocess.CalledProcessError: time.sleep(.05)
        else: raise AssertionError('IPC unavailable')
        first = send('First', timeout=1234)
        for _ in range(60):
            if ipc('settingsReady') == 'true': break
            time.sleep(.05)
        assert ipc('dndIntegration','true') == 'true'
        assert ipc('dndIntegration','false') == 'true'
        settle(); s = state()
        assert s['history'][0]['data']['timeout'] == 1234, s
        assert s['toasts'] == [first]
        assert send('Updated', replace=first, timeout=0) == first
        settle(); s = state()
        assert len(s['history']) == 1 and s['history'][0]['data']['summary'] == 'Updated'
        second = send('Second'); third = send('Third'); fourth = send('Overflow')
        settle(); s = state()
        assert s['toasts'] == [first, second, third] and len(s['history']) == 4, s
        ipc('dismiss', second); settle()
        assert second not in state()['toasts'] and len(state()['history']) == 3
        ipc('config','dnd','true'); settle()
        hidden = send('DND history'); settle()
        assert not state()['toasts'] and any(r['id']==hidden for r in state()['history'])
        critical = send('Critical', urgency=2); settle()
        assert state()['toasts'] == [critical]
        ipc('fullscreen','true'); settle()
        send('Fullscreen', urgency=2); settle(); assert not state()['toasts']
        ipc('fullscreen','false'); settle(); assert not state()['toasts']
        ipc('centre','true'); settle(); assert all(r['read'] for r in state()['history'])
        ipc('clear'); settle(); assert not state()['history']
        ipc('centre','false'); ipc('config','dnd','false')
        expiring = send('Expires', timeout=800); settle()
        ipc('hover',expiring,'true'); time.sleep(.9)
        assert state()['history'][0]['live']
        ipc('hover',expiring,'false'); time.sleep(.9)
        assert state()['history'][0]['reason'] == 1 and not state()['history'][0]['live']
        actionable = send('Action', actions=[('default','Open'),('safe','Safe action')]); settle()
        assert ipc('invoke',actionable,'safe') == 'true'
        settle(); assert not any(r['id']==actionable for r in state()['history'])
        resident = send('Resident', resident=True, actions=[('default','Open')]); settle()
        assert ipc('invoke',resident,'default') == 'true'
        settle(); assert any(r['id']==resident and r['live'] for r in state()['history'])
        command(['busctl','--user','call','org.freedesktop.Notifications','/org/freedesktop/Notifications',
                 'org.freedesktop.Notifications','CloseNotification','u',str(resident)])
        settle(); assert not any(r['id']==resident for r in state()['history'])
        send('Transient', transient=True, timeout=100); time.sleep(.4)
        assert not any(r['data']['transient'] for r in state()['history'])
        ipc('config','historyLimit','10')
        for i in range(20): send('Burst '+str(i))
        settle(); s = state()
        assert len(s['history']) == 10 and len(s['toasts']) <= 3
        assert s['history'][0]['data']['summary'] == 'Burst 19'
        ipc('clear'); settle(); assert state() == {'history':[], 'toasts':[]}
        changed_action = send('Original action', actions=[('same','Original label')]); settle()
        send('Updated action', replace=changed_action, actions=[('same','New label')]); settle()
        label = next(r for r in state()['history'] if r['id']==changed_action)['data']['actions'][0]['text']
        print('Installed API same-identifier action label after replacement:', label)
        ipc('clear'); settle()
        restored = send('Before QML reload'); settle()
        harness = config/'test.qml'
        harness.write_text(harness.read_text() + '\n// private-bus reload test\n')
        for _ in range(60):
            time.sleep(.05)
            try: s = state()
            except (json.JSONDecodeError, subprocess.CalledProcessError): continue
            if s['history'] and s['history'][0]['restored']: break
        else: raise AssertionError('tracked notification not restored on reload')
        assert s['history'][0]['id'] == restored and not s['toasts'], s
        assert send('Updated after reload', replace=restored) == restored
        settle(); assert state()['toasts'] == [restored]
        ipc('clear'); settle()
        ipc('config','enabled','false'); send('Disabled'); settle()
        assert state() == {'history':[], 'toasts':[]}
        capabilities=command(['busctl','--user','call','org.freedesktop.Notifications','/org/freedesktop/Notifications',
                 'org.freedesktop.Notifications','GetCapabilities'])
        assert all('"'+cap+'"' in capabilities for cap in ['body','actions','icon-static'])
        assert 'persistence' not in capabilities and 'body-markup' not in capabilities
        signals.flush(); signals.seek(0); wire=signals.read()
        for name in ['ActionInvoked','NotificationClosed']: assert name in wire, wire
        close_pairs = {(int(i),int(reason)) for i,reason in re.findall(
            r'member=NotificationClosed\s+uint32 (\d+)\s+uint32 (\d+)', wire)}
        assert {(expiring,1),(second,2),(resident,3)} <= close_pairs, wire
        for value in ['string "safe"','string "default"']: assert value in wire, wire
        print('PRIVATE BUS: creation, millisecond timeout, replacement, stack/cap, dismiss, DND/history, critical, fullscreen, read/clear, hover, actions, resident, exact close reasons, transient, burst/bounds, reload/replacement PASS')
    finally:
        shell.terminate(); shell.wait(timeout=5)
        monitor.terminate(); monitor.wait(timeout=5); signals.close()
        log.seek(0); output = log.read(); print(output); log.close()
    assert 'ERROR' not in output and 'WARN' not in output, output
    # Exercise the actual production singleton's construction gate separately,
    # after the first private server has exited. This never touches the desktop bus.
    (config/'settings.json').write_text('{"schemaVersion":5}')
    (config/'activation.qml').write_text(Path(__file__).with_name('activation.qml').read_text()
        .replace('../../.config/quickshell/magi/',''))
    def gate(method):
        return command(['quickshell','ipc','-p',str(config/'activation.qml'),'call','gate',method])
    with open(stage/'gate.log','w+') as gate_log:
        gate_shell=subprocess.Popen(['quickshell','-p',str(config/'activation.qml'),'--no-color'],
                                    env=env,stdout=gate_log,stderr=gate_log)
        try:
            for _ in range(60):
                try:
                    if gate('ready') == 'true': break
                except subprocess.CalledProcessError: pass
                time.sleep(.05)
            else: raise AssertionError('production gate not ready')
            owner=subprocess.run(['busctl','--user','status','org.freedesktop.Notifications'],
                                 env=env,capture_output=True)
            assert owner.returncode != 0, 'gate unexpectedly took ownership'
            gate('activate')
            send('Production gate activation')
            settle(); assert gate('count') == '1'
            activation=config/'activation.qml'
            activation.write_text(activation.read_text()+'\n// reload session approval\n')
            time.sleep(.8)
            assert gate('active') == 'true'
            send('After session gate reload'); settle(); assert gate('count') == '2'
            print('PRIVATE BUS: production gate takes no ownership until activation, then receives notifications PASS')
        finally:
            gate_shell.terminate(); gate_shell.wait(timeout=5)
            gate_log.seek(0); gate_output=gate_log.read(); print(gate_output)
        assert 'ERROR' not in gate_output and 'WARN' not in gate_output, gate_output
