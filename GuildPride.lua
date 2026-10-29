-- GuildPride v0.1.0
-- Meilenstein-Ansagen + Gilden-Logo im Chat
local ADDON, ns = ...
local L = ns.L

---------------------------------------------------------------------
-- Eigene Schriften (DejaVu, siehe Media/Fonts/LICENSE-DejaVu.txt)
---------------------------------------------------------------------
do
    local F = "Interface\\AddOns\\GuildPride\\Media\\Fonts\\"
    local function Make(name, file, size, r, g, b)
        local f = CreateFont(name)
        f:SetFont(F .. file, size, "")
        f:SetTextColor(r, g, b)
        f:SetShadowColor(0, 0, 0, 0.9)
        f:SetShadowOffset(1, -1)
        f:SetJustifyH("LEFT")
        return f
    end
    --        Name                 Datei           Größe  Farbe
    Make("GPFont_Huge",        "Heading.ttf",   20, 0.94, 0.78, 0.55)
    Make("GPFont_Large",       "Heading.ttf",   15, 0.94, 0.78, 0.55)
    Make("GPFont_Normal",      "Heading.ttf",   12, 0.94, 0.78, 0.55)
    Make("GPFont_Button",      "Heading.ttf",   12, 1.00, 0.82, 0.55)
    Make("GPFont_ButtonOff",   "Heading.ttf",   12, 0.50, 0.45, 0.42)
    Make("GPFont_Text",        "Text.ttf",      12, 0.92, 0.90, 0.88)
    Make("GPFont_TextBold",    "TextBold.ttf",  12, 0.94, 0.78, 0.55)
    Make("GPFont_TextSmall",   "Text.ttf",      11, 0.92, 0.90, 0.88)
    Make("GPFont_Muted",       "Text.ttf",      12, 0.51, 0.47, 0.45)
    Make("GPFont_MutedSmall",  "Text.ttf",       9, 0.51, 0.47, 0.45)
    Make("GPFont_Red",         "Text.ttf",      11, 1.00, 0.30, 0.25)
end
local PREFIX = "GuildPride"          -- max. 16 Zeichen
local MILESTONES = { [10]=true, [20]=true, [30]=true, [40]=true, [50]=true,
                     [60]=true, [70]=true, [80]=true, [90]=true }

-- Eigenes Logo: Interface\AddOns\GuildPride\logo.tga (64x64, 32-bit TGA)
-- Fallback, solange du noch kein Logo hast:
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_Tournaments_banner_Human"

local defaults = { sound = true, chatIcon = true, popup = true, useCustomLogo = false,
                   replaceGuildFrame = true, memberAlerts = true, helpAlerts = true, btagAuto = true }
local guildMembers = {}   -- ["Name-Realm"] = true

-- Modul-Nachrichten: ns.On("KIND", function(payload, sender) ... end)
ns.Handlers = {}
function ns.On(kind, fn)
    ns.Handlers[kind] = ns.Handlers[kind] or {}
    table.insert(ns.Handlers[kind], fn)
end
ns.SEP = "\031"
function ns.Me()
    return UnitName("player") .. "-" .. (GetNormalizedRealmName() or "")
end
function ns.IsOfficer()
    return CanEditMOTD and CanEditMOTD()
end

local function Print(msg)
    print("|cffff7d0a[GuildPride]|r " .. msg)
end

local function IconString(size)
    local path = "Interface\\AddOns\\GuildPride\\Media\\logo_small"
    return ("|T%s:%d|t"):format(path, size or 14)
end

local function Normalize(name)
    if not name then return nil end
    if not name:find("-") then
        name = name .. "-" .. (GetNormalizedRealmName() or "")
    end
    return name
end

---------------------------------------------------------------------
-- Gildenliste
---------------------------------------------------------------------
local function RefreshRoster()
    wipe(guildMembers)
    if not IsInGuild() then return end
    for i = 1, GetNumGuildMembers() do
        local name = GetGuildRosterInfo(i)
        if name then guildMembers[Normalize(name)] = true end
    end
end

---------------------------------------------------------------------
-- Popup
---------------------------------------------------------------------
local function ShowMilestone(sender, text, kind, value)
    local line = ("%s |cff00ff00%s|r %s"):format(IconString(20), Ambiguate(sender, "guild"), text)
    if GuildPrideDB.popup then
        if ns.ShowMilestonePopup then
            ns.ShowMilestonePopup(Ambiguate(sender, "guild"), text, kind, value)
        else
            RaidNotice_AddMessage(RaidWarningFrame, line, ChatTypeInfo["GUILD"])
        end
    end
    Print(line)
    -- Verlauf speichern (für das Gildenfenster)
    GuildPrideDB.log = GuildPrideDB.log or {}
    table.insert(GuildPrideDB.log, 1, { t = time(), who = Ambiguate(sender, "guild"), text = text, kind = kind, value = value })
    while #GuildPrideDB.log > 100 do table.remove(GuildPrideDB.log) end
    if ns.RefreshUI then ns.RefreshUI() end
