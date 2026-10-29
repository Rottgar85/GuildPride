-- GuildPride: Mitglieder verwalten (Gilde und Communities)
--
-- Befördern, Degradieren, Entfernen und Gildenleitung sind seit Patch 7.3 für Addons
-- gesperrt. Wir nutzen deshalb sichere Knöpfe (SecureActionButtonTemplate), die beim
-- Klick die Blizzard-Befehle /gpromote, /gdemote, /gremove und /gleader ausführen –
-- genau wie ein Makro. Gildennotizen kann kein Addon ändern; dafür öffnen wir das
-- Blizzard-Gildenfenster. Communities (C_Club) lassen sich direkt verwalten.
local ADDON, ns = ...
local L = ns.L

local CMD = {
    promote = _G.SLASH_GUILD_PROMOTE1 or "/gpromote",
    demote  = _G.SLASH_GUILD_DEMOTE1 or "/gdemote",
    remove  = _G.SLASH_GUILD_UNINVITE1 or "/gremove",
    leader  = _G.SLASH_GUILD_LEADER1 or "/gleader",
}
local InviteToGroup = (C_PartyInfo and C_PartyInfo.InviteUnit) or InviteUnit

---------------------------------------------------------------------
-- Rechte
---------------------------------------------------------------------
local function MyRankIndex()
    local _, _, r = GetGuildInfo("player")
    return r or 99
end

local function NumRanks()
    return GuildControlGetNumRanks and GuildControlGetNumRanks() or 0
end

local function RankName(rankIndex)
    return GuildControlGetRankName and GuildControlGetRankName(rankIndex + 1) or tostring(rankIndex)
end

local function CanViewOfficerNote()
    if C_GuildInfo and C_GuildInfo.CanViewOfficerNote then return C_GuildInfo.CanViewOfficerNote() end
    return CanViewOfficerNote and CanViewOfficerNote()
end

local function CanEditNotes()
    local pub = (C_GuildInfo and C_GuildInfo.CanEditPublicNote and C_GuildInfo.CanEditPublicNote())
        or (CanEditPublicNote and CanEditPublicNote())
    local off = (C_GuildInfo and C_GuildInfo.CanEditOfficerNote and C_GuildInfo.CanEditOfficerNote())
        or (CanEditOfficerNote and CanEditOfficerNote())
    return pub or off
end

local function Can(fn) return fn and fn() and true or false end

local function Has(list, value)
    for _, v in ipairs(list or {}) do if v == value then return true end end
    return false
end

-- Gildenmitglied frisch aus der Gildenliste lesen
local function GuildMember(full)
    for i = 1, GetNumGuildMembers() do
        local name, rank, rankIndex, level, _, zone, note, officerNote, isOnline, _, classFile = GetGuildRosterInfo(i)
        if name and ns.FullName(name) == full then
            return { name = Ambiguate(name, "guild"), full = full, rank = rank, rankIndex = rankIndex, level = level,
                     zone = zone, note = note, officerNote = officerNote, online = isOnline, class = classFile,
                     guild = true, inGuild = true, isSelf = full == ns.Me() }
        end
    end
end

---------------------------------------------------------------------
-- Detailfenster für Gildenmitglieder
---------------------------------------------------------------------
local page = ns.MembersPage
local panel = CreateFrame("Frame", "GuildPrideMemberPanel", page, "BackdropTemplate")
panel:SetSize(300, 440)
panel:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -30)
panel:SetFrameLevel(page:GetFrameLevel() + 20)
panel:EnableMouse(true)
panel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })
panel:SetBackdropColor(0.07, 0.05, 0.04, 0.97)
panel:SetBackdropBorderColor(0.80, 0.55, 0.27, 1)
panel:Hide()

local closeBtn = CreateFrame("Button", nil, panel)
closeBtn:SetSize(22, 22); closeBtn:SetPoint("TOPRIGHT", -8, -8)
closeBtn:SetNormalTexture(ns.MEDIA .. "close"); closeBtn:SetHighlightTexture(ns.MEDIA .. "close_hover")
closeBtn:SetScript("OnClick", function() panel:Hide() end)

local function Text(font, y, width)
    local fs = panel:CreateFontString(nil, "OVERLAY", font)
    fs:SetPoint("TOPLEFT", 16, y)
    fs:SetWidth(width or 268); fs:SetJustifyH("LEFT")
    return fs
end

