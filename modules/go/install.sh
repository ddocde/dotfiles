#!/usr/bin/env bash
set -Eeuo pipefail
binary="${MISE_DATA_DIR:-$XDG_DATA_HOME/mise}/installs/go/1.25.1/bin/go"
if [[ -x $binary && $("$binary" version) == 'go version go1.25.1 '* ]]; then exit 0; fi
run env MISE_ALWAYS_KEEP_DOWNLOAD=1 "$DOTFILES_DATA_DIR/bin/mise" install go@1.25.1
record_owned_runtime go@1.25.1