end
ns.IconString = IconString
ns.Print = Print

local function Broadcast(kind, value)
    if not IsInGuild() then return end
    C_ChatInfo.SendAddonMessage(PREFIX, kind .. ":" .. tostring(value), "GUILD")
end

local function DescribeMilestone(kind, value)
    if kind == "LEVEL" then
        return (L["hat Level %s erreicht!"]):format(value)
    end
    return (L["hat einen Meilenstein erreicht (%s %s)"]):format(kind, value)
end

---------------------------------------------------------------------
-- Chat-Filter: Logo vor Nachrichten von Gildenmitgliedern
---------------------------------------------------------------------
-- Wer hat GuildPride? (jeder, von dem wir eine Addon-Nachricht bekommen haben)
ns.AddonUsers = {}

-- Logo VOR dem Namen: Wir nutzen das "Flag"-Feld der Chatnachricht
-- (dort stehen sonst z. B. <AFK>/<DND>/GM-Symbol). Der Chat zeigt
-- _G["CHAT_FLAG_GUILDPRIDE"] direkt vor dem Spielernamen an.
local FLAG = "GUILDPRIDE"

---------------------------------------------------------------------
-- Gildenwappen als Chat-Logo
-- Der Chat kann nur EIN Bild pro Symbol zeigen. Der Wappenrock besteht aus
-- Hintergrund + Rahmen + Emblem; wir zeigen daher das Emblem in Wappenfarbe.
---------------------------------------------------------------------
local function ColorRGB(c)
    if type(c) == "table" then
        if c.GetRGB then return c:GetRGB() end
        return c.r or 1, c.g or 1, c.b or 1
    end
    return 1, 1, 1
end

