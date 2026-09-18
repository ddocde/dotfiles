#!/usr/bin/env bash
set -Eeuo pipefail
archive="$DOTFILES_DATA_DIR/bin/helix-25.07.1-x86_64-linux.tar.xz"
install_root="$DOTFILES_DATA_DIR/helix/25.07.1"
if [[ ! -x $install_root/hx ]]; then
    tmp=$(mktemp -d "$DOTFILES_CACHE_DIR/helix-extract.XXXXXX")
    tar -xJf "$archive" -C "$tmp"
    mkdir -p -- "$(dirname -- "$install_root")"
    mv -- "$tmp/helix-25.07.1-x86_64-linux" "$install_root"
    rmdir -- "$tmp"
fi
ln -sfn -- "$install_root/hx" "$DOTFILES_DATA_DIR/bin/hx"
