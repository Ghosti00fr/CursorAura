-- Cursor Aura © 2026 Ghosti. All Rights Reserved.
-- ============================================================
--  Cursor Aura — Specs.lua
--  Spé active -> effet. specID Retail, à confirmer sur Forever
--  avec /aura debug ; repli sur l'effet par défaut de la classe.
-- ============================================================

local CA = CursorAura

CA.Specs = {
    SPEC_EFFECT = {
        [71] = "sang", [72] = "feu", [73] = "terre",                    -- Guerrier
        [65] = "lumiere", [66] = "protection", [70] = "vindicte",       -- Paladin
        [253] = "nature", [254] = "vent", [255] = "terre",              -- Chasseur
        [259] = "fumee", [260] = "fumee", [261] = "fumee",              -- Voleur
        [256] = "lumiere", [257] = "lumiere", [258] = "ombre",          -- Prêtre
        [262] = "eclairs", [263] = "vent", [264] = "eau",               -- Chaman
        [62] = "arcanes", [63] = "feu", [64] = "givre",                 -- Mage
        [265] = "ombre", [266] = "gangrene", [267] = "feu",             -- Démoniste
        [102] = "arcanes", [103] = "nature", [104] = "terre", [105] = "nature", -- Druide
    },
    CLASS_DEFAULT = {
        WARRIOR = "sang", PALADIN = "lumiere", HUNTER = "nature", ROGUE = "fumee",
        PRIEST = "lumiere", SHAMAN = "eclairs", MAGE = "arcanes", WARLOCK = "ombre", DRUID = "nature",
    },
}
local Specs = CA.Specs

-- specID, index, nom de la spé (nil si inconnus), classFile
function Specs:Current()
    local _, classFile = UnitClass("player")
    local api = C_SpecializationInfo
    local index = api and api.GetSpecialization and api.GetSpecialization() or nil
    local specID, name
    if index and api.GetSpecializationInfo then specID, name = api.GetSpecializationInfo(index) end
    return specID, index, name, classFile
end

