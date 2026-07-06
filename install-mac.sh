#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# dotfiles macOS install script
# Native Darwin install path. Dispatched from bootstrap.sh.
# =============================================================================

if [ "$(uname -s)" != Darwin ]; then
  echo "ERROR: install-mac.sh must run on macOS (Darwin)." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Checking for Homebrew..."
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Installing from https://brew.sh ..."
  echo "(Requires Xcode Command Line Tools — a GUI dialog may appear for consent.)"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Homebrew's installer does NOT put brew on PATH for the current shell.
  # Source it in-process so the `brew install` lines below work this run.
  # Paths: /opt/homebrew (Apple Silicon), /usr/local (Intel).
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
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
  printf '\n# Added by dotfiles install-mac.sh — brew on PATH for interactive shells\n%s\n' "$SHELLENV_CMD" >> "$ZPROFILE"
  echo "  added shellenv line to $ZPROFILE"
else
  echo "  shellenv already present in $ZPROFILE"
fi

# Install the cross-platform brew formula list.
source "$SCRIPT_DIR/brew-packages.sh"
install_brew_packages

echo "==> Installing 1Password CLI..."
brew install --cask 1password-cli || true

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

echo "==> Installing Neovim and dependencies..."
brew install neovim node npm ripgrep

echo "==> Installing terminal emulator..."
brew install --cask ghostty || true
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
cd "$SCRIPT_DIR"
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