local nameText = Text("GPFont_Large", -14, 240)
local infoText = Text("GPFont_TextSmall", -38)
local statusText = Text("GPFont_TextSmall", -56)
local noteLabel = Text("GPFont_TextBold", -82); noteLabel:SetText(L["Öffentliche Notiz"])
local noteText = Text("GPFont_TextSmall", -100); noteText:SetHeight(28); noteText:SetJustifyV("TOP")
local offLabel = Text("GPFont_TextBold", -132); offLabel:SetText(L["Offiziersnotiz"])
local offText = Text("GPFont_TextSmall", -150); offText:SetHeight(28); offText:SetJustifyV("TOP")
local manageLabel = Text("GPFont_TextBold", -222); manageLabel:SetText(L["Verwaltung"])

local function Button(w, label, x, y, secure)
    local b = CreateFrame("Button", nil, panel, secure and "SecureActionButtonTemplate, UIPanelButtonTemplate" or "UIPanelButtonTemplate")
    b:SetSize(w, 24); b:SetPoint("TOPLEFT", x, y); b:SetText(label)
    if secure then
        b:RegisterForClicks("AnyUp", "AnyDown")
        b:SetAttribute("type", "macro")
        -- Nach der Aktion die Gildenliste neu laden
        b:HookScript("OnClick", function()
            C_Timer.After(1, function() if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end end)
        end)
    end
    return b
end

local bNotes   = Button(268, L["Notizen bearbeiten (Blizzard-Fenster)"], 16, -186)
local bPromote = Button(132, L["Befördern"], 16, -242, true)
local bDemote  = Button(132, L["Degradieren"], 152, -242, true)
local bRank    = Button(170, L["Rang wählen  ▾"], 16, -272)
local bSetRank = Button(94, L["Rang setzen"], 190, -272, true)
local bKick    = Button(268, L["Aus der Gilde entfernen …"], 16, -302)
local bKickYes = Button(268, L["|cffff4040Wirklich entfernen|r"], 16, -302, true)
local bLead    = Button(268, L["Gildenleitung übergeben …"], 16, -332)
local bLeadYes = Button(268, L["|cffff4040Wirklich Gildenleitung übergeben|r"], 16, -332, true)
local bTell    = Button(132, L["Anflüstern"], 16, -372)
local bGroup   = Button(132, L["In Gruppe einladen"], 152, -372)
local hint = Text("GPFont_MutedSmall", -406)
hint:SetText(L["Rangänderungen und Entfernen laufen über die Blizzard-Befehle /gpromote, /gdemote und /gremove."])

local current, targetRank

local function SetMacro(b, text)
    if InCombatLockdown() then return end
    b:SetAttribute("macrotext", text)
end

-- Bestätigungsknöpfe kurz nach dem Klick wieder einklappen
-- (verzögert, damit die Aktion beim Loslassen der Maustaste noch läuft)
for _, pair in ipairs({ { bKick, bKickYes }, { bLead, bLeadYes } }) do
    local ask, yes = pair[1], pair[2]
    yes:Hide()
    ask:SetScript("OnClick", function() if not InCombatLockdown() then ask:Hide(); yes:Show() end end)
    yes:HookScript("OnClick", function()
        C_Timer.After(0.3, function() if not InCombatLockdown() then yes:Hide(); ask:Show() end end)
    end)
end

