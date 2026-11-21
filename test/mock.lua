-- Mock de l'API WoW pour les tests hors jeu de Cursor Aura.
-- Usage : local M = dofile("test/mock.lua") ; M.locale = "frFR" ; M.reset()
local M = { locale = "frFR" }

local rawprint = print
function ok(c, m) rawprint((c and "OK  " or "FAIL") .. "  " .. m); if not c then os.exit(1) end end

-- ---- Cadres -------------------------------------------------
local function stub()
    local t = { shown = true, scripts = {}, events = {} }
    setmetatable(t, { __index = function() return function() end end })
    function t:Show() self.shown = true end
    function t:Hide() self.shown = false end
    function t:IsShown() return self.shown end
    function t:SetShown(v) self.shown = v and true or false end
    function t:SetScript(n, fn) self.scripts[n] = fn end
    function t:GetScript(n) return self.scripts[n] end
    function t:RegisterEvent(e) self.events[e] = true end
    function t:RegisterUnitEvent(e) self.events[e] = true end
    function t:EnableMouse(v) self.mouseEnabled = v and true or false end
    function t:SetFrameStrata(s) self.strata = s end
    function t:CreateTexture() return stub() end
    function t:CreateFontString() local fs = stub(); function fs:SetText(s) self.txt = s end; function fs:GetText() return self.txt end; return fs end
    function t:SetTexture(p) self.tex = p; self.texCount = (rawget(self, "texCount") or 0) + 1 end
    function t:CreateLine() local l = stub(); l.isLine = true
        function l:SetStartPoint(...) self.startP = { ... } end
        function l:SetEndPoint(...) self.endP = { ... } end
        function l:SetThickness(v) self.thickness = v end
        function l:SetRotation() error("SetRotation sur une Line") end
        return l end
    function t:SetVertexColor(r, g, b, a) self.color = { r, g, b, a } end
    function t:SetBlendMode(m) self.blend = m end
    function t:SetAlpha(a) self.alpha = a end
    function t:SetRotation(r) self.rot = r end
    function t:SetSize(w, h) self.w, self.h = w, h end
    function t:SetPoint(...) self.point = { ... } end
    function t:ClearAllPoints() self.point = nil end
    function t:GetEffectiveScale() return M.scale or 1 end
    return t
end
M.stub = stub

UIParent = stub()
CreateFrame = function(kind, name, parent, template)
    local f = stub(); f.name, f.parent = name, parent
    if name then _G[name] = f end
    return f
end
GetLocale = function() return M.locale end
GetCursorPosition = function() return M.cx or 0, M.cy or 0 end
MOCK_ISMOUSELOOKING = function() return M.mouselook and true or false end
GetTime = function() return M.now or 0 end
UnitClass = function(u) return M.className or M.classFile, M.classFile end
SlashCmdList, UISpecialFrames = {}, {}
tinsert = table.insert
print = function(...)
    local t = {}
    for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end
    M.printed[#M.printed + 1] = table.concat(t, " ")
end

local specAPI = {
    GetSpecialization = function() return M.specIndex end,
    GetSpecializationInfo = function(i)
        local s = M.specs and M.specs[i]
        if s then return s[1], s[2] end
    end,
}

function M.reset()
    M.now, M.cx, M.cy, M.scale, M.mouselook = 0, 0, 0, 1, false
    M.printed = {}
    M.classFile, M.className = "MAGE", nil
    M.specIndex, M.specs = nil, {}
    C_SpecializationInfo = (not M.noSpecAPI) and specAPI or nil
    UISpecialFrames = {}
    IsMouselooking = MOCK_ISMOUSELOOKING
    CursorAuraCharDB = nil
    CursorAuraFrame, CursorAuraOptions = nil, nil
    CA, CursorAura = nil, nil
end

return M
