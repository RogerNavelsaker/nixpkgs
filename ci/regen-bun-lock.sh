#!/usr/bin/env bash
# Regenerate bun.lock and bun.nix when .nixpkg-sync.json sets "bun_lock": true. No-op otherwise or without package.json.
# Same command the repos ran before central sync: bun install --lockfile-only && bun x bun2nix -o bun.nix
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$(git rev-parse --show-toplevel)"
. "$HERE/lib.sh"
if [ "$(cfg bun_lock)" != true ]; then echo "bun_lock not enabled; skipping"; exit 0; fi
[ -f package.json ] || { echo "bun_lock set but package.json missing; skipping"; exit 0; }
nix shell nixpkgs#bun -c sh -c 'bun install --lockfile-only && bun x bun2nix -o bun.nix'
