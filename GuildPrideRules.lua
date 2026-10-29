-- GuildPride: Gildeninfo (der Info-Text aus dem Blizzard-Gildenfenster)
-- Der Text kommt direkt vom Server: alle Mitglieder sehen denselben Stand,
-- auch ohne GuildPride. Wer die Gildeninfo ändern darf, bearbeitet sie hier;
-- klappt das Speichern nicht, bleibt der Weg über das Blizzard-Gildenfenster.
local ADDON, ns = ...
local L = ns.L
local MAX_LEN = 500   -- Grenze von Blizzard für die Gildeninfo

local page = ns.AddTab(L["Gildeninfo"])

---------------------------------------------------------------------
-- Anzeige und Bearbeiten
---------------------------------------------------------------------
local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 0, -4)
scroll:SetPoint("BOTTOMRIGHT", -26, 34)

local view = CreateFrame("Frame", nil, scroll)
view:SetSize(630, 1)
scroll:SetScrollChild(view)
local text = view:CreateFontString(nil, "OVERLAY", "GPFont_Text")
text:SetPoint("TOPLEFT", 4, -4)
text:SetWidth(620); text:SetJustifyH("LEFT"); text:SetSpacing(4)

local edit = CreateFrame("EditBox", nil, scroll)
edit:SetMultiLine(true)
edit:SetFontObject(GPFont_Text)
edit:SetWidth(620)
edit:SetAutoFocus(false)
edit:SetMaxLetters(MAX_LEN)
edit:SetTextInsets(6, 6, 6, 6)
edit:Hide()
local editBg = edit:CreateTexture(nil, "BACKGROUND")
editBg:SetAllPoints(); editBg:SetColorTexture(0, 0, 0, 0.45)
edit:SetScript("OnEscapePressed", edit.ClearFocus)

local info = page:CreateFontString(nil, "OVERLAY", "GPFont_MutedSmall")
info:SetPoint("BOTTOMLEFT", 2, 8)
info:SetWidth(300); info:SetJustifyH("LEFT")

local bBlizz = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
bBlizz:SetSize(150, 24); bBlizz:SetPoint("BOTTOMRIGHT", -236, 0); bBlizz:SetText(L["Blizzard-Fenster"])
bBlizz:SetScript("OnClick", function()
    ns.OpenBlizzardGuild()
    ns.Print(L["Gildeninfo bearbeiten: im Blizzard-Gildenfenster den Reiter „Info“ öffnen und dort auf „Bearbeiten“ klicken."])
end)
local bEdit = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
bEdit:SetSize(110, 24); bEdit:SetPoint("BOTTOMRIGHT", -118, 0); bEdit:SetText(L["Bearbeiten"])
local bSave = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
bSave:SetSize(110, 24); bSave:SetPoint("BOTTOMRIGHT", 0, 0); bSave:SetText(L["Speichern"])

local counter = page:CreateFontString(nil, "OVERLAY", "GPFont_MutedSmall")
counter:SetPoint("BOTTOMRIGHT", bBlizz, "BOTTOMLEFT", -10, 8)
edit:SetScript("OnTextChanged", function(self)
    counter:SetText(("%d / %d"):format(#(self:GetText() or ""), MAX_LEN))
end)

local editing = false

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
    local can = CanEdit()
    if not can then editing = false end
    if editing then
        scroll:SetScrollChild(edit); view:Hide(); edit:Show()
        edit:SetHeight(math.max(200, scroll:GetHeight()))
    else
        scroll:SetScrollChild(view); edit:Hide(); view:Show()
        local t = InfoText()
        if t == nil then
            text:SetText(L["|cff888888Die Gildeninfo ist gerade nicht verfügbar.|r"])
        else
            text:SetText(t ~= "" and t or L["|cff888888Es wurde noch keine Gildeninfo festgelegt.|r"])
            GuildPrideDB.infoSeen = Hash(t)   -- gelesen
        end
        view:SetHeight(text:GetStringHeight() + 10)
    end
    info:SetText(can and L["Du darfst die Gildeninfo ändern."] or L["Die Gildeninfo wird von der Gildenleitung gepflegt."])
    bEdit:SetShown(can); bBlizz:SetShown(can)
    bSave:SetShown(can and editing)
    counter:SetShown(can and editing)
    bEdit:SetText(editing and L["Abbrechen"] or L["Bearbeiten"])
end

bEdit:SetScript("OnClick", function()
    editing = not editing
    if editing then
        edit:SetText(InfoText() or "")
        edit:SetFocus(); edit:SetCursorPosition(0)
    end
    page:Refresh()
end)

-- Speichern und danach prüfen, ob der Server den neuen Text übernommen hat
local SetInfo = (C_GuildInfo and C_GuildInfo.SetInfoText) or SetGuildInfoText
bSave:SetScript("OnClick", function()
    if not CanEdit() or not SetInfo then return end
    local new = (edit:GetText() or ""):gsub("|", ""):sub(1, MAX_LEN)
    SetInfo(new)
    editing = false
    edit:ClearFocus()
    ns.Print(L["Gildeninfo wird gespeichert …"])
    page:Refresh()
    C_Timer.After(1, function() if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end end)
    C_Timer.After(4, function()
        local now = InfoText()
        if now == nil then return end
        if strtrim(now) == strtrim(new) then
            GuildPrideDB.infoSeen = Hash(now)
            ns.Print(L["Gildeninfo gespeichert. Alle Mitglieder sehen jetzt den neuen Text."])
        else
            ns.Print(L["|cffff4040Die Gildeninfo konnte nicht gespeichert werden.|r Bitte über „Blizzard-Fenster“ bearbeiten."])
        end
        if page:IsVisible() then page:Refresh() end
    end)
end)

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
