# GuildPride Changelog

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