local function Steps(m, target)
    local n, lines = Ambiguate(m.full, "none"), {}
    local diff = target - m.rankIndex
    local cmd = diff > 0 and CMD.demote or CMD.promote
    for _ = 1, math.abs(diff) do lines[#lines + 1] = cmd .. " " .. n end
    return table.concat(lines, "\n")
end

local function UpdateRankButton()
    local m = current
    if not m then return end
    bRank:SetText((targetRank and RankName(targetRank) or L["Rang wählen"]) .. "  ▾")
    local ok = targetRank ~= nil and targetRank ~= m.rankIndex
    bSetRank:SetEnabled(ok)
    SetMacro(bSetRank, ok and Steps(m, targetRank) or "")
end

bRank:SetScript("OnClick", function(self)
    local m = current
    if not (m and MenuUtil and MenuUtil.CreateContextMenu) then return end
    local my = MyRankIndex()
    MenuUtil.CreateContextMenu(self, function(_, root)
        root:CreateTitle(L["Neuer Rang"])
        for r = my + 1, NumRanks() - 1 do
            local up = r < m.rankIndex
            local allowed = r == m.rankIndex or (up and Can(CanGuildPromote)) or (not up and Can(CanGuildDemote))
            if allowed then
                local label = RankName(r) .. (r == m.rankIndex and (" |cff999999(" .. L["aktuell"] .. ")|r") or "")
                root:CreateRadio(label, function() return targetRank == r end, function()
                    targetRank = r
                    UpdateRankButton()
                end)
            end
        end
    end)
end)

bNotes:SetScript("OnClick", function()
    ns.OpenBlizzardGuild()
    ns.Print(L["Gildennotizen können Addons nicht ändern. Bearbeite sie im Blizzard-Gildenfenster (Rechtsklick auf das Mitglied)."])
end)
bTell:SetScript("OnClick", function() if current then ChatFrame_SendTell(current.full) end end)
bGroup:SetScript("OnClick", function() if current and InviteToGroup then InviteToGroup(current.full) end end)

local function Fill(m)
    current = m
    targetRank = nil
    local c = RAID_CLASS_COLORS[m.class] or NORMAL_FONT_COLOR
    nameText:SetText(("|cff%02x%02x%02x%s|r"):format(c.r * 255, c.g * 255, c.b * 255, m.name))
    infoText:SetText(("Lvl %d · %s"):format(m.level or 0, m.rank or ""))
    statusText:SetText(m.online and ("|cff40ff40●|r " .. (m.zone or "")) or ("|cff777777" .. (m.last or L["offline"]) .. "|r"))
    noteText:SetText((m.note and m.note ~= "") and m.note or L["|cff888888Keine Notiz.|r"])
    local canOff = CanViewOfficerNote()
    offLabel:SetShown(canOff); offText:SetShown(canOff)
    offText:SetText((m.officerNote and m.officerNote ~= "") and m.officerNote or L["|cff888888Keine Notiz.|r"])
    bNotes:SetShown(CanEditNotes() and true or false)
    bTell:SetEnabled(m.online and not m.isSelf)
    bGroup:SetEnabled(m.online and not m.isSelf)

    local my, last = MyRankIndex(), NumRanks() - 1
    local below = not m.isSelf and m.rankIndex > my          -- Ziel steht unter mir
    local canPromote = below and Can(CanGuildPromote) and m.rankIndex - 1 > my
    local canDemote = below and Can(CanGuildDemote) and m.rankIndex < last
    local canKick = below and Can(CanGuildRemove)
    local canLead = not m.isSelf and Can(IsGuildLeader)
    local any = canPromote or canDemote or canKick or canLead

    manageLabel:SetShown(any); hint:SetShown(any)
    bPromote:SetShown(any); bDemote:SetShown(any); bRank:SetShown(any); bSetRank:SetShown(any)
    bPromote:SetEnabled(canPromote and true or false)
    bDemote:SetEnabled(canDemote and true or false)
    bRank:SetEnabled((canPromote or canDemote) and true or false)
    bKick:SetShown(canKick and true or false); bKickYes:Hide()
    bLead:SetShown(canLead and true or false); bLeadYes:Hide()

    local n = Ambiguate(m.full, "none")
    SetMacro(bPromote, CMD.promote .. " " .. n)
    SetMacro(bDemote, CMD.demote .. " " .. n)
    SetMacro(bKickYes, CMD.remove .. " " .. n)
    SetMacro(bLeadYes, CMD.leader .. " " .. n)
    UpdateRankButton()
end

function ns.HideMemberPanel()
    if not InCombatLockdown() then panel:Hide() end
end

---------------------------------------------------------------------
-- Community: Notiz, Rolle, Entfernen
---------------------------------------------------------------------
StaticPopupDialogs["GUILDPRIDE_CLUB_NOTE"] = {
    text = L["Notiz für %s:"],
    button1 = L["Speichern"], button2 = L["Abbrechen"],
    hasEditBox = true, maxLetters = 120, editBoxWidth = 320,
    OnShow = function(self, m)
        local eb = self.editBox or self.EditBox
        eb:SetText(m and m.note or ""); eb:HighlightText()
    end,
    OnAccept = function(self, m)
        local eb = self.editBox or self.EditBox
        local ok = pcall(C_Club.SetClubMemberNote, m.clubId, m.memberId, strtrim(eb:GetText()))
        if not ok then ns.Print(L["|cffff4040Notiz konnte nicht gespeichert werden.|r"]) end
    end,
    EditBoxOnEnterPressed = function(self)
        local p = self:GetParent()
        StaticPopupDialogs["GUILDPRIDE_CLUB_NOTE"].OnAccept(p, p.data); p:Hide()
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

StaticPopupDialogs["GUILDPRIDE_CLUB_KICK"] = {
    text = L["%s wirklich aus „%s“ entfernen?"],
    button1 = YES, button2 = NO,
    OnAccept = function(_, m)
        local ok = pcall(C_Club.KickMember, m.clubId, m.memberId)
        if not ok then ns.Print(L["|cffff4040Mitglied konnte nicht entfernt werden.|r"]) end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

local function ClubPrivileges(clubId)
    return C_Club.GetClubPrivileges and C_Club.GetClubPrivileges(clubId) or {}
end

local function AddClubManagement(root, m)
    local priv = ClubPrivileges(m.clubId)
    local roles = (not m.isSelf and C_Club.GetAssignableRoles) and C_Club.GetAssignableRoles(m.clubId, m.memberId) or {}
    local canNote = (m.isSelf and priv.canSetOwnMemberNote) or (not m.isSelf and priv.canSetOtherMemberNote)
    local canKick = not m.isSelf and Has(priv.kickableRoleIds, m.role)
    if #roles == 0 and not canNote and not canKick then return end

    root:CreateDivider()
    root:CreateTitle(L["Verwaltung"])
    if #roles > 0 and C_Club.AssignMemberRole then
        local sub = root:CreateButton(L["Rolle ändern"])
        for _, role in ipairs(roles) do
            sub:CreateRadio(ns.CLUB_ROLES[role] or tostring(role), function() return m.role == role end, function()
                local ok = pcall(C_Club.AssignMemberRole, m.clubId, m.memberId, role)
                if not ok then ns.Print(L["|cffff4040Rolle konnte nicht geändert werden.|r"]) end
            end)
        end
    end
    if canNote and C_Club.SetClubMemberNote then
        root:CreateButton(L["Notiz bearbeiten"], function()
            StaticPopup_Show("GUILDPRIDE_CLUB_NOTE", m.name, nil, m)
        end)
    end
    if canKick and C_Club.KickMember then
        root:CreateButton(L["|cffff4040Aus der Community entfernen|r"], function()
            StaticPopup_Show("GUILDPRIDE_CLUB_KICK", m.name, m.club and m.club.name or "", m)
        end)
    end
end

---------------------------------------------------------------------
-- Rechtsklick-Menü (Gilde und Community)
---------------------------------------------------------------------
function ns.MemberMenu(owner, m)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then
        if m.full and m.online and not m.isSelf then ChatFrame_SendTell(m.full) end
        return
    end
    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateTitle(m.name)
        if m.full and m.online and not m.isSelf then
            root:CreateButton(L["Anflüstern"], function() ChatFrame_SendTell(m.full) end)
            if InviteToGroup then root:CreateButton(L["In Gruppe einladen"], function() InviteToGroup(m.full) end) end
        end
        if m.full and not m.isSelf and C_FriendList and C_FriendList.AddFriend then
            root:CreateButton(L["Als Freund hinzufügen"], function() C_FriendList.AddFriend(m.full) end)
        end
        if m.full and not m.inGuild and IsInGuild() and (not CanGuildInvite or CanGuildInvite()) then
            root:CreateButton(L["In Gilde einladen"], function() ns.InviteToGuild(m.full) end)
        end
        if m.full and not m.isSelf then
            local clubs = {}
            for _, club in ipairs(ns.Communities()) do
                if not club.bnet and club.id ~= m.clubId and ns.CanInviteToClub(club.id) then clubs[#clubs + 1] = club end
            end
            if #clubs > 0 then
                local sub = root:CreateButton(L["In Community einladen"])
                for _, club in ipairs(clubs) do
                    sub:CreateButton(club.name, function() ns.InviteToClub(club, m.full) end)
                end
            end
        end
        if m.full then
            root:CreateButton(L["Namen in den Chat einfügen"], function()
                if ChatFrame_OpenChat then ChatFrame_OpenChat(Ambiguate(m.full, "none")) end
            end)
        end
        if m.guild then
            root:CreateDivider()
            root:CreateButton(L["Details und Verwaltung …"], function() ns.ShowMemberPanel(m) end)
        elseif m.clubId then
            AddClubManagement(root, m)
        end
    end)
end

-- Linksklick: Gildenmitglied -> Detailfenster, Community-Mitglied -> Menü
function ns.ShowMemberPanel(m, owner)
    if InCombatLockdown() then return end
    if not m.guild then
        if owner then ns.MemberMenu(owner, m) end
        return
    end
    local fresh = GuildMember(m.full)
    if fresh then fresh.last = m.last end
    Fill(fresh or m)
    panel:Show()
end

---------------------------------------------------------------------
-- Aktuell halten
---------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("GUILD_ROSTER_UPDATE")
ev:RegisterEvent("GUILD_RANKS_UPDATE")
ev:SetScript("OnEvent", function()
    if not panel:IsShown() or not current or InCombatLockdown() then return end
    local fresh = GuildMember(current.full)
    if fresh then
        local keep = targetRank
        fresh.last = current.last
        Fill(fresh)
        if keep and keep ~= fresh.rankIndex then targetRank = keep; UpdateRankButton() end
    else
        panel:Hide()   -- nicht mehr in der Gilde
    end
end)

page:HookScript("OnHide", function() if not InCombatLockdown() then panel:Hide() end end)
