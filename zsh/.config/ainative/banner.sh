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

# Dark / techy neon palette (terminal-hacker vibe).
local C_CYAN=$'\e[38;2;0;229;255m'      # neon cyan
local C_CYAN_D=$'\e[38;2;0;160;200m'    # deep cyan
local C_GREEN=$'\e[38;2;0;255;140m'     # matrix green
local C_GREEN_D=$'\e[38;2;0;180;100m'   # deep green
local C_MAG=$'\e[38;2;255;0;200m'       # neon magenta
local C_MAG_D=$'\e[38;2;180;0;160m'     # deep magenta
local C_BLUE=$'\e[38;2;60;120;255m'     # electric blue
local C_AMBER=$'\e[38;2;255;176;0m'     # amber
local C_TEXT=$'\e[38;2;200;210;220m'    # soft white
local C_DIM=$'\e[38;2;90;100;115m'      # slate dim
local BOLD=$'\e[1m'
local DIM=$'\e[2m'
local RST=$'\e[0m'

# "AI NATIVE" rendered in ANSI Shadow style, all in matrix green.
print
print "${C_GREEN} █████╗ ██╗${C_DIM}    ${C_GREEN}███╗   ██╗ █████╗ ████████╗██╗██╗   ██╗███████╗${RST}"
print "${C_GREEN}██╔══██╗██║${C_DIM}    ${C_GREEN}████╗  ██║██╔══██╗╚══██╔══╝██║██║   ██║██╔════╝${RST}"
print "${C_GREEN}███████║██║${C_DIM}    ${C_GREEN}██╔██╗ ██║███████║   ██║   ██║██║   ██║█████╗  ${RST}"
print "${C_GREEN_D}██╔══██║██║${C_DIM}    ${C_GREEN_D}██║╚██╗██║██╔══██║   ██║   ██║╚██╗ ██╔╝██╔══╝  ${RST}"
print "${C_GREEN_D}██║  ██║██║${C_DIM}    ${C_GREEN_D}██║ ╚████║██║  ██║   ██║   ██║ ╚████╔╝ ███████╗${RST}"
print "${C_DIM}╚═╝  ╚═╝╚═╝    ╚═╝  ╚═══╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═══╝  ╚══════╝${RST}"
print

# Sub-banner: tools / versions
local nvim_v=$(nvim --version 2>/dev/null | head -n 1 | awk '{print $2}')
local zsh_v=$ZSH_VERSION
local node_v=$(node -v 2>/dev/null)
local py_v=$(python3 -V 2>/dev/null | awk '{print $2}')

print "  ${BOLD}${C_GREEN}»${RST} ${C_TEXT}nvim${RST} ${C_DIM}${nvim_v}${RST}   ${BOLD}${C_GREEN}»${RST} ${C_TEXT}zsh${RST} ${C_DIM}${zsh_v}${RST}   ${BOLD}${C_GREEN}»${RST} ${C_TEXT}node${RST} ${C_DIM}${node_v}${RST}   ${BOLD}${C_GREEN}»${RST} ${C_TEXT}python${RST} ${C_DIM}${py_v}${RST}"
print "  ${DIM}${C_DIM}// ai-native development environment${RST}"
print
