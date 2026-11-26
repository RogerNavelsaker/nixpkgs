#!/usr/bin/env bash
# Reconcile flake.nix nixpkg-* inputs with remote RogerNavelsaker/nixpkg-* repos, then bump their locks.
# Env: OWNER (default RogerNavelsaker), INCLUDE_PRIVATE=1 to include private repos (nix needs a token for them), SKIP_LOCK=1 to skip `nix flake update`.
set -euo pipefail
cd "$(dirname "$0")/.."

OWNER="${OWNER:-RogerNavelsaker}"
FLAKE=flake.nix

token="${GH_TOKEN:-${GITHUB_TOKEN:-$(gh auth token 2>/dev/null || true)}}"
[ -z "$token" ] || export NIX_CONFIG="${NIX_CONFIG:-}"$'\n'"access-tokens = github.com=$token"

remote=$(gh repo list "$OWNER" --limit 500 --json name,isArchived,visibility \
  --jq '.[] | select(.name | startswith("nixpkg-")) | select(.isArchived | not) | select(.visibility == "PUBLIC" or env.INCLUDE_PRIVATE == "1") | .name' | sort)
EXCLUDE_FILE=scripts/meta-flake-exclude.txt
if [ -f "$EXCLUDE_FILE" ]; then
  remote=$(comm -23 <(echo "$remote") <(grep -vE '^(#|$)' "$EXCLUDE_FILE" | sort))
fi
[ -n "$remote" ] || { echo "no remote nixpkg-* repos found" >&2; exit 1; }

current=$(grep -oE '^    nixpkg-[a-z0-9-]+\.url' "$FLAKE" | sed -E 's/^ +//; s/\.url$//' | sort)
added=$(comm -13 <(echo "$current") <(echo "$remote"))
removed=$(comm -23 <(echo "$current") <(echo "$remote"))

block=$(while read -r n; do
  printf '    %s.url = "github:%s/%s";\n    %s.inputs.nixpkgs.follows = "nixpkgs";\n' "$n" "$OWNER" "$n" "$n"
done <<<"$remote")

tmp=$(mktemp)
awk -v block="$block" -v remote="$remote" '
  BEGIN { n = split(remote, r, "\n"); for (i = 1; i <= n; i++) keep[r[i]] = 1 }
  /^    nixpkg-[a-z0-9-]+\.(url|inputs\.nixpkgs\.follows) / { next }
  /^    nixpkg-[a-z0-9-]+\./ { name = $1; sub(/\..*/, "", name); if (!(name in keep)) next }
  { print }
  /^    nixpkgs\.url = / { print ""; print block }
' "$FLAKE" >"$tmp"
cat "$tmp" >"$FLAKE"; rm -f "$tmp"

if [ -n "$removed" ]; then
  nix flake lock --accept-flake-config >/dev/null
fi

if [ "${SKIP_LOCK:-0}" != 1 ]; then
  # shellcheck disable=SC2046
  nix flake update --accept-flake-config $(echo "$remote")
fi

summary=""
[ -n "$added" ]   && summary+="+$(echo "$added" | sed 's/^nixpkg-//' | paste -sd,) "
[ -n "$removed" ] && summary+="-$(echo "$removed" | sed 's/^nixpkg-//' | paste -sd,) "
echo "added: $(echo "${added:-none}" | paste -sd, )"
echo "removed: $(echo "${removed:-none}" | paste -sd, )"
[ -n "${GITHUB_OUTPUT:-}" ] && echo "summary=${summary:-lock bump}" >>"$GITHUB_OUTPUT"
exit 0
