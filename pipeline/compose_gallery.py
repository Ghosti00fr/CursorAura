# Cursor Aura © 2026 Ghosti. All Rights Reserved.
# Compose les images de la galerie CurseForge à partir de build/gallery.txt
# (relevé du vrai code de l'addon par render_gallery.lua) et des vraies textures.
# Usage (racine du projet) : python pipeline/compose_gallery.py
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
TEXDIR = ROOT / "CursorAura"
OUT = ROOT / "build" / "gallery"
BG = (14, 16, 22)
_cache = {}


def font(size, bold=False):
    for name in (("segoeuib.ttf" if bold else "segoeui.ttf"), "arial.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            pass
    return ImageFont.load_default()


def load(path):
    p = path.replace("Interface\\AddOns\\CursorAura\\", "").replace("\\", "/")
    if p not in _cache:
        _cache[p] = Image.open(TEXDIR / (p + ".tga")).convert("RGBA")
    return _cache[p]


def parse():
    tiles, cur = {}, None
    for line in (ROOT / "build" / "gallery.txt").read_text(encoding="utf-8").splitlines():
        f = line.split()
        if f[0] == "TILE":
            cur = tiles.setdefault(f[1], [])
        elif f[0] == "T":
            cur.append(("T", f[1], *map(float, f[2:11]), f[11], int(f[12]), int(f[13]), int(f[14])))
        elif f[0] == "L":
            cur.append(("L", f[1], *map(float, f[2:11]), int(f[11]), int(f[12])))
    return tiles


def tinted(src, w, h, r, g, b, a, rot, flip):
    w, h = max(1, int(round(w))), max(1, int(round(h)))
    im = src.resize((w, h), Image.LANCZOS)
    if flip:
        im = im.transpose(Image.FLIP_LEFT_RIGHT)
    if rot:
        im = im.rotate(math.degrees(rot), resample=Image.BICUBIC, expand=True)
    R, G, B, A = im.split()
    R = R.point(lambda v: int(v * r)); G = G.point(lambda v: int(v * g)); B = B.point(lambda v: int(v * b))
    A = A.point(lambda v: int(v * min(1.0, a)))
    return Image.merge("RGBA", (R, G, B, A))


def blit(canvas, im, cx, cy, blend):
    x, y = int(round(cx - im.width / 2)), int(round(cy - im.height / 2))
    if blend == "ADD":
        R, G, B, A = im.split()
        pre = Image.merge("RGB", [ImageChops.multiply(c, A) for c in (R, G, B)])
        box = (x, y, x + im.width, y + im.height)
        layer = Image.new("RGB", canvas.size, (0, 0, 0))
        layer.paste(pre, (x, y))
        canvas.paste(ImageChops.add(canvas.convert("RGB"), layer).convert("RGBA"), (0, 0))
    else:
        layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        layer.paste(im, (x, y))
        canvas.alpha_composite(layer)


def arrow(d, x, y, s=1.0):
    pts = [(0, 0), (0, 18), (4, 14), (8, 21), (10, 20), (6, 13), (12, 13)]
    q = [(x + px * s, y + py * s) for px, py in pts]
    d.polygon(q, fill=(255, 255, 255), outline=(0, 0, 0))


def tile(items, size, origin, scale):
    W, H = size
    c = Image.new("RGBA", (W, H), BG + (255,))
    ox, oy = origin
    for it in sorted(items, key=lambda i: (i[-3] if i[0] == "T" else i[-2], i[-2] if i[0] == "T" else i[-1])):
        if it[0] == "T":
            _, f, x, y, w, h, r, g, b, a, rot, blend, sub, idx, flip = it
            im = tinted(load(f), w * scale, h * scale, r, g, b, a, rot, flip)
            blit(c, im, ox + x * scale, oy - y * scale, blend)
        else:
            _, f, x1, y1, x2, y2, th, r, g, b, a, sub, idx = it
            L = math.hypot(x2 - x1, y2 - y1) * scale
            if L < 1 or f == "-":
                continue
            im = tinted(load(f), L, th * scale, r, g, b, a, math.atan2(y2 - y1, x2 - x1), False)
            blit(c, im, ox + (x1 + x2) / 2 * scale, oy - (y1 + y2) / 2 * scale, "ADD")
    arrow(ImageDraw.Draw(c), ox, oy, scale * .9)
    return c


def sheet(name, title, sub, rows, tiles, size, origin, scale, cols):
    W, H = size
    gap, pad, head = 14, 28, 96
    n = sum(len(r) for r in rows)
    width = pad * 2 + cols * W + (cols - 1) * gap
    nrows = sum(math.ceil(len(r) / cols) for r in rows)
    height = head + pad + nrows * (H + 34 + gap) + 24
    img = Image.new("RGB", (width, height), (9, 11, 15))
    d = ImageDraw.Draw(img)
    d.text((pad, 22), title, font=font(34, True), fill=(240, 240, 240))
    d.text((pad, 64), sub, font=font(18), fill=(150, 170, 200))
    y = head + 8
    for row in rows:
        for i, (key, label) in enumerate(row):
            if i and i % cols == 0:
                y += H + 34 + gap
            x = pad + (i % cols) * (W + gap)
            img.paste(tile(tiles[key], size, origin, scale).convert("RGB"), (x, y))
            d.text((x + 4, y + H + 6), label, font=font(18, True), fill=(225, 225, 225))
        y += H + 34 + gap
    d.text((pad, height - 26), "Rendered from the addon's own particle code and textures, outside the game. In-game rendering may differ slightly.",
           font=font(13), fill=(110, 115, 125))
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / name)
    print(name, img.size)


