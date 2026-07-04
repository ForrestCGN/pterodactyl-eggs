# CGN - ATM11 - Projekt

Pterodactyl Egg für **All the Mods 11 (ATM11)** mit CurseForge ServerFiles und NeoForge.

Getestet mit:

- Pterodactyl/Wings 1.12.x
- Java 25 Runtime: `ghcr.io/ptero-eggs/yolks:java_25`
- Install-Container: `eclipse-temurin:25-jdk-jammy`
- ATM11 CurseForge Project ID: `1148445`
- ATM11 ServerFiles `0.2.0` File ID: `8357756`

## Was dieses Egg macht

Das Egg lädt eine CurseForge ServerFiles-ZIP herunter, prüft die ZIP, entpackt sie, führt den NeoForge Server-Installer aus und setzt `unix_args.txt` für den Pterodactyl-Start.

Wichtig: ServerFiles-ZIPs enthalten normalerweise **keine** `manifest.json`. Das ist korrekt. Eine `manifest.json` gehört zur normalen CurseForge Client-/Main-Datei. Dieses Egg behandelt eine ZIP ohne `manifest.json` deshalb als Serverpack-Kandidat.

## Pterodactyl-Einstellungen

### Docker Image

Im Server unter Startup/Build:

```text
ghcr.io/ptero-eggs/yolks:java_25
```

### Startup Command

```bash
java $([[ -f user_jvm_args.txt ]] && printf %s "@user_jvm_args.txt") -Xms128M -Xmx{{SERVER_MEMORY}}M -Dterminal.jline=false -Dterminal.ansi=true @unix_args.txt nogui
```

## Variablen

### PROJECT_ID

```text
1148445
```

Das ist die CurseForge Project ID von ATM11.

Alternative:

```text
zip
```

Dann muss vorher eine Datei `server.zip` manuell in den Serverordner hochgeladen werden.

### VERSION_ID

Empfohlen: konkrete ServerFiles File ID eintragen.

Beispiel für ATM11 `0.2.0`:

```text
8357756
```

`latest` wird nicht empfohlen, weil CurseForge für ATM11 aktuell nicht zuverlässig ein Serverpack über die API meldet. Wenn `latest` kein Serverpack findet, bricht das Egg bewusst mit einer klaren Fehlermeldung ab. Es gibt keinen heimlichen Fallback auf eine feste File ID.

### API_KEY

CurseForge API-Key. Wird benötigt, außer `PROJECT_ID=zip` wird mit manuell hochgeladener `server.zip` verwendet.

Der API-Key darf **nicht** in GitHub committed werden.

### CLEAN_MODPACK_FILES

Empfohlen:

```text
true
```

Bei `true` wird vor dem Entpacken ein Backup geschützter Serverdaten erstellt und packverwaltete Dateien werden sauber entfernt. Das verhindert, dass bei Updates alte Mods liegen bleiben.

## CurseForge API-Key holen

1. CurseForge Console öffnen.
2. Einloggen.
3. Bereich **API Keys** öffnen.
4. API-Key erzeugen oder vorhandenen Key kopieren.
5. In Pterodactyl beim Server unter **Startup → API_KEY** eintragen.

Wichtig:

- Der Key gehört nur in die Pterodactyl-Variable.
- Der Key gehört nicht in das Egg JSON.
- Der Key gehört nicht nach GitHub.

## Fresh Install

Empfohlene Werte:

```text
PROJECT_ID=1148445
VERSION_ID=8357756
CLEAN_MODPACK_FILES=true
```

Dann im Pterodactyl-Adminbereich den Server mit diesem Egg erstellen und auf **Create Server** klicken.

Pterodactyl startet danach automatisch die Installation. Das Egg lädt `server.zip`, entpackt die ServerFiles, installiert NeoForge und setzt `unix_args.txt`. Nach erfolgreicher Installation startet Pterodactyl den Server automatisch mit dem konfigurierten Startup Command.

## Update / Reinstall

Für Updates neue **ServerFiles File ID** bei `VERSION_ID` eintragen und danach Reinstall ausführen.

```text
Settings → Reinstall Server
```

Bei `CLEAN_MODPACK_FILES=true` wird vorher gesichert:

```text
world/
server.properties
eula.txt
ops.json
whitelist.json
banned-players.json
banned-ips.json
usercache.json
journeymap/
```

Danach werden packverwaltete Dateien entfernt und neu aus der ServerFiles-ZIP aufgebaut:

```text
mods/
libraries/
config/
defaultconfigs/
kubejs/
local/
resourcepacks/
shaderpacks/
openloader/
patchouli_books/
run.sh
run.bat
startserver.sh
startserver.bat
unix_args.txt
win_args.txt
user_jvm_args.txt
neoforge-*-installer.jar
forge-*-installer.jar
minecraft_server*.jar
server.jar
```

Backups werden abgelegt unter:

```text
backups/cgn-atm11-update-YYYYMMDD-HHMMSS/
```

## Bekannte Einschränkung

Dieses Egg ist aktuell gezielt für ATM11 getestet. Es kann als Grundlage für andere CurseForge/ATM ServerFiles-Packs dienen, ist aber nicht pauschal für alle ATM-Versionen freigegeben.

Für andere Packs müssen Java-Version, Loader und ServerFiles-Struktur separat getestet werden.

## Fehlerdiagnose

Install-Logs liegen auf dem Host unter:

```bash
/var/log/pterodactyl/install/
```

Neueste Logdatei anzeigen:

```bash
LATEST=$(ls -t /var/log/pterodactyl/install/*.log | head -n 1)
echo "$LATEST"
cat "$LATEST"
```

Erfolgreiches Ende sieht ungefähr so aus:

```text
The server installed successfully
Linking libraries/net/neoforged/neoforge/.../unix_args.txt -> unix_args.txt
Install completed successfully
```

Danach startet Pterodactyl den Server automatisch. Falls nicht, im Panel manuell **Start** drücken.
