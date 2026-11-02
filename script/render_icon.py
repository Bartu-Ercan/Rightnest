#!/usr/bin/env python3
"""Offscreen SVG rendering: uv run --with resvg-py script/render_icon.py."""
from pathlib import Path
import subprocess
import resvg_py
root = Path(__file__).resolve().parent.parent
assets = root / 'Assets'
master = (assets / 'concepts/a-corner.svg').read_text()
for name, color in [('symbol', '#245FCC'), ('symbol-black', '#161616'), ('symbol-white', '#FFFFFF')]:
    (assets / f'{name}.svg').write_text(master.replace('#161616', color))
body = master.split('</title>', 1)[1].rsplit('</svg>', 1)[0].replace('#161616', '#245FCC')
tile = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024"><rect x="64" y="64" width="896" height="896" rx="184" fill="#EEF2F8"/><g transform="translate(168 168) scale(2.6875)">' + body + '</g></svg>'
(assets / 'app-icon.svg').write_text(tile)
iconset = root / '.build/Rightnest.iconset'
iconset.mkdir(parents=True, exist_ok=True)
for size in [16, 32, 128, 256, 512]:
    for scale in [1, 2]:
        suffix = '@2x' if scale == 2 else ''
        (iconset / f'icon_{size}x{size}{suffix}.png').write_bytes(resvg_py.svg_to_bytes(svg_string=tile, width=size*scale, height=size*scale))
(assets / 'app-icon.png').write_bytes(resvg_py.svg_to_bytes(svg_string=tile, width=512, height=512))
subprocess.run(['iconutil', '-c', 'icns', str(iconset), '-o', str(assets / 'AppIcon.icns')], check=True)
