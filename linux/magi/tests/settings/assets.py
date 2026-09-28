#!/usr/bin/env python3
"""Bounded managed-asset import checks in an isolated XDG data root."""
import base64
import importlib.util
import os
from pathlib import Path
import tempfile

root = Path(__file__).resolve().parents[2]
source = root / '.config/quickshell/magi/services/assets.py'
spec = importlib.util.spec_from_file_location('magi_assets', source)
assets = importlib.util.module_from_spec(spec)
spec.loader.exec_module(assets)

with tempfile.TemporaryDirectory(prefix='magi-assets-') as temporary:
    stage = Path(temporary)
    os.environ['XDG_DATA_HOME'] = str(stage / 'data')
    os.environ['XDG_CACHE_HOME'] = str(stage / 'cache')
    png = stage / 'avatar.png'
    png.write_bytes(base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII='))
    avatar = assets.perform({'op':'avatar','url':png.as_uri()})
    assert avatar['assetId'].startswith('avatar:') and Path(avatar['url'][7:]).is_file()
    assert assets.perform({'op':'avatar','url':png.as_uri()})['assetId'] == avatar['assetId']

    svg = stage / 'icon.svg'
    svg.write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M1 1h22v22H1z"/></svg>')
    icon = assets.perform({'op':'icon','url':svg.as_uri()})
    assert icon['assetId'].startswith('icon:') and Path(icon['url'][7:]).is_file()
    standard = stage / 'standard.svg'
    standard.write_text('<?xml version="1.0"?><!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"><svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" viewBox="0 0 24 24"><path d="M1 1h22v22H1z"/></svg>')
    assert assets.perform({'op':'icon','url':standard.as_uri()})['assetId'].startswith('icon:')
    bad = stage / 'bad.svg'
    bad.write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><script>alert(1)</script></svg>')
    try: assets.perform({'op':'icon','url':bad.as_uri()})
    except ValueError as error: assert 'Unsupported SVG element' in str(error)
    else: raise AssertionError('script SVG accepted')
    entity = stage / 'entity.svg'
    entity.write_text('<!DOCTYPE svg [<!ENTITY bad SYSTEM "file:///etc/passwd">]><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><text>&bad;</text></svg>')
    try: assets.perform({'op':'icon','url':entity.as_uri()})
    except ValueError as error: assert 'entities' in str(error)
    else: raise AssertionError('entity SVG accepted')
    remote = stage / 'remote.svg'
    remote.write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="url(https://example.com/x)"/></svg>')
    try: assets.perform({'op':'icon','url':remote.as_uri()})
    except ValueError as error: assert 'External SVG' in str(error)
    else: raise AssertionError('external SVG resource accepted')
    artwork = assets.perform({'op':'artwork','url':png.as_uri()})
    assert artwork['assetId'].startswith('artwork:') and Path(artwork['url'][7:]).is_file()
    print('Managed avatar persistence, SVG validation/override storage and bounded local artwork PASS')
