#!/usr/bin/env python3
"""Synthetic tests only; never start lock, PAM, network or MPRIS."""
from pathlib import Path
import importlib.util, json, os, subprocess, tempfile, sys
sys.dont_write_bytecode=True
root=Path(__file__).resolve().parents[2]
fixture=os.environ.get('MAGI_PHASE13B_FIXTURE')
if not fixture:
    fixture=str(Path(__file__).with_name('custom-layout.json'))
subprocess.run(['node',str(Path(__file__).with_name('model.cjs')),fixture],check=True)
sys.path.insert(0,str(root/'.config/quickshell/magi/services'))
spec=importlib.util.spec_from_file_location('aux',root/'.config/quickshell/magi/services/lock_auxiliary.py');aux=importlib.util.module_from_spec(spec);spec.loader.exec_module(aux)
with tempfile.TemporaryDirectory() as tmp:
    cache=Path(tmp);(cache/'artwork').mkdir();art=cache/'artwork/test.png';art.write_bytes(b'fixture')
    for value in [None,[],{}, {'available':False}]: assert aux.prepare(value,cache)=={}
    valid=aux.prepare({'available':True,'title':'Example\ntrack','artist':12,'artwork':art.as_uri()},cache)
    assert valid['title']=='Exampletrack' and valid['artist']=='' and valid['artwork']==str(art)
    aux.prepare_icon({'icon':{'kind':'managed','url':(root/'.config/quickshell/magi/icons/packs/magi-default/media-play.svg').as_uri()}},cache)
    assert (cache/'media-icon.png').read_bytes().startswith(b'\x89PNG')
    art.write_bytes((cache/'media-icon.png').read_bytes())
    record=aux.prepare({'available':True,'artwork':art.as_uri()},cache)
    prepared=cache/'prepared';prepared.mkdir()
    aux.prepare_artwork(record,prepared)
    assert Path(record['artwork']).parent==prepared/'artwork'
    import struct
    width,height=struct.unpack('>II',Path(record['artwork']).read_bytes()[16:24])
    assert width<=256 and height<=256
    for url in ['https://example.invalid/art.png' ,'file:///etc/passwd','file://remote/art.png']:
        assert 'artwork' not in aux.prepare({'available':True,'artwork':url},cache)
    assert len(aux.prepare({'available':True,'title':'a'*1000},cache)['title'])==160
subprocess.run(['cmake','-DSOURCE='+str(root/'native/lock'),'-P',str(root/'native/lock/tests/presentation_boundary.cmake')],check=True)
# Security implementation is byte-identical to the accepted baseline.
paths=['src/credential.hpp','src/auth_controller.cpp','src/auth_controller.hpp','src/wayland_owner.cpp','src/wayland_owner.hpp','src/controller.cpp','src/controller.hpp','integration/magi-lock-request','auth']
for path in paths:
    subprocess.run(['git','diff','--exit-code','9843edd9e99759d824c5d20dd10af5a8f176ba22','--','linux/magi/native/lock/'+path],cwd=root.parents[1],check=True,stdout=subprocess.DEVNULL)
print('Phase13B cache/privacy and unchanged security boundary PASS')
