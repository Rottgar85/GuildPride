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

local defaults = { sound = true, popup = true, useCustomLogo = false,
                   replaceGuildFrame = true, memberAlerts = true, helpAlerts = true, shareMilestones = true }

-- Weitere Meilensteine neben LEVEL (Wert ist Text bzw. ID)
local EXTRA_KINDS = { ACH = true, BOSS = true, MPLUS = true, MOUNT = true }
ns.EXTRA_KINDS = EXTRA_KINDS
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
        local name, _, rankIndex = GetGuildRosterInfo(i)
        -- Wert = Rang + 1 (immer wahr), für die Empfangsstatistik je Rang
        if name then guildMembers[Normalize(name)] = (rankIndex or 0) + 1 end
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
    elseif kind == "ACH" then
        local id = tonumber(value)
        local name = id and GetAchievementInfo and select(2, GetAchievementInfo(id))
        return (L["hat den Erfolg „%s“ errungen!"]):format(name or tostring(value))
    elseif kind == "BOSS" then
        -- Wert: "Schwierigkeit,Bossname"
        local diff, boss = tostring(value):match("^(%d+),(.+)$")
        local dname = diff and GetDifficultyInfo and GetDifficultyInfo(tonumber(diff))
        return (L["hat %s besiegt!"]):format((boss or tostring(value)) .. (dname and (" (" .. dname .. ")") or ""))
    elseif kind == "MPLUS" then
        return (L["hat einen +%s-Schlüssel geschafft!"]):format(value)
    elseif kind == "MOUNT" then
        local id = tonumber(value)
        local name = id and C_MountJournal and C_MountJournal.GetMountInfoByID and C_MountJournal.GetMountInfoByID(id)
        return (L["hat ein neues Reittier: %s!"]):format(name or tostring(value))
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
    if e.kind == "LEVEL" or EXTRA_KINDS[e.kind] then return DescribeMilestone(e.kind, e.value) end
    if e.kind == "JOIN" then return L["ist der Gilde beigetreten"] end
    if e.kind == "LEAVE" then return L["hat die Gilde verlassen"] end
    if e.kind == "KICK" then return L["wurde aus der Gilde entfernt."] end
    return e.text or ""
end

local function LogKey(e)
    -- Beitritt/Austritt: ein Eintrag pro Tag und Person
    local v = (e.kind == "LEVEL" or EXTRA_KINDS[e.kind]) and e.value or math.floor((e.t or 0) / DAY)
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
    if kind ~= "LEVEL" and kind ~= "JOIN" and kind ~= "LEAVE" and kind ~= "KICK" and not EXTRA_KINDS[kind] then return end
    t = tonumber(t)
    if not t or not who or who == "" then return end
    ns.AddLog(kind, who, tonumber(value) or (value ~= "" and value or nil), t)
end)

---------------------------------------------------------------------
-- Diagnose: /gp ping (wer empfängt mich?) und /gp status (eigener Sendestand)
---------------------------------------------------------------------
local function MyRank()
    local _, rankName, rankIndex = GetGuildInfo("player")
    return rankName or "?", rankIndex or -1
end

local function YesNo(v) return v and ("|cff40ff40" .. L["ja"] .. "|r") or ("|cffff4040" .. L["nein"] .. "|r") end
ns.RecvStats = { raw = 0, total = 0, others = 0, secret = 0, badChannel = 0, byRank = {} }

ns.On("PING", function(_, sender)
    if sender == ns.Me() or not ns.Queue then return end
    local rankName = MyRank()
    local speak = (not ns.CanSpeakGuild or ns.CanSpeakGuild()) and 1 or 0
    C_Timer.After(math.random() * 2, function() ns.Queue("PONG", sender, ns.VERSION or "?", rankName, speak) end)
end)

ns.On("PONG", function(payload, sender)
    local version, rankName, speak = strsplit(ns.SEP, payload)
    Print((L["Antwort von |cffffd100%s|r: Version %s, Rang %s, darf schreiben: %s"]):format(
        Ambiguate(sender, "guild"), version or "?", rankName or "?", YesNo(speak == "1")))
end)

