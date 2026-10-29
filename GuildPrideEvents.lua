-- GuildPride: Event-Planer mit Anmeldung (synchronisiert über Addon-Nachrichten)
local ADDON, ns = ...
local L = ns.L
local PREFIX = "GuildPride"
local SEP = "\031"
local ROLES = {
    TANK   = { short = "T", label = "Tank",   color = "|cff6fa8ff" },
    HEALER = { short = "H", label = L["Heiler"], color = "|cff40ff40" },
    DAMAGER= { short = "D", label = L["DD"],     color = "|cffff6060" },
}

local STATUS = {
    yes   = { label = L["Zugesagt"],   color = "|cff40ff40" },
    maybe = { label = L["Vielleicht"], color = "|cffffd100" },
    no    = { label = L["Abgesagt"],   color = "|cffff4040" },
}

---------------------------------------------------------------------
-- Daten
---------------------------------------------------------------------
local function DB()
    GuildPrideDB.events = GuildPrideDB.events or {}
    return GuildPrideDB.events
end

local function Me()
    return UnitName("player") .. "-" .. (GetNormalizedRealmName() or "")
end

local function CanManage()
    -- Offiziere (wer die Gildennachricht ändern darf) dürfen Events anlegen/löschen
    return CanEditMOTD and CanEditMOTD()
end

local function Now() return GetServerTime() end

local function Clean(s, max)
    s = (tostring(s or ""):gsub("[%c|]", ""))
    return s:sub(1, max)
end

---------------------------------------------------------------------
-- Senden (mit Warteschlange gegen Drosselung)
---------------------------------------------------------------------
-- Der Server drosselt Addon-Nachrichten pro Prefix. Gedrosselte Nachrichten
-- gingen früher verloren; jetzt kommen sie zurück in die Warteschlange.
local queue = {}
local pauseUntil = 0
local RESULT = Enum and Enum.SendAddonMessageResult
local function Throttled(res)
    if not RESULT then return false end
    return (RESULT.AddonMessageThrottle ~= nil and res == RESULT.AddonMessageThrottle)
        or (RESULT.ChannelThrottle ~= nil and res == RESULT.ChannelThrottle)
end

C_Timer.NewTicker(0.3, function()
    if GetTime() < pauseUntil then return end
    local item = table.remove(queue, 1)
    if not item then return end
    local res
    if item.target == "@OFFICER" then
        if IsInGuild() then res = C_ChatInfo.SendAddonMessage(PREFIX, item.msg, "OFFICER") end
    elseif item.target then
        res = C_ChatInfo.SendAddonMessage(PREFIX, item.msg, "WHISPER", item.target)
    elseif IsInGuild() then
        res = C_ChatInfo.SendAddonMessage(PREFIX, item.msg, "GUILD")
    end
    if Throttled(res) then
        item.tries = (item.tries or 0) + 1
        if item.tries <= 10 then table.insert(queue, 1, item) end
        pauseUntil = GetTime() + 1.5
    end
end)

local function Queue(kind, target, ...)
    local parts = { ... }
    for i = 1, select("#", ...) do parts[i] = tostring(parts[i] == nil and "" or parts[i]) end
    table.insert(queue, { msg = kind .. ":" .. table.concat(parts, SEP), target = target })
end
ns.Queue = Queue

local function SendEvent(e, target)
    Queue("EVT", target, e.id, e.t, e.title, e.desc, e.creator, e.ver, e.note or "")
end
local function SendDelete(e, target) Queue("DEL", target, e.id, e.ver) end
local function SendSign(id, name, s, target) Queue("SGN", target, id, name, s.s, s.v, s.r or "") end

---------------------------------------------------------------------
-- Daten anwenden (neuere Version gewinnt)
---------------------------------------------------------------------
local function GetOrStub(id)
    local e = DB()[id]
    if not e then
        e = { id = id, ver = 0, signups = {} }
        DB()[id] = e
    end
    e.signups = e.signups or {}
    return e
end

local function ApplyEvent(id, t, title, desc, creator, ver, note, fromOther)
    local e = GetOrStub(id)
    if ver <= e.ver then return end
    local isNew = not e.title
    e.t, e.title, e.desc, e.creator, e.ver, e.deleted = t, title, desc, creator, ver, nil
    e.note = note or ""
    if isNew and fromOther then
        ns.Print((L["Neues Gildenevent: |cffffd100%s|r am %s"]):format(title, date("%d.%m. %H:%M", t)))
    end
