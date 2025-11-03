#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
HOOK="${ROOT_DIR}/hooks/session-start.sh"

assert_contains() {
  local haystack="$1" needle="$2" msg="${3:-}"
  echo "$haystack" | grep -Fq "$needle" || {
    echo "Assertion failed: expected to find: $needle" >&2
    [ -n "$msg" ] && echo "$msg" >&2
    exit 1
  }
}

assert_not_contains() {
  local haystack="$1" needle="$2" msg="${3:-}"
  if echo "$haystack" | grep -Fq "$needle"; then
    echo "Assertion failed: expected NOT to find: $needle" >&2
    [ -n "$msg" ] && echo "$msg" >&2
    exit 1
  fi
}

run_in_fixture() {
  local name="$1" setup_fn="$2" check_fn="$3"
  echo "--- Running case: $name" >&2
  local dir
  dir="$(mktemp -d)"
  pushd "$dir" >/dev/null
  "$setup_fn"
  local out
  out="$("$HOOK")"
  echo "$out" | jq -e . >/dev/null 2>&1 || { echo "Output is not valid JSON" >&2; echo "$out" >&2; exit 1; }
  local ctx
  ctx="$(echo "$out" | jq -r '.hookSpecificOutput.additionalContext')"
  "$check_fn" "$ctx"
  popd >/dev/null
  rm -rf "$dir"
}

# Case 1: Laravel without Sail declared
setup_case1() {
  cat > composer.json <<'JSON'
{
  "require": {"laravel/framework": "^12.0"}
}
JSON
}

check_case1() {
  assert_contains "$1" "This repository appears to be a Laravel project."
  assert_not_contains "$1" "Laravel Sail is declared in composer.json."
}

run_in_fixture "laravel-no-sail" setup_case1 check_case1

# Case 2: Laravel with Sail declared, sail binary present, containers not running
setup_case2() {
  mkdir -p vendor/bin
  printf "#!/usr/bin/env bash\nexit 0\n" > vendor/bin/sail
  chmod +x vendor/bin/sail
  cat > composer.json <<'JSON'
{
  "require": {"laravel/framework": "^12.0"},
  "require-dev": {"laravel/sail": "^1.0"}
}
JSON
}

check_case2() {
  assert_contains "$1" "Laravel Sail is declared in composer.json."
  assert_contains "$1" "Interactive safety: Sail is present but containers are not running."
  assert_contains "$1" "Tip: Start containers: 'sail up -d' then verify: 'sail ps'."
}

run_in_fixture "laravel-sail-binary-no-containers" setup_case2 check_case2

# Case 3: Laravel with Sail declared, no sail binary
setup_case3() {
  cat > composer.json <<'JSON'
{
  "require": {"laravel/framework": "^12.0"},
  "require-dev": {"laravel/sail": "^1.0"}
}
JSON
}

check_case3() {
  assert_contains "$1" "Laravel Sail is declared in composer.json."
  assert_contains "$1" "Interactive safety: Sail is present but containers are not running."
  assert_contains "$1" "Tip: Install vendor binaries first: 'composer install' (host), then 'vendor/bin/sail up -d'."
}

run_in_fixture "laravel-sail-no-binary" setup_case3 check_case3

# Case 4: Laravel with Sail declared, containers running (simulated)
setup_case4() {
  mkdir -p vendor/bin
  printf "#!/usr/bin/env bash\nexit 0\n" > vendor/bin/sail
  chmod +x vendor/bin/sail
  cat > composer.json <<'JSON'
{
  "require": {"laravel/framework": "^12.0"},
  "require-dev": {"laravel/sail": "^1.0"}
}
JSON
}

check_case4() {
  assert_contains "$1" "Sail appears to be running (docker compose ps shows active containers)."
}

(
  export SUPERPOWERS_TEST_SAIL_RUNNING=true
  run_in_fixture "laravel-sail-containers-running" setup_case4 check_case4
)

echo "All session-start.sh tests passed."
