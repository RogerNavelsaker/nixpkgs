#!/usr/bin/env bash
# Sync a URL-binary manifest (binary served from a bucket/CDN, version from a latest-version endpoint).
# Run from the caller repo root (sync-update.sh does this). Requires jq, curl, sha512sum; reads .nixpkg-sync.json.
# Config keys:
#   version_url            endpoint returning the latest version (JSON or plain text)
#   latest_version_jq      jq path into the endpoint JSON (default .version; empty/non-JSON = trimmed raw text)
#   download_url_template  URL with {version} and {platform}; fetched once per platform
#   platforms              {"<nix system>": "<platform token>"}
#   download_resolve       true = the templated URL returns JSON naming the real binary (url via download_url_jq,
#                          default .url; sha512 via download_sha512_jq, default .sha512)
#                          false/absent = the templated URL is the binary; sha512 is computed with sha512sum
#   version_file + version_jq  where the current version is read (default output: {version, sources:{<system>:{url,sha512}}})
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$HERE/lib.sh"
die() { echo "sync-url-binary: $*" >&2; exit 1; }
[ -f "$SYNC_CONFIG" ] || die "$SYNC_CONFIG not found"

version_url=$(cfg version_url); template=$(cfg download_url_template); out=$(cfg version_file)
latest_jq=$(cfg latest_version_jq); latest_jq=${latest_jq:-.version}
resolve=$(cfg download_resolve); url_jq=$(cfg download_url_jq); url_jq=${url_jq:-.url}
sha_jq=$(cfg download_sha512_jq); sha_jq=${sha_jq:-.sha512}
[ -n "$version_url" ] && [ -n "$template" ] && [ -n "$out" ] || die "version_url, download_url_template, version_file required"
jq -e '.platforms | type == "object" and length > 0' "$SYNC_CONFIG" >/dev/null || die "platforms map required"

raw=$(curl -fsSL "$version_url") || die "version lookup failed: $version_url"
if printf '%s' "$raw" | jq -e . >/dev/null 2>&1; then new_version=$(printf '%s' "$raw" | jq -r "$latest_jq")
else new_version=${raw//[[:space:]]/}; fi
[ -n "$new_version" ] && [ "$new_version" != null ] || die "no version in response from $version_url"

old_version=$(read_version || true)
if [ -n "$old_version" ] && [ "$old_version" = "$new_version" ]; then echo "up to date: $old_version"; exit 0; fi
if [ -n "$old_version" ] && [ "$(printf '%s\n%s\n' "$old_version" "$new_version" | sort -V | tail -n1)" = "$old_version" ]; then
  echo "up to date: manifest $old_version >= latest $new_version"; exit 0
fi

echo "syncing ${old_version:-none} -> $new_version"
sources='{}'
while IFS=$'\t' read -r system platform; do
  url=${template//\{version\}/$new_version}; url=${url//\{platform\}/$platform}
  if [ "$resolve" = true ]; then
    resp=$(curl -fsSL "$url") || die "resolve failed: $url"
    bin_url=$(printf '%s' "$resp" | jq -r "$url_jq"); sha=$(printf '%s' "$resp" | jq -r "$sha_jq")
    [ -n "$bin_url" ] && [ "$bin_url" != null ] && [ -n "$sha" ] && [ "$sha" != null ] || die "no url/sha512 in $url"
  else
    bin_url=$url
    sha=$(curl -fsSL "$bin_url" | sha512sum | cut -d' ' -f1) || die "download failed: $bin_url"
  fi
  sources=$(jq --arg s "$system" --arg u "$bin_url" --arg h "$sha" '.[$s] = {url:$u, sha512:$h}' <<<"$sources")
done < <(jq -r '.platforms | to_entries[] | [.key, .value] | @tsv' "$SYNC_CONFIG")

tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
jq -n --arg v "$new_version" --argjson s "$sources" '{version:$v, sources:$s}' > "$tmp"
cat "$tmp" > "$out"
echo "updated $out: $new_version"