end

local function ApplyDelete(id, ver)
    local e = GetOrStub(id)
    if ver < e.ver then return end
    e.deleted, e.ver = true, ver
end

local function ApplySign(id, name, status, ver, role)
    if not STATUS[status] then return end
    if not ROLES[role or ""] then role = nil end
    local e = GetOrStub(id)
    local cur = e.signups[name]
    if not cur or ver > cur.v then e.signups[name] = { s = status, v = ver, r = role } end
end

---------------------------------------------------------------------
-- Empfangen
---------------------------------------------------------------------
local function OnEventMessage(kind, payload, sender)
    if sender == Me() then return end
    local a = { strsplit(SEP, payload) }
    if kind == "EVT" then
        ApplyEvent(a[1], tonumber(a[2]) or 0, Clean(a[3], 40), Clean(a[4], 120), a[5], tonumber(a[6]) or 0,
            Clean(a[7], 100), true)
    elseif kind == "DEL" then
        ApplyDelete(a[1], tonumber(a[2]) or 0)
    elseif kind == "SGN" then
        ApplySign(a[1], a[2], a[3], tonumber(a[4]) or 0, a[5])
    elseif kind == "REQ" then
        -- Jemand hat sich eingeloggt: unsere bekannten Events schicken
        local cutoff = Now() - 86400
        for _, e in pairs(DB()) do
            if e.deleted then
                SendDelete(e, sender)
            elseif e.title and e.t > cutoff then
                SendEvent(e, sender)
                for name, s in pairs(e.signups) do SendSign(e.id, name, s, sender) end
            end
        end
    end
    if ns.RefreshUI then ns.RefreshUI() end
end
for _, k in ipairs({ "EVT", "DEL", "SGN", "REQ" }) do
    ns.On(k, function(payload, sender) OnEventMessage(k, payload, sender) end)
end

---------------------------------------------------------------------
-- Aktionen
---------------------------------------------------------------------
local function CreateEvent(title, t, desc)
    local e = GetOrStub(Me() .. "-" .. Now() .. "-" .. math.random(1000, 9999))
    ApplyEvent(e.id, t, Clean(title, 40), Clean(desc, 120), Me(), Now())
    SendEvent(e)
    ns.RefreshUI()
end

local function DeleteEvent(e)
    ApplyDelete(e.id, Now())
    SendDelete(e)
    ns.RefreshUI()
end

local function MyRole()
    if GuildPrideDB.role then return GuildPrideDB.role end
    local spec = GetSpecialization and GetSpecialization()
    local r = spec and GetSpecializationRole and GetSpecializationRole(spec)
    return ROLES[r or ""] and r or "DAMAGER"
end

local function SetNote(e, note)
    ApplyEvent(e.id, e.t, e.title, e.desc, e.creator, Now(), Clean(note, 100))
    SendEvent(e)
    ns.RefreshUI()
end

local function SignUp(e, status)
    ApplySign(e.id, Me(), status, Now(), status ~= "no" and MyRole() or nil)
    SendSign(e.id, Me(), e.signups[Me()])
    ns.RefreshUI()
end

-- "24.12. 20:00" oder "24.12.2026 20:00"
local function ParseDate(str)
    local d, m, y, H, M = str:match("^(%d+)%.(%d+)%.(%d*)%s+(%d+):(%d+)$")
    if not d then return nil end
    y = tonumber(y) or tonumber(date("%Y"))
    if y < 100 then y = y + 2000 end
    return time({ year = y, month = tonumber(m), day = tonumber(d), hour = tonumber(H), min = tonumber(M) })
end

