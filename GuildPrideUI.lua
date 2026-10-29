-- GuildPride: eigenes Gildenfenster im "Schmiede"-Stil
-- Seitenleiste mit Logo + Navigation links, Glut-Banner oben, Inhalt rechts
local ADDON, ns = ...
local L = ns.L

local MEDIA = "Interface\\AddOns\\GuildPride\\Media\\"
local CLASS_COLORS = RAID_CLASS_COLORS
local COPPER = { 0.80, 0.55, 0.27 }
local GOLD_TEXT = "|cfff0c88c"

local W, H, SIDEBAR, HEADER = 860, 580, 180, 96

---------------------------------------------------------------------
-- Hauptfenster
---------------------------------------------------------------------
local frame = CreateFrame("Frame", "GuildPrideFrame", UIParent)
frame:SetSize(W, H)
frame:SetPoint("CENTER")
frame:SetFrameStrata("HIGH")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetClampedToScreen(true)
frame:Hide()
tinsert(UISpecialFrames, "GuildPrideFrame") -- ESC schließt

-- Hintergrund
local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
bg:SetAllPoints()
bg:SetTexture(MEDIA .. "bg")

-- Kupferrahmen (1 px außen + 2 px innen) und Ecken-Ornamente
local function Line(p1, p2, x1, y1, x2, y2, size, r, g, b)
    local t = frame:CreateTexture(nil, "BORDER")
    t:SetColorTexture(r, g, b, 1)
    t:SetPoint(p1, x1, y1); t:SetPoint(p2, x2, y2)
    if p1:find("LEFT") and p2:find("LEFT") or p1:find("RIGHT") and p2:find("RIGHT") then t:SetWidth(size) else t:SetHeight(size) end
end
Line("TOPLEFT", "TOPRIGHT", 0, 0, 0, 0, 2, unpack(COPPER))
Line("BOTTOMLEFT", "BOTTOMRIGHT", 0, 0, 0, 0, 2, unpack(COPPER))
Line("TOPLEFT", "BOTTOMLEFT", 0, 0, 0, 0, 2, unpack(COPPER))
Line("TOPRIGHT", "BOTTOMRIGHT", 0, 0, 0, 0, 2, unpack(COPPER))

local corners = {
    { "TOPLEFT",     0, 1, 0, 1 },
    { "TOPRIGHT",    1, 0, 0, 1 },
    { "BOTTOMLEFT",  0, 1, 1, 0 },
    { "BOTTOMRIGHT", 1, 0, 1, 0 },
}
for _, c in ipairs(corners) do
    local t = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    t:SetSize(40, 40)
    t:SetPoint(c[1], c[1]:find("LEFT") and -6 or 6, c[1]:find("TOP") and 6 or -6)
    t:SetTexture(MEDIA .. "corner")
    t:SetTexCoord(c[2], c[3], c[4], c[5])
end

-- Seitenleiste
local side = frame:CreateTexture(nil, "BACKGROUND", nil, -6)
side:SetPoint("TOPLEFT", 2, -2)
side:SetPoint("BOTTOMLEFT", 2, 2)
side:SetWidth(SIDEBAR)
side:SetTexture(MEDIA .. "sidebar")

-- Gildenkürzel + Wappenrock der Gilde (aus dem Spiel)
local tagText = frame:CreateFontString(nil, "OVERLAY", "GPFont_Huge")
tagText:SetPoint("TOP", frame, "TOPLEFT", SIDEBAR / 2 + 2, -14)

local crestGlow = frame:CreateTexture(nil, "ARTWORK", nil, 0)
crestGlow:SetSize(124, 124)
crestGlow:SetPoint("TOP", tagText, "BOTTOM", 0, 4)
crestGlow:SetTexture(MEDIA .. "crest_glow")

local tabardBg = frame:CreateTexture(nil, "ARTWORK", nil, 1)
local tabardBorder = frame:CreateTexture(nil, "ARTWORK", nil, 2)
local tabardEmblem = frame:CreateTexture(nil, "ARTWORK", nil, 3)
for _, t in ipairs({ tabardBg, tabardBorder, tabardEmblem }) do
    t:SetSize(84, 84)
    t:SetPoint("CENTER", crestGlow, "CENTER", 0, 0)
end

-- Kürzel: eigener Wert (/gp kuerzel XYZ) oder Anfangsbuchstaben des Gildennamens
local function GuildTag(name)
    if GuildPrideDB and GuildPrideDB.tag and GuildPrideDB.tag ~= "" then return GuildPrideDB.tag end
    if not name then return "" end
    local tag = ""
    for word in name:gmatch("%S+") do
        local c = word:match("^[%z\1-\127\194-\244][\128-\191]*")
        if c then tag = tag .. c end
    end
    return tag:upper():sub(1, 6)
