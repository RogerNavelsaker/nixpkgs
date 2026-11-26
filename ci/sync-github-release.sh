#!/usr/bin/env bash
# Sync a GitHub-release-tarball manifest (craft-style repos) to the latest upstream release.
# Run from the caller repo root (sync-update.sh does this). Requires jq, nix; gh optional (git fallback).
# Env: MANIFEST (default nix/package-manifest.json), GH_TOKEN (optional, for gh).
# Schemas autodetected: .source.{owner,repo,version,tag,archive,url,hash} or .upstream.{...}; .package.version kept in step.
set -euo pipefail
MANIFEST=${MANIFEST:-nix/package-manifest.json}
die() { echo "sync-github-release: $*" >&2; exit 1; }
[ -f "$MANIFEST" ] || die "manifest not found: $MANIFEST"

root=$(jq -r 'if .source then "source" elif .upstream then "upstream" else empty end' "$MANIFEST")
[ -n "$root" ] || die "$MANIFEST has neither .source nor .upstream"
field() { jq -r --arg r "$root" --arg k "$1" '.[$r][$k] // empty' "$MANIFEST"; }

owner=$(field owner); repo=$(field repo)
old_version=$(field version); old_tag=$(field tag); old_archive=$(field archive); old_url=$(field url)
[ -n "$owner" ] && [ -n "$repo" ] && [ -n "$old_version" ] || die "$root.owner/repo/version required in $MANIFEST"
[ -n "$old_tag" ] || old_tag="v$old_version"

latest_tag() {
  local t=""
  if command -v gh >/dev/null 2>&1; then
    t=$(gh release view --repo "$owner/$repo" --json tagName --jq .tagName 2>/dev/null || true)
  fi
  if [ -z "$t" ]; then
    t=$(git ls-remote --tags --refs "https://github.com/$owner/$repo.git" 2>/dev/null \
      | sed -E 's#.*refs/tags/##' | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1 || true)
  fi
  printf '%s' "$t"
}

new_tag=$(latest_tag)
[ -n "$new_tag" ] || die "could not resolve latest release for $owner/$repo"
new_version=${new_tag#v}

if [ "$new_tag" = "$old_tag" ] && [ "$new_version" = "$old_version" ]; then
  echo "up to date: $owner/$repo $old_tag"; exit 0
fi

if [ "$(printf '%s\n%s\n' "$old_version" "$new_version" | sort -V | tail -n1)" = "$old_version" ]; then
  echo "up to date: manifest $old_version >= latest $new_version"; exit 0
fi

swap() { local s=${1//"$old_tag"/"$new_tag"}; printf '%s' "${s//"$old_version"/"$new_version"}"; }
new_archive=$(swap "$old_archive")
if [ -n "$old_url" ]; then new_url=$(swap "$old_url")
else new_url="https://github.com/$owner/$repo/releases/download/$new_tag/$new_archive"; fi
[ -n "$new_archive" ] || new_archive=${new_url##*/}
[ "$new_url" != "$old_url" ] || die "url pattern did not change for $new_tag; cannot derive new asset url"

echo "syncing $owner/$repo $old_tag -> $new_tag"
prefetch=$(nix store prefetch-file --json "$new_url") || die "missing asset: $new_url"
hash=$(printf '%s' "$prefetch" | jq -r '.hash // empty')
[ -n "$hash" ] || die "prefetch returned no hash for $new_url"

tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
jq --arg r "$root" --arg v "$new_version" --arg t "$new_tag" --arg a "$new_archive" --arg u "$new_url" --arg h "$hash" '
  .[$r] |= (.version = $v
    | (if has("tag") then .tag = $t else . end)
    | (if has("archive") then .archive = $a else . end)
    | (if has("url") then .url = $u else . end)
    | .hash = $h)
  | (if .package then .package.version = $v else . end)' "$MANIFEST" > "$tmp"
cat "$tmp" > "$MANIFEST"
echo "updated $MANIFEST: $new_version $hash"
