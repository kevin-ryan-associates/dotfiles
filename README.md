# dotfiles

Personal configuration files, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Currently tracking:

- **`zsh`** — Zsh shell configuration with Zinit plugin manager, Starship prompt, and comprehensive aliases
- **`starship`** — Starship prompt configuration with Tokyo Night palette
- **`nvim`** — [AstroNvim](https://astronvim.com/) Neovim setup with Tokyo Night colorscheme
- **`opencode`** — [OpenCode](https://github.com/opencode-ai/opencode) CLI AI coding agent with Tokyo Night theme
- **`ghostty`** — [Ghostty](https://ghostty.org/) terminal emulator with Tokyo Night theme
- **`bat`** — Syntax highlighting with Tokyo Night theme
- **`btop`** — Resource monitor with Tokyo Night theme
- **`herdr`** — Terminal workspace multiplexer with Tokyo Night theme
- **`htop`** — Process viewer with Black Night color scheme (closest to Tokyo Night in htop)
- **`lazygit`** — TUI git client with Tokyo Night colors
- **`git`** — Git config with Tokyo Night delta diff colors
- **`lazydocker`** — TUI Docker client with Tokyo Night colors
- **`colima`** — Docker runtime (replaces Docker Desktop, no GUI)

## Why this exists

Config files have a habit of drifting. You tweak your Neovim keymaps on one machine, forget what you changed, then spend twenty minutes on the next machine wondering why muscle memory doesn't work. This repo is the single source of truth for that config, version-controlled so every change is a deliberate, reversible checkpoint.

### Why not just `git init` in `$HOME`?

Tempting, but a footgun. Turning your home directory into a git repo means git is aware of *everything* under it — every cache, every secret, every stray token. One careless `git add -A` and your SSH keys, cloud credentials, or password-manager session files are in a commit. Managing the recursive ignores to prevent that is its own special misery.

### Why Stow?

Stow keeps the repo as an ordinary directory (`~/dotfiles`) that lives *outside* `$HOME`-as-a-repo territory, and uses **symlinks** to put each config file where its application expects to find it. That gives three things:

- **No copy step.** The deployed file and the repo file are the same file (same inode, two names). Edit either, and you've edited the one real file.
- **Explicit tracking.** Only what you deliberately put into a package and `stow` gets linked. Nothing is tracked by accident.
- **Zero dependencies beyond Stow itself.** No templating engine, no daemon, no runtime. It's just symlinks.

## How it works

Each top-level folder in this repo is a Stow **package**. The directory structure *inside* a package mirrors where its files should land relative to `$HOME`:

```
~/dotfiles/
├── zsh/
│   ├── .zshrc                      → ~/.zshrc
│   ├── .zshenv                     → ~/.zshenv
│   └── .config/ainative/
│       └── banner.sh               → ~/.config/ainative/banner.sh
├── starship/
│   └── .config/
│       └── starship.toml           → ~/.config/starship.toml
├── nvim/
│   └── .config/
│       └── nvim/                   → ~/.config/nvim/
│           ├── init.lua
│           └── lua/...
├── bat/
│   └── .config/
│       └── bat/
│           ├── config               → ~/.config/bat/config
│           └── themes/
│               └── tokyonight_moon.tmTheme
├── btop/
│   └── .config/
│       └── btop/
│           └── btop.conf            → ~/.config/btop/btop.conf
├── herdr/
│   └── .config/
│       └── herdr/
│           └── config.toml          → ~/.config/herdr/config.toml
├── htop/
│   └── .config/
│       └── htop/
│           └── htoprc               → ~/.config/htop/htoprc
├── lazygit/
│   └── .config/
│       └── lazygit/
│           └── config.yml           → ~/.config/lazygit/config.yml
│   └── Library/
│       └── Application Support/
│           └── lazygit/
│               └── config.yml       → ~/Library/Application Support/lazygit/config.yml
├── lazydocker/
│   └── .config/
│       └── lazydocker/
│           └── config.yml           → ~/.config/lazydocker/config.yml
│   └── Library/
│       └── Application Support/
│           └── lazydocker/
│               └── config.yml       → ~/Library/Application Support/lazydocker/config.yml
├── git/
│   └── .config/
│       └── git/
│           └── config               → ~/.config/git/config
├── opencode/
│   └── .config/
│       └── opencode/               → ~/.config/opencode/
│           ├── opencode.jsonc
│           ├── tui.json
│           └── themes/
│               └── tokyonight-moon.json  → ~/.config/opencode/themes/tokyonight-moon.json
└── ghostty/
    └── .config/
        └── ghostty/                → ~/.config/ghostty/
            └── config
```

When you run `stow zsh` from inside `~/dotfiles`, Stow treats the `zsh/` package folder as transparent and replicates everything beneath it into your home directory as symlinks.

> **The one rule that matters:** the path *inside* each package must mirror the target path under `$HOME`. Get that nesting right and everything else just works. If files ever link to the wrong place, it's almost always a package's internal structure not matching the target layout.

## Zsh Configuration

### Plugin Manager: Zinit

[Zinit](https://github.com/zdharma-continuum/zinit) is a flexible and fast Zsh plugin manager. On the first interactive shell startup, it automatically clones itself to `~/.local/share/zinit/` if it isn't already present. There is no separate install step.

**How turbo loading works:**

Normally, Zsh loads plugins immediately during shell startup, which adds latency. Zinit's `wait lucid` directive **defers** plugin loading until *after* the prompt appears. This means your shell is usable instantly, and plugins load quietly in the background. The trade-off is a ~100ms gap where completions aren't yet available — practically unnoticeable.

**Plugins loaded:**

| Plugin | What it does | Load mode |
|---|---|---|
| `fast-syntax-highlighting` | Syntax highlighting as you type | Turbo (`wait`) |
| `zsh-autosuggestions` | Suggests completions from history | Turbo (`wait`, starts on load) |
| `zsh-completions` | Additional completion definitions for many tools | Turbo (`wait`) |
| `fzf-tab` | Replaces Zsh's default tab completion with an fzf interface | Turbo (`wait`) |

### Prompt: Starship

[Starship](https://starship.rs/) is a minimal, blazing-fast, and infinitely customizable prompt written in Rust. It displays:

- OS and username
- Current directory (with icon substitutions for common folders)
- Git branch and status
- Language versions (Python, Node.js, Rust, Go, Lua)
- Docker and Kubernetes contexts
- Execution time for slow commands
- Exit status indicator

The custom **tokyo_night** palette uses Tokyo Night Moon colors (cyan, green, magenta, amber) on dark backgrounds to match the ainative banner.

### Key Features

| Feature | Description |
|---|---|
| **History** | 100,000 entries, shared across sessions, ignores duplicates and spaces |
| **Auto-cd** | Type a directory name to `cd` into it without typing `cd` |
| **Completion** | Case-insensitive matching, git-aware, `fzf` preview for directories |
| **fzf-tab** | Preview directories with `eza` when tab-completing `cd` or `zoxide` |
| **zoxide** | Smart `cd` command that learns your habits — use `z` instead of `cd` |

### Aliases

| Alias | Command | Description |
|---|---|---|
| `ls` | `eza --icons --group-directories-first` | List files |
| `ll` | `eza -l --icons --git --group-directories-first` | Long list |
| `la` | `eza -la --icons --git --group-directories-first` | All files |
| `lt` | `eza --tree --icons --level=2` | Tree view |
| `cat` | `bat --paging=never` | Syntax-highlighted cat |
| `less` | `bat --paging=always` | Syntax-highlighted less |
| `diff` | `delta` | Beautiful diffs |
| `g` | `git` | Short git |
| `lg` | `lazygit` | TUI git client |
| `v` / `vi` / `vim` | `nvim` | Neovim |
| `k` | `kubectl` | Kubernetes |
| `d` | `docker` | Docker |
| `dc` | `docker compose` | Docker Compose |
| `tf` | `terraform` | Terraform |
| `oc` | `opencode` | OpenCode AI agent |
| `cp` / `mv` / `rm` | `*-i` | Interactive (safer) defaults |
| `reload` | `exec zsh` | Quick shell restart |

### Installed CLI tools

These tools are installed by `install.sh` and integrate with the Zsh configuration:

| Tool | Purpose | Zsh integration |
|---|---|---|
| `eza` | Modern `ls` replacement | Aliased to `ls`, `ll`, `la`, `lt` |
| `bat` | Syntax-highlighted `cat`/`less` | Aliased to `cat`, `less`; `BAT_THEME` set |
| `fzf` | Fuzzy finder | Tab completion, file search, directory preview |
| `zoxide` | Smart `cd` | `z` command replaces `cd`; learns habits |
| `fd` | Fast `find` replacement | Powers `fzf` file/directory listing |
| `git-delta` | Beautiful diffs | Aliased to `diff`; `GIT_PAGER` |
| `lazygit` | TUI git client | Aliased to `lg` |
| `ripgrep` | Fast grep | Used by Neovim/telescope |
| `jq` | JSON processor | Command-line JSON queries |
| `yq` | YAML processor | Command-line YAML queries |
| `gh` | GitHub CLI | PRs, issues, `gh copilot` |
| `glab` | GitLab CLI | PRs, issues, pipelines |
| `htop` | Interactive process viewer | Better `top` |
| `btop` | Resource monitor | TUI system monitor with graphs |
| `tree` | Directory tree listing | Hierarchical directory views |
| `1password-cli` | 1Password secrets | Fetch secrets via `op read` in `.zshrc` |
| `herdr` | Agent multiplexer | Terminal workspace manager |
| `kubectl` | Kubernetes CLI | Aliased to `k` |
| `helm` | Kubernetes package manager | Native command |
| `k9s` | TUI Kubernetes cluster manager | Native command |
| `cmake` | Build system generator | Required for Neovim plugin builds |
| `colima` | Docker runtime (VM-based) | Replaces Docker Desktop; `colima start/stop` |
| `openspec` | Spec-driven dev framework | Native opencode slash commands (`/opsx:propose`, etc.); telemetry opt-out via `OPENSPEC_TELEMETRY=0` |

### Banner

An interactive shell displays a startup banner showing the **AI NATIVE** ASCII art and tool versions (nvim, zsh, node, python). It is shown **once per session** and automatically skipped inside Neovim terminals.

**Disable the banner:**
```bash
export AINATIVE_NO_BANNER=1
```

## Tokyo Night Theme

This dotfiles stack uses the **[Tokyo Night](https://tokyonight.org/)** theme across all tools for a consistent, cohesive terminal experience. Based on the **`moon`** variant from [folke/tokyonight.nvim](https://github.com/folke/tokyonight.nvim).

| Tool | Theme Integration |
|---|---|
| **Neovim** | `tokyonight.nvim` plugin with `style = "moon"` |
| **Ghostty** | Built-in `theme = TokyoNight Moon` |
| **opencode** | Custom `tokyonight-moon` theme (Moon palette guaranteed) |
| **Starship** | Custom `tokyo_night` palette (Moon colors) |
| **fzf** | Tokyo Night Moon color exports |
| **bat** | `tokyonight_moon.tmTheme` syntax highlighting |
| **btop** | Built-in `tokyo-night` theme |
| **herdr** | Built-in `tokyo-night` theme |
| **htop** | Black Night color scheme (closest available) |
| **lazygit** | Tokyo Night Moon colors in `config.yml` |
| **lazydocker** | Tokyo Night Moon best-effort colors |
| **delta** | Tokyo Night Moon diff colors in `~/.config/git/config` |
| **Zsh banner** | ANSI colors mapped to Tokyo Night Moon palette |

## Neovim

This repo uses [AstroNvim](https://astronvim.com/) as the base configuration. The following customizations are layered on top:

### Symbol search (Aerial)

[Aerial](https://github.com/stevearc/aerial.nvim) provides a symbol outline / code navigation sidebar. It ships with AstroNvim by default.

A custom **Tree-sitter query** (`queries/dockerfile/aerial.scm`) adds Dockerfile symbol support to Aerial. When you open a `Dockerfile`, the symbol tree shows:

| Symbol | Kind | Description |
|---|---|---|
| `FROM <image>` | Module | Build stage |
| `RUN ...` | Method | Shell command |
| `COPY / ADD` | Method | File copy |
| `WORKDIR` | Method | Working directory |
| `ENV` | Method | Environment variable |
| `ARG` | Method | Build argument |
| `LABEL` | Method | Image metadata |

**How to use:** Open a Dockerfile and press `<Leader>ls` (or `:AerialToggle`) to open the symbol sidebar. Navigate with `j`/`k`, press `Enter` to jump to the symbol.

### Docker support

`lua/plugins/docker.lua` imports the AstroCommunity Docker pack, which automatically installs:

- **Treesitter grammar** for Dockerfile syntax highlighting
- **docker-language-server** — LSP for Dockerfile intelligence
- **hadolint** — Dockerfile linter (catches best-practice violations)

No manual config needed — open a `Dockerfile` and it Just Works.

### Shell consistency

`lua/plugins/shell.lua` forces Neovim to use `/bin/zsh` (the macOS system zsh) for:

- `:terminal` — embedded terminal buffers
- `:!` — external command execution
- **toggleterm** — floating/split terminal windows

This ensures your shell aliases, Zinit plugins, and environment are available inside Neovim terminals.

### Neo-tree (file tree)

`lua/plugins/neotree.lua` configures the file tree to show **hidden files and dotfiles by default**, matching the behavior of your terminal `ls` aliases.

## Fresh machine setup

### 1. Install prerequisites

On macOS with Homebrew:

```bash
# Stow (required)
brew install stow

# Zsh ecosystem (all required for the .zshrc to work properly)
brew install starship eza bat fzf zoxide fd git-delta lazygit

# CLI utilities
brew install jq yq htop tree herdr

# Git platform CLIs
brew install gh glab

# Kubernetes tooling
brew install kubectl helm k9s

# Build tools
brew install cmake

# Docker runtime (Colima — lightweight, no GUI)
# docker-compose provides the v2 compose plugin; install.sh wires cliPluginsExtraDirs
# into ~/.docker/config.json so `docker compose` resolves out of the box.
brew install colima docker docker-compose

# 1Password CLI (for secret management)
brew install --cask 1password-cli

# Terminal emulator
brew install --cask ghostty

# Neovim (AstroNvim requires a Nerd Font)
brew install neovim node npm ripgrep
brew install --cask font-jetbrains-mono-nerd-font   # or your preferred Nerd Font

# OpenCode
curl -fsSL https://raw.githubusercontent.com/anomalyco/opencode/master/install | bash

# OpenSpec (spec-driven dev framework; integrates with opencode via /opsx:* commands)
npm install -g @fission-ai/openspec@latest
```

### 2. Clone this repo

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
```

### 3. Stow the packages

```bash
stow bat btop git herdr htop lazygit lazydocker zsh starship nvim opencode ghostty
```

That's it. Stow's default target is the parent of wherever you run it, so cloning to `~/dotfiles` and running from inside it links everything into `$HOME` automatically.

### 4. First Launch

Open a new terminal. Zinit will auto-install itself and all plugins on the first run. This takes ~10-30 seconds depending on your connection. After it completes, run `reload` or open a new terminal to see the full prompt.

### 5. Install AstroNvim plugins

Open Neovim — Lazy.nvim will detect the config and install all plugins on first launch:

```bash
nvim
```

Mason (LSP/linter/formatter installer) will also run on first open. Let it complete before doing anything else.

### 6. Authenticate OpenCode

```bash
opencode auth
```

Auth tokens are stored in `~/.local/share/opencode/` — outside the dotfiles repo and never tracked.

### 7. Initialize OpenSpec (per project)

OpenSpec is installed globally, but needs initializing in each project where you want spec-driven workflows. From inside the project:

```bash
openspec init                       # generates openspec/ + wires opencode slash commands
openspec init --tools opencode      # non-interactive: just opencode, no other agent prompts
```

This creates `openspec/` (specs + changes) plus `.opencode/skills/openspec-*/` and `.opencode/commands/opsx-*.md` so `/opsx:propose`, `/opsx:explore`, `/opsx:apply`, `/opsx:archive` are available inside opencode for that project. Telemetry is disabled via `OPENSPEC_TELEMETRY=0` in `.zshrc`.

#### About the `npm warn allow-scripts` message

When `install.sh` runs `npm install -g @fission-ai/openspec@latest`, npm prints:

```
npm warn allow-scripts 1 package has install scripts not yet covered by allowScripts:
npm warn allow-scripts   @fission-ai/openspec@1.5.0 (postinstall: node scripts/postinstall.js)
npm warn allow-scripts Run `npm install -g --allow-scripts=@fission-ai/openspec` ...
```

This is **expected and intentionally left in place**. Modern npm (v7+) blocks a package's `postinstall` script by default as a supply-chain safety guard — a global package's install scripts can run arbitrary code on your machine, so npm refuses to run them unless explicitly allow-listed.

We do **not** allow-list `@fission-ai/openspec`'s postinstall in `install.sh` because:

1. **The CLI works without it.** `openspec --version`, `openspec init`, `openspec update` all function correctly with the script suppressed (verified during `install.sh` setup).
2. **Defense in depth.** Global npm packages are vendored from a registry; running their install scripts without review is exactly what the guard exists to prevent. Running install scripts is an opt-in privilege, not a sensible default.
3. **Decision is reversible per-user.** If a future OpenSpec release's postinstall does something you want (e.g., prints a one-time migration hint), allow it once:
   ```bash
   npm install -g --allow-scripts=@fission-ai/openspec @fission-ai/openspec@latest
   ```
   Or permanently trust this package:
   ```bash
   npm config set allow-scripts=@fission-ai/openspec --location=user
   ```
   Re-running `bash install.sh` will continue to work either way — the warning is informational, not an error.

The `set -euo pipefail` in `install.sh` is not broken by the warning: npm's exit code is `0` when the install succeeds with the script suppressed.

### 8. Start Colima (Docker runtime)

Colima replaces Docker Desktop with a lightweight, CLI-only Docker runtime:

```bash
colima start        # Start the Docker VM (~10s on first run)
docker ps           # Verify it works
docker compose version   # Confirm compose plugin is wired up
lazydocker          # TUI Docker client connects automatically
colima stop         # Stop when done
colima status       # Check if running
```

Colima creates a VM with default specs (2 CPU, 2GB RAM). To customize:
```bash
colima start --cpu 4 --memory 8 --disk 60
```

## Conflicts on a fresh machine

If an application already wrote a default config before you stowed (e.g. `~/.config/opencode/opencode.jsonc` already exists as a real file), Stow refuses to clobber it and reports a conflict. Two ways out:

- Remove or back up the offending target file, then `stow` again, **or**
- `stow --adopt nvim` — but use this carefully. `--adopt` pulls the *existing target file's contents into the repo*, overwriting the repo's version. Commit first so you can diff and revert if it swallowed something you wanted to keep.

## Syncing — and what "both ways" actually means

There are two different syncs in play, and **neither is an automatic background daemon**. This isn't Dropbox.

### Local: edits ↔ repo (genuinely two-way)

Because Stow uses symlinks, the file at `~/.config/nvim/init.lua` *is* the file at `~/dotfiles/nvim/.config/nvim/init.lua` — one inode, two names. Edit it from either location and there's no copy and no drift. Your live config edits land in the repo's working tree **as you make them**.

This also means anything written *by* an application into its config directory is immediately in the repo too. Create an OpenCode agent through the TUI, save a Ghostty theme, update your Zsh aliases — all of it lands directly in `~/dotfiles/` without any sync step. You just need to commit when you want a checkpoint.

The only remaining local step is taking a git snapshot:

```bash
cd ~/dotfiles
git add -A
git commit -m "add opencode agent for JLR pipeline"
git push
```

### Cross-machine: repo ↔ other machines (manual, order matters)

This half is always deliberate git, regardless of tooling:

```bash
# machine A — after committing and pushing (above)

# machine B
cd ~/dotfiles
git pull
stow -R bat btop git herdr htop lazygit lazydocker zsh starship nvim opencode ghostty   # restow: cleans up and re-links after a pull that added files
```

If you edit on two machines without pulling first, you get a normal git divergence to merge — nothing exotic, just regular git.

## Day-to-day Stow commands

| Command | What it does |
|---|---|
| `stow zsh` | Link the `zsh` package into `$HOME` |
| `stow -R zsh` | **Restow** — unlink then relink. Run after a `git pull` that added new files |
| `stow -D zsh` | **Unstow** — remove the package's symlinks (leaves the repo files untouched) |
| `stow zsh starship nvim` | Operate on multiple packages at once |

Notes:

- You only need to re-run `stow` when the *set of files changes* (a new file or a new package). **Editing an already-linked file needs nothing** — the link already points at it.
- Re-running `stow` on an already-stowed package is safe and idempotent.
- `stow -D` must be run from the *same directory* you originally stowed from, since Stow resolves link targets relative to its current location.

## Adding a new config

1. Create the package structure mirroring the target path:
   ```bash
   mkdir -p ~/dotfiles/starship/.config
   ```
2. Move the existing config into it:
   ```bash
   mv ~/.config/starship.toml ~/dotfiles/starship/.config/starship.toml
   ```
3. Stow it:
   ```bash
   cd ~/dotfiles && stow starship
   ```
4. Commit.

## Secret hygiene

A dotfiles repo lives one careless commit away from leaking credentials, so the standing rules:

- **Never put API keys or tokens in config files.** Reference environment variables instead, and set those via your password manager CLI at shell startup — e.g. `export NEBIUS_API_KEY="$(op read 'op://vault/nebius/api_key')"` in `.zshrc`. The key is fetched at shell startup, never touches the repo.
- **Never blanket-add.** Always `git add -p` or add specific files. A `.gitignore` that excludes `*.token`, `*secret*`, `*key*`, `auth.json` patterns is cheap insurance.
- **Audit before pushing anywhere public.** Run [`gitleaks detect`](https://github.com/gitleaks/gitleaks) over the repo. Remember that *anything ever committed stays in history* even if you later delete it — scrub with `git filter-repo` and rotate the key if anything slips through.
- **OpenCode auth lives outside the repo.** Tokens are stored in `~/.local/share/opencode/` — not tracked. But check `opencode.jsonc` for any inline API keys if you've manually edited it.
- **Zsh config is the highest-risk file.** It's easy to export a key inline in `.zshrc` and forget it's there. Audit it before the first commit.

## What is and isn't tracked

| Path | Tracked | Reason |
|---|---|---|
| `~/.config/nvim/` | ✅ | Your config and Lazy lockfile |
| `~/.local/share/nvim/` | ❌ | Plugin installs — regenerated by Lazy |
| `~/.config/opencode/` | ✅ | Config, agents, rules |
| `~/.local/share/opencode/` | ❌ | Auth tokens — never track |
| `~/.config/ghostty/` | ✅ | Terminal config |
| `~/.zshrc` / `.zshenv` / `.zprofile` | ✅ | Shell config |
| `~/.config/starship.toml` | ✅ | Prompt config |
| `~/.config/ainative/banner.sh` | ✅ | Startup banner |
| `~/.config/bat/` | ✅ | Syntax highlighting theme and config |
| `~/.config/btop/btop.conf` | ✅ | Resource monitor config and theme |
| `~/.config/herdr/config.toml` | ✅ | Terminal workspace multiplexer theme |
| `~/.config/htop/htoprc` | ✅ | htop color scheme config |
| `~/.config/lazygit/config.yml` | ✅ | Lazygit UI theme (Linux) |
| `~/Library/Application Support/lazygit/config.yml` | ✅ | Lazygit UI theme (macOS) |
| `~/.config/lazydocker/config.yml` | ✅ | Lazydocker UI theme (Linux) |
| `~/Library/Application Support/lazydocker/config.yml` | ✅ | Lazydocker UI theme (macOS) |
| `~/.config/git/config` | ✅ | Git config with delta colors |
| `~/.zsh_history` / `.bash_history` | ❌ | Shell history — contains commands that may include secrets |

## Platform notes

These configs assume macOS / Linux with the standard XDG layout (`~/.config`, `~/.local/share`, `~/.local/state`, `~/.cache`). If you've set a non-default `$XDG_CONFIG_HOME`, the target paths shift accordingly — check with `echo $XDG_CONFIG_HOME`.

## License

Personal config — take whatever's useful.
