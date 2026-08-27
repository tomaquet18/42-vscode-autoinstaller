#!/usr/bin/env bash
set -e

# Color definitions
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
MAGENTA="\033[1;35m"
CYAN="\033[1;36m"
BOLD="\033[1m"
RESET="\033[0m"

# Header
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════╗"
echo -e "║${BOLD}     Visual Studio Code Installer Script       ${RESET}${CYAN}║"
echo -e "║${BOLD}        Created by tomaquet18 (alefern2)       ${RESET}${CYAN}║"
echo -e "╚═══════════════════════════════════════════════╝"
echo -e "${RESET}"

VSCODE_URL="https://code.visualstudio.com/sha/download?build=stable&os=linux-x64"

# Generate random temp filename
TMPFILE="/tmp/vscode_$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12).tar.gz"

# Target directory
if [ -d "$HOME/sgoinfre" ] && [ -w "$HOME/sgoinfre" ]; then
    TARGET_DIR="$HOME/sgoinfre/vscode"
    echo -e "${BLUE}sgoinfre detected, installing there.${RESET}"
else
    TARGET_DIR="$HOME/opt/vscode"
    echo -e "${YELLOW}sgoinfre not found or not writable, falling back to $TARGET_DIR${RESET}"
fi
VSCODE_BIN_PATH="$TARGET_DIR/bin"

# Detect shell and choose rc file
case "$SHELL" in
    */zsh)
        RC_FILE="$HOME/.zshrc"
        ;;
    */bash)
        RC_FILE="$HOME/.bashrc"
        ;;
    *)
        echo -e "${YELLOW}Unknown shell ($SHELL), defaulting to .bashrc${RESET}"
        RC_FILE="$HOME/.bashrc"
        ;;
esac
echo -e "${BLUE}Using rc file:${RESET} $RC_FILE"

# --- Handle existing installation (update case) ---
if [ -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}Existing installation found at $TARGET_DIR${RESET}"

    # Warn if a VS Code process is still running, since that can leave
    # NFS ".nfsXXXXXXXX" silly-rename files behind and make rm -rf fail
    if pgrep -f "$VSCODE_BIN_PATH/code" >/dev/null 2>&1; then
        echo -e "${RED}VS Code appears to still be running. Please close it before updating.${RESET}"
        echo -e "${YELLOW}Attempting to close it automatically...${RESET}"
        pkill -f "$VSCODE_BIN_PATH/code" || true
        sleep 1
    fi

    echo -e "${MAGENTA}Removing previous installation to prepare for update...${RESET}"
    if ! rm -rf "$TARGET_DIR" 2>/tmp/rm_error.log; then
        echo -e "${RED}Failed to fully remove $TARGET_DIR.${RESET}"
        if grep -q "Device or resource busy" /tmp/rm_error.log; then
            echo -e "${YELLOW}This usually means some files are still open by a running process"
            echo -e "(NFS leaves behind .nfsXXXXXXXX files until the handle is released).${RESET}"
            echo -e "Close any remaining VS Code windows/processes and re-run this script."
        fi
        rm -f /tmp/rm_error.log
        exit 1
    fi
    rm -f /tmp/rm_error.log
fi

mkdir -p "$TARGET_DIR"

echo -e "${MAGENTA}Downloading VS Code to $TMPFILE ...${RESET}"
curl -sSL "$VSCODE_URL" -o "$TMPFILE"

echo -e "${MAGENTA}Extracting VS Code...${RESET}"
tar -xzf "$TMPFILE" -C "$TARGET_DIR" --strip-components=1

echo -e "${MAGENTA}Cleaning up...${RESET}"
rm -f "$TMPFILE"

# Add PATH entry only if not already in rc file
if ! grep -q "$VSCODE_BIN_PATH" "$RC_FILE" 2>/dev/null; then
    echo -e "${BLUE}Adding VS Code path to $RC_FILE${RESET}"
    {
        echo ""
        echo "# Add Visual Studio Code to PATH"
        echo "export PATH=\"$VSCODE_BIN_PATH:\$PATH\""
    } >> "$RC_FILE"
else
    echo -e "${YELLOW}VS Code path already present in $RC_FILE, skipping.${RESET}"
fi

# Verify the icon exists where we expect it before wiring it into the .desktop file
ICON_PATH="${TARGET_DIR}/resources/app/resources/linux/code.png"
if [ ! -f "$ICON_PATH" ]; then
    echo -e "${YELLOW}Warning: icon not found at expected path ($ICON_PATH).${RESET}"
    echo -e "${YELLOW}The desktop launcher will still be created, but the icon may not show.${RESET}"
fi

# Create desktop entry
DESKTOP_FILE="$HOME/Desktop/vscode.desktop"
DESKTOP_FILE_CONTENT="[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editing. Redefined.
Exec=${VSCODE_BIN_PATH}/code --no-sandbox %F
Icon=${ICON_PATH}
Type=Application
Terminal=false
Categories=Development;IDE;
StartupWMClass=Code"

mkdir -p "$HOME/Desktop"
echo -e "${BLUE}Creating desktop entry at $DESKTOP_FILE ...${RESET}"
echo "$DESKTOP_FILE_CONTENT" > "$DESKTOP_FILE"
chmod +x "$DESKTOP_FILE"

# Mark the .desktop file as trusted on GNOME/Nautilus so it doesn't
# show up as "untrusted" and require a manual right-click > Allow Launching
if command -v gio >/dev/null 2>&1; then
    gio set "$DESKTOP_FILE" metadata::trusted true 2>/dev/null || true
fi

echo -e "${GREEN}\n✔ VS Code installed in $TARGET_DIR${RESET}"
echo -e "${GREEN}Desktop launcher created: $DESKTOP_FILE${RESET}"
echo -e "\nReload your shell to apply PATH changes:"
echo -e "    ${BOLD}source $RC_FILE${RESET}\n"
