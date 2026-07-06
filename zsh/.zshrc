# ============================================================================
# ainative .zshrc -- a snappy, demo-friendly zsh
# ============================================================================

# ---- History --------------------------------------------------------------
HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS INC_APPEND_HISTORY EXTENDED_HISTORY

# ---- Options --------------------------------------------------------------
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
setopt INTERACTIVE_COMMENTS NO_BEEP PROMPT_SUBST
setopt COMPLETE_IN_WORD ALWAYS_TO_END

# ---- bun ------------------------------------------------------------------
export BUN_INSTALL="$HOME/.bun"

# ---- PATH -----------------------------------------------------------------
typeset -U path
path=(
  $HOME/.local/bin
  $HOME/.opencode/bin
  $HOME/.bun/bin
  /usr/local/bin
  $path
)

# bun completions
[ -s "/Users/kevinryan/.bun/_bun" ] && source "/Users/kevinryan/.bun/_bun"

# ---- Zinit (plugin manager) ----------------------------------------------
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ ! -d $ZINIT_HOME ]]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone --depth 1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" 2>/dev/null
fi
source "$ZINIT_HOME/zinit.zsh"

# Annexes (recommended)
zinit light-mode for \
  zdharma-continuum/zinit-annex-as-monitor \
  zdharma-continuum/zinit-annex-bin-gem-node \
  zdharma-continuum/zinit-annex-patch-dl \
  zdharma-continuum/zinit-annex-rust

# Plugins -- turbo loaded after prompt for snappy startup
zinit wait lucid for \
  atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
  atload"_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
  blockf atpull'zinit creinstall -q .' \
    zsh-users/zsh-completions \
  Aloxaf/fzf-tab

# ---- Completion styling --------------------------------------------------
zstyle ':completion:*' menu no
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always --icons $realpath'

# ---- fzf ------------------------------------------------------------------
source <(fzf --zsh)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="
  --highlight-line
  --info=inline-right
  --ansi
  --layout=reverse
  --border=none
  --color=bg+:#2f334d
  --color=bg:#222436
  --color=border:#0db9d7
  --color=fg:#c8d3f5
  --color=gutter:#222436
  --color=header:#ff966c
  --color=hl+:#86e1fc
  --color=hl:#86e1fc
  --color=info:#636da6
  --color=marker:#c099ff
  --color=pointer:#c099ff
  --color=prompt:#86e1fc
  --color=query:#c8d3f5:regular
  --color=scrollbar:#0db9d7
  --color=separator:#ff966c
  --color=spinner:#c099ff
"

# ---- zoxide ---------------------------------------------------------------
eval "$(zoxide init zsh)"

# ---- Starship prompt ------------------------------------------------------
eval "$(starship init zsh)"

# ---- Aliases --------------------------------------------------------------
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --git --group-directories-first'
alias la='eza -la --icons --git --group-directories-first'
alias lt='eza --tree --icons --level=2'
alias cat='bat --paging=never'
alias less='bat --paging=always'
alias grep='grep --color=auto'
alias diff='delta'
alias g='git'
alias lg='lazygit'
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias k='kubectl'
alias d='docker'
alias dc='docker compose'
alias tf='terraform'
alias oc='opencode'

# Safer defaults
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# Quick reload
alias reload='exec zsh'

# ---- Bat theme ------------------------------------------------------------
export BAT_THEME="tokyonight_moon"

# ---- Tool-specific env ----------------------------------------------------
export OPENSPEC_TELEMETRY=0   # disable OpenSpec anonymous usage stats

# ---- Editor ---------------------------------------------------------------
export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export LESS='-R --use-color -Dd+r$Du+b'

# ---- Banner ---------------------------------------------------------------
if [[ -o interactive && -f "$HOME/.config/ainative/banner.sh" ]]; then
  source "$HOME/.config/ainative/banner.sh"
fi

