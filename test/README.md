# Test harness

Docker-based test for the **Ubuntu 24.04** chezmoi apply path. Spins up a container, runs the chezmoi apply end-to-end, and asserts the converged state.

## Quick start

```bash
# Default: test the chezmoi apply against your local working tree (fast iteration)
bash test/run.sh

# Test the real public one-liner against main (release verification; requires test/ on main)
bash test/run.sh published
```

If the build succeeds, the apply converges and every assertion passes. If any step fails, the Docker build stops there — the failure point is the test report.

## The two flavors

| Flavor | What it runs | When to use |
|---|---|---|
| `local` | `COPY`s the repo, runs `chezmoi init --source=... && chezmoi apply` directly | During development — tests your uncommitted changes immediately |
| `published` | `chezmoi init --apply kevin-ryan-associates/dotfiles` (the public one-liner against `main`) | Release verification — tests the real public contract end-to-end (clone + apply) |

The `local` flavor skips the remote-clone half of `chezmoi init` (the repo is `COPY`'d in without `.git`; we point chezmoi at it directly via `--source`) and exercises the apply path directly. The `published` flavor exercises the full `chezmoi init --apply <repo>` chain.

## What this tests

The container runs as a **non-root user** (Homebrew refuses root) with passwordless `sudo` (so apt/chsh work non-interactively). After the apply, `assertions.sh` checks:

1. `chezmoi apply` exit 0 (the build reaching the assertions step means this passed).
2. Homebrew on PATH; `~/.zprofile` contains the `brew shellenv` line — rendered by `dot_zprofile.tmpl`'s `stat` probe of `/home/linuxbrew/.linuxbrew/bin/brew` (or `~/.linuxbrew/bin/brew`).
3. Every brew formula resolves on PATH (`eza`, `bat`, `fzf`, `zoxide`, `fd`, `delta`, `lazygit`, `lazydocker`, `starship`, `nvim`, `node`, `rg`, `jq`, `yq`, `gh`, `glab`, `kubectl`, `helm`, `k9s`, `cmake`, `tree`, `htop`, `btop`, `herdr`).
4. 1Password CLI (`op --version`).
5. OpenCode + OpenSpec (`opencode --version`, `openspec --version`).
6. Docker **binaries** resolve (`docker --version`, `docker compose version`) — see "What this does NOT test".
7. chezmoi deployed real files (not symlinks): `~/.zshrc`, `~/.zshenv`, `~/.zprofile`, `~/.config/starship.toml`, `~/.config/nvim/init.lua`; and `chezmoi managed` lists the corresponding source entries.
8. `chezmoi verify` exits 0 — nothing in `$HOME` differs from source state. (Bidirectional idempotency check — replaces the legacy `stow -R` re-link assertion.)
9. `.zshrc` sources cleanly under `zsh -i` (zinit clones plugins on first run — slow + network).
10. AstroNvim config parses under `nvim --headless` (Lazy installs plugins on first run — slow + network).
11. Idempotent apply: second `chezmoi apply` exits 0. The `run_*` scripts' `once_`/`onchange_` guards prevent reinstall churn; file targets are byte-stable.
12. Nerd Font installed (`fc-list | grep -i meslo`).
13. Ghostty `.deb` installed (install only — cannot launch headless).

## What this does NOT test

These are deliberate omissions, not gaps:

- **Real Docker daemon (`docker ps`).** An unprivileged container cannot run `dockerd`. The harness asserts the binaries resolve and the compose plugin wires up — that's the apply path. To verify the daemon actually runs, test manually on a real Ubuntu VM (e.g. Multipass) or a GitHub Actions `ubuntu-latest` runner, where `dockerd` is available natively.
- **Ghostty launch.** Ghostty is a GUI terminal; a headless container cannot open it. The harness only asserts the `.deb` installs.
- **Herdr pane shells.** Herdr uses ghostty's terminal backend for pane emulation; in a headless container, pane creation fails with `ghostty error -2` and falls back to `/bin/sh`. The `default_shell`/`shell_mode` config is correct but can only be verified on a real machine with ghostty available.
- **`chsh` password flow.** PAM inside a container differs from a real Ubuntu login session. The harness runs under `sudo chsh` (passwordless) as a container-specific accommodation in the `run_once_after_set-default-shell` script; the real interactive `chsh` flow is verified manually.
- **macOS.** Docker cannot run macOS. The macOS path is verified manually on a real Mac.

## Iteration tip (fast loop without re-downloading Homebrew)

Full rebuilds are slow (~10-20 min) because Homebrew + ~30 formulae install each time. For fast iteration on the apply path, use an interactive container with a persisted home volume:

```bash
# One-time: start a dev container with a persisted home dir
docker run -it -v dotfiles-home:/home/dotfiles --name dotfiles-dev ubuntu:24.04 bash

# Inside it: install the apt base + chezmoi once, then iterate on the apply
sudo apt update && sudo apt install -y sudo curl ca-certificates gnupg git
sh -c "$(curl -fsSL https://chezmoi.io/get)" -- -b /usr/local/bin
# (create the non-root user as in the Dockerfile, or just run as root for dev)
# Then re-run `chezmoi apply` repeatedly — Homebrew is already in the volume, so only your changes re-run
```

The `Dockerfile` (reproducible build) is the canonical test; the interactive container is the debug harness.

## Notes

- `test/` is **not** a chezmoi deployable entry. It is listed in `.chezmoiignore` so `chezmoi apply` never writes it into `$HOME`. Same for the repo-root `.dockerignore` (a Docker build artifact, not config).
- The `published` flavor requires `test/` to exist on `main` already (it runs `assertions.sh` from the freshly cloned source). Run it only after pushing the harness.
- Ubuntu version is parameterized: `docker build --build-arg UBUNTU_VERSION=22.04 ...` to test against 22.04 (not currently in the default matrix).