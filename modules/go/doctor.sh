#!/usr/bin/env bash
set -Eeuo pipefail
"$DOTFILES_DATA_DIR/bin/mise" x go@1.25.1 -- go version >/dev/null
