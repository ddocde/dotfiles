#!/usr/bin/env bash
set -Eeuo pipefail
binary="${MISE_DATA_DIR:-$XDG_DATA_HOME/mise}/installs/go/1.25.1/bin/go"
if [[ -x $binary && $("$binary" version) == 'go version go1.25.1 '* ]]; then exit 0; fi
bootstrap="$DOTFILES_CACHE_DIR/go-bootstrap"
mkdir -p -- "$bootstrap"
install -m 0644 "$DOTFILES_ROOT/modules/go/mise/config.toml" "$bootstrap/config.toml"
install -m 0644 "$DOTFILES_ROOT/modules/go/mise/mise.lock" "$bootstrap/mise.lock"
# The locked checksum comes from upstream, even when the mirror does not
# publish adjacent checksum files. mise remains responsible for installation.
run_with_source_fallback go env MISE_GLOBAL_CONFIG_FILE="$bootstrap/config.toml" \
    MISE_LOCKED=1 MISE_GO_SKIP_CHECKSUM=false MISE_ALWAYS_KEEP_DOWNLOAD=1 \
    "$DOTFILES_DATA_DIR/bin/mise" install go@1.25.1
record_owned_runtime go@1.25.1