local function UpcomingEvents()
    local list, cutoff = {}, Now() - 3 * 3600 -- 3 h nach Beginn noch sichtbar
    for _, e in pairs(DB()) do
        if e.title and not e.deleted and e.t > cutoff then list[#list + 1] = e end
    end
    table.sort(list, function(a, b) return a.t < b.t end)
    return list
end

local function CountSignups(e)
    local c = { yes = 0, maybe = 0, no = 0 }
    for _, s in pairs(e.signups) do c[s.s] = (c[s.s] or 0) + 1 end
    return c
end

---------------------------------------------------------------------
-- UI: Reiter "Events"
---------------------------------------------------------------------
local page = ns.AddTab("Events")
local selected
local ROWS = 6
local rows = {}

for i = 1, ROWS do
    local b = CreateFrame("Button", nil, page)
    b:SetSize(650, 24)
    b:SetPoint("TOPLEFT", 0, -(i - 1) * 25)
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    b.when = b:CreateFontString(nil, "OVERLAY", "GPFont_TextSmall")
    b.when:SetPoint("LEFT", 6, 0)
    b.title = b:CreateFontString(nil, "OVERLAY", "GPFont_Normal")
    b.title:SetPoint("LEFT", 110, 0)
    b.info = b:CreateFontString(nil, "OVERLAY", "GPFont_TextSmall")
    b.info:SetPoint("RIGHT", -6, 0)
    b:SetScript("OnClick", function(self) selected = self.event and self.event.id; page:Refresh() end)
    rows[i] = b
end

local empty = page:CreateFontString(nil, "OVERLAY", "GPFont_Muted")
empty:SetPoint("TOP", 0, -60)
empty:SetText(L["Keine anstehenden Events."])

-- Detailbereich
local detail = CreateFrame("Frame", nil, page, "BackdropTemplate")
detail:SetPoint("TOPLEFT", 0, -ROWS * 25 - 8)
detail:SetPoint("BOTTOMRIGHT", 0, 34)
detail:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
detail:SetBackdropColor(0, 0, 0, 0.35)

local dTitle = detail:CreateFontString(nil, "OVERLAY", "GPFont_Large")
dTitle:SetPoint("TOPLEFT", 8, -8)
local dWhen = detail:CreateFontString(nil, "OVERLAY", "GPFont_TextSmall")
dWhen:SetPoint("TOPLEFT", dTitle, "BOTTOMLEFT", 0, -4)
local dDesc = detail:CreateFontString(nil, "OVERLAY", "GPFont_Text")
dDesc:SetPoint("TOPLEFT", dWhen, "BOTTOMLEFT", 0, -6)
dDesc:SetWidth(620); dDesc:SetJustifyH("LEFT")
local dPeople = detail:CreateFontString(nil, "OVERLAY", "GPFont_TextSmall")
dPeople:SetPoint("TOPLEFT", dDesc, "BOTTOMLEFT", 0, -8)
dPeople:SetWidth(620); dPeople:SetJustifyH("LEFT"); dPeople:SetSpacing(3)

local function Btn(text, w, anchor, x, onClick)
    local b = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    b:SetSize(w, 24); b:SetText(text)
    b:SetPoint("BOTTOMLEFT", anchor or page, anchor and "BOTTOMRIGHT" or "BOTTOMLEFT", x or 0, 0)
    b:SetScript("OnClick", onClick)
    return b
end

local function Sel() return selected and DB()[selected] end
local bYes   = Btn(L["Zusagen"], 90, nil, 0, function() if Sel() then SignUp(Sel(), "yes") end end)
local bMaybe = Btn(L["Vielleicht"], 90, bYes, 4, function() if Sel() then SignUp(Sel(), "maybe") end end)
local bNo    = Btn(L["Absagen"], 90, bMaybe, 4, function() if Sel() then SignUp(Sel(), "no") end end)
local bDel   = Btn(L["Löschen"], 80, bNo, 20, function()
    if Sel() then StaticPopup_Show("GUILDPRIDE_DELETE_EVENT", Sel().title, nil, Sel()) end
end)
local bNew   = Btn(L["Neues Event"], 110, bDel, 8, function() ns.ShowCreateDialog() end)

-- Rollenwahl (oben rechts im Detailbereich)
local roleBtns = {}
local roleLabel = detail:CreateFontString(nil, "OVERLAY", "GPFont_TextSmall")
for i, key in ipairs({ "TANK", "HEALER", "DAMAGER" }) do
    local b = CreateFrame("Button", nil, detail, "UIPanelButtonTemplate")
    b:SetSize(58, 20)
    b:SetPoint("TOPRIGHT", detail, "TOPRIGHT", -8 - (3 - i) * 62, -8)
    b:SetText(ROLES[key].label)
    b:SetScript("OnClick", function()
        GuildPrideDB.role = key
        local e = Sel()
        local mine = e and e.signups[Me()]
        if mine and mine.s ~= "no" then SignUp(e, mine.s) else page:Refresh() end
    end)
    roleBtns[key] = b
end
roleLabel:SetPoint("RIGHT", roleBtns.TANK, "LEFT", -6, 0)
roleLabel:SetText(L["Meine Rolle:"])

-- Offiziers-Notiz bearbeiten
local bNote = CreateFrame("Button", nil, detail, "UIPanelButtonTemplate")
bNote:SetSize(140, 22)
bNote:SetPoint("BOTTOMRIGHT", -8, 8)
bNote:SetText(L["Notiz bearbeiten"])
bNote:SetScript("OnClick", function()
    if Sel() then StaticPopup_Show("GUILDPRIDE_EVENT_NOTE", nil, nil, Sel()) end
end)

StaticPopupDialogs["GUILDPRIDE_EVENT_NOTE"] = {
    text = L["Offiziers-Notiz (z. B. Treffpunkt, benötigte Rollen):"],
    button1 = SAVE or L["Speichern"], button2 = CANCEL,
    hasEditBox = true, maxLetters = 100, editBoxWidth = 320,
    OnShow = function(self, e)
        local eb = self.editBox or self.EditBox
        eb:SetText(e.note or ""); eb:SetFocus()
    end,
    OnAccept = function(self, e)
        local eb = self.editBox or self.EditBox
        SetNote(e, strtrim(eb:GetText()))
    end,
    EditBoxOnEnterPressed = function(self)
        local p = self:GetParent()
        SetNote(p.data, strtrim(self:GetText())); p:Hide()
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

StaticPopupDialogs["GUILDPRIDE_DELETE_EVENT"] = {
    text = L["Event \"%s\" wirklich löschen?"],
    button1 = YES, button2 = NO,
    OnAccept = function(_, e) DeleteEvent(e); selected = nil end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

function page:Refresh()
    local list = UpcomingEvents()
    empty:SetShown(#list == 0)
    for i, b in ipairs(rows) do
        local e = list[i]
        b.event = e
        b:SetShown(e ~= nil)
        if e then
            local c = CountSignups(e)
            local mine = e.signups[Me()]
            b.when:SetText(ns.FormatDate(e.t, "short"))
            b.title:SetText(e.title)
            b.info:SetText(("%s%d|r / %s%d|r%s"):format(STATUS.yes.color, c.yes, STATUS.maybe.color, c.maybe,
                mine and ("  " .. STATUS[mine.s].color .. "●|r") or ""))
            b.bg:SetColorTexture(1, 0.82, 0, e.id == selected and 0.18 or (i % 2 == 0 and 0.04 or 0))
        end
    end

    local e = Sel()
    if e and (e.deleted or not e.title) then e, selected = nil, nil end
    detail:SetShown(e ~= nil)
    bYes:SetEnabled(e ~= nil); bMaybe:SetEnabled(e ~= nil); bNo:SetEnabled(e ~= nil)
    bDel:SetShown(CanManage() and e ~= nil)
    bNew:SetShown(CanManage())
    if not e then return end

    dTitle:SetText(e.title)
    dWhen:SetText((L["%s · erstellt von %s"]):format(ns.FormatDate(e.t, "long"), Ambiguate(e.creator or "?", "guild")))
    local descText = e.desc ~= "" and e.desc or L["|cff888888Keine Beschreibung.|r"]
    if e.note and e.note ~= "" then
        descText = descText .. L["\n|cffff7d0aOffiziers-Notiz:|r "] .. e.note
    end
    dDesc:SetText(descText)
    bNote:SetShown(CanManage())

    local myRole = MyRole()
    for key, b in pairs(roleBtns) do
        if key == myRole then b:LockHighlight() else b:UnlockHighlight() end
    end

    local groups = { yes = {}, maybe = {}, no = {} }
    local roleCount = { TANK = 0, HEALER = 0, DAMAGER = 0 }
    for name, s in pairs(e.signups) do
        local label = Ambiguate(name, "guild")
        if s.r and ROLES[s.r] and s.s ~= "no" then
            label = ("%s %s(%s)|r"):format(label, ROLES[s.r].color, ROLES[s.r].short)
            if s.s == "yes" then roleCount[s.r] = roleCount[s.r] + 1 end
        end
        table.insert(groups[s.s], label)
    end
    local lines = {
        (L["Zusagen nach Rolle: %sTanks %d|r · %sHeiler %d|r · %sDD %d|r"]):format(
            ROLES.TANK.color, roleCount.TANK, ROLES.HEALER.color, roleCount.HEALER,
            ROLES.DAMAGER.color, roleCount.DAMAGER),
    }
    for _, key in ipairs({ "yes", "maybe", "no" }) do
        table.sort(groups[key])
        lines[#lines + 1] = ("%s%s (%d):|r %s"):format(STATUS[key].color, STATUS[key].label, #groups[key],
            #groups[key] > 0 and table.concat(groups[key], ", ") or "–")
    end
    dPeople:SetText(table.concat(lines, "\n"))
end

---------------------------------------------------------------------
-- Dialog: Event erstellen
---------------------------------------------------------------------
local dlg = CreateFrame("Frame", "GuildPrideCreateEvent", UIParent, "BackdropTemplate")
dlg:SetSize(360, 230)
dlg:SetPoint("CENTER")
dlg:SetFrameStrata("DIALOG")
dlg:EnableMouse(true)
dlg:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
})
dlg:Hide()
tinsert(UISpecialFrames, "GuildPrideCreateEvent")

local dh = dlg:CreateFontString(nil, "OVERLAY", "GPFont_Large")
dh:SetPoint("TOP", 0, -16); dh:SetText(L["Neues Gildenevent"])

local function Field(label, y, width, maxLen)
    local l = dlg:CreateFontString(nil, "OVERLAY", "GPFont_TextSmall")
    l:SetPoint("TOPLEFT", 24, y); l:SetText(label)
    local eb = CreateFrame("EditBox", nil, dlg, "InputBoxTemplate")
    eb:SetSize(width, 22); eb:SetPoint("TOPLEFT", 28, y - 14)
    eb:SetAutoFocus(false); eb:SetMaxLetters(maxLen)
    return eb
end
local fTitle = Field(L["Titel"], -44, 300, 40)
local fDate  = Field(L["Datum & Uhrzeit (z. B. 24.12. 20:00)"], -86, 160, 16)
local fDesc  = Field(L["Beschreibung (optional)"], -128, 300, 120)
local fErr   = dlg:CreateFontString(nil, "OVERLAY", "GPFont_Red")
fErr:SetPoint("BOTTOM", 0, 48)

local ok = CreateFrame("Button", nil, dlg, "UIPanelButtonTemplate")
ok:SetSize(120, 24); ok:SetPoint("BOTTOMLEFT", 40, 18); ok:SetText(L["Erstellen"])
local cancel = CreateFrame("Button", nil, dlg, "UIPanelButtonTemplate")
cancel:SetSize(120, 24); cancel:SetPoint("BOTTOMRIGHT", -40, 18); cancel:SetText(CANCEL)
cancel:SetScript("OnClick", function() dlg:Hide() end)

ok:SetScript("OnClick", function()
    local title = strtrim(fTitle:GetText())
    local t = ParseDate(strtrim(fDate:GetText()))
    if title == "" then fErr:SetText(L["Bitte einen Titel eingeben."]); return end
    if not t then fErr:SetText(L["Datum bitte als TT.MM. HH:MM eingeben."]); return end
    if t < time() then fErr:SetText(L["Der Termin liegt in der Vergangenheit."]); return end
    CreateEvent(title, t, strtrim(fDesc:GetText()))
    dlg:Hide()
end)

function ns.ShowCreateDialog()
    if not CanManage() then ns.Print(L["Nur Offiziere können Events erstellen."]); return end
    fTitle:SetText(""); fDate:SetText(""); fDesc:SetText(""); fErr:SetText("")
    dlg:Show(); fTitle:SetFocus()
end

function ns.CloseEventDialogs() dlg:Hide() end

---------------------------------------------------------------------
-- Sync beim Login + Erinnerung 15 Min. vorher
---------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    C_Timer.After(8, function() Queue("REQ", nil, "1") end)
end)

C_Timer.NewTicker(30, function()
    if not GuildPrideDB then return end
    local now = Now()
    for _, e in pairs(DB()) do
        local mine = e.signups and e.signups[Me()]
        if e.title and not e.deleted and mine and mine.s ~= "no" and not e.reminded
           and e.t - now <= 900 and e.t - now > 0 then
            e.reminded = true
            RaidNotice_AddMessage(RaidWarningFrame,
                (L["%s %s beginnt in %d Min.!"]):format(ns.IconString(20), e.title, math.ceil((e.t - now) / 60)),
                ChatTypeInfo["GUILD"])
            if GuildPrideDB.sound then PlaySound(SOUNDKIT.RAID_WARNING) end
        end
    end
end)
