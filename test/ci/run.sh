#!/usr/bin/env bash

set -uo pipefail

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)
status=0

bash "$repository_root/test/ci/syntax.sh" || status=1
bash "$repository_root/test/ci/smoke.sh" || status=1

exit "$status"
