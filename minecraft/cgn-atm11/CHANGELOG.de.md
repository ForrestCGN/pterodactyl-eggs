# Changelog

## 0.1.0

Erster veröffentlichter CGN-ATM11-Egg-Stand.

### Enthalten

- Java 25 Runtime-Unterstützung.
- CurseForge Download per Project ID und File ID.
- ServerFiles-ZIP wird ohne `manifest.json` als Serverpack-Kandidat behandelt.
- NeoForge Installer wird nach dem Entpacken automatisch gesucht und ausgeführt.
- `unix_args.txt` wird automatisch auf die NeoForge-Datei verlinkt.
- `PROJECT_ID=zip` unterstützt manuell hochgeladene `server.zip`.
- `latest` wird nicht auf eine feste File ID hardcoded.
- Update/Clean-Modus über `CLEAN_MODPACK_FILES`.
- Geschützte Serverdaten werden vor Clean-Reinstall/Update gesichert und danach wiederhergestellt.

### Getestet

- ATM11 Project ID `1148445`
- ATM11 ServerFiles `0.2.0` File ID `8357756`
- NeoForge `26.1.2.76`
- Java 25

### Hinweis

`VERSION_ID=latest` ist aktuell nicht empfohlen, weil CurseForge für ATM11 nicht zuverlässig ein Serverpack über die API meldet. Empfohlen ist eine konkrete ServerFiles File ID.
