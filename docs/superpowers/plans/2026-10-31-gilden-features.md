# Plan: Gilden-Features (nächstes großes Update, 1.10.0)

Ziel: die vorgeschlagenen Verbesserungen einbauen. Schlüsselsteine und
M+-Wertung nur in Retail, in WoW Forever ausgeblendet.

## Grundlagen

- `ns.IS_RETAIL` (GuildPride.lua): Interface-Version ≥ 100000 **und** `C_MythicPlus`
  vorhanden. Forever (Interface 16001) ist damit nie Retail.
- `ns.WeekStart()`: Beginn der laufenden Woche (Blizzard-Wochenreset, sonst 7 Tage).
- Neue Standardwerte: `minimap`, `chatFont`, `scale`, `alpha`, `welcome`.
- Alle neuen Texte deutsch als Schlüssel, englisch in `GuildPrideLocale.lua`.

## Für alle Mitglieder

| # | Feature | Datei | Umsetzung |
|---|---------|-------|-----------|
| 1 | Mitglieder suchen | GuildPrideUI.lua | Suchfeld in der großen Mitgliederliste, filtert Name, Rang, Notiz, Zone |
| 2 | Sortieren | GuildPrideUI.lua | Spaltenköpfe Name, Level, Rang, Zuletzt online; erneuter Klick dreht die Richtung. Wahl in `GuildPrideDB.memberSort` |
| 3 | Ungelesen im Chat | GuildPrideChat.lua | Zähler je Kanal an Gilde, Offiziere, Communities (auch im Menü) und am Reiter „Gilde & Chat“. Eigene Nachrichten zählen nicht. Kanal öffnen = gelesen |
| 4 | Erwähnungen | GuildPrideChat.lua | Zeilen mit deinem Namen bekommen ein »-Zeichen und goldene Schrift |
| 5 | Schlüsselsteine + Wertung (nur Retail) | GuildPrideKeys.lua (neu), GuildPrideHelp.lua, GuildPrideUI.lua | Jeder mit GuildPride meldet Schlüssel und Wertung („KEY“), beim Login wird gefragt („KEYQ“). Ansicht „Schlüssel der Gilde“ in der Gruppensuche, Schlüssel in Mitgliederliste und Tooltip. Alte Schlüssel fallen beim Wochenreset weg |
| 6 | Wochenrückblick | GuildPrideUI.lua | Abschnitt „Diese Woche“ auf der Übersicht: Level, Raid-Siege, M+ (nur Retail), Erfolge, Reittiere, Beitritte, Abgänge, fleißigstes Mitglied |
| 7 | Minimap-Knopf | GuildPrideMinimap.lua (neu) | Linksklick öffnet, Rechtsklick Einstellungen, ziehen verschiebt. In den Einstellungen abschaltbar |

## Für Offiziere

| # | Feature | Datei | Umsetzung |
|---|---------|-------|-----------|
| 8 | Inaktive Mitglieder | GuildPrideUI.lua | Knopf „Inaktive“ (nur wer entfernen darf, nur Gilde): schaltet 30+, 60+, 90+ Tage durch. Entfernen wie bisher per Klick auf die Zeile |
| 9 | Automatische Begrüßung | GuildPrideMembers.lua | Einstellung + eigener Text mit `{name}`. Wartet zufällig 2–8 s; wer zuerst begrüßt, meldet das („WEL“), die anderen schweigen. Nicht in der Chat-Sperre |
| 10 | Wöchentliche Events | GuildPrideEvents.lua | Haken „Jede Woche wiederholen“. 3 Std. nach Beginn rückt das Event auf die nächste Woche; jeder rechnet gleich, alte Anmeldungen verfallen |
| 11 | Anwesenheit | GuildPrideEvents.lua | 10 Min. nach Beginn erfasst Ersteller bzw. Offizier in der Gruppe, wer da ist. Knopf „Anwesenheit erfassen“ und Übersicht „Anwesenheit“ (zugesagt, da, Quote). Nur lokal gespeichert |

## Aussehen

| # | Feature | Datei | Umsetzung |
|---|---------|-------|-----------|
| 12 | Eigener Style | GuildPrideTheme.lua, GuildPrideUI.lua | 6. Style „Eigene“: Blizzards Farbwähler, alle Farben werden aus einer Farbe abgeleitet |
| 13 | Fenstergröße, Deckkraft, Chat-Schrift | GuildPrideUI.lua, GuildPrideChat.lua | −/+-Regler in den Einstellungen (70–130 %, 50–100 %, 10–18 pt). Die Einstellungsseite wird scrollbar |

## Abschluss

- luacheck ohne Warnungen, README und CHANGELOG (Abschnitt „Unreleased“) ergänzen.
- Version erst beim Veröffentlichen auf 1.10.0 setzen.
- Im Spiel testen: Retail **und** Forever (dort keine Schlüssel/M+-Anzeige).
