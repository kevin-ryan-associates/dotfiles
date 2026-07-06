#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# dotfiles Linux install script
# Native Ubuntu install path. Dispatched from bootstrap.sh.
# Uses apt for the base + Docker, and Linuxbrew for the shared UX tooling list.
# =============================================================================

if [ "$(uname -s)" != Linux ]; then
  echo "ERROR: install-linux.sh must run on Linux." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing apt base (Homebrew prereqs + sudo + zsh)..."
sudo apt-get update
sudo apt-get install -y zsh git curl file ca-certificates build-essential procps fontconfig unzip

echo "==> Checking for Homebrew..."
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Installing from https://brew.sh ..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Homebrew's installer does NOT put brew on PATH for the current shell.
  # Source it in-process so the `brew install` lines below work this run.
  # Paths: /home/linuxbrew/.linuxbrew (system), $HOME/.linuxbrew (user).
  if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then
    eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
  else
    echo "ERROR: Homebrew install completed but brew not found at expected path." >&2
    exit 1
  fi
fi

echo "==> Ensuring brew shellenv is in ~/.zprofile..."
ZPROFILE="$HOME/.zprofile"
BREW_PREFIX="$(brew --prefix)"
SHELLENV_CMD="eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\""
touch "$ZPROFILE" 2>/dev/null || true
if ! grep -qF 'brew shellenv' "$ZPROFILE" 2>/dev/null; then
  printf '\n# Added by dotfiles install-linux.sh — brew on PATH for interactive shells\n%s\n' "$SHELLENV_CMD" >> "$ZPROFILE"
  echo "  added shellenv line to $ZPROFILE"
else
  echo "  shellenv already present in $ZPROFILE"
fi

# Install the cross-platform brew formula list.
source "$SCRIPT_DIR/brew-packages.sh"
install_brew_packages

echo "==> Installing Docker (native Linux runtime)..."
# Colima is macOS-only. On Linux, Docker runs natively.
# docker-compose-v2 provides the `docker compose` plugin; resolves natively
# (no ~/.docker/config.json cliPluginsExtraDirs wiring needed, unlike macOS Colima).
sudo apt-get install -y docker.io docker-compose-v2
sudo usermod -aG docker "$(id -un)" 2>/dev/null || true
echo "  Note: re-login (or 'newgrp docker') to use docker without sudo."

echo "==> Installing 1Password CLI..."
# 1password-cli is a cask on both macOS and Linux. On Linux, the cask downloads
# the `op` binary and unzips it (requires the `unzip` apt package, installed above).
brew install --cask 1password-cli || true

echo "==> Installing Neovim and dependencies..."
brew install neovim node npm ripgrep

echo "==> Installing terminal emulator..."
# Ghostty's Linux build is not reliably on Linuxbrew. Attempt brew, then
# fall back to a manual hint. Real-world ghostty is verified separately.
brew install ghostty 2>/dev/null || \
  echo "  Ghostty: install manually from https://ghostty.org/download (Linux .deb)"

echo "==> Installing Nerd Font (MesloLGS)..."
# Casks install to ~/Library/Fonts (macOS-only). On Linux, download the .ttf
# to ~/.local/share/fonts and refresh the fontconfig cache.
mkdir -p "$HOME/.local/share/fonts"
FONT_URL="https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
if curl -fsSL -o "$HOME/.local/share/fonts/MesloLGSNerdFont-Regular.ttf" "$FONT_URL"; then
  fc-cache -f "$HOME/.local/share/fonts" 2>/dev/null || true
else
  echo "  Font download failed; install MesloLGS Nerd Font manually"
fi

echo "==> Installing OpenCode..."
curl -fsSL https://raw.githubusercontent.com/anomalyco/opencode/master/install -o /tmp/opencode-install.sh
bash /tmp/opencode-install.sh --no-modify-path
rm -f /tmp/opencode-install.sh

echo "==> Installing OpenSpec (spec-driven dev framework)..."
npm install -g @fission-ai/openspec@latest

echo "==> Building bat theme cache..."
bat cache --build

echo "==> Stowing dotfiles packages..."
cd "$SCRIPT_DIR"
stow -R bat btop git herdr htop lazygit lazydocker zsh starship nvim opencode ghostty

# On Linux, zsh isn't the default shell (Ubuntu ships bash). Run chsh to make
# zsh the login shell. On a real machine, sudo prompts for the user's password
# (expected). In a container with passwordless sudo, it succeeds silently.
if [ "${SHELL:-}" != "$(command -v zsh)" ]; then
  echo ""
  echo "==> Setting default shell to zsh..."
  sudo chsh -s "$(command -v zsh)" "$(id -un)" 2>/dev/null || \
    echo "  chsh needs your password; run manually: chsh -s $(command -v zsh)"
fi

echo ""
echo "========================================"
echo "  Installation complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Open a new terminal window"
echo "  2. Zinit will auto-install on first run (~10-30s)"
echo "  3. Run 'nvim' to install AstroNvim plugins"
echo "  4. Run 'opencode auth' to authenticate"
echo "  5. Docker is installed — start the daemon: sudo systemctl start docker"
echo ""