end

local function UpdateCrest()
    local ok = false
    if IsInGuild() then
        if SetLargeGuildTabardTextures then
            ok = pcall(SetLargeGuildTabardTextures, "player", tabardEmblem, tabardBg, tabardBorder)
        elseif SetSmallGuildTabardTextures then
            ok = pcall(SetSmallGuildTabardTextures, "player", tabardEmblem, tabardBg, tabardBorder)
        end
    end
    -- Ohne Gilde/Wappenrock: unser eigenes Wappen anzeigen
    tabardBg:SetShown(ok); tabardBorder:SetShown(ok)
    if not ok then
        tabardEmblem:SetTexture(MEDIA .. "logo")
        tabardEmblem:SetTexCoord(0, 1, 0, 1)
        tabardEmblem:SetVertexColor(1, 1, 1)
    end
    tabardEmblem:SetShown(true)
end

local versionText = frame:CreateFontString(nil, "OVERLAY", "GPFont_MutedSmall")
versionText:SetPoint("BOTTOM", frame, "BOTTOMLEFT", SIDEBAR / 2 + 2, 14)

-- Banner oben
local header = frame:CreateTexture(nil, "BACKGROUND", nil, -5)
header:SetPoint("TOPLEFT", SIDEBAR + 2, -2)
header:SetPoint("TOPRIGHT", -2, -2)
header:SetHeight(HEADER)
header:SetTexture(MEDIA .. "header")

local title = frame:CreateFontString(nil, "OVERLAY", "GPFont_Huge")
title:SetPoint("TOPLEFT", header, "TOPLEFT", 24, -20)
title:SetTextColor(0.94, 0.78, 0.55)
title:SetShadowOffset(2, -2)

local subtitle = frame:CreateFontString(nil, "OVERLAY", "GPFont_Text")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 2, -6)

local pageTitle = frame:CreateFontString(nil, "OVERLAY", "GPFont_Large")
pageTitle:SetPoint("TOPRIGHT", header, "TOPRIGHT", -46, -24)
pageTitle:SetTextColor(1, 0.55, 0.25)

local close = CreateFrame("Button", nil, frame)
close:SetSize(26, 26)
close:SetPoint("TOPRIGHT", -12, -12)
close:SetNormalTexture(MEDIA .. "close")
close:SetHighlightTexture(MEDIA .. "close_hover")
close:SetPushedTexture(MEDIA .. "close_hover")
close:SetScript("OnClick", function() ns.ToggleUI() end)

local function UpdateHeader()
    local guildName = GetGuildInfo("player")
    title:SetText(guildName or L["Keine Gilde"])
    tagText:SetText(GuildTag(guildName))
    UpdateCrest()
    local total, online = GetNumGuildMembers()
    subtitle:SetText((L["%s%d|r Mitglieder  ·  |cff40ff40%d|r online"]):format(GOLD_TEXT, total or 0, online or 0))
    versionText:SetText("GuildPride " .. (ns.VERSION or ""))
end

---------------------------------------------------------------------
-- Navigation (Seitenleiste)
---------------------------------------------------------------------
local pages, tabs = {}, {}
local content = CreateFrame("Frame", nil, frame)
content:SetPoint("TOPLEFT", SIDEBAR + 14, -HEADER - 12)
content:SetPoint("BOTTOMRIGHT", -14, 14)

local function SelectTab(id)
    for i, page in ipairs(pages) do
        page:SetShown(i == id)
        local tab = tabs[i]
        if tab then
            tab.bgTex:SetTexture(MEDIA .. (i == id and "nav_active" or "nav"))
            tab.text:SetTextColor(i == id and 1 or 0.85, i == id and 0.82 or 0.75, i == id and 0.55 or 0.65)
        end
    end
    frame.selected = id
    pageTitle:SetText(tabs[id] and tabs[id].label or "")
    if pages[id] and pages[id].Refresh then pages[id]:Refresh() end
end

local function AddTab(label)
    local id = #pages + 1
    local page = CreateFrame("Frame", nil, content)
    page:SetAllPoints()
    page:Hide()
    pages[id] = page

    local tab = CreateFrame("Button", nil, frame)
    tab:SetSize(SIDEBAR - 16, 36)
    tab:SetPoint("TOPLEFT", 10, -168 - (id - 1) * 40)
    tab.bgTex = tab:CreateTexture(nil, "BACKGROUND")
    tab.bgTex:SetAllPoints()
    tab.bgTex:SetTexture(MEDIA .. "nav")
    local hl = tab:CreateTexture(nil, "HIGHLIGHT")
    hl:SetPoint("TOPLEFT", 3, -3); hl:SetPoint("BOTTOMRIGHT", -3, 3)
    hl:SetColorTexture(1, 0.5, 0.2, 0.12)
    tab.text = tab:CreateFontString(nil, "OVERLAY", "GPFont_Normal")
    tab.text:SetPoint("LEFT", 18, 0)
    tab.text:SetText(label)
    tab.label = label
    tab:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
        SelectTab(id)
    end)
    tabs[id] = tab
    page.tabId = id
    return page
