#!/usr/bin/env bash
set -Eeuo pipefail
archive="$DOTFILES_DATA_DIR/bin/yazi-v25.5.31-x86_64-unknown-linux-gnu.zip"
tmp=$(mktemp -d "$DOTFILES_CACHE_DIR/yazi-extract.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT
unzip -q "$archive" -d "$tmp"
root="$tmp/yazi-x86_64-unknown-linux-gnu"
install -m 0755 "$root/yazi" "$DOTFILES_DATA_DIR/bin/yazi"
install -m 0755 "$root/ya" "$DOTFILES_DATA_DIR/bin/ya"
