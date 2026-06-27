
# bun completions
[ -s "/Users/kevinryan/.bun/_bun" ] && source "/Users/kevinryan/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# opencode
export PATH=/Users/kevinryan/.opencode/bin:$PATH

# BEGIN mac-terminal-setup
# https://github.com/YOUR_USERNAME/mac-terminal-setup
# Order matters here — do not rearrange

# 1. fastfetch — MUST come before p10k instant prompt
fastfetch

# 2. Powerlevel10k instant prompt — MUST be before any output/sourcing
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# 3. Powerlevel10k theme
source /usr/local/share/powerlevel10k/powerlevel10k.zsh-theme
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# 4. zsh plugins
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# 5. Aliases
alias ls='eza --icons --group-directories-first'
alias ll='eza -lah --icons --group-directories-first --git'
alias lt='eza --tree --icons --level=2'
alias la='eza -a --icons'
alias cat='bat --paging=never'

# 6. Tool integrations
eval "$(zoxide init zsh)"
source <(fzf --zsh)
export GIT_PAGER='delta'
# END mac-terminal-setup

