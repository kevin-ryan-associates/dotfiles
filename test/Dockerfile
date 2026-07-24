# syntax=docker/dockerfile:1
#
# Test harness for the Ubuntu chezmoi apply path. Two flavors:
#   local     — COPYs the repo, runs `chezmoi init --source=...` + `chezmoi apply`
#               directly (fast iteration on local changes)
#   published — runs the real chezmoi one-liner against main (release verification)
#
# Build/run via: bash test/run.sh          (local)
#                bash test/run.sh published
#
# See test/README.md for what this tests and what it deliberately does not.

ARG UBUNTU_VERSION=24.04

# =============================================================================
# Base stage: apt prereqs + non-root user. Independent of the apply path — just
# prepares an image that can run chezmoi and its install run-script (which does
# its own apt/brew installs at apply time).
# =============================================================================
FROM ubuntu:${UBUNTU_VERSION} AS base
ARG DEBIAN_FRONTEND=noninteractive

# Chezmoi install needs curl + ca-certificates to fetch the binary. The apply
# run-script installs everything else (zsh, git-curl-file-ca-certs, build-essential,
# procps, fontconfig, unzip) via apt itself — but to get to first apply we need
# the bootstrap: curl, ca-certificates, gpg (for the chezmoi install signature
# check), sudo (so the run-script's apt/chsh steps work non-interactively).
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         sudo curl ca-certificates gnupg git \
    && rm -rf /var/lib/apt/lists/*

# Install chezmoi from the official one-liner. Single Go binary; the run-script
# handles its own brew dependency installs at apply time.
RUN sh -c "$(curl -fsSL https://chezmoi.io/get)" -- -b /usr/local/bin

# Non-root user with passwordless sudo so the apply run-script can run apt/chsh
# without a TTY prompt. Login shell is zsh (installed by the apply run-script's
# apt step) so the container mirrors a real Ubuntu machine after `chsh`.
RUN useradd -m -s /usr/bin/zsh dotfiles \
    && echo "dotfiles ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# TTY-aware entrypoint: `docker run -it` drops into zsh; headless `docker run` exits 0.
COPY test/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER dotfiles
WORKDIR /home/dotfiles
ENV HOME=/home/dotfiles
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# =============================================================================
# Flavor 1: local-state — tests the chezmoi apply path against the working tree.
# The repo is COPY'd in (no .git, so we skip `chezmoi init`'s clone half). We
# write a minimal chezmoi config that points chezmoi at the COPY'd source so
# subsequent `chezmoi managed`/`verify`/`apply` commands in assertions.sh
# resolve the right source without needing `--source` flag on every invocation.
# =============================================================================
FROM base AS local
COPY --chown=dotfiles:dotfiles . /home/dotfiles/dotfiles
RUN mkdir -p /home/dotfiles/.config/chezmoi \
    && printf 'sourceDir = "/home/dotfiles/dotfiles"\n' \
        > /home/dotfiles/.config/chezmoi/chezmoi.toml
RUN chezmoi apply
RUN bash /home/dotfiles/dotfiles/test/assertions.sh
# Default interactive shell — `docker run -it dotfiles-test:local` drops into zsh
# with the full configured environment (starship, plugins, aliases).
# Headless `docker run` exits 0 via the inherited TTY-aware entrypoint.

# =============================================================================
# Flavor 2: published-contract — tests the real public one-liner against main.
# `chezmoi init --apply kevin-ryan-associates/dotfiles` clones the source over
# HTTPS and applies end-to-end. Use this for release verification (post-push);
# requires test/ to be on main already.
# =============================================================================
FROM base AS published
RUN chezmoi init --apply kevin-ryan-associates/dotfiles
RUN bash /home/dotfiles/dotfiles/test/assertions.sh