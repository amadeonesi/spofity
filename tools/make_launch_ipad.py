# Draws the iPad launch images (iOS 5/6, status bar excluded): the app's dark background with an empty sidebar
# and an empty player bar, at the same proportions as the iPad layout (sidebar 220 pt, player bar 72 pt).
#   python3 tools/make_launch_ipad.py Resources
import sys
from PIL import Image, ImageDraw

BG, SIDE, BAR, LINE = (18, 18, 18), (18, 18, 20), (24, 24, 24), (42, 42, 42)   # SpotTheme bg / sidebar / bar / line

def draw(w, h, s):
    """w, h in points (without the 20 pt status bar), s = scale (1 or 2)"""
    img = Image.new("RGB", (w * s, h * s), BG); d = ImageDraw.Draw(img)
    side_w, bar_h = 220 * s, 72 * s
    d.rectangle([0, 0, side_w - 1, h * s - bar_h - 1], fill=SIDE)
    d.rectangle([side_w - s, 0, side_w - 1, h * s - bar_h - 1], fill=LINE)       # Kante Seitenleiste/Inhalt
    d.rectangle([0, h * s - bar_h, w * s - 1, h * s - 1], fill=BAR)
    d.rectangle([0, h * s - bar_h, w * s - 1, h * s - bar_h + s - 1], fill=LINE)  # Linie über der Player-Leiste
    return img

out = sys.argv[1]
for name, w, h, s in [("Default-Portrait~ipad.png", 768, 1004, 1), ("Default-Landscape~ipad.png", 1024, 748, 1),
                      ("Default-Portrait@2x~ipad.png", 768, 1004, 2), ("Default-Landscape@2x~ipad.png", 1024, 748, 2)]:
    draw(w, h, s).save(f"{out}/{name}")
