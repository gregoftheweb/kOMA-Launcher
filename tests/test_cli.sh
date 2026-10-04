#!/usr/bin/env bash
# Tests for bin/komalauncher with a fake qdbus6 on PATH (no plasmashell needed).
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cli="$here/../bin/komalauncher"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0 passes=0

# fake qdbus6: records the script it was given, replies with $FAKE_REPLY
cat >"$tmp/qdbus6" <<'FAKE'
#!/usr/bin/env bash
printf '%s' "${@: -1}" >"$FAKE_LOG"
printf '%s\n' "${FAKE_REPLY:-ok}"
FAKE
chmod +x "$tmp/qdbus6"
export PATH="$tmp:$PATH" FAKE_LOG="$tmp/script.js"

check() { # name, condition...
  local name=$1
  shift
  if "$@"; then passes=$((passes + 1)); else
    echo "FAIL: $name"
    fails=$((fails + 1))
  fi
}

out=$("$cli" frobnicate 2>&1)
rc=$?
check "unknown command exits 2" test "$rc" -eq 2
check "unknown command prints usage" grep -q "usage: komalauncher open" <<<"$out"

FAKE_REPLY=ok "$cli" open system.power
check "open succeeds when the widget answers" test $? -eq 0
check "route reaches the widget" grep -q "'system.power|'" "$FAKE_LOG"

FAKE_REPLY=ok "$cli" open "x';evil();'" >/dev/null 2>&1
check "route is stripped of quotes and code" grep -q "'xevil|'" "$FAKE_LOG"

FAKE_REPLY=ok "$cli"
check "no arguments opens the root menu" grep -q "'root|'" "$FAKE_LOG"

out=$(FAKE_REPLY=no-widget "$cli" open 2>&1)
rc=$?
check "missing widget exits 1" test "$rc" -eq 1
check "missing widget explains itself" grep -q "not found on any panel" <<<"$out"

echo "komalauncher CLI: $passes passed, $fails failed"
[[ $fails -eq 0 ]]
