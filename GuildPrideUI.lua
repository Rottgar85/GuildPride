-- GuildPride: eigenes Gildenfenster im "Schmiede"-Stil
-- Seitenleiste mit Logo + Navigation links, Glut-Banner oben, Inhalt rechts
local ADDON, ns = ...
local L = ns.L

local MEDIA = "Interface\\AddOns\\GuildPride\\Media\\"
local CLASS_COLORS = RAID_CLASS_COLORS
local GOLD_TEXT = "|cfff0c88c"
local Paint = ns.Paint

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
Paint(bg, "tex")

-- Rahmen (2 px, Farbe je nach Style) und Ecken-Ornamente
local function Line(p1, p2, size)
    local t = frame:CreateTexture(nil, "BORDER")
    Paint(t, "accent")
    t:SetPoint(p1); t:SetPoint(p2)
    if p1:find("LEFT") and p2:find("LEFT") or p1:find("RIGHT") and p2:find("RIGHT") then t:SetWidth(size) else t:SetHeight(size) end
end
Line("TOPLEFT", "TOPRIGHT", 2)
Line("BOTTOMLEFT", "BOTTOMRIGHT", 2)
Line("TOPLEFT", "BOTTOMLEFT", 2)
Line("TOPRIGHT", "BOTTOMRIGHT", 2)

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
    Paint(t, "tex")
end

-- Seitenleiste
local side = frame:CreateTexture(nil, "BACKGROUND", nil, -6)
side:SetPoint("TOPLEFT", 2, -2)
side:SetPoint("BOTTOMLEFT", 2, 2)
side:SetWidth(SIDEBAR)
side:SetTexture(MEDIA .. "sidebar")
Paint(side, "tex")

-- Gildenkürzel + Wappenrock der Gilde (aus dem Spiel)
local tagText = frame:CreateFontString(nil, "OVERLAY", "GPFont_Huge")
tagText:SetPoint("TOP", frame, "TOPLEFT", SIDEBAR / 2 + 2, -14)

local crestGlow = frame:CreateTexture(nil, "ARTWORK", nil, 0)
crestGlow:SetSize(124, 124)
crestGlow:SetPoint("TOP", tagText, "BOTTOM", 0, 4)
crestGlow:SetTexture(MEDIA .. "crest_glow")
Paint(crestGlow, "tex")

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
Paint(header, "tex")

local title = frame:CreateFontString(nil, "OVERLAY", "GPFont_Huge")
title:SetPoint("TOPLEFT", header, "TOPLEFT", 24, -20)
title:SetShadowOffset(2, -2)

local subtitle = frame:CreateFontString(nil, "OVERLAY", "GPFont_Text")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 2, -6)

local pageTitle = frame:CreateFontString(nil, "OVERLAY", "GPFont_Large")
pageTitle:SetPoint("TOPRIGHT", header, "TOPRIGHT", -46, -24)
Paint(pageTitle, "title")

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

local function MarkTabs()
    local t = ns.Theme()
    for i, tab in ipairs(tabs) do
        local on = i == frame.selected
        tab.bgTex:SetTexture(MEDIA .. (on and "nav_active" or "nav"))
        if on then tab.text:SetTextColor(t.button[1], t.button[2], t.button[3])
        else tab.text:SetTextColor(0.82, 0.79, 0.76) end
    end
end
ns.OnThemeChanged(MarkTabs)

local function SelectTab(id)
    for i, page in ipairs(pages) do page:SetShown(i == id) end
    frame.selected = id
    MarkTabs()
    pageTitle:SetText(tabs[id] and tabs[id].label or "")
    if pages[id] and pages[id].Refresh then pages[id]:Refresh() end
end

-- Reiter nach "order" sortiert untereinander; ab Ordnung 90 (Einstellungen)
-- unten in der Seitenleiste
local function LayoutTabs()
    local sorted = {}
    for _, tab in ipairs(tabs) do sorted[#sorted + 1] = tab end
    table.sort(sorted, function(a, b) return a.order < b.order end)
    local top, bottom = 0, 0
    for _, tab in ipairs(sorted) do
        tab:ClearAllPoints()
        if tab.order >= 90 then
            tab:SetPoint("BOTTOMLEFT", 10, 34 + bottom * 40)
            bottom = bottom + 1
        else
            tab:SetPoint("TOPLEFT", 10, -168 - top * 40)
            top = top + 1
        end
    end
end

-- order: Platz in der Seitenleiste (kleiner = weiter oben)
local function AddTab(label, order)
    local id = #pages + 1
    local page = CreateFrame("Frame", nil, content)
    page:SetAllPoints()
    page:Hide()
    pages[id] = page

    local tab = CreateFrame("Button", nil, frame)
    tab:SetSize(SIDEBAR - 16, 36)
    tab.bgTex = tab:CreateTexture(nil, "BACKGROUND")
    tab.bgTex:SetAllPoints()
    tab.bgTex:SetTexture(MEDIA .. "nav")
    Paint(tab.bgTex, "tex")
    local hl = tab:CreateTexture(nil, "HIGHLIGHT")
    hl:SetPoint("TOPLEFT", 3, -3); hl:SetPoint("BOTTOMRIGHT", -3, 3)
    Paint(hl, "glow", 0.12)
    tab.text = tab:CreateFontString(nil, "OVERLAY", "GPFont_Normal")
    tab.text:SetPoint("LEFT", 18, 0)
    tab.text:SetText(label)
    tab.label = label
    tab.order = order or id * 10
    tab:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
        SelectTab(id)
    end)
    tabs[id] = tab
    page.tabId = id
    LayoutTabs()
    return page
end

-- Zusatz hinter dem Reiternamen, z. B. ungelesene Nachrichten "(3)"
function ns.SetTabBadge(page, text)
    local tab = tabs[page.tabId]
    if not tab then return end
    tab.text:SetText(tab.label .. (text and ("  |cffff8c40" .. text .. "|r") or ""))
