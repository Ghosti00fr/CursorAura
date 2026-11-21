-- 0.0.9 : écusson PvP qui évolue avec le rang (14 rangs), Alliance et Horde
local M = dofile("test/mock.lua"); M.reset()
M.faction, M.unitRank, M.lifeRank = "Alliance", 0, 0
UnitFactionGroup = function(u) return M.faction, M.faction end
UnitPVPRank = function(u) return M.unitRank end
GetPVPLifetimeStats = function() return 10, M.lifeRank end
GetPVPSessionStats = function() return 0, 0 end
for _, f in ipairs({"Locales/enUS","Locales/frFR","Core","Effects","Specs","Particles","Renderer","PvP","Crest","Bank","Options","Commands","Minimap"}) do dofile("CursorAura/"..f..".lua") end; CA = CursorAura
CA.Config:Init(); M.specIndex = 2; M.specs = { [2] = { 63, "Feu" } }
local C, R, P = CA.Crest, CA.Renderer, CA.PvP
local pf = CursorAuraPvPFrame

-- rang
M.unitRank = 9; ok(C:ReadRank() == 5, "UnitPVPRank 9 -> rang 5 (Sergent-major)")
M.unitRank = 18; ok(C:ReadRank() == 14, "UnitPVPRank 18 -> rang 14")
M.unitRank = 0; M.lifeRank = 12; ok(C:ReadRank() == 8, "UnitPVPRank 0 : repli sur le meilleur rang à vie")
M.lifeRank = 3; ok(C:ReadRank() == 0, "déshonoré / sans rang -> 0")
local u, g = UnitPVPRank, GetPVPLifetimeStats; UnitPVPRank, GetPVPLifetimeStats = nil, nil
ok(C:ReadRank() == 0, "aucune API : rang 0, pas d'erreur")
UnitPVPRank, GetPVPLifetimeStats = u, g
ok(C:Faction() == "a", "Alliance détectée")
M.faction = "Horde"; ok(C:Faction() == "h", "Horde détectée")
M.faction = "Neutral"; ok(C:Faction() == nil, "neutre : pas d'écusson")
M.faction = "Alliance"

-- réglage
CA.Config:Set("pvp", "rang"); CursorAuraCharDB.pvp = "rang"; CA.Config:Init()
ok(CA.Config:Get("pvp") == "rang", "réglage pvp = rang accepté")

-- rendu
R:Refresh(); M.cx, M.cy = 500, 300
local function at(rank, fac)
    M.faction = fac or "Alliance"; M.unitRank = rank > 0 and rank + 4 or 0; M.lifeRank = 0
    pf.scripts.OnEvent(pf, "PLAYER_PVP_RANK_CHANGED", "player")
    for i = 1, 20 do R:OnUpdate(1/60) end
end
local function shownChev() local n = 0; for i = 1, 5 do if C.marks[i].shown then n = n + 1 end end; return n end
at(1)
ok(C.rank == 1, "PLAYER_PVP_RANK_CHANGED : rang relu")
ok(C.shield.shown and C.shield.tex == CA.TEX .. "crest\\shield_a", "Alliance : bouclier Alliance")
ok(shownChev() == 1 and C.marks[1].tex == CA.TEX .. "crest\\chevron", "rang 1 : 1 chevron")
ok(not C.wpn[1].shown and not C.crown.shown and not C.wings[1].shown, "rang 1 : ni armes, ni ailes, ni couronne")
local pt = C.shield.point; ok(pt and pt[4] > 500 and pt[5] < 300, "écusson en bas à droite du curseur")
at(5); ok(shownChev() == 5, "rang 5 : 5 chevrons")
at(6); ok(shownChev() == 0 and C.emblem.shown and C.emblem.tex == CA.TEX .. "crest\\star", "rang 6 : étoile")
ok(C.wpn[1].shown and C.wpn[2].shown and C.wpn[1].tex == CA.TEX .. "crest\\sword_blade", "rang 6 : épées croisées")
ok(C.wpn[1].rot and C.wpn[2].rot and C.wpn[1].rot ~= C.wpn[2].rot, "épées inclinées en croix")
local rim = C.rim.color; ok(rim[3] > .3, "rang 6 : bordure sombre")
at(8); rim = C.rim.color; ok(rim[1] > .85 and rim[2] > .7 and rim[3] < .4, "rang 8 : bordure dorée")
ok(not C.spikes.shown, "Alliance : pas de pointes")
at(9); ok(C.dot.shown, "rang 9 : point central")
at(10); ok(C.wings[1].shown and C.wings[2].shown and C.wings[1].tex == CA.TEX .. "crest\\wing_a", "rang 10 : ailes")
ok(not C.crown.shown, "rang 10 : pas encore de couronne")
at(12); ok(C.crown.shown and C.gem.shown and C.crown.tex == CA.TEX .. "crest\\crown_a", "rang 12 : couronne")
at(13); local sp = 0; for _ = 1, 60 do R:OnUpdate(1/60) end
for i = 1, R.sys.count do if R.sys.list[i].crestSpark then sp = sp + 1 end end
ok(sp > 0, "rang 13 : étincelles")
ok(not C.rays.shown, "rang 13 : pas de rayons")
at(14); local r1 = C.rays.rot; R:OnUpdate(1/10)
ok(C.rays.shown and C.rays.rot ~= r1, "rang 14 : rayons qui tournent")

