# Shared Homebrew formula list used by both install-mac.sh and install-linux.sh.
# This file is sourced, not executed directly; it defines install_brew_packages().
# Keeping the tool inventory in one place prevents drift between platforms.

install_brew_packages() {
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
}
