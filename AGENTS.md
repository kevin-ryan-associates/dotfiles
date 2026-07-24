# AGENTS.md

Guidance for AI coding agents working in this repository. Read this before making any change.

## What this repo is

A personal dotfiles repository whose **purpose is repeatable development workflow across different machine installations**. Four mechanisms carry that purpose:

- **[chezmoi](https://www.chezmoi.io/)** manages the source state at `~/.local/share/chezmoi/` (the repo root after `chezmoi init`). `chezmoi apply` writes the target state — real files (not symlinks) — into `$HOME`, rendering templates on the way.
- **The public one-liner** `chezmoi init --apply kevin-ryan-associates/dotfiles` is the entry point. It installs chezmoi if missing, clones the source state, then applies end-to-end.
- **`run_*` scripts under `.chezmoiscripts/`** install tooling and converge machine state that depends on dynamic or architecture-specific values. The single `run_once_before_install-packages.sh.tmpl` replaces the legacy `bootstrap.sh` + `install-mac.sh` + `install-linux.sh` + `brew-packages.sh` quartet. **This build currently targets macOS only** — the `{{ if eq .chezmoi.os "darwin" }}` arm is the sole install path; the `{{ else }}` arm fails fast on non-macOS. The Linux (`{{ else if eq .chezmoi.os "linux" }}`) arm is retired for now and can be reintroduced later; until then, ignore Linux-specific guidance below that references it.
- **`.chezmoidata.yaml`** is the single source of truth for the tool inventory. The install run-script renders the `brew install …` / `npm install -g …` lines from `{{ range .packages.brew.main }}…{{ end }}` loops bound to it. (The `linux:` section is retired; reintroduce it alongside the Linux install arm.)

A machine that has never seen this repo should reach a known-good state by running:

```bash
sh -c "$(curl -fsSL https://chezmoi.io/get)" -- init --apply kevin-ryan-associates/dotfiles
```

…or, if the source state is already present, from anywhere:

```bash
chezmoi apply
```

…and nothing else. A machine that has been here before should converge to the same known-good state by running `chezmoi update` (or `chezmoi apply` if anything was edited in source). This contract is the repo's reason for existing.

## The prime directive

**Every change to machine state must be reproducible by running `chezmoi apply` (or `chezmoi init --apply` on a fresh machine). The fix is always a source-state edit; the live effect comes from applying. Never patch the live machine directly.**

If you are about to type a command that modifies a file outside `~/.local/share/chezmoi/` and that modification is meant to be permanent (not a one-off diagnostic), stop. Instead:

1. Edit the source file — a chezmoi-named entry (e.g. `dot_config/nvim/init.lua`), a `.chezmoiscripts/run_*` script, or `.chezmoidata.yaml`.
2. Run `chezmoi apply` (or `chezmoi apply <path>` for one target) to deploy it.
3. Verify the failing command now works.

Diagnosing on the live machine is fine — `cat`, `ls -l`, `jq`, `docker compose version`, `chezmoi status`, `chezmoi diff` etc. are all read-only and encouraged. **Mutating** the live machine outside `chezmoi apply` is not.

## Where each kind of change belongs

| Change | Location | Why |
|---|---|---|
| Static, machine-agnostic config (e.g. `starship.toml`, `btop.conf`, `init.lua`) | `dot_config/<app>/...` chezmoi source entry | Plain file target; renders verbatim |
| Adding a Homebrew tool the user invokes | `.chezmoidata.yaml` `packages.brew.*` section | Single source of truth consumed by the install run-script. (Don't forget the README "What `.chezmoidata.yaml` installs" block if the user-facing list needs to reflect it — see docs-sync rule.) |
| Adding a cask (macOS-only) | `.chezmoidata.yaml` `macos.brew.casks` | Same single-file principle. |
| Adding an apt package (Linux-only — retired) | `.chezmoidata.yaml` `linux.apt` or `linux.apt_docker` (re-add when Linux install arm returns) | Same single-file principle. |
| Platform-specific install step (e.g. Colima setup, font install) | `run_once_before_install-packages.sh.tmpl` with `{{ if eq .chezmoi.os "..." }}` branch | Idiomatic chezmoi; OS dispatch happens at template-render time, not via shell `if`. |
| Machine-state file whose correct content depends on a runtime value (`brew --prefix` etc.) | Either a `.tmpl` chezmoi source file (when overwriting is OK) **or** a `run_onchange_before_…sh.tmpl` script (when the file must merge with existing content) | See "When to template vs. when to run-script" below. |
| Cleanup of stale state from a tool the install script explicitly replaces | `run_once_after_…sh.tmpl` self-heal block (see convention below) | Old machines with the replaced tool have cruft; fresh machines have none. The block must no-op on fresh machines. |
| Random pre-existing cruft unrelated to a replaced tool | README "Post-removal cleanup" area, manual | Not the install run-script's job to clean arbitrary user state. |
| Anything at source root that isn't a deployable config (README, AGENTS, opencode runtime artifacts) | Add an entry to `.chezmoiignore` | Otherwise it deploys to `$HOME` on next apply. |

## When to template vs. when to run-script (for arch-conditional content)

The legacy rule — "if the file's content contains a path, version, or arch-conditional value, it belongs in the install script, not a Stow package" — no longer applies wholesale. chezmoi gives two tools, and the choice depends on whether the target file is fully owned by the repo or whether the repo must *merge* with whatever else the user (or another tool) wrote there.

### Case A: Template (`dot_<file>.tmpl`)

Use when the repo is the single owner of the target file's content. The template fully overwrites the destination on `chezmoi apply`.

Canonical case in this repo: `dot_zprofile.tmpl` → `~/.zprofile`. The whole file is the brew shellenv line; nothing else competes for that namespace. The template probes `/opt/homebrew/bin/brew` and `/usr/local/bin/brew` via `stat` (NOT `lookPath` — chezmoi's process PATH may not include a just-installed brew; see "Apply order and PATH" below) and emits the appropriate `eval "$(<brew path> shellenv)"` line. Zero arch branches, zero hardcoded paths. (Linuxbrew candidate paths are retired; reinstate them when the Linux install arm returns.)

**Caveat:** on a truly fresh machine where brew is not yet installed, the template renders to an empty file. A subsequent `chezmoi apply` (after brew is installed) fills it in. Don't gate the template on `lookPath "brew"` — `lookPath` is cached and won't re-resolve after the install run-script puts brew on disk.

### Case B: Run-script that patches in place (`run_onchange_before_<name>.sh.tmpl`)

Use when the target file is NOT fully owned by the repo and the patch must merge with whatever the user or other tools wrote. The run-script receives no stdin but reads the existing target, transforms it (typically with `jq`), and writes the result back.

Canonical case in this repo: `run_onchange_before_configure-docker-cli-plugins.sh.tmpl` writes `~/.docker/config.json`. That file is NOT managed as a chezmoi source entry — it lives outside `~/.local/share/chezmoi/` and is jq-patched at apply time. The patch:

- Adds the brew `cli-plugins` dir to `cliPluginsExtraDirs` (idempotent — `jq '… | index($dir) then . else … + [$dir] …'`).
- Removes `credsStore == "desktop"` (the Docker Desktop credential helper Colima replaces).
- Preserves every other key (`currentContext`, `auths`, etc.) — a templated overwrite would clobber them.

The `onchange_` prefix means the script only runs when the script's own source content changes; re-applies with a stable script don't churn the target file's mtime once the patch is in place. The `before_` prefix means it runs in step 4 of the application order (before file targets are written) — but it doesn't write a chezmoi-managed file, so the ordering matters only relative to run-scripts whose template logic might read its output.

**Rule of thumb:** if the file is named `<file>.tmpl` under the source root, the template fully owns the target — pick this only if you're sure no one else (user, GUI app, another run-script) writes to that target. Otherwise, the patch belongs in a `run_onchange_before_<name>.sh.tmpl` and the target file is left unmanaged by chezmoi.

## Apply order and PATH (read before adding templates that call `output`)

chezmoi application order (per [chezmoi docs](https://www.chezmoi.io/reference/application-order/)):

1. Read source state.
2. Read destination state.
3. Compute target state.
4. Run `run_before_` scripts (in alphabetical order).
5. Update target entries (files, dirs, externals, plain `run_` scripts, symlinks) in alphabetical order of **target name** (after attribute stripping).
6. Run `run_after_` scripts.

This means `run_once_before_install-packages.sh.tmpl` (step 4) installs Homebrew **before** any `*.tmpl` file target renders (step 5). But there's a wrinkle: chezmoi's own process PATH is **not** updated when a `before_` script installs brew. So:

- `output "brew" "--prefix"` in a template will *fail with a template error* on a machine where brew was just installed by the preceding `before_` script — chezmoi's PATH is the shell PATH as of `chezmoi apply` invocation, and the install script's `eval "$(.../brew shellenv)"` only updates the *script's* subshell.
- `lookPath "brew"` likewise returns empty because (a) brew isn't on the parent PATH and (b) `lookPath` caches its first result.

**Therefore:** templates that need brew's location must use `stat "/opt/homebrew/bin/brew"` and `stat "/usr/local/bin/brew"` to probe candidate install paths. `stat` returns a truthy structured object if the file exists (no PATH dependency). This pattern is canonical for `dot_zprofile.tmpl` and the docker-cli-plugins run-script — copy it for any new template that needs to know where brew landed. (Re-add `stat "/home/linuxbrew/.linuxbrew/bin/brew"` and `stat (joinPath .chezmoi.homeDir ".linuxbrew/bin/brew")` when the Linux install arm returns.)

Run-scripts themselves are bash and can `eval "$(.../brew shellenv)"` in-process to update their own PATH, exactly as the legacy install scripts did. That's how `run_once_before_install-packages.sh.tmpl` makes its subsequent `brew install …` lines find brew after a fresh Homebrew install.

## Self-heal convention

A run-script sometimes replaces a tool the user previously had (e.g. Docker Desktop → Colima on macOS). On machines that had the old tool, stale state may linger (broken symlinks pointing at a removed `.app`). On fresh machines that state doesn't exist. The self-heal run-script block must:

1. **No-op on fresh machines** — guard on the existence of the stale state, not on a blanket remove.
2. **Only act on broken symlinks** — `[ -L "$link" ] && [ ! -e "$link" ]`. A working brew link for the same name must be left alone.
3. **Never abort the apply when sudo can't prompt** — `sudo rm ... 2>/dev/null || echo "hint"`. Under `set -euo pipefail` (when present) a failed sudo must not crash the apply; it should print an actionable message and continue. The Docker-Desktop cleaner block deliberately omits `set -e` for this reason.
4. **Print the manual equivalent in the hint** so a non-interactive apply leaves the user a copy-pasteable command.

See `.chezmoiscripts/run_once_after_cleanup-docker-desktop-symlinks.sh.tmpl` for the reference pattern.

## Install run-script conventions

- **Idempotent.** Running `chezmoi apply` twice produces the same state. The `once_` script guards (re-runs only when the script's source content changes) and `onchange_` (re-runs only when the source content differs from the last-run hash) make this strict for the install scripts; `brew install` is free for already-installed formulae; `jq` patches must guard against duplicates (`if … | index($x) then . else … + [$x] …`).
- **No secrets.** Never inline an API key, token, or password. Reference environment variables only; fetch them via the password manager CLI at shell startup (see README "Secret hygiene").
- **Architecture-agnostic.** Use `stat` to probe brew paths, `output "brew" "--prefix"` only after confirming it's already on PATH for the chezmoi process. Never hardcode `/usr/local` or `/opt/homebrew` into a non-template source file or a non-templated run-script.
- **OS dispatch via template, not shell.** `{{ if eq .chezmoi.os "darwin" }} … {{ else if eq .chezmoi.os "linux" }} … {{ else }}{{ fail "…" }}{{ end }}` keeps the install logic in one file. Do not split install logic into per-OS files.
- **One tool per concept.** Don't install two tools that do the same job unless one explicitly replaces the other (and there's a self-heal block for the replaced one).
- **Order matters.** Use `before_` for the package-install run-script so brew is on disk before template files that need `brew --prefix` render. Use `after_` for cleanup chores that should only run once config is in place. (The Linux-only `set-default-shell` script was `after_`; it is retired for now — reintroduce it as `after_` alongside the Linux install arm, since `chsh -s zsh` is a final-state fixup, not a prerequisite for anything else.)

## Source state conventions

- **Static config files are plain files.** No `.tmpl` suffix unless they actually use `{{ }}` directives.
- **Target path is encoded in the source filename.** `dot_zshrc` → `~/.zshrc`; `dot_config/btop/btop.conf` → `~/.config/btop/btop.conf`. The README's "rules that matter" — get the `dot_` / `dot_config/` nesting right and everything works.
- **Use `private_` on sensitive targets.** `~/.ssh/config`, `~/.netrc`, etc. (none currently). Drop group/world perms.
- **Use `executable_` on shell-script targets that the user runs directly.** (None currently — `banner.sh` is `source`d, not executed.)
- **No secrets, no history, no machine-specific state.** If an app writes session/auth state into its config dir, that dir is either untracked or selectively excluded via `.chezmoiignore` (see README "What is and isn't tracked" and the opencode-runtime-artifacts entries in `.chezmoiignore`).
- **Editing a deployed file does NOT edit the source.** This is the inverse of the legacy Stow symlink model. To persist a live edit: `chezmoi re-add <path>` (live → source) or `chezmoi edit <path>` (open source, edit, then `chezmoi apply`).

## `.chezmoiignore` is mandatory for non-config source-root entries

Anything at the source root that isn't a deployable config **must** be listed in `.chezmoiignore` — otherwise it deploys to `$HOME` on `chezmoi apply`.

Current non-config entries to keep ignored:

- `README.md`, `AGENTS.md`, `LICENSE` — repo metadata.
- `test/` — the Docker test harness (NOT a chezmoi package, never deployable).
- `.config/opencode/node_modules`, `.config/opencode/package.json`, `.config/opencode/package-lock.json`, `.config/opencode/.gitignore`, `.config/opencode/*.bak`, `.config/opencode/plugins/` — opencode runtime artifacts (opencode writes these into `~/.config/opencode/` on first run; tracked here so `chezmoi update` pulls them but NEVER deployed — they're noise in `$HOME`'s config dir).

Note: under the legacy Stow symlink model, the directory-symlink shape meant opencode's runtime writes leaked back into the working tree. Under chezmoi the live `~/.config/opencode/` is a real directory, so runtime writes stay in `$HOME` — more hygienic — and we track + ignore the artifacts in source instead.

Lint `.chezmoiignore` whenever source layout changes:

```bash
chezmoi ignored        # what's currently ignored
chezmoi unmanaged     # anything chezmoi sees in source but isn't managing — flags drift
```

## Docs-sync rule (hard convention)

`.chezmoidata.yaml` (the authoritative package inventory) and the README "What `.chezmoidata.yaml` installs" block both describe the package set. **They must stay in sync.** When you add or change a formula/cask/npm package in `.chezmoidata.yaml`, update the corresponding README block in the same change. AGENTS.md treats drift between them as a defect.

The README description is grouped by platform with prose summaries, not line-for-line; `.chezmoidata.yaml` is the authoritative source. If they disagree, `.chezmoidata.yaml` is truth and the README is the bug — but AGENTS.md requires you to fix the README in the same change rather than leave a known mismatch. The two-location hazard that motivated this rule under Stow (`brew-packages.sh` *and* the README install blocks *and* the install scripts) is now down to two locations — closing one of the long-standing gaps that drove this migration.

## Workflow for fixing an environment issue

1. **Diagnose** with read-only commands (`which`, `ls -l`, `--version`, `jq`, `colima status`, `chezmoi status`, `chezmoi diff`). Don't mutate.
2. **Identify the location** using the decision table above.
3. **Edit the source file** — a chezmoi-named entry (`dot_config/<app>/…`), a `.chezmoiscripts/run_*` template, or `.chezmoidata.yaml`.
4. **Run `chezmoi apply`** end-to-end (or `chezmoi apply <path>` for a single-target iterate). Don't skip steps; don't run only the new lines.
5. **Verify the originally-failing command.** Don't declare success from reading the template.
6. **Update README** if its install lines drifted (docs-sync rule). Update `.chezmoiignore` if you added a non-config source-root entry.
7. **Commit only if the user asks.** The user explicitly requests commits; otherwise leave changes in the working tree.

## Verification rule (hard)

Before declaring a task done, run `chezmoi apply` end-to-end on the working source state (or `chezmoi init --apply <repo>` from a fresh HOME for full from-scratch verification). Reading the template is not verification. Running only the new lines is not verification. `chezmoi apply`'s job is to converge a machine from any prior state; verifying that requires actually running it.

Lessons from the Stow era carry over:

- `chezmoi status` and `chezmoi diff` reveal what an apply would change without mutating — the equivalent of `stow -R -v -n` (dry-run) under the old model.
- `chezmoi verify` exits non-zero if anything in `$HOME` differs from source — useful as a CI gate.
- `chezmoi managed` lists all source-state entries; `chezmoi unmanaged` lists anything in source that isn't being managed (useful for catching `.chezmoiignore` drift).

If a `run_*` script step requires sudo and your environment can't prompt (no TTY), the self-heal block will print a manual hint. In that case:

- **Report it explicitly.** Don't claim the sudo step succeeded.
- **Verify the steps that don't need sudo** (brew install, jq patch, file writes) actually worked.
- **Tell the user to run `chezmoi apply` themselves** in a real terminal to exercise the sudo path (the Docker Desktop broken-symlink cleanup, if present).

False success claims are the worst AGENTS.md violation. Ambient silence about a skipped sudo path is the second-worst.

## Don'ts

- Don't mutate live machine state outside `chezmoi apply`. Diagnose freely; mutate via the apply.
- Don't edit deployed files (`~/.zshrc`, `~/.config/nvim/init.lua`) directly — that edits a copy, not the source. Use `chezmoi edit <target>` or `chezmoi re-add <target>`.
- Don't commit secrets. Audit `.chezmoirc` / `dot_zshrc` and any config with `op read` calls before the first commit on a new chezmoi source entry.
- Don't add a tool to `.chezmoidata.yaml` without checking it's not already covered by another formula/cask entry (avoid duplicates).
- Don't add a non-templated source file whose content depends on `brew --prefix`, a username, or a version — that goes in a `.tmpl` (with `stat`/`output`) or a `run_onchange_*` script.
- Don't claim a fix works without running `chezmoi apply` end-to-end.
- Don't update README install blocks without updating `.chezmoidata.yaml` to match, or vice versa (docs-sync rule).
- Don't add a source-root entry (file or directory) that isn't a deployable config without adding it to `.chezmoiignore`.
- Don't use `output "brew" "--prefix"` in a template evaluated on a fresh machine — use `stat` probes on candidate install paths instead (see "Apply order and PATH" above).

## Pointers

- **README.md** — full project context, chezmoi source layout, theme policy, fresh-machine setup. Read it for the big picture; AGENTS.md is for *how to make changes safely*.
- **.chezmoidata.yaml** — static package inventory. Single source of truth consumed by `run_once_before_install-packages.sh.tmpl`. Add brew formulae / casks / npm globals here. (The `linux:` apt section is retired; reintroduce it with the Linux install arm.)
- **.chezmoi.toml.tmpl** — init config template. Fails early if git missing.
- **.chezmoiignore** — non-config source-root entries that must never deploy to `$HOME`.
- **.chezmoiscripts/run_once_before_install-packages.sh.tmpl** — the install logic. macOS-only via `{{ if eq .chezmoi.os "darwin" }}`; the `{{ else }}` arm fails fast. Replaces the legacy `bootstrap.sh` + `install-mac.sh` + `install-linux.sh` + `brew-packages.sh` quartet. (Linux arm retired — re-add the `{{ else if eq .chezmoi.os "linux" }}` branch to bring it back.)
- **.chezmoiscripts/run_onchange_before_configure-docker-cli-plugins.sh.tmpl** — jq merge on `~/.docker/config.json` (macOS only).
- **.chezmoiscripts/run_once_after_cleanup-docker-desktop-symlinks.sh.tmpl** — self-heal for stale Docker Desktop symlinks (macOS only).
- **dot_zprofile.tmpl** — `~/.zprofile` (brew shellenv line, resolved via `stat` on candidate brew paths: `/opt/homebrew/bin/brew`, `/usr/local/bin/brew`).
- **dot_config/**, **dot_zshrc**, **dot_zshenv** — config packages, chezmoi-named.
- **`test/`** — *retired.* Was a Docker-based test harness for the Ubuntu apply path; removed when the Linux install path was retired. Re-add it alongside the Linux install arm.