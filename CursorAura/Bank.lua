-- Cursor Aura © 2026 Ghosti. All Rights Reserved.
-- ============================================================
--  Cursor Aura — Bank.lua
--  Curseurs « banquier » (choix manuels, jamais en Auto) qui grossissent
--  avec l'or porté (échelle log : 1 po -> 1 000 000 po) :
--   - Or : aura de pièces + cascade qui rebondit sur 2 marches ;
--   - Bourse : bourse en cuir qui se remplit, déborde, s'écrase.
--  Paliers : 100, 1 000, 10 000, 100 000, 1 000 000 po.
-- ============================================================

local CA = CursorAura
local cos, sin, random, abs, max, min, floor, sqrt =
      math.cos, math.sin, math.random, math.abs, math.max, math.min, math.floor, math.sqrt

CA.Bank = { heap = {}, crown = {}, TIERS = { 100, 1000, 10000, 100000, 1000000 } }
local B = CA.Bank
local TEX = CA.TEX .. "bank\\"

local function col(s) return { CA.hex(s) } end
local CU, AG, AU = col("#E39A5B"), col("#E3E7EC"), col("#FFD34A")
local GEMS = { col("#FF2D55"), col("#2EE07A"), col("#3F8CFF") }
local RUBY, SPARK, DARK = col("#FF2D55"), col("#FFF6C8"), col("#1E1006")
local CORD, CORD_GOLD = col("#D9B47A"), col("#FFE27A")

-- géométrie de la bourse dans son repère (200 unités, y vers le bas) : voir draw_bank.py
local BW, BH = 50, 56
local NECK, MOUTH_Y = .42 * 50, -.7 * 56

function B:Gold() return floor((GetMoney and GetMoney() or 0) / 10000) end
function B:Level() return min(1, math.log10(self:Gold() + 1) / 6) end
function B:Tier()
    local g, t = self:Gold(), 0
    for i, v in ipairs(self.TIERS) do if g >= v then t = i end end
    return t
end

local function pick(tier, k)
    if tier == 0 then return k < .6 and CU or AG end
    if tier == 1 then return k < .5 and AU or (k < .8 and AG or CU) end
    return k < .85 and AU or AG
end

local function coinP(x, y, size, c, extra)
    local p = { x = x, y = y, ox = x, oy = y, life = 1, decay = 1, size = size, sizeGrow = 0,
                r = c[1], g = c[2], b = c[3], alpha = 1, sprite = "bank\\coin", blend = "BLEND",
                rot = 0, rotSpeed = 0, vx = 0, vy = 0, coin = true, ph = random() * 6, ps = 4 + random() * 4 }
    for k, v in pairs(extra) do p[k] = v end
    return p
end

local function sparkle(sys, x, y)
    sys:Add({ x = x, y = y, ox = x, oy = y, life = 1, decay = 1 / .3, size = 9, sizeGrow = 0,
              r = SPARK[1], g = SPARK[2], b = SPARK[3], alpha = 1, sprite = "star", blend = "ADD",
              rot = 0, rotSpeed = 0, vx = 0, vy = 0 })
end

function B:Build(frame)
    if self.body then return end
    local function tex(sub, file, blend)
        local t = frame:CreateTexture(nil, "OVERLAY", nil, sub)
        if file then t:SetTexture(file) end
        t:SetBlendMode(blend or "BLEND"); t:Hide()
        return t
    end
    self.glow = tex(-8, CA.TEX .. "soft", "ADD")
    self.soft = tex(-8, CA.TEX .. "soft", "ADD")
    for i = 1, 12 do self.crown[i] = tex(-7, TEX .. "coin") end
    self.shadow = tex(-7, TEX .. "ellipse")
    self.body, self.medal, self.gem = tex(-6), tex(-5, TEX .. "purse_medal"), tex(-4, TEX .. "gemcut")
    self.mouth = tex(-4, TEX .. "ellipse")
    for i = 1, 46 do
        self.heap[i] = tex(-3, TEX .. "coin")
        self.heap[i].x, self.heap[i].y, self.heap[i].k, self.heap[i].ph, self.heap[i].gm =
            random() * 2 - 1, (i - 1) / 45, random(), random() * 6, random(1, 3)
    end
    self.collar, self.cord = tex(-2), tex(-1, TEX .. "purse_cord")
    self.t, self.acc, self.cacc, self.facc, self.sacc, self.squash, self.squashMax = 0, 0, 0, 0, 0, 0, 0
end

function B:Hide()
    if not self.body then return end
    for _, k in ipairs({ "glow", "soft", "shadow", "body", "medal", "gem", "mouth", "collar", "cord" }) do self[k]:Hide() end
    for i = 1, 12 do self.crown[i]:Hide() end
    for i = 1, 46 do self.heap[i]:Hide() end
