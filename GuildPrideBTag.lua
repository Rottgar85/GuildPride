-- GuildPride: BattleTags neuer Mitglieder -> Offiziersnotiz (mit Bestätigung)
--
-- Ablauf:
--  1. Mitglied stimmt zu, sein Addon flüstert den BattleTag an einen Offizier mit GuildPride.
--  2. Der Offizier speichert ihn verschleiert in seiner Warteliste und verteilt ihn
--     über den Offiziers-Addonkanal an alle anderen Offiziere (nur Offiziere empfangen ihn).
--  3. Alle Offiziere bekommen eine Benachrichtigung; einer drückt L["Übernehmen"],
--     das Addon trägt den BattleTag in die Offiziersnotiz ein und meldet das den anderen.
--
-- Hinweis: Echte Verschlüsselung ist in WoW-Addons nicht möglich (der Schlüssel stünde
-- im Addon-Code). Die Daten werden deshalb nur VERSCHLEIERT gespeichert – und
-- ausschließlich bei Offizieren, nie bei normalen Mitgliedern.
local ADDON, ns = ...
local L = ns.L
local SEP = ns.SEP
local OFFICER = "@OFFICER"

---------------------------------------------------------------------
-- Hilfen
---------------------------------------------------------------------
local function CanEditNotes()
    if C_GuildInfo and C_GuildInfo.CanEditOfficerNote then return C_GuildInfo.CanEditOfficerNote() end
    return CanEditOfficerNote and CanEditOfficerNote()
end

local function MyBattleTag()
    if not BNGetInfo then return end
    local _, tag = BNGetInfo()
    return tag
end

local function GuildKey()
    local name = GetGuildInfo("player")
    return name and (name .. "-" .. (GetNormalizedRealmName() or ""))
end

local function ValidTag(tag)
    return type(tag) == "string" and tag:match("^[^#%s|]+#%d+$") ~= nil
end

-- Verschleierung (XOR mit Schlüssel aus Gildenname, als Hex gespeichert)
local function KeyBytes()
    local k = (GuildKey() or "GuildPride") .. "|GP-v1"
    local out = {}
    for i = 1, #k do out[i] = k:byte(i) end
    return out
end