-- Horde
at(1, "Horde"); ok(C.shield.tex == CA.TEX .. "crest\\shield_h" and C.marks[1].tex == CA.TEX .. "crest\\bar", "Horde : bouclier à pointes, barres")
local sc = C.shield.color; ok(sc[1] > .5 and sc[3] < .2, "Horde : rouge")
at(6, "Horde"); ok(C.emblem.tex == CA.TEX .. "crest\\tusks" and C.wpn[1].tex == CA.TEX .. "crest\\axe_haft", "Horde rang 6 : crocs et haches")
at(8, "Horde"); ok(C.spikes.shown, "Horde rang 8 : pointes de fer")
at(10, "Horde"); ok(C.wings[1].tex == CA.TEX .. "crest\\horn_h", "Horde rang 10 : cornes")
at(12, "Horde"); ok(C.crown.tex == CA.TEX .. "crest\\crown_h", "Horde rang 12 : couronne à pointes")
at(0); ok(C.shield.shown and shownChev() == 0 and not C.emblem.shown, "sans rang : bouclier nu")

-- l'écusson remplace la série, et inversement
P:SetStreak(20); at(5)
ok(not P.ring.shown, "mode rang : pas d'anneau de série")
CA.Config:Set("pvp", "serie"); for i = 1, 5 do R:OnUpdate(1/60) end
ok(not C.shield.shown and P.ring.shown, "mode série : pas d'écusson")
CA.Config:Set("pvp", "rang"); M.faction = "Neutral"; for i = 1, 5 do R:OnUpdate(1/60) end
ok(not C.shield.shown, "neutre : écusson masqué")
M.faction = "Alliance"; M.mouselook = true; R:OnUpdate(1/60)
ok(not C.shield.shown, "rotation caméra : écusson masqué")
M.mouselook = false

-- commandes
CA.Config:Set("pvp", "serie")
CA.Commands:Run("pvp"); ok(CA.Config:Get("pvp") == "rang", "/aura pvp : série -> rang")
CA.Commands:Run("pvp"); ok(CA.Config:Get("pvp") == "off", "/aura pvp : rang -> désactivé")
CA.Commands:Run("pvp"); ok(CA.Config:Get("pvp") == "serie", "/aura pvp : désactivé -> série")
CA.Commands:Run("pvp rang"); ok(CA.Config:Get("pvp") == "rang", "/aura pvp rang")
CA.Commands:Run("pvp rank"); ok(CA.Config:Get("pvp") == "rang", "/aura pvp rank")
CA.Commands:Run("pvp off"); ok(CA.Config:Get("pvp") == "off", "/aura pvp off")
CA.Commands:Run("pvp serie"); ok(CA.Config:Get("pvp") == "serie", "/aura pvp serie")
ok(CA.L.rank_a and #CA.L.rank_a == 14 and #CA.L.rank_h == 14, "14 noms de rang par faction")
