#!/usr/bin/env python3
"""Real Gio/Agent1 transport against a disposable bus and fake BlueZ, never host."""
from pathlib import Path
import subprocess
import sys
import tempfile
import time
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'.config/quickshell/magi/services'))
from bluetooth_backend import Backend, Gio, GLib, AGENT_PATH
A='/org/bluez/hci0/dev_11_22_33_44_55_66'
XML='''<node>
<interface name="org.bluez.AgentManager1"><method name="RegisterAgent"><arg type="o" direction="in"/><arg type="s" direction="in"/></method></interface>
<interface name="org.bluez.Device1">
<method name="Pair"/><method name="Connect"/><method name="Disconnect"/><method name="CancelPairing"/>
<property name="Adapter" type="o" access="read"/><property name="Paired" type="b" access="read"/>
<property name="Connected" type="b" access="read"/><property name="Trusted" type="b" access="readwrite"/>
</interface>
<interface name="org.bluez.Adapter1"><property name="Powered" type="b" access="read"/></interface>
</node>'''

def spin(predicate):
    deadline=time.monotonic()+5
    while not predicate():
        if time.monotonic()>deadline: raise AssertionError('Timed out waiting for private-bus fixture')
        GLib.MainContext.default().iteration(False)
        time.sleep(.001)