local function GuildEmblemString(size)
    if not IsInGuild() then return end
    local emblemFile, r, g, b
    if C_GuildInfo and C_GuildInfo.GetGuildTabardInfo then
        local ok, info = pcall(C_GuildInfo.GetGuildTabardInfo, "player")
        if ok and info and info.emblemFileID then
            emblemFile = info.emblemFileID
            r, g, b = ColorRGB(info.emblemColor)
        end
    end
    if not emblemFile and GetGuildLogoInfo then
        local ok, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10 = pcall(GetGuildLogoInfo, "player")
        if ok and type(a1) == "table" then
            -- Neuere Clients: backgroundColor, borderColor, emblemColor, emblemFileID
            emblemFile = a4
            r, g, b = ColorRGB(a3)
        elseif ok and a10 then
            -- Classic: bkgR,G,B, borderR,G,B, emblemR,G,B (0-1), emblemFile
            emblemFile = a10
            r, g, b = a7 or 1, a8 or 1, a9 or 1
            if r > 1 or g > 1 or b > 1 then r, g, b = r / 255, g / 255, b / 255 end
        end
    end
    if not emblemFile then return end
    -- Sehr dunkle Wappenfarben im dunklen Chat aufhellen
    local light = 0.299 * r + 0.587 * g + 0.114 * b
    if light < 0.35 then
        local f = 0.35 / math.max(light, 0.05)
        r, g, b = math.min(1, r * f + 0.15), math.min(1, g * f + 0.15), math.min(1, b * f + 0.15)
    end
    return ("|T%s:%d:%d:0:0:64:64:0:64:0:64:%d:%d:%d|t"):format(tostring(emblemFile), size, size,
        math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
end

function ns.UpdateChatEmblem()
    _G["CHAT_FLAG_GUILDPRIDE"] = (GuildEmblemString(14) or IconString(14)) .. " "
end

local function ChatFilter(self, event, msg, author, a3, a4, a5, flag, ...)
    if not GuildPrideDB or not GuildPrideDB.chatIcon then return false end
    -- Midnight: Chatdaten können "secret" sein -> dann nicht anfassen
    if issecretvalue and (issecretvalue(msg) or issecretvalue(author) or issecretvalue(flag)) then
        return false
    end
    -- AFK/DND/GM-Markierungen nicht überschreiben
    if author and (flag == nil or flag == "") and ns.AddonUsers[Normalize(author)] then
        return false, msg, author, a3, a4, a5, FLAG, ...
    end
    return false
end
ns.ChatFilter = ChatFilter

---------------------------------------------------------------------
-- Events
---------------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("GUILD_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("CHAT_MSG_ADDON")

f:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" and ... == ADDON then
        GuildPrideDB = GuildPrideDB or {}
        for k, v in pairs(defaults) do
            if GuildPrideDB[k] == nil then GuildPrideDB[k] = v end
        end
        -- Einmalige Bereinigung vor der ersten Veröffentlichung:
        -- entfernt alle Testdaten (Regeln, Events, Verlauf, Warteschlangen).
        -- Die leeren Regeln bekommen einen aktuellen Zeitstempel, damit ältere
        -- Test-Regeln von anderen Spielern nicht zurückkommen.
        if GuildPrideDB.cleanStart ~= 1 then
            local hadRules = GuildPrideDB.rules and (GuildPrideDB.rules.ver or 0) > 0
            -- Nur bei vorhandenen (Test-)Regeln einen neuen Zeitstempel setzen;
            -- frische Installationen bleiben bei 0 und übernehmen echte Regeln.
            GuildPrideDB.rules = { text = "", ver = hadRules and GetServerTime() or 0 }
            GuildPrideDB.rulesSeen = GuildPrideDB.rules.ver
            GuildPrideDB.events = {}
            GuildPrideDB.log = {}
            GuildPrideDB.btagQueue = {}
            GuildPrideDB.btagAsked, GuildPrideDB.btagSent, GuildPrideDB.btagDone = nil, nil, nil
            GuildPrideDB.chat = nil
            GuildPrideDB.cleanStart = 1
        end
        C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
        ns.UpdateChatEmblem()
        ns.AddonUsers[Normalize(UnitName("player"))] = true
        ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", ChatFilter) -- Allgemein, Handel ...
        ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", ChatFilter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", ChatFilter)

    elseif event == "PLAYER_LOGIN" then
        if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
        Print(L["geladen. /gp für Befehle"])

    elseif event == "GUILD_ROSTER_UPDATE" then
        RefreshRoster()
        ns.UpdateChatEmblem()   -- Wappen kann sich geändert haben
        if ns.RefreshUI then ns.RefreshUI() end

    elseif event == "PLAYER_LEVEL_UP" then
        local level = ...
        if MILESTONES[level] then Broadcast("LEVEL", level) end

    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        if prefix ~= PREFIX or (channel ~= "GUILD" and channel ~= "WHISPER" and channel ~= "OFFICER") then return end
        if sender then ns.AddonUsers[Normalize(sender)] = true end
        local kind, value = message:match("^(%u+):(.+)$")
        if not kind then return end
        if ns.Handlers[kind] then
            for _, fn in ipairs(ns.Handlers[kind]) do fn(value, sender) end
        elseif kind == "LEVEL" then
            ShowMilestone(sender, DescribeMilestone(kind, value), kind, value)
        end
    end
end)

---------------------------------------------------------------------
-- Slash-Befehle
---------------------------------------------------------------------
SLASH_GUILDPRIDE1 = "/gp"
SLASH_GUILDPRIDE2 = "/guildpride"
SlashCmdList.GUILDPRIDE = function(arg)
    arg = (arg or ""):lower()
    local toggles = { sound = "sound", icon = "chatIcon", popup = "popup", logo = "useCustomLogo" }
    if toggles[arg] then
        local key = toggles[arg]
        GuildPrideDB[key] = not GuildPrideDB[key]
        Print(("%s: %s"):format(arg, GuildPrideDB[key] and L["an"] or L["aus"]))
    elseif arg == "" or arg == "show" then
        if ns.ToggleUI then ns.ToggleUI() end
    elseif arg == "blizzard" then
        GuildPrideDB.replaceGuildFrame = not GuildPrideDB.replaceGuildFrame
        Print(L["Eigenes Gildenfenster: "] .. (GuildPrideDB.replaceGuildFrame and L["an"] or L["aus"]))
    elseif arg:match("^kuerzel") or arg:match("^kürzel") or arg:match("^tag%f[%A]") then
        local tag = arg:match("^%S+%s+(.+)$")
        GuildPrideDB.tag = tag and tag:upper() or nil
        Print(L["Gildenkürzel: "] .. (GuildPrideDB.tag or L["automatisch"]))
        if ns.RefreshUI then ns.RefreshUI() end
    elseif arg == "test" then
        ShowMilestone(UnitName("player"), DescribeMilestone("LEVEL", 20), "LEVEL", 20)
    elseif arg == "testall" then
        Broadcast("LEVEL", 20)   -- alle Gildenmitglieder mit Addon sehen es
    else
        Print(L["Befehle: /gp (Fenster) · sound · icon · popup · blizzard · kuerzel <XYZ> · badge <Level> · version · battletag · btags · test · testall"])
    end
end
