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

local function ClubLine(m, kind)
    if not m or m.destroyed or not m.content then return end
    if issecretvalue and issecretvalue(m.content) then return end
    local a = m.author or {}
    local full = a.name or "?"
    local t = (m.messageId and m.messageId.epoch or 0) / 1000000
    -- Battle.net-Communities: kein Charaktername -> kein Player-Link
    local link = (kind ~= "CLUB" or a.clubType ~= Enum.ClubType.BattleNet) and full or nil
    return Line(t, Ambiguate(full, "guild"), link, ClassHex(a.classID), m.content, kind)
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
        local ranges = C_Club.GetMessageRanges(clubId, streamId) or {}
        local last = ranges[#ranges]
        if last then
            local list = C_Club.GetMessagesInRange(clubId, streamId, last.oldestMessageId, last.newestMessageId) or {}
            for i = math.max(1, #list - HISTORY + 1), #list do
                local line = ClubLine(list[i], channel.kind)
                if line then msgs:AddMessage(line) end
            end
        else
            msgs:AddMessage(L["|cff888888Noch keine Nachrichten.|r"])
        end
        local key = clubId .. ":" .. streamId
        if not requested[key] and C_Club.RequestMoreMessagesBefore then
            requested[key] = true
            C_Club.RequestMoreMessagesBefore(clubId, streamId, last and last.oldestMessageId or nil, HISTORY)
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
    f:RegisterEvent("CLUB_MESSAGE_ADDED")
    f:RegisterEvent("CLUB_MESSAGE_HISTORY_RECEIVED")
    f:RegisterEvent("CLUB_STREAMS_LOADED")
    f:SetScript("OnEvent", function(_, event, clubId, streamId, messageId)
        if not page:IsVisible() then return end
        local myClub, myStream = Resolve(channel)
        if clubId ~= myClub then return end
        if event == "CLUB_MESSAGE_ADDED" then
            if streamId ~= myStream then return end
            local line = ClubLine(C_Club.GetMessageInfo(clubId, streamId, messageId), channel.kind)
            if line then msgs:AddMessage(line) end
        else
            Redraw()
        end
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