end

-- Abschnitts-Überschrift mit Kupferlinie
local function Section(parent, text, anchor, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GPFont_Large")
    if anchor then fs:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y or -20) else fs:SetPoint("TOPLEFT", 4, y or -4) end
    fs:SetText(text)
    fs:SetTextColor(0.94, 0.78, 0.55)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("LEFT", fs, "RIGHT", 10, 0)
    line:SetPoint("RIGHT", parent, "RIGHT", -4, 0)
    line:SetColorTexture(COPPER[1], COPPER[2], COPPER[3], 0.5)
    return fs
end
ns.Section = Section

-- Scrollbare Liste
local function CreateList(parent, rowHeight)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, -4)
    scroll:SetPoint("BOTTOMRIGHT", -26, 0)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(620, 1)
    scroll:SetScrollChild(child)
    child.rows = {}
    function child:GetRow(i)
        local row = self.rows[i]
        if not row then
            row = CreateFrame("Frame", nil, self)
            row:SetSize(620, rowHeight)
            row:SetPoint("TOPLEFT", 0, -(i - 1) * rowHeight)
            row.bg = row:CreateTexture(nil, "BACKGROUND")
            row.bg:SetAllPoints()
            row.bg:SetColorTexture(1, 0.6, 0.3, i % 2 == 0 and 0.05 or 0)
            row.left = row:CreateFontString(nil, "OVERLAY", "GPFont_Text")
            row.left:SetPoint("LEFT", 8, 0)
            row.mid = row:CreateFontString(nil, "OVERLAY", "GPFont_TextSmall")
            row.mid:SetPoint("LEFT", 200, 0)
            row.right = row:CreateFontString(nil, "OVERLAY", "GPFont_MutedSmall")
            row.right:SetPoint("RIGHT", -8, 0)
            self.rows[i] = row
        end
        row:Show()
        return row
    end
    function child:Finish(count)
        for i = count + 1, #self.rows do self.rows[i]:Hide() end
        self:SetHeight(math.max(1, count * rowHeight))
    end
    return child
end

---------------------------------------------------------------------
-- 1) Übersicht
---------------------------------------------------------------------
local overview = AddTab(L["Übersicht"])
-- Der Gildenknopf in der Mikroleiste ruft ToggleGuildFrame auf und
-- öffnet damit automatisch dieses Fenster (siehe Hook unten).

-- Statistik-Kacheln
local tiles = {}
local function Tile(i, label)
    local f = CreateFrame("Frame", nil, overview)
    f:SetSize(196, 64)
    f:SetPoint("TOPLEFT", (i - 1) * 210, -4)
    local b = f:CreateTexture(nil, "BACKGROUND"); b:SetAllPoints(); b:SetColorTexture(0, 0, 0, 0.45)
    local edge = f:CreateTexture(nil, "BORDER"); edge:SetPoint("TOPLEFT"); edge:SetPoint("BOTTOMLEFT"); edge:SetWidth(3)
    edge:SetColorTexture(1, 0.45, 0.15, 1)
    f.value = f:CreateFontString(nil, "OVERLAY", "GPFont_Huge")
    f.value:SetPoint("TOPLEFT", 14, -10)
    f.value:SetTextColor(1, 0.85, 0.6)
    f.label = f:CreateFontString(nil, "OVERLAY", "GPFont_MutedSmall")
    f.label:SetPoint("BOTTOMLEFT", 14, 10)
    f.label:SetText(label)
    tiles[i] = f
end
Tile(1, L["MITGLIEDER ONLINE"])
Tile(2, L["NÄCHSTES EVENT"])
Tile(3, L["MEILENSTEINE DIESE WOCHE"])

local motdLabel = Section(overview, L["Nachricht des Tages"], nil, -92)
local motd = overview:CreateFontString(nil, "OVERLAY", "GPFont_Text")
motd:SetPoint("TOPLEFT", motdLabel, "BOTTOMLEFT", 0, -10)
motd:SetWidth(620); motd:SetJustifyH("LEFT")

