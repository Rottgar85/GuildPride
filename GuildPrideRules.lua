-- GuildPride: Gildenregeln (von Offizieren gepflegt, an alle synchronisiert)
local ADDON, ns = ...
local L = ns.L
local SEP = ns.SEP
local CHUNK = 200

local page = ns.AddTab(L["Regeln"])

---------------------------------------------------------------------
-- Anzeige
---------------------------------------------------------------------
local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 0, -4)
scroll:SetPoint("BOTTOMRIGHT", -26, 34)

local view = CreateFrame("Frame", nil, scroll)
view:SetSize(630, 1)
local text = view:CreateFontString(nil, "OVERLAY", "GPFont_Text")
text:SetPoint("TOPLEFT", 4, -4)
text:SetWidth(620); text:SetJustifyH("LEFT"); text:SetSpacing(4)

local edit = CreateFrame("EditBox", nil, scroll)
edit:SetMultiLine(true)
edit:SetFontObject(GPFont_Text)
edit:SetWidth(620)
edit:SetAutoFocus(false)
edit:SetMaxLetters(2000)
edit:SetScript("OnEscapePressed", edit.ClearFocus)
local editBg = edit:CreateTexture(nil, "BACKGROUND")
editBg:SetAllPoints(); editBg:SetColorTexture(0, 0, 0, 0.4)

local info = page:CreateFontString(nil, "OVERLAY", "GPFont_MutedSmall")
info:SetPoint("BOTTOMLEFT", 2, 8)

local bEdit = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
bEdit:SetSize(110, 24); bEdit:SetPoint("BOTTOMRIGHT", -120, 0); bEdit:SetText(L["Bearbeiten"])
local bSave = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
bSave:SetSize(110, 24); bSave:SetPoint("BOTTOMRIGHT", 0, 0); bSave:SetText(L["Speichern"])

local editing = false

local function Rules()
    GuildPrideDB.rules = GuildPrideDB.rules or { text = "", ver = 0 }
    return GuildPrideDB.rules
end

function page:Refresh()
    local r = Rules()
    local officer = ns.IsOfficer()
    if editing then
        scroll:SetScrollChild(edit); view:Hide(); edit:Show()
    else
        scroll:SetScrollChild(view); edit:Hide(); view:Show()
        text:SetText(r.text ~= "" and r.text or L["|cff888888Es wurden noch keine Regeln festgelegt.|r"])
        view:SetHeight(text:GetStringHeight() + 10)
    end
    -- Nur das Datum anzeigen, nicht wer die Regeln geschrieben hat
    info:SetText((r.ver > 0 and r.text ~= "") and (L["Stand: "] .. date("%d.%m.%Y %H:%M", r.ver)) or "")
    bEdit:SetShown(officer)
    bSave:SetShown(officer and editing)
    bEdit:SetText(editing and L["Abbrechen"] or L["Bearbeiten"])
    -- Gelesen markieren
    GuildPrideDB.rulesSeen = r.ver
end

---------------------------------------------------------------------
-- Senden / Empfangen in Stücken (Addon-Nachrichten max. 255 Byte)
---------------------------------------------------------------------
local function SendRules(target)
    local r = Rules()
    if r.ver == 0 then return end
    local parts = {}
    local s = r.text
    if s == "" then parts[1] = "" end
    for i = 1, #s, CHUNK do parts[#parts + 1] = s:sub(i, i + CHUNK - 1) end
    for i, p in ipairs(parts) do
        ns.Queue("RUL", target, r.ver, i, #parts, r.by or "", p)
    end
end

local buffers = {}
ns.On("RUL", function(payload, sender)
    if sender == ns.Me() then return end
    local ver, i, n, by, chunk = payload:match("^(%d+)" .. SEP .. "(%d+)" .. SEP .. "(%d+)" .. SEP .. "([^" .. SEP .. "]*)" .. SEP .. "(.*)$")
    ver, i, n = tonumber(ver), tonumber(i), tonumber(n)
    if not ver or ver <= Rules().ver then return end
    local key = sender .. ver
    local buf = buffers[key] or { n = n, got = 0, parts = {} }
    buffers[key] = buf
    if not buf.parts[i] then buf.parts[i] = chunk; buf.got = buf.got + 1 end
    if buf.got == buf.n then
        buffers[key] = nil
        local r = Rules()
        r.text = (table.concat(buf.parts):gsub("|", ""))
        r.ver, r.by = ver, by ~= "" and by or nil
        ns.Print(L["Die Gildenregeln wurden aktualisiert. Schau im Gildenfenster unter \"Regeln\" nach."])
        if ns.RefreshUI then ns.RefreshUI() end
    end
end)

ns.On("REQ", function(_, sender)
    if sender ~= ns.Me() then SendRules(sender) end
end)

---------------------------------------------------------------------
-- Bearbeiten
---------------------------------------------------------------------
bEdit:SetScript("OnClick", function()
    editing = not editing
    if editing then edit:SetText(Rules().text); edit:SetFocus() end
    page:Refresh()
end)

bSave:SetScript("OnClick", function()
    local r = Rules()
    r.text = (strtrim(edit:GetText()):gsub("|", ""):gsub(SEP, ""))
    r.ver = GetServerTime()
    r.by = ns.Me()
    editing = false
    SendRules()
    ns.Print(L["Regeln gespeichert und an die Gilde gesendet."])
    page:Refresh()
end)

---------------------------------------------------------------------
-- Ungelesene Regeln beim Öffnen zuerst anzeigen
---------------------------------------------------------------------
ns.GuildFrame:HookScript("OnShow", function()
    local r = Rules()
    if r.ver > 0 and (GuildPrideDB.rulesSeen or 0) < r.ver then
        ns.GuildFrame.selected = page.tabId
    end
end)
