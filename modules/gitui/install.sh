#!/usr/bin/env bash
set -Eeuo pipefail
archive="$DOTFILES_DATA_DIR/bin/gitui-v0.27.0-linux-x86_64.tar.gz"
tmp=$(mktemp -d "$DOTFILES_CACHE_DIR/gitui-extract.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT
tar -xzf "$archive" -C "$tmp"
install -m 0755 "$tmp/gitui" "$DOTFILES_DATA_DIR/bin/gitui"
