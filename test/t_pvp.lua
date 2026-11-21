-- 0.0.8 : curseur PvP évolutif (série de victimes honorables)
local M = dofile("test/mock.lua"); M.reset()
M.hk = 0
GetPVPSessionStats = function() return M.hk, 0 end
for _, f in ipairs({"Locales/enUS","Locales/frFR","Core","Effects","Specs","Particles","Renderer","PvP","Crest","Bank","Options","Commands","Minimap"}) do dofile("CursorAura/"..f..".lua") end; CA = CursorAura
CA.Config:Init(); M.specIndex = 2; M.specs = { [2] = { 63, "Feu" } }
local P, R = CA.PvP, CA.Renderer
local f = CursorAuraPvPFrame

-- paliers
local exp = { [0]=0, [2]=0, [3]=1, [4]=1, [5]=2, [9]=2, [10]=3, [19]=3, [20]=4, [49]=4, [50]=5, [99]=5, [100]=6, [250]=6 }
local good = true
for n, t in pairs(exp) do if P:Tier(n) ~= t then good = false; print("palier faux", n, P:Tier(n)) end end
ok(good, "paliers 3 / 5 / 10 / 20 / 50 / 100")
ok(CA.Config:Get("pvp") == "serie" and P:Streak() == 0, "défaut : série active, à zéro")

-- détection des victimes
f.scripts.OnEvent(f, "PLAYER_ENTERING_WORLD")
M.hk = 1; f.scripts.OnEvent(f, "PLAYER_PVP_KILLS_CHANGED", "player")
ok(P:Streak() == 1, "victoire honorable : +1")
M.hk = 3; f.scripts.OnEvent(f, "PLAYER_PVP_KILLS_CHANGED", "player")
ok(P:Streak() == 3 and P.popup and P.popup.n == 3, "deux victoires d'un coup : +2, palier 3 annoncé")
ok(P.popup.text == "Série 3 !", "texte du palier en français")
f.scripts.OnEvent(f, "PLAYER_PVP_KILLS_CHANGED", "player")
ok(P:Streak() == 3, "événement sans nouvelle victoire : rien")
M.hk = 4; f.scripts.OnEvent(f, "PLAYER_PVP_KILLS_CHANGED", "party1")
ok(P:Streak() == 3, "autre unité ignorée")
M.hk = 4; f.scripts.OnEvent(f, "PLAYER_PVP_KILLS_CHANGED", "player")
ok(P:Streak() == 4, "puis comptée pour le joueur")
ok(CursorAuraCharDB.streak == 4, "série sauvegardée par personnage")
CursorAuraCharDB.streak = 4; CA.Config:Init()
ok(P:Streak() == 4, "série gardée après /reload")
CursorAuraCharDB.streak = "x"; CA.Config:Init()
ok(P:Streak() == 0, "série invalide -> 0")
P:SetStreak(4)
M.hk = 0; f.scripts.OnEvent(f, "PLAYER_ENTERING_WORLD")       -- nouvelle session : compteur repart à 0
M.hk = 1; f.scripts.OnEvent(f, "PLAYER_PVP_KILLS_CHANGED", "player")
ok(P:Streak() == 5, "nouvelle session : pas de faux saut")
f.scripts.OnEvent(f, "PLAYER_DEAD")
ok(P:Streak() == 0 and CursorAuraCharDB.streak == 0, "mort : série à zéro")

-- client sans GetPVPSessionStats : +1 par événement
local saved = GetPVPSessionStats; GetPVPSessionStats = nil
f.scripts.OnEvent(f, "PLAYER_PVP_KILLS_CHANGED", "player")
ok(P:Streak() == 1, "sans stats de session : +1 par événement")
GetPVPSessionStats = saved

-- rendu
R:Init(); R:Refresh(); M.cx, M.cy = 500, 300
local function frames(n) for i = 1, n do R:OnUpdate(1/60) end end
P:SetStreak(0); frames(30)
ok(not P.ring.shown and not P.shards[1].shown, "série 0 : rien en plus")
local base = R.sys.count
P:SetStreak(5); frames(30)
ok(P.ring.shown and not P.ring2.shown and not P.shards[1].shown, "palier 2 : anneau rouge seul")
P:SetStreak(10); frames(30)
ok(P.shards[1].shown and P.shards[3].shown and P.shards[1].tex == CA.TEX .. "shard", "palier 3 : couronne de 3 éclats")
P:SetStreak(20); frames(60)
ok(P.ring2.shown, "palier 4 : double anneau")
local embers = 0; for i = 1, R.sys.count do if R.sys.list[i].ember then embers = embers + 1 end end
ok(embers > 0, "palier 4 : braises qui montent")
P:SetStreak(50); frames(60)
ok(P.bolts[1].isLine and P.bolts[1].startP ~= nil, "palier 5 : éclairs rouges (Lines)")
local c = P.ring.color; ok(c[1] > .9 and c[2] < .4, "anneau rouge avant 100")
P:SetStreak(100); frames(30)
c = P.ring.color; ok(c[1] > .9 and c[2] > .7 and c[3] < .5, "palier 6 : anneau en or")
ok(P.glow.shown, "palier 6 : halo doré")
local allGold = R.sys.count > 0
for i = 1, R.sys.count do local pt = R.pool[i].color; if not (pt[1] > .9 and pt[2] > .7) then allGold = false end end
ok(allGold, "palier 6 : particules de l'aura en or (blanc, or clair, or)")
P.popup = nil; P:SetStreak(0); P:AddKills(5)
ok(P.popup and P.popup.n == 5, "passage direct 0 -> 5 : palier 5 annoncé")
frames(10); ok(P.text.shown and P.text.txt == "Série 5 !", "texte affiché au-dessus du curseur")
frames(120); ok(not P.text.shown, "texte disparaît")
CA.Config:Set("pvp", "off"); frames(10)
ok(not P.ring.shown and not P.shards[1].shown, "PvP désactivé : rien affiché")
M.mouselook = true; CA.Config:Set("pvp", "serie"); P:SetStreak(20); frames(2)
ok(not P.ring.shown and not P.shards[1].shown, "rotation caméra : PvP masqué aussi")
M.mouselook = false

-- commande
CA.Commands:Run("pvp off")
ok(CA.Config:Get("pvp") == "off", "/aura pvp off : désactive")
CA.Commands:Run("pvp serie")
ok(CA.Config:Get("pvp") == "serie", "/aura pvp serie : réactive")
CursorAuraCharDB.pvp = "n'importe"; CA.Config:Init(); ok(CA.Config:Get("pvp") == "serie", "valeur pvp invalide -> serie")
