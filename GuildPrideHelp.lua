-- GuildPride: Gruppensuche / Quest-Hilfe
-- Man trägt sich ein, die anderen sehen wer sucht, wie voll die Gruppe ist
-- und welche Rollen noch fehlen – und melden sich selbst.
local ADDON, ns = ...
local L = ns.L
local SEP = ns.SEP
local EXPIRE = 30 * 60   -- Einträge verfallen nach 30 Minuten
local RESEND = 4 * 60    -- eigenen Eintrag regelmäßig neu senden (falls Nachrichten verloren gingen)
local STALE = 10 * 60    -- fremde Einträge ohne Lebenszeichen ausblenden

local TYPES = {
    group = { label = L["Sucht Gruppe"],        color = "|cff6fa8ff", icon = "Interface\\Icons\\INV_Misc_GroupNeedMore" },
    quest = { label = L["Braucht Quest-Hilfe"], color = "|cffffd100", icon = "Interface\\Icons\\INV_Misc_Note_01" },
}
-- Schlüsselstein anbieten (nur Retail, siehe GuildPrideKeys.lua)
if ns.MyKey then
    TYPES.key = { label = L["Bietet Schlüssel an"], color = "|cffa335ee", icon = "Interface\\Icons\\INV_Relics_Hourglass" }
end

-- "+12 Nebel von Tirna Scithe"
local function KeyLabel(map, level)
    if not level or level == 0 then return "" end
    local name = ns.KeyMapName and ns.KeyMapName(map) or nil
    return ("|cffa335ee+%d %s|r"):format(level, name or "")
end

-- Quest-Link selbst bauen: GetQuestLink erwartet in Classic den Questlog-Index
local function QuestLink(id, level, name)
    if not id or id == 0 or not name or name == "" then return "" end
    return ("|cffffff00|Hquest:%d:%d|h[%s]|h|r"):format(id, level or 0, name)
end

