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
    assert assets.validate_svg(svg.read_bytes()) == svg.read_bytes()
    standard = stage / 'standard.svg'
    standard.write_text('<?xml version="1.0"?><!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"><svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" viewBox="0 0 24 24"><path d="M1 1h22v22H1z"/></svg>')
    assert b"DOCTYPE" not in assets.validate_svg(standard.read_bytes())
    noncanonical = stage / 'noncanonical.svg'
    noncanonical.write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16"><path d="M1 1h14v14H1z"/></svg>')
    try: assets.validate_svg(noncanonical.read_bytes())
    except ValueError as error: assert '24 24' in str(error)
    else: raise AssertionError('noncanonical UI icon accepted')
    bad = stage / 'bad.svg'
    bad.write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><script>alert(1)</script></svg>')
    try: assets.validate_svg(bad.read_bytes())
    except ValueError as error: assert 'Unsupported SVG element' in str(error)
    else: raise AssertionError('script SVG accepted')
    entity = stage / 'entity.svg'
    entity.write_text('<!DOCTYPE svg [<!ENTITY bad SYSTEM "file:///etc/passwd">]><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><text>&bad;</text></svg>')
    try: assets.validate_svg(entity.read_bytes())
    except ValueError as error: assert 'entities' in str(error)
    else: raise AssertionError('entity SVG accepted')
    remote = stage / 'remote.svg'
    remote.write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="url(https://example.com/x)"/></svg>')
    try: assets.validate_svg(remote.read_bytes())
    except ValueError as error: assert 'External SVG' in str(error)
    else: raise AssertionError('external SVG resource accepted')
    artwork = assets.perform({'op':'artwork','url':png.as_uri()})
    assert artwork['assetId'].startswith('artwork:') and Path(artwork['url'][7:]).is_file()
    pack = stage / 'pack'; pack.mkdir()
    (pack/'wifi.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M4 12h16"/></svg>')
    (pack/'logo.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="#89b4fa" d="M4 4h16v16H4z"/></svg>')
    manifest = pack/'manifest.json'
    manifest.write_text('{"formatVersion":1,"id":"test-pack","displayName":"Test Pack","parent":"magi-legacy","roles":{"wifi":"wifi.svg","profile":{"asset":"logo.svg","colorMode":"fixed"}}}')
    installed = assets.perform({'op':'icon-pack','url':manifest.as_uri()})
    assert installed['assetId'] == 'pack:test-pack'
    listed = [p for p in assets.perform({'op':'pack-list'})['packs'] if p['id'] == 'test-pack']
    assert listed[0]['id'] == 'test-pack' and listed[0]['roles']['wifi']['asset'] == 'wifi.svg'
    assert 'parent' not in listed[0]
    assert listed[0]['roles']['wifi']['colorMode'] == 'semantic'
    assert listed[0]['roles']['profile']['colorMode'] == 'fixed'
    assert {p['id'] for p in assets.list_packs()['packs']} >= {'magi-default', 'magi-legacy', 'test-pack'}
    installed_manifest = stage/'data/magi/icon-packs/test-pack/manifest.json'
    for bad in ['[]', '{"formatVersion":1}', '{broken']:
        installed_manifest.write_text(bad)
        assert 'test-pack' not in {p['id'] for p in assets.list_packs()['packs']}
    print('Managed assets, canonical SVG validation, pack install/list and artwork PASS')
