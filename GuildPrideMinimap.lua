-- GuildPride: Knopf am Minimap-Rand
-- Linksklick öffnet das Gildenfenster, Rechtsklick die Einstellungen,
-- ziehen verschiebt ihn am Rand. In den Einstellungen abschaltbar.
local ADDON, ns = ...
local L = ns.L

local btn = CreateFrame("Button", "GuildPrideMinimapButton", Minimap)
btn:SetSize(31, 31)
btn:SetFrameStrata("MEDIUM")
btn:SetFrameLevel(8)
btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
btn:RegisterForDrag("LeftButton")
btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local back = btn:CreateTexture(nil, "BACKGROUND")
back:SetSize(20, 20); back:SetPoint("CENTER")
back:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
local icon = btn:CreateTexture(nil, "ARTWORK")
icon:SetSize(20, 20); icon:SetPoint("CENTER")
icon:SetTexture(ns.MEDIA .. "logo")
local border = btn:CreateTexture(nil, "OVERLAY")
border:SetSize(53, 53); border:SetPoint("TOPLEFT")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

-- Position als Winkel am Minimap-Rand (GuildPrideDB.minimapAngle, Grad)
local function Place()
    local a = math.rad(GuildPrideDB.minimapAngle or 200)
    local r = Minimap:GetWidth() / 2 + 5
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
end

local function Drag()
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    GuildPrideDB.minimapAngle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
    Place()
end
btn:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", Drag) end)
btn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

btn:SetScript("OnClick", function(_, button)
    if button == "RightButton" then
        if not ns.GuildFrame:IsShown() then ns.ToggleUI() end
        if ns.GuildFrame:IsShown() and ns.SettingsPage then ns.SelectTab(ns.SettingsPage.tabId) end
    else
        ns.ToggleUI()
    end
end)
btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("GuildPride")
    GameTooltip:AddLine(L["Linksklick: Gildenfenster"], 1, 1, 1)
    GameTooltip:AddLine(L["Rechtsklick: Einstellungen"], 1, 1, 1)
    GameTooltip:AddLine(L["Ziehen: verschieben"], 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)
btn:SetScript("OnLeave", GameTooltip_Hide)
btn:Hide()

function ns.UpdateMinimap()
    if GuildPrideDB.minimap == false then btn:Hide() else Place(); btn:Show() end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function() ns.UpdateMinimap() end)
