#!/usr/bin/env bash
set -Eeuo pipefail
archive="$DOTFILES_DATA_DIR/bin/navi-v2.24.0-x86_64-unknown-linux-musl.tar.gz"
tmp=$(mktemp -d "$DOTFILES_CACHE_DIR/navi-extract.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT
tar -xzf "$archive" -C "$tmp"
install -m 0755 "$tmp/navi" "$DOTFILES_DATA_DIR/bin/navi"