local recentLabel = Section(overview, L["Letzte Meilensteine"], motd, -26)
local recent = overview:CreateFontString(nil, "OVERLAY", "GPFont_Text")
recent:SetPoint("TOPLEFT", recentLabel, "BOTTOMLEFT", 0, -10)
recent:SetWidth(620); recent:SetJustifyH("LEFT"); recent:SetSpacing(6)

function overview:Refresh()
    local total, online = GetNumGuildMembers()
    tiles[1].value:SetText(("%d / %d"):format(online or 0, total or 0))

    local nextEvent
    for _, e in pairs(GuildPrideDB.events or {}) do
        if e.title and not e.deleted and e.t and e.t > GetServerTime() and (not nextEvent or e.t < nextEvent.t) then
            nextEvent = e
        end
    end
    tiles[2].value:SetText(nextEvent and date("%d.%m. %H:%M", nextEvent.t) or "–")
    tiles[2].label:SetText(nextEvent and (L["NÄCHSTES EVENT: "] .. nextEvent.title:upper()) or L["NÄCHSTES EVENT"])

    local week, cutoff = 0, time() - 7 * 86400
    for _, e in ipairs(GuildPrideDB.log or {}) do if e.t > cutoff then week = week + 1 end end
    tiles[3].value:SetText(week)

    local text = GetGuildRosterMOTD and GetGuildRosterMOTD() or ""
    motd:SetText(text ~= "" and text or L["|cff888888Keine Nachricht gesetzt.|r"])
    local lines = {}
    for i = 1, math.min(6, #(GuildPrideDB.log or {})) do
        local e = GuildPrideDB.log[i]
        local icon = (e.kind and ns.BadgeFor) and ("|T%s:18|t"):format(ns.BadgeFor(e.kind, e.value)) or "|cffff8c40•|r"
        lines[#lines + 1] = ("%s |cfff0c88c%s|r %s  |cff777777%s|r"):format(icon, e.who, e.text, date("%d.%m.", e.t))
    end
    recent:SetText(#lines > 0 and table.concat(lines, "\n") or L["|cff888888Noch keine Meilensteine.|r"])
end

---------------------------------------------------------------------
-- 2) Mitglieder (Gilde oder eine Community)
---------------------------------------------------------------------
local members = AddTab(L["Mitglieder"])
local showOffline = false
local source   -- nil = Gilde, sonst { id, name, bnet } einer Community
local HAS_CLUB = C_Club and C_Club.GetSubscribedClubs and C_Club.GetClubMembers and C_Club.GetMemberInfo

local function FullName(name)
    if name and not name:find("-") then name = name .. "-" .. (GetNormalizedRealmName() or "") end
    return name
end

-- Communities (ohne Gilde), nach Name sortiert
local function Communities()
    local out = {}
    if not HAS_CLUB then return out end
    for _, club in ipairs(C_Club.GetSubscribedClubs() or {}) do
        if club.clubType ~= Enum.ClubType.Guild then
            out[#out + 1] = { id = club.clubId, name = club.name, bnet = club.clubType == Enum.ClubType.BattleNet }
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

local function CanInviteToClub(clubId)
    local priv = C_Club.GetClubPrivileges and C_Club.GetClubPrivileges(clubId)
    return priv and priv.canSendInvitation
end

-- Einladen: in die Gilde bzw. in eine Charakter-Community
function ns.InviteToGuild(name)
    if not IsInGuild() then ns.Print(L["Du bist in keiner Gilde."]); return end
    if CanGuildInvite and not CanGuildInvite() then
        ns.Print(L["|cffff4040Du darfst keine Spieler in die Gilde einladen.|r"]); return
    end
    if C_GuildInfo and C_GuildInfo.Invite then C_GuildInfo.Invite(name) else GuildInvite(name) end
    ns.Print((L["Gildeneinladung an |cffffd100%s|r gesendet."]):format(name))
end

function ns.InviteToClub(club, name)
    if club.bnet then
        ns.Print(L["Battle.net-Communities: Einladungen bitte über das Blizzard-Community-Fenster verschicken."]); return
    end
    if not (C_Club and C_Club.SendCharacterInvitation) then return end
    if not CanInviteToClub(club.id) then
        ns.Print((L["|cffff4040Du darfst in „%s“ niemanden einladen.|r"]):format(club.name)); return
    end
    local ok = pcall(C_Club.SendCharacterInvitation, club.id, name)
    if ok then
        ns.Print((L["Einladung in „%s“ an |cffffd100%s|r gesendet."]):format(club.name, name))
    else
        ns.Print(L["|cffff4040Einladung konnte nicht gesendet werden.|r"])
    end
end

-- Kopfzeile: Gilde | Communities ▾ | Nur online | Alle
local bSrcGuild = CreateFrame("Button", nil, members, "UIPanelButtonTemplate")
bSrcGuild:SetSize(90, 24); bSrcGuild:SetPoint("TOPLEFT", 0, 0); bSrcGuild:SetText(L["Gilde"])
local bSrcClub = CreateFrame("Button", nil, members, "UIPanelButtonTemplate")
bSrcClub:SetSize(170, 24); bSrcClub:SetPoint("LEFT", bSrcGuild, "RIGHT", 6, 0); bSrcClub:SetText("Communities  ▾")
bSrcClub:SetShown(HAS_CLUB and true or false)
local bOnline = CreateFrame("Button", nil, members, "UIPanelButtonTemplate")
bOnline:SetSize(110, 24); bOnline:SetPoint("LEFT", bSrcClub, "RIGHT", 18, 0); bOnline:SetText(L["Nur online"])
local bAll = CreateFrame("Button", nil, members, "UIPanelButtonTemplate")
bAll:SetSize(150, 24); bAll:SetPoint("LEFT", bOnline, "RIGHT", 6, 0); bAll:SetText(L["Alle (inkl. offline)"])

local listHolder = CreateFrame("Frame", nil, members)
listHolder:SetPoint("TOPLEFT", 0, -32)
listHolder:SetPoint("BOTTOMRIGHT", 0, 36)
local memberList = CreateList(listHolder, 24)

-- Fußzeile: Name eingeben + Einladen, rechts die Anzahl
local inviteBox = CreateFrame("EditBox", nil, members, "InputBoxTemplate")
inviteBox:SetSize(170, 22); inviteBox:SetPoint("BOTTOMLEFT", 8, 6)
inviteBox:SetAutoFocus(false); inviteBox:SetMaxLetters(60)
local inviteHint = inviteBox:CreateFontString(nil, "OVERLAY", "GPFont_Muted")
inviteHint:SetPoint("LEFT", 2, 0); inviteHint:SetText(L["Name-Realm"])
inviteBox:SetScript("OnTextChanged", function(self) inviteHint:SetShown(self:GetText() == "") end)
local inviteBtn = CreateFrame("Button", nil, members, "UIPanelButtonTemplate")
inviteBtn:SetSize(210, 24); inviteBtn:SetPoint("LEFT", inviteBox, "RIGHT", 8, 0)
local countText = members:CreateFontString(nil, "OVERLAY", "GPFont_MutedSmall")
countText:SetPoint("BOTTOMRIGHT", -4, 12)

local function DoInvite()
    local name = strtrim(inviteBox:GetText() or "")
    if name == "" then ns.Print(L["Bitte einen Charakternamen eingeben."]); return end
    if source then ns.InviteToClub(source, name) else ns.InviteToGuild(name) end
    inviteBox:SetText(""); inviteBox:ClearFocus()
end
inviteBtn:SetScript("OnClick", DoInvite)
inviteBox:SetScript("OnEnterPressed", DoInvite)
inviteBox:SetScript("OnEscapePressed", inviteBox.ClearFocus)

local function SetOffline(on)
    showOffline = on
    -- Manche Clients liefern Offline-Mitglieder nur, wenn das eingeschaltet ist
    if not source then
        if SetGuildRosterShowOffline then SetGuildRosterShowOffline(on) end
        if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
    end
    members:Refresh()
end
bOnline:SetScript("OnClick", function() SetOffline(false) end)
bAll:SetScript("OnClick", function() SetOffline(true) end)

local function SetSource(club)
    source = club
    if ns.HideMemberPanel then ns.HideMemberPanel() end
    -- Online-Status der Community-Mitglieder vom Server holen
    if C_Club and C_Club.ClearClubPresenceSubscription then pcall(C_Club.ClearClubPresenceSubscription) end
    if club and C_Club.SetClubPresenceSubscription then pcall(C_Club.SetClubPresenceSubscription, club.id) end
    if not club and C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
    members:Refresh()
end
bSrcGuild:SetScript("OnClick", function() SetSource(nil) end)

bSrcClub:SetScript("OnClick", function(self)
    local list = Communities()
    if #list == 0 then ns.Print(L["Du bist in keiner Blizzard-Community."]); return end
    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(self, function(_, root)
            root:CreateTitle("Communities")
            for _, club in ipairs(list) do
                root:CreateButton(club.name .. (club.bnet and " |cff82c5ff(Battle.net)|r" or ""), function() SetSource(club) end)
            end
        end)
    else
        -- Fallback: der Reihe nach durchschalten
        local idx = 1
        for i, c in ipairs(list) do if source and c.id == source.id then idx = i % #list + 1 end end
        SetSource(list[idx])
    end
end)

-- Für die Mitgliederverwaltung (GuildPrideManage.lua)
ns.Communities = Communities
ns.CanInviteToClub = CanInviteToClub
ns.FullName = FullName
ns.MembersPage = members

-- "zuletzt online vor …"
local function LastOnline(i)
    if not GetGuildRosterLastOnline then return L["offline"] end
    local y, m, d, h = GetGuildRosterLastOnline(i)
    if not y then return L["offline"] end
    if y > 0 then return (L["vor %d Jahr(en)"]):format(y) end
    if m > 0 then return (L["vor %d Monat(en)"]):format(m) end
    if d > 0 then return (L["vor %d Tag(en)"]):format(d) end
    if h > 0 then return (L["vor %d Std."]):format(h) end
    return L["vor < 1 Std."]
end

local function LastOnlineHours(i)
    if not GetGuildRosterLastOnline then return 0 end
    local y, m, d, h = GetGuildRosterLastOnline(i)
    return ((y or 0) * 365 + (m or 0) * 30 + (d or 0)) * 24 + (h or 0)
end

local function AgoText(y, m, d, h)
    if not y then return L["offline"] end
    if y > 0 then return (L["vor %d Jahr(en)"]):format(y) end
    if m > 0 then return (L["vor %d Monat(en)"]):format(m) end
    if d > 0 then return (L["vor %d Tag(en)"]):format(d) end
    if h > 0 then return (L["vor %d Std."]):format(h) end
    return L["vor < 1 Std."]
end

local CLUB_ROLES = { [1] = L["Besitzer"], [2] = L["Leiter"], [3] = L["Moderator"], [4] = L["Mitglied"] }
ns.CLUB_ROLES = CLUB_ROLES

local function ClassFile(classID)
    local info = classID and C_CreatureInfo and C_CreatureInfo.GetClassInfo and C_CreatureInfo.GetClassInfo(classID)
    return info and info.classFile
end

-- Gildenmitglieder (Name-Realm -> true), um "In Gilde einladen" nur Nicht-Mitgliedern anzubieten
local function GuildNames()
    local set = {}
    for i = 1, GetNumGuildMembers() do
        local name = GetGuildRosterInfo(i)
        if name then set[FullName(name)] = true end
    end
    return set
end

local function GuildData()
    local data, total, online = {}, 0, 0
    for i = 1, GetNumGuildMembers() do
        local name, rank, rankIndex, level, _, zone, note, officerNote, isOnline, _, classFile = GetGuildRosterInfo(i)
        if name then
            total = total + 1
            if isOnline then online = online + 1 end
            if isOnline or showOffline then
                local full = FullName(name)
                data[#data + 1] = { name = Ambiguate(name, "guild"), full = full, rank = rank, rankIndex = rankIndex,
                                    level = level, zone = zone, note = note, officerNote = officerNote,
                                    online = isOnline, class = classFile, inGuild = true, guild = true,
                                    isSelf = full == ns.Me(),
                                    last = not isOnline and LastOnline(i) or nil,
                                    hours = not isOnline and LastOnlineHours(i) or 0 }
            end
        end
    end
    return data, total, online
end

local function ClubData(club, inGuild)
    local data, total, online = {}, 0, 0
    local P = Enum.ClubMemberPresence or {}
    for _, id in ipairs(C_Club.GetClubMembers(club.id) or {}) do
        local info = C_Club.GetMemberInfo(club.id, id)
        if info and info.name and not (issecretvalue and issecretvalue(info.name)) then
            total = total + 1
            local p = info.presence
            local isOnline = p ~= nil and p ~= P.Offline and p ~= P.Unknown
            local mobile = p ~= nil and p == P.OnlineMobile
            if isOnline then online = online + 1 end
            if isOnline or showOffline then
                local full = not club.bnet and FullName(info.name) or nil
                local y, mo, d, h = info.lastOnlineYear, info.lastOnlineMonth, info.lastOnlineDay, info.lastOnlineHour
                data[#data + 1] = { name = club.bnet and info.name or Ambiguate(info.name, "guild"), full = full,
                                    rank = CLUB_ROLES[info.role] or "", level = info.level, online = isOnline,
                                    zone = mobile and L["Battle.net-App"] or info.zone,
                                    class = ClassFile(info.classID), isSelf = info.isSelf, club = club, clubId = club.id,
                                    memberId = info.memberId, role = info.role, note = info.memberNote,
                                    inGuild = full and inGuild[full] or false,
                                    last = not isOnline and AgoText(y, mo, d, h) or nil,
                                    hours = not isOnline and (((y or 0) * 365 + (mo or 0) * 30 + (d or 0)) * 24 + (h or 0)) or 0 }
            end
        end
    end
    return data, total, online
end

function members:Refresh()
    -- Community nicht mehr vorhanden (verlassen) -> zurück zur Gilde
    if source and not (C_Club.GetClubInfo and C_Club.GetClubInfo(source.id)) then source = nil end
    local function mark(btn, on)
        if btn.gpBg then btn.gpBg:SetTexture(MEDIA .. (on and "nav_active" or "nav")) end
    end
    mark(bOnline, not showOffline); mark(bAll, showOffline)
    mark(bSrcGuild, source == nil); mark(bSrcClub, source ~= nil)
    bSrcClub:SetText(source and (source.name .. "  ▾") or "Communities  ▾")
    inviteBtn:SetText(source and L["In Community einladen"] or L["In Gilde einladen"])

    local data, total, online
    if source then data, total, online = ClubData(source, GuildNames()) else data, total, online = GuildData() end
    table.sort(data, function(a, b)
        if a.online ~= b.online then return a.online end
        if not a.online and a.hours ~= b.hours then return a.hours < b.hours end
        return (a.level or 0) > (b.level or 0)
    end)
    countText:SetText((L["%d online · %d offline"]):format(online, total - online))
    for i, m in ipairs(data) do
        local row = memberList:GetRow(i)
        if not row.gpMenu then
            row.gpMenu = true
            row:EnableMouse(true)
            row.mid:SetWidth(260); row.mid:SetJustifyH("LEFT"); row.mid:SetWordWrap(false)
            -- Linksklick: Details/Verwaltung · Rechtsklick: Menü (GuildPrideManage.lua)
            row:SetScript("OnMouseUp", function(self, button)
                if not self.data then return end
                if button == "RightButton" then
                    if ns.MemberMenu then ns.MemberMenu(self, self.data) end
                elseif ns.ShowMemberPanel then
                    ns.ShowMemberPanel(self.data, self)
                end
            end)
        end
        row.data = m
        local c = CLASS_COLORS[m.class] or NORMAL_FONT_COLOR
        local alpha = m.online and 1 or 0.55   -- Offline-Mitglieder gedimmt
        row.left:SetText(("|cff%02x%02x%02x%s|r"):format(c.r * 255, c.g * 255, c.b * 255, m.name))
        row.left:SetAlpha(alpha); row.mid:SetAlpha(alpha)
        local mid = (m.level and m.level > 0) and ("Lvl %d · %s"):format(m.level, m.rank or "") or (m.rank or "")
        if source and m.inGuild then mid = mid .. "  |cff999999(" .. L["Gilde"] .. ")|r" end
        if m.note and m.note ~= "" then mid = mid .. "  |cff888888" .. m.note .. "|r" end
        row.mid:SetText(mid)
        row.right:SetText(m.online and ("|cff40ff40●|r " .. (m.zone or "")) or ("|cff777777" .. (m.last or "") .. "|r"))
    end
    memberList:Finish(#data)
end

-- Community-Mitglieder ändern sich -> Liste neu zeichnen (gebündelt)
if HAS_CLUB then
    local pending
    local cf = CreateFrame("Frame")
    for _, e in ipairs({ "CLUB_MEMBER_ADDED", "CLUB_MEMBER_REMOVED", "CLUB_MEMBER_UPDATED",
                         "CLUB_MEMBER_PRESENCE_UPDATED", "CLUB_REMOVED" }) do
        pcall(cf.RegisterEvent, cf, e)
    end
    cf:SetScript("OnEvent", function(_, _, clubId)
        if not (source and members:IsVisible()) or pending then return end
        if clubId and clubId ~= source.id then return end
        pending = C_Timer.NewTimer(0.5, function() pending = nil; members:Refresh() end)
    end)
    members:HookScript("OnHide", function()
        if C_Club.ClearClubPresenceSubscription then pcall(C_Club.ClearClubPresenceSubscription) end
    end)
    members:HookScript("OnShow", function()
        if source and C_Club.SetClubPresenceSubscription then pcall(C_Club.SetClubPresenceSubscription, source.id) end
    end)
end

---------------------------------------------------------------------
-- 3) Meilensteine (Verlauf)
---------------------------------------------------------------------
local milestones = AddTab(L["Meilensteine"])
local msList = CreateList(milestones, 24)

function milestones:Refresh()
    local log = GuildPrideDB.log or {}
    for i, e in ipairs(log) do
        local row = msList:GetRow(i)
        if not row.badge then
            row.badge = row:CreateTexture(nil, "ARTWORK")
            row.badge:SetSize(22, 22)
            row.badge:SetPoint("LEFT", 4, 0)
            row.left:SetPoint("LEFT", 32, 0)
        end
        row.badge:SetShown(e.kind ~= nil)
        if e.kind and ns.BadgeFor then row.badge:SetTexture(ns.BadgeFor(e.kind, e.value)) end
        row.left:SetText("|cfff0c88c" .. e.who .. "|r")
        row.mid:SetText(e.text)
        row.right:SetText(date("%d.%m. %H:%M", e.t))
    end
    msList:Finish(#log)
end

---------------------------------------------------------------------
-- 4) Einstellungen
---------------------------------------------------------------------
local settings = AddTab(L["Einstellungen"])
local options = {
    { key = "replaceGuildFrame", label = L["Dieses Fenster statt Blizzard-Gildenfenster (J)"] },
    { key = "popup",         label = L["Meilenstein-Popups anzeigen"] },
    { key = "sound",         label = L["Sounds abspielen"] },
    { key = "chatIcon",      label = L["Gilden-Logo im Chat"] },
    { key = "memberAlerts",  label = L["Warnung bei Beitritt / Austritt"] },
    { key = "helpAlerts",    label = L["Hinweis, wenn jemand Gruppe / Quest-Hilfe sucht"] },
}
local checks = {}
for i, opt in ipairs(options) do
    local cb = CreateFrame("CheckButton", nil, settings, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 0, -(i - 1) * 34)
    local label = settings:CreateFontString(nil, "OVERLAY", "GPFont_Text")
    label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    label:SetText(opt.label)
    cb:SetScript("OnClick", function(self)
        GuildPrideDB[opt.key] = self:GetChecked() and true or false
    end)
    checks[opt.key] = cb
end

local blizzBtn = CreateFrame("Button", nil, settings, "UIPanelButtonTemplate")
blizzBtn:SetSize(220, 26)
blizzBtn:SetPoint("TOPLEFT", 4, -(#options * 34) - 16)
blizzBtn:SetText(L["Blizzard-Gildenfenster öffnen"])
blizzBtn:SetScript("OnClick", function() ns.OpenBlizzardGuild() end)

function settings:Refresh()
    for key, cb in pairs(checks) do cb:SetChecked(GuildPrideDB[key]) end
end

---------------------------------------------------------------------
-- Öffnen / Aktualisieren
---------------------------------------------------------------------
function ns.RefreshUI()
    if not frame:IsShown() then return end
    UpdateHeader()
    local page = pages[frame.selected or 1]
    if page and page.Refresh then page:Refresh() end
end

function ns.ToggleUI()
    if InCombatLockdown() and not frame:IsShown() then
        ns.Print(L["|cffff4040Im Kampf kann das Gildenfenster nicht geöffnet werden.|r"])
        return
    end
    if frame:IsShown() then
        frame:Hide()
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
    else
        if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
        frame:Show()
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
        UpdateHeader()
        SelectTab(frame.selected or 1)
    end
end

---------------------------------------------------------------------
-- Blizzard-Gildenfenster ersetzen
---------------------------------------------------------------------
local bypass = false

function ns.OpenBlizzardGuild()
    frame:Hide()
    bypass = true
    ToggleGuildFrame()
    bypass = false
end

-- Wir überschreiben ToggleGuildFrame NICHT (würde Taint verursachen),
-- sondern schließen das Blizzard-Fenster direkt nach dem Öffnen wieder.
hooksecurefunc("ToggleGuildFrame", function()
    -- Im Kampf: jedes Gildenfenster blocken (auch das von Blizzard)
    if InCombatLockdown() then
        if CommunitiesFrame and CommunitiesFrame:IsShown() then CommunitiesFrame:Hide() end
        ns.Print(L["|cffff4040Im Kampf kann das Gildenfenster nicht geöffnet werden.|r"])
        return
    end
    if bypass or not GuildPrideDB or not GuildPrideDB.replaceGuildFrame then return end
    if not IsInGuild() then return end
    if CommunitiesFrame and CommunitiesFrame:IsShown() then
        HideUIPanel(CommunitiesFrame)
    end
    ns.ToggleUI()
end)

-- Bei Kampfbeginn offene Fenster schließen
local combat = CreateFrame("Frame")
combat:RegisterEvent("PLAYER_REGEN_DISABLED")
combat:SetScript("OnEvent", function()
    frame:Hide()
    if ns.CloseEventDialogs then ns.CloseEventDialogs() end
    if CommunitiesFrame and CommunitiesFrame:IsShown() then CommunitiesFrame:Hide() end
end)

-- Für andere Module freigeben
ns.AddTab = AddTab
ns.SelectTab = SelectTab
ns.CreateList = CreateList
ns.GuildFrame = frame
ns.MEDIA = MEDIA
