#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo " Z.A.T.O. - French Translation Installer"
echo "============================================"
echo

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STEAM_APP_ID="4122860"
GAME_FOLDER="Z.A.T.O.  I Love the World and Everything In It"
GAME_DIR=""

# --- Detect Steam installation ---
STEAM_PATHS=()

if [[ "$(uname)" == "Darwin" ]]; then
    # macOS
    STEAM_PATHS+=("$HOME/Library/Application Support/Steam")
else
    # Linux
    STEAM_PATHS+=("$HOME/.steam/steam")
    STEAM_PATHS+=("$HOME/.local/share/Steam")
    # Flatpak Steam
    STEAM_PATHS+=("$HOME/.var/app/com.valvesoftware.Steam/.steam/steam")
    STEAM_PATHS+=("$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam")
fi

find_game() {
    local steam_path="$1"

    # Check default library
    if [[ -f "$steam_path/steamapps/appmanifest_${STEAM_APP_ID}.acf" ]]; then
        GAME_DIR="$steam_path/steamapps/common/$GAME_FOLDER"
        return 0
    fi

    # Parse libraryfolders.vdf for additional libraries
    local vdf="$steam_path/steamapps/libraryfolders.vdf"
    if [[ ! -f "$vdf" ]]; then
        return 1
    fi

    while IFS= read -r line; do
        # Match lines like:    "path"    "/some/path"
        if echo "$line" | grep -qi '"path"'; then
            # Extract the path value (4th quoted string on the line)
            lib_path="$(echo "$line" | sed 's/.*"path"[[:space:]]*"//' | sed 's/".*//')"
            # Unescape backslashes (VDF uses \\ for \)
            lib_path="$(echo "$lib_path" | sed 's|\\\\|/|g')"
            if [[ -n "$lib_path" && -f "$lib_path/steamapps/appmanifest_${STEAM_APP_ID}.acf" ]]; then
                GAME_DIR="$lib_path/steamapps/common/$GAME_FOLDER"
                return 0
            fi
        fi
    done < "$vdf"

    return 1
}

# Try each known Steam path
for sp in "${STEAM_PATHS[@]}"; do
    if [[ -d "$sp" ]]; then
        echo "[*] Checking Steam at: $sp"
        if find_game "$sp"; then
            break
        fi
    fi
done

# --- Validate or ask for manual input ---
if [[ -n "$GAME_DIR" && -d "$GAME_DIR/game" ]]; then
    echo "[*] Game found at: $GAME_DIR"
    echo
else
    if [[ -n "$GAME_DIR" ]]; then
        echo "[!] Found game path but 'game/' subfolder is missing:"
        echo "    $GAME_DIR"
    else
        echo "[!] Z.A.T.O. (App ID $STEAM_APP_ID) was not found automatically."
    fi
    echo
    echo "Please enter the full path to the Z.A.T.O. game folder."
    echo "Example: /home/user/.steam/steam/steamapps/common/Z.A.T.O.  I Love the World and Everything In It"
    echo
    read -rp "Game path: " GAME_DIR

    if [[ -z "$GAME_DIR" ]]; then
        echo "[!] No path entered. Aborting."
        exit 1
    fi

    if [[ ! -d "$GAME_DIR/game" ]]; then
        echo "[!] Invalid path: could not find a 'game/' subfolder at:"
        echo "    $GAME_DIR"
        exit 1
    fi
fi

# --- Install translation files ---
echo "[*] Installing French translation..."
echo

cp "$SCRIPT_DIR/force_lang_fr.rpy" "$GAME_DIR/game/force_lang_fr.rpy"
echo "    Copied: force_lang_fr.rpy"

mkdir -p "$GAME_DIR/game/tl/french"
cp -r "$SCRIPT_DIR/tl/french/." "$GAME_DIR/game/tl/french/"
echo "    Copied: tl/french/ (translation files)"

echo
echo "============================================"
echo " Installation complete!"
echo " Launch Z.A.T.O. and the game will be"
echo " in French."
echo "============================================"
