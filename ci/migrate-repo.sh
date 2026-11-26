#!/usr/bin/env bash
# Usage: ci/migrate-repo.sh <repo-path>
# Writes thin caller workflows and a .nixpkg-sync.json skeleton. Idempotent, no network.
# Existing .nixpkg-sync.json is kept; workflow files are rewritten (cron minute kept if present).
set -euo pipefail
repo=${1:?usage: migrate-repo.sh <repo-path>}
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# Repo name: origin URL basename (no .git); else the container dir (parent or grandparent holding a main/ checkout); else the dir basename.
repo_name() {
  local dir url name up
  url=$(git -C "$1" remote get-url origin 2>/dev/null || true)
  if [ -n "$url" ]; then
    name=${url%/}; name=${name##*[/:]}; echo "${name%.git}"; return
  fi
  dir=$(cd "$1" && pwd -P)
  for up in "$(dirname "$dir")" "$(dirname "$(dirname "$dir")")"; do
    if [ -d "$up/main" ]; then basename "$up"; return; fi
  done
  basename "$dir"
}
[ -d "$repo/.git" ] || [ -f "$repo/.git" ] || { echo "not a git checkout: $repo" >&2; exit 1; }
wf="$repo/.github/workflows"; mkdir -p "$wf"
cp "$here/templates/ci.yml" "$wf/ci.yml"
minute=$(grep -oE 'cron: "[0-9]+ ' "$wf/sync-upstream.yml" 2>/dev/null | grep -oE '[0-9]+' | head -n1 || true)
if [ -z "$minute" ]; then
  name=$(repo_name "$repo")
  minute=$(( $(printf '%s' "$name" | cksum | cut -d' ' -f1) % 60 ))
fi
sed "s/__MINUTE__/$minute/" "$here/templates/sync-upstream.yml" > "$wf/sync-upstream.yml"
[ -f "$repo/.nixpkg-sync.json" ] || cp "$here/templates/nixpkg-sync.json" "$repo/.nixpkg-sync.json"
echo "migrated $repo (cron minute $minute); edit .nixpkg-sync.json kind/upstream/version_file"
