# GuildPride Changelog

## 1.6.2

**English**
- Community chat in the GuildPride window now also shows new messages in battlegrounds and instances (protected messages are shown for the current session)
- Event sign-ups and poll votes are also whispered directly to the creator, so the guild master sees sign-ups from every rank

**Deutsch**
- Der Community-Chat im GuildPride-Fenster zeigt neue Nachrichten jetzt auch in Schlachtfeldern und Instanzen (geschützte Nachrichten werden für die laufende Sitzung angezeigt)
- Event-Anmeldungen und Umfrage-Stimmen gehen zusätzlich per Flüstern direkt an den Ersteller, damit der Gildenmeister Anmeldungen aller Ränge sieht

## 1.6.1

**English**
- Removed the guild logo in chat (`/gp icon`). Its chat filter could hide messages from players without GuildPride in channels, say, yell, guild chat and battlegrounds. GuildPride no longer touches the normal chat at all

**Deutsch**
- Gilden-Logo im Chat (`/gp icon`) entfernt. Sein Chat-Filter konnte Nachrichten von Spielern ohne GuildPride in Channels, Sagen, Schreien, Gildenchat und Schlachtfeldern verschwinden lassen. GuildPride fasst den normalen Chat jetzt gar nicht mehr an

## 1.6.0

**English**
- New "Polls" tab: officers create polls with up to 6 answers, everyone votes, results with names are synced across the guild. Optional duration (1 day, 3 days, 1 week, 2 weeks); the poll closes on its own and shows the time left. Only officers can create, close and delete polls
- Events: lineup check (tanks, healers, DPS for a group or raid) and "Invite all attendees" for officers – converts to a raid automatically when needed
- More milestones: personal achievements, first raid boss kills per difficulty, new M+ best (+10 and up, in time) and new mounts. Can be turned off in the settings
- Recruiting text: save it in the settings and put it into the chat input with one click or `/gp recruit` – you send it yourself
- Note templates (one per line, `{datum}` = today): set community notes directly from the right-click menu; for guild notes the template is shown ready to copy and Blizzard's window opens
- GuildPride now also has its own page in the WoW options (Options → AddOns), `/gp options` opens it
- Guild info: new "Copy text" button, the hint line below the text was removed
- Chat: messages from former members now show "Former member" instead of "Unknown"

**Deutsch**
- Neuer Reiter „Umfragen“: Offiziere legen Umfragen mit bis zu 6 Antworten an, alle stimmen ab, Ergebnisse mit Namen werden in der Gilde abgeglichen. Wahlweise mit Laufzeit (1 Tag, 3 Tage, 1 Woche, 2 Wochen); die Umfrage endet dann von selbst und zeigt die Restzeit. Anlegen, beenden und löschen dürfen nur Offiziere
- Events: Aufstellungs-Check (Tanks, Heiler, DD für Gruppe oder Schlachtzug) und „Alle Zugesagten einladen“ für Offiziere – wandelt bei Bedarf automatisch in einen Schlachtzug um
- Mehr Meilensteine: persönliche Erfolge, erster Raidboss-Sieg je Schwierigkeit, neue M+-Bestleistung (ab +10, in der Zeit) und neue Reittiere. In den Einstellungen abschaltbar
- Werbetext: in den Einstellungen speichern und per Klick oder `/gp werben` in die Chat-Eingabe legen – abschicken tust du selbst
- Notiz-Vorlagen (eine pro Zeile, `{datum}` = heute): Community-Notizen direkt aus dem Rechtsklick-Menü setzen; bei Gildennotizen wird die Vorlage zum Kopieren gezeigt und das Blizzard-Fenster geöffnet
- GuildPride hat jetzt auch eine eigene Seite in den WoW-Optionen (Optionen → AddOns), `/gp optionen` öffnet sie
- Gildeninfo: neuer Knopf „Text kopieren“, der Hinweistext unter dem Text ist entfernt
- Chat: Nachrichten ehemaliger Mitglieder zeigen jetzt „Ehemaliges Mitglied“ statt „Unbekannt“

## 1.5.4

