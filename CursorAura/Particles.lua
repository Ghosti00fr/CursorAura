-- Cursor Aura © 2026 Ghosti. All Rights Reserved.
-- ============================================================
--  Cursor Aura — Particles.lua
--  Moteur de particules pur Lua (aucune API WoW) : émission,
--  mouvement, vie. Le rendu (Renderer.lua) lit sys.list.
-- ============================================================

local CA = CursorAura

local MAX_DT = 0.1
local TRAIL_STEP, TRAIL_MAX, TRAIL_DRIFT, TRAIL_JUMP = 3, 8, 24, 150
local cos, sin, sqrt, floor, min, max = math.cos, math.sin, math.sqrt, math.floor, math.min, math.max

local function lerp(a, b, t) return a + (b - a) * t end

local function pickColor(def, rng)
    local w, r = def.weights, rng()
    if w then
        local acc = 0
        for i = 1, #def.colors do acc = acc + w[i]; if r < acc then return def.colors[i] end end
        return def.colors[#def.colors]
    end
    return def.colors[min(#def.colors, floor(r * #def.colors) + 1)]
end

local Sys = {}
Sys.__index = Sys

CA.Particles = {}
function CA.Particles.New(cap)
    return setmetatable({ cap = cap, list = {}, count = 0, acc = 0 }, Sys)
end

function Sys:Clear()
    for i = self.count, 1, -1 do self.list[i] = nil end
    self.count, self.acc, self.tx, self.ty, self.facc = 0, 0, nil, nil, 0
end

function Sys:Add(p)
    if self.count >= self.cap then return false end
    self.count = self.count + 1
    self.list[self.count] = p
    return true
end

-- particule de base d'un effet, au point (x, y)
local function base(def, x, y, rng)
    local c = pickColor(def, rng)
    return { x = x, y = y, ox = x, oy = y, life = 1, decay = 1 / def.life,
             size = lerp(def.size and def.size[1] or 4, def.size and def.size[2] or 4, rng()),
             sizeGrow = def.sizeGrow or 0, r = c[1], g = c[2], b = c[3], alpha = def.alpha,
             sprite = def.sprite, blend = def.blend, rot = rng() * 6.283, rotSpeed = def.rotSpeed or 0,
             vx = 0, vy = 0, def = def }
end

-- bouffée sombre de l'ombre, près du curseur
local function darkPuff(self, d, cx, cy, rng)
    if rng() >= d.chance then return end
    local a, rr = rng() * 6.283, lerp(d.ring[1], d.ring[2], rng())
    local r, g, b = CA.hex(d.color)
    self:Add({ x = cx + cos(a) * rr, y = cy + sin(a) * rr, ox = 0, oy = 0, life = 1, decay = 1 / d.life,
               size = lerp(d.size[1], d.size[2], rng()), sizeGrow = d.sizeGrow, r = r, g = g, b = b,
               alpha = d.alpha, sprite = "puff", blend = d.blend, rot = 0, rotSpeed = 0,
               vx = 0, vy = d.vy })
end

-- une particule en mode aura, autour du curseur
local function spawnAura(self, def, cx, cy, rng)
    local a, rr = rng() * 6.283, lerp(def.ring[1], def.ring[2], rng())
    local p = base(def, cx + cos(a) * rr, cy + sin(a) * rr, rng)
    if def.spawn == "orbit" then
        p.orbit, p.ang, p.rad, p.spin, p.grow, p.minRadius = true, a, rr, def.spin, def.grow or 0, def.minRadius
    else
        p.vx, p.vy = lerp(def.vel[1], def.vel[2], rng()), lerp(def.vel[3], def.vel[4], rng())
    end
    if self:Add(p) and def.extras and def.extras.darkPuff then darkPuff(self, def.extras.darkPuff, cx, cy, rng) end
end

-- une particule en mode traînée, au point (x, y) du trajet : mouvement libre
local function spawnTrail(self, def, x, y, rng)
    local p = base(def, x, y, rng)
    if def.spawn == "orbit" then
        p.vx, p.vy = lerp(-TRAIL_DRIFT, TRAIL_DRIFT, rng()), lerp(-TRAIL_DRIFT, TRAIL_DRIFT, rng())
    else
        p.vx, p.vy = lerp(def.vel[1], def.vel[2], rng()), lerp(def.vel[3], def.vel[4], rng())
    end
    if self:Add(p) and def.extras and def.extras.darkPuff then darkPuff(self, def.extras.darkPuff, x, y, rng) end
end

-- giclée du sang : quelques gouttes projetées, retombent avec la gravité
local function splatter(self, s, cx, cy, dt, rng)
    self.splat = (self.splat or 0) + dt
    if self.splat < s.every then return end
    self.splat = 0
    local r, g, b = CA.hex(s.color)
    for _ = 1, s.n do
        local a, v = rng() * 6.283, lerp(s.speed[1], s.speed[2], rng())
        self:Add({ x = cx, y = cy, ox = cx, oy = cy, life = 1, decay = 1 / s.life,
                   size = lerp(s.size[1], s.size[2], rng()), sizeGrow = 0, r = r, g = g, b = b,
                   alpha = s.alpha, sprite = "soft", blend = "BLEND", rot = 0, rotSpeed = 0,
                   vx = cos(a) * v, vy = sin(a) * v * .6 + v * .4, gravity = s.gravity })
    end
end

-- petite particule « enfant » (traînée, éclat, poussière, fumée)
local function dot(self, x, y, vx, vy, size, life, r, g, b, alpha, blend, sprite, gravity, tag)
    local p = { x = x, y = y, ox = x, oy = y, life = 1, decay = 1 / life, size = size, sizeGrow = 0,
                r = r, g = g, b = b, alpha = alpha, sprite = sprite or "soft", blend = blend,
                rot = 0, rotSpeed = 0, vx = vx, vy = vy, gravity = gravity }
    p[tag] = true
    self:Add(p)
end

-- effet secondaire 0.0.7 : une particule qui se détache de l'aura
local function fallSpawn(self, f, def, cx, cy, rng)
    local c = def.colors[rng() < .5 and 1 or 2]
    local a = rng() * 6.283
    local p = { x = cx + cos(a) * 12, y = cy + sin(a) * 12, life = 1, decay = 1 / f.life,
                size = lerp(f.size[1], f.size[2], rng()), sizeGrow = f.sizeGrow or 0,
                r = c[1], g = c[2], b = c[3], alpha = f.alpha or def.alpha or .9, sprite = f.sprite,
                blend = f.blend or def.blend, rot = rng() * 6.283, rotSpeed = f.rotSpeed or 0,
                vx = 0, vy = 0, gravity = f.gravity, fall = f, ph = rng() * 6.283, trailT = 0, smokeT = 0 }
    p.ox, p.oy = p.x, p.y
    if f.spiral then
        p.orbit, p.ang, p.rad, p.spin, p.grow = true, a, 12, f.spiral.spin, f.spiral.grow
    elseif f.speed then
        p.vx, p.vy = cos(a) * f.speed, sin(a) * f.speed
    elseif f.horiz then
        local s = lerp(f.horiz[1], f.horiz[2], rng())
        p.vx, p.vy = rng() < .5 and -s or s, lerp(-9, 9, rng())
    else
        p.vx, p.vy = lerp(f.vel[1], f.vel[2], rng()), lerp(f.vel[3], f.vel[4], rng())
    end
    if f.bounce then p.floor = cy - f.bounce end
    if f.splash then p.splashY = cy - f.splash.depth end
    self:Add(p)
end

-- comportement par image d'une particule secondaire (y vers le haut)
local function fallStep(self, p, dt)
    local f = p.fall
    p.ph = p.ph + dt * 3
    if f.sway then p.x = p.x + sin(p.ph) * f.sway * dt; p.rot = sin(p.ph) * 1.1 end
    if f.wig then p.x = p.x + sin(p.ph * 3) * f.wig * dt end
    if f.twinkle then p.tw = .6 + .4 * sin(p.ph * 6) end
    if p.floor and p.y < p.floor and p.vy < 0 then                 -- rebond + poussière
        p.y, p.vy, p.vx, p.bounced = p.floor, -p.vy * .45, p.vx * .7, true
        for _ = 1, 3 do dot(self, p.x, p.y, (math.random() - .5) * 40, math.random() * 12, 6, .5,
                            p.r * .6, p.g * .6, p.b * .6, .35, "BLEND", "puff", nil, "dustDot") end
    end
    if p.splashY and p.y < p.splashY then                          -- éclaboussure
        p.life = 0
        for _ = 1, f.splash.n do dot(self, p.x, p.y, (math.random() - .5) * 70, 35 + math.random() * 35, 3, .45,
                                     p.r, p.g, p.b, .9, p.blend, "soft", -180, "splashDot") end
    end
    if f.burst and not p.burst and p.life < .25 then               -- éclat en fin de vie
        p.burst = true
        for _ = 1, f.burst.n do
            local a = math.random() * 6.283
            dot(self, p.x, p.y, cos(a) * f.burst.speed, sin(a) * f.burst.speed, 3, .4,
                p.r, p.g, p.b, .9, p.blend, "soft", -40, "burstDot")
        end
    end
    if f.trail then                                                -- traînée qui s'estompe
        p.trailT = p.trailT + dt
        if p.trailT >= .06 then
            p.trailT = 0
            dot(self, p.x, p.y, 0, 0, max(2, min(5, p.size * .45)), .35, p.r, p.g, p.b, .6, p.blend, "soft", nil, "trailDot")
        end
    end
    if f.smoke then                                                -- fumée derrière la goutte
        p.smokeT = p.smokeT + dt
        if p.smokeT >= f.smoke.every then
            p.smokeT = 0
            local r, g, b = CA.hex(f.smoke.color)
            dot(self, p.x, p.y, 0, 14, 9, .8, r, g, b, .35, "BLEND", "puff", nil, "smokeDot")
        end
    end
end

function Sys:Emit(def, mode, cx, cy, px, py, dt, rng)
    rng = rng or math.random
    if mode == "seul" then return end
    dt = min(dt, MAX_DT)
    local f = def.extras and def.extras.fall
    if f then
        self.facc = (self.facc or 0) + f.rate * dt
        while self.facc >= 1 do self.facc = self.facc - 1; fallSpawn(self, f, def, cx, cy, rng) end
    end
    if not def.sprite or (def.rate or 0) <= 0 then return end
    if mode == "aura" then
        self.acc = self.acc + def.rate * dt
        while self.acc >= 1 do
            self.acc = self.acc - 1
            spawnAura(self, def, cx, cy, rng)
        end
        if def.extras and def.extras.splatter then splatter(self, def.extras.splatter, cx, cy, dt, rng) end
    elseif mode == "trainee" then
        -- la distance s'accumule depuis le dernier point d'émission (souris lente, fps élevé)
        local tx, ty = self.tx or px, self.ty or py
        local dx, dy = cx - tx, cy - ty
        local dist = sqrt(dx * dx + dy * dy)
        if dist > TRAIL_JUMP then self.tx, self.ty = cx, cy; return end   -- saut (alt-tab, Alt+Z)
        local n = floor(dist / TRAIL_STEP)
        if n == 0 then self.tx, self.ty = tx, ty; return end
        local ux, uy = dx / dist * TRAIL_STEP, dy / dist * TRAIL_STEP
        for i = 0, min(n, TRAIL_MAX) - 1 do spawnTrail(self, def, tx + ux * i, ty + uy * i, rng) end
        if n > TRAIL_MAX then self.tx, self.ty = cx, cy
        else self.tx, self.ty = tx + ux * n, ty + uy * n end
    end
end

function Sys:Step(dt, cx, cy)
    dt = min(dt, MAX_DT)
    local list, i = self.list, 1
    while i <= self.count do
        local p = list[i]
        p.life = p.life - dt * p.decay
        p.ox, p.oy = p.x, p.y
        if p.orbit then
            p.ang = p.ang + p.spin * dt
            p.rad = p.rad + p.grow * dt
            p.x, p.y = cx + cos(p.ang) * p.rad, cy + sin(p.ang) * p.rad
        else
            if p.gravity then p.vy = p.vy + p.gravity * dt end
            p.x, p.y = p.x + p.vx * dt, p.y + p.vy * dt
        end
        p.rot = p.rot + p.rotSpeed * dt
        if p.fall then fallStep(self, p, dt) end
        if p.ps then p.ph = p.ph + p.ps * dt end                       -- pièce qui tourne sur elle-même
        if p.floors then                                               -- marches de la cascade (y vers le haut)
            local fl = p.floors[p.bn + 1]
            if fl and p.y < fl and p.vy < 0 then
                p.y, p.vy = fl, -p.vy * (.35 + math.random() * .15)
                p.vx, p.bn = (p.vx + (math.random() - .5) * 80) * 1.1, p.bn + 1
            end
        end
        p.size = max(1, p.size + p.sizeGrow * dt)
        if p.life <= 0 or (p.minRadius and p.rad < p.minRadius) then
            list[i] = list[self.count]
            list[self.count] = nil
            self.count = self.count - 1
        else
            i = i + 1
        end
    end
end
