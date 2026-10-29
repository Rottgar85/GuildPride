-- GuildPride: Gildeninfo (der Info-Text aus dem Blizzard-Gildenfenster)
-- Der Text kommt direkt vom Server: alle Mitglieder sehen denselben Stand,
-- auch ohne GuildPride. Addons dürfen ihn nur lesen, nicht ändern – bearbeitet
-- wird er deshalb im Blizzard-Gildenfenster (Reiter "Info").
local ADDON, ns = ...
local L = ns.L

local page = ns.AddTab(L["Gildeninfo"])

---------------------------------------------------------------------
-- Anzeige
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

local info = page:CreateFontString(nil, "OVERLAY", "GPFont_MutedSmall")
info:SetPoint("BOTTOMLEFT", 2, 8)
info:SetWidth(420); info:SetJustifyH("LEFT")

local bEdit = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
bEdit:SetSize(220, 24); bEdit:SetPoint("BOTTOMRIGHT", 0, 0); bEdit:SetText(L["Im Blizzard-Fenster bearbeiten"])
bEdit:SetScript("OnClick", function()
    ns.OpenBlizzardGuild()
    ns.Print(L["Gildeninfo bearbeiten: im Blizzard-Gildenfenster den Reiter „Info“ öffnen und dort auf „Bearbeiten“ klicken."])
end)

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
    view:SetHeight(text:GetStringHeight() + 10)
    info:SetText(CanEdit() and L["Du darfst die Gildeninfo ändern."] or L["Die Gildeninfo wird von der Gildenleitung gepflegt."])
    bEdit:SetShown(CanEdit())
end

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
