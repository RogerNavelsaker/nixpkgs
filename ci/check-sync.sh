#!/usr/bin/env bash
# Central sync checks for nixpkg-* repos. Run from (or inside) a caller checkout; reads .nixpkg-sync.json.
# One PASS/FAIL/SKIP line per check; exit non-zero on any FAIL.
# Env: CHECK_OFFLINE=1 skips network checks; BASE_REF=<ref> enables the bump-on-change check;
#      SYNC_CONFIG=<file> overrides .nixpkg-sync.json; GH_TOKEN used by `gh api` for github-release.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$(git rev-parse --show-toplevel)" || exit 2
# shellcheck source=lib.sh
. "$HERE/lib.sh"

fail=0
pass() { echo "PASS  $1"; }
skip() { echo "SKIP  $1"; }
bad()  { echo "FAIL  $1"; fail=1; }
check() { local name=$1; shift; if "$@" >/dev/null 2>&1; then pass "$name"; else bad "$name"; fi; }

[ -f "$SYNC_CONFIG" ] && jq -e . "$SYNC_CONFIG" >/dev/null 2>&1 || { echo "FAIL  $SYNC_CONFIG missing or invalid JSON"; exit 1; }

KIND=$(cfg kind); UPSTREAM=$(cfg upstream); TAG_REGEX=$(cfg tag_regex); TAG_PREFIX=$(cfg tag_prefix)
VERSION_FILE=$(cfg version_file)
CACHIX_NAME=$(cfg cachix_name); CACHIX_NAME=${CACHIX_NAME:-rogernavelsaker}
SYNC_WORKFLOW=$(cfg sync_workflow); SYNC_WORKFLOW=${SYNC_WORKFLOW:-.github/workflows/sync-upstream.yml}
PINNED_FLAKE_REGEX=$(cfg pinned_flake_regex)
mapfile -t PINNED_PATHS < <(cfg_list pinned_paths)
case "$KIND" in git-tag|github-release|npm|pypi|git-head|none) ;; *) echo "FAIL  unknown kind '$KIND'"; exit 1;; esac

WORKFLOWS=$(ls .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null)
CENTRAL='RogerNavelsaker/nixpkgs/\.github/workflows/reusable-'

