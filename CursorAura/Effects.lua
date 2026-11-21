-- Cursor Aura © 2026 Ghosti. All Rights Reserved.
-- ============================================================
--  Cursor Aura — Effects.lua
--  Les 17 effets, en données. Unités : px (échelle UI 1), secondes,
--  y vers le haut. Valeurs tirées de la maquette validée (elements-v2).
-- ============================================================

local CA = CursorAura

local hex = CA.hex
local function cols(a, b, c) return { { hex(a) }, { hex(b) }, { hex(c) } } end

CA.Effects = { defs = {
    feu = { colors = cols("#FFE08A", "#FF9A2E", "#E8401C"), sprite = "flame", blend = "ADD",
        rate = 140, life = 0.55, size = { 6, 12 }, sizeGrow = -10, alpha = .9,
        spawn = "ring", ring = { 4, 14 }, vel = { -12, 12, 36, 72 } },
    givre = { colors = cols("#FFFFFF", "#AEE6FF", "#3FA9F5"), sprite = "flake", blend = "ADD",
        rate = 48, life = 0.93, size = { 6, 10 }, sizeGrow = 0, alpha = .9,
        spawn = "ring", ring = { 12, 22 }, vel = { -6, 6, -15, -15 }, rotSpeed = 2.4 },
    arcanes = { colors = cols("#FFD6FF", "#C77DFF", "#7B2CBF"), sprite = "soft", blend = "ADD",
        rate = 96, life = 0.67, size = { 3, 7 }, sizeGrow = 0, alpha = .9,
        spawn = "orbit", ring = { 14, 20 }, spin = 3.6, grow = 0 },
    eclairs = { colors = cols("#FFFFFF", "#5AB8FF", "#2F7FFF"), blend = "ADD", rate = 0,
        extras = { bolts = { every = 0.05, rFrom = 5, rTo = { 16, 26 }, spread = 0.8,
                             white = .3, haloColor = "#2F7FFF", haloAlpha = { .35, .55 } } } },
    eau = { colors = cols("#7FE7FF", "#4FD39A", "#2FB8C8"), sprite = "bubble", blend = "ADD",
        rate = 48, life = 1.11, size = { 3, 8 }, sizeGrow = 0, alpha = .85,
        spawn = "ring", ring = { 10, 22 }, vel = { -9, 9, 15, 33 },
        extras = { wave = { every = 0.75, speed = 36, life = 0.83, color = "#5FE3D0", alpha = .6 } } },
    vent = { colors = cols("#DDF3FF", "#7FC8FF", "#FFD36A"), weights = { .46, .46, .08 },
        sprite = "arc", blend = "ADD", rate = 140, life = 0.48, sizeGrow = 0, alpha = .8,
        spawn = "orbit", ring = { 10, 24 }, spin = 10.8, grow = 9, arcSize = true },
    nature = { colors = cols("#C8F57A", "#5DBB3A", "#2E7D32"), sprite = "leaf", blend = "ADD",
        rate = 48, life = 1.39, size = { 6, 10 }, sizeGrow = 0, alpha = .85,
        spawn = "orbit", ring = { 10, 20 }, spin = 1.8, grow = 3, rotSpeed = 3 },
    lumiere = { colors = cols("#FFFFFF", "#FFE27A", "#F2B705"), sprite = "star", blend = "ADD",
        rate = 48, life = 0.55, size = { 4, 12 }, sizeGrow = 0, alpha = .9,
        spawn = "ring", ring = { 6, 20 }, vel = { 0, 0, 12, 12 } },
    ombre = { colors = cols("#B58CFF", "#5A1FA8", "#2A0850"), sprite = "streak", blend = "ADD",
        rate = 96, life = 0.83, size = { 4, 4 }, sizeGrow = 0, alpha = .9,
        spawn = "orbit", ring = { 24, 32 }, spin = 4.2, grow = -27, minRadius = 3, streak = true,
        extras = {
            darkPuff = { chance = .5, ring = { 6, 16 }, vy = 9, life = 1.39, size = { 10, 20 },
                         sizeGrow = 4.8, color = "#0A0012", alpha = .55, blend = "BLEND" },
            core = { size = 32, ring = 14, ringColor = "#7A2CFF", pulse = 4 },
        } },
    fumee = { colors = cols("#C9CDD4", "#8A9099", "#4A4F57"), sprite = "puff", blend = "BLEND",
        rate = 96, life = 1.67, size = { 8, 18 }, sizeGrow = 7, alpha = .28,
        spawn = "ring", ring = { 4, 16 }, vel = { -10, 10, 9, 21 } },
    gangrene = { colors = cols("#E6FF9A", "#7CFF2E", "#2E8B00"), sprite = "flame", blend = "ADD",
        rate = 140, life = 0.48, size = { 5, 11 }, sizeGrow = -10, alpha = .9,
        spawn = "ring", ring = { 4, 14 }, vel = { -15, 15, 48, 84 } },
    sang = { colors = cols("#FF2A2A", "#B00000", "#5A0000"), sprite = "drop", blend = "BLEND",
        rate = 60, life = 0.9, size = { 5, 9 }, sizeGrow = 0, alpha = .95,
        spawn = "ring", ring = { 4, 16 }, vel = { -4, 4, -54, -26 },
        extras = {
            darkPuff = { chance = .35, ring = { 2, 12 }, vy = -6, life = 1.1, size = { 8, 16 },
                         sizeGrow = 3, color = "#3A0000", alpha = .6, blend = "BLEND" },
            splatter = { every = 0.4, n = 5, speed = { 40, 90 }, gravity = -220, life = 0.55,
                         size = { 3, 6 }, color = "#C00000", alpha = .95 },
        } },
    terre = { colors = cols("#E8C99A", "#A9763D", "#5C3A1A"), sprite = "rock", blend = "ADD",
        rate = 48, life = 1.11, size = { 4, 10 }, sizeGrow = 0, alpha = .85,
        spawn = "orbit", ring = { 10, 22 }, spin = 3, grow = 0, rotSpeed = 1.8 },
    protection = { colors = cols("#FFFFFF", "#8FD0FF", "#2F7FFF"), sprite = "star", blend = "ADD",
        rate = 48, life = 0.7, size = { 4, 11 }, sizeGrow = 0, alpha = .9,
        spawn = "orbit", ring = { 14, 22 }, spin = 2.4, grow = 0,
        extras = { shield = { size = 46, color = "#2F7FFF", pulse = 4 } } },
    vindicte = { colors = cols("#FFE0A0", "#FF4A2A", "#B00000"), sprite = "star", blend = "ADD",
        rate = 72, life = 0.6, size = { 4, 11 }, sizeGrow = 0, alpha = .9,
        spawn = "ring", ring = { 6, 18 }, vel = { -10, 10, 30, 60 } },
    -- 0.0.10, banquier (aperçus validés) : tout est dessiné par Bank.lua, selon l'or porté
    ["or"] = { colors = cols("#FFF4B8", "#FFD34A", "#B8860B"), blend = "BLEND", rate = 0, bank = "or" },
    bourse = { colors = cols("#FFF4B8", "#FFD34A", "#B8860B"), blend = "BLEND", rate = 0, bank = "bourse" },
} }