end

-- Abschnitts-Überschrift mit Kupferlinie
local function Section(parent, text, anchor, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GPFont_Large")
    if anchor then fs:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y or -20) else fs:SetPoint("TOPLEFT", 4, y or -4) end
    fs:SetText(text)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("LEFT", fs, "RIGHT", 10, 0)
    line:SetPoint("RIGHT", parent, "RIGHT", -4, 0)
    Paint(line, "accent", 0.5)
    return fs
end
ns.Section = Section

-- Scrollbereich mit schmalem Blizzard-Scrollbalken wie im Chat
-- (ältere Clients ohne die Vorlage: klassischer Balken)
function ns.NewScroll(parent)
    local ok, scroll = pcall(CreateFrame, "ScrollFrame", nil, parent, "ScrollFrameTemplate")
    if not ok or not scroll then scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate") end
    return scroll
end

-- Scrollbare Liste (width: Zeilenbreite, Standard 620)
local function CreateList(parent, rowHeight, width)
    width = width or 620
    local scroll = ns.NewScroll(parent)
    scroll:SetPoint("TOPLEFT", 0, -4)
    scroll:SetPoint("BOTTOMRIGHT", -26, 0)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(width, 1)
    scroll:SetScrollChild(child)
    child.rows = {}
    function child:GetRow(i)
        local row = self.rows[i]
        if not row then
            row = CreateFrame("Frame", nil, self)
            row:SetSize(width, rowHeight)
            row:SetPoint("TOPLEFT", 0, -(i - 1) * rowHeight)
            row.bg = row:CreateTexture(nil, "BACKGROUND")
            row.bg:SetAllPoints()
            Paint(row.bg, "glow", i % 2 == 0 and 0.05 or 0)
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
local overview = AddTab(L["Übersicht"], 10)
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
    Paint(edge, "ember")
    f.value = f:CreateFontString(nil, "OVERLAY", "GPFont_Huge")
    f.value:SetPoint("TOPLEFT", 14, -10)
    Paint(f.value, "button")
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

local weekLabel = Section(overview, L["Diese Woche"], motd, -26)
local weekText = overview:CreateFontString(nil, "OVERLAY", "GPFont_Text")
weekText:SetPoint("TOPLEFT", weekLabel, "BOTTOMLEFT", 0, -10)
weekText:SetWidth(620); weekText:SetJustifyH("LEFT"); weekText:SetSpacing(4)