**English**
- `/gp testall` now always shows the test pop-up for everyone with GuildPride (including yourself) and no longer ends up in the milestone history
- Updated descriptions and README

**Deutsch**
- `/gp testall` zeigt das Test-Popup jetzt immer bei allen mit GuildPride an (auch bei dir selbst) und landet nicht mehr im Meilenstein-Verlauf
- Beschreibungen und README aktualisiert

## 1.5.3

**English**
- Members of all ranks are shown again in the Group Finder and at events: messages are always sent to the guild directly first; relaying only kicks in if that fails. The relay no longer depends on rank permissions that only the guild leadership can read
- Group Finder: entries no longer flip between "Looking for group" and "Needs quest help". Every entry carries a version number, older states are ignored, and there is at most one chat notice per player per minute
- New: `/gp ping` asks everyone with GuildPride to reply (version, rank, may write), `/gp status` shows your own sending state

**Deutsch**
- Mitglieder aller Ränge erscheinen wieder in Gruppensuche und bei Events: Nachrichten gehen immer zuerst direkt an die Gilde, die Weiterleitung springt nur ein, wenn das scheitert. Sie hängt nicht mehr an Rangrechten, die nur die Gildenleitung lesen kann
- Gruppensuche: Einträge springen nicht mehr zwischen „Sucht Gruppe“ und „Braucht Quest-Hilfe“ hin und her. Jeder Eintrag hat eine Versionsnummer, ältere Stände werden ignoriert, und pro Spieler kommt höchstens ein Chat-Hinweis pro Minute
- Neu: `/gp ping` bittet alle mit GuildPride um eine Antwort (Version, Rang, darf schreiben), `/gp status` zeigt den eigenen Sendestand

## 1.5.2

**English**
- The "Rules" tab is now "Guild Info": it shows the guild info text from Blizzard's guild window, so everyone sees the same text, even without GuildPride. Blizzard blocks addons from changing it, so whoever may change it gets "Edit in Blizzard's window"; the tab updates right after the change. When it changes, the tab is shown first the next time you open the window
- Chat: names of older messages are looked up (own messages, guild roster, member list, character) instead of showing "Unknown", and duplicate copies without a name are removed. Guild and officer chat are also recorded while the window is closed, so the history keeps growing
- Dungeons, PvP, raids and M+: the normal chat no longer loses messages. During Blizzard's chat lockdown GuildPride does not touch chat lines at all (no guild logo there) and holds back its own addon messages until the lockdown ends
- English client: dates in the overview, milestones and event messages now use the English format (31 Oct instead of 31.10.)

**Deutsch**
- Der Reiter „Regeln“ heißt jetzt „Gildeninfo“: Er zeigt den Info-Text aus dem Blizzard-Gildenfenster, alle sehen also denselben Text, auch ohne GuildPride. Blizzard sperrt das Ändern für Addons, deshalb bekommt, wer ihn ändern darf, „Im Blizzard-Fenster bearbeiten“; der Reiter zeigt die Änderung sofort danach. Ändert er sich, wird der Reiter beim nächsten Öffnen zuerst gezeigt
- Chat: Namen älterer Nachrichten werden nachgeschlagen (eigene Nachrichten, Gildenliste, Mitgliederliste, Charakter), statt „Unbekannt“ anzuzeigen, und doppelte Kopien ohne Namen werden entfernt. Gilden- und Offizierschat werden auch bei geschlossenem Fenster mitgeschrieben, der Verlauf wächst also weiter
- Dungeons, PvP, Schlachtzüge und M+: Im normalen Chat gehen keine Nachrichten mehr verloren. Während Blizzards Chat-Sperre fasst GuildPride Chatzeilen gar nicht an (dort kein Gildenlogo) und hält eigene Addon-Nachrichten zurück, bis die Sperre vorbei ist
- Englischer Client: Datumsangaben in Übersicht, Meilensteinen und Event-Meldungen im englischen Format (31 Oct statt 31.10.)

## 1.5.1

