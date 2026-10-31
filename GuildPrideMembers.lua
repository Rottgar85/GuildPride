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
local function ShowToast(kind, name)
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

    -- Im Verlauf (Reiter Meilensteine) festhalten
    ns.AddLog(kind == "join" and "JOIN" or (kind == "kick" and "KICK" or "LEAVE"), short)
    if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
end

---------------------------------------------------------------------
-- Systemnachrichten auswerten
---------------------------------------------------------------------
---------------------------------------------------------------------
-- Automatische Begrüßung (Einstellung). Jeder mit GuildPride wartet zufällig
-- 2–8 s; wer zuerst begrüßt, meldet das ("WEL"), die anderen schweigen.
---------------------------------------------------------------------
ns.WELCOME_DEFAULT = L["Willkommen in der Gilde, {name}!"]
local welcomed = {}   -- [Name] = Zeit, zu der jemand begrüßt hat

ns.On("WEL", function(payload)
    if payload and payload ~= "" then welcomed[Ambiguate(payload, "none")] = GetTime() end
end)

-- Chat-Sperre (Midnight, z. B. in Instanzen): dann nicht senden
local function Locked()
    return C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown()
end

local function Welcome(name)
    if not GuildPrideDB.welcome then return end
    local short = Ambiguate(name, "none")
    C_Timer.After(2 + math.random() * 6, function()
        if welcomed[short] and GetTime() - welcomed[short] < 60 then return end
        if Locked() or not IsInGuild() then return end
        welcomed[short] = GetTime()
        ns.Queue("WEL", nil, short)
        local text = strtrim(GuildPrideDB.welcomeText or "")
        if text == "" then text = ns.WELCOME_DEFAULT end
        local SendChat = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
        SendChat((text:gsub("{name}", Ambiguate(name, "guild"))), "GUILD")
    end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_SYSTEM")
f:SetScript("OnEvent", function(_, _, msg)
    if not GuildPrideDB then return end
    if issecretvalue and issecretvalue(msg) then return end
    if type(msg) ~= "string" then return end

    local name = JOIN and msg:match(JOIN)
    if name then
        if Ambiguate(name, "none") ~= UnitName("player") then
            Welcome(name)
            if GuildPrideDB.memberAlerts ~= false then ShowToast("join", name) end
        end
        return
    end
    if GuildPrideDB.memberAlerts == false then return end
    name = LEAVE and msg:match(LEAVE)
    if name then ShowToast("leave", name); return end
    name = KICK and msg:match(KICK)
    if name then ShowToast("kick", name) end
end)
