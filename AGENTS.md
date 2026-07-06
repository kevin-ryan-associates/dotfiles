# AGENTS.md

Guidance for AI coding agents working in this repository. Read this before making any change.

## What this repo is

A personal dotfiles repository whose **purpose is repeatable development workflow across different machine installations**. Four mechanisms carry that purpose:

- **GNU Stow** deploys static config files from this repo into `$HOME` via symlinks. The deployed file and the repo file are the same inode.
- **`bootstrap.sh`** is the public entry point. It clones (or pulls) the repo into `~/dotfiles` and dispatches to the native install script for the current OS.
- **`install-mac.sh`** / **`install-linux.sh`** install tooling and converge machine state that depends on dynamic or architecture-specific values a Stow package cannot represent.
- **`brew-packages.sh`** is the shared Homebrew formula list sourced by both install scripts. It is the single source of truth for the cross-platform tool inventory.

A machine that has never seen this repo should reach a known-good state by running:

```bash
curl -fsSL https://raw.githubusercontent.com/kevin-ryan-associates/dotfiles/main/bootstrap.sh | bash
```

…or, if the repo is already present, from `~/dotfiles`:

```bash
bash bootstrap.sh        # dispatches to install-mac.sh or install-linux.sh
```

…and nothing else. A machine that has been here before should converge to the same known-good state by running the same command. This contract is the repo's reason for existing.

## The prime directive

**Every change to machine state must be reproducible by running `bootstrap.sh` (or the native `install-mac.sh` / `install-linux.sh`) plus `stow`. The fix is always a repo edit; the live effect comes from running the script. Never patch the live machine directly.**

If you are about to type a command that modifies a file outside `~/dotfiles` and that modification is meant to be permanent (not a one-off diagnostic), stop. Instead:

1. Edit the repo file (`install-mac.sh`, `install-linux.sh`, `brew-packages.sh`, or a Stow package).
2. Run `bootstrap.sh` (or the native install script for this OS) to apply it.
3. Verify the failing command now works.

Diagnosing on the live machine is fine — `cat`, `ls -l`, `jq`, `docker compose version` etc. are all read-only and encouraged. **Mutating** the live machine outside the script is not.

## Where each kind of change belongs

| Change | Location | Why |
|---|---|---|
| Static, machine-agnostic config (e.g. `starship.toml`, `btop.conf`, `init.lua`) | Stow package, mirrored path | Stow symlinks it verbatim; no runtime logic needed |
| Adding a Homebrew tool the user invokes | `brew-packages.sh` formula list | One shared source of truth consumed by both install scripts |
| Platform-specific install step (e.g. apt base, Docker runtime, font install) | `install-mac.sh` or `install-linux.sh` | Native per-platform steps diverge cleanly; no `if Darwin` branches inside the scripts |
| Machine-state config that depends on a runtime value (e.g. `brew --prefix`) | `install-mac.sh` / `install-linux.sh` idempotent `jq`/heredoc block | The value can't be known at repo-edit time across `/usr/local` (Intel) vs `/opt/homebrew` (Apple Silicon) vs `/home/linuxbrew/.linuxbrew` (Linux) |
| Cleanup of stale state from a tool the install script explicitly replaces | Native install script's guarded self-heal block (see convention below) | Old machines with the replaced tool have cruft; fresh machines have none. The block must no-op on fresh machines. |
| Random pre-existing cruft unrelated to a replaced tool | README "Post-removal cleanup" section, manual | Not the install script's job to clean arbitrary user state |

## Why some machine state lives in the install scripts, not a Stow package

A Stow package deploys a file byte-for-byte. That's wrong whenever the file's correct content depends on a value only knowable on the target machine. The canonical example is `~/.docker/config.json`:

```json
{ "cliPluginsExtraDirs": ["/usr/local/lib/docker/cli-plugins"] }
```

That path is `/usr/local/...` on Intel macs, `/opt/homebrew/...` on Apple Silicon, and `/home/linuxbrew/...` on Linux. A Stow package would freeze one path and break the others. `install-mac.sh` resolves it via `brew --prefix` at runtime. **Rule of thumb:** if the file's content contains a path, a version, or anything architecture-conditional, it belongs in the install script, not a Stow package.

