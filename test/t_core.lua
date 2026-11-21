-- Tâche 1 : réglages et langues
local M = dofile("test/mock.lua")
M.reset()
for _, f in ipairs({"Locales/enUS","Locales/frFR","Locales/esES","Core","Effects","Specs","Particles","Renderer","PvP","Crest","Bank","Options","Commands","Minimap"}) do dofile("CursorAura/"..f..".lua") end
ok(rawget(_G, "CA") == nil and type(CursorAura) == "table", "pas de global CA, espace de noms CursorAura")
local function load()
    for _, f in ipairs({"Locales/enUS","Locales/frFR","Locales/esES","Core"}) do dofile("CursorAura/"..f..".lua") end
    CA = CursorAura
end
M.locale = "frFR"; M.reset(); load()
local tocv = io.open("CursorAura/CursorAura.toc"):read("*a"):match("## Version: (%S+)")
ok(CA.VERSION == tocv and CA.VERSION:match("^%d+%.%d+%.%d+$") and CA.LANG == "fr", "version = .toc, et langue")
ok(CA.L.__absente == "__absente", "clé absente -> clé")
CA.Config:Init()
ok(CA.Config:Get("mode") == "aura" and CA.Config:Get("choice") == "auto", "défauts")
ok(CursorAuraCharDB.version == 1, "version DB")
CursorAuraCharDB = { mode = "trainee", choice = "feu", extra = 7 }; CA.Config:Init()
ok(CA.Config:Get("mode") == "trainee" and CA.Config:Get("choice") == "feu" and CursorAuraCharDB.extra == 7, "existant gardé")
CursorAuraCharDB = { mode = "xyz", choice = "lave" }; CA.Config:Init()
ok(CA.Config:Get("mode") == "aura" and CA.Config:Get("choice") == "auto", "invalide -> défaut")
CursorAuraCharDB = "cassé"; CA.Config:Init()
ok(type(CursorAuraCharDB) == "table" and CA.Config:Get("mode") == "aura", "DB non-table -> recréée")
ok(#CA.EFFECT_KEYS == 17 and CA.EFFECT_KEYS[14] == "protection" and CA.EFFECT_KEYS[15] == "vindicte", "17 clés d'effet, nouvelles en fin")
local r, g, b = CA.hex("#FF8000")
ok(r == 1 and math.abs(g - 128/255) < 1e-6 and b == 0, "hex")
M.locale = "esMX"; M.reset(); load(); ok(CA.LANG == "es", "esMX -> es")
M.locale = "deDE"; M.reset(); load(); ok(CA.LANG == "en", "autre -> en")
