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
brew install stow starship eza bat fzf zoxide fd git-delta lazygit lazydocker

echo "==> Installing CLI utilities..."
brew install jq yq htop tree btop herdr

echo "==> Installing Git platform CLIs..."
brew install gh glab

echo "==> Installing Kubernetes tooling..."
brew install kubectl helm k9s

echo "==> Installing build tools..."
brew install cmake

echo "==> Installing Colima (Docker runtime without GUI)..."
brew install colima docker docker-compose

echo "==> Configuring Docker CLI plugins..."
mkdir -p ~/.docker
CONFIG_FILE="$HOME/.docker/config.json"
if [ ! -f "$CONFIG_FILE" ]; then
  echo '{}' > "$CONFIG_FILE"
fi
PLUGINS_DIR="$(brew --prefix)/lib/docker/cli-plugins"
tmp=$(mktemp)
jq --arg dir "$PLUGINS_DIR" '
  if (.cliPluginsExtraDirs // []) | index($dir) then . else
    .cliPluginsExtraDirs = ((.cliPluginsExtraDirs // []) + [$dir])
  end
  | if .credsStore == "desktop" then del(.credsStore) else . end
' "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"

echo "==> Cleaning up stale Docker Desktop symlinks (if present)..."
# Self-heal: machines that previously had Docker Desktop may have broken symlinks
# pointing at the removed .app. Fresh machines have none, so this is a no-op there.
# Only touch broken symlinks; leave working brew links alone.
for link in /usr/local/bin/docker-compose \
            /usr/local/bin/docker-credential-desktop \
            /usr/local/bin/docker-credential-osxkeychain; do
  if [ -L "$link" ] && [ ! -e "$link" ]; then
    sudo rm -f "$link" 2>/dev/null || \
      echo "  skipping $link (no sudo TTY; run manually: sudo rm $link)"
  fi
done

echo "==> Installing 1Password CLI..."
brew install --cask 1password-cli || true

echo "==> Installing terminal emulator..."
brew install --cask ghostty || true

echo "==> Installing Neovim and dependencies..."
brew install neovim node npm ripgrep
brew install --cask font-meslo-lg-nerd-font

echo "==> Installing OpenCode..."
curl -fsSL https://raw.githubusercontent.com/anomalyco/opencode/master/install -o /tmp/opencode-install.sh
bash /tmp/opencode-install.sh --no-modify-path
rm -f /tmp/opencode-install.sh

echo "==> Installing OpenSpec (spec-driven dev framework)..."
npm install -g @fission-ai/openspec@latest

echo "==> Building bat theme cache..."
bat cache --build

echo "==> Stowing dotfiles packages..."
cd "$(dirname "$0")"
stow -R bat btop git herdr htop lazygit lazydocker zsh starship nvim opencode ghostty

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
echo "  5. Run 'colima start' to launch the Docker runtime"
echo ""
