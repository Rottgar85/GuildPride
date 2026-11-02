# Plan: Serverweite Gruppensuche (1.13.0)

Ziel: In der Gruppensuche sieht man nicht nur die eigene Gilde, sondern alle
Spieler auf dem Server, die GuildPride benutzen. Dabei bleibt jeder Spiel-Client
(Retail, Classic Era, Anniversary, MoP Classic, WoW Forever …) strikt für sich,
und die geschützten Gildendaten verlassen nie die Gilde.

## Ist-Stand (kurz)

- Gruppensuche: `GuildPrideHelp.lua`, Nachrichten `LFG` (Eintrag) und `LFGQ`
  (Abfrage beim Öffnen des Reiters), Einträge in `entries[sender]`.
- Versand: Warteschlange in `GuildPrideEvents.lua` (Ziele: Gilde, `@OFFICER`,
  `@CHANNEL` = abgesicherter Gildenkanal `GPs…`, Flüstern).
- Empfang: `GuildPride.lua` (`CHAT_MSG_ADDON`) nimmt Kanal- und Flüster-
  Nachrichten **nur von Gildenmitgliedern** an und lässt nur den eigenen
  Gildenkanal zu. Genau diese Sperre muss für den neuen Weg gezielt und eng
  geöffnet werden.

## 1. Abgrenzung zwischen den Clients

Zwei Schichten, damit nie Daten eines anderen Clients angezeigt werden:

1. **Eigener Kanal pro Client.** Kanalname aus festem Präfix + Client-Kennung,
   z. B. `GPLFG_R` (Retail), `GPLFG_E` (Classic Era), `GPLFG_A` (Anniversary),
   `GPLFG_M` (MoP Classic), `GPLFG_F` (Forever). Kennung aus
   `WOW_PROJECT_ID` + Interface-Nummer (`GetBuildInfo`), zentral als
   `ns.CLIENT_TAG` in `GuildPride.lua` neben `ns.IS_RETAIL`/`ns.IS_CLASSIC`.
2. **Kennung in jeder Nachricht.** Erstes Feld jeder öffentlichen Nachricht ist
   `ns.CLIENT_TAG` plus Protokollversion (`R1`). Passt sie nicht, wird die
   Nachricht verworfen – schützt auch, falls zwei Clients denselben Kanal
   teilen oder ein künftiger Client dazukommt.

Zusätzlich je nach Client:
- **Fraktion:** In Classic sind eigene Kanäle fraktionsgetrennt, und man kann die
  andere Fraktion nicht einladen. Fraktion (`A`/`H`) wird mitgeschickt; in
  Classic werden fremde Fraktionen ausgeblendet, in Retail mit Symbol gezeigt.
- **Realm-Verbund:** Retail-Kanäle gehen über verbundene Realms; Namen immer als
  `Name-Realm` behandeln (ist über `Normalize` schon so).
- **Inhalte:** Schlüsselstein-Einträge (`key`) nur in Retail; Dungeon-/
  Schwierigkeitswahl wie bisher je Client (`DIFFS`, `HAS_DUNGEON_PICK`).

## 2. Abgrenzung Gilde ↔ Server

- **Neue Nachrichtenarten** statt `LFG`/`LFGQ` wiederzuverwenden:
  `PLFG` (öffentlicher Eintrag) und `PLFGQ` (öffentliche Abfrage). Über den
  öffentlichen Kanal werden **ausschließlich** diese beiden angenommen – kein
  `REQ`, `RLY`, `FWD`, `CKY`, `MP`, Events, Umfragen, Meilensteine usw.
- **Eigener Speicher** `publicEntries[sender]`, getrennt von `entries` der
  Gilde. Ein Gildenmitglied, das auch öffentlich sucht, erscheint einmal (Gilden-
  eintrag hat Vorrang).
- **Sichtbarkeit pro Eintrag:** Beim Eintragen wählt man „Nur Gilde" oder
  „Gilde + Server". Standard: **Nur Gilde** (niemand wird ungefragt öffentlich).
- **Sparsamer Inhalt:** Der öffentliche Eintrag enthält nur, was für die Suche
  nötig ist (Art, Notiz, Stufe, Zone, Gruppengröße, gesuchte Rollen, eigene
  Rolle, Klasse, Fraktion, Dungeon/Quest/Schlüssel). **Kein Gildenname** – auch
  nicht optional. Er muss unter die 195-Byte-Grenze passen, damit kein `MP`
  nötig ist; zu lange Notiz/Questnamen werden gekürzt.

## 3. Kanal beitreten und verwalten (`GuildPrideEvents.lua`)

- Neben `JoinDataChannel` ein `JoinPublicChannel()`: gleiche Verzögerung (15 s
  nach `PLAYER_ENTERING_WORLD`), damit Allgemein/Handel ihre Nummern behalten;
  ohne Passwort, nicht in Chatfenster eintragen.
- Nur beitreten, wenn die Option **„Serverweite Gruppensuche"** an ist
  (Einstellungen + `/gp server`). Ausschalten verlässt den Kanal sofort.
- Kanal-Limit (max. 10 eigene Kanäle) abfangen: Klappt der Beitritt nicht,
  einmal Hinweis im Chat, Funktion bleibt aus, Gilde läuft normal weiter.
- Neues Warteschlangen-Ziel `@PUBLIC`: sendet nur über den öffentlichen Kanal,
  **nie** ersatzweise an Gilde oder per Flüstern.
- Eigene, langsamere Drosselung für `@PUBLIC` (z. B. höchstens 1 Nachricht pro
  2 s), damit Gildennachrichten nicht ausgebremst werden. Chat-Sperre
  (`InChatMessagingLockdown`) gilt wie bisher.

