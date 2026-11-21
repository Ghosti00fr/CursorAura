-- Cursor Aura © 2026 Ghosti. All Rights Reserved.
-- ============================================================
--  Cursor Aura — Crest.lua
--  Écusson PvP (choix « rang ») : un bouclier près du curseur qui
--  évolue avec le rang d'honneur (1 à 14), un pour l'Alliance (bleu
--  et or, épées, ailes) et un pour la Horde (rouge et noir, haches,
--  cornes). Pièces dans textures\crest, même repère pour toutes.
-- ============================================================

local CA = CursorAura
local random = math.random

CA.Crest = { marks = {}, wpn = {}, wpn2 = {}, wings = {} }
local C = CA.Crest

local SIZE = 84                 -- taille d'une pièce (px) ; 200 unités de l'aperçu
local OX, OY = 30, -30           -- en bas à droite du curseur, pour ne pas le cacher
local U = SIZE / 200
local TEX = CA.TEX .. "crest\\"

local hex = CA.hex
local function col(s) return { hex(s) } end
local LOOK = {
    a = { shield = "shield_a", half = "half_a", rim = "rim_a", mark = "chevron", emblem = "star",
          w1 = "sword_blade", w2 = "sword_hilt", wing = "wing_a", crown = "crown_a",
          main = col("#1F4FB8"), dark = col("#0E2766"), trim = col("#E8C150"), acc = col("#E8C150"),
          emb = col("#E8C150"), c1 = col("#D8DEE6"), c2 = col("#C9A227"), wingC = col("#DDE6F5"),
          crownC = col("#E8C150"), gem = col("#C81E3A"), dot = col("#FFFFFF"),
          sparks = { col("#E8C150"), col("#7FB2FF") }, rays = col("#E8C150") },
    h = { shield = "shield_h", half = "half_h", rim = "rim_h", mark = "bar", emblem = "tusks",
          w1 = "axe_haft", w2 = "axe_head", wing = "horn_h", crown = "crown_h",
          main = col("#8E1414"), dark = col("#3A0808"), trim = col("#B8B8B8"), acc = col("#E8541C"),
          emb = col("#E8541C"), c1 = col("#5A3A1E"), c2 = col("#9AA0A6"), wingC = col("#D9CBB0"),
          crownC = col("#8C8C8C"), gem = col("#FF5A1C"), dot = col("#FFD0A0"), spikes = col("#C9C9C9"),
          sparks = { col("#FF6A1C"), col("#FFB020") }, rays = col("#E8541C") },
}

-- rang d'honneur 0..14 (0 = aucun). UnitPVPRank et l'énumération PvPRanks :
-- 5 = rang 1 ... 18 = rang 14 ; en dessous : sans rang ou déshonoré.
local function toRank(v)
    v = tonumber(v) or 0
    if v >= 5 then return math.min(v - 4, 14) end
    return 0
end

function C:ReadRank()
    local r = UnitPVPRank and toRank(UnitPVPRank("player")) or 0
    if r == 0 and GetPVPLifetimeStats then r = toRank(select(2, GetPVPLifetimeStats())) end
    return r
end

function C:Faction()
    local f = UnitFactionGroup and UnitFactionGroup("player")
    if f == "Alliance" then return "a" elseif f == "Horde" then return "h" end
end

function C:OnEvent(event)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_PVP_RANK_CHANGED" then
        self.rank = self:ReadRank()
    end
end

