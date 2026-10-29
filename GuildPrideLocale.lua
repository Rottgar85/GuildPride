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
    ["Befehle: /gp (Fenster) · sound · icon · popup · blizzard · kuerzel <XYZ> · badge <Level> · version · battletag · btags · test · testall"] = "Commands: /gp (window) · sound · icon · popup · blizzard · tag <XYZ> · badge <level> · version · battletag · btags · test · testall",
    ["Neuer BattleTag zur Bestätigung: |cffffd100%s|r (%d offen)"] = "New BattleTag awaiting confirmation: |cffffd100%s|r (%d pending)",
    ["Offiziersnotiz von |cffffd100%s|r ist zu voll. Bitte von Hand eintragen: %s"] = "|cffffd100%s|r's officer note is too full. Please add it manually: %s",
    ["BattleTag von |cffffd100%s|r übernommen."] = "Saved |cffffd100%s|r's BattleTag.",
    ["|cffff4040Offiziersnotiz konnte nicht geändert werden.|r"] = "|cffff4040Could not change the officer note.|r",
    ["BattleTag von %s abgelehnt."] = "Declined %s's BattleTag.",
    ["|cffff8c40Neuer BattleTag|r\n\n|cffffd100%s|r möchte seinen BattleTag in die Offiziersnotiz eintragen lassen:\n\n|cffffffff%s|r"] = "|cffff8c40New BattleTag|r\n\n|cffffd100%s|r would like their BattleTag added to their officer note:\n\n|cffffffff%s|r",
    ["Übernehmen"] = "Accept",
    ["Ablehnen"] = "Decline",
    ["Später"] = "Later",
    ["|cffff8c40Offizier online|r\n\n"] = "|cffff8c40Officer online|r\n\n",
    ["|cffffd100%s|r ist jetzt online.\n\n"] = "|cffffd100%s|r is now online.\n\n",
    ["Mit |cffffffff„Jetzt senden“|r wird dein BattleTag (|cffffffff%s|r) an die Offiziere geschickt. "] = "|cffffffff\"Send now\"|r sends your BattleTag (|cffffffff%s|r) to the officers. ",
    ["Sie tragen ihn danach in deine Offiziersnotiz ein – so können sie dich auch erreichen, "] = "They will then add it to your officer note, so they can reach you ",
    ["wenn du auf einem anderen Charakter spielst. Nur Offiziere können die Notiz sehen.\n\n"] = "even when you're playing another character. Only officers can see this note.\n\n",
    ["|cff999999„Später“: Du wirst beim nächsten Offizier wieder gefragt.\n"] = "|cff999999\"Later\": You will be asked again when the next officer comes online.\n",
    ["„Nicht senden“: Du wirst nicht mehr gefragt (später mit /gp battletag möglich).|r"] = "\"Don\'t send\": You won\'t be asked again (you can still use /gp battletag later).|r",
    ["Jetzt senden"] = "Send now",
    ["Nicht senden"] = "Don't send",
    ["Okay, dein BattleTag wird nicht gesendet. Mit |cffff8c40/gp battletag|r kannst du es später nachholen."] = "Okay, your BattleTag won't be sent. You can still do it later with |cffff8c40/gp battletag|r.",
    ["Dein BattleTag wurde an die Offiziere übermittelt. Sie tragen ihn in Kürze ein."] = "Your BattleTag has been sent to the officers. They will add it shortly.",
    ["Dein BattleTag wurde in deine Offiziersnotiz eingetragen. Danke!"] = "Your BattleTag has been added to your officer note. Thank you!",
    ["Kein BattleTag gefunden (Battle.net nicht verbunden?)."] = "No BattleTag found (not connected to Battle.net?).",
    ["Gerade ist kein Offizier mit GuildPride online. Du bekommst Bescheid, sobald einer online kommt."] = "No officer with GuildPride is online right now. You'll be notified as soon as one comes online.",
    ["Willkommen in der Gilde!\n\nDarf GuildPride deinen BattleTag (%s) an die Offiziere schicken, "] = "Welcome to the guild!\n\nMay GuildPride send your BattleTag (%s) to the officers ",
    ["damit sie ihn in deine Offiziersnotiz eintragen? Nur Offiziere können ihn sehen."] = "so they can add it to your officer note? Only officers can see it.",
    ["Nur Offiziere können BattleTags bestätigen."] = "Only officers can confirm BattleTags.",
    ["Keine BattleTags offen."] = "No pending BattleTags.",
    ["%s ist nicht mehr in der Gilde – Eintrag verworfen."] = "%s is no longer in the guild – entry discarded.",
    ["%s Offizier %s ist online – du kannst deinen BattleTag jetzt senden."] = "%s Officer %s is online – you can send your BattleTag now.",
    ["%d BattleTag(s) warten auf Bestätigung – |cffff8c40/gp btags|r"] = "%d BattleTag(s) awaiting confirmation – |cffff8c40/gp btags|r",
    [" – |cffff8c40/gp btags|r"] = " – |cffff8c40/gp btags|r",
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
    ["BattleTags neuer Mitglieder in Offiziersnotiz eintragen (nur Offiziere)"] = "Add new members' BattleTags to officer notes (officers only)",
    ["Blizzard-Gildenfenster öffnen"] = "Open Blizzard's guild window",
    ["|cffff4040Im Kampf kann das Gildenfenster nicht geöffnet werden.|r"] = "|cffff4040The guild window can't be opened in combat.|r",
    ["Neue GuildPride-Version verfügbar: |cff40ff40%s|r (du hast %s). Bitte aktualisieren!"] = "A new GuildPride version is available: |cff40ff40%s|r (you have %s). Please update!",
    ["Deine Version: "] = "Your version: ",
    ["  Noch keine anderen Versionen empfangen."] = "  No other versions received yet.",
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
