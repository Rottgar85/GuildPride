-- GuildPride: Chat im Gildenfenster
-- Bindet Blizzards Gildenchat, Offizierschat und alle eigenen Communities
-- (inkl. Server-Verlauf über C_Club) ein.
local ADDON, ns = ...
local L = ns.L
local MAX_SAVED = 60
local HISTORY = 150
local SendChat = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
local HAS_CLUB = C_Club and C_Club.GetGuildClubId and C_Club.GetStreams and C_Club.GetMessageRanges

local page = ns.AddTab(L["Gildenchat"])

-- Aktueller Kanal: { kind = "GUILD" | "OFFICER" | "CLUB", clubId, streamId, label }
local channel = { kind = "GUILD", label = L["Gilde"] }

---------------------------------------------------------------------
-- Kanal-Leiste
---------------------------------------------------------------------
local bGuild = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
bGuild:SetSize(100, 24); bGuild:SetPoint("TOPLEFT", 0, 0); bGuild:SetText(L["Gilde"])
local bOfficer = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
bOfficer:SetSize(100, 24); bOfficer:SetPoint("LEFT", bGuild, "RIGHT", 6, 0); bOfficer:SetText(L["Offiziere"])
local bClub = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
bClub:SetSize(170, 24); bClub:SetPoint("LEFT", bOfficer, "RIGHT", 6, 0); bClub:SetText("Communities  ▾")

local current = page:CreateFontString(nil, "OVERLAY", "GPFont_MutedSmall")
current:SetPoint("RIGHT", page, "TOPRIGHT", -4, -12)

---------------------------------------------------------------------
-- Nachrichtenfeld
---------------------------------------------------------------------
local box = CreateFrame("Frame", nil, page)
box:SetPoint("TOPLEFT", 0, -32)
box:SetPoint("BOTTOMRIGHT", 0, 40)
local boxBg = box:CreateTexture(nil, "BACKGROUND")
boxBg:SetAllPoints(); boxBg:SetColorTexture(0, 0, 0, 0.45)
local boxEdge = box:CreateTexture(nil, "BORDER")
boxEdge:SetPoint("TOPLEFT"); boxEdge:SetPoint("BOTTOMLEFT"); boxEdge:SetWidth(3)
boxEdge:SetColorTexture(1, 0.45, 0.15, 1)

local msgs = CreateFrame("ScrollingMessageFrame", nil, box)
msgs:SetPoint("TOPLEFT", 12, -8)
msgs:SetPoint("BOTTOMRIGHT", -8, 8)
msgs:SetFontObject(GPFont_Text)
msgs:SetJustifyH("LEFT")
msgs:SetFading(false)
msgs:SetMaxLines(300)
msgs:SetSpacing(3)
msgs:SetHyperlinksEnabled(true)
msgs:SetScript("OnHyperlinkClick", function(_, link, text, button) SetItemRef(link, text, button) end)
msgs:EnableMouseWheel(true)
msgs:SetScript("OnMouseWheel", function(self, delta)
    if delta > 0 then self:ScrollUp() else self:ScrollDown() end
end)

---------------------------------------------------------------------
-- Eingabe
---------------------------------------------------------------------
local input = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
input:SetPoint("BOTTOMLEFT", 8, 6)
input:SetPoint("BOTTOMRIGHT", -110, 6)
input:SetHeight(24)
input:SetAutoFocus(false)
input:SetMaxLetters(255)

local send = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
send:SetSize(100, 26)
send:SetPoint("BOTTOMRIGHT", 0, 5)
send:SetText(L["Senden"])

---------------------------------------------------------------------
-- Hilfsfunktionen
---------------------------------------------------------------------
local function ClassHex(classID, classFile)
    local file = classFile
    if classID and C_CreatureInfo and C_CreatureInfo.GetClassInfo then
        local info = C_CreatureInfo.GetClassInfo(classID)
        file = info and info.classFile or file
    end
    local c = file and RAID_CLASS_COLORS[file]
    return c and c.colorStr and c.colorStr:sub(3) or "f0c88c"
end

local TEXT_COLOR = { GUILD = "|cffe6e0da", OFFICER = "|cff40c040", CLUB = "|cff8fd3ff" }