function C:Build(frame)
    if self.shield then return end
    local function tex(sub, blend)
        local t = frame:CreateTexture(nil, "OVERLAY", nil, sub)
        t:SetBlendMode(blend or "BLEND"); t:Hide()
        return t
    end
    self.rays = tex(-8, "ADD")
    self.rays:SetTexture(TEX .. "rays")
    for i = 1, 2 do self.wings[i] = tex(-7) end
    self.wings[2]:SetTexCoord(1, 0, 0, 1)                 -- aile / corne gauche en miroir
    for i = 1, 2 do self.wpn[i], self.wpn2[i] = tex(-6), tex(-5) end
    self.shield, self.half, self.rim, self.spikes = tex(-4), tex(-3), tex(-2), tex(-1)
    self.spikes:SetTexture(TEX .. "spikes_h")
    for i = 1, 5 do self.marks[i] = tex(1) end
    self.emblem, self.dot = tex(1), tex(2)
    self.dot:SetTexture(TEX .. "dot")
    self.crown, self.gem = tex(3), tex(4)
    self.gem:SetTexture(TEX .. "gem")
    self.t, self.sparkT = 0, 0
end

local ALL = { "rays", "shield", "half", "rim", "spikes", "emblem", "dot", "crown", "gem" }
function C:Hide()
    if not self.shield then return end
    for _, k in ipairs(ALL) do self[k]:Hide() end
    for i = 1, 5 do self.marks[i]:Hide() end
    for i = 1, 2 do self.wpn[i]:Hide(); self.wpn2[i]:Hide(); self.wings[i]:Hide() end
end

local function put(t, file, c, x, y, rot)
    if file then local p = TEX .. file; if t.file ~= p then t:SetTexture(p); t.file = p end end
    t:ClearAllPoints()
    t:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    t:SetSize(SIZE, SIZE)
    t:SetRotation(rot or 0)
    t:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
    t:Show()
end
local function show(t, on, ...) if on then put(t, ...) else t:Hide() end end

function C:Draw(frame, sys, cx, cy, dt)
    self:Build(frame)
    local fac = self:Faction()
    if CA.Config:Get("pvp") ~= "rang" or not fac then self:Hide(); return end
    if not self.rank then self.rank = self:ReadRank() end
    local r, L = self.rank, LOOK[fac]
    self.t = self.t + dt
    local x, y = cx + OX, cy + OY

    show(self.rays, r >= 14, nil, { L.rays[1], L.rays[2], L.rays[3], .35 }, x, y, -self.t * .4)
    for i = 1, 2 do
        show(self.wings[i], r >= 10, L.wing, L.wingC, x, y)
        local rot = (i == 1 and -.6 or .6)
        show(self.wpn[i], r >= 6, L.w1, L.c1, x, y, rot)
        show(self.wpn2[i], r >= 6, L.w2, L.c2, x, y, rot)
    end
    put(self.shield, L.shield, L.main, x, y)
    put(self.half, L.half, L.dark, x, y)
    put(self.rim, L.rim, r >= 8 and L.trim or L.dark, x, y)
    show(self.spikes, fac == "h" and r >= 8, nil, L.spikes or L.trim, x, y)
    for i = 1, 5 do                                       -- chevrons / barres, 10 unités d'écart
        show(self.marks[i], r >= 1 and r <= 5 and i <= r, L.mark, L.acc, x, y - (-18 + (i - 1) * 10) * U)
    end
    show(self.emblem, r >= 6, L.emblem, L.emb, x, y)
    show(self.dot, r >= 9, nil, L.dot, x, y)
    show(self.crown, r >= 12, L.crown, L.crownC, x, y)
    show(self.gem, r >= 12, nil, L.gem, x, y)

    if r >= 13 then                                       -- étincelles / braises qui montent
        self.sparkT = self.sparkT + dt
        while self.sparkT >= .033 do
            self.sparkT = self.sparkT - .033
            local c = L.sparks[random(1, 2)]
            local px = x + (random() - .5) * 90 * U
            sys:Add({ x = px, y = y - 40 * U, ox = px, oy = y, life = 1, decay = 1 / 1.4, size = 4, sizeGrow = 0,
                      r = c[1], g = c[2], b = c[3], alpha = .9, sprite = "soft", blend = "ADD",
                      rot = 0, rotSpeed = 0, vx = (random() - .5) * 12 * U, vy = (20 + random() * 40) * U,
                      crestSpark = true })
        end
    end
end
