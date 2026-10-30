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
local ROLES = {
    { key = "T", label = "Tank",        color = "|cff6fa8ff", spec = "TANK" },
    { key = "H", label = L["Heiler"],   color = "|cff40ff40", spec = "HEALER" },
    { key = "D", label = L["DD"],       color = "|cffff6060", spec = "DAMAGER" },
}
local ROLE_BY_SPEC = { TANK = "T", HEALER = "H", DAMAGER = "D" }

local entries = {}   -- [Name-Realm] = { kind, note, level, zone, size, max, needs, role, class, t, seen }
local mine           -- eigener Eintrag
local needs = {}     -- eigene Auswahl: { T = true, H = true }
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
local function SendMine(target)
    if mine then
        local size, max = GroupSize()
        local _, class = UnitClass("player")
        ns.Queue("LFG", target, mine.kind, mine.note, UnitLevel("player"), GetZoneText() or "",
            size, max, mine.needs or "", MyRoleKey(), class or "", stateVer)
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
             t = mine.t, self = true }
end

ns.On("LFG", function(payload, sender)
    if sender == ns.Me() then return end
    local kind, note, level, zone, size, max, need, role, class, ver = strsplit(SEP, payload)
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
                    seen = GetServerTime() }
        if isNew then e.t = GetServerTime() end
        entries[sender] = e
        if alert and GuildPrideDB.helpAlerts ~= false then
            local extra = (" · " .. L["Gruppe %d/%d"]):format(e.size, e.max)
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
local page = ns.AddTab(L["Gruppensuche"])

local hint = page:CreateFontString(nil, "OVERLAY", "GPFont_TextSmall")
hint:SetPoint("TOPLEFT", 2, -2)
hint:SetText(L["Notiz (optional), Rollen wählen, dann eintragen. Die Gruppengröße wird automatisch übernommen."])

local noteBox = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
noteBox:SetSize(240, 22)
noteBox:SetPoint("TOPLEFT", 8, -22)
noteBox:SetAutoFocus(false)
noteBox:SetMaxLetters(60)

local needLabel = page:CreateFontString(nil, "OVERLAY", "GPFont_Text")
needLabel:SetPoint("LEFT", noteBox, "RIGHT", 16, 0)
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
    if kind then
        mine = { kind = kind, note = Clean(noteBox:GetText(), 60), needs = NeedsCode(), t = GetServerTime() }
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

local bGroup = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
bGroup:SetSize(118, 24); bGroup:SetPoint("TOPLEFT", 4, -52); bGroup:SetText(L["Sucht Gruppe"])
bGroup:SetScript("OnClick", function() Set("group") end)
local bQuest = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
bQuest:SetSize(118, 24); bQuest:SetPoint("LEFT", bGroup, "RIGHT", 4, 0); bQuest:SetText(L["Quest-Hilfe"])
bQuest:SetScript("OnClick", function() Set("quest") end)
local bClear = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
bClear:SetSize(100, 24); bClear:SetPoint("LEFT", bQuest, "RIGHT", 4, 0); bClear:SetText(L["Austragen"])
bClear:SetScript("OnClick", function() Set(nil) end)

local status = page:CreateFontString(nil, "OVERLAY", "GPFont_TextSmall")
status:SetPoint("RIGHT", page, "TOPRIGHT", -4, -64)
status:SetJustifyH("RIGHT")

