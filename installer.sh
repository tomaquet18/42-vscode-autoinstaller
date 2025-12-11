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
TARGET_DIR="$HOME/opt/vscode"
VSCODE_BIN_PATH="$TARGET_DIR"

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

echo -e "${MAGENTA}Downloading VS Code to $TMPFILE ...${RESET}"
curl -sSL "$VSCODE_URL" -o "$TMPFILE"

echo -e "${MAGENTA}Preparing install directory: $TARGET_DIR${RESET}"
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

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

# Create desktop entry
DESKTOP_FILE="$HOME/Desktop/vscode.desktop"
mkdir -p "$HOME/Desktop"

echo -e "${BLUE}Creating desktop entry at $DESKTOP_FILE ...${RESET}"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editing. Redefined.
Exec=$HOME/opt/vscode/code --no-sandbox %F
Icon=$HOME/opt/vscode/resources/app/resources/linux/code.png
Type=Application
Terminal=false
Categories=Development;IDE;
StartupWMClass=Code
EOF

chmod +x "$DESKTOP_FILE"

echo -e "${GREEN}\n✔ VS Code installed in $TARGET_DIR${RESET}"
echo -e "${GREEN}Desktop launcher created: $DESKTOP_FILE${RESET}"
echo -e "\nReload your shell to apply PATH changes:"
echo -e "    ${BOLD}source $RC_FILE${RESET}\n"
