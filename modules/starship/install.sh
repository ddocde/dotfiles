#!/usr/bin/env bash
set -Eeuo pipefail
archive="$DOTFILES_DATA_DIR/bin/starship-v1.23.0-x86_64-unknown-linux-musl.tar.gz"
tmp=$(mktemp -d "$DOTFILES_CACHE_DIR/starship-extract.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT
tar -xzf "$archive" -C "$tmp"
install -m 0755 "$tmp/starship" "$DOTFILES_DATA_DIR/bin/starship"
"$DOTFILES_ROOT/scripts/generate-shell-init.sh" starship
