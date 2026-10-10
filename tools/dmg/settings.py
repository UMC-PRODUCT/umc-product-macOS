# Created by euijjang97 on 10/10/26.
from pathlib import Path

app = Path(defines["app"])
files = [str(app)]
symlinks = {"Applications": "/Applications"}
icon = str(app / "Contents/Resources/AppIcon.icns")
background = defines["background"]
format = "UDZO"
filesystem = "HFS+"
window_rect = ((200, 200), (660, 390))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
icon_size = 128
text_size = 13
label_pos = "bottom"
# hide_extensions adds FinderInfo attributes that invalidate strict app signature checks.
icon_locations = {app.name: (180, 180), "Applications": (480, 180)}