-- Liste: zwei Zeilen pro Eintrag
local ROWS, ROW_H, rows = 7, 46, {}
for i = 1, ROWS do
    local r = CreateFrame("Frame", nil, page)
    r:SetSize(650, ROW_H - 2)
    r:SetPoint("TOPLEFT", 0, -88 - (i - 1) * ROW_H)
    r.bg = r:CreateTexture(nil, "BACKGROUND"); r.bg:SetAllPoints()
    r.bg:SetColorTexture(1, 0.6, 0.3, i % 2 == 0 and 0.05 or 0.02)
    r.edge = r:CreateTexture(nil, "BORDER"); r.edge:SetPoint("TOPLEFT"); r.edge:SetPoint("BOTTOMLEFT"); r.edge:SetWidth(3)
    r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(30, 30); r.icon:SetPoint("LEFT", 10, 0)
    r.name = r:CreateFontString(nil, "OVERLAY", "GPFont_TextBold"); r.name:SetPoint("TOPLEFT", 50, -6)
    r.info = r:CreateFontString(nil, "OVERLAY", "GPFont_TextSmall"); r.info:SetPoint("LEFT", r.name, "RIGHT", 10, 0)
    r.line2 = r:CreateFontString(nil, "OVERLAY", "GPFont_TextSmall"); r.line2:SetPoint("BOTTOMLEFT", 50, 7)
    r.line2:SetWidth(420); r.line2:SetJustifyH("LEFT"); r.line2:SetWordWrap(false)
    -- Gruppen-Füllstand als Punkte
    r.pips = {}
    for p = 1, 5 do
        local t = r:CreateTexture(nil, "ARTWORK")
        t:SetSize(9, 9)
        t:SetPoint("RIGHT", r, "RIGHT", -112 - (5 - p) * 12, 8)
        r.pips[p] = t
    end
    r.count = r:CreateFontString(nil, "OVERLAY", "GPFont_MutedSmall"); r.count:SetPoint("TOPRIGHT", r, "TOPRIGHT", -112, -28)
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
        status:SetText((L["Dein Status: %s%s|r"]):format(TYPES[mine.kind].color, KindLabel(mine.kind, size))
            .. "  |cff999999" .. (L["Gruppe %d/%d"]):format(size, max) .. "|r")
    else
        status:SetText(L["|cff888888Du bist nicht eingetragen.|r"])
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

    for i, r in ipairs(rows) do
        local item = list[i]
        r:SetShown(item ~= nil)
        if item then
            local e, t = item.e, TYPES[item.e.kind]
            local c = RAID_CLASS_COLORS[e.class]
            local hex = c and c.colorStr and c.colorStr:sub(3) or "f0c88c"
            r.icon:SetTexture(t.icon)
            if item.e.kind == "quest" then r.edge:SetColorTexture(1, 0.82, 0, 1) else r.edge:SetColorTexture(0.44, 0.66, 1, 1) end
            r.name:SetText(("|cff%s%s|r"):format(hex, Ambiguate(item.name, "guild"))
                .. (e.self and (" |cff999999(" .. L["du"] .. ")|r") or ""))
            r.info:SetText(("Lvl %d · %s · |cff999999%s|r"):format(e.level, RoleLabel(e.role), e.zone))

            local parts = { t.color .. KindLabel(e.kind, e.size) .. "|r" }
            if e.needs ~= "" then parts[#parts + 1] = (L["Sucht noch: %s"]):format(NeedsString(e.needs)) end
            if e.note ~= "" then parts[#parts + 1] = "|cffe6e0da" .. e.note .. "|r" end
            parts[#parts + 1] = "|cff777777" .. Ago(now, e.t) .. "|r"
            r.line2:SetText(table.concat(parts, "  ·  "))

            -- Füllstand: bei 5er-Gruppen Punkte, bei Raids nur Zahl
            local showPips = e.max <= 5
            for p = 1, 5 do
                local pip = r.pips[p]
                pip:SetShown(showPips)
                if p <= e.size then pip:SetColorTexture(1, 0.55, 0.2, 1) else pip:SetColorTexture(0.25, 0.2, 0.18, 1) end
            end
            r.count:SetText(e.size <= 1 and L["Allein"] or (L["Gruppe %d/%d"]):format(e.size, e.max))

            -- Allein + "Sucht Gruppe" -> in die eigene Gruppe einladen,
            -- sonst eine Beitrittsanfrage an seine Gruppe schicken
            local target = Ambiguate(item.name, "none")
            local inMyGroup = UnitInParty(target) or UnitInRaid(target)
            local mode = (e.kind == "group" and e.size <= 1) and "invite" or "join"
            r.tell:SetShown(not e.self)
            if inMyGroup then
                r.tell:SetText(L["In Gruppe"]); r.tell:Disable()
            elseif mode == "join" and e.size >= e.max then
                r.tell:SetText(L["Voll"]); r.tell:Disable()
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
