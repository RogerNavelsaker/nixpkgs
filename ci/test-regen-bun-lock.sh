#!/usr/bin/env bash
# Offline tests for ci/regen-bun-lock.sh (stub nix via PATH). Usage: ci/test-regen-bun-lock.sh [scratch-dir]
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=${1:-$HOME/.cache/nixpkg-bun-lock-fixtures}; rm -rf "$ROOT"; mkdir -p "$ROOT/bin"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
nfail=0
cat > "$ROOT/bin/nix" <<'S'
#!/usr/bin/env bash
echo "$*" >> "$STUB_LOG"
S
chmod +x "$ROOT/bin/nix"
mk() { # mk <name> <config-json|-> <with-package.json 1|0>
  local d=$ROOT/$1; mkdir -p "$d"; (cd "$d" && git init -q -b main)
  [ "$2" = - ] || echo "$2" > "$d/.nixpkg-sync.json"
  [ "$3" = 1 ] && echo '{}' > "$d/package.json"
  :
}
run() { (cd "$ROOT/$1" && STUB_LOG="$ROOT/$1.log" PATH="$ROOT/bin:$PATH" bash "$HERE/regen-bun-lock.sh" 2>&1); }
t() { # t <label> <fixture> <expect-called 1|0>
  local rc=0; run "$2" >/dev/null || rc=$?
  local called=0; [ -s "$ROOT/$2.log" ] && called=1
  if [ "$rc" = 0 ] && [ "$called" = "$3" ]; then echo "ok    $1"; else echo "NOTOK $1 (rc=$rc called=$called)"; nfail=1; fi
}
mk on '{"bun_lock":true}' 1;   t "bun_lock true runs bun2nix" on 1
grep -q 'nixpkgs#bun' "$ROOT/on.log" && echo "ok    uses nixpkgs#bun" || { echo "NOTOK nix args"; nfail=1; }
mk off '{"bun_lock":false}' 1; t "bun_lock false skips" off 0
mk unset '{"kind":"none"}' 1;  t "bun_lock unset skips" unset 0
mk nopkg '{"bun_lock":true}' 0; t "no package.json skips" nopkg 0
exit $nfail