**English**
- Sync fixed in all windows: messages longer than WoW's limit of 255 bytes (e.g. events with description and officer note) never arrived. They are now split into parts and put back together automatically
- Events and rules are also requested when you open their tab, not only at login
- Community and guild chat: the history no longer disappears. All loaded parts of the history are shown, and the last 150 messages per channel are also kept locally
- All ranks can now take part: members whose rank may not write in guild chat could not send anything (event sign-ups, Group Finder, milestones). Their messages are now passed on to the guild by another GuildPride user. Members who may not read guild chat get the data by whisper when they open a tab

**Deutsch**
- Abgleich in allen Fenstern repariert: Nachrichten über WoWs Grenze von 255 Byte (z. B. Events mit Beschreibung und Offiziers-Notiz) kamen nie an. Sie werden jetzt automatisch in Teile zerlegt und wieder zusammengesetzt
- Events und Regeln werden zusätzlich beim Öffnen ihres Reiters abgefragt, nicht nur beim Login
- Community- und Gildenchat: der Verlauf verschwindet nicht mehr. Alle geladenen Teile des Verlaufs werden angezeigt, und die letzten 150 Nachrichten je Kanal werden zusätzlich lokal gespeichert
- Alle Ränge können mitmachen: Mitglieder, deren Rang im Gildenchat nicht schreiben darf, konnten nichts senden (Event-Anmeldungen, Gruppensuche, Meilensteine). Ihre Nachrichten gibt jetzt ein anderer GuildPride-Nutzer an die Gilde weiter. Wer den Gildenchat nicht lesen darf, bekommt die Daten per Flüstern, sobald er einen Reiter öffnet

## 1.5.0

**English**
- Guild management: click a guild member to open details with public and officer note, then promote, demote, set any rank, remove from the guild or transfer guild leadership (depending on your rights)
- These actions use Blizzard's commands /gpromote, /gdemote, /gremove and /gleader, because Blizzard blocks addons from doing them directly. Removing and transferring leadership need a second click to confirm
- Guild notes can't be changed by addons; the "Edit notes" button opens Blizzard's guild window
- Community management (right-click a member): change role, edit note, remove from the community
- Right-click menu for everyone: whisper, invite to group, add friend, invite to guild or community, put name in chat
- Notes are shown in the member list
- Milestones are now synced: on login and when you open the Milestones tab, missed entries are fetched from other guild members. Level-ups are also detected from the guild roster, so they show up for members without GuildPride too. Joins and leaves are synced the same way
- New event: date and time now have separate fields, prefilled with today (or tomorrow) at 20:00. Many formats work (24.12., 24.12.2026, 20, 20:00, 20.00, 20 Uhr); without a year the next matching date is used, and impossible dates like 31.02. are rejected
- Group Finder: instead of "Whisper" the button now sends a join request to the player's group ("Join"), or invites a solo player looking for a group into yours ("Invite"). It shows "In group" or "Full" when that applies. Right-click still whispers

**Deutsch**
- Gildenverwaltung: Klick auf ein Gildenmitglied öffnet Details mit öffentlicher Notiz und Offiziersnotiz, dort befördern, degradieren, beliebigen Rang setzen, aus der Gilde entfernen oder Gildenleitung übergeben (je nach deinen Rechten)
- Diese Aktionen nutzen die Blizzard-Befehle /gpromote, /gdemote, /gremove und /gleader, weil Blizzard sie für Addons direkt sperrt. Entfernen und Gildenleitung übergeben brauchen einen zweiten Klick zur Bestätigung
- Gildennotizen kann kein Addon ändern; der Knopf „Notizen bearbeiten“ öffnet das Blizzard-Gildenfenster
- Community-Verwaltung (Rechtsklick auf ein Mitglied): Rolle ändern, Notiz bearbeiten, aus der Community entfernen
- Rechtsklick-Menü für alle: anflüstern, in Gruppe einladen, als Freund hinzufügen, in Gilde oder Community einladen, Namen in den Chat einfügen
- Notizen werden in der Mitgliederliste angezeigt
- Meilensteine werden jetzt abgeglichen: beim Login und beim Öffnen des Reiters Meilensteine kommen verpasste Einträge von anderen Gildenmitgliedern. Level-Aufstiege werden zusätzlich aus der Gildenliste erkannt, also auch bei Mitgliedern ohne GuildPride. Beitritte und Austritte werden genauso abgeglichen
- Neues Event: Datum und Uhrzeit haben jetzt getrennte Felder, vorausgefüllt mit heute (oder morgen) um 20:00. Viele Schreibweisen gehen (24.12., 24.12.2026, 20, 20:00, 20.00, 20 Uhr); ohne Jahr gilt der nächste passende Termin, unmögliche Daten wie 31.02. werden abgelehnt
- Gruppensuche: statt „Anflüstern“ schickt der Knopf jetzt eine Beitrittsanfrage an die Gruppe des Spielers („Beitreten“) oder lädt einen Spieler, der allein eine Gruppe sucht, in deine Gruppe ein („Einladen“). Er zeigt „In Gruppe“ oder „Voll“, wenn das zutrifft. Rechtsklick flüstert weiterhin an

