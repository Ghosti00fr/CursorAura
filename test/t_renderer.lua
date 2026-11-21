-- Tâche 5 : rendu en jeu
local M = dofile("test/mock.lua"); M.reset()
for _, f in ipairs({"Locales/enUS","Core","Effects","Specs","Particles","Renderer"}) do dofile("CursorAura/"..f..".lua") end; CA = CursorAura
CA.Config:Init(); M.classFile = "MAGE"; M.specIndex = 2; M.specs = { [2] = { 63, "Feu" } }
CA.Renderer:Init()
local f = CursorAuraFrame
ok(f.mouseEnabled == false and f.strata == "TOOLTIP", "frame : pas de souris, TOOLTIP")
CA.Renderer:Refresh(); ok(CA.Renderer.current == "feu", "mage feu -> feu")
M.cx, M.cy, M.scale = 1000, 600, 2
for i = 1, 30 do CA.Renderer:OnUpdate(1/60) end
ok(CA.Renderer.sys.count > 0, "particules émises")
local p = CA.Renderer.sys.list[1]; ok(math.abs(p.x - 500) < 40 and math.abs(p.y - 300) < 80, "position / échelle UI")
local tex = CA.Renderer.pool[1]
ok(tex.shown and tex.tex == CA.TEX .. "flame" and tex.blend == "ADD", "texture du pool appliquée")
ok(not CA.Renderer.pool[#CA.Renderer.pool].shown, "textures en trop masquées")
M.mouselook = true; CA.Renderer:OnUpdate(1/60)
ok(CA.Renderer.sys.count == 0 and not CA.Renderer.pool[1].shown and not CA.Renderer.halo.shown, "rotation caméra : tout masqué")
M.mouselook = false; CA.Renderer:OnUpdate(1/60)
ok(CA.Renderer.halo.shown, "halo revient après la rotation")
CA.Config:Set("mode", "seul"); CA.Renderer:Refresh(); CA.Renderer:OnUpdate(1/60)
ok(CA.Renderer.sys.count == 0 and CA.Renderer.halo.shown, "mode seul : halo sans particules")
CA.Config:Set("mode", "aura"); CA.Renderer:Refresh(); for i = 1, 30 do CA.Renderer:OnUpdate(1/60) end
M.specIndex = 3; M.specs[3] = { 64, "Givre" }
f.scripts.OnEvent(f, "PLAYER_SPECIALIZATION_CHANGED", "player")
ok(CA.Renderer.current == "givre" and CA.Renderer.sys.count == 0, "changement de spé : nouvel effet, anciennes particules vidées")
f.scripts.OnEvent(f, "PLAYER_SPECIALIZATION_CHANGED", "party1")
ok(CA.Renderer.current == "givre", "spé d'un autre joueur ignorée")
CA.Config:Set("choice", "eclairs"); CA.Renderer:Refresh()
for i = 1, 5 do CA.Renderer:OnUpdate(1/60) end
ok(CA.Renderer.bolts[1].shown and CA.Renderer.sys.count == 0, "éclairs : arcs visibles, pas de particules")
CA.Config:Set("choice", "ombre"); CA.Renderer:Refresh(); CA.Renderer:OnUpdate(1/60)
ok(CA.Renderer.core.shown and not CA.Renderer.halo.shown and not CA.Renderer.bolts[1].shown, "ombre : cœur noir à la place du halo")
CA.Config:Set("choice", "eau"); CA.Renderer:Refresh()
for i = 1, 50 do CA.Renderer:OnUpdate(1/60) end
ok(CA.Renderer.wave.shown, "eau : onde")
f.scripts.OnUpdate(f, 1/60); ok(true, "OnUpdate branché")
CA.Config:Set("choice", "eclairs"); CA.Renderer:Refresh()
for i = 1, 5 do CA.Renderer:OnUpdate(1/60) end
local bl = CA.Renderer.bolts[1]
ok(bl.isLine and bl.startP and bl.endP and bl.thickness == 10, "éclairs : vraies Lines (début, fin, épaisseur)")
CA.Config:Set("choice", "feu"); CA.Renderer:Refresh(); CA.Renderer:OnUpdate(1/60)
for i = 1, 120 do rawset(CA.Renderer.pool[i], "texCount", 0) end
for i = 1, 60 do CA.Renderer:OnUpdate(1/60) end
ok((rawget(CA.Renderer.pool[1], "texCount") or 0) == 0, "SetTexture seulement quand le sprite change : "..tostring(CA.Renderer.pool[1].texCount))
IsMouselooking = nil
local okc = pcall(CA.Renderer.OnUpdate, CA.Renderer, 1/60); ok(okc, "IsMouselooking absent : pas d'erreur")
ok(CursorAuraFrame.events.TRAIT_CONFIG_UPDATED and CursorAuraFrame.events.PLAYER_TALENT_UPDATE, "écoute les changements de talents")
CA.Config:Set("choice", "protection"); CA.Renderer:Refresh(); CA.Renderer:OnUpdate(1/60)
ok(CA.Renderer.coreRing.shown and CA.Renderer.halo.shown and not CA.Renderer.core.shown, "protection : anneau bouclier + halo")
CA.Config:Set("choice", "feu"); CA.Renderer:Refresh(); CA.Renderer:OnUpdate(1/60)
ok(not CA.Renderer.coreRing.shown, "anneau masqué hors protection/ombre")
CA.Config:Set("choice", "givre"); CA.Renderer:Refresh()
for i = 1, 90 do CA.Renderer:OnUpdate(1/60) end
local tw = false
for i = 1, CA.Renderer.sys.count do local p = CA.Renderer.sys.list[i]; if p.tw and p.tw < 1 then tw = true end end
ok(tw, "givre : scintillement appliqué")
ok(#CA.Renderer.pool >= 260, "plafond relevé pour les effets secondaires")
-- 0.0.11 : bug éclairs (étincelles secondaires sans alpha -> erreur Lua au rendu)
CA.Config:Set("choice", "eclairs"); CA.Renderer:Refresh()
local okRun = pcall(function() for i = 1, 120 do CA.Renderer:OnUpdate(1/60) end end)
ok(okRun and CA.Renderer.sys.count > 0, "éclairs : étincelles rendues sans erreur")
