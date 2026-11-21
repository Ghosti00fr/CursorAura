# Cursor Aura © 2026 Ghosti. All Rights Reserved.
# Génère les pièces des écussons PvP (0.0.9, aperçu validé par Ghosti).
# Chaque pièce : 128x128, RGBA, TGA, blanc (couleur appliquée en jeu).
# Toutes les pièces partagent le même repère : centre de l'écusson au
# centre de l'image, ±100 unités de l'aperçu sur la largeur (y vers le bas).
# Usage : cd pipeline && python draw_crests.py
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "CursorAura" / "textures" / "crest"
PREVIEW = ROOT / "build" / "preview" / "_crests.png"
S, K = 128, 4
N = S * K
U = N / 200.0           # pixels (sur-échantillonnés) par unité de l'aperçu


def P(x, y):
    return (N / 2 + x * U, N / 2 + y * U)


def canvas():
    return Image.new("L", (N, N), 0)


def finish(a, blur=0.4):
    if blur:
        a = a.filter(ImageFilter.GaussianBlur(blur * K))
    a = a.resize((S, S), Image.LANCZOS)
    w = Image.new("L", (S, S), 255)
    return Image.merge("RGBA", (w, w, w, a))


def quad(p0, c, p1, n=12):
    out = []
    for i in range(1, n + 1):
        t = i / n
        out.append(((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * c[0] + t * t * p1[0],
                    (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * c[1] + t * t * p1[1]))
    return out


def shield_a_pts():
    pts = [(-34, -38)]
    pts += quad((-34, -38), (0, -46), (34, -38))
    pts += [(34, 0)]
    pts += quad((34, 0), (30, 30), (0, 46))
    pts += quad((0, 46), (-30, 30), (-34, 0))
    return pts


def shield_h_pts():
    return [(-40, -44), (-22, -34), (0, -42), (22, -34), (40, -44), (34, -4), (40, 10),
            (0, 46), (-40, 10), (-34, -4)]


def poly(pts, width=0):
    a = canvas()
    d = ImageDraw.Draw(a)
    q = [P(*p) for p in pts]
    if width:
        d.line(q + [q[0]], fill=255, width=int(width * U), joint="curve")
    else:
        d.polygon(q, fill=255)
    return a


def half(pts):
    a = poly(pts)
    ImageDraw.Draw(a).rectangle((N / 2, 0, N, N), fill=0)
    return a


def shield_a(): return finish(poly(shield_a_pts()))
def half_a(): return finish(half(shield_a_pts()))
def rim_a(): return finish(poly(shield_a_pts(), 4.5))
def shield_h(): return finish(poly(shield_h_pts()))
def half_h(): return finish(half(shield_h_pts()))
def rim_h(): return finish(poly(shield_h_pts(), 4.5))


def spikes_h():
    a = canvas()
    d = ImageDraw.Draw(a)
    for x, y in [(-40, -44), (40, -44), (-40, 10), (40, 10)]:
        s = -1 if x < 0 else 1
        d.polygon([P(x, y - 6), P(x + s * 9, y), P(x, y + 6)], fill=255)
    d.polygon([P(-5, 46), P(0, 55), P(5, 46)], fill=255)
    return finish(a)


def stroke(points, w):
    a = canvas()
    d = ImageDraw.Draw(a)
    q = [P(*p) for p in points]
    d.line(q, fill=255, width=int(w * U), joint="curve")
    r = w * U / 2
    for x, y in (q[0], q[-1]):
        d.ellipse((x - r, y - r, x + r, y + r), fill=255)
    return a


def chevron(): return finish(stroke([(-18, 8), (0, 0), (18, 8)], 5))     # placé à y = -18 + 10 i
def bar(): return finish(stroke([(-18, 0), (18, 0)], 5))


def star():
    a = canvas()
    pts = []
    for i in range(10):
        ang = -math.pi / 2 + i * math.pi / 5
        r = 20 * (.42 if i % 2 else 1)
        pts.append((math.cos(ang) * r, math.sin(ang) * r))
    return finish(poly(pts))


def tusks():
    a = stroke([(-14, 22)] + quad((-14, 22), (-20, -6), (-6, -22)), 6)
    b = stroke([(14, 22)] + quad((14, 22), (20, -6), (6, -22)), 6)
    from PIL import ImageChops
    a = ImageChops.lighter(a, b)
    ImageDraw.Draw(a).ellipse((*P(-5, -1), *P(5, 9)), fill=255)
    return finish(a)


def dot():
    a = canvas()
    ImageDraw.Draw(a).ellipse((*P(-4, -4), *P(4, 4)), fill=255)
    return finish(a)


def gem():
    a = canvas()
    ImageDraw.Draw(a).ellipse((*P(-3.5, -57.5), *P(3.5, -50.5)), fill=255)
    return finish(a)


def sword_blade():
    a = canvas()
    d = ImageDraw.Draw(a)
    d.rectangle((*P(-2.5, -62), *P(2.5, 12)), fill=255)
    d.polygon([P(-2.5, -62), P(0, -70), P(2.5, -62)], fill=255)
    return finish(a)


def sword_hilt():
    a = canvas()
    d = ImageDraw.Draw(a)
    d.rectangle((*P(-11, 12), *P(11, 16)), fill=255)
    d.rectangle((*P(-2, 16), *P(2, 28)), fill=255)
    d.ellipse((*P(-3.5, 26.5), *P(3.5, 33.5)), fill=255)
    return finish(a)


def axe_haft():
    a = canvas()
    ImageDraw.Draw(a).rectangle((*P(-2.5, -56), *P(2.5, 30)), fill=255)
    return finish(a)


def axe_head():
    a = poly([(2, -54)] + quad((2, -54), (26, -50), (24, -30)) + quad((24, -30), (14, -36), (2, -34)))
    b = poly([(-2, -54)] + quad((-2, -54), (-18, -48), (-16, -36)) + [(-2, -38)])
    from PIL import ImageChops
    return finish(ImageChops.lighter(a, b))


def wing_a():   # aile droite ; la gauche = miroir en jeu
    pts = [(32, -20)] + quad((32, -20), (80, -46), (96, -14)) + quad((96, -14), (76, -18), (84, 0)) \
        + quad((84, 0), (64, -6), (70, 12)) + quad((70, 12), (52, 4), (34, 10))
    return finish(poly(pts))


def horn_h():   # corne droite ; la gauche = miroir en jeu
    pts = [(34, -26)] + quad((34, -26), (84, -30), (90, -74)) + quad((90, -74), (70, -40), (36, -6))
    return finish(poly(pts))


def crown_a():
    return finish(poly([(-24, -46), (-24, -60), (-12, -52), (0, -66), (12, -52), (24, -60), (24, -46)]))


def crown_h():
    return finish(poly([(-26, -44), (-30, -70), (-14, -52), (0, -76), (14, -52), (30, -70), (26, -44)]))


def rays():
    a = canvas()
    d = ImageDraw.Draw(a)
    for i in range(12):
        ang = i * math.pi / 6
        def rot(x, y):
            return (x * math.cos(ang) - y * math.sin(ang), x * math.sin(ang) + y * math.cos(ang))
        d.polygon([P(0, 0), P(*rot(-8, -98)), P(*rot(8, -98))], fill=255)
    a = a.filter(ImageFilter.GaussianBlur(2 * K))
    return finish(a, 0)


PIECES = {
    "shield_a": shield_a, "half_a": half_a, "rim_a": rim_a, "shield_h": shield_h, "half_h": half_h,
    "rim_h": rim_h, "spikes_h": spikes_h, "chevron": chevron, "bar": bar, "star": star, "tusks": tusks,
    "dot": dot, "gem": gem, "sword_blade": sword_blade, "sword_hilt": sword_hilt, "axe_haft": axe_haft,
    "axe_head": axe_head, "wing_a": wing_a, "horn_h": horn_h, "crown_a": crown_a, "crown_h": crown_h,
    "rays": rays,
}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    cols, cell = 8, S + 8
    rows = math.ceil(len(PIECES) / cols)
    sheet = Image.new("RGBA", (cols * cell, rows * cell), (18, 21, 26, 255))
    for i, (name, fn) in enumerate(PIECES.items()):
        im = fn()
        im.save(OUT / f"{name}.tga")
        sheet.alpha_composite(im, ((i % cols) * cell + 4, (i // cols) * cell + 4))
    sheet.save(PREVIEW)
    print(f"{len(PIECES)} pièces -> {OUT}")


if __name__ == "__main__":
    main()