## Self-heal convention

The install scripts sometimes replace a tool the user previously had (e.g. Docker Desktop → Colima on macOS). On machines that had the old tool, stale state may linger (broken symlinks pointing at a removed `.app`). On fresh machines that state doesn't exist. The self-heal block must:

1. **No-op on fresh machines** — guard on the existence of the stale state, not on a blanket remove.
2. **Only act on broken symlinks** — `[ -L "$link" ] && [ ! -e "$link" ]`. A working brew link for the same name must be left alone.
3. **Never abort the script when sudo can't prompt** — `sudo rm ... 2>/dev/null || echo "hint"`. Under `set -euo pipefail` a failed sudo must not crash the install; it should print an actionable message and continue.
4. **Print the manual equivalent in the hint** so a non-interactive run leaves the user a copy-pasteable command.

See the Docker Desktop symlink block in `install-mac.sh` for the reference pattern.

## Install script conventions

- **Idempotent.** Running a script twice produces the same state. `brew install` is free for already-installed formulae; `jq` patches must guard against duplicates; `stow -R` re-links cleanly.
- **No secrets.** Never inline an API key, token, or password. Reference environment variables only; fetch them via the password manager CLI at shell startup (see README "Secret hygiene").
- **Architecture-agnostic.** Use `brew --prefix` (or `brew --prefix <formula>`) rather than hardcoding `/usr/local`, `/opt/homebrew`, or `/home/linuxbrew/.linuxbrew`.
- **No OS branches inside install scripts.** `bootstrap.sh` detects the OS via `uname -s` and dispatches to `install-mac.sh` or `install-linux.sh`. Each native script contains only the steps appropriate for that platform. The shared brew formula list lives in `brew-packages.sh` and is sourced by both scripts.
- **One tool per concept.** Don't install two tools that do the same job unless one explicitly replaces the other (and there's a self-heal block for the replaced one).
- **Stow at the end.** The final step is `stow -R <packages>`. Config symlinks should point at files that already exist.

## Stow package conventions

- **Static only.** No architecture-conditional content, no `brew --prefix` paths, no templating.
- **Mirror the target path.** `nvim/.config/nvim/init.lua` → `~/.config/nvim/init.lua`. The README's "one rule that matters" — get the nesting right and everything works.
- **No secrets, no history, no machine-specific state.** If an app writes session/auth state into its config dir, that dir is not tracked (see README "What is and isn't tracked").
- **Editing a deployed file edits the repo.** Because Stow uses symlinks. Edit the repo source for clarity; the deployed file updates automatically. Don't edit the deployed path directly — it works, but obscures what changed in git.

### Stow deployment shape — read before verifying symlinks

Stow deploys a package in one of two shapes, and both are correct:

- **Per-file symlinks** — when the target directory already exists with unrelated
  content, Stow creates a real subdirectory at the target and symlinks each tracked
  file into it. `ls -l ~/.config/<app>/<file>` shows `lrwxr-xr-x`.
- **Directory symlink** — when the target directory is exclusively this package's
  content, Stow folds it into a single symlink: `~/.config/<app>` →
  `../dotfiles/<app>/.config/<app>`. Files *under* it are not individually symlinked;
  they are reached through the one directory link and appear as regular files
  (`-rw-r--r--`) when listed. **This is not a broken deployment.**

The `opencode` package is the directory-symlink shape: `~/.config/opencode` →
`../dotfiles/opencode/.config/opencode`. Consequently
`~/.config/opencode/agents/sdd-analyze.md` is the same inode as the repo file, yet
`ls -l` shows a regular file. Runtime artifacts (`node_modules/`, `package.json`,
`package-lock.json`) live in the repo working tree (gitignored) because application
writes flow through the directory symlink — expected, not a defect.

**Verifying a Stow deployment (do this, not `ls -l`):**