def main():
    t = parse()
    fx = [("feu", "Fire"), ("givre", "Frost"), ("arcanes", "Arcane"), ("eclairs", "Lightning"), ("eau", "Water"),
          ("vent", "Wind"), ("nature", "Nature"), ("lumiere", "Light"), ("ombre", "Shadow"), ("fumee", "Smoke"),
          ("gangrene", "Fel"), ("sang", "Blood"), ("terre", "Earth"), ("protection", "Protection"), ("vindicte", "Retribution")]
    sheet("1-effects.png", "Cursor Aura - 15 class effects", "Auto mode picks the effect from your class and talent tree, or choose any effect yourself.",
          [[("fx_" + k, n) for k, n in fx]], t, (236, 200), (118, 100), 1.6, 5)
    st = [(0, "No streak"), (3, "3 kills"), (5, "5 kills"), (10, "10 kills"), (20, "20 kills"), (50, "50 kills"), (100, "100 kills")]
    sheet("2-pvp-streak.png", "PvP kill streak", "Every honorable kill grows your aura. Death resets the streak. Shown on the Fire effect.",
          [[("streak_%d" % n, l) for n, l in st[:4]], [("streak_%d" % n, l) for n, l in st[4:]]], t, (290, 230), (145, 115), 1.6, 4)
    ranks = [1, 3, 5, 6, 8, 10, 12, 14]
    sheet("3-pvp-rank-crest.png", "PvP rank crest", "A shield next to the cursor that evolves with your honor rank. One for the Alliance, one for the Horde.",
          [[("crest_Alliance_%d" % r, "Alliance rank %d" % r) for r in ranks], [("crest_Horde_%d" % r, "Horde rank %d" % r) for r in ranks]],
          t, (200, 200), (62, 62), 1.6, 4)
    gold = [(50, "50 gold"), (1000, "1,000 gold"), (10000, "10,000 gold"), (100000, "100,000 gold"), (1000000, "1,000,000 gold")]
    sheet("4-banker-gold.png", "Banker: Gold", "A coin aura with a cascade of coins. It grows with the gold your character carries.",
          [[("bank_or_%d" % g, l) for g, l in gold]], t, (236, 300), (118, 90), 1.0, 5)
    sheet("5-banker-purse.png", "Banker: Purse", "A leather purse that fills up, overflows and squashes when coins drop in. It grows with your gold.",
          [[("bank_bourse_%d" % g, l) for g, l in gold]], t, (236, 250), (36, 40), 1.0, 5)


if __name__ == "__main__":
    main()
