-- Cursor Aura © 2026 Ghosti. All Rights Reserved.
-- ============================================================
--  Cursor Aura — Minimap.lua
--  Icône sur le bord de la minimap (sans bibliothèque). Visible en
--  fondu seulement quand la souris est sur la minimap. Clic : réglages.
--  Glisser : la déplacer autour de la minimap (angle par personnage).
-- ============================================================

local CA = CursorAura
if not Minimap then return end
local L = CA.L

local b = CreateFrame("Button", "CursorAuraMinimapButton", Minimap)
b:SetSize(31, 31)
b:SetFrameStrata("MEDIUM")
b:SetFrameLevel(8)
b:RegisterForClicks("AnyUp")
b:RegisterForDrag("LeftButton")
b.icon = b:CreateTexture(nil, "ARTWORK")
b.icon:SetTexture(CA.TEX .. "bank\\minimap")
b.icon:SetAllPoints()
b.alpha, b.dragging, b.placed = 0, false, false
b:SetAlpha(0)
b:EnableMouse(false)
CA.MinimapButton = b

local function angle() return CA.Config:Get("minimapAngle") or 225 end

function b:Place()
    local a = math.rad(angle())
    local r = (Minimap:GetWidth() or 140) / 2 + 10
    self:ClearAllPoints()
    self:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
end

b:SetScript("OnClick", function() CA.Options:Toggle() end)
b:SetScript("OnDragStart", function(self) self.dragging = true end)
b:SetScript("OnDragStop", function(self) self.dragging = false; self:Place() end)
b:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Cursor Aura")
    GameTooltip:AddLine(L.minimap_tip, 1, 1, 1)
    GameTooltip:Show()
end)
b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

b:SetScript("OnUpdate", function(self, dt)
    if not CA.Config.db then return end
    if self.dragging then
        local mx, my = Minimap:GetCenter()
        local s = Minimap:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        CA.Config:Set("minimapAngle", math.deg(math.atan2(cy / s - my, cx / s - mx)))
        self:Place()
    elseif not self.placed then
        self:Place(); self.placed = true
    end
    local over = Minimap:IsMouseOver() or self:IsMouseOver() or self.dragging
    local a = math.max(0, math.min(1, self.alpha + (over and 5 or -5) * dt))
    if a ~= self.alpha then
        self.alpha = a
        self:SetAlpha(a)
        self:EnableMouse(a > 0)
    end
end)
