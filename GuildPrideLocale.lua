-- GuildPride: Übersetzungen
-- Deutsch ist die Grundsprache (Schlüssel = deutscher Text).
-- Auf allen nicht-deutschen Clients wird automatisch Englisch verwendet.
local ADDON, ns = ...

local LOCALE = GetLocale()
ns.LOCALE = LOCALE
ns.IS_GERMAN = (LOCALE == "deDE")

local enUS = {
    ["Alle (inkl. offline)"] = "All (incl. offline)",
    ["offline"] = "offline",
    ["%d online · %d offline"] = "%d online · %d offline",
    ["vor %d Jahr(en)"] = "%d year(s) ago",
    ["vor %d Monat(en)"] = "%d month(s) ago",
    ["vor %d Tag(en)"] = "%d day(s) ago",
    ["vor %d Std."] = "%d hr ago",
    ["vor < 1 Std."] = "< 1 hr ago",
    ["Sucht Mitspieler"] = "Looking for members",
    ["Fehlt noch:"] = "Still needed:",
    ["Gruppe %d/%d"] = "Group %d/%d",
    ["Allein"] = "Solo",
    ["Sucht noch: %s"] = "Needs: %s",
    ["vor %d Min."] = "%d min ago",
    ["gerade eben"] = "just now",
    ["Notiz (optional), Rollen wählen, dann eintragen. Die Gruppengröße wird automatisch übernommen."] = "Add a note (optional), pick the roles you still need, then sign up. Your group size is added automatically.",
    ["DD"] = "DPS",
    ["hat Level %s erreicht!"] = "reached level %s!",
    ["hat einen Meilenstein erreicht (%s %s)"] = "reached a milestone (%s %s)",
    ["geladen. /gp für Befehle"] = "loaded. Type /gp for commands",
    ["Eigenes Gildenfenster: "] = "Custom guild window: ",
    ["Gildenkürzel: "] = "Guild tag: ",
    ["automatisch"] = "automatic",
    ["Befehle: /gp (Fenster) · sound · icon · popup · blizzard · kuerzel <XYZ> · einladen <Name> · badge <Level> · version · test · testall"] = "Commands: /gp (window) · sound · icon · popup · blizzard · tag <XYZ> · invite <name> · badge <level> · version · test · testall",
    ["Gildenchat"] = "Guild Chat",
    ["Gilde"] = "Guild",
    ["Offiziere"] = "Officers",
    ["Senden"] = "Send",
    ["Kanal: |cfff0c88c"] = "Channel: |cfff0c88c",
    ["|cff888888Chat wird geladen …|r"] = "|cff888888Loading chat …|r",
    ["|cff888888Noch keine Nachrichten.|r"] = "|cff888888No messages yet.|r",
    ["Allgemein"] = "General",
    ["Du bist in keiner Blizzard-Community."] = "You're not in any Blizzard community.",
    ["|cffff4040Nachricht konnte nicht gesendet werden:|r "] = "|cffff4040Message could not be sent:|r ",
    ["Heiler"] = "Healer",
    ["Zugesagt"] = "Attending",
    ["Vielleicht"] = "Maybe",
    ["Abgesagt"] = "Declined",
    ["Neues Gildenevent: |cffffd100%s|r am %s"] = "New guild event: |cffffd100%s|r on %s",
    ["Keine anstehenden Events."] = "No upcoming events.",
    ["Zusagen"] = "Attend",
    ["Absagen"] = "Decline",
    ["Löschen"] = "Delete",
    ["Neues Event"] = "New Event",
    ["Meine Rolle:"] = "My role:",
    ["Notiz bearbeiten"] = "Edit note",
    ["Offiziers-Notiz (z. B. Treffpunkt, benötigte Rollen):"] = "Officer note (e.g. meeting point, roles needed):",
    ["Speichern"] = "Save",
    ["Event \"%s\" wirklich löschen?"] = "Really delete event \"%s\"?",
    ["|cff888888Keine Beschreibung.|r"] = "|cff888888No description.|r",
    ["\n|cffff7d0aOffiziers-Notiz:|r "] = "\n|cffff7d0aOfficer note:|r ",
    ["Zusagen nach Rolle: %sTanks %d|r · %sHeiler %d|r · %sDD %d|r"] = "Attending by role: %sTanks %d|r · %sHealers %d|r · %sDPS %d|r",
    ["%s · erstellt von %s"] = "%s · created by %s",
    ["%s %s beginnt in %d Min.!"] = "%s %s starts in %d min!",
    ["Neues Gildenevent"] = "New Guild Event",
    ["Titel"] = "Title",
    ["Datum & Uhrzeit (z. B. 24.12. 20:00)"] = "Date & time as DD.MM. HH:MM (e.g. 24.12. 20:00)",
    ["Beschreibung (optional)"] = "Description (optional)",
    ["Erstellen"] = "Create",
    ["Bitte einen Titel eingeben."] = "Please enter a title.",
    ["Datum bitte als TT.MM. HH:MM eingeben."] = "Please enter the date as DD.MM. HH:MM.",
    ["Der Termin liegt in der Vergangenheit."] = "That date is in the past.",
    ["Nur Offiziere können Events erstellen."] = "Only officers can create events.",
    ["Sucht Gruppe"] = "Looking for group",
    ["Braucht Quest-Hilfe"] = "Needs quest help",
    ["Gruppensuche"] = "Group Finder",
    ["Du bist eingetragen: "] = "You are listed: ",
    ["Du bist ausgetragen."] = "You are no longer listed.",
    ["Quest-Hilfe"] = "Quest help",
    ["Austragen"] = "Remove me",
    ["Anflüstern"] = "Whisper",
    ["Gerade sucht niemand Hilfe."] = "Nobody is looking for help right now.",
    ["Dein Status: %s%s|r"] = "Your status: %s%s|r",
    ["|cff888888Du bist nicht eingetragen.|r"] = "|cff888888You're not listed.|r",
    ["|cff40ff40Neues Gildenmitglied!|r"] = "|cff40ff40New guild member!|r",
    ["|cffffd100%s|r ist der Gilde beigetreten.\nSag Hallo!"] = "|cffffd100%s|r has joined the guild.\nSay hello!",
    ["|cffff4040Mitglied hat die Gilde verlassen|r"] = "|cffff4040A member has left the guild|r",
    ["wurde aus der Gilde entfernt."] = "was removed from the guild.",
    ["hat die Gilde verlassen."] = "has left the guild.",
    ["ist der Gilde beigetreten"] = "joined the guild",
    ["hat die Gilde verlassen"] = "left the guild",
    ["Testspieler"] = "TestPlayer",
    ["hat Level %d erreicht!"] = "reached level %d!",
    ["MEILENSTEIN ERREICHT"] = "MILESTONE REACHED",
    ["Regeln"] = "Rules",
    ["Bearbeiten"] = "Edit",
    ["|cff888888Es wurden noch keine Regeln festgelegt.|r"] = "|cff888888No rules have been set yet.|r",
    ["Stand: "] = "Last updated: ",
    ["Abbrechen"] = "Cancel",
    ["Die Gildenregeln wurden aktualisiert. Schau im Gildenfenster unter \"Regeln\" nach."] = "The guild rules have been updated. Check the \"Rules\" tab in the guild window.",
    ["Regeln gespeichert und an die Gilde gesendet."] = "Rules saved and sent to the guild.",
    ["Keine Gilde"] = "No guild",
    ["Übersicht"] = "Overview",
    ["Nachricht des Tages"] = "Message of the Day",
    ["Letzte Meilensteine"] = "Recent Milestones",
    ["|cff888888Keine Nachricht gesetzt.|r"] = "|cff888888No message set.|r",
    ["|cff888888Noch keine Meilensteine.|r"] = "|cff888888No milestones yet.|r",
    ["%s%d|r Mitglieder  ·  |cff40ff40%d|r online"] = "%s%d|r members  ·  |cff40ff40%d|r online",
    ["MITGLIEDER ONLINE"] = "MEMBERS ONLINE",
    ["NÄCHSTES EVENT"] = "NEXT EVENT",
    ["NÄCHSTES EVENT: "] = "NEXT EVENT: ",
    ["MEILENSTEINE DIESE WOCHE"] = "MILESTONES THIS WEEK",
    ["Mitglieder"] = "Members",
    ["Nur online"] = "Online only",
    ["Meilensteine"] = "Milestones",
    ["Einstellungen"] = "Settings",
    ["Dieses Fenster statt Blizzard-Gildenfenster (J)"] = "Use this window instead of Blizzard's guild window (J)",
    ["Meilenstein-Popups anzeigen"] = "Show milestone pop-ups",
    ["Sounds abspielen"] = "Play sounds",
    ["Gilden-Logo im Chat"] = "Guild logo in chat",
    ["Warnung bei Beitritt / Austritt"] = "Alert when members join / leave",
    ["Hinweis, wenn jemand Gruppe / Quest-Hilfe sucht"] = "Notify me when someone needs a group / quest help",
    ["Blizzard-Gildenfenster öffnen"] = "Open Blizzard's guild window",
    ["|cffff4040Im Kampf kann das Gildenfenster nicht geöffnet werden.|r"] = "|cffff4040The guild window can't be opened in combat.|r",
    ["Neue GuildPride-Version verfügbar: |cff40ff40%s|r (du hast %s). Bitte aktualisieren!"] = "A new GuildPride version is available: |cff40ff40%s|r (you have %s). Please update!",
    ["Deine Version: "] = "Your version: ",
    ["  Noch keine anderen Versionen empfangen."] = "  No other versions received yet.",
    ["du"] = "you",
    ["Dein Eintrag in der Gruppensuche ist abgelaufen."] = "Your Group Finder listing has expired.",
    ["Besitzer"] = "Owner",
    ["Leiter"] = "Leader",
    ["Moderator"] = "Moderator",
    ["Mitglied"] = "Member",
    ["Battle.net-App"] = "Battle.net app",
    ["Name-Realm"] = "Name-Realm",
    ["In Gilde einladen"] = "Invite to guild",
    ["In Community einladen"] = "Invite to community",
    ["Bitte einen Charakternamen eingeben."] = "Please enter a character name.",
    ["Du bist in keiner Gilde."] = "You're not in a guild.",
    ["|cffff4040Du darfst keine Spieler in die Gilde einladen.|r"] = "|cffff4040You're not allowed to invite players to the guild.|r",
    ["Gildeneinladung an |cffffd100%s|r gesendet."] = "Guild invite sent to |cffffd100%s|r.",
    ["Battle.net-Communities: Einladungen bitte über das Blizzard-Community-Fenster verschicken."] = "Battle.net communities: please send invites from Blizzard's community window.",
    ["|cffff4040Du darfst in „%s“ niemanden einladen.|r"] = "|cffff4040You're not allowed to invite anyone to \"%s\".|r",
    ["Einladung in „%s“ an |cffffd100%s|r gesendet."] = "Invite to \"%s\" sent to |cffffd100%s|r.",
    ["|cffff4040Einladung konnte nicht gesendet werden.|r"] = "|cffff4040The invite could not be sent.|r",
    ["an"] = "on",
    ["aus"] = "off",
}

