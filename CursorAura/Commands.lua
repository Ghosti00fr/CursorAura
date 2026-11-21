-- Cursor Aura © 2026 Ghosti. All Rights Reserved.
-- ============================================================
--  Cursor Aura — Commands.lua
--  /aura : panneau, modes, effets (noms FR / EN / ES acceptés), debug.
-- ============================================================

local CA = CursorAura

local L = CA.L

-- minuscules, accents retirés (UTF-8), espaces de bord retirés
local ACCENTS = { ["é"]="e", ["è"]="e", ["ê"]="e", ["à"]="a", ["á"]="a", ["ï"]="i", ["í"]="i",
                  ["ô"]="o", ["ó"]="o", ["ù"]="u", ["û"]="u", ["ú"]="u", ["ç"]="c", ["ñ"]="n",
                  ["É"]="e", ["È"]="e", ["Ê"]="e", ["À"]="a", ["Á"]="a", ["Í"]="i", ["Ó"]="o",
                  ["Ú"]="u", ["Ç"]="c", ["Ñ"]="n", ["î"]="i", ["Î"]="i", ["Ï"]="i", ["â"]="a",
                  ["Â"]="a", ["Ô"]="o", ["Û"]="u", ["Ù"]="u", ["ü"]="u", ["Ü"]="u", ["ë"]="e", ["Ë"]="e", ["ò"]="o" }
function CA.strip(s)
    s = (s or ""):match("^%s*(.-)%s*$")
    for k, v in pairs(ACCENTS) do s = s:gsub(k, v) end
    return s:lower()
end

-- noms reconnus dans les 3 langues, quelle que soit la langue du client
local MODES = { aura = { "aura" }, trainee = { "trainee", "trail", "estela" },
                seul = { "seul", "curseur", "cursor", "solo", "curseur seul", "cursor only", "solo cursor" } }
local EFFECTS = {
    feu = { "feu", "fire", "fuego" }, givre = { "givre", "frost", "escarcha" },
    arcanes = { "arcanes", "arcane", "arcano" },
    eclairs = { "eclairs", "eclair", "lightning", "relampago", "relampagos" },
    eau = { "eau", "water", "agua" }, vent = { "vent", "wind", "viento" },
    nature = { "nature", "naturaleza" }, lumiere = { "lumiere", "light", "luz" },
    ombre = { "ombre", "shadow", "sombra" }, fumee = { "fumee", "smoke", "humo" },
    gangrene = { "gangrene", "fel", "vil" }, sang = { "sang", "blood", "sangre" },
    terre = { "terre", "earth", "tierra" },
    protection = { "protection", "proteccion" },
    vindicte = { "vindicte", "retribution", "reprension", "retribucion" },
    ["or"] = { "or", "gold", "oro" }, bourse = { "bourse", "purse", "bolsa" },
}
local PVP = { serie = { "serie", "streak", "racha" },
              rang = { "rang", "rank", "rango", "ecusson", "crest", "escudo" },
              off = { "off", "non", "no", "desactive", "desactivado" } }
local NEXT_PVP = { serie = "rang", rang = "off", off = "serie" }
local function find(map, word)
    for key, names in pairs(map) do
        for _, n in ipairs(names) do if n == word then return key end end
    end
end

local function say(msg) print("|cff66ccffCursor Aura|r " .. msg) end

CA.Commands = {}
function CA.Commands:Run(msg)
    local word = CA.strip(msg)
    if word == "" then CA.Options:Toggle(); return end
    if word == "debug" then
        local specID, index, name, classFile = CA.Specs:Current()
        say(("debug: class=%s specIndex=%s specID=%s spec=%s effect=%s mode=%s choice=%s"):format(
            tostring(classFile), tostring(index), tostring(specID), tostring(name),
            CA.Specs:Resolve(), tostring(CA.Config:Get("mode")), tostring(CA.Config:Get("choice"))))
        say(("pvp=%s streak=%s"):format(tostring(CA.Config:Get("pvp")), tostring(CA.PvP:Streak())))
        local fac, rank = CA.Crest:Faction(), CA.Crest:ReadRank()
        say(("rank: faction=%s UnitPVPRank=%s lifetimeMax=%s -> %d %s"):format(tostring(fac),
            tostring(UnitPVPRank and UnitPVPRank("player")),
            tostring(GetPVPLifetimeStats and select(2, GetPVPLifetimeStats())), rank,
            rank > 0 and fac and L["rank_" .. fac][rank] or "-"))
        say(CA.Specs:Probe())
        say(CA.Specs:ProbeTree())
        local p = CA.Specs:TabPoints()
        say("tabs: " .. (p and table.concat(p, " / ") or "nil"))
        return
    end
    local pw, arg = word:match("^(%S+)%s*(.*)$")
    if pw == "pvp" or pw == "jcj" then
        local v = find(PVP, arg)
        if not v then v = NEXT_PVP[CA.Config:Get("pvp")] or "serie" end   -- sans argument : au suivant
        CA.Config:Set("pvp", v); CA.Options:Update()
        say(L.set_pvp:format(L["pvp_" .. v])); return
    end
    local mode = find(MODES, word)
    if mode then
        CA.Config:Set("mode", mode); CA.Renderer:Refresh(); CA.Options:Update()
        say(L.set_mode:format(L["mode_" .. mode])); return
    end
    local fx = (word == "auto") and "auto" or find(EFFECTS, word)
    if fx then
        CA.Config:Set("choice", fx); CA.Renderer:Refresh(); CA.Options:Update()
        say(L.set_effect:format(fx == "auto" and L.auto or CA.Effects:Name(fx))); return
    end
    local names = {}
    for _, k in ipairs(CA.EFFECT_KEYS) do names[#names + 1] = CA.Effects:Name(k) end
    say(L.help)
    print(L.help_effects .. table.concat(names, ", "))
end

SLASH_CURSORAURA1 = "/aura"
SlashCmdList.CURSORAURA = function(msg) CA.Commands:Run(msg) end
