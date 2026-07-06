#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# dotfiles bootstrap script — public one-liner entry point
# Clones (or pulls) the repo into ~/dotfiles, then execs the native install
# script for this OS (install-mac.sh or install-linux.sh).
# Does NOT install tooling itself; that is the install script's job.
#
#   curl -fsSL https://raw.githubusercontent.com/kevin-ryan-associates/dotfiles/main/bootstrap.sh | bash
# =============================================================================

REPO_URL="https://github.com/kevin-ryan-associates/dotfiles.git"
CLONE_DIR="$HOME/dotfiles"
RAW_URL="https://raw.githubusercontent.com/kevin-ryan-associates/dotfiles/main/bootstrap.sh"

# git comes with Xcode Command Line Tools, which Homebrew also requires.
# Fail early with a clear message rather than letting `git clone` trigger a
# system dialog mid-script.
if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git not found." >&2
  case "$(uname -s)" in
    Darwin)
      echo "Install Xcode Command Line Tools first: xcode-select --install" >&2 ;;
    Linux)
      echo "Install git first: sudo apt-get update && sudo apt-get install -y git" >&2 ;;
  esac
  echo "Then re-run: curl -fsSL $RAW_URL | bash" >&2
  exit 1
fi

if [ -d "$CLONE_DIR/.git" ]; then
  echo "==> $CLONE_DIR already cloned; pulling latest..."
  # --ff-only: refuse to synthesize a merge commit. If the machine has local
  # divergent commits, fail loudly with git's own error so the user resolves
  # manually. Matches README's "regular git divergence" contract.
  git -C "$CLONE_DIR" pull --ff-only
elif [ -e "$CLONE_DIR" ]; then
  echo "ERROR: $CLONE_DIR exists but is not a git clone of this repo." >&2
  echo "       Move or remove it, then re-run: curl -fsSL $RAW_URL | bash" >&2
  exit 1
else
  echo "==> Cloning dotfiles into $CLONE_DIR..."
  git clone "$REPO_URL" "$CLONE_DIR"
fi

echo "==> Detecting OS and handing off to native install script..."
# exec: replace this process so the native install script's exit code is the
# caller's exit code. Without exec, a piped `curl | bash` would report
# bootstrap's exit status, masking install failures.
case "$(uname -s)" in
  Darwin)
    exec bash "$CLONE_DIR/install-mac.sh" ;;
  Linux)
    exec bash "$CLONE_DIR/install-linux.sh" ;;
  *)
    echo "ERROR: Unsupported OS: $(uname -s)" >&2
    echo "       Supported platforms: macOS (Darwin), Ubuntu (Linux)." >&2
    exit 1 ;;
esac