end

function B:HeapShown()
    local n = 0
    for i = 1, 46 do if self.heap[i]:IsShown() then n = n + 1 end end
    return n
end

local function put(t, x, y, w, h, c, a, rot)
    t:ClearAllPoints()
    t:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    t:SetSize(w, h or w)
    t:SetRotation(rot or 0)
    if c then t:SetVertexColor(c[1], c[2], c[3], a or 1) end
    t:Show()
end
local function file(t, f) if t.file ~= f then t:SetTexture(f); t.file = f end end

-- ---- Or : aura de pièces + cascade ---------------------------------
function B:DrawOr(sys, cx, cy, dt, lv, tier)
    local sc = 1 + lv * 1.5
    local rad, s2 = 16 * sc, sqrt(sc)
    self.acc = self.acc + dt * (10 + lv * 40)
    while self.acc >= 1 do
        self.acc = self.acc - 1
        sys:Add(coinP(cx, cy, (6 + random() * 4) * s2, pick(tier, random()), {
            orbit = true, ang = random() * 6.283, rad = rad * (.7 + random() * .6), grow = 0,
            spin = (1.2 + random()) * (random() < .5 and 1 or -1), decay = 1 / (1.2 + random()) }))
    end
    self.cacc = self.cacc + dt * (4 + lv * 36)
    while self.cacc >= 1 do
        self.cacc = self.cacc - 1
        local x = cx + (random() - .5) * rad * .8
        local p = coinP(x, cy - rad * .6, (6 + random() * 3) * s2, pick(tier, random()), {
            vx = (random() - .5) * (15 + lv * 30), vy = -(20 + random() * 30), gravity = -420,
            decay = 1 / 1.6, bn = 0, floors = { cy - 55 - lv * 15, cy - 115 - lv * 30 }, cascade = true,
            ps = 8 + random() * 8 })
        if tier >= 4 and random() < .12 then
            local c = GEMS[random(1, 3)]
            p.sprite, p.coin, p.r, p.g, p.b = "bank\\gemcut", nil, c[1], c[2], c[3]
        end
        sys:Add(p)
    end
    if tier >= 4 and random() < dt * 8 then                    -- gemmes en orbite
        local c = GEMS[random(1, 3)]
        sys:Add({ x = cx, y = cy, ox = cx, oy = cy, life = 1, decay = 1 / .7, size = 8, sizeGrow = 0,
                  r = c[1], g = c[2], b = c[3], alpha = 1, sprite = "bank\\gemcut", blend = "BLEND",
                  rot = 0, rotSpeed = 0, vx = 0, vy = 0, orbit = true, ang = random() * 6.283,
                  rad = rad * 1.3, spin = .8, grow = 0 })
    end
    if tier >= 2 and random() < dt * (10 + lv * 20) then
        local a, r = random() * 6.283, random() * rad * 1.2
        sparkle(sys, cx + cos(a) * r, cy + sin(a) * r)
    end
    put(self.soft, cx, cy, rad * 2.6, nil, AU, .15 + lv * .25)
    if tier >= 5 then
        put(self.glow, cx, cy, rad * 6, nil, AU, .22)
        for i = 1, 12 do
            local a = self.t * .8 + i * .5236
            put(self.crown[i], cx + cos(a) * rad * 2, cy + sin(a) * rad * 2, 10 * max(.18, abs(cos(self.t * 3 + i))), 10, AU)
        end
    else
        self.glow:Hide()
        for i = 1, 12 do self.crown[i]:Hide() end
    end
end