-- Quests im eigenen Questlog: { id, level, name } (Retail/Forever: C_QuestLog, Classic: GetQuestLogTitle)
local function QuestLogList()
    local out = {}
    local Q = C_QuestLog
    local modern = Q and Q.GetInfo and Q.GetNumQuestLogEntries
    local n = (modern and Q.GetNumQuestLogEntries()) or (GetNumQuestLogEntries and GetNumQuestLogEntries()) or 0
    for i = 1, n do
        local title, level, isHeader, hidden, id
        if modern then
            local q = Q.GetInfo(i)
            if q then title, level, isHeader, hidden, id = q.title, q.level, q.isHeader, q.isHidden, q.questID end
        elseif GetQuestLogTitle then
            local _
            title, level, _, isHeader, _, _, _, id = GetQuestLogTitle(i)
        end
        if title and not isHeader and not hidden and (id or 0) > 0 then
            out[#out + 1] = { id = id, level = level or 0, name = title }
        end
    end
    return out
end
local ROLES = {
    { key = "T", label = "Tank",        color = "|cff6fa8ff", spec = "TANK" },
    { key = "H", label = L["Heiler"],   color = "|cff40ff40", spec = "HEALER" },
    { key = "D", label = L["DD"],       color = "|cffff6060", spec = "DAMAGER" },
}
local ROLE_BY_SPEC = { TANK = "T", HEALER = "H", DAMAGER = "D" }

local entries = {}   -- [Name-Realm] = { kind, note, level, zone, size, max, needs, role, class, t, seen }
local mine           -- eigener Eintrag
local needs = {}     -- eigene Auswahl: { T = true, H = true }
local picked         -- gewählte Quest aus dem Questlog: { id, level, name }
local lastSent = 0
-- Versionsnummer des eigenen Zustands (eingetragen/ausgetragen/Art). Sie steigt
-- bei jeder Änderung; Empfänger ignorieren ältere Stände. Sonst konnte eine
-- verspätete Nachricht (Drosselung, Antwort auf eine Anfrage) einen neueren
-- Eintrag überschreiben und der Eintrag sprang zwischen zwei Arten hin und her.
local stateVer = 0
local function BumpVer() stateVer = math.max(stateVer + 1, GetServerTime()) end
local verBy = {}     -- [Name-Realm] = zuletzt gesehene Version
local alertedAt = {} -- [Name-Realm] = Zeit des letzten Chat-Hinweises
local ALERT_GAP = 60

local function Clean(s, max) return (tostring(s or ""):gsub("[%c|]", "")):sub(1, max) end

local function GroupSize()
    if IsInGroup and IsInGroup() then
        return GetNumGroupMembers(), (IsInRaid() and 40 or 5)
    end
    return 1, 5
end

local function MyRoleKey()
    local r = GuildPrideDB.role
    if not r and GetSpecialization and GetSpecializationRole then
        local spec = GetSpecialization()
        r = spec and GetSpecializationRole(spec)
    end
    return ROLE_BY_SPEC[r or ""] or "D"
end

local function NeedsString(s)
    local out = {}
    for _, r in ipairs(ROLES) do
        if s and s:find(r.key, 1, true) then out[#out + 1] = r.color .. r.label .. "|r" end
    end
    return table.concat(out, ", ")
end

local function RoleLabel(key)
    for _, r in ipairs(ROLES) do if r.key == key then return r.color .. r.label .. "|r" end end
    return ""
end

-- "Sucht Gruppe" allein, "Sucht Mitspieler" wenn man schon eine Gruppe hat
local function KindLabel(kind, size)
    if kind == "group" and (size or 1) > 1 then return L["Sucht Mitspieler"] end
    return TYPES[kind].label
end

---------------------------------------------------------------------
-- Senden / Empfangen
---------------------------------------------------------------------
-- Angebotener Schlüssel aktuell halten (Stufe ändert sich nach einem Lauf)
local function UpdateMyKey()
    if mine and mine.kind == "key" and ns.MyKey then
        local map, level = ns.MyKey()
        if map then mine.map, mine.keyLevel = map, level end
    end
end

local function SendMine(target)
    if mine then
        UpdateMyKey()
        local size, max = GroupSize()
        local _, class = UnitClass("player")
        -- Felder 11/12: Schlüssel (ältere Versionen ignorieren sie und kennen "key" nicht)
        -- Felder 13–15: verlinkte Quest (ID, Stufe, Name)
        local q = mine.quest
        ns.Queue("LFG", target, mine.kind, mine.note, UnitLevel("player"), GetZoneText() or "",
            size, max, mine.needs or "", MyRoleKey(), class or "", stateVer, mine.map or 0, mine.keyLevel or 0,
            q and q.id or 0, q and q.level or 0, q and Clean(q.name, 50) or "")
        if not target then lastSent = GetServerTime() end
    elseif not target then
        ns.Queue("LFG", nil, "none", "", 0, "", 0, 0, "", "", "", stateVer)
    end
    -- Rundsendung zusätzlich an die Gildenleitung flüstern (Rangrechte)
    if not target and ns.TellLeaders then ns.TellLeaders(SendMine) end
end

-- Eigener Eintrag als Listenzeile (wird nicht über das Netz empfangen)
local function MyEntry()
    local size, max = GroupSize()
    local _, class = UnitClass("player")
    return { kind = mine.kind, note = mine.note, level = UnitLevel("player"), zone = GetZoneText() or "",
             size = size, max = max, needs = mine.needs or "", role = MyRoleKey(), class = class or "",
             map = mine.map, keyLevel = mine.keyLevel, t = mine.t, self = true,
             questId = mine.quest and mine.quest.id or 0, questLevel = mine.quest and mine.quest.level or 0,
             questName = mine.quest and mine.quest.name or "" }
end

ns.On("LFG", function(payload, sender)
    if sender == ns.Me() then return end
    local kind, note, level, zone, size, max, need, role, class, ver, map, keyLevel, questId, questLevel, questName = strsplit(SEP, payload)
    -- Älteren Stand als den schon bekannten ignorieren (ältere Versionen senden keine Nummer)
    ver = tonumber(ver) or 0
    if ver > 0 then
        if verBy[sender] and ver < verBy[sender] then return end
        verBy[sender] = ver
    end
    if kind == "none" or not TYPES[kind] then
        entries[sender] = nil
    else
        local old = entries[sender]
        local isNew = not old or old.kind ~= kind
        -- Höchstens ein Chat-Hinweis pro Spieler und Minute
        local now = GetServerTime()
        local alert = isNew and now - (alertedAt[sender] or 0) >= ALERT_GAP
        if alert then alertedAt[sender] = now end
        local e = { kind = kind, note = Clean(note, 60), level = tonumber(level) or 0, zone = Clean(zone, 40),
                    size = tonumber(size) or 1, max = tonumber(max) or 5, needs = Clean(need, 3),
                    role = Clean(role, 1), class = Clean(class, 20), t = old and old.t or GetServerTime(),
                    map = tonumber(map) or 0, keyLevel = tonumber(keyLevel) or 0, seen = GetServerTime(),
                    questId = tonumber(questId) or 0, questLevel = tonumber(questLevel) or 0, questName = Clean(questName, 50) }
        if isNew then e.t = GetServerTime() end
        entries[sender] = e
        if alert and GuildPrideDB.helpAlerts ~= false then
            local extra = (" · " .. L["Gruppe %d/%d"]):format(e.size, e.max)
            if kind == "key" then extra = " · " .. KeyLabel(e.map, e.keyLevel) .. extra end
            if e.questId > 0 then extra = " · " .. QuestLink(e.questId, e.questLevel, e.questName) .. extra end
            if e.needs ~= "" then extra = extra .. " · " .. (L["Sucht noch: %s"]):format(NeedsString(e.needs)) end
            ns.Print(("%s%s|r: |cffffd100%s|r (Lvl %d, %s)%s%s"):format(TYPES[kind].color, KindLabel(kind, e.size),
                Ambiguate(sender, "guild"), e.level, e.zone, extra, e.note ~= "" and (" – " .. e.note) or ""))
            if GuildPrideDB.sound then PlaySound(SOUNDKIT.TELL_MESSAGE) end
        end
    end
    if ns.RefreshUI then ns.RefreshUI() end
end)

-- REQ: Login-Abgleich aller Module · LFGQ: jemand hat die Gruppensuche geöffnet
for _, k in ipairs({ "REQ", "LFGQ" }) do
    ns.On(k, function(_, sender)
        if sender ~= ns.Me() then SendMine(sender) end
    end)
end

-- Eigenen Eintrag regelmäßig erneuern bzw. nach Ablauf austragen
C_Timer.NewTicker(60, function()
    if not mine then return end
    local now = GetServerTime()
    if now - mine.t > EXPIRE then
        mine = nil
        BumpVer()
        SendMine()
        ns.Print(L["Dein Eintrag in der Gruppensuche ist abgelaufen."])
        if ns.RefreshUI then ns.RefreshUI() end
    elseif now - lastSent >= RESEND then
        SendMine()
    end
end)

-- Gruppengröße ändert sich -> Eintrag automatisch aktualisieren
local pendingUpdate
local grp = CreateFrame("Frame")
grp:RegisterEvent("GROUP_ROSTER_UPDATE")
grp:RegisterEvent("ZONE_CHANGED_NEW_AREA")
grp:SetScript("OnEvent", function()
    if not mine or pendingUpdate then return end
    pendingUpdate = C_Timer.NewTimer(2, function()
        pendingUpdate = nil
        if mine then SendMine(); if ns.RefreshUI then ns.RefreshUI() end end
    end)
end)

---------------------------------------------------------------------
-- UI-Reiter
---------------------------------------------------------------------
local page = ns.AddTab(L["Gruppensuche"], 40)

local hint = page:CreateFontString(nil, "OVERLAY", "GPFont_TextSmall")
hint:SetPoint("TOPLEFT", 2, -2)
hint:SetText(L["Titel (optional), Rollen wählen, dann eintragen. Die Gruppengröße wird automatisch übernommen."])

local noteBox = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
noteBox:SetSize(170, 22)
noteBox:SetPoint("TOPLEFT", 8, -22)
noteBox:SetAutoFocus(false)
noteBox:SetMaxLetters(60)

-- Quest aus dem Questlog verlinken (eigene Liste, gleich in allen Spielversionen)
local bQuestPick = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
bQuestPick:SetSize(66, 22)
bQuestPick:SetPoint("LEFT", noteBox, "RIGHT", 4, 0)
bQuestPick:SetText(L["Quest"])
bQuestPick:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(L["Quest verlinken"], 1, 1, 1)
    GameTooltip:AddLine(L["Quest aus deinem Questlog wählen"], 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)
bQuestPick:HookScript("OnLeave", function() GameTooltip:Hide() end)

local picker = CreateFrame("Frame", nil, page)
picker:SetFrameStrata("DIALOG")
picker:SetPoint("TOPLEFT", bQuestPick, "BOTTOMLEFT", 0, -2)
picker:SetWidth(320)
picker:EnableMouse(true)
picker:Hide()
local pickerBg = picker:CreateTexture(nil, "BACKGROUND")
pickerBg:SetAllPoints()
pickerBg:SetColorTexture(0.05, 0.04, 0.04, 0.97)
local pickerEdge = picker:CreateTexture(nil, "BORDER")
pickerEdge:SetPoint("TOPLEFT"); pickerEdge:SetPoint("TOPRIGHT"); pickerEdge:SetHeight(2)
ns.Paint(pickerEdge, "accent")
local pickScroll = ns.NewScroll(picker)
pickScroll:SetPoint("TOPLEFT", 4, -6)
pickScroll:SetPoint("BOTTOMRIGHT", -26, 4)
local pickChild = CreateFrame("Frame", nil, pickScroll)
pickChild:SetSize(290, 1)
pickScroll:SetScrollChild(pickChild)
local pickRows = {}
local PICK_H = 20

local function SetPicked(q)
    picked = q
    picker:Hide()
    -- Schon eingetragen: Eintrag gleich mit der neuen Quest erneuern
    if mine then
        mine.quest = picked
        BumpVer()
        SendMine()
    end
    ns.RefreshUI()
end

local function OpenPicker()
    local list = QuestLogList()
    if #list == 0 then
        ns.Print(L["Dein Questlog ist leer."])
        return
    end
    table.insert(list, 1, { none = true })
    for i, q in ipairs(list) do
        local b = pickRows[i]
        if not b then
            b = CreateFrame("Button", nil, pickChild)
            b:SetSize(290, PICK_H)
            b:SetPoint("TOPLEFT", 0, -(i - 1) * PICK_H)
            b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            b.text = b:CreateFontString(nil, "OVERLAY", "GPFont_TextSmall")
            b.text:SetPoint("LEFT", 6, 0); b.text:SetPoint("RIGHT", -4, 0)
            b.text:SetJustifyH("LEFT"); b.text:SetWordWrap(false)
            pickRows[i] = b
        end
        if q.none then
            b.text:SetText("|cff999999" .. L["Keine Quest"] .. "|r")
            b:SetScript("OnClick", function() SetPicked(nil) end)
        else
            b.text:SetText(("|cff999999[%d]|r |cffffd100%s|r"):format(q.level, q.name))
            b:SetScript("OnClick", function() SetPicked(q) end)
        end
        b:Show()
    end
    for i = #list + 1, #pickRows do pickRows[i]:Hide() end
    pickChild:SetHeight(#list * PICK_H)
    picker:SetHeight(math.min(#list, 14) * PICK_H + 10)
    picker:Show()
end
bQuestPick:SetScript("OnClick", function()
    if picker:IsShown() then picker:Hide() else OpenPicker() end
end)
page:HookScript("OnHide", function() picker:Hide() end)

local needLabel = page:CreateFontString(nil, "OVERLAY", "GPFont_Text")
needLabel:SetPoint("LEFT", bQuestPick, "RIGHT", 16, 0)
needLabel:SetText(L["Fehlt noch:"])

local needBtns = {}
local function UpdateNeedButtons()
    for _, r in ipairs(ROLES) do
        local b = needBtns[r.key]
        if b.gpBg then b.gpBg:SetTexture(ns.MEDIA .. (needs[r.key] and "nav_active" or "nav")) end
        if needs[r.key] then b:LockHighlight() else b:UnlockHighlight() end
    end
end
local prev = needLabel
for _, r in ipairs(ROLES) do
    local b = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    b:SetSize(74, 22)
    b:SetPoint("LEFT", prev, "RIGHT", prev == needLabel and 8 or 4, 0)
    b:SetText(r.label)
    b:SetScript("OnClick", function()
        needs[r.key] = not needs[r.key] or nil
        UpdateNeedButtons()
    end)
    needBtns[r.key] = b
    prev = b
end

local function NeedsCode()
    local s = ""
    for _, r in ipairs(ROLES) do if needs[r.key] then s = s .. r.key end end
    return s
end

local function Set(kind)
    if kind == "key" and not (ns.MyKey and ns.MyKey()) then
        ns.Print(L["Du hast gerade keinen Schlüsselstein."])
        return
    end
    if kind then
        mine = { kind = kind, note = Clean(noteBox:GetText(), 60), needs = NeedsCode(), quest = picked, t = GetServerTime() }
        UpdateMyKey()
        ns.Print(L["Du bist eingetragen: "] .. KindLabel(kind, (GroupSize())))
    else
        mine = nil
        ns.Print(L["Du bist ausgetragen."])
    end
    noteBox:ClearFocus()
    BumpVer()
    SendMine()
    ns.RefreshUI()
end

-- Knopfleiste: links eintragen / austragen, rechts die Schlüssel-Ansicht (Retail)
local bGroup = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
bGroup:SetSize(108, 24); bGroup:SetPoint("TOPLEFT", 4, -52); bGroup:SetText(L["Sucht Gruppe"])
bGroup:SetScript("OnClick", function() Set("group") end)
local bQuest = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
bQuest:SetSize(108, 24); bQuest:SetPoint("LEFT", bGroup, "RIGHT", 4, 0); bQuest:SetText(L["Quest-Hilfe"])
bQuest:SetScript("OnClick", function() Set("quest") end)
local bOffer = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
bOffer:SetSize(132, 24); bOffer:SetPoint("LEFT", bQuest, "RIGHT", 4, 0); bOffer:SetText(L["Schlüssel anbieten"])
bOffer:SetScript("OnClick", function() Set("key") end)
bOffer:SetShown(TYPES.key ~= nil)
local bClear = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
bClear:SetSize(92, 24); bClear:SetPoint("LEFT", TYPES.key and bOffer or bQuest, "RIGHT", 4, 0); bClear:SetText(L["Austragen"])
bClear:SetScript("OnClick", function() Set(nil) end)

-- Ansicht "Schlüssel der Gilde" (nur Retail, siehe GuildPrideKeys.lua)
local keysView = false
local keysHolder, keysList, keysEmpty
local bKeys = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
bKeys:SetSize(140, 24); bKeys:SetPoint("TOPRIGHT", -2, -52)
bKeys:SetShown(ns.GuildKeys ~= nil)
if ns.GuildKeys then
    keysHolder = CreateFrame("Frame", nil, page)
    keysHolder:SetPoint("TOPLEFT", 0, -96)
    keysHolder:SetPoint("BOTTOMRIGHT", 0, 0)
    keysHolder:Hide()
    keysList = ns.CreateList(keysHolder, 24)
    keysEmpty = keysHolder:CreateFontString(nil, "OVERLAY", "GPFont_Muted")
    keysEmpty:SetPoint("TOP", 0, -76)
    keysEmpty:SetText(L["Noch keine Schlüssel bekannt (nur Mitglieder mit GuildPride)."])
    bKeys:SetScript("OnClick", function()
        keysView = not keysView
        if keysView and ns.AskKeys then ns.AskKeys() end
        page:Refresh()
    end)
end

-- Eigener Status in einer eigenen Zeile unter den Knöpfen
local status = page:CreateFontString(nil, "OVERLAY", "GPFont_TextSmall")
status:SetPoint("TOPLEFT", 6, -82)
status:SetJustifyH("LEFT")

-- Liste: Titel groß oben, darunter zwei Zeilen; scrollbar bei vielen Einträgen
local ROW_H, ROW_W, rows = 60, 624, {}
local listScroll = ns.NewScroll(page)
listScroll:SetPoint("TOPLEFT", 0, -98)
listScroll:SetPoint("BOTTOMRIGHT", -26, 0)
local listChild = CreateFrame("Frame", nil, listScroll)
listChild:SetSize(ROW_W, 1)
listScroll:SetScrollChild(listChild)

local function GetRow(i)
    if rows[i] then return rows[i] end
    local r = CreateFrame("Frame", nil, listChild)
    r:SetSize(ROW_W, ROW_H - 2)
    r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
    r.bg = r:CreateTexture(nil, "BACKGROUND"); r.bg:SetAllPoints()
    ns.Paint(r.bg, "glow", i % 2 == 0 and 0.05 or 0.02)
    r.edge = r:CreateTexture(nil, "BORDER"); r.edge:SetPoint("TOPLEFT"); r.edge:SetPoint("BOTTOMLEFT"); r.edge:SetWidth(3)
    r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(30, 30); r.icon:SetPoint("LEFT", 10, 0)
    -- Titel: der oben eingegebene Text, sonst die Art des Eintrags
    r.title = r:CreateFontString(nil, "OVERLAY", "GPFont_Large"); r.title:SetPoint("TOPLEFT", 50, -6)
    r.title:SetWidth(420); r.title:SetJustifyH("LEFT"); r.title:SetWordWrap(false)
    r.name = r:CreateFontString(nil, "OVERLAY", "GPFont_TextBold"); r.name:SetPoint("TOPLEFT", 50, -25)
    r.info = r:CreateFontString(nil, "OVERLAY", "GPFont_TextSmall"); r.info:SetPoint("LEFT", r.name, "RIGHT", 10, 0)
    r.line2 = r:CreateFontString(nil, "OVERLAY", "GPFont_TextSmall"); r.line2:SetPoint("BOTTOMLEFT", 50, 7)
    r.line2:SetWidth(420); r.line2:SetJustifyH("LEFT"); r.line2:SetWordWrap(false)
    -- Quest-Link: Maus drüber zeigt die Quest, Klick öffnet sie, Shift-Klick postet sie im Chat
    if r.SetHyperlinksEnabled then
        r:SetHyperlinksEnabled(true)
        r:SetScript("OnHyperlinkEnter", function(self, link)
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            if pcall(GameTooltip.SetHyperlink, GameTooltip, link) then GameTooltip:Show() else GameTooltip:Hide() end
        end)
        r:SetScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)
        r:SetScript("OnHyperlinkClick", function(_, link, text, button) pcall(SetItemRef, link, text, button) end)
    end
    -- Gruppen-Füllstand als Punkte
    r.pips = {}
    for p = 1, 5 do
        local t = r:CreateTexture(nil, "ARTWORK")
        t:SetSize(9, 9)
        t:SetPoint("RIGHT", r, "RIGHT", -112 - (5 - p) * 12, 8)
        r.pips[p] = t
    end
    r.count = r:CreateFontString(nil, "OVERLAY", "GPFont_MutedSmall"); r.count:SetPoint("TOPRIGHT", r, "TOPRIGHT", -112, -36)
    r.tell = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
    r.tell:SetSize(96, 24); r.tell:SetPoint("RIGHT", -6, 0); r.tell:SetText(L["Beitreten"])
    -- Rechtsklick: trotzdem anflüstern
    r.tell:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    r.tell:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["Linksklick: Beitritt anfragen bzw. einladen"], 1, 1, 1)
        GameTooltip:AddLine(L["Rechtsklick: anflüstern"], 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    r.tell:HookScript("OnLeave", function() GameTooltip:Hide() end)
    rows[i] = r
    return r
end
local empty = page:CreateFontString(nil, "OVERLAY", "GPFont_Muted")
empty:SetPoint("TOP", 0, -160)
empty:SetText(L["Gerade sucht niemand Hilfe."])

-- Beitritt anfragen bzw. einladen; ohne passende Spielfunktion wird angeflüstert
local function JoinOrInvite(target, mode)
    local P = C_PartyInfo or {}
    if mode == "invite" then
        local invite = P.InviteUnit or InviteUnit
        if invite then
            invite(target)
            ns.Print((L["Einladung an |cffffd100%s|r gesendet."]):format(target))
            return
        end
    elseif P.RequestInviteFromUnit then
        local r = { tank = false, healer = false, dps = false }
        local key = MyRoleKey()
        if key == "T" then r.tank = true elseif key == "H" then r.healer = true else r.dps = true end
        P.RequestInviteFromUnit(target, r.tank, r.healer, r.dps)
        ns.Print((L["Beitrittsanfrage an |cffffd100%s|r gesendet."]):format(target))
        return
    end
    ChatFrame_SendTell(target)
end

local function Ago(now, t)
    local m = math.floor((now - t) / 60)
    return m < 1 and L["gerade eben"] or (L["vor %d Min."]):format(m)
end

function page:Refresh()
    local now = GetServerTime()
    -- Ablauf des eigenen Eintrags erledigt der Minuten-Takt oben (inkl. Austragen bei den anderen)
    UpdateNeedButtons()
    if mine then
        local size, max = GroupSize()
        UpdateMyKey()
        status:SetText((L["Dein Status: %s%s|r"]):format(TYPES[mine.kind].color, KindLabel(mine.kind, size))
            .. (mine.kind == "key" and ("  " .. KeyLabel(mine.map, mine.keyLevel)) or "")
            .. "  |cff999999" .. (L["Gruppe %d/%d"]):format(size, max) .. "|r")
    else
        status:SetText(L["|cff888888Du bist nicht eingetragen.|r"])
    end
    if picked then status:SetText(status:GetText() .. "  ·  " .. QuestLink(picked.id, picked.level, picked.name)) end

    -- Schlüssel der Gilde statt der Suchliste
    bKeys:SetText(keysView and L["Gruppensuche"] or L["Schlüssel der Gilde"])
    if keysHolder then keysHolder:SetShown(keysView) end
    listScroll:SetShown(not keysView)
    if keysView then
        empty:Hide()
        local list = ns.GuildKeys()
        keysEmpty:SetShown(#list == 0)
        for i, k in ipairs(list) do
            local row = keysList:GetRow(i)
            row.left:SetText(Ambiguate(k.name, "guild") .. (k.name == ns.Me() and (" |cff999999(" .. L["du"] .. ")|r") or ""))
            row.mid:SetText(k.level > 0 and ("|cffa335ee+%d|r %s"):format(k.level, k.map or "") or ("|cff777777" .. L["kein Schlüssel"] .. "|r"))
            row.right:SetText(k.rating > 0 and ("|cffffd100" .. (L["M+-Wertung: %d"]):format(k.rating) .. "|r") or "")
        end
        keysList:Finish(#list)
        return
    end

    local list = {}
    if mine then list[1] = { name = ns.Me(), e = MyEntry() } end
    for name, e in pairs(entries) do
        if now - e.t > EXPIRE or now - (e.seen or e.t) > STALE then
            entries[name] = nil
        else
            list[#list + 1] = { name = name, e = e }
        end
    end
    table.sort(list, function(a, b) return a.e.t > b.e.t end)
    empty:SetShown(#list == 0)

    for i = #list + 1, #rows do rows[i]:Hide() end
    listChild:SetHeight(math.max(1, #list * ROW_H))
    for i, item in ipairs(list) do
        local r = GetRow(i)
        r:Show()
        do
            local e, t = item.e, TYPES[item.e.kind]
            local c = RAID_CLASS_COLORS[e.class]
            local hex = c and c.colorStr and c.colorStr:sub(3) or "f0c88c"
            r.icon:SetTexture(t.icon)
            if item.e.kind == "quest" then r.edge:SetColorTexture(1, 0.82, 0, 1)
            elseif item.e.kind == "key" then r.edge:SetColorTexture(0.64, 0.21, 0.93, 1)
            else r.edge:SetColorTexture(0.44, 0.66, 1, 1) end
            r.name:SetText(("|cff%s%s|r"):format(hex, Ambiguate(item.name, "guild"))
                .. (e.self and (" |cff999999(" .. L["du"] .. ")|r") or ""))
            r.info:SetText(("Lvl %d · %s · |cff999999%s|r"):format(e.level, RoleLabel(e.role), e.zone))
            -- Titel: eigener Text, sonst die verlinkte Quest, sonst die Art des Eintrags
            local hasQuest = (e.questId or 0) > 0 and (e.questName or "") ~= ""
            r.title:SetText(e.note ~= "" and e.note or (hasQuest and ("|cffffd100" .. e.questName .. "|r"))
                or (t.color .. KindLabel(e.kind, e.size) .. "|r"))

            local parts = { t.color .. KindLabel(e.kind, e.size) .. "|r" }
            if hasQuest then parts[#parts + 1] = QuestLink(e.questId, e.questLevel, e.questName) end
            if e.kind == "key" then parts[#parts + 1] = KeyLabel(e.map, e.keyLevel) end
            if e.needs ~= "" then parts[#parts + 1] = (L["Sucht noch: %s"]):format(NeedsString(e.needs)) end
            parts[#parts + 1] = "|cff777777" .. Ago(now, e.t) .. "|r"
            r.line2:SetText(table.concat(parts, "  ·  "))

            -- Füllstand: bei 5er-Gruppen Punkte, bei Raids nur Zahl
            local showPips = e.max <= 5
            for p = 1, 5 do
                local pip = r.pips[p]
                pip:SetShown(showPips)
                local c = ns.Theme().ember
                if p <= e.size then pip:SetColorTexture(c[1], c[2], c[3], 1) else pip:SetColorTexture(0.25, 0.2, 0.18, 1) end
            end
            r.count:SetText(e.size <= 1 and L["Allein"] or (L["Gruppe %d/%d"]):format(e.size, e.max))

            -- Allein + "Sucht Gruppe" -> in die eigene Gruppe einladen,
            -- sonst eine Beitrittsanfrage an seine Gruppe schicken
            local target = Ambiguate(item.name, "none")
            local inMyGroup = UnitInParty(target) or UnitInRaid(target)
            -- Schlüssel-Angebot: immer anmelden (Beitrittsanfrage an den Schlüsselhalter)
            local mode = (e.kind == "group" and e.size <= 1) and "invite" or "join"
            r.tell:SetShown(not e.self)
            if inMyGroup then
                r.tell:SetText(L["In Gruppe"]); r.tell:Disable()
            elseif mode == "join" and e.size >= e.max then
                r.tell:SetText(L["Voll"]); r.tell:Disable()
            elseif e.kind == "key" then
                r.tell:SetText(L["Anmelden"]); r.tell:Enable()
            else
                r.tell:SetText(mode == "invite" and L["Einladen"] or L["Beitreten"]); r.tell:Enable()
            end
            r.tell:SetScript("OnClick", function(_, button)
                if button == "RightButton" then ChatFrame_SendTell(target) else JoinOrInvite(target, mode) end
            end)
        end
    end
end

-- Beim Öffnen die aktuellen Einträge der anderen anfragen (höchstens einmal pro Minute)
local lastAsk = 0
page:HookScript("OnShow", function()
    local now = GetServerTime()
    if now - lastAsk < 60 then return end
    lastAsk = now
    ns.Queue("LFGQ", nil, "1")
end)

C_Timer.NewTicker(60, function() if ns.RefreshUI then ns.RefreshUI() end end)
