-- Tâche 2 : effets et spé -> effet
local M = dofile("test/mock.lua")
local function load() for _, f in ipairs({"Locales/enUS","Locales/frFR","Locales/esES","Core","Effects","Specs"}) do dofile("CursorAura/"..f..".lua") end; CA = CursorAura end
M.reset(); load(); CA.Config:Init()
for _, k in ipairs(CA.EFFECT_KEYS) do
    local d = CA.Effects.defs[k]
    ok(d and #d.colors == 3 and (d.blend == "ADD" or d.blend == "BLEND"), "effet complet : "..k)
    ok(CA.Effects:Name(k) ~= "fx_"..k, "nom localisé : "..k)
end
ok(#CA.EFFECT_KEYS == 17, "17 effets")
ok(CA.Effects.defs.fumee.blend == "BLEND" and CA.Effects.defs.ombre.extras.core, "fumée BLEND, ombre a un cœur")
M.classFile = "SHAMAN"; M.specIndex = 1; M.specs = { [1] = { 262, "Élémentaire" } }
ok(CA.Specs:Resolve() == "eclairs", "chaman élém -> éclairs")
M.classFile = "ROGUE"; M.specIndex = 3; M.specs = { [3] = { 261, "Finesse" } }
ok(CA.Specs:Resolve() == "fumee", "voleur -> fumée")
M.classFile = "MAGE"; M.specIndex = nil
ok(CA.Specs:Resolve() == "arcanes", "pas de spé -> défaut classe")
M.specIndex = 5; M.specs = {}
ok(CA.Specs:Resolve() == "arcanes", "index inconnu -> défaut classe")
M.classFile = "WARLOCK"; M.specIndex = 1; M.specs = { [1] = { 9999, "?" } }
ok(CA.Specs:Resolve() == "ombre", "specID inconnu -> défaut classe")
M.noSpecAPI = true; M.reset(); load(); CA.Config:Init(); M.classFile = "PRIEST"
ok(CA.Specs:Resolve() == "lumiere", "API absente -> défaut classe")
M.noSpecAPI = false; M.reset(); load(); CA.Config:Init(); M.classFile = "DEATHKNIGHT"
ok(CA.Specs:Resolve() == "arcanes", "classe inconnue -> arcanes")
CA.Config:Set("choice", "terre"); M.classFile = "MAGE"
ok(CA.Specs:Resolve() == "terre", "manuel prioritaire")
local n = 0; for id, k in pairs(CA.Specs.SPEC_EFFECT) do n = n + 1; ok(CA.Effects.defs[k], "spec "..id.." -> effet existant") end
ok(n == 28, "28 specID (9 classes)")
-- 0.0.3 : sondage talents pour /aura debug (Forever : 1 spé par classe)
C_ClassTalents, C_Traits = nil, nil
ok(type(CA.Specs:Probe()) == "string", "probe sans API talents")
C_ClassTalents = { GetActiveConfigID = function() return 7 end, GetActiveHeroTalentSpec = function() return 42 end,
                   GetHeroTalentSpecsForClassSpec = function(c, s) return { 41, 42 } end }
C_Traits = { GetSubTreeInfo = function(c, id) return { name = "Sub" .. id, isActive = id == 42 } end }
local s = CA.Specs:Probe()
ok(s:find("hero=42", 1, true) and s:find("41:Sub41", 1, true) and s:find("42:Sub42*", 1, true), "probe lit les sous-arbres : " .. s)
C_ClassTalents.GetActiveConfigID = function() error("boom") end
ok(type(CA.Specs:Probe()) == "string", "probe survit à une erreur")
C_ClassTalents, C_Traits = nil, nil
-- 0.0.4 : sondage de l'arbre (devises par branche, talents achetés)
C_ClassTalents = { GetActiveConfigID = function() return 7 end, GetTraitTreeForSpec = function(s) return 900 end }
C_Traits = {
    GetTreeCurrencyInfo = function(c, t) return { { traitCurrencyID = 11, spent = 5, maxQuantity = 31 } } end,
    GetTreeNodes = function(t) return { 1, 2, 3 } end,
    GetNodeInfo = function(c, n) return { ID = n, ranksPurchased = n == 3 and 0 or 1, subTreeID = n == 2 and 77 or nil,
                                          activeEntry = { entryID = 100 + n } } end,
    GetEntryInfo = function(c, e) return { definitionID = e + 100 } end,
    GetDefinitionInfo = function(d) return { spellID = d } end,
}
C_Spell = { GetSpellName = function(id) return "Spell" .. id end }
local t = CA.Specs:ProbeTree()
ok(t:find("tree=900", 1, true) and t:find("cur11=5/31", 1, true) and t:find("bought=2", 1, true)
   and t:find("sub77=1", 1, true) and t:find("Spell201", 1, true) and not t:find("Spell203", 1, true), "probe arbre : " .. t)
C_Traits.GetTreeNodes = function() error("boom") end
ok(type(CA.Specs:ProbeTree()) == "string", "probe arbre survit à une erreur")
C_ClassTalents, C_Traits, C_Spell = nil, nil, nil
ok(type(CA.Specs:ProbeTree()) == "string", "probe arbre sans API")
-- 0.0.5 : Forever = arbre à 3 onglets façon Classic ; spé = onglet le plus rempli
local function tree(points)   -- points = {onglet1, onglet2, onglet3}
    local nodes, info = {}, {}
    for tab = 1, 3 do for k = 1, 3 do
        local id = tab * 10 + k; nodes[#nodes + 1] = id
        info[id] = { ID = id, posX = (tab - 1) * 1000 + k * 100, posY = k * 50,
                     ranksPurchased = (k == 1) and points[tab] or 0 }
    end end
    C_ClassTalents = { GetActiveConfigID = function() return 7 end, GetTraitTreeForSpec = function() return 900 end }
    C_Traits = { GetTreeNodes = function() return nodes end, GetNodeInfo = function(c, n) return info[n] end }
end
M.reset(); load(); CA.Config:Init(); M.specIndex = 1
M.classFile = "MAGE"; M.specs = { [1] = { 1482, "Mage" } }
tree({ 0, 0, 1 }); ok(CA.Specs:Resolve() == "givre", "mage, 1 point en Givre -> givre")
tree({ 0, 3, 1 }); ok(CA.Specs:Resolve() == "feu", "mage, Feu majoritaire -> feu")
tree({ 0, 0, 0 }); ok(CA.Specs:Resolve() == "arcanes", "aucun point -> défaut classe")
tree({ 2, 2, 0 }); ok(CA.Specs:Resolve() == "arcanes", "égalité -> défaut classe")
M.classFile = "WARLOCK"; tree({ 0, 5, 0 }); ok(CA.Specs:Resolve() == "gangrene", "démo -> gangrène")
M.classFile = "SHAMAN"; tree({ 0, 0, 4 }); ok(CA.Specs:Resolve() == "eau", "chaman resto -> eau")
M.classFile = "PALADIN"
tree({ 5, 0, 0 }); ok(CA.Specs:Resolve() == "lumiere", "paladin Sacré -> lumière (jaune)")
tree({ 0, 5, 0 }); ok(CA.Specs:Resolve() == "protection", "paladin Protection -> protection (bleu)")
tree({ 0, 0, 5 }); ok(CA.Specs:Resolve() == "vindicte", "paladin Vindicte -> vindicte (rouge)")
M.classFile = "SHAMAN"; tree({ 0, 0, 4 })
local p = CA.Specs:TabPoints(); ok(p and p[1] == 0 and p[2] == 0 and p[3] == 4, "points par onglet")
C_Traits.GetTreeNodes = function() error("boom") end
ok(CA.Specs:Resolve() == "eclairs", "erreur d'arbre -> défaut classe")
for cls, tabs in pairs(CA.Specs.TAB_EFFECT) do
    ok(#tabs == 3 and CA.Effects.defs[tabs[1]] and CA.Effects.defs[tabs[2]] and CA.Effects.defs[tabs[3]], "onglets " .. cls)
end
C_ClassTalents, C_Traits = nil, nil
