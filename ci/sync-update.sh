#!/usr/bin/env bash
# Run the caller's sync step. Uses sync_script from .nixpkg-sync.json, else the standard fallbacks.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$(git rev-parse --show-toplevel)"
. "$HERE/lib.sh"
script=$(cfg sync_script)
if [ -n "$script" ]; then bash -c "$script"
elif [ -f ./update.sh ]; then bash ./update.sh
elif [ -f package.json ] && grep -q '"sync:source"' package.json; then nix shell nixpkgs#bun -c sh -c 'bun run sync:source'
elif [ -f scripts/sync-from-github.sh ]; then bash scripts/sync-from-github.sh
elif [ -f scripts/sync-from-upstream.sh ]; then bash scripts/sync-from-upstream.sh
else nix run nixpkgs#nix-update -- --flake default
fi
