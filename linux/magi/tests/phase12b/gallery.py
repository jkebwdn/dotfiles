#!/usr/bin/env python3
"""Review artifact only: exact registry swatches and production Qt captures."""
from pathlib import Path
import html,json,shutil,sys
root=Path(__file__).resolve().parents[2]
out=Path(sys.argv[1]);out.mkdir(parents=True,exist_ok=True)
source=Path(sys.argv[2])
registry=json.loads((root/'.config/quickshell/magi/theme/palettes/registry.json').read_text())
cards=[]
for t in registry['themes']:
 r=t['roles'];e=html.escape
 swatches=''.join(f'<div class="swatch" style="background:{r[k]};color:{r["on"+k.title()] if k in ["accent"]+registry["accentRoles"] else r["text"]}">{e(k)}<br><code>{r[k]}</code></div>' for k in ['background','surface','elevated','accent']+registry['accentRoles'])
 texts=''.join(f'<span style="color:{r[k]}">{k}: {r[k]} </span>' for k in ['text','subtext','muted'])
 capture=source/(t['id']+'.png');picture=''
 if capture.exists():
  shutil.copyfile(capture,out/capture.name)
  picture=f'<a href="{capture.name}"><img loading="lazy" src="{capture.name}" alt="Production Settings and Control Centre preview — {e(t["label"])}"></a>'
 cards.append(f'<article style="background:{r["background"]};color:{r["text"]};border-color:{r["border"]}"><h2>{e(t["label"])}</h2><p>{t["id"]} · {"dark" if t["dark"] else "light"}</p><div class="swatches">{swatches}</div><p>{texts}</p>{picture}</article>')
(out/'index.html').write_text('''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>MAGI Phase 12B theme review</title>
<style>body{font:16px system-ui;margin:24px;background:#eee;color:#222}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,580px),1fr));gap:18px}article{padding:18px;border:1px solid;border-radius:14px}h2{margin:0}p{line-height:1.6}.swatches{display:flex;flex-wrap:wrap;gap:6px}.swatch{padding:10px;min-width:90px;border-radius:5px}img{width:100%;margin-top:10px}a{color:inherit}</style>
<h1>MAGI · Phase 12B</h1><p>Isolated review. Eight additions; existing themes retained. Swatches are exact canonical RGB values. Click captures for full-size production Settings/Control Centre renders.</p>
<p>Software Qt captures omit shader-rendered SVG icons and artwork. Native visual review is pending; no renderer changes or live theme activation. Accent labels/muted colours may have low contrast: see <a href="contrast.json">measured contrast report</a>. This gallery does not claim WCAG conformance.</p><main>'''+''.join(cards)+'</main></html>\n')
