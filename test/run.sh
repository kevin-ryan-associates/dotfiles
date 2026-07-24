#!/usr/bin/env bash
# Build and run the dotfiles test image.
#   bash test/run.sh            # local flavor (tests `chezmoi apply` against your working tree)
#   bash test/run.sh published  # published flavor (real `chezmoi init --apply` one-liner vs main)
set -euo pipefail

FLAVOR="${1:-local}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

echo "==> Building dotfiles-test:$FLAVOR (context: $REPO_ROOT)"
docker build --target "$FLAVOR" -t "dotfiles-test:$FLAVOR" -f test/Dockerfile .

echo "==> Build OK; running container sanity check..."
docker run --rm "dotfiles-test:$FLAVOR"
echo "==> $FLAVOR test PASSED"
