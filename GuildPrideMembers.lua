-- GuildPride: Warnung bei Beitritt / Austritt (nur Info, begrüßt wird von Hand)
local ADDON, ns = ...
local L = ns.L

-- Blizzard-Systemtexte (sprachunabhängig) in Lua-Muster umwandeln
local function ToPattern(fmt)
    if not fmt then return nil end
    local p = fmt:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    p = p:gsub("%%%%%d%%%$s", "(.+)")   -- %1$s
    p = p:gsub("%%%%s", "(.+)")         -- %s
    return "^" .. p .. "$"
end

local JOIN  = ToPattern(ERR_GUILD_JOIN_S)
local LEAVE = ToPattern(ERR_GUILD_LEAVE_S)
local KICK  = ToPattern(ERR_GUILD_REMOVE_SS)


---------------------------------------------------------------------
-- Hinweisfenster oben am Bildschirm
---------------------------------------------------------------------
local toast = CreateFrame("Frame", "GuildPrideMemberToast", UIParent, "BackdropTemplate")
toast:SetSize(420, 96)
toast:SetPoint("TOP", 0, -140)
toast:SetFrameStrata("DIALOG")
toast:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
    tile = true, tileSize = 32, edgeSize = 24,
    insets = { left = 6, right = 6, top = 6, bottom = 6 },
})
toast:Hide()

local icon = toast:CreateTexture(nil, "ARTWORK")
icon:SetSize(48, 48)
icon:SetPoint("LEFT", 16, 6)

local headline = toast:CreateFontString(nil, "OVERLAY", "GPFont_Large")
headline:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -2)

local line = toast:CreateFontString(nil, "OVERLAY", "GPFont_Text")
line:SetPoint("TOPLEFT", headline, "BOTTOMLEFT", 0, -6)
line:SetWidth(320); line:SetJustifyH("LEFT")

local dismiss = CreateFrame("Button", nil, toast, "UIPanelCloseButton")
dismiss:SetPoint("TOPRIGHT", -2, -2)
dismiss:SetScript("OnClick", function() toast:Hide() end)

local hideTimer
local function ShowToast(kind, name, test)
    local short = Ambiguate(name, "guild")
    if kind == "join" then
        headline:SetText(L["|cff40ff40Neues Gildenmitglied!|r"])
        line:SetText((L["|cffffd100%s|r ist der Gilde beigetreten.\nSag Hallo!"]):format(short))
        icon:SetTexture("Interface\\AddOns\\GuildPride\\Media\\logo")
    else
        headline:SetText(L["|cffff4040Mitglied hat die Gilde verlassen|r"])
        line:SetText(("|cffffd100%s|r %s"):format(short, kind == "kick" and L["wurde aus der Gilde entfernt."] or L["hat die Gilde verlassen."]))
        icon:SetTexture("Interface\\Icons\\Ability_Rogue_FeignDeath")
    end
    toast:Show()
    if GuildPrideDB.sound then
        PlaySound(kind == "join" and SOUNDKIT.READY_CHECK or SOUNDKIT.RAID_WARNING)
    end
    if hideTimer then hideTimer:Cancel() end
    hideTimer = C_Timer.NewTimer(kind == "join" and 30 or 12, function() toast:Hide() end)

    -- Im Verlauf (Reiter Meilensteine) festhalten; Testspieler nicht
    if not test then
        ns.AddLog(kind == "join" and "JOIN" or (kind == "kick" and "KICK" or "LEAVE"), short)
    end
    if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
end

---------------------------------------------------------------------
-- Systemnachrichten auswerten
---------------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_SYSTEM")
f:SetScript("OnEvent", function(_, _, msg)
    if not GuildPrideDB or GuildPrideDB.memberAlerts == false then return end
    if issecretvalue and issecretvalue(msg) then return end
    if type(msg) ~= "string" then return end

    local name = JOIN and msg:match(JOIN)
    if name then
        if Ambiguate(name, "none") ~= UnitName("player") then ShowToast("join", name) end
        return
    end
    name = LEAVE and msg:match(LEAVE)
    if name then ShowToast("leave", name); return end
    name = KICK and msg:match(KICK)
    if name then ShowToast("kick", name) end
end)

---------------------------------------------------------------------
-- Testbefehle: /gp testjoin, /gp testleave
---------------------------------------------------------------------
local orig = SlashCmdList.GUILDPRIDE
SlashCmdList.GUILDPRIDE = function(arg)
    local cmd = (arg or ""):match("^(%S*)")
    if cmd:lower() == "testjoin" then
        ShowToast("join", L["Testspieler"], true)
    elseif cmd:lower() == "testleave" then
        ShowToast("leave", L["Testspieler"], true)
    else
        orig(arg)
    end
end