-- Wochenrückblick aus dem Verlauf (seit dem letzten Wochenreset)
local WEEK_KINDS = {
    { kinds = { LEVEL = true }, label = L["Level-Aufstiege"] },
    { kinds = { BOSS = true },  label = L["Raid-Siege"] },
    { kinds = { MPLUS = true }, label = L["M+-Bestwerte"], retail = true },
    { kinds = { ACH = true },   label = L["Erfolge"] },
    { kinds = { MOUNT = true }, label = L["Reittiere"] },
    { kinds = { JOIN = true },  label = L["Neue Mitglieder"] },
    { kinds = { LEAVE = true, KICK = true }, label = L["Abgänge"] },
}
local function WeekSummary()
    local since, counts, byWho = ns.WeekStart(), {}, {}
    for _, e in ipairs(GuildPrideDB.log or {}) do
        if (e.t or 0) >= since then
            for i, w in ipairs(WEEK_KINDS) do
                if w.kinds[e.kind] then counts[i] = (counts[i] or 0) + 1 end
            end
            if e.kind ~= "JOIN" and e.kind ~= "LEAVE" and e.kind ~= "KICK" and e.who then
                byWho[e.who] = (byWho[e.who] or 0) + 1
            end
        end
    end
    local parts = {}
    for i, w in ipairs(WEEK_KINDS) do
        if not w.retail or ns.IS_RETAIL then
            parts[#parts + 1] = ("%s |cffffd18c%d|r"):format(w.label, counts[i] or 0)
        end
    end
    local text = table.concat(parts, "  ·  ")
    local best, n = nil, 0
    for who, c in pairs(byWho) do if c > n then best, n = who, c end end
    if best then text = text .. "\n" .. (L["Fleißigstes Mitglied: |cfff0c88c%s|r (%d Meilensteine)"]):format(best, n) end
    return text
end

local recentLabel = Section(overview, L["Letzte Meilensteine"], weekText, -26)
local recent = overview:CreateFontString(nil, "OVERLAY", "GPFont_Text")
recent:SetPoint("TOPLEFT", recentLabel, "BOTTOMLEFT", 0, -10)
recent:SetWidth(620); recent:SetJustifyH("LEFT"); recent:SetSpacing(6)

function overview:Refresh()
    local total, online = GetNumGuildMembers()
    tiles[1].value:SetText(("%d / %d"):format(online or 0, total or 0))

    local nextEvent
    if ns.RollEvents then ns.RollEvents() end   -- wöchentliche Events auf den nächsten Termin
    for _, e in pairs(GuildPrideDB.events or {}) do
        if e.title and not e.deleted and e.t and e.t > GetServerTime() and (not nextEvent or e.t < nextEvent.t) then
            nextEvent = e
        end
    end
    tiles[2].value:SetText(nextEvent and ns.FormatDate(nextEvent.t, "short") or "–")
    tiles[2].label:SetText(nextEvent and (L["NÄCHSTES EVENT: "] .. nextEvent.title:upper()) or L["NÄCHSTES EVENT"])

    local week, cutoff = 0, ns.WeekStart()
    for _, e in ipairs(GuildPrideDB.log or {}) do if e.t >= cutoff then week = week + 1 end end
    tiles[3].value:SetText(week)

    local text = GetGuildRosterMOTD and GetGuildRosterMOTD() or ""
    motd:SetText(text ~= "" and text or L["|cff888888Keine Nachricht gesetzt.|r"])
    weekText:SetText(WeekSummary())
    local lines = {}
    for i = 1, math.min(5, #(GuildPrideDB.log or {})) do
        local e = GuildPrideDB.log[i]
        local icon = (e.kind == "LEVEL" and ns.BadgeFor) and ("|T%s:18|t"):format(ns.BadgeFor(e.kind, e.value)) or "|cffff8c40•|r"
        lines[#lines + 1] = ("%s |cfff0c88c%s|r %s  |cff777777%s|r"):format(icon, e.who, ns.LogText(e), ns.FormatDay(e.t))
    end
    recent:SetText(#lines > 0 and table.concat(lines, "\n") or L["|cff888888Noch keine Meilensteine.|r"])
end

---------------------------------------------------------------------
-- 2) Gilde & Chat – wie Blizzards Community-Fenster: Chat links, Mitglieder
--    rechts. "Mitgliederliste" schaltet auf die große Liste mit Details um.
--    Die Kanal-Leiste oben links (GuildPrideChat.lua) bestimmt auch, wessen
--    Mitglieder angezeigt werden (Gilde oder eine Community).
---------------------------------------------------------------------
local community = AddTab(L["Gilde & Chat"], 20)
local ROSTER_W = 210

local bViewList = CreateFrame("Button", nil, community, "UIPanelButtonTemplate")
bViewList:SetSize(130, 24); bViewList:SetPoint("TOPRIGHT", 0, 0); bViewList:SetText(L["Mitgliederliste"])
local bViewChat = CreateFrame("Button", nil, community, "UIPanelButtonTemplate")
bViewChat:SetSize(70, 24); bViewChat:SetPoint("RIGHT", bViewList, "LEFT", -6, 0); bViewChat:SetText(L["Chat"])

-- Chat-Bereich (wird von GuildPrideChat.lua gefüllt)
local chatPane = CreateFrame("Frame", nil, community)
chatPane:SetPoint("TOPLEFT", 0, -32)
chatPane:SetPoint("BOTTOMRIGHT", -(ROSTER_W + 10), 0)

-- Kompakte Mitgliederliste neben dem Chat
local roster = CreateFrame("Frame", nil, community)
roster:SetPoint("TOPRIGHT", 0, -32)
roster:SetPoint("BOTTOMRIGHT", 0, 0)
roster:SetWidth(ROSTER_W)

-- Große Mitgliederliste (statt Chat)
local members = CreateFrame("Frame", nil, community)
members:SetPoint("TOPLEFT", 0, -32)
members:SetPoint("BOTTOMRIGHT")
members:Hide()

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

-- Große Liste, Kopfzeile: Nur online | Alle
local bOnline = CreateFrame("Button", nil, members, "UIPanelButtonTemplate")
bOnline:SetSize(110, 24); bOnline:SetPoint("TOPLEFT", 0, 0); bOnline:SetText(L["Nur online"])
local bAll = CreateFrame("Button", nil, members, "UIPanelButtonTemplate")
bAll:SetSize(150, 24); bAll:SetPoint("LEFT", bOnline, "RIGHT", 6, 0); bAll:SetText(L["Alle (inkl. offline)"])

-- Suche (Name, Rang, Notiz, Zone)
local searchBox = CreateFrame("EditBox", nil, members, "InputBoxTemplate")
searchBox:SetSize(150, 22); searchBox:SetPoint("LEFT", bAll, "RIGHT", 14, 0)
searchBox:SetAutoFocus(false); searchBox:SetMaxLetters(30)
local searchHint = searchBox:CreateFontString(nil, "OVERLAY", "GPFont_Muted")
searchHint:SetPoint("LEFT", 2, 0); searchHint:SetText(L["Suchen …"])
searchBox:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
searchBox:SetScript("OnEnterPressed", searchBox.ClearFocus)

-- Inaktive Mitglieder (nur Gilde, nur wer entfernen darf): aus -> 30 -> 60 -> 90 Tage
local INACTIVE_STEPS = { 0, 30, 60, 90 }
local inactiveDays = 0
local bInactive = CreateFrame("Button", nil, members, "UIPanelButtonTemplate")
bInactive:SetSize(150, 24); bInactive:SetPoint("TOPRIGHT", 0, 0)

-- Spaltenköpfe: Klick sortiert, erneuter Klick dreht die Richtung
local SORT_COLS = {
    { key = "name",  label = L["Name"],             x = 8 },
    { key = "level", label = L["Level"],            x = 200 },
    { key = "rank",  label = L["Rang"],             x = 260 },
    { key = "last",  label = L["Online / zuletzt"], right = true },
}
local sortHeads = {}
local function MarkSort()
    local s = GuildPrideDB.memberSort or {}
    for _, h in ipairs(sortHeads) do
        local on = (s.key or "last") == h.key
        local arrow = s.desc and "Interface\\Buttons\\Arrow-Up-Up" or "Interface\\Buttons\\Arrow-Down-Up"
        h.text:SetText(h.label .. (on and (" |T" .. arrow .. ":10|t") or ""))
        if on then h.text:SetTextColor(1, 0.82, 0.55) else h.text:SetTextColor(0.6, 0.56, 0.52) end
    end
end
for _, c in ipairs(SORT_COLS) do
    local h = CreateFrame("Button", nil, members)
    h:SetSize(110, 16)
    if c.right then h:SetPoint("TOPRIGHT", -34, -30) else h:SetPoint("TOPLEFT", c.x, -30) end
    h.text = h:CreateFontString(nil, "OVERLAY", "GPFont_MutedSmall")
    h.text:SetPoint(c.right and "RIGHT" or "LEFT")
    h.key, h.label = c.key, c.label
    h:SetScript("OnClick", function(self)
        local s = GuildPrideDB.memberSort or {}
        if (s.key or "last") == self.key then s.desc = not s.desc else s.key, s.desc = self.key, false end
        GuildPrideDB.memberSort = s
        members:Refresh()
    end)
    sortHeads[#sortHeads + 1] = h
end

local listHolder = CreateFrame("Frame", nil, members)
listHolder:SetPoint("TOPLEFT", 0, -46)
listHolder:SetPoint("BOTTOMRIGHT", 0, 36)
local memberList = CreateList(listHolder, 24)

-- Kompakte Liste: Kopf mit Anzahl und "Offline zeigen", darunter die Namen
local rosterBg = roster:CreateTexture(nil, "BACKGROUND")
rosterBg:SetAllPoints(); rosterBg:SetColorTexture(0, 0, 0, 0.45)
local rosterCount = roster:CreateFontString(nil, "OVERLAY", "GPFont_MutedSmall")
rosterCount:SetPoint("TOPLEFT", 10, -10)
local rosterOffline = CreateFrame("CheckButton", nil, roster, "UICheckButtonTemplate")
rosterOffline:SetSize(20, 20); rosterOffline:SetPoint("TOPRIGHT", -4, -3)
local rosterOfflineText = roster:CreateFontString(nil, "OVERLAY", "GPFont_MutedSmall")
rosterOfflineText:SetPoint("RIGHT", rosterOffline, "LEFT", -2, 0); rosterOfflineText:SetText(L["Offline zeigen"])
local rosterHolder = CreateFrame("Frame", nil, roster)
rosterHolder:SetPoint("TOPLEFT", 6, -24)
rosterHolder:SetPoint("BOTTOMRIGHT", -2, 4)
local rosterList = CreateList(rosterHolder, 20, ROSTER_W - 34)

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

-- Beide Listen neu zeichnen (nur die sichtbare)
local function RefreshMembers()
    if members:IsShown() then members:Refresh() end
    if roster:IsShown() then roster:Refresh() end
end

local function SetOffline(on)
    showOffline = on
    -- Manche Clients liefern Offline-Mitglieder nur, wenn das eingeschaltet ist
    if not source then
        if SetGuildRosterShowOffline then SetGuildRosterShowOffline(on) end
        if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
    end
    RefreshMembers()
end
bOnline:SetScript("OnClick", function() SetOffline(false) end)
bAll:SetScript("OnClick", function() SetOffline(true) end)
searchBox:SetScript("OnTextChanged", function(self)
    searchHint:SetShown(self:GetText() == "")
    if members:IsShown() then members:Refresh() end
end)
bInactive:SetScript("OnClick", function()
    for i, d in ipairs(INACTIVE_STEPS) do
        if d == inactiveDays then inactiveDays = INACTIVE_STEPS[i % #INACTIVE_STEPS + 1]; break end
    end
    -- Offline-Mitglieder vom Server holen
    if inactiveDays > 0 and SetGuildRosterShowOffline then SetGuildRosterShowOffline(true) end
    if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
    members:Refresh()
end)
rosterOffline:SetScript("OnClick", function(self) SetOffline(self:GetChecked() and true or false) end)

-- Wessen Mitglieder? nil = Gilde, sonst { id, name, bnet } einer Community.
-- Wird beim Kanalwechsel im Chat aufgerufen.
function ns.SetMemberSource(club)
    if (club and club.id) == (source and source.id) then return end
    source = club
    if ns.HideMemberPanel then ns.HideMemberPanel() end
    -- Online-Status der Community-Mitglieder vom Server holen
    if C_Club and C_Club.ClearClubPresenceSubscription then pcall(C_Club.ClearClubPresenceSubscription) end
    if club and C_Club.SetClubPresenceSubscription then pcall(C_Club.SetClubPresenceSubscription, club.id) end
    if not club and C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
    RefreshMembers()
end

-- Chat oder große Liste
local function SetView(list)
    GuildPrideDB.listView = list
    chatPane:SetShown(not list); roster:SetShown(not list); members:SetShown(list)
    if bViewChat.gpBg then bViewChat.gpBg:SetTexture(MEDIA .. (list and "nav" or "nav_active")) end
    if bViewList.gpBg then bViewList.gpBg:SetTexture(MEDIA .. (list and "nav_active" or "nav")) end
    RefreshMembers()
end
bViewChat:SetScript("OnClick", function() SetView(false) end)
bViewList:SetScript("OnClick", function() SetView(true) end)

function community:Refresh()
    SetView(GuildPrideDB.listView and true or false)
    if ns.ChatRefresh then ns.ChatRefresh() end
end

-- Für Chat und Mitgliederverwaltung (GuildPrideChat.lua, GuildPrideManage.lua)
ns.Communities = Communities
ns.CanInviteToClub = CanInviteToClub
ns.FullName = FullName
ns.CommunityPage = community
ns.ChatPane = chatPane
ns.MembersPage = community

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

local function GuildData(withOffline)
    local data, total, online = {}, 0, 0
    for i = 1, GetNumGuildMembers() do
        local name, rank, rankIndex, level, _, zone, note, officerNote, isOnline, _, classFile = GetGuildRosterInfo(i)
        if name then
            total = total + 1
            if isOnline then online = online + 1 end
            if isOnline or withOffline then
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

local function ClubData(club, inGuild, withOffline)
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
            if isOnline or withOffline then
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

local function Plain(v)
    return type(v) == "string" and not (issecretvalue and issecretvalue(v)) and v or ""
end

-- Passt das Mitglied zur Suche? (Name, Rang, Notiz, Zone)
local function Matches(m, q)
    if q == "" then return true end
    for _, v in ipairs({ m.name, m.rank, m.note, m.zone }) do
        if Plain(v):lower():find(q, 1, true) then return true end
    end
    return false
end

-- Sortierwert je Spalte; "last": online zuerst, dann zuletzt online
local function SortValue(m, key)
    if key == "name" then return Plain(m.name):lower() end
    if key == "level" then return -(m.level or 0) end
    if key == "rank" then return m.rankIndex or m.role or 99 end
    return m.online and -1 or (m.hours or 0)
end

-- Mitglieder der aktuellen Quelle
-- opts: offline (auch Offline), query (Suche), inactive (Tage, nur Offline ab da),
--       sort/desc (Spalte und Richtung, Standard "last")
local function MemberData(opts)
    opts = opts or {}
    -- Community nicht mehr vorhanden (verlassen) -> zurück zur Gilde
    if source and not (C_Club.GetClubInfo and C_Club.GetClubInfo(source.id)) then source = nil end
    local inactive = opts.inactive or 0
    local withOffline = opts.offline or inactive > 0
    local data, total, online
    if source then data, total, online = ClubData(source, GuildNames(), withOffline) else data, total, online = GuildData(withOffline) end
    local q, keep = strtrim(opts.query or ""):lower(), {}
    for _, m in ipairs(data) do
        if Matches(m, q) and (inactive == 0 or (not m.online and (m.hours or 0) >= inactive * 24)) then keep[#keep + 1] = m end
    end
    local key = opts.sort or "last"
    table.sort(keep, function(a, b)
        local va, vb = SortValue(a, key), SortValue(b, key)
        if va ~= vb then if opts.desc then return va > vb end return va < vb end
        if a.online ~= b.online then return a.online end
        return Plain(a.name):lower() < Plain(b.name):lower()
    end)
    return keep, total, online
end

local function ClassName(m)
    local c = CLASS_COLORS[m.class] or NORMAL_FONT_COLOR
    return ("|cff%02x%02x%02x%s|r"):format(c.r * 255, c.g * 255, c.b * 255, m.name)
end

-- Linksklick: Details/Verwaltung · Rechtsklick: Menü (GuildPrideManage.lua)
local function RowClicks(row)
    row:EnableMouse(true)
    row:SetScript("OnMouseUp", function(self, button)
        if not self.data then return end
        if button == "RightButton" then
            if ns.MemberMenu then ns.MemberMenu(self, self.data) end
        elseif ns.ShowMemberPanel then
            ns.ShowMemberPanel(self.data, self)
        end
    end)
end

function members:Refresh()
    local function mark(btn, on)
        if btn.gpBg then btn.gpBg:SetTexture(MEDIA .. (on and "nav_active" or "nav")) end
    end
    mark(bOnline, not showOffline); mark(bAll, showOffline)
    inviteBtn:SetText(source and L["In Community einladen"] or L["In Gilde einladen"])
    -- Inaktive: nur Gilde, nur wer Mitglieder entfernen darf
    local canInactive = not source and ((CanGuildRemove and CanGuildRemove()) or ns.IsOfficer())
    if not canInactive then inactiveDays = 0 end
    bInactive:SetShown(canInactive and true or false)
    bInactive:SetText(inactiveDays > 0 and (L["Inaktiv %d+ Tage"]):format(inactiveDays) or L["Inaktive: aus"])
    MarkSort()

    local s = GuildPrideDB.memberSort or {}
    local data, total, online = MemberData({ offline = showOffline, sort = s.key, desc = s.desc,
                                             query = searchBox:GetText(), inactive = inactiveDays })
    countText:SetText((L["%d online · %d offline"]):format(online, total - online))
    for i, m in ipairs(data) do
        local row = memberList:GetRow(i)
        if not row.gpMenu then
            row.gpMenu = true
            row.mid:SetWidth(260); row.mid:SetJustifyH("LEFT"); row.mid:SetWordWrap(false)
            RowClicks(row)
        end
        row.data = m
        local alpha = m.online and 1 or 0.55   -- Offline-Mitglieder gedimmt
        row.left:SetText(ClassName(m))
        row.left:SetAlpha(alpha); row.mid:SetAlpha(alpha)
        local mid = (m.level and m.level > 0) and ("Lvl %d · %s"):format(m.level, m.rank or "") or (m.rank or "")
        if source and m.inGuild then mid = mid .. "  |cff999999(" .. L["Gilde"] .. ")|r" end
        local key = ns.KeyText and m.full and ns.KeyText(m.full)
        if key then mid = mid .. "  " .. key end
        if m.note and m.note ~= "" then mid = mid .. "  |cff888888" .. m.note .. "|r" end
        row.mid:SetText(mid)
        row.right:SetText(m.online and ("|cff40ff40●|r " .. (m.zone or "")) or ("|cff777777" .. (m.last or "") .. "|r"))
    end
    memberList:Finish(#data)
end

-- Kompakte Liste: Name und Level, Rest im Tooltip
local function RosterTooltip(row)
    local m = row.data
    if not m then return end
    GameTooltip:SetOwner(row, "ANCHOR_LEFT")
    GameTooltip:AddLine(ClassName(m))
    if m.level and m.level > 0 then GameTooltip:AddLine(("Lvl %d"):format(m.level), 1, 1, 1) end
    if m.rank and m.rank ~= "" then GameTooltip:AddLine((L["Rang: %s"]):format(m.rank), 0.8, 0.8, 0.8) end
    if m.online then GameTooltip:AddLine("|cff40ff40●|r " .. (m.zone or ""), 1, 1, 1)
    else GameTooltip:AddLine(m.last or L["offline"], 0.5, 0.5, 0.5) end
    if m.note and m.note ~= "" then GameTooltip:AddLine(m.note, 0.6, 0.6, 0.6, true) end
    if ns.KeyTooltip and m.full then ns.KeyTooltip(GameTooltip, m.full) end
    GameTooltip:Show()
end

function roster:Refresh()
    rosterOffline:SetChecked(showOffline)
    local data, total, online = MemberData({ offline = showOffline })
    rosterCount:SetText((L["%d online · %d offline"]):format(online, total - online))
    for i, m in ipairs(data) do
        local row = rosterList:GetRow(i)
        if not row.gpMenu then
            row.gpMenu = true
            row.mid:Hide()
            row.left:SetPoint("RIGHT", row.right, "LEFT", -4, 0)
            row.left:SetWordWrap(false)
            RowClicks(row)
            row:SetScript("OnEnter", RosterTooltip)
            row:SetScript("OnLeave", GameTooltip_Hide)
        end
        row.data = m
        local alpha = m.online and 1 or 0.55
        row.left:SetText((m.online and "|cff40ff40●|r " or "|cff555555●|r ") .. ClassName(m))
        row.left:SetAlpha(alpha)
        row.right:SetText((m.level and m.level > 0) and m.level or "")
    end
    rosterList:Finish(#data)
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
        if not (source and community:IsVisible()) or pending then return end
        if clubId and clubId ~= source.id then return end
        pending = C_Timer.NewTimer(0.5, function() pending = nil; RefreshMembers() end)
    end)
    community:HookScript("OnHide", function()
        if C_Club.ClearClubPresenceSubscription then pcall(C_Club.ClearClubPresenceSubscription) end
    end)
    community:HookScript("OnShow", function()
        if source and C_Club.SetClubPresenceSubscription then pcall(C_Club.SetClubPresenceSubscription, source.id) end
    end)
end

---------------------------------------------------------------------
-- 3) Meilensteine (Verlauf)
---------------------------------------------------------------------
local milestones = AddTab(L["Meilensteine"], 60)
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
        local badged = e.kind == "LEVEL" or (ns.EXTRA_KINDS and ns.EXTRA_KINDS[e.kind])
        row.badge:SetShown(badged and true or false)
        if badged and ns.BadgeFor then row.badge:SetTexture(ns.BadgeFor(e.kind, e.value)) end
        row.left:SetText("|cfff0c88c" .. e.who .. "|r")
        row.mid:SetText(ns.LogText(e))
        row.right:SetText(ns.FormatDay(e.t, true))
    end
    msList:Finish(#log)
end

-- Beim Öffnen verpasste Einträge von anderen holen (höchstens alle 2 Minuten)
local lastHistoryAsk = 0
milestones:HookScript("OnShow", function()
    if GetTime() - lastHistoryAsk < 120 or not ns.RequestHistory then return end
    lastHistoryAsk = GetTime()
    ns.RequestHistory()
end)

---------------------------------------------------------------------
-- 4) Einstellungen
---------------------------------------------------------------------
local settingsPage = AddTab(L["Einstellungen"], 90)
-- Die Seite ist länger als das Fenster: Inhalt in einem Scrollbereich
local settingsScroll = ns.NewScroll(settingsPage)
settingsScroll:SetPoint("TOPLEFT", 0, 0)
settingsScroll:SetPoint("BOTTOMRIGHT", -26, 0)
local settings = CreateFrame("Frame", nil, settingsScroll)
settings:SetSize(640, 1)
settingsScroll:SetScrollChild(settings)

-- Style-Auswahl ganz oben: ein Knopf je Style, der aktive ist hervorgehoben
local styleLabel = settings:CreateFontString(nil, "OVERLAY", "GPFont_TextBold")
styleLabel:SetPoint("TOPLEFT", 4, -4)
styleLabel:SetText(L["Style"])
local styleButtons = {}
for i, t in ipairs(ns.THEMES) do
    local b = CreateFrame("Button", nil, settings, "UIPanelButtonTemplate")
    b:SetSize(98, 24)
    b:SetPoint("TOPLEFT", 4 + (i - 1) * 104, -22)
    b:SetText(t.name)
    b:SetScript("OnClick", function() ns.ApplyTheme(t.key) end)
    -- Farbtupfer des Styles
    local dot = b:CreateTexture(nil, "OVERLAY")
    dot:SetSize(8, 8); dot:SetPoint("LEFT", 8, 0)
    b.dot, b.theme = dot, t
    b.key = t.key
    styleButtons[i] = b
end
local function MarkStyle()
    local current = ns.Theme().key
    for _, b in ipairs(styleButtons) do
        if b.gpBg then b.gpBg:SetTexture(MEDIA .. (b.key == current and "nav_active" or "nav")) end
        local c = b.theme.ember   -- "Eigene" ändert die Farbe
        b.dot:SetColorTexture(c[1], c[2], c[3], 1)
    end
end
ns.OnThemeChanged(MarkStyle)

-- Eigener Style: Farbe über Blizzards Farbwähler
local colorBtn = CreateFrame("Button", nil, settings, "UIPanelButtonTemplate")
colorBtn:SetSize(170, 22); colorBtn:SetPoint("TOPLEFT", 4, -50)
colorBtn:SetText(L["Eigene Farbe wählen …"])
colorBtn:SetScript("OnClick", function() ns.PickCustomColor() end)

local OPT_Y = -80
local options = {
    { key = "replaceGuildFrame", label = L["Dieses Fenster statt Blizzard-Gildenfenster (J)"] },
    { key = "popup",         label = L["Meilenstein-Popups anzeigen"] },
    { key = "sound",         label = L["Sounds abspielen"] },
    { key = "memberAlerts",  label = L["Warnung bei Beitritt / Austritt"] },
    { key = "helpAlerts",    label = L["Hinweis, wenn jemand Gruppe / Quest-Hilfe sucht"] },
    { key = "shareMilestones", label = L["Eigene Erfolge, Bosse, M+ und Reittiere mit der Gilde teilen"] },
    { key = "minimap",       label = L["Minimap-Knopf anzeigen"],
      changed = function() if ns.UpdateMinimap then ns.UpdateMinimap() end end },
    { key = "welcome",       label = L["Neue Mitglieder automatisch im Gildenchat begrüßen"] },
}
local function SetOption(opt, on)
    GuildPrideDB[opt.key] = on and true or false
    if opt.changed then opt.changed() end
end
local checks = {}
for i, opt in ipairs(options) do
    local cb = CreateFrame("CheckButton", nil, settings, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 0, OPT_Y - (i - 1) * 30)
    local label = settings:CreateFontString(nil, "OVERLAY", "GPFont_Text")
    label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    label:SetText(opt.label)
    cb:SetScript("OnClick", function(self) SetOption(opt, self:GetChecked()) end)
    checks[opt.key] = cb
end

local blizzBtn = CreateFrame("Button", nil, settings, "UIPanelButtonTemplate")
blizzBtn:SetSize(220, 26)
blizzBtn:SetPoint("TOPLEFT", 4, OPT_Y - (#options * 30) - 8)
blizzBtn:SetText(L["Blizzard-Gildenfenster öffnen"])
blizzBtn:SetScript("OnClick", function() ns.OpenBlizzardGuild() end)

-- Begrüßungstext (GuildPrideMembers.lua), {name} = neues Mitglied
local welcomeY = OPT_Y - (#options * 30) - 46
local welcomeLabel = settings:CreateFontString(nil, "OVERLAY", "GPFont_TextBold")
welcomeLabel:SetPoint("TOPLEFT", 4, welcomeY)
welcomeLabel:SetText(L["Begrüßungstext ({name} = neues Mitglied)"])
local welcomeBox = CreateFrame("EditBox", nil, settings, "InputBoxTemplate")
welcomeBox:SetSize(470, 22); welcomeBox:SetPoint("TOPLEFT", 10, welcomeY - 18)
welcomeBox:SetAutoFocus(false); welcomeBox:SetMaxLetters(200)
welcomeBox:SetScript("OnTextChanged", function(self, user)
    if user then GuildPrideDB.welcomeText = self:GetText() end
end)
welcomeBox:SetScript("OnEnterPressed", welcomeBox.ClearFocus)
welcomeBox:SetScript("OnEscapePressed", welcomeBox.ClearFocus)

-- Regler mit - / +: Fenstergröße, Deckkraft, Chat-Schrift
local function ApplyLook()
    frame:SetScale(GuildPrideDB.scale or 1)
    frame:SetAlpha(GuildPrideDB.alpha or 1)
end
local steppers = {}
local function Stepper(label, y, key, step, min, max, fmt, apply)
    local l = settings:CreateFontString(nil, "OVERLAY", "GPFont_Text")
    l:SetPoint("TOPLEFT", 8, y); l:SetWidth(170); l:SetText(label)
    local minus = CreateFrame("Button", nil, settings, "UIPanelButtonTemplate")
    minus:SetSize(26, 22); minus:SetPoint("LEFT", l, "RIGHT", 4, 0); minus:SetText("-")
    local value = settings:CreateFontString(nil, "OVERLAY", "GPFont_TextBold")
    value:SetPoint("LEFT", minus, "RIGHT", 6, 0); value:SetWidth(60)
    local plus = CreateFrame("Button", nil, settings, "UIPanelButtonTemplate")
    plus:SetSize(26, 22); plus:SetPoint("LEFT", value, "RIGHT", 6, 0); plus:SetText("+")
    local s = { value = value }
    function s.Show() value:SetText(fmt(GuildPrideDB[key])) end
    local function Change(d)
        local v = (GuildPrideDB[key] or min) + d
        v = math.max(min, math.min(max, math.floor(v / step + 0.5) * step))
        GuildPrideDB[key] = v
        apply(v)
        s.Show()
    end
    minus:SetScript("OnClick", function() Change(-step) end)
    plus:SetScript("OnClick", function() Change(step) end)
    steppers[#steppers + 1] = s
end
local lookY = welcomeY - 56
local function Pct(v) return ("%d %%"):format(math.floor((v or 1) * 100 + 0.5)) end
Stepper(L["Fenstergröße"], lookY, "scale", 0.05, 0.7, 1.3, Pct, ApplyLook)
Stepper(L["Deckkraft"], lookY - 28, "alpha", 0.05, 0.5, 1, Pct, ApplyLook)
Stepper(L["Chat-Schrift"], lookY - 56, "chatFont", 1, 10, 18, function(v) return ("%d pt"):format(v or 12) end,
    function(v) if ns.SetChatFont then ns.SetChatFont(v) end end)

local lookFrame = CreateFrame("Frame")
lookFrame:RegisterEvent("PLAYER_LOGIN")
lookFrame:SetScript("OnEvent", ApplyLook)

-- Werbetext: gespeichert und auf Knopfdruck in die Chat-Eingabe gelegt.
-- Abschicken (und Kanal wählen, z. B. "/2 ") macht der Spieler selbst.
local baseY = lookY - 96
local recruitLabel = settings:CreateFontString(nil, "OVERLAY", "GPFont_TextBold")
recruitLabel:SetPoint("TOPLEFT", 4, baseY)
recruitLabel:SetText(L["Werbetext (z. B. „/2 Gilde XY sucht …“)"])
local recruitBox = CreateFrame("EditBox", nil, settings, "InputBoxTemplate")
recruitBox:SetSize(470, 22); recruitBox:SetPoint("TOPLEFT", 10, baseY - 18)
recruitBox:SetAutoFocus(false); recruitBox:SetMaxLetters(250)
recruitBox:SetScript("OnTextChanged", function(self, user)
    if user then GuildPrideDB.recruitText = self:GetText() end
end)
recruitBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
recruitBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

function ns.PostRecruitText()
    local t = GuildPrideDB.recruitText
    if not t or strtrim(t) == "" then ns.Print(L["Noch kein Werbetext gespeichert (Einstellungen)."]); return end
    if ChatFrame_OpenChat then ChatFrame_OpenChat(t) end
    ns.Print(L["Werbetext steht in der Chat-Eingabe – mit Enter abschicken."])
end
local recruitBtn = CreateFrame("Button", nil, settings, "UIPanelButtonTemplate")
recruitBtn:SetSize(150, 24); recruitBtn:SetPoint("LEFT", recruitBox, "RIGHT", 8, 0)
recruitBtn:SetText(L["In den Chat legen"])
recruitBtn:SetScript("OnClick", function() ns.PostRecruitText() end)

-- Notiz-Vorlagen: eine pro Zeile, nutzbar im Mitglieder-Rechtsklick
local tplLabel = settings:CreateFontString(nil, "OVERLAY", "GPFont_TextBold")
tplLabel:SetPoint("TOPLEFT", 4, baseY - 52)
tplLabel:SetText(L["Notiz-Vorlagen (eine pro Zeile, {datum} = heute)"])
local tplScroll = ns.NewScroll(settings)
tplScroll:SetPoint("TOPLEFT", 10, baseY - 72)
tplScroll:SetSize(600, 64)
local tplBg = tplScroll:CreateTexture(nil, "BACKGROUND")
tplBg:SetPoint("TOPLEFT", -4, 4); tplBg:SetPoint("BOTTOMRIGHT", 4, -4)
tplBg:SetColorTexture(0, 0, 0, 0.45)
local tplBox = CreateFrame("EditBox", nil, tplScroll)
tplBox:SetMultiLine(true); tplBox:SetAutoFocus(false)
tplBox:SetFontObject(GPFont_TextSmall); tplBox:SetWidth(590)
tplScroll:SetScrollChild(tplBox)
tplScroll:EnableMouse(true)
tplScroll:SetScript("OnMouseDown", function() tplBox:SetFocus() end)
tplBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
tplBox:SetScript("OnTextChanged", function(self, user)
    if not user then return end
    local list = {}
    for line in (self:GetText() .. "\n"):gmatch("([^\n]*)\n") do
        line = strtrim(line)
        if line ~= "" then list[#list + 1] = line:sub(1, 120) end
    end
    GuildPrideDB.noteTemplates = list
end)

-- Vorlagen mit eingesetztem Datum (für GuildPrideManage.lua)
function ns.NoteTemplates()
    local out = {}
    for _, t in ipairs(GuildPrideDB.noteTemplates or {}) do
        out[#out + 1] = (t:gsub("{datum}", date("%d.%m.%Y")):gsub("{date}", date("%Y-%m-%d")))
    end
    return out
end

settings:SetHeight(-(baseY - 150))

function settingsPage:Refresh()
    MarkStyle()
    for key, cb in pairs(checks) do cb:SetChecked(GuildPrideDB[key]) end
    for _, s in ipairs(steppers) do s.Show() end
    if not welcomeBox:HasFocus() then
        local w = GuildPrideDB.welcomeText
        welcomeBox:SetText((w and w ~= "") and w or (ns.WELCOME_DEFAULT or ""))
    end
    if not recruitBox:HasFocus() then recruitBox:SetText(GuildPrideDB.recruitText or "") end
    if not tplBox:HasFocus() then tplBox:SetText(table.concat(GuildPrideDB.noteTemplates or {}, "\n")) end
end
ns.SettingsPage = settingsPage

-- Dieselben Schalter im WoW-Menü (Optionen -> AddOns -> GuildPride)
-- Ältere Classic-Clients ohne neues Settings-Menü: alte Interface-Optionen
if (Settings and Settings.RegisterCanvasLayoutCategory) or InterfaceOptions_AddCategory then
    local panel = CreateFrame("Frame")
    panel.name = "GuildPride"
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("GuildPride")
    local panelChecks = {}
    for i, opt in ipairs(options) do
        local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 16, -44 - (i - 1) * 32)
        local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        label:SetText(opt.label)
        cb:SetScript("OnClick", function(self) SetOption(opt, self:GetChecked()) end)
        panelChecks[opt.key] = cb
    end
    local open = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    open:SetSize(220, 26)
    open:SetPoint("TOPLEFT", 20, -44 - #options * 32 - 12)
    open:SetText(L["Gildenfenster öffnen"])
    open:SetScript("OnClick", function()
        if SettingsPanel then HideUIPanel(SettingsPanel) end
        if InterfaceOptionsFrame then HideUIPanel(InterfaceOptionsFrame) end
        if not frame:IsShown() then ns.ToggleUI() end
    end)
    panel:SetScript("OnShow", function()
        if not GuildPrideDB then return end
        for key, cb in pairs(panelChecks) do cb:SetChecked(GuildPrideDB[key]) end
    end)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "GuildPride")
        Settings.RegisterAddOnCategory(category)
        ns.SettingsCategory = category
    else
        InterfaceOptions_AddCategory(panel)
        ns.SettingsPanel = panel
    end
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

-- Blizzard-Gildenfenster je nach Client: Communities (Retail, MoP),
-- GuildFrame (Cata/Wrath) oder der Gilden-Reiter im Freundesfenster (Era, Anniversary)
local function HideBlizzardGuild(useHideUIPanel)
    local hide = useHideUIPanel and HideUIPanel or function(f) f:Hide() end
    local hidden = false
    for _, f in ipairs({ CommunitiesFrame, GuildFrame }) do
        if f and f:IsShown() then hide(f); hidden = true end
    end
    -- Freundesfenster nur, wenn ToggleGuildFrame kein eigenes Gildenfenster geöffnet hat
    if not hidden and FriendsFrame and FriendsFrame:IsShown() then hide(FriendsFrame) end
end

function ns.OpenBlizzardGuild()
    frame:Hide()
    bypass = true
    if ToggleGuildFrame then ToggleGuildFrame() end
    bypass = false
end

-- Wir überschreiben ToggleGuildFrame NICHT (würde Taint verursachen),
-- sondern schließen das Blizzard-Fenster direkt nach dem Öffnen wieder.
if ToggleGuildFrame then
    hooksecurefunc("ToggleGuildFrame", function()
        -- Im Kampf: jedes Gildenfenster blocken (auch das von Blizzard)
        if InCombatLockdown() then
            HideBlizzardGuild()
            ns.Print(L["|cffff4040Im Kampf kann das Gildenfenster nicht geöffnet werden.|r"])
            return
        end
        if bypass or not GuildPrideDB or not GuildPrideDB.replaceGuildFrame then return end
        if not IsInGuild() then return end
        HideBlizzardGuild(true)
        ns.ToggleUI()
    end)
end

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
