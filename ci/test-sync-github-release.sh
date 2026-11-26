#!/usr/bin/env bash
# Offline tests for ci/sync-github-release.sh (stub gh/nix via PATH). Usage: ci/test-sync-github-release.sh [scratch-dir]
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=${1:-$HOME/.cache/nixpkg-sync-gh-fixtures}; rm -rf "$ROOT"; mkdir -p "$ROOT/bin"
nfail=0
cat > "$ROOT/bin/gh" <<'S'
#!/usr/bin/env bash
[ -n "${STUB_TAG:-}" ] && echo "$STUB_TAG" || exit 1
S
cat > "$ROOT/bin/nix" <<'S'
#!/usr/bin/env bash
case "$*" in *"$STUB_MISSING"*) [ -n "${STUB_MISSING:-}" ] && { echo "404" >&2; exit 1; };; esac
echo '{"hash":"sha256-STUBHASH0000000000000000000000000000000000="}'
S
cat > "$ROOT/bin/git" <<'S'
#!/usr/bin/env bash
if [ "$1" = ls-remote ]; then printf 'aaa\trefs/tags/v0.1.0\nbbb\trefs/tags/v0.9.0\nccc\trefs/tags/v0.10.0\nddd\trefs/tags/nightly\n'; else exec /usr/bin/git "$@"; fi
S
chmod +x "$ROOT"/bin/*
manifest() { # manifest <dir> <root-key>
  mkdir -p "$1/nix"; jq -n --arg r "$2" '{($r):{type:"github-release",owner:"storytold",repo:"x",version:"0.12.0",tag:"v0.12.0",archive:"x-0.12.0-linux-x86_64.tar.gz",url:"https://github.com/storytold/x/releases/download/v0.12.0/x-0.12.0-linux-x86_64.tar.gz",hash:"sha256-OLD"},package:{repo:"x",version:"0.12.0"},binary:{name:"x"}}' > "$1/nix/package-manifest.json"
}
run() { (cd "$1" && PATH="$ROOT/bin:$PATH" env "${@:3}" bash "$HERE/sync-github-release.sh" 2>&1); }
check() { # check <label> <cond-rc>
  if [ "$2" = 0 ]; then echo "ok    $1"; else echo "NOTOK $1"; nfail=1; fi
}
for key in source upstream; do
  d=$ROOT/$key; manifest "$d" "$key"
  out=$(run "$d" x STUB_TAG=v0.20.1); rc=$?
  m=$d/nix/package-manifest.json
  [ $rc = 0 ] && jq -e --arg r "$key" '.[$r]|.version=="0.20.1" and .tag=="v0.20.1" and .archive=="x-0.20.1-linux-x86_64.tar.gz" and .url=="https://github.com/storytold/x/releases/download/v0.20.1/x-0.20.1-linux-x86_64.tar.gz" and (.hash|startswith("sha256-STUB"))' "$m" >/dev/null && jq -e '.package.version=="0.20.1"' "$m" >/dev/null && jq -e '.binary.name=="x"' "$m" >/dev/null
  check "schema .$key bumps all fields" $?
  out=$(run "$d" x STUB_TAG=v0.20.1); rc=$?; cp "$m" "$d/after"
  [ $rc = 0 ] && grep -q 'up to date' <<<"$out" && cmp -s "$m" "$d/after"
  check "schema .$key idempotent when current" $?
done
d=$ROOT/uptodate; manifest "$d" source; cp "$d/nix/package-manifest.json" "$d/before"
out=$(run "$d" x STUB_TAG=v0.12.0); rc=$?
[ $rc = 0 ] && cmp -s "$d/nix/package-manifest.json" "$d/before" && grep -q 'up to date' <<<"$out"
check "up-to-date: exit 0, no diff" $?
d=$ROOT/missing; manifest "$d" source; cp "$d/nix/package-manifest.json" "$d/before"
out=$(run "$d" x STUB_TAG=v0.20.1 STUB_MISSING=0.20.1); rc=$?
[ $rc != 0 ] && grep -q 'missing asset' <<<"$out" && cmp -s "$d/nix/package-manifest.json" "$d/before"
check "missing asset: fails loud, manifest untouched" $?
d=$ROOT/fallback; manifest "$d" source
out=$(run "$d" x); rc=$?
[ $rc = 0 ] && grep -q 'latest 0.10.0' <<<"$out" && jq -e '.source.version=="0.12.0"' "$d/nix/package-manifest.json" >/dev/null
check "gh failure falls back to git ls-remote (sort -V picks 0.10.0); no downgrade" $?
d=$ROOT/fallback-up; manifest "$d" source; jq '.source.version="0.9.0"|.source.tag="v0.9.0"|.source.archive="x-0.9.0-linux-x86_64.tar.gz"|.source.url="https://github.com/storytold/x/releases/download/v0.9.0/x-0.9.0-linux-x86_64.tar.gz"' "$d/nix/package-manifest.json" > "$d/t" && mv "$d/t" "$d/nix/package-manifest.json"
out=$(run "$d" x); rc=$?
[ $rc = 0 ] && jq -e '.source.version=="0.10.0"' "$d/nix/package-manifest.json" >/dev/null
check "fallback upgrades 0.9.0 -> 0.10.0" $?
exit $nfail
