-- Tâche 3 : moteur de particules
local M = dofile("test/mock.lua"); M.reset()
for _, f in ipairs({"Locales/enUS","Core","Effects","Particles"}) do dofile("CursorAura/"..f..".lua") end; CA = CursorAura
local seq = 0; local function rng() seq = (seq * 7 + 3) % 10; return seq / 10 end
local D = CA.Effects.defs
local s = CA.Particles.New(120)
for i = 1, 60 do s:Emit(D.feu, "aura", 500, 300, 500, 300, 1/60, rng); s:Step(1/60, 500, 300) end
ok(s.count > 40 and s.count <= 120, "feu : flux continu sous plafond ("..s.count..")")
local p = s.list[1]; ok(p.y > 300 - 14, "feu monte")
s:Clear(); ok(s.count == 0, "Clear")
s:Emit(D.feu, "aura", 0, 0, 0, 0, 2.0, rng); ok(s.count <= math.floor(D.feu.rate * 0.1) + 1, "dt borné à 0,1 s ("..s.count..")")
s:Clear(); for i = 1, 200 do s:Emit(D.gangrene, "aura", 0, 0, 0, 0, 0.1, rng) end
ok(s.count == 120, "plafond 120")
s:Clear(); s:Emit(D.arcanes, "aura", 100, 100, 100, 100, 0.1, rng)
s:Step(0.01, 400, 400); local q = s.list[1]
local d = math.sqrt((q.x-400)^2 + (q.y-400)^2); ok(d >= 13 and d <= 21, "orbite suit le curseur")
s:Clear(); s:Emit(D.ombre, "aura", 0, 0, 0, 0, 0.1, rng)
local n0 = s.count; for i = 1, 18 do s:Step(1/60, 0, 0) end
for _, t in ipairs(s.list) do if t.sprite == "streak" then ok(math.sqrt(t.x^2 + t.y^2) < 25, "tendril aspiré vers le centre") end end
for i = 1, 42 do s:Step(1/60, 0, 0) end
local dark = 0; for _, t in ipairs(s.list) do if t.sprite ~= "puff" then dark = dark + 1 end end
ok(n0 > 0 and dark == 0, "ombre : tendrils tous morts en 1 s")
s:Clear(); s:Emit(D.ombre, "aura", 0, 0, 0, 0, 0.1, rng)
local puffs = 0; for _, t in ipairs(s.list) do if t.sprite == "puff" and t.blend == "BLEND" then puffs = puffs + 1 end end
ok(puffs > 0, "ombre : bouffées sombres BLEND")
s:Clear(); s:Emit(D.eclairs, "aura", 0, 0, 0, 0, 0.1, rng); ok(s.count == 0, "éclairs : pas de particules")
s:Clear(); s:Emit(D.feu, "trainee", 30, 0, 0, 0, 1/60, rng); ok(s.count == 8, "traînée : 8 max sur 30 px")
s:Clear(); s:Emit(D.feu, "trainee", 0, 0, 0, 0, 1/60, rng); ok(s.count == 0, "traînée immobile : rien")
s:Clear(); s:Emit(D.arcanes, "trainee", 30, 0, 0, 0, 1/60, rng)
s:Step(0.1, 500, 500); ok(s.list[1].x < 100, "traînée : orbite devenue libre (ne suit plus)")
s:Clear(); s:Emit(D.feu, "seul", 0, 0, 50, 50, 1/60, rng); ok(s.count == 0, "seul : rien")
s:Clear(); for i = 1, 10 do s:Emit(D.feu, "aura", 0, 0, 0, 0, 1/60, rng) end
for i = 1, 150 do s:Step(1/60, 0, 0) end; ok(s.count == 0, "mortes après life (effets secondaires compris)")
s:Clear(); local x = 0
for i = 1, 10 do s:Emit(D.feu, "trainee", x + 1, 0, x, 0, 1/144, rng); x = x + 1 end
ok(s.count == 3, "traînée lente : la distance s'accumule (10 px -> 3) : "..s.count)
-- 0.0.6 : sang plus sanglant, intensité renforcée
ok(D.feu.rate >= 140 * 1.6 and D.feu.size[2] > 12, "intensité renforcée (feu)")
ok(D.sang.blend == "BLEND" and D.sang.sprite == "drop" and D.sang.vel[4] < 0, "sang : gouttes opaques qui tombent")
s = CA.Particles.New(400); for i = 1, 30 do s:Emit(D.sang, "aura", 0, 0, 0, 0, 1/60, rng); s:Step(1/60, 0, 0) end
local drops, dark, splat = 0, 0, 0
for _, t in ipairs(s.list) do
    if t.sprite == "drop" and t.vy < 0 then drops = drops + 1 end
    if t.sprite == "puff" and t.blend == "BLEND" then dark = dark + 1 end
    if t.gravity then splat = splat + 1 end
