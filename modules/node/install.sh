#!/usr/bin/env bash
set -Eeuo pipefail
binary="${MISE_DATA_DIR:-$XDG_DATA_HOME/mise}/installs/node/24.8.0/bin/node"
if [[ -x $binary && $("$binary" --version) == v24.8.0 ]]; then exit 0; fi
run_with_source_fallback node env MISE_ALWAYS_KEEP_DOWNLOAD=1 "$DOTFILES_DATA_DIR/bin/mise" install node@24.8.0
record_owned_runtime node@24.8.0
