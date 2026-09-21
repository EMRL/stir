#!/usr/bin/env bash

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  return 1
}

assert_status() {
  local expected=$1
  local actual=$2
  local description=$3

  if [[ "$actual" -ne "$expected" ]]; then
    fail "$description (expected status $expected, got $actual)"
  fi
}

assert_contains() {
  local output=$1
  local expected=$2
  local description=$3

  if [[ "$output" != *"$expected"* ]]; then
    fail "$description (missing: $expected)"
  fi
}