with tempfile.TemporaryDirectory(prefix='magi-bt-bus-') as tmp:
    daemon=subprocess.Popen(['dbus-daemon','--session','--nofork','--print-address=1','--address=unix:path='+tmp+'/bus'],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
    address=daemon.stdout.readline().strip()
    if not address:
        raise RuntimeError('Private bus could not start: '+daemon.stderr.read())
    try:
        bus=Gio.DBusConnection.new_for_address_sync(address,Gio.DBusConnectionFlags.AUTHENTICATION_CLIENT|Gio.DBusConnectionFlags.MESSAGE_BUS_CONNECTION,None,None)
        bus.call_sync('org.freedesktop.DBus','/org/freedesktop/DBus','org.freedesktop.DBus','RequestName',GLib.Variant('(su)',('org.bluez',0)),None,Gio.DBusCallFlags.NONE,5000,None)
        props={'Adapter':GLib.Variant('o','/org/bluez/hci0'),'Powered':GLib.Variant('b',True),'Paired':GLib.Variant('b',False),'Connected':GLib.Variant('b',False),'Trusted':GLib.Variant('b',False)}
        calls=[]; agent=[]; mode=['RequestConfirmation']; pending=[]; challenge_results=[]
        def getter(_b,_sender,_path,_iface,name): return props[name]
        def setter(_b,_sender,_path,_iface,name,value):
            props[name]=value;calls.append(('Set',name,value.unpack()));return True
        def method(_b,sender,path,iface,name,args,inv):
            calls.append((name,sender))
            if name=='RegisterAgent':
                assert args.unpack()==(AGENT_PATH,'KeyboardDisplay');agent[:]=[sender,args.unpack()[0]];inv.return_value(None)
            elif name=='Pair':
                assert sender==agent[0], 'Agent registration and Pair must share the same bus owner'
                kind=mode[0]
                if kind=='hold': pending.append(inv);return
                variants={'RequestConfirmation':GLib.Variant('(ou)',(A,123)),
                          'RequestPinCode':GLib.Variant('(o)',(A,)),
                          'RequestPasskey':GLib.Variant('(o)',(A,)),
                          'DisplayPinCode':GLib.Variant('(os)',(A,'001234')),
                          'DisplayPasskey':GLib.Variant('(ouq)',(A,123,2)),
                          'RequestAuthorization':GLib.Variant('(o)',(A,)),
                          'AuthorizeService':GLib.Variant('(os)',(A,'0000110b-0000-1000-8000-00805f9b34fb'))}
                def answered(connection,result):
                    try: challenge_results.append(connection.call_finish(result).unpack())
                    except GLib.Error:
                        inv.return_dbus_error('org.bluez.Error.AuthenticationRejected','Rejected');return
                    props['Paired']=GLib.Variant('b',True);inv.return_value(None)
                bus.call(sender,AGENT_PATH,'org.bluez.Agent1',kind,variants[kind],None,Gio.DBusCallFlags.NONE,5000,None,answered)
            elif name=='Connect': props['Connected']=GLib.Variant('b',True);inv.return_value(None)
            elif name=='Disconnect': props['Connected']=GLib.Variant('b',False);inv.return_value(None)
            elif name=='CancelPairing':
                for old in pending: old.return_dbus_error('org.bluez.Error.AuthenticationCanceled','Cancelled')
                pending.clear();inv.return_value(None)
        node=Gio.DBusNodeInfo.new_for_xml(XML)
        for index,path in enumerate(['/org/bluez',A,'/org/bluez/hci0']):
            bus.register_object(path,node.interfaces[index],method,getter,setter)
        backend=Backend(address);events=[];backend.emit=events.append;backend.actions.emit=events.append
        for kind,value,result in [('RequestConfirmation','',()),('RequestPinCode','0123',('0123',)),('RequestPasskey','000123',(123,)),('RequestAuthorization','',()),('AuthorizeService','',())]:
            mode[0]=kind
            for p in ('Paired','Connected','Trusted'): props[p]=GLib.Variant('b',False)
            calls.clear();backend.command({'action':'select','path':A})
            spin(lambda:backend.actions.prompt is not None)
            if kind=='RequestConfirmation': assert events[-1]['prompt']['value']=='000123'
            backend.command({'action':'answer','id':backend.actions.prompt['id'],'accepted':True,'value':value})
            spin(lambda:backend.actions.operation is None)
            assert challenge_results[-1]==result,challenge_results
            assert [x[0] for x in calls].count('Connect')==1,calls
            assert props['Trusted'].unpack()
            assert events[-1]['error']=='',events[-1]
        # Real rejected agent invocation propagates an error, no trust or Connect.
        mode[0]='RequestConfirmation'
        for p in ('Paired','Connected','Trusted'): props[p]=GLib.Variant('b',False)
        calls.clear();backend.command({'action':'select','path':A});spin(lambda:backend.actions.prompt is not None)
        backend.command({'action':'answer','id':backend.actions.prompt['id'],'accepted':False})
        spin(lambda:any(x[0]=='CancelPairing' for x in calls))
        assert not props['Trusted'].unpack()
        # Only BlueZ's unique bus owner may deliver agent requests.
        stranger=Gio.DBusConnection.new_for_address_sync(address,Gio.DBusConnectionFlags.AUTHENTICATION_CLIENT|Gio.DBusConnectionFlags.MESSAGE_BUS_CONNECTION,None,None)
        rejected=[]
        def attack_done(connection,result):
            try: connection.call_finish(result);rejected.append(False)
            except GLib.Error as error: rejected.append(Gio.DBusError.get_remote_error(error)=='org.bluez.Error.Rejected')
        stranger.call(backend.bus.get_unique_name(),AGENT_PATH,'org.bluez.Agent1','RequestPinCode',GLib.Variant('(o)',(A,)),None,Gio.DBusCallFlags.NONE,5000,None,attack_done)
        spin(lambda:bool(rejected));assert rejected==[True]
        # Device disappearance cancels a genuinely pending D-Bus Pair.
        mode[0]='hold';backend.command({'action':'select','path':A});spin(lambda:bool(pending))
        bus.emit_signal(None,'/','org.freedesktop.DBus.ObjectManager','InterfacesRemoved',GLib.Variant('(oas)',(A,['org.bluez.Device1'])))
        spin(lambda:backend.actions.operation is None)
        assert 'unavailable' in events[-1]['error']
        spin(lambda:not pending)
        backend.shutdown();stranger.close_sync(None);bus.close_sync(None)
        print('Private-bus Agent1 authentication, same-owner routing, trust/connect, rejection, caller isolation and removal PASS')
    finally:
        daemon.terminate();daemon.wait(timeout=5)