-- Effets secondaires 0.0.7 (aperçu v2 validé par Ghosti) : particules qui se détachent de l'aura.
local FALL = {
    feu = { fall = { rate = 7, sprite = "soft", size = { 4, 6 }, life = 1.3, vel = { -14, 14, 45, 90 }, trail = true, burst = { n = 5, speed = 45 } } },
    givre = { fall = { rate = 4, sprite = "flake", size = { 9, 13 }, life = 1.6, vel = { -6, 6, -36, -20 }, sway = 26, twinkle = true, trail = true } },
    arcanes = { fall = { rate = 5, sprite = "star", size = { 7, 10 }, life = 1.3, spiral = { spin = 3.5, grow = 38 }, trail = true } },
    eclairs = { fall = { rate = 9, sprite = "streak", size = { 6, 6 }, life = 0.8, speed = 130, gravity = -220, trail = true } },
    eau = { fall = { rate = 4, sprite = "drop", size = { 8, 11 }, life = 1.5, vel = { -6, 6, -20, -10 }, gravity = -170, splash = { depth = 60, n = 6 }, trail = true } },
    vent = { fall = { rate = 6, sprite = "streak", size = { 6, 6 }, life = 1.0, horiz = { 140, 200 }, trail = true } },
    nature = { fall = { rate = 4, sprite = "leaf", size = { 10, 14 }, life = 1.7, vel = { -6, 6, -40, -24 }, sway = 26, trail = true } },
    lumiere = { fall = { rate = 4, sprite = "star", size = { 8, 12 }, life = 1.3, speed = 95, trail = true } },
    ombre = { fall = { rate = 6, sprite = "soft", size = { 4, 6 }, life = 1.3, speed = 55, wig = 45, trail = true } },
    fumee = { fall = { rate = 5, sprite = "puff", size = { 16, 22 }, sizeGrow = 8, life = 1.8, vel = { -5, 5, 30, 46 }, sway = 20, alpha = .3 } },
    gangrene = { fall = { rate = 5, sprite = "drop", size = { 7, 10 }, life = 1.3, vel = { -3, 3, -12, -4 }, gravity = -130, trail = true, smoke = { every = 0.12, color = "#2E8B00" } } },
    terre = { fall = { rate = 4, sprite = "rock", size = { 7, 10 }, life = 1.4, vel = { -35, 35, 24, 48 }, gravity = -280, bounce = 50, rotSpeed = 4 } },
    protection = { fall = { rate = 5, sprite = "shard", size = { 8, 11 }, life = 1.3, speed = 75, gravity = -60, trail = true } },
    vindicte = { fall = { rate = 9, sprite = "soft", size = { 4, 6 }, life = 1.2, vel = { -35, 35, 60, 120 }, gravity = -140, trail = true } },
}
for k, x in pairs(FALL) do
    local d = CA.Effects.defs[k]
    d.extras = d.extras or {}
    d.extras.fall = x.fall
end

-- Intensité 0.0.6 (validée par Ghosti) : +70 % de particules, plus grosses et plus vives.
CA.INTENSITY = 1.7
for _, d in pairs(CA.Effects.defs) do
    if d.rate then d.rate = d.rate * CA.INTENSITY end
    if d.size then d.size = { d.size[1] * 1.3, d.size[2] * 1.3 } end
    if d.alpha then d.alpha = math.min(1, d.alpha * 1.1) end
end
local bolts = CA.Effects.defs.eclairs.extras.bolts
bolts.every, bolts.haloAlpha = 0.035, { .45, .7 }

function CA.Effects:Name(key) return CA.L["fx_" .. key] end
