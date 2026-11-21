-- Cursor Aura © 2026 Ghosti. All Rights Reserved.
-- ============================================================
--  Cursor Aura — Core.lua
--  Espace de noms, réglages par personnage, utilitaires.
-- ============================================================

local CA = CursorAura
CA.VERSION    = "0.0.11"
CA.DB_VERSION = 1
CA.PATH       = "Interface\\AddOns\\CursorAura\\"
CA.TEX        = CA.PATH .. "textures\\"

-- les 17 effets, dans l'ordre d'affichage (nouveaux toujours en fin)
CA.EFFECT_KEYS = { "feu", "givre", "arcanes", "eclairs", "eau", "vent", "nature",
                   "lumiere", "ombre", "fumee", "gangrene", "sang", "terre", "protection", "vindicte",
                   "or", "bourse" }
local IS_EFFECT = {}
for _, k in ipairs(CA.EFFECT_KEYS) do IS_EFFECT[k] = true end
CA.IS_EFFECT = IS_EFFECT

-- "#RRGGBB" -> r, g, b (0..1)
function CA.hex(s)
    local r, g, b = s:match("#?(%x%x)(%x%x)(%x%x)")
    return tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255
end

-- ---- Réglages (SavedVariablesPerCharacter : CursorAuraCharDB) ----
CA.Config = {
    defaults = { mode = "aura", choice = "auto", pvp = "serie", minimapAngle = 225 },
    validators = {
        mode   = function(v) return v == "aura" or v == "trainee" or v == "seul" end,
        choice = function(v) return v == "auto" or IS_EFFECT[v] == true end,
        pvp    = function(v) return v == "serie" or v == "rang" or v == "off" end,
        minimapAngle = function(v) return type(v) == "number" and v == v and v >= -360 and v <= 360 end,
    },
}
local Config = CA.Config

-- migrations futures : une étape par version, jamais de renommage brutal
function Config:Migrate(db)
    db.version = db.version or CA.DB_VERSION
end

function Config:Init()
    if type(CursorAuraCharDB) ~= "table" then CursorAuraCharDB = {} end
    local db = CursorAuraCharDB
    for k, v in pairs(self.defaults) do
        if db[k] == nil or not self.validators[k](db[k]) then db[k] = v end
    end
    if type(db.streak) ~= "number" or db.streak < 0 then db.streak = 0 end   -- série PvP en cours
    self:Migrate(db)
    self.db = db
end
function Config:Get(k) return self.db and self.db[k] end
function Config:Set(k, v) if self.db then self.db[k] = v end end
