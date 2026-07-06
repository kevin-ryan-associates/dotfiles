# Test harness

Docker-based test for the **Ubuntu 24.04** install path. Spins up a container, runs the install end-to-end, and asserts the converged state.

## Quick start

```bash
# Default: test install-linux.sh against your local working tree (fast iteration)
bash test/run.sh

# Test the real public one-liner against main (release verification; requires test/ on main)
bash test/run.sh published
```

If the build succeeds, the install converges and every assertion passes. If any step fails, the Docker build stops there — the failure point is the test report.

## The two flavors

| Flavor | What it runs | When to use |
|---|---|---|
| `local` | `COPY`s the repo, runs `install-linux.sh` directly | During development — tests your uncommitted changes immediately |
| `published` | `curl \| bash` the public `bootstrap.sh` against `main` | Release verification — tests the real public contract end-to-end (clone/pull + install-linux.sh) |

The `local` flavor skips `bootstrap.sh`'s clone/pull logic (the repo is `COPY`'d in without `.git`, so that logic is moot) and exercises `install-linux.sh` directly. The `published` flavor exercises the full `bootstrap.sh → install-linux.sh` chain.

## What this tests

The container runs as a **non-root user** (Homebrew refuses root) with passwordless `sudo` (so apt/chsh work non-interactively). After the install, `assertions.sh` checks:

1. `bootstrap.sh` / `install-linux.sh` exit 0 (the build reaching the assertions step means this passed).
2. Homebrew on PATH; `~/.zprofile` contains the `brew shellenv` line.
3. Every brew formula resolves on PATH (`eza`, `bat`, `fzf`, `zoxide`, `fd`, `delta`, `lazygit`, `lazydocker`, `starship`, `nvim`, `node`, `rg`, `jq`, `yq`, `gh`, `glab`, `kubectl`, `helm`, `k9s`, `cmake`, `stow`, `tree`, `htop`, `btop`, `herdr`).
4. 1Password CLI (`op --version`).
5. OpenCode + OpenSpec (`opencode --version`, `openspec --version`).
6. Docker **binaries** resolve (`docker --version`, `docker compose version`) — see "What this does NOT test".
7. Stow symlinks resolve into the repo (`~/.zshrc`, `~/.config/starship.toml`, `~/.config/nvim/init.lua`).
8. Stow is idempotent (re-run `stow -R` with no conflicts).
9. `.zshrc` sources cleanly under `zsh -i` (zinit clones plugins on first run — slow + network).
10. AstroNvim config parses under `nvim --headless` (Lazy installs plugins on first run — slow + network).
11. `install-linux.sh` is idempotent (second run exits 0).
12. Nerd Font installed (`fc-list | grep -i meslo`).
13. Ghostty `.deb` installed (install only — cannot launch headless).

## What this does NOT test

These are deliberate omissions, not gaps:

- **Real Docker daemon (`docker ps`).** An unprivileged container cannot run `dockerd`. The harness asserts the binaries resolve and the compose plugin wires up — that's the install path. To verify the daemon actually runs, test manually on a real Ubuntu VM (e.g. Multipass) or a GitHub Actions `ubuntu-latest` runner, where `dockerd` is available natively.
- **Ghostty launch.** Ghostty is a GUI terminal; a headless container cannot open it. The harness only asserts the `.deb` installs.
- **Herdr pane shells.** Herdr uses ghostty's terminal backend for pane emulation; in a headless container, pane creation fails with `ghostty error -2` and falls back to `/bin/sh`. The `default_shell`/`shell_mode` config is correct but can only be verified on a real machine with ghostty available.
- **`chsh` password flow.** PAM inside a container differs from a real Ubuntu login session. The harness uses `sudo chsh` (passwordless) as a container-specific accommodation; the real interactive `chsh` flow is verified manually.
- **macOS.** Docker cannot run macOS. The macOS path is verified manually on a real Mac (see the v1.0.0 verification in the commit history).

## Iteration tip (fast loop without re-downloading Homebrew)

Full rebuilds are slow (~10-20 min) because Homebrew + ~30 formulae install each time. For fast iteration on `install-linux.sh` changes, use an interactive container with a persisted home volume:

```bash
# One-time: start a dev container with a persisted home dir
docker run -it -v dotfiles-home:/home/dotfiles --name dotfiles-dev ubuntu:24.04 bash

# Inside it: install the apt base once, then iterate on install-linux.sh
sudo apt update && sudo apt install -y sudo zsh git curl file ca-certificates build-essential procps
# (create the non-root user as in the Dockerfile, or just run as root for dev)
# Then re-run install-linux.sh repeatedly — Homebrew is already in the volume, so only your changes re-run
```

The `Dockerfile` (reproducible build) is the canonical test; the interactive container is the debug harness.

## Notes

- `test/` is **not** a Stow package. It is never added to the `stow -R` line in `install-linux.sh`. Same for the repo-root `.dockerignore` (a Docker build artifact, not config).
- The `published` flavor requires `test/` to exist on `main` already (it runs `assertions.sh` from the freshly cloned repo). Run it only after pushing the harness.
- Ubuntu version is parameterized: `docker build --build-arg UBUNTU_VERSION=22.04 ...` to test against 22.04 (not currently in the default matrix).
