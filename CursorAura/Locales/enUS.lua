-- Cursor Aura © 2026 Ghosti. All Rights Reserved.
-- ============================================================
--  Cursor Aura — Locales/enUS.lua
--  Langue de base (anglais) et repli pour toute clé absente.
-- ============================================================

CursorAura = CursorAura or {}
local CA = CursorAura
local loc = GetLocale and GetLocale() or "enUS"
CA.LANG = (loc == "frFR") and "fr" or ((loc == "esES" or loc == "esMX") and "es" or "en")

-- clé absente -> la clé elle-même (visible, jamais d'erreur)
CA.L = setmetatable({}, { __index = function(_, k) return k end })
local L = CA.L

L.loaded = "loaded. Type |cffffff00/aura|r for options."

L.fx_feu, L.fx_givre, L.fx_arcanes, L.fx_eclairs, L.fx_eau = "Fire", "Frost", "Arcane", "Lightning", "Water"
L.fx_vent, L.fx_nature, L.fx_lumiere, L.fx_ombre, L.fx_fumee = "Wind", "Nature", "Light", "Shadow", "Smoke"
L.fx_gangrene, L.fx_sang, L.fx_terre = "Fel", "Blood", "Earth"
L.fx_protection, L.fx_vindicte = "Protection", "Retribution"
L.fx_or, L.fx_bourse = "Gold", "Purse"

L.mode_aura, L.mode_trainee, L.mode_seul = "Aura", "Trail", "Cursor only"
L.auto, L.auto_long = "Auto", "Auto (from your specialization)"
L.label_mode, L.label_effect = "Display", "Effect"
L.set_mode, L.set_effect = "display: %s", "effect: %s"
L.help = "commands: |cffffff00/aura|r (panel), |cffffff00/aura aura / trail / cursor|r, |cffffff00/aura auto|r, |cffffff00/aura <effect>|r, |cffffff00/aura pvp [streak / rank / off]|r, |cffffff00/aura debug|r"
L.help_effects = "Effects: "
L.streak_up = "Streak %d!"
L.label_pvp, L.pvp_serie, L.pvp_off = "PvP", "Kill streak", "Off"
L.set_pvp = "PvP: %s"
L.pvp_rang = "Rank crest"
L.rank_a = { "Private", "Corporal", "Sergeant", "Master Sergeant", "Sergeant Major", "Knight", "Knight-Lieutenant",
             "Knight-Captain", "Knight-Champion", "Lieutenant Commander", "Commander", "Marshal", "Field Marshal", "Grand Marshal" }
L.rank_h = { "Scout", "Grunt", "Sergeant", "Senior Sergeant", "First Sergeant", "Stone Guard", "Blood Guard",
             "Legionnaire", "Centurion", "Champion", "Lieutenant General", "General", "Warlord", "High Warlord" }
L.minimap_tip = "Click: settings. Drag: move."
