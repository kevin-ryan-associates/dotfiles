# syntax=docker/dockerfile:1
#
# Test harness for the Ubuntu install path. Two flavors:
#   local     — COPYs the repo, runs install-linux.sh directly (fast iteration on local changes)
#   published — runs the real curl|bash one-liner against main (release verification)
#
# Build/run via: bash test/run.sh          (local)
#                bash test/run.sh published
#
# See test/README.md for what this tests and what it deliberately does not.

ARG UBUNTU_VERSION=24.04

# =============================================================================
# Base stage: apt prereqs + non-root user. Independent of the install script — just
# prepares an image that can run Homebrew's installer and bootstrap.sh.
# =============================================================================
FROM ubuntu:${UBUNTU_VERSION} AS base
ARG DEBIAN_FRONTEND=noninteractive

# Homebrew-on-Linux documented prereqs (build-essential, procps, curl, file, git)
# plus sudo (so apt/chsh can run non-interactively) and zsh.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         sudo zsh git curl file ca-certificates build-essential procps \
    && rm -rf /var/lib/apt/lists/*

# Homebrew refuses to install as root. Create a non-root user with passwordless
# sudo so the build can run apt/chsh without a TTY prompt. Login shell is zsh
# (installed in the apt step above) so the container mirrors a real Ubuntu
# machine after `chsh` — herdr and `docker run -it` default to zsh.
RUN useradd -m -s /usr/bin/zsh dotfiles \
    && echo "dotfiles ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER dotfiles
WORKDIR /home/dotfiles
ENV HOME=/home/dotfiles

# =============================================================================
# Flavor 1: local-state — tests install-linux.sh against the working tree.
# The repo is COPY'd in (no .git, so bootstrap's clone/pull is moot); we run
# install-linux.sh directly. This is the fast loop for testing linux changes.
# =============================================================================
FROM base AS local
COPY --chown=dotfiles:dotfiles . /home/dotfiles/dotfiles
RUN bash /home/dotfiles/dotfiles/install-linux.sh
RUN bash /home/dotfiles/dotfiles/test/assertions.sh
# Default interactive shell — `docker run -it dotfiles-test:local` drops into zsh
# with the full configured environment (starship, plugins, aliases).
CMD ["zsh"]

# =============================================================================
# Flavor 2: published-contract — tests the real public one-liner against main.
# bootstrap.sh clones ~/dotfiles over HTTPS, then execs install-linux.sh. Use this
# for release verification (post-push); requires test/ to be on main already.
# =============================================================================
FROM base AS published
RUN curl -fsSL https://raw.githubusercontent.com/kevin-ryan-associates/dotfiles/main/bootstrap.sh | bash
RUN bash /home/dotfiles/dotfiles/test/assertions.sh
