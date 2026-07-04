#!/bin/bash
set -Eeuo pipefail

cd /mnt/server

log() { echo "        $*" >&2; }
fail() { echo "        ERROR: $*" >&2; exit 1; }

PROJECT_ID="${PROJECT_ID:-1148445}"
VERSION_ID="${VERSION_ID:-latest}"
API_KEY="${API_KEY:-}"
CLEAN_MODPACK_FILES="${CLEAN_MODPACK_FILES:-true}"
CF_API="https://api.curseforge.com/v1"
SERVER_ZIP="server.zip"

log "CGN ATM11 installer starting"
log "PROJECT_ID=${PROJECT_ID}"
log "VERSION_ID=${VERSION_ID}"
log "CLEAN_MODPACK_FILES=${CLEAN_MODPACK_FILES}"

log "Installing required packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends curl jq unzip ca-certificates
log "Required packages installed"

api_get() {
    local url="$1"
    [[ -n "${API_KEY}" ]] || fail "CurseForge API key is missing"
    curl -fsSL --retry 3 --retry-delay 2 \
        -H "Accept: application/json" \
        -H "x-api-key: ${API_KEY}" \
        "$url"
}

download_file_id() {
    local file_id="$1"
    [[ -n "$file_id" ]] || fail "download_file_id called without file id"
    log "Resolving CurseForge download URL for file id ${file_id}"
    local url
    url="$(api_get "${CF_API}/mods/${PROJECT_ID}/files/${file_id}/download-url" | jq -r '.data // empty')"
    [[ -n "$url" && "$url" != "null" ]] || fail "No download URL returned for file id ${file_id}"
    log "Downloading ${url}"
    curl -fL --retry 3 --retry-delay 2 "$url" -o "${SERVER_ZIP}"
    log "Downloaded ${SERVER_ZIP} ($(du -h "${SERVER_ZIP}" | awk '{print $1}'))"
}

