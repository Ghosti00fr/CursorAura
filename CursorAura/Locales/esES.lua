-- Cursor Aura © 2026 Ghosti. All Rights Reserved.
-- ============================================================
--  Cursor Aura — Locales/esES.lua
--  Textos en español (esES y esMX).
-- ============================================================

local CA = CursorAura

if CA.LANG ~= "es" then return end
local L = CA.L

L.loaded = "cargado. Escribe |cffffff00/aura|r para las opciones."

L.fx_feu, L.fx_givre, L.fx_arcanes, L.fx_eclairs, L.fx_eau = "Fuego", "Escarcha", "Arcano", "Relámpago", "Agua"
L.fx_vent, L.fx_nature, L.fx_lumiere, L.fx_ombre, L.fx_fumee = "Viento", "Naturaleza", "Luz", "Sombra", "Humo"
L.fx_gangrene, L.fx_sang, L.fx_terre = "Vil", "Sangre", "Tierra"
L.fx_protection, L.fx_vindicte = "Protección", "Reprensión"
L.fx_or, L.fx_bourse = "Oro", "Bolsa"

L.mode_aura, L.mode_trainee, L.mode_seul = "Aura", "Estela", "Solo cursor"
L.auto, L.auto_long = "Auto", "Auto (según tu especialización)"
L.label_mode, L.label_effect = "Visualización", "Efecto"
L.set_mode, L.set_effect = "visualización: %s", "efecto: %s"
L.help = "comandos: |cffffff00/aura|r (panel), |cffffff00/aura aura / estela / solo|r, |cffffff00/aura auto|r, |cffffff00/aura <efecto>|r, |cffffff00/aura pvp [streak / rank / off]|r, |cffffff00/aura debug|r"
L.help_effects = "Efectos: "
L.streak_up = "¡Racha %d!"
L.label_pvp, L.pvp_serie, L.pvp_off = "JcJ", "Racha de muertes", "Desactivado"
L.set_pvp = "JcJ: %s"
L.pvp_rang = "Escudo de rango"
L.rank_a = { "Soldado", "Cabo", "Sargento", "Sargento maestro", "Sargento mayor", "Caballero", "Caballero teniente",
             "Caballero capitán", "Caballero campeón", "Teniente coronel", "Comandante", "Mariscal", "Mariscal de campo", "Gran mariscal" }
L.rank_h = { "Explorador", "Bruto", "Sargento", "Sargento primero", "Sargento mayor", "Guardia de piedra", "Guardia de sangre",
             "Legionario", "Centurión", "Campeón", "Teniente general", "General", "Señor de la guerra", "Gran señor de la guerra" }
L.minimap_tip = "Clic: ajustes. Arrastrar: mover."
