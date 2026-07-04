# Changelog

## 0.1.0

First published CGN-ATM11 Egg release.

### Included

- Java 25 runtime support.
- CurseForge download by Project ID and File ID.
- ServerFiles ZIPs without `manifest.json` are treated as server-pack candidates.
- NeoForge installer is automatically found and executed after extraction.
- `unix_args.txt` is automatically linked to the NeoForge file.
- `PROJECT_ID=zip` supports a manually uploaded `server.zip`.
- `latest` is not hardcoded to a fixed File ID.
- Update/clean mode via `CLEAN_MODPACK_FILES`.
- Protected server data is backed up before clean reinstall/update and restored afterwards.

### Tested

- ATM11 Project ID `1148445`
- ATM11 ServerFiles `0.2.0` File ID `8357756`
- NeoForge `26.1.2.76`
- Java 25

### Note

`VERSION_ID=latest` is currently not recommended because CurseForge does not reliably expose an ATM11 server pack through the API. A specific ServerFiles File ID is recommended.
