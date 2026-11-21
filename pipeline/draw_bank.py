# Cursor Aura © 2026 Ghosti. All Rights Reserved.
# Génère les textures « banquier » (0.0.10, aperçus validés par Ghosti) :
#  - pièce, gemme taillée, ellipse : niveaux de gris, teintés en jeu ;
#  - bourse (corps, corps brodé d'or, médaillon, col, cordon) : même
#    repère pour toutes les pièces, ±100 unités, y vers le bas ;
#  - icône de minimap tirée du logo.
# Usage : cd pipeline && python draw_bank.py
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "CursorAura" / "textures" / "bank"
PREVIEW = ROOT / "build" / "preview" / "_bank.png"
K = 4

# géométrie de la bourse (unités du repère 200 × 200)
BW, BH = 50.0, 56.0
NECK, TOP = .42 * BW, -.82 * BH


def bez3(p0, p1, p2, p3, n=24):
    out = []
    for i in range(1, n + 1):
        t = i / n
        a, b, c, d = (1 - t) ** 3, 3 * (1 - t) ** 2 * t, 3 * (1 - t) * t * t, t ** 3
        out.append((a * p0[0] + b * p1[0] + c * p2[0] + d * p3[0], a * p0[1] + b * p1[1] + c * p2[1] + d * p3[1]))
    return out