local function Line(t, who, full, hex, text, kind)
    local name = full and ("|Hplayer:%s|h|cff%s%s|r|h"):format(full, hex, who) or ("|cff%s%s|r"):format(hex, who)
    return ("|cff777777%s|r  %s: %s%s|r"):format(date("%H:%M", t), name, TEXT_COLOR[kind] or "|cffffffff", text)
end

-- Name noch nicht geladen? (Der Server liefert ältere Nachrichten oft ohne
-- Autorennamen; Blizzard zeigt dann "Unbekannt".)
local function IsUnknown(name)
    return name == nil or name == "" or name == "?" or name == UNKNOWNOBJECT or name == UNKNOWN
end

-- Autorennamen nachschlagen: Mitgliederliste des Clubs, sonst über die GUID
local function AuthorName(clubId, a)
    local name = a.name
    if issecretvalue and issecretvalue(name) then name = nil end
    if IsUnknown(name) and clubId and a.memberId and C_Club.GetMemberInfo then
        local info = C_Club.GetMemberInfo(clubId, a.memberId)
        if info and not IsUnknown(info.name) and not (issecretvalue and issecretvalue(info.name)) then
            name, a.classID = info.name, a.classID or info.classID
        end
    end
    if IsUnknown(name) and a.guid and GetPlayerInfoByGUID then
        local _, _, _, _, _, n, realm = GetPlayerInfoByGUID(a.guid)
        if n and n ~= "" then name = (realm and realm ~= "") and (n .. "-" .. realm) or n end
    end
    return (not IsUnknown(name)) and name or nil
end

-- Server-Nachricht -> gespeicherter Eintrag { t, who, full, hex, text, memberId, guid }
local function ClubEntry(clubId, m, kind)
    if not m or m.destroyed or not m.content then return end
    if issecretvalue and issecretvalue(m.content) then return end
    local a = m.author or {}
    local full = AuthorName(clubId, a)
    local t = (m.messageId and m.messageId.epoch or 0) / 1000000
    -- Battle.net-Communities: kein Charaktername -> kein Player-Link
    local link = full and (kind ~= "CLUB" or a.clubType ~= Enum.ClubType.BattleNet) and full or nil
    return { t = t, who = full and Ambiguate(full, "guild") or nil, full = link, hex = ClassHex(a.classID),
             text = m.content, memberId = a.memberId, guid = a.guid }
end

local function EntryLine(e, kind)
    return Line(e.t, e.who or UNKNOWNOBJECT or "?", e.full, e.hex, e.text, kind)
end

-- Verlauf je Kanal lokal merken: der Server liefert nach dem Login oft nur
-- einen Teil, so bleibt das bisher Gesagte trotzdem sichtbar.
local CACHE_MAX = 200

local function Cache(clubId, streamId)
    GuildPrideDB.clubCache = GuildPrideDB.clubCache or {}
    local key = tostring(clubId) .. ":" .. tostring(streamId)
    GuildPrideDB.clubCache[key] = GuildPrideDB.clubCache[key] or {}
    return GuildPrideDB.clubCache[key]
end

-- Dieselbe Nachricht? Gleicher Text, höchstens 2 Minuten auseinander
-- (Chat-Ereignis und Server-Verlauf haben leicht andere Zeitstempel).
local function Same(a, b)
    return a.text == b.text and math.abs((a.t or 0) - (b.t or 0)) < 120
        and (a.who == nil or b.who == nil or a.who == b.who)
end

