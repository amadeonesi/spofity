# Draws the Spotify6 icon in the iOS 6 style: dark textured tile, a glossy raised green disc
# with a music note pressed into it (Material Icons "music_note", Apache License 2.0), soft cast shadow and top gloss.
# MARK=glyph (♫ from Arial Unicode) and STYLE=raised (white note) are the alternatives that were compared.
#   python3 tools/make_icon.py Resources
import math, random, sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops

S = 1024          # final working size
K = 2             # supersampling for smooth edges
W = S * K
def lerp(a, b, t): return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))

def vgrad(w, h, top, bottom):
    g = Image.new("RGBA", (w, h)); d = ImageDraw.Draw(g)
    for y in range(h):
        d.line([(0, y), (w, y)], fill=lerp(top, bottom, y / (h - 1)))
    return g

def radial(size, stops, cx, cy, r):
    """stops: list of (t, rgba); t = distance / r"""
    img = Image.new("RGBA", (size, size)); px = img.load()
    for y in range(size):
        for x in range(size):
            t = min(1.0, math.hypot(x - cx, y - cy) / r)
            for (t0, c0), (t1, c1) in zip(stops, stops[1:]):
                if t <= t1:
                    px[x, y] = lerp(c0, c1, (t - t0) / (t1 - t0) if t1 > t0 else 0); break
    return img

def circle_mask(size, cx, cy, r, blur=0):
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    return m.filter(ImageFilter.GaussianBlur(blur)) if blur else m

# ---- 1. tile: charcoal with soft top light and fine grain (iOS 6 texture) ----
icon = vgrad(S, S, (70, 76, 73, 255), (14, 16, 15, 255))
icon.alpha_composite(radial(S, [(0, (255, 255, 255, 34)), (1, (255, 255, 255, 0))], S * 0.5, S * 0.18, S * 0.75))
random.seed(6)
grain = Image.new("L", (S, S)); gp = grain.load()
for y in range(S):
    for x in range(S):
        gp[x, y] = 128 + random.randint(-18, 18)
grain = grain.filter(ImageFilter.GaussianBlur(0.6))
noise = Image.new("RGBA", (S, S), (255, 255, 255, 0))
noise.putalpha(grain.point(lambda v: max(0, v - 128) * 2))          # light speckles
icon.alpha_composite(noise)
dark = Image.new("RGBA", (S, S), (0, 0, 0, 0))
dark.putalpha(grain.point(lambda v: max(0, 128 - v) * 2))           # dark speckles
icon.alpha_composite(dark)

# ---- 2. disc: cast shadow, dark rim, glossy green body ----
cx, cy, R = S * 0.5, S * 0.505, S * 0.36
shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
shadow.putalpha(circle_mask(S, cx, cy + 26, R + 6, 34).point(lambda v: int(v * 0.75)))
icon.alpha_composite(shadow)
rim = Image.new("RGBA", (S, S), (6, 70, 30, 255)); rim.putalpha(circle_mask(S, cx, cy, R + 10))
icon.alpha_composite(rim)
body = radial(S, [(0, (140, 250, 180, 255)), (0.45, (34, 214, 98, 255)), (0.85, (16, 160, 70, 255)), (1, (10, 120, 50, 255))],
              cx - R * 0.28, cy - R * 0.38, R * 1.45)
body.putalpha(circle_mask(S, cx, cy, R))
icon.alpha_composite(body)
# soft darker lower edge inside the disc (gives it volume)
low = Image.new("RGBA", (S, S), (0, 40, 15, 0))
inner = ImageChops.subtract(circle_mask(S, cx, cy, R), circle_mask(S, cx, cy - 26, R - 8, 10))
low.putalpha(inner.filter(ImageFilter.GaussianBlur(8)).point(lambda v: int(v * 0.55)))
icon.alpha_composite(low)

# ---- 3. the music note, pressed into the disc (dark groove + light lower lip) ----
# Note shape: Google Material Icons "music_note" (Apache License 2.0), 24x24 viewBox.
NOTE_PATH = "M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"
def svg_polys(d, steps=32):
    """Tiny SVG path reader (M/L/H/V/C/S/Z, absolute + relative), cubic curves flattened."""
    import re
    toks = re.findall(r"[MmLlHhVvCcSsZz]|-?\d*\.?\d+(?:e-?\d+)?", d); i = 0; cmd = None
    x = y = sx = sy = 0.0; px = py = None; polys = []; cur = []
    def num():
        nonlocal i; v = float(toks[i]); i += 1; return v
    while i < len(toks):
        if re.match(r"[A-Za-z]", toks[i]): cmd = toks[i]; i += 1
        rel = cmd.islower(); c = cmd.upper()
        if c == "Z":
            if cur: polys.append(cur); cur = []
            x, y = sx, sy; px = py = None; continue
        if c == "M":
            nx, ny = num(), num()
            if rel: nx += x; ny += y
            if cur: polys.append(cur)
            cur = [(nx, ny)]; x, y = sx, sy = nx, ny; cmd = "l" if rel else "L"; px = py = None
        elif c == "L":
            nx, ny = num(), num()
            if rel: nx += x; ny += y
            cur.append((nx, ny)); x, y = nx, ny; px = py = None
        elif c == "H":
            nx = num(); x = nx + x if rel else nx; cur.append((x, y)); px = py = None
        elif c == "V":
            ny = num(); y = ny + y if rel else ny; cur.append((x, y)); px = py = None
        else:  # C / S
            if c == "C":
                x1, y1 = num(), num()
                if rel: x1 += x; y1 += y
            else:
                x1, y1 = (2 * x - px, 2 * y - py) if px is not None else (x, y)
            x2, y2, ex, ey = num(), num(), num(), num()
            if rel: x2 += x; y2 += y; ex += x; ey += y
            for k in range(1, steps + 1):
                t = k / steps; u = 1 - t
                cur.append((u**3*x + 3*u*u*t*x1 + 3*u*t*t*x2 + t**3*ex, u**3*y + 3*u*u*t*y1 + 3*u*t*t*y2 + t**3*ey))
            px, py = x2, y2; x, y = ex, ey
    if cur: polys.append(cur)
    return polys
