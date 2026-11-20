#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd "$ROOT"
# bash -n accepts one script; passing a glob as arguments checks only its first file.
while IFS= read -r -d '' file; do
    bash -n -- "$file"
done < <(find setup.sh lib modules scripts tests -type f -name '*.sh' -print0)
