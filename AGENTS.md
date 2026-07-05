# AGENTS.md

Guidance for AI coding agents working in this repository. Read this before making any change.

## What this repo is

A personal dotfiles repository whose **purpose is repeatable development workflow across different machine installations**. Two mechanisms carry that purpose:

- **GNU Stow** deploys static config files from this repo into `$HOME` via symlinks. The deployed file and the repo file are the same inode.
- **`install.sh`** installs tooling (Homebrew formulae) and converges machine state that depends on dynamic or architecture-specific values a Stow package cannot represent.

A machine that has never seen this repo should reach a known-good state by running, from `~/dotfiles`:

```bash
bash install.sh
```

…and nothing else. A machine that has been here before should converge to the same known-good state by running the same command. This contract is the repo's reason for existing.

## The prime directive

**Every change to machine state must be reproducible by running `install.sh` plus `stow`. The fix is always a repo edit; the live effect comes from running the script. Never patch the live machine directly.**

If you are about to type a command that modifies a file outside `~/dotfiles` and that modification is meant to be permanent (not a one-off diagnostic), stop. Instead:

1. Edit the repo file (`install.sh` or a Stow package).
2. Run `install.sh` (or `stow -R <package>`) to apply it.
3. Verify the failing command now works.

Diagnosing on the live machine is fine — `cat`, `ls -l`, `jq`, `docker compose version` etc. are all read-only and encouraged. **Mutating** the live machine outside the script is not.

## Where each kind of change belongs

| Change | Location | Why |
|---|---|---|
| Static, machine-agnostic config (e.g. `starship.toml`, `btop.conf`, `init.lua`) | Stow package, mirrored path | Stow symlinks it verbatim; no runtime logic needed |
| Adding a Homebrew tool the user invokes | `install.sh` `brew install` line | install.sh is the source of truth for installed tooling |
| Machine-state config that depends on a runtime value (e.g. `brew --prefix`) | `install.sh` idempotent `jq`/heredoc block | The value can't be known at repo-edit time across `/usr/local` (Intel) vs `/opt/homebrew` (Apple Silicon) |
| Cleanup of stale state from a tool install.sh explicitly replaces | `install.sh` guarded self-heal block (see convention below) | Old machines with the replaced tool have cruft; fresh machines have none. The block must no-op on fresh machines. |
| Random pre-existing cruft unrelated to a replaced tool | README "Post-removal cleanup" section, manual | Not install.sh's job to clean arbitrary user state |

## Why some machine state lives in install.sh, not a Stow package

A Stow package deploys a file byte-for-byte. That's wrong whenever the file's correct content depends on a value only knowable on the target machine. The canonical example is `~/.docker/config.json`:

```json
{ "cliPluginsExtraDirs": ["/usr/local/lib/docker/cli-plugins"] }
```

That path is `/usr/local/...` on Intel macs and `/opt/homebrew/...` on Apple Silicon. A Stow package would freeze one path and break the other. install.sh resolves it via `brew --prefix` at runtime, so the same script works on both architectures. **Rule of thumb:** if the file's content contains a path, a version, or anything architecture-conditional, it belongs in install.sh, not a Stow package.

## install.sh self-heal convention

install.sh sometimes replaces a tool the user previously had (e.g. Docker Desktop → Colima). On machines that had the old tool, stale state may linger (broken symlinks pointing at a removed `.app`). On fresh machines that state doesn't exist. The self-heal block must:

1. **No-op on fresh machines** — guard on the existence of the stale state, not on a blanket remove.
2. **Only act on broken symlinks** — `[ -L "$link" ] && [ ! -e "$link" ]`. A working brew link for the same name must be left alone.
3. **Never abort the script when sudo can't prompt** — `sudo rm ... 2>/dev/null || echo "hint"`. Under `set -euo pipefail` a failed sudo must not crash the install; it should print an actionable message and continue.
4. **Print the manual equivalent in the hint** so a non-interactive run leaves the user a copy-pasteable command.

See the Docker Desktop symlink block in install.sh for the reference pattern.

## install.sh conventions

