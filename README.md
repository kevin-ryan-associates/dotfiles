# dotfiles

Personal configuration files, managed with [chezmoi](https://www.chezmoi.io/).

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
- **`pi`** — [Pi](https://pi.dev/) open-source AI coding harness with Tokyo Night Moon theme
- **`claude`** — [Claude Code](https://claude.com/product/claude-code) terminal AI coding assistant with Tokyo Night Moon theme
- **`colima`** — Docker runtime (macOS; replaces Docker Desktop, no GUI)

## Why this exists

Config files have a habit of drifting. You tweak your Neovim keymaps on one machine, forget what you changed, then spend twenty minutes on the next machine wondering why muscle memory doesn't work. This repo is the single source of truth for that config, version-controlled so every change is a deliberate, reversible checkpoint.

### Why not just `git init` in `$HOME`?

Tempting, but a footgun. Turning your home directory into a git repo means git is aware of *everything* under it — every cache, every secret, every stray token. One careless `git add -A` and your SSH keys, cloud credentials, or password-manager session files are in a commit. Managing the recursive ignores to prevent that is its own special misery.

### Why chezmoi?

chezmoi keeps the repo (the "source state") in its own directory, separate from `$HOME`, and **writes real files** into your home directory where each application expects to find them. That gives four things:

- **Explicit tracking.** Only files you deliberately add with `chezmoi add` get deployed. Nothing is tracked by accident.
- **Templating.** Files whose correct content depends on a runtime value (`brew --prefix`, the OS, the hostname) live as `.tmpl` sources that render at apply time on the actual machine — no separate install script needed for the bits that depend on the world. (The prior Stow setup worked around this by keeping those files out of the repo entirely and writing them from a bash install script. chezmoi closes that gap.)
- **Run scripts.** Package installation (brew/npm), the `~/.docker/config.json` jq merge, and the Docker-Desktop symlink self-heal all live as `run_*` scripts next to the config they relate to — same repo, same source of truth.
- **Single source of truth for packages.** `.chezmoidata.yaml` lists every brew formula, cask, and npm global; the install run-script renders from it. Edits to the package list happen in one place.

## How it works

The repo root *is* the chezmoi source directory. After `chezmoi init kevin-ryan-associates/dotfiles` it lives at `~/.local/share/chezmoi/`. chezmoi encodes target paths in the source filenames using attribute prefixes (`dot_` → `.`, `private_` → 0600, `executable_` → +x, `.tmpl` → template) and special directories (`.chezmoiscripts/`, `.chezmoidata.yaml`, `.chezmoiignore`, `.chezmoi.toml.tmpl`).

```
~/.local/share/chezmoi/
├── dot_zshrc                        → ~/.zshrc
├── dot_zshenv                       → ~/.zshenv
├── dot_zprofile.tmpl                → ~/.zprofile   (templated: probes brew install paths via stat)
├── dot_config/
│   ├── ainative/
│   │   └── banner.sh                → ~/.config/ainative/banner.sh
│   ├── starship.toml                → ~/.config/starship.toml
│   ├── nvim/                        → ~/.config/nvim/
│   │   ├── init.lua
│   │   └── lua/...
│   ├── bat/
│   │   ├── config                   → ~/.config/bat/config
│   │   └── themes/
│   │       └── tokyonight_moon.tmTheme
│   ├── btop/btop.conf               → ~/.config/btop/btop.conf
│   ├── herdr/config.toml            → ~/.config/herdr/config.toml
│   ├── htop/htoprc                  → ~/.config/htop/htoprc
│   ├── lazygit/config.yml           → ~/.config/lazygit/config.yml
│   ├── lazydocker/config.yml        → ~/.config/lazydocker/config.yml
│   ├── git/config                   → ~/.config/git/config
│   ├── opencode/                    → ~/.config/opencode/
│   │   ├── opencode.jsonc
│   │   ├── tui.json
│   │   └── themes/tokyonight-moon.json
│   └── ghostty/config               → ~/.config/ghostty/config
├── .chezmoidata.yaml                 # static package inventory (brew/cask/npm lists)
├── .chezmoi.toml.tmpl                # init config — fails early if git missing
├── .chezmoiignore                   # README/AGENTS + opencode runtime artifacts
└── .chezmoiscripts/
    ├── run_once_before_install-packages.sh.tmpl              # brew install + casks + opencode + openspec
    ├── run_onchange_before_configure-docker-cli-plugins.sh.tmpl  # macOS jq patch to ~/.docker/config.json
    └── run_once_after_cleanup-docker-desktop-symlinks.sh.tmpl    # self-heal broken /usr/local/bin links
```

When you run `chezmoi apply`, chezmoi:

1. Runs `run_before_` scripts (installs packages before any templated config needs `brew --prefix`).
2. Writes every target file (real files, not symlinks) to `$HOME`, rendering templates on the way.
3. Runs `run_after_` scripts (Docker Desktop cleanup).

> **The rules that matter:**
> - Editing a deployed file (`~/.zshrc`) does **not** edit the source — it edits a copy. To persist a change, either `chezmoi re-add` (copies the live file back into source) or `chezmoi edit ~/.zshrc` (opens the source in `$EDITOR`, then `chezmoi apply` to deploy). This is the inverse of the Stow symlink model; see [Syncing](#syncing--and-what-chezmoi-apply-actually-does).
> - Files depending on `brew --prefix`, `.chezmoi.os`, `.chezmoi.arch`, or similar runtime values must be a `.tmpl` and use `output`/`stat`/`.chezmoi.os` — never hand-bake `/opt/homebrew` or `/usr/local` into a non-template source file.
> - Anything at the source root that isn't a deployable config (README, AGENTS, test harness, opencode runtime artifacts) must be in `.chezmoiignore`, or it will deploy into `$HOME`.

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

These tools are installed by `run_once_before_install-packages.sh.tmpl` (which renders from `.chezmoidata.yaml`) and integrate with the Zsh configuration:

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
| `glow` | Terminal markdown renderer | `glow README.md` |
| `bandwhich` | Live network bandwidth monitor | `sudo bandwhich` (needs sudo for raw-socket capture on macOS) |
| `dust` | `du` successor (Rust) | `dust`, `dust -d 2` for depth |
| `hunk` | Review-first diff viewer for agent changesets | `hunk diff`, `hunk show` — complements `delta` (pager) and `lazygit` (TUI); themed to Tokyo Night Moon via `~/.config/hunk/config.toml` |
| `1password-cli` | 1Password secrets | Fetch secrets via `op read` in `.zshrc` |
| `herdr` | Agent multiplexer | Terminal workspace manager |
| `kubectl` | Kubernetes CLI | Aliased to `k` |
| `helm` | Kubernetes package manager | Native command |
| `k9s` | TUI Kubernetes cluster manager | Native command |
| `cmake` | Build system generator | Required for Neovim plugin builds |
| `colima` | Docker runtime (VM-based, macOS) | Replaces Docker Desktop; `colima start/stop` |
| `openspec` | Spec-driven dev framework | Native opencode slash commands (`/opsx:propose`, etc.); telemetry opt-out via `OPENSPEC_TELEMETRY=0` |
| `pi` | Open-source AI coding harness | `pi` to start; themed to Tokyo Night Moon via `~/.pi/agent/themes/tokyo-night-moon.json` (selected by jq-merge in `~/.pi/agent/settings.json`) |
| `claude` | Anthropic's terminal AI coding assistant | `claude` to start; themed to Tokyo Night Moon via `~/.claude/themes/tokyo-night-moon.json` (selected by jq-merge in `~/.claude/settings.json`) |

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
| **hunk** | Custom theme inheriting `tokyo-night`; Moon-palette overrides for chrome + `syntax_scopes` in `~/.config/hunk/config.toml` |
| **pi** | Custom JSON theme `tokyo-night-moon` in `~/.pi/agent/themes/`, selected via jq-merge patch to `~/.pi/agent/settings.json` |
| **claude** | Custom JSON theme `tokyo-night-moon` in `~/.claude/themes/`, selected via jq-merge patch to `~/.claude/settings.json` (preserves existing hooks block) |
| **Zsh banner** | ANSI colors mapped to Tokyo Night Moon palette |

### Centralized palette source

The canonical Moon palette now lives in one place: `.chezmoidata.yaml` under `theme.tokyo_night_moon`. The templated tool configs (starship, git/delta, lazygit, hunk, btop theme, ghostty, the `dot_zshrc.tmpl` fzf color block, and the pi/claude/opencode theme JSON files — stored as `*.tmpl` sources) reference it via `{{ .theme.tokyo_night_moon.<key> }}`, so editing a color there propagates to every templated config on the next `chezmoi apply`. The per-tool integration rows above still hold; rendering is transparent (the deployed files resolve to the same literal hex values as before — `chezmoi verify` stays green).

One consumer is deliberately **not** templated this pass: `dot_config/bat/themes/tokyonight_moon.tmTheme` — a vendored TextMate grammar with hundreds of scope→hex entries. Centralizing it is mechanical but bulk-heavy and regression-prone, so it stays literal (its values are already self-consistent with the palette); templating it is tracked as a follow-up.

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

### 1. One-liner (recommended)

```bash
sh -c "$(curl -fsSL https://chezmoi.io/get)" -- init --apply kevin-ryan-associates/dotfiles
```

This installs chezmoi if missing, clones the source state into `~/.local/share/chezmoi/`, then runs `chezmoi apply` end-to-end. The apply phase:

- Runs `run_once_before_install-packages.sh.tmpl` — installs Homebrew if missing, then every formula/cask/npm package listed in `.chezmoidata.yaml`.
- Writes every config file from source into `$HOME`, rendering templates on the way. Two templated files retire the legacy install-script-as-machine-state pattern:
  - `dot_zprofile.tmpl` probes `/opt/homebrew/bin/brew` and `/usr/local/bin/brew` via `stat` and emits the matching `eval "$(.../brew shellenv)"` line. No more arch-conditional heredoc block in an install script.
  - `run_onchange_before_configure-docker-cli-plugins.sh.tmpl` does the `~/.docker/config.json` jq merge (preserving existing keys) — the same logic the legacy install script owned, now sitting next to the config it touches.
- Runs `run_once_after_*` scripts — the Docker Desktop symlink self-heal.

Then continue to [First Launch](#3-first-launch) below.

> **Heads up — Xcode Command Line Tools:** on a truly fresh macOS, the Homebrew install step inside `install-packages` pops a GUI dialog for CLT. Click Install, wait for it to finish, and the apply continues. This is unavoidable — it's Homebrew's own prerequisite. If `git` is also missing, `.chezmoi.toml.tmpl` aborts `chezmoi init` immediately with the message `xcode-select --install`.

> **First apply on a fresh machine, friendly fail mode:** if you skip `chezmoi init` and run a raw `chezmoi apply` against a machine that doesn't have brew installed yet, `dot_zprofile.tmpl`'s `stat` probes both candidate brew paths, finds none, and renders an empty `~/.zprofile`. A subsequent `chezmoi apply` (after installing brew) fills it in. No apply fails on a missing binary.

### 2. Manual alternative (if you prefer not to pipe to bash)

The one-liner above does exactly this, step by step:

#### Install chezmoi

```bash
# macOS (chezmoi is a single Go binary)
brew install chezmoi
```

#### Init the source state from this repo

```bash
chezmoi init kevin-ryan-associates/dotfiles
# Clones into ~/.local/share/chezmoi/ and renders ~/.config/chezmoi/chezmoi.toml
# from .chezmoi.toml.tmpl (fails early if git not on PATH).
```

#### Apply (installs packages, writes configs, runs self-heal)

```bash
chezmoi apply
```

`chezmoi apply` is the single converge command — equivalent to the legacy `bash bootstrap.sh` end-to-end. Running it twice is idempotent (the `once_`/`onchange_` script guards prevent reinstall churn).

The package list `chezmoi apply` installs is the authoritative inventory in `.chezmoidata.yaml`; if you want to audit it before running apply, you can:

```bash
chezmoi execute-template < ~/.local/share/chezmoi/.chezmoiscripts/run_once_before_install-packages.sh.tmpl
# or just read .chezmoidata.yaml directly — it's plain YAML.
```

#### What `.chezmoidata.yaml` installs

For reference, the package list **and** the centralized Tokyo Night Moon palette (`theme.tokyo_night_moon`) live in `.chezmoidata.yaml` at the source root. The palette is consumed read-only by the `*.tmpl` tool configs, not by an install script. The inventory currently prescribes:

**Brew formulae:** `starship eza bat fzf zoxide fd git-delta lazygit lazydocker` (Zsh ecosystem), `jq yq htop tree btop herdr glow bandwhich dust hunk` (CLI utilities), `gh glab` (Git platform CLIs), `kubectl helm k9s` (Kubernetes), `cmake` (build), `neovim node npm ripgrep` (AstroNvim prerequisites).

**Brew casks:** `1password-cli ghostty font-meslo-lg-nerd-font`. Plus `colima docker docker-compose` (the Docker runtime). `~/.docker/config.json` is jq-patched by `run_onchange_before_configure-docker-cli-plugins.sh.tmpl` to wire the brew `cli-plugins` dir.

**npm globals:** `@fission-ai/openspec@latest`, `@earendil-works/pi-coding-agent@latest`.

**Pi packages** (curated set, idempotently ensured in `~/.pi/agent/settings.json`'s `packages` array by `run_onchange_before_configure-pi-packages.sh.tmpl`): `npm:pi-mcp-adapter` (MCP server support), `npm:pi-subagents` (task delegation / chains / parallel / TUI clarify), `npm:pi-web-access` (web search + URL fetch + GitHub clone + PDF/YT), `npm:pi-hermes-memory` (local memory + SQLite FTS5 search + secret scanning), `npm:@narumitw/pi-plan-mode` (Codex-like read-only `/plan` mode), `npm:context-mode` (MCP plugin: ~98% context savings via sandboxed code exec + FTS5 knowledge base). The merge is **append-only** — entries are *ensured present*, never removed; user `pi install` adds and entries dropped from `.chezmoidata.yaml` stay on disk (removal requires `pi remove npm:<pkg>`). pi auto-installs any missing tarballs on its next startup.

**Also installed:** OpenCode installer (upstream `opencode-ai/opencode` — `curl | bash -- --no-modify-path`); Claude Code native installer (`curl https://claude.ai/install.sh | bash`, auto-updates in background); `bat cache --build`. The deprecated npm-global `@anthropic-ai/claude-code` install is removed by a `run_once_after_*` self-heal script if present.

> Linux (Ubuntu) support is retired for now — `chezmoi apply` fails fast with an explicit message on non-macOS. The Linux branch can be re-added later by reintroducing an `{{- else if eq .chezmoi.os "linux" }}` arm in `run_once_before_install-packages.sh.tmpl` and a `linux:` section in `.chezmoidata.yaml`.

### 3. First Launch

Open a new terminal. Zinit will auto-install itself and all plugins on the first run. This takes ~10-30 seconds depending on your connection. After it completes, run `reload` or open a new terminal to see the full prompt.

### 4. Install AstroNvim plugins

Open Neovim — Lazy.nvim will detect the config and install all plugins on first launch:

```bash
nvim
```

Mason (LSP/linter/formatter installer) will also run on first open. Let it complete before doing anything else.

### 5. Authenticate OpenCode

```bash
opencode auth
```

Auth tokens are stored in `~/.local/share/opencode/` — outside the source state and never tracked.

### 6. Initialize OpenSpec (per project)

OpenSpec is installed globally, but needs initializing in each project where you want spec-driven workflows. From inside the project:

```bash
openspec init                       # generates openspec/ + wires opencode slash commands
openspec init --tools opencode      # non-interactive: just opencode, no other agent prompts
```

This creates `openspec/` (specs + changes) plus `.opencode/skills/openspec-*/` and `.opencode/commands/opsx-*.md` so `/opsx:propose`, `/opsx:explore`, `/opsx:apply`, `/opsx:archive` are available inside opencode for that project. Telemetry is disabled via `OPENSPEC_TELEMETRY=0` in `.zshrc`.

#### About the `npm warn allow-scripts` message

When the install run-script renders `npm install -g @fission-ai/openspec@latest`, npm prints:

```
npm warn allow-scripts 1 package has install scripts not yet covered by allowScripts:
npm warn allow-scripts   @fission-ai/openspec@1.5.0 (postinstall: node scripts/postinstall.js)
npm warn allow-scripts Run `npm install -g --allow-scripts=@fission-ai/openspec` ...
```

This is **expected and intentionally left in place**. Modern npm (v7+) blocks a package's `postinstall` script by default as a supply-chain safety guard — a global package's install scripts can run arbitrary code on your machine, so npm refuses to run them unless explicitly allow-listed.

We do **not** allow-list `@fission-ai/openspec`'s postinstall in the install run-script because:

1. **The CLI works without it.** `openspec --version`, `openspec init`, `openspec update` all function correctly with the script suppressed (verified during install script setup).
2. **Defense in depth.** Global npm packages are vendored from a registry; running their install scripts without review is exactly what the guard exists to prevent. Running install scripts is an opt-in privilege, not a sensible default.
3. **Decision is reversible per-user.** If a future OpenSpec release's postinstall does something you want (e.g., prints a one-time migration hint), allow it once:
   ```bash
   npm install -g --allow-scripts=@fission-ai/openspec @fission-ai/openspec@latest
   ```
   Or permanently trust this package:
   ```bash
   npm config set allow-scripts=@fission-ai/openspec --location=user
   ```
   Re-running `chezmoi apply` will continue to work either way — the warning is informational, not an error.

The `set -euo pipefail` in the install run-script is not broken by the warning: npm's exit code is `0` when the install succeeds with the script suppressed.

### 7. Start Colima (Docker runtime)

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

If an application already wrote a default config before you applied chezmoi (e.g. `~/.config/opencode/opencode.jsonc` already exists with non-empty content), `chezmoi apply` will prompt you with a diff and ask whether to overwrite. Options:

- Run `chezmoi diff ~/.config/opencode/opencode.jsonc` first to inspect the proposed change.
- Force overwrite: `chezmoi apply --force`.
- Keep the live version: `chezmoi forget ~/.config/opencode/opencode.jsonc` (untrack it without removing it from disk), then make your edit part of source via `chezmoi add ~/.config/opencode/opencode.jsonc` after deciding.
- Take the live file as the new source of truth: `chezmoi re-add ~/.config/opencode/opencode.jsonc` (re-copies the live file into source, overwriting the previous source).

## Syncing — and what `chezmoi apply` actually does

Two halves, and **neither is an automatic background daemon**. This isn't Dropbox.

### Local: edits ↔ source state (one-way)

chezmoi writes **real files** to `$HOME`, not symlinks. Editing a deployed file (`~/.config/nvim/init.lua`) edits a copy — the source state is unaffected. To persist a change in source:

```bash
# Open the source (in $EDITOR), make the edit, then deploy:
chezmoi edit ~/.config/nvim/init.lua
chezmoi apply ~/.config/nvim/init.lua

# OR adopt the live file's current content as the new source:
chezmoi re-add ~/.config/nvim/init.lua
```

To see what's drifted between live and source:

```bash
chezmoi status        # lists changed/added/removed files
chezmoi diff          # unified diff for each
```

### Application-written state inside a managed directory

Anything an application writes into a chezmoi-managed directory (e.g. `~/.config/opencode/`) lands on disk in `$HOME` — **not** pulled back into the source automatically. If you add an opencode agent through the TUI and want it tracked in source, run `chezmoi add ~/.config/opencode/agents/...`. If you'd like this captured on every apply cycle, set up `chezmoi re-add` as a `run_after_` script — though this is a divergence from chezmoi's normal one-way reflexive model, so by default the repo deliberately does not.

### Cross-machine: repo ↔ other machines (manual, order matters)

```bash
# machine A — after editing in source (above) and committing

# machine B
chezmoi update       # git pull on the source, then apply
```

If you edit on two machines without pulling first, you get a normal git divergence to merge — nothing exotic, just regular git (`chezmoi cd` drops you into the source dir to resolve it).

## Day-to-day chezmoi commands

| Command | What it does |
|---|---|
| `chezmoi status` | Lists files in `$HOME` that differ from source state (a dry-run pointer for `apply`) |
| `chezmoi diff` | Shows unified diff of every pending change |
| `chezmoi diff <path>` | Shows the diff for one path |
| `chezmoi apply` | Writes every pending change to `$HOME` (runs scripts; idempotent) |
| `chezmoi apply <path>` | Converge just one path |
| `chezmoi edit <path>` | Open the source for a live path in `$EDITOR` |
| `chezmoi add <path>` | Track a live file (copies live → source) |
| `chezmoi re-add <path>` | Re-capture an already-tracked live file's current contents into source |
| `chezmoi forget <path>` | Untrack a file (leaves the live file alone) |
| `chezmoi cd` | `cd` into the source directory |
| `chezmoi update` | `git pull` source, then apply |
| `chezmoi verify` | Exit non-zero if anything in `$HOME` differs from source (the inverse of `apply`) |

## Adding a new config

1. Install chezmoi and init the source (one-time per machine): `chezmoi init kevin-ryan-associates/dotfiles`.
2. Track the live config:
   ```bash
   chezmoi add ~/.config/starship.toml
   ```
   This copies the live file into the source directory at the appropriate chezmoi-named path (`~/.local/share/chezmoi/dot_config/starship.toml`).
3. (Optional) Make it a template if it needs runtime resolution: rename the source file to `<name>.tmpl` and use `{{ ... }}` directives. Re-run `chezmoi apply`.
4. Commit:
   ```bash
   chezmoi cd
   git add -A
   git commit -m "add starship prompt config"
   git push
   ```

## Secret hygiene

A dotfiles repo lives one careless commit away from leaking credentials, so the standing rules:

- **Never put API keys or tokens in config files.** Reference environment variables instead, and set those via your password manager CLI at shell startup — e.g. `export NEBIUS_API_KEY="$(op read 'op://vault/nebius/api_key')"` in `.zshrc`. The key is fetched at shell startup, never touches the repo.
- **Never blanket-add.** Always `git add -p` or add specific files. A `.gitignore` that excludes `*.token`, `*secret*`, `*key*`, `auth.json` patterns is cheap insurance.
- **Audit before pushing anywhere public.** Run [`gitleaks detect`](https://github.com/gitleaks/gitleaks) over the repo. Remember that *anything ever committed stays in history* even if you later delete it — scrub with `git filter-repo` and rotate the key if anything slips through.
- **OpenCode auth lives outside the repo.** Tokens are stored in `~/.local/share/opencode/` — not tracked. But check `opencode.jsonc` for any inline API keys if you've manually edited it.
- **Zsh config is the highest-risk file.** It's easy to export a key inline in `.zshrc` and forget it's there. Audit it before the first commit.
- **`.chezmoiignore` is also a secret-defense layer.** Anything tracked in source that must never deploy to `$HOME` belongs here. Review it whenever source layout changes.

## What is and isn't tracked

| Path | Tracked | Reason |
|---|---|---|
| `~/.config/nvim/` | ✅ | Your config and Lazy lockfile |
| `~/.local/share/nvim/` | ❌ | Plugin installs — regenerated by Lazy |
| `~/.config/opencode/` | ✅ (minus runtime artifacts — see `.chezmoiignore`) | Config, agents, rules |
| `~/.local/share/opencode/` | ❌ | Auth tokens — never track |
| `~/.config/ghostty/` | ✅ | Terminal config |
| `~/.zshrc` / `.zshenv` | ✅ | Shell config |
| `~/.zprofile` | ✅ (templated — `dot_zprofile.tmpl`) | `brew shellenv` line rendered from `stat`-probed brew path at apply time. The legacy install script owned this; chezmoi now templates it. |
| `~/.docker/config.json` | ❌ (unmanaged; written by `run_onchange_before_configure-docker-cli-plugins.sh.tmpl`) | jq merge preserves user keys; a templated file would clobber them |
| `~/.config/starship.toml` | ✅ | Prompt config |
| `~/.config/ainative/banner.sh` | ✅ | Startup banner |
| `~/.config/bat/` | ✅ | Syntax highlighting theme and config |
| `~/.config/btop/btop.conf` | ✅ | Resource monitor config and theme |
| `~/.config/herdr/config.toml` | ✅ | Terminal workspace multiplexer theme |
| `~/.config/hunk/config.toml` | ✅ | Hunk theme: custom Tokyo Night Moon, chrome + syntax scopes (hunk's own `state.json` in the same dir is untracked runtime state) |
| `~/.config/htop/htoprc` | ✅ | htop color scheme config |
| `~/.config/lazygit/config.yml` | ✅ | Lazygit UI theme (all platforms — lazygit reads XDG first on macOS) |
| `~/.config/lazydocker/config.yml` | ✅ | Lazydocker UI theme (all platforms — lazydocker reads XDG first on macOS) |
| `~/.config/git/config` | ✅ | Git config with delta colors |
| `~/.pi/agent/themes/tokyo-night-moon.json` | ✅ | Pi theme: custom Tokyo Night Moon, 51 tokens + export |
| `~/.pi/agent/settings.json` | ❌ (unmanaged; written by `run_onchange_before_configure-pi-theme.sh.tmpl` and `run_onchange_before_configure-pi-packages.sh.tmpl`) | Two jq merges: one sets the `theme` key to `tokyo-night-moon`, the other *ensures presence* of the curated `packages` array from `.chezmoidata.yaml`'s `pi.packages` list. Both are append-only / scalar-set, preserving every other key (provider, model, thinking level). Interactive `pi install`/`pi remove` writes are never overwritten; `chezmoi apply` only adds curated entries, never prunes |
| `~/.pi/agent/auth.json`, `~/.pi/agent/trust.json` | ❌ | Pi runtime auth/trust state — never track |
| `~/.pi/agent/sessions/` | ❌ | Pi session history — runtime |
| `~/.claude/themes/tokyo-night-moon.json` | ✅ | Claude Code theme: custom Tokyo Night Moon, ~40 token overrides on `dark` base |
| `~/.claude/settings.json` | ❌ (unmanaged; written by `run_onchange_before_configure-claude-theme.sh.tmpl`) | jq merge only sets the `theme` key to `custom:tokyo-night-moon`; preserves existing hooks block wiring `herdr-agent-state.sh` |
| `~/.claude.json` | ❌ | Claude Code global config (OAuth, MCP, trust state) — never track |
| `~/.claude/sessions/`, `projects/`, `shell-snapshots/`, `history.jsonl` | ❌ | Claude Code runtime session state — never track |
| `~/.claude/hooks/herdr-agent-state.sh` | ⚠️ untracked but referenced by settings.json | Wires herdr + claude session state; should be tracked as a follow-up task |
| `~/.zsh_history` / `.bash_history` | ❌ | Shell history — contains commands that may include secrets |
| `README.md`, `AGENTS.md`, `LICENSE` | tracked in source, ignored from deploy | Repo metadata — see `.chezmoiignore` |

## Platform notes

Supported platform: **macOS** (Darwin). `chezmoi init` doesn't need OS dispatch — chezmoi detects the OS at apply time via `.chezmoi.os`. Behavior:

- **macOS:** Homebrew for all tooling; Colima as the Docker runtime; casks for 1Password CLI, Ghostty, and the Nerd Font. `dot_zprofile.tmpl`'s `stat` will find `/opt/homebrew/bin/brew` (Apple Silicon) or `/usr/local/bin/brew` (Intel) and emit the appropriate `eval "$(... shellenv)"` line — no arch branches in source.

The install path is encoded in a single template (`run_once_before_install-packages.sh.tmpl`) with an `{{ if eq .chezmoi.os "darwin" }}` arm and a `{{ else }}` arm that fails fast with an explicit message on non-macOS. The shared formula/cask list lives in `.chezmoidata.yaml` and is the single source of truth — edits happen in one file, not across `brew-packages.sh` *and* the README install blocks *and* the install scripts (the previous docs-sync hazard).

All configs use the standard XDG layout (`~/.config`, `~/.local/share`, `~/.local/state`, `~/.cache`). If you've set a non-default `$XDG_CONFIG_HOME`, the target paths shift accordingly — check with `echo $XDG_CONFIG_HOME`.

### Testing

The macOS path is verified manually on a real Mac. (A Docker-based harness for the Ubuntu apply path previously lived in `test/`; it has been retired along with the Linux install path and can be re-added when Linux support returns.)

## License

Personal config — take whatever's useful.