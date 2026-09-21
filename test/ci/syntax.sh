#!/usr/bin/env bash

set -uo pipefail

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)
status=0
count=0

while IFS= read -r -d '' file; do
  count=$((count + 1))
  if ! bash -n "$file"; then
    status=1
  fi
done < <(
  find "$repository_root" -type f \( -name '*.sh' -o -name '*.rc' \) \
    -not -path "$repository_root/.git/*" -print0
)

if [[ "$status" -ne 0 ]]; then
  printf 'Bash syntax checks failed.\n' >&2
  exit "$status"
fi

printf 'Bash syntax checks passed for %d files.\n' "$count"
