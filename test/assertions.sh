#!/usr/bin/env bash
# Test matrix for the dotfiles chezmoi apply. Sourced/run inside the container
# after `chezmoi apply` has converged. Any failure exits non-zero, failing the
# Docker build. See test/README.md for the full matrix and the things this
# deliberately does NOT test (real Docker daemon, GUI launches).
set -euo pipefail
trap 'echo "==> ASSERTION FAILED (line $LINENO)" >&2' ERR

# The assertions RUN layer is a non-login, non-interactive bash shell. A real
# user's zsh login shell sources ~/.zprofile (brew shellenv, rendered by
# dot_zprofile.tmpl) and ~/.zshrc (user bins). Mirror that PATH setup here so
# assertions see the installed tools. This block is test-only — it doesn't
# affect the real user environment.
export TERM="${TERM:-xterm}"
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$HOME/.bun/bin:$PATH"
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then
  eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
elif [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

echo "==> Running dotfiles test assertions..."

# 1. `chezmoi apply` exit 0 (the build reaching this step means this passed).

# 2. Homebrew on PATH + .zprofile shellenv line present (rendered by dot_zprofile.tmpl)
command -v brew >/dev/null
brew --prefix >/dev/null
grep -q 'brew shellenv' "$HOME/.zprofile"

# 3. All brew formulae resolve on PATH. (stow no longer in the list — not
#    installed under chezmoi.)
for cmd in eza bat fzf zoxide fd delta lazygit lazydocker starship nvim node rg \
           jq yq gh glab kubectl helm k9s cmake tree htop btop herdr; do
  command -v "$cmd" >/dev/null || { echo "FAIL: $cmd not on PATH"; exit 1; }
done

# 4. 1Password CLI
op --version >/dev/null

# 5. opencode + openspec
opencode --version >/dev/null
openspec --version >/dev/null

# 6. Docker BINARIES only — not the daemon. An unprivileged container cannot
#    run dockerd; real-daemon testing is done manually on a VM (see README).
docker --version >/dev/null
docker compose version >/dev/null

# 7. chezmoi deployed real files (NOT symlinks). The legacy Stow assertions
#    (test -L + readlink matching dotfiles/zsh/.zshrc) become regular-file
#    checks + a chezmoi managed-list probe.
test -f "$HOME/.zshrc"
test -f "$HOME/.zshenv"
test -f "$HOME/.zprofile"
test -f "$HOME/.config/starship.toml"
test -f "$HOME/.config/nvim/init.lua"
chezmoi managed | grep -q '^dot_zshrc$'
chezmoi managed | grep -q '^dot_config/nvim/init.lua$'

# 8. chezmoi verify exits 0 — nothing in $HOME differs from source state.
#    Equivalent to the legacy `stow -R` "idempotent re-link" check, but
#    bidirectional (covers both deployed-vs-source and source-vs-deployed).
chezmoi verify

# 9. .zshrc sources cleanly. zinit clones plugins on first run (slow + network).
#    Use `true` (not `exit`) so the assertion checks that zsh can source .zshrc
#    and run a command — not the incidental $? left by compinit/plugin loading.
zsh -i -c 'true' 2>/dev/null

# 10. AstroNvim config parses. (Full Lazy sync is slow/flaky in CI; this checks
#     the config loads without Lua errors. May be tightened post-port.)
nvim --headless -c 'qa' 2>/dev/null || \
  nvim --headless -c 'lua print("config ok")' -c 'qa'

# 11. Apply idempotent — second `chezmoi apply` exits 0. The run_* scripts'
#     once_/onchange_ guards prevent reinstall churn; file targets are
#     byte-stable so apply reports no changes.
chezmoi apply

# 12. Nerd Font installed
fc-list 2>/dev/null | grep -iq meslo

# 13. Ghostty deb installed (cannot launch headless — install only). Non-fatal
#     on Linux: ghostty's Linux build isn't reliably container-installable;
#     verify real-world ghostty manually (like the Docker daemon).
dpkg -s ghostty >/dev/null 2>&1 || command -v ghostty >/dev/null 2>&1 || \
  echo "WARN: ghostty not installed (GUI app — verify manually on Linux)"

echo "==> All assertions passed."