- `ls -ld ~/.config/<app>` — `-d` shows the entry itself; `l` confirms a directory
  symlink. (`ls -l ~/.config/<app>/<file>` through a dir symlink shows the file's
  own mode and is misleading.)
- Compare inodes: `stat -f %i <repo file>` and `stat -f %i <deployed file>` —
  identical inode = correctly stowed (same file, two names).
- `stow -R -v -n <package>` — dry-run; reports `LINK`/`UNLINK` actions and the
  already-linked state without mutating.

## Docs-sync rule (hard convention)

`brew-packages.sh` and the README "Fresh machine setup" section both list the brew install commands. **They must stay in sync.** When you add or change a formula in `brew-packages.sh`, update the corresponding macOS and Ubuntu README blocks in the same change. AGENTS.md treats drift between them as a defect.

The README install lines are descriptive (numbered, commented, grouped by purpose). `brew-packages.sh` is the authoritative source. If they disagree, `brew-packages.sh` is truth and README is the bug — but AGENTS.md requires you to fix the README in the same change rather than leave a known mismatch.

## Workflow for fixing an environment issue

1. **Diagnose** with read-only commands (`which`, `ls -l`, `--version`, `jq`, `colima status`). Don't mutate.
2. **Identify the location** using the decision table above.
3. **Edit the repo file** — `install-mac.sh`, `install-linux.sh`, `brew-packages.sh`, or a Stow package.
4. **Run `bash bootstrap.sh`** end-to-end from the repo root. Don't skip steps; don't run only the new lines.
5. **Verify the originally-failing command.** Don't declare success from reading the script.
6. **Update README** if its install lines drifted (docs-sync rule).
7. **Commit only if the user asks.** The user explicitly requests commits; otherwise leave changes in the working tree.

## Verification rule (hard)

Before declaring a task done, run `bash bootstrap.sh` from the repo root end-to-end. Reading the script is not verification. Running only the new lines is not verification. The script's job is to converge a machine from any prior state; verifying that requires actually running it.

If a step in the install script requires sudo and your environment can't prompt (no TTY), the self-heal block will print a manual hint. In that case:

- **Report it explicitly.** Don't claim the sudo step succeeded.
- **Verify the steps that don't need sudo** (brew install, jq patch, stow) actually worked.
- **Tell the user to run `bash bootstrap.sh` themselves** in a real terminal to exercise the sudo path.

False success claims are the worst AGENTS.md violation. Ambient silence about a skipped sudo path is the second-worst.

## Don'ts

- Don't mutate live machine state outside the install scripts / `stow`. Diagnose freely; mutate via the script.
- Don't edit deployed files (`~/.zshrc`, `~/.config/nvim/init.lua`) directly — edit the repo source so the change is version-controlled.
- Don't commit secrets. Audit `.zshrc` and any config with `op read` calls before the first commit on a new package.
- Don't add a tool to `brew-packages.sh` without checking it's not already covered by another formula (avoid duplicates).
- Don't add a Stow package whose content depends on `brew --prefix`, a username, or a version — that goes in the install script.
- Don't claim a fix works without running `bootstrap.sh` end-to-end.
- Don't update README install lines without updating `brew-packages.sh` to match, or vice versa (docs-sync rule).

## Pointers

- **README.md** — full project context, Stow layout, theme policy, fresh-machine setup. Read it for the big picture; AGENTS.md is for *how to make changes safely*.
- **install-mac.sh** — macOS tooling + machine-state script.
- **install-linux.sh** — Ubuntu tooling + machine-state script.
- **brew-packages.sh** — shared Homebrew formula list sourced by both install scripts.
- **bootstrap.sh** — public one-liner wrapper (`curl | bash`). Clones/pulls the repo to `~/dotfiles` and `exec`s the native install script. Does not itself install tooling.
- **`test/`** — Docker-based test harness for the Ubuntu install path. **Not** a Stow package; never add it to the `stow -R` line. Same for the repo-root `.dockerignore` (Docker build artifact, not config).
- **Top-level folders** — Stow packages. One folder per application's config.
