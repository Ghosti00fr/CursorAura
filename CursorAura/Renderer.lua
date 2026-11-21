-- Cursor Aura © 2026 Ghosti. All Rights Reserved.
-- ============================================================
--  Cursor Aura — Renderer.lua
--  Frame plein écran (jamais de souris), pool de textures, suivi
--  du curseur à chaque image, extras (éclairs, onde, cœur d'ombre).
-- ============================================================

local CA = CursorAura

local CAP = 260                   -- 0.0.7 : effets secondaires (traînées, éclats)
local ARC_RADIUS_PX = 30          -- rayon de l'arc dans arc.tga (64 px)
local HALO, DOT = 18, 7
local cos, sin, atan2, random = math.cos, math.sin, math.atan2, math.random

CA.Renderer = { pool = {}, bolts = {} }
local R = CA.Renderer

local function place(tex, x, y, w, h)
    tex:ClearAllPoints()
    tex:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    tex:SetSize(w, h or w)
end

function R:Init()
    if self.frame then return end
    local f = CreateFrame("Frame", "CursorAuraFrame", UIParent)
    f:SetFrameStrata("TOOLTIP")
    f:EnableMouse(false)
    f:SetAllPoints(UIParent)
    self.frame = f
    local function tex(sprite, blend)
        local t = f:CreateTexture(nil, "OVERLAY")
        if sprite then t:SetTexture(CA.TEX .. sprite) end
        t:SetBlendMode(blend or "ADD")
        t:Hide()
        return t
    end
    for i = 1, CAP do self.pool[i] = tex() end
    for i = 1, 4 do
        local l = f:CreateLine(nil, "OVERLAY")
        l:SetBlendMode("ADD"); l:SetThickness(10); l:Hide()
        self.bolts[i] = l
    end
    self.halo, self.dot = tex("soft"), tex("soft", "BLEND")
    self.wave = tex("ring")
    self.core, self.coreRing = tex("voidcore", "BLEND"), tex("ring")
    self.sys = CA.Particles.New(CAP)
    self.shownCount, self.boltTimer, self.waveTimer, self.waveAge = 0, 0, 0, nil

    f:RegisterEvent("PLAYER_LOGIN")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
    f:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
    f:RegisterEvent("TRAIT_CONFIG_UPDATED")      -- talents appliqués (Forever : spé = onglet)
    f:RegisterEvent("PLAYER_TALENT_UPDATE")
    f:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_SPECIALIZATION_CHANGED" and unit ~= "player" then return end
        if event == "PLAYER_LOGIN" then
            CA.Config:Init()
            print("|cff66ccffCursor Aura|r " .. CA.L.loaded)
        end
        R:Refresh()
    end)
    f:SetScript("OnUpdate", function(_, dt) R:OnUpdate(dt) end)
end

function R:HideAll()
    for i = 1, self.shownCount do self.pool[i]:Hide() end
    self.shownCount = 0
    for i = 1, 4 do self.bolts[i]:Hide() end
    self.halo:Hide(); self.dot:Hide(); self.wave:Hide(); self.core:Hide(); self.coreRing:Hide()
    self.waveAge = nil
    if CA.PvP then CA.PvP:Hide() end
    if CA.Crest then CA.Crest:Hide() end
    if CA.Bank then CA.Bank:Hide() end
end

function R:Refresh()
    if not CA.Config.db then return end
    local key, mode = CA.Specs:Resolve(), CA.Config:Get("mode")
    if key ~= self.current or mode ~= self.mode then
        self.sys:Clear()
        self:HideAll()
    end
    self.current, self.mode, self.def = key, mode, CA.Effects.defs[key]
end

-- ---- extras ----------------------------------------------------
local function drawBolts(self, b, cx, cy, dt)
    self.boltTimer = self.boltTimer - dt
    if self.boltTimer > 0 then return end
    self.boltTimer = b.every
    local n = random() < .7 and 2 or 4
    local wr, wg, wb = 1, 1, 1
    local br, bg, bb = CA.hex("#5AB8FF")
    for i = 1, 4 do
        local t = self.bolts[i]
        if i > n then t:Hide() else
            local a = random() * 6.283
            local a2 = a + (random() * 2 - 1) * b.spread
            local r2 = b.rTo[1] + random() * (b.rTo[2] - b.rTo[1])
            local x1, y1 = cx + cos(a) * b.rFrom, cy + sin(a) * b.rFrom
            local x2, y2 = cx + cos(a2) * r2, cy + sin(a2) * r2
            t:SetTexture(CA.TEX .. "bolt" .. random(1, 3))
            t:SetStartPoint("BOTTOMLEFT", UIParent, x1, y1)
            t:SetEndPoint("BOTTOMLEFT", UIParent, x2, y2)
            if random() < b.white then t:SetVertexColor(wr, wg, wb, .6 + random() * .4)
            else t:SetVertexColor(br, bg, bb, .6 + random() * .4) end
            t:Show()
        end
    end
    local hr, hg, hb = CA.hex(b.haloColor)
    self.halo:SetVertexColor(hr, hg, hb, b.haloAlpha[1] + random() * (b.haloAlpha[2] - b.haloAlpha[1]))
