#!/usr/bin/env zsh
# ainative startup banner -- shown once per interactive shell session.
# Disable with: export AINATIVE_NO_BANNER=1

[[ -n "$AINATIVE_NO_BANNER" ]] && return 0
[[ -n "$AINATIVE_BANNER_SHOWN" ]] && return 0
# Skip the banner when running inside Neovim's :terminal / :! / toggleterm.
[[ -n "$NVIM" || -n "$NVIM_LISTEN_ADDRESS" ]] && return 0
export AINATIVE_BANNER_SHOWN=1

# Clear the screen before rendering for a clean stage on every launch.
# Use ANSI escape directly so it works even when TERM is unset (e.g. some
# non-interactive shells docker spawns).
if [[ -t 1 ]]; then
  if [[ -n "$TERM" ]] && command -v clear >/dev/null 2>&1; then
    clear
  else
    printf '\e[H\e[2J\e[3J'
  fi
fi

# Tokyo Night palette (night variant).
local C_BLUE=$'\e[38;2;122;162;247m'      # #7aa2f7
local C_BLUE_D=$'\e[38;2;90;130;220m'     # deep blue
local C_CYAN=$'\e[38;2;125;207;255m'      # #7dcfff
local C_CYAN_D=$'\e[38;2;90;170;230m'     # deep cyan
local C_GREEN=$'\e[38;2;158;206;106m'     # #9ece6a
local C_PURPLE=$'\e[38;2;187;154;247m'    # #bb9af7
local C_TEXT=$'\e[38;2;192;202;245m'      # #c0caf5
local C_DIM=$'\e[38;2;86;95;137m'         # #565f89
local BOLD=$'\e[1m'
local DIM=$'\e[2m'
local RST=$'\e[0m'

# "AI NATIVE" rendered in ANSI Shadow style, all in Tokyo Night blue.
print
print "${C_BLUE} █████╗ ██╗${C_DIM}    ${C_BLUE}███╗   ██╗ █████╗ ████████╗██╗██╗   ██╗███████╗${RST}"
print "${C_BLUE}██╔══██╗██║${C_DIM}    ${C_BLUE}████╗  ██║██╔══██╗╚══██╔══╝██║██║   ██║██╔════╝${RST}"
print "${C_BLUE}███████║██║${C_DIM}    ${C_BLUE}██╔██╗ ██║███████║   ██║   ██║██║   ██║█████╗  ${RST}"
print "${C_BLUE_D}██╔══██║██║${C_DIM}    ${C_BLUE_D}██║╚██╗██║██╔══██║   ██║   ██║╚██╗ ██╔╝██╔══╝  ${RST}"
print "${C_BLUE_D}██║  ██║██║${C_DIM}    ${C_BLUE_D}██║ ╚████║██║  ██║   ██║   ██║ ╚████╔╝ ███████╗${RST}"
print "${C_DIM}╚═╝  ╚═╝╚═╝    ╚═╝  ╚═══╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═══╝  ╚══════╝${RST}"
print

# Sub-banner: tools / versions
local nvim_v=$(nvim --version 2>/dev/null | head -n 1 | awk '{print $2}')
local zsh_v=$ZSH_VERSION
local node_v=$(node -v 2>/dev/null)
local py_v=$(python3 -V 2>/dev/null | awk '{print $2}')

print "  ${BOLD}${C_CYAN}»${RST} ${C_TEXT}nvim${RST} ${C_DIM}${nvim_v}${RST}   ${BOLD}${C_CYAN}»${RST} ${C_TEXT}zsh${RST} ${C_DIM}${zsh_v}${RST}   ${BOLD}${C_CYAN}»${RST} ${C_TEXT}node${RST} ${C_DIM}${node_v}${RST}   ${BOLD}${C_CYAN}»${RST} ${C_TEXT}python${RST} ${C_DIM}${py_v}${RST}"
print "  ${DIM}${C_DIM}// ai-native development environment${RST}"
print
