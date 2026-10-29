-- luacheck fuer GuildPride: findet Syntaxfehler und echte Fehler, ignoriert WoW-Globale und Stilfragen
std = "lua51"
max_line_length = false
allow_defined_top = true
ignore = {
    "1..", -- globale Variablen (WoW-API, Blizzard-Frames)
    "2..", -- unbenutzte Variablen und Argumente
    "4..", -- Verdecken von Variablen
    "5..", -- leere Bloecke, unerreichbarer Code
    "6..", -- Leerzeichen und Einrueckung
}
exclude_files = { ".github/**" }
