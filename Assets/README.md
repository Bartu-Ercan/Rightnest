# Rightnest identity

User-selected direction: A / Corner. Blue #245FCC mark, pale #EEF2F8 tile, black #161616 and white one-color variants. Keep clear space at least one 28-unit bar width. Minimum symbol size 16 px; avoid adding detail or traffic-light colors. SVG masters are editable; PNG and ICNS are generated, not independently redrawn.

Regenerate offscreen on macOS with `uv run --with resvg-py script/render_icon.py`. `iconutil` produces the application ICNS. Rendering dependencies are developer tooling only, not app runtime dependencies. Concept sheet in concepts/ records alternatives and the chosen direction. Reference-library artwork is not bundled.

Installer art uses the same blue/pale palette, an800×500point canvas within an800×580Finder window,112point icons at(210,274)/(590,274), a quiet right-corner motif and one drag arrow. Generate with `swift script/render_installer.swift`. The background TIFF has1×/2× representations at72/144DPI; the documentation PNG preview is explicitly an illustration. Finder draws real icons and labels in the mounted image. The installer keeps system window chrome; no borderless installer executable is added.
