#!/usr/bin/env bash
# Offline fixture tests for ci/check-sync.sh. Usage: ci/test-check-sync.sh [scratch-dir]
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=${1:-$HOME/.cache/nixpkg-ci-fixtures}; rm -rf "$ROOT"; mkdir -p "$ROOT"
export CHECK_OFFLINE=1 GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
nfail=0
mk() { # mk <name> <kind> -> good repo fixture
  local d=$ROOT/$1; mkdir -p "$d/.github/workflows" "$d/nix"; cd "$d" && git init -q -b main
  cp "$HERE/templates/ci.yml" .github/workflows/ci.yml
  sed 's/__MINUTE__/5/' "$HERE/templates/sync-upstream.yml" > .github/workflows/sync-upstream.yml
  echo '{ nixConfig.extra-substituters = ["https://rogernavelsaker.cachix.org"]; }' > flake.nix
  echo '{"package":{"version":"1.2.3"}}' > nix/package-manifest.json
  jq -n --arg k "$2" '{kind:$k,upstream:"https://example.invalid/x.git",tag_regex:"^v[0-9.]+$",tag_prefix:"v",version_file:"nix/package-manifest.json",version_jq:".package.version",pinned_paths:["vendor"]}' > .nixpkg-sync.json
  git add -A && git commit -qm base
}
expect() { # expect <label> <want-exit> <fixture> [grep-pattern]
  local out rc; out=$(cd "$ROOT/$3" && bash "$HERE/check-sync.sh" 2>&1); rc=$?
  if [ "$rc" = "$2" ] && { [ -z "${4:-}" ] || grep -qE "$4" <<<"$out"; }; then echo "ok    $1"; else echo "NOTOK $1 (rc=$rc)"; echo "$out" | sed 's/^/      /'; nfail=1; fi
}
for k in git-tag github-release npm pypi git-head; do mk "k-$k" "$k"; expect "kind $k offline clean" 0 "k-$k" 'SKIP  manifest version == latest upstream \(CHECK_OFFLINE'; done
mk k-none none; jq 'del(.version_file,.version_jq)' "$ROOT/k-none/.nixpkg-sync.json" > "$ROOT/k-none/x" && mv "$ROOT/k-none/x" "$ROOT/k-none/.nixpkg-sync.json"
expect "kind none (no version_file)" 0 k-none 'SKIP  manifest version == latest upstream \(kind none\)'
mk k-none-nosync none; rm .github/workflows/sync-upstream.yml 2>/dev/null; (cd "$ROOT/k-none-nosync" && git add -A && git commit -qm nosync)
expect "kind none without sync workflow passes" 0 k-none-nosync 'SKIP  sync workflow checks \(kind none'
mk k-grep git-tag; jq 'del(.version_jq)|.version_file="flake.nix"|.version_grep="version = \"[^\"]+\""' "$ROOT/k-grep/.nixpkg-sync.json" > "$ROOT/k-grep/x" && mv "$ROOT/k-grep/x" "$ROOT/k-grep/.nixpkg-sync.json"
echo '{ version = "9.9.9"; nixConfig.extra-substituters = ["https://rogernavelsaker.cachix.org"]; }' > "$ROOT/k-grep/flake.nix"
expect "version_grep reads flake.nix" 0 k-grep 'SKIP  manifest version == latest upstream \(CHECK_OFFLINE'
# induced structural failures (each from a clean git-tag fixture)
inject() { mk "f-$1" git-tag; (cd "$ROOT/f-$1" && eval "$2"); expect "induced: $1" 1 "f-$1" "$3"; }
inject path-input   "echo 'inputs.x.url = \"path:../x\";' >> flake.nix"                     'FAIL  no path: flake inputs'
inject local-sync   "echo 'cp -r ../sibling/* vendor/' > sync.sh; mkdir scripts; mv sync.sh scripts/"  'FAIL  no local folder-to-folder sync'
inject no-schedule  "sed -i '/schedule:/,/cron:/d' .github/workflows/sync-upstream.yml"    'FAIL  sync workflow has schedule'
inject explicit-branch "echo '      branch: dev' >> .github/workflows/sync-upstream.yml"    'FAIL  sync workflow commits'
inject no-cachix    "rm .github/workflows/ci.yml; echo 'on: push' > .github/workflows/other.yml"  'FAIL  cachix configured'
inject no-substituter "echo '{ }' > flake.nix"                                              'FAIL  flake nixConfig'
inject npm-publish  "echo 'npm publish' > release.sh"                                      'FAIL  no npm publish'
inject bad-version  "echo '{}' > nix/package-manifest.json"                                 'FAIL  manifest version readable'
# bump-on-change
mk b-nobump git-tag; (cd "$ROOT/b-nobump" && git checkout -qb pr && mkdir vendor && echo x > vendor/a && git add -A && git commit -qm change)
out=$(cd "$ROOT/b-nobump" && BASE_REF=main bash "$HERE/check-sync.sh" 2>&1); grep -q 'FAIL  pinned source changed' <<<"$out" && echo "ok    induced: no version bump on pinned change" || { echo "NOTOK bump"; nfail=1; }
(cd "$ROOT/b-nobump" && echo '{"package":{"version":"1.2.4"}}' > nix/package-manifest.json && git commit -qam bump)
out=$(cd "$ROOT/b-nobump" && BASE_REF=main bash "$HERE/check-sync.sh" 2>&1); grep -q 'PASS  version bump on pinned-source change (1.2.3 -> 1.2.4' <<<"$out" && echo "ok    bump accepted" || { echo "NOTOK bump2"; nfail=1; }
# migrate idempotent
mkdir -p "$ROOT/m" && (cd "$ROOT/m" && git init -q) && bash "$HERE/migrate-repo.sh" "$ROOT/m" >/dev/null && cp -r "$ROOT/m" "$ROOT/m1" && bash "$HERE/migrate-repo.sh" "$ROOT/m" >/dev/null && diff -r -x .git "$ROOT/m" "$ROOT/m1" >/dev/null && echo "ok    migrate-repo idempotent" || { echo "NOTOK migrate"; nfail=1; }
# cron minute hashes the origin repo name, not the checkout dir name
mkdir -p "$ROOT/central-sync" && (cd "$ROOT/central-sync" && git init -q && git remote add origin https://example.invalid/RogerNavelsaker/nixpkg-cadcraft.git) && bash "$HERE/migrate-repo.sh" "$ROOT/central-sync" >/dev/null
want=$(( $(printf '%s' nixpkg-cadcraft | cksum | cut -d' ' -f1) % 60 ))
grep -qE "cron: \"$want " "$ROOT/central-sync/.github/workflows/sync-upstream.yml" && echo "ok    migrate-repo cron minute from origin name" || { echo "NOTOK migrate origin-name minute (want $want)"; nfail=1; }
exit $nfail
