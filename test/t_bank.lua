-- 0.0.10 : curseurs « banquier » (Or, Bourse) qui grossissent avec l'or, icône de minimap
local M = dofile("test/mock.lua"); M.reset()
M.money = 0
GetMoney = function() return M.money end
Minimap = M.stub(); M.overMap = false
function Minimap:IsMouseOver() return M.overMap end
function Minimap:GetCenter() return 1000, 700 end
for _, f in ipairs({"Locales/enUS","Locales/frFR","Core","Effects","Specs","Particles","Renderer","PvP","Crest","Bank","Options","Commands","Minimap"}) do dofile("CursorAura/"..f..".lua") end; CA = CursorAura
CA.Config:Init(); M.specIndex = 2; M.specs = { [2] = { 63, "Feu" } }
local B, R = CA.Bank, CA.Renderer
local G = 10000                                        -- 1 po = 10 000 pc

ok(#CA.EFFECT_KEYS == 17 and CA.EFFECT_KEYS[16] == "or" and CA.EFFECT_KEYS[17] == "bourse", "17 effets, Or et Bourse en fin")
ok(CA.Effects:Name("or") == "Or" and CA.Effects:Name("bourse") == "Bourse", "noms localisés")
CursorAuraCharDB.choice = "bourse"; CA.Config:Init(); ok(CA.Config:Get("choice") == "bourse", "choix Bourse sauvegardé")
CA.Config:Set("choice", "auto"); R:Refresh(); ok(R.current == "feu", "Auto ne choisit jamais un effet banquier")

-- or -> niveau et palier
M.money = 0; ok(B:Gold() == 0 and B:Level() == 0 and B:Tier() == 0, "0 po : niveau 0")
M.money = 99 * G + 9999; ok(B:Gold() == 99 and B:Tier() == 0, "99 po : palier 0 (pièces de cuivre arrondies)")
M.money = 100 * G; ok(B:Tier() == 1, "100 po : palier 1")
M.money = 1000 * G; ok(B:Tier() == 2, "1 000 po : palier 2")
M.money = 10000 * G; ok(B:Tier() == 3, "10 000 po : palier 3")
M.money = 100000 * G; ok(B:Tier() == 4, "100 000 po : palier 4")
M.money = 1000000 * G; ok(B:Tier() == 5 and B:Level() == 1, "1 000 000 po : palier 5, niveau max")
M.money = 9e7 * G; ok(B:Level() == 1, "niveau plafonné")
M.money = 1000 * G; ok(math.abs(B:Level() - .5) < .01, "échelle log : 1 000 po = mi-chemin")

-- effet Or
local function run(choice, money, n)
    M.money = money; CA.Config:Set("choice", choice); R:Refresh()
    for i = 1, n or 60 do R:OnUpdate(1/60) end
end
local function count(f) local k = 0; for i = 1, R.sys.count do if f(R.sys.list[i]) then k = k + 1 end end; return k end
M.cx, M.cy = 500, 400
run("or", 50 * G)
ok(count(function(p) return p.coin and p.orbit end) > 0, "Or : pièces en orbite")
ok(count(function(p) return p.coin and p.r > .99 end) == 0, "50 po : pas de pièce d'or")
ok(count(function(p) return p.cascade end) > 0, "Or : cascade dès le départ")
ok(count(function(p) return p.cascade and p.y < 400 end) > 0, "cascade : les pièces tombent sous le curseur")
run("or", 50 * G, 90); ok(count(function(p) return p.cascade and p.bn and p.bn >= 1 end) > 0, "cascade : rebonds sur les marches")
local narrow = false
for i = 1, R.sys.count do local p, t = R.sys.list[i], R.pool[i]; if p.coin and t.w < t.h * .9 then narrow = true end end
ok(narrow, "pièces qui tournent (largeur variable)")
local poor = count(function(p) return p.cascade end)
run("or", 1000000 * G, 90)
ok(count(function(p) return p.cascade end) > poor, "plus d'or : cascade plus fournie")
ok(count(function(p) return p.sprite == "bank\\gemcut" end) > 0, "100 000 po et plus : gemmes")
ok(B.crown[1].shown and B.crown[12].shown and B.glow.shown, "1 000 000 po : couronne de 12 pièces et halo")
run("or", 500 * G); ok(not B.crown[1].shown, "500 po : pas de couronne")

-- effet Bourse
run("bourse", 0, 20)
ok(B.body.shown and B.body.tex == CA.TEX .. "bank\\purse_body", "Bourse : corps en cuir")
local mc = B.medal.color; ok(mc[1] > .8 and mc[2] < .7, "0 po : médaillon de cuivre")
local pt = B.body.point; ok(pt[4] > 500 and pt[5] < 400, "bourse en bas à droite du curseur")
local small, smallHeap = B.body.w, B:HeapShown()
ok(smallHeap >= 5, "quelques pièces dans la bourse")
ok(B.cord.color[3] > .4, "cordon en cuir clair")
run("bourse", 1000000 * G, 20)
ok(B.body.tex == CA.TEX .. "bank\\purse_body_lux" and B.collar.tex == CA.TEX .. "bank\\purse_collar_lux", "1 000 000 po : cuir brodé d'or")
ok(B.body.w > small * 2, "la bourse grossit avec l'or")
ok(B:HeapShown() > smallHeap + 20, "elle se remplit de pièces")
local cc = B.cord.color; ok(cc[1] > .95 and cc[2] > .8 and cc[3] < .55, "cordon doré")
ok(B.gem.shown, "rubis sur le médaillon")
run("bourse", 1000000 * G, 120)
ok(count(function(p) return p.into end) > 0, "des pièces tombent dans la bourse")
ok(count(function(p) return p.spill end) > 0, "les pièces débordent")
ok(B.squashMax > 0, "la bourse s'écrase quand une pièce arrive")
run("bourse", 100 * G, 120); ok(count(function(p) return p.spill end) == 0, "100 po : pas de débordement")
ok(not B.gem.shown, "100 po : pas de rubis")
CA.Config:Set("mode", "seul"); run("bourse", 1000000 * G, 10)
ok(not B.body.shown and count(function(p) return p.coin end) == 0, "Curseur seul : ni bourse ni pièces")
CA.Config:Set("mode", "aura"); run("feu", 0, 10)
ok(not B.body.shown and not B.crown[1].shown, "autre effet : bourse masquée")
run("bourse", 0, 5); M.mouselook = true; R:OnUpdate(1/60)
ok(not B.body.shown, "rotation caméra : bourse masquée"); M.mouselook = false

-- icône de minimap
local btn = CursorAuraMinimapButton
ok(btn and btn.parent == Minimap, "icône sur la minimap")
ok(btn.icon.tex == CA.TEX .. "bank\\minimap", "logo de l'addon")
M.overMap = false; for i = 1, 30 do btn.scripts.OnUpdate(btn, 1/60) end
ok(btn.alpha == 0 and btn.mouseEnabled == false, "souris hors de la minimap : icône cachée")
M.overMap = true; for i = 1, 30 do btn.scripts.OnUpdate(btn, 1/60) end
ok(btn.alpha > .95 and btn.mouseEnabled, "souris sur la minimap : icône visible")
M.overMap = false; btn.scripts.OnUpdate(btn, 1/60)
ok(btn.alpha > 0 and btn.alpha < 1, "fondu en sortie")
for i = 1, 30 do btn.scripts.OnUpdate(btn, 1/60) end; ok(btn.alpha == 0, "puis cachée")
btn.scripts.OnClick(btn, "LeftButton"); ok(CursorAuraOptions and CursorAuraOptions:IsShown(), "clic : ouvre les réglages")
btn.scripts.OnClick(btn, "LeftButton"); ok(not CursorAuraOptions:IsShown(), "re-clic : ferme")
ok(CursorAuraCharDB.minimapAngle == 225, "position par défaut")
M.cx, M.cy = 1000, 800                                 -- curseur au-dessus du centre de la minimap
btn.scripts.OnDragStart(btn); btn.scripts.OnUpdate(btn, 1/60); btn.scripts.OnDragStop(btn)
ok(math.abs(CursorAuraCharDB.minimapAngle - 90) < .5, "glisser : nouvel angle sauvegardé")
local p = btn.point; ok(p and p[2] == Minimap and math.abs(p[4]) < 1 and p[5] > 70, "icône replacée au bord")
CursorAuraCharDB.minimapAngle = "x"; CA.Config:Init(); ok(CursorAuraCharDB.minimapAngle == 225, "angle invalide -> défaut")