## 4. Empfang absichern (`GuildPride.lua`)

Im `CHAT_MSG_ADDON`-Zweig für `CHANNEL` einen zweiten, getrennten Weg:

1. Kanal ist exakt unser öffentlicher Kanal (Name/ID wie beim Datenkanal prüfen).
2. Nachricht beginnt mit `PLFG:` oder `PLFGQ:` – alles andere sofort verwerfen.
3. Client-Kennung stimmt (siehe 1.).
4. Absender nicht auf der Ignorierliste (`C_FriendList.IsIgnored`) und nicht auf
   der eigenen GuildPride-Sperrliste.
5. Begrenzung pro Absender (höchstens 1 Eintrag / 10 s, 1 Abfrage / 30 s) und
   Obergrenze für `publicEntries` (z. B. 300; älteste fliegen raus).
6. Dann direkt an den Handler – **nicht** über `Dispatch`, damit die
   Gilden-Weiterleitungen (`RLY`/`FWD`/`MP`) dort nie erreichbar sind.
   `ns.AddonUsers` wird dabei **nicht** gesetzt (das ist die Gildenliste für
   Weiterleitungen).

Die bestehende Regel „Kanal/Flüstern nur von Gildenmitgliedern" bleibt für alles
andere unverändert.

## 5. Abfrage ohne Antwortflut

`LFGQ` lässt heute alle sofort antworten – auf einem vollen Server zu viel.

- `PLFGQ` beim Öffnen des Reiters höchstens alle 60 s.
- Nur wer selbst einen öffentlichen Eintrag hat, antwortet – mit zufälliger
  Verzögerung 1–8 s als **Rundsendung** in den Kanal. Wurde der eigene Eintrag
  vor weniger als 60 s schon gesendet, entfällt die Antwort.
- Eigener öffentlicher Eintrag wird zusammen mit dem Gildeneintrag alle 4 min erneuert, fremde öffentliche
  Einträge verfallen nach 10 min ohne Lebenszeichen, Austragen schickt `PLFG`
  mit Art `none`.

## 6. Oberfläche (`GuildPrideHelp.lua`, `GuildPrideLocale.lua`)

- Umschalter über der Liste: **Gilde · Server · Alle** (gemerkt in
  `GuildPrideDB`). Bei ausgeschalteter Option nur „Gilde".
- Beim Eintragen: Kontrollkästchen **„Auch serverweit anzeigen"**.
- Fremde Einträge mit Kennzeichnung „Server" (statt Gildenname), Realm bei
  anderem Realm, Fraktionssymbol in Retail.
- Aktionen für fremde Einträge: Anflüstern, Einladen / Einladung anfragen,
  **Ignorieren** (setzt GuildPride-Sperrliste, blendet sofort aus).
- Chat-Hinweise für öffentliche Einträge als eigene Option, Standard **aus** –
  sonst wird man auf großen Servern zugespammt.
- Alle neuen Texte in Deutsch + Englisch in `GuildPrideLocale.lua`.

## 7. Verträglichkeit

- Ältere GuildPride-Versionen treten dem Kanal nicht bei und kennen `PLFG` nicht
  → keine Störung. Gildenpfad (`LFG`) bleibt unverändert.
- Protokollversion im Kennungsfeld (`R1`) erlaubt spätere Formatänderungen;
  unbekannte Versionen werden ignoriert.

## 8. Umsetzungsschritte

1. `ns.CLIENT_TAG`, Fraktionskürzel und Optionen (`publicLFG`, `publicAlerts`,
   `lfgScope`, Sperrliste) anlegen; SavedVariables-Standardwerte.
2. Öffentlichen Kanal beitreten/verlassen + Ziel `@PUBLIC` mit eigener
   Drosselung in `GuildPrideEvents.lua`.
3. Abgesicherter Empfangsweg in `GuildPride.lua` (Filter 1–6).
4. `PLFG`/`PLFGQ` senden/empfangen, `publicEntries`, Verfall, Antwort mit
   Zufallsverzögerung in `GuildPrideHelp.lua`.
5. Oberfläche: Umschalter, Kontrollkästchen, Kennzeichnung, Ignorieren.
6. Einstellungen-Seite + `/gp server` + Hilfetext der Befehle.
7. Texte (DE/EN), `CHANGELOG.md`, `README`, `docs/CURSEFORGE.md`,
   Version **1.13.0** in `GuildPride.toc`.

## 9. Testen (im Spiel)

- Zwei Charaktere in **verschiedenen Gilden** (oder einer ohne Gilde) auf
  demselben Realm/Client: Eintrag „Gilde + Server" erscheint beim anderen unter
  „Server"; „Nur Gilde" erscheint dort nicht.
- Derselbe Account auf **zwei Clients** (z. B. Retail + Classic Era): kein
  Eintrag wandert hinüber (Kanalname und Kennung verschieden).
- Classic: fremde Fraktion wird nicht angezeigt.
- Untergeschobene Nachricht (z. B. `EVT:` per `/run` in den öffentlichen Kanal)
  wird verworfen.
- Option aus → Kanal verlassen, Reiter zeigt nur Gilde.
- Gildenfunktionen (Events, Umfragen, Kanal-Schlüssel) unverändert.
- Bosskampf/M+: Warteschlange pausiert, danach Versand.

## Entscheidungen (2026-11-02)

- „Clients" = **Spielversionen**. Die Trennung aus Abschnitt 1 reicht, keine
  zusätzliche Freigabeliste für Spieler oder Gilden.
- **Kein Gildenname** im öffentlichen Eintrag.
