-- GuildPride: Gildeninfo (der Info-Text aus dem Blizzard-Gildenfenster)
-- Der Text kommt direkt vom Server: alle Mitglieder sehen denselben Stand,
-- auch ohne GuildPride. Ändern darf ihn nur Blizzards eigene Oberfläche
-- (SetGuildInfoText ist für Addons gesperrt, im Spiel geprüft) – dafür
-- öffnet der Knopf das Blizzard-Gildenfenster.
local ADDON, ns = ...
local L = ns.L

local page = ns.AddTab(L["Gildeninfo"])

---------------------------------------------------------------------
-- Anzeige
---------------------------------------------------------------------
local scroll = ns.NewScroll(page)
scroll:SetPoint("TOPLEFT", 0, -4)
scroll:SetPoint("BOTTOMRIGHT", -26, 34)

local view = CreateFrame("Frame", nil, scroll)
view:SetSize(630, 1)
scroll:SetScrollChild(view)
local text = view:CreateFontString(nil, "OVERLAY", "GPFont_Text")
text:SetPoint("TOPLEFT", 4, -4)
text:SetWidth(620); text:SetJustifyH("LEFT"); text:SetSpacing(4)

local bEdit = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
bEdit:SetSize(220, 24); bEdit:SetPoint("BOTTOMRIGHT", 0, 0); bEdit:SetText(L["Im Blizzard-Fenster bearbeiten"])
bEdit:SetScript("OnClick", function()
    ns.OpenBlizzardGuild()
    ns.Print(L["Gildeninfo bearbeiten: im Blizzard-Gildenfenster den Reiter „Info“ öffnen und dort auf „Bearbeiten“ klicken."])
end)

---------------------------------------------------------------------
-- Kopieren: WoW hat keinen Zugriff auf die Zwischenablage. Darum zeigen wir
-- den Text in einem markierten Eingabefeld, Strg+C kopiert ihn.
---------------------------------------------------------------------
local copyScroll = ns.NewScroll(page)
copyScroll:SetPoint("TOPLEFT", 0, -4)
copyScroll:SetPoint("BOTTOMRIGHT", -26, 34)
copyScroll:Hide()
local copyBox = CreateFrame("EditBox", nil, copyScroll)
copyBox:SetMultiLine(true)
copyBox:SetAutoFocus(false)
copyBox:SetFontObject(GPFont_Text)
copyBox:SetWidth(620)
copyScroll:SetScrollChild(copyBox)
local copyBg = copyScroll:CreateTexture(nil, "BACKGROUND")
copyBg:SetAllPoints(); copyBg:SetColorTexture(0, 0, 0, 0.45)

local bCopy = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
bCopy:SetSize(140, 24)

local copyText = ""
local function CopyMode(on)
    copyScroll:SetShown(on)
    scroll:SetShown(not on)
    bCopy:SetText(on and L["Fertig"] or L["Text kopieren"])
    if on then
        copyBox:SetText(copyText)
        copyBox:SetFocus()
        copyBox:HighlightText()
        ns.Print(L["Text ist markiert – mit Strg+C kopieren."])
    else
        copyBox:ClearFocus()
    end
end
CopyMode(false)
-- Nur lesen: Eingaben sofort zurücksetzen, Markierung behalten
copyBox:SetScript("OnTextChanged", function(self, userInput)
    if userInput then self:SetText(copyText); self:HighlightText() end
end)
copyBox:SetScript("OnEscapePressed", function() CopyMode(false) end)
copyBox:SetScript("OnMouseUp", function(self) self:HighlightText() end)
bCopy:SetScript("OnClick", function() CopyMode(not copyScroll:IsShown()) end)
page:HookScript("OnHide", function() CopyMode(false) end)

local function InfoText()
    local t
    if C_GuildInfo and C_GuildInfo.GetInfoText then t = C_GuildInfo.GetInfoText()
    elseif GetGuildInfoText then t = GetGuildInfoText() end
    -- Midnight: im Kampf kann der Text gesperrt ("secret") sein
    if issecretvalue and issecretvalue(t) then return nil end
    return t or ""
end

local function CanEdit()
    return CanEditGuildInfo and CanEditGuildInfo() and true or false
end

-- Kurzer Fingerabdruck, um Änderungen zu erkennen
local function Hash(s)
    local h = 0
    for i = 1, #s do h = (h * 31 + s:byte(i)) % 2147483647 end
    return h .. ":" .. #s
end

function page:Refresh()
    local t = InfoText()
    if t == nil then
        text:SetText(L["|cff888888Die Gildeninfo ist gerade nicht verfügbar.|r"])
    else
        text:SetText(t ~= "" and t or L["|cff888888Es wurde noch keine Gildeninfo festgelegt.|r"])
        GuildPrideDB.infoSeen = Hash(t)   -- gelesen
    end
    copyText = t or ""
    bCopy:SetShown(copyText ~= "")
    if copyText == "" and copyScroll:IsShown() then CopyMode(false) end
    view:SetHeight(text:GetStringHeight() + 10)
    local can = CanEdit()
    bEdit:SetShown(can)
    -- Kopieren für alle; bei Offizieren links neben "Bearbeiten"
    bCopy:ClearAllPoints()
    if can then bCopy:SetPoint("RIGHT", bEdit, "LEFT", -6, 0) else bCopy:SetPoint("BOTTOMRIGHT", 0, 0) end
end

-- Nach dem Bearbeiten im Blizzard-Fenster sofort den neuen Text zeigen
local refresh = CreateFrame("Frame")
refresh:RegisterEvent("GUILD_ROSTER_UPDATE")
refresh:SetScript("OnEvent", function() if page:IsVisible() then page:Refresh() end end)

---------------------------------------------------------------------
-- Geänderte Gildeninfo melden und beim Öffnen zuerst zeigen
---------------------------------------------------------------------
local announced
local function Changed()
    local t = InfoText()
    if not t or t == "" or not GuildPrideDB then return false end
    return GuildPrideDB.infoSeen ~= Hash(t)
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("GUILD_ROSTER_UPDATE")
ev:SetScript("OnEvent", function()
    if not GuildPrideDB then return end
    if GuildPrideDB.infoSeen == nil then
        -- Erster Start mit dieser Version: aktuellen Stand als gelesen merken
        local t = InfoText()
        if t then GuildPrideDB.infoSeen = Hash(t) end
        return
    end
    if Changed() and not announced then
        announced = true
        ns.Print(L["Die Gildeninfo wurde geändert. Schau im Gildenfenster unter „Gildeninfo“ nach."])
    end
end)

ns.GuildFrame:HookScript("OnShow", function()
    if Changed() then ns.GuildFrame.selected = page.tabId end
end)
page:HookScript("OnShow", function() announced = false end)