-- ---- Bourse --------------------------------------------------------
function B:DrawBourse(sys, cx, cy, dt, lv, tier)
    local sc = 1 + lv * 1.5
    local F = 70 * sc                              -- px pour 200 unités
    local u = F / 200
    local wide = 1 + .3 * lv
    local bx, by = cx + 20 + BW * u * wide, cy - 20 - BH * u
    self.squash = max(0, self.squash - dt * 4)
    local sq = sin(self.squash * 9) * self.squash * .08
    local rot = sin(self.t * 2.1) * .05
    local W, H = F * wide * (1 + sq), F * (1 - sq)
    local lux = tier >= 5
    local cr, sr = cos(rot), sin(rot)
    local function at(x, y)                         -- repère de la bourse -> écran (y vers le haut)
        x, y = x * u * wide, -y * u
        return bx + x * cr - y * sr, by + x * sr + y * cr
    end

    if lux then put(self.glow, bx, by, BW * u * 5.6, nil, AU, .22 + .06 * sin(self.t * 3)) else self.glow:Hide() end
    put(self.shadow, bx, by - BH * 1.05 * u, BW * 2.6 * u * wide, BH * .44 * u, { 0, 0, 0 }, .55)
    file(self.body, TEX .. (lux and "purse_body_lux" or "purse_body"))
    put(self.body, bx, by, W, H, { 1, 1, 1 }, 1, rot)
    put(self.medal, bx, by, W, H, tier >= 4 and AU or (tier >= 2 and AG or CU), 1, rot)
    if lux then
        local gx, gy = at(0, BH * .32)
        put(self.gem, gx, gy, BW * .26 * u * 2, nil, RUBY, 1, rot)
    else self.gem:Hide() end

    local fill = min(1, .12 + lv * 1.1)
    local mw = NECK * 2 + lv * BW * .9
    local mx, my = at(0, MOUTH_Y)
    put(self.mouth, mx, my, mw * 1.2 * u * wide, BH * .3 * u, DARK, 1, rot)
    local n = floor(5 + fill * 40 + .5)
    for i = 1, 46 do
        local c, t = self.heap[i], self.heap[i]
        if i <= n then
            local hx = c.x * mw * .52 * (1 - c.y * .55)
            local hy = MOUTH_Y - c.y * BH * (.1 + fill * .6)
            local x, y = at(hx, hy)
            local sz = 16 * u
            if tier >= 4 and c.k > .9 then
                file(t, TEX .. "gemcut"); put(t, x, y, sz, nil, GEMS[c.gm], 1, rot)
            else
                file(t, TEX .. "coin")
                local w = c.k > .85 and max(.18, abs(cos(c.ph + self.t * 2.5))) or 1
                put(t, x, y, sz * w, sz, pick(tier, c.k), 1, rot)
            end
        else t:Hide() end
    end
    file(self.collar, TEX .. (lux and "purse_collar_lux" or "purse_collar"))
    put(self.collar, bx, by, W, H, { 1, 1, 1 }, 1, rot)
    put(self.cord, bx, by, W, H, tier >= 4 and CORD_GOLD or CORD, 1, rot)

    -- pièces qui tombent dans la bourse
    self.facc = self.facc + dt * (1 + lv * 5)
    while self.facc >= 1 do
        self.facc = self.facc - 1
        local x0 = bx + (random() - .5) * BW * u * 3
        local tx = mx + (random() - .5) * mw * .4 * u
        sys:Add(coinP(x0, by + BH * 3.2 * u, 7 * sqrt(sc), pick(tier, random()), {
            vx = (tx - x0) / .55, vy = 40, gravity = -420, decay = 1 / 1.2, into = my, ps = 10 }))
    end
    for i = 1, sys.count do
        local p = sys.list[i]
        if p.into and p.y < p.into and p.vy < 0 and p.life > 0 then
            p.life, p.decay = 0, 1e9
            self.squash = min(1, self.squash + .35)
            self.squashMax = max(self.squashMax, self.squash)
        end
    end
    if tier >= 3 then                                           -- débordement
        self.sacc = self.sacc + dt * (2 + lv * 10)
        while self.sacc >= 1 do
            self.sacc = self.sacc - 1
            sys:Add(coinP(mx + (random() - .5) * mw * .5 * u, my, 7 * sqrt(sc), pick(tier, random()), {
                vx = (random() < .5 and -1 or 1) * (30 + random() * 40), vy = 60 + random() * 50,
                gravity = -420, decay = 1 / 1.5, bn = 0, floors = { by - BH * 1.02 * u }, spill = true, ps = 8 + random() * 8 }))
        end
    end
    if tier >= 2 and random() < dt * (6 + lv * 16) then
        local a, r = random() * 6.283, random() * BW * u * 1.1
        sparkle(sys, bx + cos(a) * r, by + sin(a) * r * .8)
    end
    self.soft:Hide()
    for i = 1, 12 do self.crown[i]:Hide() end
end

function B:Draw(frame, sys, def, mode, cx, cy, dt)
    self:Build(frame)
    if not def.bank or mode == "seul" then self:Hide(); return end
    self.t = self.t + dt
    local lv, tier = self:Level(), self:Tier()
    if def.bank == "or" then
        for _, k in ipairs({ "shadow", "body", "medal", "gem", "mouth", "collar", "cord" }) do self[k]:Hide() end
        for i = 1, 46 do self.heap[i]:Hide() end
        self:DrawOr(sys, cx, cy, dt, lv, tier)
    else
        self:DrawBourse(sys, cx, cy, dt, lv, tier)
    end
end
