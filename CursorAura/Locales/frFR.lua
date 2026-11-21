-- Cursor Aura © 2026 Ghosti. All Rights Reserved.
-- ============================================================
--  Cursor Aura — Locales/frFR.lua
--  Textes en français.
-- ============================================================

local CA = CursorAura

if CA.LANG ~= "fr" then return end
local L = CA.L

L.loaded = "chargé. Tape |cffffff00/aura|r pour les réglages."

L.fx_feu, L.fx_givre, L.fx_arcanes, L.fx_eclairs, L.fx_eau = "Feu", "Givre", "Arcanes", "Éclairs", "Eau"
L.fx_vent, L.fx_nature, L.fx_lumiere, L.fx_ombre, L.fx_fumee = "Vent", "Nature", "Lumière", "Ombre", "Fumée"
L.fx_gangrene, L.fx_sang, L.fx_terre = "Gangrène", "Sang", "Terre"
L.fx_protection, L.fx_vindicte = "Protection", "Vindicte"
L.fx_or, L.fx_bourse = "Or", "Bourse"

L.mode_aura, L.mode_trainee, L.mode_seul = "Aura", "Traînée", "Curseur seul"
L.auto, L.auto_long = "Auto", "Auto (selon ta spé)"
L.label_mode, L.label_effect = "Affichage", "Effet"
L.set_mode, L.set_effect = "affichage : %s", "effet : %s"
L.help = "commandes : |cffffff00/aura|r (panneau), |cffffff00/aura aura / trainee / seul|r, |cffffff00/aura auto|r, |cffffff00/aura <effet>|r, |cffffff00/aura pvp [serie / rang / off]|r, |cffffff00/aura debug|r"
L.help_effects = "Effets : "
L.streak_up = "Série %d !"
L.label_pvp, L.pvp_serie, L.pvp_off = "PvP", "Série de victimes", "Désactivé"
L.set_pvp = "PvP : %s"
L.pvp_rang = "Écusson de rang"
L.rank_a = { "Soldat", "Caporal", "Sergent", "Sergent-chef", "Sergent-major", "Chevalier", "Chevalier-lieutenant",
             "Chevalier-capitaine", "Chevalier-champion", "Lieutenant-commandant", "Commandant", "Maréchal", "Grand maréchal", "Connétable" }
L.rank_h = { "Éclaireur", "Grunt", "Sergent", "Sergent-chef", "Adjudant", "Garde de pierre", "Garde de sang",
             "Légionnaire", "Centurion", "Champion", "Lieutenant-général", "Général", "Seigneur de guerre", "Grand seigneur de guerre" }
L.minimap_tip = "Clic : réglages. Glisser : déplacer."