def quad(p0, c, p1, n=16):
    return [((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * c[0] + t * t * p1[0],
             (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * c[1] + t * t * p1[1]) for t in (i / n for i in range(1, n + 1))]


class Frame:
    """repère ±100 unités sur une image carrée sur-échantillonnée."""
    def __init__(self, size=128):
        self.S, self.N = size, size * K
        self.U = self.N / 200.0

    def P(self, x, y):
        return (self.N / 2 + x * self.U, self.N / 2 + y * self.U)

    def L(self):
        return Image.new("L", (self.N, self.N), 0)

    def RGBA(self):
        return Image.new("RGBA", (self.N, self.N), (0, 0, 0, 0))

    def down(self, im):
        return im.resize((self.S, self.S), Image.LANCZOS)


def body_pts():
    a = (-NECK, TOP + BH * .16)
    pts = [a] + bez3(a, (-BW * 1.45, -BH * .1), (-BW * 1.25, BH * .98), (0, BH))
    pts += bez3((0, BH), (BW * 1.25, BH * .98), (BW * 1.45, -BH * .1), (NECK, TOP + BH * .16))
    return pts


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def hexc(s):
    return tuple(int(s[i:i + 2], 16) for i in (1, 3, 5))


def purse_body(lux):
    F = Frame(128)
    mask = F.L()
    ImageDraw.Draw(mask).polygon([F.P(*p) for p in body_pts()], fill=255)
    c0, c1, c2 = (hexc("#B07A35"), hexc("#7A4F1C"), hexc("#3A240A")) if lux else \
                 (hexc("#A8683A"), hexc("#6E3F1C"), hexc("#2E1808"))
    img = F.RGBA()
    px = img.load()
    fx, fy = F.P(-BW * .4, -BH * .05)
    R = BW * 1.5 * F.U
    for y in range(F.N):
        for x in range(F.N):
            d = min(1.0, math.hypot(x - fx, y - fy) / R)
            col = lerp(c0, c1, d / .55) if d < .55 else lerp(c1, c2, (d - .55) / .45)
            px[x, y] = col + (255,)
    img.putalpha(mask)
    over = F.RGBA()
    d = ImageDraw.Draw(over)
    for i in range(-3, 4):                                    # plis du cuir
        pts = [(i * BW * .18, TOP + BH * .3)] + quad((i * BW * .18, TOP + BH * .3), (i * BW * .45, BH * .3), (i * BW * .22, BH))
        d.line([F.P(*p) for p in pts], fill=(0, 0, 0, 64), width=int(1.2 * F.U))
    sheen = F.L()                                            # reflet
    ImageDraw.Draw(sheen).ellipse((*F.P(-BW * .72, -BH * .37), *F.P(-BW * .28, BH * .47)), fill=48)
    sheen = sheen.rotate(14, center=F.P(-BW * .5, BH * .05)).filter(ImageFilter.GaussianBlur(3 * K))
    over.paste((255, 235, 200, 255), (0, 0), sheen)
    st = (232, 193, 80, 230) if lux else (230, 190, 140, 170)  # couture en pointillés
    a = (-NECK * 1.1, TOP + BH * .3)
    seam = [a] + bez3(a, (-BW * 1.3, -BH * .05), (-BW * 1.12, BH * .88), (0, BH * .9), 60) \
        + bez3((0, BH * .9), (BW * 1.12, BH * .88), (BW * 1.3, -BH * .05), (NECK * 1.1, TOP + BH * .3), 60)
    for j in range(0, len(seam) - 1, 2):
        d.line([F.P(*seam[j]), F.P(*seam[j + 1])], fill=st, width=int(1.3 * F.U))
    if lux:                                                  # arabesques dorées autour du médaillon
        ey = BH * .32
        for s in (-1, 1):
            for p in (quad((s * BW * .35, ey), (s * BW * .7, ey - BH * .25), (s * BW * .6, ey - BH * .5)),
                      quad((s * BW * .35, ey), (s * BW * .75, ey + BH * .2), (s * BW * .55, ey + BH * .45))):
                d.line([F.P(*q) for q in [(s * BW * .35, ey)] + p], fill=(232, 193, 80, 255), width=int(1.6 * F.U))
    over.putalpha(Image.composite(over.split()[3], Image.new("L", over.size, 0), mask))
    img.alpha_composite(over)
    return F.down(img)


def purse_medal():
    F = Frame(128)
    img = F.RGBA()
    d = ImageDraw.Draw(img)
    ey, r = BH * .32, BW * .3
    d.ellipse((*F.P(-r, ey - r + 1.5), *F.P(r, ey + r + 1.5)), fill=(150, 150, 150, 255))
    d.ellipse((*F.P(-r, ey - r), *F.P(r, ey + r)), fill=(235, 235, 235, 255))
    r2 = BW * .2
    d.ellipse((*F.P(-r2, ey - r2), *F.P(r2, ey + r2)), outline=(150, 150, 150, 255), width=int(1.6 * F.U))
    d.ellipse((*F.P(-r * .55, ey - r * .65), *F.P(-r * .05, ey - r * .35)), fill=(255, 255, 255, 255))
    return F.down(img)


def purse_collar(lux):
    F = Frame(128)
    top = [(-NECK * 1.25, TOP + BH * .12)] + quad((-NECK * 1.25, TOP + BH * .12), (0, TOP + BH * .02), (NECK * 1.25, TOP + BH * .12))
    bot = [(NECK * 1.05, TOP + BH * .34)] + quad((NECK * 1.05, TOP + BH * .34), (0, TOP + BH * .28), (-NECK * 1.05, TOP + BH * .34))
    mask = F.L()
    ImageDraw.Draw(mask).polygon([F.P(*p) for p in top + bot], fill=255)
    c0, c1 = (hexc("#9A6A2A"), hexc("#5A3A12")) if lux else (hexc("#8E5428"), hexc("#4E2A10"))
    img = F.RGBA()
    px = img.load()
    y0, y1 = F.P(0, TOP - BH * .05)[1], F.P(0, TOP + BH * .35)[1]
    for y in range(F.N):
        col = lerp(c0, c1, min(1, max(0, (y - y0) / (y1 - y0)))) + (255,)
        for x in range(F.N):
            px[x, y] = col
    img.putalpha(mask)
    return F.down(img)


def purse_cord():
    """cordon + nœud + 2 glands, gris (teinté en jeu : cuir clair ou or)."""
    F = Frame(128)
    img = F.RGBA()
    d = ImageDraw.Draw(img)
    dark, light = (140, 140, 140, 255), (255, 255, 255, 255)
    a, b = (-NECK * 1.1, TOP + BH * .3), (NECK * 1.1, TOP + BH * .3)
    d.line([F.P(*p) for p in [a] + quad(a, (0, TOP + BH * .42), b)], fill=dark, width=int(3 * 50 / 17 * F.U))
    a2, b2 = (-NECK * 1.1, TOP + BH * .28), (NECK * 1.1, TOP + BH * .28)
    d.line([F.P(*p) for p in [a2] + quad(a2, (0, TOP + BH * .4), b2)], fill=light, width=int(1.2 * 50 / 17 * F.U))
    kx, ky = NECK * .95, TOP + BH * .33
    for s, ang in ((0, 0.0), (1, .35)):
        ca, sa = math.cos(ang), math.sin(ang)
        def R(x, y):
            return (kx + x * ca - y * sa, ky + x * sa + y * ca)
        string = [R(0, 0)] + [R(*p) for p in quad((0, 0), (NECK * .5, BH * .25), (NECK * .25, BH * .5))]
        d.line([F.P(*p) for p in string], fill=dark, width=int(2.4 * 50 / 17 * F.U))
        d.polygon([F.P(*R(NECK * .12, BH * .48)), F.P(*R(NECK * .38, BH * .48)),
                   F.P(*R(NECK * .42, BH * .72)), F.P(*R(NECK * .08, BH * .72))], fill=light)
    r = 2.6 * 50 / 17
    d.ellipse((*F.P(kx - r, ky - r), *F.P(kx + r, ky + r)), fill=light)
    return F.down(img)


def coin():
    F = Frame(64)
    img = F.RGBA()
    d = ImageDraw.Draw(img)
    R = 92
    d.ellipse((*F.P(-R, -R + 8), *F.P(R, R + 8)), fill=(120, 120, 120, 255))
    d.ellipse((*F.P(-R, -R), *F.P(R, R)), fill=(225, 225, 225, 255))
    d.ellipse((*F.P(-R * .66, -R * .66), *F.P(R * .66, R * .66)), outline=(140, 140, 140, 255), width=int(12 * F.U))
    d.ellipse((*F.P(-R * .55, -R * .55), *F.P(-R * .1, -R * .25)), fill=(255, 255, 255, 255))
    return F.down(img.filter(ImageFilter.GaussianBlur(K * .5)))


def gemcut():
    F = Frame(64)
    img = F.RGBA()
    d = ImageDraw.Draw(img)
    s = 92
    d.polygon([F.P(0, -s), F.P(s * .75, -s * .25), F.P(0, s), F.P(-s * .75, -s * .25)], fill=(215, 215, 215, 255))
    d.polygon([F.P(0, -s * .25), F.P(s * .75, -s * .25), F.P(0, s)], fill=(150, 150, 150, 255))
    d.polygon([F.P(0, -s), F.P(s * .3, -s * .25), F.P(0, -s * .1), F.P(-s * .3, -s * .25)], fill=(255, 255, 255, 255))
    return F.down(img)


def ellipse():
    F = Frame(64)
    a = F.L()
    ImageDraw.Draw(a).ellipse((*F.P(-96, -96), *F.P(96, 96)), fill=255)
    a = F.down(a.filter(ImageFilter.GaussianBlur(K * 1.5)))
    w = Image.new("L", a.size, 255)
    return Image.merge("RGBA", (w, w, w, a))


def minimap_icon():
    S = 64
    logo = Image.open(ROOT / "build" / "logo.png").convert("RGBA").resize((S * K, S * K), Image.LANCZOS)
    m = Image.new("L", (S * K, S * K), 0)
    ImageDraw.Draw(m).ellipse((6 * K, 6 * K, (S - 6) * K, (S - 6) * K), fill=255)
    out = Image.new("RGBA", (S * K, S * K), (0, 0, 0, 0))
    out.paste(logo, (0, 0), m)
    ImageDraw.Draw(out).ellipse((5 * K, 5 * K, (S - 5) * K, (S - 5) * K), outline=(201, 162, 74, 255), width=4 * K)
    return out.resize((S, S), Image.LANCZOS)


PIECES = {
    "purse_body": lambda: purse_body(False), "purse_body_lux": lambda: purse_body(True),
    "purse_medal": purse_medal, "purse_collar": lambda: purse_collar(False),
    "purse_collar_lux": lambda: purse_collar(True), "purse_cord": purse_cord,
    "coin": coin, "gemcut": gemcut, "ellipse": ellipse, "minimap": minimap_icon,
}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    sheet = Image.new("RGBA", (len(PIECES) * 136, 136), (18, 21, 26, 255))
    for i, (name, fn) in enumerate(PIECES.items()):
        im = fn()
        im.save(OUT / f"{name}.tga")
        sheet.alpha_composite(im.resize((128, 128)), (i * 136 + 4, 4))
    sheet.save(PREVIEW)
    print(f"{len(PIECES)} textures -> {OUT}")


if __name__ == "__main__":
    main()