end
ok(drops > 0 and dark > 0, "sang : gouttes + taches sombres ("..drops.."/"..dark..")")
s:Clear(); for i = 1, 60 do s:Emit(D.sang, "aura", 0, 0, 0, 0, 1/60, rng); s:Step(1/60, 0, 0) end
splat = 0; for _, t in ipairs(s.list) do if t.gravity then splat = splat + 1 end end
ok(splat > 0, "sang : giclées avec gravité ("..splat..")")
local g = { x = 0, y = 0, ox = 0, oy = 0, life = 1, decay = 0, size = 4, sizeGrow = 0, rot = 0, rotSpeed = 0, vx = 0, vy = 50, gravity = -200 }
s:Clear(); s:Add(g); s:Step(0.1, 0, 0); ok(g.vy < 50, "gravité ralentit la montée")
ok(D.protection.colors[2][3] > D.protection.colors[2][1] and D.protection.extras.shield, "protection : bleu + bouclier")
ok(D.vindicte.colors[2][1] > D.vindicte.colors[2][3] and D.vindicte.vel[3] > 0, "vindicte : rouge, monte")
-- 0.0.7 : effets secondaires (particules qui se détachent)
local lcg = 12345; local function rnd() lcg = (lcg * 1103515245 + 12345) % 2147483648; return lcg / 2147483648 end
for _, k in ipairs(CA.EFFECT_KEYS) do
    if k ~= "sang" and not D[k].bank then ok(D[k].extras and D[k].extras.fall, "effet secondaire : " .. k) end
end
local function run(key, secs, sys)
    sys = sys or CA.Particles.New(400)
    for i = 1, math.floor(secs * 60) do sys:Emit(D[key], "aura", 0, 0, 0, 0, 1/60, rnd); sys:Step(1/60, 0, 0) end
    return sys
end
local function count(sys, f) local n = 0; for _, t in ipairs(sys.list) do if f(t) then n = n + 1 end end; return n end
s = run("nature", 2)
ok(count(s, function(t) return t.fall and t.sprite == "leaf" and t.y < -12 end) > 0, "nature : feuilles qui tombent")
ok(count(s, function(t) return t.trailDot end) > 0, "nature : traînée")
s = run("givre", 1.5); ok(count(s, function(t) return t.fall and t.tw and t.tw < 1 end) > 0, "givre : scintille")
s = run("eclairs", 1); ok(count(s, function(t) return t.fall end) > 0, "éclairs : étincelles malgré rate 0")
s = run("terre", 2); ok(count(s, function(t) return t.fall and t.bounced end) > 0, "terre : cailloux qui rebondissent")
s = run("eau", 2); ok(count(s, function(t) return t.splashDot end) > 0, "eau : éclaboussures")
s = run("feu", 2); ok(count(s, function(t) return t.burstDot end) > 0, "feu : braises qui éclatent")
s = run("gangrene", 2); ok(count(s, function(t) return t.smokeDot end) > 0, "gangrène : fume")
s = run("arcanes", 1); ok(count(s, function(t) return t.fall and t.orbit end) > 0, "arcanes : spirale")
s = CA.Particles.New(400); for i = 1, 60 do s:Emit(D.nature, "seul", 0, 0, 0, 0, 1/60, rnd) end
ok(s.count == 0, "seul : pas d'effet secondaire")
