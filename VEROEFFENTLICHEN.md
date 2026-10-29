# GuildPride veröffentlichen

GitHub baut die ZIP automatisch und lädt sie zu CurseForge (und auf Wunsch zu Wago) hoch.
Diese Datei und der Ordner `.github` landen nicht in der ZIP.

## Schon eingerichtet

- GitHub-Repository: https://github.com/Rottgar85/GuildPride
- CurseForge-Projekt-ID in `GuildPride.toc`: `## X-Curse-Project-ID: 1771937`
- GitHub-Secret `CF_API_KEY` (Repository → Settings → Secrets and variables → Actions)

Für Wago zusätzlich: `## X-Wago-ID: abcdef12` in die `.toc` und das Secret `WAGO_API_TOKEN`
(addons.wago.io → Account → API Keys). Das GitHub-Token ist automatisch vorhanden.

## Neue Version veröffentlichen

1. In `GuildPride.toc` die `## Version:` erhöhen und in `CHANGELOG.md` eintragen, was neu ist.
2. Änderungen hochladen (commit und push). GitHub prüft dabei den Lua-Code (Check).
3. Einen Tag mit der Version setzen und hochladen, zum Beispiel:
   `git tag v1.3.1` und dann `git push origin v1.3.1`
4. Unter „Actions“ im Repository siehst du, wie die ZIP gebaut und hochgeladen wird.
   Die fertige ZIP liegt danach auch unter „Releases“.

## Ohne GitHub: ZIP von Hand hochladen

Auf curseforge.com → Projekt 1771937 → „Upload File“ die fertige ZIP wählen,
als Spielversion Retail angeben, Release-Typ „Release“ und den Abschnitt der neuen
Version aus `CHANGELOG.md` als Changelog einfügen.
