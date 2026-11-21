-- Cursor Aura © 2026 Ghosti. All Rights Reserved.
-- ============================================================
--  Cursor Aura — PvP.lua
--  Curseur PvP évolutif : chaque victoire honorable (joueur du camp
--  adverse) allonge la série, la mort la remet à zéro. Paliers 3, 5,
--  10, 20, 50 et 100, cumulés par-dessus l'effet de la classe.
-- ============================================================

local CA = CursorAura
local L = CA.L
local cos, sin, random, max = math.cos, math.sin, math.random, math.max

CA.PvP = { TIERS = { 3, 5, 10, 20, 50, 100 }, shards = {}, bolts = {} }
local P = CA.PvP

local RED, GOLD = { 1, .19, .19 }, { 1, .83, .29 }
local GOLDS = { { 1, 1, 1 }, { 1, .89, .48 }, { .95, .72, .02 } }
local POPUP_LIFE = 1.6

function P:Tier(n)
    local t = 0
    for i, v in ipairs(self.TIERS) do if n >= v then t = i end end
    return t
end

function P:Streak() return CA.Config.db and CA.Config.db.streak or 0 end

function P:SetStreak(n)
    if CA.Config.db then CA.Config.db.streak = n end
end

function P:AddKills(k)
    local before = self:Tier(self:Streak())
    self:SetStreak(self:Streak() + k)
    local after = self:Tier(self:Streak())
    if after > before then
        self.popup = { n = self.TIERS[after], age = 0, text = L.streak_up:format(self.TIERS[after]) }
        self.burst = after
    end
end

local function sessionKills()
    if not GetPVPSessionStats then return nil end
    return (GetPVPSessionStats()) or 0
end

function P:OnEvent(event, unit)
    if not CA.Config.db then return end
    if event == "PLAYER_ENTERING_WORLD" then
        self.lastHK = sessionKills()
    elseif event == "PLAYER_PVP_KILLS_CHANGED" then
        if unit and unit ~= "player" then return end
        local hk = sessionKills()
        if not hk then self:AddKills(1); return end
        local delta = hk - (self.lastHK or hk)
        self.lastHK = hk
        if delta > 0 then self:AddKills(delta) end
    elseif event == "PLAYER_DEAD" then
        self:SetStreak(0)
        self.popup = nil
    end
end

local f = CreateFrame("Frame", "CursorAuraPvPFrame", UIParent)
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_PVP_KILLS_CHANGED")
f:RegisterEvent("PLAYER_DEAD")
f:RegisterEvent("PLAYER_PVP_RANK_CHANGED")          -- écusson (Crest.lua)
f:SetScript("OnEvent", function(_, event, unit)
    P:OnEvent(event, unit)
    if CA.Crest then CA.Crest:OnEvent(event) end
end)

-- ---- rendu (appelé par le Renderer à chaque image) ----------------
local function place(tex, x, y, w)
    tex:ClearAllPoints()
    tex:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    tex:SetSize(w, w)
end

function P:Build(frame)
    if self.ring then return end
    local function tex(sprite)
        local t = frame:CreateTexture(nil, "OVERLAY")
        t:SetTexture(CA.TEX .. sprite); t:SetBlendMode("ADD"); t:Hide()
        return t
    end
    self.glow, self.ring, self.ring2 = tex("soft"), tex("ring"), tex("ring")
    for i = 1, 3 do self.shards[i] = tex("shard") end
    for i = 1, 2 do
        local l = frame:CreateLine(nil, "OVERLAY")
        l:SetTexture(CA.TEX .. "bolt" .. i); l:SetBlendMode("ADD"); l:SetThickness(8); l:Hide()
        self.bolts[i] = l
    end
    self.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    self.text:Hide()
    self.t, self.boltT = 0, 0
end

function P:Hide()
    if not self.ring then return end
    self.glow:Hide(); self.ring:Hide(); self.ring2:Hide(); self.text:Hide()
    for i = 1, 3 do self.shards[i]:Hide() end
    for i = 1, 2 do self.bolts[i]:Hide() end
end

function P:Active()
    return CA.Config:Get("pvp") == "serie" and self:Tier(self:Streak()) or 0
end

