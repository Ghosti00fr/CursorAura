-- Cursor Aura © 2026 Ghosti. All Rights Reserved.
-- ============================================================
--  Cursor Aura — Options.lua
--  Petit panneau maison (pas d'API Settings ni de menu déroulant) :
--  mode, Auto / effet manuel. Échap le ferme.
-- ============================================================

local CA = CursorAura

local L = CA.L
CA.Options = { modeButtons = {}, effectButtons = {}, pvpButtons = {} }
local O = CA.Options

local function button(parent, text, w, x, y, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, 22)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    b:SetText(text)
    b.sel = b:CreateTexture(nil, "BACKGROUND")
    b.sel:SetColorTexture(1, .82, 0, .7)
    b.sel:SetPoint("TOPLEFT", -3, 3)
    b.sel:SetPoint("BOTTOMRIGHT", 3, -3)
    b.sel:Hide()
    b:SetScript("OnClick", onClick)
    return b
end

local function apply(key, value)
    CA.Config:Set(key, value)
    CA.Renderer:Refresh()
    O:Update()
end

function O:Build()
    local p = CreateFrame("Frame", "CursorAuraOptions", UIParent)
    p:SetSize(440, 346)
    p:SetPoint("CENTER")
    p:SetFrameStrata("DIALOG")
    p:EnableMouse(true)
    p:SetMovable(true)
    p:RegisterForDrag("LeftButton")
    p:SetScript("OnDragStart", p.StartMoving)
    p:SetScript("OnDragStop", p.StopMovingOrSizing)
    local bg = p:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(.06, .07, .09, .92)
    local title = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Cursor Aura")
    local close = CreateFrame("Button", nil, p, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)

    local lm = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lm:SetPoint("TOPLEFT", 16, -40); lm:SetText(L.label_mode)
    for i, m in ipairs({ "aura", "trainee", "seul" }) do
        self.modeButtons[m] = button(p, L["mode_" .. m], 120, 16 + (i - 1) * 136, -58,
            function() apply("mode", m) end)
    end

    local le = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    le:SetPoint("TOPLEFT", 16, -92); le:SetText(L.label_effect)
    self.autoButton = button(p, L.auto_long, 200, 16, -110, function() apply("choice", "auto") end)
    for i, k in ipairs(CA.EFFECT_KEYS) do
        local col, row = (i - 1) % 4, math.floor((i - 1) / 4)
        self.effectButtons[k] = button(p, CA.Effects:Name(k), 98, 16 + col * 104, -140 - row * 26,
            function() apply("choice", k) end)
    end
    local lp = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lp:SetPoint("TOPLEFT", 16, -280); lp:SetText(L.label_pvp)
    for i, v in ipairs({ "serie", "rang", "off" }) do
        self.pvpButtons[v] = button(p, L["pvp_" .. v], 130, 16 + (i - 1) * 136, -298,
            function() apply("pvp", v) end)
    end
    tinsert(UISpecialFrames, "CursorAuraOptions")
    p:Hide()
    self.panel = p
end

function O:Update()
    if not self.panel then return end
    local mode, choice = CA.Config:Get("mode"), CA.Config:Get("choice")
    for m, b in pairs(self.modeButtons) do b.sel:SetShown(m == mode) end
    for k, b in pairs(self.effectButtons) do b.sel:SetShown(k == choice) end
    self.autoButton.sel:SetShown(choice == "auto")
    for v, b in pairs(self.pvpButtons) do b.sel:SetShown(v == CA.Config:Get("pvp")) end
end

function O:Toggle()
    if not self.panel then self:Build() end
    if self.panel:IsShown() then self.panel:Hide() else self:Update(); self.panel:Show() end
end