-- Einträge in den Speicher übernehmen: ohne Doppelte, fehlende Namen ergänzen
local function Remember(cache, entries)
    local changed = false
    for _, e in ipairs(entries) do
        local found
        for i = #cache, 1, -1 do
            if Same(cache[i], e) then found = cache[i]; break end
        end
        if found then
            if not found.who and e.who then
                found.who, found.full, found.hex = e.who, e.full, e.hex
                changed = true
            end
            found.memberId, found.guid = found.memberId or e.memberId, found.guid or e.guid
        else
            cache[#cache + 1] = e
            changed = true
        end
    end
    if changed then
        table.sort(cache, function(a, b) return a.t < b.t end)
        while #cache > CACHE_MAX do table.remove(cache, 1) end
    end
end

-- Alte Einträge ohne Namen beim Anzeigen erneut nachschlagen
local function FixNames(clubId, cache)
    for _, e in ipairs(cache) do
        if not e.who or IsUnknown(e.who) then
            local full = AuthorName(clubId, { memberId = e.memberId, guid = e.guid })
            if full then e.who, e.full = Ambiguate(full, "guild"), full end
            if IsUnknown(e.who) then e.who = nil end
        end
    end
end

-- Welcher Club/Stream gehört zum aktuellen Kanal?
local function Resolve(ch)
    if not HAS_CLUB then return end
    if ch.kind == "CLUB" then return ch.clubId, ch.streamId end
    local clubId = C_Club.GetGuildClubId()
    if not clubId then return end
    local want = ch.kind == "OFFICER" and Enum.ClubStreamType.Officer or Enum.ClubStreamType.Guild
    for _, st in ipairs(C_Club.GetStreams(clubId) or {}) do
        if st.streamType == want then return clubId, st.streamId end
    end
end

-- Lokaler Fallback (Clients ohne C_Club)
local function Store()
    GuildPrideDB.chat = GuildPrideDB.chat or { GUILD = {}, OFFICER = {} }
    return GuildPrideDB.chat
end

---------------------------------------------------------------------
-- Anzeigen
---------------------------------------------------------------------
local requested = {}
local focused

local function Redraw()
    msgs:Clear()
    current:SetText(L["Kanal: |cfff0c88c"] .. (channel.label or "") .. "|r")
    if HAS_CLUB then
        local clubId, streamId = Resolve(channel)
        if not clubId then
            msgs:AddMessage(L["|cff888888Chat wird geladen …|r"])
            return
        end
        -- Stream "fokussieren", damit der Server den Verlauf schickt
        if C_Club.FocusStream then
            if focused and C_Club.UnfocusStream and (focused[1] ~= clubId or focused[2] ~= streamId) then
                C_Club.UnfocusStream(focused[1], focused[2])
            end
            C_Club.FocusStream(clubId, streamId)
            focused = { clubId, streamId }
        end
        -- ALLE geladenen Bereiche lesen (früher nur den letzten -> älterer Verlauf fehlte)
        local ranges = C_Club.GetMessageRanges(clubId, streamId) or {}
        local server, oldest = {}, nil
        for _, rg in ipairs(ranges) do
            local o = rg.oldestMessageId
            if o and (not oldest or (o.epoch or 0) < (oldest.epoch or 0)) then oldest = o end
            for _, m in ipairs(C_Club.GetMessagesInRange(clubId, streamId, rg.oldestMessageId, rg.newestMessageId) or {}) do
                local e = ClubEntry(clubId, m, channel.kind)
                if e then server[#server + 1] = e end
            end
        end
        local cache = Cache(clubId, streamId)
        Remember(cache, server)
        FixNames(clubId, cache)
        if #cache == 0 then
            msgs:AddMessage(L["|cff888888Noch keine Nachrichten.|r"])
        end
        for i = math.max(1, #cache - HISTORY + 1), #cache do
            msgs:AddMessage(EntryLine(cache[i], channel.kind))
        end
        -- Mehr Verlauf vom Server holen (höchstens alle 30 Sekunden je Kanal)
        local key = clubId .. ":" .. streamId
        if #server < HISTORY and C_Club.RequestMoreMessagesBefore and GetTime() - (requested[key] or -999) > 30 then
            requested[key] = GetTime()
            C_Club.RequestMoreMessagesBefore(clubId, streamId, oldest, HISTORY)
        end
    else
        if channel.kind == "CLUB" then return end
        for _, e in ipairs(Store()[channel.kind] or {}) do
            msgs:AddMessage(Line(e.t, e.who, e.full, ClassHex(nil, e.class), e.text, e.ch))
        end
    end
    msgs:ScrollToBottom()
end

local function Highlight()
    local function set(btn, on)
        if btn.gpBg then btn.gpBg:SetTexture(ns.MEDIA .. (on and "nav_active" or "nav")) end
    end
    set(bGuild, channel.kind == "GUILD")
    set(bOfficer, channel.kind == "OFFICER")
    set(bClub, channel.kind == "CLUB")
end

local function SetChannel(ch)
    channel = ch
    Highlight()
    Redraw()
end

bGuild:SetScript("OnClick", function() SetChannel({ kind = "GUILD", label = L["Gilde"] }) end)
bOfficer:SetScript("OnClick", function() SetChannel({ kind = "OFFICER", label = L["Offiziere"] }) end)

---------------------------------------------------------------------
-- Community-Auswahl (alle Blizzard-Communities, außer der Gilde)
---------------------------------------------------------------------
local function Communities()
    local out = {}
    if not (HAS_CLUB and C_Club.GetSubscribedClubs) then return out end
    for _, club in ipairs(C_Club.GetSubscribedClubs() or {}) do
        if club.clubType ~= Enum.ClubType.Guild then
            local streams = {}
            for _, st in ipairs(C_Club.GetStreams(club.clubId) or {}) do
                streams[#streams + 1] = { id = st.streamId, name = st.name ~= "" and st.name or L["Allgemein"] }
            end
            out[#out + 1] = { id = club.clubId, name = club.name, bnet = club.clubType == Enum.ClubType.BattleNet, streams = streams }
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

local function Pick(club, st)
    local label = #club.streams > 1 and (club.name .. " · " .. st.name) or club.name
    SetChannel({ kind = "CLUB", clubId = club.id, streamId = st.id, label = label })
end

bClub:SetScript("OnClick", function(self)
    local list = Communities()
    if #list == 0 then
        ns.Print(L["Du bist in keiner Blizzard-Community."])
        return
    end
    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(self, function(_, root)
            root:CreateTitle("Communities")
            for _, club in ipairs(list) do
                local label = club.name .. (club.bnet and " |cff82c5ff(Battle.net)|r" or "")
                if #club.streams <= 1 then
                    local st = club.streams[1]
                    if st then root:CreateButton(label, function() Pick(club, st) end) end
                else
                    local sub = root:CreateButton(label)
                    for _, st in ipairs(club.streams) do
                        sub:CreateButton(st.name, function() Pick(club, st) end)
                    end
                end
            end
        end)
    else
        -- Fallback: der Reihe nach durchschalten
        local flat = {}
        for _, c in ipairs(list) do for _, st in ipairs(c.streams) do flat[#flat + 1] = { c, st } end end
        local idx = 1
        for i, p in ipairs(flat) do
            if channel.kind == "CLUB" and p[1].id == channel.clubId and p[2].id == channel.streamId then idx = i % #flat + 1 end
        end
        Pick(flat[idx][1], flat[idx][2])
    end
end)

---------------------------------------------------------------------
-- Senden
---------------------------------------------------------------------
local function Send()
    local text = strtrim(input:GetText() or "")
    if text == "" then input:ClearFocus(); return end
    if channel.kind == "CLUB" then
        local ok, err = pcall(C_Club.SendMessage, channel.clubId, channel.streamId, text)
        if not ok then
            ns.Print(L["|cffff4040Nachricht konnte nicht gesendet werden:|r "] .. tostring(err))
            return
        end
    else
        SendChat(text, channel.kind)
    end
    input:SetText("")
end
send:SetScript("OnClick", Send)
input:SetScript("OnEnterPressed", Send)
input:SetScript("OnEscapePressed", input.ClearFocus)

function page:Refresh()
    local canOfficer = (C_GuildInfo and C_GuildInfo.CanViewOfficerNote and C_GuildInfo.CanViewOfficerNote())
        or (CanViewOfficerNote and CanViewOfficerNote())
    bOfficer:SetShown(canOfficer and true or false)
    bClub:ClearAllPoints()
    bClub:SetPoint("LEFT", canOfficer and bOfficer or bGuild, "RIGHT", 6, 0)
    bClub:SetShown(HAS_CLUB and C_Club.GetSubscribedClubs and true or false)
    if not canOfficer and channel.kind == "OFFICER" then channel = { kind = "GUILD", label = L["Gilde"] } end
    SetChannel(channel)
end

page:SetScript("OnHide", function()
    if focused and C_Club and C_Club.UnfocusStream then
        C_Club.UnfocusStream(focused[1], focused[2])
        focused = nil
    end
end)

---------------------------------------------------------------------
-- Ereignisse
---------------------------------------------------------------------
local f = CreateFrame("Frame")
if HAS_CLUB then
    local pendingRedraw
    local function RedrawSoon()
        if pendingRedraw then return end
        pendingRedraw = C_Timer.NewTimer(0.5, function() pendingRedraw = nil; if page:IsVisible() then Redraw() end end)
    end
    f:RegisterEvent("CLUB_MESSAGE_ADDED")
    f:RegisterEvent("CLUB_MESSAGE_HISTORY_RECEIVED")
    f:RegisterEvent("CLUB_STREAMS_LOADED")
    f:RegisterEvent("CLUB_MESSAGE_UPDATED")
    f:RegisterEvent("CLUB_MEMBER_UPDATED")    -- Autorennamen kommen oft erst später
    f:RegisterEvent("CLUB_MEMBERS_UPDATED")
    f:SetScript("OnEvent", function(_, event, clubId, streamId, messageId)
        if event == "CLUB_MESSAGE_ADDED" then
            -- Auch bei geschlossenem Fenster merken, damit der Verlauf vollständig bleibt
            local kind = channel.kind == "CLUB" and "CLUB" or "GUILD"
            local e = ClubEntry(clubId, C_Club.GetMessageInfo(clubId, streamId, messageId), kind)
            if not e or not GuildPrideDB then return end
            Remember(Cache(clubId, streamId), { e })
            local myClub, myStream = Resolve(channel)
            if page:IsVisible() and clubId == myClub and streamId == myStream then
                msgs:AddMessage(EntryLine(e, channel.kind))
            end
            return
        end
        if not page:IsVisible() then return end
        local myClub = Resolve(channel)
        if clubId == myClub then RedrawSoon() end
    end)

    -- Gilden- und Offizierschat zusätzlich über die normalen Chat-Ereignisse merken:
    -- dort ist der Name immer bekannt (auch wenn der Server-Verlauf ihn nicht liefert)
    local gc = CreateFrame("Frame")
    gc:RegisterEvent("CHAT_MSG_GUILD")
    gc:RegisterEvent("CHAT_MSG_OFFICER")
    gc:SetScript("OnEvent", function(_, event, text, author, _, _, _, _, _, _, _, _, _, guid)
        if not GuildPrideDB or issecretvalue and (issecretvalue(text) or issecretvalue(author)) then return end
        local clubId, streamId = Resolve({ kind = event == "CHAT_MSG_OFFICER" and "OFFICER" or "GUILD" })
        if not clubId or not author or author == "" then return end
        local _, class = nil, nil
        if guid and guid ~= "" and GetPlayerInfoByGUID then _, class = GetPlayerInfoByGUID(guid) end
        Remember(Cache(clubId, streamId), { { t = GetServerTime(), who = Ambiguate(author, "guild"), full = author,
            hex = ClassHex(nil, class), text = text, guid = guid } })
    end)
else
    f:RegisterEvent("CHAT_MSG_GUILD")
    f:RegisterEvent("CHAT_MSG_OFFICER")
    f:SetScript("OnEvent", function(_, event, text, author, _, _, _, _, _, _, _, _, _, guid)
        if issecretvalue and (issecretvalue(text) or issecretvalue(author)) then return end
        if not GuildPrideDB then return end
        local ch = event == "CHAT_MSG_OFFICER" and "OFFICER" or "GUILD"
        local list = Store()[ch]
        local _, class = (guid and guid ~= "" and GetPlayerInfoByGUID) and GetPlayerInfoByGUID(guid)
        local e = { t = time(), ch = ch, who = Ambiguate(author, "guild"), full = author, text = text, class = class }
        table.insert(list, e)
        while #list > MAX_SAVED do table.remove(list, 1) end
        if page:IsVisible() and channel.kind == ch then
            msgs:AddMessage(Line(e.t, e.who, e.full, ClassHex(nil, e.class), e.text, ch))
        end
    end)
end

-- Logo auch im normalen Gildenchat anzeigen
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    if ns.ChatFilter then
        ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", ns.ChatFilter)
    end
end)
