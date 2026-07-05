#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# dotfiles install script
# Installs all tooling required by the zsh + starship configuration
# =============================================================================

echo "==> Checking for Homebrew..."
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Please install it first: https://brew.sh"
  exit 1
fi

echo "==> Installing Homebrew dependencies for Zsh ecosystem..."
brew install stow starship eza bat fzf zoxide fd git-delta lazygit

echo "==> Installing CLI utilities..."
brew install jq yq htop tree btop herdr

echo "==> Installing Git platform CLIs..."
brew install gh glab

echo "==> Installing Kubernetes tooling..."
brew install kubectl helm k9s

echo "==> Installing build tools..."
brew install cmake

echo "==> Installing Docker Desktop..."
brew install --cask docker

echo "==> Installing 1Password CLI..."
brew install --cask 1password-cli

echo "==> Installing terminal emulator..."
brew install --cask ghostty

echo "==> Installing Neovim and dependencies..."
brew install neovim node npm ripgrep
brew install --cask font-meslo-lg-nerd-font

echo "==> Installing OpenCode..."
curl -fsSL https://raw.githubusercontent.com/anomalyco/opencode/master/install -o /tmp/opencode-install.sh
bash /tmp/opencode-install.sh --no-modify-path
rm -f /tmp/opencode-install.sh

echo "==> Building bat theme cache..."
bat cache --build

echo "==> Stowing dotfiles packages..."
cd "$(dirname "$0")"
stow -R bat btop git herdr lazygit zsh starship nvim opencode ghostty

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
echo ""