-- Fehlende Übersetzung -> deutscher Text als Rückfall
ns.L = setmetatable({}, { __index = function(_, key)
    if not ns.IS_GERMAN and enUS[key] then return enUS[key] end
    return key
end })

---------------------------------------------------------------------
-- Datumsangaben (Lua-date() kennt nur englische Wochentage)
---------------------------------------------------------------------
local DAYS_DE   = { "Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag" }
local DAYS_DE_S = { "So", "Mo", "Di", "Mi", "Do", "Fr", "Sa" }
local MONTHS_EN = { "January", "February", "March", "April", "May", "June", "July",
                    "August", "September", "October", "November", "December" }

-- style: "short" -> "Fr 31.10. 20:00" / "Fri 31 Oct 20:00"
--        "long"  -> "Freitag, 31.10.2026 um 20:00 Uhr" / "Friday, 31 October 2026 at 20:00"
function ns.FormatDate(t, style)
    local d = date("*t", t)
    if ns.IS_GERMAN then
        if style == "long" then
            return ("%s, %02d.%02d.%d um %02d:%02d Uhr"):format(DAYS_DE[d.wday], d.day, d.month, d.year, d.hour, d.min)
        end
        return ("%s %02d.%02d. %02d:%02d"):format(DAYS_DE_S[d.wday], d.day, d.month, d.hour, d.min)
    end
    if style == "long" then
        return date("%A", t) .. (", %d %s %d at %02d:%02d"):format(d.day, MONTHS_EN[d.month], d.year, d.hour, d.min)
    end
    return date("%a", t) .. (" %d %s %02d:%02d"):format(d.day, MONTHS_EN[d.month]:sub(1, 3), d.hour, d.min)
end