-- Sondage pour /aura debug : sur Forever, la spé est unique par classe ;
-- la vraie spé (Givre…) se trouve peut-être dans un sous-arbre de talents.
function Specs:Probe()
    local ok, out = pcall(function()
        local ct, tr = C_ClassTalents, C_Traits
        if not ct then return "talents: no C_ClassTalents" end
        local cfg = ct.GetActiveConfigID and ct.GetActiveConfigID()
        local hero = ct.GetActiveHeroTalentSpec and ct.GetActiveHeroTalentSpec()
        local parts = { "talents: cfg=" .. tostring(cfg), "hero=" .. tostring(hero) }
        local ids = ct.GetHeroTalentSpecsForClassSpec and ct.GetHeroTalentSpecsForClassSpec(cfg, (self:Current())) or {}
        for _, id in ipairs(ids) do
            local i = tr and tr.GetSubTreeInfo and tr.GetSubTreeInfo(cfg, id)
            parts[#parts + 1] = id .. ":" .. tostring(i and i.name) .. ((i and i.isActive) and "*" or "")
        end
        return table.concat(parts, " ")
    end)
    return ok and out or ("talents: error " .. tostring(out))
end

-- Sondage de l'arbre : points par devise (branche ?), talents achetés
-- par sous-arbre, et les 10 premiers noms de sorts achetés.
function Specs:ProbeTree()
    local ok, out = pcall(function()
        local ct, tr = C_ClassTalents, C_Traits
        if not (ct and tr and ct.GetTraitTreeForSpec) then return "tree: no API" end
        local cfg, tree = ct.GetActiveConfigID(), ct.GetTraitTreeForSpec((self:Current()) or 0)
        local parts = { "tree=" .. tostring(tree) }
        if not (cfg and tree) then return table.concat(parts, " ") end
        for _, c in ipairs(tr.GetTreeCurrencyInfo(cfg, tree, false) or {}) do
            parts[#parts + 1] = ("cur%s=%s/%s"):format(tostring(c.traitCurrencyID), tostring(c.spent), tostring(c.maxQuantity))
        end
        local bought, subs, names = 0, {}, {}
        for _, n in ipairs(tr.GetTreeNodes(tree) or {}) do
            local i = tr.GetNodeInfo(cfg, n)
            if i and (i.ranksPurchased or 0) > 0 then
                bought = bought + 1
                if i.subTreeID then subs[i.subTreeID] = (subs[i.subTreeID] or 0) + 1 end
                local e = i.activeEntry and tr.GetEntryInfo(cfg, i.activeEntry.entryID)
                local d = e and e.definitionID and tr.GetDefinitionInfo(e.definitionID)
                if d and d.spellID and #names < 10 and C_Spell then names[#names + 1] = tostring(C_Spell.GetSpellName(d.spellID)) end
            end
        end
        parts[#parts + 1] = "bought=" .. bought
        for id, k in pairs(subs) do parts[#parts + 1] = "sub" .. id .. "=" .. k end
        parts[#parts + 1] = "spells: " .. table.concat(names, ", ")
        return table.concat(parts, " ")
    end)
    return ok and out or ("tree: error " .. tostring(out))
end

-- Forever : une seule « spé » par classe, mais un arbre à 3 onglets façon
-- Classic (ex. Mage : Arcane / Feu / Givre), de gauche à droite.
Specs.TAB_EFFECT = {
    WARRIOR = { "sang", "feu", "terre" },        PALADIN = { "lumiere", "protection", "vindicte" },
    HUNTER  = { "nature", "vent", "terre" },     ROGUE   = { "fumee", "fumee", "fumee" },
    PRIEST  = { "lumiere", "lumiere", "ombre" }, SHAMAN  = { "eclairs", "vent", "eau" },
    MAGE    = { "arcanes", "feu", "givre" },     WARLOCK = { "ombre", "gangrene", "feu" },
    DRUID   = { "arcanes", "nature", "nature" },
}

-- Points dépensés par onglet {o1, o2, o3}, ou nil. Les onglets sont trouvés
-- en coupant les posX des nœuds aux deux plus grands écarts.
function Specs:TabPoints()
    local ok, pts = pcall(function()
        local ct, tr = C_ClassTalents, C_Traits
        if not (ct and tr and ct.GetTraitTreeForSpec and tr.GetTreeNodes) then return end
        local cfg, tree = ct.GetActiveConfigID(), ct.GetTraitTreeForSpec((self:Current()) or 0)
        if not (cfg and tree) then return end
        local infos, xs = {}, {}
        for _, n in ipairs(tr.GetTreeNodes(tree) or {}) do
            local i = tr.GetNodeInfo(cfg, n)
            if i and i.posX then infos[#infos + 1] = i; xs[#xs + 1] = i.posX end
        end
        if #xs < 3 then return end
        table.sort(xs)
        local g1, g2 = { gap = -1 }, { gap = -1 }   -- deux plus grands écarts
        for k = 2, #xs do
            local gap = xs[k] - xs[k - 1]
            if gap > g1.gap then g2 = g1; g1 = { gap = gap, at = xs[k] }
            elseif gap > g2.gap then g2 = { gap = gap, at = xs[k] } end
        end
        local c1, c2 = math.min(g1.at, g2.at), math.max(g1.at, g2.at)
        local p = { 0, 0, 0 }
        for _, i in ipairs(infos) do
            local tab = (i.posX < c1) and 1 or (i.posX < c2) and 2 or 3
            p[tab] = p[tab] + (i.ranksPurchased or 0)
        end
        return p
    end)
    return ok and pts or nil
end

-- onglet strictement majoritaire, sinon nil
local function topTab(p)
    if not p then return end
    local best, n = 1, 0
    for k = 2, 3 do if p[k] > p[best] then best = k end end
    for k = 1, 3 do if p[k] == p[best] then n = n + 1 end end
    if p[best] > 0 and n == 1 then return best end
end

function Specs:Resolve()
    local choice = CA.Config:Get("choice")
    if choice and choice ~= "auto" and CA.IS_EFFECT[choice] then return choice end
    local specID, _, _, classFile = self:Current()
    local tab = topTab(self:TabPoints())
    local byTab = tab and self.TAB_EFFECT[classFile] and self.TAB_EFFECT[classFile][tab]
    return byTab or (specID and self.SPEC_EFFECT[specID]) or self.CLASS_DEFAULT[classFile] or "arcanes"
end
