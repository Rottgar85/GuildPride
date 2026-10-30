# GuildPride

**Your guild, front and center.** GuildPride replaces the default guild window with a fully styled guild hub: milestones, events, guild info, a group finder, guild chat and member management in one place. Works for any guild – the window automatically shows *your* guild name, tag and tabard.

*Deutsche Beschreibung weiter unten.*

---

## 🇬🇧 English

### Features

- **New guild window** – opens with **J** or the guild button in the micro menu. Your guild name at the top, your guild tag and tabard on the left. Prefer Blizzard's window? `/gp blizzard` switches back. The window can't be opened in combat.
- **Milestones with badges** – when a member reaches level 10, 20, 30 … 90, every guildmate with GuildPride sees an animated pop-up with a badge for that level. Milestones you missed while offline are fetched from other members when you log in.
- **Join / leave alerts** – a clear on-screen notice when someone joins, leaves or is removed from the guild. Greeting stays personal – you type "hello" yourself.
- **Event planner** – officers create events with a title, date and time (separate fields), description and an officer note (e.g. meeting point). Members of every rank sign up as *Attending / Maybe / Declined* and pick their role (Tank / Healer / DPS). Reminder 15 minutes before the start.
- **Group finder & quest help** – sign up as *Looking for group* (shown as *Looking for members* once you're in a group) or *Needs quest help*, with a note and the roles you still need. Everyone sees class, level, role, zone and how full the group is (e.g. *Group 3/5*); the group size updates automatically. One click on **Join** sends a join request to the group, or **Invite** invites a solo player. Right-click to whisper. Open to every guild rank.
- **Guild info** – shows the info text from Blizzard's guild window, the same for everyone. You get a notice when it changes. Officers edit it in Blizzard's guild window, one click away (Blizzard does not allow addons to change it).
- **Guild chat & communities** – guild chat, officer chat and all your Blizzard communities inside the window, with the server-side history. Messages are also kept locally, so old messages stay visible with the right author names.
- **Members list** – your guild or any of your communities, online only or everyone including offline, with rank, notes and "last online".
- **Invite players** – type a name to invite someone to the guild or the selected community, or right-click a member to whisper, invite to your group, add as friend or invite to the guild / a community.
- **Guild management** – click a member to see their notes and to promote, demote, set a rank, remove them or transfer leadership (depending on your rights). Uses Blizzard's own guild commands.
- **Community management** – right-click a community member to change their role, edit their note or remove them.
- **Polls** – officers create polls with up to 6 answers and an optional duration (1 day to 2 weeks), everyone votes.
- **More milestones** – achievements, first raid boss kills, new M+ bests and new mounts.
- **Event lineup** – role check for group or raid and "Invite all attendees" for officers.
- **Recruiting text and note templates**, plus a settings page in the WoW options (`/gp options`).
- **Version check** – a reminder when a newer GuildPride version is in use in your guild.
- **English & German** – switches automatically to your game client's language.

### Commands

| Command | What it does |
|---|---|
| `/gp` | open the window (`/gp help` lists all commands) |
| `/gp sound` · `/gp popup` | turn sounds or pop-ups on/off |
| `/gp blizzard` | switch between GuildPride and Blizzard's guild window |
| `/gp tag XYZ` | set your guild tag (without a tag: automatic) |
| `/gp invite Name-Realm` | invite a player to the guild |
| `/gp version` | who in the guild uses which version |
| `/gp recruit` | put your saved recruiting text into the chat input |
| `/gp options` | open the GuildPride page in the WoW options |
| `/gp badge 30` | preview a milestone pop-up |

### Good to know

- Milestones, events and the group finder sync between guild members who **have GuildPride installed**.
- Data is shared only with your guild, through addon messages. Members whose rank can't write in guild chat send through an online guildmate.
- Guild data also travels over a hidden, password-protected background channel of your guild, so syncing does not depend on guild chat rank rights.
- Blizzard blocks addon messages in instances during *chat lockdown* (e.g. Mythic+, rated PvP). GuildPride waits and sends afterwards.
- Feedback and bug reports are very welcome – please include the Lua error and your game version.

---

## 🇩🇪 Deutsch

**Deine Gilde im Mittelpunkt.** GuildPride ersetzt das normale Gildenfenster durch einen komplett gestalteten Gilden-Treffpunkt: Meilensteine, Events, Gildeninfo, Gruppensuche, Gildenchat und Mitgliederverwaltung an einem Ort. Funktioniert für jede Gilde – das Fenster zeigt automatisch *euren* Gildennamen, euer Kürzel und euren Wappenrock.

### Funktionen

- **Neues Gildenfenster** – öffnet sich mit **J** oder über den Gildenknopf in der Mikroleiste. Oben euer Gildenname, links euer Kürzel und Wappenrock. Lieber das Blizzard-Fenster? `/gp blizzard` schaltet zurück. Im Kampf lässt sich das Fenster nicht öffnen.
- **Meilensteine mit Abzeichen** – erreicht jemand Level 10, 20, 30 … 90, sehen alle mit GuildPride ein animiertes Popup mit dem Abzeichen für dieses Level. Was ihr offline verpasst habt, wird beim Einloggen von anderen Mitgliedern nachgeladen.
- **Hinweis bei Beitritt / Austritt** – eine deutliche Bildschirmmeldung, wenn jemand beitritt, die Gilde verlässt oder entfernt wird. Begrüßt wird persönlich – „Hallo“ schreibt ihr selbst.
- **Event-Planer** – Offiziere legen Events mit Titel, Datum und Uhrzeit (getrennte Felder), Beschreibung und Offiziers-Notiz (z. B. Treffpunkt) an. Mitglieder aller Ränge melden sich mit *Zusagen / Vielleicht / Absagen* an und wählen ihre Rolle (Tank / Heiler / DD). Erinnerung 15 Minuten vor Beginn.
- **Gruppensuche & Quest-Hilfe** – als *Sucht Gruppe* (in einer Gruppe als *Sucht Mitspieler* angezeigt) oder *Braucht Quest-Hilfe* eintragen, mit Notiz und den Rollen, die noch fehlen. Alle sehen Klasse, Level, Rolle, Zone und wie voll die Gruppe ist (z. B. *Gruppe 3/5*); die Gruppengröße wird automatisch aktualisiert. Ein Klick auf **Beitreten** schickt eine Beitrittsanfrage an die Gruppe, **Einladen** lädt einen Einzelspieler ein. Rechtsklick zum Anflüstern. Für alle Gildenränge.
- **Gildeninfo** – zeigt den Info-Text aus dem Blizzard-Gildenfenster, für alle gleich. Ändert er sich, bekommt ihr einen Hinweis. Offiziere bearbeiten ihn im Blizzard-Gildenfenster, einen Klick entfernt (Blizzard erlaubt Addons nicht, ihn zu ändern).
- **Gildenchat & Communities** – Gildenchat, Offizierschat und alle Blizzard-Communities direkt im Fenster, mit dem Verlauf vom Server. Nachrichten werden zusätzlich lokal gespeichert, damit alte Nachrichten mit dem richtigen Namen sichtbar bleiben.
- **Mitgliederliste** – eure Gilde oder jede eurer Communities, nur online oder alle inkl. offline, mit Rang, Notizen und „zuletzt online“.
- **Spieler einladen** – Namen eingeben und in die Gilde oder die gewählte Community einladen, oder per Rechtsklick auf ein Mitglied anflüstern, in die Gruppe einladen, als Freund hinzufügen oder in Gilde / Community einladen.
- **Gildenverwaltung** – Klick auf ein Mitglied zeigt die Notizen; dort befördern, degradieren, Rang setzen, entfernen oder Gildenleitung übergeben (je nach deinen Rechten). Läuft über Blizzards eigene Gildenbefehle.
- **Community-Verwaltung** – Rechtsklick auf ein Community-Mitglied, um die Rolle zu ändern, die Notiz zu bearbeiten oder es zu entfernen.
- **Umfragen** – Offiziere legen Umfragen mit bis zu 6 Antworten und wahlweiser Laufzeit (1 Tag bis 2 Wochen) an, alle stimmen ab.
- **Mehr Meilensteine** – Erfolge, erste Raidboss-Siege, neue M+-Bestleistungen und neue Reittiere.
- **Event-Aufstellung** – Rollen-Check für Gruppe oder Schlachtzug und „Alle Zugesagten einladen“ für Offiziere.
- **Werbetext und Notiz-Vorlagen**, dazu eine Einstellungsseite in den WoW-Optionen (`/gp optionen`).
- **Versionscheck** – Erinnerung, wenn in der Gilde eine neuere GuildPride-Version genutzt wird.
- **Deutsch & Englisch** – stellt sich automatisch auf die Sprache deines Clients ein.

### Befehle

| Befehl | Funktion |
|---|---|
| `/gp` | Fenster öffnen (`/gp hilfe` zeigt alle Befehle) |
| `/gp sound` · `/gp popup` | Sounds oder Popups an/aus |
| `/gp blizzard` | zwischen GuildPride und dem Blizzard-Gildenfenster wechseln |
| `/gp kuerzel XYZ` | Gildenkürzel festlegen (ohne Kürzel: automatisch) |
| `/gp einladen Name-Realm` | Spieler in die Gilde einladen |
| `/gp version` | wer in der Gilde welche Version nutzt |
| `/gp werben` | gespeicherten Werbetext in die Chat-Eingabe legen |
| `/gp optionen` | GuildPride-Seite in den WoW-Optionen öffnen |
| `/gp badge 30` | Meilenstein-Popup testen |

### Gut zu wissen

- Meilensteine, Events und Gruppensuche werden zwischen Gildenmitgliedern abgeglichen, die **GuildPride installiert haben**.
- Daten gehen nur an eure Gilde, per Addon-Nachricht. Wer mit seinem Rang nicht im Gildenchat schreiben darf, sendet über ein Gildenmitglied, das gerade online ist.
- Gildendaten laufen zusätzlich über einen versteckten, passwortgeschützten Hintergrund-Kanal eurer Gilde, damit der Abgleich nicht von Rangrechten im Gildenchat abhängt.
- Während der *Chat-Sperre* in Instanzen (z. B. Mythisch+, gewertetes PvP) blockiert Blizzard Addon-Nachrichten. GuildPride wartet und sendet danach.
- Feedback und Fehlermeldungen sind sehr willkommen – am besten mit Lua-Fehlermeldung und Spielversion.

---

*Fonts: DejaVu (free license, included). Artwork created for GuildPride.*
