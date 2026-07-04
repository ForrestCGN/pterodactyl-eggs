# CGN - ATM11 - Project

Pterodactyl Egg for **All the Mods 11 (ATM11)** using CurseForge ServerFiles and NeoForge.

Tested with:

- Pterodactyl/Wings 1.12.x
- Java 25 runtime: `ghcr.io/ptero-eggs/yolks:java_25`
- Install container: `eclipse-temurin:25-jdk-jammy`
- ATM11 CurseForge Project ID: `1148445`
- ATM11 ServerFiles `0.2.0` File ID: `8357756`

## What this Egg does

The Egg downloads a CurseForge ServerFiles ZIP, validates it, extracts it, runs the NeoForge server installer, and links `unix_args.txt` for the Pterodactyl startup command.

Important: ServerFiles ZIPs normally do **not** contain a `manifest.json`. That is expected. The `manifest.json` belongs to the normal CurseForge client/main file. This Egg treats a ZIP without `manifest.json` as a server-pack candidate.

## Pterodactyl settings

### Docker Image

Use this image in the server Startup/Build settings:

```text
ghcr.io/ptero-eggs/yolks:java_25
```

### Startup Command

```bash
java $([[ -f user_jvm_args.txt ]] && printf %s "@user_jvm_args.txt") -Xms128M -Xmx{{SERVER_MEMORY}}M -Dterminal.jline=false -Dterminal.ansi=true @unix_args.txt nogui
```

## Variables

### PROJECT_ID

```text
1148445
```

This is the CurseForge Project ID for ATM11.

Alternative:

```text
zip
```

Use this only if you manually upload a file named `server.zip` into the server directory before installation.

### VERSION_ID

Recommended: use a specific ServerFiles File ID.

Example for ATM11 `0.2.0`:

```text
8357756
```

`latest` is not recommended right now because CurseForge currently does not reliably expose the ATM11 server pack through the API. If `latest` cannot find a server pack, the Egg exits with a clear error message. It does not silently fall back to a hardcoded File ID.

### API_KEY

CurseForge API key. Required unless `PROJECT_ID=zip` is used with a manually uploaded `server.zip`.

The API key must **not** be committed to GitHub.

### CLEAN_MODPACK_FILES

Recommended:

```text
true
```

When set to `true`, the Egg backs up protected server data and removes pack-managed files before extracting the new ServerFiles ZIP. This prevents old mods from staying behind during updates.

## Getting a CurseForge API key

1. Open the CurseForge Console.
2. Log in.
3. Open **API Keys**.
4. Create a new key or copy an existing key.
5. Enter the key in Pterodactyl under **Startup → API_KEY**.

Important:

- The key belongs only in the Pterodactyl variable.
- The key does not belong in the Egg JSON.
- The key does not belong in GitHub.

## Fresh install

Recommended values:

```text
PROJECT_ID=1148445
VERSION_ID=8357756
CLEAN_MODPACK_FILES=true
```

Create the server in the Pterodactyl admin area with this Egg and click **Create Server**.

Pterodactyl automatically starts the installation. The Egg downloads `server.zip`, extracts the ServerFiles, installs NeoForge, and links `unix_args.txt`. After a successful installation, Pterodactyl automatically starts the server with the configured startup command.

## Update / reinstall

For updates, enter the new **ServerFiles File ID** in `VERSION_ID`, then run reinstall.

```text
Settings → Reinstall Server
```

With `CLEAN_MODPACK_FILES=true`, the Egg backs up:

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

Then pack-managed files are removed and rebuilt from the ServerFiles ZIP:

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

Backups are stored in:

```text
backups/cgn-atm11-update-YYYYMMDD-HHMMSS/
```

## Known limitation

This Egg is currently tested specifically for ATM11. It can be used as a base for other CurseForge/ATM ServerFiles packs, but it is not generally approved for every ATM version.

For other packs, the Java version, loader, and ServerFiles structure need to be tested separately.

## Troubleshooting

Install logs are located on the host at:

```bash
/var/log/pterodactyl/install/
```

Show the newest install log:

```bash
LATEST=$(ls -t /var/log/pterodactyl/install/*.log | head -n 1)
echo "$LATEST"
cat "$LATEST"
```

A successful ending looks similar to:

```text
The server installed successfully
Linking libraries/net/neoforged/neoforge/.../unix_args.txt -> unix_args.txt
Install completed successfully
```

After that, Pterodactyl starts the server automatically. If it does not, press **Start** manually in the panel.
