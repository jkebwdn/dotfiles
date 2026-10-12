#!/usr/bin/env python3
"""Production service/content in disposable config; native layer wrapper offscreen."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
root=Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='magi-wallpaper-ui-') as tmp:
    stage=Path(tmp); config=stage/'config'
    shutil.copytree(root/'.config/quickshell/magi',config)
    library=stage/'library'; library.mkdir()
    # Qt-generated fixture, with no library dependency.
    import struct,zlib
    def chunk(kind,data): return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data))
    png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',1,1,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(b'\x00\x66\x88\xcc'))+chunk(b'IEND',b'')
    image=library/'test image.png'; image.write_bytes(png)
    (config/'settings.json').write_text(json.dumps({'schemaVersion':9,'wallpaper':{'directories':[str(library)]}}))
    path=config/'components/wallpaper/WallpaperWindow.qml'
    text=path.read_text().replace('PanelWindow {','FloatingWindow {\n    implicitWidth: 1200; implicitHeight: 900')
    text='\n'.join(line for line in text.splitlines() if not any(s in line for s in ['    anchors {','    exclusionMode:', '    WlrLayershell.', '    mask:']))
    path.write_text(text)
    bin_dir=stage/'bin'; bin_dir.mkdir()
    (bin_dir/'hyprctl').write_text('''#!/usr/bin/env python3
import sys,json,os
from pathlib import Path
p=Path(os.environ['MAGI_FAKE_CURRENT'])
a=sys.argv[1:]
if a==['-j','monitors']: print(json.dumps([{'name':'TEST-1','description':'Fixture'}]))
elif a==['hyprpaper','listactive']: print('TEST-1: '+p.read_text())
elif a[:2]==['hyprpaper','wallpaper']:
 monitor,path,mode=a[2].split(',')
 if mode=='contain': print('error: simulated rejection'); sys.exit(1)
 p.write_text(path)
else: sys.exit(1)
'''); (bin_dir/'hyprctl').chmod(0o755)
    current=stage/'current'; current.write_text(str(image))
    runtime=stage/'runtime'; runtime.mkdir(mode=0o700)
    env=dict(os.environ,QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software',XDG_RUNTIME_DIR=str(runtime),
        XDG_STATE_HOME=str(stage/'state'),PATH=str(bin_dir)+':'+os.environ['PATH'],MAGI_FAKE_CURRENT=str(current),
        MAGI_WALLPAPER_IMAGE=str(image),MAGI_WALLPAPER_ROOT=str(library))
    env.pop('WAYLAND_DISPLAY',None); env.pop('DISPLAY',None)
    (config/'test.qml').write_text(Path(__file__).with_name('integration.qml').read_text().replace('../../.config/quickshell/magi/',''))
    result=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,text=True,capture_output=True,timeout=25)
    out=result.stdout+result.stderr; print(out)
    assert result.returncode==0 and 'Wallpaper UI, apply, failure, state, settings and reset PASS' in out
    assert 'FAIL' not in out and 'TypeError' not in out and 'ReferenceError' not in out
    persisted=json.loads((stage/'state/magi/wallpaper/state.json').read_text())
    assert persisted['shared']['path']==str(image) and persisted['favourites']==[str(image)]
    assert image.read_bytes()==png
    print('Wallpaper disk persistence and source immutability PASS')

    # New Quickshell process, same state directory; simulate hyprpaper reset.
    current.write_text('/previous/session/wallpaper.png')
    (config/'test.qml').write_text(Path(__file__).with_name('reload.qml').read_text().replace('../../.config/quickshell/magi/',''))
    result=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,text=True,capture_output=True,timeout=25)
    out=result.stdout+result.stderr; print(out)
    assert result.returncode==0 and 'Wallpaper process restart, thumbnail decode, Enter, Escape and outside dismissal PASS' in out
    assert 'FAIL' not in out and 'TypeError' not in out and 'ReferenceError' not in out
    assert current.read_text()==str(image)