NOTE = svg_polys(NOTE_PATH)
nx0 = min(p[0] for q in NOTE for p in q); nx1 = max(p[0] for q in NOTE for p in q)
ny0 = min(p[1] for q in NOTE for p in q); ny1 = max(p[1] for q in NOTE for p in q)
NOTE_H = R * 1.18                                        # note height on the disc
import os
MARK = os.environ.get("MARK", "material"); STYLE = os.environ.get("STYLE", "engraved")   # gewählt: dunkle, eingeprägte Material-Note
def glyph_mask(dy):
    from PIL import ImageFont
    f = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Unicode.ttf", 1400)
    g = Image.new("L", (2000, 2000), 0); ImageDraw.Draw(g).text((200, 0), "\u266b", font=f, fill=255)
    g = g.crop(g.getbbox()); sc = NOTE_H * K * 1.02 / g.height
    g = g.resize((int(g.width * sc), int(g.height * sc)), Image.LANCZOS)
    m = Image.new("L", (W, W), 0); m.paste(g, (int(cx * K - g.width / 2), int((cy + dy) * K - g.height / 2)))
    return m.resize((S, S), Image.LANCZOS)
def mark_mask(dy):
    if MARK == "glyph": return glyph_mask(dy)
    m = Image.new("L", (W, W), 0); d = ImageDraw.Draw(m)
    sc = NOTE_H / (ny1 - ny0)
    ox = cx - (nx0 + nx1) / 2 * sc + R * 0.02           # optical centre: the head is heavy on the left
    oy = cy - (ny0 + ny1) / 2 * sc + dy
    for q in NOTE: d.polygon([((ox + px * sc) * K, (oy + py * sc) * K) for px, py in q], fill=255)
    return m.resize((S, S), Image.LANCZOS)
if STYLE == "engraved":
    lip = Image.new("RGBA", (S, S), (210, 255, 225, 0)); lip.putalpha(mark_mask(6).point(lambda v: int(v * 0.7)))
    icon.alpha_composite(lip)
    groove = vgrad(S, S, (4, 26, 12, 255), (8, 44, 22, 255)); groove.putalpha(mark_mask(0))
    icon.alpha_composite(groove)
    inset = Image.new("RGBA", (S, S), (0, 0, 0, 0))   # inner shadow along the top of each groove
    inset.putalpha(ImageChops.subtract(mark_mask(0), mark_mask(7)).filter(ImageFilter.GaussianBlur(2)).point(lambda v: int(v * 0.6)))
    icon.alpha_composite(inset)
else:   # raised: white glossy note with a soft shadow on the disc
    sh = Image.new("RGBA", (S, S), (0, 50, 20, 0)); sh.putalpha(mark_mask(14).filter(ImageFilter.GaussianBlur(10)).point(lambda v: int(v * 0.6)))
    icon.alpha_composite(sh)
    wn = vgrad(S, S, (255, 255, 255, 255), (214, 232, 220, 255)); wn.putalpha(mark_mask(0))
    icon.alpha_composite(wn)
# ---- 4. gloss: highlight on the disc, then the classic soft gloss over the tile ----
dg = Image.new("RGBA", (S, S), (255, 255, 255, 0))
gm = Image.new("L", (S, S), 0)
ImageDraw.Draw(gm).ellipse([cx - R * 0.86, cy - R * 0.97, cx + R * 0.86, cy + R * 0.12], fill=255)
gm = ImageChops.multiply(gm.filter(ImageFilter.GaussianBlur(10)), circle_mask(S, cx, cy, R - 6))
dg.putalpha(ImageChops.multiply(gm, vgrad(S, S, (0, 0, 0, 95), (0, 0, 0, 0)).getchannel("A")))
icon.alpha_composite(dg)
if STYLE == "engraved":
    redo = Image.new("RGBA", (S, S), (4, 26, 12, 0)); redo.putalpha(mark_mask(0).point(lambda v: int(v * 0.45)))
    icon.alpha_composite(redo)   # Rillen unter dem Glanz nachdunkeln: bleiben auch in 57 px lesbar
tg = Image.new("RGBA", (S, S), (255, 255, 255, 0))
tm = Image.new("L", (S, S), 0)
ImageDraw.Draw(tm).ellipse([-320, -600, S + 320, 455], fill=255)
tg.putalpha(ImageChops.multiply(tm.filter(ImageFilter.GaussianBlur(26)), vgrad(S, S, (0, 0, 0, 44), (0, 0, 0, 4)).getchannel("A")))
icon.alpha_composite(tg)

out = sys.argv[1]
icon = icon.convert("RGB")  # iOS 6 masks the corners itself (UIPrerenderedIcon: no extra system gloss)
for name, px in [("Icon.png", 57), ("Icon@2x.png", 114), ("Icon-Small.png", 29), ("Icon-Small@2x.png", 58),
                 ("Icon-72.png", 72), ("Icon-72@2x.png", 144), ("Icon-Small-50.png", 50), ("Icon-Small-50@2x.png", 100)]:   # iPad
    icon.resize((px, px), Image.LANCZOS).save(f"{out}/{name}")
if len(sys.argv) > 2:
    icon.resize((512, 512), Image.LANCZOS).save(sys.argv[2])