- **Idempotent.** Running it twice produces the same state. `brew install` is free for already-installed formulae; `jq` patches must guard against duplicates; `stow -R` re-links cleanly.
- **No secrets.** Never inline an API key, token, or password. Reference environment variables only; fetch them via the password manager CLI at shell startup (see README "Secret hygiene").
- **Architecture-agnostic.** Use `brew --prefix` (or `brew --prefix <formula>`) rather than hardcoding `/usr/local` or `/opt/homebrew`.
- **One tool per concept.** Don't install two tools that do the same job unless one explicitly replaces the other (and there's a self-heal block for the replaced one).
- **Stow at the end.** The final step is `stow -R <packages>`. Config symlinks should point at files that already exist.

## Stow package conventions

- **Static only.** No architecture-conditional content, no `brew --prefix` paths, no templating.
- **Mirror the target path.** `nvim/.config/nvim/init.lua` → `~/.config/nvim/init.lua`. The README's "one rule that matters" — get the nesting right and everything works.
- **No secrets, no history, no machine-specific state.** If an app writes session/auth state into its config dir, that dir is not tracked (see README "What is and isn't tracked").
- **Editing a deployed file edits the repo.** Because Stow uses symlinks. Edit the repo source for clarity; the deployed file updates automatically. Don't edit the deployed path directly — it works, but obscures what changed in git.

## Docs-sync rule (hard convention)

`install.sh` and the README "Fresh machine setup" section both list the brew install commands. **They must stay in sync.** When you add or change a `brew install` line in install.sh, update the corresponding README line in the same change. AGENTS.md treats drift between them as a defect.

The README install lines are descriptive (numbered, commented, grouped by purpose). install.sh is the authoritative script. If they disagree, install.sh is truth and README is the bug — but AGENTS.md requires you to fix the README in the same change rather than leave a known mismatch.

## Workflow for fixing an environment issue

1. **Diagnose** with read-only commands (`which`, `ls -l`, `--version`, `jq`, `colima status`). Don't mutate.
2. **Identify the location** using the decision table above.
3. **Edit the repo file** — install.sh for tooling/state, Stow package for static config.
4. **Run `bash install.sh`** end-to-end from the repo root. Don't skip steps; don't run only the new lines.
5. **Verify the originally-failing command.** Don't declare success from reading the script.
6. **Update README** if its install lines drifted (docs-sync rule).
7. **Commit only if the user asks.** The user explicitly requests commits; otherwise leave changes in the working tree.

## Verification rule (hard)

Before declaring a task done, run `bash install.sh` from the repo root end-to-end. Reading the script is not verification. Running only the new lines is not verification. The script's job is to converge a machine from any prior state; verifying that requires actually running it.

If a step in install.sh requires sudo and your environment can't prompt (no TTY), the self-heal block will print a manual hint. In that case:

- **Report it explicitly.** Don't claim the sudo step succeeded.
- **Verify the steps that don't need sudo** (brew install, jq patch, stow) actually worked.
- **Tell the user to run `bash install.sh` themselves** in a real terminal to exercise the sudo path.

False success claims are the worst AGENTS.md violation. ambient silence about a skipped sudo path is the second-worst.

## Don'ts

- Don't mutate live machine state outside install.sh / stow. Diagnose freely; mutate via the script.
- Don't edit deployed files (`~/.zshrc`, `~/.config/nvim/init.lua`) directly — edit the repo source so the change is version-controlled.
- Don't commit secrets. Audit `.zshrc` and any config with `op read` calls before the first commit on a new package.
- Don't add a tool to install.sh without checking it's not already covered by another formula (avoid duplicates).
- Don't add a Stow package whose content depends on `brew --prefix`, a username, or a version — that goes in install.sh.
- Don't claim a fix works without running install.sh end-to-end.
- Don't update README install lines without updating install.sh to match, or vice versa (docs-sync rule).

## Pointers

- **README.md** — full project context, Stow layout, theme policy, fresh-machine setup. Read it for the big picture; AGENTS.md is for *how to make changes safely*.
- **install.sh** — authoritative tooling + machine-state script.
- **Top-level folders** — Stow packages. One folder per application's config.