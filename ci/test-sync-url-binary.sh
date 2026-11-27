#!/usr/bin/env bash
# Offline tests for ci/sync-url-binary.sh and check-sync url-binary (stub curl via PATH). Usage: ci/test-sync-url-binary.sh [scratch-dir]
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=${1:-$HOME/.cache/nixpkg-url-binary-fixtures}; rm -rf "$ROOT"; mkdir -p "$ROOT/bin"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
nfail=0
cat > "$ROOT/bin/curl" <<'S'
#!/usr/bin/env bash
url=${@: -1}
case "$url" in
  https://v.invalid/latest) echo "${STUB_VERSION:-2.0.0}"; echo ;;
  https://v.invalid/latest.json) echo "{\"version\":\"${STUB_VERSION:-2.0.0}\"}" ;;
  https://m.invalid/manifests/linux.json) echo "{\"version\":\"2.0.0\",\"url\":\"https://dl.invalid/2.0.0-build9/linux.tgz\",\"sha512\":\"aa11\"}" ;;
  https://m.invalid/manifests/mac.json) echo "{\"version\":\"2.0.0\",\"url\":\"https://dl.invalid/2.0.0-build9/mac.tgz\",\"sha512\":\"bb22\"}" ;;
  https://dl.invalid/2.0.0/linux.tgz|https://dl.invalid/2.0.0/mac.tgz) printf 'payload' ;;
  *) exit 22 ;;
esac
S
chmod +x "$ROOT/bin/curl"
mk() { # mk <name> <config-json>
  local d=$ROOT/$1; mkdir -p "$d"; (cd "$d" && git init -q -b main && echo '{"version":"1.0.0","sources":{}}' > sources.json && echo "$2" > .nixpkg-sync.json)
}
run() { (cd "$ROOT/$1" && PATH="$ROOT/bin:$PATH" env "${@:2}" bash "$HERE/sync-url-binary.sh" 2>&1); }
ok() { if [ "$2" = 0 ]; then echo "ok    $1"; else echo "NOTOK $1"; nfail=1; fi; }
base='"version_file":"sources.json","version_jq":".version","platforms":{"x86_64-linux":"linux","aarch64-darwin":"mac"}'
# resolve mode (antigravity-style)
mk res "{\"kind\":\"url-binary\",\"version_url\":\"https://v.invalid/latest.json\",\"download_url_template\":\"https://m.invalid/manifests/{platform}.json\",\"download_resolve\":true,$base}"
run res >/dev/null; rc=$?; ok "resolve mode exits 0" $rc
[ "$(jq -r '.version, .sources["x86_64-linux"].url, .sources["aarch64-darwin"].sha512' "$ROOT/res/sources.json" | paste -sd' ')" = "2.0.0 https://dl.invalid/2.0.0-build9/linux.tgz bb22" ]; ok "resolve mode writes version/url/sha512" $?
run res | grep -q 'up to date'; ok "resolve mode rerun is up to date" $?
# direct mode (templated URL is the binary; sha512 computed)
mk dir "{\"kind\":\"url-binary\",\"version_url\":\"https://v.invalid/latest\",\"download_url_template\":\"https://dl.invalid/{version}/{platform}.tgz\",$base}"
run dir >/dev/null; rc=$?; ok "direct mode exits 0" $rc
want=$(printf payload | sha512sum | cut -d' ' -f1)
[ "$(jq -r '.sources["x86_64-linux"] | .url + " " + .sha512' "$ROOT/dir/sources.json")" = "https://dl.invalid/2.0.0/linux.tgz $want" ]; ok "direct mode computes sha512" $?
# older upstream is not a downgrade
mk old "{\"kind\":\"url-binary\",\"version_url\":\"https://v.invalid/latest.json\",\"download_url_template\":\"https://dl.invalid/{version}/{platform}.tgz\",$base}"
run old STUB_VERSION=0.9.0 | grep -q 'up to date'; ok "older upstream skipped" $?
# endpoint failure fails loud
mk bad "{\"kind\":\"url-binary\",\"version_url\":\"https://v.invalid/nope\",\"download_url_template\":\"https://dl.invalid/{version}/{platform}.tgz\",$base}"
run bad >/dev/null; [ $? -ne 0 ]; ok "version endpoint failure exits non-zero" $?
# check-sync kind (online path via stub curl): stale -> FAIL, current -> PASS
chk() { (cd "$ROOT/$1" && git add -A >/dev/null && git commit -qm c >/dev/null 2>&1; PATH="$ROOT/bin:$PATH" bash "$HERE/check-sync.sh" 2>&1 | grep "manifest version" || true); }
out=$(chk res); grep -qF "PASS  manifest version == latest upstream (2.0.0)" <<<"$out"; ok "check-sync url-binary current passes" $?
out=$(chk old); grep -qF "FAIL  manifest version 1.0.0 != latest upstream 2.0.0" <<<"$out"; ok "check-sync url-binary stale fails" $?
exit $nfail
