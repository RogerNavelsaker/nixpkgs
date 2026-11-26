#!/usr/bin/env bash
# Verify flake.nix/flake.lock mirror the remote RogerNavelsaker/nixpkg-* repos.
# Env: OWNER, CHECK_WINDOW_HOURS (default 24), CHECK_OFFLINE=1 (run local checks only; skip remote list + staleness),
#      INCLUDE_PRIVATE=1 (count private repos).
set -uo pipefail
cd "$(dirname "$0")/.."

OWNER="${OWNER:-RogerNavelsaker}"
WINDOW_SECONDS=$(( ${CHECK_WINDOW_HOURS:-24} * 3600 ))
fail=0
bad() { echo "FAIL: $*" >&2; fail=1; }

# local checks
grep -nE '(url *= *"|\.url *= *")path:' flake.nix | while read -r l; do echo "FAIL: path: input in flake.nix: $l" >&2; done
grep -qE '\.url *= *"path:|url *= *"path:' flake.nix && fail=1
if jq -e '[.nodes[]?.locked?.type? // empty] | any(. == "path")' flake.lock >/dev/null; then bad "flake.lock contains a path: input"; fi
links=$(git ls-files -s | awk '$1=="120000"{print $4}')
[ -z "$links" ] || bad "tracked symlinks: $(echo "$links" | paste -sd' ')"

inputs=$(grep -oE '^    nixpkg-[a-z0-9-]+\.url' flake.nix | sed -E 's/^ +//; s/\.url$//' | sort)

if [ "${CHECK_OFFLINE:-0}" = 1 ]; then
  echo "SKIP: remote repo list and staleness checks (CHECK_OFFLINE=1)"
  [ "$fail" = 0 ] && echo "OK (offline)"; exit "$fail"
fi

remote=$(gh repo list "$OWNER" --limit 500 --json name,isArchived,visibility \
  --jq '.[] | select(.name | startswith("nixpkg-")) | select(.isArchived | not) | select(.visibility == "PUBLIC" or env.INCLUDE_PRIVATE == "1") | .name' | sort)
[ -n "$remote" ] || { echo "FAIL: no remote nixpkg-* repos found" >&2; exit 1; }
if [ -f scripts/meta-flake-exclude.txt ]; then
  remote=$(comm -23 <(echo "$remote") <(grep -vE '^(#|$)' scripts/meta-flake-exclude.txt | sort))
fi

missing=$(comm -13 <(echo "$inputs") <(echo "$remote"))
stale=$(comm -23 <(echo "$inputs") <(echo "$remote"))
[ -z "$missing" ] || bad "remote repos without input: $(echo "$missing" | paste -sd' ')"
[ -z "$stale" ] || bad "inputs pointing to missing/archived repos: $(echo "$stale" | paste -sd' ')"

# staleness: locked rev older than remote default-branch HEAD by more than the window
for n in $(comm -12 <(echo "$inputs") <(echo "$remote")); do
  echo "$n"
done | xargs -P 8 -I{} bash -c '
  n={}
  locked=$(jq -r --arg n "$n" ".nodes[\$n] | \"\(.locked.rev) \(.locked.lastModified)\"" flake.lock)
  rev=${locked% *}; lm=${locked#* }
  head=$(gh api "repos/'"$OWNER"'/$n/commits/HEAD" --jq "\"\(.sha) \(.commit.committer.date)\"" 2>/dev/null) || { echo "FAIL: cannot read HEAD of $n" >&2; exit 0; }
  sha=${head% *}; hd=$(date -d "${head#* }" +%s)
  [ "$sha" = "$rev" ] && exit 0
  age=$(( hd - lm ))
  [ "$age" -le '"$WINDOW_SECONDS"' ] || echo "FAIL: $n lock is $(( age / 3600 ))h behind remote HEAD (${rev:0:7} -> ${sha:0:7})" >&2
' 2>&1 | tee /dev/stderr | grep -q '^FAIL' && fail=1

[ "$fail" = 0 ] && echo "OK: ${inputs:+$(echo "$inputs" | wc -l)} nixpkg-* inputs match remote, no path/symlink, locks within ${CHECK_WINDOW_HOURS:-24}h"
exit "$fail"
