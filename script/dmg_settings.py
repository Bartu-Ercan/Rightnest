"""Finder presentation for the Rightnest distribution image; build-time only."""
from pathlib import Path

application = defines["app"]
files = [application]
symlinks = {"Applications": "/Applications"}
format = "UDZO"
filesystem = "HFS+"
size = "32M"  # Keep HFS+ above its minimum even when the app/background are small.
icon = str(Path(application) / "Contents/Resources/AppIcon.icns")
background = defines["background"]
window_rect = ((160, 120), (800, 580))
icon_locations = {"Rightnest.app": (210, 274), "Applications": (590, 274)}
icon_size = 112
text_size = 14
label_pos = "bottom"
arrange_by = None
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
show_icon_preview = False
hide_extensions = []  # FinderInfo on the signed app would invalidate strict verification.
