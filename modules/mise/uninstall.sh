#!/usr/bin/env bash
set -Eeuo pipefail
run rm -f -- "$DOTFILES_DATA_DIR/bin/mise" "$DOTFILES_DATA_DIR/bin/mise-v2026.9.10-linux-x64.tar.xz"
run rm -f -- "$DOTFILES_CACHE_DIR/shell-init/mise.bash" "$DOTFILES_CACHE_DIR/shell-init/mise.zsh"
