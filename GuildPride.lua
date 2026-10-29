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
                   replaceGuildFrame = true, memberAlerts = true, helpAlerts = true }
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

ns.IconString = IconString
ns.Print = Print

-- Über die Warteschlange (Drosselung, Weiterleitung für Ränge ohne Gildenchat)
local function Broadcast(kind, value)
    if not IsInGuild() or not ns.Queue then return end
    ns.Queue(kind, nil, value)
end

local function DescribeMilestone(kind, value)
    if kind == "LEVEL" then
        return (L["hat Level %s erreicht!"]):format(value)
    end
    return (L["hat einen Meilenstein erreicht (%s %s)"]):format(kind, value)
end

---------------------------------------------------------------------
-- Verlauf (Meilensteine, Beitritte, Austritte)
-- Jeder Eintrag hat einen Schlüssel (Art + Name + Wert). So kommt er nur einmal
-- in den Verlauf, egal ob er live, über die Gildenliste oder über den Abgleich
-- mit anderen Spielern ankommt.
---------------------------------------------------------------------
local LOG_MAX = 100
local DAY = 86400

function ns.LogText(e)
    if e.kind == "LEVEL" then return DescribeMilestone("LEVEL", e.value) end
    if e.kind == "JOIN" then return L["ist der Gilde beigetreten"] end
    if e.kind == "LEAVE" then return L["hat die Gilde verlassen"] end
    if e.kind == "KICK" then return L["wurde aus der Gilde entfernt."] end
    return e.text or ""
end

local function LogKey(e)
    -- Beitritt/Austritt: ein Eintrag pro Tag und Person
    local v = (e.kind == "LEVEL") and e.value or math.floor((e.t or 0) / DAY)
    return (e.kind or "?") .. ":" .. tostring(e.who) .. ":" .. tostring(v)
end

local function Log()
    GuildPrideDB.log = GuildPrideDB.log or {}
    return GuildPrideDB.log
end

-- Neuen Eintrag aufnehmen; true, wenn er neu war
function ns.AddLog(kind, who, value, t)
    local e = { kind = kind, who = who, value = value, t = t or GetServerTime() }
    local key = LogKey(e)
    for _, old in ipairs(Log()) do
        if LogKey(old) == key then
            -- Schon bekannt: den früheren (genaueren) Zeitpunkt behalten
            if e.t < (old.t or e.t) then
                old.t = e.t
                table.sort(Log(), function(a, b) return (a.t or 0) > (b.t or 0) end)
                if ns.RefreshUI then ns.RefreshUI() end
            end
            return false
        end
    end
    table.insert(Log(), e)
    table.sort(Log(), function(a, b) return (a.t or 0) > (b.t or 0) end)
    while #Log() > LOG_MAX do table.remove(Log()) end
    if ns.RefreshUI then ns.RefreshUI() end
    return true
end

-- Meilenstein anzeigen (Popup + Chat), aber nur beim ersten Mal
local function ShowMilestone(sender, kind, value, silent)
    local who = Ambiguate(sender, "guild")
    if not ns.AddLog(kind, who, tonumber(value) or value) or silent then return end
    local text = DescribeMilestone(kind, value)
    local line = ("%s |cff00ff00%s|r %s"):format(IconString(20), who, text)
    if GuildPrideDB.popup then
        if ns.ShowMilestonePopup then
            ns.ShowMilestonePopup(who, text, kind, value)
        else
            RaidNotice_AddMessage(RaidWarningFrame, line, ChatTypeInfo["GUILD"])
        end
    end
    Print(line)
end

-- Level-Aufstiege aus der Gildenliste erkennen – funktioniert auch für
-- Mitglieder ohne GuildPride. Aufstiege, die während man offline war passiert
-- sind, kommen nach dem Login nur still in den Verlauf (kein Popup-Schwall).
local rosterSeen = false
local function CheckRosterLevels()
    if not IsInGuild() or GetNumGuildMembers() == 0 then return end
    GuildPrideDB.levels = GuildPrideDB.levels or {}
    local known = GuildPrideDB.levels
    local silent = not rosterSeen
    for i = 1, GetNumGuildMembers() do
        local name, _, _, level = GetGuildRosterInfo(i)
        if name and level and level > 0 then
            local full = Normalize(name)
            local before = known[full]
            if before and level > before then
                for lv = before + 1, level do
                    if MILESTONES[lv] then ShowMilestone(full, "LEVEL", lv, silent) end
                end
            end
            known[full] = level
        end
    end
    rosterSeen = true
