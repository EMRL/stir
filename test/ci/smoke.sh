#!/usr/bin/env bash

set -uo pipefail

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)

# shellcheck source=test/ci/assert.sh
source "$repository_root/test/ci/assert.sh"

tests=0
failures=0

run_test() {
  local description=$1
  shift

  tests=$((tests + 1))
  if "$@"; then
    printf 'PASS: %s\n' "$description"
  else
    return 1
  fi
}

test_help() {
  local output
  local status

  output=$(bash "$repository_root/stir.sh" --help 2>&1)
  status=$?

  assert_status 0 "$status" '--help exits successfully' || return
  assert_contains "$output" 'Usage: stir [options] [target]' \
    '--help displays usage' || return
  assert_contains "$output" '--current' '--help includes --current' || return
  assert_contains "$output" '--prepare' '--help includes --prepare'
}

test_extended_help() {
  local output
  local status

  output=$(bash "$repository_root/stir.sh" --more-help 2>&1)
  status=$?

  assert_status 0 "$status" '--more-help exits successfully' || return
  assert_contains "$output" '--automate' \
    '--more-help includes --automate' || return
  assert_contains "$output" '--skip-git' \
    '--more-help includes --skip-git' || return
  assert_contains "$output" '--show-settings' \
    '--more-help includes --show-settings'
}

test_version() {
  local output
  local status

  output=$(bash "$repository_root/stir.sh" --version 2>&1)
  status=$?

  assert_status 0 "$status" '--version exits successfully' || return
  if [[ ! "$output" =~ ^stir\.sh\ [0-9]+\.[0-9]+\.[0-9]+(-[[:alnum:]._-]+)?$ ]]; then
    fail "--version has an unexpected format: $output"
  fi
}

test_invalid_option() {
  local output
  local status

  output=$(bash "$repository_root/stir.sh" --not-a-real-option 2>&1)
  status=$?

  assert_status 1 "$status" 'an invalid option exits with status 1' || return
  assert_contains "$output" "Invalid option: '--not-a-real-option'" \
    'an invalid option explains the error'
}

run_test 'help output' test_help || failures=$((failures + 1))
run_test 'extended help output' test_extended_help || failures=$((failures + 1))
run_test 'version output' test_version || failures=$((failures + 1))
run_test 'invalid option handling' test_invalid_option || failures=$((failures + 1))

if [[ "$failures" -ne 0 ]]; then
  printf 'Smoke tests failed: %d of %d.\n' "$failures" "$tests" >&2
  exit 1
fi

printf 'Smoke tests passed: %d.\n' "$tests"
