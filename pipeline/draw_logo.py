# Cursor Aura — logo CurseForge 400x400 (PNG).
# Fond sombre, flèche de curseur blanche, couronne de particules
# aux couleurs de plusieurs éléments. Sortie : build/logo.png
import math, random, os
from PIL import Image, ImageDraw, ImageFilter

S = 400
OUT = os.path.join(os.path.dirname(__file__), "..", "build", "logo.png")
random.seed(7)

# fond : dégradé radial bleu nuit -> noir
bg = Image.new("RGB", (S, S))
px = bg.load()
for y in range(S):
    for x in range(S):
        d = math.hypot(x - S / 2, y - S / 2) / (S * .72)
        k = max(0, 1 - d)
        px[x, y] = (int(8 + 22 * k), int(10 + 18 * k), int(18 + 40 * k))

# couronne : 6 secteurs d'éléments (feu, givre, arcanes, éclairs, nature, ombre)
ELEMS = [((255, 120, 30), (255, 210, 80)), ((90, 200, 255), (220, 245, 255)),
         ((190, 90, 255), (255, 150, 255)), ((70, 150, 255), (255, 255, 255)),
         ((80, 220, 90), (200, 255, 120)), ((122, 44, 255), (40, 0, 70))]
glow = Image.new("RGB", (S, S))
g = ImageDraw.Draw(glow)
cx, cy = S / 2, S / 2
for i in range(900):
    a = random.random() * 2 * math.pi
    sector = int((a / (2 * math.pi)) * len(ELEMS)) % len(ELEMS)
    c1, c2 = ELEMS[sector]
    t = random.random()
    col = tuple(int(c1[j] + (c2[j] - c1[j]) * t) for j in range(3))
    r = random.gauss(118, 22)
    x, y = cx + math.cos(a) * r, cy + math.sin(a) * r
    s = random.uniform(1.5, 6)
    g.ellipse([x - s, y - s, x + s, y + s], fill=col)
soft = glow.filter(ImageFilter.GaussianBlur(10))
sharp = glow.filter(ImageFilter.GaussianBlur(1.2))
img = Image.blend(bg, bg, 0)
from PIL import ImageChops
img = ImageChops.add(img, soft)
img = ImageChops.add(img, ImageChops.multiply(sharp, Image.new("RGB", (S, S), (200, 200, 200))))

# halo central
halo = Image.new("RGB", (S, S))
ImageDraw.Draw(halo).ellipse([cx - 70, cy - 70, cx + 70, cy + 70], fill=(70, 60, 120))
img = ImageChops.add(img, halo.filter(ImageFilter.GaussianBlur(35)))

# flèche de curseur (pointe en haut à gauche, centrée visuellement)
arrow = [(0, 0), (0, 150), (38, 114), (64, 172), (90, 160), (64, 104), (114, 104)]
ox, oy = cx - 44, cy - 84
pts = [(ox + x, oy + y) for x, y in arrow]
shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ImageDraw.Draw(shadow).polygon([(x + 6, y + 8) for x, y in pts], fill=(0, 0, 0, 170))
img = Image.alpha_composite(img.convert("RGBA"), shadow.filter(ImageFilter.GaussianBlur(6)))
d = ImageDraw.Draw(img)
d.polygon(pts, fill=(250, 250, 255), outline=(20, 20, 30))
d.line(pts + [pts[0]], fill=(20, 20, 30), width=6, joint="curve")

os.makedirs(os.path.dirname(OUT), exist_ok=True)
img.convert("RGB").save(OUT)
print("ok", OUT)
