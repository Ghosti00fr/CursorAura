# Cursor Aura © 2026 Ghosti. All Rights Reserved.
# Génère les 16 sprites de particules : 64x64, RGBA, TGA non compressé,
# blanc / niveaux de gris (la couleur est appliquée en jeu par SetVertexColor).
# Usage : cd pipeline && python draw_sprites.py
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "CursorAura" / "textures"
PREVIEW = ROOT / "build" / "preview" / "_sprites.png"
S = 64          # taille finale
K = 4           # sur-échantillonnage
N = S * K
C = N / 2


def canvas():
    return Image.new("L", (N, N), 0)


def finish(alpha, gray=None, blur=0):
    """alpha (L, N×N) [+ gris] -> image RGBA 64×64."""
    if blur:
        alpha = alpha.filter(ImageFilter.GaussianBlur(blur * K))
    alpha = alpha.resize((S, S), Image.LANCZOS)
    g = (gray.resize((S, S), Image.LANCZOS) if gray else Image.new("L", (S, S), 255))
    return Image.merge("RGBA", (g, g, g, alpha))


def radial(power=2.0, r0=1.0, peak=255):
    img = canvas()
    px = img.load()
    R = C * r0
    for y in range(N):
        for x in range(N):
            d = math.hypot(x - C + .5, y - C + .5) / R
            px[x, y] = int(peak * max(0.0, 1 - d) ** power) if d < 1 else 0
    return img


def soft():
    return finish(radial(2.0, .95))


def flame():
    a = canvas()
    d = ImageDraw.Draw(a)
    # goutte : bas arrondi, pointe vers le haut
    d.ellipse((C - 13 * K, C - 2 * K, C + 13 * K, C + 24 * K), fill=255)
    d.polygon([(C - 13 * K, C + 9 * K), (C, C - 28 * K), (C + 13 * K, C + 9 * K)], fill=255)
    a = a.filter(ImageFilter.GaussianBlur(3 * K))
    glow = radial(1.2, .9)
    from PIL import ImageChops
    return finish(ImageChops.multiply(a, Image.eval(glow, lambda v: min(255, v + 90))))


def flake():
    a = canvas()
    d = ImageDraw.Draw(a)
    L, w = 26 * K, int(2.2 * K)
    for i in range(3):
        t = i * math.pi / 3
        dx, dy = math.cos(t) * L, math.sin(t) * L
        d.line((C - dx, C - dy, C + dx, C + dy), fill=255, width=w)
        for sgn in (1, -1):  # petites branches
            bx, by = C + sgn * dx * .6, C + sgn * dy * .6
            for side in (1, -1):
                tt = t + side * math.pi / 4 + (math.pi if sgn < 0 else 0)
                d.line((bx, by, bx + math.cos(tt) * 8 * K, by + math.sin(tt) * 8 * K), fill=230, width=w)
    return finish(a, blur=.4)


def star():
    a = canvas()
    d = ImageDraw.Draw(a)
    L, W = 30 * K, 3 * K
    d.polygon([(C - L, C), (C, C - W), (C + L, C), (C, C + W)], fill=255)
    d.polygon([(C, C - L), (C + W, C), (C, C + L), (C - W, C)], fill=255)
    from PIL import ImageChops
    return finish(ImageChops.lighter(a.filter(ImageFilter.GaussianBlur(.6 * K)), radial(3, .45)))


def leaf():
    a, g = canvas(), Image.new("L", (N, N), 255)
    d, dg = ImageDraw.Draw(a), ImageDraw.Draw(g)
    pts = []
    for i in range(41):
        t = i / 40 * math.pi
        pts.append((C - 28 * K * math.cos(t), C - 13 * K * math.sin(t) ** 1.3))
    for i in range(41):
        t = i / 40 * math.pi
        pts.append((C + 28 * K * math.cos(t), C + 13 * K * math.sin(t) ** 1.3))
    d.polygon(pts, fill=255)
    dg.line((C - 26 * K, C, C + 26 * K, C), fill=150, width=int(1.6 * K))
    return finish(a.filter(ImageFilter.GaussianBlur(.5 * K)), g)


def rock():
    random.seed(7)
    a, g = canvas(), Image.new("L", (N, N), 200)
    d, dg = ImageDraw.Draw(a), ImageDraw.Draw(g)
    pts = []
    for i in range(6):
        t = i / 6 * 2 * math.pi + random.uniform(-.25, .25)
        r = random.uniform(20, 28) * K
        pts.append((C + math.cos(t) * r, C + math.sin(t) * r))
    d.polygon(pts, fill=255)
    dg.polygon([pts[3], pts[4], pts[5], (C, C)], fill=255)   # facette claire
    dg.polygon([pts[0], pts[1], (C, C)], fill=140)            # facette sombre
    return finish(a.filter(ImageFilter.GaussianBlur(.4 * K)), g)


