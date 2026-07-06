#!/usr/bin/env sh
# TTY-aware entrypoint for the dotfiles test image.
# Lets `docker run -it` drop into zsh while keeping `docker run` (headless)
# exit 0 cleanly.

if [ -t 0 ]; then
  # Interactive: default to zsh, or run the command the user passed.
  exec "${@:-zsh}"
else
  # Headless: run an explicit command if given, otherwise just exit 0.
  if [ "$#" -gt 0 ]; then
    exec "$@"
  fi
  exit 0
fi