-- multiplicateur d'émission de l'aura (palier 1 et plus)
function P:Boost()
    local k = self:Active()
    return k >= 1 and (1.25 + k * .08) or 1
end

-- couleur d'or d'une particule au palier 100 (stable par particule)
function P:Gold(p)
    if self:Active() < 6 then return nil end
    p.gold = p.gold or random(1, 3)
    return GOLDS[p.gold]
end

local function spark(sys, x, y, vx, vy, size, life, c, tag)
    local p = { x = x, y = y, ox = x, oy = y, life = 1, decay = 1 / life, size = size, sizeGrow = 0,
                r = c[1], g = c[2], b = c[3], alpha = .9, sprite = "soft", blend = "ADD",
                rot = 0, rotSpeed = 0, vx = vx, vy = vy }
    p[tag] = true
    sys:Add(p)
end

function P:Draw(frame, sys, cx, cy, dt)
    self:Build(frame)
    local k = self:Active()
    if k == 0 then self:Hide(); return end
    self.t = self.t + dt
    local col = k == 6 and GOLD or RED
    local pulse = .5 + .5 * sin(self.t * 5)

    if self.burst then                                     -- explosion au passage de palier
        for _ = 1, 40 do
            local a, s = random() * 6.283, 60 + random() * 120
            spark(sys, cx, cy, cos(a) * s, sin(a) * s, 5, .7, col, "burstDot")
        end
        self.burst = nil
    end

    if k >= 2 then
        place(self.ring, cx, cy, (30 + pulse * 4) * 2 * 32 / 28)       -- ring.tga : rayon 28 px sur 64
        self.ring:SetVertexColor(col[1], col[2], col[3], .35 + .4 * pulse); self.ring:Show()
    else self.ring:Hide() end
    if k >= 4 then
        place(self.ring2, cx, cy, (40 - pulse * 3) * 2 * 32 / 28)
        self.ring2:SetVertexColor(col[1], col[2], col[3], .25 + .3 * (1 - pulse)); self.ring2:Show()
        if random() < dt * 14 then
            local c = k == 6 and GOLD or (random() < .5 and RED or { 1, .69, .13 })
            spark(sys, cx + (random() - .5) * 30, cy, (random() - .5) * 20, 40 + random() * 50, 5, 1.1, c, "ember")
        end
    else self.ring2:Hide() end

    for i = 1, 3 do
        local s = self.shards[i]
        if k >= 3 then
            local a = self.t * 3 + i * 2.094
            local x, y = cx + cos(a) * 36, cy + sin(a) * 36
            place(s, x, y, 18); s:SetRotation(a + 1.571)
            s:SetVertexColor(col[1], col[2] * (k == 6 and 1 or .6), col[3] * (k == 6 and 1 or .6), 1); s:Show()
            if random() < dt * 20 then spark(sys, x, y, 0, 0, 4, .4, col, "trailDot") end
        else s:Hide() end
    end

    self.boltT = self.boltT - dt
    if k >= 5 and self.boltT <= 0 then
        self.boltT = .16
        for i = 1, 2 do
            local l, a = self.bolts[i], random() * 6.283
            local r2 = 34 + random() * 18
            l:SetStartPoint("BOTTOMLEFT", UIParent, cx + cos(a) * 6, cy + sin(a) * 6)
            l:SetEndPoint("BOTTOMLEFT", UIParent, cx + cos(a) * r2, cy + sin(a) * r2)
            l:SetVertexColor(col[1], k == 6 and .95 or .42, k == 6 and .69 or .42, .7 + random() * .3); l:Show()
        end
    elseif k < 5 then for i = 1, 2 do self.bolts[i]:Hide() end end

    if k == 6 then
        place(self.glow, cx, cy, 140); self.glow:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], .18 + .06 * pulse); self.glow:Show()
    else self.glow:Hide() end

    local pop = self.popup
    if pop then
        pop.age = pop.age + dt
        if pop.age >= POPUP_LIFE then self.popup = nil; self.text:Hide()
        else
            self.text:ClearAllPoints()
            self.text:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy + 50 + pop.age * 20)
            self.text:SetText(pop.text)
            self.text:SetTextColor(col[1], col[2], col[3], max(0, 1 - pop.age / POPUP_LIFE))
            self.text:Show()
        end
    else self.text:Hide() end
end