local function Status()
    local rankName, rankIndex = MyRank()
    local s = ns.SendStats or {}
    local online, known = 0, 0
    for i = 1, GetNumGuildMembers() do
        local name, _, _, _, _, _, _, _, isOnline = GetGuildRosterInfo(i)
        if name and isOnline then
            online = online + 1
            if ns.AddonUsers[Normalize(name)] then known = known + 1 end
        end
    end
    Print(("GuildPride %s · %s %s (%d)"):format(ns.VERSION or "?", L["Rang"], rankName, rankIndex))
    local inInstance, instanceType = IsInInstance()
    local lockdown = C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() or false
    Print((L["Gildenchat schreiben: %s · lesen: %s"]):format(
        YesNo(not ns.CanSpeakGuild or ns.CanSpeakGuild()), YesNo(not ns.CanListenGuild or ns.CanListenGuild())))
    Print((L["Instanz: %s (%s) · Blizzard-Chat-Sperre: %s"]):format(YesNo(inInstance), tostring(instanceType), YesNo(lockdown)))
    local r = ns.RecvStats
    Print((L["Empfangen: %d roh, %d gelesen, davon %d von anderen · %d geschützt · %d falscher Kanal %s"]):format(
        r.raw, r.total, r.others, r.secret, r.badChannel, r.lastBadChannel and ("(" .. r.lastBadChannel .. ")") or ""))
    Print((L["Ich bin: %s · Prefix registriert: %s"]):format(ns.Me(),
        YesNo(C_ChatInfo.IsAddonMessagePrefixRegistered and C_ChatInfo.IsAddonMessagePrefixRegistered(PREFIX))))
    if r.lastFrom then
        Print((L["Zuletzt von anderen: %s (%s) vor %d s"]):format(Ambiguate(r.lastFrom, "guild"), tostring(r.lastKind),
            math.floor(GetTime() - r.lastAt)))
    end
    Print((L["Gesendet: %d direkt, %d weitergeleitet, %d fehlgeschlagen · letztes Ergebnis: %s · Warteschlange: %d"]):format(
        s.direct or 0, s.relayed or 0, s.failed or 0, tostring(s.lastResult), ns.QueueLength and ns.QueueLength() or 0))
    Print((L["Online: %d Mitglieder, davon %d mit GuildPride bekannt"]):format(online, known))
    -- Empfang je Rang: Gilde 0 bei vielen Flüstern = dieser Rang kommt im Gildenkanal nicht an
    local ranks = {}
    for rank in pairs(r.byRank) do ranks[#ranks + 1] = rank end
    table.sort(ranks)
    for _, rank in ipairs(ranks) do
        local b = r.byRank[rank]
        local warn = (b.GUILD == 0 and (b.WHISPER > 0 or (b.CHANNEL or 0) > 0)) and (" |cffff4040" .. L["nur per Flüstern!"] .. "|r") or ""
        Print((L["Von Rang %d: %d über Gilde, %d über Kanal, %d geflüstert, %d Offiziere%s"]):format(
            rank, b.GUILD, b.CHANNEL or 0, b.WHISPER, b.OFFICER, warn))
    end
    local chan, chanName = ns.DataChannelId and ns.DataChannelId()
    Print((L["Hintergrund-Kanal: %s"]):format(chan and ("%d (%s)"):format(chan, chanName) or YesNo(false)))
end
ns.Status = Status

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

local function IsSecret(v) return issecretvalue and issecretvalue(v) or false end

---------------------------------------------------------------------
-- Addon-Nachrichten verteilen; mehrteilige ("MP") erst zusammensetzen
---------------------------------------------------------------------
local multipart = {}   -- ["Sender:id"] = { n, got, parts, t }
local recent, recentSweep = {}, 0   -- zuletzt empfangene Nachrichten (gegen Doppelte)
local forwarded = {}   -- ["Name:id"] = Zeit, gegen doppelte Weiterleitungen

local function Dispatch(message, sender)
    local kind, value = message:match("^(%u+):(.+)$")
    if not kind then return end
    if kind == "RLY" then
        -- Ein Mitglied ohne Gildenchat-Recht bittet uns, an die Gilde weiterzugeben
        local id, msg = value:match("^([^\031]+)\031(.+)$")
        if id and guildMembers[Normalize(sender)] and ns.Queue and (not ns.CanSpeakGuild or ns.CanSpeakGuild()) then
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
    elseif kind == "LEVEL" or EXTRA_KINDS[kind] then
        ShowMilestone(sender, kind, value)
    elseif kind == "LVTEST" then
        -- /gp testall: immer anzeigen, nie in den Verlauf (sonst greift die Dublettenprüfung)
        local who = Ambiguate(sender, "guild")
        if GuildPrideDB.popup and ns.ShowMilestonePopup then
            ns.ShowMilestonePopup(who, DescribeMilestone("LEVEL", value), "LEVEL", value)
        end
        Print(("%s |cff00ff00%s|r %s (Test)"):format(IconString(20), who, DescribeMilestone("LEVEL", value)))
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
f:RegisterEvent("ACHIEVEMENT_EARNED")
f:RegisterEvent("ENCOUNTER_END")
f:RegisterEvent("CHALLENGE_MODE_COMPLETED")
f:RegisterEvent("NEW_MOUNT_ADDED")

-- Eigene weitere Meilensteine melden (abschaltbar in den Einstellungen)
local function Share(kind, value)
    if GuildPrideDB.shareMilestones == false then return end
    Broadcast(kind, value)
end

local function OnExtraMilestone(event, ...)
    for i = 1, select("#", ...) do if IsSecret((select(i, ...))) then return end end
    if event == "ACHIEVEMENT_EARNED" then
        local id, already = ...
        -- Nur persönliche Erfolge, keine Gildenerfolge
        local isGuild = id and select(12, GetAchievementInfo(id))
        if id and not already and not isGuild then Share("ACH", id) end
    elseif event == "ENCOUNTER_END" then
        local _, name, diff, size, success = ...
        if success ~= 1 or not IsInRaid() or (size or 0) < 10 or not name then return end
        GuildPrideDB.bossKills = GuildPrideDB.bossKills or {}
        local key = diff .. "," .. name
        if GuildPrideDB.bossKills[key] then return end   -- nur der erste Sieg je Schwierigkeit
        GuildPrideDB.bossKills[key] = true
        Share("BOSS", key)
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        local info = C_ChallengeMode.GetChallengeCompletionInfo and C_ChallengeMode.GetChallengeCompletionInfo()
        local level = info and info.level
        if not level then level = select(2, C_ChallengeMode.GetCompletionInfo()) end
        if not level or level < 10 or (info and info.onTime == false) then return end
        if level <= (GuildPrideDB.mplusBest or 0) then return end   -- nur neue Bestwerte
        GuildPrideDB.mplusBest = level
        Share("MPLUS", level)
    elseif event == "NEW_MOUNT_ADDED" then
        local id = ...
        if id then Share("MOUNT", id) end
    end
end

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
        ns.AddonUsers[Normalize(UnitName("player"))] = true

    elseif event == "PLAYER_LOGIN" then
        if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
        Print(L["geladen. /gp für Befehle"])
        -- Alle /gp-Befehle (aus allen Dateien) gegen Fehler absichern: ein Fehler
        -- würde sonst Blizzards Chat-Eingabe offen lassen und den Befehl drin stehen
        local slash = SlashCmdList.GUILDPRIDE
        SlashCmdList.GUILDPRIDE = function(arg)
            local ok, err = pcall(slash, arg)
            if not ok then Print("|cffff4040" .. (IsSecret(err) and "?" or tostring(err)) .. "|r") end
        end
        C_Timer.After(15, RequestHistory)   -- verpasste Meilensteine von anderen holen

    elseif event == "GUILD_ROSTER_UPDATE" then
        RefreshRoster()
        CheckRosterLevels()
        if ns.RefreshUI then ns.RefreshUI() end

    elseif event == "PLAYER_LEVEL_UP" then
        local level = ...
        if MILESTONES[level] then Broadcast("LEVEL", level) end

    elseif event == "ACHIEVEMENT_EARNED" or event == "ENCOUNTER_END"
        or event == "CHALLENGE_MODE_COMPLETED" or event == "NEW_MOUNT_ADDED" then
        OnExtraMilestone(event, ...)

    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        local r = ns.RecvStats
        -- Geschützte Werte zuerst prüfen: schon ein Vergleich damit wirft einen Fehler
        if IsSecret(prefix) then r.secret = r.secret + 1; return end
        if prefix ~= PREFIX then return end
        r.raw = r.raw + 1
        if IsSecret(message) or IsSecret(sender) or IsSecret(channel) then r.secret = r.secret + 1; return end
        if channel ~= "GUILD" and channel ~= "WHISPER" and channel ~= "OFFICER" and channel ~= "CHANNEL" then
            r.badChannel, r.lastBadChannel = r.badChannel + 1, tostring(channel)
            return
        end
        if type(message) ~= "string" or type(sender) ~= "string" then return end
        -- Absender immer als "Name-Realm": manchmal kommt er ohne Realm an, dann
        -- wurden eigene Nachrichten für fremde gehalten (z. B. doppelte Hinweise)
        sender = Normalize(sender)
        -- Hintergrund-Kanal: nur Gildenmitglieder (der Kanal ist nicht abgeschlossen)
        if channel == "CHANNEL" and not guildMembers[sender] then return end
        -- Rundsendungen kommen über Gilde UND Kanal: zweites Exemplar verwerfen
        local now, key = GetTime(), sender .. "\030" .. message
        if recent[key] and now - recent[key] < 30 then return end
        recent[key] = now
        if now - recentSweep > 60 then
            recentSweep = now
            for k, t in pairs(recent) do if now - t >= 30 then recent[k] = nil end end
        end
        r.total = r.total + 1
        if sender ~= ns.Me() then
            r.others = r.others + 1; r.lastFrom, r.lastKind, r.lastAt = sender, message:match("^(%u+)"), GetTime()
            -- Je Rang und Kanal zählen: zeigt, ob ein Rang nur per Flüstern ankommt
            local rank = guildMembers[sender]
            if rank then
                local b = r.byRank[rank - 1] or { GUILD = 0, WHISPER = 0, OFFICER = 0 }
                r.byRank[rank - 1] = b
                b[channel] = (b[channel] or 0) + 1
            end
        end
        ns.AddonUsers[sender] = true
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
    local toggles = { sound = "sound", popup = "popup", logo = "useCustomLogo" }
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
    elseif arg == "status" then
        Status()
    elseif arg == "ping" then
        Print(L["Ping an die Gilde gesendet – jeder mit GuildPride antwortet gleich."])
        if ns.Queue then ns.Queue("PING", nil, "1") end
    elseif arg == "test" then
        -- Nur anzeigen, nicht in den Verlauf schreiben
        if ns.ShowMilestonePopup then ns.ShowMilestonePopup(UnitName("player"), DescribeMilestone("LEVEL", 20), "LEVEL", 20) end
    elseif arg == "testall" then
        Broadcast("LVTEST", 20)   -- alle Gildenmitglieder mit Addon sehen es (auch du selbst)
    elseif arg == "werben" or arg == "recruit" then
        if ns.PostRecruitText then ns.PostRecruitText() end
    elseif arg == "optionen" or arg == "options" then
        if ns.SettingsCategory and Settings and Settings.OpenToCategory then
            Settings.OpenToCategory(ns.SettingsCategory:GetID())
        end
    else
        Print(L["Befehle: /gp (Fenster) · sound · popup · blizzard · kuerzel <XYZ> · einladen <Name> · werben · optionen · badge <Level> · version · status · ping · test · testall"])
    end
end