local function Obfuscate(s)
    local key, out = KeyBytes(), {}
    for i = 1, #s do
        out[i] = ("%02x"):format(bit.bxor(s:byte(i), key[(i - 1) % #key + 1]))
    end
    return table.concat(out)
end

local function Reveal(hex)
    local key, out, i = KeyBytes(), {}, 0
    for pair in hex:gmatch("%x%x") do
        i = i + 1
        out[i] = string.char(bit.bxor(tonumber(pair, 16), key[(i - 1) % #key + 1]))
    end
    return table.concat(out)
end

---------------------------------------------------------------------
-- Warteliste (nur bei Offizieren)
---------------------------------------------------------------------
local function Queue()
    local key = GuildKey() or "?"
    GuildPrideDB.btagQueue = GuildPrideDB.btagQueue or {}
    GuildPrideDB.btagQueue[key] = GuildPrideDB.btagQueue[key] or {}
    return GuildPrideDB.btagQueue[key]   -- [Name-Realm] = { d = "<verschleiert>", t = Zeit }
end

local function PendingCount()
    local n = 0
    for _ in pairs(Queue()) do n = n + 1 end
    return n
end

local function FindMember(fullName)
    for i = 1, GetNumGuildMembers() do
        local name, _, _, _, _, _, _, officerNote = GetGuildRosterInfo(i)
        if name and (name == fullName or Ambiguate(name, "none") == Ambiguate(fullName, "none")) then
            return i, officerNote or ""
        end
    end
end

local ShowNext -- weiter unten

local function Notify(name)
    if GuildPrideDB.btagAuto == false then return end
    local msg = (L["Neuer BattleTag zur Bestätigung: |cffffd100%s|r (%d offen)"]):format(Ambiguate(name, "guild"), PendingCount())
    ns.Print(msg .. L[" – |cffff8c40/gp btags|r"])
    RaidNotice_AddMessage(RaidWarningFrame, ns.IconString(20) .. " " .. msg, ChatTypeInfo["OFFICER"])
    if GuildPrideDB.sound then PlaySound(SOUNDKIT.TELL_MESSAGE) end
    if not InCombatLockdown() then ShowNext() end
end

-- Eintrag aufnehmen (von Mitglied oder anderem Offizier)
local function AddPending(name, tag, t, quiet)
    if not ValidTag(tag) or not CanEditNotes() then return end
    local q = Queue()
    local index, note = FindMember(name)
    if index and note:find(tag, 1, true) then return end -- steht schon drin
    local isNew = not q[name]
    q[name] = { d = Obfuscate(tag), t = t or GetServerTime() }
    if isNew and not quiet then Notify(name) end
end

local function RemovePending(name)
    Queue()[name] = nil
end

---------------------------------------------------------------------
-- Übernehmen / Ablehnen
---------------------------------------------------------------------
local function Accept(name)
    local entry = Queue()[name]
    if not entry then return end
    local tag = Reveal(entry.d)
    local index, note = FindMember(name)
    if not index then
        ns.Print((L["%s ist nicht mehr in der Gilde – Eintrag verworfen."]):format(Ambiguate(name, "guild")))
        RemovePending(name); ns.Queue("BTDN", OFFICER, name)
        return
    end
    local newNote = (note == "" and tag) or (note:find(tag, 1, true) and note) or (note .. " " .. tag)
    if #newNote > 31 then
        ns.Print((L["Offiziersnotiz von |cffffd100%s|r ist zu voll. Bitte von Hand eintragen: %s"]):format(Ambiguate(name, "guild"), tag))
        return
    end
    local ok = GuildRosterSetOfficerNote and pcall(GuildRosterSetOfficerNote, index, newNote)
    if ok then
        ns.Print((L["BattleTag von |cffffd100%s|r übernommen."]):format(Ambiguate(name, "guild")))
        RemovePending(name)
        ns.Queue("BTDN", OFFICER, name)  -- andere Offiziere: erledigt
        ns.Queue("BTOK", name, "1")      -- Mitglied: erledigt
    else
        ns.Print(L["|cffff4040Offiziersnotiz konnte nicht geändert werden.|r"])
    end
end

local function Decline(name)
    RemovePending(name)
    ns.Queue("BTDN", OFFICER, name)
    ns.Print((L["BattleTag von %s abgelehnt."]):format(Ambiguate(name, "guild")))
end

StaticPopupDialogs["GUILDPRIDE_BTAG_CONFIRM"] = {
    text = L["|cffff8c40Neuer BattleTag|r\n\n|cffffd100%s|r möchte seinen BattleTag in die Offiziersnotiz eintragen lassen:\n\n|cffffffff%s|r"],
    button1 = L["Übernehmen"], button2 = L["Ablehnen"], button3 = L["Später"],
    OnAccept = function(_, name) Accept(name); C_Timer.After(0.2, ShowNext) end,
    OnCancel = function(_, name, reason) if reason == "clicked" then Decline(name); C_Timer.After(0.2, ShowNext) end end,
    OnAlt = function() end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

function ShowNext()
    if InCombatLockdown() or StaticPopup_FindVisible("GUILDPRIDE_BTAG_CONFIRM") then return end
    for name, entry in pairs(Queue()) do
        local popup = StaticPopup_Show("GUILDPRIDE_BTAG_CONFIRM", Ambiguate(name, "guild"), Reveal(entry.d))
        if popup then popup.data = name end
        return
    end
end

---------------------------------------------------------------------
-- Nachrichten
---------------------------------------------------------------------
-- Mitglied fragt nach Offizieren -> Offiziere melden sich per Flüstern
ns.On("OFFQ", function(_, sender)
    if sender ~= ns.Me() and CanEditNotes() then ns.Queue("OFFP", sender, "1") end
end)

-- Offizier empfängt BattleTag vom Mitglied
ns.On("BTAG", function(payload, sender)
    if sender == ns.Me() or not CanEditNotes() then return end
    if not FindMember(sender) or not ValidTag(payload) then return end
    AddPending(sender, payload)
    ns.Queue("BTRC", sender, "1")                                        -- Mitglied: angekommen
    ns.Queue("BTSY", OFFICER, sender, Obfuscate(payload), GetServerTime()) -- an alle Offiziere
end)

-- Synchronisation unter Offizieren (nur Offiziers-Kanal)
ns.On("BTSY", function(payload, sender)
    if sender == ns.Me() or not CanEditNotes() then return end
    local name, data, t = strsplit(SEP, payload)
    if name and data then AddPending(name, Reveal(data), tonumber(t)) end
end)

ns.On("BTDN", function(payload, sender)
    if sender == ns.Me() then return end
    if Queue()[payload] then
        RemovePending(payload)
        local popup = StaticPopup_FindVisible("GUILDPRIDE_BTAG_CONFIRM")
        if popup and popup.data == payload then popup:Hide() end
    end
end)

-- Offizier loggt sich ein -> Warteliste abgleichen
ns.On("BTRQ", function(_, sender)
    if sender == ns.Me() or not CanEditNotes() then return end
    for name, entry in pairs(Queue()) do
        ns.Queue("BTSY", sender, name, entry.d, entry.t)
    end
end)

---------------------------------------------------------------------
-- Mitglieds-Seite
---------------------------------------------------------------------
local pending = false   -- wartet gerade auf Antwort
local waiting = false   -- zugestimmt, aber noch kein Offizier online

local readyOfficer -- Offizier, an den gesendet werden kann

StaticPopupDialogs["GUILDPRIDE_BTAG_SEND"] = {
    text = L["|cffff8c40Offizier online|r\n\n"]
        .. L["|cffffd100%s|r ist jetzt online.\n\n"]
        .. L["Mit |cffffffff„Jetzt senden“|r wird dein BattleTag (|cffffffff%s|r) an die Offiziere geschickt. "]
        .. L["Sie tragen ihn danach in deine Offiziersnotiz ein – so können sie dich auch erreichen, "]
        .. L["wenn du auf einem anderen Charakter spielst. Nur Offiziere können die Notiz sehen.\n\n"]
        .. L["|cff999999„Später“: Du wirst beim nächsten Offizier wieder gefragt.\n"]
        .. L["„Nicht senden“: Du wirst nicht mehr gefragt (später mit /gp battletag möglich).|r"],
    button1 = L["Jetzt senden"], button2 = L["Nicht senden"], button3 = L["Später"],
    OnAccept = function()
        local tag = MyBattleTag()
        if tag and readyOfficer then
            waiting = false
            ns.Queue("BTAG", readyOfficer, tag)
        end
    end,
    OnCancel = function(_, _, reason)
        if reason == "clicked" then
            waiting = false
            GuildPrideDB.btagAsked[GuildKey() or "?"] = "no"
            ns.Print(L["Okay, dein BattleTag wird nicht gesendet. Mit |cffff8c40/gp battletag|r kannst du es später nachholen."])
        end
    end,
    OnAlt = function() end, -- Später: bleibt wartend
    timeout = 0, whileDead = true, hideOnEscape = true, showAlert = true,
}

local function AskToSend()
    if InCombatLockdown() or not readyOfficer then return end
    if StaticPopup_FindVisible("GUILDPRIDE_BTAG_SEND") then return end
    local tag = MyBattleTag()
    if tag then StaticPopup_Show("GUILDPRIDE_BTAG_SEND", Ambiguate(readyOfficer, "guild"), tag) end
end

ns.On("OFFP", function(_, sender)
    if sender == ns.Me() or not (pending or waiting) then return end
    local tag = MyBattleTag()
    if not tag then return end
    if pending then
        -- Gerade erst zugestimmt: direkt senden
        pending = false
        ns.Queue("BTAG", sender, tag)
        return
    end
    -- Hat gewartet: informieren und selbst entscheiden lassen
    readyOfficer = sender
    if GuildPrideDB.sound then PlaySound(SOUNDKIT.TELL_MESSAGE) end
    RaidNotice_AddMessage(RaidWarningFrame, (L["%s Offizier %s ist online – du kannst deinen BattleTag jetzt senden."]):format(
        ns.IconString(20), Ambiguate(sender, "guild")), ChatTypeInfo["GUILD"])
    AskToSend()
end)

local regen = CreateFrame("Frame")
regen:RegisterEvent("PLAYER_REGEN_ENABLED")
regen:SetScript("OnEvent", function() if waiting and readyOfficer then C_Timer.After(1, AskToSend) end end)

ns.On("BTRC", function()
    GuildPrideDB.btagSent = GuildPrideDB.btagSent or {}
    GuildPrideDB.btagSent[GuildKey() or "?"] = true
    ns.Print(L["Dein BattleTag wurde an die Offiziere übermittelt. Sie tragen ihn in Kürze ein."])
end)

ns.On("BTOK", function()
    GuildPrideDB.btagDone = GuildPrideDB.btagDone or {}
    GuildPrideDB.btagDone[GuildKey() or "?"] = true
    ns.Print(L["Dein BattleTag wurde in deine Offiziersnotiz eingetragen. Danke!"])
end)

local function StartSend()
    if not MyBattleTag() then
        ns.Print(L["Kein BattleTag gefunden (Battle.net nicht verbunden?)."])
        return
    end
    pending = true
    ns.Queue("OFFQ", nil, "1")
    C_Timer.After(20, function()
        if pending then
            pending, waiting = false, true
            ns.Print(L["Gerade ist kein Offizier mit GuildPride online. Du bekommst Bescheid, sobald einer online kommt."])
        end
    end)
end

StaticPopupDialogs["GUILDPRIDE_BTAG"] = {
    text = L["Willkommen in der Gilde!\n\nDarf GuildPride deinen BattleTag (%s) an die Offiziere schicken, "]
        .. L["damit sie ihn in deine Offiziersnotiz eintragen? Nur Offiziere können ihn sehen."],
    button1 = YES, button2 = NO,
    OnAccept = function(_, key) GuildPrideDB.btagAsked[key] = "yes"; StartSend() end,
    OnCancel = function(_, key) GuildPrideDB.btagAsked[key] = "no" end,
    timeout = 0, whileDead = true, hideOnEscape = false,
}

local function CheckMember()
    local key = GuildKey()
    if not IsInGuild() or not key or CanEditNotes() then return end
    GuildPrideDB.btagAsked = GuildPrideDB.btagAsked or {}
    GuildPrideDB.btagSent = GuildPrideDB.btagSent or {}
    GuildPrideDB.btagDone = GuildPrideDB.btagDone or {}
    if GuildPrideDB.btagDone[key] or GuildPrideDB.btagSent[key] or GuildPrideDB.btagAsked[key] == "no" then return end
    if GuildPrideDB.btagAsked[key] == "yes" then StartSend(); return end
    local tag = MyBattleTag()
    if not tag then return end
    local popup = StaticPopup_Show("GUILDPRIDE_BTAG", tag)
    if popup then popup.data = key end
end

local function CheckOfficer()
    if not CanEditNotes() then return end
    ns.Queue("OFFP", nil, "1")   -- wartende Mitglieder informieren
    ns.Queue("BTRQ", OFFICER, "1")
    C_Timer.After(5, function()
        local n = PendingCount()
        if n > 0 then
            ns.Print((L["%d BattleTag(s) warten auf Bestätigung – |cffff8c40/gp btags|r"]):format(n))
            ShowNext()
        end
    end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_GUILD_UPDATE")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        if CanEditNotes() and PendingCount() > 0 then C_Timer.After(1, ShowNext) end
        return
    end
    C_Timer.After(event == "PLAYER_LOGIN" and 15 or 5, function()
        if InCombatLockdown() then return end
        CheckOfficer()
        CheckMember()
    end)
end)

C_Timer.NewTicker(600, function()
    if waiting and IsInGuild() and not InCombatLockdown() then ns.Queue("OFFQ", nil, "1") end
end)

-- /gp battletag  -> Mitglied: erneut senden   |   /gp btags -> Offizier: Warteliste abarbeiten
local orig = SlashCmdList.GUILDPRIDE
SlashCmdList.GUILDPRIDE = function(arg)
    local cmd = (arg or ""):lower()
    if cmd == "battletag" then
        local key = GuildKey()
        if key then
            for _, t in ipairs({ "btagAsked", "btagSent", "btagDone" }) do
                if GuildPrideDB[t] then GuildPrideDB[t][key] = nil end
            end
        end
        CheckMember()
    elseif cmd == "btags" then
        if not CanEditNotes() then ns.Print(L["Nur Offiziere können BattleTags bestätigen."]); return end
        if PendingCount() == 0 then ns.Print(L["Keine BattleTags offen."]); return end
        ShowNext()
    else
        orig(arg)
    end
end