end

local function drawWave(self, w, cx, cy, dt)
    self.waveTimer = self.waveTimer + dt
    if self.waveTimer >= w.every then self.waveTimer, self.waveAge = 0, 0 end
    if not self.waveAge then return end
    self.waveAge = self.waveAge + dt
    if self.waveAge >= w.life then self.waveAge = nil; self.wave:Hide(); return end
    local radius = 4 + w.speed * self.waveAge
    local r, g, b = CA.hex(w.color)
    place(self.wave, cx, cy, radius * 2 * 32 / 28)       -- ring.tga : rayon 28 px sur 64
    self.wave:SetVertexColor(r, g, b, w.alpha * (1 - self.waveAge / w.life))
    self.wave:Show()
end

-- ---- image par image ---------------------------------------------
function R:OnUpdate(dt)
    if not CA.Config.db then return end
    if not self.def then self:Refresh() end
    if IsMouselooking and IsMouselooking() then
        self.sys:Clear(); self:HideAll(); self.px = nil
        return
    end
    local def, mode = self.def, self.mode
    local scale = UIParent:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    cx, cy = cx / scale, cy / scale
    local px, py = self.px or cx, self.py or cy
    self.px, self.py = cx, cy

    local sys = self.sys
    sys:Emit(def, mode, cx, cy, px, py, dt * (CA.PvP and CA.PvP:Boost() or 1))   -- palier PvP : aura renforcée
    sys:Step(dt, cx, cy)

    for i = 1, sys.count do
        local p, t = sys.list[i], self.pool[i]
        if t.spr ~= p.sprite then t:SetTexture(CA.TEX .. p.sprite); t.spr = p.sprite end
        if t.bm ~= p.blend then t:SetBlendMode(p.blend); t.bm = p.blend end
        local gc = CA.PvP and CA.PvP:Gold(p)                        -- palier PvP 100 : tout en or
        if gc then t:SetVertexColor(gc[1], gc[2], gc[3], p.alpha * p.life * (p.tw or 1))
        else t:SetVertexColor(p.r, p.g, p.b, p.alpha * p.life * (p.tw or 1)) end
        if p.sprite == "arc" and p.orbit then
            place(t, cx, cy, p.rad * 64 / ARC_RADIUS_PX)
            t:SetRotation(p.ang)
        elseif p.sprite == "streak" then
            place(t, p.x, p.y, 12)
            t:SetRotation(atan2(p.y - p.oy, p.x - p.ox))
        elseif p.coin then                                  -- pièce : largeur selon la rotation
            place(t, p.x, p.y, p.size * math.max(.18, math.abs(cos(p.ph))), p.size)
            t:SetRotation(0)
        else
            place(t, p.x, p.y, p.size)
            t:SetRotation((p.rotSpeed ~= 0 or (p.fall and p.fall.sway)) and p.rot or 0)
        end
        t:Show()
    end
    for i = sys.count + 1, self.shownCount do self.pool[i]:Hide() end
    self.shownCount = sys.count

    -- centre : halo + point, ou cœur noir + anneau pulsé pour l'ombre
    local ex = def.extras or {}
    local c2 = def.colors[2]
    if ex.core then
        self.halo:Hide(); self.dot:Hide()
        place(self.core, cx, cy, ex.core.size); self.core:SetVertexColor(0, 0, 0, 1); self.core:Show()
        local rr, rg, rb = CA.hex(ex.core.ringColor)
        self.pulse = (self.pulse or 0) + dt * ex.core.pulse
        place(self.coreRing, cx, cy, ex.core.ring)
        self.coreRing:SetVertexColor(rr, rg, rb, .5 + sin(self.pulse) * .3); self.coreRing:Show()
    else
        self.core:Hide()
        if ex.shield then        -- protection : anneau bleu pulsé, façon bouclier
            local sr, sg, sb = CA.hex(ex.shield.color)
            self.pulse = (self.pulse or 0) + dt * ex.shield.pulse
            place(self.coreRing, cx, cy, ex.shield.size)
            self.coreRing:SetVertexColor(sr, sg, sb, .55 + sin(self.pulse) * .3); self.coreRing:Show()
        else self.coreRing:Hide() end
        place(self.halo, cx, cy, HALO); self.halo:SetVertexColor(c2[1], c2[2], c2[3], .3); self.halo:Show()
        place(self.dot, cx, cy, DOT); self.dot:SetVertexColor(c2[1], c2[2], c2[3], 1); self.dot:Show()
    end

    if ex.bolts and mode ~= "seul" then drawBolts(self, ex.bolts, cx, cy, dt)
    else for i = 1, 4 do self.bolts[i]:Hide() end end
    if ex.wave and mode ~= "seul" then drawWave(self, ex.wave, cx, cy, dt)
    else self.wave:Hide(); self.waveAge = nil end
    if CA.PvP then CA.PvP:Draw(self.frame, sys, cx, cy, dt) end
    if CA.Crest then CA.Crest:Draw(self.frame, sys, cx, cy, dt) end
    if CA.Bank then CA.Bank:Draw(self.frame, sys, def, mode, cx, cy, dt) end
end

R:Init()