## 1.4.0

**English**
- Members: switch between your guild and any of your communities and see their members (online or everyone, with role, zone and "last online")
- Invite players: type a name at the bottom of the Members tab to invite them to the guild or the selected community, or use `/gp invite Name`
- Right-click a member: whisper, invite to guild, or invite to one of your communities
- Group Finder: your own listing now shows up in the list, listings are refreshed regularly and the list is requested when you open the tab
- Messages that the server throttled are now sent again instead of being lost (affected group finder, events and rules)
- Removed: BattleTags in officer notes

**Deutsch**
- Mitglieder: zwischen Gilde und jeder deiner Communities wechseln und deren Mitglieder sehen (online oder alle, mit Rolle, Zone und „zuletzt online“)
- Spieler einladen: unten im Reiter Mitglieder einen Namen eingeben und in die Gilde oder die gewählte Community einladen, oder `/gp einladen Name`
- Rechtsklick auf ein Mitglied: anflüstern, in die Gilde einladen oder in eine deiner Communities einladen
- Gruppensuche: der eigene Eintrag erscheint jetzt in der Liste, Einträge werden regelmäßig erneuert und beim Öffnen des Reiters neu abgefragt
- Nachrichten, die der Server gedrosselt hat, werden jetzt erneut gesendet statt verloren zu gehen (betraf Gruppensuche, Events und Regeln)
- Entfernt: BattleTags in der Offiziersnotiz

## 1.3.0

**English**
- Own guild window with sidebar: overview, members, milestones, events, rules, group search and chat
- Milestone pop-ups with badges when guild members reach a new level, guild logo in chat
- Event planner with sign-up and roles, synchronized between all guild members with GuildPride
- Guild rules maintained by officers and shared with everyone
- Group search and quest help: see who is looking and which roles are still missing
- Guild chat, officer chat and your communities right in the guild window
- Notice when a member joins or leaves the guild
- BattleTags of new members go into the officer note after confirmation (officers only)
- Version check: shows when a newer GuildPride version is available in the guild
- English and German

**Deutsch**
- Eigenes Gildenfenster mit Seitenleiste: Übersicht, Mitglieder, Meilensteine, Events, Regeln, Gruppensuche und Chat
- Meilenstein-Einblendungen mit Abzeichen, wenn Gildenmitglieder ein neues Level erreichen, Gilden-Logo im Chat
- Event-Planer mit Anmeldung und Rollen, synchronisiert zwischen allen Gildenmitgliedern mit GuildPride
- Gildenregeln, von Offizieren gepflegt und an alle verteilt
- Gruppensuche und Quest-Hilfe: sehen, wer sucht und welche Rollen noch fehlen
- Gildenchat, Offizierschat und eigene Communities direkt im Gildenfenster
- Hinweis, wenn ein Mitglied der Gilde beitritt oder sie verlässt
- BattleTags neuer Mitglieder kommen nach Bestätigung in die Offiziersnotiz (nur Offiziere)
- Versionscheck: zeigt an, wenn in der Gilde eine neuere GuildPride-Version unterwegs ist
- Deutsch und Englisch
