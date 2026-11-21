-- Cursor Aura © 2026 Ghosti. All Rights Reserved.
-- Fait tourner le vrai code de l'addon hors jeu (mock de l'API) et écrit,
-- pour chaque vignette, toutes les textures visibles (position, taille,
-- couleur, rotation, mélange). compose_gallery.py en fait des images.
-- Usage (racine du projet) : luajit pipeline/render_gallery.lua > build/gallery.txt
local M = dofile("test/mock.lua"); M.reset()
math.randomseed(7)
local ALL = {}
local rawCreateFrame = CreateFrame
local function patch(f)
    local ct, cl = f.CreateTexture, f.CreateLine
    f.CreateTexture = function(self, name, layer, tmpl, sub)
        local t = ct(self); t.sub = sub or 0; t.idx = #ALL + 1
        function t:SetTexCoord(a) self.flip = (a == 1) end
        ALL[#ALL + 1] = t; return t
    end
    f.CreateLine = function(self, ...)
        local l = cl(self, ...); l.sub = 0; l.idx = #ALL + 1; ALL[#ALL + 1] = l; return l
    end
    return f
end
CreateFrame = function(...) return patch(rawCreateFrame(...)) end
M.money, M.faction, M.unitRank = 0, "Alliance", 0
GetMoney = function() return M.money end
UnitFactionGroup = function() return M.faction, M.faction end
UnitPVPRank = function() return M.unitRank end
GetPVPSessionStats = function() return 0, 0 end
for _, f in ipairs({"Locales/enUS","Core","Effects","Specs","Particles","Renderer","PvP","Crest","Bank","Options","Commands"}) do
    dofile("CursorAura/" .. f .. ".lua")
end
CA = CursorAura
CA.Config:Init(); M.classFile = "MAGE"; M.specIndex = 2; M.specs = { [2] = { 63, "Fire" } }
local R, P = CA.Renderer, CA.PvP
io.stdout:setvbuf("full")
local out = io.stdout

local function dump(name)
    out:write("TILE ", name, "\n")
    for _, t0 in ipairs(ALL) do
        local t = setmetatable({}, { __index = function(_, k) return rawget(t0, k) end })
        if t.shown and t.color and t.color[4] and t.color[4] > 0.01 then
            if t.isLine then
                if t.startP and t.endP then
                    out:write(("L %s %.2f %.2f %.2f %.2f %.2f %.3f %.3f %.3f %.3f %d %d\n"):format(
                        t.tex or "-", t.startP[3], t.startP[4], t.endP[3], t.endP[4], t.thickness or 8,
                        t.color[1], t.color[2], t.color[3], t.color[4], t.sub, t.idx))
                end
            elseif t.tex and t.point and t.w then
                out:write(("T %s %.2f %.2f %.2f %.2f %.3f %.3f %.3f %.3f %.4f %s %d %d %d\n"):format(
                    t.tex, t.point[4], t.point[5], t.w, t.h or t.w, t.color[1], t.color[2], t.color[3], t.color[4],
                    t.rot or 0, t.blend or "ADD", t.sub, t.idx, t.flip and 1 or 0))
            end
        end
    end
end

local function hideAll() for _, t in ipairs(ALL) do t.shown = false end end
-- les textures du mock renvoient une fonction pour tout champ absent : lecture brute
local function run(name, frames)
    R.sys:Clear(); hideAll()
    for i = 1, frames or 90 do R:OnUpdate(1 / 60) end
    dump(name)
end
local function set(k, v) CA.Config:Set(k, v); R:Refresh() end

M.cx, M.cy = 0, 0
set("pvp", "off")
for _, k in ipairs(CA.EFFECT_KEYS) do
    if not CA.Effects.defs[k].bank then set("choice", k); run("fx_" .. k) end
end
-- série PvP sur Feu
set("choice", "feu"); set("pvp", "serie")
for _, n in ipairs({ 0, 3, 5, 10, 20, 50, 100 }) do P:SetStreak(n); P.popup = nil; run("streak_" .. n) end
P:SetStreak(0)
-- écussons
set("pvp", "rang"); set("choice", "arcanes")
for _, fac in ipairs({ "Alliance", "Horde" }) do
    M.faction = fac
    for _, r in ipairs({ 1, 3, 5, 6, 8, 10, 12, 14 }) do
        M.unitRank = r + 4; CA.Crest.rank = r; run("crest_" .. fac .. "_" .. r, 60)
    end
end
set("pvp", "off")
-- banquier
for _, k in ipairs({ "or", "bourse" }) do
    set("choice", k)
    for _, g in ipairs({ 50, 1000, 10000, 100000, 1000000 }) do M.money = g * 10000; run("bank_" .. k .. "_" .. g, 120) end
end
out:flush()