no_path_inputs() {
  ! grep -nE '(url|path)[[:space:]]*=[[:space:]]*"path:|inputs\.[A-Za-z0-9_-]+\.url[[:space:]]*=[[:space:]]*"path:' flake.nix &&
  ! { [ -f flake.lock ] && jq -e '[.nodes[]?.locked.type? // empty] | any(. == "path")' flake.lock; }
}
no_local_sync() {
  # cp/rsync/ln/mv of sibling folders (../ or /workspace) inside sync scripts or workflows
  local files; files=$(ls scripts/* 2>/dev/null; echo "$WORKFLOWS")
  ! { echo "$files" | xargs -r grep -nE '(^|[[:space:];&|])(cp|rsync|ln|mv)[[:space:]].*(\.\./|/workspace/)' 2>/dev/null | grep -v 'check-sync.sh'; }
}
sync_schedule() { grep -qE '^[[:space:]]*schedule:' "$SYNC_WORKFLOW" && grep -qE '^[[:space:]]*-[[:space:]]*cron:' "$SYNC_WORKFLOW"; }
sync_commits() {
  grep -qE "$CENTRAL""sync-upstream" "$SYNC_WORKFLOW" || grep -q 'git-auto-commit-action' "$SYNC_WORKFLOW" || grep -q 'git push' "$SYNC_WORKFLOW" || return 1
  ! grep -qE '^[[:space:]]*branch:' "$SYNC_WORKFLOW" # default branch = no explicit target branch
}
cachix_workflow() {
  grep -qE "$CENTRAL""ci" $WORKFLOWS && return 0
  grep -q 'cachix/cachix-action' $WORKFLOWS && grep -qE "name:[[:space:]]*\"?$CACHIX_NAME\"?[[:space:]]*$" $WORKFLOWS
}
cachix_flake() { grep -q "https://$CACHIX_NAME.cachix.org" flake.nix; }
no_npm_publish() {
  ! grep -rnE 'npm publish|NPM_TOKEN' --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=.devenv \
      --exclude=check-sync.sh --exclude='result*' . 2>/dev/null
}

check "no path: flake inputs (flake.nix, flake.lock)" no_path_inputs
check "no local folder-to-folder sync (scripts, workflows)" no_local_sync
if [ "$KIND" = none ]; then
  skip "sync workflow checks (kind none: no upstream sync)"
else
  check "sync workflow has schedule cron ($SYNC_WORKFLOW)" sync_schedule
  check "sync workflow commits to default branch" sync_commits
fi
check "cachix configured (name $CACHIX_NAME)" cachix_workflow
check "flake nixConfig has $CACHIX_NAME substituter" cachix_flake
check "no npm publish / NPM_TOKEN" no_npm_publish

latest_upstream() {
  case "$KIND" in
    git-tag)
      local tags; tags=$(git ls-remote --tags --refs "$UPSTREAM" 2>/dev/null) && [ -n "$tags" ] || return 1
      printf '%s\n' "$tags" | awk '{sub("refs/tags/","",$2); print $2}' | grep -E "${TAG_REGEX:-.}" | sort -V | tail -n1 | sed "s|^$TAG_PREFIX||" ;;
    github-release)
      gh api "repos/$UPSTREAM/releases/latest" -q .tag_name 2>/dev/null | sed "s|^$TAG_PREFIX||" ;;
    npm)  curl -fsS "https://registry.npmjs.org/$UPSTREAM/latest" 2>/dev/null | jq -r .version ;;
    pypi) curl -fsS "https://pypi.org/pypi/$UPSTREAM/json" 2>/dev/null | jq -r .info.version ;;
    git-head) git ls-remote "$UPSTREAM" HEAD 2>/dev/null | awk '{print $1}' ;;
  esac
}

if [ "$KIND" = none ]; then
  skip "manifest version == latest upstream (kind none)"
else
  manifest_version=$(read_version)
  if [ -z "$manifest_version" ] || [ "$manifest_version" = null ]; then
    bad "manifest version readable ($VERSION_FILE)"
  elif [ "${CHECK_OFFLINE:-0}" = 1 ]; then
    skip "manifest version == latest upstream (CHECK_OFFLINE=1)"
  else
    latest=$(latest_upstream)
    if [ -z "$latest" ] || [ "$latest" = null ]; then
      bad "manifest version == latest upstream ($KIND lookup failed; set CHECK_OFFLINE=1 to skip)"
    elif [ "$KIND" = git-head ]; then
      case "$latest" in "$manifest_version"*) pass "pinned rev == upstream HEAD (${latest:0:12})";;
        *) bad "pinned rev $manifest_version != upstream HEAD $latest";; esac
    elif [ "$manifest_version" = "$latest" ]; then pass "manifest version == latest upstream ($latest)"
    else bad "manifest version $manifest_version != latest upstream $latest"; fi
  fi
fi

if [ "$KIND" = none ] || [ -z "$VERSION_FILE" ]; then
  skip "version bump on pinned-source change (kind none / no version_file)"
elif [ -z "${BASE_REF:-}" ]; then
  skip "version bump on pinned-source change (BASE_REF unset)"
elif ! git rev-parse --verify -q "$BASE_REF^{commit}" >/dev/null; then
  bad "version bump on pinned-source change (BASE_REF $BASE_REF not found; use fetch-depth 0)"
else
  base=$(git merge-base "$BASE_REF" HEAD 2>/dev/null || git rev-parse "$BASE_REF")
  changed=""
  if [ "${#PINNED_PATHS[@]}" -gt 0 ] && [ -n "$(git diff --name-only "$base" -- "${PINNED_PATHS[@]}")" ]; then changed="${PINNED_PATHS[*]}"; fi
  if [ -z "$changed" ] && [ -n "$PINNED_FLAKE_REGEX" ] && git diff -U0 "$base" -- flake.nix | grep -E '^[+-][^+-]' | grep -qE "$PINNED_FLAKE_REGEX"; then
    changed="flake.nix pins"
  fi
  if [ -z "$changed" ] && git diff -U0 "$base" -- "$VERSION_FILE" | grep -E '^[+-][^+-]' | grep -vE '"version"' | grep -qE '(rev|hash|sha|tag)'; then
    changed="$VERSION_FILE source rev/hash"
  fi
  if [ -z "$changed" ]; then
    pass "version bump on pinned-source change (no pinned source change vs $BASE_REF)"
  else
    base_version=$(read_version "$base"); manifest_version=$(read_version)
    if [ "$manifest_version" != "$base_version" ]; then pass "version bump on pinned-source change ($base_version -> $manifest_version; changed: $changed)"
    else bad "pinned source changed ($changed) but version still $base_version"; fi
  fi
fi

exit $fail