def bubble():
    a = canvas()
    d = ImageDraw.Draw(a)
    R = 26 * K
    d.ellipse((C - R, C - R, C + R, C + R), fill=60)
    d.ellipse((C - R, C - R, C + R, C + R), outline=235, width=int(2.5 * K))
    d.ellipse((C - 15 * K, C - 15 * K, C - 5 * K, C - 5 * K), fill=255)
    return finish(a, blur=.4)


def puff():
    random.seed(3)
    a = canvas()
    d = ImageDraw.Draw(a)
    for _ in range(7):
        r = random.uniform(10, 16) * K
        x, y = C + random.uniform(-10, 10) * K, C + random.uniform(-8, 8) * K
        d.ellipse((x - r, y - r, x + r, y + r), fill=150)
    return finish(a, blur=5)


def arc():
    """arc de 0 à 60° (sens trigo, 0 = vers la droite), rayon 30 px, centré."""
    a = canvas()
    d = ImageDraw.Draw(a)
    R, steps = 30 * K, 60
    for i in range(steps):
        t0, t1 = i / steps * math.radians(60), (i + 1) / steps * math.radians(60)
        fade = math.sin(math.pi * (i + .5) / steps)  # extrémités effilées
        d.line((C + math.cos(t0) * R, C - math.sin(t0) * R, C + math.cos(t1) * R, C - math.sin(t1) * R),
               fill=int(255 * fade), width=int(2 * K))
    return finish(a, blur=.3)


def streak():
    a = canvas()
    d = ImageDraw.Draw(a)
    d.polygon([(2 * K, C), (C, C - 3 * K), (N - 2 * K, C), (C, C + 3 * K)], fill=255)
    return finish(a, blur=.8)


def bolt(seed):
    random.seed(seed)
    pts = [(2 * K, C), (N - 2 * K, C)]
    for depth, amp in ((0, 14), (1, 8), (2, 5), (3, 3)):
        new = [pts[0]]
        for (x1, y1), (x2, y2) in zip(pts, pts[1:]):
            new += [((x1 + x2) / 2, (y1 + y2) / 2 + random.uniform(-amp, amp) * K), (x2, y2)]
        pts = new
    pts = [(x, max(6 * K, min(N - 6 * K, y))) for x, y in pts]
    core, glow = canvas(), canvas()
    ImageDraw.Draw(glow).line(pts, fill=150, width=int(5 * K))
    ImageDraw.Draw(core).line(pts, fill=255, width=int(1.6 * K))
    from PIL import ImageChops
    return finish(ImageChops.lighter(glow.filter(ImageFilter.GaussianBlur(2 * K)), core))


def drop():
    # goutte de sang : bas rond, pointe vers le haut (elle tombe)
    a = canvas()
    d = ImageDraw.Draw(a)
    d.ellipse((C - 11 * K, C - 2 * K, C + 11 * K, C + 20 * K), fill=255)
    d.polygon([(C - 10 * K, C + 6 * K), (C, C - 26 * K), (C + 10 * K, C + 6 * K)], fill=255)
    return finish(a, blur=.8)


def shard():
    # éclat de bouclier : losange effilé
    a = canvas()
    ImageDraw.Draw(a).polygon([(C, C - 28 * K), (C + 11 * K, C + 4 * K), (C, C + 24 * K), (C - 10 * K, C + 4 * K)], fill=255)
    return finish(a, blur=.6)


def voidcore():
    return finish(radial(1.0, .98, peak=242))


def ring():
    a = canvas()
    R = 28 * K
    ImageDraw.Draw(a).ellipse((C - R, C - R, C + R, C + R), outline=255, width=int(2 * K))
    return finish(a, blur=.3)


SPRITES = {
    "soft": soft, "flame": flame, "flake": flake, "star": star, "leaf": leaf, "rock": rock,
    "bubble": bubble, "puff": puff, "arc": arc, "streak": streak,
    "bolt1": lambda: bolt(11), "bolt2": lambda: bolt(22), "bolt3": lambda: bolt(33),
    "voidcore": voidcore, "ring": ring, "drop": drop, "shard": shard,
}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    imgs = {}
    for name, fn in SPRITES.items():
        im = fn()
        im.save(OUT / f"{name}.tga")
        imgs[name] = im
    # planche d'aperçu, x3, sur fond sombre
    cols, cell = 8, S * 3 + 8
    rows = math.ceil(len(imgs) / cols)
    sheet = Image.new("RGBA", (cols * cell, rows * cell), (18, 21, 26, 255))
    for i, im in enumerate(imgs.values()):
        big = im.resize((S * 3, S * 3), Image.NEAREST)
        sheet.alpha_composite(big, ((i % cols) * cell + 4, (i // cols) * cell + 4))
    sheet.save(PREVIEW)
    print(f"{len(imgs)} sprites -> {OUT}")


if __name__ == "__main__":
    main()
