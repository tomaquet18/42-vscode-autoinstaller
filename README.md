# 42 VSCode AutoInstaller

Automated VS Code installer designed for **42 students**.  
This script installs VS Code in your home directory (`~/opt/vscode`), adds it to your PATH, and creates a desktop launcher. It works on **Linux** with **Bash** or **Zsh**.

## Features

- Downloads the latest stable VS Code release.
- Installs it in `~/opt/vscode` (no sudo required).
- Updates your shell configuration (`.bashrc` or `.zshrc`) to include VS Code in PATH.
- Creates a `vscode.desktop` launcher on your Desktop.
- Fully automated and colorized terminal output.

## Installation

Run the installer in a single line:

```bash
curl -sSL https://raw.githubusercontent.com/tomaquet18/42-vscode-autoinstaller/refs/heads/master/installer.sh | bash
```