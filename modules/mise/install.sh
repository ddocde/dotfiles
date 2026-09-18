#!/usr/bin/env bash
set -Eeuo pipefail
archive="$DOTFILES_DATA_DIR/bin/mise-v2026.9.10-linux-x64.tar.xz"
if [[ ! -x $DOTFILES_DATA_DIR/bin/mise || $("$DOTFILES_DATA_DIR/bin/mise" --version 2>/dev/null) != 2026.9.10* ]]; then
    tmp=$(mktemp -d "$DOTFILES_CACHE_DIR/mise-extract.XXXXXX")
    tar -xJf "$archive" -C "$tmp" mise/bin/mise
    install -m 0755 "$tmp/mise/bin/mise" "$DOTFILES_DATA_DIR/bin/mise"
fi
PATH="$DOTFILES_DATA_DIR/bin:$PATH" "$DOTFILES_ROOT/scripts/generate-shell-init.sh" mise