end

-- Abgleich: beim Login fragt man nach Einträgen, die neuer sind als der eigene
-- neueste. Ein zufälliger anderer Spieler antwortet für alle sichtbar; wer die
-- Antwort sieht, schickt keine zweite.
local answered = {}

-- whisper: Anfragender kann den Gildenchat nicht lesen -> Antwort per Flüstern
local function SendHistory(requester, since, whisper)
    local list = {}
    for _, e in ipairs(Log()) do
        if e.kind and e.t and e.t > since then list[#list + 1] = e end
        if #list >= 25 then break end
    end
    for i = #list, 1, -1 do
        local e = list[i]
        ns.Queue("MSL", whisper and requester or nil, requester, e.t, e.who, e.kind, e.value or "")
    end
end

ns.On("MSQ", function(payload, sender)
    if sender == ns.Me() then return end
    local sinceStr, listen = strsplit(ns.SEP, payload)
    local since = tonumber(sinceStr) or 0
    if listen == "0" then
        -- Antworten anderer sieht er nicht; jeder antwortet direkt, aber versetzt
        C_Timer.After(math.random() * 5, function() SendHistory(sender, since, true) end)
        return
    end
    local newest = Log()[1]
    if not newest or (newest.t or 0) <= since then return end
    answered[sender] = nil
    C_Timer.After(1 + math.random() * 5, function()
        if not answered[sender] then
            answered[sender] = true
            SendHistory(sender, since)
        end
    end)
end)

ns.On("MSL", function(payload, sender)
    local requester, t, who, kind, value = strsplit(ns.SEP, payload)
    if requester then answered[requester] = true end
    if sender == ns.Me() then return end
    if kind ~= "LEVEL" and kind ~= "JOIN" and kind ~= "LEAVE" and kind ~= "KICK" then return end
    t = tonumber(t)
    if not t or not who or who == "" then return end
    ns.AddLog(kind, who, tonumber(value) or (value ~= "" and value or nil), t)
end)

local function RequestHistory()
    local newest = Log()[1]
    local listen = (not ns.CanListenGuild or ns.CanListenGuild()) and 1 or 0
    if ns.Queue then ns.Queue("MSQ", nil, newest and newest.t or 0, listen) end
end
ns.RequestHistory = RequestHistory

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
-- Addon-Nachrichten verteilen; mehrteilige ("MP") erst zusammensetzen
---------------------------------------------------------------------
local multipart = {}   -- ["Sender:id"] = { n, got, parts, t }
local forwarded = {}   -- ["Name:id"] = Zeit, gegen doppelte Weiterleitungen

local function Dispatch(message, sender)
    local kind, value = message:match("^(%u+):(.+)$")
    if not kind then return end
    if kind == "RLY" then
        -- Ein Mitglied ohne Gildenchat-Recht bittet uns, an die Gilde weiterzugeben
        local id, msg = value:match("^([^\031]+)\031(.+)$")
        if id and guildMembers[Normalize(sender)] and ns.CanSpeakGuild and ns.CanSpeakGuild() and ns.Queue then
            ns.Queue("FWD", nil, Normalize(sender), id, msg)
        end
        return
    end
    if kind == "FWD" then
        local origin, id, msg = value:match("^([^\031]+)\031([^\031]+)\031(.+)$")
        if not origin or not guildMembers[origin] or msg:match("^FWD:") or msg:match("^RLY:") then return end
        local now, key = GetTime(), origin .. ":" .. id
        for k, t in pairs(forwarded) do if now - t > 120 then forwarded[k] = nil end end
        if forwarded[key] then return end
        forwarded[key] = now
        ns.AddonUsers[origin] = true
        Dispatch(msg, origin)
        return
    end
    if kind == "MP" then
        local id, i, n, part = value:match("^([^\031]+)\031(%d+)\031(%d+)\031(.*)$")
        i, n = tonumber(i), tonumber(n)
        if not id or not i or not n or n > 20 then return end
        local now = GetTime()
        for k, b in pairs(multipart) do if now - b.t > 60 then multipart[k] = nil end end
        local key = sender .. ":" .. id
        local buf = multipart[key] or { n = n, got = 0, parts = {}, t = now }
        multipart[key] = buf
        if not buf.parts[i] then buf.parts[i] = part; buf.got = buf.got + 1 end
        if buf.got < buf.n then return end
        multipart[key] = nil
        local full = table.concat(buf.parts)
        if not full:match("^MP:") then Dispatch(full, sender) end
        return
    end
    if ns.Handlers[kind] then
        for _, fn in ipairs(ns.Handlers[kind]) do fn(value, sender) end
    elseif kind == "LEVEL" then
        ShowMilestone(sender, kind, value)
    end
end

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
        -- entfernt alle Testdaten (Events, Verlauf, Warteschlangen).
        if GuildPrideDB.cleanStart ~= 1 then
            GuildPrideDB.events = {}
            GuildPrideDB.log = {}
            GuildPrideDB.chat = nil
            GuildPrideDB.cleanStart = 1
        end
        -- Eigene Regeln wurden durch die Blizzard-Gildeninfo ersetzt
        GuildPrideDB.rules, GuildPrideDB.rulesSeen = nil, nil
        -- BattleTag-Funktion wurde entfernt: alte gespeicherte Daten löschen
        GuildPrideDB.btagQueue, GuildPrideDB.btagAuto = nil, nil
        GuildPrideDB.btagAsked, GuildPrideDB.btagSent, GuildPrideDB.btagDone = nil, nil, nil
        C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
        ns.UpdateChatEmblem()
        ns.AddonUsers[Normalize(UnitName("player"))] = true
        ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", ChatFilter) -- Allgemein, Handel ...
        ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", ChatFilter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", ChatFilter)

    elseif event == "PLAYER_LOGIN" then
        if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
        Print(L["geladen. /gp für Befehle"])
        C_Timer.After(15, RequestHistory)   -- verpasste Meilensteine von anderen holen

    elseif event == "GUILD_ROSTER_UPDATE" then
        RefreshRoster()
        CheckRosterLevels()
        ns.UpdateChatEmblem()   -- Wappen kann sich geändert haben
        if ns.RefreshUI then ns.RefreshUI() end

    elseif event == "PLAYER_LEVEL_UP" then
        local level = ...
        if MILESTONES[level] then Broadcast("LEVEL", level) end

    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        if prefix ~= PREFIX or (channel ~= "GUILD" and channel ~= "WHISPER" and channel ~= "OFFICER") then return end
        if not sender or not message or (issecretvalue and (issecretvalue(message) or issecretvalue(sender))) then return end
        ns.AddonUsers[Normalize(sender)] = true
        Dispatch(message, sender)
    end
end)

---------------------------------------------------------------------
-- Slash-Befehle
---------------------------------------------------------------------
SLASH_GUILDPRIDE1 = "/gp"
SLASH_GUILDPRIDE2 = "/guildpride"
SlashCmdList.GUILDPRIDE = function(arg)
    local raw = strtrim(arg or "")
    arg = raw:lower()
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
    elseif arg:match("^einladen%f[%A]") or arg:match("^invite%f[%A]") then
        local name = raw:match("^%S+%s+(%S+)")
        if name and ns.InviteToGuild then ns.InviteToGuild(name) else Print(L["Bitte einen Charakternamen eingeben."]) end
    elseif arg == "test" then
        -- Nur anzeigen, nicht in den Verlauf schreiben
        if ns.ShowMilestonePopup then ns.ShowMilestonePopup(UnitName("player"), DescribeMilestone("LEVEL", 20), "LEVEL", 20) end
    elseif arg == "testall" then
        Broadcast("LEVEL", 20)   -- alle Gildenmitglieder mit Addon sehen es
    else
        Print(L["Befehle: /gp (Fenster) · sound · icon · popup · blizzard · kuerzel <XYZ> · einladen <Name> · badge <Level> · version · test · testall"])
    end
end