select_latest_serverpack() {
    log "Searching latest server pack for project ${PROJECT_ID}"
    local files_json selected main_file server_pack
    files_json="$(api_get "${CF_API}/mods/${PROJECT_ID}/files?pageSize=50")"

    selected="$(jq -r '
      [.data[]
        | select((.isAvailable // true) == true)
        | select(
            ((.isServerPack // false) == true)
            or ((.displayName // "") | test("server[ -_]*files|server[ -_]*pack|server"; "i"))
            or ((.fileName // "") | test("server[ -_]*files|server[ -_]*pack|server"; "i"))
          )
      ]
      | sort_by(.fileDate // "")
      | reverse
      | .[0].id // empty
    ' <<< "$files_json")"

    if [[ -n "$selected" && "$selected" != "null" ]]; then
        log "Selected latest server-pack-like file id: ${selected}"
        printf '%s\n' "$selected"
        return 0
    fi

    log "No server-pack-like file found in file list; checking main file metadata"
    main_file="$(api_get "${CF_API}/mods/${PROJECT_ID}" | jq -r '.data.mainFileId // empty')"
    [[ -n "$main_file" && "$main_file" != "null" ]] || fail "Could not determine main file id"

    server_pack="$(api_get "${CF_API}/mods/${PROJECT_ID}/files/${main_file}" | jq -r '.data.serverPackFileId // empty')"
    if [[ -n "$server_pack" && "$server_pack" != "null" ]]; then
        log "Selected serverPackFileId from main file metadata: ${server_pack}"
        printf '%s\n' "$server_pack"
        return 0
    fi

    fail "Could not find a latest server pack. Set VERSION_ID to the ServerFiles file id manually."
}

archive_has() {
    local pattern="$1"
    unzip -Z1 "${SERVER_ZIP}" | grep -Eiq "$pattern"
}

backup_and_clean_pack_files() {
    local enabled="$(printf '%s' "${CLEAN_MODPACK_FILES}" | tr '[:upper:]' '[:lower:]')"
    if [[ "$enabled" != "true" && "$enabled" != "1" && "$enabled" != "yes" ]]; then
        log "Update clean disabled; keeping existing files before unpack"
        return 0
    fi

    local backup_dir="backups/cgn-atm11-update-$(date +%Y%m%d-%H%M%S)"
    log "Update clean enabled; backing up protected server data to ${backup_dir}"
    mkdir -p "$backup_dir"

    local item
    for item in world server.properties eula.txt ops.json whitelist.json banned-players.json banned-ips.json usercache.json journeymap; do
        if [[ -e "$item" ]]; then
            log "Backing up ${item}"
            cp -a "$item" "$backup_dir/"
        fi
    done

    log "Removing pack-managed files for clean modpack update"
    rm -rf mods libraries config defaultconfigs kubejs local resourcepacks shaderpacks openloader patchouli_books
    rm -f run.sh run.bat startserver.sh startserver.bat unix_args.txt win_args.txt user_jvm_args.txt
    rm -f neoforge-*-installer.jar forge-*-installer.jar minecraft_server*.jar server.jar
}

restore_protected_data() {
    local enabled="$(printf '%s' "${CLEAN_MODPACK_FILES}" | tr '[:upper:]' '[:lower:]')"
    if [[ "$enabled" != "true" && "$enabled" != "1" && "$enabled" != "yes" ]]; then
        return 0
    fi

    local backup_dir
    backup_dir="$(ls -dt backups/cgn-atm11-update-* 2>/dev/null | head -n 1 || true)"
    [[ -n "$backup_dir" ]] || return 0

    log "Restoring protected server data after unpack"
    local item base
    for item in "$backup_dir"/*; do
        [[ -e "$item" ]] || continue
        base="$(basename "$item")"
        rm -rf "$base"
        cp -a "$item" ./
    done
}

maybe_replace_client_zip_with_serverpack() {
    if ! archive_has '(^|/)manifest\.json$'; then
        return 0
    fi

    log "Archive contains manifest.json; this is a CurseForge client pack"

    if [[ "${PROJECT_ID}" == "zip" ]]; then
        fail "Uploaded server.zip is a client pack. Upload the ServerFiles ZIP instead."
    fi

    local lookup_id file_json server_pack
    lookup_id="${VERSION_ID}"
    if [[ -z "$lookup_id" || "$lookup_id" == "latest" ]]; then
        lookup_id="$(api_get "${CF_API}/mods/${PROJECT_ID}" | jq -r '.data.mainFileId // empty')"
    fi

    if [[ -n "$lookup_id" && "$lookup_id" != "null" ]]; then
        file_json="$(api_get "${CF_API}/mods/${PROJECT_ID}/files/${lookup_id}")"
        server_pack="$(jq -r '.data.serverPackFileId // empty' <<< "$file_json")"
        if [[ -n "$server_pack" && "$server_pack" != "null" ]]; then
            log "Client file references serverPackFileId ${server_pack}; downloading server pack instead"
            rm -f "${SERVER_ZIP}"
            download_file_id "$server_pack"
            return 0
        fi
    fi

    fail "Downloaded archive is a client pack and no serverPackFileId was available. Use VERSION_ID of the ServerFiles ZIP."
}

install_serverpack_zip() {
    [[ -f "${SERVER_ZIP}" ]] || fail "${SERVER_ZIP} does not exist"

    log "Testing ${SERVER_ZIP}"
    unzip -tq "${SERVER_ZIP}" || fail "${SERVER_ZIP} is not a valid ZIP archive"

    maybe_replace_client_zip_with_serverpack

    log "Checking archive type"
    if archive_has '(^|/)manifest\.json$'; then
        fail "Archive still contains manifest.json; refusing to install client pack as server pack"
    fi

    backup_and_clean_pack_files

    log "No manifest.json found; treating archive as server-pack candidate"
    log "Unpacking ${SERVER_ZIP}"
    unzip -oq "${SERVER_ZIP}"

    restore_protected_data

    local installer
    installer="$(find . -maxdepth 4 -type f -iname 'neoforge-*-installer.jar' | sort -V | tail -n 1 || true)"
    [[ -n "$installer" ]] || fail "No neoforge-*-installer.jar found after unpacking; archive is not an ATM11/NeoForge server pack"

    log "Installing NeoForge using ${installer}"
    java -jar "$installer" --installServer

    local unix_args
    unix_args="$(find ./libraries -type f -path '*/net/neoforged/neoforge/*/unix_args.txt' | sort -V | tail -n 1 || true)"
    [[ -n "$unix_args" ]] || fail "NeoForge installed, but unix_args.txt was not found"

    log "Linking ${unix_args#./} -> unix_args.txt"
    ln -sf "${unix_args#./}" unix_args.txt

    if [[ ! -f eula.txt ]]; then
        echo "eula=true" > eula.txt
    fi
    log "Install completed successfully"
}

if [[ "${PROJECT_ID}" == "zip" ]]; then
    log "PROJECT_ID=zip selected; using existing ${SERVER_ZIP}"
else
    [[ -n "${API_KEY}" ]] || fail "API_KEY is required unless PROJECT_ID=zip"
    rm -f "${SERVER_ZIP}"
    if [[ -z "${VERSION_ID}" || "${VERSION_ID}" == "latest" ]]; then
        selected_id="$(select_latest_serverpack)"
        download_file_id "$selected_id"
    else
        download_file_id "${VERSION_ID}"
    fi
fi

install_serverpack_zip
