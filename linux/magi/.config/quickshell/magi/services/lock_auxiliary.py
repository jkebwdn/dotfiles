#!/usr/bin/env python3
"""Publish display-only media metadata. No discovery, control, downloads or auth."""
import json, os, sys, time, tempfile, subprocess, hashlib
import xml.sax.saxutils
from pathlib import Path
from urllib.parse import urlparse, unquote

def clean(value):
    return ''.join(c for c in value if c.isprintable())[:160] if isinstance(value,str) else ''

def prepare(value, cache):
    if not isinstance(value,dict) or value.get('available') is not True: return {}
    out={'title':clean(value.get('title')), 'artist':clean(value.get('artist')), 'playing':value.get('playing') is True, 'observed':time.time()}
    raw=value.get('artwork','')
    if isinstance(raw,str):
        url=urlparse(raw)
        if url.scheme=='file' and not url.netloc:
            path=Path(unquote(url.path))
            try:
                if path.resolve().parent==(cache/'artwork').resolve() and path.is_file() and path.stat().st_size<=4*1024*1024:
                    out['artwork']=str(path.resolve())
            except OSError: pass
    return out

def prepare_icon(value, directory):
    """Resolve elsewhere, validate here, rasterize outside the lock only."""
    icon=value.get('icon',{}) if isinstance(value,dict) else {}
    if not isinstance(icon,dict): return
    try:
        if icon.get('kind')=='managed':
            url=urlparse(icon.get('url',''))
            if url.scheme!='file' or url.netloc: return
            path=Path(unquote(url.path))
            if path.stat().st_size>256*1024: return
            raw=path.read_bytes()
            from assets import validate_svg
            raw=validate_svg(raw)
        elif icon.get('kind')=='glyph':
            glyph=clean(icon.get('text'))[:8]
            raw=('<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96"><text x="48" y="72" text-anchor="middle" font-family="JetBrainsMono Nerd Font" font-size="72">'+xml.sax.saxutils.escape(glyph)+'</text></svg>').encode()
        else: return
        result=subprocess.run(['rsvg-convert','-w','96','-h','96'],input=raw,capture_output=True,timeout=3)
        if result.returncode or not result.stdout.startswith(b'\x89PNG') or len(result.stdout)>128*1024: return
        fd,name=tempfile.mkstemp(prefix='.icon-',dir=directory)
        with os.fdopen(fd,'wb') as stream: stream.write(result.stdout)
        os.replace(name,directory/'media-icon.png')
    except (OSError,ValueError,subprocess.TimeoutExpired): pass

def prepare_artwork(record, directory):
    path=record.pop('artwork',None)
    if not path: return
    try:
        from assets import image_extension
        raw=Path(path).read_bytes()
        if len(raw)>4*1024*1024: return
        codec=image_extension(raw)
        result=subprocess.run(['magick','-limit','memory','64MiB','-limit','map','128MiB','-limit','disk','0','-limit','time','3',codec+':-','-thumbnail','256x256','-strip','png:-'],input=raw,capture_output=True,timeout=4)
        if result.returncode or not result.stdout.startswith(b'\x89PNG') or len(result.stdout)>512*1024: return
        target=directory/'artwork';target.mkdir(exist_ok=True,mode=0o700)
        name=hashlib.sha256(result.stdout).hexdigest()+'.png';output=target/name
        if not output.exists():
            fd,temp=tempfile.mkstemp(prefix='.art-',dir=target)
            with os.fdopen(fd,'wb') as stream:stream.write(result.stdout)
            os.replace(temp,output)
        output.touch();record['artwork']=str(output)
        for old in sorted(target.glob('*.png'),key=lambda f:f.stat().st_mtime,reverse=True)[16:]:old.unlink()
    except (OSError,ValueError,subprocess.TimeoutExpired): pass

def publish(value):
    cache=Path(os.environ.get('XDG_CACHE_HOME',str(Path.home()/'.cache')))/'magi'
    directory=Path(os.environ.get('XDG_STATE_HOME',str(Path.home()/'.local/state')))/'magi/lock-auxiliary'
    directory.mkdir(parents=True,exist_ok=True,mode=0o700)
    record=prepare(value,cache)
    prepare_artwork(record,directory)
    prepare_icon(value,directory)
    fd,name=tempfile.mkstemp(prefix='.media-',dir=directory)
    try:
        with os.fdopen(fd,'w') as stream: json.dump(record,stream)
        os.replace(name,directory/'media.json')
    finally:
        if os.path.exists(name): os.unlink(name)

if __name__=='__main__':
    try: publish(json.loads(sys.stdin.readline(8192)))
    except (ValueError,OSError,TypeError): sys.exit(1)
